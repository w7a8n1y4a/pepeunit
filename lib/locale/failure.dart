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

/// A failure the client found itself, written for both languages.
///
/// Screens keep `'$error'`, so the text travels as a string: [toString] joins
/// the lines behind a mark and [describeFailure] picks the language again.
/// The copy button shows [plain] instead of the mark.
class LocalFailure implements Exception {
  const LocalFailure(this.ru, this.en);

  final String ru;
  final String en;

  @override
  String toString() => '$_localMark$ru$_localSplit$en';

  /// The lines of a [toString] text, or null for any other text.
  static Map<String, String>? read(String text) {
    if (!text.startsWith(_localMark)) return null;
    final parts = text.substring(_localMark.length).split(_localSplit);
    return {'ru': parts.first, if (parts.length > 1) 'en': parts[1]};
  }

  /// The Russian line of a [toString] text, the text itself otherwise.
  static String plain(String text) => read(text)?['ru'] ?? text;
}

const _localMark = '\u0001';
const _localSplit = '\u0002';

/// The text a person reads in place of an error.
///
/// [raw] is what the screen kept of the failure: `ApiException.toString()`
/// (`HTTP <status> <body>`) or the text of any other exception. A backend
/// code gets its own line from [errorTexts]. A failure without a known code
/// gets a general line for its status, or for a lost connection, a timeout,
/// or a broken answer. A [LocalFailure] gets the line of the language. Anything
/// else is already a sentence written for the user and stays as it is.
String describeFailure(String raw, String language, {Map<int, String>? names}) {
  final text = raw.trim();
  final local = LocalFailure.read(text);
  if (local != null) return phrase(language, local);
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
      'en':
          'The server did not answer in time. It is overloaded or '
          'unavailable, try again later.',
    });
  }
  if (_offline.hasMatch(text)) {
    return phrase(language, {
      'ru':
          'Нет связи с сервером. Проверьте интернет и адрес инстанса, '
          'возможно, сервер сейчас выключен.',
      'en':
          'No connection to the server. Check the internet and the instance '
          'address, the server may be down.',
    });
  }
  if (_technical.hasMatch(text)) {
    return phrase(language, {
      'ru':
          'Не удалось разобрать ответ сервера. Возможно, версия инстанса не '
          'подходит этому клиенту: обновите клиент или инстанс.',
      'en':
          'The server answer could not be read. The instance version may not '
          'fit this client: update the client or the instance.',
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
  final line = phrase(language, {
    'ru': _statusLine(status),
    'en': _statusLineEn(status),
  });
  if (code == null) return line;
  return language == 'en' ? '$line (code $code)' : '$line (код $code)';
}

String _statusLineEn(int status) {
  if (status >= 200 && status < 300) {
    return 'The server answered not as the client expects. Check the '
        'instance address, its version may not fit the client.';
  }
  switch (status) {
    case 401:
      return 'The server did not accept the sign-in: the session has expired '
          'or the key did not fit. Sign in again.';
    case 403:
      return 'You have no rights for this action on this instance.';
    case 404:
      return 'The server did not find what was asked. The instance version '
          'may not fit this client.';
    case 408:
      return 'The server did not wait for the request. Check the connection '
          'and try again.';
    case 413:
      return 'The request is too large for the server.';
    case 422:
      return 'The server did not accept the data: the values did not pass '
          'validation. Check the filled fields.';
    case 429:
      return 'Too many requests. Wait a little and try again.';
    case 502:
    case 503:
    case 504:
      return 'The server is temporarily unavailable: it is restarting or '
          'overloaded. Try again later.';
  }
  if (status >= 500) {
    return 'An error occurred on the server. Try again later, and if it '
        'does not pass, tell the instance owner.';
  }
  return 'The server rejected the request. Check the data and try again.';
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
