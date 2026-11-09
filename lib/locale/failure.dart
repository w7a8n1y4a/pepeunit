import 'dart:convert';

import 'error_texts.dart';
import 'languages.dart';

/// Code number to code name, as the backend lists them at `/error_codes`.
///
/// The texts are keyed by name, the response carries the number. One table is
/// enough for every instance: a number never changes its meaning.
class ErrorCatalog {
  const ErrorCatalog._();

  static var _names = <int, String>{};

  static bool get loaded => _names.isNotEmpty;

  /// Adds a `/error_codes` answer. A row that is not name to number is dropped.
  static void learn(Map<String, Object?> catalog) {
    final next = {..._names};
    for (final entry in catalog.entries) {
      final number = entry.value;
      if (number is int) next[number] = entry.key;
    }
    _names = next;
  }

  static String? nameOf(int code) => _names[code];

  static void forget() => _names = <int, String>{};
}

/// The text a person reads in place of an error.
///
/// [raw] is what the screen kept of the failure: `ApiException.toString()`
/// (`HTTP <status> <body>`) or the text of any other exception. A backend
/// code gets its own line from [errorTexts]. A failure without a known code
/// gets a general line for its status, or for a lost connection, a timeout,
/// or a broken answer. Anything else is already a sentence written for the
/// user and stays as it is.
String describeFailure(String raw, String language, {Map<int, String>? names}) {
  final text = raw.trim();
  final reply = _httpReply.firstMatch(text);
  if (reply != null) {
    final status = int.parse(reply.group(1)!);
    final code = _codeOf(reply.group(2) ?? '');
    final name = code == null ? null : (names ?? ErrorCatalog._names)[code];
    final line = name == null ? null : _codeLine(name, language);
    if (line != null) return line;
    return _byStatus(status, language, code);
  }
  if (_timeout.hasMatch(text)) {
    return phrase(language, {
      'ru':
          'Сервер не ответил вовремя. Он перегружен или недоступен, '
          'повторите позже.',
    });
  }
  if (_offline.hasMatch(text)) {
    return phrase(language, {
      'ru':
          'Нет связи с сервером. Проверьте интернет и адрес инстанса, '
          'возможно, сервер сейчас выключен.',
    });
  }
  if (_technical.hasMatch(text)) {
    return phrase(language, {
      'ru':
          'Не удалось разобрать ответ сервера. Возможно, версия инстанса не '
          'подходит этому клиенту: обновите клиент или инстанс.',
    });
  }
  return raw;
}

String? _codeLine(String name, String language) {
  final own = errorTexts[language]?[name];
  if (own != null && own.isNotEmpty) return own;
  final russian = errorTexts['ru']?[name];
  if (russian != null && russian.isNotEmpty) return russian;
  return null;
}

final _httpReply = RegExp(r'^HTTP (\d{3})(?:\s+([\s\S]*))?$');

final _timeout = RegExp(r'TimeoutException');

final _offline = RegExp(
  r'SocketException|ClientException|HandshakeException|TlsException|'
  r'WebSocketException|Failed host lookup|Connection (?:refused|reset|closed)|'
  r'Failed to fetch|XMLHttpRequest error|Network is unreachable',
);

/// An exception printed as is, so the text is for a developer.
final _technical = RegExp(
  r'^(?:[A-Za-z_]\w*\.)*[A-Za-z_]\w*(?:Exception|Error)\b|'
  r'is not a subtype of type|Null check operator',
);

final _wireCode = RegExp(r'^\d{3}: (\d{6}): ');

final _validationType = RegExp(r'^error\.(\d{6})$');

/// The backend code in an error body, or null when the body has none.
///
/// A domain error carries `error_code`. A failed pydantic validator carries it
/// as `error.<code>` in the type of a row of `detail`.
int? _codeOf(String body) {
  final Object? json;
  try {
    json = jsonDecode(body);
  } on FormatException {
    return null;
  }
  if (json is! Map) return null;
  final direct = json['error_code'];
  if (direct is int) return direct;
  final detail = json['detail'];
  if (detail is String) {
    final match = _wireCode.firstMatch(detail);
    return match == null ? null : int.parse(match.group(1)!);
  }
  if (detail is List) {
    for (final row in detail) {
      if (row is! Map) continue;
      final type = row['type'];
      if (type is! String) continue;
      final match = _validationType.firstMatch(type);
      if (match != null) return int.parse(match.group(1)!);
    }
  }
  return null;
}

String _byStatus(int status, String language, int? code) {
  final line = phrase(language, {'ru': _statusLine(status)});
  return code == null ? line : '$line (код $code)';
}

String _statusLine(int status) {
  if (status >= 200 && status < 300) {
    return 'Сервер ответил не так, как ждёт клиент. Проверьте адрес '
        'инстанса, возможно, его версия не подходит клиенту.';
  }
  switch (status) {
    case 401:
      return 'Сервер не принял вход: сессия истекла или ключ не подошёл. '
          'Войдите заново.';
    case 403:
      return 'На этом инстансе у вас нет прав на это действие.';
    case 404:
      return 'Сервер не нашёл запрошенное. Возможно, версия инстанса не '
          'подходит этому клиенту.';
    case 408:
      return 'Сервер не дождался запроса. Проверьте связь и повторите.';
    case 413:
      return 'Запрос слишком большой для сервера.';
    case 422:
      return 'Сервер не принял данные: значения не прошли проверку. '
          'Проверьте заполненные поля.';
    case 429:
      return 'Запросов слишком много. Подождите немного и повторите.';
    case 502:
    case 503:
    case 504:
      return 'Сервер временно недоступен: он перезапускается или перегружен. '
          'Повторите позже.';
  }
  if (status >= 500) {
    return 'На сервере произошла ошибка. Повторите позже, а если не '
        'проходит, сообщите владельцу инстанса.';
  }
  return 'Сервер отклонил запрос. Проверьте данные и повторите.';
}
