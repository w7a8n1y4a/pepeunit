import 'package:flutter/material.dart';

import '../../alerts/notice.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../hex_page.dart';
import 'alerts_chrome.dart';

/// One cell per type the signed-in role can receive. A tap adds or removes
/// that type from the list request.
class AlertTypesPage extends StatelessWidget {
  const AlertTypesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = alertsColor;
    final role = model.target?.role;
    model.alignNoticeTypes(role);
    final types = noticeTypesForRole(role);
    final wide = hexWide(MediaQuery.sizeOf(context));
    final frame = hexFrame(
      count: types.length,
      back: HexBack.center,
      wide: wide,
    );
    final back = frame.back!;
    return HexPage(
      slots: [
        backSlot(
          title: alertText(language, 'Назад', 'Back'),
          q: back.$1,
          r: back.$2,
        ),
        for (var i = 0; i < types.length && i < frame.cells.length; i++)
          _type(types[i], frame.cells[i], language, color, model.noticeQuery),
      ],
      onTap: (id) {
        if (id == 'back') {
          popOrHome(context);
          return;
        }
        if (!id.startsWith('type:')) return;
        model.toggleNoticeType(id.substring(5));
      },
    );
  }

  HexSlot _type(
    String type,
    (int, int) at,
    String language,
    Color color,
    NoticeQuery query,
  ) {
    final on = query.types.contains(type);
    return HexSlot(
      id: 'type:$type',
      title: type,
      footer: on
          ? alertText(language, 'Вкл', 'On')
          : alertText(language, 'Выкл', 'Off'),
      color: on ? color : hexMuted,
      q: at.$1,
      r: at.$2,
      icon: noticeIcon(type),
    );
  }
}
