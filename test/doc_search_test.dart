import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/library/doc_search.dart';
import 'package:pepeunit_client/library/library.dart';

DocsTree _tree(Map<String, String> files) {
  return DocsTree.build(
    keys: files.keys,
    language: 'ru',
    read: (key) => files[key]!,
  );
}

final _files = {
  'docs/ru/sidebar.json': '''[
    { "text": "Начало", "link": "/intro" },
    { "text": "Устройства", "items": [
      { "text": "Юниты", "link": "/units/unit" }
    ] }
  ]''',
  'docs/ru/intro.md': '''# Введение

Pepeunit соединяет устройства с сервером.

## Установка

Скопируйте файл `docker-compose.yml` и запустите контейнеры.

### Переменные окружения

Файл `.env` задаёт адрес базы данных.
''',
  'docs/ru/units/unit.md': '''# Юнит

Юнит — это программа на устройстве.

## Команды

Команда обновления скачивает новую версию программы.

## Установка

Юнит ставится из репозитория.
''',
  'docs/ru/lonely.md': '''# Одинокая

Статья без места в дереве: бирюзовый.
''',
};

void main() {
  group('sections', () {
    test('an article is cut at its headings, the title is not a section', () {
      final tree = _tree(_files);
      final sections = sectionsOfArticle(tree.article('intro')!);
      expect(
        [for (final s in sections) s.heading],
        [null, 'Установка', 'Переменные окружения'],
      );
      expect(sections[0].text, contains('соединяет устройства'));
      expect(sections[1].anchor, 'установка');
      expect(sections[2].trail, ['Установка']);
      expect(sections[2].text, contains('адрес базы данных'));
      // The words under a heading do not leak into the one above it.
      expect(sections[1].text, isNot(contains('адрес базы данных')));
    });
  });

  group('search', () {
    final index = DocSearchIndex.of(_tree(_files));

    test('an empty query finds nothing', () {
      expect(index.search(''), isEmpty);
      expect(index.search('   '), isEmpty);
    });

    test('a heading outweighs the words under another one', () {
      final hits = index.search('установка');
      expect(hits.first.section.heading, 'Установка');
      expect(hits.first.section.article.path, 'intro');
      // The sidebar order breaks the tie between equal hits.
      expect(hits[1].section.heading, 'Установка');
      expect(hits[1].section.article.path, 'units/unit');
    });

    test('all words have to be found in one section', () {
      final hits = index.search('docker контейнеры');
      expect(hits, hasLength(1));
      expect(hits.single.section.heading, 'Установка');
      expect(index.search('docker репозитория'), isEmpty);
    });

    test('an ending does not matter, nor does the breve', () {
      expect(index.search('устройство').first.section.article.path, 'intro');
      expect(index.search('юнит').first.section.article.path, 'units/unit');
      expect(index.search('Юнит').first.section.article.path, 'units/unit');
      // `й` and `и` count the same, and so do `ё` and `е`.
      List<String> paths(String query) => [
        for (final hit in index.search(query))
          '${hit.section.article.path}#${hit.section.anchor}',
      ];
      expect(paths('юнит'), paths('юнйт'));
    });

    test('the title of an article finds its first part', () {
      final hit = index.search('введение').first;
      expect(hit.section.article.path, 'intro');
      expect(hit.section.intro, isTrue);
    });

    test('code is searched too', () {
      final hit = index.search('docker-compose').first;
      expect(hit.section.heading, 'Установка');
    });

    test('an article the sidebar leaves out is found, last', () {
      final hits = index.search('бирюзовый');
      expect(hits.single.section.article.path, 'lonely');
    });

    test('a letter inside a word is not a start of it', () {
      expect(index.search('ст'), isNotEmpty);
      // Two letters match only the start of a word.
      expect(index.search('нк'), isEmpty);
      expect(index.search('тановк'), isNotEmpty);
    });
  });

  group('marks', () {
    test('a term that starts a word covers the whole word', () {
      final ranges = markRanges('Устройства и устройство', queryTerms('устро'));
      expect(ranges, [(start: 0, end: 10), (start: 13, end: 23)]);
    });

    test('ranges that overlap are one', () {
      final ranges = markRanges('файлы и файл', queryTerms('фай файл'));
      expect(ranges, [(start: 0, end: 5), (start: 8, end: 12)]);
      expect(markRanges('файлы', queryTerms('фай файл')), [(start: 0, end: 5)]);
    });

    test('a find marks every place, anywhere in a word', () {
      expect(findRanges('Файл и файлы, ФАЙЛ', foldText('файл')), [
        (start: 0, end: 4),
        (start: 7, end: 11),
        (start: 14, end: 18),
      ]);
      expect(findRanges('аааа', 'аа'), [
        (start: 0, end: 2),
        (start: 2, end: 4),
      ]);
      expect(findRanges('текст', ''), isEmpty);
      // `й` and `е` are what a person types for `и` and `ё`.
      expect(findRanges('Йод', foldText('иод')), [(start: 0, end: 3)]);
    });

    test('a text keeps its length when folded', () {
      const text = 'ЁЖИК Йод Hello';
      expect(foldText(text), hasLength(text.length));
    });

    test('an excerpt holds the first word found', () {
      final text = '${'слово ' * 60}цель ${'слово ' * 60}'.trim();
      final cut = excerptOf(text, queryTerms('цель'));
      expect(cut, contains('цель'));
      expect(cut.length, lessThan(190));
      expect(cut, startsWith('…'));
      expect(cut, endsWith('…'));
    });

    test('a short text is its own excerpt', () {
      expect(excerptOf('коротко', const ['кор']), 'коротко');
    });
  });
}
