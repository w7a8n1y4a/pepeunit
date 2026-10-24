bool backendCompatible(String version) {
  final parts = version.split('.');
  if (parts.length < 3) return false;
  final major = int.tryParse(parts[0]);
  final minor = int.tryParse(parts[1]);
  final patch = int.tryParse(parts[2]);
  if (major == null || minor == null || patch == null) return false;
  return major == 1 && minor >= 5 && minor < 6;
}
