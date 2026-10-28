import 'dart:math';

import 'package:flutter/material.dart';

import '../../account/alerts.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../hive/marks.dart';
import '../../locale/languages.dart';

/// UTC summary time. Hour and minute change on their own and are stored at once.
class AlertTimeCell extends StatelessWidget {
  const AlertTimeCell({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final time = model.vault.alerts.time;
    final parts = time.split(':');
    return Semantics(
      label: time,
      container: true,
      explicitChildNodes: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final side = constraints.maxWidth;
          final style = TextStyle(
            fontFamily: 'OpenGost Type B',
            fontSize: cellFont(side),
            color: const Color(0xFFFFFFFF),
            decoration: TextDecoration.none,
            height: 1.05,
          );
          return Padding(
            padding: EdgeInsets.fromLTRB(
              side * 0.12,
              side * 0.28,
              side * 0.12,
              side * 0.16,
            ),
            child: Column(
              children: [
                Expanded(
                  child: _StepRow(
                    value: parts[0],
                    style: style,
                    extent: side * 0.18,
                    previous: phrase(language, {
                      'ru': 'Предыдущий час',
                      'en': 'Previous hour',
                    }),
                    next: phrase(language, {
                      'ru': 'Следующий час',
                      'en': 'Next hour',
                    }),
                    onPrevious: () =>
                        model.setAlertTime(stepAlertHour(time, -1)),
                    onNext: () => model.setAlertTime(stepAlertHour(time, 1)),
                  ),
                ),
                Container(
                  height: max(1, side * 0.006),
                  margin: EdgeInsets.symmetric(horizontal: side * 0.06),
                  color: const Color(0xFFA1A1AA),
                ),
                Expanded(
                  child: _StepRow(
                    value: parts[1],
                    style: style,
                    extent: side * 0.18,
                    previous: phrase(language, {
                      'ru': 'Предыдущая минута',
                      'en': 'Previous minute',
                    }),
                    next: phrase(language, {
                      'ru': 'Следующая минута',
                      'en': 'Next minute',
                    }),
                    onPrevious: () =>
                        model.setAlertTime(stepAlertMinute(time, -1)),
                    onNext: () => model.setAlertTime(stepAlertMinute(time, 1)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.value,
    required this.style,
    required this.extent,
    required this.previous,
    required this.next,
    required this.onPrevious,
    required this.onNext,
  });

  final String value;
  final TextStyle style;
  final double extent;
  final String previous;
  final String next;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Step(left: true, extent: extent, label: previous, onTap: onPrevious),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: style),
          ),
        ),
        _Step(left: false, extent: extent, label: next, onTap: onNext),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.left,
    required this.extent,
    required this.label,
    required this.onTap,
  });

  final bool left;
  final double extent;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: HoverPop(
          child: SizedBox(
            width: extent,
            height: extent,
            child: CustomPaint(
              painter: ChevronMarkPainter(
                left: left,
                color: const Color(0xFFFFFFFF),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
