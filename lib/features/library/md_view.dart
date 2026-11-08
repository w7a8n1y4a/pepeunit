import 'dart:convert';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderSliverMultiBoxAdaptor;
import 'package:flutter/services.dart';

import '../../hive/bevel.dart';
import '../../hive/hex_scene.dart';
import '../../hive/marks.dart';
import '../../instances/link.dart';
import '../../library/doc_search.dart';
import '../../library/markdown.dart';
import '../code/code_highlight.dart';
import '../code/code_syntax.dart';
import '../code/code_view.dart';

/// Where a rendered diagram comes from. The service gets the diagram text in
/// the address and answers with a picture. Point this at your own server to
/// keep the text inside.
const mermaidRenderer = 'https://mermaid.ink/img/';

String mermaidUrl(String code) {
  final encoded = base64Url.encode(utf8.encode(code)).replaceAll('=', '');
  return '$mermaidRenderer$encoded?type=png&theme=dark&bgColor=14161B';
}

/// Colors of the `:::` blocks.
Color admonitionColor(MdAdmonitionKind kind) {
  switch (kind) {
    case MdAdmonitionKind.info:
      return const Color(0xFF2196F3);
    case MdAdmonitionKind.tip:
      return addColor;
    case MdAdmonitionKind.warning:
      return const Color(0xFFFF9800);
    case MdAdmonitionKind.danger:
      return errorColor;
    case MdAdmonitionKind.details:
      return hexMuted;
  }
}

/// A find in the open text: the words typed and the match that is current.
/// The view marks every match and scrolls to the current one.
class MdFind {
  const MdFind(this.query, this.current);

  final String query;

  /// Place of the current match among all of them, from zero.
  final int current;

  @override
  bool operator ==(Object other) =>
      other is MdFind && other.query == query && other.current == current;

  @override
  int get hashCode => Object.hash(query, current);
}

/// Lets the owner of a [MdView] scroll it to a heading.
class MdController {
  _MdViewState? _state;

  /// Scrolls to the heading with this anchor. False when the document has
  /// none.
  bool jump(String slug) => _state?._jump(slug) ?? false;

  void _attach(_MdViewState state) => _state = state;

  void _detach(_MdViewState state) {
    if (_state == state) _state = null;
  }
}

/// A markdown document drawn as a scrolling column. [font] is the size of
/// the running text; code is a little smaller.
///
/// A link is live only when [canOpen] says so. Any other link is drawn as a
/// plain term, so a reference to something the client does not have is not a
/// dead button.
class MdView extends StatefulWidget {
  const MdView({
    required this.doc,
    required this.font,
    required this.accent,
    required this.canOpen,
    required this.onOpen,
    this.controller,
    this.anchor,
    this.linkOf,
    this.find,
    this.onFound,
    this.sides = 0,
    this.lead = 0,
    this.trail = 0,
    super.key,
  });

  final MdDoc doc;
  final double font;
  final Color accent;
  final bool Function(String url) canOpen;
  final void Function(String url) onOpen;
  final MdController? controller;

  /// Heading the view scrolls to once it is drawn.
  final String? anchor;

  /// The address of the heading with this anchor. With it, a heading of level
  /// two to four has a mark in front of it that copies the address. Without
  /// it the headings carry no mark.
  final String Function(String slug)? linkOf;

  /// The words to mark in the text. The page cannot be searched by the
  /// browser: the web build draws it on a canvas, so the text has its own
  /// find. Code blocks and the titles of `:::` blocks are not searched.
  final MdFind? find;

  /// Called with how many matches [find] has in the text, after it changed.
  final void Function(int count)? onFound;

  /// Empty room on the left and on the right of the column.
  final double sides;

  /// How far the left edge of the view stands from the left edge of the
  /// screen. A wide screen has the sidebar there. The column leans toward the
  /// center of the screen by as much as the width allows.
  final double lead;

  /// How much of the right edge another panel covers. The column stays clear
  /// of it, and its scroll bar is still at the edge of the view, so the panel
  /// leaves the last [codeBarRoom] free.
  final double trail;

  @override
  State<MdView> createState() => _MdViewState();
}

class _MdViewState extends State<MdView> {
  final _scroll = ScrollController();
  final _list = GlobalKey();
  final _keys = <String, GlobalKey>{};

  /// The text that holds the current match of [MdView.find].
  final _matchKey = GlobalKey();

  /// Index in the list of the block that holds each match.
  var _matchAt = const <int>[];
  int? _reported;

  /// Index in the list of the block that holds each heading.
  final _at = <String, int>{};
  final _recognizers = <GestureRecognizer>[];
  List<Widget> _blocks = const [];
  var _ticket = 0;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _build();
    _jumpLater(widget.anchor);
  }

  @override
  void didUpdateWidget(MdView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (oldWidget.doc != widget.doc ||
        oldWidget.font != widget.font ||
        oldWidget.accent != widget.accent ||
        oldWidget.find != widget.find ||
        (oldWidget.linkOf == null) != (widget.linkOf == null)) {
      _build();
      if (oldWidget.doc != widget.doc) {
        if (_scroll.hasClients) _scroll.jumpTo(0);
        _jumpLater(widget.anchor);
      } else if (oldWidget.find != widget.find) {
        _goToMatch();
      }
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _disposeRecognizers();
    _scroll.dispose();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  void _jumpLater(String? slug) {
    if (slug == null || slug.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _jump(slug);
    });
  }

  /// A heading by its anchor, as the text spells it. Links write the same
  /// anchor in different ways (`env-json`, `envjson`, `фаиловои`), so a miss
  /// falls back to [anchorKey].
  String? _slugOf(String slug) {
    if (_keys.containsKey(slug)) return slug;
    final plain = anchorKey(slug);
    for (final key in _keys.keys) {
      if (anchorKey(key) == plain) return key;
    }
    return null;
  }

  bool _jump(String slug) {
    final found = _slugOf(slug);
    if (found == null) return false;
    _reach(found);
    return true;
  }

  /// Scrolls to a heading. The list builds only the blocks near the window,
  /// so a heading far away has no widget yet: the view moves toward its
  /// block, a window at a time, until the heading is built.
  Future<void> _reach(String slug) => _reachAt(
    _at[slug] ?? 0,
    () => _keys[slug]?.currentContext,
    alignment: 0.02,
  );

  /// The current match of the find comes into view, a third of the way down.
  void _goToMatch() {
    final find = widget.find;
    if (find == null || find.query.isEmpty) return;
    if (find.current < 0 || find.current >= _matchAt.length) return;
    _reachAt(
      _matchAt[find.current],
      () => _matchKey.currentContext,
      alignment: 0.3,
    );
  }

  /// Scrolls to the block at [index] until [widgetOf] has a widget, then to
  /// that widget.
  Future<void> _reachAt(
    int index,
    BuildContext? Function() widgetOf, {
    required double alignment,
  }) async {
    final ticket = ++_ticket;
    for (var step = 0; step < 40; step++) {
      if (!mounted || ticket != _ticket || !_scroll.hasClients) return;
      final heading = widgetOf();
      if (heading != null && heading.mounted) {
        Scrollable.ensureVisible(heading, alignment: alignment);
        return;
      }
      final position = _scroll.position;
      final list = _list.currentContext?.findRenderObject();
      if (list is! RenderSliverMultiBoxAdaptor) return;
      final first = list.firstChild;
      final last = list.lastChild;
      if (first == null || last == null) return;
      final window = position.viewportDimension * 0.8;
      final guess =
          position.maxScrollExtent * index / max(1, _blocks.length - 1);
      double target;
      if (list.indexOf(first) > index) {
        target = min(guess, position.pixels - window);
      } else if (list.indexOf(last) < index) {
        target = max(guess, position.pixels + window);
      } else {
        // Inside the built blocks, yet no widget: a closed notice holds it.
        return;
      }
      position.jumpTo(
        max(position.minScrollExtent, min(position.maxScrollExtent, target)),
      );
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  void _build() {
    _disposeRecognizers();
    _keys.clear();
    _at.clear();
    final linkOf = widget.linkOf;
    final builder = _Blocks(
      font: widget.font,
      accent: widget.accent,
      canOpen: widget.canOpen,
      onOpen: widget.onOpen,
      keys: _keys,
      recognizers: _recognizers,
      linkOf: linkOf == null ? null : (slug) => widget.linkOf?.call(slug) ?? '',
      find: widget.find,
      matchKey: _matchKey,
    );
    final blocks = <Widget>[];
    for (final block in widget.doc.blocks) {
      final before = _keys.length;
      builder.at = blocks.length;
      blocks.add(builder.row(block));
      for (final slug in _keys.keys.skip(before)) {
        _at[slug] = blocks.length - 1;
      }
    }
    _blocks = blocks;
    _matchAt = builder.matchAt;
    _report(builder.matchAt.length);
  }

  /// Tells the owner how many matches the find has, once the frame is done:
  /// the owner redraws itself in answer.
  void _report(int count) {
    if (_reported == count) return;
    _reported = count;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onFound?.call(count);
    });
  }

  @override
  Widget build(BuildContext context) {
    final font = widget.font;
    final column = font * (mdWidth + (widget.linkOf == null ? 0 : mdGutter));
    final sides = widget.sides;
    return LayoutBuilder(
      builder: (context, constraints) {
        // The column leans toward the middle of the screen: the view stands
        // [MdView.lead] from its left edge, so the right side takes that much
        // more room, as far as the column still fits.
        final reserved = max(codeBarRoom, widget.trail);
        final delta = widget.lead - reserved;
        final room = max(
          0.0,
          constraints.maxWidth - 2 * sides - reserved - column,
        );
        // Toward the left when the right side holds the more.
        final shift = min(delta.abs(), room);
        final left = delta < 0 ? shift : 0.0;
        final right = delta < 0 ? 0.0 : shift;
        return CodeScrollbar(
          controller: _scroll,
          child: SelectionArea(
            child: CustomScrollView(
              controller: _scroll,
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    sides + left,
                    font * 0.3,
                    sides + right + reserved,
                    font * 1.5,
                  ),
                  // Blocks are built when they come near the window, not all
                  // at once, so a long article opens at once. The column is
                  // centered; every block, text or not, has the same width,
                  // so the left and right edges line up down the page.
                  sliver: SliverList.builder(
                    key: _list,
                    itemCount: _blocks.length,
                    itemBuilder: (context, i) => Padding(
                      padding: EdgeInsets.only(top: i > 0 ? _gap(i) : 0),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: column),
                          child: SizedBox(
                            width: double.infinity,
                            child: _blocks[i],
                          ),
                        ),
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

  /// More air above a heading than under it, so a section reads as a unit.
  double _gap(int i) {
    final block = widget.doc.blocks[i];
    final font = widget.font;
    if (block is MdHeading) return font * (block.level <= 2 ? 1.9 : 1.3);
    if (widget.doc.blocks[i - 1] is MdHeading) return font * 0.7;
    return font * 1.0;
  }
}

/// Width of the reading column, in font sizes, shared by text, notices, code,
/// tables, and pictures. A line of text holds about ninety characters.
const mdWidth = 48.0;

/// Room in front of the column for the copy-link mark of a heading, in font
/// sizes. It is there only while the view has [MdView.linkOf].
const mdGutter = 1.8;

const _ink = Color(0xFFFFFFFF);

/// Running text is a shade under white, so bold and headings stand out.
const _bodyInk = Color(0xFFE6E6EB);
const _bodyFamily = 'OpenGost Type B';

/// How far under the baseline a link's underline stands, in font sizes. The
/// descenders of OpenGost end at 0.18.
const _underlineDrop = 0.2;

/// Turns blocks into widgets. One builder serves one build of a document;
/// the links it makes are kept in [recognizers] for the view to release.
class _Blocks {
  _Blocks({
    required this.font,
    required this.accent,
    required this.canOpen,
    required this.onOpen,
    required this.keys,
    required this.recognizers,
    this.linkOf,
    this.find,
    this.matchKey,
  });

  final double font;
  final Color accent;
  final bool Function(String url) canOpen;
  final void Function(String url) onOpen;
  final Map<String, GlobalKey> keys;
  final List<GestureRecognizer> recognizers;
  final String Function(String slug)? linkOf;
  final MdFind? find;
  final GlobalKey? matchKey;

  /// Index of the top-level block being built, and the block of every match
  /// found so far, in the order the text reads.
  var at = 0;
  final matchAt = <int>[];

  /// The words of [find], as [foldText] makes them. Empty: nothing to mark.
  late final _needle = foldText(find?.query ?? '');

  /// True once the current match has been drawn into the spans being built:
  /// the text that holds it takes [matchKey].
  var _hit = false;

  /// The spans for a piece of text: the text itself, or pieces of it with
  /// the matches marked. The current match is stronger than the others.
  List<InlineSpan> _lit(String text, [TextStyle? style]) {
    final ranges = findRanges(text, _needle);
    if (ranges.isEmpty) return [TextSpan(text: text, style: style)];
    final current = find?.current ?? -1;
    final out = <InlineSpan>[];
    var from = 0;
    for (final range in ranges) {
      if (range.start > from) {
        out.add(TextSpan(text: text.substring(from, range.start), style: style));
      }
      final mine = matchAt.length == current;
      if (mine) _hit = true;
      matchAt.add(at);
      out.add(
        TextSpan(
          text: text.substring(range.start, range.end),
          style: (style ?? const TextStyle()).merge(
            TextStyle(
              background: Paint()
                ..color = accent.withValues(alpha: mine ? 0.75 : 0.3),
              color: mine ? const Color(0xFF000000) : null,
            ),
          ),
        ),
      );
      from = range.end;
    }
    if (from < text.length) {
      out.add(TextSpan(text: text.substring(from), style: style));
    }
    return out;
  }

  /// [text] with the key of the current match, when the spans just built
  /// hold it.
  Widget _found(Widget text) {
    if (!_hit) return text;
    _hit = false;
    return KeyedSubtree(key: matchKey, child: text);
  }

  double get code => font * 0.82;

  double get gutter => linkOf == null ? 0 : font * mdGutter;

  /// A block of the document's own list. Under a heading with a copy mark
  /// the mark stands in the gutter; every other block leaves the gutter empty,
  /// so the text lines up.
  Widget row(MdBlock block) {
    final built = this.block(block, top: true);
    if (gutter == 0 || _marked(block)) return built;
    return Padding(padding: EdgeInsets.only(left: gutter), child: built);
  }

  bool _marked(MdBlock block) =>
      linkOf != null &&
      block is MdHeading &&
      block.level >= 2 &&
      block.level <= 4;

  /// True while the spans of a link are built.
  var _inLink = false;

  /// The color of the block being built when it has its own, a `:::` block.
  Color? _tint;

  /// The color a code span is marked with: the block's, or the section's.
  Color get tint => _tint ?? accent;

  TextStyle get body => TextStyle(
    color: _bodyInk,
    fontFamily: _bodyFamily,
    fontSize: font,
    height: 1.5,
    decoration: TextDecoration.none,
  );

  Widget block(MdBlock block, {TextStyle? style, bool top = false}) {
    final base = style ?? body;
    switch (block) {
      case MdHeading():
        return _heading(block, marked: top && _marked(block));
      case MdParagraph():
        return _found(
          Text.rich(
            TextSpan(children: spans(block.inlines, base)),
            style: base,
          ),
        );
      case MdListBlock():
        return _list(block, base);
      case MdCodeBlock():
        if (block.language == 'mermaid') {
          return _Diagram(block.code, code, accent);
        }
        return _CodeBlock(
          code: block.code,
          language: block.language,
          font: code,
          accent: accent,
        );
      case MdQuote():
        return _Quote(
          font: font,
          children: [
            for (final inner in block.blocks)
              this.block(inner, style: base.copyWith(color: hexMuted)),
          ],
        );
      case MdAdmonition():
        final outer = _tint;
        final color = admonitionColor(block.kind);
        _tint = color;
        final built = [for (final child in block.blocks) this.block(child)];
        _tint = outer;
        return _Admonition(
          font: font,
          color: color,
          title: block.title,
          folded: block.kind == MdAdmonitionKind.details,
          children: built,
        );
      case MdTable():
        return _table(block);
      case MdImage():
        return _Picture(url: block.url, alt: block.alt, font: font);
      case MdVideo():
        return _Video(video: block, font: font, accent: accent);
      case MdRule():
        return _Fade(color: accent, height: 1);
    }
  }

  Widget _heading(MdHeading heading, {required bool marked}) {
    const scale = [2.0, 1.55, 1.25, 1.1, 1.0, 0.95];
    final key = keys.putIfAbsent(heading.slug, GlobalKey.new);
    final level = heading.level;
    final size = font * scale[level - 1];
    final style = body.copyWith(
      fontSize: size,
      height: 1.25,
      color: level == 1 || level == 3 ? accent : _ink,
    );
    final text = _found(
      Text.rich(
        TextSpan(children: spans(heading.inlines, style)),
        style: style,
      ),
    );
    Widget content;
    switch (level) {
      case 1:
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            text,
            SizedBox(height: font * 0.55),
            _Fade(color: accent, height: 2),
          ],
        );
      case 2:
        content = Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SelectionContainer.disabled(
              child: Padding(
                padding: EdgeInsets.only(right: font * 0.6),
                child: _HexMark(color: accent, size: size * 0.52),
              ),
            ),
            Expanded(child: text),
          ],
        );
      default:
        content = text;
    }
    final link = linkOf;
    if (marked && link != null) {
      // The mark stands in the gutter, level with the first line.
      content = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CopyLinkMark(
            link: () => link(heading.slug),
            width: gutter,
            height: size * 1.25,
          ),
          Expanded(child: content),
        ],
      );
    }
    return KeyedSubtree(key: key, child: content);
  }

  Widget _list(MdListBlock list, TextStyle base) {
    final marker = font * (list.ordered ? 1.9 : 1.1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < list.items.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == list.items.length - 1 ? 0 : font * 0.45,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: marker,
                  child: SelectionContainer.disabled(
                    child: list.ordered
                        ? Text(
                            '${list.start + i}.',
                            textAlign: TextAlign.right,
                            style: base.copyWith(color: accent),
                          )
                        : Padding(
                            // The hex sits on the middle of the first line.
                            padding: EdgeInsets.only(
                              top: font * 0.75 - font * 0.2,
                              right: font * 0.2,
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              heightFactor: 1,
                              child: _HexMark(color: accent, size: font * 0.4),
                            ),
                          ),
                  ),
                ),
                SizedBox(width: font * 0.55),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var b = 0; b < list.items[i].length; b++) ...[
                        if (b > 0) SizedBox(height: font * 0.5),
                        block(list.items[i][b], style: base),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _table(MdTable table) {
    final cellStyle = body.copyWith(fontSize: font * 0.92, height: 1.35);
    Widget cell(List<MdInline> inlines, MdAlign align, {bool head = false}) {
      final style = head ? cellStyle.copyWith(color: accent) : cellStyle;
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: font * 24),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: font * 0.8,
            vertical: font * 0.55,
          ),
          child: _found(
            Text.rich(
              TextSpan(children: spans(inlines, style)),
              style: style,
              textAlign: switch (align) {
                MdAlign.left => TextAlign.left,
                MdAlign.center => TextAlign.center,
                MdAlign.right => TextAlign.right,
              },
            ),
          ),
        ),
      );
    }

    return _WideTable(
      accent: accent,
      font: font,
      table: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder(
          horizontalInside: BorderSide(color: accent.withValues(alpha: 0.18)),
        ),
        children: [
          TableRow(
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.16)),
            children: [
              for (var c = 0; c < table.header.length; c++)
                cell(table.header[c], table.aligns[c], head: true),
            ],
          ),
          for (var r = 0; r < table.rows.length; r++)
            TableRow(
              decoration: r.isOdd
                  ? const BoxDecoration(color: Color(0x0AFFFFFF))
                  : null,
              children: [
                for (var c = 0; c < table.rows[r].length; c++)
                  cell(table.rows[r][c], table.aligns[c]),
              ],
            ),
        ],
      ),
    );
  }

  /// [spans] with [recognizer] on every span that holds words.
  List<InlineSpan> _tappable(
    List<InlineSpan> spans,
    GestureRecognizer recognizer,
  ) {
    return [
      for (final span in spans)
        if (span is TextSpan)
          TextSpan(
            text: span.text,
            style: span.style,
            recognizer: span.recognizer ?? recognizer,
            mouseCursor: SystemMouseCursors.click,
            children: span.children == null
                ? null
                : _tappable(span.children!, recognizer),
          )
        else
          span,
    ];
  }

  /// Inline spans over [style]. A live link keeps its recognizer in
  /// [recognizers].
  List<InlineSpan> spans(List<MdInline> inlines, TextStyle style) {
    final out = <InlineSpan>[];
    for (final inline in inlines) {
      switch (inline) {
        case MdText():
          out.addAll(_lit(inline.text));
        case MdBreak():
          out.add(const TextSpan(text: '\n'));
        case MdCodeSpan():
          // The words keep the font and the size of the text around them.
          final size = style.fontSize ?? font;
          // The pad is a no-break space of the same font (0.353 of the size
          // in OpenGost), narrowed to a fifth of a letter, so the mark reaches
          // past the first and the last letter and has the same height as the
          // words.
          final pad = TextSpan(
            text: '\u00A0',
            style: TextStyle(letterSpacing: -size * 0.153),
          );
          out.add(
            TextSpan(
              style: TextStyle(
                color: _inLink ? _ink : Color.lerp(_ink, tint, 0.22),
                // A flat box has sharp corners and stops on the last pixel.
                // A blurred one is soft at the edge and round at the corners.
                background: Paint()
                  ..color = tint.withValues(alpha: 0.15)
                  ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.1),
                // In a link the words are drawn by the shadow of the link,
                // which a code span does not take.
                shadows: _inLink ? const [] : null,
                decoration: _inLink ? TextDecoration.none : null,
              ),
              children: [pad, ..._lit(inline.code), pad],
            ),
          );
        case MdMarked():
          final inner = spans(inline.children, style);
          switch (inline.mark) {
            case MdMark.bold:
              out.add(
                TextSpan(
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _inLink ? null : _ink,
                  ),
                  children: inner,
                ),
              );
            case MdMark.italic:
              out.add(
                TextSpan(
                  style: const TextStyle(fontStyle: FontStyle.italic),
                  children: inner,
                ),
              );
            case MdMark.strike:
              out.add(
                TextSpan(
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                  ),
                  children: inner,
                ),
              );
          }
        case MdInlineImage():
          out.add(
            TextSpan(
              style: _inLink ? null : TextStyle(color: accent),
              children: _lit(inline.alt.isEmpty ? inline.url : inline.alt),
            ),
          );
        case MdLink():
          final wasInLink = _inLink;
          _inLink = true;
          final inner = spans(inline.children, style);
          _inLink = wasInLink;
          if (!canOpen(inline.url)) {
            // A term the client has no page for is plain text, not a dead link.
            out.add(TextSpan(children: inner));
            break;
          }
          final recognizer = TapGestureRecognizer()
            ..onTap = () => onOpen(inline.url);
          recognizers.add(recognizer);
          out.add(
            TextSpan(
              // OpenGost puts its underline on the baseline, through the
              // letters. The words are drawn as their own shadow, lifted by
              // the drop, and the line stays where the font puts it: under
              // the descenders.
              style: TextStyle(
                color: const Color(0x00000000),
                shadows: [
                  Shadow(
                    color: accent,
                    offset: Offset(
                      0,
                      -(style.fontSize ?? font) * _underlineDrop,
                    ),
                  ),
                ],
                decoration: TextDecoration.underline,
                decorationColor: accent,
              ),
              // A tap is read by the innermost span under the finger, so the
              // recognizer sits on the words, not on the wrapper.
              children: _tappable(inner, recognizer),
            ),
          );
      }
    }
    return out;
  }
}

/// A table wider than the view scrolls sideways under its own bar.
class _WideTable extends StatefulWidget {
  const _WideTable({
    required this.table,
    required this.accent,
    required this.font,
  });

  final Table table;
  final Color accent;
  final double font;

  @override
  State<_WideTable> createState() => _WideTableState();
}

class _WideTableState extends State<_WideTable> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Plate(
      border: widget.accent.withValues(alpha: 0.55),
      fill: const Color(0x55000000),
      font: widget.font,
      child: LayoutBuilder(
        builder: (context, constraints) => Scrollbar(
          controller: _scroll,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scroll,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 14),
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: widget.table,
            ),
          ),
        ),
      ),
    );
  }
}

/// A panel of a text: a [BevelFrame] with a fill under its content.
class _Plate extends StatelessWidget {
  const _Plate({
    required this.border,
    required this.fill,
    required this.font,
    required this.child,
  });

  final Color border;
  final Color fill;
  final double font;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BevelFrame(
      color: border,
      radius: font * 0.75,
      fill: fill,
      child: child,
    );
  }
}

/// A line that fades out to the right.
class _Fade extends StatelessWidget {
  const _Fade({required this.color, required this.height});

  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }
}

/// The mark that copies an address: two links of a chain. A tap puts [link]
/// on the clipboard and the mark turns green for a moment. It is not part of
/// a selection.
class CopyLinkMark extends StatefulWidget {
  const CopyLinkMark({
    required this.link,
    required this.width,
    required this.height,
    this.label = 'Скопировать ссылку',
    super.key,
  });

  final String Function() link;
  final double width;
  final double height;
  final String label;

  @override
  State<CopyLinkMark> createState() => _CopyLinkMarkState();
}

class _CopyLinkMarkState extends State<CopyLinkMark> {
  var _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.link()));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final extent = min(widget.width, widget.height) * 0.8;
    return SelectionContainer.disabled(
      child: Semantics(
        button: true,
        label: widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _copy,
          child: HoverPop(
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: Center(
                child: SizedBox(
                  width: extent,
                  height: extent,
                  child: CustomPaint(
                    painter: LinkMarkPainter(_copied ? addColor : hexMuted),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A pointy-top hexagon, the mark of the cells, used as a bullet and a
/// heading sign.
class _HexMark extends StatelessWidget {
  const _HexMark({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _HexMarkPainter(color),
    );
  }
}

class _HexMarkPainter extends CustomPainter {
  const _HexMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final path = Path();
    for (var k = 0; k < 6; k++) {
      final angle = (-90 + 60 * k) * pi / 180;
      final x = r + r * cos(angle);
      final y = r + r * sin(angle);
      if (k == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _HexMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _Quote extends StatelessWidget {
  const _Quote({required this.font, required this.children});

  final double font;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: font * 0.9),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: hexMuted, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) SizedBox(height: font * 0.5),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// `:::info`, `:::tip`, `:::warning`, `:::danger`, and a folded `:::details`.
class _Admonition extends StatefulWidget {
  const _Admonition({
    required this.font,
    required this.color,
    required this.title,
    required this.folded,
    required this.children,
  });

  final double font;
  final Color color;
  final String title;
  final bool folded;
  final List<Widget> children;

  @override
  State<_Admonition> createState() => _AdmonitionState();
}

class _AdmonitionState extends State<_Admonition> {
  late var _open = !widget.folded;

  @override
  Widget build(BuildContext context) {
    final font = widget.font;
    final title = Text(
      widget.title,
      style: TextStyle(
        color: widget.color,
        fontFamily: _bodyFamily,
        fontSize: font * 0.95,
        decoration: TextDecoration.none,
      ),
    );
    return _Plate(
      border: widget.color,
      // The tint over the scene color, 85% opaque: the mosaic shows faintly
      // through, the text stays readable.
      fill: Color.alphaBlend(
        widget.color.withValues(alpha: 0.16),
        sceneBackground,
      ).withValues(alpha: 0.85),
      font: font,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          font * 1.1,
          font * 0.75,
          font * 1.1,
          font * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.folded)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _open = !_open),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Row(
                    children: [
                      Text(
                        _open ? '▾ ' : '▸ ',
                        style: TextStyle(color: widget.color, fontSize: font),
                      ),
                      Expanded(child: title),
                    ],
                  ),
                ),
              )
            else
              Row(
                children: [
                  SelectionContainer.disabled(
                    child: Padding(
                      padding: EdgeInsets.only(right: font * 0.5),
                      child: _HexMark(color: widget.color, size: font * 0.55),
                    ),
                  ),
                  Expanded(child: title),
                ],
              ),
            if (_open)
              for (final child in widget.children) ...[
                SizedBox(height: font * 0.55),
                child,
              ],
          ],
        ),
      ),
    );
  }
}

/// A fenced block: language and copy on top, numbered colored lines under
/// them. Lines do not wrap; a wide block scrolls sideways.
class _CodeBlock extends StatefulWidget {
  const _CodeBlock({
    required this.code,
    required this.language,
    required this.font,
    required this.accent,
  });

  final String code;
  final String language;
  final double font;
  final Color accent;

  @override
  State<_CodeBlock> createState() => _CodeBlockState();
}

class _CodeBlockState extends State<_CodeBlock> {
  final _scroll = ScrollController();
  var _copied = false;

  /// The colors of the lines are read once, not on every frame of the mark.
  late final List<List<CodeToken>> _tokens = codeTokens(
    widget.code,
    codeLanguageOfFence(widget.language),
  );

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.code));
    if (!mounted) return;
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final font = widget.font;
    final lines = widget.code.split('\n');
    final tokens = _tokens;
    final style = codeMono(font);
    final strut = codeStrut(font);
    final gutter = font * 0.62 * '${lines.length}'.length + font * 1.2;
    final extent = font * 1.8;
    return _Plate(
      border: widget.accent.withValues(alpha: 0.55),
      fill: const Color(0x80000000),
      font: font,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: extent,
            padding: EdgeInsets.only(left: font * 0.8),
            color: widget.accent.withValues(alpha: 0.16),
            child: Row(
              children: [
                Expanded(
                  child: SelectionContainer.disabled(
                    child: Text(
                      widget.language.isEmpty ? 'text' : widget.language,
                      style: codeMono(font * 0.9, color: widget.accent),
                    ),
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Скопировать',
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _copy,
                    child: HoverPop(
                      child: SizedBox(
                        width: extent,
                        height: extent,
                        child: Padding(
                          padding: EdgeInsets.all(extent * 0.2),
                          child: CustomPaint(
                            painter: CopyMarkPainter(_copied ? addColor : _ink),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Scrollbar(
            controller: _scroll,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(
                top: font * 0.5,
                bottom: font * 0.5 + 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The numbers and the lines are one text each, not one
                  // widget per line: every row has the height of the strut,
                  // so they stay level.
                  SelectionContainer.disabled(
                    child: SizedBox(
                      width: gutter,
                      child: Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: EdgeInsets.only(right: font * 0.7),
                          child: Text(
                            [for (var i = 0; i < lines.length; i++) '${i + 1}']
                                .join('\n'),
                            textAlign: TextAlign.right,
                            strutStyle: strut,
                            style: codeMono(font, color: hexMuted),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: font),
                    child: Text.rich(
                      TextSpan(
                        style: style,
                        children: [
                          for (var i = 0; i < lines.length; i++) ...[
                            ...codeLineSpans(
                              i < tokens.length ? tokens[i] : const [],
                              style,
                            ),
                            if (i < lines.length - 1)
                              const TextSpan(text: '\n'),
                          ],
                        ],
                      ),
                      strutStyle: strut,
                      softWrap: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A picture by link. It opens full screen on a tap. A link that is not on
/// the network draws nothing.
class _Picture extends StatelessWidget {
  const _Picture({required this.url, required this.alt, required this.font});

  final String url;
  final String alt;
  final double font;

  @override
  Widget build(BuildContext context) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return const SizedBox.shrink();
    }
    return _Zoomable(
      url: url,
      alt: alt,
      font: font,
      child: Image.network(
        url,
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        errorBuilder: (context, error, stack) =>
            _Missing(label: alt, font: font),
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : SizedBox(
                height: font * 4,
                child: Center(
                  child: SizedBox(
                    width: font * 1.6,
                    height: font * 1.6,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  const _Missing({required this.label, required this.font});

  final String label;
  final double font;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: font * 3,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: font),
      decoration: BoxDecoration(
        border: Border.all(color: hexMuted.withValues(alpha: 0.5)),
      ),
      child: Text(
        label.isEmpty ? 'Изображение недоступно' : label,
        style: TextStyle(
          color: hexMuted,
          fontFamily: _bodyFamily,
          fontSize: font * 0.9,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}

/// Opens [url] over the whole screen, where it can be pinched and dragged.
class _Zoomable extends StatelessWidget {
  const _Zoomable({
    required this.url,
    required this.alt,
    required this.font,
    required this.child,
  });

  final String url;
  final String alt;
  final double font;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.zoomIn,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => showGeneralDialog<void>(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Закрыть',
          barrierColor: const Color(0xE6000000),
          pageBuilder: (dialog, _, _) => Material(
            type: MaterialType.transparency,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(dialog).pop(),
              child: InteractiveViewer(
                maxScale: 8,
                child: Center(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stack) =>
                        _Missing(label: alt, font: font),
                  ),
                ),
              ),
            ),
          ),
        ),
        child: child,
      ),
    );
  }
}

/// A diagram drawn by the [mermaidRenderer]. When the picture does not come,
/// the diagram text is shown as code.
class _Diagram extends StatelessWidget {
  const _Diagram(this.code, this.font, this.accent);

  final String code;
  final double font;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final fallback = _CodeBlock(
      code: code,
      language: 'mermaid',
      font: font,
      accent: accent,
    );
    return _Zoomable(
      url: mermaidUrl(code),
      alt: 'mermaid',
      font: font,
      child: Container(
        color: const Color(0xFF14161B),
        padding: EdgeInsets.all(font * 0.6),
        child: Image.network(
          mermaidUrl(code),
          fit: BoxFit.scaleDown,
          errorBuilder: (context, error, stack) => fallback,
          loadingBuilder: (context, child, progress) => progress == null
              ? child
              : SizedBox(
                  height: font * 6,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
        ),
      ),
    );
  }
}

/// A YouTube preview. A tap opens the video in the browser or the app.
class _Video extends StatelessWidget {
  const _Video({required this.video, required this.font, required this.accent});

  final MdVideo video;
  final double font;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Смотреть видео',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openVideo(video),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: max(240, font * 36)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    video.preview,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) =>
                        const ColoredBox(color: Color(0xFF14161B)),
                  ),
                  const ColoredBox(color: Color(0x55000000)),
                  Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: accent, width: 3),
                        color: const Color(0x99000000),
                      ),
                      child: SizedBox(
                        width: font * 3.6,
                        height: font * 3.6,
                        child: CustomPaint(painter: _PlayPainter(accent)),
                      ),
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

typedef VideoOpener = void Function(MdVideo video);

/// What a video preview does on a tap. Tests replace it.
VideoOpener videoOpener = (video) => launchExternal(Uri.parse(video.url));

void _openVideo(MdVideo video) => videoOpener(video);

class _PlayPainter extends CustomPainter {
  const _PlayPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.40, h * 0.30)
      ..lineTo(w * 0.72, h * 0.50)
      ..lineTo(w * 0.40, h * 0.70)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PlayPainter oldDelegate) =>
      oldDelegate.color != color;
}
