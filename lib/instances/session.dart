import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../account/identity.dart';
import '../api/pepeunit_api.dart';
import 'test_env_stub.dart' if (dart.library.io) 'test_env_io.dart';

class InstanceSession {
  const InstanceSession({
    required this.token,
    required this.uuid,
    required this.role,
  });

  final String token;
  final String uuid;
  final String role;
}

/// Registers the key on the instance when it is not there yet, then signs
/// the challenge. The private key does not leave the client.
Future<InstanceSession> openSession(PepeunitApi api, Identity identity) async {
  final challenge = await _challenge(api, identity);
  // The sign is a few dozen ms of pure Dart. It runs apart from the UI
  // isolate on desktop and mobile; on web `compute` stays inline, and a
  // widget-test runner signs inline so the fake clock keeps control.
  final signature = base64.encode(
    inFlutterTestRunner
        ? identity.signChallenge(challenge)
        : await compute(signChallengeDetached, (
            secretKey: identity.secretKeyBase64,
            challenge: challenge,
          )),
  );
  final token = await api.auth(challenge, signature);
  final uuid = jwtUuid(token);
  final user = await api.user(token, uuid);
  return InstanceSession(token: token, uuid: uuid, role: user.role);
}

Future<String> _challenge(PepeunitApi api, Identity identity) async {
  try {
    return await api.challenge(identity.hashPublicKey);
  } on ApiException catch (error) {
    if (!error.missingUser) rethrow;
  }
  try {
    await api.register(identity.publicKeyBase64);
  } on ApiException catch (error) {
    if (error.status >= 500) rethrow;
  }
  return api.challenge(identity.hashPublicKey);
}
