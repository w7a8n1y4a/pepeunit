import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// A rough surface instead of a flat color, like a pass of sandpaper. Every
/// pixel is opaque and differs a little from its neighbour, inside a narrow
/// band around [base]: one shared shift of brightness and a smaller shift of
/// each channel, so the grain stays gray with a faint tint. The mean of the
/// tile is [base], so the surface keeps the color the palette gives it.
///
/// One small tile is made in code, once, and tiled. [texel] physical pixels
/// make one grain, on every screen density and on every scale tick.
class GrainTile {
  GrainTile(this.base, this.spread, {this.seed = 11});

  /// Side of the tile, in texels.
  static const side = 256;

  /// Physical pixels in one grain. 1 is the finest, 2 makes pairs.
  static const texel = 1;

  /// The color the grain averages to.
  final Color base;

  /// Standard deviation of one pixel from [base], in color levels of 255.
  final double spread;

  final int seed;

  /// The tile, or null until it is made. A painter that listens to this
  /// draws the grain from the frame it appears.
  final ready = ValueNotifier<ui.Image?>(null);

  var _started = false;

  /// Makes the tile once. Later calls do nothing.
  void load() {
    if (_started) return;
    _started = true;
    final rng = Random(seed);
    double bell() {
      // The sum of four uniforms is close to a bell, bounded, and cheap. Its
      // deviation is 1/sqrt(3), so it is scaled up to one.
      return (rng.nextDouble() +
              rng.nextDouble() +
              rng.nextDouble() +
              rng.nextDouble() -
              2) *
          sqrt(3);
    }

    final pixels = Uint8List(side * side * 4);
    final red = (base.r * 255).round();
    final green = (base.g * 255).round();
    final blue = (base.b * 255).round();
    int level(int center, double shared, double own) =>
        (center + shared + own).round().clamp(0, 255);
    for (var i = 0; i < side * side; i++) {
      // bell() has a deviation of one. The shared part carries most of the
      // spread, the channel part the rest: 0.87² + 0.5² = 1.
      final shared = bell() * spread * 0.87;
      final at = i * 4;
      pixels[at] = level(red, shared, bell() * spread * 0.5);
      pixels[at + 1] = level(green, shared, bell() * spread * 0.5);
      pixels[at + 2] = level(blue, shared, bell() * spread * 0.5);
      pixels[at + 3] = 255;
    }
    ui.decodeImageFromPixels(pixels, side, side, ui.PixelFormat.rgba8888, (
      image,
    ) {
      ready.value = image;
    });
  }

  /// How many different shifts [shader] hands out.
  static const shifts = 16;

  final _shaders = <int, ui.Shader>{};
  var _shaderRatio = 0.0;

  /// A shader that tiles the grain, [texel] physical pixels per texel. [shift]
  /// picks one of [shifts] places of the tile, so two surfaces do not show
  /// the same grain in the same place. Null until the tile is made.
  ///
  /// The shaders are kept and never disposed. On the web renderer a shader
  /// does not clone the tile: disposing one disposes the tile for everyone,
  /// and the next cell fails to paint.
  ui.Shader? shader(double ratio, [int shift = 0]) {
    final image = ready.value;
    if (image == null) return null;
    if (ratio != _shaderRatio) {
      _shaders.clear();
      _shaderRatio = ratio;
    }
    final step = shift % shifts;
    return _shaders.putIfAbsent(step, () {
      final scale = texel / ratio;
      final dx = step * 37 % side * scale;
      final dy = step * 91 % side * scale;
      return ui.ImageShader(
        image,
        ui.TileMode.repeated,
        ui.TileMode.repeated,
        Float64List.fromList(<double>[
          scale, 0, 0, 0, //
          0, scale, 0, 0,
          0, 0, 1, 0,
          dx, dy, 0, 1,
        ]),
        filterQuality: ui.FilterQuality.none,
      );
    });
  }
}

/// Fills its area with a grain and puts [child] on top. Until the tile is
/// made, it is the flat [GrainTile.base]. [opacity] below 1 lets what lies
/// under the box show through.
class GrainBox extends StatefulWidget {
  const GrainBox({
    required this.tile,
    this.opacity = 1,
    this.child,
    super.key,
  });

  final GrainTile tile;
  final double opacity;
  final Widget? child;

  @override
  State<GrainBox> createState() => _GrainBoxState();
}

class _GrainBoxState extends State<GrainBox> {
  @override
  void initState() {
    super.initState();
    widget.tile.load();
  }

  @override
  Widget build(BuildContext context) {
    // The fill sits in its own layer: a screen above it that repaints does
    // not paint the whole grain again.
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _GrainPainter(
              widget.tile,
              MediaQuery.devicePixelRatioOf(context),
              widget.opacity,
            ),
          ),
        ),
        ?widget.child,
      ],
    );
  }
}

class _GrainPainter extends CustomPainter {
  _GrainPainter(this.tile, this.ratio, this.opacity)
    : super(repaint: tile.ready);

  final GrainTile tile;
  final double ratio;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final shader = tile.shader(ratio);
    final paint = Paint()..color = tile.base.withValues(alpha: opacity);
    if (shader != null) paint.shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant _GrainPainter oldDelegate) =>
      oldDelegate.tile != tile ||
      oldDelegate.ratio != ratio ||
      oldDelegate.opacity != opacity;
}
