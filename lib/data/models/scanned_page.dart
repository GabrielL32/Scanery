class ScannedPage {
  final String id;
  final String imagePath;
  final int rotationAngle; // 0, 90, 180, 270

  ScannedPage({
    required this.id,
    required this.imagePath,
    this.rotationAngle = 0,
  });

  ScannedPage copyWith({
    String? id,
    String? imagePath,
    int? rotationAngle,
  }) {
    return ScannedPage(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      rotationAngle: rotationAngle ?? this.rotationAngle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'rotationAngle': rotationAngle,
    };
  }

  factory ScannedPage.fromJson(Map<String, dynamic> json) {
    return ScannedPage(
      id: json['id'] as String,
      imagePath: json['imagePath'] as String,
      rotationAngle: (json['rotationAngle'] as num?)?.toInt() ?? 0,
    );
  }
}

