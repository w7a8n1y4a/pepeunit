import 'dart:convert';

import '../account/identity.dart';
import '../api/pepeunit_api.dart';

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
  final signature = base64.encode(identity.signChallenge(challenge));
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
