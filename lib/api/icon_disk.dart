import 'dart:typed_data';

/// Bytes kept across launches. The web client does not use one: the backend
/// already marks icon responses cacheable, and the browser stores them.
abstract class IconDisk {
  Future<Uint8List?> read(String key);

  Future<void> write(String key, Uint8List bytes);
}
