import 'dart:convert';

import '../locale/languages.dart';
import 'unit.dart';

/// Free, used and total flash bytes from a `statvfs` block.
class FlashUse {
  const FlashUse({required this.total, required this.free, required this.used});

  final double total;
  final double free;
  final double used;
}

/// Fragment size, block count, free blocks, blocks available to the unit.
FlashUse? flashUse(List<num> statvfs) {
  if (statvfs.length < 5) return null;
  final frsize = statvfs[1].toDouble();
  final blocks = statvfs[2].toDouble();
  final bfree = statvfs[3].toDouble();
  final bavail = statvfs[4].toDouble();
  if (frsize <= 0 || blocks < 0) return null;
  final total = blocks * frsize;
  final free = bavail * frsize;
  final used = (blocks - bfree) * frsize;
  if (total <= 0 && free <= 0) return null;
  return FlashUse(
    total: total,
    free: free < 0 ? 0 : free,
    used: used < 0 ? 0 : used,
  );
}

String byteText(num? value, String language) {
  if (value == null) return '—';
  var n = value.toDouble();
  if (n < 0) n = 0;
  const ru = ['Б', 'КБ', 'МБ', 'ГБ'];
  const en = ['B', 'KB', 'MB', 'GB'];
  var step = 0;
  while (n >= 1024 && step < 3) {
    n /= 1024;
    step++;
  }
  final unit = phrase(language, {'ru': ru[step], 'en': en[step]});
  if (step == 0) return '${n.round()} $unit';
  final shown = n.toStringAsFixed(n >= 10 ? 0 : 1);
  final trimmed = shown.endsWith('.0')
      ? shown.substring(0, shown.length - 2)
      : shown;
  return '$trimmed $unit';
}

String freqText(num? freq, String language) {
  if (freq == null) return '—';
  final hz = freq.toDouble();
  if (hz >= 1000000) {
    return '${_compact(hz / 1000000)} ${phrase(language, {'ru': 'МГц', 'en': 'MHz'})}';
  }
  if (hz >= 1000) {
    return '${_compact(hz / 1000)} ${phrase(language, {'ru': 'кГц', 'en': 'kHz'})}';
  }
  return '${hz.round()} ${phrase(language, {'ru': 'Гц', 'en': 'Hz'})}';
}

String _compact(double value) {
  final shown = value.toStringAsFixed(value >= 10 ? 0 : 1);
  if (shown.endsWith('.0')) return shown.substring(0, shown.length - 2);
  return shown;
}

/// Clock `HH:MM UTC` when [millis] is a unix stamp, otherwise uptime.
String? deviceTimeEdge(num? millis, String language) {
  if (millis == null) return null;
  final ms = millis.round();
  if (ms >= 1000000000000) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm UTC';
  }
  if (ms < 0) return null;
  final total = ms ~/ 1000;
  final days = total ~/ 86400;
  final hours = (total % 86400) ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  String mark(String ru, String en) => phrase(language, {'ru': ru, 'en': en});
  if (days > 0) return '$days${mark('д', 'd')} $hours${mark('ч', 'h')}';
  if (hours > 0) return '$hours${mark('ч', 'h')} $minutes${mark('м', 'm')}';
  if (minutes > 0) return '$minutes${mark('м', 'm')} $seconds${mark('с', 's')}';
  return '$seconds${mark('с', 's')}';
}

List<String> deviceTimeLines(num? millis, String language) {
  final edge = deviceTimeEdge(millis, language);
  if (millis == null || edge == null) return const ['—'];
  final ms = millis.round();
  if (ms >= 1000000000000) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
    final date =
        '${dt.year}.${dt.month.toString().padLeft(2, '0')}.${dt.day.toString().padLeft(2, '0')}';
    final clock =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
    return ['$date $clock UTC'];
  }
  final total = ms ~/ 1000;
  final days = total ~/ 86400;
  final hours = (total % 86400) ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  final seconds = total % 60;
  String mark(String ru, String en) => phrase(language, {'ru': ru, 'en': en});
  final clock =
      '$days${mark('д', 'd')} $hours${mark('ч', 'h')} $minutes${mark('м', 'm')} $seconds${mark('с', 's')}';
  return [
    clock,
    phrase(language, {'ru': 'с запуска', 'en': 'since start'}),
  ];
}

/// Free RAM, free flash (or used RAM when flash is absent) and the crystal.
List<String> unitGlance(Unit unit, String language) {
  final live = unit.state;
  final flash = flashUse(live?.statvfs ?? const []);
  final second = flash == null
      ? '${phrase(language, {'ru': 'Занято', 'en': 'Used'})} ${byteText(live?.memAlloc, language)}'
      : 'Flash ${byteText(flash.free, language)}';
  return [
    'RAM ${byteText(live?.memFree, language)}',
    second,
    freqText(live?.freq, language),
  ];
}

String _deviceCommit(Unit unit) {
  final live = unit.state?.commit?.trim() ?? '';
  if (live.isNotEmpty) return live;
  return unit.currentCommit?.trim() ?? '';
}

List<String> updateLines(Unit unit, String language) {
  final device = _deviceCommit(unit);
  final target = unit.commit?.trim() ?? '';
  return [
    '${phrase(language, {'ru': 'Устройство', 'en': 'Device'})} ${device.isEmpty ? '—' : shortCommit(device)}',
    '${phrase(language, {'ru': 'Цель', 'en': 'Target'})} ${target.isEmpty ? '—' : shortCommit(target)}',
    firmwareStatusLabel(language, unit.firmwareStatus),
    if ((unit.firmwareError ?? '').trim().isNotEmpty)
      unit.firmwareError!.trim(),
  ];
}

String updateCopy(Unit unit) {
  final device = _deviceCommit(unit);
  final target = unit.commit?.trim() ?? '';
  return [
    if (device.isNotEmpty) device,
    if (target.isNotEmpty) target,
    if ((unit.firmwareError ?? '').trim().isNotEmpty)
      unit.firmwareError!.trim(),
  ].join('\n');
}

List<String> networkLines(Unit unit, String language) {
  final rows = unit.state?.ifconfig ?? const <String>[];
  if (rows.isEmpty) return const ['—'];
  final labels = [
    'IP',
    phrase(language, {'ru': 'Маска', 'en': 'Mask'}),
    phrase(language, {'ru': 'Шлюз', 'en': 'Gateway'}),
    'DNS',
  ];
  return [
    for (var i = 0; i < rows.length; i++)
      '${i < labels.length ? labels[i] : '${i + 1}'} ${rows[i]}',
  ];
}

List<String> ramLines(Unit unit, String language) {
  final live = unit.state;
  return [
    '${phrase(language, {'ru': 'Свободно', 'en': 'Free'})} ${byteText(live?.memFree, language)}',
    '${phrase(language, {'ru': 'Занято', 'en': 'Used'})} ${byteText(live?.memAlloc, language)}',
  ];
}

List<String> flashLines(Unit unit, String language) {
  final flash = flashUse(unit.state?.statvfs ?? const []);
  if (flash == null) return const ['—'];
  return [
    '${phrase(language, {'ru': 'Всего', 'en': 'Total'})} ${byteText(flash.total, language)}',
    '${phrase(language, {'ru': 'Свободно', 'en': 'Free'})} ${byteText(flash.free, language)}',
    '${phrase(language, {'ru': 'Занято', 'en': 'Used'})} ${byteText(flash.used, language)}',
  ];
}

/// Pretty text for the unit storage. JSON is indented by 4. Base64 is
/// decoded first, and decoded JSON is indented the same way.
String presentStorage(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return '';
  final direct = _prettyJson(text);
  if (direct != null) return direct;
  final decoded = _decodeBase64(text);
  if (decoded == null) return text;
  return _prettyJson(decoded) ?? decoded;
}

String? _prettyJson(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  final start = trimmed[0];
  if (start != '{' && start != '[') return null;
  try {
    final value = jsonDecode(trimmed);
    if (value is! Map && value is! List) return null;
    return const JsonEncoder.withIndent('    ').convert(value);
  } catch (_) {
    return null;
  }
}

String? _decodeBase64(String text) {
  final compact = text.replaceAll(RegExp(r'\s+'), '');
  if (compact.length < 16 || compact.length % 4 != 0) return null;
  if (!RegExp(r'^[A-Za-z0-9+/]+={0,2}$').hasMatch(compact)) return null;
  try {
    final bytes = base64.decode(compact);
    if (bytes.isEmpty || bytes.contains(0)) return null;
    return utf8.decode(bytes);
  } catch (_) {
    return null;
  }
}

/// Where a JSON note points, and the note itself.
class EnvNote {
  const EnvNote({required this.line, required this.text});

  final int line;
  final String text;
}

/// A short JSON syntax note. Null when [raw] is an object.
EnvNote? envIssue(String language, String raw) {
  if (raw.trim().isEmpty) {
    return EnvNote(
      line: 1,
      text: phrase(language, {'ru': 'Строка 1: пусто', 'en': 'Line 1: empty'}),
    );
  }
  try {
    final value = jsonDecode(raw);
    if (value is! Map) {
      final line = _lineAt(raw, raw.indexOf(RegExp(r'\S')));
      return EnvNote(
        line: line,
        text: phrase(language, {
          'ru': 'Строка $line: нужен объект',
          'en': 'Line $line: an object is required',
        }),
      );
    }
    for (final key in value.keys) {
      if ('$key'.isEmpty) {
        return EnvNote(
          line: 1,
          text: phrase(language, {'ru': 'Пустой ключ', 'en': 'Empty key'}),
        );
      }
    }
    return null;
  } on FormatException catch (error) {
    final line = _causeLine(raw, error.offset);
    final key = _keyAt(raw, line);
    final hint = _jsonHint(language, error.message);
    final where = key == null
        ? phrase(language, {'ru': 'Строка $line', 'en': 'Line $line'})
        : phrase(language, {
            'ru': 'Строка $line, ключ $key',
            'en': 'Line $line, key $key',
          });
    return EnvNote(line: line, text: '$where: $hint');
  }
}

Map<String, Object?>? envObject(String raw) {
  try {
    final value = jsonDecode(raw);
    if (value is! Map) return null;
    return {for (final entry in value.entries) '${entry.key}': entry.value};
  } catch (_) {
    return null;
  }
}

String envText(Map<String, Object?> env) =>
    const JsonEncoder.withIndent('    ').convert(env);

int _lineAt(String text, int? offset) {
  if (offset == null || offset < 0) return 1;
  var line = 1;
  final end = offset < text.length ? offset : text.length;
  for (var i = 0; i < end; i++) {
    if (text.codeUnitAt(i) == 10) line++;
  }
  return line;
}

/// The parser stops on the next brace. The broken line is the one before it.
int _causeLine(String text, int? offset) {
  final line = _lineAt(text, offset);
  final lines = text.split('\n');
  if (line < 1 || line > lines.length) return line;
  final trimmed = lines[line - 1].trim();
  if (trimmed != '}' && trimmed != ']' && trimmed != '{' && trimmed != '[') {
    return line;
  }
  for (var i = line - 1; i >= 1; i--) {
    if (lines[i - 1].trim().isNotEmpty) return i;
  }
  return line;
}

String? _keyAt(String text, int line) {
  final lines = text.split('\n');
  final pattern = RegExp(r'"((?:\\.|[^"\\])*)"');
  for (var i = line; i >= 1 && i > line - 3; i--) {
    if (i > lines.length) continue;
    final key = pattern.firstMatch(lines[i - 1])?.group(1);
    if (key != null && key.isNotEmpty) return key;
  }
  return null;
}

String _jsonHint(String language, String message) {
  final lower = message.toLowerCase();
  if (lower.contains('unterminated')) {
    return phrase(language, {
      'ru': 'строка не закрыта',
      'en': 'unterminated string',
    });
  }
  if (lower.contains('unexpected') || lower.contains('character')) {
    return phrase(language, {
      'ru': 'неожиданный символ',
      'en': 'unexpected character',
    });
  }
  if (lower.contains('expected')) {
    return phrase(language, {
      'ru': 'ожидалось значение',
      'en': 'a value was expected',
    });
  }
  return phrase(language, {'ru': 'ошибка синтаксиса', 'en': 'syntax error'});
}
