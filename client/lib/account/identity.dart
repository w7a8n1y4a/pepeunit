// pqcrypto does not publish secret-key recovery. The steps below are FIPS 204
// KeyGen from the expanded secret key, checked against tr = H(pk).
// ignore_for_file: implementation_imports

import 'dart:convert';
import 'dart:typed_data';

import 'package:pqcrypto/pqcrypto.dart';
import 'package:pqcrypto/src/algos/dilithium/ntt.dart';
import 'package:pqcrypto/src/algos/dilithium/packing.dart';
import 'package:pqcrypto/src/algos/dilithium/params.dart' show n;
import 'package:pqcrypto/src/algos/dilithium/poly.dart';
import 'package:pqcrypto/src/algos/dilithium/rounding.dart';
import 'package:pqcrypto/src/algos/dilithium/symmetric.dart';

import 'key_mark.dart';

(Uint8List, Uint8List) generateMlDsa87KeyPair(int _) {
  return MlDsa.generateKeyPair(DilithiumParams.mlDsa87);
}

/// Public key for an ML-DSA-87 secret key, or null when [secretKey] is not one.
///
/// The public key is determined by the secret key. Nothing is sent anywhere.
(Uint8List, Uint8List)? deriveMlDsa87Public(Uint8List secretKey) {
  final params = DilithiumParams.mlDsa87;
  if (secretKey.length != params.secretKeyBytes) return null;
  Uint8List? rho;
  Uint8List? kKey;
  Uint8List? tr;
  DilithiumPolyVec? s1;
  DilithiumPolyVec? s2;
  DilithiumPolyVec? t0;
  try {
    final unpacked = unpackSK(secretKey, params.k, params.l, params.eta);
    rho = unpacked.$1;
    kKey = unpacked.$2;
    tr = unpacked.$3;
    s1 = unpacked.$4;
    s2 = unpacked.$5;
    t0 = unpacked.$6;
    if (!_bounded(s1, params.eta) || !_bounded(s2, params.eta)) return null;
    final publicKey = _publicKey(params, rho, s1, s2);
    if (!_same(DilithiumSymmetric.crh(publicKey, 64), tr)) return null;
    return (publicKey, secretKey);
  } catch (_) {
    return null;
  } finally {
    secureZero(rho);
    secureZero(kKey);
    secureZero(tr);
    _zeroVec(s1);
    _zeroVec(s2);
    _zeroVec(t0);
  }
}

Uint8List _publicKey(
  DilithiumParams params,
  Uint8List rho,
  DilithiumPolyVec s1,
  DilithiumPolyVec s2,
) {
  final aHat = DilithiumSymmetric.expandA(rho, params.k, params.l);
  final s1Hat = DilithiumPolyVec.zero(params.l);
  for (var i = 0; i < params.l; i++) {
    s1Hat[i].coeffs.setAll(0, s1[i].coeffs);
    s1Hat[i].reduce();
    DilithiumNTT.ntt(s1Hat[i]);
  }
  final s2Hat = DilithiumPolyVec.zero(params.k);
  for (var i = 0; i < params.k; i++) {
    s2Hat[i].coeffs.setAll(0, s2[i].coeffs);
    s2Hat[i].reduce();
    DilithiumNTT.ntt(s2Hat[i]);
  }
  final tHat = DilithiumPolyVec.zero(params.k);
  for (var i = 0; i < params.k; i++) {
    for (var j = 0; j < params.l; j++) {
      tHat[i] = tHat[i] + aHat[i][j].pointwiseMul(s1Hat[j]);
    }
    tHat[i] = tHat[i] + s2Hat[i];
  }
  final t1 = DilithiumPolyVec.zero(params.k);
  for (var i = 0; i < params.k; i++) {
    DilithiumNTT.invNtt(tHat[i]);
    for (var c = 0; c < n; c++) {
      t1[i].coeffs[c] = power2Round(tHat[i].coeffs[c]).$1;
    }
  }
  return packPK(rho, t1);
}

bool _bounded(DilithiumPolyVec vec, int limit) {
  for (final poly in vec.components) {
    for (final coeff in poly.coeffs) {
      if (coeff < -limit || coeff > limit) return false;
    }
  }
  return true;
}

bool _same(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

void _zeroVec(DilithiumPolyVec? vec) {
  if (vec == null) return;
  for (final poly in vec.components) {
    secureZeroInt32(poly.coeffs);
  }
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

  String get hashPublicKey => publicKeyHashHex(publicKey);

  Uint8List signChallenge(String challenge) {
    return MlDsa.sign(
      secretKey,
      Uint8List.fromList(utf8.encode(challenge)),
      params,
    );
  }
}
