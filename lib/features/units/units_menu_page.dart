import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../units/unit_view.dart';
import '../hex_page.dart';
import 'units_chrome.dart';
import '../../locale/languages.dart';

/// First screen of the units section: add, search and groups.
class UnitsMenuPage extends StatelessWidget {
  const UnitsMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = unitsMenuBoard(wide: wide);
    return HexPage(
      slots: [for (final slot in board.slots) _slot(slot, language)],
      onTap: (id) {
        switch (id) {
          case 'back':
            popOrHome(context);
          case 'add':
            context.push('/units/new');
          case 'search':
            context.push('/units/search');
          case 'groups':
            context.push('/units/groups');
        }
      },
    );
  }

  HexSlot _slot(BoardSlot slot, String language) {
    switch (slot.id) {
      case 'back':
        return backSlot(language, q: slot.q, r: slot.r);
      case 'add':
        return HexSlot(
          id: 'add',
          title: localized(language, 'Создать аппарат', 'Create unit'),
          color: unitAddColor,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/actions/unit_add.svg',
        );
      case 'search':
        return HexSlot(
          id: 'search',
          title: localized(language, 'Поиск', 'Search'),
          color: unitsColor,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/actions/search.svg',
        );
      default:
        return HexSlot(
          id: 'groups',
          title: localized(language, 'Группы', 'Groups'),
          color: unitGroupsColor,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/objects/groups.svg',
        );
    }
  }
}
