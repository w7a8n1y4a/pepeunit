import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/hive/marks.dart';
import 'package:url_launcher/link.dart';
import 'package:pepeunit_client/features/network/line_cell.dart';
import 'package:pepeunit_client/registry/repo.dart';
import 'package:pepeunit_client/features/registry/registry_chrome.dart';
import 'package:pepeunit_client/hive/hint.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/features/network/instance_page.dart';
import 'package:pepeunit_client/features/network/network_chrome.dart';
import 'package:pepeunit_client/hive/hex_scene.dart';
import 'package:pepeunit_client/instances/instance.dart';
import 'package:pepeunit_client/instances/portrait.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  String? clipboard;
  setUp(() {
    clipboard = null;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard = (call.arguments as Map)['text'] as String;
        }
        return null;
      },
    );
  });
  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  Future<void> showCell(WidgetTester tester, MetricsCell cell) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: SizedBox.square(dimension: 240, child: cell)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> copySelection(WidgetTester tester) async {
    final selection = tester.state<SelectableRegionState>(
      find.byType(SelectableRegion),
    );
    selection.selectAll(SelectionChangedCause.keyboard);
    await tester.pump();
    selection.contextMenuButtonItems
        .firstWhere((item) => item.type == ContextMenuButtonType.copy)
        .onPressed!();
    await tester.pump();
  }

  testWidgets('selection copies only the active summary page', (tester) async {
    await showCell(
      tester,
      const MetricsCell(
        lines: ['fallback'],
        pages: [
          SummaryPage(title: 'Metrics', lines: ['Users 12', 'Units 34']),
          SummaryPage(title: 'Status', lines: ['Ready', 'Ping 5 ms']),
        ],
      ),
    );
    expect(find.bySemanticsLabel('Copy'), findsNothing);
    await copySelection(tester);
    expect(clipboard, 'Users 12\nUnits 34');
    await tester.tap(find.bySemanticsLabel('Next'));
    await tester.pumpAndSettle();
    await copySelection(tester);
    expect(clipboard, 'Ready\nPing 5 ms');
    await tester.tap(find.bySemanticsLabel('Previous'));
    await tester.pumpAndSettle();
    await copySelection(tester);
    expect(clipboard, 'Users 12\nUnits 34');
  });

  testWidgets('a single-page summary supports copying selected text', (
    tester,
  ) async {
    await showCell(
      tester,
      const MetricsCell(lines: ['Device abc123', 'Target def456']),
    );
    expect(find.bySemanticsLabel('Copy'), findsNothing);
    await copySelection(tester);
    expect(clipboard, 'Device abc123\nTarget def456');
  });

  testWidgets('a touch hold selects summary text instead of opening its hint', (
    tester,
  ) async {
    var hints = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HintHost(
            has: (_, _) => true,
            open: (_, _, _, _) => hints++,
            child: const Center(
              child: SizedBox.square(
                dimension: 240,
                child: HintTarget(
                  id: 'summary',
                  title: 'Summary',
                  color: Colors.orange,
                  child: MetricsCell(lines: ['Selectable summary']),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.longPress(find.text('Selectable summary'));
    await tester.pumpAndSettle();
    expect(hints, 0);
    tester
        .state<SelectableRegionState>(find.byType(SelectableRegion))
        .contextMenuButtonItems
        .firstWhere((item) => item.type == ContextMenuButtonType.copy)
        .onPressed!();
    await tester.pump();
    expect(clipboard, isNotEmpty);
  });

  testWidgets('full repo errors wrap and scroll within the cell', (
    tester,
  ) async {
    final error = 'Failed to synchronize repository: ${'long-path/' * 40}\nEND';
    final repo = RegistryRepo.fromJson({'sync_error': error});
    final page = repoSummaries(repo, 'en').firstWhere((p) => p.title == 'Sync');
    expect(page.lines, [error]);
    await showCell(tester, MetricsCell(lines: page.lines));

    final textSize = tester.getSize(find.text(error));
    expect(textSize.width, lessThanOrEqualTo(240 * 0.7));
    expect(textSize.height, greaterThan(240));
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable));
    expect(scroll.position.maxScrollExtent, greaterThan(0));
    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
    expect(scroll.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
    await copySelection(tester);
    expect(clipboard, error);
  });

  testWidgets('the first repo line is a selectable link in the section color', (
    tester,
  ) async {
    const url = 'https://gitlab.com/pepe/unit.git';
    final repo = RegistryRepo.fromJson({
      'repository_url': url,
      'platform': 'Gitlab',
      'is_public_repository': true,
    });
    final pages = repoSummaries(repo, 'ru');
    expect(pages, hasLength(1));
    final launches = <MethodCall>[];
    const channel = MethodChannel('plugins.flutter.io/url_launcher');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
      call,
    ) async {
      launches.add(call);
      return true;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    await showCell(
      tester,
      MetricsCell(
        lines: const [],
        linkColor: registryColor,
        pages: [
          for (final page in pages)
            SummaryPage(
              title: page.title,
              lines: page.lines,
              firstLineUrl: page.firstLineUrl,
            ),
        ],
      ),
    );
    expect(find.text(url), findsNothing);
    expect(find.bySemanticsLabel('Copy'), findsNothing);
    final label = pages.first.lines.first;
    expect(label, 'Публичный · Гитлаб');
    final text = tester.widget<Text>(find.text(label));
    expect(text.style?.color, registryColor);
    expect(text.style?.decoration, TextDecoration.none);
    final linkStyle = tester
        .widget<RichText>(
          find.descendant(
            of: find.text(label),
            matching: find.byType(RichText),
          ),
        )
        .text
        .style!;
    final plainStyle = tester
        .widget<RichText>(
          find.descendant(
            of: find.text(pages.first.lines.last),
            matching: find.byType(RichText),
          ),
        )
        .text
        .style!;
    expect(linkStyle.copyWith(color: plainStyle.color), plainStyle);
    expect(tester.widget<Link>(find.byType(Link)).target, LinkTarget.blank);
    await copySelection(tester);
    expect(clipboard, pages.first.lines.join('\n'));
    expect(launches, isEmpty);
    await tester.tap(find.text(pages.first.lines.last));
    await tester.pump();
    expect(launches, isEmpty);
    final drag = await tester.startGesture(
      tester.getTopLeft(find.text(label)) + const Offset(1, 5),
      kind: PointerDeviceKind.mouse,
    );
    await drag.moveTo(tester.getBottomRight(find.text(pages.first.lines.last)));
    await drag.up();
    await tester.pump();
    expect(launches, isEmpty);
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
    expect(launches.single.arguments['url'], url);
    expect(launches.single.arguments['useWebView'], isFalse);
  });

  testWidgets(
    'instance summary omits UnitIO and pins its address above the rule',
    (tester) async {
      await (FontLoader(
            'OpenGost Type B',
          )..addFont(rootBundle.load('assets/fonts/OpenGostTypeB-Regular.ttf')))
          .load();
      final model = AppModel(store: MemoryVaultStore());
      await model.load();
      model.portraits[devInstanceUrl] = const InstancePortrait(
        url: devInstanceUrl,
        users: 12,
        units: 34,
        repos: 56,
        unitIos: 78,
        email: 'contact@example.com',
      );
      final launches = <MethodCall>[];
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        launches.add(call);
        return true;
      });
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        ),
      );
      await tester.pumpWidget(
        AppScope(
          model: model,
          child: const MaterialApp(home: InstancePage(url: devInstanceUrl)),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('UnitIO'), findsNothing);
      final address = find.textContaining('Адрес');
      final text = tester.widget<Text>(address);
      expect(text.style?.color, networkColor);
      expect(text.style?.decoration, TextDecoration.none);
      final copyIcon = find.descendant(
        of: find.byType(MetricsCell),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is CopyMarkPainter,
        ),
      );
      expect(
        tester.getSize(copyIcon).height,
        closeTo(text.style!.fontSize! * 1000 / 1700, 0.01),
      );
      final paragraph = tester.renderObject<RenderParagraph>(
        find.descendant(of: address, matching: find.byType(RichText)),
      );
      final letter = paragraph
          .getBoxesForSelection(
            const TextSelection(baseOffset: 1, extentOffset: 2),
          )
          .single;
      expect(
        tester.getTopRight(copyIcon).dx,
        lessThan(paragraph.localToGlobal(Offset(letter.left, 0)).dx),
      );
      final metrics = TextPainter(
        text: TextSpan(text: 'Адрес', style: paragraph.text.style),
        textDirection: paragraph.textDirection,
        textScaler: paragraph.textScaler,
      )..layout();
      final baseline = paragraph
          .localToGlobal(
            Offset(0, metrics.computeLineMetrics().single.baseline),
          )
          .dy;
      metrics.dispose();
      expect(tester.getBottomLeft(copyIcon).dy, closeTo(baseline, 0.01));
      final rule = find.descendant(
        of: find.byType(MetricsCell),
        matching: find.byWidgetPredicate(
          (widget) => widget is Container && widget.color == hexMuted,
        ),
      );
      expect(
        tester.getBottomLeft(address).dy,
        lessThanOrEqualTo(tester.getTopLeft(rule).dy),
      );
      expect(
        tester.getTopLeft(address).dy,
        greaterThan(tester.getTopLeft(find.byType(MetricsCell)).dy),
      );
      await copySelection(tester);
      expect(clipboard, 'Юзеры 12\nАппараты 34\nРепозитории 56');
      await tester.tap(address);
      await tester.pumpAndSettle();
      expect(clipboard, devInstanceUrl);
      expect(launches, isEmpty);
      const copiedColor = Color(0xFF4CAF50);
      expect(tester.widget<Text>(address).style?.color, copiedColor);
      expect(
        (tester.widget<CustomPaint>(copyIcon).painter as CopyMarkPainter).color,
        copiedColor,
      );
      await tester.pump(const Duration(seconds: 1));
      expect(tester.widget<Text>(address).style?.color, networkColor);
      expect(
        (tester.widget<CustomPaint>(copyIcon).painter as CopyMarkPainter).color,
        networkColor,
      );
      clipboard = null;
      await tester.tap(copyIcon);
      await tester.pump();
      expect(clipboard, devInstanceUrl);
      expect(tester.widget<Text>(address).style?.color, copiedColor);
      await tester.tap(find.bySemanticsLabel('Следующая сводка'));
      await tester.pumpAndSettle();
      expect(address, findsNothing);
      expect(find.text('contact@example.com'), findsOneWidget);
    },
  );
}
