import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show SelectedContent;
import 'package:flutter/services.dart';
import 'package:url_launcher/link.dart';

import '../../hive/hex_scene.dart';
import '../../hive/hint.dart';
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
  const SummaryPage({
    required this.title,
    required this.lines,
    this.firstLineUrl,
    this.footerAddress,
  });

  final String title;
  final List<String> lines;

  /// Optional destination for the first line only.
  final String? firstLineUrl;

  /// An address-copy action below the page content, just above the divider.
  final ({String label, String url})? footerAddress;
}

class MetricsCell extends StatefulWidget {
  const MetricsCell({
    required this.lines,
    this.pages = const [],
    this.showCopyButton = false,
    this.linkColor = const Color(0xFFFFFFFF),
    this.copyLabel,
    this.prevLabel,
    this.nextLabel,
    super.key,
  });

  final List<String> lines;
  final List<SummaryPage> pages;

  /// Explicit copy action for address cells outside summaries.
  final bool showCopyButton;
  final Color linkColor;
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

  Future<void> _copy(String text) async {
    if (text.isEmpty) return;
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
    _copiedReset?.cancel();
    setState(() {
      _index = (_index + delta + count) % count;
      _copied = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final allPages = widget.pages.isNotEmpty
        ? widget.pages
        : [SummaryPage(title: '', lines: widget.lines)];
    final safeIndex = _index.clamp(0, allPages.length - 1);
    final activePage = allPages[safeIndex];
    final hasFooter =
        allPages.length > 1 ||
        widget.showCopyButton ||
        activePage.footerAddress != null;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final style = TextStyle(
          color: const Color(0xFFFFFFFF),
          decoration: TextDecoration.none,
          fontFamily: 'OpenGost Type B',
          fontSize: side * 0.072,
          height: 1.15,
        );
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
                child: LayoutBuilder(
                  builder: (context, bodyConstraints) => SelectionArea(
                    key: ValueKey(safeIndex),
                    child: SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: bodyConstraints.maxHeight,
                          minWidth: bodyConstraints.maxWidth,
                        ),
                        child: _SummarySelection(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (var i = 0; i < activePage.lines.length; i++)
                                if (i == 0 && activePage.firstLineUrl != null)
                                  _SummaryLink(
                                    url: activePage.firstLineUrl!,
                                    label: activePage.lines[i],
                                    color: widget.linkColor,
                                    style: style,
                                  )
                                else
                                  Text(
                                    activePage.lines[i],
                                    softWrap: true,
                                    textAlign: TextAlign.center,
                                    style: style,
                                  ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (activePage.footerAddress case final address?)
                _SummaryTextAction(
                  label: address.label,
                  copyMark: true,
                  color: _copied ? const Color(0xFF4CAF50) : widget.linkColor,
                  style: style,
                  onTap: () => _copy(address.url),
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
                        HintTarget(
                          id: 'summary-previous',
                          title: widget.prevLabel ?? 'Previous',
                          color: hexMuted,
                          child: Semantics(
                            button: true,
                            label: widget.prevLabel ?? 'Previous',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _step(-1, allPages.length),
                              child: HoverPop(
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
                          ),
                        ),
                      if (widget.showCopyButton)
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: side * 0.03,
                          ),
                          child: HintTarget(
                            id: 'button-copy',
                            title: widget.copyLabel ?? 'Copy',
                            color: hexMuted,
                            child: Semantics(
                              button: true,
                              label: widget.copyLabel ?? 'Copy',
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: () => _copy(activePage.lines.join('\n')),
                                child: HoverPop(
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
                          ),
                        ),
                      if (allPages.length > 1)
                        HintTarget(
                          id: 'summary-next',
                          title: widget.nextLabel ?? 'Next',
                          color: hexMuted,
                          child: Semantics(
                            button: true,
                            label: widget.nextLabel ?? 'Next',
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => _step(1, allPages.length),
                              child: HoverPop(
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

/// Each text widget is a summary row, so copying across rows keeps newlines.
class _SummarySelectionDelegate extends StaticSelectionContainerDelegate {
  @override
  SelectedContent? getSelectedContent() {
    final rows = [
      for (final selectable in selectables)
        if (selectable.getSelectedContent() case final content?)
          content.plainText,
    ];
    return rows.isEmpty ? null : SelectedContent(plainText: rows.join('\n'));
  }
}

class _SummarySelection extends StatefulWidget {
  const _SummarySelection({required this.child});

  final Widget child;

  @override
  State<_SummarySelection> createState() => _SummarySelectionState();
}

class _SummarySelectionState extends State<_SummarySelection> {
  final _delegate = _SummarySelectionDelegate();

  @override
  void dispose() {
    _delegate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      SelectionContainer(delegate: _delegate, child: widget.child);
}

/// The same plain colored text and hover motion as the alerts' Read all action.
class _SummaryLink extends StatelessWidget {
  const _SummaryLink({
    required this.url,
    required this.label,
    required this.color,
    required this.style,
  });

  final String url;
  final String label;
  final Color color;
  final TextStyle style;

  @override
  Widget build(BuildContext context) => Link(
    uri: Uri.parse(url),
    target: LinkTarget.blank,
    builder: (context, followLink) => _SummaryTextAction(
      label: label,
      color: color,
      style: style,
      onTap: followLink,
      link: true,
    ),
  );
}

class _SummaryTextAction extends StatelessWidget {
  const _SummaryTextAction({
    required this.label,
    required this.color,
    required this.style,
    required this.onTap,
    this.copyMark = false,
    this.link = false,
  });

  final String label;
  final Color color;
  final TextStyle style;
  final VoidCallback? onTap;
  final bool copyMark;
  final bool link;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      softWrap: true,
      textAlign: TextAlign.center,
      style: style.copyWith(color: color, decoration: TextDecoration.none),
    );
    // OpenGost Type B: capital А is 1000 units high in a 1700-unit em.
    // WidgetSpan applies the surrounding text scale to the icon as well.
    final capHeight = style.fontSize! * 1000 / 1700;
    return Semantics(
      link: link,
      button: !link,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: HoverPop(
          child: !copyMark
              ? text
              : Text.rich(
                  TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.baseline,
                        baseline: TextBaseline.alphabetic,
                        child: Padding(
                          padding: EdgeInsets.only(right: capHeight * 0.35),
                          child: CustomPaint(
                            size: Size(
                              capHeight * CopyMarkPainter.tightAspectRatio,
                              capHeight,
                            ),
                            painter: CopyMarkPainter(color, tight: true),
                          ),
                        ),
                      ),
                      TextSpan(text: label),
                    ],
                  ),
                  textAlign: TextAlign.center,
                  style: style.copyWith(
                    color: color,
                    decoration: TextDecoration.none,
                  ),
                ),
        ),
      ),
    );
  }
}
