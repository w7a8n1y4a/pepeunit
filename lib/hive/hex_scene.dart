import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' show PathMetric, Tangent;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'hex_motion.dart';
import 'icon_scale.dart';

/// Text inside a cell: a choice and a value that sits with it.
/// Log levels and the account parameters cell are the reference.
double cellFont(double side) => max(11, side * 0.068);

const hexFill = Color(0xFF14161B);
const sceneBackground = Color(0xFF1B1B1F);
const hexMuted = Color(0xFFA1A1AA);
const errorColor = Color(0xFFFF3333);

/// Cells that add something. Green reads as «add».
const addColor = Color(0xFF00C853);

/// Access grants: the «Access» cell of a unit or a node, and the cells of the
/// grant screens that belong to no section. One indigo on the whole client.
const accessColor = Color(0xFF5C6BFF);

const _mutedFilter = ColorFilter.matrix(<double>[
  0.33,
  0.33,
  0.33,
  0,
  40,
  0.33,
  0.33,
  0.33,
  0,
  40,
  0.33,
  0.33,
  0.33,
  0,
  40,
  0,
  0,
  0,
  0.55,
  0,
]);

class HexSlot {
  const HexSlot({
    required this.id,
    required this.title,
    required this.color,
    required this.q,
    required this.r,
    this.icon,
    this.image,
    this.titleColor = const Color(0xFFFFFFFF),
    this.titleRight,
    this.titleRightColor = const Color(0xFFFFFFFF),
    this.footer,
    this.footerColor = const Color(0xFFFFFFFF),
    this.footerLeft,
    this.footerLeftColor = const Color(0xFFFFFFFF),
    this.sideLeft,
    this.sideLeftColor = const Color(0xFFFFFFFF),
    this.sideRight,
    this.sideRightColor = const Color(0xFFFFFFFF),
    this.body,
    this.center,
    this.centerColor = const Color(0xFFFFFFFF),
    this.badge,
    this.tappable = true,
    this.enabled = true,
    this.busy = false,
    this.rim,
  });

  final String id;
  final String title;
  final Color color;
  final int q;
  final int r;
  final String? icon;

  /// PNG bytes drawn in the center, in place of [icon].
  final Uint8List? image;
  final Color titleColor;

  /// Short text centered on the upper right edge. From 13 characters it
  /// takes both upper edges, and the upper left caption is not drawn.
  final String? titleRight;
  final Color titleRightColor;

  /// Short text centered on the lower right edge. From 13 characters it
  /// takes both lower edges, and the lower left caption is not drawn.
  final String? footer;
  final Color footerColor;

  /// Short text centered on the lower left edge. From 13 characters it
  /// takes both lower edges, and the lower right caption is not drawn.
  final String? footerLeft;
  final Color footerLeftColor;

  /// Text along the left edge, read from the bottom up. Repo cards put the size here.
  final String? sideLeft;
  final Color sideLeftColor;

  /// Text along the right edge, read from the bottom up. User cards put the role here.
  final String? sideRight;
  final Color sideRightColor;

  /// Replaces the icon and stays inside this cell. Used for the error text.
  final Widget? body;

  /// Text in the middle of the cell. The cell stays a button.
  final String? center;
  final Color centerColor;

  /// Unread count drawn on the upper-right vertex. Zero and null stay hidden.
  final int? badge;

  /// False for a caption that does not open anything.
  final bool tappable;

  /// False for a control that is shown and does nothing yet.
  final bool enabled;

  /// True while this cell is waiting on a request.
  final bool busy;

  /// Border colors, [hexRimSegments] long. Each side is cut into
  /// [hexRimSideParts] parts. Segment 0 starts at the top vertex and the order
  /// runs clockwise. Null keeps the border in [color]. A disabled cell stays
  /// muted.
  final List<Color>? rim;
}

const hexRimSideParts = 8;
const hexRimSegments = 6 * hexRimSideParts;

/// Mixes the colors around the border in proportion to their weights, so
/// they alternate segment by segment. The first color takes segment 0. A color
/// with a positive weight keeps at least one segment. Returns null when every
/// weight is zero.
List<Color>? rimMix(List<(Color, int)> parts) {
  final live = [
    for (final part in parts)
      if (part.$2 > 0) part,
  ];
  if (live.isEmpty) return null;
  final total = live.fold<int>(0, (sum, part) => sum + part.$2);
  final exact = [for (final part in live) part.$2 * hexRimSegments / total];
  final cells = [for (final share in exact) max(1, share.floor())];
  var left = hexRimSegments - cells.fold<int>(0, (sum, count) => sum + count);
  while (left != 0) {
    var pick = -1;
    for (var i = 0; i < cells.length; i++) {
      if (left < 0 && cells[i] < 2) continue;
      final gap = exact[i] - cells[i];
      if (pick < 0) {
        pick = i;
      } else if (left > 0
          ? gap > exact[pick] - cells[pick]
          : gap < exact[pick] - cells[pick]) {
        pick = i;
      }
    }
    if (pick < 0) break;
    cells[pick] += left > 0 ? 1 : -1;
    left += left > 0 ? -1 : 1;
  }
  // Smooth weighted round robin: every color keeps its count and its
  // segments are spread as evenly as the counts allow.
  final credit = List<int>.filled(live.length, 0);
  return [
    for (var step = 0; step < hexRimSegments; step++)
      () {
        var pick = 0;
        for (var i = 0; i < live.length; i++) {
          credit[i] += cells[i];
          if (credit[i] > credit[pick]) pick = i;
        }
        credit[pick] -= hexRimSegments;
        return live[pick].$1;
      }(),
  ];
}

/// Draws the border of a pointy-top hex in [rim] colors. Runs of one color
/// are stroked as one path, so the corners stay mitered.
void paintHexRim(
  Canvas canvas,
  Offset center,
  double radius,
  double stroke,
  List<Color> rim,
) {
  if (rim.length != hexRimSegments) return;
  final corners = [
    for (var i = 0; i < 6; i++)
      Offset(
        center.dx + radius * cos(pi / 3 * i - pi / 2),
        center.dy + radius * sin(pi / 3 * i - pi / 2),
      ),
  ];
  Offset at(int segment) {
    final side = segment ~/ hexRimSideParts % 6;
    final t = (segment - side * hexRimSideParts) / hexRimSideParts;
    return Offset.lerp(corners[side], corners[(side + 1) % 6], t)!;
  }

  final paint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..strokeCap = StrokeCap.butt
    ..strokeJoin = StrokeJoin.miter;
  var from = 0;
  while (from < hexRimSegments) {
    var to = from + 1;
    while (to < hexRimSegments && rim[to] == rim[from]) {
      to++;
    }
    final path = Path()..moveTo(at(from).dx, at(from).dy);
    var corner = (from ~/ hexRimSideParts + 1) * hexRimSideParts;
    for (; corner < to; corner += hexRimSideParts) {
      final point = at(corner);
      path.lineTo(point.dx, point.dy);
    }
    final end = at(to % hexRimSegments);
    path.lineTo(end.dx, end.dy);
    canvas.drawPath(path, paint..color = rim[from]);
    from = to;
  }

  // Where the color changes on a vertex the two butt ends leave a notch on
  // the outside. Each half of the miter goes to the color on its side.
  final half = stroke / 2;
  final reach = half / cos(pi / 6);
  for (var i = 0; i < 6; i++) {
    final next = rim[i * hexRimSideParts];
    final prev =
        rim[(i * hexRimSideParts - 1 + hexRimSegments) % hexRimSegments];
    if (i != 0 && prev == next) continue;
    final angle = pi / 3 * i - pi / 2;
    final vertex = corners[i];
    final before =
        vertex + Offset(cos(angle - pi / 6), sin(angle - pi / 6)) * half;
    final after =
        vertex + Offset(cos(angle + pi / 6), sin(angle + pi / 6)) * half;
    final tip = vertex + Offset(cos(angle), sin(angle)) * reach;
    canvas.drawPath(
      Path()
        ..moveTo(vertex.dx, vertex.dy)
        ..lineTo(before.dx, before.dy)
        ..lineTo(tip.dx, tip.dy)
        ..close(),
      Paint()..color = prev,
    );
    canvas.drawPath(
      Path()
        ..moveTo(vertex.dx, vertex.dy)
        ..lineTo(tip.dx, tip.dy)
        ..lineTo(after.dx, after.dy)
        ..close(),
      Paint()..color = next,
    );
  }
}

String slotLabel(HexSlot slot) {
  final left = slot.sideLeft;
  final right = slot.sideRight;
  final parts = <String>[
    if (slot.title.isNotEmpty) slot.title,
    if (left != null && left.isNotEmpty) left,
    if (right != null && right.isNotEmpty) right,
    if (slot.badge != null && slot.badge! > 0) '${slot.badge}',
  ];
  if (parts.isEmpty) return slot.title;
  return parts.join(', ');
}

typedef HexSlotWrap = Widget Function(HexSlot slot, Widget child);

class HexScene extends StatefulWidget {
  const HexScene({
    required this.slots,
    required this.onTap,
    this.wrap,
    this.echo,
    super.key,
  });

  final List<HexSlot> slots;
  final ValueChanged<String> onTap;
  final HexSlotWrap? wrap;

  /// A command or a sync that just ended. Each new object plays one echo
  /// of lines between the cells.
  final HexEcho? echo;

  @override
  State<HexScene> createState() => _HexSceneState();
}

class _HexSceneState extends State<HexScene>
    with SingleTickerProviderStateMixin {
  AnimationController? _clock;
  HexEcho? _echo;
  final _lease = MotionLease();

  @override
  void didUpdateWidget(HexScene oldWidget) {
    super.didUpdateWidget(oldWidget);
    final echo = widget.echo;
    if (echo == null || identical(echo, oldWidget.echo)) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    var clock = _clock;
    if (clock == null) {
      clock = AnimationController(vsync: this, duration: echoDuration);
      clock.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          _lease.set(false);
          setState(() => _echo = null);
        }
      });
      _clock = clock;
    }
    _echo = echo;
    _lease.set(true);
    clock.forward(from: 0);
  }

  @override
  void dispose() {
    _lease.set(false);
    _clock?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = HexLayout.fit(widget.slots, constraints.biggest);
        final echo = _echo;
        final clock = _clock;
        return Stack(
          children: [
            // Under the cells: the lines live in the gaps. The slot stays in
            // the list so the cells keep their place and their state.
            Positioned.fill(
              child: echo == null || clock == null
                  ? const SizedBox.shrink()
                  : IgnorePointer(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          painter: EchoPainter(
                            spots: [
                              for (final placed in layout.placed)
                                EchoSpot(
                                  q: placed.slot.q,
                                  r: placed.slot.r,
                                  center: placed.center,
                                  lattice:
                                      placed.radius * HexLayout.latticeRatio,
                                ),
                            ],
                            color: echo.ok ? addColor : errorColor,
                            clock: clock,
                          ),
                        ),
                      ),
                    ),
            ),
            for (final placed in layout.placed)
              Positioned(
                left: placed.center.dx - placed.radius,
                top: placed.center.dy - placed.radius,
                width: placed.radius * 2,
                height: placed.radius * 2,
                child: _tile(placed, MediaQuery.devicePixelRatioOf(context)),
              ),
          ],
        );
      },
    );
  }

  Widget _tile(PlacedHex placed, double ratio) {
    final icon = placed.slot.icon;
    final body = placed.slot.body;
    final image = placed.slot.image;
    Widget child;
    if (body != null) {
      child = ClipPath(clipper: const _CellClip(), child: body);
    } else if (image != null) {
      final side = placed.radius * 1.15 * 0.85;
      // Decode straight to the drawn size in device pixels: no full-size
      // raster in memory, no resample on every rebuild.
      final decoded = (side * ratio).ceil();
      child = Center(
        child: ClipOval(
          child: Image.memory(
            image,
            width: side,
            height: side,
            fit: BoxFit.cover,
            cacheWidth: decoded,
            cacheHeight: decoded,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
          ),
        ),
      );
    } else if (icon != null) {
      final scale = iconScaleOf(icon);
      final picture = SvgPicture.asset(
        icon,
        width: placed.radius * 0.72 * scale,
        height: placed.radius * 0.72 * scale,
      );
      final caption = placed.slot.center;
      if (caption == null || caption.isEmpty) {
        child = Center(child: picture);
      } else {
        // A short caption sits on the lower half of the picture, like the
        // extension on a file icon.
        child = Stack(
          alignment: Alignment.center,
          children: [
            picture,
            IgnorePointer(
              child: Transform.translate(
                offset: Offset(0, placed.radius * 0.18),
                child: ExcludeSemantics(
                  child: Text(
                    caption,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: placed.slot.centerColor,
                      fontFamily: 'JetBrains Mono',
                      fontSize: placed.radius * 0.13,
                      height: 1,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }
    } else {
      final center = placed.slot.center;
      if (center != null && center.isNotEmpty) {
        final radius = placed.radius;
        // The flat middle of the hex. Notification `small_text` is capped
        // by `pu_notification_small_text_limit`: 48 characters by default,
        // 96 at most. The block is a little wider and a little smaller so
        // that whole range stays in the middle, clear of the edge captions.
        child = IgnorePointer(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: radius * 0.30,
              vertical: radius * 0.52,
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: radius * 1.38),
                  child: ExcludeSemantics(
                    child: Text(
                      center,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: placed.slot.centerColor,
                        fontFamily: 'OpenGost Type B',
                        fontSize: radius * 0.13,
                        height: 1.15,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        child = const SizedBox.expand();
      }
    }
    final slot = placed.slot;
    if (!slot.enabled) {
      child = IgnorePointer(
        child: ColorFiltered(colorFilter: _mutedFilter, child: child),
      );
    }
    final frame = _CellFrame(
      key: ValueKey(slot.id),
      slot: slot,
      button: body == null,
      interactive: body == null && slot.tappable && slot.enabled,
      onTap: () => widget.onTap(slot.id),
      child: child,
    );
    Widget tile;
    if (body != null) {
      tile = Semantics(
        container: true,
        explicitChildNodes: true,
        label: slotLabel(slot),
        child: frame,
      );
    } else {
      tile = Semantics(
        button: slot.tappable || !slot.enabled,
        enabled: slot.enabled,
        label: slotLabel(slot),
        value: slot.footer,
        child: frame,
      );
    }
    final wrap = widget.wrap;
    if (wrap != null) tile = wrap(placed.slot, tile);
    return RepaintBoundary(child: tile);
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
  static const _radius = 74.0;

  /// Side of a lattice hex over the radius of a drawn cell. The gaps between
  /// cells run along the lattice edges.
  static const latticeRatio = _step / _radius;

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
    const radius = _radius;
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
  HexPainter(this.slot);

  final HexSlot slot;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final path = pointyHex(center, radius);
    final enabled = slot.enabled;
    final stroke = max(1.4, radius * 0.03);
    canvas.drawPath(path, Paint()..color = hexFill);
    final rim = slot.rim;
    if (enabled && rim != null) {
      paintHexRim(canvas, center, radius, stroke, rim);
    } else {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..color = enabled ? slot.color : hexMuted,
      );
    }
    _label(canvas, center, radius);
  }

  void _label(Canvas canvas, Offset center, double radius) {
    final enabled = slot.enabled;
    final muted = !enabled;
    _half(
      canvas,
      center,
      radius,
      upper: true,
      left: slot.title,
      leftColor: muted ? hexMuted : slot.titleColor,
      right: slot.titleRight,
      rightColor: muted ? hexMuted : slot.titleRightColor,
    );
    _half(
      canvas,
      center,
      radius,
      upper: false,
      left: slot.footerLeft,
      leftColor: muted ? hexMuted : slot.footerLeftColor,
      right: slot.footer,
      rightColor: muted ? hexMuted : slot.footerColor,
    );
    _paintSide(canvas, center, radius, right: false);
    _paintSide(canvas, center, radius, right: true);
  }

  /// A side caption follows a vertical edge. The path runs upward, so the
  /// word is read from the bottom.
  void _paintSide(
    Canvas canvas,
    Offset center,
    double radius, {
    required bool right,
  }) {
    final text = right ? slot.sideRight : slot.sideLeft;
    if (text == null || text.isEmpty) return;
    final color = !slot.enabled
        ? hexMuted
        : (right ? slot.sideRightColor : slot.sideLeftColor);
    final inset = radius * 0.16;
    final pad = radius * 0.12;
    final edge = radius * cos(pi / 6);
    final x = right ? center.dx + edge - inset : center.dx - edge + inset;
    final top = center.dy - radius * 0.5 + pad;
    final bottom = center.dy + radius * 0.5 - pad;
    final path = Path()
      ..moveTo(x, bottom)
      ..lineTo(x, top);
    _paintText(canvas, text, color, radius, (
      path: path,
      centerAt: (bottom - top) / 2,
    ));
  }

  /// A caption of 13 characters or more bends across both edges of its half.
  /// The other caption on that half stays off, so the two do not overlap.
  void _half(
    Canvas canvas,
    Offset center,
    double radius, {
    required bool upper,
    required String? left,
    required Color leftColor,
    required String? right,
    required Color rightColor,
  }) {
    final hasLeft = left != null && left.isNotEmpty;
    final hasRight = right != null && right.isNotEmpty;
    if (!hasLeft && !hasRight) return;
    if (hasLeft && left.runes.length >= 13) {
      _paintText(
        canvas,
        left,
        leftColor,
        radius,
        _roofRim(center, radius, upper: upper),
      );
      return;
    }
    if (hasRight && right.runes.length >= 13) {
      _paintText(
        canvas,
        right,
        rightColor,
        radius,
        _roofRim(center, radius, upper: upper),
      );
      return;
    }
    if (hasLeft) {
      _paintText(
        canvas,
        left,
        leftColor,
        radius,
        _edgeRim(center, radius, upper: upper, right: false),
      );
    }
    if (hasRight) {
      _paintText(
        canvas,
        right,
        rightColor,
        radius,
        _edgeRim(center, radius, upper: upper, right: true),
      );
    }
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

  ({Path path, double centerAt}) _edgeRim(
    Offset center,
    double radius, {
    required bool upper,
    required bool right,
  }) {
    final cap = _cap(center, radius, upper: upper);
    final Offset from;
    final Offset to;
    final Offset edgeMid;
    if (!right) {
      from = cap.leftOuter;
      to = cap.corner;
      edgeMid = (cap.leftVertex + cap.peak) / 2 + cap.inwardLeft * cap.inset;
    } else {
      from = cap.corner;
      to = cap.rightOuter;
      edgeMid = (cap.peak + cap.rightVertex) / 2 + cap.inwardRight * cap.inset;
    }
    final delta = to - from;
    final length = delta.distance;
    final direction = delta / length;
    final start = from + direction * cap.pad;
    final end = to - direction * cap.pad;
    return (
      path: Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(end.dx, end.dy),
      centerAt: _along(start, end, edgeMid),
    );
  }

  ({Path path, double centerAt}) _roofRim(
    Offset center,
    double radius, {
    required bool upper,
  }) {
    final cap = _cap(center, radius, upper: upper);
    final path = _roof(
      cap.leftOuter,
      cap.corner,
      cap.rightOuter,
      cap.pad,
      cap.bend,
    ).path;
    return (path: path, centerAt: path.computeMetrics().single.length / 2);
  }

  ({
    Offset leftOuter,
    Offset rightOuter,
    Offset corner,
    Offset inwardLeft,
    Offset inwardRight,
    Offset leftVertex,
    Offset rightVertex,
    Offset peak,
    double inset,
    double pad,
    double bend,
  })
  _cap(Offset center, double radius, {required bool upper}) {
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
    return (
      leftOuter: leftVertex + inwardLeft * inset,
      rightOuter: rightVertex + inwardRight * inset,
      corner: peak + peakInset,
      inwardLeft: inwardLeft,
      inwardRight: inwardRight,
      leftVertex: leftVertex,
      rightVertex: rightVertex,
      peak: peak,
      inset: inset,
      pad: pad,
      bend: bend,
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
  bool shouldRepaint(covariant HexPainter oldDelegate) {
    final previous = oldDelegate.slot;
    return slot.color != previous.color ||
        !listEquals(slot.rim, previous.rim) ||
        slot.enabled != previous.enabled ||
        slot.title != previous.title ||
        slot.titleColor != previous.titleColor ||
        slot.titleRight != previous.titleRight ||
        slot.titleRightColor != previous.titleRightColor ||
        slot.footer != previous.footer ||
        slot.footerColor != previous.footerColor ||
        slot.footerLeft != previous.footerLeft ||
        slot.footerLeftColor != previous.footerLeftColor ||
        slot.sideLeft != previous.sideLeft ||
        slot.sideLeftColor != previous.sideLeftColor ||
        slot.sideRight != previous.sideRight ||
        slot.sideRightColor != previous.sideRightColor;
  }
}

/// Hover, press, and the waiting mark for one cell.
class _CellFrame extends StatefulWidget {
  const _CellFrame({
    required this.slot,
    required this.button,
    required this.interactive,
    required this.onTap,
    required this.child,
    super.key,
  });

  final HexSlot slot;
  final bool button;
  final bool interactive;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_CellFrame> createState() => _CellFrameState();
}

class _CellFrameState extends State<_CellFrame> with TickerProviderStateMixin {
  AnimationController? _burst;
  AnimationController? _spin;
  PressPainter? _press;
  final _lease = MotionLease();
  var _hover = false;

  @override
  void initState() {
    super.initState();
    if (widget.slot.busy) _spinning(true);
  }

  @override
  void didUpdateWidget(_CellFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.slot.busy != oldWidget.slot.busy) _spinning(widget.slot.busy);
  }

  @override
  void dispose() {
    _lease.set(false);
    _burst?.dispose();
    _spin?.dispose();
    super.dispose();
  }

  /// The cell plays an effect: the ring turns or a burst is in the air.
  void _rest() =>
      _lease.set(widget.slot.busy || (_burst?.isAnimating ?? false));

  void _spinning(bool on) {
    if (!on) {
      _spin?.stop();
      _rest();
      return;
    }
    final spin = _spin ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (!spin.isAnimating) spin.repeat();
    _lease.set(true);
  }

  void _tap() {
    final route = ModalRoute.of(context);
    widget.onTap();
    // A menu change leaves this route before the next frame. The burst
    // stays on the screen the tap did not leave.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || route?.isCurrent == false) return;
      _flash();
    });
  }

  void _flash() {
    if (MediaQuery.disableAnimationsOf(context)) return;
    var burst = _burst;
    if (burst == null) {
      burst = AnimationController(vsync: this, duration: pressDuration);
      burst.addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        _rest();
        setState(() {});
      });
      _burst = burst;
    }
    _press = PressPainter(color: widget.slot.color, clock: burst);
    burst.forward(from: 0);
    _lease.set(true);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final interactive = widget.interactive;
    final burst = _burst;
    final press = _press;
    final spin = _spin;
    Widget scene = Transform.scale(
      scale: _hover && interactive ? 1.02 : 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The border, the captions, and the picture are one layer. A press,
          // a hover, or the waiting ring above it moves and fades without
          // painting every glyph of the captions again.
          RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(painter: HexPainter(widget.slot)),
                widget.child,
              ],
            ),
          ),
          if (_hover && interactive)
            IgnorePointer(
              child: CustomPaint(
                painter: _RimPainter(widget.slot.color, widget.slot.rim),
              ),
            ),
          if (burst != null && burst.isAnimating && press != null)
            IgnorePointer(child: CustomPaint(painter: press)),
          if (widget.slot.badge != null && widget.slot.badge! > 0)
            IgnorePointer(child: _UnreadBadge(widget.slot.badge!)),
          if (widget.slot.busy && spin != null)
            IgnorePointer(
              child: RepaintBoundary(
                child: RotationTransition(
                  turns: spin,
                  child: CustomPaint(
                    painter: _WaitRingPainter(
                      widget.slot.color,
                      _markReach(widget.slot),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    if (!widget.button) return scene;
    final detector = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: interactive ? _tap : null,
      child: scene,
    );
    if (!interactive) return detector;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      // onEnter also fires when a new menu is built under a still cursor.
      // Hover starts only after the pointer actually moves.
      onHover: (_) {
        if (_hover) return;
        setState(() => _hover = true);
      },
      onExit: (_) {
        if (_hover) setState(() => _hover = false);
      },
      child: detector,
    );
  }
}

/// Red count on the vertex where the upper-right edge meets the right edge.
class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge(this.count);

  final int count;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final radius = side / 2;
        final center = Offset(radius, radius);
        final vertex =
            center + Offset(radius * cos(-pi / 6), radius * sin(-pi / 6));
        final badge = radius * 0.2;
        final dx = min(vertex.dx, side - badge);
        final dy = max(vertex.dy, badge);
        final label = count > 99 ? '99+' : '$count';
        return Stack(
          children: [
            Positioned(
              left: dx - badge,
              top: dy - badge,
              width: badge * 2,
              height: badge * 2,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: errorColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: const Color(0xFFFFFFFF),
                        fontFamily: 'OpenGost Type B',
                        fontSize: badge * 0.95,
                        height: 1,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A small grow for a control that sits inside a cell.
class HoverPop extends StatefulWidget {
  const HoverPop({required this.child, this.enabled = true, super.key});

  final Widget child;
  final bool enabled;

  @override
  State<HoverPop> createState() => _HoverPopState();
}

class _HoverPopState extends State<HoverPop> {
  var _hover = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled && _hover;
    return MouseRegion(
      cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onHover: (_) {
        if (!widget.enabled || _hover) return;
        setState(() => _hover = true);
      },
      onExit: (_) {
        if (_hover) setState(() => _hover = false);
      },
      child: Transform.scale(scale: on ? 1.06 : 1, child: widget.child),
    );
  }
}

class _RimPainter extends CustomPainter {
  const _RimPainter(this.color, this.rim);

  final Color color;
  final List<Color>? rim;

  static Color _lift(Color color) =>
      Color.lerp(color, const Color(0xFFFFFFFF), 0.16)!;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = max(1.4, radius * 0.03);
    final rim = this.rim;
    if (rim != null) {
      paintHexRim(canvas, center, radius, stroke, [
        for (final segment in rim) _lift(segment),
      ]);
      return;
    }
    canvas.drawPath(
      pointyHex(center, radius),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = _lift(color),
    );
  }

  @override
  bool shouldRepaint(covariant _RimPainter oldDelegate) =>
      oldDelegate.color != color || !listEquals(oldDelegate.rim, rim);
}

/// How far the center mark reaches, as a fraction of the vertex radius.
double _markReach(HexSlot slot) {
  if (slot.image != null) return 1.15 * 0.85 / 2;
  if (slot.icon != null) return 0.72 * iconScaleOf(slot.icon!) / 2;
  return 0.36;
}

class _WaitRingPainter extends CustomPainter {
  const _WaitRingPainter(this.color, this.mark);

  final Color color;

  /// Outer radius of the center mark, as a fraction of the vertex radius.
  final double mark;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final vertex = size.shortestSide / 2;
    // Labels sit on a path inset from the edge, and the glyphs hang inward.
    final textInner = vertex * (sqrt(3) / 2 - 0.16 - 0.095);
    final stroke = max(1.4, vertex * 0.03);
    final iconOuter = vertex * mark + stroke / 2;
    final labelInner = textInner - stroke / 2;
    final radius = iconOuter < labelInner
        ? (iconOuter + labelInner) / 2
        : labelInner;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    const segments = 3;
    final sweep = pi * 2 / segments * 0.62;
    final rect = Rect.fromCircle(center: center, radius: radius);
    for (var i = 0; i < segments; i++) {
      canvas.drawArc(rect, i * pi * 2 / segments, sweep, false, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaitRingPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.mark != mark;
}
