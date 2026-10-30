import 'package:flutter/material.dart';

import '../../locale/languages.dart';
import '../../navigation/sections.dart';

Color get alertsColor => sectionById('alerts')!.color;

String alertText(String language, String ru, String en) =>
    phrase(language, {'ru': ru, 'en': en});

/// Monospace for notice tables and the test log. OpenGost has no mono face.
const noticeMonoFamily = 'JetBrains Mono';

TextStyle noticeMono(double fontSize, {Color color = const Color(0xFFFFFFFF)}) {
  return TextStyle(
    color: color,
    fontFamily: noticeMonoFamily,
    fontSize: fontSize,
    height: 1.35,
    decoration: TextDecoration.none,
  );
}

String noticeReadLabel(String language, String read) {
  switch (read) {
    case 'all':
      return alertText(language, 'Все', 'All');
    case 'read':
      return alertText(language, 'Прочитанные', 'Read');
    default:
      return alertText(language, 'Не прочитанные', 'Unread');
  }
}

String noticeStatusLabel(String language, {required bool read}) {
  if (read) return alertText(language, 'Прочитана', 'Read');
  return alertText(language, 'Не прочитана', 'Unread');
}

String noticeIcon(String type) {
  switch (type) {
    case 'InstanceDailyState':
      return 'assets/icons/exclaim.svg';
    case 'UnitDailySummary':
      return 'assets/icons/micro.svg';
    case 'DataPipeAlert':
      return 'assets/icons/pipe.svg';
    case 'IntegrationTests':
      return 'assets/icons/rorschach.svg';
    case 'ScanAllPeers':
      return 'assets/icons/instances.svg';
    case 'ScanPeer':
      return 'assets/icons/instance.svg';
    case 'UpdateAllRepos':
      return 'assets/icons/reload.svg';
    case 'UpdateRepo':
      return 'assets/icons/repo.svg';
    case 'UpdateUnitsFirmware':
      return 'assets/icons/rocket.svg';
    case 'UpdateAllUnitsFirmware':
      return 'assets/icons/send.svg';
    case 'RebootInstance':
      return 'assets/icons/power.svg';
    default:
      return 'assets/icons/notifications.svg';
  }
}
