import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/hive/hex_scene.dart';

void main() {
  const a = Color(0xFF2BD9C3);
  const b = Color(0xFFFF7A59);

  int count(List<Color> rim, Color color) =>
      rim.where((item) => item == color).length;

  test('the border is 6 sides of 8 segments', () {
    expect(hexRimSegments, 48);
  });

  test('equal weights alternate segment by segment, first color first', () {
    final rim = rimMix([(a, 1), (b, 1)])!;
    expect(rim.length, 48);
    expect(count(rim, a), 24);
    for (var i = 0; i < 48; i++) {
      expect(rim[i], i.isEven ? a : b);
    }
  });

  test('uneven weights spread evenly', () {
    final rim = rimMix([(a, 3), (b, 1)])!;
    expect(count(rim, a), 36);
    expect(count(rim, b), 12);
    // No two of the rarer color touch.
    for (var i = 0; i < 48; i++) {
      expect(rim[i] == b && rim[(i + 1) % 48] == b, isFalse);
    }
  });

  test('a present color keeps at least one segment', () {
    final rim = rimMix([(a, 1000), (b, 1)])!;
    expect(rim.length, 48);
    expect(count(rim, b), 1);
  });

  test('uneven weights still fill all 48 segments', () {
    for (var x = 1; x < 20; x++) {
      for (var y = 1; y < 20; y++) {
        expect(rimMix([(a, x), (b, y)])!.length, 48);
      }
    }
  });

  test('one color fills the border and zero weights give none', () {
    expect(count(rimMix([(a, 3), (b, 0)])!, a), 48);
    expect(rimMix([(a, 0), (b, 0)]), isNull);
  });
}
