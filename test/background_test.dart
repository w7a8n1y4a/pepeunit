import 'dart:io';
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/hive/background.dart';

void main() {
  group('Mosaic', () {
    test('covers the screen and keeps neighbours different', () {
      final mosaic = Mosaic(const Size(1200, 800), 20);
      expect(mosaic.count, greaterThan(100));
      for (var i = 0; i < mosaic.count; i++) {
        expect(mosaic.iconAt(i), inInclusiveRange(0, 19));
        expect(
          mosaic.angleAt(i, 12.5).abs(),
          lessThanOrEqualTo(Mosaic.maxTurn + Mosaic.rustle),
        );
        if (i + 1 < mosaic.count && (i + 1) % mosaic.columns != 0) {
          expect(mosaic.iconAt(i), isNot(mosaic.iconAt(i + 1)));
        }
        if (i + mosaic.columns < mosaic.count) {
          expect(mosaic.iconAt(i), isNot(mosaic.iconAt(i + mosaic.columns)));
        }
      }
    });

    test('is the same for the same size', () {
      final a = Mosaic(const Size(640, 480), 12);
      final b = Mosaic(const Size(640, 480), 12);
      expect([for (var i = 0; i < a.count; i++) a.iconAt(i)], [
        for (var i = 0; i < b.count; i++) b.iconAt(i),
      ]);
    });

    test('keeps the same few tiles flipping all the time', () {
      final mosaic = Mosaic(const Size(800, 600), 20);
      final before = [for (var i = 0; i < mosaic.count; i++) mosaic.iconAt(i)];
      var least = 99;
      var most = 0;
      for (var t = 0.0; t < 60; t += 0.033) {
        mosaic.advance(t);
        if (t < 2) continue;
        final now = mosaic.flipping.length;
        least = least < now ? least : now;
        most = most > now ? most : now;
      }
      expect(least, greaterThanOrEqualTo(Mosaic.flipsTogether - 1));
      expect(most, lessThanOrEqualTo(Mosaic.flipsTogether + 1));
      final after = [for (var i = 0; i < mosaic.count; i++) mosaic.iconAt(i)];
      expect(after, isNot(before));
      for (final i in mosaic.flipping) {
        expect(mosaic.flipAt(i), inInclusiveRange(0, 1));
        expect(mosaic.nextIconAt(i), isNot(mosaic.iconAt(i)));
      }
    });

    test('is empty without pictures or room', () {
      expect(Mosaic(const Size(800, 600), 0).count, 0);
      expect(Mosaic(Size.zero, 5).count, 0);
      Mosaic(Size.zero, 5).advance(10);
    });
  });

  test('every icon path in the code is a file', () {
    final path = RegExp(r'assets/icons/[\w/]+\.svg');
    final bare = RegExp(
      r"'((?:actions|objects|sections|services|status)/\w+\.svg)'",
    );
    final missing = <String>[];
    for (final file in Directory('lib').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      final text = file.readAsStringSync();
      for (final match in path.allMatches(text)) {
        if (!File(match.group(0)!).existsSync()) missing.add(match.group(0)!);
      }
      for (final match in bare.allMatches(text)) {
        if (!File('assets/icons/${match.group(1)}').existsSync()) {
          missing.add(match.group(1)!);
        }
      }
    }
    expect(missing, isEmpty);
  });

  test('every icon folder is listed in pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final folders = [
      for (final root in ['assets/icons', 'assets/background'])
        for (final entry in Directory(root).listSync())
          if (entry is Directory) '${entry.path}/',
    ];
    expect(folders, isNotEmpty);
    for (final folder in folders) {
      expect(pubspec, contains('- $folder\n'), reason: folder);
    }
  });
}
