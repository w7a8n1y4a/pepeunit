import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/features/library/presentation_content.dart';
import 'package:pepeunit_client/features/library/presentation_page.dart';

Future<void> _open(
  WidgetTester tester, {
  Size size = const Size(1440, 900),
  String language = 'ru',
  double textScale = 1,
  VoidCallback? onClose,
  VoidCallback? onDocs,
  VoidCallback? onHome,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: PresentationPage(
          language: language,
          onClose: onClose ?? () {},
          onDocs: onDocs ?? () {},
          onHome: onHome ?? () {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Следующий слайд'));
  await tester.pumpAndSettle();
}

void main() {
  test('both stories have nine slides and a five-minute speaking plan', () {
    for (final language in ['ru', 'en']) {
      final slides = presentationSlides(language);
      expect(slides, hasLength(9));
      expect(slides.fold<int>(0, (total, slide) => total + slide.seconds), 300);
      expect(slides.every((slide) => slide.notes.isNotEmpty), isTrue);
    }
    expect(presentationSlides('unknown'), same(presentationSlides('ru')));
  });

  testWidgets('keyboard, slide menu, restart, notes and language', (
    tester,
  ) async {
    var closed = false;
    await _open(tester, onClose: () => closed = true);
    expect(find.textContaining('ЗАМЕТКИ'), findsNothing);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    expect(find.text('1 / 9 · Идея'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('2 / 9 · Общий язык'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pumpAndSettle();
    expect(find.text('3 / 9 · Код → устройство'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
    await tester.pumpAndSettle();
    expect(find.text('2 / 9 · Общий язык'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.pumpAndSettle();
    expect(find.textContaining('0:25–0:55'), findsOneWidget);
    await tester.tap(find.text('RU'));
    await tester.pumpAndSettle();
    expect(
      find.text('A device or a service.\nBoth are Units.'),
      findsOneWidget,
    );
    expect(find.textContaining('NOTES · visible on screen'), findsOneWidget);
    await tester.tap(find.byTooltip('All slides'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(closed, isFalse);
    expect(find.text('2 / 9 · A shared language'), findsOneWidget);
    await tester.tap(find.byTooltip('All slides'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('9. Your first Unit'));
    await tester.pumpAndSettle();
    expect(find.text('9 / 9 · Your first Unit'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    expect(find.text('9 / 9 · Your first Unit'), findsOneWidget);
    await tester.tap(find.byTooltip('Restart'));
    await tester.pumpAndSettle();
    expect(find.text('1 / 9 · The idea'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    expect(closed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('connection and temperature jointly control the sample fan', (
    tester,
  ) async {
    await _open(tester);
    for (var i = 0; i < 3; i++) {
      await _next(tester);
    }
    expect(find.text('Нет связи'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Соединить'));
    await tester.pumpAndSettle();
    expect(find.text('Вентилятор выключен'), findsOneWidget);
    final slider = find.byType(Slider);
    final rect = tester.getRect(slider);
    await tester.tapAt(Offset(rect.right - 30, rect.center.dy));
    await tester.pumpAndSettle();
    expect(find.text('Вентилятор включён'), findsOneWidget);
    // Slider keyboard focus must not turn a slide when changing its value.
    final temperature = tester.widget<Slider>(slider).value;
    tester.widget<Slider>(slider).focusNode!.requestFocus();
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('4 / 9 · Взаимодействие'), findsOneWidget);
    expect(tester.widget<Slider>(slider).value, lessThan(temperature));
    await tester.tap(find.bySemanticsLabel('Разъединить'));
    await tester.pumpAndSettle();
    expect(find.text('Нет связи'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DataPipe example excludes the outlier on demand', (
    tester,
  ) async {
    await _open(tester);
    for (var i = 0; i < 5; i++) {
      await _next(tester);
    }
    expect(find.text('99'), findsOneWidget);
    await tester.tap(find.text('Включить фильтр'));
    await tester.pumpAndSettle();
    expect(find.text('99'), findsNothing);
    expect(
      find.text('99 °C отфильтровано. Осталось 6 измерений.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Выключить фильтр'));
    await tester.pumpAndSettle();
    expect(find.text('99'), findsOneWidget);
  });

  testWidgets('timer is manual, pauses, resets, and never advances slides', (
    tester,
  ) async {
    await _open(tester);
    await tester.pump(const Duration(seconds: 10));
    expect(find.text('0:00 / 5:00'), findsOneWidget);
    await tester.tap(find.byTooltip('Запустить таймер'));
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('1 / 9 · Идея'), findsOneWidget);
    await tester.tap(find.byTooltip('Пауза таймера'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    // Clicking the timer may retain focus; the slide menu works regardless.
    if (find.byTooltip('Начать заново').evaluate().isEmpty) {
      await tester.tap(find.byTooltip('Все слайды'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('9. Ваш первый Unit'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.byTooltip('Начать заново'));
    await tester.pumpAndSettle();
    expect(find.text('0:00 / 5:00'), findsOneWidget);
    expect(find.byTooltip('Запустить таймер'), findsOneWidget);
    await tester.tap(find.byTooltip('Запустить таймер'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipe navigates and final actions open the menu and guide', (
    tester,
  ) async {
    var docs = false;
    var home = false;
    await _open(tester, onDocs: () => docs = true, onHome: () => home = true);
    await tester.drag(
      find.text('От кода\nк работающей системе'),
      const Offset(-150, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('2 / 9 · Общий язык'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.end);
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('В главное меню'));
    expect(home, isTrue);
    await tester.tap(find.bySemanticsLabel('Создать первый Unit'));
    expect(docs, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.pumpAndSettle();
    expect(find.text('1 / 9 · Идея'), findsOneWidget);
  });

  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(1024, 768),
    const Size(1920, 1080),
    const Size(2560, 1440),
  ]) {
    testWidgets('all slides fit or scroll at $size', (tester) async {
      await _open(tester, size: size);
      for (var i = 0; i < 9; i++) {
        expect(find.text(presentationSlides('ru')[i].title), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'slide ${i + 1} at $size',
        );
        if (i < 8) await _next(tester);
      }
      await tester.ensureVisible(find.bySemanticsLabel('Создать первый Unit'));
      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('Создать первый Unit').hitTestable(),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Заметки рассказчика (N)'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('English deck supports larger text on a phone', (tester) async {
    await _open(
      tester,
      size: const Size(375, 667),
      language: 'en',
      textScale: 1.6,
    );
    for (var i = 0; i < 9; i++) {
      expect(tester.takeException(), isNull, reason: 'slide ${i + 1}');
      if (i < 8) {
        await tester.tap(find.byTooltip('Next slide'));
        await tester.pumpAndSettle();
      }
    }
  });
}
