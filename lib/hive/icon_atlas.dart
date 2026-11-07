import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Where the background mosaic takes its pictures from: every SVG under
/// it. Only the themed catalog drawn for the mosaic; interface icons stay out.
const backgroundIconRoots = ['assets/background/'];

/// Every icon of the background in one raster, so the whole mosaic is one
/// draw call. Each cell holds a white mask: the shape of the icon, with the
/// brightness of the source as its opacity. A dark fill inside an icon stays
/// a hole, and the color is set when the mask is drawn.
class IconAtlas {
  IconAtlas._(this.image, this.count, this.columns, this.rawRects);

  /// Side of one cell, in pixels.
  static const cell = 96.0;
  static const _pad = 6.0;

  /// Mean side of the ink box, in pixels of one cell, the same for every icon.
  static const _inkSide = 72.0;

  /// Opacity, out of 255, from which a pixel counts as ink.
  static const _inkAlpha = 40;

  static const _toMask = ui.ColorFilter.matrix(<double>[
    0, 0, 0, 0, 255, //
    0, 0, 0, 0, 255,
    0, 0, 0, 0, 255,
    0.45, 0.55, 0.35, 0, 0,
  ]);

  final ui.Image image;
  final int count;
  final int columns;

  /// Left, top, right, bottom of each cell, four numbers per icon.
  final Float32List rawRects;

  /// Null when no icon could be read.
  static Future<IconAtlas?> load(AssetBundle bundle) async {
    final manifest = await AssetManifest.loadFromAssetBundle(bundle);
    final assets = [
      for (final asset in manifest.listAssets())
        if (asset.endsWith('.svg') && backgroundIconRoots.any(asset.startsWith))
          asset,
    ]..sort();
    final pictures = <PictureInfo>[];
    for (final asset in assets) {
      try {
        final info = await vg.loadPicture(
          SvgAssetLoader(asset, assetBundle: bundle),
          null,
        );
        if (info.size.isEmpty) {
          info.picture.dispose();
          continue;
        }
        pictures.add(info);
      } catch (_) {
        // A file that does not parse is only missing from the mosaic.
      }
    }
    if (pictures.isEmpty) return null;

    final count = pictures.length;
    final columns = sqrt(count).ceil();
    final rows = (count / columns).ceil();

    // First fit each file by its view box, then measure the ink that really
    // landed in each cell and fit again by the ink. Files draw with different
    // margins, and the mosaic should show every picture the same size.
    final boxed = [
      for (final info in pictures)
        () {
          final fit =
              (cell - _pad * 2) / max(info.size.width, info.size.height);
          return _Place(
            fit,
            (cell - info.size.width * fit) / 2,
            (cell - info.size.height * fit) / 2,
          );
        }(),
    ];
    var image = await _raster(pictures, boxed, columns, rows);
    final data = await image.toByteData();
    if (data != null) {
      final width = columns * cell.toInt();
      final fitted = <_Place>[
        for (var i = 0; i < count; i++)
          _byInk(boxed[i], _ink(data, width, i % columns, i ~/ columns)),
      ];
      image.dispose();
      image = await _raster(pictures, fitted, columns, rows);
    }
    final rects = Float32List(count * 4);
    for (var i = 0; i < count; i++) {
      final left = (i % columns) * cell;
      final top = (i ~/ columns) * cell;
      rects[i * 4] = left;
      rects[i * 4 + 1] = top;
      rects[i * 4 + 2] = left + cell;
      rects[i * 4 + 3] = top + cell;
    }
    for (final info in pictures) {
      info.picture.dispose();
    }
    return IconAtlas._(image, count, columns, rects);
  }

  static Future<ui.Image> _raster(
    List<PictureInfo> pictures,
    List<_Place> places,
    int columns,
    int rows,
  ) async {
    final bounds = ui.Rect.fromLTWH(0, 0, columns * cell, rows * cell);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, bounds);
    canvas.saveLayer(bounds, ui.Paint()..colorFilter = _toMask);
    canvas.drawRect(bounds, ui.Paint()..color = const ui.Color(0xFF000000));
    for (var i = 0; i < pictures.length; i++) {
      final left = (i % columns) * cell;
      final top = (i ~/ columns) * cell;
      final place = places[i];
      canvas.save();
      canvas.clipRect(ui.Rect.fromLTWH(left, top, cell, cell));
      canvas.translate(left + place.dx, top + place.dy);
      canvas.scale(place.scale);
      canvas.drawPicture(pictures[i].picture);
      canvas.restore();
    }
    canvas.restore();
    final picture = recorder.endRecording();
    final image = await picture.toImage(
      bounds.width.toInt(),
      bounds.height.toInt(),
    );
    picture.dispose();
    return image;
  }

  /// The box of the visible pixels of one cell: left, top, right, bottom,
  /// right and bottom not included. Null for an empty cell.
  static (int, int, int, int)? _ink(
    ByteData data,
    int width,
    int column,
    int row,
  ) {
    final side = cell.toInt();
    var left = side;
    var top = side;
    var right = -1;
    var bottom = -1;
    for (var y = 0; y < side; y++) {
      for (var x = 0; x < side; x++) {
        final at = ((row * side + y) * width + column * side + x) * 4 + 3;
        if (data.getUint8(at) < _inkAlpha) continue;
        left = min(left, x);
        right = max(right, x);
        top = min(top, y);
        bottom = max(bottom, y);
      }
    }
    if (right < 0) return null;
    return (left, top, right + 1, bottom + 1);
  }

  /// Fits [first] again by the ink [box]. The mean side of the box,
  /// `sqrt(width * height)`, is brought to [_inkSide] so a wide or a tall
  /// picture looks as big as a square one. The longer side still stays inside
  /// the cell margin.
  static _Place _byInk(_Place first, (int, int, int, int)? box) {
    if (box == null) return first;
    final (left, top, right, bottom) = box;
    final width = (right - left).toDouble();
    final height = (bottom - top).toDouble();
    // Where the ink sits in the picture's own units.
    final x0 = (left - first.dx) / first.scale;
    final y0 = (top - first.dy) / first.scale;
    final grow = min(
      min(
        _inkSide / sqrt(width * height),
        (cell - _pad * 2) / max(width, height),
      ),
      2.5,
    );
    final scale = first.scale * grow;
    return _Place(
      scale,
      cell / 2 - (x0 + width / first.scale / 2) * scale,
      cell / 2 - (y0 + height / first.scale / 2) * scale,
    );
  }

  void dispose() => image.dispose();
}

/// Where a picture goes in its cell: its own units are scaled, then moved.
class _Place {
  const _Place(this.scale, this.dx, this.dy);

  final double scale;
  final double dx;
  final double dy;
}
