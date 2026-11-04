import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/api/pepeunit_api.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/features/units/commit_pick_page.dart';
import 'package:pepeunit_client/features/units/unit_create_page.dart';
import 'package:pepeunit_client/features/units/unit_forms.dart';
import 'package:pepeunit_client/features/units/units_menu_page.dart';
import 'package:pepeunit_client/features/units/units_page.dart';
import 'package:pepeunit_client/hive/hex_order.dart';
import 'package:pepeunit_client/instances/instance.dart';
import 'package:pepeunit_client/units/unit.dart';
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
    expect(
      unitMenuIds(owned: true, private: true),
      containsAll(['settings', 'env', 'operate', 'access']),
    );
    expect(
      unitMenuIds(owned: false, private: true),
      isNot(contains('settings')),
    );
    expect(unitMenuIds(owned: true, private: false), isNot(contains('access')));
    expect(
      ioMenuIds(owned: true, input: true, private: true, datapipe: false),
      isNot(contains('pipe')),
    );
    expect(
      ioMenuIds(owned: false, input: true, private: false, datapipe: true),
      ['card', 'summary', 'value', 'links'],
    );
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

  testWidgets('environment fields sit inside the cell', (tester) async {
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
        child: const MaterialApp(home: UnitEnvPage(uuid: 'u1', scope: 1)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
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

  @override
  Future<Map<String, Object?>> unitEnv(String token, String uuid) async {
    return {'DELAY_PUB_MSG': 1};
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
