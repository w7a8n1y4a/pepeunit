import 'dart:math';

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
  });

  final String id;
  final String title;
  final Color color;
  final int q;
  final int r;
  final String? icon;
  final double iconScale;
}

class HexScene extends StatelessWidget {
  const HexScene({required this.slots, required this.onTap, super.key});

  final List<HexSlot> slots;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = HexLayout.fit(slots, constraints.biggest);
        return Stack(
          children: [
            CustomPaint(
              size: constraints.biggest,
              painter: HexPainter(layout),
            ),
            for (final placed in layout.placed)
              Positioned(
                left: placed.center.dx - placed.radius,
                top: placed.center.dy - placed.radius,
                width: placed.radius * 2,
                height: placed.radius * 2,
                child: Semantics(
                  button: true,
                  label: placed.slot.title,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(placed.slot.id),
                    child: placed.slot.icon == null
                        ? const SizedBox.expand()
                        : Center(
                            child: SvgPicture.asset(
                              placed.slot.icon!,
                              width: placed.radius * 0.72 * placed.slot.iconScale,
                              height: placed.radius * 0.72 * placed.slot.iconScale,
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
    final raw = [for (final slot in slots) MapEntry(slot, _axial(slot.q, slot.r))];
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
    final origin = Offset((size.width - width * scale) / 2, (size.height - height * scale) / 2);
    return HexLayout([
      for (final entry in raw)
        PlacedHex(
          entry.key,
          origin + Offset((entry.value.dx - minX + radius + 18) * scale, (entry.value.dy - minY + radius + 18) * scale),
          radius * scale,
        ),
    ]);
  }

  static Offset _axial(int q, int r) {
    return Offset(_step * sqrt(3) * (q + r / 2), _step * 1.5 * r);
  }
}

class HexPainter extends CustomPainter {
  HexPainter(this.layout);

  final HexLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    for (final placed in layout.placed) {
      final path = Path();
      for (var i = 0; i < 6; i++) {
        final angle = pi / 3 * i - pi / 2;
        final point = Offset(
          placed.center.dx + placed.radius * cos(angle),
          placed.center.dy + placed.radius * sin(angle),
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      path.close();
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
    final upperLeft = Offset(
      placed.center.dx + placed.radius * cos(7 * pi / 6),
      placed.center.dy + placed.radius * sin(7 * pi / 6),
    );
    final top = Offset(placed.center.dx, placed.center.dy - placed.radius);
    final edge = top - upperLeft;
    final dir = edge / edge.distance;
    var inward = Offset(-dir.dy, dir.dx);
    if ((upperLeft + inward - placed.center).distance > (upperLeft - inward - placed.center).distance) {
      inward = -inward;
    }
    final fontSize = max(11.0, placed.radius * 0.18);
    final painter = TextPainter(
      text: TextSpan(
        text: placed.slot.title,
        style: TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: fontSize,
          fontFamily: 'OpenGost Type B',
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: placed.radius * 0.95);
    final origin = upperLeft + dir * (edge.distance / 2) + inward * (painter.height / 2 + placed.radius * 0.11);
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(-pi / 6);
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HexPainter oldDelegate) => true;
}
