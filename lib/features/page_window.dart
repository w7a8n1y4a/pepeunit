import 'package:flutter/material.dart';

import '../hive/hex_scene.dart';
import '../hive/marks.dart';

/// Previous and next arrows with the `start-end of count` label between them.
///
/// Search lists and the notice filter share this row. The arrows stay muted
/// until the caller says another page exists.
class PageWindow extends StatelessWidget {
  const PageWindow({
    required this.range,
    required this.canBack,
    required this.canForward,
    required this.previousLabel,
    required this.nextLabel,
    required this.onStep,
    required this.style,
    required this.chevronExtent,
    super.key,
  });

  final String range;
  final bool canBack;
  final bool canForward;
  final String previousLabel;
  final String nextLabel;
  final ValueChanged<int> onStep;
  final TextStyle style;
  final double chevronExtent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _chevron(
          left: true,
          enabled: canBack,
          label: previousLabel,
          onTap: () => onStep(-1),
        ),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              range,
              style: style.copyWith(color: const Color(0xFFFFFFFF)),
            ),
          ),
        ),
        _chevron(
          left: false,
          enabled: canForward,
          label: nextLabel,
          onTap: () => onStep(1),
        ),
      ],
    );
  }

  Widget _chevron({
    required bool left,
    required bool enabled,
    required String label,
    required VoidCallback onTap,
  }) {
    final color = enabled ? const Color(0xFFFFFFFF) : hexMuted;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : null,
        child: HoverPop(
          enabled: enabled,
          child: SizedBox(
            width: chevronExtent,
            height: chevronExtent,
            child: CustomPaint(
              painter: ChevronMarkPainter(left: left, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
