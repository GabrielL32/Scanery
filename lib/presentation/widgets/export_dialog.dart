import 'dart:io';
import 'package:flutter/material.dart';
import '../../data/models/scanned_document.dart';
import '../../data/services/pdf_service.dart';

class ExportDialog extends StatefulWidget {
  final ScannedDocument document;
  final Function(ScannedDocument updatedDoc)? onDocumentUpdated;

  const ExportDialog({
    super.key,
    required this.document,
    this.onDocumentUpdated,
  });

  @override
  State<ExportDialog> createState() => _ExportDialogState();
}

class _ExportDialogState extends State<ExportDialog> {
  final PdfService _pdfService = PdfService();
  late TextEditingController _titleController;
  PageSizeOption _selectedPageSize = PageSizeOption.a4;

  bool _isGenerating = false;
  File? _generatedPdfFile;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.document.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleGeneratePdf() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final file = await _pdfService.generatePdf(
        documentTitle: _titleController.text.trim().isEmpty
            ? 'Documento_Scanery'
            : _titleController.text.trim(),
        pages: widget.document.pages,
        pageSizeOption: _selectedPageSize,
      );

      final size = await file.length();
      final updatedDoc = widget.document.copyWith(
        title: _titleController.text.trim().isEmpty
            ? widget.document.title
            : _titleController.text.trim(),
        pdfPath: file.path,
        fileSizeBytes: size,
      );

      widget.onDocumentUpdated?.call(updatedDoc);

      setState(() {
        _generatedPdfFile = file;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generando PDF: $e';
        _isGenerating = false;
      });
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.picture_as_pdf, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Exportar a PDF'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.onErrorContainer),
                ),
              ),
            ],
            if (_generatedPdfFile == null) ...[
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del archivo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tamaño de papel:',
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              SegmentedButton<PageSizeOption>(
                segments: const [
                  ButtonSegment(
                    value: PageSizeOption.a4,
                    label: Text('A4'),
                    icon: Icon(Icons.crop_portrait),
                  ),
                  ButtonSegment(
                    value: PageSizeOption.letter,
                    label: Text('Carta'),
                    icon: Icon(Icons.crop_din),
                  ),
                ],
                selected: {_selectedPageSize},
                onSelectionChanged: (set) {
                  setState(() {
                    _selectedPageSize = set.first;
                  });
                },
              ),
              const SizedBox(height: 12),
              Text(
                'Total de páginas: ${widget.document.pageCount}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withAlpha(80),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.primaryContainer),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '¡PDF generado con éxito!',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FutureBuilder<int>(
                      future: _generatedPdfFile!.length(),
                      builder: (context, snapshot) {
                        final sizeText = snapshot.hasData
                            ? _formatFileSize(snapshot.data!)
                            : 'Calculando...';
                        return Text('Tamaño: $sizeText');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  await _pdfService.sharePdf(
                    _generatedPdfFile!.path,
                    text: 'Te comparto el documento "${widget.document.title}" generado con Scanery.',
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Compartir PDF'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () async {
                  await _pdfService.printOrOpenPdf(
                    _generatedPdfFile!.path,
                    widget.document.title,
                  );
                },
                icon: const Icon(Icons.open_in_new),
                label: const Text('Abrir / Imprimir'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        if (_generatedPdfFile == null) ...[
          TextButton(
            onPressed: _isGenerating ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: _isGenerating ? null : _handleGeneratePdf,
            icon: _isGenerating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(_isGenerating ? 'Generando...' : 'Crear PDF'),
          ),
        ] else ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ],
    );
  }
}

