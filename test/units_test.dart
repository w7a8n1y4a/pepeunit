import 'dart:convert';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/api/pepeunit_api.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/features/units/commit_pick_page.dart';
import 'package:pepeunit_client/features/units/unit_create_page.dart';
import 'package:pepeunit_client/features/units/unit_panels.dart';
import 'package:pepeunit_client/features/units/units_menu_page.dart';
import 'package:pepeunit_client/features/units/units_page.dart';
import 'package:pepeunit_client/hive/hex_order.dart';
import 'package:pepeunit_client/instances/instance.dart';
import 'package:pepeunit_client/units/unit.dart';
import 'package:pepeunit_client/units/unit_read.dart';
import 'package:pepeunit_client/units/unit_view.dart';

void main() {
  test('own units stay on and the last filter cannot be cleared', () {
    final query = UnitQuery();
    expect(query.owner, 'mine');
    expect(query.visibilityFilter, isNull);
    expect(query.autoOnly, isNull);
    expect(query.setOwner('mine'), isFalse);
    expect(query.setOwner('all'), isTrue);
    expect(query.owner, 'all');
    expect(query.toggleVisibility('Public'), isTrue);
    expect(query.toggleVisibility('Internal'), isTrue);
    expect(query.toggleVisibility('Private'), isFalse);
    expect(query.visibility, {'Private'});
    expect(query.toggleAuto('on'), isTrue);
    expect(query.toggleAuto('off'), isFalse);
    expect(query.autoOnly, isFalse);
    expect(unitNameOk('ab'), isFalse);
    expect(unitNameOk('room.1'), isTrue);
    expect(unitNameOk('bad name'), isFalse);
    expect(headPageLimit(searchScaleTick, head: unitsHead), 9);
    expect(unitMenuIds(owned: true), [
      'card',
      'info',
      'settings',
      'operate',
      'nodes',
      'env',
    ]);
    expect(unitMenuIds(owned: false), ['card', 'info', 'nodes']);
    expect(unitMenuIds(owned: true), isNot(contains('access')));
    expect(
      ioMenuIds(owned: true, input: true, private: true, datapipe: false),
      isNot(contains('pipe')),
    );
    expect(
      ioMenuIds(owned: false, input: true, private: false, datapipe: true),
      ['card', 'value', 'links'],
    );
  });

  test('the node menu has a value for both directions', () {
    expect(
      ioMenuIds(owned: true, input: false, private: true, datapipe: true),
      ['card', 'value', 'settings', 'pipe', 'access'],
    );
    expect(
      ioMenuIds(owned: true, input: true, private: false, datapipe: true),
      ['card', 'value', 'settings', 'pipe', 'links'],
    );
    expect(
      ioMenuIds(owned: false, input: false, private: true, datapipe: true),
      ['card', 'value'],
    );
  });

  test('the node value keeps text and indents only JSON', () {
    expect(ioValueShown(null), '');
    expect(ioValueShown('SGVsbG8gd29ybGQ='), 'SGVsbG8gd29ybGQ=');
    expect(ioValueShown('1e3'), '1e3');
    expect(
      ioValueShown('{"a":1,"b":[2]}'),
      '{\n    "a": 1,\n    "b": [\n        2\n    ]\n}',
    );
    expect(ioValueShown('{broken'), '{broken');
    expect(ioValueGlance(null), '-');
    expect(ioValueGlance('  \n '), '-');
    expect(ioValueGlance('a\n  b'), 'a b');
    expect(ioValueGlance('x' * 60), '${'x' * 48}…');
  });

  test('the units menu is Back in the center, add, search and groups', () {
    final board = unitsMenuBoard();
    expect(
      [for (final slot in board.slots) slot.id],
      ['back', 'add', 'search', 'groups'],
    );
    expect((board.slots.first.q, board.slots.first.r), (0, 0));
    expect(board.canZoomIn, isFalse);
  });

  testWidgets('search opens on own units and asks for the creator', (
    tester,
  ) async {
    final api = _UnitsApi();
    final model = AppModel(store: MemoryVaultStore(), api: (_) => api);
    await model.load();
    model.vault.instances.add(
      InstanceRecord(
        url: defaultInstanceUrl,
        token: 't',
        role: 'User',
        userUuid: 'me',
        active: true,
      ),
    );
    await tester.pumpWidget(
      AppScope(
        model: model,
        child: const MaterialApp(home: UnitsPage(scope: searchScaleTick)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Свои'), findsOneWidget);
    expect(api.creator, 'me');
    expect(find.bySemanticsLabel('pump'), findsOneWidget);
  });

  test('storage, env syntax and the info glance', () {
    expect(presentStorage('{"a":1}'), '{\n    "a": 1\n}');
    final encoded = base64Encode(utf8.encode('{"alpha":1}'));
    expect(presentStorage(encoded), '{\n    "alpha": 1\n}');
    final note = base64Encode(utf8.encode('hello from pepeunit'));
    expect(presentStorage(note), 'hello from pepeunit');
    expect(presentStorage('plain text'), 'plain text');

    final broken = envIssue('ru', '{\n  "DELAY":\n}');
    expect(broken!.line, 2);
    expect(broken.text, contains('DELAY'));
    final later = envIssue('ru', '{\n    "a": 1,\n    "b": 2\n    "c": 3\n}');
    expect(later!.line, 4);
    expect(envIssue('ru', '{\n    "name": "ab')!.line, 2);
    expect(envIssue('ru', '{\n    "DELAY": 1\n}'), isNull);

    expect(unitCommandLabel('ru', 'EnvUpdate'), 'Обновить окружение');
    expect(unitCommandLabel('ru', 'LogSync'), 'Синхронизировать логи');
    expect(deviceTimeEdge(595925249, 'ru'), '6д 21ч');

    const unit = Unit(
      uuid: 'u',
      iconUuid: '',
      visibility: 'Private',
      name: 'pump',
      created: '',
      auto: true,
      compilable: false,
      tagsOnly: false,
      branch: 'main',
      updated: '',
      creatorUuid: 'me',
      repoUuid: 'r',
      state: UnitLive(
        millis: 595925249,
        memFree: 12368,
        memAlloc: 25648,
        freq: 80000000,
        statvfs: [4096, 4096, 763, 716, 716, 0, 0, 0, 0, 255],
      ),
    );
    expect(unitGlance(unit, 'ru'), ['RAM 12 КБ', 'Flash 2.8 МБ', '80 МГц']);
  });

  testWidgets('environment line numbers cover the closing brace', (
    tester,
  ) async {
    final font = FontLoader('JetBrains Mono')
      ..addFont(rootBundle.load('assets/fonts/JetBrainsMono-Regular.ttf'));
    await font.load();
    tester.view.physicalSize = const Size(720, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final api = _UnitsApi()
      ..env = {
        for (var i = 0; i < 30; i++) 'KEY_$i': i == 4 ? 'x' * 180 : 'v$i',
      };
    final model = AppModel(store: MemoryVaultStore(), api: (_) => api);
    await model.load();
    model.vault.instances.add(
      InstanceRecord(
        url: defaultInstanceUrl,
        token: 't',
        role: 'User',
        userUuid: 'me',
        active: true,
      ),
    );
    await tester.pumpWidget(
      AppScope(
        model: model,
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.25)),
            child: child!,
          ),
          home: UnitEnvPanel(uuid: 'u1', onClose: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final scrollable = find.descendant(
      of: find.byType(TextField),
      matching: find.byType(Scrollable),
    );
    final position = tester.state<ScrollableState>(scrollable);
    if (position.position.maxScrollExtent > 0) {
      position.position.jumpTo(position.position.maxScrollExtent);
      await tester.pump();
    }
    final field = tester.widget<TextField>(find.byType(TextField));
    final text = field.controller!.text;
    final lines = text.split('\n');
    RenderEditable? editable;
    void seek(RenderObject object) {
      if (object is RenderEditable) editable = object;
      object.visitChildren(seek);
    }

    seek(tester.renderObject(find.byType(TextField)));
    final origin = editable!.localToGlobal(Offset.zero);
    final caret = editable!.getLocalRectForCaret(
      TextPosition(offset: text.lastIndexOf('}')),
    );
    final number = tester.renderObject<RenderBox>(find.text('${lines.length}'));
    final top = number.localToGlobal(Offset.zero);
    final editorBottom = origin.dy + editable!.size.height;
    expect(top.dy + number.size.height, lessThanOrEqualTo(editorBottom + 0.5));
    expect(
      (top.dy - (origin.dy + caret.top)).abs(),
      lessThan(number.size.height / 2),
    );
  });

  testWidgets('environment opens as json', (tester) async {
    final api = _UnitsApi();
    final model = AppModel(store: MemoryVaultStore(), api: (_) => api);
    await model.load();
    model.vault.instances.add(
      InstanceRecord(
        url: defaultInstanceUrl,
        token: 't',
        role: 'User',
        userUuid: 'me',
        active: true,
      ),
    );
    await tester.pumpWidget(
      AppScope(
        model: model,
        child: MaterialApp(
          home: UnitEnvPanel(uuid: 'u1', onClose: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('DELAY_PUB_MSG'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('push writes the open screen into the location', (tester) async {
    final previous = GoRouter.optionURLReflectsImperativeAPIs;
    GoRouter.optionURLReflectsImperativeAPIs = true;
    addTearDown(() => GoRouter.optionURLReflectsImperativeAPIs = previous);
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const Text('home')),
        GoRoute(
          path: '/units/:uuid',
          builder: (context, state) => Text(state.pathParameters['uuid']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    router.push('/units/abc');
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/units/abc');
    expect(find.text('abc'), findsOneWidget);
  });

  testWidgets('create unit opens the form and waits for a repository', (
    tester,
  ) async {
    final model = AppModel(store: MemoryVaultStore(), api: (_) => _UnitsApi());
    await model.load();
    await tester.pumpWidget(
      AppScope(
        model: model,
        child: const MaterialApp(home: UnitsMenuPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Создать аппарат'), findsOneWidget);
    expect(find.bySemanticsLabel('Добавить'), findsNothing);

    await tester.pumpWidget(
      AppScope(
        model: model,
        child: const MaterialApp(home: UnitCreatePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Выбрать репозиторий'), findsOneWidget);
    expect(find.bySemanticsLabel('Имя'), findsOneWidget);
    expect(find.bySemanticsLabel('Видимость'), findsOneWidget);
    expect(find.bySemanticsLabel('Ветка'), findsOneWidget);
    expect(find.bySemanticsLabel('Обновления'), findsOneWidget);
    expect(find.bySemanticsLabel('Создать'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Создать'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Ветка'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Обновления'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Обновления')).value,
      'Интерп',
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Выбрать репозиторий'))
          .flagsCollection
          .isEnabled,
      Tristate.isTrue,
    );
    final cell = tester.getRect(find.byKey(const ValueKey('visibility')));
    final words = ['Публичный', 'Внутренний', 'Приватный'];
    var union = tester.getRect(find.bySemanticsLabel(words.first));
    for (final word in words.skip(1)) {
      union = union.expandToInclude(
        tester.getRect(find.bySemanticsLabel(word)),
      );
    }
    expect((union.center - cell.center).distance, lessThan(cell.width * 0.12));
    expect(union.left, greaterThan(cell.left + cell.width * 0.08));
    expect(union.right, lessThan(cell.right - cell.width * 0.08));
    expect(tester.takeException(), isNull);
  });

  testWidgets('updates menu follows the compilable and auto flags', (
    tester,
  ) async {
    final model = AppModel(store: MemoryVaultStore(), api: (_) => _UnitsApi());
    await model.load();
    Future<void> show(UnitUpdatesPage page) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        AppScope(
          model: model,
          child: MaterialApp(home: page),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show(
      const UnitUpdatesPage(
        repoUuid: 'r1',
        branch: 'main',
        compilable: false,
        auto: true,
        tagsOnly: true,
      ),
    );
    expect(find.bySemanticsLabel('Интерпретируемый'), findsOneWidget);
    expect(find.bySemanticsLabel('Автообновление'), findsOneWidget);
    expect(find.bySemanticsLabel('Только теги'), findsOneWidget);
    expect(find.bySemanticsLabel('Коммит'), findsNothing);
    expect(find.bySemanticsLabel('Платформа'), findsNothing);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Только теги'))
          .flagsCollection
          .isEnabled,
      Tristate.isTrue,
    );
    await tester.tap(find.bySemanticsLabel('Интерпретируемый'));
    await tester.pump();
    expect(find.bySemanticsLabel('Компилируемый'), findsOneWidget);
    expect(find.bySemanticsLabel('Платформа'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Последний тег'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    await tester.tap(find.bySemanticsLabel('Автообновление'));
    await tester.pump();
    expect(find.bySemanticsLabel('Руками'), findsOneWidget);
    expect(find.bySemanticsLabel('Коммит'), findsOneWidget);
    expect(find.bySemanticsLabel('Только теги'), findsNothing);

    await show(
      const UnitUpdatesPage(
        repoUuid: 'r1',
        branch: 'main',
        compilable: true,
        auto: true,
        tagsOnly: false,
      ),
    );
    expect(find.bySemanticsLabel('Компилируемый'), findsOneWidget);
    expect(find.bySemanticsLabel('Платформа'), findsOneWidget);
    expect(find.bySemanticsLabel('Коммит'), findsNothing);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Последний тег'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );

    await show(
      const UnitUpdatesPage(
        repoUuid: 'r1',
        branch: 'main',
        compilable: true,
        auto: false,
        tagsOnly: true,
        commit: 'abcdef1234567890',
        platform: 'esp32',
      ),
    );
    expect(find.bySemanticsLabel('Руками'), findsOneWidget);
    expect(find.bySemanticsLabel('Только теги'), findsNothing);
    expect(find.bySemanticsLabel('Коммит'), findsOneWidget);
    expect(find.bySemanticsLabel('Платформа'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Коммит')).value,
      'abcdef1',
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Платформа')).value,
      'esp32',
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('commit search asks by hash or tag and locks tags', (
    tester,
  ) async {
    final api = _CommitApi();
    final model = AppModel(store: MemoryVaultStore(), api: (_) => api);
    await model.load();
    model.vault.instances.add(
      InstanceRecord(
        url: defaultInstanceUrl,
        token: 't',
        role: 'User',
        userUuid: 'me',
        active: true,
      ),
    );
    await tester.pumpWidget(
      AppScope(
        model: model,
        child: const MaterialApp(
          home: CommitPickPage(
            repoUuid: 'r1',
            branch: 'main',
            compilable: false,
            scope: searchScaleTick,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(api.onlyTag, isFalse);
    expect(find.bySemanticsLabel('Все'), findsOneWidget);
    expect(find.bySemanticsLabel('Только теги'), findsOneWidget);
    expect(find.bySemanticsLabel('v1'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Только теги'));
    await tester.pumpAndSettle();
    expect(api.onlyTag, isTrue);
    await tester.enterText(find.byKey(const ValueKey('commit-search')), 'abc');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(api.search, 'abc');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      AppScope(
        model: model,
        child: const MaterialApp(
          home: CommitPickPage(
            repoUuid: 'r1',
            branch: 'main',
            compilable: true,
            scope: searchScaleTick,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(api.onlyTag, isTrue);
    expect(api.search, '');
    expect(find.bySemanticsLabel('Все'), findsNothing);
    expect(find.bySemanticsLabel('v1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _UnitsApi extends PepeunitApi {
  _UnitsApi() : super('https://devunit.pepeunit.com');

  String? creator;
  Map<String, Object?>? env;

  @override
  Future<Map<String, Object?>> unitEnv(String token, String uuid) async {
    return env ?? {'DELAY_PUB_MSG': 1};
  }

  @override
  Future<({int count, List<Unit> units})> units({
    required String token,
    required int offset,
    required int limit,
    String search = '',
    String order = 'asc',
    String? creatorUuid,
    List<String>? visibility,
    bool? auto,
    String? repoUuid,
    String? inputUuid,
    bool includeIos = false,
  }) async {
    creator = creatorUuid;
    return (
      count: 1,
      units: [
        const Unit(
          uuid: 'u1',
          iconUuid: '',
          visibility: 'Private',
          name: 'pump',
          created: '',
          auto: true,
          compilable: false,
          tagsOnly: false,
          branch: 'main',
          updated: '',
          creatorUuid: 'me',
          repoUuid: 'r1',
        ),
      ],
    );
  }
}

class _CommitApi extends PepeunitApi {
  _CommitApi() : super('https://devunit.pepeunit.com');

  bool? onlyTag;
  String search = '';

  @override
  Future<({int count, List<RepoCommit> commits})> branchCommits(
    String token,
    String uuid, {
    required String branch,
    bool onlyTag = false,
    String search = '',
    int offset = 0,
    int limit = 100,
  }) async {
    this.onlyTag = onlyTag;
    this.search = search;
    return (
      count: 1,
      commits: const [
        RepoCommit(commit: 'abcdef1234567890', summary: 'init', tag: 'v1'),
      ],
    );
  }
}
