import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'instance.dart';

/// Web reads `instance-config.json`, which the container writes from
/// `INSTANCE_URL` at start. An empty value means the instance that served
/// the page. Desktop and mobile stay without a target until one is chosen.
/// A compile-time `INSTANCE_URL` is used when it is set.
Future<String?> readHostedInstanceUrl({http.Client? client}) async {
  const defined = String.fromEnvironment('INSTANCE_URL');
  if (defined.isNotEmpty) return defined;
  if (!kIsWeb) return null;
  final httpClient = client ?? http.Client();
  final close = client == null;
  try {
    final response = await httpClient
        .get(Uri.base.resolve('/instance-config.json'))
        .timeout(const Duration(seconds: 3));
    final body = response.body.trimLeft();
    if (response.statusCode == 200 &&
        body.isNotEmpty &&
        !body.startsWith('<')) {
      final json = jsonDecode(response.body);
      if (json is Map) {
        final url = json['instanceUrl'];
        if (url is String && url.trim().isNotEmpty) return url.trim();
      }
    }
  } catch (_) {
  } finally {
    if (close) httpClient.close();
  }
  // `flutter run` serves the client itself. That origin is not an instance.
  if (kDebugMode) return null;
  return Uri.base.resolve(instanceCurrentPath).replace(query: '').toString();
}
