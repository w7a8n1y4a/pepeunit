import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The error message, drawn inside its own cell. The rest of the menu stays put.
class ErrorCell extends StatefulWidget {
  const ErrorCell({required this.message, required this.copyLabel, super.key});

  final String message;
  final String copyLabel;

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
            side * 0.28,
            side * 0.16,
            side * 0.08,
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SelectableText(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFFF3333),
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
                    width: side * 0.16,
                    height: side * 0.12,
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

class _CopyMarkPainter extends CustomPainter {
  const _CopyMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.4, size.shortestSide * 0.07)
      ..color = color;
    final radius = Radius.circular(size.width * 0.08);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.28,
          size.height * 0.08,
          size.width * 0.56,
          size.height * 0.56,
        ),
        radius,
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.12,
          size.height * 0.28,
          size.width * 0.56,
          size.height * 0.56,
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
