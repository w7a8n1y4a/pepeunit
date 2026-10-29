import 'package:flutter/material.dart';

import '../locale/languages.dart';

class MenuSection {
  const MenuSection({
    required this.id,
    required this.titles,
    required this.color,
    required this.q,
    required this.r,
    required this.icon,
  });

  final String id;
  final Map<String, String> titles;
  final Color color;
  final int q;
  final int r;
  final String icon;

  String title(String language) => phrase(language, titles);
}

const menuSections = <MenuSection>[
  MenuSection(
    id: 'people',
    titles: {'ru': 'Аккаунт', 'en': 'Account'},
    color: Color(0xFFFF3333),
    q: 0,
    r: 0,
    icon: 'assets/icons/account.svg',
  ),
  MenuSection(
    id: 'units',
    titles: {'ru': 'Аппараты', 'en': 'Units'},
    color: Color(0xFFFF0080),
    q: 1,
    r: -1,
    icon: 'assets/icons/micro.svg',
  ),
  MenuSection(
    id: 'peers',
    titles: {'ru': 'Сеть', 'en': 'Network'},
    color: Color(0xFFFF9800),
    q: 0,
    r: -1,
    icon: 'assets/icons/instances.svg',
  ),
  MenuSection(
    id: 'registry',
    titles: {'ru': 'Репозитории', 'en': 'Repositories'},
    color: Color(0xFF7F00FF),
    q: 1,
    r: 0,
    icon: 'assets/icons/copy.svg',
  ),
  MenuSection(
    id: 'dashboards',
    titles: {'ru': 'Панели', 'en': 'Dashboards'},
    color: Color(0xFFFFFF33),
    q: -1,
    r: 0,
    icon: 'assets/icons/panel.svg',
  ),
  MenuSection(
    id: 'alerts',
    titles: {'ru': 'Уведомления', 'en': 'Alerts'},
    color: Color(0xFF2196F3),
    q: -1,
    r: 1,
    icon: 'assets/icons/notifications.svg',
  ),
  MenuSection(
    id: 'library',
    titles: {'ru': 'Библиотека', 'en': 'Library'},
    color: Color(0xFF4CAF50),
    q: 0,
    r: 1,
    icon: 'assets/icons/library.svg',
  ),
];

MenuSection? sectionById(String id) {
  for (final section in menuSections) {
    if (section.id == id) return section;
  }
  return null;
}

Color get peopleColor => sectionById('people')!.color;
