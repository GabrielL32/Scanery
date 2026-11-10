import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanery/core/theme/theme_provider.dart';
import 'package:scanery/data/models/scanned_document.dart';
import 'package:scanery/data/models/scanned_page.dart';
import 'package:scanery/data/services/image_processing_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ScannedDocument and ScannedPage Models', () {
    test('Should serialize and deserialize ScannedDocument and ScannedPage edits correctly', () {
      final now = DateTime.now();
      final page1 = ScannedPage(
        id: 'p1',
        imagePath: '/mock/path/edited_p1.jpg',
        originalImagePath: '/mock/path/p1.jpg',
        rotationAngle: 90,
        filter: PageFilter.darkInk,
        contrastLevel: 1.4,
        cropLeft: 0.05,
        cropTop: 0.05,
        cropRight: 0.95,
        cropBottom: 0.95,
      );
      final page2 = ScannedPage(
        id: 'p2',
        imagePath: '/mock/path/p2.jpg',
        rotationAngle: 0,
      );

      final doc = ScannedDocument(
        id: 'doc1',
        title: 'Mi Documento',
        createdAt: now,
        pages: [page1, page2],
        pdfPath: '/mock/path/doc.pdf',
        fileSizeBytes: 2048,
      );

      expect(doc.pageCount, 2);
      expect(doc.thumbnailPath, '/mock/path/edited_p1.jpg');
      expect(page1.isCropped, isTrue);
      expect(page1.hasEdits, isTrue);
      expect(page2.isCropped, isFalse);
      expect(page2.hasEdits, isFalse);

      final json = doc.toJson();
      final fromJson = ScannedDocument.fromJson(json);

      expect(fromJson.id, 'doc1');
      expect(fromJson.title, 'Mi Documento');
      expect(fromJson.pageCount, 2);
      expect(fromJson.pages[0].rotationAngle, 90);
      expect(fromJson.pages[0].filter, PageFilter.darkInk);
      expect(fromJson.pages[0].contrastLevel, 1.4);
      expect(fromJson.pages[0].originalImagePath, '/mock/path/p1.jpg');
      expect(fromJson.pages[0].cropLeft, 0.05);
      expect(fromJson.pages[1].rotationAngle, 0);
      expect(fromJson.pages[1].filter, PageFilter.original);
      expect(fromJson.pdfPath, '/mock/path/doc.pdf');
      expect(fromJson.fileSizeBytes, 2048);
    });

    test('ImageProcessingService should generate valid 20-element color matrices', () {
      for (final filter in PageFilter.values) {
        final matrix = ImageProcessingService.buildColorMatrix(filter, 1.2);
        expect(matrix.length, 20);
      }
    });
  });

  group('ThemeProvider', () {
    test('Should initialize with system mode and default color', () {
      final provider = ThemeProvider();
      expect(provider.themeMode, ThemeMode.system);
    });

    test('Should change ThemeMode and notify listeners', () async {
      final provider = ThemeProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      await provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);
      expect(notified, isTrue);
    });

    test('Should change seed color and notify listeners', () async {
      final provider = ThemeProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      const newColor = Color(0xFF059669);
      await provider.setSeedColor(newColor);
      expect(provider.seedColor, newColor);
      expect(notified, isTrue);
    });
  });
}
