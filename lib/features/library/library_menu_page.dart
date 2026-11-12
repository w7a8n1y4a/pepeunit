import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../locale/languages.dart';
import '../../navigation/back.dart';
import '../../navigation/sections.dart';
import '../hex_page.dart';
import 'tree_page.dart';

Color get libraryColor => sectionById('library')!.color;

/// Leaves a Library text: back to the screen under it, or to the Library
/// when the text was opened by its address.
void closeLibrary(BuildContext context, String home) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(home);
  }
}

/// Documentation, the screen tree, presentation, tools and project information.
class LibraryMenuPage extends StatelessWidget {
  const LibraryMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = cardBoard(const [
      'docs',
      'tree',
      'presentation',
      'tools',
      'about',
    ], wide: wide);
    final slots = [for (final slot in board) _slot(slot, language)];
    return HexPage(
      slots: slots,
      onTap: (id) {
        switch (id) {
          case 'back':
            popOrHome(context);
          case 'presentation':
            context.push('/library/presentation');
          case 'docs':
            // `go`, not `push`: the screen then moves between articles by
            // `go` too, and keeps its trail, because both name one page.
            context.go('/library/docs');
          case 'tree':
            context.push(treePath);
          case 'tools':
            context.push('/library/tools');
          case 'about':
            context.push('/library/about');
        }
      },
    );
  }

  HexSlot _slot(BoardSlot slot, String language) {
    switch (slot.id) {
      case 'back':
        return backSlot(language, q: slot.q, r: slot.r);
      case 'presentation':
        return HexSlot(
          id: 'presentation',
          title: localized(language, 'Презентация', 'Presentation'),
          color: libraryColor,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/status/bulb.svg',
        );
      case 'docs':
        return HexSlot(
          id: 'docs',
          title: localized(language, 'Документация', 'Documentation'),
          color: libraryColor,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/objects/file.svg',
          center: '.md',
        );
      case 'tree':
        return HexSlot(
          id: 'tree',
          title: localized(language, 'Дерево 6 путей', 'Tree of 6 paths'),
          color: libraryColor,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/objects/tree.svg',
        );
      case 'tools':
        return HexSlot(
          id: 'tools',
          title: localized(language, 'Инструменты', 'Tools'),
          color: libraryColor,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/services/tools.svg',
        );
      default:
        return HexSlot(
          id: 'about',
          title: localized(language, 'О приложении', 'About'),
          color: libraryColor,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/status/info.svg',
        );
    }
  }
}
