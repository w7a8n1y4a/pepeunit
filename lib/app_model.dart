import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'account/alerts.dart';
import 'account/icon_file.dart';
import 'account/identity.dart';
import 'account/key_file_port.dart';
import 'account/vault.dart';
import 'account/vault_store.dart';
import 'api/pepeunit_api.dart';
import 'instances/hosted_url.dart';
import 'instances/instance.dart';
import 'instances/link.dart';
import 'instances/network_view.dart';
import 'instances/portrait.dart';
import 'instances/session.dart';
import 'locale/languages.dart';

class SyncReport {
  const SyncReport(this.reached, this.problems);

  final int reached;
  final List<String> problems;

  bool get empty => reached == 0 && problems.isEmpty;
}

class AppModel extends ChangeNotifier {
  AppModel({
    required this.store,
    KeyFilePort? files,
    PepeunitApi Function(String origin)? api,
    Future<String?> Function()? hostedUrl,
    this.openLink,
  }) : files = files ?? PlatformKeyFilePort(),
       api = api ?? PepeunitApi.new,
       hostedUrl = hostedUrl ?? readHostedInstanceUrl;

  final VaultStore store;
  final KeyFilePort files;
  final PepeunitApi Function(String origin) api;
  final Future<String?> Function() hostedUrl;
  final Future<void> Function(Uri uri)? openLink;

  Vault vault = Vault.fresh();
  bool ready = false;
  bool networkBusy = false;
  String? networkFailure;
  final NetworkQuery query = NetworkQuery();
  final Set<String> discovered = {};
  final Map<String, PeerHead> peers = {};
  final Map<String, InstancePortrait> portraits = {};
  final Map<String, Uint8List> icons = {};
  Map<String, Object?>? targetSettings;
  Future<void> _pending = Future<void>.value();
  var _ticket = 0;

  InstanceRecord? get target => vault.target;

  static const profileCooldown = Duration(minutes: 1);

  /// Time left before the profile can be sent again.
  Duration get profileCooldownLeft {
    final sent = vault.profileSentAt;
    if (sent == null) return Duration.zero;
    final elapsed = DateTime.now().millisecondsSinceEpoch - sent;
    final window = profileCooldown.inMilliseconds;
    if (elapsed < 0 || elapsed >= window) return Duration.zero;
    return Duration(milliseconds: window - elapsed);
  }

  bool get canSendProfile =>
      vault.target != null && profileCooldownLeft == Duration.zero;

  InstancePortrait? portraitOf(String url) =>
      portraits[url] ?? peers[url]?.portrait;

  Uint8List? iconOf(String url) {
    final uuid = portraitOf(url)?.iconUuid;
    if (uuid == null) return null;
    return icons['${originOf(url)}/$uuid'];
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

  Future<void> load({String? hostedUrl}) async {
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
      await refreshTarget();
    } else {
      notifyListeners();
    }
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
      final urls = await collectPages(
        limit: limit,
        fetch: (offset, pageLimit) =>
            client.peerUrls(offset: offset, limit: pageLimit),
      );
      final heads = await collectPages(
        limit: limit,
        fetch: (offset, pageLimit) =>
            client.peers(offset: offset, limit: pageLimit),
      );
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

  /// Asks the instance for a fresh JWT with the same key login.
  Future<void> resign(String raw) async {
    if (!vault.hasKey) throw StateError('key');
    final url = canonicalInstanceUrl(raw);
    final record = _ensureRecord(url);
    final identity = Identity.fromParts(vault.publicKey!, vault.secretKey!);
    await _open(record, api(originOf(url)), identity);
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
    if (uuid != null) {
      try {
        icons['${originOf(url)}/$uuid'] ??= await client.icon(uuid);
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

  Future<void> patchSetting(String key, Object? value) {
    return patchSettings({key: value});
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
      icons['${originOf(current.url)}/$uuid'] = png;
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
    var index = 0;
    Future<void> worker() async {
      while (index < pending.length) {
        if (ticket != _ticket) return;
        final url = pending[index++];
        try {
          final portrait = await api(originOf(url)).portrait();
          if (ticket != _ticket) return;
          portraits[url] = portrait;
          final uuid = portrait.iconUuid;
          if (uuid != null) {
            final key = '${originOf(url)}/$uuid';
            icons[key] ??= await api(originOf(url)).icon(uuid);
          }
          notifyListeners();
        } catch (_) {
          final cachedUuid = portraits[url]?.iconUuid;
          if (cachedUuid != null) {
            final key = '${originOf(url)}/$cachedUuid';
            try {
              icons[key] ??= await api(originOf(url)).icon(cachedUuid);
              notifyListeners();
            } catch (_) {}
          }
        }
      }
    }

    final count = pending.length < 4 ? pending.length : 4;
    await Future.wait([for (var i = 0; i < count; i++) worker()]);
    final targetUrl = vault.target?.url;
    final targetUuid = targetUrl == null
        ? null
        : portraits[targetUrl]?.iconUuid;
    if (targetUrl != null && targetUuid != null) {
      final key = '${originOf(targetUrl)}/$targetUuid';
      try {
        icons[key] ??= await api(originOf(targetUrl)).icon(targetUuid);
      } catch (_) {}
    }
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
