import 'dart:convert';
import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pepeunit_client/account/key_file_port.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/client_version.dart';
import 'package:pepeunit_client/features/library/doc_find_bar.dart';
import 'package:pepeunit_client/features/library/doc_search_panel.dart';
import 'package:pepeunit_client/features/library/docs_page.dart';
import 'package:pepeunit_client/features/library/library_modal.dart';
import 'package:pepeunit_client/features/library/tip_modal.dart';
import 'package:pepeunit_client/hive/bevel.dart';
import 'package:pepeunit_client/features/library/md_view.dart';
import 'package:pepeunit_client/library/library.dart';
import 'package:pepeunit_client/library/markdown.dart';
import 'package:pepeunit_client/main.dart';

DocsTree _tree(Map<String, String> files) {
  return DocsTree.build(
    keys: files.keys,
    language: 'ru',
    read: (key) => files[key]!,
  );
}

void main() {
  test('the sidebar binds files to names, a missing file is left out', () {
    final tree = _tree({
      'docs/ru/a/one.md': '# Первая\n',
      'docs/ru/a/deep/two.md': '# Вторая\n',
      'docs/ru/top.md': '# Верхняя\n',
      'docs/ru/lonely.md': '# Одинокая\n',
      'docs/ru/sidebar.json': '''[
        { "text": "Раздел", "items": [
          { "text": "Один", "link": "/a/one" },
          { "text": "Папка", "collapsed": true, "items": [
            { "text": "Два", "link": "/a/deep/two.md" },
            { "text": "Нет такой", "link": "/a/missing" }
          ] },
          { "text": "Пустая", "items": [ { "text": "Нет", "link": "/none" } ] }
        ] },
        { "text": "Верх", "link": "/top" }
      ]''',
    });
    final root = tree.sidebar;
    expect([for (final n in root) n.text], ['Раздел', 'Верх']);
    expect(root[1].path, 'top');
    expect(root[1].isGroup, isFalse);
    final group = root[0];
    expect([for (final n in group.items) n.text], ['Один', 'Папка']);
    expect(group.items[0].path, 'a/one');
    final folder = group.items[1];
    expect(folder.collapsed, isTrue);
    expect([for (final n in folder.items) n.text], ['Два']);
    expect(folder.items.single.path, 'a/deep/two');
    // A row keeps its place in the file when another is left out.
    expect(folder.id, '0.1');
    expect(folder.items.single.id, '0.1.0');
    expect(tree.first!.path, 'a/one');
    expect(tree.groupsOf('a/deep/two'), ['0', '0.1']);
    expect(tree.groupsOf('top'), isEmpty);
    // The title of an article is its heading, not its row.
    expect(tree.article('a/deep/two')!.title, 'Вторая');
    // A file no row links to is not in the tree, a link still reaches it.
    expect(tree.groupsOf('lonely'), isEmpty);
    expect(tree.article('lonely'), isNotNull);
    expect(resolveDocLink('/lonely', tree: tree)!.article!.path, 'lonely');
  });

  test('a sidebar that is not a list of named rows is an error', () {
    bool all(String _) => true;
    expect(() => parseSidebar('{}', all), throwsFormatException);
    expect(() => parseSidebar('[1]', all), throwsFormatException);
    expect(() => parseSidebar('[{"link": "/a"}]', all), throwsFormatException);
    expect(() => parseSidebar('[', all), throwsFormatException);
    expect(parseSidebar('[]', all), isEmpty);
  });

  test('a link finds its article from where the text stands', () {
    final tree = _tree({
      'docs/ru/a/one.md': '# Первая\n',
      'docs/ru/a/two.md': '# Вторая\n',
      'docs/ru/b/three.md': '# Третья\n',
    });
    String? at(String url, [String? from]) =>
        resolveDocLink(url, tree: tree, from: from)?.article?.path;
    expect(at('/b/three'), 'b/three');
    expect(at('/b/three.md'), 'b/three');
    expect(at('/b/three/'), 'b/three');
    expect(at('two', 'a/one'), 'a/two');
    expect(at('../b/three', 'a/one'), 'b/three');
    expect(at('/missing'), isNull);
    expect(resolveDocLink('#Часть')!.anchor, 'часть');
    expect(resolveDocLink('#'), isNull);
    expect(resolveDocLink('https://x.y')!.outside, Uri.parse('https://x.y'));
    expect(resolveDocLink('/b/three#раздел', tree: tree)!.anchor, 'раздел');
  });

  test('another language falls back to Russian path by path', () {
    final files = {
      'docs/ru/a.md': '# Русская\n',
      'docs/ru/b.md': '# Вторая\n',
      'docs/en/a.md': '# English\n',
      'docs/ru/sidebar.json':
          '[{"text": "А", "link": "/a"}, {"text": "Б", "link": "/b"}]',
    };
    final tree = DocsTree.build(
      keys: files.keys,
      language: 'en',
      read: (key) => files[key]!,
    );
    expect(tree.article('a')!.title, 'English');
    expect(tree.article('b')!.title, 'Вторая');
    // No English sidebar: the Russian one serves.
    expect([for (final n in tree.sidebar) n.text], ['А', 'Б']);
    files['docs/en/sidebar.json'] = '[{"text": "B", "link": "/b"}]';
    final own = DocsTree.build(
      keys: files.keys,
      language: 'en',
      read: (key) => files[key]!,
    );
    expect([for (final n in own.sidebar) n.text], ['B']);
  });

  test('a tip belongs to a screen by its route pattern', () {
    expect(tipScreenOf('/'), 'home');
    expect(tipScreenOf('/library'), 'library');
    expect(tipScreenOf('/units/:uuid/io/:io'), 'units.uuid.io.io');
    expect(tipCellOk('people'), isTrue);
    expect(tipCellOk('notice:3f'), isFalse);
    expect(tipCellOk('dir:deployment/docker'), isFalse);
  });

  test('a tip is found by screen and cell, a shared one and Russian serve', () {
    final library = Library.fromTexts({
      'tooltip/ru/home.people.md': 'a',
      'tooltip/ru/common.back.md': 'b',
      'tooltip/ru/units.search.unit.md': 'c',
    });
    expect(library.tipKey('ru', 'home', 'people'), endsWith('home.people.md'));
    expect(library.tipKey('ru', 'units', 'back'), endsWith('common.back.md'));
    expect(library.tipKey('en', 'home', 'people'), contains('/ru/'));
    expect(
      library.tipKey('ru', 'units.search', 'unit:3f'),
      endsWith('units.search.unit.md'),
    );
    expect(library.tipKey('ru', 'home', 'nothing'), isNull);
  });

  group('bundled texts', () {
    late Library library;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      library = Library.instance;
      await library.load();
    });

    test('the documentation folders are the ones in pubspec', () {
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final root = Directory('docs/ru');
      for (final entity in root.listSync(recursive: true)) {
        if (entity is! Directory) continue;
        final path = entity.path;
        if (path.startsWith('docs/ru/user')) {
          expect(pubspec, isNot(contains('- $path/')), reason: path);
          continue;
        }
        expect(pubspec, contains('- $path/'), reason: path);
      }
      expect(pubspec, contains('- docs/ru/sidebar.json'));
      expect(pubspec, isNot(contains('docs/ru/definitions.md')));
      expect(pubspec, isNot(contains('docs/ru/conception/')));
      expect(pubspec, isNot(contains('docs/ru/index.md')));
    });

    test(
      'the sidebar lists every bundled article once, and only them',
      () async {
        final tree = await library.docs('ru');
        expect(
          [for (final n in tree.sidebar) n.text],
          ['Развёртывание', 'Разработчику Unit', 'Разработчику Pepeunit'],
        );
        expect(tree.article('definitions'), isNull);
        expect(tree.article('conception/overview'), isNull);
        expect(tree.article('development-pepeunit/maps'), isNotNull);
        for (final article in tree.articles) {
          expect(article.path, isNot(startsWith('user/')));
        }
        // The file is read as written: a mistyped link would be left out of
        // the tree without a word, so every link is checked against the files.
        final listed = <String>[];
        void walk(Object? rows) {
          for (final row in rows as List) {
            final link = (row as Map)['link'] as String?;
            if (link != null) {
              listed.add(docPathOf(link));
              expect(
                File('docs/ru/${docPathOf(link)}.md').existsSync(),
                isTrue,
                reason: link,
              );
            }
            if (row['items'] != null) walk(row['items']);
          }
        }

        walk(jsonDecode(File('docs/ru/sidebar.json').readAsStringSync()));
        expect(listed.toSet().length, listed.length, reason: 'a link twice');
        expect(
          tree.articles.map((a) => a.path).toSet(),
          listed.toSet(),
          reason: 'an article has no row, or a row has no article',
        );
      },
    );

    test(
      'every article opens with its title and its links lead somewhere',
      () async {
        final tree = await library.docs('ru');
        final docs = {
          for (final article in tree.articles)
            article.path: parseMarkdown(article.source),
        };
        final link = RegExp(r'\]\(([^)\s]*)\)');
        final broken = <String>[];
        for (final article in tree.articles) {
          final doc = docs[article.path]!;
          final first = doc.blocks.first;
          if (first is! MdHeading || first.level != 1) {
            broken.add('${article.path}: no title first');
          }
          for (final match in link.allMatches(article.source)) {
            final url = match.group(1)!;
            if (url.startsWith('http') || url.startsWith('mailto:')) continue;
            // Pictures wait for the schemas to be brought up to date.
            if (url.startsWith('/schemas/')) continue;
            final hash = url.indexOf('#');
            var target = hash < 0 ? url : url.substring(0, hash);
            if (target.startsWith('/')) target = target.substring(1);
            if (target.isEmpty) target = article.path;
            final to = docs[target];
            if (to == null) {
              // The user guide is not in the bundle: its links stay plain.
              if (!target.startsWith('user/')) {
                broken.add('${article.path}: $url');
              }
              continue;
            }
            if (hash >= 0) {
              final key = anchorKey(url.substring(hash + 1));
              if (!to.headings.any((h) => anchorKey(h.slug) == key)) {
                broken.add('${article.path}: $url');
              }
            }
          }
        }
        expect(broken, isEmpty);
      },
    );

    test('every Russian tip is bundled and not empty', () async {
      final files = Directory('tooltip/ru')
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.md'))
          .toList();
      expect(files.length, greaterThan(300));
      for (final file in files) {
        final key = file.path.replaceAll('\\', '/');
        expect(library.has(key), isTrue, reason: key);
        expect((await library.text(key)).trim(), isNotEmpty, reason: key);
      }
    });

    test('every link of a tip leads to an article of the bundle', () async {
      final tree = await library.docs('ru');
      final link = RegExp(r'\]\(([^)\s]*)\)');
      final broken = <String>[];
      for (final file in Directory('tooltip/ru').listSync().whereType<File>()) {
        final text = file.readAsStringSync();
        for (final match in link.allMatches(text)) {
          final url = match.group(1)!;
          if (url.startsWith('http')) continue;
          if (resolveDocLink(url, tree: tree)?.article == null) {
            broken.add('${file.path}: $url');
          }
        }
      }
      expect(broken, isEmpty);
    });

    test('the presentation has no slides yet', () async {
      expect(await library.presentation('ru'), isEmpty);
    });
  });

  group('screens', () {
    // Controlled texts keep these gesture tests independent of the copy.
    final tips = {
      'tooltip/ru/home.library.md': 'Подсказка библиотеки.',
      'tooltip/ru/common.back.md': 'Подсказка возврата.',
    };

    Future<AppModel> start(
      WidgetTester tester, {
      Map<String, String>? withTips,
      KeyFilePort? files,
      http.Client? client,
    }) async {
      if (withTips != null) {
        final real = Library.instance;
        Library.instance = Library.fromTexts(withTips);
        addTearDown(() => Library.instance = real);
      }
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(Library.instance.load);
      final model = AppModel(
        store: MemoryVaultStore(),
        files: files,
        client: client,
      );
      await model.load();
      await tester.pumpWidget(
        AppScope(model: model, child: const PepeunitApp(background: false)),
      );
      await tester.pumpAndSettle();
      return model;
    }

    Future<void> settle(WidgetTester tester) async {
      // Texts come from the bundle, which needs real time.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Library: documentation is a full screen with a sidebar', (
      tester,
    ) async {
      await start(tester);
      await tester.tap(find.bySemanticsLabel('Библиотека'));
      await tester.pumpAndSettle();
      for (final label in [
        'Документация',
        'Дерево 6 путей',
        'Презентация',
        'Инструменты',
        'О приложении',
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }
      expect(find.text('.md'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Документация'));
      await settle(tester);
      // No cells: the sidebar, the first article, the bar.
      expect(find.byType(DocsPage), findsOneWidget);
      expect(find.byType(MdView), findsOneWidget);
      expect(find.text('Конфигурации Nginx'), findsOneWidget);
      expect(find.text('Развёртывание'), findsWidgets);
      // The article is always rendered: there is no switch to its source.
      expect(find.text('Рендер'), findsNothing);
      expect(find.text('Исходник'), findsNothing);
      expect(find.bySemanticsLabel('Закрыть'), findsOneWidget);
      expect(find.bySemanticsLabel('Назад'), findsNothing);
      // Groups the file leaves folded are folded.
      expect(find.text('Docker'), findsOneWidget);
      expect(find.text('Установка Docker и Compose'), findsNothing);
      await tester.tap(find.text('Docker'));
      await tester.pumpAndSettle();
      expect(find.text('Установка Docker и Compose'), findsOneWidget);
      await tester.tap(find.text('Установка Docker и Compose'));
      await settle(tester);
      expect(find.text('Установка Docker и Compose'), findsWidgets);
      // Back is the picture of the Back cell, not a word.
      expect(find.text('Назад'), findsNothing);
      expect(find.bySemanticsLabel('Назад'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Назад'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Назад'), findsNothing);
      // Close returns to the Library menu.
      await tester.tap(find.bySemanticsLabel('Закрыть'));
      await settle(tester);
      expect(find.byType(DocsPage), findsNothing);
      expect(find.bySemanticsLabel('Документация'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    Future<void> openDocs(WidgetTester tester, Size size) async {
      await start(tester);
      tester.view.physicalSize = size;
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Библиотека'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Документация'));
      await settle(tester);
    }

    // The layout has three stages, the way VitePress has: half of a 16:9
    // screen, a large one, a phone.
    testWidgets('Library: half a screen has the sidebar at the left edge', (
      tester,
    ) async {
      await openDocs(tester, const Size(960, 540));
      final row = find.text('Развёртывание').first;
      expect(tester.getTopLeft(row).dx, lessThan(40));
      // The scroll bar of the text is at the right edge of the screen.
      expect(tester.getTopRight(find.byType(MdView)).dx, 960);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Library: a large screen centers the sidebar and the text', (
      tester,
    ) async {
      await openDocs(tester, const Size(1920, 1080));
      final row = find.text('Развёртывание').first;
      expect(tester.getTopLeft(row).dx, greaterThan(100));
      expect(tester.getTopRight(find.byType(MdView)).dx, 1920);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Library: a large screen has the outline of the text', (
      tester,
    ) async {
      await openDocs(tester, const Size(1920, 1080));
      expect(find.text('На этой странице'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Library: a smaller screen has no outline', (tester) async {
      await openDocs(tester, const Size(1200, 800));
      expect(find.text('На этой странице'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Library: a phone has the text alone, the sidebar is a mark', (
      tester,
    ) async {
      await openDocs(tester, const Size(420, 800));
      expect(find.text('Развёртывание'), findsNothing);
      expect(tester.getTopRight(find.byType(MdView)).dx, 420);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Library: search leads to the article that has the words', (
      tester,
    ) async {
      await openDocs(tester, const Size(1200, 800));
      expect(find.byType(DocSearchPanel), findsNothing);
      await tester.tap(find.bySemanticsLabel('Поиск'));
      await tester.pumpAndSettle();
      expect(find.byType(DocSearchPanel), findsOneWidget);
      expect(find.text('Введите слова из статьи'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'zzzqqq');
      await tester.pumpAndSettle();
      expect(find.textContaining('Ничего не найдено'), findsOneWidget);
      // Escape closes it, Ctrl+K opens it again.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(DocSearchPanel), findsNothing);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.byType(DocSearchPanel), findsOneWidget);
      // The field has the focus already: typing needs no click.
      expect(tester.testTextInput.isVisible, isTrue);
      await tester.enterText(find.byType(TextField), 'установка docker');
      await tester.pumpAndSettle();
      final row = find.bySemanticsLabel(RegExp('Установка Docker'));
      expect(row, findsWidgets);
      // Down and Up move the lit hit, Enter opens it.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await settle(tester);
      expect(find.byType(DocSearchPanel), findsNothing);
      expect(find.bySemanticsLabel('Назад'), findsOneWidget);
      expect(find.text('Установка Docker и Compose'), findsWidgets);
      String? doc() => GoRouterState.of(
        tester.element(find.byType(DocsPage)),
      ).uri.queryParameters['doc'];
      expect(doc(), isNotNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Library: Ctrl+F finds in the open article', (tester) async {
      await openDocs(tester, const Size(1200, 800));
      expect(find.byType(DocFindBar), findsNothing);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(find.byType(DocFindBar), findsOneWidget);
      // The field has the focus already: typing needs no click.
      expect(tester.testTextInput.isVisible, isTrue);
      tester.testTextInput.enterText('backend');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'backend');
      await tester.pumpAndSettle();
      final counter = find.textContaining(RegExp(r'^\d+/\d+$'));
      expect(counter, findsOneWidget);
      String shown() => (tester.widget(counter) as Text).data!;
      expect(shown(), startsWith('1/'));
      final total = int.parse(shown().split('/').last);
      expect(total, greaterThan(1));
      // Enter steps to the next match, Shift+Enter to the one before.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(shown(), '2/$total');
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.pumpAndSettle();
      expect(shown(), '1/$total');
      await tester.enterText(find.byType(TextField), 'zzzqqq');
      await tester.pumpAndSettle();
      expect(find.text('0/0'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.byType(DocFindBar), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Library: search on a phone opens from the bar', (
      tester,
    ) async {
      await openDocs(tester, const Size(420, 800));
      await tester.tap(find.bySemanticsLabel('Поиск'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'docker');
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp('Docker')).first);
      await settle(tester);
      expect(find.byType(DocSearchPanel), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Library: the address follows the open article', (
      tester,
    ) async {
      await start(tester);
      await tester.tap(find.bySemanticsLabel('Библиотека'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Документация'));
      await settle(tester);
      String? doc() => GoRouterState.of(
        tester.element(find.byType(DocsPage)),
      ).uri.queryParameters['doc'];
      await tester.tap(find.text('Docker'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Установка Docker и Compose'));
      await settle(tester);
      expect(doc(), 'deployment/docker/install-docker');
      // Back keeps the screen and moves the address with it.
      await tester.tap(find.bySemanticsLabel('Назад'));
      await settle(tester);
      expect(doc(), isNot('deployment/docker/install-docker'));
      expect(find.byType(DocsPage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Library: the title and the headings copy their address', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await start(tester);
      await tester.tap(find.bySemanticsLabel('Библиотека'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Документация'));
      await settle(tester);
      await tester.tap(find.text('Конфигурации Nginx'));
      await settle(tester);
      final marks = find.byType(CopyLinkMark);
      // The first mark is the one of the title, the rest are headings.
      expect(marks.evaluate().length, greaterThan(1));
      await tester.tap(marks.first);
      await tester.pump();
      expect(copied, contains('/library/docs?doc='));
      expect(copied, isNot(contains('anchor')));
      await tester.pump(const Duration(seconds: 1));
      await tester.ensureVisible(marks.at(1));
      await tester.pump();
      await tester.tap(marks.at(1));
      await tester.pump();
      expect(copied, contains('anchor='));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Library: on a phone the text has room and rows are big', (
      tester,
    ) async {
      await start(tester);
      tester.view.physicalSize = const Size(420, 800);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Библиотека'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Документация'));
      await settle(tester);
      final inText = find.descendant(
        of: find.byType(MdView),
        matching: find.byType(RichText),
      );
      expect(tester.getTopLeft(inText.first).dx, greaterThanOrEqualTo(16));
      expect(tester.getTopRight(inText.first).dx, lessThanOrEqualTo(420 - 16));
      await tester.tap(find.bySemanticsLabel('Разделы'));
      await tester.pumpAndSettle();
      final row = tester.widget<Text>(find.text('Конфигурации Nginx'));
      expect(row.style!.fontSize, greaterThanOrEqualTo(15));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Library: a link in an article leads to its row', (
      tester,
    ) async {
      await start(tester);
      await tester.tap(find.bySemanticsLabel('Библиотека'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Документация'));
      await settle(tester);
      // "Grafana Мониторинг" links to Prometheus, which sits in a folded
      // group: following the link unfolds it.
      await tester.tap(find.text('Мониторинг'));
      await settle(tester);
      expect(find.text('Зависимости'), findsOneWidget);
      expect(find.text('PostgreSQL'), findsNothing);
      TapGestureRecognizer? link;
      void walk(InlineSpan span) {
        if (span is TextSpan) {
          if (span.recognizer is TapGestureRecognizer &&
              span.toPlainText() == 'Prometheus') {
            link = span.recognizer as TapGestureRecognizer;
          }
          span.children?.forEach(walk);
        }
      }

      for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
        walk(rich.text);
      }
      link!.onTap!();
      await tester.pumpAndSettle();
      expect(find.text('PostgreSQL'), findsOneWidget);
      expect(find.bySemanticsLabel('Назад'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Library: on a narrow screen the sidebar opens over the text', (
      tester,
    ) async {
      await start(tester);
      tester.view.physicalSize = const Size(500, 800);
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Библиотека'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Документация'));
      await settle(tester);
      expect(find.text('Конфигурации Nginx'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Разделы'));
      await tester.pumpAndSettle();
      expect(find.text('Конфигурации Nginx'), findsOneWidget);
      await tester.tap(find.text('Мониторинг'));
      await settle(tester);
      // A pick closes the sidebar again.
      expect(find.text('Конфигурации Nginx'), findsNothing);
      expect(find.bySemanticsLabel('Назад'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Library: about has the version, platforms and social links', (
      tester,
    ) async {
      final launches = <MethodCall>[];
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        launches.add(call);
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await start(tester);
      await tester.tap(find.bySemanticsLabel('Библиотека'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('О приложении'));
      await tester.pumpAndSettle();
      expect(find.byType(LibraryModal), findsNothing);
      expect(find.text(clientVersion), findsOneWidget);
      expect(find.bySemanticsLabel('Нативные приложения'), findsOneWidget);
      expect(find.bySemanticsLabel('Соцсети'), findsOneWidget);
      expect(find.bySemanticsLabel('Поддержать проект'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Нативные приложения'));
      await tester.pumpAndSettle();
      for (final label in ['Android', 'iOS', 'Linux', 'macOS', 'Windows']) {
        final cell = tester.widget<Semantics>(find.bySemanticsLabel(label));
        expect(cell.properties.enabled, isFalse, reason: label);
      }
      await tester.tap(find.bySemanticsLabel('Назад'));
      await tester.pumpAndSettle();

      await tester.tap(find.bySemanticsLabel('Соцсети'));
      await tester.pumpAndSettle();
      const urls = {
        'GitLab': 'https://git.pepemoss.com/pepe/pepeunit/pepeunit',
        'GitHub': 'https://github.com/w7a8n1y4a/pepeunit',
        'Discord': 'https://discord.gg/bTAF2mxzuN',
        'Telegram': 'https://t.me/pepeunit',
        'YouTube': 'https://www.youtube.com/@pepeunit',
      };
      for (final link in urls.entries) {
        await tester.tap(find.bySemanticsLabel(link.key));
        await tester.pump();
      }
      expect([
        for (final call in launches) call.arguments['url'],
      ], urls.values.toList());
      await tester.tap(find.bySemanticsLabel('Назад'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Соцсети'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'Library: support copies addresses, shows rules and saves CSV',
      (tester) async {
        const bitcoin = 'bc1q537kletr80tg9s3cc47920cd5qcef0dwly08qr';
        const ethereum = '0xF7BF1e2C10c562679A88DB8DC73b67cc8469Ca19';
        final files = MemoryKeyFilePort();
        late http.Request reportRequest;
        final client = MockClient((request) async {
          reportRequest = request;
          return http.Response.bytes([0, 1, 2], 200);
        });
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String?;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await start(tester, files: files, client: client);
        await tester.tap(find.bySemanticsLabel('Библиотека'));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('О приложении'));
        await tester.pumpAndSettle();
        await tester.tap(find.bySemanticsLabel('Поддержать проект'));
        await tester.pumpAndSettle();

        expect(find.text(bitcoin), findsOneWidget);
        expect(find.text(ethereum), findsOneWidget);
        expect(find.text('.csv'), findsOneWidget);
        await tester.tap(find.bySemanticsLabel('Скопировать').first);
        await tester.pump();
        expect(copied, bitcoin);
        await tester.tap(find.bySemanticsLabel('Скопировать').last);
        await tester.pump();
        expect(copied, ethereum);

        await tester.tap(find.bySemanticsLabel('Правила расходов'));
        await tester.pumpAndSettle();
        expect(find.byType(LibraryModal), findsOneWidget);
        expect(
          find.textContaining(
            'Монеты будут расходоваться на улучшение проекта',
          ),
          findsOneWidget,
        );
        await tester.tap(find.bySemanticsLabel('Закрыть'));
        await tester.pumpAndSettle();
        expect(find.byType(LibraryModal), findsNothing);

        await tester.tap(find.bySemanticsLabel('Скачать Отчётность'));
        await tester.pumpAndSettle();
        expect(
          reportRequest.url.toString(),
          'https://minio.pepemoss.com/public-data/csv/detail.csv',
        );
        expect(files.savedName, 'detail.csv');
        expect(files.saved, [0, 1, 2]);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('Library: tools hold the generator', (
      tester,
    ) async {
      await start(tester);
      await tester.tap(find.bySemanticsLabel('Библиотека'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Инструменты'));
      await tester.pumpAndSettle();
      for (final label in ['Генератор README', 'Назад']) {
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }
      expect(find.bySemanticsLabel('Дерево 6 путей'), findsNothing);
      expect(find.bySemanticsLabel('Поиск пути'), findsNothing);
      // Without a sign-in the generator says so and opens no file dialog.
      await tester.tap(find.bySemanticsLabel('Генератор README'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Ошибка'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Назад'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Инструменты'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Library: the presentation cell opens an empty panel', (
      tester,
    ) async {
      await start(tester);
      await tester.tap(find.bySemanticsLabel('Библиотека'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Презентация'));
      await settle(tester);
      expect(find.byType(LibraryModal), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Закрыть'));
      await settle(tester);
      expect(find.byType(LibraryModal), findsNothing);
      expect(find.bySemanticsLabel('Презентация'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a tip opens on a click of the wheel, and not on a tap', (
      tester,
    ) async {
      await start(tester, withTips: tips);
      final cell = tester.getCenter(find.bySemanticsLabel('Библиотека'));
      final middle = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kMiddleMouseButton,
      );
      await middle.down(cell);
      await middle.up();
      await settle(tester);
      expect(find.byType(TipModal), findsOneWidget);
      expect(find.textContaining('Подсказка библиотеки'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Закрыть'));
      await settle(tester);
      expect(find.byType(TipModal), findsNothing);
      // Still the home screen: the click did not open the section.
      expect(find.bySemanticsLabel('Аккаунт'), findsOneWidget);
    });

    testWidgets('a tip is a small card with no source switch', (tester) async {
      await start(tester, withTips: tips);
      await tester.longPress(find.bySemanticsLabel('Библиотека'));
      await settle(tester);
      final card = tester.getSize(find.byType(TipModal));
      final frame = tester.getSize(find.descendant(
        of: find.byType(TipModal),
        matching: find.byType(BevelFrame),
      ));
      final extent = tester
          .state<ScrollableState>(find.descendant(
            of: find.byType(TipModal),
            matching: find.byType(Scrollable),
          ).first)
          .position
          .maxScrollExtent;
      // The card is as tall as the text: nothing to scroll.
      expect(extent, 0);
      expect(frame.height, lessThan(card.height * 0.6));
      expect(frame.width, lessThan(card.width));
      expect(find.bySemanticsLabel('Исходник'), findsNothing);
      expect(find.bySemanticsLabel('Рендер'), findsNothing);
      expect(find.bySemanticsLabel('Скопировать'), findsNothing);
      expect(find.bySemanticsLabel('Закрыть'), findsOneWidget);
    });

    testWidgets('a cursor resting on a cell opens nothing', (tester) async {
      await start(tester, withTips: tips);
      final cell = tester.getCenter(find.bySemanticsLabel('Сеть'));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(cell);
      await tester.pump(const Duration(seconds: 1));
      await mouse.moveTo(cell + const Offset(2, 2));
      await tester.pump(const Duration(seconds: 3));
      await settle(tester);
      expect(find.byType(TipModal), findsNothing);
      await mouse.removePointer();
    });

    testWidgets('a long press of the mouse opens the tip, not the cell', (
      tester,
    ) async {
      await start(tester, withTips: tips);
      final cell = tester.getCenter(find.bySemanticsLabel('Библиотека'));
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.down(cell);
      await tester.pump(const Duration(seconds: 1));
      await mouse.up();
      await settle(tester);
      expect(find.byType(TipModal), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Закрыть'));
      await settle(tester);
      expect(find.bySemanticsLabel('Аккаунт'), findsOneWidget);
    });

    testWidgets('a long touch opens the tip and does not open the cell', (
      tester,
    ) async {
      await start(tester, withTips: tips);
      await tester.longPress(find.bySemanticsLabel('Библиотека'));
      await settle(tester);
      expect(find.byType(TipModal), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Закрыть'));
      await settle(tester);
      expect(find.bySemanticsLabel('Аккаунт'), findsOneWidget);
    });

    testWidgets('the shared tip of Back opens on the menu', (tester) async {
      await start(tester, withTips: tips);
      await tester.tap(find.bySemanticsLabel('Библиотека'));
      await tester.pumpAndSettle();
      // The menu cells have tips, Back has the shared one.
      final back = tester.getCenter(find.bySemanticsLabel('Назад'));
      final middle = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kMiddleMouseButton,
      );
      await middle.down(back);
      await middle.up();
      await settle(tester);
      expect(find.textContaining('Подсказка возврата'), findsOneWidget);
    });

    testWidgets('a tip is found for a screen that was opened by a push', (
      tester,
    ) async {
      await start(
        tester,
        withTips: {
          ...tips,
          'tooltip/ru/library.docs.md': 'Подсказка документации.',
          'tooltip/ru/library.about.version.md': 'Подсказка версии.',
        },
      );
      await tester.tap(find.bySemanticsLabel('Библиотека'));
      await tester.pumpAndSettle();
      await tester.longPress(find.bySemanticsLabel('Документация'));
      await settle(tester);
      expect(find.textContaining('Подсказка документации'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Закрыть'));
      await settle(tester);
      // One level deeper, still by push.
      await tester.tap(find.bySemanticsLabel('О приложении'));
      await tester.pumpAndSettle();
      await tester.longPress(find.bySemanticsLabel('Версия клиента'));
      await settle(tester);
      expect(find.textContaining('Подсказка версии'), findsOneWidget);
    });

    testWidgets('a cell with no tip does nothing on a click of the wheel', (
      tester,
    ) async {
      await start(tester, withTips: const {});
      final cell = tester.getCenter(find.bySemanticsLabel('Библиотека'));
      final middle = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kMiddleMouseButton,
      );
      await middle.down(cell);
      await middle.up();
      await settle(tester);
      expect(find.byType(TipModal), findsNothing);
    });
  });

  group('library modal', () {
    Future<AppModel> open(
      WidgetTester tester, {
      required String source,
      DocsTree? docs,
      String? path,
    }) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final model = AppModel(store: MemoryVaultStore());
      await model.load();
      await tester.pumpWidget(
        AppScope(
          model: model,
          child: MaterialApp(
            home: Scaffold(
              body: LibraryModal(
                title: 'Статья',
                color: Colors.green,
                source: source,
                docs: docs,
                path: path,
                onClose: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return model;
    }

    testWidgets('render and source switch, and the choice is kept', (
      tester,
    ) async {
      final model = await open(
        tester,
        source: '# Заголовок\n\nТекст **жирный**.\n',
      );
      expect(find.byType(MdView), findsOneWidget);
      // The modal frame has cut corners.
      expect(find.byType(BevelFrame), findsWidgets);
      expect(model.vault.libraryRaw, isFalse);
      await tester.tap(find.text('Исходник'));
      await tester.pumpAndSettle();
      expect(find.byType(MdView), findsNothing);
      expect(model.vault.libraryRaw, isTrue);
      // Raw is numbered code: the source line is there with its number.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('# Заголовок'), findsOneWidget);
      await tester.tap(find.text('Рендер'));
      await tester.pumpAndSettle();
      expect(find.byType(MdView), findsOneWidget);
      expect(model.vault.libraryRaw, isFalse);
    });

    testWidgets('a link to an article opens it in place, Back returns', (
      tester,
    ) async {
      final tree = _tree({
        'docs/ru/a/one.md':
            '# Первая\n\nЕщё [вторая](/a/two) и [там](two#часть).\n',
        'docs/ru/a/two.md': '# Вторая\n\n## Часть\n\nКонец\n',
      });
      await open(
        tester,
        source: '# Старт\n\n[первая](/a/one) и [определение](/missing#unit)\n',
        docs: tree,
      );
      TapGestureRecognizer? linkOf(String label) {
        TapGestureRecognizer? found;
        void walk(InlineSpan span) {
          if (span is TextSpan) {
            if (span.recognizer is TapGestureRecognizer &&
                span.toPlainText() == label) {
              found = span.recognizer as TapGestureRecognizer;
            }
            span.children?.forEach(walk);
          }
        }

        for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
          walk(rich.text);
        }
        return found;
      }

      expect(linkOf('определение'), isNull, reason: 'no page, so a plain term');
      linkOf('первая')!.onTap!();
      await tester.pumpAndSettle();
      expect(find.text('Первая'), findsWidgets);
      expect(find.text('Назад'), findsOneWidget);
      linkOf('вторая')!.onTap!();
      await tester.pumpAndSettle();
      expect(find.text('Конец'), findsOneWidget);
      await tester.tap(find.text('Назад'));
      await tester.pumpAndSettle();
      expect(find.text('Ещё '), findsNothing);
      await tester.tap(find.text('Назад'));
      await tester.pumpAndSettle();
      expect(find.text('Назад'), findsNothing);
      expect(find.text('Старт'), findsWidgets);
    });

    testWidgets('the first heading is the title and is drawn once', (
      tester,
    ) async {
      await open(tester, source: '# Из текста\n\nАбзац.\n\n## Раздел\n');
      // The frame shows the title of the text, not the one it was given, and
      // the text does not repeat it.
      expect(find.text('Из текста'), findsOneWidget);
      expect(find.text('Статья'), findsNothing);
      expect(find.text('Абзац.'), findsOneWidget);
      expect(find.text('Раздел'), findsOneWidget);
    });

    testWidgets('a text with no heading keeps the given title', (tester) async {
      await open(tester, source: 'Просто абзац.\n');
      expect(find.text('Статья'), findsOneWidget);
    });

    testWidgets('a link finds a heading the old site spelled with и for й', (
      tester,
    ) async {
      final filler = [for (var i = 0; i < 60; i++) 'Строка $i\n'].join('\n');
      final tree = _tree({
        'docs/ru/a/two.md':
            '# Вторая\n\n$filler\n## Файловой структуры\n\n$filler\n',
      });
      await open(
        tester,
        source: '# Старт\n\n[туда](/a/two#фаиловои-структуры)\n',
        docs: tree,
      );
      TapGestureRecognizer? found;
      void walk(InlineSpan span) {
        if (span is TextSpan) {
          if (span.recognizer is TapGestureRecognizer &&
              span.toPlainText() == 'туда') {
            found = span.recognizer as TapGestureRecognizer;
          }
          span.children?.forEach(walk);
        }
      }

      for (final rich in tester.widgetList<RichText>(find.byType(RichText))) {
        walk(rich.text);
      }
      found!.onTap!();
      await tester.pumpAndSettle();
      // The text is longer than the view; the section is brought to its top.
      expect(
        tester.getTopLeft(find.text('Файловой структуры')).dy,
        lessThan(300),
      );
    });

    testWidgets('a tap on a link to a heading of the same text scrolls to it', (
      tester,
    ) async {
      final filler = [for (var i = 0; i < 60; i++) 'Строка $i\n'].join('\n');
      final source =
          '# Статья\n\n:::tip\n1. [Один](/a/one#первыи-раздел)\n:::\n\n'
          '$filler\n## Первый раздел\n\n$filler\n';
      final tree = _tree({'docs/ru/a/one.md': source});
      await open(tester, source: source, docs: tree, path: 'a/one');
      // The link is the first word of its line, so its corner is on it.
      await tester.tapAt(
        tester.getTopLeft(find.text('Один', findRichText: true)) +
            const Offset(6, 6),
      );
      await tester.pumpAndSettle();
      // Same text, so no second page and no Back; the heading is at the top.
      expect(find.text('Назад'), findsNothing);
      expect(tester.getTopLeft(find.text('Первый раздел')).dy, lessThan(300));
    });

    testWidgets('a find counts the matches and scrolls to the current', (
      tester,
    ) async {
      final filler = [for (var i = 0; i < 80; i++) 'Строка $i\n'].join('\n');
      var count = -1;
      final doc = parseMarkdown('$filler\n## Конец\n\nредкое слово и Редкое.\n');
      Widget view(MdFind? find) => MaterialApp(
        home: Scaffold(
          body: MdView(
            doc: doc,
            font: 16,
            accent: const Color(0xFF00BCD4),
            canOpen: (_) => false,
            onOpen: (_) {},
            find: find,
            onFound: (n) => count = n,
          ),
        ),
      );
      await tester.pumpWidget(view(null));
      await tester.pumpAndSettle();
      expect(count, 0);
      expect(find.textContaining('редкое', findRichText: true), findsNothing);
      // Two matches at the very end: the view comes down to the first.
      await tester.pumpWidget(view(const MdFind('редкое', 0)));
      await tester.pumpAndSettle();
      expect(count, 2);
      expect(find.textContaining('слово', findRichText: true), findsOneWidget);
      expect(tester.takeException(), isNull);
      // No match, no count.
      await tester.pumpWidget(view(const MdFind('нету', 0)));
      await tester.pumpAndSettle();
      expect(count, 0);
    });

    testWidgets('a long text has no contents word', (tester) async {
      final filler = [for (var i = 0; i < 60; i++) 'Строка $i\n'].join('\n');
      await open(
        tester,
        source: '# Один\n\n$filler\n## Два\n\n$filler\n## Три\n\nхвост\n',
      );
      expect(find.text('Оглавление'), findsNothing);
    });

    testWidgets('a table wider than the view scrolls sideways', (tester) async {
      final cells = List.filled(14, 'очень длинное содержимое ячейки');
      final row = cells.join(' | ');
      await open(
        tester,
        source:
            '${List.generate(14, (i) => 'К$i').join(' | ')}\n'
            '${List.filled(14, '--').join(' | ')}\n$row\n',
      );
      final sideways = find.descendant(
        of: find.byType(MdView),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is SingleChildScrollView &&
              widget.scrollDirection == Axis.horizontal,
        ),
      );
      expect(sideways, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('code blocks are numbered and a video is a preview', (
      tester,
    ) async {
      MdVideo? opened;
      final before = videoOpener;
      videoOpener = (video) => opened = video;
      addTearDown(() => videoOpener = before);
      await open(
        tester,
        source:
            '```python\nprint(1)\nprint(2)\n```\n\n'
            'https://www.youtube.com/watch?v=r1CpkXD_MJY\n',
      );
      expect(find.text('python'), findsOneWidget);
      // The numbers are one text, a line each.
      expect(find.text('1\n2'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Смотреть видео'));
      expect(opened?.id, 'r1CpkXD_MJY');
    });
  });
}
