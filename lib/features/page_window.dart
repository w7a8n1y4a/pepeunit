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

/// А-Я / Я-А above the stroke, and the page arrows under it.
///
/// Unit, user, and repository search share this column.
class OrderWindow extends StatelessWidget {
  const OrderWindow({
    required this.orders,
    required this.selected,
    required this.onOrder,
    required this.range,
    required this.canBack,
    required this.canForward,
    required this.previousLabel,
    required this.nextLabel,
    required this.onStep,
    super.key,
  });

  final List<({String value, String label})> orders;
  final String selected;
  final ValueChanged<String> onOrder;
  final String range;
  final bool canBack;
  final bool canForward;
  final String previousLabel;
  final String nextLabel;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final style = TextStyle(
          fontFamily: 'OpenGost Type B',
          fontSize: cellFont(side),
          decoration: TextDecoration.none,
          height: 1.05,
        );
        return Padding(
          padding: EdgeInsets.fromLTRB(
            side * 0.12,
            side * 0.22,
            side * 0.12,
            side * 0.16,
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    for (final order in orders)
                      Expanded(child: _word(order, style)),
                  ],
                ),
              ),
              Container(
                height: 1,
                margin: EdgeInsets.symmetric(horizontal: side * 0.06),
                color: const Color(0xFFA1A1AA),
              ),
              Expanded(
                child: PageWindow(
                  range: range,
                  canBack: canBack,
                  canForward: canForward,
                  previousLabel: previousLabel,
                  nextLabel: nextLabel,
                  onStep: onStep,
                  style: style,
                  chevronExtent: side * 0.18,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _word(({String value, String label}) order, TextStyle style) {
    final on = selected == order.value;
    return Semantics(
      button: true,
      selected: on,
      label: order.label,
      excludeSemantics: true,
      onTap: () => onOrder(order.value),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onOrder(order.value),
        child: HoverPop(
          child: Center(
            child: Text(
              order.label,
              style: style.copyWith(
                color: on ? const Color(0xFFFFFFFF) : hexMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
