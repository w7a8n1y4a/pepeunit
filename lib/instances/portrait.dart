class InstancePortrait {
  const InstancePortrait({
    required this.url,
    this.name = '',
    this.version = '',
    this.description = '',
    this.license = '',
    this.swagger = '',
    this.grafanaUrl = '',
    this.telegramBot = '',
    this.iconUuid,
    this.datapipe,
    this.notifications,
    this.grafana,
    this.prometheus,
    this.telegram,
    this.federation,
    this.users,
    this.units,
    this.repos,
    this.unitIos,
    this.links,
    this.email = '',
    this.telegramContact = '',
    this.latitude,
    this.longitude,
    this.pagination = 100,
    this.mqttHost,
    this.mqttPort,
    this.mqttSecure,
    this.instanceDatetime,
    this.lastStartDatetime,
    this.testsDatetime,
    this.testsStatus,
    this.testsPercent,
  });

  final String url;
  final String name;
  final String version;
  final String description;
  final String license;
  final String swagger;
  final String grafanaUrl;
  final String telegramBot;
  final String? iconUuid;
  final bool? datapipe;
  final bool? notifications;
  final bool? grafana;
  final bool? prometheus;
  final bool? telegram;
  final bool? federation;
  final int? users;
  final int? units;
  final int? repos;
  final int? unitIos;
  final int? links;
  final String email;
  final String telegramContact;
  final double? latitude;
  final double? longitude;
  final int pagination;
  final String? mqttHost;
  final int? mqttPort;
  final bool? mqttSecure;
  final String? instanceDatetime;
  final String? lastStartDatetime;
  final String? testsDatetime;
  final String? testsStatus;
  final double? testsPercent;

  String get iconPath =>
      iconUuid == null ? '' : '/pepeunit/api/v1/icons/$iconUuid';

  InstancePortrait copyWith({
    String? iconUuid,
    bool? datapipe,
    bool? notifications,
    bool? grafana,
    bool? prometheus,
    bool? telegram,
    bool? federation,
    String? email,
    String? telegramContact,
    String? telegramBot,
    double? latitude,
    double? longitude,
    int? pagination,
  }) {
    return InstancePortrait(
      url: url,
      name: name,
      version: version,
      description: description,
      license: license,
      swagger: swagger,
      grafanaUrl: grafanaUrl,
      telegramBot: telegramBot ?? this.telegramBot,
      iconUuid: iconUuid ?? this.iconUuid,
      datapipe: datapipe ?? this.datapipe,
      notifications: notifications ?? this.notifications,
      grafana: grafana ?? this.grafana,
      prometheus: prometheus ?? this.prometheus,
      telegram: telegram ?? this.telegram,
      federation: federation ?? this.federation,
      users: users,
      units: units,
      repos: repos,
      unitIos: unitIos,
      links: links,
      email: email ?? this.email,
      telegramContact: telegramContact ?? this.telegramContact,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      pagination: pagination ?? this.pagination,
      mqttHost: mqttHost,
      mqttPort: mqttPort,
      mqttSecure: mqttSecure,
      instanceDatetime: instanceDatetime,
      lastStartDatetime: lastStartDatetime,
      testsDatetime: testsDatetime,
      testsStatus: testsStatus,
      testsPercent: testsPercent,
    );
  }

  InstancePortrait applySettings(Map<String, Object?> settings) {
    return copyWith(
      iconUuid: settings['icon_uuid'] as String? ?? iconUuid,
      datapipe: settings['pu_ff_datapipe_enable'] as bool? ?? datapipe,
      notifications:
          settings['pu_ff_notification_enable'] as bool? ?? notifications,
      grafana:
          settings['pu_ff_grafana_integration_enable'] as bool? ?? grafana,
      prometheus: settings['pu_ff_prometheus_enable'] as bool? ?? prometheus,
      telegram: settings['pu_ff_telegram_bot_enable'] as bool? ?? telegram,
      federation: settings['pu_ff_federation_enable'] as bool? ?? federation,
      email: settings['pu_instance_owner_email'] as String? ?? email,
      telegramContact:
          settings['pu_instance_owner_tg'] as String? ?? telegramContact,
      telegramBot: settings['pu_telegram_bot_link'] as String? ?? telegramBot,
      latitude: settings.containsKey('pu_instance_lat')
          ? _double(settings['pu_instance_lat'])
          : latitude,
      longitude: settings.containsKey('pu_instance_lon')
          ? _double(settings['pu_instance_lon'])
          : longitude,
      pagination:
          _int(settings['pu_instance_max_pagination_size']) ?? pagination,
    );
  }
}

class PeerHead {
  const PeerHead({
    required this.uuid,
    required this.url,
    required this.trust,
    this.lastPing,
    this.collectionStatus,
    this.collectionError,
    this.consecutiveSuccessCount = 0,
    this.lastSuccessDatetime,
    this.lastAttemptDatetime,
    this.portrait,
  });

  final String uuid;
  final String url;
  final String trust;
  final double? lastPing;
  final String? collectionStatus;
  final String? collectionError;
  final int consecutiveSuccessCount;
  final String? lastSuccessDatetime;
  final String? lastAttemptDatetime;
  final InstancePortrait? portrait;
}

const trustStatuses = ['Trust', 'Pending', 'Blocking'];

InstancePortrait portraitFromJson(
  Map<String, Object?> json, {
  required String url,
}) {
  final flags = _map(json['feature_flags']);
  final metrics = _map(json['metrics']);
  final settings = _map(json['settings']);
  final state = _map(json['state']);
  final contacts = _map(json['contacts']);
  final pagination = settings['pu_instance_max_pagination_size'];
  return InstancePortrait(
    url: url,
    name: json['name'] as String? ?? '',
    version: json['version'] as String? ?? '',
    description: json['description'] as String? ?? '',
    license: json['license'] as String? ?? '',
    swagger: json['swagger'] as String? ?? '',
    grafanaUrl: json['grafana'] as String? ?? '',
    telegramBot: json['telegram_bot'] as String? ?? '',
    iconUuid: json['icon_uuid'] as String?,
    datapipe: flags['pu_ff_datapipe_enable'] as bool?,
    notifications: flags['pu_ff_notification_enable'] as bool?,
    grafana: flags['pu_ff_grafana_integration_enable'] as bool?,
    prometheus: flags['pu_ff_prometheus_enable'] as bool?,
    telegram: flags['pu_ff_telegram_bot_enable'] as bool?,
    federation: flags['pu_ff_federation_enable'] as bool?,
    users: _int(metrics['user_count']),
    units: _int(metrics['unit_count']),
    repos: _int(metrics['repo_count']),
    unitIos: _int(metrics['unit_io_count']),
    links: _int(metrics['link_count']),
    email: contacts['email'] as String? ?? '',
    telegramContact: contacts['telegram'] as String? ?? '',
    latitude: _double(json['latitude']),
    longitude: _double(json['longitude']),
    pagination: _int(pagination) ?? 100,
    mqttHost: settings['pu_mqtt_host'] as String?,
    mqttPort: _int(settings['pu_mqtt_port']),
    mqttSecure: settings['pu_mqtt_secure'] as bool?,
    instanceDatetime: state['instance_datetime'] as String?,
    lastStartDatetime: state['last_successful_start_datetime'] as String?,
    testsDatetime: state['integration_tests_datetime'] as String?,
    testsStatus: state['integration_tests_status'] as String?,
    testsPercent: _double(state['integration_tests_success_percentage']),
  );
}

Map<String, Object?> _map(Object? value) {
  if (value is Map) return value.cast<String, Object?>();
  return const {};
}

int? _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return null;
}

double? _double(Object? value) {
  if (value is num) return value.toDouble();
  return null;
}
