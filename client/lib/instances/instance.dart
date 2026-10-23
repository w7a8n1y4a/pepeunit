class InstanceRecord {
  InstanceRecord({
    required this.url,
    this.token,
    this.userUuid,
    this.active = false,
  });

  final String url;
  String? token;
  String? userUuid;
  bool active;

  bool get signedIn => token != null && token!.isNotEmpty;

  InstanceRecord copy() {
    return InstanceRecord(
      url: url,
      token: token,
      userUuid: userUuid,
      active: active,
    );
  }

  Map<String, Object?> toJson() {
    return {'url': url, 'token': token, 'userUuid': userUuid, 'active': active};
  }

  factory InstanceRecord.fromJson(Map<String, Object?> json) {
    return InstanceRecord(
      url: json['url']! as String,
      token: json['token'] as String?,
      userUuid: json['userUuid'] as String?,
      active: json['active'] as bool? ?? false,
    );
  }
}

const defaultInstanceUrl = 'https://devunit.pepeunit.com';

String normalizeInstanceUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    throw FormatException('Пустой адрес инстанса');
  }
  final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';
  final uri = Uri.parse(withScheme);
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    throw FormatException('Адрес должен начинаться с http или https');
  }
  if (uri.host.isEmpty) {
    throw FormatException('В адресе нет хоста');
  }
  return Uri(
    scheme: uri.scheme,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
  ).toString();
}
