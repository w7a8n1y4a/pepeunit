import 'dart:convert';

import '../instances/instance.dart';
import '../locale/languages.dart';
import '../locale/time_zones.dart';
import 'alerts.dart';

class Vault {
  Vault({
    this.publicKey,
    this.secretKey,
    this.login = '',
    this.iconPng,
    this.alerts = const AlertPrefs(),
    this.profileSentAt,
    this.registeredAt,
    this.language = 'ru',
    this.timeZone = '0',
    List<String>? allow,
    List<String>? deny,
    List<String>? pinned,
    List<InstanceRecord>? instances,
  }) : allow = allow ?? [],
       deny = deny ?? [],
       pinned = pinned ?? [],
       instances = instances ?? [];

  String? publicKey;
  String? secretKey;
  String login;
  String? iconPng;
  AlertPrefs alerts;

  /// Epoch milliseconds of the last profile send. Limits the next one.
  int? profileSentAt;

  /// Epoch milliseconds of the last registration press. Sign out keeps it.
  int? registeredAt;
  String language;
  String timeZone;

  /// Empty means every discovered instance is admitted.
  final List<String> allow;
  final List<String> deny;
  final List<String> pinned;
  final List<InstanceRecord> instances;

  bool get hasKey =>
      publicKey != null &&
      secretKey != null &&
      publicKey!.isNotEmpty &&
      secretKey!.isNotEmpty;

  /// Drops the global account: keys, profile fields, and instance sessions.
  void clearSession() {
    publicKey = null;
    secretKey = null;
    login = '';
    iconPng = null;
    alerts = const AlertPrefs();
    profileSentAt = null;
    for (final instance in instances) {
      instance.token = null;
      instance.userUuid = null;
      instance.role = null;
    }
  }

  InstanceRecord? get target {
    for (final instance in instances) {
      if (instance.active) return instance;
    }
    return null;
  }

  InstanceRecord? recordFor(String url) {
    for (final instance in instances) {
      if (instance.url == url) return instance;
    }
    return null;
  }

  bool admits(String url) {
    if (deny.contains(url)) return false;
    if (allow.isEmpty) return true;
    return allow.contains(url);
  }

  factory Vault.fresh() => Vault();

  Vault copy() {
    return Vault(
      publicKey: publicKey,
      secretKey: secretKey,
      login: login,
      iconPng: iconPng,
      alerts: alerts,
      profileSentAt: profileSentAt,
      registeredAt: registeredAt,
      language: language,
      timeZone: timeZone,
      allow: [...allow],
      deny: [...deny],
      pinned: [...pinned],
      instances: [for (final instance in instances) instance.copy()],
    );
  }

  String encode() => jsonEncode(toJson());

  Map<String, Object?> toJson() {
    return {
      'publicKey': publicKey,
      'secretKey': secretKey,
      'login': login,
      'iconPng': iconPng,
      'alerts': alerts.toJson(),
      'profileSentAt': profileSentAt,
      'registeredAt': registeredAt,
      'language': language,
      'timeZone': timeZone,
      'allow': allow,
      'deny': deny,
      'pinned': pinned,
      'instances': [for (final instance in instances) instance.toJson()],
    };
  }

  factory Vault.decode(String raw) =>
      Vault.fromJson(jsonDecode(raw) as Map<String, Object?>);

  factory Vault.fromJson(Map<String, Object?> json) {
    final rawInstances = json['instances'] as List<Object?>? ?? const [];
    return Vault(
      publicKey: json['publicKey'] as String?,
      secretKey: json['secretKey'] as String?,
      login: json['login'] as String? ?? '',
      iconPng: json['iconPng'] as String?,
      alerts: AlertPrefs.fromJson(json['alerts']),
      profileSentAt: json['profileSentAt'] as int?,
      registeredAt: json['registeredAt'] as int?,
      language: _language(json['language'] as String?),
      timeZone: _timeZone(json['timeZone'] as String?),
      allow: _urls(json['allow']),
      deny: _urls(json['deny']),
      pinned: _urls(json['pinned']),
      instances: [
        for (final item in rawInstances)
          _migrateInstance(
            InstanceRecord.fromJson((item as Map).cast<String, Object?>()),
          ),
      ],
    );
  }
}

String _language(String? raw) {
  if (raw != null && knownLanguage(raw)) return raw;
  return 'ru';
}

String _timeZone(String? raw) => zoneMinutes(raw ?? '0').toString();

List<String> _urls(Object? raw) {
  if (raw is! List) return [];
  final urls = <String>[];
  for (final item in raw) {
    if (item is! String || item.isEmpty) continue;
    try {
      urls.add(_migrateUrl(item));
    } catch (_) {}
  }
  return urls;
}

InstanceRecord _migrateInstance(InstanceRecord instance) {
  return InstanceRecord(
    url: _migrateUrl(instance.url),
    token: instance.token,
    userUuid: instance.userUuid,
    role: instance.role,
    notifications: instance.notifications,
    grafana: instance.grafana,
    telegram: instance.telegram,
    active: instance.active,
  );
}

String _migrateUrl(String url) {
  if (url == 'https://localunit.pepeunit.com' ||
      url == 'https://localunit.pepeunit.com$instanceCurrentPath') {
    return defaultInstanceUrl;
  }
  try {
    return canonicalInstanceUrl(url);
  } catch (_) {
    return url;
  }
}
