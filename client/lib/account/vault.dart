import 'dart:convert';

import '../instances/instance.dart';

class Vault {
  Vault({
    this.publicKey,
    this.secretKey,
    this.login = '',
    this.iconPng,
    this.language = 'ru',
    this.timeZone = 'UTC',
    List<InstanceRecord>? instances,
  }) : instances = instances ?? [InstanceRecord(url: defaultInstanceUrl, active: true)];

  String? publicKey;
  String? secretKey;
  String login;
  String? iconPng;
  String language;
  String timeZone;
  final List<InstanceRecord> instances;

  bool get hasKey => publicKey != null && secretKey != null && publicKey!.isNotEmpty && secretKey!.isNotEmpty;

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

  factory Vault.decode(String raw) => Vault.fromJson(jsonDecode(raw) as Map<String, Object?>);

  factory Vault.fromJson(Map<String, Object?> json) {
    final rawInstances = json['instances'] as List<Object?>? ?? const [];
    final instances = [
      for (final item in rawInstances) _migrateInstance(InstanceRecord.fromJson((item as Map).cast<String, Object?>())),
    ];
    return Vault(
      publicKey: json['publicKey'] as String?,
      secretKey: json['secretKey'] as String?,
      login: json['login'] as String? ?? '',
      iconPng: json['iconPng'] as String?,
      language: json['language'] as String? ?? 'ru',
      timeZone: json['timeZone'] as String? ?? 'UTC',
      instances: instances.isEmpty ? [InstanceRecord(url: defaultInstanceUrl, active: true)] : instances,
    );
  }
}

InstanceRecord _migrateInstance(InstanceRecord instance) {
  if (instance.url != 'https://localunit.pepeunit.com') return instance;
  return InstanceRecord(
    url: defaultInstanceUrl,
    token: instance.token,
    userUuid: instance.userUuid,
    active: instance.active,
  );
}
