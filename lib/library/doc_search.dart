/// Search over the documentation, pure Dart: the way the local search of
/// VitePress works. Every article is cut into sections at its headings of
/// level two to four; a query is words that all have to be found in a
/// section; the hits come back best first, each one a place to scroll to.
/// `features/library/doc_search_panel.dart` draws them.
library;

import 'dart:math';

import 'library.dart';
import 'markdown.dart';

/// Most hits one article puts in the list, so a single long page does not
/// push every other one out.
const _perArticle = 6;

/// Most words of a query. The rest is dropped.
const _maxTerms = 8;

/// A piece of an article under one heading: what a hit points at.
class DocSection {
  DocSection._({
    required this.article,
    required this.heading,
    required this.anchor,
    required this.trail,
    required this.text,
  }) : _title = foldText(article.title),
       _heading = foldText(heading ?? ''),
       _trail = foldText(trail.join('\n')),
       _text = foldText(text);

  final DocArticle article;

  /// The heading of the section. Null for the part before the first one:
  /// the title of the article stands for it.
  final String? heading;

  /// Anchor of [heading] in the article. Null together with it.
  final String? anchor;

  /// The headings above [heading], outermost first, the title not included.
  final List<String> trail;

  /// The words under the heading, on one line.
  final String text;

  final String _title;
  final String _heading;
  final String _trail;
  final String _text;

  bool get intro => heading == null;
}

/// One place found by a query.
class DocHit {
  const DocHit(this.section, this.score);

  final DocSection section;
  final double score;
}

/// The words of a query, folded and cut to their stems, in the form
/// [DocSearchIndex.search] and [markRanges] take.
List<String> queryTerms(String query) {
  final terms = <String>[];
  for (final word in query.split(RegExp(r'\s+'))) {
    final folded = foldText(word.trim());
    if (folded.isEmpty) continue;
    final term = _stem(folded);
    if (!terms.contains(term)) terms.add(term);
    if (terms.length == _maxTerms) break;
  }
  return terms;
}

/// Lower case, with `й` and `ё` taken for `и` and `е`, so a query and a text
/// that spell a word differently still meet. The result is as long as
/// [text], so a place in one is a place in the other.
String foldText(String text) {
  final out = StringBuffer();
  for (var i = 0; i < text.length; i++) {
    final lower = text[i].toLowerCase();
    out.write(switch (lower) {
      'й' => 'и',
      'ё' => 'е',
      _ => lower.length == 1 ? lower : text[i],
    });
  }
  return out.toString();
}

/// A word without its ending, as far as a query can lose one and still be a
/// start of the word in the text: `устройства` finds `устройство`.
String _stem(String word) {
  final length = word.length;
  if (length >= 7) return word.substring(0, length - 2);
  if (length >= 5) return word.substring(0, length - 1);
  return word;
}

final _letter = RegExp(r'[\p{L}\p{N}]', unicode: true);

bool _wordChar(String char) => _letter.hasMatch(char);

/// Where [term] starts in [haystack]: at the start of a word when it can,
/// inside a word only for a term of three letters or more. -1 for none.
/// Both are folded.
({int at, bool word}) _find(String haystack, String term, [int from = 0]) {
  var inner = -1;
  var at = haystack.indexOf(term, from);
  while (at >= 0) {
    if (at == 0 || !_wordChar(haystack[at - 1])) return (at: at, word: true);
    if (inner < 0) inner = at;
    at = haystack.indexOf(term, at + 1);
  }
  if (term.length >= 3 && inner >= 0) return (at: inner, word: false);
  return (at: -1, word: false);
}

int _count(String haystack, String term) {
  var count = 0;
  var from = 0;
  while (count < 5) {
    final found = _find(haystack, term, from);
    if (found.at < 0) break;
    count++;
    from = found.at + term.length;
  }
  return count;
}

/// The ranges of [text] that [terms] cover, in order and apart. A term that
/// starts a word covers the whole word, so the hit reads as a word and not
/// as its stem.
List<({int start, int end})> markRanges(String text, List<String> terms) {
  final folded = foldText(text);
  final spans = <({int start, int end})>[];
  for (final term in terms) {
    if (term.isEmpty) continue;
    var from = 0;
    while (from < folded.length) {
      final found = _find(folded, term, from);
      if (found.at < 0) break;
      var end = found.at + term.length;
      if (found.word) {
        while (end < folded.length && _wordChar(folded[end])) {
          end++;
        }
      }
      spans.add((start: found.at, end: end));
      from = end;
    }
  }
  spans.sort((a, b) => a.start.compareTo(b.start));
  final merged = <({int start, int end})>[];
  for (final span in spans) {
    if (merged.isNotEmpty && span.start <= merged.last.end) {
      final last = merged.removeLast();
      merged.add((
        start: last.start,
        end: span.end > last.end ? span.end : last.end,
      ));
    } else {
      merged.add(span);
    }
  }
  return merged;
}

/// Where [query] stands in [text], for the find in an open article: the
/// same letters, case and `й`/`ё` aside, anywhere inside a word, one after
/// the other and never overlapping. [query] is as [foldText] makes it.
List<({int start, int end})> findRanges(String text, String query) {
  if (query.isEmpty) return const [];
  final folded = foldText(text);
  final out = <({int start, int end})>[];
  var at = folded.indexOf(query);
  while (at >= 0) {
    out.add((start: at, end: at + query.length));
    at = folded.indexOf(query, at + query.length);
  }
  return out;
}

/// A piece of [text] that holds the first of [terms], about [length] letters
/// long, cut between words and marked with `…` where it does not reach the
/// end. A text with no term in it gives its start.
String excerptOf(String text, List<String> terms, {int length = 150}) {
  if (text.length <= length) return text;
  final folded = foldText(text);
  var first = -1;
  for (final term in terms) {
    final found = _find(folded, term);
    if (found.at >= 0 && (first < 0 || found.at < first)) first = found.at;
  }
  var start = first < 0 ? 0 : max(0, first - length ~/ 4);
  var end = min(text.length, start + length);
  // A window that reaches the end of the text is moved back to full length.
  start = min(start, max(0, end - length));
  if (start > 0 && text[start - 1] != ' ') {
    final space = text.indexOf(' ', start);
    if (space >= 0 && (first < 0 || space < first)) start = space + 1;
  }
  if (end < text.length) {
    final space = text.lastIndexOf(' ', end);
    if (space > start + length ~/ 2) end = space;
  }
  final cut = text.substring(start, end).trim();
  return '${start > 0 ? '… ' : ''}$cut${end < text.length ? ' …' : ''}';
}

/// The sections of every article of a [DocsTree]. Built once for a tree,
/// then asked as often as the person types.
class DocSearchIndex {
  DocSearchIndex._(this.sections);

  static final _built = Expando<DocSearchIndex>();

  /// The index of [tree], made on the first ask.
  factory DocSearchIndex.of(DocsTree tree) {
    return _built[tree] ??= DocSearchIndex._(_sectionsOf(tree));
  }

  final List<DocSection> sections;

  /// The places where every word of [query] is found, best first. A hit in
  /// a heading outweighs one in the words under it, and a title of the
  /// article outweighs the headings above the hit. Equal hits keep the order
  /// of the sidebar. An empty query finds nothing.
  List<DocHit> search(String query, {int limit = 30}) {
    final terms = queryTerms(query);
    if (terms.isEmpty) return const [];
    final hits = <({DocHit hit, int seq})>[];
    for (var i = 0; i < sections.length; i++) {
      final score = _score(sections[i], terms);
      if (score > 0) hits.add((hit: DocHit(sections[i], score), seq: i));
    }
    // The sections stand in the order of the sidebar, and Dart's sort is
    // not stable: their place breaks a tie.
    hits.sort((a, b) {
      final byScore = b.hit.score.compareTo(a.hit.score);
      return byScore != 0 ? byScore : a.seq.compareTo(b.seq);
    });
    final taken = <String, int>{};
    final out = <DocHit>[];
    for (final (:hit, seq: _) in hits) {
      final path = hit.section.article.path;
      final count = taken[path] ?? 0;
      if (count >= _perArticle) continue;
      taken[path] = count + 1;
      out.add(hit);
      if (out.length == limit) break;
    }
    return out;
  }
}

double _score(DocSection section, List<String> terms) {
  var total = 0.0;
  for (final term in terms) {
    var score = 0.0;
    final heading = _find(section._heading, term);
    if (heading.at >= 0) score += heading.word ? 10 : 5;
    final trail = _find(section._trail, term);
    if (trail.at >= 0) score += trail.word ? 4 : 2;
    final title = _find(section._title, term);
    if (title.at >= 0) {
      score += (section.intro ? 8 : 3) * (title.word ? 1 : 0.5);
    }
    final body = _find(section._text, term);
    if (body.at >= 0) {
      score += (body.word ? 2 : 1) + _count(section._text, term) * 0.2;
    }
    if (score == 0) return 0;
    total += score;
  }
  return total;
}

List<DocSection> _sectionsOf(DocsTree tree) {
  final listed = <String>[];
  void walk(List<DocNode> nodes) {
    for (final node in nodes) {
      final path = node.path;
      if (path != null && !listed.contains(path)) listed.add(path);
      walk(node.items);
    }
  }

  walk(tree.sidebar);
  final rest = [
    for (final article in tree.articles)
      if (!listed.contains(article.path)) article.path,
  ]..sort();
  final out = <DocSection>[];
  for (final path in [...listed, ...rest]) {
    final article = tree.article(path);
    if (article == null) continue;
    out.addAll(sectionsOfArticle(article));
  }
  return out;
}

/// The sections of one article, in reading order.
List<DocSection> sectionsOfArticle(DocArticle article) {
  final doc = parseMarkdown(article.source);
  final sections = <DocSection>[];
  final above = <({int level, String text})>[];
  String? heading;
  String? anchor;
  var trail = const <String>[];
  final words = <String>[];

  void flush() {
    final text = words.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    words.clear();
    // The part before the first heading is the article itself: it stays
    // even when empty, so a title is found.
    sections.add(
      DocSection._(
        article: article,
        heading: heading,
        anchor: anchor,
        trail: trail,
        text: text,
      ),
    );
  }

  void blocks(List<MdBlock> list) {
    for (final block in list) {
      switch (block) {
        case MdHeading():
          if (block.level == 1) {
            // The title of the article is its own name, not a section.
          } else if (block.level > 4) {
            words.add(block.text);
          } else {
            flush();
            while (above.isNotEmpty && above.last.level >= block.level) {
              above.removeLast();
            }
            trail = [for (final item in above) item.text];
            above.add((level: block.level, text: block.text));
            heading = block.text;
            anchor = block.slug;
          }
        case MdParagraph():
          words.add(plainText(block.inlines));
        case MdListBlock():
          for (final item in block.items) {
            blocks(item);
          }
        case MdCodeBlock():
          words.add(block.code);
        case MdQuote():
          blocks(block.blocks);
        case MdAdmonition():
          words.add(block.title);
          blocks(block.blocks);
        case MdTable():
          for (final cell in block.header) {
            words.add(plainText(cell));
          }
          for (final row in block.rows) {
            for (final cell in row) {
              words.add(plainText(cell));
            }
          }
        case MdImage():
          words.add(block.alt);
        case MdVideo():
        case MdRule():
      }
    }
  }

  blocks(doc.blocks);
  flush();
  return sections;
}
