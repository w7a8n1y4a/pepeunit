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
import 'package:pepeunit_client/instances/directory_user.dart';
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

  test('search keeps at least one trust status and hides blocked', () {
    final query = NetworkQuery();
    expect(query.trust, {'Trust', 'Pending'});
    expect(query.matches(_unit, null), isTrue);
    expect(query.matches(_unit, 'Blocking'), isFalse);
    query.text = 'https://unit.pepeunit.com';
    expect(query.matches(_unit, 'Trust'), isTrue);
    expect(query.matches(_dc, 'Trust'), isFalse);
    query.toggleTrust('Blocking');
    expect(query.matches(_unit, 'Blocking'), isTrue);
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
    expect(quiet.slots.map((slot) => slot.id), ['idle', 'search', 'back']);
    expect(quiet.slots.any((slot) => slot.id == 'instance'), isFalse);
    expect(quiet.canZoomIn, isFalse);
    expect(quiet.slots.firstWhere((slot) => slot.id == 'idle').q, 0);
    expect(quiet.slots.firstWhere((slot) => slot.id == 'idle').r, -1);
    expect(quiet.slots.firstWhere((slot) => slot.id == 'back').q, 0);
    expect(quiet.slots.firstWhere((slot) => slot.id == 'back').r, 0);
    expect(quiet.slots.firstWhere((slot) => slot.id == 'search').q, 1);
    expect(quiet.slots.firstWhere((slot) => slot.id == 'search').r, -1);
    final placed = cardBoard(const ['identity', 'metrics', 'settings']);
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
        placed.firstWhere((slot) => slot.id == 'settings').q,
        placed.firstWhere((slot) => slot.id == 'settings').r,
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
    final first = searchBoard(scope: 0, urls: many, page: 0);
    expect(first.slots.any((slot) => slot.id == 'settings'), isTrue);
    expect(first.slots.any((slot) => slot.id == 'add'), isFalse);
    expect(first.slots.any((slot) => slot.id == 'scan-all'), isFalse);
    expect(first.slots.where((slot) => slot.id == 'instance').length, 4);
    expect(first.canZoomIn, isTrue);
    final outer = searchBoard(scope: 2, urls: many, page: 0);
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
          telegram: false,
          trust: 'Trust',
        ),
        ['metrics', 'clear'],
      );
      expect(
        cardActions(
          isTarget: true,
          owner: false,
          staff: false,
          signedIn: true,
          telegram: false,
          trust: 'Trust',
        ),
        ['metrics', 'users', 'clear'],
      );
      expect(
        cardActions(
          isTarget: true,
          owner: false,
          staff: true,
          telegram: false,
          trust: 'Trust',
        ),
        ['metrics', 'users', 'clear'],
      );
      final owner = cardActions(
        isTarget: true,
        owner: true,
        staff: true,
        telegram: true,
        trust: 'Trust',
      );
      expect(owner, ['metrics', 'settings', 'users', 'telegram', 'clear']);
      expect(cardBoard(['identity', ...owner]).length, lessThanOrEqualTo(7));
      expect(tuneActions(owner: true), ['settings', 'ops']);
      expect(ownerSettingSections, [
        'instance',
        'mqtt',
        'datapipe',
        'notifications',
        'telegram',
        'icon',
      ]);
      expect(tuneActions(owner: false), isEmpty);
      expect(operationActions(owner: true, staff: true, federation: true), [
        'tests',
        'scan-all',
        'track',
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
          telegram: true,
          trust: 'Pending',
        ),
        ['metrics', 'peer', 'telegram', 'target'],
      );
      expect(
        memberActions(
          owner: false,
          staff: false,
          role: 'User',
          status: 'Active',
        ),
        ['card'],
      );
      expect(
        memberActions(
          owner: false,
          staff: true,
          role: 'User',
          status: 'Active',
        ),
        ['card', 'block'],
      );
      expect(
        memberActions(owner: true, staff: true, role: 'User', status: 'Active'),
        ['card', 'grant', 'block'],
      );
      expect(
        memberActions(
          owner: true,
          staff: true,
          role: 'Admin',
          status: 'Blocked',
        ),
        ['card', 'revoke', 'unblock'],
      );
      expect(
        memberActions(
          owner: true,
          staff: true,
          role: 'Owner',
          status: 'Active',
        ),
        ['card', 'block'],
      );
      final people = UserQuery();
      expect(people.roles, {'User', 'Admin', 'Owner'});
      expect(people.statuses, {'Active'});
      expect(people.order, 'desc');
      expect(people.toggleStatus('Blocked'), isTrue);
      expect(people.statuses, {'Active', 'Blocked'});
      expect(people.toggleStatus('Active'), isTrue);
      expect(people.toggleStatus('Blocked'), isFalse);
      expect(people.statuses, {'Blocked'});
      expect(people.toggleRole('Admin'), isTrue);
      expect(people.toggleRole('Owner'), isTrue);
      expect(people.toggleRole('User'), isFalse);
      expect(people.roles, {'User'});
      expect(people.setOrder('asc'), isTrue);
      expect(people.setOrder('asc'), isFalse);
      expect(people.order, 'asc');
      expect(userPageLimit(1), 16);
      expect(userPageLimit(2), 34);
      expect(
        userWindowText(offset: 0, limit: 16, count: 40, ofWord: 'из'),
        '1-16 из 40',
      );
      expect(
        userWindowText(offset: 0, limit: 34, count: 40, ofWord: 'из'),
        '1-34 из 40',
      );
      expect(
        userWindowText(offset: 16, limit: 16, count: 40, ofWord: 'из'),
        '17-32 из 40',
      );
      expect(
        userWindowText(offset: 34, limit: 34, count: 80, ofWord: 'из'),
        '35-68 из 80',
      );
      expect(
        userWindowText(offset: 0, limit: 16, count: 0, ofWord: 'of'),
        '0 of 0',
      );
      expect(userCanPageBack(offset: 0, count: 10), isFalse);
      expect(userCanPageForward(offset: 0, limit: 16, count: 10), isFalse);
      expect(userCanPageForward(offset: 0, limit: 16, count: 20), isTrue);
      expect(userCanPageBack(offset: 16, count: 20), isTrue);
      expect(userCanPageForward(offset: 0, limit: 34, count: 20), isFalse);
      expect(userCanPageForward(offset: 0, limit: 34, count: 40), isTrue);
      final narrow = usersBoard(
        scope: 1,
        uuids: [for (var i = 0; i < 16; i++) 'u$i'],
      );
      expect(narrow.slots.where((slot) => slot.id == 'user').length, 0);
      expect(
        narrow.slots.where((slot) => slot.id.startsWith('user:')).length,
        16,
      );
      expect(narrow.slots.firstWhere((slot) => slot.id == 'back').q, 0);
      expect(narrow.slots.firstWhere((slot) => slot.id == 'back').r, 0);
      expect(narrow.slots.firstWhere((slot) => slot.id == 'query').r, -1);
      expect(narrow.canZoomIn, isTrue);
      final wideRing = usersBoard(
        scope: 2,
        uuids: [for (var i = 0; i < 34; i++) 'u$i'],
      );
      expect(
        wideRing.slots.where((slot) => slot.id.startsWith('user:')).length,
        34,
      );
      expect(wideRing.canZoomIn, isFalse);
      expect(wideRing.slots.length, 37);
      expect(
        DirectoryUser.fromJson({
          'uuid': 'u',
          'role': 'Admin',
          'status': 'Blocked',
          'public_key': 'abc',
          'login': '  pepe  ',
          'icon_uuid': '',
        }).login,
        'pepe',
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

  test('settings cover every owner field once and honor flag locks', () {
    final keys = [
      for (final category in settingCategories)
        for (final field in category.fields) field.key,
    ];
    expect(keys.toSet().length, keys.length);
    expect(keys.length, 58);
    for (final category in settingCategories) {
      expect(category.fields.length, lessThanOrEqualTo(6));
      if (category.id != 'instance') {
        expect(category.links.length, lessThanOrEqualTo(6));
      }
    }
    expect(settingCategory('instance')!.links.length, 8);
    final reachable = <String>{};
    void walk(String id) {
      final category = settingCategory(id);
      if (category == null || !reachable.add(id)) return;
      for (final link in category.links) {
        walk(link);
      }
    }

    for (final id in ownerSettingSections) {
      walk(id);
    }
    expect(reachable, settingCategories.map((c) => c.id).toSet());
    expect(keys, contains('pu_ff_telegram_bot_enable'));
    expect(keys, contains('pu_telegram_token'));
    expect(keys, isNot(contains('icon_uuid')));
    final users = settingCategory('users')!.fields.first;
    expect(parseSetting(users, '0'), isNull);
    expect(settingIssue(users, '0', 'ru'), 'Вне диапазона 1..1000000');
    final keepalive = settingCategory('datapipe-link')!.fields.first;
    expect(parseSetting(keepalive, '0'), isNull);
    expect(parseSetting(keepalive, '1'), 1);
    expect(parseSetting(keepalive, '600'), 600);
    expect(settingIssue(keepalive, '0', 'ru'), 'Вне диапазона 1..600');
    final mqttKeepalive = settingCategory('mqtt-basic')!.fields.first;
    expect(parseSetting(mqttKeepalive, '0'), isNull);
    expect(parseSetting(mqttKeepalive, '1'), 1);
    expect(parseSetting(mqttKeepalive, '600'), 600);
    expect(settingIssue(mqttKeepalive, '0', 'ru'), 'Вне диапазона 1..600');
    final repoMaxSize = settingCategory('registry')!.fields.first;
    expect(parseSetting(repoMaxSize, '0'), isNull);
    expect(parseSetting(repoMaxSize, '1'), 1);
    expect(parseSetting(repoMaxSize, '1024'), 1024);
    expect(settingIssue(repoMaxSize, '0', 'ru'), 'Вне диапазона 1..1024');
    final cipherMax = settingCategory('instance-basic')!.fields.first;
    expect(parseSetting(cipherMax, '99999'), isNull);
    expect(parseSetting(cipherMax, '100000'), 100000);
    expect(parseSetting(cipherMax, '5000000'), 5000000);
    expect(
      settingIssue(cipherMax, '99999', 'ru'),
      'Вне диапазона 100000..5000000',
    );
    expect(settingIssue(users, '16', 'ru'), isNull);
    expect(parseSetting(users, '16'), 16);
    final emailField = settingCategory('contacts')!.fields.first;
    expect(parseSetting(emailField, 'not-an-email'), isNull);
    expect(
      parseSetting(emailField, 'owner@pepeunit.com'),
      'owner@pepeunit.com',
    );
    final link = settingCategory('telegram-link')!;
    const ready = {
      'pu_telegram_token': '123456:ABC-def',
      'pu_telegram_bot_mode': 'webhook',
      'pu_telegram_bot_link': 'https://t.me/bot',
      'pu_telegram_git_hash_length': 8,
      'pu_telegram_proxy_url': 'socks5://127.0.0.1:9050',
    };
    expect(settingFieldsReady(link, const {}), isFalse);
    expect(settingFieldsReady(link, ready), isTrue);
    expect(
      settingFieldsReady(link, {...ready, 'pu_telegram_token': 'bad'}),
      isFalse,
    );
    expect(
      settingSectionOpen(settingCategory('datapipe-basic')!, const {}),
      isFalse,
    );
    expect(
      settingSectionOpen(settingCategory('datapipe-link')!, {
        'pu_ff_datapipe_enable': true,
      }),
      isTrue,
    );
    expect(
      settingSectionOpen(settingCategory('notifications-basic')!, {
        'pu_ff_notification_enable': true,
      }),
      isTrue,
    );
    expect(
      settingSectionOpen(settingCategory('notifications-telegram')!, {
        'pu_ff_notification_enable': true,
      }),
      isFalse,
    );
    expect(
      settingSectionOpen(settingCategory('notifications-telegram')!, {
        'pu_ff_notification_enable': true,
        'pu_ff_telegram_bot_enable': true,
      }),
      isTrue,
    );
    expect(
      settingSectionOpen(settingCategory('telegram-look')!, {
        'pu_ff_telegram_bot_enable': false,
      }),
      isFalse,
    );
  });

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

  test('local add reads current and does not create a peer', () async {
    final api = _QuietApi();
    final model = AppModel(
      store: MemoryVaultStore(),
      api: (_) => api,
      hostedUrl: () async => null,
    );
    await model.load();
    await model.rememberInstance('https://unit.pepeunit.com');
    expect(api.portraits, 1);
    expect(api.created, isEmpty);
    expect(model.vault.pinned, [_unit]);
    expect(model.portraitOf(_unit)?.version, '1.5.0');
    expect(model.visibleInstances(), contains(_unit));
  });

  test('only the owner can post a tracked peer', () async {
    final api = _QuietApi();
    final store = MemoryVaultStore();
    store.vault = Vault.fromJson({
      'instances': [
        {'url': defaultInstanceUrl, 'active': true, 'role': 'User'},
      ],
    });
    final model = AppModel(
      store: store,
      api: (_) => api,
      hostedUrl: () async => defaultInstanceUrl,
    );
    await model.load();
    await expectLater(
      model.trackInstance('https://unit.pepeunit.com'),
      throwsA(isA<StateError>()),
    );
    expect(api.created, isEmpty);
    model.target!.role = 'Owner';
    model.target!.token = 'token';
    model.target!.userUuid = 'user-1';
    await model.trackInstance('https://unit.pepeunit.com');
    expect(api.created, [_unit]);
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
    expect(find.bySemanticsLabel('Добавить локально'), findsNothing);
    expect(find.bySemanticsLabel('Настройки'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Поиск инстансов'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('unit.pepeunit.com'), findsOneWidget);
    expect(find.bySemanticsLabel('dcunit.pepeunit.com'), findsOneWidget);
    expect(find.bySemanticsLabel('devunit.pepeunit.com'), findsOneWidget);
    expect(find.bySemanticsLabel('Настройки'), findsOneWidget);
    expect(find.bySemanticsLabel('Опросить соседей'), findsNothing);
    expect(find.bySemanticsLabel('Доверенный'), findsNothing);
    expect(find.bySemanticsLabel('Ожидает'), findsNothing);
    expect(find.bySemanticsLabel('Заблокирован'), findsNothing);

    model.target!.role = 'Admin';
    model.notifyListeners();
    await tester.pump();
    expect(find.bySemanticsLabel('Добавить локально'), findsNothing);
    expect(find.bySemanticsLabel('Опросить соседей'), findsNothing);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Доверенный'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Ожидает'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Заблокирован'))
          .flagsCollection
          .isSelected,
      Tristate.isFalse,
    );
    expect(find.bySemanticsLabel('unit.pepeunit.com'), findsOneWidget);
    expect(find.bySemanticsLabel('dcunit.pepeunit.com'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Настройки'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Добавить локально'), findsOneWidget);
    expect(find.bySemanticsLabel('Белый список'), findsOneWidget);
    expect(find.bySemanticsLabel('Чёрный список'), findsOneWidget);
    expect(find.bySemanticsLabel('Добавить адрес'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pumpAndSettle();

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
    expect(find.bySemanticsLabel('Сделать избранным'), findsOneWidget);
    expect(find.bySemanticsLabel('Телеграм бот'), findsOneWidget);
    expect(find.bySemanticsLabel('Перезайти'), findsNothing);
    expect(find.bySemanticsLabel('Команды'), findsNothing);
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
    expect(find.bySemanticsLabel('Управление инстансом'), findsOneWidget);
    expect(find.bySemanticsLabel('Пользователи'), findsOneWidget);
    expect(find.bySemanticsLabel('Разжаловать'), findsOneWidget);
    expect(find.bySemanticsLabel('Команды'), findsNothing);
    expect(find.bySemanticsLabel('Перезайти'), findsNothing);
    expect(find.bySemanticsLabel('Перезапуск'), findsNothing);
    expect(find.bySemanticsLabel('Тесты'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Управление инстансом'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Загрузить аватар'), findsNothing);
    expect(find.bySemanticsLabel('Настройки'), findsOneWidget);
    expect(find.bySemanticsLabel('Команды'), findsOneWidget);
    expect(find.bySemanticsLabel('Флаги'), findsNothing);
    expect(find.bySemanticsLabel('Система'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Команды'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Перезапуск'), findsOneWidget);
    expect(find.bySemanticsLabel('Тесты'), findsOneWidget);
    expect(find.bySemanticsLabel('Опросить соседей'), findsOneWidget);
    expect(find.bySemanticsLabel('Отслеживать инстанс'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Настройки'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Инстанс'), findsOneWidget);
    expect(find.bySemanticsLabel('MQTT'), findsOneWidget);
    expect(find.bySemanticsLabel('DataPipe'), findsOneWidget);
    expect(find.bySemanticsLabel('Уведомления'), findsOneWidget);
    expect(find.bySemanticsLabel('Телеграм бот'), findsOneWidget);
    expect(find.bySemanticsLabel('Загрузить аватар'), findsOneWidget);
    expect(find.bySemanticsLabel('Сервисы'), findsNothing);
    expect(find.bySemanticsLabel('Транспорт'), findsNothing);
    expect(find.bySemanticsLabel('Система'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Инстанс'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Флаги'), findsOneWidget);
    expect(find.bySemanticsLabel('Базовые'), findsOneWidget);
    expect(find.bySemanticsLabel('Пользователи'), findsOneWidget);
    expect(find.bySemanticsLabel('Реестр'), findsOneWidget);
    expect(find.bySemanticsLabel('Устройства'), findsOneWidget);
    expect(find.bySemanticsLabel('GitHub'), findsOneWidget);
    expect(find.bySemanticsLabel('Логи'), findsOneWidget);
    expect(find.bySemanticsLabel('Контакты'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Пользователи'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Макс. юзеров'), findsOneWidget);
    expect(find.bySemanticsLabel('Макс. групп'), findsOneWidget);
    expect(find.bySemanticsLabel('Срок токена (с)'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('DataPipe'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('DataPipe Вкл ?'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Базовые'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Соединение'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );

    model.targetSettings = {'pu_ff_datapipe_enable': true};
    model.notifyListeners();
    await tester.pump();
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Базовые'))
          .flagsCollection
          .isEnabled,
      Tristate.isTrue,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Соединение'))
          .flagsCollection
          .isEnabled,
      Tristate.isTrue,
    );

    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Телеграм бот'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Подключение'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Визуальные'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    await tester.tap(find.bySemanticsLabel('Визуальные'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Подключение'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Подключение'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Токен бота'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Бот Вкл ?'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );

    model.targetSettings = {
      'pu_telegram_token': '123456:ABC-def',
      'pu_telegram_bot_mode': 'webhook',
      'pu_telegram_bot_link': 'https://t.me/bot',
      'pu_telegram_git_hash_length': 8,
      'pu_telegram_proxy_url': 'socks5://127.0.0.1:9050',
    };
    model.notifyListeners();
    await tester.pump();
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Бот Вкл ?'))
          .flagsCollection
          .isEnabled,
      Tristate.isTrue,
    );

    model.targetSettings = {
      ...model.targetSettings!,
      'pu_ff_telegram_bot_enable': true,
      'pu_ff_notification_enable': false,
    };
    model.notifyListeners();
    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pumpAndSettle();
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Визуальные'))
          .flagsCollection
          .isEnabled,
      Tristate.isTrue,
    );

    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Уведомления'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Уведомления Вкл?'), findsOneWidget);
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Базовые'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Телеграм бот'))
          .flagsCollection
          .isEnabled,
      Tristate.isFalse,
    );

    model.targetSettings = {
      ...model.targetSettings!,
      'pu_ff_notification_enable': true,
    };
    model.notifyListeners();
    await tester.pump();
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Базовые'))
          .flagsCollection
          .isEnabled,
      Tristate.isTrue,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Телеграм бот'))
          .flagsCollection
          .isEnabled,
      Tristate.isTrue,
    );
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

class _QuietApi extends _DirectoryApi {
  _QuietApi() : super('https://devunit.pepeunit.com');

  var portraits = 0;
  final created = <String>[];

  @override
  Future<InstancePortrait> portrait() async {
    portraits++;
    return super.portrait();
  }

  @override
  Future<void> createPeer(String token, String url) async {
    created.add(url);
  }

  @override
  Future<({String role, String uuid})> user(String token, String uuid) async {
    return (role: 'Owner', uuid: uuid);
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
