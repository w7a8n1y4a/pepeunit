import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/features/code/code_modal.dart';
import 'package:pepeunit_client/features/hex_page.dart';
import 'package:pepeunit_client/hive/hex_scene.dart';

Widget backPage(VoidCallback onBack, {bool enabled = true}) => HexPage(
  slots: [
    HexSlot(
      id: 'back',
      title: 'Back',
      color: Colors.white,
      q: 0,
      r: 0,
      enabled: enabled,
      icon: 'assets/icons/actions/back.svg',
    ),
  ],
  onTap: (_) => onBack(),
);

Widget closeButton(VoidCallback onClose, {Key? key}) =>
    CodeCloseMark(key: key, label: 'Close', extent: 48, onTap: onClose);

Future<void> open(WidgetTester tester, Widget child) async {
  final model = AppModel(store: MemoryVaultStore());
  await model.load();
  await tester.pumpWidget(
    AppScope(
      model: model,
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Escape calls Back even while a field has focus', (tester) async {
    var back = 0;
    await open(
      tester,
      Stack(
        children: [
          backPage(() => back++),
          const Align(
            alignment: Alignment.topCenter,
            child: TextField(autofocus: true),
          ),
        ],
      ),
    );
    await tester.enterText(find.byType(TextField), 'editing');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(back, 1);
  });

  testWidgets('Escape closes the editor before Back and ignores key repeat', (
    tester,
  ) async {
    var editing = true;
    var closed = 0;
    var back = 0;
    await open(
      tester,
      StatefulBuilder(
        builder: (context, setState) => Stack(
          children: [
            backPage(() => back++),
            if (editing)
              CodeModal(
                title: 'Editor',
                color: Colors.green,
                onClose: () => setState(() {
                  editing = false;
                  closed++;
                }),
                copy: () => '',
                body: (_, _) => const TextField(autofocus: true),
              ),
          ],
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'unsaved');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(closed, 1);
    expect(back, 0);
    expect(find.byType(CodeModal), findsNothing);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.escape);
    expect(back, 0);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(back, 1);
  });

  testWidgets('frontmost Close wins even if an underlying button remounts', (
    tester,
  ) async {
    var pageCloses = 0;
    var modalCloses = 0;
    var generation = 0;
    var modal = true;
    late StateSetter rebuild;
    await open(
      tester,
      StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return Stack(
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: closeButton(
                  () => pageCloses++,
                  key: ValueKey(generation),
                ),
              ),
              if (modal)
                Align(
                  alignment: Alignment.topRight,
                  child: closeButton(
                    () => setState(() {
                      modal = false;
                      modalCloses++;
                    }),
                  ),
                ),
            ],
          );
        },
      ),
    );
    rebuild(() => generation++);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(modalCloses, 1);
    expect(pageCloses, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(pageCloses, 1);
  });

  testWidgets('offstage Close and a disabled Back cannot handle Escape', (
    tester,
  ) async {
    var closes = 0;
    var backs = 0;
    await open(
      tester,
      Stack(
        children: [
          backPage(() => backs++, enabled: false),
          Offstage(child: closeButton(() => closes++)),
        ],
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(closes, 0);
    expect(backs, 0);
  });

  testWidgets(
    'only the current route responds, then the previous one resumes',
    (tester) async {
      var closes = 0;
      var backs = 0;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(body: closeButton(() => closes++)),
          ),
          GoRoute(
            path: '/next',
            builder: (context, _) => backPage(() {
              backs++;
              context.pop();
            }),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      router.push('/next');
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(backs, 1);
      expect(closes, 0);
      expect(router.state.uri.path, '/');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(closes, 1);
    },
  );

  testWidgets('a dialog closes without also invoking the underlying Back', (
    tester,
  ) async {
    var backs = 0;
    var closes = 0;
    late BuildContext page;
    await open(
      tester,
      Builder(
        builder: (context) {
          page = context;
          return backPage(() => backs++);
        },
      ),
    );
    showDialog<void>(
      context: page,
      builder: (context) => Dialog(
        child: closeButton(() {
          closes++;
          Navigator.of(context).pop();
        }),
      ),
    );
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(closes, 1);
    expect(backs, 0);
    expect(find.byType(Dialog), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(backs, 1);
  });
}
