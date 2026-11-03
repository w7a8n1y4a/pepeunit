import 'icon_disk.dart';
import 'icon_disk_stub.dart' if (dart.library.io) 'icon_disk_io.dart' as impl;

/// Disk cache on a native process, nothing on the web.
Future<IconDisk?> openIconDisk() => impl.openIconDisk();
