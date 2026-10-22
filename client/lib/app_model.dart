import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'account/identity.dart';
import 'account/vault.dart';
import 'account/vault_store.dart';
import 'api/pepeunit_api.dart';
import 'instances/instance.dart';

class AppModel extends ChangeNotifier {
  AppModel({required this.store, PepeunitApi Function(String origin)? api}) : _api = api ?? PepeunitApi.new;

  final VaultStore store;
  final PepeunitApi Function(String origin) _api;

  Vault vault = Vault.fresh();
  bool ready = false;
  bool busy = false;
  String notice = '';

  Future<void> load() async {
    vault = await store.read();
    ready = true;
    notifyListeners();
  }

  Future<void> createAccount() async {
    if (vault.hasKey || busy) return;
    await _run(() async {
      final (publicKey, secretKey) = await compute(generateMlDsa87KeyPair, 0);
      vault.publicKey = base64Encode(publicKey);
      vault.secretKey = base64Encode(secretKey);
      notice = vault.language == 'en' ? 'Account created on this device' : 'Аккаунт создан на этом устройстве';
    });
  }

  Future<void> saveProfile({required String login, required String language, required String timeZone}) async {
    vault.login = login.trim();
    vault.language = language == 'en' ? 'en' : 'ru';
    vault.timeZone = timeZone.trim().isEmpty ? 'UTC' : timeZone.trim();
    notice = vault.language == 'en' ? 'Saved on this device' : 'Сохранено на этом устройстве';
    await store.write(vault);
    notifyListeners();
  }

  Future<void> setIcon(Uint8List png) async {
    if (png.length < 8 || png[0] != 0x89 || png[1] != 0x50 || png[2] != 0x4e || png[3] != 0x47) {
      notice = vault.language == 'en' ? 'Icon must be a PNG' : 'Картинка должна быть PNG';
      notifyListeners();
      return;
    }
    if (png.length > 128 * 1024) {
      notice = vault.language == 'en' ? 'Icon is larger than 128 KB' : 'Картинка больше 128 КБ';
      notifyListeners();
      return;
    }
    vault.iconPng = base64Encode(png);
    notice = vault.language == 'en' ? 'Icon saved on this device' : 'Картинка сохранена на этом устройстве';
    await store.write(vault);
    notifyListeners();
  }

  Future<void> addInstance(String raw) async {
    await _run(() async {
      final url = normalizeInstanceUrl(raw);
      final existing = vault.instances.where((item) => item.url == url);
      if (existing.isEmpty) {
        vault.instances.add(InstanceRecord(url: url));
      }
      _activate(url);
      notice = url;
    });
  }

  Future<void> selectInstance(String url) async {
    _activate(url);
    notice = url;
    await store.write(vault);
    notifyListeners();
  }

  Future<void> signInActive() async {
    final instance = vault.active;
    if (instance == null) {
      notice = _text('Добавьте инстанс', 'Add an instance');
      notifyListeners();
      return;
    }
    if (!vault.hasKey) {
      notice = _text('Сначала создайте аккаунт', 'Create an account first');
      notifyListeners();
      return;
    }
    await _run(() async {
      final identity = Identity.fromParts(vault.publicKey!, vault.secretKey!);
      final api = _api(instance.url);
      await api.currentVersion();
      String challenge;
      try {
        challenge = await api.challenge(identity.hashPublicKey);
      } on ApiException catch (error) {
        if (!error.missingUser) rethrow;
        await api.register(identity.publicKeyBase64);
        challenge = await api.challenge(identity.hashPublicKey);
      }
      final token = await api.auth(challenge, base64Encode(identity.signChallenge(challenge)));
      instance.token = token;
      instance.userUuid = jwtUuid(token);
      notice = _text('Вход выполнен: ${instance.url}', 'Signed in: ${instance.url}');
    });
  }

  Future<void> pushProfile() async {
    final targets = vault.instances.where((item) => item.signedIn).toList();
    if (targets.isEmpty) {
      notice = _text('Нет инстансов со входом', 'No signed-in instances');
      notifyListeners();
      return;
    }
    await _run(() async {
      final lines = <String>[];
      final png = vault.iconPng == null ? null : base64Decode(vault.iconPng!);
      for (final instance in targets) {
        try {
          final api = _api(instance.url);
          final uuid = instance.userUuid ?? jwtUuid(instance.token!);
          if (vault.login.isNotEmpty) {
            await api.updateLogin(instance.token!, uuid, vault.login);
          }
          if (png != null) {
            await api.uploadIcon(instance.token!, uuid, png);
          }
          lines.add('${instance.url}: ok');
        } catch (error) {
          lines.add('${instance.url}: $error');
        }
      }
      notice = lines.join('\n');
    });
  }

  void _activate(String url) {
    for (final instance in vault.instances) {
      instance.active = instance.url == url;
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (busy) return;
    busy = true;
    notice = '';
    notifyListeners();
    try {
      await action();
    } catch (error) {
      notice = '$error';
    } finally {
      busy = false;
      await store.write(vault);
      notifyListeners();
    }
  }

  String _text(String ru, String en) => vault.language == 'en' ? en : ru;
}
