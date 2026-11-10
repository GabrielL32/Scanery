import 'package:flutter/foundation.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';

class ScannerResult {
  final List<String> images;
  final String? initialPdfPath;

  ScannerResult({
    required this.images,
    this.initialPdfPath,
  });
}

class ScannerService {
  final ImagePicker _imagePicker = ImagePicker();

  /// Inicia el escáner avanzado de Google ML Kit (con detección de contornos, corrección de perspectiva y filtros)
  Future<ScannerResult?> scanWithMlKit({int pageLimit = 100}) async {
    try {
      final options = DocumentScannerOptions(
        documentFormats: {DocumentFormat.jpeg, DocumentFormat.pdf},
        mode: ScannerMode.full,
        isGalleryImport: true,
        pageLimit: pageLimit,
      );

      final scanner = DocumentScanner(options: options);
      final result = await scanner.scanDocument();
      await scanner.close();

      final images = result.images ?? [];
      final pdfPath = result.pdf?.pageCount != null && result.pdf!.pageCount > 0
          ? null // Dejamos que nuestro propio PdfService gestione los metadatos y rotaciones
          : null;

      if (images.isEmpty) {
        return null;
      }

      return ScannerResult(
        images: images,
        initialPdfPath: pdfPath,
      );
    } catch (e) {
      debugPrint('Error en scanWithMlKit: $e');
      rethrow;
    }
  }

  /// Permite seleccionar múltiples imágenes de la galería del dispositivo
  Future<List<String>> pickImagesFromGallery() async {
    try {
      final List<XFile> picked = await _imagePicker.pickMultiImage(
        imageQuality: 95,
      );
      return picked.map((xFile) => xFile.path).toList();
    } catch (e) {
      debugPrint('Error picking images from gallery: $e');
      return [];
    }
  }

  /// Permite capturar una foto rápida desde la cámara del sistema
  Future<String?> capturePhotoFromCamera() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 95,
      );
      return photo?.path;
    } catch (e) {
      debugPrint('Error capturing photo from camera: $e');
      return null;
    }
  }
}

