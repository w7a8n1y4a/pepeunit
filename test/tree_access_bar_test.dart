import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/features/library/tree_access_bar.dart';
import 'package:pepeunit_client/features/library/tree_map.dart';
import 'package:pepeunit_client/library/screen_tree.dart';

void main() {
  const roles = {
    'Bot': ('Бот', 'Bot'),
    'User': ('Пользователь', 'User'),
    'Admin': ('Админ', 'Admin'),
    'Owner': ('Владелец', 'Owner'),
  };
  for (final language in ['ru', 'en']) {
    for (final entry in roles.entries) {
      testWidgets('${entry.key} is translated and fits a phone in $language', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final label = language == 'ru' ? entry.value.$1 : entry.value.$2;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TreeAccessBar(
                    language: language,
                    role: entry.key,
                    available: 75,
                    total: 100,
                    font: 12,
                  ),
                ),
              ),
            ),
          ),
        );
        final progress = find.byType(LinearProgressIndicator);
        expect(tester.widget<LinearProgressIndicator>(progress).value, 0.75);
        expect(find.text(label), findsOneWidget);
        expect(find.text('75 / 100'), findsOneWidget);
        expect(
          tester.getRect(find.text(label)).right,
          lessThan(tester.getRect(progress).left),
        );
        expect(tester.getRect(progress).right, lessThanOrEqualTo(304));
        final semantics = tester.ensureSemantics();
        final title = language == 'ru' ? 'Доступность' : 'Availability';
        expect(
          tester.getSemantics(find.bySemanticsLabel(title)).value,
          contains(label),
        );
        expect(
          tester.getSemantics(find.bySemanticsLabel(title)).value,
          contains('25'),
        );
        semantics.dispose();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('an empty map has a determinate empty bar', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TreeAccessBar(
          language: 'en',
          role: 'Bot',
          available: 0,
          total: 0,
          font: 12,
        ),
      ),
    );
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      0,
    );
    expect(find.text('0 / 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('replacing a map updates the existing canvas layout', (
    tester,
  ) async {
    final first = ScreenMap(const [
      ScreenNode('/', ScreenKind.menu, 'Главная', 'Home'),
      ScreenNode('/first', ScreenKind.menu, 'Первый', 'First'),
    ]);
    final second = ScreenMap(const [
      ScreenNode('/', ScreenKind.menu, 'Главная', 'Home'),
      ScreenNode('/second', ScreenKind.menu, 'Второй', 'Second'),
      ScreenNode('/second/child', ScreenKind.menu, 'Внутри', 'Child'),
    ]);
    Future<void> open(ScreenMap map) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ScreenTreeMap(
            map: map,
            language: 'en',
            selected: null,
            available: {for (final node in map.nodes) node.path},
            onSelect: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await open(first);
    final state = tester.state<ScreenTreeMapState>(find.byType(ScreenTreeMap));
    final scale = state.controller.value.getMaxScaleOnAxis();
    await open(second);
    expect(
      tester.state<ScreenTreeMapState>(find.byType(ScreenTreeMap)),
      same(state),
    );
    state.focus('/second/child');
    await tester.pumpAndSettle();
    expect(
      state.controller.value.getMaxScaleOnAxis(),
      greaterThan(scale * 4.9),
    );
    expect(tester.takeException(), isNull);
  });
}
