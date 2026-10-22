import 'package:flutter/foundation.dart';

import 'account/vault.dart';
import 'account/vault_store.dart';

class AppModel extends ChangeNotifier {
  AppModel({required this.store});

  final VaultStore store;

  Vault vault = Vault.fresh();
  bool ready = false;

  Future<void> load() async {
    vault = await store.read();
    ready = true;
    notifyListeners();
  }
}
