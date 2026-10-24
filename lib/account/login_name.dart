final _allowed = RegExp(r'^[a-zA-Z0-9_.-]+$');
final _rejected = RegExp(r'[^a-zA-Z0-9_.-]');

const loginMin = 4;
const loginMax = 20;

String cleanLogin(String raw) {
  final cleaned = raw.replaceAll(_rejected, '');
  if (cleaned.length <= loginMax) return cleaned;
  return cleaned.substring(0, loginMax);
}

/// Empty means the login is not set. Anything else must fit the alphabet
/// and the length.
bool loginStorable(String text) => text.isEmpty || loginValid(text);

bool loginValid(String text) =>
    text.length >= loginMin &&
    text.length <= loginMax &&
    _allowed.hasMatch(text);
