import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'account/identity.dart';
import 'account/key_file_port.dart';
import 'account/vault.dart';
import 'account/vault_store.dart';
import 'locale/languages.dart';

class AppModel extends ChangeNotifier {
  AppModel({required this.store, KeyFilePort? files})
    : files = files ?? PlatformKeyFilePort();

  final VaultStore store;
  final KeyFilePort files;

  Vault vault = Vault.fresh();
  bool ready = false;
  Future<void> _pending = Future<void>.value();

  Future<void> load() async {
    vault = await store.read();
    ready = true;
    notifyListeners();
  }

  /// Keeps the key pair on the client. The network is not used.
  Future<void> adoptIdentity(Identity identity) {
    vault.publicKey = identity.publicKeyBase64;
    vault.secretKey = identity.secretKeyBase64;
    return _commit();
  }

  Future<void> signOut() {
    vault.clearSession();
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

  Future<void> _commit() {
    notifyListeners();
    final snapshot = vault.copy();
    _pending = _pending.then((_) => store.write(snapshot));
    return _pending;
  }
}
