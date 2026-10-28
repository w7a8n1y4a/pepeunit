import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../hive/hex_order.dart';
import '../../hive/hex_scene.dart';
import '../../navigation/back.dart';
import '../../navigation/sections.dart';
import '../hex_page.dart';

class PlaceholderPage extends StatelessWidget {
  const PlaceholderPage({required this.sectionId, super.key});

  final String sectionId;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final section = sectionById(sectionId);
    final title = section?.title(language) ?? sectionId;
    final soon = language == 'en' ? 'Soon' : 'Скоро';
    final back = language == 'en' ? 'Back' : 'Назад';
    final frame = hexFrame(
      count: 2,
      back: HexBack.center,
      wide: hexWide(MediaQuery.sizeOf(context)),
    );
    final at = frame.cells;
    final backAt = frame.back!;
    return HexPage(
      slots: [
        HexSlot(
          id: sectionId,
          title: title,
          color: section?.color ?? hexMuted,
          q: at[0].$1,
          r: at[0].$2,
          icon: section?.icon,
        ),
        HexSlot(
          id: 'soon',
          title: soon,
          color: hexMuted,
          q: at[1].$1,
          r: at[1].$2,
        ),
        backSlot(title: back, q: backAt.$1, r: backAt.$2),
      ],
      onTap: (id) {
        if (id == 'back') popOrHome(context);
      },
    );
  }
}
