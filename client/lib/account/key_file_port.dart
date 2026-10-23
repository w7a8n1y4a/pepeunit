import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

abstract class KeyFilePort {
  Future<Uint8List?> pick({String? dialogTitle});

  /// False when the person dismissed the dialog.
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
    String? dialogTitle,
  });
}

class MemoryKeyFilePort implements KeyFilePort {
  Uint8List? nextPick;
  bool failSave = false;
  bool cancelSave = false;
  Uint8List? saved;
  String? savedName;

  @override
  Future<Uint8List?> pick({String? dialogTitle}) async =>
      nextPick == null ? null : Uint8List.fromList(nextPick!);

  @override
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
    String? dialogTitle,
  }) async {
    if (failSave) throw StateError('save failed');
    if (cancelSave) return false;
    savedName = fileName;
    saved = Uint8List.fromList(bytes);
    return true;
  }
}

class PlatformKeyFilePort implements KeyFilePort {
  @override
  Future<Uint8List?> pick({String? dialogTitle}) async {
    final file = await FilePicker.pickFile(
      dialogTitle: dialogTitle,
      type: FileType.any,
    );
    if (file == null) return null;
    return file.readAsBytes();
  }

  @override
  Future<bool> save({
    required String fileName,
    required Uint8List bytes,
    String? dialogTitle,
  }) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      dialogTitle: dialogTitle,
      mimeType: 'application/octet-stream',
    );
    // The browser download starts and then reports no path.
    if (kIsWeb) return true;
    return uri != null;
  }
}
