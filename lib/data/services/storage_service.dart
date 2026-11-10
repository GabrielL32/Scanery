import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/scanned_document.dart';
import '../models/scanned_page.dart';

class StorageService extends ChangeNotifier {
  static const String _keyDocuments = 'saved_scanned_documents';
  final List<ScannedDocument> _documents = [];
  bool _isInitialized = false;

  List<ScannedDocument> get documents => List.unmodifiable(_documents);
  bool get isInitialized => _isInitialized;

  StorageService() {
    loadDocuments();
  }

  Future<void> loadDocuments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyDocuments);
      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> list = jsonDecode(jsonString);
        _documents.clear();
        for (final item in list) {
          try {
            _documents.add(ScannedDocument.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            debugPrint('Error deserializing document: $e');
          }
        }
        // Ordenar por fecha descendente
        _documents.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }
    } catch (e) {
      debugPrint('Error loading documents: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveDocumentsToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _documents.map((doc) => doc.toJson()).toList();
      await prefs.setString(_keyDocuments, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving documents to prefs: $e');
    }
  }

  /// Copies an external or temporary image file to the app's persistent storage.
  Future<String> persistImage(String sourcePath, String documentId) async {
    final appDir = await getApplicationDocumentsDirectory();
    final docDir = Directory(p.join(appDir.path, 'documents', documentId));
    if (!await docDir.exists()) {
      await docDir.create(recursive: true);
    }

    final ext = p.extension(sourcePath).isNotEmpty ? p.extension(sourcePath) : '.jpg';
    final targetFileName = 'page_${const Uuid().v4()}$ext';
    final targetPath = p.join(docDir.path, targetFileName);

    final sourceFile = File(sourcePath);
    await sourceFile.copy(targetPath);
    return targetPath;
  }

  Future<void> addDocument(ScannedDocument document) async {
    _documents.insert(0, document);
    notifyListeners();
    await _saveDocumentsToPrefs();
  }

  Future<void> updateDocument(ScannedDocument document) async {
    final index = _documents.indexWhere((doc) => doc.id == document.id);
    if (index != -1) {
      _documents[index] = document;
      notifyListeners();
      await _saveDocumentsToPrefs();
    }
  }

  Future<void> deleteDocument(String documentId) async {
    final index = _documents.indexWhere((doc) => doc.id == documentId);
    if (index != -1) {
      final doc = _documents.removeAt(index);
      notifyListeners();
      await _saveDocumentsToPrefs();

      // Eliminar archivos físicos
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final docDir = Directory(p.join(appDir.path, 'documents', documentId));
        if (await docDir.exists()) {
          await docDir.delete(recursive: true);
        }
        if (doc.pdfPath != null) {
          final pdfFile = File(doc.pdfPath!);
          if (await pdfFile.exists()) {
            await pdfFile.delete();
          }
        }
      } catch (e) {
        debugPrint('Error deleting files for document $documentId: $e');
      }
    }
  }

  /// Helper to generate a new document container
  Future<ScannedDocument> createDocumentFromImages(
    List<String> rawImagePaths, {
    String? title,
  }) async {
    final docId = const Uuid().v4();
    final now = DateTime.now();
    final docTitle = title ??
        'Escaneo_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    final pages = <ScannedPage>[];
    for (final rawPath in rawImagePaths) {
      final persistentPath = await persistImage(rawPath, docId);
      pages.add(ScannedPage(
        id: const Uuid().v4(),
        imagePath: persistentPath,
      ));
    }

    final document = ScannedDocument(
      id: docId,
      title: docTitle,
      createdAt: now,
      pages: pages,
    );

    await addDocument(document);
    return document;
  }
}

