import 'dart:convert';

import '../instances/instance.dart';
import '../locale/languages.dart';
import '../locale/time_zones.dart';

class Vault {
  Vault({
    this.publicKey,
    this.secretKey,
    this.login = '',
    this.iconPng,
    this.language = 'ru',
    this.timeZone = '0',
    List<InstanceRecord>? instances,
  }) : instances =
           instances ?? [InstanceRecord(url: defaultInstanceUrl, active: true)];

  String? publicKey;
  String? secretKey;
  String login;
  String? iconPng;
  String language;
  String timeZone;
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
    for (final instance in instances) {
      instance.token = null;
      instance.userUuid = null;
    }
  }

  InstanceRecord? get active {
    for (final instance in instances) {
      if (instance.active) return instance;
    }
    return instances.isEmpty ? null : instances.first;
  }

  factory Vault.fresh() => Vault();

  Vault copy() {
    return Vault(
      publicKey: publicKey,
      secretKey: secretKey,
      login: login,
      iconPng: iconPng,
      language: language,
      timeZone: timeZone,
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
      'language': language,
      'timeZone': timeZone,
      'instances': [for (final instance in instances) instance.toJson()],
    };
  }

  factory Vault.decode(String raw) =>
      Vault.fromJson(jsonDecode(raw) as Map<String, Object?>);

  factory Vault.fromJson(Map<String, Object?> json) {
    final rawInstances = json['instances'] as List<Object?>? ?? const [];
    final instances = [
      for (final item in rawInstances)
        _migrateInstance(
          InstanceRecord.fromJson((item as Map).cast<String, Object?>()),
        ),
    ];
    return Vault(
      publicKey: json['publicKey'] as String?,
      secretKey: json['secretKey'] as String?,
      login: json['login'] as String? ?? '',
      iconPng: json['iconPng'] as String?,
      language: _language(json['language'] as String?),
      timeZone: _timeZone(json['timeZone'] as String?),
      instances: instances.isEmpty
          ? [InstanceRecord(url: defaultInstanceUrl, active: true)]
          : instances,
    );
  }
}

String _language(String? raw) {
  if (raw != null && knownLanguage(raw)) return raw;
  return 'ru';
}

String _timeZone(String? raw) => zoneMinutes(raw ?? '0').toString();

InstanceRecord _migrateInstance(InstanceRecord instance) {
  if (instance.url != 'https://localunit.pepeunit.com') return instance;
  return InstanceRecord(
    url: defaultInstanceUrl,
    token: instance.token,
    userUuid: instance.userUuid,
    active: instance.active,
  );
}
