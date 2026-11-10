import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/api/pepeunit_api.dart';
import 'package:pepeunit_client/locale/error_texts.dart';
import 'package:pepeunit_client/locale/failure.dart';

const _names = {920100: 'UNIT_NOT_FOUND', 933101: 'USER_LOGIN_INVALID'};

String _body(int code) =>
    '{"detail":"422: $code: Unit Validation Error: x",'
    '"error_code":$code}';

void main() {
  tearDown(ErrorCatalog.forget);

  test('a backend code gets the line of its name', () {
    final text = describeFailure(
      ApiException(422, _body(920100)).toString(),
      'ru',
      names: _names,
    );
    expect(text, errorTexts['ru']!['UNIT_NOT_FOUND']);
    expect(text, isNot(contains('detail')));
  });

  test('the catalog from the route resolves the number', () {
    ErrorCatalog.learn({'USER_LOGIN_INVALID': 933101, 'bad': 'x'});
    expect(ErrorCatalog.loaded, isTrue);
    expect(ErrorCatalog.nameOf(933101), 'USER_LOGIN_INVALID');
    expect(
      describeFailure('HTTP 422 ${_body(933101)}', 'ru'),
      errorTexts['ru']!['USER_LOGIN_INVALID'],
    );
  });

  test('a validator code in a detail row is found', () {
    const body =
        '{"detail":[{"type":"error.933101","loc":["body","login"],'
        '"msg":"Value error"}]}';
    expect(
      describeFailure('HTTP 422 $body', 'ru', names: _names),
      errorTexts['ru']!['USER_LOGIN_INVALID'],
    );
  });

  test('a code with no line falls back to the status and shows the code', () {
    final text = describeFailure(
      'HTTP 422 ${_body(999999)}',
      'ru',
      names: _names,
    );
    expect(text, contains('(код 999999)'));
    expect(text, isNot(contains('{')));
  });

  test('English has the line of the code', () {
    expect(
      describeFailure('HTTP 422 ${_body(920100)}', 'en', names: _names),
      errorTexts['en']!['UNIT_NOT_FOUND'],
    );
  });

  test('a language with no lines reads Russian', () {
    expect(
      describeFailure('HTTP 422 ${_body(920100)}', 'de', names: _names),
      errorTexts['ru']!['UNIT_NOT_FOUND'],
    );
  });

  test('general lines come in both languages', () {
    for (final status in [
      200,
      401,
      403,
      404,
      408,
      413,
      422,
      429,
      503,
      500,
      418,
    ]) {
      final ru = describeFailure(ApiException(status, '').toString(), 'ru');
      final en = describeFailure(ApiException(status, '').toString(), 'en');
      expect(en, isNot(ru), reason: '$status');
      expect(en, isNot(matches(RegExp(r'[А-Яа-яЁё]'))), reason: '$status');
    }
    final en = describeFailure(
      'HTTP 422 ${_body(999999)}',
      'en',
      names: _names,
    );
    expect(en, contains('(code 999999)'));
    expect(describeFailure('Failed to fetch', 'en'), contains('No connection'));
    expect(
      describeFailure('TimeoutException after 0:00:20', 'en'),
      contains('did not answer'),
    );
    expect(
      describeFailure('FormatException: Unexpected character', 'en'),
      contains('could not be read'),
    );
  });

  test('a local failure is read in the language of the screen', () {
    const failure = LocalFailure('Нет входа', 'No sign-in');
    expect(describeFailure('$failure', 'ru'), 'Нет входа');
    expect(describeFailure('$failure', 'en'), 'No sign-in');
    final api = ApiException.local('Нет связи', 'Offline');
    expect(describeFailure('$api', 'en'), 'Offline');
    expect(LocalFailure.plain('$failure'), 'Нет входа');
    expect(LocalFailure.plain('plain'), 'plain');
  });

  test('a failure without a code gets a general line by status', () {
    String line(int status, [String body = '']) =>
        describeFailure(ApiException(status, body).toString(), 'ru');
    expect(line(401), contains('Войдите'));
    expect(line(403), contains('нет прав'));
    expect(line(404, '{"detail":"Not Found"}'), contains('не нашёл'));
    expect(line(422), contains('Проверьте'));
    expect(line(429), contains('Подождите'));
    expect(line(502, '<html>bad gateway</html>'), contains('недоступен'));
    expect(line(500), contains('ошибка'));
    expect(line(418), contains('отклонил'));
    for (final status in [401, 404, 500, 502]) {
      expect(line(status, '<html>x</html>'), isNot(contains('<html>')));
    }
  });

  test('a lost connection and a timeout are explained', () {
    expect(
      describeFailure(
        'ClientException with SocketException: Failed host lookup: x',
        'ru',
      ),
      contains('Нет связи'),
    );
    expect(describeFailure('Failed to fetch', 'ru'), contains('Нет связи'));
    expect(
      describeFailure(
        'TimeoutException after 0:00:20.000000: Future not completed',
        'ru',
      ),
      contains('не ответил'),
    );
  });

  test('a developer exception becomes a sentence', () {
    expect(
      describeFailure('FormatException: Unexpected character', 'ru'),
      contains('Не удалось разобрать'),
    );
    expect(
      describeFailure(
        "type 'Null' is not a subtype of type 'String' in type cast",
        'ru',
      ),
      contains('Не удалось разобрать'),
    );
  });

  test('a sentence for the user stays as it is', () {
    const own = 'Нет входа';
    expect(describeFailure(own, 'ru'), own);
    expect(
      describeFailure('host.example: Нет связи с сервером.', 'ru'),
      'host.example: Нет связи с сервером.',
    );
  });

  test('every text is a short sentence under its own code name', () {
    final name = RegExp(r'^[A-Z][A-Z0-9_]+$');
    for (final entry in errorTexts['ru']!.entries) {
      expect(name.hasMatch(entry.key), isTrue, reason: entry.key);
      expect(entry.value.trim(), isNotEmpty, reason: entry.key);
      expect(entry.value.length, lessThan(160), reason: entry.key);
      expect(entry.value, isNot(contains('{')), reason: entry.key);
    }
  });

  test('every Russian line has an English one', () {
    expect(errorTexts['en']!.keys.toSet(), errorTexts['ru']!.keys.toSet());
    final cyrillic = RegExp(r'[А-Яа-яЁё]');
    for (final entry in errorTexts['en']!.entries) {
      expect(entry.value.trim(), isNotEmpty, reason: entry.key);
      expect(entry.value.length, lessThan(160), reason: entry.key);
      expect(entry.value, isNot(contains('{')), reason: entry.key);
      expect(cyrillic.hasMatch(entry.value), isFalse, reason: entry.key);
    }
  });

  test('the table names every code of the backend next to this repo', () {
    final file = File('../pepeunit_backend/app/configs/error_codes.py');
    if (!file.existsSync()) return;
    final codes = RegExp(
      r'^\s{4}([A-Z][A-Z0-9_]+) = \d+_\d+\s*$',
      multiLine: true,
    ).allMatches(file.readAsStringSync()).map((m) => m.group(1)!).toList();
    expect(codes, isNotEmpty);
    final lacking = [
      for (final code in codes)
        if (!errorTexts['ru']!.containsKey(code)) code,
    ];
    expect(lacking, isEmpty, reason: 'no text for $lacking');
    final extra = [
      for (final key in errorTexts['ru']!.keys)
        if (!codes.contains(key)) key,
    ];
    expect(extra, isEmpty, reason: 'not in the backend: $extra');
  });
}
