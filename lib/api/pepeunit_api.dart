import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../alerts/notice.dart';
import '../dashboards/dashboard.dart';
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

  /// Releases the HTTP client this api owns. A client shared with the model
  /// is closed by the model instead.
  void close() => _client.close();

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

  /// One timeout, one status check, and one JSON header set for every call.
  ///
  /// [json] stays off for the public reads, which send no headers. A null
  /// [token] still sends `content-type` when [json] is on, matching register
  /// and the challenge. [pairs] keeps repeated query keys a map cannot.
  Future<http.Response> _send(
    String method,
    String path, {
    String? token,
    Map<String, Object?>? query,
    Object? body,
    List<String>? pairs,
    Duration? timeout,
    bool bytes = false,
    bool json = true,
  }) async {
    final uri = pairs == null ? _uri(path, query) : _pairs(path, pairs);
    final headers = json ? _jsonHeaders(token) : null;
    final encoded = body == null ? null : jsonEncode(body);
    final Future<http.Response> pending = switch (method) {
      'POST' => _client.post(uri, headers: headers, body: encoded),
      'PATCH' => _client.patch(uri, headers: headers, body: encoded),
      'DELETE' => _client.delete(uri, headers: headers, body: encoded),
      _ => _client.get(uri, headers: headers),
    };
    final response = await pending.timeout(timeout ?? _timeout);
    if (bytes) {
      _ensureBytes(response);
    } else {
      _ensureOk(response);
    }
    return response;
  }

  Map<String, Object?> _object(http.Response response) =>
      (jsonDecode(response.body) as Map).cast<String, Object?>();

  List<T> _list<T>(
    http.Response response,
    T Function(Map<String, Object?> row) read,
  ) {
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return <T>[];
    return [
      for (final item in decoded)
        if (item is Map) read(item.cast<String, Object?>()),
    ];
  }

  /// A counted page. [read] returns null to drop a row, such as an empty uuid.
  ({int count, List<T> rows}) _page<T>(
    http.Response response,
    String key,
    T? Function(Map<String, Object?> row) read,
  ) {
    final json = _object(response);
    final rows = <T>[];
    for (final item in json[key] as List<Object?>? ?? const []) {
      if (item is! Map) continue;
      final row = read(item.cast<String, Object?>());
      if (row == null) continue;
      rows.add(row);
    }
    final raw = json['count'];
    return (count: raw is num ? raw.round() : rows.length, rows: rows);
  }

  Future<InstancePortrait> portrait() async {
    final response = await _send('GET', '/instances/current', json: false);
    final json = _object(response);
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
    final response = await _send(
      'GET',
      '/peers/urls',
      query: {'offset': offset, 'limit': limit},
      json: false,
    );
    final json = _object(response);
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
    final response = await _send(
      'GET',
      '/peers',
      query: {'offset': offset, 'limit': limit},
      json: false,
    );
    final json = _object(response);
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
    await _send('POST', '/peers', token: token, body: {'url': url});
  }

  Future<void> updatePeer(String token, String uuid, String trust) async {
    await _send(
      'PATCH',
      '/peers/$uuid',
      token: token,
      body: {'trust_status': trust},
    );
  }

  Future<void> deletePeer(String token, String uuid) async {
    await _send('DELETE', '/peers/$uuid', token: token);
  }

  Future<void> scanPeer(String token, String uuid) async {
    await _send('POST', '/peers/scan/$uuid', token: token);
  }

  Future<void> scanAll(String token) async {
    await _send('POST', '/peers/scan_all', token: token);
  }

  Future<void> register(String publicKeyBase64) async {
    await _send('POST', '/users', body: {'public_key': publicKeyBase64});
  }

  Future<String> challenge(String hashPublicKey) async {
    final response = await _send(
      'POST',
      '/users/auth/challenge',
      body: {'hash_public_key': hashPublicKey},
    );
    return _object(response)['challenge']! as String;
  }

  Future<String> auth(String challengeToken, String signatureBase64) async {
    final response = await _send(
      'POST',
      '/users/auth',
      body: {'challenge': challengeToken, 'signature': signatureBase64},
    );
    return _object(response)['token']! as String;
  }

  Future<({String role, String uuid})> user(String token, String uuid) async {
    final response = await _send('GET', '/users/$uuid', token: token);
    final json = _object(response);
    return (
      role: json['role'] as String? ?? 'User',
      uuid: json['uuid']! as String,
    );
  }

  Future<String> verificationLink(String token) async {
    final response = await _send(
      'GET',
      '/users/generate_verification_link/',
      token: token,
    );
    final decoded = jsonDecode(response.body);
    if (decoded is String && decoded.isNotEmpty) return decoded;
    throw ApiException(response.statusCode, response.body);
  }

  Future<Map<String, Object?>> settings(String token) async {
    final response = await _send('GET', '/instances/settings', token: token);
    return _object(response);
  }

  Future<Map<String, Object?>> patchSettings(
    String token,
    Map<String, Object?> patch,
  ) async {
    final response = await _send(
      'PATCH',
      '/instances/settings',
      token: token,
      body: patch,
    );
    return _object(response);
  }

  Future<void> reboot(String token) async {
    await _send('POST', '/instances/reboot', token: token);
  }

  Future<void> integrationTests(String token) async {
    await _send('POST', '/instances/integration_tests', token: token);
  }

  Future<void> updateLogin(String token, String userUuid, String login) async {
    await _send(
      'PATCH',
      '/users/$userUuid',
      token: token,
      body: {'login': login},
    );
  }

  Future<Map<String, Object?>> notificationSettings(String token) async {
    final response = await _send(
      'GET',
      '/notifications/settings',
      token: token,
    );
    return _object(response);
  }

  Future<void> updateNotificationSettings(
    String token,
    Map<String, Object?> patch,
  ) async {
    await _send('PATCH', '/notifications/settings', token: token, body: patch);
  }

  Future<({int count, List<Notice> items})> notices({
    required String token,
    required int offset,
    required int limit,
    bool? isRead,
    List<String>? types,
  }) async {
    final response = await _send(
      'GET',
      '/notifications',
      token: token,
      pairs: [
        'offset=$offset',
        'limit=$limit',
        if (isRead != null) 'is_read=$isRead',
        for (final type in types ?? const <String>[])
          'type=${Uri.encodeQueryComponent(type)}',
      ],
    );
    final page = _page(response, 'notifications', (row) {
      final notice = Notice.fromJson(row);
      return notice.uuid.isEmpty ? null : notice;
    });
    return (count: page.count, items: page.rows);
  }

  Future<Notice> markNoticeRead(String token, String uuid) async {
    final response = await _send(
      'PATCH',
      '/notifications/$uuid/read',
      token: token,
    );
    return Notice.fromJson(_object(response));
  }

  Future<int> markAllNoticesRead(String token) async {
    final response = await _send('PATCH', '/notifications/read', token: token);
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
    final response = await _send('GET', '/users', token: token, pairs: pairs);
    final page = _page(response, 'users', (row) {
      final user = DirectoryUser.fromJson(row);
      return user.uuid.isEmpty ? null : user;
    });
    return (count: page.count, users: page.rows);
  }

  Future<DirectoryUser> readDirectoryUser(String token, String uuid) async {
    final response = await _send('GET', '/users/$uuid', token: token);
    return DirectoryUser.fromJson(_object(response));
  }

  Future<DirectoryUser> grantAdmin(String token, String uuid) {
    return _patchUser(token, '/users/grant_admin/$uuid');
  }

  Future<DirectoryUser> revokeAdmin(String token, String uuid) {
    return _patchUser(token, '/users/revoke_admin/$uuid');
  }

  Future<DirectoryUser> blockUser(String token, String uuid) async {
    final response = await _send('PATCH', '/users/block/$uuid', token: token);
    return _userOrFetch(response, token, uuid);
  }

  Future<DirectoryUser> unblockUser(String token, String uuid) async {
    final response = await _send('PATCH', '/users/unblock/$uuid', token: token);
    return _userOrFetch(response, token, uuid);
  }

  /// Block and unblock sometimes return the user and sometimes an empty body.
  /// A parsed user skips the follow-up read.
  Future<DirectoryUser> _userOrFetch(
    http.Response response,
    String token,
    String uuid,
  ) async {
    final parsed = _maybeUser(response);
    if (parsed != null) return parsed;
    return readDirectoryUser(token, uuid);
  }

  DirectoryUser? _maybeUser(http.Response response) {
    try {
      final trimmed = response.body.trim();
      if (trimmed.isEmpty || trimmed == 'null') return null;
      final decoded = jsonDecode(trimmed);
      if (decoded is! Map) return null;
      final user = DirectoryUser.fromJson(decoded.cast<String, Object?>());
      if (user.uuid.isEmpty) return null;
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<DirectoryUser> _patchUser(String token, String path) async {
    final response = await _send('PATCH', path, token: token);
    return DirectoryUser.fromJson(_object(response));
  }

  Future<({int count, List<RegistryRepo> repos})> repos({
    required String token,
    required int offset,
    required int limit,
    required String search,
    required String order,
    bool? public,
  }) async {
    final response = await _send(
      'GET',
      '/repo',
      token: token,
      query: {
        'offset': offset,
        'limit': limit,
        'order_by_repository_url': order,
        if (search.trim().isNotEmpty) 'search_string': search.trim(),
        'is_public_repository': ?public,
      },
    );
    final page = _page(response, 'repos', (row) {
      final repo = RegistryRepo.fromJson(row);
      return repo.uuid.isEmpty ? null : repo;
    });
    return (count: page.count, repos: page.rows);
  }

  /// `POST /repo`. `credentials` goes only with a private repository.
  Future<RegistryRepo> createRepo(
    String token, {
    required String url,
    required String platform,
    required bool public,
    String? username,
    String? pat,
  }) async {
    final response = await _send(
      'POST',
      '/repo',
      token: token,
      body: {
        'repository_url': url,
        'platform': platform,
        'is_public_repository': public,
        if (!public) 'credentials': {'username': username, 'pat_token': pat},
      },
    );
    return RegistryRepo.fromJson(_object(response));
  }

  Future<RegistryRepo> readRepo(String token, String uuid) async {
    final response = await _send('GET', '/repo/$uuid', token: token);
    return RegistryRepo.fromJson(_object(response));
  }

  Future<void> deleteRepo(String token, String uuid) async {
    await _send('DELETE', '/repo/$uuid', token: token);
  }

  Future<void> updateLocalRepository(String token, String uuid) async {
    await _send('PATCH', '/repo/update_local_repository/$uuid', token: token);
  }

  Future<RepoCredentials?> repoCredentials(String token, String uuid) async {
    final response = await _send(
      'GET',
      '/repo/get_credentials/$uuid',
      token: token,
    );
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
    await _send(
      'PATCH',
      '/repo/set_credentials/$uuid',
      token: token,
      body: {'username': username, 'pat_token': pat},
    );
  }

  Future<void> updateAllRepos(String token) async {
    await _send('PATCH', '/repo/update_all', token: token);
  }

  Future<({int count, List<RepoCommit> commits})> branchCommits(
    String token,
    String uuid, {
    required String branch,
    bool onlyTag = false,
    String search = '',
    int offset = 0,
    int limit = 100,
  }) async {
    final needle = search.trim();
    final response = await _send(
      'GET',
      '/repo/branch_commits/$uuid',
      token: token,
      query: {
        'repo_branch': branch,
        'only_tag': onlyTag,
        'offset': offset,
        'limit': limit,
        if (needle.isNotEmpty) 'search_string': needle,
      },
    );
    final page = _page(response, 'commits', RepoCommit.fromJson);
    return (count: page.count, commits: page.rows);
  }

  Future<List<FirmwarePlatform>> firmwarePlatforms(
    String token,
    String uuid, {
    String? branch,
    String? commit,
    String? tag,
  }) async {
    final response = await _send(
      'GET',
      '/repo/available_platforms/$uuid',
      token: token,
      query: {'branch': ?branch, 'target_commit': ?commit, 'target_tag': ?tag},
    );
    return _list(response, FirmwarePlatform.fromJson);
  }

  Future<Unit> createUnit(String token, Map<String, Object?> body) async {
    final response = await _send('POST', '/units', token: token, body: body);
    return Unit.fromJson(_object(response));
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
    List<String>? ioTypes,
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
      // Only units that have a node of these types are listed, and each
      // carries those nodes.
      for (final type in ioTypes ?? const <String>[])
        'unit_io_type=${Uri.encodeQueryComponent(type)}',
      if (includeIos || ioTypes != null) 'is_include_output_unit_ios=true',
    ];
    final response = await _send('GET', '/units', token: token, pairs: pairs);
    return _units(response);
  }

  Future<Unit> readUnit(String token, String uuid) async {
    final response = await _send('GET', '/units/$uuid', token: token);
    return Unit.fromJson(_object(response));
  }

  Future<Unit> updateUnit(
    String token,
    String uuid,
    Map<String, Object?> patch,
  ) async {
    final response = await _send(
      'PATCH',
      '/units/$uuid',
      token: token,
      body: patch,
    );
    return Unit.fromJson(_object(response));
  }

  Future<void> deleteUnit(String token, String uuid) async {
    await _send('DELETE', '/units/$uuid', token: token);
  }

  Future<Map<String, Object?>> unitEnv(String token, String uuid) async {
    final response = await _send('GET', '/units/env/$uuid', token: token);
    return _object(response);
  }

  Future<void> setUnitEnv(
    String token,
    String uuid,
    Map<String, Object?> env,
  ) async {
    await _send(
      'PATCH',
      '/units/env/$uuid',
      token: token,
      body: {'env_json_string': jsonEncode(env)},
    );
  }

  Future<void> resetUnitEnv(String token, String uuid) async {
    await _send('DELETE', '/units/env/$uuid', token: token);
  }

  Future<({String commit, String? tag})> targetVersion(
    String token,
    String uuid,
  ) async {
    final response = await _send(
      'GET',
      '/units/get_target_version/$uuid',
      token: token,
    );
    final json = _object(response);
    final tag = json['tag'];
    return (
      commit: json['commit'] as String? ?? '',
      tag: tag is String && tag.isNotEmpty ? tag : null,
    );
  }

  Future<String> unitSchema(String token, String uuid) async {
    final response = await _send(
      'GET',
      '/units/get_current_schema/$uuid',
      token: token,
    );
    return response.body;
  }

  Future<Uint8List> unitFirmware(String token, String uuid, String kind) async {
    final response = await _send(
      'GET',
      '/units/firmware/$kind/$uuid',
      token: token,
      query: kind == 'tgz' ? {'wbits': 9, 'level': 9} : null,
      timeout: const Duration(seconds: 60),
      bytes: true,
    );
    return response.bodyBytes;
  }

  Future<String> unitStateStorage(String token, String uuid) async {
    final response = await _send(
      'GET',
      '/units/get_state_storage/$uuid',
      token: token,
    );
    final decoded = jsonDecode(response.body);
    return decoded is String ? decoded : response.body;
  }

  Future<void> sendUnitCommand(
    String token,
    String uuid,
    String command,
  ) async {
    await _send(
      'POST',
      '/units/send_command_to_input_base_topic/$uuid',
      token: token,
      query: {'command': command},
    );
  }

  Future<void> bulkUpdateUnits(String token) async {
    await _send('POST', '/units/bulk_update', token: token);
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
    final response = await _send(
      'GET',
      '/units/log_list/',
      token: token,
      pairs: pairs,
    );
    final page = _page(response, 'unit_logs', (row) {
      final log = UnitLog.fromJson(row);
      return log.uuid.isEmpty ? null : log;
    });
    return (count: page.count, logs: page.rows);
  }

  Future<Uint8List> downloadUnitLogs(String token, String uuid) async {
    final response = await _send(
      'GET',
      '/units/logs/$uuid',
      token: token,
      timeout: const Duration(seconds: 60),
      bytes: true,
    );
    return response.bodyBytes;
  }

  Future<UnitGroup> createGroup(String token, String name) async {
    final response = await _send(
      'POST',
      '/unit_groups',
      token: token,
      body: {'name': name},
    );
    return UnitGroup.fromJson(_object(response));
  }

  Future<({int count, List<UnitGroup> groups})> groups({
    required String token,
    required int offset,
    required int limit,
    String search = '',
    String order = 'asc',
    String? unitUuid,
  }) async {
    final response = await _send(
      'GET',
      '/unit_groups',
      token: token,
      query: {
        'offset': offset,
        'limit': limit,
        'order_by_group_name': order,
        if (search.trim().isNotEmpty) 'search_string': search.trim(),
        'unit_uuid': ?unitUuid,
      },
    );
    final page = _page(response, 'unit_groups', (row) {
      final group = UnitGroup.fromJson(row);
      return group.uuid.isEmpty ? null : group;
    });
    return (count: page.count, groups: page.rows);
  }

  Future<UnitGroup> readGroup(String token, String uuid) async {
    final response = await _send('GET', '/unit_groups/$uuid', token: token);
    return UnitGroup.fromJson(_object(response));
  }

  Future<UnitGroup> renameGroup(String token, String uuid, String name) async {
    final response = await _send(
      'PATCH',
      '/unit_groups/$uuid',
      token: token,
      body: {'name': name},
    );
    return UnitGroup.fromJson(_object(response));
  }

  Future<void> deleteGroup(String token, String uuid) async {
    await _send('DELETE', '/unit_groups/$uuid', token: token);
  }

  Future<({int count, List<Unit> units})> groupUnits({
    required String token,
    required String uuid,
    required int offset,
    required int limit,
    String search = '',
    String order = 'asc',
  }) async {
    final response = await _send(
      'GET',
      '/unit_groups/$uuid/units',
      token: token,
      query: {
        'offset': offset,
        'limit': limit,
        'order_by_unit_name': order,
        if (search.trim().isNotEmpty) 'search_string': search.trim(),
      },
    );
    return _units(response);
  }

  Future<void> linkGroupUnit(String token, String uuid, String unitUuid) async {
    await _send('POST', '/unit_groups/$uuid/units/$unitUuid', token: token);
  }

  Future<void> unlinkGroupUnit(
    String token,
    String uuid,
    String unitUuid,
  ) async {
    await _send('DELETE', '/unit_groups/$uuid/units/$unitUuid', token: token);
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
    final response = await _send(
      'GET',
      '/unit_ios',
      token: token,
      pairs: pairs,
    );
    final page = _page(response, 'unit_ios', (row) {
      final io = UnitIo.fromJson(row);
      return io.uuid.isEmpty ? null : io;
    });
    return (count: page.count, ios: page.rows);
  }

  Future<UnitIo> readUnitIo(String token, String uuid) async {
    final response = await _send('GET', '/unit_ios/$uuid', token: token);
    return UnitIo.fromJson(_object(response));
  }

  Future<UnitIo> updateUnitIo(
    String token,
    String uuid,
    Map<String, Object?> patch,
  ) async {
    final response = await _send(
      'PATCH',
      '/unit_ios/$uuid',
      token: token,
      body: patch,
    );
    return UnitIo.fromJson(_object(response));
  }

  Future<UnitIo> setInputState(String token, String uuid, String state) async {
    final response = await _send(
      'PATCH',
      '/unit_ios/set_state_input/$uuid',
      token: token,
      body: {'state': state},
    );
    return UnitIo.fromJson(_object(response));
  }

  Future<void> createIoLink(
    String token, {
    required String outputUuid,
    required String inputUuid,
  }) async {
    await _send(
      'POST',
      '/unit_ios/create_link',
      token: token,
      body: {'output_uuid': outputUuid, 'input_uuid': inputUuid},
    );
  }

  Future<void> deleteIoLink(
    String token, {
    required String outputUuid,
    required String inputUuid,
  }) async {
    await _send(
      'DELETE',
      '/unit_ios/delete_link',
      token: token,
      query: {'input_uuid': inputUuid, 'output_uuid': outputUuid},
    );
  }

  Future<List<PipeIssue>> checkPipe(String token, Uint8List yml) async {
    final response = await _file(
      token,
      '/unit_ios/check_data_pipe_config',
      yml,
      'pipe.yml',
    );
    _ensureOk(response);
    return _list(response, PipeIssue.fromJson);
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
    final response = await _send(
      'GET',
      '/unit_ios/get_data_pipe_config/$uuid',
      token: token,
      bytes: true,
    );
    return response.bodyBytes;
  }

  Future<({int count, List<PipeRow> rows})> pipeData({
    required String token,
    required String uuid,
    required String type,
    required int offset,
    required int limit,
  }) async {
    final response = await _send(
      'GET',
      '/unit_ios/get_data_pipe_data/',
      token: token,
      query: {
        'uuid': uuid,
        'type': type,
        'offset': offset,
        'limit': limit,
        'order_by_create_date': 'desc',
      },
    );
    final page = _page(response, 'pipe_data', PipeRow.fromJson);
    return (count: page.count, rows: page.rows);
  }

  Future<Uint8List> pipeCsv(String token, String uuid) async {
    final response = await _send(
      'GET',
      '/unit_ios/get_data_pipe_data_csv/$uuid',
      token: token,
      timeout: const Duration(seconds: 60),
      bytes: true,
    );
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
    await _send(
      'DELETE',
      '/unit_ios/delete_data_pipe_data/$uuid',
      token: token,
    );
  }

  Future<AccessGrant> createAccess(
    String token, {
    required String agentUuid,
    required String agentType,
    required String resourceUuid,
    required String resourceType,
  }) async {
    final response = await _send(
      'POST',
      '/permission',
      token: token,
      body: {
        'agent_uuid': agentUuid,
        'agent_type': agentType,
        'resource_uuid': resourceUuid,
        'resource_type': resourceType,
      },
    );
    return AccessGrant.fromJson(_object(response));
  }

  Future<({int count, List<AccessGrant> grants})> accessGrants({
    required String token,
    required String resourceUuid,
    required String resourceType,
    required int offset,
    required int limit,
  }) async {
    final response = await _send(
      'GET',
      '/permission/get_resource_agents',
      token: token,
      query: {
        'resource_uuid': resourceUuid,
        'resource_type': resourceType,
        'offset': offset,
        'limit': limit,
      },
    );
    final page = _page(response, 'permissions', (row) {
      final grant = AccessGrant.fromJson(row);
      return grant.uuid.isEmpty ? null : grant;
    });
    return (count: page.count, grants: page.rows);
  }

  Future<void> deleteAccess(
    String token, {
    required String uuid,
    required String agentUuid,
    required String resourceUuid,
  }) async {
    await _send(
      'DELETE',
      '/permission/$uuid',
      token: token,
      query: {'agent_uuid': agentUuid, 'resource_uuid': resourceUuid},
    );
  }

  Future<String?> uploadEntityIcon(
    String token,
    String entityUuid,
    String entityType,
    Uint8List png,
  ) {
    return _uploadIcon(token, entityUuid, entityType, png);
  }

  Future<Dashboard> createDashboard(String token, String name) async {
    final response = await _send(
      'POST',
      '/grafana/create_dashboard',
      token: token,
      body: {'name': name},
    );
    return Dashboard.fromJson(_object(response));
  }

  /// Dashboards of the signed-in user. The backend lists no one else's.
  Future<({int count, List<Dashboard> dashboards})> dashboards({
    required String token,
    required int offset,
    required int limit,
    String search = '',
    String order = 'desc',
  }) async {
    final response = await _send(
      'GET',
      '/grafana/get_dashboards',
      token: token,
      query: {
        'offset': offset,
        'limit': limit,
        'order_by_create_date': order,
        if (search.trim().isNotEmpty) 'search_string': search.trim(),
      },
    );
    final page = _page(response, 'dashboards', (row) {
      final dashboard = Dashboard.fromJson(row);
      return dashboard.uuid.isEmpty ? null : dashboard;
    });
    return (count: page.count, dashboards: page.rows);
  }

  Future<Dashboard> readDashboard(String token, String uuid) async {
    final response = await _send(
      'GET',
      '/grafana/get_dashboard/$uuid',
      token: token,
    );
    return Dashboard.fromJson(_object(response));
  }

  /// Sends the dashboard to Grafana. The backend checks every linked node
  /// first, so the call is given more time than a read.
  Future<Dashboard> syncDashboard(String token, String uuid) async {
    final response = await _send(
      'POST',
      '/grafana/sync_dashboard',
      token: token,
      query: {'uuid': uuid},
      timeout: const Duration(seconds: 90),
    );
    return Dashboard.fromJson(_object(response));
  }

  Future<void> deleteDashboard(String token, String uuid) async {
    await _send('DELETE', '/grafana/delete_dashboard/$uuid', token: token);
  }

  /// Every panel of one dashboard with its linked nodes. The backend does not
  /// page this list.
  Future<List<DashboardPanel>> dashboardPanels(
    String token,
    String uuid,
  ) async {
    final response = await _send(
      'GET',
      '/grafana/get_dashboard_panels/$uuid',
      token: token,
    );
    final page = _page(response, 'panels', (row) {
      final panel = DashboardPanel.fromJson(row);
      return panel.uuid.isEmpty ? null : panel;
    });
    return page.rows;
  }

  Future<DashboardPanel> createPanel(
    String token, {
    required String dashboardUuid,
    required String title,
    required String type,
  }) async {
    final response = await _send(
      'POST',
      '/grafana/create_dashboard_panel',
      token: token,
      body: {'dashboard_uuid': dashboardUuid, 'title': title, 'type': type},
    );
    return DashboardPanel.fromJson(_object(response));
  }

  Future<void> deletePanel(String token, String uuid) async {
    await _send('DELETE', '/grafana/delete_panel/$uuid', token: token);
  }

  Future<PanelLink> linkPanelIo(
    String token, {
    required String panelUuid,
    required String ioUuid,
    required bool lastOnly,
    required bool asJson,
  }) async {
    final response = await _send(
      'POST',
      '/grafana/link_unit_io_to_panel',
      token: token,
      body: {
        'unit_io_uuid': ioUuid,
        'dashboard_panels_uuid': panelUuid,
        'is_last_data': lastOnly,
        'is_forced_to_json': asJson,
      },
    );
    return PanelLink.fromJson(_object(response));
  }

  /// The route carries a `{uuid}` segment the handler never reads, so the
  /// panel uuid fills it. The pair travels in the query.
  Future<void> deletePanelLink(
    String token, {
    required String panelUuid,
    required String ioUuid,
  }) async {
    await _send(
      'DELETE',
      '/grafana/delete_link/$panelUuid',
      token: token,
      query: {'unit_io_uuid': ioUuid, 'dashboard_panel_uuid': panelUuid},
    );
  }

  /// Grafana organization of a user. It exists after the first sync.
  Future<String?> grafanaOrgId(String token, String uuid) async {
    final response = await _send('GET', '/users/$uuid', token: token);
    final id = _object(response)['grafana_org_id'];
    return id is String && id.isNotEmpty ? id : null;
  }

  Future<Uint8List> icon(String uuid) async {
    final response = await _send('GET', '/icons/$uuid', json: false);
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

  ({int count, List<Unit> units}) _units(http.Response response) {
    final page = _page(response, 'units', (row) {
      final unit = Unit.fromJson(row);
      return unit.uuid.isEmpty ? null : unit;
    });
    return (count: page.count, units: page.rows);
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
