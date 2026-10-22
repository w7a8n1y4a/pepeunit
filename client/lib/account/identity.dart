import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pqcrypto/pqcrypto.dart' hide sha256;

(Uint8List, Uint8List) generateMlDsa87KeyPair(int _) {
  return MlDsa.generateKeyPair(DilithiumParams.mlDsa87);
}

/// ML-DSA-87 key pair. The backend expects the raw 2592-byte public key
/// in standard base64 and a signature over the challenge JWT bytes.
class Identity {
  Identity({required this.publicKey, required this.secretKey});

  static final params = DilithiumParams.mlDsa87;

  final Uint8List publicKey;
  final Uint8List secretKey;

  factory Identity.generate() {
    final (publicKey, secretKey) = generateMlDsa87KeyPair(0);
    return Identity(publicKey: publicKey, secretKey: secretKey);
  }

  factory Identity.fromParts(String publicKeyBase64, String secretKeyBase64) {
    return Identity(
      publicKey: base64.decode(publicKeyBase64),
      secretKey: base64.decode(secretKeyBase64),
    );
  }

  String get publicKeyBase64 => base64.encode(publicKey);

  String get secretKeyBase64 => base64.encode(secretKey);

  String get hashPublicKey => sha256.convert(publicKey).toString();

  Uint8List signChallenge(String challenge) {
    return MlDsa.sign(
      secretKey,
      Uint8List.fromList(utf8.encode(challenge)),
      params,
    );
  }
}
