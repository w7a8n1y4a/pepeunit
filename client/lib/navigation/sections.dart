import 'package:flutter/material.dart';

class MenuSection {
  const MenuSection({
    required this.id,
    required this.titleRu,
    required this.titleEn,
    required this.color,
    required this.q,
    required this.r,
    required this.icon,
    this.iconScale = 1,
  });

  final String id;
  final String titleRu;
  final String titleEn;
  final Color color;
  final int q;
  final int r;
  final String icon;
  final double iconScale;

  String title(String language) => language == 'en' ? titleEn : titleRu;
}

const menuSections = <MenuSection>[
  MenuSection(
    id: 'people',
    titleRu: 'Аккаунт',
    titleEn: 'Account',
    color: Color(0xFFFF3333),
    q: 0,
    r: 0,
    icon: 'assets/icons/signin.svg',
  ),
  MenuSection(
    id: 'units',
    titleRu: 'Устройства',
    titleEn: 'Units',
    color: Color(0xFFFF0080),
    q: 1,
    r: -1,
    icon: 'assets/icons/micro.svg',
  ),
  MenuSection(
    id: 'peers',
    titleRu: 'Инстансы',
    titleEn: 'Instances',
    color: Color(0xFFFF9800),
    q: 0,
    r: -1,
    icon: 'assets/icons/instances.svg',
    iconScale: 0.81,
  ),
  MenuSection(
    id: 'registry',
    titleRu: 'Реестр',
    titleEn: 'Registry',
    color: Color(0xFF7F00FF),
    q: 1,
    r: 0,
    icon: 'assets/icons/copy.svg',
  ),
  MenuSection(
    id: 'dashboards',
    titleRu: 'Панели',
    titleEn: 'Dashboards',
    color: Color(0xFFFFFF33),
    q: -1,
    r: 0,
    icon: 'assets/icons/panel.svg',
  ),
  MenuSection(
    id: 'alerts',
    titleRu: 'Уведомления',
    titleEn: 'Alerts',
    color: Color(0xFF2196F3),
    q: -1,
    r: 1,
    icon: 'assets/icons/notifications.svg',
  ),
  MenuSection(
    id: 'library',
    titleRu: 'Библиотека',
    titleEn: 'Library',
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
