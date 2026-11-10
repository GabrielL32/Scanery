import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final VoidCallback onScanPressed;
  final VoidCallback onGalleryPressed;

  const EmptyState({
    super.key,
    required this.onScanPressed,
    required this.onGalleryPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withAlpha(80),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.document_scanner_outlined,
                size: 72,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No hay documentos escaneados',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Escanea hojas impresas, recibos o apuntes con tu cámara o importa fotos desde la galería para crear tu primer PDF.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: onScanPressed,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Escanear con Cámara'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(220, 48),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onGalleryPressed,
              icon: const Icon(Icons.photo_library_outlined),
              label: const Text('Importar de Galería'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(220, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

