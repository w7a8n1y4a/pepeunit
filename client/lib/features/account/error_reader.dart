import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The error message, drawn inside its own cell. The rest of the menu stays put.
class ErrorCell extends StatefulWidget {
  const ErrorCell({
    required this.message,
    required this.copyLabel,
    required this.color,
    super.key,
  });

  final String message;
  final String copyLabel;
  final Color color;

  @override
  State<ErrorCell> createState() => _ErrorCellState();
}

class _ErrorCellState extends State<ErrorCell> {
  Timer? _copiedReset;
  var _copied = false;

  @override
  void dispose() {
    _copiedReset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.message));
    if (!mounted) return;
    setState(() => _copied = true);
    _copiedReset?.cancel();
    _copiedReset = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            side * 0.16,
            side * 0.26,
            side * 0.16,
            side * 0.16,
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: widget.color,
                      decoration: TextDecoration.none,
                      fontFamily: 'OpenGost Type B',
                      fontSize: max(10, side * 0.055),
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              Semantics(
                button: true,
                label: widget.copyLabel,
                child: GestureDetector(
                  onTap: _copy,
                  behavior: HitTestBehavior.opaque,
                  child: SizedBox(
                    width: side * 0.18,
                    height: side * 0.16,
                    child: CustomPaint(
                      painter: _CopyMarkPainter(
                        _copied
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Two overlapping sheets, the same copy mark as the previous web client.
class _CopyMarkPainter extends CustomPainter {
  const _CopyMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * 0.07
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final radius = Radius.circular(size.shortestSide * 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.34,
          size.height * 0.08,
          size.width * 0.54,
          size.height * 0.62,
        ),
        radius,
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.1,
          size.height * 0.28,
          size.width * 0.54,
          size.height * 0.62,
        ),
        radius,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _CopyMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
