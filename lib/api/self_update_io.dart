import 'dart:io';
import 'dart:typed_data';

/// A running AppImage names its own file in `APPIMAGE`. The new file is
/// written next to it and renamed over it, so a failed write leaves the old
/// one whole. The running process keeps the old file open.
Future<bool> replaceRunningApp(Uint8List bytes, String platform) async {
  if (platform != 'linux' || bytes.isEmpty) return false;
  final path = Platform.environment['APPIMAGE'];
  if (path == null || path.isEmpty) return false;
  final staged = File('$path.new');
  try {
    await staged.writeAsBytes(bytes, flush: true);
    final chmod = await Process.run('chmod', ['755', staged.path]);
    if (chmod.exitCode != 0) throw const FileSystemException('chmod failed');
    await staged.rename(path);
    return true;
  } catch (_) {
    try {
      if (staged.existsSync()) staged.deleteSync();
    } catch (_) {}
    return false;
  }
}
