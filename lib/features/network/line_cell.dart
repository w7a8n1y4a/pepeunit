import 'dart:math';

import 'package:flutter/material.dart';

/// One line inside a cell. [onSubmit] receives the trimmed text.
class LineCell extends StatefulWidget {
  const LineCell({
    required this.hint,
    required this.color,
    required this.onSubmit,
    this.error,
    super.key,
  });

  final String hint;
  final Color color;
  final ValueChanged<String> onSubmit;
  final String? error;

  @override
  State<LineCell> createState() => _LineCellState();
}

class _LineCellState extends State<LineCell> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final font = side * 0.07;
        return Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: side * 0.16,
              vertical: side * 0.2,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: side * 0.16,
                  child: TextField(
                    controller: _controller,
                    focusNode: _focus,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFFFFFFF),
                      fontFamily: 'OpenGost Type B',
                      fontSize: font,
                      height: 1,
                      decoration: TextDecoration.none,
                    ),
                    cursorColor: widget.color,
                    decoration: InputDecoration(
                      isCollapsed: true,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      hintText: widget.hint,
                      hintStyle: TextStyle(
                        color: const Color(0xFFA1A1AA),
                        fontFamily: 'OpenGost Type B',
                        fontSize: font,
                        height: 1,
                      ),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) {
                      final text = value.trim();
                      if (text.isEmpty) return;
                      widget.onSubmit(text);
                      _controller.clear();
                    },
                  ),
                ),
                SizedBox(height: side * 0.03),
                Container(height: max(1, side * 0.008), color: widget.color),
                SizedBox(
                  height: side * 0.16,
                  child: Center(
                    child: Text(
                      widget.error ?? '',
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: widget.color,
                        decoration: TextDecoration.none,
                        fontFamily: 'OpenGost Type B',
                        fontSize: side * 0.045,
                        height: 1.1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class MetricsCell extends StatelessWidget {
  const MetricsCell({required this.lines, super.key});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: side * 0.16,
            vertical: side * 0.2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final line in lines)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      line,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFFFFFFF),
                        decoration: TextDecoration.none,
                        fontFamily: 'OpenGost Type B',
                        fontSize: side * 0.08,
                        height: 1.15,
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
