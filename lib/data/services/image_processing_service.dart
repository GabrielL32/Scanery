import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import '../models/scanned_page.dart';

class _ProcessImageParams {
  final String sourcePath;
  final String outputPath;
  final double cropLeft;
  final double cropTop;
  final double cropRight;
  final double cropBottom;
  final List<double> colorMatrix;
  final bool isIdentityMatrix;
  final bool isCropped;

  _ProcessImageParams({
    required this.sourcePath,
    required this.outputPath,
    required this.cropLeft,
    required this.cropTop,
    required this.cropRight,
    required this.cropBottom,
    required this.colorMatrix,
    required this.isIdentityMatrix,
    required this.isCropped,
  });
}

class ImageProcessingService {
  /// Construye la matriz 4x5 de color para previsualización en GPU (ColorFilter.matrix)
  /// y procesamiento exacto de píxeles al guardar.
  static List<double> buildColorMatrix(
    PageFilter filter,
    double contrastLevel,
  ) {
    const double lr = 0.299;
    const double lg = 0.587;
    const double lb = 0.114;

    switch (filter) {
      case PageFilter.original:
        if ((contrastLevel - 1.0).abs() < 0.01) {
          return <double>[
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ];
        }
        final double c = contrastLevel;
        final double t = 185.0 * (1.0 - c);
        return <double>[
          c,
          0,
          0,
          0,
          t,
          0,
          c,
          0,
          0,
          t,
          0,
          0,
          c,
          0,
          t,
          0,
          0,
          0,
          1,
          0,
        ];

      case PageFilter.highContrastText:
        final double c = 1.65 * contrastLevel;
        final double t = 190.0 * (1.0 - c) + 8.0;
        return <double>[
          c,
          0,
          0,
          0,
          t,
          0,
          c,
          0,
          0,
          t,
          0,
          0,
          c,
          0,
          t,
          0,
          0,
          0,
          1,
          0,
        ];

      case PageFilter.blackAndWhite:
        final double c = 1.75 * contrastLevel;
        final double t = 188.0 * (1.0 - c) + 10.0;
        final double r = lr * c;
        final double g = lg * c;
        final double b = lb * c;
        return <double>[
          r,
          g,
          b,
          0,
          t,
          r,
          g,
          b,
          0,
          t,
          r,
          g,
          b,
          0,
          t,
          0,
          0,
          0,
          1,
          0,
        ];

      case PageFilter.darkInk:
        final double c = 2.65 * contrastLevel;
        final double t = 196.0 * (1.0 - c) + 6.0;
        final double r = lr * c;
        final double g = lg * c;
        final double b = lb * c;
        return <double>[
          r,
          g,
          b,
          0,
          t,
          r,
          g,
          b,
          0,
          t,
          r,
          g,
          b,
          0,
          t,
          0,
          0,
          0,
          1,
          0,
        ];

      case PageFilter.extraDarkLetters:
        final double c = 3.55 * contrastLevel;
        final double t = 204.0 * (1.0 - c) - 10.0;
        final double r = lr * c;
        final double g = lg * c;
        final double b = lb * c;
        return <double>[
          r,
          g,
          b,
          0,
          t,
          r,
          g,
          b,
          0,
          t,
          r,
          g,
          b,
          0,
          t,
          0,
          0,
          0,
          1,
          0,
        ];

      case PageFilter.magicColor:
        final double c = 1.85 * contrastLevel;
        const double s = 1.45; // Refuerzo de saturación
        final double t = 194.0 * (1.0 - c) + 14.0;

        final double sr = (1.0 - s) * lr;
        final double sg = (1.0 - s) * lg;
        final double sb = (1.0 - s) * lb;

        return <double>[
          c * (sr + s),
          c * sg,
          c * sb,
          0,
          t,
          c * sr,
          c * (sg + s),
          c * sb,
          0,
          t,
          c * sr,
          c * sg,
          c * (sb + s),
          0,
          t,
          0,
          0,
          0,
          1,
          0,
        ];
    }
  }

  static ColorFilter getColorFilter(PageFilter filter, double contrastLevel) {
    return ColorFilter.matrix(buildColorMatrix(filter, contrastLevel));
  }

  /// Procesa el recorte y el filtro sobre la imagen original y devuelve la ruta resultante.
  Future<String> applyEditsToPage({
    required ScannedPage page,
    required PageFilter filter,
    required double contrastLevel,
    required double cropLeft,
    required double cropTop,
    required double cropRight,
    required double cropBottom,
  }) async {
    final bool isIdentity =
        filter == PageFilter.original && (contrastLevel - 1.0).abs() < 0.01;
    final bool isCropped =
        cropLeft > 0.005 ||
        cropTop > 0.005 ||
        cropRight < 0.995 ||
        cropBottom < 0.995;

    // Si no hay recorte ni filtro activo, podemos usar directamente la imagen original
    if (isIdentity && !isCropped) {
      if (page.imagePath != page.originalImagePath) {
        try {
          final oldEdited = File(page.imagePath);
          if (await oldEdited.exists()) {
            await oldEdited.delete();
          }
        } catch (_) {}
      }
      return page.originalImagePath;
    }

    final dir = p.dirname(page.originalImagePath);
    final outputFileName =
        'edited_${page.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final outputPath = p.join(dir, outputFileName);

    final matrix = buildColorMatrix(filter, contrastLevel);

    final params = _ProcessImageParams(
      sourcePath: page.originalImagePath,
      outputPath: outputPath,
      cropLeft: cropLeft,
      cropTop: cropTop,
      cropRight: cropRight,
      cropBottom: cropBottom,
      colorMatrix: matrix,
      isIdentityMatrix: isIdentity,
      isCropped: isCropped,
    );

    await compute(_processImageIsolate, params);

    // Borrar archivo editado anterior si no es el original
    if (page.imagePath != page.originalImagePath &&
        page.imagePath != outputPath) {
      try {
        final oldFile = File(page.imagePath);
        if (await oldFile.exists()) {
          await oldFile.delete();
        }
      } catch (_) {}
    }

    return outputPath;
  }

  static void _processImageIsolate(_ProcessImageParams params) {
    final sourceFile = File(params.sourcePath);
    final Uint8List bytes = sourceFile.readAsBytesSync();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('No se pudo decodificar la imagen para editar.');
    }

    // Normalizar orientación EXIF si aplica
    image = img.bakeOrientation(image);

    // 1. Aplicar recorte si se definió
    if (params.isCropped) {
      final int x = (params.cropLeft * image.width).round().clamp(
        0,
        image.width - 1,
      );
      final int y = (params.cropTop * image.height).round().clamp(
        0,
        image.height - 1,
      );
      final int right = (params.cropRight * image.width).round().clamp(
        x + 1,
        image.width,
      );
      final int bottom = (params.cropBottom * image.height).round().clamp(
        y + 1,
        image.height,
      );
      final int w = (right - x).clamp(1, image.width - x);
      final int h = (bottom - y).clamp(1, image.height - y);

      image = img.copyCrop(image, x: x, y: y, width: w, height: h);
    }

    // 2. Aplicar matriz de filtro y contraste de letras
    if (!params.isIdentityMatrix) {
      final m = params.colorMatrix;
      final double m0 = m[0], m1 = m[1], m2 = m[2], m4 = m[4];
      final double m5 = m[5], m6 = m[6], m7 = m[7], m9 = m[9];
      final double m10 = m[10], m11 = m[11], m12 = m[12], m14 = m[14];

      for (final pixel in image) {
        final num r = pixel.r;
        final num g = pixel.g;
        final num b = pixel.b;

        final int nr = (m0 * r + m1 * g + m2 * b + m4).round().clamp(0, 255);
        final int ng = (m5 * r + m6 * g + m7 * b + m9).round().clamp(0, 255);
        final int nb = (m10 * r + m11 * g + m12 * b + m14).round().clamp(
          0,
          255,
        );

        pixel
          ..r = nr
          ..g = ng
          ..b = nb;
      }
    }

    // 3. Guardar JPEG con alta calidad
    final Uint8List encoded = img.encodeJpg(image, quality: 92);
    File(params.outputPath).writeAsBytesSync(encoded);
  }
}
