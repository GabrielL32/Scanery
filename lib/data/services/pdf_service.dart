import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scanned_page.dart';

enum PageSizeOption {
  a4,
  letter,
  fitToImage,
}

class PdfService {
  /// Genera un archivo PDF a partir de una lista de páginas escaneadas
  Future<File> generatePdf({
    required String documentTitle,
    required List<ScannedPage> pages,
    PageSizeOption pageSizeOption = PageSizeOption.a4,
    double marginMm = 0,
  }) async {
    final pdf = pw.Document(
      title: documentTitle,
      author: 'Scanery',
    );

    PdfPageFormat selectedFormat;
    switch (pageSizeOption) {
      case PageSizeOption.letter:
        selectedFormat = PdfPageFormat.letter;
        break;
      case PageSizeOption.a4:
      default:
        selectedFormat = PdfPageFormat.a4;
        break;
    }

    final margin = marginMm * PdfPageFormat.mm;

    for (final page in pages) {
      final imageFile = File(page.imagePath);
      if (!await imageFile.exists()) {
        continue;
      }

      final imageBytes = await imageFile.readAsBytes();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: selectedFormat,
          margin: pw.EdgeInsets.all(margin),
          build: (pw.Context context) {
            pw.Widget child = pw.Center(
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
              ),
            );

            // Aplicar rotación si es distinta de 0
            if (page.rotationAngle != 0) {
              double radians = (page.rotationAngle * 3.141592653589793) / 180.0;
              child = pw.Transform.rotate(
                angle: radians,
                child: child,
              );
            }

            return child;
          },
        ),
      );
    }

    // Guardar el PDF en el directorio de documentos de la aplicación
    final appDir = await getApplicationDocumentsDirectory();
    final pdfDir = Directory(p.join(appDir.path, 'exports'));
    if (!await pdfDir.exists()) {
      await pdfDir.create(recursive: true);
    }

    // Sanitizar nombre de archivo
    final safeTitle = documentTitle
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .trim();
    final fileName = '${safeTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final outputFile = File(p.join(pdfDir.path, fileName));

    final pdfBytes = await pdf.save();
    await outputFile.writeAsBytes(pdfBytes);

    return outputFile;
  }

  /// Comparte el archivo PDF usando la hoja nativa del sistema
  Future<void> sharePdf(String pdfPath, {String? text}) async {
    final file = File(pdfPath);
    if (await file.exists()) {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(pdfPath, mimeType: 'application/pdf')],
          text: text ?? 'Documento escaneado con Scanery',
        ),
      );
    } else {
      throw Exception('El archivo PDF no existe en la ruta especificada.');
    }
  }

  /// Abre el visor/impresión de PDF
  Future<void> printOrOpenPdf(String pdfPath, String title) async {
    final file = File(pdfPath);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      await Printing.layoutPdf(
        name: title,
        onLayout: (PdfPageFormat format) async => bytes,
      );
    } else {
      throw Exception('El archivo PDF no existe en la ruta especificada.');
    }
  }
}
