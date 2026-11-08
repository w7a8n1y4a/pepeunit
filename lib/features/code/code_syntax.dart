import 'code_highlight.dart';

/// Languages of the Library code blocks beyond JSON and YAML. One small
/// scanner serves all of them: strings, comments, numbers, keywords and calls
/// are told apart, everything else stays plain. It is a reading aid, not a
/// parser, and it never fails: a line it cannot read stays plain.
///
/// [CodeLanguage.fromFence] maps the word after a fence to a language.
class _Spec {
  const _Spec({
    this.keywords = const {},
    this.lineComments = const ['//'],
    this.blockComment,
    this.quotes = const ['"', "'"],
    this.tripleQuotes = false,
    this.variables = false,
    this.directive = false,
    this.sections = false,
    this.instruction = false,
    this.calls = true,
  });

  final Set<String> keywords;
  final List<String> lineComments;
  final (String, String)? blockComment;
  final List<String> quotes;

  /// Python `"""` and `'''` run over several lines.
  final bool tripleQuotes;

  /// `$name` and `${name}` are variables (shell, nginx).
  final bool variables;

  /// The first word of a line is a directive (nginx).
  final bool directive;

  /// `[section]` lines (TOML).
  final bool sections;

  /// The first word of a line is an instruction (Dockerfile).
  final bool instruction;

  /// A word before `(` is a call.
  final bool calls;
}

Set<String> _words(String text) => text.split(RegExp(r'\s+')).toSet();

final _specs = <CodeLanguage, _Spec>{
  CodeLanguage.python: _Spec(
    keywords: _words(
      'and as assert async await break class continue def del elif else '
      'except finally for from global if import in is lambda nonlocal not or '
      'pass raise return try while with yield True False None self',
    ),
    lineComments: const ['#'],
    tripleQuotes: true,
  ),
  CodeLanguage.go: _Spec(
    keywords: _words(
      'break case chan const continue default defer else fallthrough for func '
      'go goto if import interface map package range return select struct '
      'switch type var true false nil',
    ),
    blockComment: ('/*', '*/'),
    quotes: const ['"', '`', "'"],
  ),
  CodeLanguage.rust: _Spec(
    keywords: _words(
      'as async await break const continue crate dyn else enum extern false fn '
      'for if impl in let loop match mod move mut pub ref return self Self '
      'static struct super trait true type unsafe use where while',
    ),
    blockComment: ('/*', '*/'),
  ),
  CodeLanguage.c: _Spec(
    keywords: _words(
      'auto break case char const continue default do double else enum extern '
      'float for goto if inline int long register return short signed sizeof '
      'static struct switch typedef union unsigned void volatile while bool '
      'true false NULL class namespace new delete public private protected '
      'template typename using virtual #include #define #ifdef #ifndef #endif',
    ),
    blockComment: ('/*', '*/'),
  ),
  CodeLanguage.javascript: _Spec(
    keywords: _words(
      'async await break case catch class const continue default delete do '
      'else export extends false finally for from function if import in '
      'instanceof let new null return static super switch this throw true try '
      'typeof undefined var void while yield interface type',
    ),
    blockComment: ('/*', '*/'),
    quotes: const ['"', "'", '`'],
  ),
  CodeLanguage.shell: _Spec(
    keywords: _words(
      'if then else elif fi for while do done case esac in function return '
      'export local readonly unset set source alias exit sudo',
    ),
    lineComments: const ['#'],
    variables: true,
    instruction: true,
  ),
  CodeLanguage.nginx: const _Spec(
    lineComments: ['#'],
    variables: true,
    directive: true,
    calls: false,
  ),
  CodeLanguage.toml: _Spec(
    keywords: _words('true false'),
    lineComments: const ['#'],
    sections: true,
    calls: false,
  ),
  CodeLanguage.sql: _Spec(
    keywords: _words(
      'select from where and or not in is null insert into values update set '
      'delete create table drop alter add join left right inner outer on as '
      'group by order having limit offset distinct union all primary key '
      'foreign references index unique default exists case when then else end '
      'SELECT FROM WHERE AND OR NOT IN IS NULL INSERT INTO VALUES UPDATE SET '
      'DELETE CREATE TABLE DROP ALTER ADD JOIN LEFT RIGHT INNER OUTER ON AS '
      'GROUP BY ORDER HAVING LIMIT OFFSET DISTINCT UNION ALL PRIMARY KEY '
      'FOREIGN REFERENCES INDEX UNIQUE DEFAULT EXISTS CASE WHEN THEN ELSE END',
    ),
    lineComments: const ['--'],
    blockComment: ('/*', '*/'),
  ),
  CodeLanguage.dockerfile: _Spec(
    keywords: _words(
      'FROM RUN CMD LABEL EXPOSE ENV ADD COPY ENTRYPOINT VOLUME USER WORKDIR '
      'ARG ONBUILD STOPSIGNAL HEALTHCHECK SHELL AS',
    ),
    lineComments: const ['#'],
    variables: true,
    calls: false,
  ),
};

/// Which language a fence word names. Unknown words give [CodeLanguage.plain].
CodeLanguage codeLanguageOfFence(String word) {
  switch (word.toLowerCase()) {
    case 'json':
    case 'jsonc':
      return CodeLanguage.json;
    case 'yaml':
    case 'yml':
      return CodeLanguage.yaml;
    case 'md':
    case 'markdown':
      return CodeLanguage.markdown;
    case 'py':
    case 'python':
    case 'micropython':
      return CodeLanguage.python;
    case 'go':
    case 'golang':
      return CodeLanguage.go;
    case 'rs':
    case 'rust':
      return CodeLanguage.rust;
    case 'c':
    case 'h':
    case 'cpp':
    case 'c++':
    case 'cc':
      return CodeLanguage.c;
    case 'js':
    case 'javascript':
    case 'ts':
    case 'typescript':
    case 'jsx':
    case 'tsx':
      return CodeLanguage.javascript;
    case 'sh':
    case 'bash':
    case 'zsh':
    case 'shell':
    case 'console':
      return CodeLanguage.shell;
    case 'nginx':
      return CodeLanguage.nginx;
    case 'toml':
    case 'ini':
    case 'env':
      return CodeLanguage.toml;
    case 'sql':
    case 'postgresql':
      return CodeLanguage.sql;
    case 'dockerfile':
    case 'docker':
      return CodeLanguage.dockerfile;
    default:
      return CodeLanguage.plain;
  }
}

bool codeHasSyntax(CodeLanguage language) => _specs.containsKey(language);

/// What a line leaves open for the next one.
class _Carry {
  /// Closing text of the block comment or triple quote still open.
  String? closing;
  CodeKind kind = CodeKind.comment;
}

/// One token list per line of [lines], for a language in [_specs].
List<List<CodeToken>> syntaxTokens(List<String> lines, CodeLanguage language) {
  final spec = _specs[language]!;
  final carry = _Carry();
  return [for (final line in lines) _scan(line, spec, carry)];
}

bool _isWordStart(String c) {
  final u = c.codeUnitAt(0);
  return (u >= 0x41 && u <= 0x5A) || (u >= 0x61 && u <= 0x7A) || u == 0x5F;
}

bool _isWordPart(String c) {
  final u = c.codeUnitAt(0);
  return _isWordStart(c) || (u >= 0x30 && u <= 0x39);
}

bool _isDigit(String c) {
  final u = c.codeUnitAt(0);
  return u >= 0x30 && u <= 0x39;
}

const _punct = '{}()[];,:=<>+-*/%&|!^~.?@';

List<CodeToken> _scan(String line, _Spec spec, _Carry carry) {
  final out = <CodeToken>[];
  final plain = StringBuffer();
  void flush() {
    if (plain.isEmpty) return;
    out.add(CodeToken(plain.toString(), CodeKind.plain));
    plain.clear();
  }

  void put(String text, CodeKind kind) {
    flush();
    out.add(CodeToken(text, kind));
  }

  var i = 0;
  final closing = carry.closing;
  if (closing != null) {
    final end = line.indexOf(closing);
    if (end < 0) {
      return line.isEmpty ? const [] : [CodeToken(line, carry.kind)];
    }
    put(line.substring(0, end + closing.length), carry.kind);
    carry.closing = null;
    i = end + closing.length;
  }

  if (spec.sections) {
    final section = RegExp(r'^\s*\[\[?[^\]]+\]\]?\s*$');
    if (section.hasMatch(line)) {
      return [CodeToken(line, CodeKind.keyword)];
    }
    final pair = RegExp(r'^(\s*)([A-Za-z0-9_."-]+)(\s*=)(.*)$')
        .firstMatch(line);
    if (pair != null) {
      if (pair.group(1)!.isNotEmpty) put(pair.group(1)!, CodeKind.plain);
      put(pair.group(2)!, CodeKind.key);
      put(pair.group(3)!, CodeKind.punct);
      out.addAll(_scan(pair.group(4)!, spec, carry));
      return out;
    }
  }

  var first = true;
  while (i < line.length) {
    final c = line[i];
    if (c == ' ' || c == '\t') {
      plain.write(c);
      i++;
      continue;
    }
    final rest = line.substring(i);
    final atStart = first;
    first = false;
    var comment = false;
    for (final mark in spec.lineComments) {
      if (rest.startsWith(mark)) comment = true;
    }
    // `#` inside a word is not a comment for the shell: `a#b`.
    if (comment && spec.lineComments.contains('#') && i > 0) {
      final before = line[i - 1];
      if (before != ' ' && before != '\t' && before != ';') comment = false;
    }
    if (comment) {
      put(rest, CodeKind.comment);
      return out;
    }
    final block = spec.blockComment;
    if (block != null && rest.startsWith(block.$1)) {
      final end = line.indexOf(block.$2, i + block.$1.length);
      if (end < 0) {
        put(rest, CodeKind.comment);
        carry
          ..closing = block.$2
          ..kind = CodeKind.comment;
        return out;
      }
      put(line.substring(i, end + block.$2.length), CodeKind.comment);
      i = end + block.$2.length;
      continue;
    }
    if (spec.tripleQuotes &&
        (rest.startsWith('"""') || rest.startsWith("'''"))) {
      final mark = rest.substring(0, 3);
      final end = line.indexOf(mark, i + 3);
      if (end < 0) {
        put(rest, CodeKind.string);
        carry
          ..closing = mark
          ..kind = CodeKind.string;
        return out;
      }
      put(line.substring(i, end + 3), CodeKind.string);
      i = end + 3;
      continue;
    }
    if (spec.quotes.contains(c)) {
      var end = i + 1;
      while (end < line.length) {
        if (line[end] == r'\' && c != '`') {
          end += 2;
          continue;
        }
        if (line[end] == c) {
          end++;
          break;
        }
        end++;
      }
      end = end > line.length ? line.length : end;
      put(line.substring(i, end), CodeKind.string);
      i = end;
      continue;
    }
    if (spec.variables && c == r'$') {
      final match = RegExp(
        r'^\$(?:\{[^}]*\}|[A-Za-z_][A-Za-z0-9_]*|[0-9@#?!*$-])',
      ).firstMatch(rest);
      if (match != null) {
        put(match.group(0)!, CodeKind.keyword);
        i += match.end;
        continue;
      }
    }
    if (_isDigit(c)) {
      final match = RegExp(
        r'^(?:0[xX][0-9a-fA-F_]+|\d[\d_]*(?:\.\d+)?(?:[eE][+-]?\d+)?)',
      ).firstMatch(rest)!;
      final before = i > 0 ? line[i - 1] : ' ';
      if (_isWordPart(before)) {
        plain.write(match.group(0));
      } else {
        put(match.group(0)!, CodeKind.number);
      }
      i += match.end;
      continue;
    }
    if (_isWordStart(c) ||
        (c == '#' && spec.keywords.any((k) => k[0] == '#'))) {
      var end = i + 1;
      while (end < line.length &&
          (_isWordPart(line[end]) ||
              (spec.directive && line[end] == '-') ||
              (spec.instruction && atStart && line[end] == '-'))) {
        end++;
      }
      final word = line.substring(i, end);
      var after = end;
      while (after < line.length && line[after] == ' ') {
        after++;
      }
      final call = spec.calls && after < line.length && line[after] == '(';
      if (spec.keywords.contains(word)) {
        put(word, CodeKind.keyword);
      } else if (spec.directive && atStart) {
        put(word, CodeKind.key);
      } else if (spec.instruction && atStart) {
        put(word, CodeKind.key);
      } else if (call) {
        put(word, CodeKind.key);
      } else {
        plain.write(word);
      }
      i = end;
      continue;
    }
    if (_punct.contains(c)) {
      put(c, CodeKind.punct);
      i++;
      continue;
    }
    plain.write(c);
    i++;
  }
  flush();
  return out;
}

// --------------------------------------------------------------- markdown

final _mdHeading = RegExp(r'^(\s{0,3}#{1,6})(\s.*)?$');
final _mdFence = RegExp(r'^\s*(`{3,}|~{3,})');
final _mdAdmonition = RegExp(r'^(\s*:::)(\s*\w*)(.*)$');
final _mdList = RegExp(r'^(\s*)([-*+]|\d+[.)])(\s+)(.*)$');
final _mdInline = RegExp(
  r'(`[^`]+`)|(!?\[[^\]]*\]\([^)]*\))|(\*\*[^*]+\*\*)|(https?://[^\s)]+)',
);

/// One token list per line of a markdown source: headings, fences, list
/// marks, `:::` blocks, quotes, links and code spans. Text inside a fence is
/// colored by the language of that fence.
List<List<CodeToken>> markdownTokens(List<String> lines) {
  final out = <List<CodeToken>>[];
  String? fence;
  CodeLanguage? inner;
  var block = <String>[];

  void closeBlock() {
    if (block.isEmpty) return;
    final language = inner;
    if (language != null && codeHasSyntax(language)) {
      out.addAll(syntaxTokens(block, language));
    } else if (language == CodeLanguage.json || language == CodeLanguage.yaml) {
      out.addAll(codeTokens(block.join('\n'), language!));
    } else {
      for (final line in block) {
        out.add(line.isEmpty ? const [] : [CodeToken(line, CodeKind.plain)]);
      }
    }
    block = <String>[];
  }

  for (final line in lines) {
    final open = _mdFence.firstMatch(line);
    if (fence != null) {
      if (open != null &&
          open.group(1)!.startsWith(fence[0]) &&
          line.trim().replaceAll(fence[0], '').isEmpty) {
        closeBlock();
        out.add([CodeToken(line, CodeKind.punct)]);
        fence = null;
        inner = null;
      } else {
        block.add(line);
      }
      continue;
    }
    if (open != null) {
      fence = open.group(1)!;
      final word = line.trim().substring(fence.length).trim();
      inner = codeLanguageOfFence(word);
      out.add([CodeToken(line, CodeKind.punct)]);
      continue;
    }
    out.add(_markdownLine(line));
  }
  closeBlock();
  return out;
}

List<CodeToken> _markdownLine(String line) {
  if (line.isEmpty) return const [];
  final heading = _mdHeading.firstMatch(line);
  if (heading != null) {
    return [
      CodeToken(heading.group(1)!, CodeKind.punct),
      if (heading.group(2) != null) CodeToken(heading.group(2)!, CodeKind.key),
    ];
  }
  final admonition = _mdAdmonition.firstMatch(line);
  if (admonition != null) {
    return [
      CodeToken(admonition.group(1)!, CodeKind.punct),
      if (admonition.group(2)!.isNotEmpty)
        CodeToken(admonition.group(2)!, CodeKind.keyword),
      if (admonition.group(3)!.isNotEmpty)
        CodeToken(admonition.group(3)!, CodeKind.plain),
    ];
  }
  if (line.trimLeft().startsWith('>')) {
    return [CodeToken(line, CodeKind.comment)];
  }
  final out = <CodeToken>[];
  var rest = line;
  final list = _mdList.firstMatch(line);
  if (list != null) {
    out.add(CodeToken('${list.group(1)}${list.group(2)}', CodeKind.punct));
    out.add(CodeToken(list.group(3)!, CodeKind.plain));
    rest = list.group(4)!;
  }
  var at = 0;
  for (final match in _mdInline.allMatches(rest)) {
    if (match.start > at) {
      out.add(CodeToken(rest.substring(at, match.start), CodeKind.plain));
    }
    final kind = match.group(1) != null
        ? CodeKind.string
        : match.group(2) != null
        ? CodeKind.number
        : match.group(3) != null
        ? CodeKind.keyword
        : CodeKind.number;
    out.add(CodeToken(match.group(0)!, kind));
    at = match.end;
  }
  if (at < rest.length) {
    out.add(CodeToken(rest.substring(at), CodeKind.plain));
  }
  return out;
}
