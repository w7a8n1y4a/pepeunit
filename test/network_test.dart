import 'dart:convert';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/account/identity.dart';
import 'package:pepeunit_client/account/vault.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/api/pepeunit_api.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/instances/instance.dart';
import 'package:pepeunit_client/instances/network_view.dart';
import 'package:pepeunit_client/instances/portrait.dart';
import 'package:pepeunit_client/instances/session.dart';
import 'package:pepeunit_client/instances/settings_catalog.dart';
import 'package:pepeunit_client/main.dart';

const _unit = 'https://unit.pepeunit.com$instanceCurrentPath';
const _dc = 'https://dcunit.pepeunit.com$instanceCurrentPath';

void main() {
  test('allow list narrows the directory and deny wins', () {
    const open = InstancePolicy();
    expect(open.admits(_unit), isTrue);
    expect(const InstancePolicy(deny: [_unit]).admits(_unit), isFalse);
    expect(const InstancePolicy(allow: [_dc]).admits(_unit), isFalse);
    expect(const InstancePolicy(allow: [_dc]).admits(_dc), isTrue);
    expect(
      const InstancePolicy(allow: [_unit], deny: [_unit]).admits(_unit),
      isFalse,
    );
  });

  test('search keeps at least one trust status', () {
    final query = NetworkQuery();
    expect(query.matches(_unit, null), isTrue);
    expect(query.matches(_unit, 'Blocking'), isTrue);
    query.text = 'https://unit.pepeunit.com';
    expect(query.matches(_unit, 'Trust'), isTrue);
    expect(query.matches(_dc, 'Trust'), isFalse);
    query.toggleTrust('Trust');
    query.toggleTrust('Pending');
    expect(query.trust, {'Blocking'});
    query.toggleTrust('Blocking');
    expect(query.trust, {'Blocking'});
  });

  test('three rings grow by six cells and the outer ring pages', () {
    expect(hexDisk(0), [(0, 0)]);
    expect(hexDisk(1), [
      (0, 0),
      (0, -1),
      (1, -1),
      (0, 1),
      (-1, 1),
      (-1, 0),
      (1, 0),
    ]);
    expect(hexDisk(1, wide: true), [
      (0, 0),
      (-1, 0),
      (1, 0),
      (0, -1),
      (1, -1),
      (0, 1),
      (-1, 1),
    ]);
    expect(hexDisk(2).skip(7), [
      (0, -2),
      (1, -2),
      (2, -2),
      (0, 2),
      (-1, 2),
      (-2, 2),
      (-1, -1),
      (-2, 0),
      (-2, 1),
      (2, -1),
      (2, 0),
      (1, 1),
    ]);
    expect(hexDisk(3).length, 37);
    expect(hexDisk(3).toSet().length, 37);
    expect(hexDisk(3)[19], (0, -3));
    expect(hexDisk(3)[32], (3, -2));
    expect(hexDisk(3)[34], (3, 0));
    expect(nextHex(const [(0, 0), (0, 1), (0, -1), (1, -1)]), (-1, 1));
    expect(nextHex(const [(0, 0), (0, 1), (0, -1), (1, -1)], wide: true), (
      -1,
      0,
    ));
    final loose = cardBoard(const ['custom']);
    expect(
      (
        loose.firstWhere((slot) => slot.id == 'custom').q,
        loose.firstWhere((slot) => slot.id == 'custom').r,
      ),
      (0, -1),
    );
    expect(
      (
        loose.firstWhere((slot) => slot.id == 'back').q,
        loose.firstWhere((slot) => slot.id == 'back').r,
      ),
      (0, 0),
    );

    final quiet = networkBoard(target: null);
    expect(quiet.slots.map((slot) => slot.id), [
      'settings',
      'address',
      'search',
      'back',
    ]);
    expect(quiet.slots.any((slot) => slot.id == 'instance'), isFalse);
    expect(quiet.canZoomIn, isFalse);
    expect(quiet.slots.firstWhere((slot) => slot.id == 'settings').q, 0);
    expect(quiet.slots.firstWhere((slot) => slot.id == 'settings').r, -1);
    expect(quiet.slots.firstWhere((slot) => slot.id == 'back').q, 0);
    expect(quiet.slots.firstWhere((slot) => slot.id == 'back').r, 0);
    expect(quiet.slots.firstWhere((slot) => slot.id == 'address').q, 1);
    expect(quiet.slots.firstWhere((slot) => slot.id == 'address').r, -1);
    expect(quiet.slots.firstWhere((slot) => slot.id == 'search').q, 0);
    expect(quiet.slots.firstWhere((slot) => slot.id == 'search').r, 1);
    final placed = cardBoard(const ['identity', 'metrics', 'relogin']);
    final back = placed.firstWhere((slot) => slot.id == 'back');
    expect((back.q, back.r), (0, 0));
    expect(
      (
        placed.firstWhere((slot) => slot.id == 'identity').q,
        placed.firstWhere((slot) => slot.id == 'identity').r,
      ),
      (0, -1),
    );
    expect(
      (
        placed.firstWhere((slot) => slot.id == 'metrics').q,
        placed.firstWhere((slot) => slot.id == 'metrics').r,
      ),
      (1, -1),
    );
    expect(
      (
        placed.firstWhere((slot) => slot.id == 'relogin').q,
        placed.firstWhere((slot) => slot.id == 'relogin').r,
      ),
      (0, 1),
    );

    final many = [
      for (var i = 0; i < 40; i++) 'https://h$i.example$instanceCurrentPath',
    ];
    final aimed = networkBoard(target: defaultInstanceUrl);
    expect(
      aimed.slots.firstWhere((slot) => slot.id == 'target').url,
      defaultInstanceUrl,
    );
    final first = searchBoard(
      scope: 0,
      staff: true,
      scanAll: true,
      urls: many,
      page: 0,
    );
    expect(first.slots.any((slot) => slot.id == 'add'), isTrue);
    expect(first.slots.any((slot) => slot.id == 'scan-all'), isTrue);
    expect(first.slots.where((slot) => slot.id == 'instance').length, 3);
    expect(first.canZoomIn, isTrue);
    final outer = searchBoard(
      scope: 2,
      staff: true,
      scanAll: true,
      urls: many,
      page: 0,
    );
    expect(outer.pages, greaterThan(1));
    expect(outer.slots.any((slot) => slot.id == 'next'), isTrue);
    expect(outer.canZoomIn, isFalse);
  });

  test(
    'role decides which instance actions exist without bloating the card',
    () {
      expect(
        cardActions(
          isTarget: true,
          owner: false,
          staff: false,
          federation: true,
          telegram: false,
          trust: 'Trust',
        ),
        ['metrics', 'relogin', 'clear'],
      );
      final owner = cardActions(
        isTarget: true,
        owner: true,
        staff: true,
        federation: true,
        telegram: true,
        trust: 'Trust',
      );
      expect(owner, ['metrics', 'relogin', 'clear', 'telegram', 'settings']);
      expect(cardBoard(['identity', ...owner]).length, lessThanOrEqualTo(7));
      expect(tuneActions(owner: true, staff: true, federation: true), [
        'icon',
        'ops',
        'flags',
        'core',
        'services',
        'transport',
      ]);
      expect(operationActions(owner: true, staff: true, federation: true), [
        'tests',
        'scan-all',
        'reboot',
      ]);
      expect(operationActions(owner: false, staff: true, federation: true), [
        'tests',
        'scan-all',
      ]);
      expect(
        cardActions(
          isTarget: false,
          owner: false,
          staff: true,
          federation: true,
          telegram: true,
          trust: 'Pending',
        ),
        ['metrics', 'relogin', 'target', 'telegram', 'peer'],
      );
      expect(peerActions(trust: 'Pending', federation: true), [
        'trust',
        'block',
        'delete',
      ]);
      expect(peerActions(trust: 'Trust', federation: true), [
        'block',
        'scan',
        'delete',
      ]);
      expect(
        peerActions(trust: 'Trust', federation: false),
        isNot(contains('scan')),
      );
    },
  );

  test('menu follows the target and its flags', () {
    expect(menuSectionEnabled('library', hasTarget: false), isTrue);
    expect(menuSectionEnabled('peers', hasTarget: false), isTrue);
    expect(menuSectionEnabled('people', hasTarget: false), isTrue);
    expect(menuSectionEnabled('units', hasTarget: false), isFalse);
    expect(menuSectionEnabled('units', hasTarget: true), isTrue);
    expect(
      menuSectionEnabled('alerts', hasTarget: true, notifications: false),
      isFalse,
    );
    expect(
      menuSectionEnabled('dashboards', hasTarget: true, grafana: false),
      isFalse,
    );
    expect(menuSectionEnabled('alerts', hasTarget: true), isTrue);
  });

  test(
    'settings categories cover the owner fields once and groups stay 1-ring',
    () {
      final keys = [
        for (final category in settingCategories)
          for (final field in category.fields) field.key,
      ];
      expect(keys.toSet().length, keys.length);
      expect(keys.length, 58);
      for (final category in settingCategories) {
        expect(category.fields.length, lessThanOrEqualTo(6));
      }
      final groupedCategories = [
        'flags',
        for (final group in settingGroups) ...group.categoryIds,
      ];
      expect(
        groupedCategories.toSet(),
        settingCategories.map((c) => c.id).toSet(),
      );
      expect(keys, contains('pu_ff_telegram_bot_enable'));
      expect(keys, contains('pu_telegram_token'));
      expect(keys, isNot(contains('icon_uuid')));
      final users = settingCategory('users')!.fields.first;
      expect(parseSetting(users, '0'), isNull);
      expect(settingIssue(users, '0', 'ru'), 'Вне диапазона 1..1000000');
      expect(settingIssue(users, '16', 'ru'), isNull);
      expect(parseSetting(users, '16'), 16);
      final emailField = settingCategory('contacts')!.fields.first;
      expect(parseSetting(emailField, 'not-an-email'), isNull);
      expect(
        parseSetting(emailField, 'owner@pepeunit.com'),
        'owner@pepeunit.com',
      );
    },
  );

  test('peer pages stop at the reported total', () async {
    final seen = <int>[];
    final urls = await collectPages<String>(
      limit: 2,
      fetch: (offset, limit) async {
        seen.add(offset);
        const all = ['a', 'b', 'c'];
        return (
          total: all.length,
          items: all.skip(offset).take(limit).toList(),
        );
      },
    );
    expect(urls, ['a', 'b', 'c']);
    expect(seen, [0, 2]);
  });

  test('a loopback target yields to the hosted instance', () async {
    final store = MemoryVaultStore();
    store.vault = Vault.fromJson({
      'instances': [
        {'url': 'http://localhost:1234$instanceCurrentPath', 'active': true},
      ],
    });
    final model = AppModel(
      store: store,
      api: (origin) => _DirectoryApi(origin),
      hostedUrl: () async => defaultInstanceUrl,
    );
    await model.load();
    expect(model.target?.url, defaultInstanceUrl);
    expect(
      model.vault.instances.any(
        (instance) => instance.url.contains('localhost'),
      ),
      isFalse,
    );
  });

  test('a missing user is registered before the challenge is signed', () async {
    final identity = Identity.generate();
    final api = _SessionApi();
    final session = await openSession(api, identity);
    expect(api.registered, isTrue);
    expect(session.role, 'User');
    expect(session.uuid, 'user-1');
  });

  testWidgets('flags, search, peer moderation and the owner hub stay 1-ring', (
    tester,
  ) async {
    final model = AppModel(
      store: MemoryVaultStore(),
      api: (origin) => _DirectoryApi(origin),
      hostedUrl: () async => defaultInstanceUrl,
    );
    await model.load();
    await tester.pumpWidget(AppScope(model: model, child: const PepeunitApp()));
    await tester.pumpAndSettle();

    expect(model.target?.url, defaultInstanceUrl);
    expect(model.discovered, containsAll([_unit, _dc]));
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Уведомления'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Панели'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Устройства'))
          .flagsCollection
          .isEnabled,
      Tristate.isTrue,
    );

    await tester.tap(find.bySemanticsLabel('devunit.pepeunit.com'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('unit.pepeunit.com'), findsNothing);
    expect(find.bySemanticsLabel('Добавить'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Поиск пиров'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('unit.pepeunit.com'), findsOneWidget);
    expect(find.bySemanticsLabel('dcunit.pepeunit.com'), findsOneWidget);

    model.target!.role = 'Admin';
    model.notifyListeners();
    await tester.pump();
    expect(find.bySemanticsLabel('Добавить'), findsOneWidget);
    expect(find.bySemanticsLabel('Опросить все'), findsOneWidget);
    // Peers remain visible on the first ring (scope=0) even when Admin is logged in!
    expect(find.bySemanticsLabel('unit.pepeunit.com'), findsOneWidget);
    expect(find.bySemanticsLabel('dcunit.pepeunit.com'), findsOneWidget);

    final search = find.byKey(const ValueKey('network-search'));
    await tester.tap(search);
    await tester.pump();
    await tester.enterText(search, 'd');
    await tester.pump();
    await tester.enterText(search, 'dc');
    await tester.pump();
    final field = tester.widget<TextField>(search);
    expect(field.controller!.text, 'dc');
    expect(field.focusNode!.hasFocus, isTrue);
    await tester.enterText(search, 'dcunit');
    await tester.pump();
    expect(find.bySemanticsLabel('unit.pepeunit.com'), findsNothing);
    expect(find.bySemanticsLabel('dcunit.pepeunit.com'), findsOneWidget);

    model.setSearch('');
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('unit.pepeunit.com'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Сделать Текущим'), findsOneWidget);
    expect(find.bySemanticsLabel('Telegram'), findsOneWidget);
    expect(find.bySemanticsLabel('Перезайти'), findsOneWidget);
    expect(find.bySemanticsLabel('Модерация'), findsOneWidget);
    expect(find.bySemanticsLabel('Доверять'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Модерация'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Доверять'), findsOneWidget);
    expect(find.bySemanticsLabel('Блокировать'), findsOneWidget);
    expect(find.bySemanticsLabel('Удалить'), findsOneWidget);
    expect(find.bySemanticsLabel('Опрос'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Модерация'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pumpAndSettle();
    model.target!.role = 'Owner';
    model.notifyListeners();
    await tester.pump();
    await tester.tap(find.bySemanticsLabel('devunit.pepeunit.com'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Параметры'), findsOneWidget);
    expect(find.bySemanticsLabel('Отменить выбор'), findsOneWidget);
    expect(find.bySemanticsLabel('Перезапуск'), findsNothing);
    expect(find.bySemanticsLabel('Тесты'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Параметры'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Аватар инстанса'), findsOneWidget);
    expect(find.bySemanticsLabel('Операции'), findsOneWidget);
    expect(find.bySemanticsLabel('Флаги'), findsOneWidget);
    expect(find.bySemanticsLabel('Система'), findsOneWidget);
    expect(find.bySemanticsLabel('Сервисы'), findsOneWidget);
    expect(find.bySemanticsLabel('Транспорт'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Операции'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Перезапуск'), findsOneWidget);
    expect(find.bySemanticsLabel('Тесты'), findsOneWidget);
    expect(find.bySemanticsLabel('Опросить все'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Система'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Контакты'), findsOneWidget);
    expect(find.bySemanticsLabel('Пользователи'), findsOneWidget);
    expect(find.bySemanticsLabel('Федерация'), findsOneWidget);
    expect(find.bySemanticsLabel('Журнал'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Пользователи'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Макс. юзеров'), findsOneWidget);
    expect(find.bySemanticsLabel('Макс. групп'), findsOneWidget);
    expect(find.bySemanticsLabel('Срок токена (с)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _DirectoryApi extends PepeunitApi {
  _DirectoryApi(super.origin);

  @override
  Future<InstancePortrait> portrait() async {
    return InstancePortrait(
      url: '$origin$instanceCurrentPath',
      version: '1.5.0',
      notifications: origin != 'https://devunit.pepeunit.com',
      grafana: false,
      telegram: origin == 'https://unit.pepeunit.com',
      federation: true,
      users: 4,
      units: 9,
      repos: 2,
    );
  }

  @override
  Future<({int total, List<String> items})> peerUrls({
    required int offset,
    required int limit,
  }) async {
    const urls = [_unit, _dc];
    return (total: urls.length, items: urls.skip(offset).take(limit).toList());
  }

  @override
  Future<({int total, List<PeerHead> items})> peers({
    required int offset,
    required int limit,
  }) async {
    if (offset > 0) return (total: 1, items: const <PeerHead>[]);
    return (
      total: 1,
      items: const [PeerHead(uuid: 'peer-1', url: _unit, trust: 'Pending')],
    );
  }
}

class _SessionApi extends PepeunitApi {
  _SessionApi() : super('https://example.test');

  var registered = false;
  var challenges = 0;

  @override
  Future<String> challenge(String hashPublicKey) async {
    challenges++;
    if (challenges == 1) throw ApiException(404, 'user does not exist');
    return 'challenge';
  }

  @override
  Future<void> register(String publicKeyBase64) async {
    registered = true;
  }

  @override
  Future<String> auth(String challengeToken, String signatureBase64) async {
    final payload = base64Url.encode(utf8.encode('{"uuid":"user-1"}'));
    return 'h.$payload.s';
  }

  @override
  Future<({String role, String uuid})> user(String token, String uuid) async {
    return (role: 'User', uuid: uuid);
  }
}
