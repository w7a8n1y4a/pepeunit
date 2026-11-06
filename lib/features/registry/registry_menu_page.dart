import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../registry/registry_view.dart';
import '../hex_page.dart';
import 'registry_chrome.dart';

/// First screen of the repositories section: add and search.
class RegistryMenuPage extends StatelessWidget {
  const RegistryMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = cardBoard(registryMenuIds, wide: wide);
    return HexPage(
      slots: [for (final slot in board) _slot(slot, language)],
      onTap: (id) {
        switch (id) {
          case 'back':
            popOrHome(context);
          case 'add':
            context.push('/registry/new');
          case 'search':
            context.push('/registry/search');
        }
      },
    );
  }

  HexSlot _slot(BoardSlot slot, String language) {
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: regText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'add':
        return HexSlot(
          id: 'add',
          title: regText(language, 'Добавить репозиторий', 'Add repository'),
          color: addColor,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/plus.svg',
        );
      default:
        return HexSlot(
          id: 'search',
          title: regText(language, 'Поиск', 'Search'),
          color: registryColor,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/search.svg',
        );
    }
  }
}
