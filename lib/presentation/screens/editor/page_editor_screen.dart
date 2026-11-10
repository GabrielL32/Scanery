import 'dart:io';
import 'package:flutter/material.dart';
import '../../../data/models/scanned_page.dart';
import '../../../data/services/image_processing_service.dart';

enum _EditorTab {
  filters,
  crop,
  rotate,
}

class PageEditorScreen extends StatefulWidget {
  final ScannedPage page;
  final int pageNumber;

  const PageEditorScreen({
    super.key,
    required this.page,
    required this.pageNumber,
  });

  @override
  State<PageEditorScreen> createState() => _PageEditorScreenState();
}

class _PageEditorScreenState extends State<PageEditorScreen> {
  final ImageProcessingService _processingService = ImageProcessingService();

  late PageFilter _selectedFilter;
  late double _contrastLevel;
  late int _rotationAngle;
  late double _cropLeft;
  late double _cropTop;
  late double _cropRight;
  late double _cropBottom;

  _EditorTab _currentTab = _EditorTab.filters;
  bool _isComparingOriginal = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.page.filter;
    _contrastLevel = widget.page.contrastLevel;
    _rotationAngle = widget.page.rotationAngle;
    _cropLeft = widget.page.cropLeft;
    _cropTop = widget.page.cropTop;
    _cropRight = widget.page.cropRight;
    _cropBottom = widget.page.cropBottom;
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final newImagePath = await _processingService.applyEditsToPage(
        page: widget.page,
        filter: _selectedFilter,
        contrastLevel: _contrastLevel,
        cropLeft: _cropLeft,
        cropTop: _cropTop,
        cropRight: _cropRight,
        cropBottom: _cropBottom,
      );

      final updatedPage = widget.page.copyWith(
        imagePath: newImagePath,
        rotationAngle: _rotationAngle,
        filter: _selectedFilter,
        contrastLevel: _contrastLevel,
        cropLeft: _cropLeft,
        cropTop: _cropTop,
        cropRight: _cropRight,
        cropBottom: _cropBottom,
      );

      if (mounted) {
        Navigator.of(context).pop(updatedPage);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar la página: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  void _resetAll() {
    setState(() {
      _selectedFilter = PageFilter.original;
      _contrastLevel = 1.0;
      _rotationAngle = 0;
      _cropLeft = 0.0;
      _cropTop = 0.0;
      _cropRight = 1.0;
      _cropBottom = 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeFilter = _isComparingOriginal
        ? PageFilter.original
        : _selectedFilter;
    final activeContrast = _isComparingOriginal ? 1.0 : _contrastLevel;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          'Página ${widget.pageNumber}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          // Botón para mantener presionado y comparar con el original
          GestureDetector(
            onTapDown: (_) => setState(() => _isComparingOriginal = true),
            onTapUp: (_) => setState(() => _isComparingOriginal = false),
            onTapCancel: () => setState(() => _isComparingOriginal = false),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _isComparingOriginal
                    ? theme.colorScheme.primary
                    : Colors.white12,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.compare, size: 18, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Original',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Restablecer todo',
            onPressed: _isSaving ? null : _resetAll,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, left: 4),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveChanges,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check, size: 18),
              label: Text(_isSaving ? 'Guardando' : 'Guardar'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Banner informativo superior
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
            color: Colors.white10,
            child: Text(
              _currentTab == _EditorTab.crop
                  ? 'Arrastra las esquinas azules para recortar los bordes de la página'
                  : 'Pellizca con dos dedos para hacer zoom y revisar la nitidez de las letras',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),

          // Área principal del visor / editor
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _currentTab == _EditorTab.crop
                  ? _buildCropCanvas(activeFilter, activeContrast)
                  : _buildZoomablePreview(activeFilter, activeContrast),
            ),
          ),

          // Panel inferior de controles según la pestaña activa
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 12,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  _buildActiveTabControls(theme),
                  const Divider(height: 1),
                  _buildBottomTabSelector(theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Visor con zoom para inspeccionar las letras y el contraste
  Widget _buildZoomablePreview(PageFilter filter, double contrast) {
    final int quarterTurns = ((_rotationAngle + 45) ~/ 90) % 4;
    final double remainderDegrees = (_rotationAngle - quarterTurns * 90).toDouble();

    return InteractiveViewer(
      minScale: 0.8,
      maxScale: 5.0,
      child: Center(
        child: RotatedBox(
          quarterTurns: quarterTurns,
          child: Transform.rotate(
            angle: remainderDegrees * 3.141592653589793 / 180.0,
            child: ClipRect(
              clipper: _NormalizedCropClipper(
                left: _cropLeft,
                top: _cropTop,
                right: _cropRight,
                bottom: _cropBottom,
              ),
              child: ColorFiltered(
                colorFilter: ImageProcessingService.getColorFilter(filter, contrast),
                child: Image.file(
                  File(widget.page.originalImagePath),
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Lienzo interactivo para recortar la página con esquinas arrastrables
  Widget _buildCropCanvas(PageFilter filter, double contrast) {
    final int quarterTurns = ((_rotationAngle + 45) ~/ 90) % 4;
    final double remainderDegrees = (_rotationAngle - quarterTurns * 90).toDouble();

    return Center(
      child: RotatedBox(
        quarterTurns: quarterTurns,
        child: Transform.rotate(
          angle: remainderDegrees * 3.141592653589793 / 180.0,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ColorFiltered(
                colorFilter: ImageProcessingService.getColorFilter(filter, contrast),
                child: Image.file(
                  File(widget.page.originalImagePath),
                  fit: BoxFit.contain,
                ),
              ),
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final height = constraints.maxHeight;
                    if (width <= 0 || height <= 0) return const SizedBox.shrink();

                    return _CropOverlay(
                      width: width,
                      height: height,
                      cropLeft: _cropLeft,
                      cropTop: _cropTop,
                      cropRight: _cropRight,
                      cropBottom: _cropBottom,
                      onCropChanged: (l, t, r, b) {
                        setState(() {
                          _cropLeft = l;
                          _cropTop = t;
                          _cropRight = r;
                          _cropBottom = b;
                        });
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabControls(ThemeData theme) {
    switch (_currentTab) {
      case _EditorTab.filters:
        return _buildFiltersPanel(theme);
      case _EditorTab.crop:
        return _buildCropPanel(theme);
      case _EditorTab.rotate:
        return _buildRotatePanel(theme);
    }
  }

  Widget _buildFiltersPanel(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Lista horizontal de preajustes de filtro
          SizedBox(
            height: 108,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: PageFilter.values.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final filter = PageFilter.values[index];
                final isSelected = filter == _selectedFilter;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 86,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest.withAlpha(120),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: ColorFiltered(
                              colorFilter: ImageProcessingService.getColorFilter(
                                filter,
                                _contrastLevel,
                              ),
                              child: Image.file(
                                File(widget.page.originalImagePath),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                cacheWidth: 160,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          filter.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),

          // Control deslizante de nitidez / contraste de letras
          Row(
            children: [
              Icon(
                Icons.contrast,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Contraste de letras:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _contrastLevel,
                  min: 0.7,
                  max: 2.0,
                  divisions: 26,
                  label: '${(_contrastLevel * 100).round()}%',
                  onChanged: (value) {
                    setState(() {
                      _contrastLevel = value;
                    });
                  },
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() => _contrastLevel = 1.0);
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text('${(_contrastLevel * 100).round()}%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCropPanel(ThemeData theme) {
    final widthPct = ((_cropRight - _cropLeft) * 100).round();
    final heightPct = ((_cropBottom - _cropTop) * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Área seleccionada: $widthPct% ancho × $heightPct% alto',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _cropLeft = 0.0;
                    _cropTop = 0.0;
                    _cropRight = 1.0;
                    _cropBottom = 1.0;
                  });
                },
                icon: const Icon(Icons.crop_free, size: 18),
                label: const Text('Página completa'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _cropLeft = 0.05;
                    _cropTop = 0.05;
                    _cropRight = 0.95;
                    _cropBottom = 0.95;
                  });
                },
                icon: const Icon(Icons.crop_din, size: 18),
                label: const Text('Quitar bordes (5%)'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _cropLeft = 0.10;
                    _cropTop = 0.10;
                    _cropRight = 0.90;
                    _cropBottom = 0.90;
                  });
                },
                icon: const Icon(Icons.crop, size: 18),
                label: const Text('Margen 10%'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRotatePanel(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.rotate_right, size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Rotar:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_rotationAngle°',
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _rotationAngle.toDouble(),
            min: 0,
            max: 360,
            divisions: 360,
            label: '$_rotationAngle°',
            onChanged: (val) {
              setState(() {
                _rotationAngle = val.round() % 360;
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    setState(() {
                      _rotationAngle = (_rotationAngle + 90) % 360;
                    });
                  },
                  icon: const Icon(Icons.rotate_90_degrees_cw_outlined),
                  label: const Text('Rotar 90°'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _rotationAngle = 0;
                    });
                  },
                  icon: const Icon(Icons.restore),
                  label: const Text('Original'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomTabSelector(ThemeData theme) {
    return NavigationBar(
      height: 64,
      selectedIndex: _currentTab.index,
      onDestinationSelected: (index) {
        setState(() {
          _currentTab = _EditorTab.values[index];
        });
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.auto_fix_high_outlined),
          selectedIcon: Icon(Icons.auto_fix_high),
          label: 'Filtros y Letras',
        ),
        NavigationDestination(
          icon: Icon(Icons.crop_outlined),
          selectedIcon: Icon(Icons.crop),
          label: 'Recortar',
        ),
        NavigationDestination(
          icon: Icon(Icons.rotate_90_degrees_ccw_outlined),
          selectedIcon: Icon(Icons.rotate_90_degrees_ccw),
          label: 'Girar',
        ),
      ],
    );
  }
}

class _NormalizedCropClipper extends CustomClipper<Rect> {
  final double left;
  final double top;
  final double right;
  final double bottom;

  _NormalizedCropClipper({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      size.width * left,
      size.height * top,
      size.width * right,
      size.height * bottom,
    );
  }

  @override
  bool shouldReclip(covariant _NormalizedCropClipper oldClipper) {
    return oldClipper.left != left ||
        oldClipper.top != top ||
        oldClipper.right != right ||
        oldClipper.bottom != bottom;
  }
}

class _CropOverlay extends StatelessWidget {
  final double width;
  final double height;
  final double cropLeft;
  final double cropTop;
  final double cropRight;
  final double cropBottom;
  final void Function(double l, double t, double r, double b) onCropChanged;

  const _CropOverlay({
    required this.width,
    required this.height,
    required this.cropLeft,
    required this.cropTop,
    required this.cropRight,
    required this.cropBottom,
    required this.onCropChanged,
  });

  static const double _minCropFraction = 0.12;
  static const double _handleSize = 32.0;

  @override
  Widget build(BuildContext context) {
    final leftPx = cropLeft * width;
    final topPx = cropTop * height;
    final rightPx = cropRight * width;
    final bottomPx = cropBottom * height;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Sombreado exterior y cuadrícula
        Positioned.fill(
          child: CustomPaint(
            painter: _CropMaskPainter(
              cropRect: Rect.fromLTRB(leftPx, topPx, rightPx, bottomPx),
            ),
          ),
        ),

        // Área central arrastrable para mover todo el recorte
        Positioned(
          left: leftPx,
          top: topPx,
          width: (rightPx - leftPx).clamp(1.0, width),
          height: (bottomPx - topPx).clamp(1.0, height),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanUpdate: (details) {
              final dx = details.delta.dx / width;
              final dy = details.delta.dy / height;
              final w = cropRight - cropLeft;
              final h = cropBottom - cropTop;

              final newLeft = (cropLeft + dx).clamp(0.0, 1.0 - w);
              final newTop = (cropTop + dy).clamp(0.0, 1.0 - h);
              onCropChanged(newLeft, newTop, newLeft + w, newTop + h);
            },
          ),
        ),

        // Esquina Superior Izquierda
        _buildCornerHandle(
          x: leftPx,
          y: topPx,
          onDrag: (dx, dy) {
            final newLeft = (cropLeft + dx / width).clamp(0.0, cropRight - _minCropFraction);
            final newTop = (cropTop + dy / height).clamp(0.0, cropBottom - _minCropFraction);
            onCropChanged(newLeft, newTop, cropRight, cropBottom);
          },
        ),

        // Esquina Superior Derecha
        _buildCornerHandle(
          x: rightPx,
          y: topPx,
          onDrag: (dx, dy) {
            final newRight = (cropRight + dx / width).clamp(cropLeft + _minCropFraction, 1.0);
            final newTop = (cropTop + dy / height).clamp(0.0, cropBottom - _minCropFraction);
            onCropChanged(cropLeft, newTop, newRight, cropBottom);
          },
        ),

        // Esquina Inferior Izquierda
        _buildCornerHandle(
          x: leftPx,
          y: bottomPx,
          onDrag: (dx, dy) {
            final newLeft = (cropLeft + dx / width).clamp(0.0, cropRight - _minCropFraction);
            final newBottom = (cropBottom + dy / height).clamp(cropTop + _minCropFraction, 1.0);
            onCropChanged(newLeft, cropTop, cropRight, newBottom);
          },
        ),

        // Esquina Inferior Derecha
        _buildCornerHandle(
          x: rightPx,
          y: bottomPx,
          onDrag: (dx, dy) {
            final newRight = (cropRight + dx / width).clamp(cropLeft + _minCropFraction, 1.0);
            final newBottom = (cropBottom + dy / height).clamp(cropTop + _minCropFraction, 1.0);
            onCropChanged(cropLeft, cropTop, newRight, newBottom);
          },
        ),
      ],
    );
  }

  Widget _buildCornerHandle({
    required double x,
    required double y,
    required void Function(double dx, double dy) onDrag,
  }) {
    return Positioned(
      left: x - _handleSize / 2,
      top: y - _handleSize / 2,
      width: _handleSize,
      height: _handleSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: (details) => onDrag(details.delta.dx, details.delta.dy),
        child: Center(
          child: Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CropMaskPainter extends CustomPainter {
  final Rect cropRect;

  _CropMaskPainter({required this.cropRect});

  @override
  void paint(Canvas canvas, Size size) {
    final fullRect = Offset.zero & size;
    final maskPaint = Paint()..color = Colors.black.withAlpha(150);

    // Pintar máscara exterior
    final path = Path()
      ..addRect(fullRect)
      ..addRect(cropRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, maskPaint);

    // Borde del área de recorte
    final borderPaint = Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(cropRect, borderPaint);

    // Líneas de tercios
    final gridPaint = Paint()
      ..color = Colors.white.withAlpha(110)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final thirdW = cropRect.width / 3;
    final thirdH = cropRect.height / 3;

    for (int i = 1; i <= 2; i++) {
      canvas.drawLine(
        Offset(cropRect.left + thirdW * i, cropRect.top),
        Offset(cropRect.left + thirdW * i, cropRect.bottom),
        gridPaint,
      );
      canvas.drawLine(
        Offset(cropRect.left, cropRect.top + thirdH * i),
        Offset(cropRect.right, cropRect.top + thirdH * i),
        gridPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CropMaskPainter oldDelegate) {
    return oldDelegate.cropRect != cropRect;
  }
}

