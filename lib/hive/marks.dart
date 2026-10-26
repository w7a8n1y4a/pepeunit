import 'dart:math';

import 'package:flutter/material.dart';

/// Chevron used by pagers and the timezone stepper.
class ChevronMarkPainter extends CustomPainter {
  const ChevronMarkPainter({required this.left, required this.color});

  final bool left;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.6, size.shortestSide * 0.09)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    final mid = size.height / 2;
    final path = Path();
    if (left) {
      path
        ..moveTo(size.width * 0.66, size.height * 0.24)
        ..lineTo(size.width * 0.34, mid)
        ..lineTo(size.width * 0.66, size.height * 0.76);
    } else {
      path
        ..moveTo(size.width * 0.34, size.height * 0.24)
        ..lineTo(size.width * 0.66, mid)
        ..lineTo(size.width * 0.34, size.height * 0.76);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ChevronMarkPainter oldDelegate) =>
      oldDelegate.left != left || oldDelegate.color != color;
}

/// Two overlapping sheets. The error cell and the summary cell share this mark.
class CopyMarkPainter extends CustomPainter {
  const CopyMarkPainter(this.color);

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
  bool shouldRepaint(covariant CopyMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}
