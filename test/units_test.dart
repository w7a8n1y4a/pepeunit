import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/api/pepeunit_api.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/features/units/unit_forms.dart';
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
    expect([for (final slot in board.slots) slot.id], [
      'back',
      'add',
      'search',
      'groups',
    ]);
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
