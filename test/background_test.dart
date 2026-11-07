import 'dart:io';
import 'dart:math';
import 'dart:ui' show Offset, Size;

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
        for (final j in mosaic.neighbours(i)) {
          expect(mosaic.iconAt(i), isNot(mosaic.iconAt(j)));
        }
      }
    });

    test('covers every corner of the screen', () {
      const size = Size(1200, 800);
      final mosaic = Mosaic(size, 20);
      for (final corner in const [
        Offset(0, 0),
        Offset(1200, 0),
        Offset(0, 800),
        Offset(1200, 800),
      ]) {
        var near = double.infinity;
        for (var i = 0; i < mosaic.count; i++) {
          near = min(
            near,
            (Offset(mosaic.xAt(i), mosaic.yAt(i)) - corner).distance,
          );
        }
        expect(near, lessThan(mosaic.pitch));
      }
    });

    test('stands on a grid turned 30° from the horizontal', () {
      final mosaic = Mosaic(const Size(1200, 800), 20);
      // A triangular grid repeats every 60°, so the turn of its rows shows
      // as the phase of the angle between touching tiles: cos(6a) is 1 for
      // rows along the horizontal and -1 for rows at 30°.
      var sum = 0.0;
      var pairs = 0;
      for (var i = 0; i < mosaic.count; i++) {
        for (final j in mosaic.neighbours(i)) {
          final a = atan2(
            mosaic.yAt(j) - mosaic.yAt(i),
            mosaic.xAt(j) - mosaic.xAt(i),
          );
          sum += cos(6 * a);
          pairs++;
        }
      }
      expect(sum / pairs, lessThan(-0.2));
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
