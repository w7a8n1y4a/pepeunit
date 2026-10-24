import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show PathMetric, Tangent;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

const hexFill = Color(0xFF14161B);
const sceneBackground = Color(0xFF1B1B1F);

class HexSlot {
  const HexSlot({
    required this.id,
    required this.title,
    required this.color,
    required this.q,
    required this.r,
    this.icon,
    this.iconScale = 1,
    this.image,
    this.titleColor = const Color(0xFFFFFFFF),
    this.footer,
    this.footerColor = const Color(0xFFFFFFFF),
    this.body,
    this.tappable = true,
    this.enabled = true,
  });

  final String id;
  final String title;
  final Color color;
  final int q;
  final int r;
  final String? icon;
  final double iconScale;

  /// PNG bytes drawn in the center, in place of [icon].
  final Uint8List? image;
  final Color titleColor;

  /// A second caption along the lower edges. Short text sits on the lower
  /// right edge. From 13 characters it is centered across both lower edges.
  final String? footer;
  final Color footerColor;

  /// Replaces the icon and stays inside this cell. Used for the error text.
  final Widget? body;

  /// False for a caption that does not open anything.
  final bool tappable;

  /// False for a control that is shown and does nothing yet.
  final bool enabled;
}

typedef HexSlotWrap = Widget Function(HexSlot slot, Widget child);

class HexScene extends StatelessWidget {
  const HexScene({
    required this.slots,
    required this.onTap,
    this.wrap,
    super.key,
  });

  final List<HexSlot> slots;
  final ValueChanged<String> onTap;
  final HexSlotWrap? wrap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = HexLayout.fit(slots, constraints.biggest);
        return Stack(
          children: [
            CustomPaint(size: constraints.biggest, painter: HexPainter(layout)),
            for (final placed in layout.placed)
              Positioned(
                left: placed.center.dx - placed.radius,
                top: placed.center.dy - placed.radius,
                width: placed.radius * 2,
                height: placed.radius * 2,
                child: _tile(placed),
              ),
          ],
        );
      },
    );
  }

  Widget _tile(PlacedHex placed) {
    final icon = placed.slot.icon;
    final body = placed.slot.body;
    final image = placed.slot.image;
    final Widget child;
    if (body != null) {
      child = ClipPath(clipper: const _CellClip(), child: body);
    } else if (image != null) {
      final side = placed.radius * 1.15 * 0.85;
      child = Center(
        child: ClipOval(
          child: Image.memory(
            image,
            width: side,
            height: side,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
      );
    } else if (icon != null) {
      child = Center(
        child: SvgPicture.asset(
          icon,
          width: placed.radius * 0.72 * placed.slot.iconScale,
          height: placed.radius * 0.72 * placed.slot.iconScale,
        ),
      );
    } else {
      child = const SizedBox.expand();
    }
    final slot = placed.slot;
    Widget tile;
    if (body != null) {
      tile = Semantics(
        container: true,
        explicitChildNodes: true,
        label: slot.title,
        child: child,
      );
    } else {
      tile = Semantics(
        button: slot.tappable || !slot.enabled,
        enabled: slot.enabled,
        label: slot.title,
        value: slot.footer,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: slot.tappable && slot.enabled ? () => onTap(slot.id) : null,
          child: child,
        ),
      );
    }
    final wrap = this.wrap;
    if (wrap != null) tile = wrap(placed.slot, tile);
    return tile;
  }
}

Path pointyHex(Offset center, double radius) {
  final path = Path();
  for (var i = 0; i < 6; i++) {
    final angle = pi / 3 * i - pi / 2;
    final point = Offset(
      center.dx + radius * cos(angle),
      center.dy + radius * sin(angle),
    );
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();
  return path;
}

class _CellClip extends CustomClipper<Path> {
  const _CellClip();

  @override
  Path getClip(Size size) => pointyHex(
    Offset(size.width / 2, size.height / 2),
    size.shortestSide / 2 * 0.92,
  );

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class PlacedHex {
  PlacedHex(this.slot, this.center, this.radius);

  final HexSlot slot;
  final Offset center;
  final double radius;
}

class HexLayout {
  HexLayout(this.placed);

  final List<PlacedHex> placed;

  static const _step = 96.0;

  static HexLayout fit(List<HexSlot> slots, Size size) {
    final raw = [
      for (final slot in slots) MapEntry(slot, _axial(slot.q, slot.r)),
    ];
    var minX = double.infinity;
    var minY = double.infinity;
    var maxX = double.negativeInfinity;
    var maxY = double.negativeInfinity;
    for (final entry in raw) {
      minX = min(minX, entry.value.dx);
      minY = min(minY, entry.value.dy);
      maxX = max(maxX, entry.value.dx);
      maxY = max(maxY, entry.value.dy);
    }
    const radius = 74.0;
    final width = max(maxX - minX, 1) + radius * 2 + 36;
    final height = max(maxY - minY, 1) + radius * 2 + 36;
    final scale = min(size.width / width, size.height / height);
    final origin = Offset(
      (size.width - width * scale) / 2,
      (size.height - height * scale) / 2,
    );
    return HexLayout([
      for (final entry in raw)
        PlacedHex(
          entry.key,
          origin +
              Offset(
                (entry.value.dx - minX + radius + 18) * scale,
                (entry.value.dy - minY + radius + 18) * scale,
              ),
          radius * scale,
        ),
    ]);
  }

  static Offset _axial(int q, int r) {
    return Offset(_step * sqrt(3) * (q + r / 2), _step * 1.5 * r);
  }
}

class _Glyph {
  const _Glyph(this.char, this.at, this.width);

  final String char;
  final double at;
  final double width;
}

class HexPainter extends CustomPainter {
  HexPainter(this.layout);

  final HexLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    for (final placed in layout.placed) {
      final path = pointyHex(placed.center, placed.radius);
      canvas.drawPath(path, Paint()..color = hexFill);
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = max(1.4, placed.radius * 0.03)
          ..color = placed.slot.color,
      );
      _label(canvas, placed);
    }
  }

  void _label(Canvas canvas, PlacedHex placed) {
    final radius = placed.radius;
    _paintText(
      canvas,
      placed.slot.title,
      placed.slot.titleColor,
      radius,
      _rim(
        placed.center,
        radius,
        upper: true,
        both: placed.slot.title.runes.length >= 13,
      ),
    );
    final footer = placed.slot.footer;
    if (footer == null || footer.isEmpty) return;
    _paintText(
      canvas,
      footer,
      placed.slot.footerColor,
      radius,
      _rim(
        placed.center,
        radius,
        upper: false,
        both: footer.runes.length >= 13,
      ),
    );
  }

  void _paintText(
    Canvas canvas,
    String text,
    Color color,
    double radius,
    ({Path path, double centerAt}) band,
  ) {
    final runes = text.runes.toList();
    final shown = runes.length >= 25
        ? '${String.fromCharCodes(runes.take(23))}…'
        : text;
    var fontSize = max(12.0, radius * 0.19);
    final metric = band.path.computeMetrics().single;
    var glyphs = _glyphs(shown, fontSize, band.centerAt, metric);
    final span = _span(glyphs);
    if (span > metric.length && span > 0) {
      fontSize *= metric.length / span * 0.98;
      glyphs = _glyphs(shown, fontSize, band.centerAt, metric);
    }
    _paintGlyphs(canvas, glyphs, fontSize, metric, color);
  }

  /// Upper captions start on the left edge. Lower captions start on the
  /// right edge. Thirteen characters or more run across both edges.
  ({Path path, double centerAt}) _rim(
    Offset center,
    double radius, {
    required bool upper,
    required bool both,
  }) {
    final inset = radius * 0.16;
    final pad = radius * 0.05;
    final bend = radius * 0.14;
    final Offset peak;
    final Offset leftVertex;
    final Offset rightVertex;
    final Offset inwardLeft;
    final Offset inwardRight;
    final Offset peakInset;
    if (upper) {
      peak = center + const Offset(0, -1) * radius;
      leftVertex =
          center + Offset(radius * cos(7 * pi / 6), radius * sin(7 * pi / 6));
      rightVertex =
          center + Offset(radius * cos(-pi / 6), radius * sin(-pi / 6));
      inwardLeft = const Offset(0.5, 0.86602540378);
      inwardRight = const Offset(-0.5, 0.86602540378);
      peakInset = Offset(0, inset * 2 / sqrt(3));
    } else {
      peak = center + const Offset(0, 1) * radius;
      leftVertex =
          center + Offset(radius * cos(5 * pi / 6), radius * sin(5 * pi / 6));
      rightVertex = center + Offset(radius * cos(pi / 6), radius * sin(pi / 6));
      inwardLeft = const Offset(0.5, -0.86602540378);
      inwardRight = const Offset(-0.5, -0.86602540378);
      peakInset = Offset(0, -inset * 2 / sqrt(3));
    }
    final leftOuter = leftVertex + inwardLeft * inset;
    final rightOuter = rightVertex + inwardRight * inset;
    final corner = peak + peakInset;
    if (both) {
      final path = _roof(leftOuter, corner, rightOuter, pad, bend).path;
      return (path: path, centerAt: path.computeMetrics().single.length / 2);
    }
    final Offset from;
    final Offset to;
    final Offset edgeMid;
    if (upper) {
      from = leftOuter;
      to = corner;
      edgeMid = (leftVertex + peak) / 2 + inwardLeft * inset;
    } else {
      from = corner;
      to = rightOuter;
      edgeMid = (peak + rightVertex) / 2 + inwardRight * inset;
    }
    final delta = to - from;
    final length = delta.distance;
    final direction = delta / length;
    final start = from + direction * pad;
    final end = to - direction * pad;
    return (
      path: Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(end.dx, end.dy),
      centerAt: _along(start, end, edgeMid),
    );
  }

  double _along(Offset from, Offset to, Offset point) {
    final delta = to - from;
    final len2 = delta.dx * delta.dx + delta.dy * delta.dy;
    if (len2 == 0) return 0;
    final t =
        ((point.dx - from.dx) * delta.dx + (point.dy - from.dy) * delta.dy) /
        len2;
    return t.clamp(0.0, 1.0) * sqrt(len2);
  }

  ({Path path, double bendStart, double bendEnd}) _roof(
    Offset leftOuter,
    Offset corner,
    Offset rightOuter,
    double pad,
    double bend,
  ) {
    final toCorner = corner - leftOuter;
    final fromCorner = rightOuter - corner;
    final leftLen = toCorner.distance;
    final rightLen = fromCorner.distance;
    final leftDir = toCorner / leftLen;
    final rightDir = fromCorner / rightLen;
    final safeBend = min(bend, min(leftLen, rightLen) * 0.28);
    final safePad = min(pad, min(leftLen, rightLen) * 0.2);
    final start = leftOuter + leftDir * safePad;
    final before = corner - leftDir * safeBend;
    final after = corner + rightDir * safeBend;
    final end = rightOuter - rightDir * safePad;
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(before.dx, before.dy)
      ..quadraticBezierTo(corner.dx, corner.dy, after.dx, after.dy)
      ..lineTo(end.dx, end.dy);
    final lead = (before - start).distance;
    final tail = (end - after).distance;
    final total = path.computeMetrics().single.length;
    return (path: path, bendStart: lead, bendEnd: total - tail);
  }

  List<_Glyph> _glyphs(
    String text,
    double fontSize,
    double centerAt,
    PathMetric metric,
  ) {
    final chars = [for (final rune in text.runes) String.fromCharCode(rune)];
    final widths = [for (final char in chars) _box(char, fontSize).width];
    final rough = _pack(chars, widths, centerAt, List.filled(chars.length, 0));
    final extra = <double>[];
    for (var i = 0; i < chars.length; i++) {
      if (i + 1 == chars.length || chars[i] == ' ' || chars[i + 1] == ' ') {
        extra.add(0);
        continue;
      }
      final turn = _turn(metric, rough[i].at, rough[i + 1].at);
      extra.add(min(fontSize * 0.045, fontSize * turn * 0.1));
    }
    return _pack(chars, widths, centerAt, extra);
  }

  List<_Glyph> _pack(
    List<String> chars,
    List<double> widths,
    double centerAt,
    List<double> extra,
  ) {
    final total =
        widths.fold(0.0, (sum, width) => sum + width) +
        extra.fold(0.0, (sum, gap) => sum + gap);
    var cursor = centerAt - total / 2;
    final glyphs = <_Glyph>[];
    for (var i = 0; i < chars.length; i++) {
      glyphs.add(_Glyph(chars[i], cursor + widths[i] / 2, widths[i]));
      cursor += widths[i] + extra[i];
    }
    return glyphs;
  }

  double _turn(PathMetric metric, double from, double to) {
    var delta = _tangentAt(metric, to).angle - _tangentAt(metric, from).angle;
    delta = delta % (2 * pi);
    if (delta < 0) delta += 2 * pi;
    if (delta > pi) delta -= 2 * pi;
    return delta.abs();
  }

  double _span(List<_Glyph> glyphs) {
    if (glyphs.isEmpty) return 0;
    return glyphs.last.at +
        glyphs.last.width / 2 -
        (glyphs.first.at - glyphs.first.width / 2);
  }

  void _paintGlyphs(
    Canvas canvas,
    List<_Glyph> glyphs,
    double fontSize,
    PathMetric metric,
    Color color,
  ) {
    final lineHeight = _box('М', fontSize).height;
    for (final glyph in glyphs) {
      final tangent = _tangentAt(metric, glyph.at);
      canvas.save();
      canvas.translate(tangent.position.dx, tangent.position.dy);
      canvas.rotate(-tangent.angle);
      _box(
        glyph.char,
        fontSize,
        color,
      ).paint(canvas, Offset(-glyph.width / 2, -lineHeight / 2));
      canvas.restore();
    }
  }

  Tangent _tangentAt(PathMetric metric, double offset) {
    final length = metric.length;
    final clamped = offset.clamp(0.0, max(0.0, length - 0.05)).toDouble();
    final tangent = metric.getTangentForOffset(clamped)!;
    final delta = offset - clamped;
    if (delta.abs() < 0.01 || tangent.vector.distance == 0) return tangent;
    final step = tangent.vector / tangent.vector.distance * delta;
    return Tangent(tangent.position + step, tangent.vector);
  }

  TextPainter _box(
    String text,
    double fontSize, [
    Color color = const Color(0xFFFFFFFF),
  ]) {
    return TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontFamily: 'OpenGost Type B',
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  bool shouldRepaint(covariant HexPainter oldDelegate) => true;
}
