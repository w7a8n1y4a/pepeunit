import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import 'icon_disk.dart';

/// Application support directory. Tests skip it, and a missing plugin leaves
/// the memory cache in place. The web build does not compile this file.
Future<IconDisk?> openIconDisk() async {
  if (Platform.environment.containsKey('FLUTTER_TEST')) return null;
  try {
    final root = await getApplicationSupportDirectory();
    final dir = Directory('${root.path}${Platform.pathSeparator}icons');
    await dir.create(recursive: true);
    return FileIconDisk(dir);
  } catch (_) {
    return null;
  }
}

/// One file per icon key. The key is hashed, so an origin cannot escape the
/// directory. A changed picture is a new uuid, and files past [cap] are the
/// ones least recently written.
class FileIconDisk implements IconDisk {
  FileIconDisk(this.root, {this.cap = 512});

  final Directory root;
  final int cap;
  var _trimming = false;

  static final _name = RegExp(r'^[0-9a-f]{64}$');

  File _file(String key) {
    final name = sha256.convert(utf8.encode(key)).toString();
    return File('${root.path}${Platform.pathSeparator}$name');
  }

  @override
  Future<Uint8List?> read(String key) async {
    final file = _file(key);
    if (!await file.exists()) return null;
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      return bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String key, Uint8List bytes) async {
    if (bytes.isEmpty) return;
    final file = _file(key);
    final part = File('${file.path}.part');
    await part.writeAsBytes(bytes, flush: true);
    if (await file.exists()) {
      try {
        await file.delete();
      } catch (_) {}
    }
    await part.rename(file.path);
    await _trim();
  }

  Future<void> _trim() async {
    if (_trimming || cap < 1) return;
    _trimming = true;
    try {
      final files = <File>[];
      await for (final entity in root.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (!_name.hasMatch(name)) continue;
        files.add(entity);
      }
      if (files.length <= cap) return;
      final stamped = <({File file, DateTime modified})>[];
      for (final file in files) {
        try {
          stamped.add((file: file, modified: (await file.stat()).modified));
        } catch (_) {}
      }
      stamped.sort((a, b) => a.modified.compareTo(b.modified));
      final extra = stamped.length - cap;
      for (var i = 0; i < extra; i++) {
        try {
          await stamped[i].file.delete();
        } catch (_) {}
      }
    } finally {
      _trimming = false;
    }
  }
}
