import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../registry/repo.dart';
import '../../registry/registry_view.dart';
import '../hex_page.dart';
import 'registry_chrome.dart';
import '../../locale/languages.dart';

/// First screen of the repositories section: add and search.
class RegistryMenuPage extends StatelessWidget {
  const RegistryMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final count = model.target == null
        ? null
        : model.portraitOf(model.target!.url)?.repos;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = cardBoard(registryMenuIds, wide: wide);
    return HexPage(
      slots: [for (final slot in board) _slot(slot, language, count)],
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

  HexSlot _slot(BoardSlot slot, String language, int? count) {
    switch (slot.id) {
      case 'back':
        return backSlot(language, q: slot.q, r: slot.r);
      case 'add':
        return HexSlot(
          id: 'add',
          title: localized(language, 'Добавить репозиторий', 'Add repository'),
          color: addColor,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/actions/plus.svg',
        );
      default:
        return HexSlot(
          id: 'search',
          title: localized(language, 'Поиск', 'Search'),
          footer: count == null ? null : pieceCount(language, count),
          color: registryColor,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/actions/search.svg',
        );
    }
  }
}
