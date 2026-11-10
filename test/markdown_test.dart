import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/library/markdown.dart';

void main() {
  test('front matter is split off and read', () {
    final split = splitFrontMatter('---\nlibrary: false # why\n---\n# Title\n');
    expect(split.meta['library'], false);
    expect(split.body, '# Title\n');
    expect(splitFrontMatter('# Title').meta, isEmpty);
  });

  test('title is the first level one heading outside a fence', () {
    expect(
      markdownTitle('text\n```\n# no\n```\n# Real *one*\n## two'),
      'Real one',
    );
    expect(markdownTitle('no headings'), isNull);
  });

  test('headings get unique anchors the old site would give', () {
    final doc = parseMarkdown(
      '# Один\n## Заполнение Первичного .env\n## Один\n',
    );
    expect(
      [for (final h in doc.headings) h.slug],
      ['один', 'заполнение-первичного-env', 'один-1'],
    );
    expect(slugOf('Пример: Last Value!'), 'пример-last-value');
  });

  test('lists keep nested blocks, fences stay inside their item', () {
    final doc = parseMarkdown(
      '- Остановить\n    ```bash\n    docker compose down\n    ```\n'
      '- Запустить\n  1. раз\n  2. два\n',
    );
    final list = doc.blocks.single as MdListBlock;
    expect(list.items, hasLength(2));
    final code = list.items[0][1] as MdCodeBlock;
    expect(code.language, 'bash');
    expect(code.code, 'docker compose down');
    final inner = list.items[1][1] as MdListBlock;
    expect(inner.ordered, isTrue);
    expect(inner.items, hasLength(2));
  });

  test('a table keeps pipes inside code and pads short rows', () {
    final doc = parseMarkdown(
      'Имя | Значение\n-- | --\n`a|b` | один\nкороткая |\n',
    );
    final table = doc.blocks.single as MdTable;
    expect(table.header, hasLength(2));
    expect(plainText(table.rows[0][0]), 'a|b');
    expect(table.rows[1], hasLength(2));
    expect(plainText(table.rows[1][1]), '');
  });

  test('table alignment comes from the rule row', () {
    final table =
        parseMarkdown('a | b | c\n:-- | :-: | --:\n1 | 2 | 3\n').blocks.single
            as MdTable;
    expect(table.aligns, [MdAlign.left, MdAlign.center, MdAlign.right]);
  });

  test('::: blocks are admonitions with a default title', () {
    final doc = parseMarkdown(
      ':::warning\nОсторожно\n:::\n\n:::info Где?\nТут\n:::\n',
    );
    final first = doc.blocks[0] as MdAdmonition;
    expect(first.kind, MdAdmonitionKind.warning);
    expect(first.title, 'Внимание');
    final second = doc.blocks[1] as MdAdmonition;
    expect(second.title, 'Где?');
    expect(second.blocks.single, isA<MdParagraph>());
    expect(admonitionTitle(MdAdmonitionKind.warning, 'en'), 'Warning');
    expect(admonitionTitle(MdAdmonitionKind.warning, 'ru'), first.title);
  });

  test('a YouTube iframe or a lone link is a video', () {
    final doc = parseMarkdown(
      '<iframe width="100%" src="https://www.youtube.com/embed/hEBC7jfkgy0" allowfullscreen></iframe>\n\n'
      'https://www.youtube.com/watch?v=r1CpkXD_MJY\n\n'
      '![x](https://youtu.be/AAAAAAAAAAA)\n',
    );
    expect(
      [for (final b in doc.blocks) (b as MdVideo).id],
      ['hEBC7jfkgy0', 'r1CpkXD_MJY', 'AAAAAAAAAAA'],
    );
  });

  test('an image alone is a block, a gif is just an image', () {
    final doc = parseMarkdown('![схема](https://a.b/c.gif)\n');
    final image = doc.blocks.single as MdImage;
    expect(image.url, 'https://a.b/c.gif');
    expect(image.alt, 'схема');
  });

  test('inlines: code, emphasis, links, bare links, escapes', () {
    final inlines = parseInlines(
      'Есть `PU_FF_X`, **жирный**, _курсив_, [ссылка](/a/b#c), https://x.y/z. \\*не звезда\\*',
    );
    expect(inlines.whereType<MdCodeSpan>().single.code, 'PU_FF_X');
    final marks = inlines.whereType<MdMarked>().map((m) => m.mark).toList();
    expect(marks, [MdMark.bold, MdMark.italic]);
    final links = inlines.whereType<MdLink>().toList();
    expect(links.map((l) => l.url), ['/a/b#c', 'https://x.y/z']);
    expect(plainText(inlines), contains('*не звезда*'));
  });

  test('snake_case words are not emphasis', () {
    expect(
      plainText(parseInlines('PU_FF_TELEGRAM_BOT и snake_case_word')),
      'PU_FF_TELEGRAM_BOT и snake_case_word',
    );
  });

  test('every documentation article parses and has a title', () {
    final root = Directory('docs/ru');
    var count = 0;
    for (final file in root.listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.md')) continue;
      final source = file.readAsStringSync();
      final doc = parseMarkdown(source);
      count++;
      if (file.path.endsWith('docs/ru/index.md')) continue;
      expect(doc.blocks, isNotEmpty, reason: file.path);
      expect(markdownTitle(source), isNotNull, reason: file.path);
    }
    expect(count, greaterThan(50));
  });
}
