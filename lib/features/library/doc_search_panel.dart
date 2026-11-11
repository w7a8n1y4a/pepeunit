import 'package:flutter/material.dart';

import '../../hive/hex_scene.dart';
import '../../hive/hint.dart';
import '../../library/doc_search.dart';
import '../../locale/languages.dart';
import 'library_menu_page.dart';
import 'search_panel.dart';

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
  /// Words of the last query, for marking them in the rows.
  var _terms = const <String>[];

  List<DocHit> _search(String text) {
    _terms = queryTerms(text);
    return widget.index.search(text);
  }

  @override
  Widget build(BuildContext context) {
    final language = widget.language;
    return SearchPanel<DocHit>(
      font: widget.font,
      rowExtent: 5.4,
      fieldLabel: localized(
        language,
        'Поиск по документации',
        'Search the documentation',
      ),
      closeLabel: localized(language, 'Закрыть поиск', 'Close search'),
      search: _search,
      emptyText: (asked) => asked.isEmpty
          ? localized(
              language,
              'Введите слова из статьи',
              'Type words from an article',
            )
          : localized(
              language,
              'Ничего не найдено по запросу «$asked»',
              'No results for “$asked”',
            ),
      rowBuilder: (context, hit, lit, onHover, onTap) => _HitRow(
        hit: hit,
        terms: _terms,
        font: widget.font,
        lit: lit,
        onHover: onHover,
        onTap: onTap,
      ),
      onPick: (hit) => widget.onOpen(hit.section),
      onClose: widget.onClose,
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
        spans.add(TextSpan(text: '  ›  ', style: searchStyle(font, hexMuted)));
      }
      spans.addAll(
        _marked(
          parts[i],
          terms,
          searchStyle(
            font * 1.05,
            last ? const Color(0xFFFFFFFF) : hexMuted,
            height: 1.25,
          ),
          libraryColor,
        ),
      );
    }
    final text = section.text;
    return HintTarget(
      id: 'doc-result',
      title: parts.join(' › '),
      color: libraryColor,
      child: SearchRowFrame(
        font: font,
        lit: lit,
        label: parts.join(', '),
        verticalPad: 0.35,
        onHover: onHover,
        onTap: onTap,
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
                    searchStyle(font * 0.88, hexMuted, height: 1.25),
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
    );
  }
}
