import 'languages.dart';

/// Account roles, including an unauthenticated visitor (Bot).
String roleLabel(String language, String role) {
  return switch (role) {
    'Bot' => localized(language, 'Бот', 'Bot'),
    'Admin' => localized(language, 'Админ', 'Admin'),
    'Owner' => localized(language, 'Владелец', 'Owner'),
    _ => localized(language, 'Пользователь', 'User'),
  };
}
