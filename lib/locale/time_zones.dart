import 'languages.dart';

/// One fixed UTC offset and the largest city people use as its name.
/// The client displays clocks with this offset. It does not follow daylight saving.
class TimeZoneOption {
  const TimeZoneOption(this.minutes, this.cities);

  final int minutes;
  final Map<String, String> cities;

  String label(String language) =>
      '${phrase(language, cities)} ${formatUtcOffset(minutes)}';
}

const timeZones = <TimeZoneOption>[
  TimeZoneOption(-660, {'ru': 'Паго-Паго', 'en': 'Pago Pago'}),
  TimeZoneOption(-600, {'ru': 'Гонолулу', 'en': 'Honolulu'}),
  TimeZoneOption(-570, {'ru': 'Таиохаэ', 'en': 'Taiohae'}),
  TimeZoneOption(-540, {'ru': 'Анкоридж', 'en': 'Anchorage'}),
  TimeZoneOption(-480, {'ru': 'Лос-Анджелес', 'en': 'Los Angeles'}),
  TimeZoneOption(-420, {'ru': 'Денвер', 'en': 'Denver'}),
  TimeZoneOption(-360, {'ru': 'Мехико', 'en': 'Mexico City'}),
  TimeZoneOption(-300, {'ru': 'Нью-Йорк', 'en': 'New York'}),
  TimeZoneOption(-240, {'ru': 'Каракас', 'en': 'Caracas'}),
  TimeZoneOption(-210, {'ru': 'Сент-Джонс', 'en': "St. John's"}),
  TimeZoneOption(-180, {'ru': 'Сан-Паулу', 'en': 'Sao Paulo'}),
  TimeZoneOption(-120, {'ru': 'Норонья', 'en': 'Noronha'}),
  TimeZoneOption(-60, {'ru': 'Прая', 'en': 'Praia'}),
  TimeZoneOption(0, {'ru': 'Лондон', 'en': 'London'}),
  TimeZoneOption(60, {'ru': 'Лагос', 'en': 'Lagos'}),
  TimeZoneOption(120, {'ru': 'Каир', 'en': 'Cairo'}),
  TimeZoneOption(180, {'ru': 'Москва', 'en': 'Moscow'}),
  TimeZoneOption(210, {'ru': 'Тегеран', 'en': 'Tehran'}),
  TimeZoneOption(240, {'ru': 'Дубай', 'en': 'Dubai'}),
  TimeZoneOption(270, {'ru': 'Кабул', 'en': 'Kabul'}),
  TimeZoneOption(300, {'ru': 'Карачи', 'en': 'Karachi'}),
  TimeZoneOption(330, {'ru': 'Мумбаи', 'en': 'Mumbai'}),
  TimeZoneOption(345, {'ru': 'Катманду', 'en': 'Kathmandu'}),
  TimeZoneOption(360, {'ru': 'Дакка', 'en': 'Dhaka'}),
  TimeZoneOption(390, {'ru': 'Янгон', 'en': 'Yangon'}),
  TimeZoneOption(420, {'ru': 'Джакарта', 'en': 'Jakarta'}),
  TimeZoneOption(480, {'ru': 'Шанхай', 'en': 'Shanghai'}),
  TimeZoneOption(540, {'ru': 'Токио', 'en': 'Tokyo'}),
  TimeZoneOption(570, {'ru': 'Аделаида', 'en': 'Adelaide'}),
  TimeZoneOption(600, {'ru': 'Сидней', 'en': 'Sydney'}),
  TimeZoneOption(630, {'ru': 'Лорд-Хау', 'en': 'Lord Howe'}),
  TimeZoneOption(660, {'ru': 'Нумеа', 'en': 'Noumea'}),
  TimeZoneOption(720, {'ru': 'Окленд', 'en': 'Auckland'}),
  TimeZoneOption(765, {'ru': 'Чатем', 'en': 'Chatham'}),
  TimeZoneOption(780, {'ru': 'Апиа', 'en': 'Apia'}),
  TimeZoneOption(840, {'ru': 'Киритимати', 'en': 'Kiritimati'}),
];

/// `+3`, `-5`, `+5:30`, `+0`.
String formatUtcOffset(int minutes) {
  final sign = minutes < 0 ? '-' : '+';
  final absolute = minutes.abs();
  final hours = absolute ~/ 60;
  final rest = absolute % 60;
  if (rest == 0) return '$sign$hours';
  return '$sign$hours:${rest.toString().padLeft(2, '0')}';
}

int zoneMinutes(String stored) {
  if (stored == 'UTC' || stored.isEmpty) return 0;
  return int.tryParse(stored) ?? 0;
}

String zoneLabel(String stored, String language) {
  final minutes = zoneMinutes(stored);
  for (final zone in timeZones) {
    if (zone.minutes == minutes) return zone.label(language);
  }
  return 'UTC ${formatUtcOffset(minutes)}';
}

/// Steps east when [direction] is positive, and wraps around the list.
int stepZone(String stored, int direction) {
  final minutes = zoneMinutes(stored);
  var index = 0;
  for (var i = 0; i < timeZones.length; i++) {
    if (timeZones[i].minutes == minutes) {
      index = i;
      break;
    }
  }
  final count = timeZones.length;
  final next = (index + direction) % count;
  return timeZones[next < 0 ? next + count : next].minutes;
}
