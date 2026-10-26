import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../hive/hex_scene.dart';
import '../../hive/marks.dart';
import '../line_input.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return;
    widget.onSubmit(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return LineInput(
      color: widget.color,
      controller: _controller,
      hint: widget.hint,
      issue: widget.error ?? '',
      onSubmitted: _submit,
    );
  }
}

class SummaryPage {
  const SummaryPage({required this.title, required this.lines});

  final String title;
  final List<String> lines;
}

class MetricsCell extends StatefulWidget {
  const MetricsCell({
    required this.lines,
    this.pages = const [],
    this.copyText,
    this.copyLabel,
    this.prevLabel,
    this.nextLabel,
    super.key,
  });

  final List<String> lines;
  final List<SummaryPage> pages;
  final String? copyText;
  final String? copyLabel;
  final String? prevLabel;
  final String? nextLabel;

  @override
  State<MetricsCell> createState() => _MetricsCellState();
}

class _MetricsCellState extends State<MetricsCell> {
  var _index = 0;
  Timer? _copiedReset;
  var _copied = false;

  @override
  void dispose() {
    _copiedReset?.cancel();
    super.dispose();
  }

  Future<void> _copy() async {
    final text = widget.copyText;
    if (text == null || text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    setState(() => _copied = true);
    _copiedReset?.cancel();
    _copiedReset = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => _copied = false);
    });
  }

  void _step(int delta, int count) {
    if (count <= 1) return;
    setState(() => _index = (_index + delta + count) % count);
  }

  @override
  Widget build(BuildContext context) {
    final allPages = widget.pages.isNotEmpty
        ? widget.pages
        : [SummaryPage(title: '', lines: widget.lines)];
    final safeIndex = _index.clamp(0, allPages.length - 1);
    final activeLines = allPages[safeIndex].lines;
    final hasFooter = allPages.length > 1 || widget.copyText != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            side * 0.15,
            side * 0.24,
            side * 0.15,
            hasFooter ? side * 0.12 : side * 0.2,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final line in activeLines)
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
                              fontSize: side * 0.072,
                              height: 1.15,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (hasFooter) ...[
                Container(
                  height: max(1, side * 0.005),
                  margin: EdgeInsets.symmetric(
                    horizontal: side * 0.08,
                    vertical: side * 0.015,
                  ),
                  color: hexMuted,
                ),
                SizedBox(
                  height: side * 0.15,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (allPages.length > 1)
                        Semantics(
                          button: true,
                          label: widget.prevLabel ?? 'Previous',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _step(-1, allPages.length),
                            child: SizedBox(
                              width: side * 0.15,
                              height: side * 0.15,
                              child: const CustomPaint(
                                painter: ChevronMarkPainter(
                                  left: true,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (widget.copyText != null)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: side * 0.03,
                          ),
                          child: Semantics(
                            button: true,
                            label: widget.copyLabel ?? 'Copy URL',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _copy,
                              child: SizedBox(
                                width: side * 0.14,
                                height: side * 0.13,
                                child: CustomPaint(
                                  painter: CopyMarkPainter(
                                    _copied
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFFFFFFF),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (allPages.length > 1)
                        Semantics(
                          button: true,
                          label: widget.nextLabel ?? 'Next',
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _step(1, allPages.length),
                            child: SizedBox(
                              width: side * 0.15,
                              height: side * 0.15,
                              child: const CustomPaint(
                                painter: ChevronMarkPainter(
                                  left: false,
                                  color: Color(0xFFFFFFFF),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
