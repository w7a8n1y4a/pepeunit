import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pepeunit_client/features/network/network_chrome.dart';
import 'package:pepeunit_client/hive/hex_order.dart';

void main() {
  test('ticks add three cells and an error may use one more', () {
    expect(scaleTickCells(1), 7);
    expect(scaleTickCells(2), 10);
    expect(scaleTickCells(3), 13);
    expect(scaleTickCells(4), 16);
    expect(scaleTickCells(5), 19);
    expect(hexBudget(13), hexDisk(2).take(13));
    expect(hexBudget(13, wide: true), hexDisk(2, wide: true).take(13));
    expect(errorBudget(4), 7);
    expect(errorBudget(7), 10);
    expect(errorBudget(13), 16);
    expect(errorBudget(19), 22);
    expect(scaleTickOf(Uri.parse('/x')), menuScaleTick);
    expect(
      scaleTickOf(Uri.parse('/peers/search'), fallback: searchScaleTick),
      searchScaleTick,
    );
    expect(scaleTickOf(Uri.parse('/x?scope=4')), 4);
    expect(scaleTickOf(Uri.parse('/x?scope=9')), scaleTickMax);
    expect(scaleTickOf(Uri.parse('/x?scope=0')), scaleTickMin);
    final full = hexFrame(count: 6, back: HexBack.center, cells: 7);
    final taken = [full.back!, ...full.cells];
    final spot = [
      for (final cell in hexBudget(errorBudget(taken.length)))
        if (!taken.contains(cell)) cell,
    ].first;
    expect(hexBudget(10).contains(spot), isTrue);
    expect(hexBudget(7).contains(spot), isFalse);
  });

  testWidgets('wheel away from a cell still steps the tick', (tester) async {
    final router = GoRouter(
      initialLocation: '/x?scope=3',
      routes: [
        GoRoute(
          path: '/x',
          builder: (context, state) {
            final tick = scaleTickOf(state.uri, fallback: searchScaleTick);
            return ScopeFrame(
              scope: tick,
              canZoomIn: tick < scaleTickMax,
              path: '/x',
              child: Stack(
                children: [
                  Positioned(
                    left: 200,
                    top: 200,
                    width: 48,
                    height: 48,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                      child: const ColoredBox(color: Color(0xFFFFFFFF)),
                    ),
                  ),
                  Positioned(right: 8, bottom: 8, child: Text('tick-$tick')),
                ],
              ),
            );
          },
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    expect(find.text('tick-3'), findsOneWidget);

    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(12, 12),
        scrollDelta: Offset(0, 40),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('tick-2'), findsOneWidget);

    await tester.sendEventToBinding(
      const PointerScrollEvent(
        position: Offset(220, 220),
        scrollDelta: Offset(0, -40),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('tick-3'), findsOneWidget);

    final left = await tester.startGesture(const Offset(20, 80));
    final right = await tester.startGesture(const Offset(70, 80));
    await tester.pump();
    await left.moveTo(const Offset(4, 80));
    await right.moveTo(const Offset(180, 80));
    await tester.pump();
    await left.up();
    await right.up();
    await tester.pumpAndSettle();
    expect(find.text('tick-4'), findsOneWidget);
  });
}
