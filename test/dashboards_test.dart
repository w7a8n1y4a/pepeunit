import 'dart:convert';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/api/pepeunit_api.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/dashboards/dashboard.dart';
import 'package:pepeunit_client/features/dashboards/dashboard_page.dart';
import 'package:pepeunit_client/features/units/name_pick_page.dart';
import 'package:pepeunit_client/hive/hex_order.dart';
import 'package:pepeunit_client/features/dashboards/dashboards_chrome.dart';
import 'package:pepeunit_client/features/dashboards/dashboards_menu_page.dart';
import 'package:pepeunit_client/features/dashboards/dashboards_page.dart';
import 'package:pepeunit_client/features/dashboards/panel_pages.dart';
import 'package:pepeunit_client/instances/instance.dart';
import 'package:pepeunit_client/units/unit.dart';

void main() {
  test('panel types, statuses and name rules', () {
    expect(panelTypes, hasLength(26));
    expect(panelTypes.map((type) => type.value).toSet(), hasLength(26));
    expect(panelTypeLabel('timeseries'), 'Time series');
    expect(panelTypeLabel('unknown'), 'unknown');
    expect(dashboardStatusLabel('ru', null), 'Черновик');
    expect(dashboardStatusLabel('ru', 'Success'), 'Отправлена');
    expect(dashboardStatusLabel('en', 'Error'), 'Error');
    expect(dashboardNameOk('abc'), isFalse);
    expect(dashboardNameOk('meter_1'), isTrue);
    expect(dashboardNameOk('bad name'), isFalse);
    expect(dashboardNameOk('x' * 21), isFalse);
    expect(dashboardMenuIds, [
      'card',
      'info',
      'panels',
      'sync',
      'open',
      'delete',
    ]);
    expect(panelMenuIds, ['card', 'nodes', 'delete']);
  });

  test('a dashboard opens in the user organization', () {
    expect(
      dashboardLink(
        'https://unit.example/',
        '/grafana/d/abc/meter',
        orgId: '7',
      ).toString(),
      'https://unit.example/grafana/d/abc/meter?orgId=7',
    );
    expect(
      dashboardLink('https://unit.example', 'grafana/d/abc').toString(),
      'https://unit.example/grafana/d/abc',
    );
    expect(
      dashboardLink(
        'https://unit.example',
        'https://other.example/d/abc?x=1',
        orgId: '2',
      ).queryParameters,
      {'x': '1', 'orgId': '2'},
    );
  });

  test(
    'the Grafana link is a one-time ticket without cookie or header',
    () async {
      late http.Request seen;
      final client = MockClient((request) async {
        seen = request;
        return http.Response('{"ticket":"abc","expires_in":60}', 201);
      });
      final api = PepeunitApi('https://unit.example/', client: client);

      final link = await api.grafanaLink(
        'jwt',
        path: '/grafana/d/abc/meter?orgId=7',
      );

      expect(
        link.toString(),
        'https://unit.example/pepeunit/api/v1/grafana/enter?ticket=abc',
      );
      expect(seen.method, 'POST');
      expect(seen.url.path, '/pepeunit/api/v1/grafana/login_ticket');
      expect(seen.headers['x-auth-token'], 'jwt');
      expect(seen.headers.containsKey('cookie'), isFalse);
      expect(jsonDecode(seen.body), {'path': '/grafana/d/abc/meter?orgId=7'});
    },
  );

  test('a dashboard opens by a ticket link on its own page', () async {
    final api = _DashApi()..orgId = '7';
    final model = await _model(api);

    final uri = await model.dashboardUri(
      const Dashboard(
        uuid: 'd1',
        name: 'meter',
        created: '',
        creatorUuid: 'me',
        url: '/grafana/d/abc/meter',
      ),
    );

    expect(uri.path, '/pepeunit/api/v1/grafana/enter');
    expect(uri.queryParameters, {'ticket': 'ticket-1'});
    expect(api.openedPath, '/grafana/d/abc/meter?orgId=7');
  });

  test('a panel counts its inputs and outputs', () {
    final panel = DashboardPanel.fromJson({
      'uuid': 'p1',
      'type': 'gauge',
      'title': 'speed',
      'dashboard_uuid': 'd1',
      'unit_ios_for_panel': [
        {
          'unit_with_unit_io_name': 'pump@in',
          'is_last_data': true,
          'unit_io': {'uuid': 'i1', 'type': 'Input', 'topic_name': 'in'},
        },
        {
          'unit_with_unit_io_name': 'pump@out',
          'is_forced_to_json': true,
          'unit_io': {'uuid': 'i2', 'type': 'Output', 'topic_name': 'out'},
        },
        {
          'unit_with_unit_io_name': 'pump@out2',
          'unit_io': {'uuid': 'i3', 'type': 'Output', 'topic_name': 'out2'},
        },
      ],
    });
    expect(panel.inputs, 1);
    expect(panel.outputs, 2);
    expect(panel.links.first.lastOnly, isTrue);
    expect(panel.links.first.asJson, isFalse);
    expect(panel.links[1].asJson, isTrue);
    final dashboard = Dashboard.fromJson({
      'uuid': 'd1',
      'name': 'meter',
      'inc_last_version': 3,
      'dashboard_url': '',
    });
    expect(dashboard.version, 3);
    expect(dashboard.opens, isFalse);
  });

  testWidgets('the list shows dashboards of the user', (tester) async {
    final api = _DashApi();
    await _show(tester, api, const DashboardsPage(scope: searchScaleTick));
    expect(api.order, 'desc');
    expect(find.bySemanticsLabel('meter'), findsOneWidget);
    expect(find.bySemanticsLabel('Создать панель'), findsNothing);
    expect(find.bySemanticsLabel('Добавить панель'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the section menu holds back, add and search', (tester) async {
    await _show(tester, _DashApi(), const DashboardsMenuPage());
    expect(find.bySemanticsLabel('Назад'), findsOneWidget);
    expect(find.bySemanticsLabel('Добавить панель'), findsOneWidget);
    expect(find.bySemanticsLabel('Поиск'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the type list pages behind its own window cell', (tester) async {
    await _show(
      tester,
      _DashApi(),
      NamePickPage(
        title: 'Type',
        scope: menuScaleTick,
        path: '/dashboards/type',
        paged: true,
        load: () async => [
          for (final type in panelTypes) (id: type.value, label: type.label),
        ],
      ),
    );
    expect(find.bySemanticsLabel('Назад'), findsOneWidget);
    expect(find.bySemanticsLabel('Страница'), findsOneWidget);
    expect(find.bySemanticsLabel('Time series'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Следующие'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Time series'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('send keeps the grafana error and open waits for a url', (
    tester,
  ) async {
    final api = _DashApi()..syncError = 'datasource is down';
    await _show(tester, api, const DashboardPage(uuid: 'd1'));
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Открыть в Grafana'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    await tester.tap(find.bySemanticsLabel('Отправить в Grafana'));
    await tester.pumpAndSettle();
    expect(api.synced, 1);
    expect(find.bySemanticsLabel('Ошибка'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a link takes the flags chosen on the form', (tester) async {
    final api = _DashApi();
    await _show(
      tester,
      api,
      const PanelNodeFormPage(panelUuid: 'p1', ioUuid: 'i1'),
    );
    expect(find.bySemanticsLabel('Только последнее'), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Только последнее')).value,
      'выкл',
    );
    await tester.tap(find.bySemanticsLabel('Только последнее'));
    await tester.pump();
    expect(
      tester.getSemantics(find.bySemanticsLabel('Только последнее')).value,
      'вкл',
    );
    await tester.tap(find.bySemanticsLabel('Связать'));
    await tester.pumpAndSettle();
    expect(api.linked, (panel: 'p1', io: 'i1', last: true, json: false));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a panel needs a valid title before it is created', (
    tester,
  ) async {
    final api = _DashApi();
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const PanelCreatePage(uuid: 'd1'),
        ),
        GoRoute(
          path: '/dashboards/:uuid/panels/:pid',
          builder: (context, state) => Text(state.pathParameters['pid']!),
        ),
      ],
    );
    addTearDown(router.dispose);
    final model = await _model(api);
    await tester.pumpWidget(
      AppScope(
        model: model,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Создать'));
    await tester.pumpAndSettle();
    expect(api.created, isNull);
    await tester.enterText(find.byType(TextField), 'speed');
    await tester.tap(find.bySemanticsLabel('Создать'));
    await tester.pumpAndSettle();
    expect(api.created, (dashboard: 'd1', title: 'speed', type: 'timeseries'));
    expect(find.text('p-new'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<AppModel> _model(_DashApi api) async {
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
  return model;
}

Future<void> _show(WidgetTester tester, _DashApi api, Widget page) async {
  final model = await _model(api);
  await tester.pumpWidget(
    AppScope(
      model: model,
      child: MaterialApp(home: page),
    ),
  );
  await tester.pumpAndSettle();
}

class _DashApi extends PepeunitApi {
  _DashApi() : super('https://devunit.pepeunit.com');

  String? order;
  String? syncError;
  String? orgId;
  String? openedPath;
  var synced = 0;
  ({String panel, String io, bool last, bool json})? linked;
  ({String dashboard, String title, String type})? created;

  @override
  Future<({int count, List<Dashboard> dashboards})> dashboards({
    required String token,
    required int offset,
    required int limit,
    String search = '',
    String order = 'desc',
  }) async {
    this.order = order;
    return (count: 1, dashboards: [_dashboard()]);
  }

  @override
  Future<String?> grafanaOrgId(String token, String uuid) async => orgId;

  @override
  Future<Uri> grafanaLink(String token, {String? path}) async {
    openedPath = path;
    return Uri.parse(
      'https://devunit.pepeunit.com/pepeunit/api/v1/grafana/enter'
      '?ticket=ticket-1',
    );
  }

  @override
  Future<Dashboard> readDashboard(String token, String uuid) async =>
      _dashboard();

  @override
  Future<List<DashboardPanel>> dashboardPanels(
    String token,
    String uuid,
  ) async => const [];

  @override
  Future<Dashboard> syncDashboard(String token, String uuid) async {
    synced++;
    return Dashboard(
      uuid: uuid,
      name: 'meter',
      created: '2026-01-01T00:00:00',
      creatorUuid: 'me',
      syncStatus: syncError == null ? 'Success' : 'Error',
      syncError: syncError,
    );
  }

  @override
  Future<UnitIo> readUnitIo(String token, String uuid) async =>
      UnitIo.fromJson({
        'uuid': uuid,
        'type': 'Output',
        'topic_name': 'temp',
        'visibility_level': 'Public',
      });

  @override
  Future<PanelLink> linkPanelIo(
    String token, {
    required String panelUuid,
    required String ioUuid,
    required bool lastOnly,
    required bool asJson,
  }) async {
    linked = (panel: panelUuid, io: ioUuid, last: lastOnly, json: asJson);
    return PanelLink.fromJson(const {});
  }

  @override
  Future<DashboardPanel> createPanel(
    String token, {
    required String dashboardUuid,
    required String title,
    required String type,
  }) async {
    created = (dashboard: dashboardUuid, title: title, type: type);
    return DashboardPanel(
      uuid: 'p-new',
      type: type,
      title: title,
      created: '',
      dashboardUuid: dashboardUuid,
    );
  }

  Dashboard _dashboard() => const Dashboard(
    uuid: 'd1',
    name: 'meter',
    created: '2026-01-01T00:00:00',
    creatorUuid: 'me',
  );
}
