import 'package:flutter/material.dart';

/// Syntax the client colors. Everything that shows or edits JSON or YAML
/// goes through here, so one palette serves every code panel.
enum CodeLanguage {
  plain,
  json,
  yaml,

  /// JSON when the text opens with an object or an array, else plain.
  auto,
}

enum CodeKind { plain, key, string, number, keyword, punct, comment }

class CodeToken {
  const CodeToken(this.text, this.kind);

  final String text;
  final CodeKind kind;
}

const _plainInk = Color(0xFFFFFFFF);

Color codeColor(CodeKind kind) {
  switch (kind) {
    case CodeKind.plain:
      return _plainInk;
    case CodeKind.key:
      return const Color(0xFF79C0FF);
    case CodeKind.string:
      return const Color(0xFFA5D6A7);
    case CodeKind.number:
      return const Color(0xFFFFB454);
    case CodeKind.keyword:
      return const Color(0xFFD19AFF);
    case CodeKind.punct:
      return const Color(0xFF9AA0AA);
    case CodeKind.comment:
      return const Color(0xFF6B7280);
  }
}

final _yamlRow = RegExp(r'''^\s*(?:#.*|-(?:\s.*)?|[\w."'-][^:]*:(?:\s.*)?)$''');

/// The language [auto] stands for on this text. JSON opens with an object or
/// an array. YAML needs a document marker, or at least two rows that are all
/// keys, list items, or comments, so a single `note: text` line stays plain.
CodeLanguage codeSniff(String text) {
  final head = text.trimLeft();
  if (head.startsWith('{') || head.startsWith('[')) return CodeLanguage.json;
  if (head.startsWith('---')) return CodeLanguage.yaml;
  var rows = 0;
  for (final line in text.split('\n')) {
    if (line.trim().isEmpty) continue;
    if (!_yamlRow.hasMatch(line.trimRight())) return CodeLanguage.plain;
    if (!line.trimLeft().startsWith('#')) rows++;
  }
  return rows >= 2 ? CodeLanguage.yaml : CodeLanguage.plain;
}

/// One list of tokens per line, split on `\n`. The tokens of a line join
/// back to the line exactly, so a colored text keeps the layout of the plain
/// one.
List<List<CodeToken>> codeTokens(String text, CodeLanguage language) {
  final lines = text.split('\n');
  final resolved = language == CodeLanguage.auto ? codeSniff(text) : language;
  switch (resolved) {
    case CodeLanguage.json:
      return [for (final line in lines) _jsonLine(line)];
    case CodeLanguage.yaml:
      final block = _YamlBlock();
      return [for (final line in lines) _yamlLine(line, block)];
    case CodeLanguage.plain:
    case CodeLanguage.auto:
      return [
        for (final line in lines)
          if (line.isEmpty)
            const <CodeToken>[]
          else
            [CodeToken(line, CodeKind.plain)],
      ];
  }
}

/// Spans of one line, colored over [style].
List<TextSpan> codeLineSpans(List<CodeToken> tokens, TextStyle style) {
  return [
    for (final token in tokens)
      TextSpan(
        text: token.text,
        style: style.copyWith(color: codeColor(token.kind)),
      ),
  ];
}

/// Spans of the whole text, newlines included.
List<TextSpan> codeSpans(String text, CodeLanguage language, TextStyle style) {
  final lines = codeTokens(text, language);
  final spans = <TextSpan>[];
  for (var i = 0; i < lines.length; i++) {
    if (i > 0) spans.add(TextSpan(text: '\n', style: style));
    spans.addAll(codeLineSpans(lines[i], style));
  }
  return spans;
}

/// A field controller that colors what is typed. The text, the selection
/// and the line layout are the plain field's own.
class CodeController extends TextEditingController {
  CodeController({super.text, this.language = CodeLanguage.auto});

  CodeLanguage language;

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final base = style ?? const TextStyle();
    return TextSpan(style: base, children: codeSpans(text, language, base));
  }
}

final _jsonNumber = RegExp(r'-?\d+(?:\.\d+)?(?:[eE][+-]?\d+)?');
final _jsonWord = RegExp(r'[A-Za-z_][A-Za-z0-9_]*');

List<CodeToken> _jsonLine(String line) {
  final out = <CodeToken>[];
  var i = 0;
  final plain = StringBuffer();
  void flush() {
    if (plain.isEmpty) return;
    out.add(CodeToken(plain.toString(), CodeKind.plain));
    plain.clear();
  }

  while (i < line.length) {
    final c = line[i];
    if (c == '"') {
      flush();
      final end = _doubleQuoteEnd(line, i);
      final key = _colonAfter(line, end);
      out.add(
        CodeToken(line.substring(i, end), key ? CodeKind.key : CodeKind.string),
      );
      i = end;
      continue;
    }
    if (c == '{' || c == '}' || c == '[' || c == ']' || c == ',' || c == ':') {
      flush();
      out.add(CodeToken(c, CodeKind.punct));
      i++;
      continue;
    }
    final isNumberStart = c == '-' || _isDigit(c);
    if (isNumberStart) {
      final match = _jsonNumber.matchAsPrefix(line, i);
      if (match != null) {
        flush();
        out.add(CodeToken(match[0]!, CodeKind.number));
        i = match.end;
        continue;
      }
    }
    if (_isLetter(c)) {
      final match = _jsonWord.matchAsPrefix(line, i)!;
      final word = match[0]!;
      if (word == 'true' || word == 'false' || word == 'null') {
        flush();
        out.add(CodeToken(word, CodeKind.keyword));
      } else {
        plain.write(word);
      }
      i = match.end;
      continue;
    }
    plain.write(c);
    i++;
  }
  flush();
  return out;
}

bool _isDigit(String c) {
  final unit = c.codeUnitAt(0);
  return unit >= 0x30 && unit <= 0x39;
}

bool _isLetter(String c) {
  final unit = c.codeUnitAt(0);
  return (unit >= 0x41 && unit <= 0x5A) ||
      (unit >= 0x61 && unit <= 0x7A) ||
      unit == 0x5F;
}

bool _isSpace(String c) => c == ' ' || c == '\t' || c == '\r';

/// Index past the closing quote of the string that opens at [from]. A string
/// that does not close runs to the end of the line.
int _doubleQuoteEnd(String line, int from) {
  var i = from + 1;
  while (i < line.length) {
    final c = line[i];
    if (c == '\\') {
      i += 2;
      continue;
    }
    if (c == '"') return i + 1;
    i++;
  }
  return line.length;
}

/// YAML single quotes escape a quote by doubling it.
int _singleQuoteEnd(String line, int from) {
  var i = from + 1;
  while (i < line.length) {
    if (line[i] == "'") {
      if (i + 1 < line.length && line[i + 1] == "'") {
        i += 2;
        continue;
      }
      return i + 1;
    }
    i++;
  }
  return line.length;
}

bool _colonAfter(String line, int from) {
  var i = from;
  while (i < line.length && _isSpace(line[i])) {
    i++;
  }
  return i < line.length && line[i] == ':';
}

/// Where a YAML block scalar (`|` or `>`) stops: lines indented deeper than
/// [indent] belong to it. Null outside a block.
class _YamlBlock {
  int? indent;
}

final _yamlDash = RegExp(r'-(?:[ \t]+|$)');
final _yamlQuotedKey = RegExp(
  r'''("(?:[^"\\]|\\.)*"|'(?:[^']|'')*')([ \t]*)(:)(?=\s|$)''',
);
final _yamlPlainKey = RegExp(
  r'''([^\s#'"\[\]{}&*!|>%@`,][^#]*?)([ \t]*)(:)(?=\s|$)''',
);
final _yamlNumber = RegExp(
  r'^(?:[-+]?\d[\d_]*(?:\.\d*)?(?:[eE][-+]?\d+)?|[-+]?\.\d+(?:[eE][-+]?\d+)?|0x[0-9a-fA-F]+|0o[0-7]+|[-+]?\.(?:inf|Inf|INF)|\.(?:nan|NaN|NAN))$',
);
final _yamlFlowScalar = RegExp(r'(?:[^\s,\[\]{}#:]|:(?![\s,\]}]|$))+');
final _yamlBlockHead = RegExp(r'[|>][-+0-9]*(?=[ \t\r]|$)');
final _yamlProps = RegExp(r'[^\s,\[\]{}]+');

const _yamlKeywords = {
  'true',
  'false',
  'null',
  'True',
  'False',
  'Null',
  'TRUE',
  'FALSE',
  'NULL',
  '~',
};

CodeKind _yamlScalarKind(String text) {
  if (_yamlKeywords.contains(text)) return CodeKind.keyword;
  if (_yamlNumber.hasMatch(text)) return CodeKind.number;
  return CodeKind.string;
}

List<CodeToken> _yamlLine(String line, _YamlBlock block) {
  final out = <CodeToken>[];
  void add(String text, CodeKind kind) {
    if (text.isNotEmpty) out.add(CodeToken(text, kind));
  }

  final trimmed = line.trimLeft();
  final indent = line.length - trimmed.length;
  final blank = trimmed.trim().isEmpty;
  final open = block.indent;
  if (open != null) {
    if (blank || indent > open) {
      add(line, blank ? CodeKind.plain : CodeKind.string);
      return out;
    }
    block.indent = null;
  }
  if (blank) {
    add(line, CodeKind.plain);
    return out;
  }
  add(line.substring(0, indent), CodeKind.plain);
  if (trimmed.startsWith('#')) {
    add(trimmed, CodeKind.comment);
    return out;
  }
  var pos = indent;
  if (indent == 0 &&
      (trimmed.startsWith('---') || trimmed.startsWith('...')) &&
      (trimmed.length == 3 || _isSpace(trimmed[3]))) {
    add(trimmed.substring(0, 3), CodeKind.punct);
    pos = 3;
    _yamlValue(line, pos, 0, block, out);
    return out;
  }
  var dashCol = -1;
  while (true) {
    final match = _yamlDash.matchAsPrefix(line, pos);
    if (match == null) break;
    dashCol = pos;
    add('-', CodeKind.punct);
    add(match[0]!.substring(1), CodeKind.plain);
    pos += match[0]!.length;
  }
  final rest = line.substring(pos);
  final key =
      _yamlQuotedKey.matchAsPrefix(rest) ?? _yamlPlainKey.matchAsPrefix(rest);
  var column = dashCol >= 0 ? dashCol : indent;
  if (key != null) {
    add(key[1]!, CodeKind.key);
    add(key[2]!, CodeKind.plain);
    add(key[3]!, CodeKind.punct);
    column = pos;
    pos += key[0]!.length;
  }
  _yamlValue(line, pos, column, block, out);
  return out;
}

/// The part of a line after its key: a scalar, a quoted string, a flow
/// collection, a block header, a comment.
void _yamlValue(
  String line,
  int from,
  int column,
  _YamlBlock block,
  List<CodeToken> out,
) {
  void add(String text, CodeKind kind) {
    if (text.isNotEmpty) out.add(CodeToken(text, kind));
  }

  var i = from;
  var depth = 0;
  var first = true;
  while (i < line.length) {
    final c = line[i];
    if (_isSpace(c)) {
      var end = i;
      while (end < line.length && _isSpace(line[end])) {
        end++;
      }
      add(line.substring(i, end), CodeKind.plain);
      i = end;
      continue;
    }
    if (c == '#' && (i == from || _isSpace(line[i - 1]))) {
      add(line.substring(i), CodeKind.comment);
      return;
    }
    if (c == '"' || c == "'") {
      final end = c == '"'
          ? _doubleQuoteEnd(line, i)
          : _singleQuoteEnd(line, i);
      final key = depth > 0 && _colonAfter(line, end);
      add(line.substring(i, end), key ? CodeKind.key : CodeKind.string);
      i = end;
      first = false;
      continue;
    }
    if (c == '[' || c == '{') {
      depth++;
      add(c, CodeKind.punct);
      i++;
      first = false;
      continue;
    }
    if ((c == ']' || c == '}' || c == ',') && depth > 0) {
      if (c != ',') depth--;
      add(c, CodeKind.punct);
      i++;
      first = false;
      continue;
    }
    if (c == ':' && depth > 0) {
      add(c, CodeKind.punct);
      i++;
      first = false;
      continue;
    }
    if (c == '&' || c == '*' || c == '!') {
      final match = _yamlProps.matchAsPrefix(line, i)!;
      add(match[0]!, CodeKind.keyword);
      i = match.end;
      continue;
    }
    if (first && (c == '|' || c == '>')) {
      final match = _yamlBlockHead.matchAsPrefix(line, i);
      if (match != null) {
        add(match[0]!, CodeKind.punct);
        block.indent = column;
        i = match.end;
        first = false;
        continue;
      }
    }
    first = false;
    if (depth > 0) {
      final match = _yamlFlowScalar.matchAsPrefix(line, i);
      if (match == null) {
        add(c, CodeKind.plain);
        i++;
        continue;
      }
      final word = match[0]!;
      final key = _colonAfter(line, match.end);
      add(word, key ? CodeKind.key : _yamlScalarKind(word));
      i = match.end;
      continue;
    }
    var end = line.length;
    for (var k = i + 1; k < line.length; k++) {
      if (line[k] == '#' && _isSpace(line[k - 1])) {
        end = k;
        break;
      }
    }
    var text = line.substring(i, end);
    final scalar = text.trimRight();
    add(scalar, _yamlScalarKind(scalar));
    add(text.substring(scalar.length), CodeKind.plain);
    i = end;
  }
}
