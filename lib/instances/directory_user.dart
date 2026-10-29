class DirectoryUser {
  const DirectoryUser({
    required this.uuid,
    required this.role,
    required this.status,
    required this.publicKey,
    this.login,
    this.iconUuid,
  });

  final String uuid;
  final String role;
  final String status;
  final String publicKey;
  final String? login;
  final String? iconUuid;

  factory DirectoryUser.fromJson(Map<String, Object?> json) {
    final login = json['login'];
    final icon = json['icon_uuid'];
    return DirectoryUser(
      uuid: json['uuid'] as String? ?? '',
      role: json['role'] as String? ?? 'User',
      status: json['status'] as String? ?? 'Active',
      publicKey: json['public_key'] as String? ?? '',
      login: login is String && login.trim().isNotEmpty ? login.trim() : null,
      iconUuid: icon is String && icon.isNotEmpty ? icon : null,
    );
  }
}
