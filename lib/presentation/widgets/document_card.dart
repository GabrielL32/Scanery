import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../data/models/scanned_document.dart';
import '../../data/services/pdf_service.dart';
import 'export_dialog.dart';

class DocumentCard extends StatelessWidget {
  final ScannedDocument document;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final Function(ScannedDocument updatedDoc) onDocumentUpdated;

  const DocumentCard({
    super.key,
    required this.document,
    required this.onTap,
    required this.onDelete,
    required this.onDocumentUpdated,
  });

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  void _openExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => ExportDialog(
        document: document,
        onDocumentUpdated: onDocumentUpdated,
      ),
    );
  }

  Future<void> _sharePdf(BuildContext context) async {
    if (document.pdfPath != null) {
      final pdfService = PdfService();
      try {
        await pdfService.sharePdf(
          document.pdfPath!,
          text: 'Documento: ${document.title}',
        );
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error compartiendo PDF: $e')),
          );
        }
      }
    } else {
      _openExportDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPdf = document.pdfPath != null;

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Miniatura
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 75,
                  height: 100,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: document.thumbnailPath != null
                      ? Image.file(
                          File(document.thumbnailPath!),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.description_outlined,
                            size: 32,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(
                          Icons.description_outlined,
                          size: 32,
                          color: Colors.grey,
                        ),
                ),
              ),

              const SizedBox(width: 14),

              // Detalles del documento
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(document.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${document.pageCount} ${document.pageCount == 1 ? "pág" : "págs"}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (hasPdf) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withAlpha(40),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.green.withAlpha(100)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.picture_as_pdf, size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  document.fileSizeBytes != null
                                      ? _formatFileSize(document.fileSizeBytes!)
                                      : 'PDF',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.green.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Menú de opciones
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'export':
                      _openExportDialog(context);
                      break;
                    case 'share':
                      _sharePdf(context);
                      break;
                    case 'edit':
                      onTap();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.picture_as_pdf_outlined),
                        SizedBox(width: 8),
                        Text('Generar / Ver PDF'),
                      ],
                    ),
                  ),
                  if (hasPdf)
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined),
                          SizedBox(width: 8),
                          Text('Compartir PDF'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: 8),
                        Text('Editar Páginas'),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.redAccent),
                        SizedBox(width: 8),
                        Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

