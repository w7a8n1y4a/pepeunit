import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../library/library.dart';
import '../../locale/languages.dart';
import '../../navigation/back.dart';
import '../../navigation/sections.dart';
import '../code/code_modal.dart';
import '../code/code_view.dart';
import '../hex_page.dart';
import 'library_modal.dart';

Color get libraryColor => sectionById('library')!.color;

/// Library texts are Russian for now. The phrase map keeps the place for
/// other languages: a missing line falls back to Russian.
String libText(String language, String ru) => phrase(language, {'ru': ru});

String libErrorText(String language, String ru, String en) =>
    phrase(language, {'ru': ru, 'en': en});

/// Leaves a Library text: back to the screen under it, or to the Library
/// when the text was opened by its address.
void closeLibrary(BuildContext context, String home) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(home);
  }
}

/// What the Library menu shows on top of itself.
enum LibraryOpen { none, presentation }

/// The first screen of the Library: presentation, documentation, tools, about.
/// The presentation is a panel over this screen, so closing it returns here.
class LibraryMenuPage extends StatefulWidget {
  const LibraryMenuPage({this.open = LibraryOpen.none, super.key});

  final LibraryOpen open;

  @override
  State<LibraryMenuPage> createState() => _LibraryMenuPageState();
}

class _LibraryMenuPageState extends State<LibraryMenuPage> {
  DocsTree? _tree;
  List<String> _slides = const [];
  var _slide = 0;
  String? _failure;
  var _failureOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.open != LibraryOpen.none) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    final language = AppScope.of(context).vault.language;
    try {
      final library = Library.instance;
      final tree = await library.docs(language);
      final slides = widget.open == LibraryOpen.presentation
          ? await library.presentation(language)
          : const <String>[];
      if (!mounted) return;
      setState(() {
        _tree = tree;
        _slides = slides;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _failure = '$error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = cardBoard(const [
      'presentation',
      'docs',
      'tools',
      'about',
    ], wide: wide);
    final slots = [for (final slot in board) _slot(slot, language)];
    appendError(
      slots,
      message: _failure,
      open: _failureOpen,
      language: language,
      text: libErrorText,
      wide: wide,
    );
    final scene = HexPage(
      slots: slots,
      onTap: (id) {
        switch (id) {
          case 'back':
            popOrHome(context);
          case 'presentation':
            context.push('/library/presentation');
          case 'docs':
            context.push('/library/docs');
          case 'tools':
            context.push('/library/tools');
          case 'about':
            context.push('/library/about');
          case 'error':
            setState(() => _failureOpen = true);
        }
      },
    );
    final panel = _panel(language);
    if (panel == null) return scene;
    return Stack(children: [scene, panel]);
  }

  Widget? _panel(String language) {
    void close() => closeLibrary(context, '/library');
    switch (widget.open) {
      case LibraryOpen.none:
        return null;
      case LibraryOpen.presentation:
        // No slides yet: the panel opens empty. Slides come back as files in
        // `assets/library/<language>/presentation/`.
        if (_slides.isEmpty) {
          return Material(
            type: MaterialType.transparency,
            child: LibraryModal(
              title: libText(language, 'Презентация'),
              color: libraryColor,
              source: '',
              docs: _tree,
              onClose: close,
            ),
          );
        }
        final last = _slides.length - 1;
        final at = _slide.clamp(0, last);
        return Material(
          type: MaterialType.transparency,
          child: LibraryModal(
            title: libText(language, 'Презентация'),
            color: libraryColor,
            source: _slides[at],
            docs: _tree,
            onClose: close,
            actions: (font) => [
              CodeWordButton(
                label: '‹',
                font: font,
                enabled: at > 0,
                onTap: () => setState(() => _slide = at - 1),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: font * 0.3),
                child: Text(
                  '${at + 1}/${_slides.length}',
                  style: codeMono(font * 0.95, color: hexMuted),
                ),
              ),
              CodeWordButton(
                label: '›',
                font: font,
                enabled: at < last,
                onTap: () => setState(() => _slide = at + 1),
              ),
            ],
          ),
        );
    }
  }

  HexSlot _slot(BoardSlot slot, String language) {
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: libText(language, 'Назад'),
          q: slot.q,
          r: slot.r,
        );
      case 'presentation':
        return HexSlot(
          id: 'presentation',
          title: libText(language, 'Презентация'),
          color: libraryColor,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/status/bulb.svg',
        );
      case 'docs':
        return HexSlot(
          id: 'docs',
          title: libText(language, 'Документация'),
          color: libraryColor,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/objects/file.svg',
          center: '.md',
        );
      case 'tools':
        return HexSlot(
          id: 'tools',
          title: libText(language, 'Инструменты'),
          color: libraryColor,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/services/tools.svg',
        );
      default:
        return HexSlot(
          id: 'about',
          title: libText(language, 'О приложении'),
          color: libraryColor,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/status/info.svg',
        );
    }
  }
}
