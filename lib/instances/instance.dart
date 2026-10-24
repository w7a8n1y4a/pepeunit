class InstanceRecord {
  InstanceRecord({
    required this.url,
    this.token,
    this.userUuid,
    this.role,
    this.notifications,
    this.grafana,
    this.telegram,
    this.active = false,
  });

  final String url;
  String? token;
  String? userUuid;
  String? role;
  bool? notifications;
  bool? grafana;
  bool? telegram;
  bool active;

  bool get signedIn => token != null && token!.isNotEmpty;

  bool get managesPeers => role == 'Admin' || role == 'Owner';

  bool get ownsInstance => role == 'Owner';

  InstanceRecord copy() {
    return InstanceRecord(
      url: url,
      token: token,
      userUuid: userUuid,
      role: role,
      notifications: notifications,
      grafana: grafana,
      telegram: telegram,
      active: active,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'url': url,
      'token': token,
      'userUuid': userUuid,
      'role': role,
      'notifications': notifications,
      'grafana': grafana,
      'telegram': telegram,
      'active': active,
    };
  }

  factory InstanceRecord.fromJson(Map<String, Object?> json) {
    return InstanceRecord(
      url: json['url']! as String,
      token: json['token'] as String?,
      userUuid: json['userUuid'] as String?,
      role: json['role'] as String?,
      notifications: json['notifications'] as bool?,
      grafana: json['grafana'] as bool?,
      telegram: json['telegram'] as bool?,
      active: json['active'] as bool? ?? false,
    );
  }
}

const instanceCurrentPath = '/pepeunit/api/v1/instances/current';

const defaultInstanceUrl = 'https://devunit.pepeunit.com$instanceCurrentPath';

/// The single settings row. Uploading the instance picture addresses this uuid.
const instanceSettingsUuid = '00000000-0000-4000-8000-000000000001';

/// A peer address is the public `/instances/current` link.
///
/// A bare origin is completed with that path. Query, fragment and credentials
/// are rejected: the backend stores the same shape.
String canonicalInstanceUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    throw const FormatException('Пустой адрес инстанса');
  }
  final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
  final uri = Uri.parse(withScheme);
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    throw const FormatException('Адрес должен начинаться с http или https');
  }
  if (uri.host.isEmpty) {
    throw const FormatException('В адресе нет хоста');
  }
  if (uri.userInfo.isNotEmpty) {
    throw const FormatException('В адресе не должно быть логина');
  }
  if (uri.query.isNotEmpty || uri.fragment.isNotEmpty) {
    throw const FormatException('В адресе не должно быть параметров');
  }
  var path = uri.path;
  if (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  if (path.isEmpty || path == '/') {
    path = instanceCurrentPath;
  } else if (!path.endsWith('/instances/current')) {
    throw const FormatException('Нужна ссылка /instances/current');
  }
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: path,
  ).toString();
}

String originOf(String currentUrl) {
  final uri = Uri.parse(currentUrl);
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
  ).toString();
}

String instanceHost(String currentUrl) {
  final host = Uri.parse(currentUrl).host;
  return host.isEmpty ? currentUrl : host;
}
