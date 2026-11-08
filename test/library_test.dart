import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pepeunit_client/account/key_file_port.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/client_version.dart';
import 'package:pepeunit_client/features/library/library_modal.dart';
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
  test('the tree is the folders: names and order come from _tree.json', () {
    final tree = _tree({
      'docs/ru/_tree.json': '{"b": "Бэ", "a": "Аз", "a/deep": "Глубоко"}',
      'docs/ru/a/one.md': '# Первая\n',
      'docs/ru/a/deep/two.md': '# Вторая\n',
      'docs/ru/b/three.md': '# Третья\n',
      'docs/ru/c/four.md': '# Четвёртая\n',
      'docs/ru/top.md': '# Верхняя\n',
      'docs/ru/a/no-title.md': 'просто текст',
    });
    // Listed folders stand in the file order, an unlisted one after them
    // under its own name.
    expect([for (final f in tree.root.folders) f.title], ['Бэ', 'Аз', 'c']);
    expect(tree.root.articles.single.title, 'Верхняя');
    final a = tree.folder('a')!;
    expect(a.folders.single.title, 'Глубоко');
    expect([for (final x in a.articles) x.title], ['no-title', 'Первая']);
    expect(tree.article('a/deep/two')!.title, 'Вторая');
  });

  test('another language falls back to Russian path by path', () {
    final files = {
      'docs/ru/a.md': '# Русская\n',
      'docs/ru/b.md': '# Вторая\n',
      'docs/en/a.md': '# English\n',
    };
    final tree = DocsTree.build(
      keys: files.keys,
      language: 'en',
      read: (key) => files[key]!,
    );
    expect(tree.article('a')!.title, 'English');
    expect(tree.article('b')!.title, 'Вторая');
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
      'assets/library/tips/ru/home.people.md': 'a',
      'assets/library/tips/ru/common.back.md': 'b',
    });
    expect(library.tipKey('ru', 'home', 'people'), endsWith('home.people.md'));
    expect(library.tipKey('ru', 'units', 'back'), endsWith('common.back.md'));
    expect(library.tipKey('en', 'home', 'people'), contains('/ru/'));
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
      expect(pubspec, isNot(contains('docs/ru/definitions.md')));
      expect(pubspec, isNot(contains('docs/ru/conception/')));
      expect(pubspec, isNot(contains('docs/ru/index.md')));
    });

    test('the tree has the three parts and no user guide', () async {
      final tree = await library.docs('ru');
      expect(
        [for (final f in tree.root.folders) f.title],
        ['Развёртывание', 'Разработчик Unit', 'Устройство Pepeunit'],
      );
      expect(tree.root.articles, isEmpty);
      expect(tree.article('definitions'), isNull);
      expect(tree.article('conception/overview'), isNull);
      expect(tree.article('development-pepeunit/maps'), isNotNull);
      for (final article in tree.articles) {
        expect(article.path, isNot(startsWith('user/')));
      }
    });

    test('the presentation has no slides yet', () async {
      expect(await library.presentation('ru'), isEmpty);
    });
  });

  group('screens', () {
    // Tips live in the bundle only when someone writes them, so the tip tests
    // bring their own.
    final tips = {
      'assets/library/tips/ru/home.library.md': 'Подсказка библиотеки.',
      'assets/library/tips/ru/common.back.md': 'Подсказка возврата.',
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

    testWidgets('Library: menu, documentation tree, an article', (
      tester,
    ) async {
      await start(tester);
      await tester.tap(find.bySemanticsLabel('Библиотека'));
      await tester.pumpAndSettle();
      for (final label in [
        'Презентация',
        'Документация',
        'Инструменты',
        'О приложении',
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }
      expect(find.text('.md'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Документация'));
      await settle(tester);
      expect(find.bySemanticsLabel('Концепция'), findsNothing);
      expect(find.bySemanticsLabel('Устройство Pepeunit'), findsOneWidget);
      expect(find.bySemanticsLabel('Поддержка проекта'), findsNothing);
      await tester.tap(find.bySemanticsLabel('Разработчик Unit'));
      await settle(tester);
      await tester.tap(find.bySemanticsLabel('Алгоритм создания Unit'));
      await settle(tester);
      expect(find.byType(LibraryModal), findsOneWidget);
      expect(find.byType(MdView), findsOneWidget);
      // Close returns to the folder.
      await tester.tap(find.bySemanticsLabel('Закрыть'));
      await settle(tester);
      expect(find.byType(LibraryModal), findsNothing);
      expect(find.bySemanticsLabel('Алгоритм создания Unit'), findsOneWidget);
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

    testWidgets('Library: tools hold the generator and two places', (
      tester,
    ) async {
      await start(tester);
      await tester.tap(find.bySemanticsLabel('Библиотека'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Инструменты'));
      await tester.pumpAndSettle();
      for (final label in [
        'Генератор README',
        'Дерево',
        'Поиск пути',
        'Назад',
      ]) {
        expect(find.bySemanticsLabel(label), findsOneWidget);
      }
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
      expect(find.byType(LibraryModal), findsOneWidget);
      expect(find.textContaining('Подсказка библиотеки'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Закрыть'));
      await settle(tester);
      expect(find.byType(LibraryModal), findsNothing);
      // Still the home screen: the click did not open the section.
      expect(find.bySemanticsLabel('Аккаунт'), findsOneWidget);
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
      expect(find.byType(LibraryModal), findsNothing);
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
      expect(find.byType(LibraryModal), findsOneWidget);
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
      expect(find.byType(LibraryModal), findsOneWidget);
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
      expect(find.byType(LibraryModal), findsNothing);
    });
  });

  group('library modal', () {
    Future<AppModel> open(
      WidgetTester tester, {
      required String source,
      DocsTree? docs,
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

    testWidgets('contents jumps to a heading', (tester) async {
      final filler = [for (var i = 0; i < 60; i++) 'Строка $i\n'].join('\n');
      await open(
        tester,
        source: '# Один\n\n$filler\n## Два\n\n$filler\n## Три\n\nхвост\n',
      );
      await tester.tap(find.text('Оглавление'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Три').last);
      await tester.pumpAndSettle();
      expect(find.text('хвост'), findsOneWidget);
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
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Смотреть видео'));
      expect(opened?.id, 'r1CpkXD_MJY');
    });
  });
}
