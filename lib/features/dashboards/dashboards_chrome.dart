import 'package:flutter/material.dart';

import '../../alerts/notice.dart';
import '../../dashboards/dashboard.dart';
import '../../hive/hex_scene.dart';
import '../../locale/languages.dart';
import '../../navigation/sections.dart';

Color get dashboardsColor => sectionById('dashboards')!.color;

/// Success reads as done, an error as an error. A draft and a dashboard in
/// flight keep the plain label color.
Color dashboardStatusColor(String? status) {
  switch (status) {
    case 'Success':
      return addColor;
    case 'Error':
      return errorColor;
    default:
      return const Color(0xFFFFFFFF);
  }
}

/// Words for the page window's order cell: `desc` is newest first.
String dashboardOrderLabel(String language, String order) {
  if (order == 'asc') return localized(language, 'Старые', 'Old');
  return localized(language, 'Новые', 'New');
}

/// Name and title of a dashboard or a panel: `4..20` of letters, digits, `_`,
/// `.` and `-`. The backend refuses any other text.
final dashboardNamePattern = RegExp(r'^[A-Za-z0-9_.-]{4,20}$');

bool dashboardNameOk(String name) => dashboardNamePattern.hasMatch(name.trim());

String dashboardNameIssue(String language) => localized(
  language,
  'От 4 до 20: буквы, цифры, _ . -',
  '4 to 20: letters, digits, _ . -',
);

/// Menu of the section: add a dashboard, then search.
const dashboardsMenuIds = ['add', 'search'];

/// Cells of one dashboard card, around Back. Opening it in Grafana needs a
/// sync first, so that cell stays in place and is only switched off.
const dashboardMenuIds = ['card', 'info', 'panels', 'sync', 'open', 'delete'];

/// Cells of one panel card, around Back.
const panelMenuIds = ['card', 'nodes', 'delete'];

/// Search card and the identity cell of one dashboard: name above, the sync
/// state on the lower right and the Grafana version on the lower left.
HexSlot dashboardMark({
  required String id,
  required Dashboard dashboard,
  required String language,
  required int q,
  required int r,
  bool tappable = true,
  bool busy = false,
}) {
  return HexSlot(
    id: id,
    title: dashboard.name,
    footer: dashboardStatusLabel(language, dashboard.syncStatus),
    footerColor: dashboardStatusColor(dashboard.syncStatus),
    footerLeft: dashboard.version == null ? null : 'v${dashboard.version}',
    color: dashboardsColor,
    q: q,
    r: r,
    icon: 'assets/icons/sections/panel.svg',
    tappable: tappable,
    busy: busy,
  );
}

/// Lines of the dashboard info cell: state, Grafana version, last sync.
List<String> dashboardLines(
  Dashboard? dashboard,
  String language,
  String zoneMinutes,
) {
  if (dashboard == null) return const ['—', '—', '—'];
  final when = dashboard.syncAt == null
      ? ''
      : noticeWhen(dashboard.syncAt!, zoneMinutes);
  return [
    dashboardStatusLabel(language, dashboard.syncStatus),
    dashboard.version == null ? '—' : 'Grafana v${dashboard.version}',
    when.isEmpty ? '—' : when,
  ];
}
