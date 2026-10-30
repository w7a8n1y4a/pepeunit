import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/alerts/notice.dart';
import 'package:pepeunit_client/api/pepeunit_api.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/features/alerts/alerts_page.dart';
import 'package:pepeunit_client/instances/instance.dart';
import 'package:pepeunit_client/instances/network_view.dart';

void main() {
  test('role hides notification types the backend will not send', () {
    expect(noticeTypesForRole('User'), [
      'UnitDailySummary',
      'DataPipeAlert',
      'UpdateRepo',
      'UpdateUnitsFirmware',
    ]);
    expect(noticeTypesForRole('Admin'), [
      'InstanceDailyState',
      'UnitDailySummary',
      'DataPipeAlert',
      'IntegrationTests',
      'ScanAllPeers',
      'ScanPeer',
      'UpdateAllRepos',
      'UpdateRepo',
      'UpdateUnitsFirmware',
      'UpdateAllUnitsFirmware',
    ]);
    expect(noticeTypesForRole('Owner'), [
      ...noticeTypesForRole('Admin'),
      'RebootInstance',
    ]);
    expect(noticeTypesForRole(null), noticeTypesForRole('User'));
  });

  test('notice time is month.day hour:minute in the client zone', () {
    expect(noticeWhen('2026-10-30T12:04:00Z', '180'), '10.30 15:04');
    expect(noticeWhen('2026-10-30T12:04:00', '0'), '10.30 12:04');
    expect(noticeWhen('2026-01-02T23:30:00Z', '-120'), '01.02 21:30');
    expect(noticeWhen('', '0'), '');
  });

  test('the list opens on tick 3 and pages only past the last tick', () {
    expect(noticePageLimit(1), 4);
    expect(noticePageLimit(searchScaleTick), 10);
    expect(noticePageLimit(scaleTickMax), 16);
    expect(noticeCanPageBack(offset: 0, count: 40), isFalse);
    expect(noticeCanPageBack(offset: 10, count: 16), isFalse);
    expect(noticeCanPageBack(offset: 10, count: 17), isTrue);
    expect(noticeCanPageForward(offset: 0, limit: 10, count: 16), isFalse);
    expect(noticeCanPageForward(offset: 0, limit: 10, count: 17), isTrue);
    final board = noticesBoard(tick: searchScaleTick, uuids: const ['a', 'b']);
    expect(board.slots.map((slot) => slot.id), [
      'back',
      'filter',
      'types',
      'notice:a',
      'notice:b',
    ]);
    expect(board.canZoomIn, isTrue);
  });

  test('a stream frame becomes a notice and a comment does not', () {
    final buffer = SseBuffer();
    expect(buffer.add(': connected\n\n'), isEmpty);
    const uuid = '11111111-1111-1111-1111-111111111111';
    final raw = jsonEncode({
      'uuid': uuid,
      'create_datetime': '2026-10-30T12:04:00Z',
      'type': 'DataPipeAlert',
      'small_text': 'boom',
      'table_text': 'unit | 1',
      'is_read': false,
    });
    expect(buffer.add('data: $raw'), isEmpty);
    final found = buffer.add('\n\n');
    expect(found, hasLength(1));
    expect(found.single.uuid, uuid);
    expect(found.single.smallText, 'boom');
    expect(found.single.isRead, isFalse);
    expect(found.single.bigText, '');
  });

  testWidgets('a card opens its table and is marked read', (tester) async {
    final api = _NoticeApi();
    final model = AppModel(store: MemoryVaultStore(), api: (_) => api);
    await model.load();
    model.vault.instances.add(
      InstanceRecord(
        url: defaultInstanceUrl,
        token: 't',
        role: 'User',
        active: true,
      ),
    );
    await tester.pumpWidget(
      AppScope(
        model: model,
        child: const MaterialApp(home: AlertsPage(scope: searchScaleTick)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Не прочитанные'), findsOneWidget);
    expect(find.text('Прочитать все'), findsOneWidget);
    expect(find.text('boom'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('DataPipeAlert'));
    await tester.pumpAndSettle();
    expect(find.text('unit | 1'), findsOneWidget);
    expect(api.marked, ['n-1']);
    expect(model.unreadCount, 0);
    await tester.tap(find.bySemanticsLabel('Закрыть'));
    await tester.pumpAndSettle();
    expect(find.text('unit | 1'), findsNothing);
  });

  testWidgets('a tap on the table leaves it open and close dismisses it', (
    tester,
  ) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async => null,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final api = _NoticeApi();
    final model = await _signedIn(api);
    await tester.pumpWidget(
      AppScope(
        model: model,
        child: const MaterialApp(home: AlertsPage(scope: searchScaleTick)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('DataPipeAlert'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Скопировать'));
    await tester.pumpAndSettle();
    expect(find.text('unit | 1'), findsOneWidget);
    await tester.tapAt(tester.getCenter(find.byType(AlertsPage)));
    await tester.pumpAndSettle();
    expect(find.text('unit | 1'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Закрыть'));
    await tester.pumpAndSettle();
    expect(find.text('unit | 1'), findsNothing);
  });

  testWidgets('a tap outside the table closes it', (tester) async {
    final api = _NoticeApi();
    final model = await _signedIn(api);
    await tester.pumpWidget(
      AppScope(
        model: model,
        child: const MaterialApp(home: AlertsPage(scope: searchScaleTick)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('DataPipeAlert'));
    await tester.pumpAndSettle();
    expect(find.text('unit | 1'), findsOneWidget);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.text('unit | 1'), findsNothing);
  });

  testWidgets('an integration log opens with line numbers and copy', (
    tester,
  ) async {
    final api = _NoticeApi(
      notice: const Notice(
        uuid: 'n-1',
        created: '2026-10-30T12:04:00Z',
        type: 'IntegrationTests',
        smallText: 'pytest',
        tableText: '',
        bigText: 'alpha\nbeta',
        isRead: false,
      ),
    );
    final model = await _signedIn(api);
    await tester.pumpWidget(
      AppScope(
        model: model,
        child: const MaterialApp(home: AlertsPage(scope: searchScaleTick)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('IntegrationTests'));
    await tester.pumpAndSettle();
    expect(find.text('Результаты тестов'), findsOneWidget);
    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('beta'), findsOneWidget);
    expect(find.bySemanticsLabel('Закрыть'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.bySemanticsLabel('Скопировать'), findsOneWidget);
    expect(find.byKey(const ValueKey('notice-sheet')), findsNothing);
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.text('alpha'), findsNothing);
    expect(api.marked, ['n-1']);
  });
}

Future<AppModel> _signedIn(_NoticeApi api) async {
  final model = AppModel(store: MemoryVaultStore(), api: (_) => api);
  await model.load();
  model.vault.instances.add(
    InstanceRecord(
      url: defaultInstanceUrl,
      token: 't',
      role: 'User',
      active: true,
    ),
  );
  return model;
}

class _NoticeApi extends PepeunitApi {
  _NoticeApi({this.notice = _pipe}) : super('https://devunit.pepeunit.com');

  static const _pipe = Notice(
    uuid: 'n-1',
    created: '2026-10-30T12:04:00Z',
    type: 'DataPipeAlert',
    smallText: 'boom',
    tableText: 'unit | 1',
    isRead: false,
  );

  final Notice notice;
  final marked = <String>[];

  @override
  Future<({int count, List<Notice> items})> notices({
    required String token,
    required int offset,
    required int limit,
    bool? isRead,
    List<String>? types,
  }) async {
    return (count: 1, items: [notice]);
  }

  @override
  Future<Notice> markNoticeRead(String token, String uuid) async {
    marked.add(uuid);
    return notice.copyWith(isRead: true);
  }
}
