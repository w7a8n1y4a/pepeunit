import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../account/icon_file.dart';
import '../../account/key_mark.dart';
import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/sections.dart';
import '../../registry/repo.dart';
import '../hex_page.dart';
import '../network/network_chrome.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    return HexPage(
      slots: [
        for (final section in menuSections) _slot(section, model, language),
      ],
      onTap: (id) {
        if (!menuSectionEnabled(
          id,
          hasTarget: model.target != null,
          signedIn: model.target?.signedIn ?? false,
          notifications: model.target?.notifications,
          grafana: model.target?.grafana,
        )) {
          return;
        }
        context.push('/$id');
      },
    );
  }
}

HexSlot _slot(MenuSection section, AppModel model, String language) {
  final vault = model.vault;
  final target = vault.target;
  if (section.id == 'peers' && target != null) {
    return instanceMark(
      id: section.id,
      url: target.url,
      language: language,
      q: section.q,
      r: section.r,
      color: section.color,
      current: true,
      version: model.portraitOf(target.url)?.version,
      image: model.iconOf(target.url),
    );
  }
  final signedIn = section.id == 'people' && vault.hasKey;
  final png = signedIn ? iconBytes(vault.iconPng) : null;
  final portrait = target == null ? null : model.portraitOf(target.url);
  final repoCount = section.id == 'registry' ? portrait?.repos : null;
  final unitCount = section.id == 'units' ? portrait?.units : null;
  final noticeTotal = section.id == 'alerts' ? model.noticeTotal : null;
  final counted = noticeTotal ?? repoCount ?? unitCount;
  return HexSlot(
    id: section.id,
    title: signedIn && vault.login.isNotEmpty
        ? vault.login
        : section.title(language),
    footer: signedIn
        ? keyMarkFromBase64(vault.publicKey)
        : (counted == null ? null : pieceCount(language, counted)),
    color: section.color,
    q: section.q,
    r: section.r,
    icon: png == null ? section.icon : null,
    image: png,
    badge: section.id == 'alerts' && model.unreadCount > 0
        ? model.unreadCount
        : null,
    enabled: menuSectionEnabled(
      section.id,
      hasTarget: target != null,
      signedIn: target?.signedIn ?? false,
      notifications: target?.notifications,
      grafana: target?.grafana,
    ),
  );
}
