import 'package:flutter/material.dart';

import '../../locale/languages.dart';
import '../../navigation/sections.dart';

Color get alertsColor => sectionById('alerts')!.color;

String noticeReadLabel(String language, String read) {
  switch (read) {
    case 'all':
      return localized(language, 'Все', 'All');
    case 'read':
      return localized(language, 'Прочитанные', 'Read');
    default:
      return localized(language, 'К прочтению', 'To read');
  }
}

String noticeStatusLabel(String language, {required bool read}) {
  if (read) return localized(language, 'Прочитана', 'Read');
  return localized(language, 'Не прочитана', 'Unread');
}

String noticeIcon(String type) {
  switch (type) {
    case 'InstanceDailyState':
      return 'assets/icons/status/exclaim.svg';
    case 'UnitDailySummary':
      return 'assets/icons/sections/micro.svg';
    case 'DataPipeAlert':
      return 'assets/icons/objects/pipe.svg';
    case 'IntegrationTests':
      return 'assets/icons/objects/rorschach.svg';
    case 'ScanAllPeers':
      return 'assets/icons/sections/instances.svg';
    case 'ScanPeer':
      return 'assets/icons/objects/instance.svg';
    case 'UpdateAllRepos':
      return 'assets/icons/actions/reload.svg';
    case 'UpdateRepo':
      return 'assets/icons/objects/repo.svg';
    case 'UpdateUnitsFirmware':
      return 'assets/icons/objects/rocket.svg';
    case 'UpdateAllUnitsFirmware':
      return 'assets/icons/actions/send.svg';
    case 'RebootInstance':
      return 'assets/icons/actions/power.svg';
    default:
      return 'assets/icons/sections/notifications.svg';
  }
}
