class InstancePortrait {
  const InstancePortrait({
    required this.url,
    this.name = '',
    this.version = '',
    this.iconUuid,
    this.notifications,
    this.grafana,
    this.telegram,
    this.federation,
    this.users,
    this.units,
    this.repos,
    this.pagination = 100,
    this.testsStatus,
    this.testsPercent,
  });

  final String url;
  final String name;
  final String version;
  final String? iconUuid;
  final bool? notifications;
  final bool? grafana;
  final bool? telegram;
  final bool? federation;
  final int? users;
  final int? units;
  final int? repos;
  final int pagination;
  final String? testsStatus;
  final double? testsPercent;

  String get iconPath =>
      iconUuid == null ? '' : '/pepeunit/api/v1/icons/$iconUuid';
}

class PeerHead {
  const PeerHead({required this.uuid, required this.url, required this.trust});

  final String uuid;
  final String url;
  final String trust;
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
  final pagination = settings['pu_instance_max_pagination_size'];
  return InstancePortrait(
    url: url,
    name: json['name'] as String? ?? '',
    version: json['version'] as String? ?? '',
    iconUuid: json['icon_uuid'] as String?,
    notifications: flags['pu_ff_notification_enable'] as bool?,
    grafana: flags['pu_ff_grafana_integration_enable'] as bool?,
    telegram: flags['pu_ff_telegram_bot_enable'] as bool?,
    federation: flags['pu_ff_federation_enable'] as bool?,
    users: _int(metrics['user_count']),
    units: _int(metrics['unit_count']),
    repos: _int(metrics['repo_count']),
    pagination: _int(pagination) ?? 100,
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
