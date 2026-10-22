import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../navigation/sections.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    return ColoredBox(
      color: sceneBackground,
      child: HexScene(
        slots: [
          for (final section in menuSections)
            HexSlot(
              id: section.id,
              title: section.title(language),
              color: section.color,
              q: section.q,
              r: section.r,
              icon: section.icon,
              iconScale: section.iconScale,
            ),
        ],
        onTap: (id) => context.push('/$id'),
      ),
    );
  }
}
