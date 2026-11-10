import 'dart:typed_data';

import 'self_update_stub.dart'
    if (dart.library.io) 'self_update_io.dart'
    as impl;

/// Puts a downloaded file in place of the running client, when the platform
/// lets a process do so. True when it did: the new version starts at the next
/// launch. False when it could not, and the file is left to the person.
///
/// Today only a Linux AppImage replaces itself. Every other platform needs an
/// installer of its own.
Future<bool> replaceRunningApp(Uint8List bytes, String platform) =>
    impl.replaceRunningApp(bytes, platform);
