import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
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
    return ColoredBox(
      color: sceneBackground,
      child: HexScene(
        slots: [
          HexSlot(id: sectionId, title: title, color: section?.color ?? const Color(0xFFA1A1AA), q: 0, r: 0, icon: section?.icon),
          HexSlot(id: 'soon', title: soon, color: const Color(0xFFA1A1AA), q: 1, r: -1),
          HexSlot(id: 'back', title: back, color: const Color(0xFFA1A1AA), q: 0, r: 1, icon: 'assets/icons/back.svg'),
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
