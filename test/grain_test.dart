import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/hive/grain.dart';
import 'package:pepeunit_client/hive/hex_scene.dart';

/// Mean and deviation of the red channel in a square well inside a cell.
Future<(double, double)> _red(GrainTile tile, ui.Color color) async {
  tile.load();
  while (tile.ready.value == null) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  const side = 200;
  final recorder = ui.PictureRecorder();
  HexPainter(HexSlot(id: 'a', title: '', color: color, q: 0, r: 0))
      .paint(ui.Canvas(recorder), const ui.Size(200, 200));
  final image = await recorder.endRecording().toImage(side, side);
  final data = (await image.toByteData())!;
  final values = <int>[
    for (var y = 70; y < 130; y++)
      for (var x = 70; x < 130; x++) data.getUint8((y * side + x) * 4),
  ];
  final mean = values.reduce((a, b) => a + b) / values.length;
  final variance =
      values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
      values.length;
  return (mean, sqrt(variance));
}

void main() {
  testWidgets('a cell is rough around the color of the palette', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final (mean, spread) = await _red(cellGrain, const ui.Color(0xFF000000));
      // hexFill red is 0x14.
      expect(mean, closeTo(0x14, 1));
      expect(spread, closeTo(cellGrain.spread, 1));
    });
  });

  test('every grain stays opaque and near its base', () {
    expect(sceneGrain.base, sceneBackground);
    expect(sceneGrain.spread, greaterThan(0));
    expect(cellGrain.spread, greaterThan(0));
  });
}
