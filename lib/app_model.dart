import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'account/alerts.dart';
import 'alerts/notice.dart';
import 'account/icon_file.dart';
import 'account/identity.dart';
import 'account/key_file_port.dart';
import 'account/vault.dart';
import 'account/vault_store.dart';
import 'api/icon_disk.dart';
import 'api/icon_disk_open.dart';
import 'api/icon_store.dart';
import 'api/pepeunit_api.dart';
import 'dashboards/dashboard.dart';
import 'instances/directory_user.dart';
import 'instances/hosted_url.dart';
import 'instances/instance.dart';
import 'instances/link.dart';
import 'instances/network_view.dart';
import 'instances/portrait.dart';
import 'instances/session.dart';
import 'locale/languages.dart';
import 'registry/registry_view.dart';
import 'registry/repo.dart';
import 'units/unit.dart';
import 'units/unit_view.dart';

class SyncReport {
  const SyncReport(this.reached, this.problems);

  final int reached;
  final List<String> problems;

  bool get empty => reached == 0 && problems.isEmpty;
}

/// One row of a name picker: the value it answers with and its label.
typedef PickItem = ({String id, String label});

class AppModel extends ChangeNotifier {
  AppModel({
    required this.store,
    KeyFilePort? files,
    PepeunitApi Function(String origin)? api,
    Future<String?> Function()? hostedUrl,
    Future<IconDisk?> Function()? iconDisk,
    http.Client? client,
    this.openLink,
  }) : files = files ?? PlatformKeyFilePort(),
       hostedUrl = hostedUrl ?? readHostedInstanceUrl,
       _apiClient = client ?? http.Client(),
       _icons = IconStore(openDisk: iconDisk ?? openIconDisk) {
    this.api = api ?? _cachedApi;
  }

  final VaultStore store;
  final KeyFilePort files;
  late final PepeunitApi Function(String origin) api;
  final Future<String?> Function() hostedUrl;
  final Future<void> Function(Uri uri)? openLink;

  Vault vault = Vault.fresh();
  bool ready = false;
  bool networkBusy = false;
  String? networkFailure;

  /// One HTTP client is shared by every origin the model talks to, so a
  /// page or an icon does not open a fresh pool and handshake per call.
  final http.Client _apiClient;
  final Map<String, PepeunitApi> _apiCache = {};

  PepeunitApi _cachedApi(String origin) {
    return _apiCache[origin] ??= PepeunitApi(origin, client: _apiClient);
  }

  @override
  void dispose() {
    _disposed = true;
    // Cached api objects share [_apiClient]; the cache never fills when a
    // caller injected its own factory.
    _apiCache.clear();
    _apiClient.close();
    _noticeClient?.close();
    super.dispose();
  }

  final NetworkQuery query = NetworkQuery();
  final UserQuery userQuery = UserQuery();
  ({int count, List<DirectoryUser> users})? directory;
  var directoryOffset = 0;
  var directoryLimit = 16;
  var _directoryTicket = 0;
  final RepoQuery repoQuery = RepoQuery();
  final UnitQuery unitQuery = UnitQuery();
  ({int count, List<RegistryRepo> repos})? registry;
  var _registryTicket = 0;
  final NoticeQuery noticeQuery = NoticeQuery();
  ({int count, List<Notice> items})? notices;
  var noticeOffset = 0;
  var noticeLimit = 0;
  var noticeRevision = 0;
  var unreadCount = 0;

  /// Every notice of this user, read and unread. Null until the first fetch.
  int? noticeTotal;

  /// How many dashboards the signed-in user owns, for the home cell. The
  /// instance portrait carries no such number.
  int? dashboardTotal;
  String? _dashboardKey;
  int _dashboardTicket = 0;
  var _noticeTicket = 0;
  var _noticeLoad = 0;
  String? _noticeKey;
  http.Client? _noticeClient;
  final Set<String> _noticeSeen = {};
  int _noticeRetrySeconds = 3;
  final Set<String> discovered = {};
  final Map<String, PeerHead> peers = {};
  final Map<String, InstancePortrait> portraits = {};

  /// Icon bytes, keyed by origin and uuid. Reads go through [_icons].
  final IconStore _icons;
  Map<String, Uint8List> get icons => _icons.memory;
  Map<String, Object?>? targetSettings;
  Future<void> _pending = Future<void>.value();
  var _ticket = 0;
  var _disposed = false;
  var _notifyScheduled = false;

  /// Marks the model dirty and notifies once on the next microtask. A burst
  /// of notices or icons rebuilds the screens once, not once per event.
  void _notifySoon() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    scheduleMicrotask(() {
      _notifyScheduled = false;
      if (_disposed) return;
      notifyListeners();
    });
  }

  InstanceRecord? get target => vault.target;

  /// The active instance has a signed-in person.
  bool get signedIn => target?.signedIn == true;

  /// The note a screen shows when it was opened without a sign-in.
  String get notSignedIn =>
      phrase(vault.language, {'ru': 'Нет входа', 'en': 'Not signed in'});

  static const profileCooldown = Duration(minutes: 1);
  static const resignCooldown = Duration(minutes: 1);
  static const registrationCooldown = Duration(minutes: 2);

  /// Epoch milliseconds of the last successful re-login, per instance url.
  final Map<String, int> resignAt = {};

  /// Time left before the profile can be sent again.
  Duration get profileCooldownLeft =>
      _windowLeft(vault.profileSentAt, profileCooldown);

  /// Time left before the favorite instance can be signed in again.
  Duration resignCooldownLeft(String raw) =>
      _windowLeft(resignAt[canonicalInstanceUrl(raw)], resignCooldown);

  /// Time left before another account can be registered.
  Duration get registrationCooldownLeft =>
      _windowLeft(vault.registeredAt, registrationCooldown);

  bool get canSendProfile =>
      vault.target != null && profileCooldownLeft == Duration.zero;

  InstancePortrait? portraitOf(String url) =>
      portraits[url] ?? peers[url]?.portrait;

  /// `pu_instance_max_pagination_size` from `/instances/current`.
  int get pageLimit {
    final url = target?.url;
    final size = url == null ? null : portraitOf(url)?.pagination;
    if (size == null || size < 1) return 100;
    return size;
  }

  /// A list request never asks for more rows than [pageLimit].
  int cappedLimit(int asked) {
    final cap = pageLimit;
    if (asked < 1) return 1;
    if (asked > cap) return cap;
    return asked;
  }

  Uint8List? cachedIcon(String? uuid) {
    final url = target?.url;
    if (url == null || uuid == null || uuid.isEmpty) return null;
    return _icons.peek(IconStore.keyOf(originOf(url), uuid));
  }

  Uint8List? iconOf(String url) {
    final uuid = portraitOf(url)?.iconUuid;
    if (uuid == null) return null;
    return _icons.peek(IconStore.keyOf(originOf(url), uuid));
  }

  /// Urls the client knows, after the allow and deny lists and the search.
  List<String> visibleInstances({bool searched = true}) {
    final known = <String>{
      ...discovered,
      ...vault.pinned,
      if (target != null) target!.url,
    };
    final admitted = known.where(vault.admits).toList()..sort();
    if (!searched) return admitted;
    return [
      for (final url in admitted)
        if (query.matches(url, peers[url]?.trust)) url,
    ];
  }

  List<String> catalog() {
    final known = <String>{
      ...discovered,
      ...vault.pinned,
      ...vault.allow,
      ...vault.deny,
      if (target != null) target!.url,
    };
    final urls = known.toList()..sort();
    return urls;
  }

  /// With [waitForNetwork] false the first screen opens at once and the
  /// instance refresh runs behind it, so a slow or unreachable instance
  /// does not hold the start.
  Future<void> load({String? hostedUrl, bool waitForNetwork = true}) async {
    vault = await store.read();
    final hosted = hostedUrl ?? await this.hostedUrl();
    final chosen = _canonicalOrNull(hosted);
    final current = vault.target;
    if (chosen != null &&
        (current == null ||
            (_loopback(current.url) && current.url != chosen))) {
      vault.instances.removeWhere((instance) => _loopback(instance.url));
      _activate(chosen);
      await _commit();
    }
    ready = true;
    if (vault.target != null) {
      final refresh = refreshTarget();
      if (waitForNetwork) await refresh;
    } else {
      notifyListeners();
    }
  }

  /// Starts the registration wait at the moment the cell is pressed.
  ///
  /// Sign out does not clear it, so the registration cell stays inactive
  /// while the new account is still signed in and after a quick sign-out.
  Future<void> holdRegistration() {
    vault.registeredAt = DateTime.now().millisecondsSinceEpoch;
    return _commit();
  }

  Future<void> adoptIdentity(Identity identity) {
    vault.publicKey = identity.publicKeyBase64;
    vault.secretKey = identity.secretKeyBase64;
    final pending = _commit();
    if (vault.target != null) {
      return pending.then((_) => refreshTarget());
    }
    return pending;
  }

  Future<void> signOut() {
    vault.clearSession();
    targetSettings = null;
    _syncNoticeStream();
    return _commit();
  }

  Future<void> setLogin(String login) {
    if (vault.login == login) return Future<void>.value();
    vault.login = login;
    return _commit();
  }

  Future<void> setIcon(Uint8List? png) {
    vault.iconPng = png == null || png.isEmpty ? null : base64.encode(png);
    return _commit();
  }

  Future<void> setLanguage(String code) {
    if (!knownLanguage(code) || vault.language == code) {
      return Future<void>.value();
    }
    vault.language = code;
    return _commit();
  }

  Future<void> setLibraryRaw(bool value) {
    if (vault.libraryRaw == value) return Future<void>.value();
    vault.libraryRaw = value;
    return _commit();
  }

  Future<void> setTimeZone(int minutes) {
    final stored = minutes.toString();
    if (vault.timeZone == stored) return Future<void>.value();
    vault.timeZone = stored;
    return _commit();
  }

  Future<void> setScheduledAlerts(bool value) {
    if (vault.alerts.scheduled == value) return Future<void>.value();
    vault.alerts = vault.alerts.copyWith(scheduled: value);
    return _commit();
  }

  Future<void> setDataPipeAlerts(bool value) {
    if (vault.alerts.dataPipe == value) return Future<void>.value();
    vault.alerts = vault.alerts.copyWith(dataPipe: value);
    return _commit();
  }

  Future<void> setTelegramAlerts(bool value) {
    if (vault.alerts.telegram == value) return Future<void>.value();
    vault.alerts = vault.alerts.copyWith(telegram: value);
    return _commit();
  }

  Future<void> setAlertTime(String raw) {
    final time = canonicalAlertTime(raw);
    if (time == null || vault.alerts.time == time) return Future<void>.value();
    vault.alerts = vault.alerts.copyWith(time: time);
    return _commit();
  }

  void setSearch(String text) {
    query.text = text;
    notifyListeners();
  }

  void toggleTrust(String status) {
    query.toggleTrust(status);
    notifyListeners();
  }

  void setUserSearch(String text) {
    if (userQuery.text == text) return;
    userQuery.text = text;
    notifyListeners();
  }

  bool toggleUserRole(String role) {
    final changed = userQuery.toggleRole(role);
    if (changed) notifyListeners();
    return changed;
  }

  bool toggleUserStatus(String status) {
    final changed = userQuery.toggleStatus(status);
    if (changed) notifyListeners();
    return changed;
  }

  bool setUserOrder(String value) {
    final changed = userQuery.setOrder(value);
    if (changed) notifyListeners();
    return changed;
  }

  void setRepoSearch(String text) {
    if (repoQuery.text == text) return;
    repoQuery.text = text;
    notifyListeners();
  }

  bool toggleRepoKind(String kind) {
    final changed = repoQuery.toggleKind(kind);
    if (changed) notifyListeners();
    return changed;
  }

  bool setRepoOrder(String value) {
    final changed = repoQuery.setOrder(value);
    if (changed) notifyListeners();
    return changed;
  }

  void setUnitSearch(String text) {
    if (unitQuery.text == text) return;
    unitQuery.text = text;
    notifyListeners();
  }

  bool setUnitOwner(String value) {
    final changed = unitQuery.setOwner(value);
    if (changed) notifyListeners();
    return changed;
  }

  bool toggleUnitVisibility(String level) {
    final changed = unitQuery.toggleVisibility(level);
    if (changed) notifyListeners();
    return changed;
  }

  bool toggleUnitAuto(String auto) {
    final changed = unitQuery.toggleAuto(auto);
    if (changed) notifyListeners();
    return changed;
  }

  bool setUnitOrder(String value) {
    final changed = unitQuery.setOrder(value);
    if (changed) notifyListeners();
    return changed;
  }

  Future<bool> loadDirectory({required int offset, required int limit}) async {
    final current = _signedTarget();
    final ticket = ++_directoryTicket;
    final page = await api(originOf(current.url)).directoryUsers(
      token: current.token!,
      offset: offset,
      limit: cappedLimit(limit),
      search: userQuery.text,
      roles: [
        for (final role in userRoles)
          if (userQuery.roles.contains(role)) role,
      ],
      statuses: [
        for (final status in userStatuses)
          if (userQuery.statuses.contains(status)) status,
      ],
      order: userQuery.order,
    );
    if (ticket != _directoryTicket) return false;
    directory = page;
    directoryOffset = offset;
    directoryLimit = limit;
    notifyListeners();
    unawaited(_loadMemberIcons(ticket, current.url, page.users));
    return true;
  }

  Future<bool> loadRegistry({required int offset, required int limit}) async {
    final current = _signedTarget();
    final ticket = ++_registryTicket;
    final page = await api(originOf(current.url)).repos(
      token: current.token!,
      offset: offset,
      limit: cappedLimit(limit),
      search: repoQuery.text,
      order: repoQuery.order,
      public: repoQuery.publicOnly,
    );
    if (ticket != _registryTicket) return false;
    registry = page;
    notifyListeners();
    unawaited(_loadRepoIcons(ticket, current.url, page.repos));
    return true;
  }

  /// Keeps every type the role can receive selected until the user toggles one.
  void alignNoticeTypes(String? role) {
    final available = noticeTypesForRole(role).toSet();
    if (!noticeQuery.tuned) {
      noticeQuery.types
        ..clear()
        ..addAll(available);
      return;
    }
    noticeQuery.types.removeWhere((type) => !available.contains(type));
  }

  bool setNoticeRead(String value) {
    if (!noticeReads.contains(value) || value == noticeQuery.read) {
      return false;
    }
    noticeQuery.read = value;
    noticeRevision++;
    notifyListeners();
    return true;
  }

  bool toggleNoticeType(String type) {
    final role = target?.role;
    final available = noticeTypesForRole(role);
    if (!available.contains(type)) return false;
    alignNoticeTypes(role);
    noticeQuery.tuned = true;
    if (noticeQuery.types.contains(type)) {
      noticeQuery.types.remove(type);
    } else {
      noticeQuery.types.add(type);
    }
    noticeRevision++;
    notifyListeners();
    return true;
  }

  List<String> _selectedNoticeTypes(String? role) {
    final available = noticeTypesForRole(role);
    return [
      for (final type in available)
        if (noticeQuery.types.contains(type)) type,
    ];
  }

  Future<bool> loadNotices({required int offset, required int limit}) async {
    final current = _signedTarget();
    alignNoticeTypes(current.role);
    final types = _selectedNoticeTypes(current.role);
    final ticket = ++_noticeLoad;
    noticeOffset = offset;
    noticeLimit = limit;
    if (types.isEmpty) {
      notices = (count: 0, items: const <Notice>[]);
      notifyListeners();
      return ticket == _noticeLoad;
    }
    final page = await api(originOf(current.url)).notices(
      token: current.token!,
      offset: offset,
      limit: cappedLimit(limit),
      isRead: switch (noticeQuery.read) {
        'read' => true,
        'unread' => false,
        _ => null,
      },
      types: types,
    );
    if (ticket != _noticeLoad) return false;
    notices = page;
    if (offset == 0 &&
        noticeQuery.read == 'unread' &&
        noticeQuery.showsAll(current.role)) {
      unreadCount = page.count;
    }
    notifyListeners();
    return true;
  }

  Future<void> markNoticeRead(String uuid) async {
    final current = _signedTarget();
    final updated = await api(originOf(current.url))
        .markNoticeRead(current.token!, uuid);
    final page = notices;
    if (page != null) {
      final hide = noticeQuery.read == 'unread' && updated.isRead;
      final items = <Notice>[];
      var removed = false;
      for (final item in page.items) {
        if (item.uuid != uuid) {
          items.add(item);
          continue;
        }
        if (hide) {
          removed = true;
          continue;
        }
        items.add(updated);
      }
      notices = (
        count: removed && page.count > 0 ? page.count - 1 : page.count,
        items: items,
      );
    }
    final wasUnread = page?.items.any(
      (item) => item.uuid == uuid && !item.isRead,
    );
    if ((wasUnread ?? true) && updated.isRead && unreadCount > 0) {
      unreadCount -= 1;
    }
    notifyListeners();
  }

  Future<void> markAllNoticesRead() async {
    final current = _signedTarget();
    await api(originOf(current.url)).markAllNoticesRead(current.token!);
    unreadCount = 0;
    final page = notices;
    if (page != null) {
      if (noticeQuery.read == 'unread') {
        notices = (count: 0, items: const <Notice>[]);
      } else {
        notices = (
          count: page.count,
          items: [for (final item in page.items) item.copyWith(isRead: true)],
        );
      }
    }
    notifyListeners();
  }

  void _takeNotice(Notice notice) {
    if (notice.uuid.isEmpty || !_noticeSeen.add(notice.uuid)) return;
    if (_noticeSeen.length > 200) {
      _noticeSeen.remove(_noticeSeen.first);
    }
    if (!notice.isRead) unreadCount += 1;
    if (noticeTotal != null) noticeTotal = noticeTotal! + 1;
    final page = notices;
    final current = target;
    if (page != null && current != null && noticeQuery.accepts(notice)) {
      final items = [...page.items];
      if (noticeOffset == 0 && !items.any((item) => item.uuid == notice.uuid)) {
        items.insert(0, notice);
        if (noticeLimit > 0 && items.length > noticeLimit) {
          items.removeLast();
        }
      }
      notices = (count: page.count + 1, items: items);
    }
    _notifySoon();
  }

  void _syncDashboardTotal() {
    final current = target;
    if (current == null || !current.signedIn || current.grafana == false) {
      if (_dashboardKey == null) return;
      _dashboardKey = null;
      _dashboardTicket++;
      final dirty = dashboardTotal != null;
      dashboardTotal = null;
      if (dirty) notifyListeners();
      return;
    }
    final key = '${current.url}|${current.token}';
    if (key == _dashboardKey) return;
    _dashboardKey = key;
    dashboardTotal = null;
    final ticket = ++_dashboardTicket;
    unawaited(_loadDashboardTotal(ticket, current));
  }

  Future<void> _loadDashboardTotal(int ticket, InstanceRecord record) async {
    final token = record.token;
    if (token == null || token.isEmpty) return;
    try {
      final page = await api(originOf(record.url))
          .dashboards(token: token, offset: 0, limit: 1);
      if (ticket != _dashboardTicket) return;
      dashboardTotal = page.count;
      notifyListeners();
    } catch (_) {}
  }

  void _shiftDashboardTotal(int by) {
    final total = dashboardTotal;
    if (total == null) return;
    dashboardTotal = total + by < 0 ? 0 : total + by;
    notifyListeners();
  }

  void _syncNoticeStream() {
    _syncDashboardTotal();
    final current = target;
    if (current == null ||
        !current.signedIn ||
        current.notifications == false) {
      if (_noticeKey != null) _stopNoticeStream();
      return;
    }
    final key = '${current.url}|${current.token}';
    if (key == _noticeKey) return;
    _stopNoticeStream();
    _noticeKey = key;
    final ticket = ++_noticeTicket;
    unawaited(_followNotices(ticket, current));
  }

  void _stopNoticeStream() {
    _noticeTicket++;
    _noticeKey = null;
    _noticeClient?.close();
    _noticeClient = null;
    _noticeSeen.clear();
    _noticeRetrySeconds = 3;
    final dirty = unreadCount != 0 || notices != null || noticeTotal != null;
    notices = null;
    unreadCount = 0;
    noticeTotal = null;
    if (dirty) notifyListeners();
  }

  Future<void> _followNotices(int ticket, InstanceRecord record) async {
    final origin = originOf(record.url);
    final token = record.token;
    if (token == null || token.isEmpty) return;
    try {
      final clientApi = api(origin);
      final unread = clientApi.notices(
        token: token,
        offset: 0,
        limit: 1,
        isRead: false,
      );
      final total = clientApi.notices(token: token, offset: 0, limit: 1);
      final pages = await Future.wait([unread, total]);
      if (ticket != _noticeTicket) return;
      unreadCount = pages[0].count;
      noticeTotal = pages[1].count;
      notifyListeners();
    } catch (_) {}
    while (ticket == _noticeTicket) {
      final client = http.Client();
      _noticeClient = client;
      var received = false;
      try {
        await for (final notice in api(origin).watchNotices(token, client)) {
          if (ticket != _noticeTicket) return;
          received = true;
          _takeNotice(notice);
        }
      } on ApiException catch (error) {
        if (error.status >= 400 && error.status < 500) return;
      } catch (_) {
      } finally {
        client.close();
        if (identical(_noticeClient, client)) _noticeClient = null;
      }
      if (ticket != _noticeTicket) return;
      // A dead stream is retried 3, 6, 12 ... 60 seconds apart. A stream
      // that proved alive with at least one notice starts the ladder again.
      await Future<void>.delayed(Duration(seconds: _noticeRetrySeconds));
      _noticeRetrySeconds = received
          ? 3
          : (_noticeRetrySeconds * 2 < 60 ? _noticeRetrySeconds * 2 : 60);
    }
  }

  Future<RegistryRepo> readRepo(String uuid) async {
    final current = _signedTarget();
    final repo = await api(originOf(current.url))
        .readRepo(current.token!, uuid);
    _replaceListedRepo(repo);
    unawaited(ensureIcon(repo.iconUuid));
    return repo;
  }

  Future<RegistryRepo> createRepo({
    required String url,
    required String platform,
    required bool public,
    String? username,
    String? pat,
  }) async {
    final current = _signedTarget();
    final repo = await api(originOf(current.url)).createRepo(
      current.token!,
      url: url,
      platform: platform,
      public: public,
      username: username,
      pat: pat,
    );
    unawaited(ensureIcon(repo.iconUuid));
    return repo;
  }

  Future<void> deleteRepo(String uuid) async {
    final current = _signedTarget();
    await api(originOf(current.url)).deleteRepo(current.token!, uuid);
    final page = registry;
    if (page == null) return;
    registry = (
      count: page.count > 0 ? page.count - 1 : 0,
      repos: [
        for (final item in page.repos)
          if (item.uuid != uuid) item,
      ],
    );
    notifyListeners();
  }

  void _replaceListedRepo(RegistryRepo repo) {
    final page = registry;
    if (page == null) return;
    if (!page.repos.any((item) => item.uuid == repo.uuid)) return;
    registry = (
      count: page.count,
      repos: [
        for (final item in page.repos)
          if (item.uuid == repo.uuid) repo else item,
      ],
    );
    notifyListeners();
  }

  Future<void> updateLocalRepo(String uuid) async {
    final current = _signedTarget();
    await api(originOf(current.url))
        .updateLocalRepository(current.token!, uuid);
  }

  Future<RepoCredentials?> readRepoCredentials(String uuid) async {
    final current = _signedTarget();
    return api(originOf(current.url)).repoCredentials(current.token!, uuid);
  }

  Future<void> saveRepoCredentials(
    String uuid,
    String username,
    String pat,
  ) async {
    final current = _signedTarget();
    await api(originOf(current.url))
        .setRepoCredentials(current.token!, uuid, username, pat);
  }

  PepeunitApi get _api {
    final current = _signedTarget();
    return api(originOf(current.url));
  }

  String get _token => _signedTarget().token!;

  Future<({int count, List<Unit> units})> listUnits({
    required int offset,
    required int limit,
    UnitQuery? query,
    String? creatorUuid,
    String? inputUuid,
    bool includeIos = false,
    List<String>? ioTypes,
  }) {
    final current = query ?? unitQuery;
    final mine = current.owner == 'mine' ? _signedTarget().userUuid : null;
    return _api.units(
      token: _token,
      offset: offset,
      limit: cappedLimit(limit),
      search: current.text,
      order: current.order,
      creatorUuid: creatorUuid ?? mine,
      visibility: current.visibilityFilter,
      auto: current.autoOnly,
      inputUuid: inputUuid,
      includeIos: includeIos,
      ioTypes: ioTypes,
    );
  }

  Future<Unit> readUnit(String uuid) async {
    final unit = await _api.readUnit(_token, uuid);
    unawaited(ensureIcon(unit.iconUuid));
    return unit;
  }

  Future<Unit> createUnit(Map<String, Object?> body) =>
      _api.createUnit(_token, body);

  Future<Unit> updateUnit(String uuid, Map<String, Object?> patch) =>
      _api.updateUnit(_token, uuid, patch);

  Future<void> deleteUnit(String uuid) => _api.deleteUnit(_token, uuid);

  Future<Map<String, Object?>> unitEnv(String uuid) =>
      _api.unitEnv(_token, uuid);

  Future<void> setUnitEnv(String uuid, Map<String, Object?> env) =>
      _api.setUnitEnv(_token, uuid, env);

  Future<void> resetUnitEnv(String uuid) => _api.resetUnitEnv(_token, uuid);

  Future<({int count, List<RepoCommit> commits})> branchCommits(
    String uuid,
    String branch, {
    bool onlyTag = false,
    String search = '',
    int offset = 0,
    int limit = 100,
  }) => _api.branchCommits(
    _token,
    uuid,
    branch: branch,
    onlyTag: onlyTag,
    search: search,
    offset: offset,
    limit: limit,
  );

  Future<List<FirmwarePlatform>> firmwarePlatforms(
    String uuid, {
    String? branch,
    String? commit,
  }) => _api.firmwarePlatforms(_token, uuid, branch: branch, commit: commit);

  Future<String> unitSchema(String uuid) => _api.unitSchema(_token, uuid);

  Future<String> unitStateStorage(String uuid) =>
      _api.unitStateStorage(_token, uuid);

  Future<void> sendUnitCommand(String uuid, String command) =>
      _api.sendUnitCommand(_token, uuid, command);

  Future<void> bulkUpdateUnits() => _api.bulkUpdateUnits(_token);

  Future<({int count, List<UnitLog> logs})> unitLogs({
    required String uuid,
    required int offset,
    required int limit,
    List<String>? levels,
  }) => _api.unitLogs(
    token: _token,
    uuid: uuid,
    offset: offset,
    limit: cappedLimit(limit),
    levels: levels,
  );

  Future<bool> saveBytes(String fileName, Uint8List bytes) =>
      files.save(fileName: fileName, bytes: bytes);

  Future<Uint8List> downloadFile(Uri uri) async {
    final response = await _apiClient.get(uri);
    if (response.statusCode != 200) {
      throw http.ClientException(
        'Download failed: ${response.statusCode}',
        uri,
      );
    }
    return response.bodyBytes;
  }

  Future<Uint8List> unitFirmware(String uuid, String kind) =>
      _api.unitFirmware(_token, uuid, kind);

  Future<String> readmeFromToml(Uint8List toml) =>
      _api.convertTomlToMd(_token, toml);

  Future<Uint8List> downloadUnitLogs(String uuid) =>
      _api.downloadUnitLogs(_token, uuid);

  Future<({int count, List<UnitGroup> groups})> listGroups({
    required int offset,
    required int limit,
    String search = '',
    String order = 'asc',
  }) => _api.groups(
    token: _token,
    offset: offset,
    limit: cappedLimit(limit),
    search: search,
    order: order,
  );

  Future<UnitGroup> readGroup(String uuid) async {
    final group = await _api.readGroup(_token, uuid);
    unawaited(ensureIcon(group.iconUuid));
    return group;
  }

  Future<UnitGroup> createGroup(String name) => _api.createGroup(_token, name);

  Future<UnitGroup> renameGroup(String uuid, String name) =>
      _api.renameGroup(_token, uuid, name);

  Future<void> deleteGroup(String uuid) => _api.deleteGroup(_token, uuid);

  Future<({int count, List<Unit> units})> groupUnits({
    required String uuid,
    required int offset,
    required int limit,
  }) => _api.groupUnits(
    token: _token,
    uuid: uuid,
    offset: offset,
    limit: cappedLimit(limit),
  );

  Future<void> linkGroupUnit(String uuid, String unitUuid) =>
      _api.linkGroupUnit(_token, uuid, unitUuid);

  Future<void> unlinkGroupUnit(String uuid, String unitUuid) =>
      _api.unlinkGroupUnit(_token, uuid, unitUuid);

  Future<({int count, List<Dashboard> dashboards})> listDashboards({
    required int offset,
    required int limit,
    String search = '',
    String order = 'desc',
  }) async {
    final page = await _api.dashboards(
      token: _token,
      offset: offset,
      limit: cappedLimit(limit),
      search: search,
      order: order,
    );
    if (search.isEmpty && page.count != dashboardTotal) {
      dashboardTotal = page.count;
      notifyListeners();
    }
    return page;
  }

  Future<Dashboard> readDashboard(String uuid) =>
      _api.readDashboard(_token, uuid);

  Future<Dashboard> createDashboard(String name) async {
    final dashboard = await _api.createDashboard(_token, name);
    _shiftDashboardTotal(1);
    return dashboard;
  }

  Future<Dashboard> syncDashboard(String uuid) =>
      _api.syncDashboard(_token, uuid);

  Future<void> deleteDashboard(String uuid) async {
    await _api.deleteDashboard(_token, uuid);
    _shiftDashboardTotal(-1);
  }

  Future<List<DashboardPanel>> dashboardPanels(String uuid) =>
      _api.dashboardPanels(_token, uuid);

  Future<DashboardPanel> createPanel({
    required String dashboardUuid,
    required String title,
    required String type,
  }) => _api.createPanel(
    _token,
    dashboardUuid: dashboardUuid,
    title: title,
    type: type,
  );

  Future<void> deletePanel(String uuid) => _api.deletePanel(_token, uuid);

  Future<PanelLink> linkPanelIo({
    required String panelUuid,
    required String ioUuid,
    required bool lastOnly,
    required bool asJson,
  }) => _api.linkPanelIo(
    _token,
    panelUuid: panelUuid,
    ioUuid: ioUuid,
    lastOnly: lastOnly,
    asJson: asJson,
  );

  Future<void> deletePanelLink({
    required String panelUuid,
    required String ioUuid,
  }) => _api.deletePanelLink(_token, panelUuid: panelUuid, ioUuid: ioUuid);

  /// A one-time browser link that signs into Grafana and opens the dashboard
  /// in the signed-in user's own organization. Ask for it right before the
  /// launch: the backend keeps the ticket for a minute.
  Future<Uri> dashboardUri(Dashboard dashboard) async {
    final current = _signedTarget();
    final user = current.userUuid;
    final orgId = user == null || user.isEmpty
        ? null
        : await _api.grafanaOrgId(current.token!, user);
    final target = dashboardLink(
      originOf(current.url),
      dashboard.url ?? '',
      orgId: orgId,
    );
    return _api.grafanaLink(
      current.token!,
      path: target.hasQuery ? '${target.path}?${target.query}' : target.path,
    );
  }

  /// Direction of every IO seen so far, so a child screen takes its color
  /// before its own request returns.
  final _ioInputs = <String, bool>{};

  bool? ioIsInput(String uuid) => _ioInputs[uuid];

  void _noteIo(UnitIo io) => _ioInputs[io.uuid] = io.input;

  Future<({int count, List<UnitIo> ios})> listIos({
    required int offset,
    required int limit,
    String? unitUuid,
    List<String>? types,
  }) async {
    final page = await _api.unitIos(
      token: _token,
      offset: offset,
      limit: cappedLimit(limit),
      unitUuid: unitUuid,
      types: types,
    );
    page.ios.forEach(_noteIo);
    return page;
  }

  Future<UnitIo> readUnitIo(String uuid) async {
    final io = await _api.readUnitIo(_token, uuid);
    _noteIo(io);
    return io;
  }

  Future<UnitIo> updateUnitIo(String uuid, Map<String, Object?> patch) async {
    final io = await _api.updateUnitIo(_token, uuid, patch);
    _noteIo(io);
    return io;
  }

  Future<UnitIo> setInputState(String uuid, String state) =>
      _api.setInputState(_token, uuid, state);

  Completer<Object?>? _pick;

  /// True while a screen waits for the person to choose something.
  bool get pickOpen => _pick != null;

  /// Starts a choice made on screens that the opener cannot await. The answer
  /// does not travel back through the route result: those screens replace
  /// their own route when the scale changes, and a replaced route never
  /// delivers it. A pick left open is closed with null when the next one
  /// starts. Openers go through `openPick` in `navigation/pick.dart`.
  Future<T?> beginPick<T extends Object>({List<PickItem>? items}) {
    _pick?.complete(null);
    final pick = Completer<Object?>();
    _pick = pick;
    pickItems = items;
    return pick.future.then((value) => value is T ? value : null);
  }

  /// Rows the opener already holds for the open pick, so a name picker shows
  /// them without asking the backend again. Null when the picker must ask.
  List<PickItem>? pickItems;

  /// Hands the choice to the screen that began the pick.
  void finishPick(Object? value) {
    final pick = _pick;
    _pick = null;
    pickItems = null;
    if (pick != null && !pick.isCompleted) pick.complete(value);
  }

  Future<void> createIoLink({
    required String outputUuid,
    required String inputUuid,
  }) => _api.createIoLink(_token, outputUuid: outputUuid, inputUuid: inputUuid);

  Future<void> deleteIoLink({
    required String outputUuid,
    required String inputUuid,
  }) => _api.deleteIoLink(_token, outputUuid: outputUuid, inputUuid: inputUuid);

  Future<List<PipeIssue>> checkPipe(Uint8List yml) =>
      _api.checkPipe(_token, yml);

  Future<void> setPipe(String uuid, Uint8List yml) =>
      _api.setPipe(_token, uuid, yml);

  Future<Uint8List> pipeConfig(String uuid) => _api.pipeConfig(_token, uuid);

  Future<({int count, List<PipeRow> rows})> pipeData({
    required String uuid,
    required String type,
    required int offset,
    required int limit,
  }) => _api.pipeData(
    token: _token,
    uuid: uuid,
    type: type,
    offset: offset,
    limit: cappedLimit(limit),
  );

  Future<Uint8List> pipeCsv(String uuid) => _api.pipeCsv(_token, uuid);

  Future<void> uploadPipeCsv(String uuid, Uint8List csv) =>
      _api.uploadPipeCsv(_token, uuid, csv);

  Future<void> deletePipeData(String uuid) => _api.deletePipeData(_token, uuid);

  Future<({int count, List<AccessGrant> grants})> accessGrants({
    required String resourceUuid,
    required String resourceType,
    required int offset,
    required int limit,
  }) => _api.accessGrants(
    token: _token,
    resourceUuid: resourceUuid,
    resourceType: resourceType,
    offset: offset,
    limit: cappedLimit(limit),
  );

  Future<AccessGrant> createAccess({
    required String agentUuid,
    required String agentType,
    required String resourceUuid,
    required String resourceType,
  }) => _api.createAccess(
    _token,
    agentUuid: agentUuid,
    agentType: agentType,
    resourceUuid: resourceUuid,
    resourceType: resourceType,
  );

  Future<void> deleteAccess(AccessGrant grant) => _api.deleteAccess(
    _token,
    uuid: grant.uuid,
    agentUuid: grant.agentUuid,
    resourceUuid: grant.resourceUuid,
  );

  Future<void> uploadEntityIcon(
    String entityUuid,
    String entityType,
    Uint8List png,
  ) async {
    final current = _signedTarget();
    final uuid = await api(originOf(current.url))
        .uploadEntityIcon(current.token!, entityUuid, entityType, png);
    if (uuid != null && uuid.isNotEmpty) {
      await _icons.remember(IconStore.keyOf(originOf(current.url), uuid), png);
      _notifySoon();
    }
  }

  /// Admin and Owner. Schedules an update of every repository.
  Future<void> updateAllRepos() async {
    final current = _staffTarget();
    await api(originOf(current.url)).updateAllRepos(current.token!);
  }

  Future<DirectoryUser> readMember(String uuid) async {
    final current = _signedTarget();
    final user = await api(originOf(current.url))
        .readDirectoryUser(current.token!, uuid);
    unawaited(ensureIcon(user.iconUuid));
    return user;
  }

  Future<DirectoryUser> grantMember(String uuid) {
    return _changeMember(
      uuid,
      (client, token) => client.grantAdmin(token, uuid),
      owner: true,
    );
  }

  Future<DirectoryUser> revokeMember(String uuid) {
    return _changeMember(
      uuid,
      (client, token) => client.revokeAdmin(token, uuid),
      owner: true,
    );
  }

  Future<DirectoryUser> blockMember(String uuid) {
    return _changeMember(
      uuid,
      (client, token) => client.blockUser(token, uuid),
    );
  }

  Future<DirectoryUser> unblockMember(String uuid) {
    return _changeMember(
      uuid,
      (client, token) => client.unblockUser(token, uuid),
    );
  }

  /// Loads every icon the current instance still lacks, through [IconStore].
  Future<void> ensureIcons(Iterable<String?> uuids) {
    final current = target;
    if (current == null) return Future<void>.value();
    return _fillIcons(url: current.url, uuids: uuids, active: () => !_disposed);
  }

  Future<void> ensureIcon(String? uuid) => ensureIcons([uuid]);

  Future<void> selectTarget(String raw) async {
    final url = canonicalInstanceUrl(raw);
    targetSettings = null;
    _activate(url);
    await _commit();
    await refreshTarget();
  }

  Future<void> clearTarget() async {
    _ticket++;
    for (final instance in vault.instances) {
      instance.active = false;
    }
    targetSettings = null;
    networkFailure = null;
    networkBusy = false;
    _syncNoticeStream();
    await _commit();
  }

  Future<void> allowInstance(String raw) async {
    final url = canonicalInstanceUrl(raw);
    vault.deny.remove(url);
    if (!vault.allow.contains(url)) vault.allow.add(url);
    await _commit();
  }

  Future<void> denyInstance(String raw) async {
    final url = canonicalInstanceUrl(raw);
    vault.allow.remove(url);
    if (!vault.deny.contains(url)) vault.deny.add(url);
    await _commit();
  }

  Future<void> forgetList(String raw, {required bool deny}) async {
    final url = canonicalInstanceUrl(raw);
    (deny ? vault.deny : vault.allow).remove(url);
    await _commit();
  }

  Future<void> refreshTarget() async {
    final current = vault.target;
    if (current == null) return;
    final ticket = ++_ticket;
    networkBusy = true;
    networkFailure = null;
    notifyListeners();
    try {
      final client = api(originOf(current.url));
      final portrait = await client.portrait();
      if (ticket != _ticket) return;
      final effective = targetSettings == null
          ? portrait
          : portrait.applySettings(targetSettings!);
      portraits[current.url] = effective;
      _applyFlags(current, effective);
      await _ensureTargetSession(current, client);
      if (ticket != _ticket) return;
      await _commit();
      final limit = effective.pagination < 1 ? 100 : effective.pagination;
      final pageLimit = cappedLimit(limit);
      // The url list and the peer rows do not depend on each other.
      final urlsFuture = collectPages(
        limit: pageLimit,
        fetch: (offset, size) => client.peerUrls(offset: offset, limit: size),
      );
      final headsFuture = collectPages(
        limit: pageLimit,
        fetch: (offset, size) => client.peers(offset: offset, limit: size),
      );
      final List<String> urls;
      final List<PeerHead> heads;
      try {
        urls = await urlsFuture;
        heads = await headsFuture;
      } catch (_) {
        unawaited(urlsFuture.then((_) {}, onError: (_) {}));
        unawaited(headsFuture.then((_) {}, onError: (_) {}));
        rethrow;
      }
      if (ticket != _ticket) return;
      peers.clear();
      for (final head in heads) {
        final canonical = _keepUrl(head.url);
        if (canonical.isEmpty) continue;
        peers[canonical] = PeerHead(
          uuid: head.uuid,
          url: canonical,
          trust: head.trust,
          lastPing: head.lastPing,
          collectionStatus: head.collectionStatus,
          collectionError: head.collectionError,
          consecutiveSuccessCount: head.consecutiveSuccessCount,
          lastSuccessDatetime: head.lastSuccessDatetime,
          lastAttemptDatetime: head.lastAttemptDatetime,
          portrait: head.portrait,
        );
        if (head.portrait != null) {
          portraits[canonical] ??= head.portrait!;
        }
      }
      discovered
        ..clear()
        ..addAll(urls.map(_keepUrl))
        ..addAll(peers.keys)
        ..remove('');
      for (final url in {...discovered, current.url}) {
        _ensureRecord(url);
      }
      await _commit();
      await _loadPortraits(
        ticket,
        {...discovered, current.url}.where((url) => url != current.url),
      );
    } catch (error) {
      if (ticket != _ticket) return;
      networkFailure = '$error';
    } finally {
      if (ticket == _ticket) {
        networkBusy = false;
        _syncNoticeStream();
        notifyListeners();
      }
    }
  }

  /// Pushes the avatar, login, and notification prefs to the favorite instance.
  ///
  /// The avatar is sent when one is stored. A minute must pass before the
  /// next send, counting from the moment this starts.
  Future<SyncReport> broadcast() async {
    if (!vault.hasKey) return const SyncReport(0, ['no-key']);
    final current = vault.target;
    if (current == null || profileCooldownLeft != Duration.zero) {
      return const SyncReport(0, []);
    }
    vault.profileSentAt = DateTime.now().millisecondsSinceEpoch;
    await _commit();
    final url = current.url;
    final host = instanceHost(url);
    try {
      final identity = Identity.fromParts(vault.publicKey!, vault.secretKey!);
      final record = _ensureRecord(url);
      final client = api(originOf(url));
      await _open(record, client, identity);
      final token = record.token!;
      final userUuid = record.userUuid!;
      final png = iconBytes(vault.iconPng);
      final problems = <String>[];
      Future<void> run(Future<void> job) async {
        try {
          await job;
        } catch (error) {
          problems.add('$host: $error');
        }
      }

      await Future.wait([
        if (png != null) run(client.uploadIcon(token, userUuid, png)),
        run(client.updateLogin(token, userUuid, vault.login)),
        run(client.updateNotificationSettings(token, vault.alerts.toPatch())),
      ]);
      await _commit();
      return SyncReport(problems.isEmpty ? 1 : 0, problems);
    } catch (error) {
      return SyncReport(0, ['$host: $error']);
    }
  }

  /// Copies the avatar, login, and notification prefs from the favorite
  /// instance onto this device.
  Future<SyncReport> recall() async {
    if (!vault.hasKey) return const SyncReport(0, ['no-key']);
    final current = vault.target;
    if (current == null) return const SyncReport(0, []);
    final url = current.url;
    final host = instanceHost(url);
    try {
      final identity = Identity.fromParts(vault.publicKey!, vault.secretKey!);
      final record = _ensureRecord(url);
      final client = api(originOf(url));
      await _open(record, client, identity);
      final token = record.token!;
      final user = await client.readDirectoryUser(token, record.userUuid!);
      final problems = <String>[];
      Uint8List? png;
      AlertPrefs? alerts;
      final iconUuid = user.iconUuid;
      Future<void> pullIcon() async {
        if (iconUuid == null) return;
        try {
          final bytes = await _icons.load(
            origin: originOf(url),
            uuid: iconUuid,
            fetch: () => client.icon(iconUuid),
          );
          if (pngSize(bytes) != null) png = bytes;
        } catch (error) {
          problems.add('$host: $error');
        }
      }

      Future<void> pullAlerts() async {
        try {
          alerts = AlertPrefs.fromPatch(
            await client.notificationSettings(token),
          );
        } catch (error) {
          problems.add('$host: $error');
        }
      }

      await Future.wait([pullIcon(), pullAlerts()]);
      final savedPng = png;
      final savedAlerts = alerts;
      vault.login = user.login ?? '';
      if (savedPng != null) vault.iconPng = base64.encode(savedPng);
      if (savedAlerts != null) vault.alerts = savedAlerts;
      await _commit();
      return SyncReport(problems.isEmpty ? 1 : 0, problems);
    } catch (error) {
      return SyncReport(0, ['$host: $error']);
    }
  }

  /// Asks the instance for a fresh JWT with the same key login.
  ///
  /// A successful call waits a minute. The instance cell stays inactive.
  Future<void> resign(String raw) async {
    if (!vault.hasKey) throw StateError('key');
    final url = canonicalInstanceUrl(raw);
    if (resignCooldownLeft(url) != Duration.zero) return;
    final record = _ensureRecord(url);
    final identity = Identity.fromParts(vault.publicKey!, vault.secretKey!);
    await _open(record, api(originOf(url)), identity);
    resignAt[url] = DateTime.now().millisecondsSinceEpoch;
    _syncNoticeStream();
    await _commit();
  }

  /// Remembers an instance on this client after reading its public portrait.
  ///
  /// Does not create a peer, whatever the role is.
  Future<void> rememberInstance(String raw) async {
    final url = canonicalInstanceUrl(raw);
    final client = api(originOf(url));
    final portrait = await client.portrait();
    portraits[url] = portrait;
    final uuid = portrait.iconUuid;
    if (uuid != null && uuid.isNotEmpty) {
      try {
        await _icons.load(
          origin: originOf(url),
          uuid: uuid,
          fetch: () => client.icon(uuid),
        );
      } catch (_) {}
    }
    if (!vault.pinned.contains(url)) vault.pinned.add(url);
    _ensureRecord(url);
    await _commit();
  }

  Future<void> createPeer(String raw) async {
    final current = _staffTarget();
    final url = canonicalInstanceUrl(raw);
    await api(originOf(current.url)).createPeer(current.token!, url);
    await refreshTarget();
  }

  /// Owner asks the current instance to start tracking [raw] as a peer.
  Future<void> trackInstance(String raw) async {
    _ownerTarget();
    await createPeer(raw);
  }

  Future<void> setTrust(String url, String trust) async {
    final current = _staffTarget();
    final head = peers[url];
    if (head == null) {
      throw StateError('peer');
    }
    await api(originOf(current.url))
        .updatePeer(current.token!, head.uuid, trust);
    await refreshTarget();
  }

  Future<void> deletePeer(String url) async {
    final current = _staffTarget();
    final head = peers[url];
    if (head == null) throw StateError('peer');
    await api(originOf(current.url)).deletePeer(current.token!, head.uuid);
    await refreshTarget();
  }

  Future<void> scanPeer(String url) async {
    final current = _staffTarget();
    final head = peers[url];
    if (head == null) throw StateError('peer');
    await api(originOf(current.url)).scanPeer(current.token!, head.uuid);
    await refreshTarget();
  }

  Future<void> scanAll() async {
    final current = _staffTarget();
    await api(originOf(current.url)).scanAll(current.token!);
  }

  Future<void> loadSettings() async {
    final current = _ownerTarget();
    targetSettings = await api(originOf(current.url)).settings(current.token!);
    final existing = portraits[current.url];
    if (existing != null && targetSettings != null) {
      final updated = existing.applySettings(targetSettings!);
      portraits[current.url] = updated;
      _applyFlags(current, updated);
    }
    notifyListeners();
  }

  Future<void> patchSettings(Map<String, Object?> patch) async {
    final current = _ownerTarget();
    targetSettings = await api(originOf(current.url))
        .patchSettings(current.token!, patch);
    final existing = portraits[current.url];
    if (existing != null && targetSettings != null) {
      final updated = existing.applySettings(targetSettings!);
      portraits[current.url] = updated;
      _applyFlags(current, updated);
    }
    await _commit();
    await refreshTarget();
  }

  Future<void> reboot() async {
    final current = _ownerTarget();
    await api(originOf(current.url)).reboot(current.token!);
  }

  /// Backend allows Admin and Owner (`[UserRole.ADMIN]`) to start integration tests.
  Future<void> runIntegrationTests() async {
    final current = _staffTarget();
    await api(originOf(current.url)).integrationTests(current.token!);
  }

  Future<void> setInstanceIcon(Uint8List png) async {
    final current = _ownerTarget();
    final newUuid = await api(originOf(current.url))
        .uploadInstanceIcon(current.token!, png);
    final uuid = newUuid ?? portraits[current.url]?.iconUuid;
    if (uuid != null && uuid.isNotEmpty) {
      await _icons.remember(IconStore.keyOf(originOf(current.url), uuid), png);
      final existing = portraits[current.url];
      if (existing != null) {
        portraits[current.url] = existing.copyWith(iconUuid: uuid);
      }
      if (targetSettings != null) {
        targetSettings = {...targetSettings!, 'icon_uuid': uuid};
      }
    }
    notifyListeners();
    await refreshTarget();
  }

  Future<String> verificationLink(String url) async {
    if (!vault.hasKey) throw StateError('key');
    final record = _ensureRecord(url);
    final client = api(originOf(url));
    final identity = Identity.fromParts(vault.publicKey!, vault.secretKey!);
    await _open(record, client, identity);
    await _commit();
    return client.verificationLink(record.token!);
  }

  Future<void> openExternal(Uri uri) => (openLink ?? launchExternal)(uri);

  Future<DirectoryUser> _changeMember(
    String uuid,
    Future<DirectoryUser> Function(PepeunitApi client, String token) change, {
    bool owner = false,
  }) async {
    final current = owner ? _ownerTarget() : _staffTarget();
    final user = await change(api(originOf(current.url)), current.token!);
    try {
      if (directory != null) {
        await loadDirectory(offset: directoryOffset, limit: directoryLimit);
      }
    } catch (_) {}
    unawaited(ensureIcon(user.iconUuid));
    return user;
  }

  Future<void> _loadMemberIcons(
    int ticket,
    String url,
    List<DirectoryUser> users,
  ) {
    return _fillIcons(
      url: url,
      uuids: [for (final user in users) user.iconUuid],
      active: () => ticket == _directoryTicket,
    );
  }

  Future<void> _loadRepoIcons(
    int ticket,
    String url,
    List<RegistryRepo> repos,
  ) {
    return _fillIcons(
      url: url,
      uuids: [for (final repo in repos) repo.iconUuid],
      active: () => ticket == _registryTicket,
    );
  }

  /// Fetches the icons a page still lacks, four requests in flight, and
  /// notifies once for the batch instead of once per icon.
  Future<void> _fillIcons({
    required String url,
    required Iterable<String?> uuids,
    required bool Function() active,
  }) {
    final origin = originOf(url);
    return _fillIconJobs([
      for (final uuid in uuids)
        if (uuid != null && uuid.isNotEmpty) (origin, uuid),
    ], active);
  }

  Future<void> _fillIconJobs(
    List<(String origin, String uuid)> jobs,
    bool Function() active,
  ) async {
    final missing = <(String origin, String uuid)>[];
    final wanted = <String>{};
    for (final job in jobs) {
      final key = IconStore.keyOf(job.$1, job.$2);
      if (!wanted.add(key)) continue;
      if (_icons.peek(key) != null) continue;
      missing.add(job);
    }
    if (missing.isEmpty) return;
    var filled = false;
    await _lanes(missing.length, (index) async {
      if (!active()) return false;
      final job = missing[index];
      try {
        await _icons.load(
          origin: job.$1,
          uuid: job.$2,
          fetch: () => api(job.$1).icon(job.$2),
        );
        if (!active()) return false;
        filled = true;
      } catch (_) {}
      return true;
    });
    if (filled && active()) _notifySoon();
  }

  /// [width] requests at a time. A step that returns false stops that lane.
  Future<void> _lanes(
    int count,
    Future<bool> Function(int index) step, {
    int width = 4,
  }) async {
    if (count <= 0) return;
    var index = 0;
    final lanes = count < width ? count : width;
    await Future.wait<void>([
      for (var lane = 0; lane < lanes; lane++)
        () async {
          while (index < count) {
            final current = index++;
            if (!await step(current)) return;
          }
        }(),
    ]);
  }

  InstanceRecord _signedTarget() {
    final current = vault.target;
    if (current == null || !current.signedIn) {
      throw StateError('role');
    }
    return current;
  }

  InstanceRecord _staffTarget() {
    final current = vault.target;
    if (current == null || !current.signedIn || !current.managesPeers) {
      throw StateError('role');
    }
    return current;
  }

  InstanceRecord _ownerTarget() {
    final current = vault.target;
    if (current == null || !current.signedIn || !current.ownsInstance) {
      throw StateError('role');
    }
    return current;
  }

  String? _canonicalOrNull(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      return canonicalInstanceUrl(raw);
    } catch (_) {
      return null;
    }
  }

  bool _loopback(String url) {
    final host = Uri.parse(url).host.toLowerCase();
    return host == 'localhost' || host == '127.0.0.1' || host == '::1';
  }

  void _activate(String url) {
    var found = false;
    for (final instance in vault.instances) {
      instance.active = instance.url == url;
      if (instance.active) found = true;
    }
    if (!found) {
      vault.instances.add(InstanceRecord(url: url, active: true));
    }
  }

  InstanceRecord _ensureRecord(String url) {
    final existing = vault.recordFor(url);
    if (existing != null) return existing;
    final created = InstanceRecord(url: url);
    vault.instances.add(created);
    return created;
  }

  Future<void> _ensureTargetSession(
    InstanceRecord record,
    PepeunitApi client,
  ) async {
    if (!vault.hasKey) return;
    if (record.signedIn && record.userUuid != null) {
      try {
        final user = await client.user(record.token!, record.userUuid!);
        record.role = user.role;
        return;
      } on ApiException catch (error) {
        if (error.status != 401 && error.status != 403) rethrow;
        record.token = null;
        record.role = null;
      }
    }
    final identity = Identity.fromParts(vault.publicKey!, vault.secretKey!);
    await _open(record, client, identity);
  }

  Future<void> _open(
    InstanceRecord record,
    PepeunitApi client,
    Identity identity,
  ) async {
    final session = await openSession(client, identity);
    record.token = session.token;
    record.userUuid = session.uuid;
    record.role = session.role;
  }

  void _applyFlags(InstanceRecord record, InstancePortrait portrait) {
    record.notifications = portrait.notifications;
    record.grafana = portrait.grafana;
    record.telegram = portrait.telegram;
  }

  Future<void> _loadPortraits(int ticket, Iterable<String> urls) async {
    final pending = urls.toList();
    final jobs = <(String origin, String uuid)>[];
    void take(String url, String? uuid) {
      if (uuid == null || uuid.isEmpty) return;
      jobs.add((originOf(url), uuid));
    }

    await _lanes(pending.length, (index) async {
      if (ticket != _ticket) return false;
      final url = pending[index];
      try {
        final portrait = await api(originOf(url)).portrait();
        if (ticket != _ticket) return false;
        portraits[url] = portrait;
        take(url, portrait.iconUuid);
        _notifySoon();
      } catch (_) {
        take(url, portraits[url]?.iconUuid);
      }
      return true;
    });
    if (ticket != _ticket) return;
    final targetUrl = vault.target?.url;
    if (targetUrl != null) take(targetUrl, portraits[targetUrl]?.iconUuid);
    await _fillIconJobs(jobs, () => ticket == _ticket);
  }

  String _keepUrl(String raw) {
    try {
      return canonicalInstanceUrl(raw);
    } catch (_) {
      return '';
    }
  }

  Future<void> _commit() {
    notifyListeners();
    final snapshot = vault.copy();
    _pending = _pending.then((_) => store.write(snapshot));
    return _pending;
  }
}

Duration _windowLeft(int? stamp, Duration window) {
  if (stamp == null) return Duration.zero;
  final elapsed = DateTime.now().millisecondsSinceEpoch - stamp;
  final width = window.inMilliseconds;
  if (elapsed < 0 || elapsed >= width) return Duration.zero;
  return Duration(milliseconds: width - elapsed);
}
