import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show ValueListenable, ValueNotifier;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'icon_atlas.dart';

/// Where the pictures of the background sit and how they move. The model
/// knows nothing about rasters, so it stays cheap to test.
///
/// The tiles stand on a staggered grid, each one nudged off its spot,
/// turned by up to [maxTurn] and drawn at a different size. Neighbours show
/// different pictures. Each tile rustles around its own angle. Some tiles are
/// always flipping over to show another picture on the back.
class Mosaic {
  Mosaic(this.size, this.icons, {this.pitch = 88, int seed = 7})
    : _flips = Random(seed + 1) {
    _build(seed);
  }

  /// Largest base turn of a tile, in radians: 20°.
  static const maxTurn = 20 * pi / 180;

  /// Half of the swing of the rustle, in radians.
  static const rustle = 3 * pi / 180;

  /// How long one flip takes, in seconds.
  static const flipSeconds = 0.8;

  /// How many tiles are mid-flip, at every moment.
  static const flipsTogether = 5;

  final Size size;
  final int icons;

  /// Distance between neighbouring tiles.
  final double pitch;

  final Random _flips;
  var count = 0;
  var columns = 0;

  late final Float32List _x;
  late final Float32List _y;
  late final Float32List _side;
  late final Float32List _turn;
  late final Float32List _phase;
  late final Float32List _speed;
  late final Float32List _alpha;
  late final Int32List _icon;
  late final Int32List _next;
  late final Float32List _progress;

  final _started = <int, double>{};
  final _done = <int>[];
  var _nextFlip = 0.0;

  /// Tiles that are flipping right now.
  Iterable<int> get flipping => _started.keys;

  void _build(int seed) {
    if (icons <= 0 || size.isEmpty) {
      _x = Float32List(0);
      _y = Float32List(0);
      _side = Float32List(0);
      _turn = Float32List(0);
      _phase = Float32List(0);
      _speed = Float32List(0);
      _alpha = Float32List(0);
      _icon = Int32List(0);
      _next = Int32List(0);
      _progress = Float32List(0);
      return;
    }
    final rng = Random(seed);
    final rowHeight = pitch * sqrt(3) / 2;
    columns = (size.width / pitch).ceil() + 2;
    final rows = (size.height / rowHeight).ceil() + 2;
    count = columns * rows;
    _x = Float32List(count);
    _y = Float32List(count);
    _side = Float32List(count);
    _turn = Float32List(count);
    _phase = Float32List(count);
    _speed = Float32List(count);
    _alpha = Float32List(count);
    _icon = Int32List(count);
    _next = Int32List(count);
    _progress = Float32List(count)..fillRange(0, count, -1);
    final deck = List<int>.generate(icons, (i) => i)..shuffle(rng);
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final i = row * columns + column;
        final stagger = row.isOdd ? pitch / 2 : 0.0;
        final shake = pitch * 0.24;
        _x[i] =
            (column - 1) * pitch + stagger + (rng.nextDouble() - 0.5) * shake;
        _y[i] = (row - 1) * rowHeight + (rng.nextDouble() - 0.5) * shake;
        _side[i] = pitch * 0.44 * (0.85 + rng.nextDouble() * 0.3);
        _turn[i] = (rng.nextDouble() * 2 - 1) * maxTurn;
        _phase[i] = rng.nextDouble() * 2 * pi;
        _speed[i] = 0.5 + rng.nextDouble() * 0.8;
        _alpha[i] = 0.05 + rng.nextDouble() * 0.04;
        // One step along a row, seven steps down a column: no tile sits
        // beside the same picture unless the catalog is tiny.
        _icon[i] = deck[(column + row * 7) % icons];
      }
    }
  }

  int iconAt(int i) => _icon[i];

  double xAt(int i) => _x[i];

  double yAt(int i) => _y[i];

  /// Side of the picture, in logical pixels.
  double sideAt(int i) => _side[i];

  double alphaAt(int i) => _alpha[i];

  double angleAt(int i, double t) =>
      _turn[i] + rustle * sin(_speed[i] * t + _phase[i]);

  /// Progress of the flip of tile [i] from 0 to 1, or -1 when it stands still.
  double flipAt(int i) => _progress[i];

  /// Picture that tile [i] is turning to while it flips.
  int nextIconAt(int i) => _next[i];

  /// Moves the flips to second [t]. Call it as time grows.
  void advance(double t) {
    if (count == 0) return;
    // A flip starts at fixed steps and lasts [flipSeconds], so the same
    // number of tiles are in the air all the time, with no waves. After a
    // pause the clock has jumped, and the steps start over from now.
    const step = flipSeconds / flipsTogether;
    if (t - _nextFlip > 1) _nextFlip = t;
    while (_nextFlip <= t) {
      _begin(_nextFlip);
      _nextFlip += step;
    }
    _done.clear();
    _started.forEach((i, start) {
      final p = (t - start) / flipSeconds;
      if (p >= 1) {
        _icon[i] = _next[i];
        _progress[i] = -1;
        _done.add(i);
      } else {
        _progress[i] = p;
      }
    });
    _done.forEach(_started.remove);
  }

  void _begin(double at) {
    for (var tries = 0; tries < 4; tries++) {
      final i = _flips.nextInt(count);
      if (_started.containsKey(i)) continue;
      _next[i] = _pick(i);
      _progress[i] = 0;
      _started[i] = at;
      return;
    }
  }

  /// A picture that neither this tile nor the ones around it show.
  int _pick(int i) {
    final around = <int>{_icon[i]};
    for (final j in [i - 1, i + 1, i - columns, i + columns]) {
      if (j >= 0 && j < count) around.add(_icon[j]);
    }
    var pick = _flips.nextInt(icons);
    for (var tries = 0; tries < 8 && around.contains(pick); tries++) {
      pick = _flips.nextInt(icons);
    }
    return pick;
  }
}

/// The mosaic behind every screen. Nothing here lays out or rebuilds: a timer
/// moves the model and the one painter draws every tile with a single atlas
/// call. It stops while the app is in the background and when the system asks
/// for reduced motion.
class HiveBackground extends StatefulWidget {
  const HiveBackground({super.key});

  @override
  State<HiveBackground> createState() => _HiveBackgroundState();
}

class _HiveBackgroundState extends State<HiveBackground>
    with WidgetsBindingObserver {
  static const _frame = Duration(milliseconds: 33);

  final _clock = ValueNotifier<double>(0);
  final _watch = Stopwatch()..start();
  IconAtlas? _atlas;
  Mosaic? _mosaic;
  _MosaicPainter? _painter;
  Timer? _timer;
  var _awake = true;
  var _still = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  Future<void> _load() async {
    final atlas = await IconAtlas.load(rootBundle);
    if (!mounted) {
      atlas?.dispose();
      return;
    }
    setState(() => _atlas = atlas);
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = MediaQuery.disableAnimationsOf(context);
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _awake = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    final run = _atlas != null && _awake && !_still;
    if (!run) {
      _timer?.cancel();
      _timer = null;
    } else {
      _timer ??= Timer.periodic(_frame, (_) => _tick());
    }
  }

  void _tick() {
    final t = _watch.elapsedMicroseconds / Duration.microsecondsPerSecond;
    _mosaic?.advance(t);
    _clock.value = t;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _clock.dispose();
    _atlas?.dispose();
    super.dispose();
  }

  _MosaicPainter _paint(IconAtlas atlas, Size size) {
    var painter = _painter;
    final mosaic = _mosaic;
    if (painter == null || mosaic == null || mosaic.size != size) {
      final fresh = Mosaic(size, atlas.count);
      _mosaic = fresh;
      painter = _painter = _MosaicPainter(atlas, fresh, _clock);
    }
    return painter;
  }

  @override
  Widget build(BuildContext context) {
    final atlas = _atlas;
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: atlas == null ? 0 : 1,
        duration: const Duration(milliseconds: 900),
        child: atlas == null
            ? const SizedBox.expand()
            : RepaintBoundary(
                child: LayoutBuilder(
                  builder: (context, constraints) => CustomPaint(
                    size: constraints.biggest,
                    painter: _paint(atlas, constraints.biggest),
                  ),
                ),
              ),
      ),
    );
  }
}

class _MosaicPainter extends CustomPainter {
  _MosaicPainter(this.atlas, this.mosaic, this.clock)
    : _transforms = Float32List(mosaic.count * 4),
      _rects = Float32List(mosaic.count * 4),
      _colors = Int32List(mosaic.count),
      super(repaint: clock);

  final IconAtlas atlas;
  final Mosaic mosaic;
  final ValueListenable<double> clock;
  final Float32List _transforms;
  final Float32List _rects;
  final Int32List _colors;

  static const _half = IconAtlas.cell / 2;
  final _paint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true;
  final _flipPaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    final count = mosaic.count;
    if (count == 0) return;
    final t = clock.value;
    for (var i = 0; i < count; i++) {
      final scale = mosaic.sideAt(i) / IconAtlas.cell;
      final angle = mosaic.angleAt(i, t);
      final cos0 = cos(angle) * scale;
      final sin0 = sin(angle) * scale;
      final at = i * 4;
      _transforms[at] = cos0;
      _transforms[at + 1] = sin0;
      _transforms[at + 2] = mosaic.xAt(i) - cos0 * _half + sin0 * _half;
      _transforms[at + 3] = mosaic.yAt(i) - sin0 * _half - cos0 * _half;
      final from = mosaic.iconAt(i) * 4;
      _rects.setRange(at, at + 4, atlas.rawRects, from);
      // A flipping tile is drawn on its own below.
      final alpha = mosaic.flipAt(i) < 0
          ? (mosaic.alphaAt(i) * 255).round()
          : 0;
      _colors[i] = (alpha << 24) | 0x00FFFFFF;
    }
    canvas.drawRawAtlas(
      atlas.image,
      _transforms,
      _rects,
      _colors,
      BlendMode.modulate,
      null,
      _paint,
    );
    for (final i in mosaic.flipping) {
      _flip(canvas, i, t);
    }
  }

  void _flip(Canvas canvas, int i, double t) {
    final p = mosaic.flipAt(i);
    if (p < 0) return;
    final icon = p < 0.5 ? mosaic.iconAt(i) : mosaic.nextIconAt(i);
    final scale = mosaic.sideAt(i) / IconAtlas.cell;
    final from = icon * 4;
    final src = Rect.fromLTRB(
      atlas.rawRects[from],
      atlas.rawRects[from + 1],
      atlas.rawRects[from + 2],
      atlas.rawRects[from + 3],
    );
    canvas.save();
    canvas.translate(mosaic.xAt(i), mosaic.yAt(i));
    canvas.rotate(mosaic.angleAt(i, t));
    canvas.scale(scale * cos(p * pi).abs().clamp(0.02, 1.0), scale);
    canvas.drawImageRect(
      atlas.image,
      src,
      const Rect.fromLTWH(-_half, -_half, IconAtlas.cell, IconAtlas.cell),
      _flipPaint
        ..color = Color.fromARGB(
          (mosaic.alphaAt(i) * 255).round(),
          255,
          255,
          255,
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MosaicPainter oldDelegate) =>
      oldDelegate.mosaic != mosaic || oldDelegate.atlas != atlas;
}
