import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// The favorite instance `INSTANCE_URL` names, or null when it is not set.
///
/// A compile-time `INSTANCE_URL` wins on every platform. Web otherwise reads
/// `instance-config.json`, which the container writes from `INSTANCE_URL` at
/// start. An empty value means no favorite: the origin that served the page is
/// not guessed, and the person picks one in the instance search. Desktop and
/// mobile behave the same way, they only rarely have the variable.
Future<String?> readHostedInstanceUrl({http.Client? client}) async {
  const defined = String.fromEnvironment('INSTANCE_URL');
  if (defined.trim().isNotEmpty) return defined.trim();
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
  return null;
}
