enum PageFilter {
  original('Original', 'Imagen sin cambios'),
  highContrastText('Texto Nítido', 'Mayor contraste para letras claras'),
  blackAndWhite('Blanco y Negro', 'Escala de grises de alto contraste'),
  darkInk('Tinta Fuerte', 'Blanquea el papel y oscurece letras tenues'),
  extraDarkLetters('Letras Extra Oscuras', 'Máximo realce para trazos muy débiles'),
  magicColor('Color Intenso', 'Realza texto, sellos y firmas a color');

  final String label;
  final String description;
  const PageFilter(this.label, this.description);

  static PageFilter fromName(String? name) {
    if (name == null) return PageFilter.original;
    return PageFilter.values.firstWhere(
      (f) => f.name == name,
      orElse: () => PageFilter.original,
    );
  }
}

class ScannedPage {
  final String id;
  final String imagePath;
  final String originalImagePath;
  final int rotationAngle; // 0, 90, 180, 270
  final PageFilter filter;
  final double contrastLevel; // 0.8 a 2.2 (1.0 por defecto)
  final double cropLeft; // 0.0 a 1.0
  final double cropTop; // 0.0 a 1.0
  final double cropRight; // 0.0 a 1.0
  final double cropBottom; // 0.0 a 1.0

  ScannedPage({
    required this.id,
    required this.imagePath,
    String? originalImagePath,
    this.rotationAngle = 0,
    this.filter = PageFilter.original,
    this.contrastLevel = 1.0,
    this.cropLeft = 0.0,
    this.cropTop = 0.0,
    this.cropRight = 1.0,
    this.cropBottom = 1.0,
  }) : originalImagePath = originalImagePath ?? imagePath;

  bool get isCropped =>
      cropLeft > 0.005 ||
      cropTop > 0.005 ||
      cropRight < 0.995 ||
      cropBottom < 0.995;

  bool get hasEdits =>
      rotationAngle != 0 ||
      filter != PageFilter.original ||
      (contrastLevel - 1.0).abs() > 0.05 ||
      isCropped;

  ScannedPage copyWith({
    String? id,
    String? imagePath,
    String? originalImagePath,
    int? rotationAngle,
    PageFilter? filter,
    double? contrastLevel,
    double? cropLeft,
    double? cropTop,
    double? cropRight,
    double? cropBottom,
  }) {
    return ScannedPage(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      originalImagePath: originalImagePath ?? this.originalImagePath,
      rotationAngle: rotationAngle ?? this.rotationAngle,
      filter: filter ?? this.filter,
      contrastLevel: contrastLevel ?? this.contrastLevel,
      cropLeft: cropLeft ?? this.cropLeft,
      cropTop: cropTop ?? this.cropTop,
      cropRight: cropRight ?? this.cropRight,
      cropBottom: cropBottom ?? this.cropBottom,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'originalImagePath': originalImagePath,
      'rotationAngle': rotationAngle,
      'filter': filter.name,
      'contrastLevel': contrastLevel,
      'cropLeft': cropLeft,
      'cropTop': cropTop,
      'cropRight': cropRight,
      'cropBottom': cropBottom,
    };
  }

  factory ScannedPage.fromJson(Map<String, dynamic> json) {
    final imgPath = json['imagePath'] as String;
    return ScannedPage(
      id: json['id'] as String,
      imagePath: imgPath,
      originalImagePath: (json['originalImagePath'] as String?) ?? imgPath,
      rotationAngle: (json['rotationAngle'] as num?)?.toInt() ?? 0,
      filter: PageFilter.fromName(json['filter'] as String?),
      contrastLevel: (json['contrastLevel'] as num?)?.toDouble() ?? 1.0,
      cropLeft: (json['cropLeft'] as num?)?.toDouble() ?? 0.0,
      cropTop: (json['cropTop'] as num?)?.toDouble() ?? 0.0,
      cropRight: (json['cropRight'] as num?)?.toDouble() ?? 1.0,
      cropBottom: (json['cropBottom'] as num?)?.toDouble() ?? 1.0,
    );
  }
}
