import 'dart:async';
import 'dart:typed_data';

import 'icon_disk.dart';

/// The only way the client reads an icon.
///
/// The backend marks icon responses cacheable, so a browser keeps them. The
/// Dart HTTP client does not, and a native process would download the same
/// picture on every launch. Bytes stay in memory, and on a device they are
/// also written to [IconDisk]. A uuid identifies the bytes: a new picture is
/// a new uuid.
///
/// Calls for one origin and uuid share one load, from disk or from the network.
class IconStore {
  IconStore({IconDisk? disk, Future<IconDisk?> Function()? openDisk})
    : _disk = disk,
      _openDisk = disk == null ? openDisk : null,
      _ready = disk != null || openDisk == null;

  static String keyOf(String origin, String uuid) => '$origin/$uuid';

  final Map<String, Uint8List> memory = {};
  final Future<IconDisk?> Function()? _openDisk;
  final Map<String, Future<Uint8List>> _inflight = {};
  IconDisk? _disk;
  Future<IconDisk?>? _opening;
  bool _ready;

  Uint8List? peek(String key) => memory[key];

  /// Keeps bytes the client already holds, such as a picture just uploaded.
  Future<void> remember(String key, Uint8List bytes) async {
    if (bytes.isEmpty) return;
    final copy = Uint8List.fromList(bytes);
    memory[key] = copy;
    await _persist(key, copy);
  }

  Future<Uint8List> load({
    required String origin,
    required String uuid,
    required Future<Uint8List> Function() fetch,
  }) {
    final key = keyOf(origin, uuid);
    final hit = memory[key];
    if (hit != null) return Future<Uint8List>.value(hit);
    return _inflight[key] ??= _miss(key, fetch);
  }

  Future<Uint8List> _miss(
    String key,
    Future<Uint8List> Function() fetch,
  ) async {
    try {
      final stored = await _read(key);
      if (stored != null) {
        final copy = Uint8List.fromList(stored);
        memory[key] = copy;
        return copy;
      }
      final bytes = await fetch();
      if (bytes.isNotEmpty) {
        final copy = Uint8List.fromList(bytes);
        memory[key] = copy;
        await _persist(key, copy);
      }
      return bytes;
    } finally {
      _inflight.remove(key);
    }
  }

  Future<IconDisk?> _diskReady() {
    if (_ready) return Future<IconDisk?>.value(_disk);
    return _opening ??= _open();
  }

  Future<IconDisk?> _open() async {
    try {
      final open = _openDisk;
      if (open != null) _disk = await open();
    } catch (_) {
      _disk = null;
    }
    _ready = true;
    return _disk;
  }

  Future<Uint8List?> _read(String key) async {
    try {
      final disk = await _diskReady();
      final stored = await disk?.read(key);
      if (stored == null || stored.isEmpty) return null;
      return stored;
    } catch (_) {
      return null;
    }
  }

  Future<void> _persist(String key, Uint8List bytes) async {
    if (bytes.isEmpty) return;
    try {
      final disk = await _diskReady();
      await disk?.write(key, bytes);
    } catch (_) {}
  }
}
