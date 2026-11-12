import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../registry/repo.dart';
import '../hex_page.dart';
import 'dashboards_chrome.dart';
import '../../locale/languages.dart';

/// First screen of the dashboards section: add and search.
class DashboardsMenuPage extends StatelessWidget {
  const DashboardsMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final count = model.dashboardTotal;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = cardBoard(dashboardsMenuIds, wide: wide);
    return HexPage(
      slots: [for (final slot in board) _slot(slot, language, count)],
      onTap: (id) {
        switch (id) {
          case 'back':
            popOrHome(context);
          case 'add':
            context.push('/dashboards/new');
          case 'search':
            context.push('/dashboards/search');
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
          title: localized(language, 'Добавить панель', 'Add dashboard'),
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
          color: dashboardsColor,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/actions/search.svg',
        );
    }
  }
}
