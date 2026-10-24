import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../account/icon_file.dart';
import '../../account/key_mark.dart';
import '../../account/vault.dart';
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
            _slot(section, model.vault, language),
        ],
        onTap: (id) => context.push('/$id'),
      ),
    );
  }
}

HexSlot _slot(MenuSection section, Vault vault, String language) {
  final signedIn = section.id == 'people' && vault.hasKey;
  final png = signedIn ? iconBytes(vault.iconPng) : null;
  return HexSlot(
    id: section.id,
    title: signedIn && vault.login.isNotEmpty
        ? vault.login
        : section.title(language),
    footer: signedIn ? keyMarkFromBase64(vault.publicKey) : null,
    color: section.color,
    q: section.q,
    r: section.r,
    icon: png == null ? section.icon : null,
    image: png,
    iconScale: section.iconScale,
  );
}
