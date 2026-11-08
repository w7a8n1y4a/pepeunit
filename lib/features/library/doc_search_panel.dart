import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../hive/bevel.dart';
import '../../hive/grain.dart';
import '../../hive/hex_scene.dart';
import '../../library/doc_search.dart';
import '../code/code_modal.dart';
import 'library_menu_page.dart';

TextStyle _style(double size, Color color, {double? height}) => TextStyle(
  color: color,
  fontFamily: 'OpenGost Type B',
  fontSize: size,
  height: height,
  decoration: TextDecoration.none,
);

/// The search of the documentation, the way the local search of VitePress
/// looks: a panel over the page with a field on top and the places found
/// under it. A hit is the article and the heading, with the words of the
/// query marked in both and in a piece of the text.
///
/// - Typing searches at once. Up and Down move along the hits, Enter opens
///   the one that is lit, Escape closes the panel. A pointer lights the hit
///   it moves over.
/// - A tap on a hit, or Enter, calls [onOpen] with its section; the panel
///   does not close itself, the owner does.
/// - A tap outside the panel calls [onClose].
class DocSearchPanel extends StatefulWidget {
  const DocSearchPanel({
    required this.index,
    required this.language,
    required this.font,
    required this.onOpen,
    required this.onClose,
    super.key,
  });

  final DocSearchIndex index;
  final String language;

  /// Size of the text of a hit. The rest follows it.
  final double font;
  final void Function(DocSection section) onOpen;
  final VoidCallback onClose;

  @override
  State<DocSearchPanel> createState() => _DocSearchPanelState();
}

class _DocSearchPanelState extends State<DocSearchPanel> {
  final _field = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();
  var _terms = const <String>[];
  var _hits = const <DocHit>[];
  var _lit = 0;

  @override
  void initState() {
    super.initState();
    // The page under the panel holds the focus, so the field's autofocus is
    // not taken: ask for it, and typing starts at once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _typed(String text) {
    setState(() {
      _terms = queryTerms(text);
      _hits = widget.index.search(text);
      _lit = 0;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _move(int step, double rowH, double viewport) {
    if (_hits.isEmpty) return;
    setState(() => _lit = (_lit + step).clamp(0, _hits.length - 1));
    if (!_scroll.hasClients) return;
    final top = _lit * rowH;
    final bottom = top + rowH;
    final from = _scroll.offset;
    if (top < from) {
      _scroll.jumpTo(top);
    } else if (bottom > from + viewport) {
      _scroll.jumpTo(bottom - viewport);
    }
  }

  void _open(int at) {
    if (at < 0 || at >= _hits.length) return;
    widget.onOpen(_hits[at].section);
  }

  @override
  Widget build(BuildContext context) {
    final font = widget.font;
    final language = widget.language;
    final asked = _field.text.trim();
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final margin = min(font * 1.2, size.width * 0.03);
        final width = min(size.width - margin * 2, font * 52);
        final top = max(margin, size.height * 0.07);
        final barH = font * 3.4;
        final rowH = font * 5.4;
        final room = max(font * 6, size.height - top - margin - barH - 1);
        final natural = _hits.isEmpty ? font * 5.5 : _hits.length * rowH;
        final listH = min(room, natural + font * 0.6);
        final viewport = listH - font * 0.6;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onClose,
                child: const ColoredBox(color: Color(0xB3000000)),
              ),
            ),
            Positioned(
              top: top,
              left: (size.width - width) / 2,
              width: width,
              height: barH + 1 + listH,
              child: Focus(
                onKeyEvent: (node, event) {
                  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                    return KeyEventResult.ignored;
                  }
                  final key = event.logicalKey;
                  if (key == LogicalKeyboardKey.escape) {
                    widget.onClose();
                    return KeyEventResult.handled;
                  }
                  if (key == LogicalKeyboardKey.arrowDown) {
                    _move(1, rowH, viewport);
                    return KeyEventResult.handled;
                  }
                  if (key == LogicalKeyboardKey.arrowUp) {
                    _move(-1, rowH, viewport);
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: BevelFrame(
                  color: libraryColor,
                  width: max(1.4, font * 0.12),
                  radius: font,
                  child: GrainBox(
                    tile: cellGrain,
                    opacity: modalFillOpacity,
                    child: Column(
                      children: [
                        SizedBox(
                          height: barH,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(
                              font * 1.1,
                              0,
                              font * 0.4,
                              0,
                            ),
                            child: Row(
                              children: [
                                SvgPicture.asset(
                                  'assets/icons/actions/search.svg',
                                  width: font * 1.5,
                                  height: font * 1.5,
                                ),
                                SizedBox(width: font * 0.8),
                                Expanded(
                                  child: Semantics(
                                    textField: true,
                                    label: libErrorText(
                                      language,
                                      'Поиск по документации',
                                      'Search the documentation',
                                    ),
                                    child: TextField(
                                      controller: _field,
                                      focusNode: _focus,
                                      autofocus: true,
                                      cursorColor: libraryColor,
                                      style: _style(
                                        font * 1.25,
                                        const Color(0xFFFFFFFF),
                                      ),
                                      textInputAction: TextInputAction.search,
                                      decoration: InputDecoration.collapsed(
                                        hintText: libErrorText(
                                          language,
                                          'Поиск по документации',
                                          'Search the documentation',
                                        ),
                                        hintStyle: _style(
                                          font * 1.25,
                                          hexMuted,
                                        ),
                                      ),
                                      onChanged: _typed,
                                      onSubmitted: (_) => _open(_lit),
                                    ),
                                  ),
                                ),
                                CodeCloseMark(
                                  label: libErrorText(
                                    language,
                                    'Закрыть поиск',
                                    'Close search',
                                  ),
                                  extent: font * 2.2,
                                  onTap: widget.onClose,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(height: 1, color: const Color(0x33FFFFFF)),
                        Expanded(
                          child: _hits.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: font,
                                    ),
                                    child: Text(
                                      asked.isEmpty
                                          ? libErrorText(
                                              language,
                                              'Введите слова из статьи',
                                              'Type words from an article',
                                            )
                                          : libErrorText(
                                              language,
                                              'Ничего не найдено по запросу «$asked»',
                                              'No results for “$asked”',
                                            ),
                                      textAlign: TextAlign.center,
                                      style: _style(font * 1.05, hexMuted),
                                    ),
                                  ),
                                )
                              : ListView.builder(
                                  controller: _scroll,
                                  padding: EdgeInsets.symmetric(
                                    vertical: font * 0.3,
                                  ),
                                  itemExtent: rowH,
                                  itemCount: _hits.length,
                                  itemBuilder: (context, i) => _HitRow(
                                    hit: _hits[i],
                                    terms: _terms,
                                    font: font,
                                    lit: i == _lit,
                                    onHover: () {
                                      if (_lit != i) setState(() => _lit = i);
                                    },
                                    onTap: () => _open(i),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The text of [text] with the [ranges] marked.
List<TextSpan> _marked(
  String text,
  List<String> terms,
  TextStyle base,
  Color mark,
) {
  final ranges = markRanges(text, terms);
  if (ranges.isEmpty) return [TextSpan(text: text, style: base)];
  final marked = base.copyWith(
    color: mark,
    backgroundColor: mark.withValues(alpha: 0.16),
  );
  final spans = <TextSpan>[];
  var at = 0;
  for (final range in ranges) {
    if (range.start > at) {
      spans.add(TextSpan(text: text.substring(at, range.start), style: base));
    }
    spans.add(
      TextSpan(text: text.substring(range.start, range.end), style: marked),
    );
    at = range.end;
  }
  if (at < text.length) {
    spans.add(TextSpan(text: text.substring(at), style: base));
  }
  return spans;
}

/// One hit: the article and the headings over the place on the first line,
/// a piece of the text on the second.
class _HitRow extends StatelessWidget {
  const _HitRow({
    required this.hit,
    required this.terms,
    required this.font,
    required this.lit,
    required this.onHover,
    required this.onTap,
  });

  final DocHit hit;
  final List<String> terms;
  final double font;
  final bool lit;
  final VoidCallback onHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final section = hit.section;
    final parts = [section.article.title, ...section.trail, ?section.heading];
    final spans = <TextSpan>[];
    for (var i = 0; i < parts.length; i++) {
      final last = i == parts.length - 1;
      if (i > 0) {
        spans.add(TextSpan(text: '  ›  ', style: _style(font, hexMuted)));
      }
      spans.addAll(
        _marked(
          parts[i],
          terms,
          _style(
            font * 1.05,
            last ? const Color(0xFFFFFFFF) : hexMuted,
            height: 1.25,
          ),
          libraryColor,
        ),
      );
    }
    final text = section.text;
    return Semantics(
      button: true,
      selected: lit,
      label: parts.join(', '),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onHover: (_) => onHover(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: font * 0.6,
              vertical: font * 0.15,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: lit ? const Color(0x14FFFFFF) : null,
                border: Border.all(
                  color: lit ? libraryColor : const Color(0x00000000),
                ),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: font * 0.7,
                  vertical: font * 0.35,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text.rich(
                      TextSpan(children: spans),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (text.isNotEmpty) ...[
                      SizedBox(height: font * 0.25),
                      Text.rich(
                        TextSpan(
                          children: _marked(
                            excerptOf(text, terms),
                            terms,
                            _style(font * 0.88, hexMuted, height: 1.25),
                            libraryColor,
                          ),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
