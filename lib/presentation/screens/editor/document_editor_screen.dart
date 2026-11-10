import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../../data/models/scanned_document.dart';
import '../../../data/models/scanned_page.dart';
import '../../../data/services/scanner_service.dart';
import '../../../data/services/storage_service.dart';
import '../../widgets/export_dialog.dart';
import 'page_editor_screen.dart';

class DocumentEditorScreen extends StatefulWidget {
  final ScannedDocument document;

  const DocumentEditorScreen({super.key, required this.document});

  @override
  State<DocumentEditorScreen> createState() => _DocumentEditorScreenState();
}

class _DocumentEditorScreenState extends State<DocumentEditorScreen> {
  late ScannedDocument _document;
  final ScannerService _scannerService = ScannerService();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _document = widget.document;
  }

  Future<void> _updateAndSave(ScannedDocument newDoc) async {
    setState(() {
      _document = newDoc;
    });
    if (!mounted) return;
    final storageService = context.read<StorageService>();
    await storageService.updateDocument(newDoc);
  }

  Future<void> _openPageEditor(int index) async {
    final currentPage = _document.pages[index];
    final updatedPage = await Navigator.of(context).push<ScannedPage>(
      MaterialPageRoute(
        builder: (_) => PageEditorScreen(
          page: currentPage,
          pageNumber: index + 1,
        ),
      ),
    );

    if (updatedPage != null && mounted) {
      // Limpiar caché de la imagen por si la ruta se reutilizó
      FileImage(File(updatedPage.imagePath)).evict();
      final pages = List<ScannedPage>.from(_document.pages);
      pages[index] = updatedPage;
      await _updateAndSave(_document.copyWith(pages: pages));
    }
  }

  void _deletePage(int index) {
    if (_document.pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El documento debe contener al menos una página.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar página?'),
        content: Text('Se eliminará la página ${index + 1} de este documento.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              final pages = List<ScannedPage>.from(_document.pages)..removeAt(index);
              _updateAndSave(_document.copyWith(pages: pages));
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _addPagesFromGallery() async {
    try {
      final imagePaths = await _scannerService.pickImagesFromGallery();
      if (imagePaths.isEmpty) return;

      if (!mounted) return;
      setState(() => _isSaving = true);
      final storage = context.read<StorageService>();
      final newPages = List<ScannedPage>.from(_document.pages);

      for (final rawPath in imagePaths) {
        final persistedPath = await storage.persistImage(rawPath, _document.id);
        newPages.add(
          ScannedPage(
            id: const Uuid().v4(),
            imagePath: persistedPath,
            originalImagePath: persistedPath,
          ),
        );
      }

      await _updateAndSave(_document.copyWith(pages: newPages));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error importando imágenes: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showScanErrorSnackBar(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    final String message = (errorStr.contains('cancel') || errorStr.contains('canell'))
        ? 'Error en el escaneo, operacion cancelada'
        : 'Error en el escaneo: $error';

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 13),
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        dismissDirection: DismissDirection.horizontal,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: '✕',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _addPagesFromScanner() async {
    try {
      final result = await _scannerService.scanWithMlKit();
      if (result == null || result.images.isEmpty) return;

      if (!mounted) return;
      setState(() => _isSaving = true);
      final storage = context.read<StorageService>();
      final newPages = List<ScannedPage>.from(_document.pages);

      for (final rawPath in result.images) {
        final persistedPath = await storage.persistImage(rawPath, _document.id);
        newPages.add(
          ScannedPage(
            id: const Uuid().v4(),
            imagePath: persistedPath,
            originalImagePath: persistedPath,
          ),
        );
      }

      await _updateAndSave(_document.copyWith(pages: newPages));
    } catch (e) {
      if (mounted) {
        _showScanErrorSnackBar(e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showRenameDialog() {
    final controller = TextEditingController(text: _document.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renombrar Documento'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Título del documento',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                _updateAndSave(_document.copyWith(title: newTitle));
              }
              Navigator.of(ctx).pop();
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _openExportDialog() {
    showDialog(
      context: context,
      builder: (ctx) => ExportDialog(
        document: _document,
        onDocumentUpdated: (updated) {
          _updateAndSave(updated);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: _showRenameDialog,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    _document.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.edit_outlined, size: 18, color: theme.colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(128),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          '${_document.pageCount} ${_document.pageCount == 1 ? "página" : "páginas"} • Toca "Editar" para mejorar letras o recortar',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.add_photo_alternate_outlined),
                            tooltip: 'Añadir fotos de galería',
                            onPressed: _addPagesFromGallery,
                          ),
                          IconButton(
                            icon: const Icon(Icons.camera_alt_outlined),
                            tooltip: 'Escanear más páginas',
                            onPressed: _addPagesFromScanner,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _document.pages.length,
                    onReorderItem: (oldIndex, newIndex) {
                      setState(() {
                        final pages = List<ScannedPage>.from(_document.pages);
                        final item = pages.removeAt(oldIndex);
                        pages.insert(newIndex, item);
                        _updateAndSave(_document.copyWith(pages: pages));
                      });
                    },
                    itemBuilder: (context, index) {
                      final page = _document.pages[index];
                      return Card(
                        key: ValueKey(page.id),
                        margin: const EdgeInsets.only(bottom: 12),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: () => _openPageEditor(index),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                // Handle de reordenación
                                ReorderableDragStartListener(
                                  index: index,
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 6),
                                    child: Icon(Icons.drag_indicator, color: Colors.grey),
                                  ),
                                ),

                                // Miniatura rotada
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 68,
                                    height: 88,
                                    color: Colors.black12,
                                    child: RotatedBox(
                                      quarterTurns: ((page.rotationAngle + 45) ~/ 90) % 4,
                                      child: Transform.rotate(
                                        angle: (page.rotationAngle - (((page.rotationAngle + 45) ~/ 90) % 4) * 90) *
                                            3.141592653589793 /
                                            180.0,
                                        child: Image.file(
                                          File(page.imagePath),
                                          key: ValueKey('${page.imagePath}_${page.filter.name}_${page.contrastLevel}_${page.rotationAngle}'),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) =>
                                              const Icon(
                                            Icons.broken_image,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Info de página y etiquetas de edición
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Página ${index + 1}',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Filtro: ${page.filter.label}',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: page.filter != PageFilter.original
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurfaceVariant,
                                          fontWeight: page.filter != PageFilter.original
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      ),
                                      if (page.rotationAngle != 0 || page.isCropped) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          [
                                            if (page.rotationAngle != 0)
                                              'Giro: ${page.rotationAngle}°',
                                            if (page.isCropped) 'Recortada',
                                          ].join(' • '),
                                          style: theme.textTheme.labelSmall?.copyWith(
                                            color: theme.colorScheme.secondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                // Botón para entrar a inspeccionar y editar la página (solo icono de ajustes)
                                IconButton.filledTonal(
                                  onPressed: () => _openPageEditor(index),
                                  icon: const Icon(Icons.tune, size: 20),
                                  tooltip: 'Ajustes de página',
                                ),

                                const SizedBox(width: 4),

                                // Única opción externa: Borrar página
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Eliminar página',
                                  onPressed: () => _deletePage(index),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: FilledButton.icon(
            onPressed: _openExportDialog,
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Exportar a PDF'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ),
      ),
    );
  }
}
