import 'package:flutter/foundation.dart';

import 'account/identity.dart';
import 'account/key_file_port.dart';
import 'account/vault.dart';
import 'account/vault_store.dart';

class AppModel extends ChangeNotifier {
  AppModel({required this.store, KeyFilePort? files})
    : files = files ?? PlatformKeyFilePort();

  final VaultStore store;
  final KeyFilePort files;

  Vault vault = Vault.fresh();
  bool ready = false;

  Future<void> load() async {
    vault = await store.read();
    ready = true;
    notifyListeners();
  }

  /// Keeps the key pair on the client. The network is not used.
  Future<void> adoptIdentity(Identity identity) async {
    vault.publicKey = identity.publicKeyBase64;
    vault.secretKey = identity.secretKeyBase64;
    await store.write(vault);
    notifyListeners();
  }

  Future<void> signOut() async {
    vault.clearSession();
    await store.write(vault);
    notifyListeners();
  }
}
