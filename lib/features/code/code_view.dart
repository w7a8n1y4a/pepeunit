import 'dart:math';

import 'package:flutter/material.dart';

import '../../hive/hex_scene.dart';
import 'code_highlight.dart';

/// Monospace for code and logs. OpenGost has no mono face.
const codeMonoFamily = 'JetBrains Mono';

TextStyle codeMono(double fontSize, {Color color = const Color(0xFFFFFFFF)}) {
  return TextStyle(
    color: color,
    fontFamily: codeMonoFamily,
    fontSize: fontSize,
    height: 1.35,
    decoration: TextDecoration.none,
  );
}

/// Every row of code takes the same height, wrapped or not, so the line
/// numbers stay level with the text.
StrutStyle codeStrut(double fontSize) {
  return StrutStyle(
    fontFamily: codeMonoFamily,
    fontSize: fontSize,
    height: 1.35,
    forceStrutHeight: true,
  );
}

/// The field keeps room for the caret: gap 1 plus cursor width 2. The view
/// keeps it too, so a text wraps the same way in both.
const _caretRoom = 3.0;

/// Right edge a code body leaves free for the scroll bar, so the bar never
/// covers text. [CodeLayout] measures without it.
const codeBarRoom = 14.0;

/// Wrapped row heights of a text at a width. The panel measures once and
/// hands the result to its view or editor, so a keystroke lays the text out
/// one time, not once for the frame and once for the body.
class CodeLayout {
  CodeLayout._({
    required this.text,
    required this.fontSize,
    required this.width,
    required this.scaler,
    required this.lines,
    required this.heights,
    required this.lineHeight,
    required this.gutterWidth,
  });

  static CodeLayout? _last;

  /// The layout of [text] at [width]. The last one is reused while its
  /// inputs stay the same.
  static CodeLayout of(
    BuildContext context, {
    required String text,
    required double fontSize,
    required double width,
  }) {
    final scaler = MediaQuery.textScalerOf(context);
    final last = _last;
    if (last != null &&
        last.fontSize == fontSize &&
        last.width == width &&
        last.scaler == scaler &&
        last.text == text) {
      return last;
    }
    return _last = _measure(text, fontSize, width, scaler);
  }

  static CodeLayout _measure(
    String text,
    double fontSize,
    double width,
    TextScaler scaler,
  ) {
    final style = codeMono(fontSize);
    final strut = codeStrut(fontSize);
    TextPainter painter(String line) => TextPainter(
      text: TextSpan(text: line, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      strutStyle: strut,
    );
    final sample = painter('0')..layout();
    final lineHeight = sample.preferredLineHeight;
    final cell = sample.width;
    sample.dispose();
    final lines = text.split('\n');
    final gutterWidth = cell * lines.length.toString().length + fontSize;
    final available = max(1.0, width - gutterWidth - _caretRoom);
    final columns = max(1, (available / cell).floor());
    final heights = <double>[];
    for (final line in lines) {
      // Plain ASCII in a monospace face wraps by count. Anything else is
      // measured, because a fallback glyph has its own width.
      if (line.length <= columns && _plain(line)) {
        heights.add(lineHeight);
        continue;
      }
      final probe = painter(line.isEmpty ? ' ' : line)
        ..layout(maxWidth: available);
      heights.add(max(lineHeight, probe.height));
      probe.dispose();
    }
    return CodeLayout._(
      text: text,
      fontSize: fontSize,
      width: width,
      scaler: scaler,
      lines: lines,
      heights: heights,
      lineHeight: lineHeight,
      gutterWidth: gutterWidth,
    );
  }

  static bool _plain(String line) {
    for (final unit in line.codeUnits) {
      if (unit < 0x20 || unit > 0x7E) return false;
    }
    return true;
  }

  final String text;
  final double fontSize;
  final double width;
  final TextScaler scaler;
  final List<String> lines;
  final List<double> heights;
  final double lineHeight;
  final double gutterWidth;

  double get total => heights.fold(0.0, (sum, h) => sum + h);
}

/// Thin visible bars, one look for every code body.
class CodeScrollbar extends StatelessWidget {
  const CodeScrollbar({
    required this.controller,
    required this.child,
    super.key,
  });

  final ScrollController controller;
  final Widget child;

  static final _theme = ScrollbarThemeData(
    thumbVisibility: const WidgetStatePropertyAll(true),
    trackVisibility: const WidgetStatePropertyAll(true),
    thickness: const WidgetStatePropertyAll(8),
    radius: const Radius.circular(4),
    thumbColor: const WidgetStatePropertyAll(Color(0xFF8A8A92)),
    trackColor: const WidgetStatePropertyAll(Color(0xFF2C2C32)),
    trackBorderColor: const WidgetStatePropertyAll(Color(0x00000000)),
  );

  @override
  Widget build(BuildContext context) {
    return ScrollbarTheme(
      data: _theme,
      child: Scrollbar(controller: controller, child: child),
    );
  }
}

/// Line number column cell of one row.
Widget _number(int line, CodeLayout layout, {Color ink = hexMuted}) {
  return SizedBox(
    width: layout.gutterWidth,
    child: SelectionContainer.disabled(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: EdgeInsets.only(right: layout.fontSize * 0.7),
          child: Text(
            '$line',
            strutStyle: codeStrut(layout.fontSize),
            style: codeMono(layout.fontSize, color: ink),
          ),
        ),
      ),
    ),
  );
}

/// Read-only code: line numbers, syntax color, long lines wrap. A text that
/// does not fit scrolls. Selecting skips the numbers.
class CodeView extends StatefulWidget {
  const CodeView({
    required this.layout,
    this.language = CodeLanguage.auto,
    super.key,
  });

  final CodeLayout layout;
  final CodeLanguage language;

  @override
  State<CodeView> createState() => _CodeViewState();
}

class _CodeViewState extends State<CodeView> {
  final _scroll = ScrollController();
  late List<List<CodeToken>> _tokens = _tokenize();

  List<List<CodeToken>> _tokenize() =>
      codeTokens(widget.layout.text, widget.language);

  @override
  void didUpdateWidget(CodeView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.layout.text != widget.layout.text ||
        oldWidget.language != widget.language) {
      _tokens = _tokenize();
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    final style = codeMono(layout.fontSize);
    final strut = codeStrut(layout.fontSize);
    return CodeScrollbar(
      controller: _scroll,
      child: SelectionArea(
        child: ListView.builder(
          controller: _scroll,
          padding: const EdgeInsets.only(right: codeBarRoom),
          itemCount: layout.lines.length,
          itemExtentBuilder: (index, _) => layout.heights[index],
          itemBuilder: (context, index) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _number(index + 1, layout),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: _caretRoom),
                  child: Text.rich(
                    TextSpan(
                      style: style,
                      children: codeLineSpans(_tokens[index], style),
                    ),
                    strutStyle: strut,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Editable code with the same numbers and wrap as [CodeView]. [errorLine]
/// colors one number.
class CodeEditor extends StatefulWidget {
  const CodeEditor({
    required this.controller,
    required this.layout,
    required this.onChanged,
    this.errorLine,
    super.key,
  });

  final TextEditingController controller;

  /// Layout of the controller's current text.
  final CodeLayout layout;
  final int? errorLine;
  final VoidCallback onChanged;

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = widget.layout;
    final style = codeMono(layout.fontSize);
    final strut = codeStrut(layout.fontSize);
    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(
        builder: (context, constraints) => CodeScrollbar(
          controller: _scroll,
          child: SingleChildScrollView(
            controller: _scroll,
            padding: const EdgeInsets.only(right: codeBarRoom),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IgnorePointer(
                    child: Column(
                      children: [
                        for (var i = 0; i < layout.heights.length; i++)
                          SizedBox(
                            height: layout.heights[i],
                            child: _number(
                              i + 1,
                              layout,
                              ink: i + 1 == widget.errorLine
                                  ? errorColor
                                  : hexMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: widget.controller,
                      maxLines: null,
                      autocorrect: false,
                      enableSuggestions: false,
                      smartDashesType: SmartDashesType.disabled,
                      smartQuotesType: SmartQuotesType.disabled,
                      style: style,
                      strutStyle: strut,
                      cursorColor: const Color(0xFFFFFFFF),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => widget.onChanged(),
                    ),
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

/// A console: the newest row at the bottom, no line numbers. The list is
/// turned over, so the newest row stays in place by itself and an older page
/// added at the far end moves nothing. Reaching the top asks for that page.
class LogView extends StatefulWidget {
  const LogView({
    required this.count,
    required this.itemBuilder,
    required this.fontSize,
    required this.canLoadOlder,
    required this.onOlder,
    super.key,
  });

  /// Rows, newest first: index 0 is the bottom row.
  final int count;
  final IndexedWidgetBuilder itemBuilder;
  final double fontSize;

  /// An older page exists and none is on its way.
  final bool canLoadOlder;
  final VoidCallback onOlder;

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_check);
    _checkAfterFrame();
  }

  @override
  void didUpdateWidget(LogView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count ||
        oldWidget.canLoadOlder != widget.canLoadOlder) {
      _checkAfterFrame();
    }
  }

  @override
  void dispose() {
    _scroll.removeListener(_check);
    _scroll.dispose();
    super.dispose();
  }

  void _checkAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _check();
    });
  }

  /// The top is near, or the rows do not fill the panel yet.
  void _check() {
    if (!widget.canLoadOlder || !_scroll.hasClients) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - 48) widget.onOlder();
  }

  @override
  Widget build(BuildContext context) {
    return CodeScrollbar(
      controller: _scroll,
      child: SelectionArea(
        child: ListView.builder(
          controller: _scroll,
          reverse: true,
          padding: EdgeInsets.only(
            right: widget.fontSize * 1.4,
            bottom: widget.fontSize,
          ),
          itemCount: widget.count,
          itemBuilder: widget.itemBuilder,
        ),
      ),
    );
  }
}
