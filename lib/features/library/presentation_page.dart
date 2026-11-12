import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../hive/bevel.dart';
import '../../hive/grain.dart';
import '../../hive/hex_scene.dart';
import '../../locale/languages.dart';
import '../code/code_modal.dart';
import 'presentation_controls.dart';
import 'presentation_content.dart';
import 'presentation_demo.dart';
import 'presentation_fullscreen.dart';

/// A full-page deck that also works without account, network or Library assets.
class PresentationPage extends StatefulWidget {
  const PresentationPage({
    required this.language,
    required this.onClose,
    required this.onDocs,
    required this.onHome,
    super.key,
  });

  final String language;
  final VoidCallback onClose;
  final VoidCallback onDocs;
  final VoidCallback onHome;

  @override
  State<PresentationPage> createState() => _PresentationPageState();
}

class _PresentationPageState extends State<PresentationPage> {
  final _focus = FocusNode();
  final _scroll = ScrollController();
  final _notesScroll = ScrollController();
  final _watch = Stopwatch();
  Timer? _ticker;
  String? _languageOverride;
  var _slide = 0;
  var _notes = false;
  var _overview = false;
  var _ownsFullscreen = false;
  var _fullscreenBusy = false;
  double _swipe = 0;

  String get _language => _languageOverride ?? widget.language;
  List<PresentationSlide> get _slides => presentationSlides(_language);
  String t(String ru, String en) => localized(_language, ru, en);

  @override
  void dispose() {
    _ticker?.cancel();
    _watch.stop();
    _focus.dispose();
    _scroll.dispose();
    _notesScroll.dispose();
    if (_ownsFullscreen) unawaited(_exitFullscreen());
    super.dispose();
  }

  Future<void> _exitFullscreen() async {
    try {
      await exitPresentationFullscreen();
    } catch (_) {
      // The browser may already have left fullscreen during navigation.
    }
  }

  Future<void> _fullscreen() async {
    if (!fullscreenAvailable || _fullscreenBusy) return;
    _fullscreenBusy = true;
    try {
      final entering = !presentationIsFullscreen;
      await togglePresentationFullscreen();
      _ownsFullscreen = entering;
      if (!mounted && entering) await _exitFullscreen();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t(
                'Браузер не разрешил полноэкранный режим.',
                'The browser did not allow fullscreen mode.',
              ),
            ),
          ),
        );
      }
    } finally {
      _fullscreenBusy = false;
    }
  }

  void _go(int index) {
    if (index < 0 || index >= _slides.length) return;
    setState(() {
      _slide = index;
      _overview = false;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    if (_notesScroll.hasClients) _notesScroll.jumpTo(0);
    _focus.requestFocus();
  }

  void _toggleTimer() {
    setState(() {
      if (_watch.isRunning) {
        _watch.stop();
        _ticker?.cancel();
      } else {
        _watch.start();
        _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  void _restart() {
    _ticker?.cancel();
    _watch.stop();
    _watch.reset();
    setState(() => _slide = 0);
    if (_scroll.hasClients) _scroll.jumpTo(0);
    if (_notesScroll.hasClients) _notesScroll.jumpTo(0);
    _focus.requestFocus();
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed ||
        HardwareKeyboard.instance.isAltPressed) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      _close();
    } else if (key == LogicalKeyboardKey.keyN) {
      setState(() => _notes = !_notes);
    } else if (key == LogicalKeyboardKey.keyF) {
      unawaited(_fullscreen());
    } else if (node.hasPrimaryFocus) {
      // Focused controls keep their own arrows and Space (notably the slider).
      if (key == LogicalKeyboardKey.arrowRight ||
          key == LogicalKeyboardKey.pageDown ||
          key == LogicalKeyboardKey.space) {
        _go(_slide + 1);
      } else if (key == LogicalKeyboardKey.arrowLeft ||
          key == LogicalKeyboardKey.pageUp) {
        _go(_slide - 1);
      } else if (key == LogicalKeyboardKey.home) {
        _go(0);
      } else if (key == LogicalKeyboardKey.end) {
        _go(_slides.length - 1);
      } else {
        return KeyEventResult.ignored;
      }
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  String _time(int seconds) =>
      '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

  void _close() {
    if (_overview) {
      setState(() => _overview = false);
      _focus.requestFocus();
    } else {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_slide];
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Focus(
          focusNode: _focus,
          autofocus: true,
          onKeyEvent: _key,
          child: Stack(
            children: [
              Column(
                children: [
                  _header(),
                  _rule(),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _focus.requestFocus,
                      onHorizontalDragStart: (_) => _swipe = 0,
                      onHorizontalDragUpdate: (event) =>
                          _swipe += event.delta.dx,
                      onHorizontalDragEnd: (_) {
                        if (_swipe.abs() > 60) {
                          _go(_slide + (_swipe < 0 ? 1 : -1));
                        }
                      },
                      child: LayoutBuilder(
                        builder: (context, bounds) {
                          final wide = bounds.maxWidth >= 850;
                          final padding = bounds.maxWidth >= 1200 ? 40.0 : 20.0;
                          final copy = _copy(slide, wide, bounds.maxWidth);
                          final demo = PresentationDemo(
                            key: ValueKey(_slide),
                            slide: _slide,
                            language: _language,
                            onDocs: widget.onDocs,
                            onHome: widget.onHome,
                          );
                          return Scrollbar(
                            controller: _scroll,
                            child: SingleChildScrollView(
                              key: const ValueKey('presentation-scroll'),
                              controller: _scroll,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: bounds.maxHeight,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(padding),
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 1700,
                                      ),
                                      child: wide
                                          ? Row(
                                              children: [
                                                Expanded(flex: 10, child: copy),
                                                SizedBox(width: padding),
                                                Expanded(flex: 11, child: demo),
                                              ],
                                            )
                                          : Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                copy,
                                                const SizedBox(height: 20),
                                                demo,
                                              ],
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  if (_notes) _speakerNotes(slide),
                  _rule(),
                  _footer(slide),
                ],
              ),
              if (_overview) Positioned.fill(child: _slideMap()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _rule() => Container(height: 1, color: hexMuted.withValues(alpha: .3));

  Widget _header() {
    final narrow = MediaQuery.sizeOf(context).width < 760;
    final tools = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PresentationWord(
          label: '${_time(_watch.elapsed.inSeconds)} / 5:00',
          tooltip: _watch.isRunning
              ? t('Пауза таймера', 'Pause timer')
              : t('Запустить таймер', 'Start timer'),
          color: _watch.isRunning ? presentationColor(_slide) : Colors.white,
          font: narrow ? 12 : 14,
          onTap: _toggleTimer,
        ),
        PresentationWord(
          label: narrow ? 'N' : t('Заметки', 'Notes'),
          tooltip: t('Заметки рассказчика (N)', 'Presenter notes (N)'),
          color: _notes ? presentationColor(_slide) : hexMuted,
          selected: _notes,
          onTap: () => setState(() => _notes = !_notes),
        ),
        PresentationWord(
          label: _language.toUpperCase(),
          onTap: () => setState(
            () => _languageOverride = _language == 'en' ? 'ru' : 'en',
          ),
        ),
        if (fullscreenAvailable)
          PresentationWord(
            label: narrow ? 'F' : t('Полный экран', 'Fullscreen'),
            tooltip: t('Полный экран (F)', 'Fullscreen (F)'),
            onTap: _fullscreen,
          ),
      ],
    );
    final close = Tooltip(
      message: t('Закрыть', 'Close'),
      child: CodeCloseMark(
        label: t('Закрыть', 'Close'),
        extent: 48,
        iconExtent: 28,
        onTap: _close,
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t('Pepeunit / Презентация', 'Pepeunit / Presentation'),
                  style: const TextStyle(
                    fontFamily: 'OpenGost Type B',
                    fontSize: 22,
                    color: Colors.white,
                  ),
                ),
              ),
              if (!narrow) tools,
              close,
            ],
          ),
          if (narrow)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: tools,
            ),
        ],
      ),
    );
  }

  Widget _copy(PresentationSlide slide, bool wide, double width) => BevelFrame(
    color: presentationColor(_slide).withValues(alpha: .7),
    radius: 20,
    width: 1.4,
    child: PresentationSurface(
      child: Padding(
        padding: EdgeInsets.all(wide ? 32 : 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${(_slide + 1).toString().padLeft(2, '0')} / ${_slides.length} · ${slide.chapter}',
              style: TextStyle(
                fontFamily: 'OpenGost Type B',
                fontSize: 18,
                color: presentationColor(_slide),
              ),
            ),
            const SizedBox(height: 24),
            Semantics(
              header: true,
              liveRegion: true,
              child: Text(
                slide.title,
                style: TextStyle(
                  fontFamily: 'OpenGost Type B',
                  fontSize: wide ? (width >= 1200 ? 48 : 38) : 32,
                  height: 1.15,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              slide.body,
              style: TextStyle(
                fontFamily: 'OpenGost Type B',
                fontSize: wide ? 23 : 20,
                height: 1.4,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            _rule(),
            const SizedBox(height: 16),
            Text(
              slide.takeaway,
              style: TextStyle(
                fontFamily: 'OpenGost Type B',
                fontSize: 19,
                height: 1.35,
                color: presentationColor(_slide),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _speakerNotes(PresentationSlide slide) {
    final start = _slides
        .take(_slide)
        .fold<int>(0, (sum, s) => sum + s.seconds);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height < 500 ? 100 : 172,
      width: double.infinity,
      child: BevelFrame(
        color: presentationColor(_slide),
        radius: 12,
        width: 1,
        child: GrainBox(
          tile: cellGrain,
          opacity: modalFillOpacity,
          child: Scrollbar(
            controller: _notesScroll,
            child: SingleChildScrollView(
              controller: _notesScroll,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${t('ЗАМЕТКИ · видны на экране', 'NOTES · visible on screen')}  /  ${_time(start)}–${_time(start + slide.seconds)}',
                    style: TextStyle(
                      color: presentationColor(_slide),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    slide.notes,
                    style: const TextStyle(fontSize: 18, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _footer(PresentationSlide slide) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: Row(
      children: [
        PresentationChevron(
          left: true,
          label: t('Предыдущий слайд', 'Previous slide'),
          onTap: _slide > 0 ? () => _go(_slide - 1) : null,
        ),
        Expanded(
          child: Text(
            '${_slide + 1} / ${_slides.length} · ${slide.chapter}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'OpenGost Type B',
              color: hexMuted,
              fontSize: 16,
            ),
          ),
        ),
        PresentationWord(
          label: t('Слайды', 'Slides'),
          tooltip: t('Все слайды', 'All slides'),
          font: 12,
          onTap: () => setState(() => _overview = true),
        ),
        if (_slide == _slides.length - 1)
          PresentationWord(
            label: '↺',
            tooltip: t('Начать заново', 'Restart'),
            onTap: _restart,
          )
        else
          PresentationChevron(
            left: false,
            label: t('Следующий слайд', 'Next slide'),
            onTap: () => _go(_slide + 1),
          ),
      ],
    ),
  );

  Widget _slideMap() => Padding(
    padding: const EdgeInsets.all(16),
    child: BevelFrame(
      color: presentationColor(_slide),
      radius: 18,
      child: GrainBox(
        tile: sceneGrain,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 4, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t('Слайды', 'Slides'),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  CodeCloseMark(
                    label: t('Закрыть список слайдов', 'Close slide list'),
                    extent: 48,
                    iconExtent: 28,
                    onTap: _close,
                  ),
                ],
              ),
            ),
            Expanded(
              child: HexScene(
                slots: [
                  for (var i = 0; i < _slides.length; i++)
                    HexSlot(
                      id: '$i',
                      title: '${i + 1}. ${_slides[i].chapter}',
                      color: presentationColor(i),
                      q: i % 3 - i ~/ 3,
                      r: i ~/ 3,
                      center: '${i + 1}',
                      centerScale: 3,
                      centerColor: i == _slide
                          ? presentationColor(i)
                          : Colors.white,
                    ),
                ],
                onTap: (id) => _go(int.parse(id)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
