import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../hive/bevel.dart';
import '../../hive/grain.dart';
import '../../hive/hex_scene.dart';
import '../../hive/hint.dart';
import '../code/code_modal.dart';
import 'library_menu_page.dart';

TextStyle _style(double size, Color color) => TextStyle(
  color: color,
  fontFamily: 'OpenGost Type B',
  fontSize: size,
  decoration: TextDecoration.none,
);

/// Find in the open article: a small bar over the text with a field, the
/// place of the current match among all of them, a step to the previous and
/// the next one, and a close mark. The browser cannot do it for the page:
/// the web build draws the text on a canvas, so it has nothing to search.
///
/// - Typing marks the matches at once ([onChanged]). Enter steps to the next
///   one, Shift+Enter to the previous one ([onStep]), Escape closes.
/// - The matches are counted by the text, so the bar only shows [count] and
///   [current].
class DocFindBar extends StatelessWidget {
  const DocFindBar({
    required this.controller,
    required this.focusNode,
    required this.language,
    required this.font,
    required this.count,
    required this.current,
    required this.onChanged,
    required this.onStep,
    required this.onClose,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String language;
  final double font;

  /// How many matches the text has.
  final int count;

  /// The match the text shows, from zero.
  final int current;
  final ValueChanged<String> onChanged;
  final void Function(int step) onStep;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final asked = controller.text.isNotEmpty;
    final none = asked && count == 0;
    final mark = font * 2.0;
    return Focus(
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.escape) {
          onClose();
          return KeyEventResult.handled;
        }
        // Enter alone is the field's own submit, which steps forward.
        if ((key == LogicalKeyboardKey.enter ||
                key == LogicalKeyboardKey.numpadEnter) &&
            HardwareKeyboard.instance.isShiftPressed) {
          onStep(-1);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: SizedBox(
        height: font * 3.0,
        child: BevelFrame(
          color: libraryColor,
          width: max(1.4, font * 0.12),
          radius: font * 0.8,
          child: GrainBox(
            tile: cellGrain,
            opacity: modalFillOpacity,
            child: Padding(
              padding: EdgeInsets.fromLTRB(font * 1.0, 0, font * 0.3, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      textField: true,
                      label: libErrorText(
                        language,
                        'Найти в статье',
                        'Find in the article',
                      ),
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        autofocus: true,
                        cursorColor: libraryColor,
                        style: _style(font * 1.15, const Color(0xFFFFFFFF)),
                        decoration: InputDecoration.collapsed(
                          hintText: libErrorText(
                            language,
                            'Найти в статье',
                            'Find in the article',
                          ),
                          hintStyle: _style(font * 1.15, hexMuted),
                        ),
                        // The field keeps the focus after Enter.
                        onEditingComplete: () {},
                        onChanged: onChanged,
                        onSubmitted: (_) => onStep(1),
                      ),
                    ),
                  ),
                  SizedBox(width: font * 0.5),
                  if (asked)
                    Text(
                      none ? '0/0' : '${current + 1}/$count',
                      style: _style(font * 0.95, none ? errorColor : hexMuted),
                    ),
                  _StepMark(
                    label: libErrorText(language, 'Предыдущее', 'Previous'),
                    extent: mark,
                    up: true,
                    enabled: count > 0,
                    onTap: () => onStep(-1),
                  ),
                  _StepMark(
                    label: libErrorText(language, 'Следующее', 'Next'),
                    extent: mark,
                    up: false,
                    enabled: count > 0,
                    onTap: () => onStep(1),
                  ),
                  CodeCloseMark(
                    label: libErrorText(
                      language,
                      'Закрыть поиск по статье',
                      'Close find',
                    ),
                    extent: mark,
                    onTap: onClose,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A chevron that steps along the matches.
class _StepMark extends StatelessWidget {
  const _StepMark({
    required this.label,
    required this.extent,
    required this.up,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final double extent;
  final bool up;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HintTarget(
      id: up ? 'find-previous' : 'find-next',
      title: label,
      color: libraryColor,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: HoverPop(
            enabled: enabled,
            child: SizedBox(
              width: extent,
              height: extent,
              child: CustomPaint(
                painter: _StepPainter(
                  up: up,
                  color: enabled ? const Color(0xFFFFFFFF) : hexMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepPainter extends CustomPainter {
  const _StepPainter({required this.up, required this.color});

  final bool up;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final a = size.width * 0.17;
    final sign = up ? -1 : 1;
    final path = Path()
      ..moveTo(cx - a, cy - sign * a * 0.5)
      ..lineTo(cx, cy + sign * a * 0.5)
      ..lineTo(cx + a, cy - sign * a * 0.5);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _StepPainter oldDelegate) =>
      oldDelegate.up != up || oldDelegate.color != color;
}
