import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pqcrypto/pqcrypto.dart';

const secretKeyFileName = 'pepeunit-ml-dsa-87.key';

const _header = 'PEPEUNIT ML-DSA-87 PRIVATE KEY';

String encodeSecretKeyFile(Uint8List secretKey) {
  final encoded = base64.encode(secretKey);
  final lines = <String>[_header];
  for (var i = 0; i < encoded.length; i += 64) {
    lines.add(encoded.substring(i, min(i + 64, encoded.length)));
  }
  return '${lines.join('\n')}\n';
}

/// Raw ML-DSA-87 secret key bytes, or null when the file is not that key.
Uint8List? decodeSecretKeyFile(Uint8List raw) {
  final size = DilithiumParams.mlDsa87.secretKeyBytes;
  if (raw.length == size) return Uint8List.fromList(raw);
  try {
    final payload = _payload(utf8.decode(raw));
    if (payload.isEmpty) return null;
    final bytes = base64.decode(_padded(payload));
    if (bytes.length != size) return null;
    return bytes;
  } catch (_) {
    return null;
  }
}

String _payload(String text) {
  final kept = <String>[];
  for (final line in text.split(RegExp(r'\r?\n'))) {
    final trimmed = line.trim();
    if (trimmed.isEmpty ||
        trimmed.startsWith('-----') ||
        trimmed.startsWith('PEPEUNIT ')) {
      continue;
    }
    kept.add(trimmed);
  }
  return kept.join();
}

String _padded(String compact) {
  final normalized = compact.replaceAll('-', '+').replaceAll('_', '/');
  final rest = normalized.length % 4;
  if (rest == 0) return normalized;
  return normalized.padRight(normalized.length + (4 - rest), '=');
}
