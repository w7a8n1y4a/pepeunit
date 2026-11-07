import 'dart:convert';

/// One indent step of every JSON the client shows.
const codeIndent = '    ';

/// [value] as JSON, indented by [codeIndent].
String encodeIndented(Object? value) =>
    const JsonEncoder.withIndent(codeIndent).convert(value);

/// [raw] as indented JSON when it holds an object or an array. Null for
/// anything else, so the caller keeps the text as it came.
String? prettyJson(String raw) {
  final head = raw.trimLeft();
  if (!head.startsWith('{') && !head.startsWith('[')) return null;
  try {
    final value = jsonDecode(head);
    if (value is Map || value is List) return encodeIndented(value);
  } catch (_) {}
  return null;
}

final _base64Text = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');

/// The UTF-8 text hidden in base64, or null when [raw] is not base64 text.
/// Short strings and binary payloads stay as they are.
String? decodeBase64Text(String raw) {
  final compact = raw.replaceAll(RegExp(r'\s+'), '');
  if (compact.length < 16 || compact.length % 4 != 0) return null;
  if (!_base64Text.hasMatch(compact)) return null;
  try {
    final bytes = base64.decode(compact);
    if (bytes.isEmpty || bytes.contains(0)) return null;
    return utf8.decode(bytes);
  } catch (_) {
    return null;
  }
}
