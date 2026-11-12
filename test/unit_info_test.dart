import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/api/pepeunit_api.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/features/units/unit_info_page.dart';
import 'package:pepeunit_client/hive/hex_scene.dart';
import 'package:pepeunit_client/instances/instance.dart';

void main() {
  for (final auto in [true, false]) {
    testWidgets('info loads the resolved target with auto=$auto', (
      tester,
    ) async {
      final requests = await openInfo(tester, auto: auto);

      expect(requests, [
        '/pepeunit/api/v1/units/u1',
        '/pepeunit/api/v1/units/get_target_version/u1',
      ]);
      expect(find.text('Цель abcdef1'), findsOneWidget);
      expect(find.text('Устройство 1234567'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('target failure preserves the other unit information', (
    tester,
  ) async {
    await openInfo(tester, targetFails: true);

    expect(find.text('Устройство 1234567'), findsOneWidget);
    expect(find.text('80 МГц'), findsOneWidget);
    expect(find.text('Цель —'), findsOneWidget);
    final scene = tester.widget<HexScene>(find.byType(HexScene));
    expect(scene.slots.any((slot) => slot.id == 'error'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('viewing another unit does not call the restricted endpoint', (
    tester,
  ) async {
    final requests = await openInfo(tester, owned: false, auto: false);

    expect(requests, ['/pepeunit/api/v1/units/u1']);
    expect(find.text('Цель 7654321'), findsOneWidget);
    expect(find.text('Устройство 1234567'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<List<String>> openInfo(
  WidgetTester tester, {
  bool auto = true,
  bool owned = true,
  bool targetFails = false,
}) async {
  final requests = <String>[];
  final client = MockClient((request) async {
    if (request.url.path == '/pepeunit/api/v1/instances/current') {
      return http.Response('{}', 200);
    }
    requests.add(request.url.path);
    expect(request.method, 'GET');
    expect(request.headers['x-auth-token'], 't');
    switch (request.url.path) {
      case '/pepeunit/api/v1/units/u1':
        return http.Response(
          jsonEncode({
            'uuid': 'u1',
            'creator_uuid': owned ? 'me' : 'someone-else',
            'is_auto_update_unit': auto,
            'target_commit': auto ? null : '7654321fedcba',
            'target_branch': 'main',
            'current_commit_version': '1234567abcdef',
            'unit_state': {'freq': 80000000},
          }),
          200,
        );
      case '/pepeunit/api/v1/units/get_target_version/u1':
        return targetFails
            ? http.Response('Version is missing', 400)
            : http.Response(
                jsonEncode({
                  'commit': 'abcdef1234567',
                  'tag': auto ? 'v2' : null,
                }),
                200,
              );
      default:
        throw StateError('Unexpected request: ${request.url}');
    }
  });
  final api = PepeunitApi('https://devunit.pepeunit.com', client: client);
  final model = AppModel(store: MemoryVaultStore(), api: (_) => api);
  addTearDown(model.dispose);
  addTearDown(client.close);
  await model.load();
  model.vault.instances.add(
    InstanceRecord(
      url: devInstanceUrl,
      token: 't',
      role: 'User',
      userUuid: 'me',
      active: true,
    ),
  );
  await tester.pumpWidget(
    AppScope(
      model: model,
      child: const MaterialApp(home: UnitInfoPage(uuid: 'u1')),
    ),
  );
  await tester.pumpAndSettle();
  return requests;
}
