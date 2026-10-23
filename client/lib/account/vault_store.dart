import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'vault.dart';

abstract class VaultStore {
  Future<Vault> read();

  Future<void> write(Vault vault);
}

class MemoryVaultStore implements VaultStore {
  Vault vault = Vault.fresh();

  @override
  Future<Vault> read() async => vault.copy();

  @override
  Future<void> write(Vault vault) async {
    this.vault = vault.copy();
  }
}

/// Secure storage when the platform has it, and a preferences copy so the
/// same account survives a web session and a desktop session alike.
class PlatformVaultStore implements VaultStore {
  PlatformVaultStore({FlutterSecureStorage? secure})
    : _secure = secure ?? const FlutterSecureStorage();

  static const _key = 'pepeunit.vault';

  final FlutterSecureStorage _secure;

  @override
  Future<Vault> read() async {
    try {
      final raw = await _secure.read(key: _key);
      if (raw != null && raw.isNotEmpty) return Vault.decode(raw);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null && raw.isNotEmpty) return Vault.decode(raw);
    return Vault.fresh();
  }

  @override
  Future<void> write(Vault vault) async {
    final raw = vault.encode();
    try {
      await _secure.write(key: _key, value: raw);
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, raw);
  }
}
