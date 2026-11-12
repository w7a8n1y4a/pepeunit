import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/features/units/unit_page.dart';
import 'package:pepeunit_client/hive/hex_scene.dart';
import 'package:pepeunit_client/instances/instance.dart';
import 'package:pepeunit_client/registry/repo.dart';
import 'package:pepeunit_client/units/unit.dart';

void main() {
  testWidgets('info shows its repo caption and ignores a stale repo response', (
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

    HexSlot info() => tester
        .widget<HexScene>(find.byType(HexScene))
        .slots
        .firstWhere((slot) => slot.id == 'info');

    await open('u1');
    expect(info().footer, isNull);
    await open('u2');
    const url = 'https://gitlab.com/pepe/units/long_repository_name.git';
    model.repos['r-u2']!.complete(
      RegistryRepo.fromJson({'uuid': 'r-u2', 'repository_url': url}),
    );
    await tester.pumpAndSettle();
    expect(info().footer, repoCaption(url));
    expect(info().footer!.length, greaterThanOrEqualTo(13));
    expect(info().footerLeft, isNull);
    expect(info().sideRight, '6д 21ч');

    model.repos['r-u1']!.complete(
      RegistryRepo.fromJson({
        'uuid': 'r-u1',
        'repository_url': 'https://gitlab.com/old/repo.git',
      }),
    );
    await tester.pumpAndSettle();
    expect(info().footer, repoCaption(url));

    await open('u3');
    expect(info().footer, isNull);
    model.repos['r-u3']!.completeError(StateError('Repository unavailable'));
    await tester.pumpAndSettle();
    expect(info().footer, isNull);
    expect(info().center, isNotEmpty);
    expect(find.bySemanticsLabel('Ошибка'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _UnitRepoModel extends AppModel {
  _UnitRepoModel() : super(store: MemoryVaultStore());

  final repos = <String, Completer<RegistryRepo>>{};

  @override
  Future<Unit> readUnit(String uuid) async => Unit.fromJson({
    'uuid': uuid,
    'repo_uuid': 'r-$uuid',
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
