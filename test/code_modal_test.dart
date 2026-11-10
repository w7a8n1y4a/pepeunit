import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/features/code/code_highlight.dart';
import 'package:pepeunit_client/features/code/code_modal.dart';
import 'package:pepeunit_client/features/code/code_view.dart';
import 'package:pepeunit_client/features/network/network_chrome.dart';
import 'package:pepeunit_client/features/units/name_pick_page.dart';
import 'package:pepeunit_client/instances/instance.dart';
import 'package:pepeunit_client/navigation/pick.dart';
import 'package:pepeunit_client/units/code_format.dart';

void main() {
  test('json is indented by four, base64 is read only when asked to', () {
    expect(prettyJson('{"a":[1]}'), '{\n    "a": [\n        1\n    ]\n}');
    expect(prettyJson('plain'), isNull);
    expect(prettyJson('{broken'), isNull);
    expect(
      decodeBase64Text(base64.encode(utf8.encode('hello from pepeunit'))),
      'hello from pepeunit',
    );
    expect(decodeBase64Text('short'), isNull);
  });

  test('the language is sniffed from the text', () {
    expect(codeSniff('{"a": 1}'), CodeLanguage.json);
    expect(codeSniff('  [1, 2]'), CodeLanguage.json);
    expect(codeSniff('---\nname: x'), CodeLanguage.yaml);
    expect(codeSniff('name: x\nlist:\n  - 1'), CodeLanguage.yaml);
    expect(codeSniff('note: one line'), CodeLanguage.plain);
    expect(codeSniff('plain text\nsecond'), CodeLanguage.plain);
  });

  Future<void> open(
    WidgetTester tester, {
    required Widget Function(BuildContext) home,
  }) async {
    final model = AppModel(store: MemoryVaultStore());
    await model.load();
    await tester.pumpWidget(
      AppScope(
        model: model,
        child: MaterialApp(
          home: Scaffold(body: Builder(builder: home)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('one frame: title, tools in a fixed order, numbered rows, note', (
    tester,
  ) async {
    await open(
      tester,
      home: (context) => CodeModal(
        title: 'Value',
        color: Colors.orange,
        onClose: () {},
        text: '{\n    "a": 1\n}',
        copy: () => '',
        onDownload: () {},
        note: 'broken',
        body: (_, layout) => CodeView(layout: layout!),
      ),
    );
    expect(find.text('Value'), findsOneWidget);
    expect(find.text('broken'), findsOneWidget);
    for (final number in ['1', '2', '3']) {
      expect(find.text(number), findsOneWidget);
    }
    final download = tester.getCenter(find.bySemanticsLabel('Скачать'));
    final copy = tester.getCenter(find.bySemanticsLabel('Скопировать'));
    final close = tester.getCenter(find.bySemanticsLabel('Закрыть'));
    expect(download.dx, lessThan(copy.dx));
    expect(copy.dx, lessThan(close.dx));
    expect(download.dy, closeTo(close.dy, 0.5));
    // The note is the lowest thing in the frame.
    expect(
      tester.getTopLeft(find.text('broken')).dy,
      greaterThan(tester.getBottomLeft(find.text('3')).dy),
    );
  });

  testWidgets('a long line wraps and keeps its one number', (tester) async {
    tester.view.physicalSize = const Size(600, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final text = 'short\n${'x' * 400}\nlast';
    await open(
      tester,
      home: (context) => CodeModal(
        title: 'Value',
        color: Colors.orange,
        onClose: () {},
        text: text,
        copy: () => text,
        body: (_, layout) => CodeView(layout: layout!),
      ),
    );
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('4'), findsNothing);
    final wrapped = tester.getSize(find.text('x' * 400)).height;
    final one = tester.getSize(find.text('short')).height;
    expect(wrapped, greaterThan(one * 1.5));
    expect(
      tester.getTopLeft(find.text('last')).dy -
          tester.getTopLeft(find.text('3')).dy,
      closeTo(0, 1),
    );
  });

  testWidgets('a log keeps the newest row at the bottom and asks for more', (
    tester,
  ) async {
    var asked = 0;
    await open(
      tester,
      home: (context) => SizedBox(
        height: 300,
        child: LogView(
          count: 3,
          fontSize: 12,
          canLoadOlder: true,
          onOlder: () => asked++,
          itemBuilder: (context, index) => Text('row $index'),
        ),
      ),
    );
    expect(
      tester.getTopLeft(find.text('row 0')).dy,
      greaterThan(tester.getTopLeft(find.text('row 2')).dy),
    );
    // Three rows do not fill the panel, so the older page is asked for.
    expect(asked, greaterThan(0));
  });

  test(
    'a pick answers the opener, typed, and a new pick closes the old',
    () async {
      final model = AppModel(store: MemoryVaultStore());
      final first = model.beginPick<String>();
      expect(model.pickOpen, isTrue);
      model.finishPick('main');
      expect(await first, 'main');
      expect(model.pickOpen, isFalse);
      final stale = model.beginPick<String>();
      final next = model.beginPick<String>();
      expect(await stale, isNull);
      model.finishPick(7);
      expect(await next, isNull);
    },
  );

  testWidgets('a pick survives a change of scale and asks only once', (
    tester,
  ) async {
    final model = AppModel(store: MemoryVaultStore());
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
    var loads = 0;
    String? answer;
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: Column(
              children: [
                TextButton(
                  onPressed: () async =>
                      answer = await openPick<String>(context, '/pick'),
                  child: const Text('open'),
                ),
                Text('answer-${answer ?? ''}'),
              ],
            ),
          ),
          routes: [
            GoRoute(
              path: 'pick',
              builder: (context, state) => NamePickPage(
                title: 'Branch',
                scope: scaleTickOf(state.uri),
                path: '/pick',
                load: () async {
                  loads++;
                  return [
                    for (var i = 0; i < 12; i++) (id: 'b$i', label: 'b$i'),
                  ];
                },
              ),
            ),
          ],
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
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(loads, 1);
    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(12, 12),
        scrollDelta: Offset(0, -40),
      ),
    );
    await tester.pumpAndSettle();
    expect(router.state.uri.queryParameters['scope'], '2');
    expect(loads, 1);
    await tester.tap(find.bySemanticsLabel('b0'));
    await tester.pumpAndSettle();
    expect(model.pickOpen, isFalse);
    expect(find.text('open'), findsOneWidget);
    expect(answer, 'b0');
  });
}
