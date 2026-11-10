import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/scanned_document.dart';
import '../../../data/services/scanner_service.dart';
import '../../../data/services/storage_service.dart';
import '../../widgets/document_card.dart';
import '../../widgets/empty_state.dart';
import '../editor/document_editor_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScannerService _scannerService = ScannerService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isProcessing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  Future<void> _startScanWithMlKit() async {
    setState(() => _isProcessing = true);
    try {
      final result = await _scannerService.scanWithMlKit();
      if (result != null && result.images.isNotEmpty) {
        if (!mounted) return;
        final storage = context.read<StorageService>();
        final document = await storage.createDocumentFromImages(result.images);

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DocumentEditorScreen(document: document),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showScanErrorSnackBar(e);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _importFromGallery() async {
    setState(() => _isProcessing = true);
    try {
      final images = await _scannerService.pickImagesFromGallery();
      if (images.isNotEmpty) {
        if (!mounted) return;
        final storage = context.read<StorageService>();
        final document = await storage.createDocumentFromImages(images);

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DocumentEditorScreen(document: document),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al importar imágenes: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _confirmDelete(ScannedDocument doc) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar documento?'),
        content: Text('Se eliminará "${doc.title}" y todos sus archivos asociados.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.read<StorageService>().deleteDocument(doc.id);
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final storage = context.watch<StorageService>();

    final filteredDocs = storage.documents.where((doc) {
      if (_searchQuery.isEmpty) return true;
      return doc.title.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.document_scanner,
                color: theme.colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Scanery',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ajustes',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Procesando imágenes escaneadas...'),
                ],
              ),
            )
          : !storage.isInitialized
              ? const Center(child: CircularProgressIndicator())
              : storage.documents.isEmpty
                  ? EmptyState(
                      onScanPressed: _startScanWithMlKit,
                      onGalleryPressed: _importFromGallery,
                    )
                  : Column(
                      children: [
                        // Barra de búsqueda
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                          child: SearchBar(
                            controller: _searchController,
                            hintText: 'Buscar documentos...',
                            leading: const Icon(Icons.search),
                            trailing: [
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _searchQuery = '';
                                    });
                                  },
                                ),
                            ],
                            onChanged: (val) {
                              setState(() {
                                _searchQuery = val.trim();
                              });
                            },
                          ),
                        ),

                        // Lista de documentos
                        Expanded(
                          child: filteredDocs.isEmpty
                              ? Center(
                                  child: Text(
                                    'No se encontraron documentos con "$_searchQuery"',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: filteredDocs.length,
                                  itemBuilder: (context, index) {
                                    final doc = filteredDocs[index];
                                    return DocumentCard(
                                      document: doc,
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                DocumentEditorScreen(document: doc),
                                          ),
                                        );
                                      },
                                      onDelete: () => _confirmDelete(doc),
                                      onDocumentUpdated: (updated) {
                                        context
                                            .read<StorageService>()
                                            .updateDocument(updated);
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
      floatingActionButton: storage.documents.isNotEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'fab_gallery',
                  onPressed: _importFromGallery,
                  tooltip: 'Importar de Galería',
                  child: const Icon(Icons.photo_library_outlined),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'fab_scan',
                  onPressed: _startScanWithMlKit,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Escanear'),
                ),
              ],
            )
          : null,
    );
  }
}

