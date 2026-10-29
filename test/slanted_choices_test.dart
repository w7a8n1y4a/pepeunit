import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/features/slanted_choices.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const lineGap = 4.0;
  const touchGap = 1.5;

  SlantedInk word(double length) {
    return SlantedInk(alongStart: 0, alongEnd: length, ascent: 12, descent: 3);
  }

  double stepAt(SlantedRowLayout layout, int index) {
    return layout.spots[index + 1].pivot.dx - layout.spots[index].pivot.dx;
  }

  test('a finished word does not keep space on an imaginary line', () {
    final layout = placeSlantedRow(
      words: [word(22), word(70)],
      maxWidth: 1000,
      lineGap: lineGap,
      touchGap: touchGap,
    );
    final dx = stepAt(layout, 0);
    final stacked = (3 + 12 + lineGap) / sin(layout.lean);
    final ended = (22 + touchGap) / cos(layout.lean);
    expect(ended, lessThan(stacked));
    expect(dx, closeTo(ended, 0.6));
    expect(dx, lessThan(stacked * 0.5));
  });

  test('a long word keeps the next letter one line-gap under its tail', () {
    final layout = placeSlantedRow(
      words: [word(200), word(40)],
      maxWidth: 150,
      lineGap: lineGap,
      touchGap: touchGap,
    );
    final dx = stepAt(layout, 0);
    final stacked = (3 + 12 + lineGap) / sin(layout.lean);
    final ended = (200 + touchGap) / cos(layout.lean);
    expect(stacked, lessThan(ended));
    expect(dx, closeTo(stacked, 0.8));
    expect(layout.size.width, lessThanOrEqualTo(150.5));
  });

  test('the gap between stacked words stays within a third of a capital', () {
    final words = [word(90), word(24), word(60)];
    final layout = placeSlantedRow(
      words: words,
      maxWidth: 180,
      lineGap: lineGap,
      touchGap: touchGap,
    );
    expect(layout.size.width, lessThanOrEqualTo(180.5));
    for (var i = 0; i < words.length - 1; i++) {
      final dx = stepAt(layout, i);
      final upGap =
          dx * sin(layout.lean) - words[i].descent - words[i + 1].ascent;
      expect(upGap, lessThanOrEqualTo(lineGap + 0.05));
      final alongGap =
          dx * cos(layout.lean) + words[i + 1].alongStart - words[i].alongEnd;
      final stacked =
          (words[i].descent + words[i + 1].ascent + lineGap) / sin(layout.lean);
      final ended =
          (words[i].alongEnd + touchGap - words[i + 1].alongStart) /
          cos(layout.lean);
      expect(dx, closeTo(min(stacked, max(0.0, ended)), 0.6));
      expect(alongGap >= touchGap - 0.05 || upGap >= lineGap - 0.05, isTrue);
    }
    final first = layout.spots.first.pivot.dy;
    for (final spot in layout.spots) {
      expect(spot.pivot.dy, closeTo(first, 0.01));
      expect(spot.pivot.dx, greaterThanOrEqualTo(layout.spots.first.pivot.dx));
    }
    final afterShort = stepAt(layout, 1);
    final shortStacked =
        (words[1].descent + words[2].ascent + lineGap) / sin(layout.lean);
    expect(afterShort, lessThan(shortStacked));
  });

  test('a short row can be spread out to the stroke', () {
    const laid = SlantedRowLayout(
      lean: 0.2,
      size: Size(80, 36),
      spots: [
        SlantedWordSpot(box: Rect.fromLTWH(0, 8, 28, 18), pivot: Offset(4, 24)),
        SlantedWordSpot(
          box: Rect.fromLTWH(36, 4, 40, 20),
          pivot: Offset(40, 24),
        ),
      ],
    );
    final spanned = spanSlantedRow(laid, 140);
    expect(spanned.size.width, 140);
    expect(spanned.size.height, 36);
    expect(spanned.lean, 0.2);
    expect(spanned.spots.first.pivot.dx, 4);
    expect(spanned.spots.last.pivot.dx, closeTo(100, 0.01));
    expect(
      spanSlantedRow(spanned, 140).spots.last.pivot.dx,
      closeTo(100, 0.01),
    );
  });

  test('words that fit stay shallow', () {
    final flat = placeSlantedRow(
      words: [word(30), word(28)],
      maxWidth: 400,
      lineGap: lineGap,
      touchGap: touchGap,
    );
    final steep = placeSlantedRow(
      words: [word(220), word(180)],
      maxWidth: 140,
      lineGap: lineGap,
      touchGap: touchGap,
    );
    expect(flat.lean, lessThan(12 * pi / 180));
    expect(steep.lean, greaterThan(flat.lean));
    expect(flat.size.height, lessThan(steep.size.height));
  });

  testWidgets('enums stay inside the search line and accept a tap', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            height: 180,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SlantedChoices(
                  fontSize: 18,
                  maxWidth: 160,
                  choices: [
                    SlantedChoice(
                      label: 'Admin',
                      selected: true,
                      onTap: () => taps++,
                    ),
                    SlantedChoice(label: 'User', selected: false, onTap: () {}),
                  ],
                ),
                const SlantedChoices(
                  fontSize: 18,
                  maxWidth: 160,
                  choices: [
                    SlantedChoice(
                      label: 'Active',
                      selected: false,
                      onTap: _noop,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final admin = tester.getRect(find.bySemanticsLabel('Admin'));
    final user = tester.getRect(find.bySemanticsLabel('User'));
    final active = tester.getRect(find.bySemanticsLabel('Active'));
    final left = min(admin.left, min(user.left, active.left));
    final right = max(admin.right, max(user.right, active.right));
    expect(right - left, lessThanOrEqualTo(160.5));
    expect(active.top, greaterThan(admin.top));
    await tester.tap(find.bySemanticsLabel('Admin'));
    expect(taps, 1);
  });

  testWidgets('a spanned enum lies across the search line', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 280,
            height: 420,
            child: SlantedChoices(
              fontSize: 28,
              maxWidth: 160,
              spanLine: true,
              choices: [
                SlantedChoice(
                  label: 'Administrator',
                  selected: true,
                  onTap: _noop,
                ),
                SlantedChoice(label: 'Member', selected: false, onTap: _noop),
                SlantedChoice(label: 'Owner', selected: false, onTap: _noop),
              ],
            ),
          ),
        ),
      ),
    );
    final user = tester.getRect(find.bySemanticsLabel('Administrator'));
    final admin = tester.getRect(find.bySemanticsLabel('Member'));
    final owner = tester.getRect(find.bySemanticsLabel('Owner'));
    final left = min(user.left, min(admin.left, owner.left));
    final right = max(user.right, max(admin.right, owner.right));
    final top = min(user.top, min(admin.top, owner.top));
    final bottom = max(user.bottom, max(admin.bottom, owner.bottom));
    expect(right - left, greaterThan(140));
    expect(right - left, lessThanOrEqualTo(160.5));
    expect(bottom - top, greaterThan(36));
  });

  test('OpenGost roles put the next word after a short one', () async {
    final bytes = File('assets/fonts/OpenGostTypeB-Regular.ttf')
        .readAsBytesSync();
    final loader = FontLoader('OpenGost Type B')
      ..addFont(Future.value(ByteData.sublistView(bytes)));
    await loader.load();
    const style = TextStyle(
      fontFamily: 'OpenGost Type B',
      fontSize: 17,
      height: 1,
    );
    final labels = ['Пользователь', 'Админ', 'Владелец'];
    final measured = [
      for (final label in labels)
        measureSlantedWord(label, style, TextScaler.noScaling)!,
    ];
    final cap = measureSlantedWord('Н', style, TextScaler.noScaling)!;
    final layout = placeSlantedRow(
      words: [for (final word in measured) word.ink],
      maxWidth: 140,
      lineGap: cap.ink.ascent / 3,
      touchGap: max(1.0, cap.ink.ascent * 0.12),
    );
    expect(layout.size.width, lessThanOrEqualTo(140.5));
    final first = layout.spots.first.pivot.dy;
    for (final spot in layout.spots) {
      expect(spot.pivot.dy, closeTo(first, 0.01));
    }
    final short = measured[1].ink;
    final next = measured[2].ink;
    final dx = stepAt(layout, 1);
    final touch = max(1.0, cap.ink.ascent * 0.12);
    final stacked =
        (short.descent + next.ascent + cap.ink.ascent / 3) / sin(layout.lean);
    final ended = (short.alongEnd + touch - next.alongStart) / cos(layout.lean);
    expect(dx, closeTo(min(stacked, max(0.0, ended)), 0.8));
    final wide = placeSlantedRow(
      words: [for (final word in measured) word.ink],
      maxWidth: 280,
      lineGap: cap.ink.ascent / 3,
      touchGap: touch,
    );
    final wideEnded =
        (short.alongEnd + touch - next.alongStart) / cos(wide.lean);
    final wideStacked =
        (short.descent + next.ascent + cap.ink.ascent / 3) / sin(wide.lean);
    expect(wideEnded, lessThan(wideStacked));
    expect(stepAt(wide, 1), closeTo(wideEnded, 0.8));
  });
}

void _noop() {}
