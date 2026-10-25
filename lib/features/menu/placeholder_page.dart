import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_order.dart';
import '../../hive/hex_scene.dart';
import '../../navigation/sections.dart';

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
    return ColoredBox(
      color: sceneBackground,
      child: HexScene(
        slots: [
          HexSlot(
            id: sectionId,
            title: title,
            color: section?.color ?? const Color(0xFFA1A1AA),
            q: at[0].$1,
            r: at[0].$2,
            icon: section?.icon,
            iconScale: section?.iconScale ?? 1,
          ),
          HexSlot(
            id: 'soon',
            title: soon,
            color: const Color(0xFFA1A1AA),
            q: at[1].$1,
            r: at[1].$2,
          ),
          HexSlot(
            id: 'back',
            title: back,
            color: const Color(0xFFA1A1AA),
            q: backAt.$1,
            r: backAt.$2,
            icon: 'assets/icons/back.svg',
          ),
        ],
        onTap: (id) {
          if (id == 'back') {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          }
        },
      ),
    );
  }
}
