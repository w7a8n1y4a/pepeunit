import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/features/code/code_highlight.dart';
import 'package:pepeunit_client/features/code/code_syntax.dart';

void main() {
  const samples = {
    CodeLanguage.python: 'import os\n\ndef run(x):\n    """doc\n    more"""\n    return "a" # note\n',
    CodeLanguage.go:
        'package main\n/* a\nb */\nfunc main() {\n\tx := `raw`\n}\n',
    CodeLanguage.rust: 'fn main() {\n    let x = 0x1F; // c\n}\n',
    CodeLanguage.c: '#include <stdio.h>\nint main(void) { return 0; }\n',
    CodeLanguage.javascript: 'const a = () => `t`;\n',
    CodeLanguage.shell: 'echo "\$HOME" # hi\ndocker exec -it x /bin/sh\n',
    CodeLanguage.nginx:
        'server {\n    listen 80;\n    proxy_pass http://\$host;\n}\n',
    CodeLanguage.toml: '[general]\nname = "x"\nlist = [1, 2]\n',
    CodeLanguage.sql: "SELECT a FROM t WHERE b = 'x' -- c\n",
    CodeLanguage.dockerfile: 'FROM debian\nRUN echo \$A\n',
    CodeLanguage.markdown: '# T\n\n- item `code` [l](u)\n:::tip\nx\n:::\n```python\nprint(1)\n```\n> q\n',
  };

  test('tokens of a line join back to the line, in every language', () {
    for (final entry in samples.entries) {
      final lines = entry.value.split('\n');
      final tokens = codeTokens(entry.value, entry.key);
      expect(tokens, hasLength(lines.length), reason: '${entry.key}');
      for (var i = 0; i < lines.length; i++) {
        expect(
          tokens[i].map((t) => t.text).join(),
          lines[i],
          reason: '${entry.key} line $i',
        );
      }
    }
  });

  test('strings, comments, keywords and numbers are told apart', () {
    CodeKind? kindOf(String text, CodeLanguage language, String piece) {
      for (final token in codeTokens(text, language).expand((line) => line)) {
        if (token.text == piece) return token.kind;
      }
      return null;
    }

    expect(
      kindOf('return "a" # n', CodeLanguage.python, 'return'),
      CodeKind.keyword,
    );
    expect(
      kindOf('return "a" # n', CodeLanguage.python, '"a"'),
      CodeKind.string,
    );
    expect(
      kindOf('return "a" # n', CodeLanguage.python, '# n'),
      CodeKind.comment,
    );
    expect(kindOf('x = 42', CodeLanguage.python, '42'), CodeKind.number);
    expect(kindOf('listen 80;', CodeLanguage.nginx, 'listen'), CodeKind.key);
    expect(
      kindOf('[general]', CodeLanguage.toml, '[general]'),
      CodeKind.keyword,
    );
  });

  test('a multi-line string or comment keeps its color to the end', () {
    final tokens = codeTokens('x = """a\nb\nc""" + 1', CodeLanguage.python);
    expect(tokens[1].single.kind, CodeKind.string);
    expect(tokens[2].first.kind, CodeKind.string);
  });

  test('a fence word names a language', () {
    expect(codeLanguageOfFence('py'), CodeLanguage.python);
    expect(codeLanguageOfFence('YML'), CodeLanguage.yaml);
    expect(codeLanguageOfFence('nginx'), CodeLanguage.nginx);
    expect(codeLanguageOfFence('mermaid'), CodeLanguage.plain);
    expect(codeLanguageOfFence(''), CodeLanguage.plain);
  });
}
