import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../instances/instance.dart';
import '../instances/portrait.dart';
import 'backend_version.dart';

class ApiException implements Exception {
  ApiException(this.status, this.body);

  final int status;
  final String body;

  bool get missingUser => status == 404 || body.contains('does not exist');

  @override
  String toString() => body.isEmpty ? 'HTTP $status' : body;
}

class PepeunitApi {
  PepeunitApi(String origin, {http.Client? client})
    : origin = origin.replaceAll(RegExp(r'/+$'), ''),
      _client = client ?? http.Client();

  final String origin;
  final http.Client _client;

  static const _timeout = Duration(seconds: 20);

  Uri _uri(String path, [Map<String, Object?>? query]) {
    final base = Uri.parse('$origin/pepeunit/api/v1$path');
    if (query == null || query.isEmpty) return base;
    return base.replace(
      queryParameters: {
        for (final entry in query.entries)
          if (entry.value != null) entry.key: '${entry.value}',
      },
    );
  }

  Map<String, String> _jsonHeaders(String? token) {
    return {
      'content-type': 'application/json',
      if (token != null && token.isNotEmpty) 'x-auth-token': token,
    };
  }

  Future<InstancePortrait> portrait() async {
    final response = await _client
        .get(_uri('/instances/current'))
        .timeout(_timeout);
    _ensureOk(response);
    final json = jsonDecode(response.body) as Map<String, Object?>;
    final version = json['version'] as String? ?? '';
    if (version.isNotEmpty && !backendCompatible(version)) {
      throw ApiException(
        response.statusCode,
        'Бекенд $version вне окна >= 1.5.0 < 1.6.0',
      );
    }
    return portraitFromJson(json, url: '$origin$instanceCurrentPath');
  }

  Future<String> currentVersion() async => (await portrait()).version;

  Future<({int total, List<String> items})> peerUrls({
    required int offset,
    required int limit,
  }) async {
    final response = await _client
        .get(_uri('/peers/urls', {'offset': offset, 'limit': limit}))
        .timeout(_timeout);
    _ensureOk(response);
    final json = jsonDecode(response.body) as Map<String, Object?>;
    final urls = [
      for (final item in json['urls'] as List<Object?>? ?? const [])
        if (item is String) item,
    ];
    return (total: json['total_count'] as int? ?? urls.length, items: urls);
  }

  Future<({int total, List<PeerHead> items})> peers({
    required int offset,
    required int limit,
  }) async {
    final response = await _client
        .get(_uri('/peers', {'offset': offset, 'limit': limit}))
        .timeout(_timeout);
    _ensureOk(response);
    final json = jsonDecode(response.body) as Map<String, Object?>;
    final items = <PeerHead>[];
    for (final item in json['peers'] as List<Object?>? ?? const []) {
      if (item is! Map) continue;
      final row = item.cast<String, Object?>();
      final url = row['url'] as String?;
      final uuid = row['uuid'] as String?;
      if (url == null || uuid == null) continue;
      items.add(
        PeerHead(
          uuid: uuid,
          url: url,
          trust: row['trust_status'] as String? ?? '',
        ),
      );
    }
    return (total: json['total_count'] as int? ?? items.length, items: items);
  }

  Future<void> createPeer(String token, String url) async {
    final response = await _client
        .post(
          _uri('/peers'),
          headers: _jsonHeaders(token),
          body: jsonEncode({'url': url}),
        )
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<void> updatePeer(String token, String uuid, String trust) async {
    final response = await _client
        .patch(
          _uri('/peers/$uuid'),
          headers: _jsonHeaders(token),
          body: jsonEncode({'trust_status': trust}),
        )
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<void> deletePeer(String token, String uuid) async {
    final response = await _client
        .delete(_uri('/peers/$uuid'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<void> scanPeer(String token, String uuid) async {
    final response = await _client
        .post(_uri('/peers/scan/$uuid'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<void> scanAll(String token) async {
    final response = await _client
        .post(_uri('/peers/scan_all'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<void> register(String publicKeyBase64) async {
    final response = await _client
        .post(
          _uri('/users'),
          headers: _jsonHeaders(null),
          body: jsonEncode({'public_key': publicKeyBase64}),
        )
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<String> challenge(String hashPublicKey) async {
    final response = await _client
        .post(
          _uri('/users/auth/challenge'),
          headers: _jsonHeaders(null),
          body: jsonEncode({'hash_public_key': hashPublicKey}),
        )
        .timeout(_timeout);
    _ensureOk(response);
    final json = jsonDecode(response.body) as Map<String, Object?>;
    return json['challenge']! as String;
  }

  Future<String> auth(String challengeToken, String signatureBase64) async {
    final response = await _client
        .post(
          _uri('/users/auth'),
          headers: _jsonHeaders(null),
          body: jsonEncode({
            'challenge': challengeToken,
            'signature': signatureBase64,
          }),
        )
        .timeout(_timeout);
    _ensureOk(response);
    final json = jsonDecode(response.body) as Map<String, Object?>;
    return json['token']! as String;
  }

  Future<({String role, String uuid})> user(String token, String uuid) async {
    final response = await _client
        .get(_uri('/users/$uuid'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    final json = jsonDecode(response.body) as Map<String, Object?>;
    return (
      role: json['role'] as String? ?? 'User',
      uuid: json['uuid']! as String,
    );
  }

  Future<String> verificationLink(String token) async {
    final response = await _client
        .get(
          _uri('/users/generate_verification_link/'),
          headers: _jsonHeaders(token),
        )
        .timeout(_timeout);
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    if (decoded is String && decoded.isNotEmpty) return decoded;
    throw ApiException(response.statusCode, response.body);
  }

  Future<Map<String, Object?>> settings(String token) async {
    final response = await _client
        .get(_uri('/instances/settings'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    return (jsonDecode(response.body) as Map).cast<String, Object?>();
  }

  Future<Map<String, Object?>> patchSettings(
    String token,
    Map<String, Object?> patch,
  ) async {
    final response = await _client
        .patch(
          _uri('/instances/settings'),
          headers: _jsonHeaders(token),
          body: jsonEncode(patch),
        )
        .timeout(_timeout);
    _ensureOk(response);
    return (jsonDecode(response.body) as Map).cast<String, Object?>();
  }

  Future<void> reboot(String token) async {
    final response = await _client
        .post(_uri('/instances/reboot'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<void> integrationTests(String token) async {
    final response = await _client
        .post(
          _uri('/instances/integration_tests'),
          headers: _jsonHeaders(token),
        )
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<void> updateLogin(String token, String userUuid, String login) async {
    final response = await _client
        .patch(
          _uri('/users/$userUuid'),
          headers: _jsonHeaders(token),
          body: jsonEncode({'login': login}),
        )
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<void> uploadIcon(String token, String userUuid, Uint8List png) {
    return _uploadIcon(token, userUuid, 'User', png);
  }

  Future<void> uploadInstanceIcon(String token, Uint8List png) {
    return _uploadIcon(token, instanceSettingsUuid, 'Instance', png);
  }

  Future<Uint8List> icon(String uuid) async {
    final response = await _client.get(_uri('/icons/$uuid')).timeout(_timeout);
    _ensureOk(response);
    return response.bodyBytes;
  }

  Future<void> _uploadIcon(
    String token,
    String entityUuid,
    String entityType,
    Uint8List png,
  ) async {
    final request = http.MultipartRequest('POST', _uri('/icons'));
    request.headers['x-auth-token'] = token;
    request.fields['entity_uuid'] = entityUuid;
    request.fields['entity_type'] = entityType;
    request.files.add(
      http.MultipartFile.fromBytes('file', png, filename: 'icon.png'),
    );
    final streamed = await _client.send(request).timeout(_timeout);
    final response = await http.Response.fromStream(streamed);
    _ensureOk(response);
  }

  void _ensureOk(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trimLeft().startsWith('<')) {
        throw ApiException(
          response.statusCode,
          'Сервер вернул страницу, а не JSON',
        );
      }
      return;
    }
    throw ApiException(response.statusCode, response.body);
  }
}

String jwtUuid(String token) {
  final parts = token.split('.');
  if (parts.length < 2) {
    throw const FormatException('Токен без полезной нагрузки');
  }
  final payload = jsonDecode(
    utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
  ) as Map<String, Object?>;
  final uuid = payload['uuid'] as String?;
  if (uuid == null || uuid.isEmpty) {
    throw const FormatException('В токене нет uuid');
  }
  return uuid;
}
