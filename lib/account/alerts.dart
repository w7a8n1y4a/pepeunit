/// Notification preferences kept with the account, like the login and avatar.
///
/// The wire names match `PATCH /notifications/settings`.
class AlertPrefs {
  const AlertPrefs({
    this.scheduled = true,
    this.time = defaultTime,
    this.dataPipe = true,
    this.telegram = true,
  });

  static const defaultTime = '16:00';

  final bool scheduled;
  final String time;
  final bool dataPipe;
  final bool telegram;

  AlertPrefs copyWith({
    bool? scheduled,
    String? time,
    bool? dataPipe,
    bool? telegram,
  }) {
    return AlertPrefs(
      scheduled: scheduled ?? this.scheduled,
      time: time ?? this.time,
      dataPipe: dataPipe ?? this.dataPipe,
      telegram: telegram ?? this.telegram,
    );
  }

  Map<String, Object?> toPatch() {
    return {
      'is_scheduled_alert_enable': scheduled,
      'scheduled_notification_time': time,
      'is_data_pipe_alert_enable': dataPipe,
      'is_telegram_alert_enable': telegram,
    };
  }

  /// Wire shape of `GET /notifications/settings`.
  factory AlertPrefs.fromPatch(Map<String, Object?> json) {
    final rawTime = json['scheduled_notification_time'];
    return AlertPrefs(
      scheduled: json['is_scheduled_alert_enable'] as bool? ?? true,
      time:
          canonicalAlertTime(rawTime is String ? rawTime : null) ?? defaultTime,
      dataPipe: json['is_data_pipe_alert_enable'] as bool? ?? true,
      telegram: json['is_telegram_alert_enable'] as bool? ?? true,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'scheduled': scheduled,
      'time': time,
      'dataPipe': dataPipe,
      'telegram': telegram,
    };
  }

  factory AlertPrefs.fromJson(Object? raw) {
    if (raw is! Map) return const AlertPrefs();
    final json = Map<String, Object?>.from(raw);
    return AlertPrefs(
      scheduled: json['scheduled'] as bool? ?? true,
      time: canonicalAlertTime(json['time'] as String?) ?? defaultTime,
      dataPipe: json['dataPipe'] as bool? ?? true,
      telegram: json['telegram'] as bool? ?? true,
    );
  }
}

final _alertTime = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

/// `HH:MM` in UTC, or null when [raw] is not one.
String? canonicalAlertTime(String? raw) {
  if (raw == null || !_alertTime.hasMatch(raw)) return null;
  return raw;
}

String stepAlertHour(String time, int delta) {
  final parts = _parts(time);
  return _format(_wrap(parts.$1 + delta, 24), parts.$2);
}

String stepAlertMinute(String time, int delta) {
  final parts = _parts(time);
  return _format(parts.$1, _wrap(parts.$2 + delta, 60));
}

/// `m:ss` remaining, rounded up so the last second stays visible.
String cooldownClock(Duration left) {
  final total = left.inMilliseconds <= 0
      ? 0
      : (left.inMilliseconds + 999) ~/ 1000;
  final minutes = total ~/ 60;
  final seconds = total % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

(int, int) _parts(String time) {
  final canonical = canonicalAlertTime(time) ?? AlertPrefs.defaultTime;
  final bits = canonical.split(':');
  return (int.parse(bits[0]), int.parse(bits[1]));
}

int _wrap(int value, int modulo) {
  final next = value % modulo;
  return next < 0 ? next + modulo : next;
}

String _format(int hour, int minute) {
  return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
