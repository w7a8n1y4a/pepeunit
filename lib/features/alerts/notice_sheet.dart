import 'dart:math';

import 'package:flutter/material.dart';

import '../../hive/hex_scene.dart';
import 'alerts_chrome.dart';
import 'notice_copy.dart';

/// A pointy hex drawn over the open list, a little smaller than seven cells
/// so the outer cells still show around it.
///
/// The table is monospaced and centered. A tap outside the hex closes it.
/// The copy mark copies, and the close mark on the upper-right ray dismisses.
class NoticeSheet extends StatelessWidget {
  const NoticeSheet({
    required this.text,
    required this.slots,
    required this.color,
    required this.copyLabel,
    required this.closeLabel,
    required this.onClose,
    super.key,
  });

  final String text;
  final List<HexSlot> slots;
  final Color color;
  final String copyLabel;
  final String closeLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final radius = _sheetRadius(size);
        final font = max(12.0, radius * 0.055);
        final mark = radius * 0.16;
        // Upper-right vertex, where the upper-right edge meets the right edge.
        const along = 0.76;
        final closeAt = Offset(
          radius + radius * along * cos(-pi / 6),
          radius + radius * along * sin(-pi / 6),
        );
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onClose,
              ),
            ),
            Positioned(
              left: size.width / 2 - radius,
              top: size.height / 2 - radius,
              width: radius * 2,
              height: radius * 2,
              child: ClipPath(
                clipper: const _PointClip(),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CustomPaint(painter: _SheetPainter(color)),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        radius * 0.28,
                        radius * 0.34,
                        radius * 0.28,
                        radius * 0.42,
                      ),
                      child: _TableText(text: text, fontSize: font),
                    ),
                    Align(
                      alignment: const Alignment(0, 0.78),
                      child: NoticeCopyButton(
                        text: text,
                        label: copyLabel,
                        extent: mark,
                      ),
                    ),
                    Positioned(
                      left: closeAt.dx - mark / 2,
                      top: closeAt.dy - mark / 2,
                      child: NoticeCloseButton(
                        label: closeLabel,
                        extent: mark,
                        onTap: onClose,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Vertex radius of a hex about 15% inside the seven-cell cluster.
double _sheetRadius(Size size) {
  const cells = <(int, int)>[
    (0, 0),
    (1, 0),
    (1, -1),
    (0, -1),
    (-1, 0),
    (-1, 1),
    (0, 1),
  ];
  final fitted = HexLayout.fit([
    for (var i = 0; i < cells.length; i++)
      HexSlot(
        id: 'sheet-$i',
        title: '',
        color: const Color(0xFFFFFFFF),
        q: cells[i].$1,
        r: cells[i].$2,
      ),
  ], size);
  final mid = Offset(size.width / 2, size.height / 2);
  var reach = size.shortestSide * 0.42;
  for (final placed in fitted.placed) {
    final far = (placed.center - mid).distance + placed.radius;
    if (far > reach) reach = far;
  }
  return reach * 0.85;
}

class _TableText extends StatelessWidget {
  const _TableText({required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final style = noticeMono(fontSize);
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width;
    final height = painter.height;
    painter.dispose();
    final table = Text(
      text,
      key: const ValueKey('notice-sheet'),
      textAlign: TextAlign.left,
      style: style,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewW = constraints.maxWidth;
        final viewH = constraints.maxHeight;
        return SingleChildScrollView(
          child: SizedBox(
            width: viewW,
            height: max(height, viewH),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: max(width, viewW),
                height: max(height, viewH),
                child: Center(child: table),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PointClip extends CustomClipper<Path> {
  const _PointClip();

  @override
  Path getClip(Size size) =>
      pointyHex(Offset(size.width / 2, size.height / 2), size.shortestSide / 2);

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _SheetPainter extends CustomPainter {
  const _SheetPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.shortestSide / 2;
    final center = Offset(size.width / 2, size.height / 2);
    final path = pointyHex(center, radius * 0.98);
    canvas.drawPath(path, Paint()..color = hexFill);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.6, radius * 0.025)
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _SheetPainter oldDelegate) =>
      oldDelegate.color != color;
}
