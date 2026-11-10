import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scanery/core/theme/theme_provider.dart';
import 'package:scanery/data/models/scanned_document.dart';
import 'package:scanery/data/models/scanned_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ScannedDocument and ScannedPage Models', () {
    test('Should serialize and deserialize ScannedDocument correctly', () {
      final now = DateTime.now();
      final page1 = ScannedPage(
        id: 'p1',
        imagePath: '/mock/path/p1.jpg',
        rotationAngle: 90,
      );
      final page2 = ScannedPage(
        id: 'p2',
        imagePath: '/mock/path/p2.jpg',
        rotationAngle: 0,
      );

      final doc = ScannedDocument(
        id: 'doc1',
        title: 'Mi Documento',
        createdAt: now,
        pages: [page1, page2],
        pdfPath: '/mock/path/doc.pdf',
        fileSizeBytes: 2048,
      );

      expect(doc.pageCount, 2);
      expect(doc.thumbnailPath, '/mock/path/p1.jpg');

      final json = doc.toJson();
      final fromJson = ScannedDocument.fromJson(json);

      expect(fromJson.id, 'doc1');
      expect(fromJson.title, 'Mi Documento');
      expect(fromJson.pageCount, 2);
      expect(fromJson.pages[0].rotationAngle, 90);
      expect(fromJson.pages[1].rotationAngle, 0);
      expect(fromJson.pdfPath, '/mock/path/doc.pdf');
      expect(fromJson.fileSizeBytes, 2048);
    });

    test('Page rotation angles should cycle correctly', () {
      final page = ScannedPage(id: 'p1', imagePath: '/path.jpg');
      expect(page.rotationAngle, 0);

      final rotated90 = page.copyWith(
        rotationAngle: (page.rotationAngle + 90) % 360,
      );
      expect(rotated90.rotationAngle, 90);

      final rotated180 = rotated90.copyWith(
        rotationAngle: (rotated90.rotationAngle + 90) % 360,
      );
      expect(rotated180.rotationAngle, 180);

      final rotated360 = rotated180
          .copyWith(rotationAngle: (180 + 90) % 360)
          .copyWith(rotationAngle: (270 + 90) % 360);
      expect(rotated360.rotationAngle, 0);
    });
  });

  group('ThemeProvider', () {
    test('Should initialize with system mode and default color', () {
      final provider = ThemeProvider();
      expect(provider.themeMode, ThemeMode.system);
    });

    test('Should change ThemeMode and notify listeners', () async {
      final provider = ThemeProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      await provider.setThemeMode(ThemeMode.dark);
      expect(provider.themeMode, ThemeMode.dark);
      expect(notified, isTrue);
    });

    test('Should change seed color and notify listeners', () async {
      final provider = ThemeProvider();
      var notified = false;
      provider.addListener(() => notified = true);

      const newColor = Color(0xFF059669);
      await provider.setSeedColor(newColor);
      expect(provider.seedColor, newColor);
      expect(notified, isTrue);
    });
  });
}
