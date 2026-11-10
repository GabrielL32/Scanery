import 'scanned_page.dart';

class ScannedDocument {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<ScannedPage> pages;
  final String? pdfPath;
  final int? fileSizeBytes;

  ScannedDocument({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.pages,
    this.pdfPath,
    this.fileSizeBytes,
  });

  int get pageCount => pages.length;

  String? get thumbnailPath => pages.isNotEmpty ? pages.first.imagePath : null;

  ScannedDocument copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    List<ScannedPage>? pages,
    String? pdfPath,
    int? fileSizeBytes,
  }) {
    return ScannedDocument(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      pages: pages ?? this.pages,
      pdfPath: pdfPath ?? this.pdfPath,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'pages': pages.map((p) => p.toJson()).toList(),
      'pdfPath': pdfPath,
      'fileSizeBytes': fileSizeBytes,
    };
  }

  factory ScannedDocument.fromJson(Map<String, dynamic> json) {
    return ScannedDocument(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      pages: (json['pages'] as List<dynamic>)
          .map((item) => ScannedPage.fromJson(item as Map<String, dynamic>))
          .toList(),
      pdfPath: json['pdfPath'] as String?,
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt(),
    );
  }
}

