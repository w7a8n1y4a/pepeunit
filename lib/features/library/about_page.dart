import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../client_version.dart';
import '../../hive/hex_scene.dart';
import '../../instances/link.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../hex_page.dart';
import 'library_menu_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = cardBoard(const [
      'version',
      'apps',
      'social',
      'support',
    ], wide: wide);
    return HexPage(
      slots: [
        for (final slot in board)
          switch (slot.id) {
            'back' => backSlot(
              title: libText(language, 'Назад'),
              q: slot.q,
              r: slot.r,
            ),
            'version' => HexSlot(
              id: 'version',
              title: libText(language, 'Версия клиента'),
              color: libraryColor,
              q: slot.q,
              r: slot.r,
              center: clientVersion,
              centerScale: 2.2,
              tappable: false,
            ),
            'apps' => HexSlot(
              id: 'apps',
              title: libText(language, 'Нативные приложения'),
              color: libraryColor,
              q: slot.q,
              r: slot.r,
              icon: 'assets/icons/objects/platform.svg',
            ),
            'social' => HexSlot(
              id: 'social',
              title: libText(language, 'Соцсети'),
              color: libraryColor,
              q: slot.q,
              r: slot.r,
              icon: 'assets/icons/objects/links.svg',
            ),
            _ => HexSlot(
              id: 'support',
              title: libText(language, 'Поддержать проект'),
              color: libraryColor,
              q: slot.q,
              r: slot.r,
              icon: 'assets/icons/services/bitcoin.svg',
            ),
          },
      ],
      onTap: (id) {
        switch (id) {
          case 'back':
            popOrHome(context);
          case 'apps':
            context.push('/library/about/apps');
          case 'social':
            context.push('/library/about/social');
          case 'support':
            context.push('/library/about/support');
        }
      },
    );
  }
}

const _platforms = <({String id, String title, String icon})>[
  (id: 'android', title: 'Android', icon: 'assets/icons/services/android.svg'),
  (id: 'ios', title: 'iOS', icon: 'assets/icons/services/ios.svg'),
  (id: 'linux', title: 'Linux', icon: 'assets/icons/services/linux.svg'),
  (id: 'macos', title: 'macOS', icon: 'assets/icons/services/macos.svg'),
  (id: 'windows', title: 'Windows', icon: 'assets/icons/services/windows.svg'),
];

class NativeAppsPage extends StatelessWidget {
  const NativeAppsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = cardBoard([
      for (final platform in _platforms) platform.id,
    ], wide: wide);
    return HexPage(
      slots: [
        for (final slot in board)
          if (slot.id == 'back')
            backSlot(title: libText(language, 'Назад'), q: slot.q, r: slot.r)
          else
            HexSlot(
              id: slot.id,
              title: _platforms.firstWhere((item) => item.id == slot.id).title,
              color: libraryColor,
              q: slot.q,
              r: slot.r,
              icon: _platforms.firstWhere((item) => item.id == slot.id).icon,
              footer: libText(language, 'Скоро'),
              enabled: false,
            ),
      ],
      onTap: (id) {
        if (id == 'back') popOrHome(context);
      },
    );
  }
}

const _socialLinks = <({String id, String title, String icon, String url})>[
  (
    id: 'gitlab',
    title: 'GitLab',
    icon: 'assets/icons/services/gitlab.svg',
    url: 'https://git.pepemoss.com/pepe/pepeunit/pepeunit',
  ),
  (
    id: 'github',
    title: 'GitHub',
    icon: 'assets/icons/services/github.svg',
    url: 'https://github.com/w7a8n1y4a/pepeunit',
  ),
  (
    id: 'discord',
    title: 'Discord',
    icon: 'assets/icons/services/discord.svg',
    url: 'https://discord.gg/bTAF2mxzuN',
  ),
  (
    id: 'telegram',
    title: 'Telegram',
    icon: 'assets/icons/services/telegram.svg',
    url: 'https://t.me/pepeunit',
  ),
  (
    id: 'youtube',
    title: 'YouTube',
    icon: 'assets/icons/services/youtube.svg',
    url: 'https://www.youtube.com/@pepeunit',
  ),
];

class SocialLinksPage extends StatelessWidget {
  const SocialLinksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = cardBoard([
      for (final link in _socialLinks) link.id,
    ], wide: wide);
    return HexPage(
      slots: [
        for (final slot in board)
          if (slot.id == 'back')
            backSlot(title: libText(language, 'Назад'), q: slot.q, r: slot.r)
          else
            HexSlot(
              id: slot.id,
              title: _socialLinks
                  .firstWhere((link) => link.id == slot.id)
                  .title,
              color: libraryColor,
              q: slot.q,
              r: slot.r,
              icon: _socialLinks.firstWhere((link) => link.id == slot.id).icon,
            ),
      ],
      onTap: (id) {
        if (id == 'back') {
          popOrHome(context);
          return;
        }
        for (final link in _socialLinks) {
          if (link.id == id) launchExternal(Uri.parse(link.url));
        }
      },
    );
  }
}
