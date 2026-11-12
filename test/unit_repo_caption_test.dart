import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/features/units/unit_page.dart';
import 'package:pepeunit_client/features/registry/registry_chrome.dart';
import 'package:pepeunit_client/hive/hex_scene.dart';
import 'package:pepeunit_client/instances/instance.dart';
import 'package:pepeunit_client/registry/repo.dart';
import 'package:pepeunit_client/units/unit.dart';

void main() {
  testWidgets('repo has its own card and ignores a stale repo response', (
    tester,
  ) async {
    final model = _UnitRepoModel();
    await model.load();
    model.vault.instances.add(
      InstanceRecord(url: 'https://example.com', token: 't', active: true),
    );

    Future<void> open(String uuid) async {
      await tester.pumpWidget(
        AppScope(
          model: model,
          child: MaterialApp(home: UnitPage(uuid: uuid)),
        ),
      );
      await tester.pumpAndSettle();
    }

    HexSlot slot(String id) => tester
        .widget<HexScene>(find.byType(HexScene))
        .slots
        .firstWhere((slot) => slot.id == id);

    await open('u1');
    expect(slot('info').footer, '6д 21ч');
    expect(slot('repo').title, 'Репозиторий');
    await open('u2');
    const url = 'https://gitlab.com/pepe/units/long_repository_name.git';
    model.repos['r-u2']!.complete(
      RegistryRepo.fromJson({
        'uuid': 'r-u2',
        'repository_url': url,
        'is_public_repository': true,
        'child_unit_count': 3,
      }),
    );
    await tester.pumpAndSettle();
    expect(slot('repo').title, repoCaption(url));
    expect(slot('repo').color, registryColor);
    expect(slot('repo').footerLeft, pieceCount('ru', 3));
    expect(slot('repo').footer, repoAccessLabel('ru', true));
    expect(slot('info').footer, '6д 21ч');
    expect(slot('info').sideRight, isNull);

    model.repos['r-u1']!.complete(
      RegistryRepo.fromJson({
        'uuid': 'r-u1',
        'repository_url': 'https://gitlab.com/old/repo.git',
      }),
    );
    await tester.pumpAndSettle();
    expect(slot('repo').title, repoCaption(url));

    await open('u3');
    expect(slot('repo').title, 'Репозиторий');
    model.repos['r-u3']!.completeError(StateError('Repository unavailable'));
    await tester.pumpAndSettle();
    expect(slot('repo').title, 'Репозиторий');
    expect(slot('repo').enabled, isTrue);
    expect(slot('info').footer, '6д 21ч');
    expect(slot('info').center, isNotEmpty);
    expect(find.bySemanticsLabel('Ошибка'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final available in [true, false]) {
    testWidgets('eighth cell opens the parent repo, available=$available', (
      tester,
    ) async {
      final model = _UnitRepoModel();
      await model.load();
      model.vault.instances.add(
        InstanceRecord(
          url: 'https://example.com',
          token: 't',
          userUuid: 'me',
          active: true,
        ),
      );
      final router = GoRouter(
        initialLocation: '/units/u1',
        routes: [
          GoRoute(
            path: '/units/:uuid',
            builder: (_, state) =>
                UnitPage(uuid: state.pathParameters['uuid']!),
          ),
          GoRoute(
            path: '/registry/repo/:uuid',
            builder: (_, state) => Scaffold(
              body: Text('Parent repo ${state.pathParameters['uuid']}'),
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        AppScope(
          model: model,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      if (available) {
        model.repos['r-u1']!.complete(
          RegistryRepo.fromJson({
            'uuid': 'r-u1',
            'repository_url': 'https://example.com/parent.git',
          }),
        );
      } else {
        model.repos['r-u1']!.completeError(
          StateError('Repository unavailable'),
        );
      }
      await tester.pumpAndSettle();
      final scene = tester.widget<HexScene>(find.byType(HexScene));
      expect(scene.slots, hasLength(8));
      final repo = scene.slots.singleWhere((slot) => slot.id == 'repo');
      await tester.tap(find.bySemanticsLabel(repo.title));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, '/registry/repo/r-u1');
      expect(find.text('Parent repo r-u1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

class _UnitRepoModel extends AppModel {
  _UnitRepoModel() : super(store: MemoryVaultStore());

  final repos = <String, Completer<RegistryRepo>>{};

  @override
  Future<Unit> readUnit(String uuid) async => Unit.fromJson({
    'uuid': uuid,
    'repo_uuid': 'r-$uuid',
    'creator_uuid': 'me',
    'visibility_level': 'Public',
    'unit_state': {'millis': 595925249},
  });

  @override
  Future<RegistryRepo> readRepo(String uuid) =>
      (repos[uuid] = Completer<RegistryRepo>()).future;

  @override
  Future<({int count, List<UnitIo> ios})> listIos({
    required int offset,
    required int limit,
    String? unitUuid,
    List<String>? types,
  }) async => (count: 0, ios: const <UnitIo>[]);
}
