import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/hive/hex_motion.dart';
import 'package:pepeunit_client/hive/hex_scene.dart';

List<EchoSpot> _spots(List<(int, int)> cells) => [
  for (final cell in cells)
    EchoSpot(
      q: cell.$1,
      r: cell.$2,
      center: Offset(cell.$1 * 100.0 + cell.$2 * 50, cell.$2 * 90.0),
      lattice: 60,
    ),
];

const _ring = <(int, int)>[(1, 0), (1, -1), (0, -1), (-1, 0), (-1, 1), (0, 1)];

HexSlot _slot(int q, int r) =>
    HexSlot(id: '$q,$r', title: '', color: addColor, q: q, r: r);

void main() {
  test('the echo draws only the gaps between two cells', () {
    final clock = AlwaysStoppedAnimation<double>(0.2);
    final flower = EchoPainter(
      spots: _spots([(0, 0), ..._ring]),
      color: addColor,
      clock: clock,
    );
    // Six spokes and six links around, and no line on the outer edge.
    expect(flower.edgeCount, 12);
    final pair = EchoPainter(
      spots: _spots([(0, 0), (1, 0)]),
      color: addColor,
      clock: clock,
    );
    expect(pair.edgeCount, 1);
    final alone = EchoPainter(
      spots: _spots([(0, 0)]),
      color: addColor,
      clock: clock,
    );
    expect(alone.edgeCount, 0);
  });

  testWidgets('a new echo plays once and goes away', (tester) async {
    final slots = [_slot(0, 0), _slot(1, 0), _slot(0, 1)];
    Future<void> show(HexEcho? echo) => tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(size: Size(600, 600)),
          child: HexScene(slots: slots, onTap: (_) {}, echo: echo),
        ),
      ),
    );

    Finder lines() => find.byWidgetPredicate(
      (widget) => widget is CustomPaint && widget.painter is EchoPainter,
    );

    await show(null);
    expect(lines(), findsNothing);
    await show(HexEcho(ok: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(lines(), findsOneWidget);
    await tester.pump(echoDuration);
    await tester.pump();
    expect(lines(), findsNothing);
    // The same object does not play again.
    final failed = HexEcho(ok: false);
    await show(failed);
    await tester.pump(const Duration(milliseconds: 100));
    expect(lines(), findsOneWidget);
    await tester.pump(echoDuration);
    await tester.pump();
    await show(failed);
    await tester.pump(const Duration(milliseconds: 100));
    expect(lines(), findsNothing);
  });

  testWidgets('the press effect paints and ends', (tester) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: pressDuration,
    );
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 200,
          height: 200,
          child: CustomPaint(
            painter: PressPainter(color: addColor, clock: controller),
          ),
        ),
      ),
    );
    for (final t in [0.0, 0.2, 0.5, 0.9, 1.0]) {
      controller.value = t;
      await tester.pump();
    }
    expect(tester.takeException(), isNull);
    controller.dispose();
  });
}
