import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// SHA-256 of the raw public key, lowercase hex. This is the backend
/// `hash_public_key`.
String publicKeyHashHex(Uint8List publicKey) =>
    sha256.convert(publicKey).toString();

/// First six and last six hex digits: `4fa478-8b7cf2`.
String keyMark(Uint8List publicKey) {
  final hex = publicKeyHashHex(publicKey);
  return '${hex.substring(0, 6)}-${hex.substring(hex.length - 6)}';
}

String? keyMarkFromBase64(String? publicKeyBase64) {
  if (publicKeyBase64 == null || publicKeyBase64.isEmpty) return null;
  try {
    final bytes = base64.decode(publicKeyBase64);
    if (bytes.isEmpty) return null;
    return keyMark(bytes);
  } catch (_) {
    return null;
  }
}
