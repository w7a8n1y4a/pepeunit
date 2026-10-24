/// Client languages. To add one, append it here and fill the same code in
/// phrase maps. A missing line falls back to Russian.
const appLanguages = <AppLanguage>[
  AppLanguage(code: 'ru', nativeName: 'Русский'),
  AppLanguage(code: 'en', nativeName: 'English'),
];

class AppLanguage {
  const AppLanguage({required this.code, required this.nativeName});

  final String code;
  final String nativeName;
}

bool knownLanguage(String code) {
  for (final language in appLanguages) {
    if (language.code == code) return true;
  }
  return false;
}

/// Picks [language], then Russian, then the first filled line.
String phrase(String language, Map<String, String> values) {
  final direct = values[language];
  if (direct != null && direct.isNotEmpty) return direct;
  final russian = values['ru'];
  if (russian != null && russian.isNotEmpty) return russian;
  for (final value in values.values) {
    if (value.isNotEmpty) return value;
  }
  return '';
}
