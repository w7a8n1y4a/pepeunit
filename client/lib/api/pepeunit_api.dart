import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

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

  Uri _uri(String path) => Uri.parse('$origin/pepeunit/api/v1$path');

  Future<String> currentVersion() async {
    final response = await _client.get(_uri('/instances/current'));
    _ensureOk(response);
    final json = jsonDecode(response.body) as Map<String, Object?>;
    final version = json['version'] as String? ?? '';
    if (!backendCompatible(version)) {
      throw ApiException(
        response.statusCode,
        'Бекенд $version вне окна >= 1.5.0 < 1.6.0',
      );
    }
    return version;
  }

  Future<void> register(String publicKeyBase64) async {
    final response = await _client.post(
      _uri('/users'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'public_key': publicKeyBase64}),
    );
    _ensureOk(response);
  }

  Future<String> challenge(String hashPublicKey) async {
    final response = await _client.post(
      _uri('/users/auth/challenge'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({'hash_public_key': hashPublicKey}),
    );
    _ensureOk(response);
    final json = jsonDecode(response.body) as Map<String, Object?>;
    return json['challenge']! as String;
  }

  Future<String> auth(String challengeToken, String signatureBase64) async {
    final response = await _client.post(
      _uri('/users/auth'),
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'challenge': challengeToken,
        'signature': signatureBase64,
      }),
    );
    _ensureOk(response);
    final json = jsonDecode(response.body) as Map<String, Object?>;
    return json['token']! as String;
  }

  Future<void> updateLogin(String token, String userUuid, String login) async {
    final response = await _client.patch(
      _uri('/users/$userUuid'),
      headers: {'content-type': 'application/json', 'x-auth-token': token},
      body: jsonEncode({'login': login}),
    );
    _ensureOk(response);
  }

  Future<void> uploadIcon(String token, String userUuid, Uint8List png) async {
    final request = http.MultipartRequest('POST', _uri('/icons'));
    request.headers['x-auth-token'] = token;
    request.fields['entity_uuid'] = userUuid;
    request.fields['entity_type'] = 'User';
    request.files.add(
      http.MultipartFile.fromBytes('file', png, filename: 'icon.png'),
    );
    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    _ensureOk(response);
  }

  void _ensureOk(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
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
