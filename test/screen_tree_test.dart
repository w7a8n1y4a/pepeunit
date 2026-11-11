import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/features/code/code_modal.dart';
import 'package:pepeunit_client/hive/bevel.dart';
import 'package:pepeunit_client/hive/hex_scene.dart';
import 'package:pepeunit_client/features/units/units_chrome.dart';
import 'package:pepeunit_client/navigation/sections.dart';
import 'package:pepeunit_client/features/library/tip_modal.dart';
import 'package:pepeunit_client/features/library/tree_map.dart';
import 'package:pepeunit_client/features/library/tree_page.dart';
import 'package:pepeunit_client/features/library/tree_search.dart';
import 'package:pepeunit_client/library/tree_layout.dart';
import 'package:pepeunit_client/library/library.dart';
import 'package:pepeunit_client/library/screen_search.dart';
import 'package:pepeunit_client/library/screen_tree.dart';
import 'package:pepeunit_client/main.dart';

/// Routes of `lib/main.dart` with the pattern of the route that holds each,
/// read from the source. A `GoRoute` opens with its `path:`, and the router
/// nests a child inside the `routes:` of its parent, so the parentheses tell
/// who holds whom.
Map<String, String?> routerPatterns(String source) {
  final opens = <int, String>{
    for (final match in RegExp(
      r"GoRoute\(\s*path:\s*'([^']*)'",
    ).allMatches(source))
      match.start + 'GoRoute'.length: match.group(1)!,
  };
  final stack = <String?>[];
  final found = <String, String?>{};
  for (var at = 0; at < source.length; at++) {
    final char = source[at];
    if (char == '(') {
      final path = opens[at];
      if (path == null) {
        stack.add(null);
        continue;
      }
      final parent = stack.whereType<String>().lastOrNull;
      final full = path.startsWith('/')
          ? path
          : '${parent == '/' ? '' : parent}/$path';
      found[full] = parent;
      stack.add(full);
    } else if (char == ')') {
      if (stack.isNotEmpty) stack.removeLast();
    }
  }
  return found;
}

void main() {
  final screens = [
    for (final node in screenTree)
      if (!node.isCell) node,
  ];
  final cells = [
    for (final node in screenTree)
      if (node.isCell) node,
  ];

  group('the registry of screens', () {
    final routes = routerPatterns(File('lib/main.dart').readAsStringSync())
      ..remove('/:section');

    test('has a row for every route of the router, and no other', () {
      final rows = {for (final node in screens) node.path};
      expect(routes.length, greaterThan(60));
      expect(rows.difference(routes.keys.toSet()), isEmpty);
      expect(routes.keys.toSet().difference(rows), isEmpty);
      final all = {for (final node in screenTree) node.path};
      expect(all.length, screenTree.length, reason: 'a path is listed twice');
    });

    test('puts a screen under the screen that holds its route', () {
      for (final entry in routes.entries) {
        final expected = entry.value ?? (entry.key == '/' ? null : '/');
        expect(screenMap.parentPath(entry.key), expected, reason: entry.key);
      }
    });

    test('names every row in both languages', () {
      for (final node in screenTree) {
        expect(node.ru.trim(), isNotEmpty, reason: node.path);
        expect(node.en.trim(), isNotEmpty, reason: node.path);
        expect(node.title('en'), node.en);
        expect(node.title('ru'), node.ru);
      }
    });

    test('a screen with a parameter does not open from its address', () {
      for (final node in screens) {
        if (node.params.isNotEmpty) {
          expect(node.open, isFalse, reason: node.path);
        }
      }
    });

    test('reads the sections and parameters from the address', () {
      final io = screenMap.node('/units/:uuid/io/:io')!;
      expect(io.section, 'units');
      expect(io.params, ['uuid', 'io']);
      expect(screenMap.root.section, isEmpty);
      expect(screenMap.root.params, isEmpty);
    });

    test('walks from the home screen down to a screen', () {
      final trail = screenMap.trail('/units/:uuid/io/:io/pipe');
      expect(
        [for (final node in trail) node.path],
        [
          '/',
          '/units',
          '/units/:uuid',
          '/units/:uuid/io',
          '/units/:uuid/io/:io',
          '/units/:uuid/io/:io/pipe',
        ],
      );
      expect(screenMap.trail('/nowhere'), isEmpty);
      expect(screenMap.parentPath('/'), isNull);
      expect(screenMap.parentPath('/library'), '/');
      expect(
        [
          for (final node in screenMap.childrenOf('/library'))
            if (!node.isCell) node.path,
        ],
        [
          '/library/presentation',
          '/library/about',
          '/library/tools',
          '/library/docs',
          '/library/tree',
        ],
      );
    });

    test('has the sections of the home menu under the home screen', () {
      final sections = [
        for (final node in screenMap.childrenOf('/'))
          if (node.path != '/background-only') node.section,
      ];
      expect(sections.toSet(), {
        'people',
        'units',
        'peers',
        'registry',
        'dashboards',
        'alerts',
        'library',
      });
    });
  });

  group('the cells', () {
    test('every cell stands on a screen, under its own id', () {
      expect(cells.length, greaterThan(120));
      for (final cell in cells) {
        expect(cell.path, contains('#'), reason: cell.path);
        final screen = screenMap.node(cell.screenPath);
        expect(screen, isNotNull, reason: cell.path);
        expect(screen!.isCell, isFalse, reason: cell.path);
        expect(screenMap.parentPath(cell.path), cell.screenPath);
        expect(cell.open, isFalse, reason: cell.path);
        expect(cell.section, screen.section);
      }
      expect(screenMap.childrenOf('/units/new/updates').length, 3);
    });

    test('has a cell on the screens that are not only a list of cells', () {
      for (final path in [
        '/units/new',
        '/people/settings',
        '/peers/tune/:category',
      ]) {
        expect(
          screenMap.childrenOf(path).where((node) => node.isCell),
          isNotEmpty,
        );
      }
    });

    test('a row takes the tone and the need of the screen above it', () {
      expect(screenMap.toneOf('/units/:uuid/io/:io/pipe#clear'), 'danger');
      expect(screenMap.toneOf('/units/:uuid/io/:io/pipe#editor'), 'pipe');
      expect(screenMap.toneOf('/units/:uuid/io/:io/links#add'), 'link');
      expect(screenMap.toneOf('/library/about'), isNull);
      expect(screenMap.needOf('/library'), ScreenNeed.open);
      expect(screenMap.needOf('/units/new#create'), ScreenNeed.signedIn);
      expect(
        screenMap.needOf('/units/:uuid/settings#save'),
        ScreenNeed.creator,
      );
      expect(
        screenMap.needOf('/peers/tune/:category#reboot'),
        ScreenNeed.owner,
      );
    });

    test('the color of a row is the color of its tone or its section', () {
      Color of(String path) => treeColorOf(screenMap.node(path)!, screenMap);
      expect(of('/units/new#create'), addColor);
      expect(of('/units/:uuid/io/:io/pipe#clear'), errorColor);
      expect(of('/units/:uuid/io'), unitIoColor);
      expect(of('/units/:uuid/access'), accessColor);
      expect(of('/units/groups'), unitGroupsColor);
      expect(of('/units/:uuid'), unitsColor);
      expect(of('/library/about'), sectionById('library')!.color);
      expect(of('/'), sectionById('library')!.color);
    });
  });

  group('who may go where', () {
    bool at(
      String path, {
      bool target = true,
      bool signed = true,
      String? role,
      bool? grafana,
      bool? notifications,
    }) => treeAccess(
      screenMap.node(path)!,
      screenMap,
      hasTarget: target,
      signedIn: signed,
      role: role,
      grafana: grafana,
      notifications: notifications,
    );

    test('a visitor reaches the open sections and nothing else', () {
      expect(at('/', target: false, signed: false), isTrue);
      expect(at('/library/docs', target: false, signed: false), isTrue);
      expect(at('/people/login', target: false, signed: false), isTrue);
      expect(at('/people#signout', target: false, signed: false), isFalse);
      expect(at('/units', target: false, signed: false), isFalse);
      expect(at('/units/new#create', target: true, signed: false), isFalse);
      expect(at('/peers/users', target: true, signed: false), isFalse);
    });

    test('an account reaches its own sections, the roles reach more', () {
      expect(at('/units/new#create', role: 'User'), isTrue);
      expect(at('/units/:uuid/settings', role: 'User'), isTrue);
      expect(at('/peers/instance#block', role: 'User'), isFalse);
      expect(at('/peers/instance#block', role: 'Admin'), isTrue);
      expect(at('/peers/tune', role: 'Admin'), isFalse);
      expect(at('/peers/tune', role: 'Owner'), isTrue);
      expect(at('/peers/users/member#grant', role: 'Owner'), isTrue);
      expect(at('/peers/users/member#grant', role: 'Admin'), isFalse);
    });

    test('a section the instance does not serve stays closed', () {
      expect(at('/dashboards', grafana: false), isFalse);
      expect(at('/dashboards/new#create', grafana: false), isFalse);
      expect(at('/dashboards', grafana: true), isTrue);
      expect(at('/alerts', notifications: false), isFalse);
      expect(at('/alerts', notifications: true), isTrue);
    });
  });

  group('the round layout', () {
    final spots = radialTree(screenMap);
    final byPath = {for (final spot in spots) spot.node.path: spot};

    test('places every row once, a parent before its children', () {
      expect(spots.length, screenTree.length);
      expect(byPath.length, screenTree.length);
      final seen = <String>{};
      for (final spot in spots) {
        final parent = screenMap.parentPath(spot.node.path);
        if (parent != null) expect(seen, contains(parent));
        seen.add(spot.node.path);
      }
    });

    test('puts every row with nothing under it on the outer ring', () {
      expect(byPath['/']!.ring, 0);
      for (final spot in spots) {
        final kids = screenMap.childrenOf(spot.node.path);
        if (kids.isEmpty) {
          expect(spot.ring, 1, reason: spot.node.path);
          expect(spot.isLeaf, isTrue);
        } else if (spot.depth > 0) {
          expect(spot.ring, inExclusiveRange(0, 1), reason: spot.node.path);
        }
      }
      final deeper = byPath['/units/:uuid/io/:io']!;
      final upper = byPath['/units/:uuid']!;
      expect(deeper.ring, greaterThan(upper.ring));
      final point = byPath['/units/:uuid']!.at(100, 100);
      expect(
        point.distanceTo(const Point(0, 0)),
        closeTo(100 * upper.ring, 1e-9),
      );
      // An oval screen stretches the rings.
      final wide = byPath['/library/docs']!.at(200, 100);
      expect(wide.x.abs() / 200, lessThanOrEqualTo(1));
      expect(wide.y.abs() / 100, lessThanOrEqualTo(1));
    });

    test('last rows are spread evenly, sections are parted by a gap', () {
      final ends = [
        for (final spot in spots)
          if (spot.isLeaf) spot.angle,
      ]..sort();
      final steps = [
        for (var i = 1; i < ends.length; i++) ends[i] - ends[i - 1],
      ];
      final unit = steps.reduce(min);
      expect(unit, greaterThan(0));
      var gaps = 0;
      for (final step in steps) {
        if (step > unit * 1.5) {
          gaps++;
          expect(step, closeTo(unit * 3, 1e-6));
        } else {
          expect(step, closeTo(unit, 1e-6));
        }
      }
      expect(gaps, 6, reason: 'seven sections have six gaps between them');
    });

    test('keeps the sections in the order of the home menu', () {
      final angles = [
        for (final node in screenMap.childrenOf('/')) byPath[node.path]!.angle,
      ];
      expect([...angles]..sort(), angles);
    });

    test('the outline lists every row with its address', () {
      final text = treeOutline('ru', screenMap);
      expect(text.split('\n').length, screenTree.length);
      expect(text, startsWith('- Главная `/`\n  - Аккаунт `/people`'));
      expect(
        text,
        contains('\n        - Вход или выход `/units/:uuid/io/:io`'),
      );
      expect(treeOutline('en', screenMap), contains('- Library `/library`'));
    });
  });

  group('the path search', () {
    List<String> find(String query, {int limit = 200, String language = 'ru'}) =>
        [
          for (final node in searchScreens(
            screenMap,
            query,
            limit: limit,
            language: language,
          ))
            node.path,
        ];

    test('an empty query finds nothing', () {
      expect(find(''), isEmpty);
      expect(find('   '), isEmpty);
      expect(find('нет-такого-экрана'), isEmpty);
    });

    test('a name in either language finds its row', () {
      expect(find('документация').first, '/library/docs');
      expect(find('Documentation').first, '/library/docs');
      expect(find('дерево 6').first, '/library/tree');
      expect(find('Peer search').first, '/peers/search');
    });

    test('the address finds a row too', () {
      expect(find('/peers/tune'), contains('/peers/tune'));
      expect(find(':uuid/io/:io/pipe'), contains('/units/:uuid/io/:io/pipe'));
    });

    test('every word must meet, and a cell takes the names of its screen', () {
      expect(find('новый аппарат создать'), contains('/units/new#create'));
      expect(find('новый аппарат zzz'), isEmpty);
    });

    test('the nearest row to the home screen comes first', () {
      final rows = find('аппарат');
      expect(rows.first, '/units');
      final depths = [
        for (final path in rows) screenMap.trail(path).length,
      ];
      expect([...depths]..sort(), depths);
      expect(find('аппарат', limit: 3).length, 3);
    });

    test('rows at one distance go alphabetically in the language', () {
      final map = ScreenMap(const [
        ScreenNode('/', ScreenKind.menu, 'Главная', 'Home', open: true),
        ScreenNode('/b', ScreenKind.menu, 'Тест б', 'Test z'),
        ScreenNode('/a', ScreenKind.menu, 'Тест а', 'Test y'),
        ScreenNode('/a/c', ScreenKind.form, 'Тест в', 'Test e'),
        ScreenNode('/a#k', ScreenKind.cell, 'Тест г', 'Test d'),
      ]);
      expect(
        [for (final node in searchScreens(map, 'тест')) node.path],
        ['/a', '/b', '/a/c', '/a#k'],
      );
      expect(
        [
          for (final node in searchScreens(map, 'test', language: 'en'))
            node.path,
        ],
        ['/a', '/b', '/a#k', '/a/c'],
      );
    });

    test('the way to a row is the names of its trail', () {
      expect(
        screenRouteText('ru', screenMap, '/library/tree'),
        'Главная › Библиотека › Дерево 6 путей',
      );
      expect(
        screenRouteText('en', screenMap, '/library/docs'),
        'Home › Library › Documentation',
      );
      expect(screenRouteText('ru', screenMap, '/nowhere'), isEmpty);
    });
  });

  group('the page of the tree', () {
    test('the address keeps the picked row', () {
      expect(treeLocation('/'), '/library/tree');
      final location = Uri.parse(treeLocation('/units/:uuid/io'));
      expect(location.path, '/library/tree');
      expect(location.queryParameters, {'node': '/units/:uuid/io'});
      final cell = Uri.parse(treeLocation('/units/new#create'));
      expect(cell.queryParameters, {'node': '/units/new#create'});
    });

    test('the card is a few lines', () {
      final screen = treeCardText(
        'ru',
        screenMap.node('/units/:uuid/io/:io')!,
        screenMap,
        available: false,
      );
      expect(screen, startsWith('`/units/:uuid/io/:io`'));
      expect(screen, contains('Вид: Меню'));
      expect(
        screen,
        contains('Путь: Главная › Аппараты › Аппарат › Входы и выходы › Вход'),
      );
      expect(screen, contains('Доступ: нет, нужен вход'));
      expect(screen, contains('Открывается только через родителя'));
      final cell = treeCardText(
        'ru',
        screenMap.node('/units/new#create')!,
        screenMap,
        available: true,
      );
      expect(cell, contains('Вид: Сота'));
      expect(cell, contains('На экране: Новый аппарат'));
      expect(cell, contains('Доступ: есть'));
      expect(cell, isNot(contains('Открывается')));
      final open = treeCardText(
        'en',
        screenMap.node('/library')!,
        screenMap,
        available: true,
      );
      expect(open, contains('Access: yes'));
      expect(open, contains('Inside: Presentation'));
      expect(open.split('\n').length, lessThan(8));
    });

    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(Library.instance.load);
      final model = AppModel(store: MemoryVaultStore());
      await model.load();
      await tester.pumpWidget(
        AppScope(model: model, child: const PepeunitApp(background: false)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Библиотека'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Дерево 6 путей'));
      await tester.pumpAndSettle();
    }

    testWidgets('fills the screen, a tap opens a small card', (tester) async {
      await open(tester);
      expect(find.byType(TreePage), findsOneWidget);
      expect(find.byType(ScreenTreeMap), findsOneWidget);
      expect(find.byType(CodeModal), findsNothing, reason: 'no frame');
      final map = tester.getRect(find.byType(ScreenTreeMap));
      expect(map.size, const Size(1000, 800));
      expect(find.byType(TipModal), findsNothing);

      final state = tester.state<ScreenTreeMapState>(
        find.byType(ScreenTreeMap),
      );
      expect(state.controller.value.getMaxScaleOnAxis(), lessThan(1));
      await tester.tapAt(map.center);
      await tester.pumpAndSettle();
      expect(find.byType(TipModal), findsOneWidget);
      expect(find.text('Главная'), findsWidgets);
      expect(find.text('Открыть'), findsOneWidget);
      expect(find.text('Адрес'), findsNothing);
      final card = tester.getRect(find.byType(BevelFrame).last);
      expect(card.height, lessThan(map.height * 0.6));
      await tester.tapAt(const Offset(5, 795));
      await tester.pumpAndSettle();
      expect(find.byType(TipModal), findsNothing);

      // Close leaves the tree for the Library.
      await tester.tap(find.bySemanticsLabel('Закрыть'));
      await tester.pumpAndSettle();
      expect(find.byType(TreePage), findsNothing);
      expect(find.bySemanticsLabel('Дерево 6 путей'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the search modal picks a row, shows its way, no card', (
      tester,
    ) async {
      await open(tester);
      final state = tester.state<ScreenTreeMapState>(
        find.byType(ScreenTreeMap),
      );
      final far = state.controller.value.getMaxScaleOnAxis();
      expect(find.byType(TreeSearchPanel), findsNothing);
      await tester.tap(find.bySemanticsLabel('Поиск пути'));
      await tester.pumpAndSettle();
      expect(find.byType(TreeSearchPanel), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'документация');
      await tester.pumpAndSettle();
      final row = find.bySemanticsLabel('Документация');
      expect(row, findsOneWidget);
      expect(find.text('Главная › Библиотека › Документация'), findsOneWidget);
      await tester.tap(row);
      await tester.pumpAndSettle();
      // The modal is closed, the card is not opened, the way is named.
      expect(find.byType(TreeSearchPanel), findsNothing);
      expect(find.byType(TipModal), findsNothing);
      expect(find.text('Главная › Библиотека › Документация'), findsOneWidget);
      expect(
        state.controller.value.getMaxScaleOnAxis(),
        greaterThan(far * 4.9),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the search modal says when nothing answers, and closes', (
      tester,
    ) async {
      await open(tester);
      await tester.tap(find.bySemanticsLabel('Поиск пути'));
      await tester.pumpAndSettle();
      expect(find.text('Введите название соты или адрес'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'zzzzzz');
      await tester.pumpAndSettle();
      expect(find.textContaining('Ничего не найдено'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Закрыть поиск'));
      await tester.pumpAndSettle();
      expect(find.byType(TreeSearchPanel), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the switch keeps the available or the closed rows', (
      tester,
    ) async {
      await open(tester);
      final total = screenTree.length;
      expect(find.text('Все $total'), findsOneWidget);
      // No instance is chosen: every section but the open ones is closed.
      final map = tester.getRect(find.byType(ScreenTreeMap));
      final yes = find.textContaining(RegExp(r'^Доступные \d+$'));
      final no = find.textContaining(RegExp(r'^Недоступные \d+$'));
      expect(yes, findsOneWidget);
      expect(no, findsOneWidget);
      await tester.tap(no);
      await tester.pumpAndSettle();
      // The home screen is open, so it is faded and a tap there picks nothing.
      await tester.tapAt(map.center);
      await tester.pumpAndSettle();
      expect(find.byType(TipModal), findsNothing);
      await tester.tap(yes);
      await tester.pumpAndSettle();
      await tester.tapAt(map.center);
      await tester.pumpAndSettle();
      expect(find.byType(TipModal), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
