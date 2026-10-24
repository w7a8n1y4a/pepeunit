import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/account/icon_file.dart';
import 'package:pepeunit_client/account/identity.dart';
import 'package:pepeunit_client/account/key_file_port.dart';
import 'package:pepeunit_client/account/key_mark.dart';
import 'package:pepeunit_client/account/login_name.dart';
import 'package:pepeunit_client/account/vault.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/locale/languages.dart';
import 'package:pepeunit_client/locale/time_zones.dart';
import 'package:pepeunit_client/main.dart';

void main() {
  test('phrases fall back and languages stay a list', () {
    expect(appLanguages.map((item) => item.code), ['ru', 'en']);
    expect(phrase('en', {'ru': 'Назад', 'en': 'Back'}), 'Back');
    expect(phrase('de', {'ru': 'Назад', 'en': 'Back'}), 'Назад');
    expect(knownLanguage('ru'), isTrue);
    expect(knownLanguage('de'), isFalse);
  });

  test('login keeps the allowed alphabet and length', () {
    expect(loginValid('ab'), isFalse);
    expect(loginValid('abc'), isFalse);
    expect(loginValid('pepe'), isTrue);
    expect(loginValid('A_z-9.0'), isTrue);
    expect(loginValid('a' * 20), isTrue);
    expect(loginValid('a' * 21), isFalse);
    expect(loginValid('bad login'), isFalse);
    expect(loginStorable(''), isTrue);
    expect(cleanLogin('pépé! '), 'pp');
    expect(cleanLogin('a' * 30).length, loginMax);
  });

  test('key mark is the backend hash, trimmed', () {
    final identity = Identity(
      publicKey: Uint8List.fromList(const [9, 8, 7, 6]),
      secretKey: Uint8List.fromList(const [1]),
    );
    final hex = identity.hashPublicKey;
    expect(hex, publicKeyHashHex(identity.publicKey));
    expect(
      keyMark(identity.publicKey),
      '${hex.substring(0, 6)}-${hex.substring(hex.length - 6)}',
    );
    expect(
      keyMarkFromBase64(identity.publicKeyBase64),
      keyMark(identity.publicKey),
    );
    expect(keyMarkFromBase64('%%%'), isNull);
  });

  test('icon rules accept only a 192 png up to 128 KB', () {
    expect(iconProblem(Uint8List(0)), 'empty');
    expect(iconProblem(Uint8List.fromList(const [1, 2, 3])), 'png');
    expect(iconProblem(_png(1, 1)), 'size');
    expect(iconProblem(_png(192, 192)), isNull);
    final heavy = Uint8List(iconMaxBytes + 1);
    heavy.setRange(0, 8, const [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(iconProblem(heavy), 'large');
  });

  test('time zones use one city and a fixed offset', () {
    expect(formatUtcOffset(180), '+3');
    expect(formatUtcOffset(-300), '-5');
    expect(formatUtcOffset(330), '+5:30');
    expect(formatUtcOffset(0), '+0');
    expect(zoneLabel('UTC', 'ru'), 'Лондон +0');
    expect(zoneLabel('180', 'ru'), 'Москва +3');
    expect(zoneLabel('180', 'en'), 'Moscow +3');
    expect(stepZone('0', 1), 60);
    expect(stepZone('0', -1), -60);
    expect(stepZone('840', 1), timeZones.first.minutes);
    final minutes = timeZones.map((zone) => zone.minutes).toList();
    expect(minutes.toSet().length, minutes.length);
  });

  test('stored UTC and an unknown language are normalized', () {
    final vault = Vault.fromJson({'timeZone': 'UTC', 'language': 'de'});
    expect(vault.timeZone, '0');
    expect(vault.language, 'ru');
    expect(Vault.fresh().timeZone, '0');
  });

  testWidgets('settings store the profile and the home cell shows it', (
    tester,
  ) async {
    final files = MemoryKeyFilePort();
    final store = MemoryVaultStore();
    final model = AppModel(store: store, files: files);
    await model.load();
    final publicKey = Uint8List.fromList(const [4, 5, 6, 7, 8]);
    await model.adoptIdentity(
      Identity(publicKey: publicKey, secretKey: Uint8List.fromList(const [9])),
    );
    final mark = keyMark(publicKey);
    await tester.pumpWidget(AppScope(model: model, child: const PepeunitApp()));
    await tester.pumpAndSettle();

    expect(tester.getSemantics(find.bySemanticsLabel('Аккаунт')).value, mark);
    await tester.tap(find.bySemanticsLabel('Аккаунт'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Логин'), findsOneWidget);
    expect(find.bySemanticsLabel('Отправить в сеть'), findsNothing);
    expect(tester.getSemantics(find.bySemanticsLabel('Ключ')).value, mark);

    await tester.tap(find.bySemanticsLabel('Настройки'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.bySemanticsLabel('Загрузить аватар'), findsOneWidget);
    expect(find.bySemanticsLabel('Параметры'), findsOneWidget);
    expect(find.bySemanticsLabel('Отправить в сеть'), findsOneWidget);
    expect(find.bySemanticsLabel('Лондон +0'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('login-field')), 'ab');
    await tester.pump();
    expect(find.text('От 4 до 20 символов'), findsOneWidget);
    expect(model.vault.login, isEmpty);

    await tester.enterText(find.byKey(const ValueKey('login-field')), 'pepe');
    await tester.pump();
    expect(model.vault.login, 'pepe');
    expect((await store.read()).login, 'pepe');

    await tester.enterText(find.byKey(const ValueKey('login-field')), 'pepe!');
    await tester.pump();
    expect(find.text('Недопустимый символ'), findsOneWidget);
    expect(model.vault.login, 'pepe');

    await tester.tap(find.bySemanticsLabel('Следующий пояс'));
    await tester.pump();
    expect(model.vault.timeZone, '60');
    expect(find.bySemanticsLabel('Лагос +1'), findsOneWidget);
    expect((await store.read()).timeZone, '60');

    await tester.tap(find.text('English'));
    await tester.pump();
    expect(model.vault.language, 'en');
    expect(find.bySemanticsLabel('Upload avatar'), findsOneWidget);
    expect(find.bySemanticsLabel('Parameters'), findsOneWidget);
    expect(find.bySemanticsLabel('Send to network'), findsOneWidget);
    expect(find.bySemanticsLabel('Lagos +1'), findsOneWidget);
    expect((await store.read()).language, 'en');

    files.nextPick = Uint8List.fromList(const [1, 2, 3]);
    await tester.tap(find.bySemanticsLabel('Upload avatar'));
    await tester.pump();
    expect(find.bySemanticsLabel('Error'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Error'));
    await tester.pump();
    expect(find.text('A PNG file is required'), findsOneWidget);

    final png = _png(192, 192);
    await tester.runAsync(() async {
      final codec = await ui.instantiateImageCodec(png);
      final frame = await codec.getNextFrame();
      expect(frame.image.width, 192);
      expect(frame.image.height, 192);
      frame.image.dispose();
      codec.dispose();
    });
    files.nextPick = png;
    await tester.tap(find.bySemanticsLabel('Upload avatar'));
    await _until(tester, () => model.vault.iconPng != null);
    expect(model.vault.iconPng, base64.encode(png));
    expect(find.bySemanticsLabel('Error'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(ClipOval), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('pepe'), findsOneWidget);
    expect(find.bySemanticsLabel('Login'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Back'));
    await tester.pumpAndSettle();
    final home = tester.getSemantics(find.bySemanticsLabel('pepe'));
    expect(home.value, mark);
    expect(find.bySemanticsLabel('Account'), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byType(ClipOval), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 50; i++) {
    if (ready()) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
  fail('timed out');
}

Uint8List _png(int width, int height) {
  final raw = BytesBuilder();
  for (var y = 0; y < height; y++) {
    raw.addByte(0);
    for (var x = 0; x < width; x++) {
      raw.addByte(220);
      raw.addByte(30);
      raw.addByte(30);
    }
  }
  final out = BytesBuilder();
  out.add(const [137, 80, 78, 71, 13, 10, 26, 10]);
  final header = ByteData(13);
  header.setUint32(0, width);
  header.setUint32(4, height);
  header.setUint8(8, 8);
  header.setUint8(9, 2);
  out.add(_chunk('IHDR', header.buffer.asUint8List()));
  out.add(_chunk('IDAT', Uint8List.fromList(zlib.encode(raw.takeBytes()))));
  out.add(_chunk('IEND', Uint8List(0)));
  return out.takeBytes();
}

Uint8List _chunk(String type, Uint8List data) {
  final typeBytes = ascii.encode(type);
  final crc = ByteData(4)..setUint32(0, _crc32([...typeBytes, ...data]));
  final length = ByteData(4)..setUint32(0, data.length);
  return Uint8List.fromList([
    ...length.buffer.asUint8List(),
    ...typeBytes,
    ...data,
    ...crc.buffer.asUint8List(),
  ]);
}

int _crc32(List<int> data) {
  var crc = 0xffffffff;
  for (final byte in data) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      if ((crc & 1) == 1) {
        crc = (crc >> 1) ^ 0xedb88320;
      } else {
        crc >>= 1;
      }
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}
