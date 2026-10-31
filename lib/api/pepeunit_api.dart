import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../alerts/notice.dart';
import '../instances/directory_user.dart';
import '../instances/instance.dart';
import '../instances/portrait.dart';
import '../registry/repo.dart';
import '../units/unit.dart';
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
      final stateRaw = row['state'];
      InstancePortrait? cachedPortrait;
      if (stateRaw is Map) {
        try {
          cachedPortrait = portraitFromJson(
            stateRaw.cast<String, Object?>(),
            url: url,
          );
        } catch (_) {}
      }
      final pingRaw = row['last_ping'];
      final countRaw = row['consecutive_success_count'];
      items.add(
        PeerHead(
          uuid: uuid,
          url: url,
          trust: row['trust_status'] as String? ?? '',
          lastPing: pingRaw is num ? pingRaw.toDouble() : null,
          collectionStatus: row['last_collection_status'] as String?,
          collectionError: row['last_collection_error'] as String?,
          consecutiveSuccessCount: countRaw is num ? countRaw.round() : 0,
          lastSuccessDatetime: row['last_success_datetime'] as String?,
          lastAttemptDatetime: row['last_attempt_datetime'] as String?,
          portrait: cachedPortrait,
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

  Future<Map<String, Object?>> notificationSettings(String token) async {
    final response = await _client
        .get(_uri('/notifications/settings'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    return (jsonDecode(response.body) as Map).cast<String, Object?>();
  }

  Future<void> updateNotificationSettings(
    String token,
    Map<String, Object?> patch,
  ) async {
    final response = await _client
        .patch(
          _uri('/notifications/settings'),
          headers: _jsonHeaders(token),
          body: jsonEncode(patch),
        )
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<({int count, List<Notice> items})> notices({
    required String token,
    required int offset,
    required int limit,
    bool? isRead,
    List<String>? types,
  }) async {
    final pairs = <String>[
      'offset=$offset',
      'limit=$limit',
      if (isRead != null) 'is_read=$isRead',
      for (final type in types ?? const <String>[])
        'type=${Uri.encodeQueryComponent(type)}',
    ];
    final uri = Uri.parse(
      '$origin/pepeunit/api/v1/notifications?${pairs.join('&')}',
    );
    final response = await _client
        .get(uri, headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    return _noticePage(response.body);
  }

  Future<Notice> markNoticeRead(String token, String uuid) async {
    final response = await _client
        .patch(_uri('/notifications/$uuid/read'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    return Notice.fromJson(
      (jsonDecode(response.body) as Map).cast<String, Object?>(),
    );
  }

  Future<int> markAllNoticesRead(String token) async {
    final response = await _client
        .patch(_uri('/notifications/read'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    return decoded is num ? decoded.round() : 0;
  }

  /// Live events for one signed-in user. [client] is closed by the caller
  /// to drop the connection. Comment frames (`: ping`) are skipped.
  Stream<Notice> watchNotices(String token, http.Client client) async* {
    final request = http.Request('GET', _uri('/notifications/stream'));
    request.headers.addAll(_jsonHeaders(token));
    request.headers['accept'] = 'text/event-stream';
    final response = await client.send(request);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final body = await response.stream.bytesToString();
      throw ApiException(response.statusCode, body);
    }
    final buffer = SseBuffer();
    await for (final chunk in response.stream.transform(utf8.decoder)) {
      for (final notice in buffer.add(chunk)) {
        yield notice;
      }
    }
  }

  ({int count, List<Notice> items}) _noticePage(String body) {
    final json = (jsonDecode(body) as Map).cast<String, Object?>();
    final items = <Notice>[];
    for (final item in json['notifications'] as List<Object?>? ?? const []) {
      if (item is! Map) continue;
      final notice = Notice.fromJson(item.cast<String, Object?>());
      if (notice.uuid.isEmpty) continue;
      items.add(notice);
    }
    final rawCount = json['count'];
    return (
      count: rawCount is num ? rawCount.round() : items.length,
      items: items,
    );
  }

  Future<String?> uploadIcon(String token, String userUuid, Uint8List png) {
    return _uploadIcon(token, userUuid, 'User', png);
  }

  Future<String?> uploadInstanceIcon(String token, Uint8List png) {
    return _uploadIcon(token, instanceSettingsUuid, 'Instance', png);
  }

  Future<({int count, List<DirectoryUser> users})> directoryUsers({
    required String token,
    required int offset,
    required int limit,
    required String search,
    required List<String> roles,
    required List<String> statuses,
    required String order,
  }) async {
    final pairs = <String>[
      'offset=$offset',
      'limit=$limit',
      'order_by_create_date=${Uri.encodeQueryComponent(order)}',
      if (search.trim().isNotEmpty)
        'search_string=${Uri.encodeQueryComponent(search.trim())}',
      for (final role in roles) 'role=${Uri.encodeQueryComponent(role)}',
      for (final status in statuses)
        'status=${Uri.encodeQueryComponent(status)}',
    ];
    final uri = Uri.parse('$origin/pepeunit/api/v1/users?${pairs.join('&')}');
    final response = await _client
        .get(uri, headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    final json = (jsonDecode(response.body) as Map).cast<String, Object?>();
    final users = <DirectoryUser>[];
    for (final item in json['users'] as List<Object?>? ?? const []) {
      if (item is! Map) continue;
      final user = DirectoryUser.fromJson(item.cast<String, Object?>());
      if (user.uuid.isEmpty) continue;
      users.add(user);
    }
    final rawCount = json['count'];
    return (
      count: rawCount is num ? rawCount.round() : users.length,
      users: users,
    );
  }

  Future<DirectoryUser> readDirectoryUser(String token, String uuid) async {
    final response = await _client
        .get(_uri('/users/$uuid'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    return DirectoryUser.fromJson(
      (jsonDecode(response.body) as Map).cast<String, Object?>(),
    );
  }

  Future<DirectoryUser> grantAdmin(String token, String uuid) {
    return _patchUser(token, '/users/grant_admin/$uuid');
  }

  Future<DirectoryUser> revokeAdmin(String token, String uuid) {
    return _patchUser(token, '/users/revoke_admin/$uuid');
  }

  Future<DirectoryUser> blockUser(String token, String uuid) async {
    final response = await _client
        .patch(_uri('/users/block/$uuid'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    return readDirectoryUser(token, uuid);
  }

  Future<DirectoryUser> unblockUser(String token, String uuid) async {
    final response = await _client
        .patch(_uri('/users/unblock/$uuid'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    return readDirectoryUser(token, uuid);
  }

  Future<DirectoryUser> _patchUser(String token, String path) async {
    final response = await _client
        .patch(_uri(path), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    return DirectoryUser.fromJson(
      (jsonDecode(response.body) as Map).cast<String, Object?>(),
    );
  }

  Future<({int count, List<RegistryRepo> repos})> repos({
    required String token,
    required int offset,
    required int limit,
    required String search,
    required String order,
    bool? public,
  }) async {
    final response = await _client
        .get(
          _uri('/repo', {
            'offset': offset,
            'limit': limit,
            'order_by_repository_url': order,
            if (search.trim().isNotEmpty) 'search_string': search.trim(),
            'is_public_repository': ?public,
          }),
          headers: _jsonHeaders(token),
        )
        .timeout(_timeout);
    _ensureOk(response);
    final json = (jsonDecode(response.body) as Map).cast<String, Object?>();
    final repos = <RegistryRepo>[];
    for (final item in json['repos'] as List<Object?>? ?? const []) {
      if (item is! Map) continue;
      final repo = RegistryRepo.fromJson(item.cast<String, Object?>());
      if (repo.uuid.isEmpty) continue;
      repos.add(repo);
    }
    final rawCount = json['count'];
    return (
      count: rawCount is num ? rawCount.round() : repos.length,
      repos: repos,
    );
  }

  Future<RegistryRepo> readRepo(String token, String uuid) async {
    final response = await _client
        .get(_uri('/repo/$uuid'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    return RegistryRepo.fromJson(
      (jsonDecode(response.body) as Map).cast<String, Object?>(),
    );
  }

  Future<void> deleteRepo(String token, String uuid) async {
    final response = await _client
        .delete(_uri('/repo/$uuid'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<void> updateLocalRepository(String token, String uuid) async {
    final response = await _client
        .patch(
          _uri('/repo/update_local_repository/$uuid'),
          headers: _jsonHeaders(token),
        )
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<RepoCredentials?> repoCredentials(String token, String uuid) async {
    final response = await _client
        .get(_uri('/repo/get_credentials/$uuid'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    if (response.body.trim().isEmpty) return null;
    final decoded = jsonDecode(response.body);
    if (decoded == null) return null;
    if (decoded is! Map) {
      throw ApiException(response.statusCode, response.body);
    }
    return RepoCredentials.fromJson(decoded.cast<String, Object?>());
  }

  Future<void> setRepoCredentials(
    String token,
    String uuid,
    String username,
    String pat,
  ) async {
    final response = await _client
        .patch(
          _uri('/repo/set_credentials/$uuid'),
          headers: _jsonHeaders(token),
          body: jsonEncode({'username': username, 'pat_token': pat}),
        )
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<void> updateAllRepos(String token) async {
    final response = await _client
        .patch(_uri('/repo/update_all'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<List<RepoCommit>> branchCommits(
    String token,
    String uuid, {
    required String branch,
    bool onlyTag = false,
    int offset = 0,
    int limit = 100,
  }) async {
    final response = await _client
        .get(
          _uri('/repo/branch_commits/$uuid', {
            'repo_branch': branch,
            'only_tag': onlyTag,
            'offset': offset,
            'limit': limit,
          }),
          headers: _jsonHeaders(token),
        )
        .timeout(_timeout);
    _ensureOk(response);
    return [
      for (final item
          in jsonDecode(response.body) as List<Object?>? ?? const [])
        if (item is Map) RepoCommit.fromJson(item.cast<String, Object?>()),
    ];
  }

  Future<List<FirmwarePlatform>> firmwarePlatforms(
    String token,
    String uuid, {
    String? branch,
    String? commit,
    String? tag,
  }) async {
    final response = await _client
        .get(
          _uri('/repo/available_platforms/$uuid', {
            'branch': ?branch,
            'target_commit': ?commit,
            'target_tag': ?tag,
          }),
          headers: _jsonHeaders(token),
        )
        .timeout(_timeout);
    _ensureOk(response);
    return [
      for (final item
          in jsonDecode(response.body) as List<Object?>? ?? const [])
        if (item is Map)
          FirmwarePlatform.fromJson(item.cast<String, Object?>()),
    ];
  }

  Future<Unit> createUnit(String token, Map<String, Object?> body) async {
    final response = await _client
        .post(
          _uri('/units'),
          headers: _jsonHeaders(token),
          body: jsonEncode(body),
        )
        .timeout(_timeout);
    _ensureOk(response);
    return Unit.fromJson(
      (jsonDecode(response.body) as Map).cast<String, Object?>(),
    );
  }

  Future<({int count, List<Unit> units})> units({
    required String token,
    required int offset,
    required int limit,
    String search = '',
    String order = 'asc',
    String? creatorUuid,
    List<String>? visibility,
    bool? auto,
    String? repoUuid,
    String? inputUuid,
    bool includeIos = false,
  }) async {
    final pairs = <String>[
      'offset=$offset',
      'limit=$limit',
      'order_by_unit_name=${Uri.encodeQueryComponent(order)}',
      if (search.trim().isNotEmpty)
        'search_string=${Uri.encodeQueryComponent(search.trim())}',
      if (creatorUuid != null && creatorUuid.isNotEmpty)
        'creator_uuid=${Uri.encodeQueryComponent(creatorUuid)}',
      for (final level in visibility ?? const <String>[])
        'visibility_level=${Uri.encodeQueryComponent(level)}',
      if (auto != null) 'is_auto_update_unit=$auto',
      if (repoUuid != null && repoUuid.isNotEmpty)
        'repo_uuid=${Uri.encodeQueryComponent(repoUuid)}',
      if (inputUuid != null && inputUuid.isNotEmpty)
        'unit_io_input_uuid=${Uri.encodeQueryComponent(inputUuid)}',
      if (includeIos) 'is_include_output_unit_ios=true',
    ];
    final response = await _client
        .get(_pairs('/units', pairs), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    return _unitPage(response.body);
  }

  Future<Unit> readUnit(String token, String uuid) async {
    final response = await _client
        .get(_uri('/units/$uuid'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    return Unit.fromJson(
      (jsonDecode(response.body) as Map).cast<String, Object?>(),
    );
  }

  Future<Unit> updateUnit(
    String token,
    String uuid,
    Map<String, Object?> patch,
  ) async {
    final response = await _client
        .patch(
          _uri('/units/$uuid'),
          headers: _jsonHeaders(token),
          body: jsonEncode(patch),
        )
        .timeout(_timeout);
    _ensureOk(response);
    return Unit.fromJson(
      (jsonDecode(response.body) as Map).cast<String, Object?>(),
    );
  }

  Future<void> deleteUnit(String token, String uuid) async {
    final response = await _client
        .delete(_uri('/units/$uuid'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<Map<String, Object?>> unitEnv(String token, String uuid) async {
    final response = await _client
        .get(_uri('/units/env/$uuid'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    return (jsonDecode(response.body) as Map).cast<String, Object?>();
  }

  Future<void> setUnitEnv(
    String token,
    String uuid,
    Map<String, Object?> env,
  ) async {
    final response = await _client
        .patch(
          _uri('/units/env/$uuid'),
          headers: _jsonHeaders(token),
          body: jsonEncode({'env_json_string': jsonEncode(env)}),
        )
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<void> resetUnitEnv(String token, String uuid) async {
    final response = await _client
        .delete(_uri('/units/env/$uuid'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<({String commit, String? tag})> targetVersion(
    String token,
    String uuid,
  ) async {
    final response = await _client
        .get(
          _uri('/units/get_target_version/$uuid'),
          headers: _jsonHeaders(token),
        )
        .timeout(_timeout);
    _ensureOk(response);
    final json = (jsonDecode(response.body) as Map).cast<String, Object?>();
    final tag = json['tag'];
    return (
      commit: json['commit'] as String? ?? '',
      tag: tag is String && tag.isNotEmpty ? tag : null,
    );
  }

  Future<String> unitSchema(String token, String uuid) async {
    final response = await _client
        .get(
          _uri('/units/get_current_schema/$uuid'),
          headers: _jsonHeaders(token),
        )
        .timeout(_timeout);
    _ensureOk(response);
    return response.body;
  }

  Future<Uint8List> unitFirmware(String token, String uuid, String kind) async {
    final response = await _client
        .get(
          _uri(
            '/units/firmware/$kind/$uuid',
            kind == 'tgz' ? {'wbits': 9, 'level': 9} : null,
          ),
          headers: _jsonHeaders(token),
        )
        .timeout(const Duration(seconds: 60));
    _ensureBytes(response);
    return response.bodyBytes;
  }

  Future<String> unitStateStorage(String token, String uuid) async {
    final response = await _client
        .get(
          _uri('/units/get_state_storage/$uuid'),
          headers: _jsonHeaders(token),
        )
        .timeout(_timeout);
    _ensureOk(response);
    final decoded = jsonDecode(response.body);
    return decoded is String ? decoded : response.body;
  }

  Future<void> sendUnitCommand(
    String token,
    String uuid,
    String command,
  ) async {
    final response = await _client
        .post(
          _uri('/units/send_command_to_input_base_topic/$uuid', {
            'command': command,
          }),
          headers: _jsonHeaders(token),
        )
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<void> bulkUpdateUnits(String token) async {
    final response = await _client
        .post(_uri('/units/bulk_update'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<({int count, List<UnitLog> logs})> unitLogs({
    required String token,
    required String uuid,
    required int offset,
    required int limit,
    List<String>? levels,
    String order = 'desc',
  }) async {
    final pairs = <String>[
      'uuid=${Uri.encodeQueryComponent(uuid)}',
      'offset=$offset',
      'limit=$limit',
      'order_by_create_date=${Uri.encodeQueryComponent(order)}',
      for (final level in levels ?? const <String>[])
        'level=${Uri.encodeQueryComponent(level)}',
    ];
    final response = await _client
        .get(_pairs('/units/log_list/', pairs), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    final json = (jsonDecode(response.body) as Map).cast<String, Object?>();
    final logs = <UnitLog>[];
    for (final item in json['unit_logs'] as List<Object?>? ?? const []) {
      if (item is! Map) continue;
      final log = UnitLog.fromJson(item.cast<String, Object?>());
      if (log.uuid.isEmpty) continue;
      logs.add(log);
    }
    final rawCount = json['count'];
    return (
      count: rawCount is num ? rawCount.round() : logs.length,
      logs: logs,
    );
  }

  Future<Uint8List> downloadUnitLogs(String token, String uuid) async {
    final response = await _client
        .get(_uri('/units/logs/$uuid'), headers: _jsonHeaders(token))
        .timeout(const Duration(seconds: 60));
    _ensureBytes(response);
    return response.bodyBytes;
  }

  Future<UnitGroup> createGroup(String token, String name) async {
    final response = await _client
        .post(
          _uri('/unit_groups'),
          headers: _jsonHeaders(token),
          body: jsonEncode({'name': name}),
        )
        .timeout(_timeout);
    _ensureOk(response);
    return UnitGroup.fromJson(
      (jsonDecode(response.body) as Map).cast<String, Object?>(),
    );
  }

  Future<({int count, List<UnitGroup> groups})> groups({
    required String token,
    required int offset,
    required int limit,
    String search = '',
    String order = 'asc',
    String? unitUuid,
  }) async {
    final response = await _client
        .get(
          _uri('/unit_groups', {
            'offset': offset,
            'limit': limit,
            'order_by_group_name': order,
            if (search.trim().isNotEmpty) 'search_string': search.trim(),
            'unit_uuid': ?unitUuid,
          }),
          headers: _jsonHeaders(token),
        )
        .timeout(_timeout);
    _ensureOk(response);
    final json = (jsonDecode(response.body) as Map).cast<String, Object?>();
    final groups = <UnitGroup>[];
    for (final item in json['unit_groups'] as List<Object?>? ?? const []) {
      if (item is! Map) continue;
      final group = UnitGroup.fromJson(item.cast<String, Object?>());
      if (group.uuid.isEmpty) continue;
      groups.add(group);
    }
    final rawCount = json['count'];
    return (
      count: rawCount is num ? rawCount.round() : groups.length,
      groups: groups,
    );
  }

  Future<UnitGroup> readGroup(String token, String uuid) async {
    final response = await _client
        .get(_uri('/unit_groups/$uuid'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    return UnitGroup.fromJson(
      (jsonDecode(response.body) as Map).cast<String, Object?>(),
    );
  }

  Future<UnitGroup> renameGroup(String token, String uuid, String name) async {
    final response = await _client
        .patch(
          _uri('/unit_groups/$uuid'),
          headers: _jsonHeaders(token),
          body: jsonEncode({'name': name}),
        )
        .timeout(_timeout);
    _ensureOk(response);
    return UnitGroup.fromJson(
      (jsonDecode(response.body) as Map).cast<String, Object?>(),
    );
  }

  Future<void> deleteGroup(String token, String uuid) async {
    final response = await _client
        .delete(_uri('/unit_groups/$uuid'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<({int count, List<Unit> units})> groupUnits({
    required String token,
    required String uuid,
    required int offset,
    required int limit,
    String search = '',
    String order = 'asc',
  }) async {
    final response = await _client
        .get(
          _uri('/unit_groups/$uuid/units', {
            'offset': offset,
            'limit': limit,
            'order_by_unit_name': order,
            if (search.trim().isNotEmpty) 'search_string': search.trim(),
          }),
          headers: _jsonHeaders(token),
        )
        .timeout(_timeout);
    _ensureOk(response);
    return _unitPage(response.body);
  }

  Future<void> linkGroupUnit(String token, String uuid, String unitUuid) async {
    final response = await _client
        .post(
          _uri('/unit_groups/$uuid/units/$unitUuid'),
          headers: _jsonHeaders(token),
        )
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<void> unlinkGroupUnit(
    String token,
    String uuid,
    String unitUuid,
  ) async {
    final response = await _client
        .delete(
          _uri('/unit_groups/$uuid/units/$unitUuid'),
          headers: _jsonHeaders(token),
        )
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<({int count, List<UnitIo> ios})> unitIos({
    required String token,
    required int offset,
    required int limit,
    String? unitUuid,
    String search = '',
    List<String>? types,
    String? outputUuid,
    String order = 'asc',
  }) async {
    final pairs = <String>[
      'offset=$offset',
      'limit=$limit',
      'order_by_create_date=${Uri.encodeQueryComponent(order)}',
      if (unitUuid != null && unitUuid.isNotEmpty)
        'unit_uuid=${Uri.encodeQueryComponent(unitUuid)}',
      if (search.trim().isNotEmpty)
        'search_string=${Uri.encodeQueryComponent(search.trim())}',
      for (final type in types ?? const <String>[])
        'type=${Uri.encodeQueryComponent(type)}',
      if (outputUuid != null && outputUuid.isNotEmpty)
        'output_uuid=${Uri.encodeQueryComponent(outputUuid)}',
    ];
    final response = await _client
        .get(_pairs('/unit_ios', pairs), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    final json = (jsonDecode(response.body) as Map).cast<String, Object?>();
    final ios = <UnitIo>[];
    for (final item in json['unit_ios'] as List<Object?>? ?? const []) {
      if (item is! Map) continue;
      final io = UnitIo.fromJson(item.cast<String, Object?>());
      if (io.uuid.isEmpty) continue;
      ios.add(io);
    }
    final rawCount = json['count'];
    return (count: rawCount is num ? rawCount.round() : ios.length, ios: ios);
  }

  Future<UnitIo> readUnitIo(String token, String uuid) async {
    final response = await _client
        .get(_uri('/unit_ios/$uuid'), headers: _jsonHeaders(token))
        .timeout(_timeout);
    _ensureOk(response);
    return UnitIo.fromJson(
      (jsonDecode(response.body) as Map).cast<String, Object?>(),
    );
  }

  Future<UnitIo> updateUnitIo(
    String token,
    String uuid,
    Map<String, Object?> patch,
  ) async {
    final response = await _client
        .patch(
          _uri('/unit_ios/$uuid'),
          headers: _jsonHeaders(token),
          body: jsonEncode(patch),
        )
        .timeout(_timeout);
    _ensureOk(response);
    return UnitIo.fromJson(
      (jsonDecode(response.body) as Map).cast<String, Object?>(),
    );
  }

  Future<UnitIo> setInputState(String token, String uuid, String state) async {
    final response = await _client
        .patch(
          _uri('/unit_ios/set_state_input/$uuid'),
          headers: _jsonHeaders(token),
          body: jsonEncode({'state': state}),
        )
        .timeout(_timeout);
    _ensureOk(response);
    return UnitIo.fromJson(
      (jsonDecode(response.body) as Map).cast<String, Object?>(),
    );
  }

  Future<void> createIoLink(
    String token, {
    required String outputUuid,
    required String inputUuid,
  }) async {
    final response = await _client
        .post(
          _uri('/unit_ios/create_link'),
          headers: _jsonHeaders(token),
          body: jsonEncode({
            'output_uuid': outputUuid,
            'input_uuid': inputUuid,
          }),
        )
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<List<PipeIssue>> checkPipe(String token, Uint8List yml) async {
    final response = await _file(
      token,
      '/unit_ios/check_data_pipe_config',
      yml,
      'pipe.yml',
    );
    _ensureOk(response);
    return [
      for (final item
          in jsonDecode(response.body) as List<Object?>? ?? const [])
        if (item is Map) PipeIssue.fromJson(item.cast<String, Object?>()),
    ];
  }

  Future<void> setPipe(String token, String uuid, Uint8List yml) async {
    final response = await _file(
      token,
      '/unit_ios/set_data_pipe_config',
      yml,
      'pipe.yml',
      query: {'uuid': uuid},
    );
    _ensureOk(response);
  }

  Future<Uint8List> pipeConfig(String token, String uuid) async {
    final response = await _client
        .get(
          _uri('/unit_ios/get_data_pipe_config/$uuid'),
          headers: _jsonHeaders(token),
        )
        .timeout(_timeout);
    _ensureBytes(response);
    return response.bodyBytes;
  }

  Future<({int count, List<PipeRow> rows})> pipeData({
    required String token,
    required String uuid,
    required String type,
    required int offset,
    required int limit,
  }) async {
    final response = await _client
        .get(
          _uri('/unit_ios/get_data_pipe_data/', {
            'uuid': uuid,
            'type': type,
            'offset': offset,
            'limit': limit,
            'order_by_create_date': 'desc',
          }),
          headers: _jsonHeaders(token),
        )
        .timeout(_timeout);
    _ensureOk(response);
    final json = (jsonDecode(response.body) as Map).cast<String, Object?>();
    final rows = <PipeRow>[];
    for (final item in json['pipe_data'] as List<Object?>? ?? const []) {
      if (item is! Map) continue;
      rows.add(PipeRow.fromJson(item.cast<String, Object?>()));
    }
    final rawCount = json['count'];
    return (
      count: rawCount is num ? rawCount.round() : rows.length,
      rows: rows,
    );
  }

  Future<Uint8List> pipeCsv(String token, String uuid) async {
    final response = await _client
        .get(
          _uri('/unit_ios/get_data_pipe_data_csv/$uuid'),
          headers: _jsonHeaders(token),
        )
        .timeout(const Duration(seconds: 60));
    _ensureBytes(response);
    return response.bodyBytes;
  }

  Future<void> uploadPipeCsv(String token, String uuid, Uint8List csv) async {
    final response = await _file(
      token,
      '/unit_ios/set_data_pipe_data_csv',
      csv,
      'pipe.csv',
      query: {'uuid': uuid},
    );
    _ensureOk(response);
  }

  Future<void> deletePipeData(String token, String uuid) async {
    final response = await _client
        .delete(
          _uri('/unit_ios/delete_data_pipe_data/$uuid'),
          headers: _jsonHeaders(token),
        )
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<AccessGrant> createAccess(
    String token, {
    required String agentUuid,
    required String agentType,
    required String resourceUuid,
    required String resourceType,
  }) async {
    final response = await _client
        .post(
          _uri('/permission'),
          headers: _jsonHeaders(token),
          body: jsonEncode({
            'agent_uuid': agentUuid,
            'agent_type': agentType,
            'resource_uuid': resourceUuid,
            'resource_type': resourceType,
          }),
        )
        .timeout(_timeout);
    _ensureOk(response);
    return AccessGrant.fromJson(
      (jsonDecode(response.body) as Map).cast<String, Object?>(),
    );
  }

  Future<({int count, List<AccessGrant> grants})> accessGrants({
    required String token,
    required String resourceUuid,
    required String resourceType,
    required int offset,
    required int limit,
  }) async {
    final response = await _client
        .get(
          _uri('/permission/get_resource_agents', {
            'resource_uuid': resourceUuid,
            'resource_type': resourceType,
            'offset': offset,
            'limit': limit,
          }),
          headers: _jsonHeaders(token),
        )
        .timeout(_timeout);
    _ensureOk(response);
    final json = (jsonDecode(response.body) as Map).cast<String, Object?>();
    final grants = <AccessGrant>[];
    for (final item in json['permissions'] as List<Object?>? ?? const []) {
      if (item is! Map) continue;
      final grant = AccessGrant.fromJson(item.cast<String, Object?>());
      if (grant.uuid.isEmpty) continue;
      grants.add(grant);
    }
    final rawCount = json['count'];
    return (
      count: rawCount is num ? rawCount.round() : grants.length,
      grants: grants,
    );
  }

  Future<void> deleteAccess(
    String token, {
    required String uuid,
    required String agentUuid,
    required String resourceUuid,
  }) async {
    final response = await _client
        .delete(
          _uri('/permission/$uuid', {
            'agent_uuid': agentUuid,
            'resource_uuid': resourceUuid,
          }),
          headers: _jsonHeaders(token),
        )
        .timeout(_timeout);
    _ensureOk(response);
  }

  Future<String?> uploadEntityIcon(
    String token,
    String entityUuid,
    String entityType,
    Uint8List png,
  ) {
    return _uploadIcon(token, entityUuid, entityType, png);
  }

  Future<Uint8List> icon(String uuid) async {
    final response = await _client.get(_uri('/icons/$uuid')).timeout(_timeout);
    _ensureOk(response);
    return response.bodyBytes;
  }

  Future<String?> _uploadIcon(
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
    if (response.body.trim().isEmpty) return null;
    try {
      final json = jsonDecode(response.body);
      if (json is Map) return json['uuid'] as String?;
    } catch (_) {}
    return null;
  }

  Uri _pairs(String path, List<String> pairs) {
    final tail = pairs.isEmpty ? '' : '?${pairs.join('&')}';
    return Uri.parse('$origin/pepeunit/api/v1$path$tail');
  }

  ({int count, List<Unit> units}) _unitPage(String body) {
    final json = (jsonDecode(body) as Map).cast<String, Object?>();
    final units = <Unit>[];
    for (final item in json['units'] as List<Object?>? ?? const []) {
      if (item is! Map) continue;
      final unit = Unit.fromJson(item.cast<String, Object?>());
      if (unit.uuid.isEmpty) continue;
      units.add(unit);
    }
    final rawCount = json['count'];
    return (
      count: rawCount is num ? rawCount.round() : units.length,
      units: units,
    );
  }

  Future<http.Response> _file(
    String token,
    String path,
    Uint8List bytes,
    String filename, {
    Map<String, Object?>? query,
  }) async {
    final request = http.MultipartRequest('POST', _uri(path, query));
    request.headers['x-auth-token'] = token;
    request.files.add(
      http.MultipartFile.fromBytes('data', bytes, filename: filename),
    );
    final streamed = await _client
        .send(request)
        .timeout(const Duration(seconds: 60));
    return http.Response.fromStream(streamed);
  }

  void _ensureBytes(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw ApiException(response.statusCode, response.body);
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
