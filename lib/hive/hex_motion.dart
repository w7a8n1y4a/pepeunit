import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show PointMode;

import 'package:flutter/material.dart';

/// Effects on the scene right now: waiting rings, press bursts, echoes. The
/// background mosaic rests while any plays, so the effect gets every frame
/// to itself instead of sharing it with a full-screen repaint.
abstract final class MotionLoad {
  static var _active = 0;

  /// True while some effect plays.
  static bool get active => _active > 0;
}

/// One owner's share of [MotionLoad]. Set it on when the owner's effect
/// starts and off when it ends. Setting the same value twice counts once, so
/// an owner cannot leave the background resting by mistake; always set it
/// off in `dispose`.
class MotionLease {
  var _held = false;

  void set(bool on) {
    if (on == _held) return;
    _held = on;
    MotionLoad._active += on ? 1 : -1;
  }
}

/// How long one press effect lasts.
const pressDuration = Duration(milliseconds: 420);

/// Six short rays that leave the middle of the cell and fade. They go to the
/// canvas in one call, and the painter reuses its buffer and its paint.
class PressPainter extends CustomPainter {
  PressPainter({required this.color, required Animation<double> clock})
    : _clock = clock,
      super(repaint: clock);

  final Color color;
  final Animation<double> _clock;
  final _points = Float32List(6 * 4);
  final _paint = Paint()..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final t = _clock.value.clamp(0.0, 1.0);
    final alpha = 1 - t;
    if (alpha <= 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.shortestSide / 2;
    for (var i = 0; i < 6; i++) {
      final angle = pi / 3 * i - pi / 2;
      final dx = cos(angle);
      final dy = sin(angle);
      final from = radius * (0.28 + 0.42 * t);
      final to = radius * (0.55 + 0.4 * t);
      _points[i * 4] = cx + dx * from;
      _points[i * 4 + 1] = cy + dy * from;
      _points[i * 4 + 2] = cx + dx * to;
      _points[i * 4 + 3] = cy + dy * to;
    }
    canvas.drawRawPoints(
      PointMode.lines,
      _points,
      _paint
        ..strokeWidth = max(1.4, radius * 0.035)
        ..color = Color.lerp(
          color,
          const Color(0xFFFFFFFF),
          0.35,
        )!.withValues(alpha: alpha),
    );
  }

  @override
  bool shouldRepaint(covariant PressPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// Result of a command or a sync that spreads over the scene.
///
/// Every request makes a new object, and the scene plays one echo for each
/// object it has not shown yet. So the constructor is not `const`.
class HexEcho {
  HexEcho({required this.ok});

  final bool ok;
}

/// A cell as the echo sees it.
class EchoSpot {
  const EchoSpot({
    required this.q,
    required this.r,
    required this.center,
    required this.lattice,
  });

  final int q;
  final int r;
  final Offset center;

  /// Side of the lattice hex around the cell. The gaps run along its edges.
  final double lattice;
}

/// How long one echo lasts.
const echoDuration = Duration(milliseconds: 700);

/// Lines in the gaps between cells that touch. All of them are one path and
/// pulse together: they come up, then go out. An edge between a cell and empty
/// space is not drawn, so the outer contour is never closed.
class EchoPainter extends CustomPainter {
  EchoPainter({
    required List<EchoSpot> spots,
    required this.color,
    required Animation<double> clock,
  }) : _clock = clock,
       super(repaint: clock) {
    final byCell = {for (final spot in spots) (spot.q, spot.r): spot};
    for (final spot in spots) {
      for (final step in _steps) {
        final next = byCell[(spot.q + step.$1, spot.r + step.$2)];
        if (next == null) continue;
        final span = next.center - spot.center;
        final length = span.distance;
        if (length == 0) continue;
        // The gap between two cells follows the lattice edge: a line across
        // the middle of the span.
        final half = Offset(-span.dy, span.dx) / length * (spot.lattice / 2);
        final mid = spot.center + span / 2;
        _web
          ..moveTo(mid.dx - half.dx, mid.dy - half.dy)
          ..lineTo(mid.dx + half.dx, mid.dy + half.dy);
        edgeCount++;
      }
    }
    _stroke = spots.isEmpty ? 2 : max(1.6, spots.first.lattice * 0.04);
  }

  static const _steps = <(int, int)>[(1, 0), (0, 1), (-1, 1)];

  /// Share of the echo the lines take to come up.
  static const _rise = 0.25;

  final Color color;
  final Animation<double> _clock;

  /// Gaps that carry a line.
  var edgeCount = 0;

  final _web = Path();
  late final double _stroke;
  final _glow = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final _core = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final t = _clock.value;
    final fade = t < _rise
        ? Curves.easeOut.transform(t / _rise)
        : 1 - Curves.easeIn.transform((t - _rise) / (1 - _rise));
    if (fade <= 0) return;
    _glow.strokeWidth = _stroke * 3;
    _core.strokeWidth = _stroke;
    canvas.drawPath(_web, _glow..color = color.withValues(alpha: fade * 0.25));
    canvas.drawPath(_web, _core..color = color.withValues(alpha: fade));
  }

  @override
  bool shouldRepaint(covariant EchoPainter oldDelegate) => true;
}
