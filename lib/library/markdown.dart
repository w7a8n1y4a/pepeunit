/// Markdown the Library reads. The parser is pure Dart: it turns a text into
/// blocks and inlines, and `features/library/md_view.dart` draws them.
///
/// Dialect: CommonMark basics, tables, `~~strike~~`, bare links, and
/// `:::info|tip|warning|danger|details` blocks. A YouTube `<iframe>` or a
/// lone YouTube link becomes a video block. Indented code is not supported,
/// fences are.
library;

import 'package:yaml/yaml.dart';

import '../locale/languages.dart';

// ---------------------------------------------------------------- inlines

sealed class MdInline {
  const MdInline();
}

class MdText extends MdInline {
  const MdText(this.text);

  final String text;
}

class MdCodeSpan extends MdInline {
  const MdCodeSpan(this.code);

  final String code;
}

class MdBreak extends MdInline {
  const MdBreak();
}

enum MdMark { bold, italic, strike }

class MdMarked extends MdInline {
  const MdMarked(this.mark, this.children);

  final MdMark mark;
  final List<MdInline> children;
}

class MdLink extends MdInline {
  const MdLink(this.url, this.children);

  final String url;
  final List<MdInline> children;
}

class MdInlineImage extends MdInline {
  const MdInlineImage(this.alt, this.url);

  final String alt;
  final String url;
}

// ----------------------------------------------------------------- blocks

sealed class MdBlock {
  const MdBlock();
}

class MdHeading extends MdBlock {
  const MdHeading(this.level, this.inlines, this.text, this.slug);

  final int level;
  final List<MdInline> inlines;

  /// The plain words of the heading.
  final String text;

  /// Anchor of the heading, unique inside one document.
  final String slug;
}

class MdParagraph extends MdBlock {
  const MdParagraph(this.inlines);

  final List<MdInline> inlines;
}

class MdListBlock extends MdBlock {
  const MdListBlock({
    required this.ordered,
    required this.start,
    required this.items,
  });

  final bool ordered;
  final int start;
  final List<List<MdBlock>> items;
}

class MdCodeBlock extends MdBlock {
  const MdCodeBlock(this.language, this.code);

  /// The word after the opening fence, lower case. Empty when there is none.
  final String language;
  final String code;
}

class MdQuote extends MdBlock {
  const MdQuote(this.blocks);

  final List<MdBlock> blocks;
}

enum MdAdmonitionKind { info, tip, warning, danger, details }

class MdAdmonition extends MdBlock {
  const MdAdmonition(this.kind, this.title, this.blocks);

  final MdAdmonitionKind kind;
  final String title;
  final List<MdBlock> blocks;
}

enum MdAlign { left, center, right }

class MdTable extends MdBlock {
  const MdTable({
    required this.header,
    required this.aligns,
    required this.rows,
  });

  final List<List<MdInline>> header;
  final List<MdAlign> aligns;
  final List<List<List<MdInline>>> rows;
}

class MdImage extends MdBlock {
  const MdImage(this.alt, this.url);

  final String alt;
  final String url;
}

/// A YouTube video. It is shown as a preview that opens [url].
class MdVideo extends MdBlock {
  const MdVideo(this.id);

  final String id;

  String get url => 'https://www.youtube.com/watch?v=$id';
  String get preview => 'https://img.youtube.com/vi/$id/hqdefault.jpg';
}

class MdRule extends MdBlock {
  const MdRule();
}

class MdDoc {
  const MdDoc({required this.blocks, required this.meta});

  final List<MdBlock> blocks;

  /// Front matter, empty when the text has none.
  final Map<String, Object?> meta;

  /// Headings of the whole document, in order.
  List<MdHeading> get headings {
    final found = <MdHeading>[];
    void walk(List<MdBlock> blocks) {
      for (final block in blocks) {
        switch (block) {
          case MdHeading():
            found.add(block);
          case MdAdmonition():
            walk(block.blocks);
          case MdQuote():
            walk(block.blocks);
          case MdListBlock():
            for (final item in block.items) {
              walk(item);
            }
          default:
        }
      }
    }

    walk(blocks);
    return found;
  }

  /// First level one heading, or null.
  String? get title {
    for (final heading in headings) {
      if (heading.level == 1) return heading.text;
    }
    return null;
  }

  /// The document without its first level one heading, when that heading
  /// stands on its own in the text. A frame that shows [title] itself does
  /// not draw it a second time.
  MdDoc withoutTitle() {
    final at = blocks.indexWhere(
      (block) => block is MdHeading && block.level == 1,
    );
    if (at < 0) return this;
    return MdDoc(
      blocks: [...blocks.sublist(0, at), ...blocks.sublist(at + 1)],
      meta: meta,
    );
  }
}

/// Front matter and the text after it.
({Map<String, Object?> meta, String body}) splitFrontMatter(String source) {
  final text = source.replaceAll('\r\n', '\n');
  if (!text.startsWith('---\n')) return (meta: const {}, body: text);
  final end = text.indexOf('\n---', 3);
  if (end < 0) return (meta: const {}, body: text);
  final rest = text.indexOf('\n', end + 1);
  final body = rest < 0 ? '' : text.substring(rest + 1);
  var meta = <String, Object?>{};
  try {
    final loaded = loadYaml(text.substring(4, end));
    if (loaded is YamlMap) {
      meta = {for (final entry in loaded.entries) '${entry.key}': entry.value};
    }
  } catch (_) {}
  return (meta: meta, body: body);
}

/// The title of [source] without parsing the whole text: the first `# ` line.
String? markdownTitle(String source) {
  final body = splitFrontMatter(source).body;
  var fenced = false;
  for (final line in body.split('\n')) {
    if (_fenceOpen.hasMatch(line)) fenced = !fenced;
    if (fenced) continue;
    final match = _heading.firstMatch(line);
    if (match != null && match.group(1)!.length == 1) {
      return plainText(parseInlines(_headingText(match.group(2)!)));
    }
  }
  return null;
}

MdDoc parseMarkdown(String source) {
  final split = splitFrontMatter(source);
  final slugs = <String, int>{};
  final blocks = _parseBlocks(split.body.split('\n'), slugs);
  return MdDoc(blocks: blocks, meta: split.meta);
}

// ----------------------------------------------------------- block parser

final _fenceOpen = RegExp(r'^\s*(`{3,}|~{3,})\s*([^\s`]*)');
final _heading = RegExp(r'^ {0,3}(#{1,6})\s+(.*?)\s*$');
final _rule = RegExp(r'^ {0,3}([-*_])(\s*\1){2,}\s*$');
final _listMark = RegExp(r'^(\s*)([-*+]|\d{1,9}[.)])(\s+|$)');
final _admonitionOpen = RegExp(r'^\s*:::\s*([a-zA-Z]*)\s*(.*?)\s*$');
final _admonitionClose = RegExp(r'^\s*:::\s*$');
final _tableRule = RegExp(r'^\s*\|?\s*:?-+:?\s*(\|\s*:?-+:?\s*)*\|?\s*$');
final _customAnchor = RegExp(r'\s*\{#[^}]*\}\s*$');
final _iframe = RegExp(r'''<iframe[^>]*\ssrc\s*=\s*["']([^"']+)["']''');
final _youtube = RegExp(
  r'(?:youtube\.com/(?:embed/|watch\?(?:[^#\s]*&)?v=)|youtu\.be/)([A-Za-z0-9_-]{11})',
);

String _headingText(String raw) => raw.replaceAll(_customAnchor, '').trim();

bool _startsBlock(String line, String? next) {
  if (_fenceOpen.hasMatch(line)) return true;
  if (_heading.hasMatch(line)) return true;
  if (_admonitionOpen.hasMatch(line) && line.trimLeft().startsWith(':::')) {
    return true;
  }
  if (line.trimLeft().startsWith('>')) return true;
  if (_rule.hasMatch(line)) return true;
  if (_listMark.hasMatch(line)) return true;
  if (_isTableStart(line, next)) return true;
  if (_iframe.hasMatch(line)) return true;
  return false;
}

bool _isTableStart(String line, String? next) {
  if (next == null || !line.contains('|')) return false;
  return next.contains('|') && next.contains('-') && _tableRule.hasMatch(next);
}

List<MdBlock> _parseBlocks(List<String> lines, Map<String, int> slugs) {
  final blocks = <MdBlock>[];
  var i = 0;
  while (i < lines.length) {
    final line = lines[i];
    if (line.trim().isEmpty) {
      i++;
      continue;
    }
    final fence = _fenceOpen.firstMatch(line);
    if (fence != null) {
      final marker = fence.group(1)!;
      final indent = line.length - line.trimLeft().length;
      final body = <String>[];
      i++;
      while (i < lines.length) {
        final current = lines[i];
        final closes =
            current.trim().startsWith(marker) &&
            current.trim().replaceAll(marker[0], '').isEmpty;
        if (closes) {
          i++;
          break;
        }
        body.add(_dedent(current, indent));
        i++;
      }
      blocks.add(MdCodeBlock(fence.group(2)!.toLowerCase(), body.join('\n')));
      continue;
    }
    final head = _heading.firstMatch(line);
    if (head != null) {
      final raw = _headingText(head.group(2)!);
      final inlines = parseInlines(raw);
      final text = plainText(inlines);
      blocks.add(
        MdHeading(head.group(1)!.length, inlines, text, _slug(text, slugs)),
      );
      i++;
      continue;
    }
    if (_rule.hasMatch(line)) {
      blocks.add(const MdRule());
      i++;
      continue;
    }
    final open = _admonitionOpen.firstMatch(line);
    if (open != null && line.trimLeft().startsWith(':::')) {
      final body = <String>[];
      i++;
      var depth = 1;
      while (i < lines.length) {
        final current = lines[i];
        if (_admonitionClose.hasMatch(current)) {
          depth--;
          if (depth == 0) {
            i++;
            break;
          }
        } else if (_admonitionOpen.hasMatch(current) &&
            current.trimLeft().startsWith(':::')) {
          depth++;
        }
        body.add(current);
        i++;
      }
      final kind = _kind(open.group(1)!);
      var title = open.group(2)!;
      if (title.isEmpty) title = _kindTitle(kind);
      blocks.add(MdAdmonition(kind, title, _parseBlocks(body, slugs)));
      continue;
    }
    if (line.trimLeft().startsWith('>')) {
      final body = <String>[];
      while (i < lines.length && lines[i].trimLeft().startsWith('>')) {
        var text = lines[i].trimLeft().substring(1);
        if (text.startsWith(' ')) text = text.substring(1);
        body.add(text);
        i++;
      }
      blocks.add(MdQuote(_parseBlocks(body, slugs)));
      continue;
    }
    if (_isTableStart(line, i + 1 < lines.length ? lines[i + 1] : null)) {
      final header = _cells(line);
      final aligns = [for (final cell in _cells(lines[i + 1])) _align(cell)];
      i += 2;
      final rows = <List<List<MdInline>>>[];
      while (i < lines.length &&
          lines[i].trim().isNotEmpty &&
          lines[i].contains('|')) {
        final cells = _cells(lines[i]);
        rows.add([
          for (var c = 0; c < header.length; c++)
            parseInlines(c < cells.length ? cells[c] : ''),
        ]);
        i++;
      }
      blocks.add(
        MdTable(
          header: [for (final cell in header) parseInlines(cell)],
          aligns: [
            for (var c = 0; c < header.length; c++)
              c < aligns.length ? aligns[c] : MdAlign.left,
          ],
          rows: rows,
        ),
      );
      continue;
    }
    final iframe = _iframe.firstMatch(line);
    if (iframe != null) {
      final video = _youtube.firstMatch(iframe.group(1)!);
      if (video != null) blocks.add(MdVideo(video.group(1)!));
      i++;
      continue;
    }
    final mark = _listMark.firstMatch(line);
    if (mark != null) {
      final result = _parseList(lines, i, slugs);
      blocks.add(result.block);
      i = result.next;
      continue;
    }
    if (line.trimLeft().startsWith('<!--')) {
      while (i < lines.length && !lines[i].contains('-->')) {
        i++;
      }
      i++;
      continue;
    }
    final paragraph = <String>[line.trim()];
    i++;
    while (i < lines.length) {
      final next = lines[i];
      if (next.trim().isEmpty) break;
      if (_startsBlock(next, i + 1 < lines.length ? lines[i + 1] : null)) {
        break;
      }
      paragraph.add(next.trim());
      i++;
    }
    blocks.add(_paragraph(paragraph));
  }
  return blocks;
}

MdBlock _paragraph(List<String> lines) {
  final text = lines.join('\n');
  final inlines = parseInlines(text);
  if (inlines.length == 1) {
    final only = inlines.first;
    if (only is MdInlineImage) {
      final video = _youtube.firstMatch(only.url);
      if (video != null) return MdVideo(video.group(1)!);
      return MdImage(only.alt, only.url);
    }
    if (only is MdLink && _loneVideo(only)) {
      return MdVideo(_youtube.firstMatch(only.url)!.group(1)!);
    }
  }
  return MdParagraph(inlines);
}

bool _loneVideo(MdLink link) {
  if (!link.url.startsWith('http') || _youtube.firstMatch(link.url) == null) {
    return false;
  }
  return plainText(link.children) == link.url;
}

({MdListBlock block, int next}) _parseList(
  List<String> lines,
  int from,
  Map<String, int> slugs,
) {
  final first = _listMark.firstMatch(lines[from])!;
  final baseIndent = first.group(1)!.length;
  final ordered = RegExp(r'\d').hasMatch(first.group(2)!);
  final start = ordered
      ? int.parse(first.group(2)!.replaceAll(RegExp(r'[^0-9]'), ''))
      : 1;
  final items = <List<MdBlock>>[];
  var i = from;
  while (i < lines.length) {
    final mark = _listMark.firstMatch(lines[i]);
    if (mark == null || mark.group(1)!.length != baseIndent) break;
    if (RegExp(r'\d').hasMatch(mark.group(2)!) != ordered) break;
    final offset = mark.end;
    final body = <String>[lines[i].substring(offset.clamp(0, lines[i].length))];
    i++;
    while (i < lines.length) {
      final current = lines[i];
      if (current.trim().isEmpty) {
        // A blank line stays in the item only when an indented line follows.
        var look = i + 1;
        while (look < lines.length && lines[look].trim().isEmpty) {
          look++;
        }
        if (look < lines.length && _indentOf(lines[look]) > baseIndent) {
          body.add('');
          i++;
          continue;
        }
        break;
      }
      final indent = _indentOf(current);
      if (indent > baseIndent) {
        body.add(_dedent(current, offset));
        i++;
        continue;
      }
      break;
    }
    items.add(_parseBlocks(body, slugs));
    // Blank lines between items.
    var look = i;
    while (look < lines.length && lines[look].trim().isEmpty) {
      look++;
    }
    final upcoming = look < lines.length
        ? _listMark.firstMatch(lines[look])
        : null;
    if (upcoming != null && upcoming.group(1)!.length == baseIndent) {
      i = look;
    }
  }
  return (
    block: MdListBlock(ordered: ordered, start: start, items: items),
    next: i,
  );
}

int _indentOf(String line) => line.length - line.trimLeft().length;

String _dedent(String line, int amount) {
  var cut = 0;
  while (cut < amount && cut < line.length && line[cut] == ' ') {
    cut++;
  }
  return line.substring(cut);
}

MdAdmonitionKind _kind(String word) {
  switch (word.toLowerCase()) {
    case 'tip':
    case 'success':
      return MdAdmonitionKind.tip;
    case 'warning':
    case 'caution':
      return MdAdmonitionKind.warning;
    case 'danger':
    case 'error':
      return MdAdmonitionKind.danger;
    case 'details':
      return MdAdmonitionKind.details;
    default:
      return MdAdmonitionKind.info;
  }
}

String _kindTitle(MdAdmonitionKind kind) => admonitionTitle(kind, 'ru');

/// The name a block shows when its text gives none. The parser writes the
/// Russian one into [MdAdmonition.title]; a screen that knows the language
/// swaps it with this.
String admonitionTitle(MdAdmonitionKind kind, String language) {
  switch (kind) {
    case MdAdmonitionKind.info:
      return phrase(language, {'ru': 'Информация', 'en': 'Information'});
    case MdAdmonitionKind.tip:
      return phrase(language, {'ru': 'Совет', 'en': 'Tip'});
    case MdAdmonitionKind.warning:
      return phrase(language, {'ru': 'Внимание', 'en': 'Warning'});
    case MdAdmonitionKind.danger:
      return phrase(language, {'ru': 'Опасно', 'en': 'Danger'});
    case MdAdmonitionKind.details:
      return phrase(language, {'ru': 'Подробнее', 'en': 'Details'});
  }
}

MdAlign _align(String cell) {
  final text = cell.trim();
  final left = text.startsWith(':');
  final right = text.endsWith(':');
  if (left && right) return MdAlign.center;
  if (right) return MdAlign.right;
  return MdAlign.left;
}

/// Cells of one table row. A pipe inside backticks or after a backslash is
/// text.
List<String> _cells(String line) {
  var text = line.trim();
  if (text.startsWith('|')) text = text.substring(1);
  if (text.endsWith('|') && !text.endsWith(r'\|')) {
    text = text.substring(0, text.length - 1);
  }
  final cells = <String>[];
  final cell = StringBuffer();
  var ticks = 0;
  for (var i = 0; i < text.length; i++) {
    final char = text[i];
    if (char == r'\' && i + 1 < text.length && text[i + 1] == '|') {
      cell.write('|');
      i++;
      continue;
    }
    if (char == '`') {
      var run = 1;
      while (i + run < text.length && text[i + run] == '`') {
        run++;
      }
      if (ticks == 0) {
        ticks = run;
      } else if (ticks == run) {
        ticks = 0;
      }
      cell.write('`' * run);
      i += run - 1;
      continue;
    }
    if (char == '|' && ticks == 0) {
      cells.add(cell.toString().trim());
      cell.clear();
      continue;
    }
    cell.write(char);
  }
  cells.add(cell.toString().trim());
  return cells;
}

/// Anchor of a heading as the old documentation site wrote it: lower case,
/// words joined by `-`, punctuation dropped.
String slugOf(String text) {
  final lower = text.toLowerCase().trim();
  final out = StringBuffer();
  var dash = false;
  for (final rune in lower.runes) {
    final char = String.fromCharCode(rune);
    final word = RegExp(r'[\p{L}\p{N}_]', unicode: true).hasMatch(char);
    if (word) {
      if (dash && out.isNotEmpty) out.write('-');
      dash = false;
      out.write(char);
    } else if (char == ' ' || char == '-') {
      dash = true;
    }
  }
  return out.toString();
}

/// The letters of an anchor and nothing else. The old documentation site
/// wrote anchors without the breve and the diaeresis (`фаиловои`, `еще`) and
/// links kept that spelling, so `й` and `и`, `ё` and `е` count the same here.
/// Two anchors that differ only in dashes, underscores, or those pairs point
/// at one heading.
String anchorKey(String anchor) {
  final out = StringBuffer();
  for (final rune in anchor.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    if (!RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(char)) continue;
    out.write(switch (char) {
      'й' => 'и',
      'ё' => 'е',
      _ => char,
    });
  }
  return out.toString();
}

String _slug(String text, Map<String, int> used) {
  final base = slugOf(text);
  final seen = used[base] ?? 0;
  used[base] = seen + 1;
  return seen == 0 ? base : '$base-$seen';
}

// ---------------------------------------------------------- inline parser

String plainText(List<MdInline> inlines) {
  final out = StringBuffer();
  for (final inline in inlines) {
    switch (inline) {
      case MdText():
        out.write(inline.text);
      case MdCodeSpan():
        out.write(inline.code);
      case MdBreak():
        out.write(' ');
      case MdMarked():
        out.write(plainText(inline.children));
      case MdLink():
        out.write(plainText(inline.children));
      case MdInlineImage():
        out.write(inline.alt);
    }
  }
  return out.toString();
}

const _escapable = r'\`*_{}[]()#+-.!|~<>:"';
final _bareLink = RegExp(r'''^https?://[^\s<>"')\]]+''');
final _autoLink = RegExp(r'^<(https?://[^\s>]+)>');
final _htmlTag = RegExp(r'^</?[a-zA-Z][^>]*>');

List<MdInline> parseInlines(String source) {
  final out = <MdInline>[];
  final text = StringBuffer();

  void flush() {
    if (text.isEmpty) return;
    out.add(MdText(text.toString()));
    text.clear();
  }

  var i = 0;
  while (i < source.length) {
    final char = source[i];
    final rest = source.substring(i);
    if (char == r'\' && i + 1 < source.length) {
      final next = source[i + 1];
      if (next == '\n') {
        flush();
        out.add(const MdBreak());
        i += 2;
        continue;
      }
      if (_escapable.contains(next)) {
        text.write(next);
        i += 2;
        continue;
      }
    }
    if (char == '\n') {
      final hard = text.toString().endsWith('  ');
      if (hard) {
        final trimmed = text.toString().trimRight();
        text
          ..clear()
          ..write(trimmed);
        flush();
        out.add(const MdBreak());
      } else {
        final trimmed = text.toString().trimRight();
        text
          ..clear()
          ..write(trimmed)
          ..write(' ');
      }
      i++;
      continue;
    }
    if (char == '`') {
      var run = 1;
      while (i + run < source.length && source[i + run] == '`') {
        run++;
      }
      final ticks = '`' * run;
      final close = source.indexOf(ticks, i + run);
      if (close > 0) {
        flush();
        var code = source.substring(i + run, close).replaceAll('\n', ' ');
        if (code.length > 2 && code.startsWith(' ') && code.endsWith(' ')) {
          code = code.substring(1, code.length - 1);
        }
        out.add(MdCodeSpan(code));
        i = close + run;
        continue;
      }
      text.write(ticks);
      i += run;
      continue;
    }
    if (char == '!' && rest.startsWith('![')) {
      final link = _bracketLink(source, i + 1);
      if (link != null) {
        flush();
        out.add(MdInlineImage(link.label, link.url));
        i = link.end;
        continue;
      }
    }
    if (char == '[') {
      final link = _bracketLink(source, i);
      if (link != null) {
        flush();
        out.add(MdLink(link.url, parseInlines(link.label)));
        i = link.end;
        continue;
      }
    }
    if (char == '<') {
      final auto = _autoLink.firstMatch(rest);
      if (auto != null) {
        flush();
        out.add(MdLink(auto.group(1)!, [MdText(auto.group(1)!)]));
        i += auto.end;
        continue;
      }
      final tag = _htmlTag.firstMatch(rest);
      if (tag != null) {
        if (RegExp(r'^<br\s*/?>', caseSensitive: false).hasMatch(rest)) {
          flush();
          out.add(const MdBreak());
        }
        i += tag.end;
        continue;
      }
    }
    if (char == 'h' && rest.startsWith('http')) {
      final bare = _bareLink.firstMatch(rest);
      final before = i == 0 ? ' ' : source[i - 1];
      if (bare != null && !RegExp(r'[A-Za-z0-9]').hasMatch(before)) {
        var url = bare.group(0)!;
        while (url.endsWith('.') || url.endsWith(',') || url.endsWith(':')) {
          url = url.substring(0, url.length - 1);
        }
        flush();
        out.add(MdLink(url, [MdText(url)]));
        i += url.length;
        continue;
      }
    }
    final mark = _emphasis(source, i);
    if (mark != null) {
      flush();
      out.add(MdMarked(mark.mark, parseInlines(mark.inner)));
      i = mark.end;
      continue;
    }
    text.write(char);
    i++;
  }
  flush();
  return out;
}

({String label, String url, int end})? _bracketLink(String source, int open) {
  if (open >= source.length || source[open] != '[') return null;
  var depth = 0;
  var close = -1;
  for (var i = open; i < source.length; i++) {
    final char = source[i];
    if (char == r'\') {
      i++;
    } else if (char == '`') {
      final end = source.indexOf('`', i + 1);
      if (end > 0) i = end;
    } else if (char == '[') {
      depth++;
    } else if (char == ']') {
      depth--;
      if (depth == 0) {
        close = i;
        break;
      }
    }
  }
  if (close < 0 || close + 1 >= source.length || source[close + 1] != '(') {
    return null;
  }
  var parens = 0;
  var end = -1;
  for (var i = close + 1; i < source.length; i++) {
    final char = source[i];
    if (char == '(') {
      parens++;
    } else if (char == ')') {
      parens--;
      if (parens == 0) {
        end = i;
        break;
      }
    }
  }
  if (end < 0) return null;
  var target = source.substring(close + 2, end).trim();
  final space = target.indexOf(RegExp(r'\s'));
  if (space > 0) target = target.substring(0, space);
  if (target.startsWith('<') && target.endsWith('>')) {
    target = target.substring(1, target.length - 1);
  }
  return (label: source.substring(open + 1, close), url: target, end: end + 1);
}

({MdMark mark, String inner, int end})? _emphasis(String source, int i) {
  for (final delimiter in const ['**', '__', '~~', '*', '_']) {
    if (!source.startsWith(delimiter, i)) continue;
    final single = delimiter.length == 1;
    if (single && source.startsWith(delimiter * 2, i)) continue;
    final underscore = delimiter.startsWith('_');
    if (underscore && i > 0 && RegExp(r'[A-Za-z0-9]').hasMatch(source[i - 1])) {
      continue;
    }
    final from = i + delimiter.length;
    if (from >= source.length || source[from].trim().isEmpty) continue;
    var close = source.indexOf(delimiter, from);
    while (close >= 0) {
      final before = source[close - 1];
      final after = close + delimiter.length < source.length
          ? source[close + delimiter.length]
          : ' ';
      final spaced = before.trim().isEmpty;
      final glued = underscore && RegExp(r'[A-Za-z0-9]').hasMatch(after);
      final doubled = single && after == delimiter;
      if (!spaced && !glued && !doubled && close > from) break;
      close = source.indexOf(delimiter, close + delimiter.length);
    }
    if (close < 0) continue;
    final mark = delimiter == '~~'
        ? MdMark.strike
        : single
        ? MdMark.italic
        : MdMark.bold;
    return (
      mark: mark,
      inner: source.substring(from, close),
      end: close + delimiter.length,
    );
  }
  return null;
}
