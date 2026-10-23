import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/account/identity.dart';
import 'package:pepeunit_client/account/key_file_port.dart';
import 'package:pepeunit_client/account/secret_key_file.dart';
import 'package:pepeunit_client/account/vault.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/api/backend_version.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/instances/instance.dart';
import 'package:pepeunit_client/main.dart';
import 'package:pqcrypto/pqcrypto.dart';

void main() {
  test('backend window is 1.5', () {
    expect(backendCompatible('1.5.0'), isTrue);
    expect(backendCompatible('1.5.9'), isTrue);
    expect(backendCompatible('1.4.9'), isFalse);
    expect(backendCompatible('1.6.0'), isFalse);
  });

  test('fresh vault keeps the local instance', () {
    final vault = Vault.fresh();
    final restored = Vault.decode(vault.encode());
    expect(restored.instances.single.url, defaultInstanceUrl);
    expect(restored.instances.single.active, isTrue);
    expect(restored.language, 'ru');
  });

  test('stored localunit moves to devunit', () {
    final vault = Vault.fromJson({
      'instances': [
        {'url': 'https://localunit.pepeunit.com', 'active': true},
      ],
    });
    expect(vault.instances.single.url, defaultInstanceUrl);
    expect(vault.instances.single.active, isTrue);
  });

  test('instance url drops a trailing path', () {
    expect(
      normalizeInstanceUrl('https://devunit.pepeunit.com/pepeunit/docs'),
      'https://devunit.pepeunit.com',
    );
  });

  testWidgets('home opens a section and comes back', (tester) async {
    final model = AppModel(store: MemoryVaultStore());
    await model.load();
    await tester.pumpWidget(AppScope(model: model, child: const PepeunitApp()));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Аккаунт'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Устройства'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Назад'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Аккаунт'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel('Аккаунт'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Вход'), findsOneWidget);
    expect(find.bySemanticsLabel('Регистрация'), findsOneWidget);
    expect(find.bySemanticsLabel('Назад'), findsOneWidget);
    expect(find.bySemanticsLabel('Аккаунт'), findsNothing);
    expect(find.bySemanticsLabel('Скоро'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Назад'));
    await tester.pumpAndSettle();
    expect(find.bySemanticsLabel('Аккаунт'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('secret key file round-trips and the public key is derived', () {
    final identity = Identity.generate();
    final derived = deriveMlDsa87Public(identity.secretKey);
    expect(derived, isNotNull);
    expect(derived!.$1, identity.publicKey);
    final signature = identity.signChallenge('pepeunit');
    expect(
      MlDsa.verify(
        derived.$1,
        Uint8List.fromList(utf8.encode('pepeunit')),
        signature,
        DilithiumParams.mlDsa87,
      ),
      isTrue,
    );
    final broken = Uint8List.fromList(identity.secretKey);
    broken[200] ^= 0xff;
    expect(deriveMlDsa87Public(broken), isNull);
    expect(deriveMlDsa87Public(Uint8List(8)), isNull);

    final file = Uint8List.fromList(
      utf8.encode(encodeSecretKeyFile(identity.secretKey)),
    );
    expect(decodeSecretKeyFile(file), identity.secretKey);
    expect(
      decodeSecretKeyFile(Uint8List.fromList(utf8.encode('nope'))),
      isNull,
    );
    expect(decodeSecretKeyFile(Uint8List(0)), isNull);
  });

  test('sign out clears keys, profile and instance sessions', () async {
    final store = MemoryVaultStore();
    final model = AppModel(store: store, files: MemoryKeyFilePort());
    await model.load();
    model.vault.login = 'pepe';
    model.vault.iconPng = 'png';
    model.vault.language = 'en';
    model.vault.instances.first.token = 'token';
    model.vault.instances.first.userUuid = 'user';
    await model.adoptIdentity(
      Identity(
        publicKey: Uint8List.fromList([1]),
        secretKey: Uint8List.fromList([2]),
      ),
    );
    await model.signOut();
    expect(model.vault.hasKey, isFalse);
    expect(model.vault.login, isEmpty);
    expect(model.vault.iconPng, isNull);
    expect(model.vault.language, 'en');
    expect(model.vault.instances.single.token, isNull);
    expect(model.vault.instances.single.userUuid, isNull);
    expect(model.vault.instances.single.url, defaultInstanceUrl);
    expect((await store.read()).hasKey, isFalse);
  });

  testWidgets('registration and key login stay on the client', (tester) async {
    final files = MemoryKeyFilePort();
    final model = AppModel(store: MemoryVaultStore(), files: files);
    await model.load();
    await tester.pumpWidget(AppScope(model: model, child: const PepeunitApp()));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Аккаунт'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Регистрация'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Генерация ключа'));
    await _waitFor(tester, 'Настройки');

    expect(model.vault.hasKey, isTrue);
    expect(find.bySemanticsLabel('Вход'), findsNothing);
    expect(find.bySemanticsLabel('Отправить в сеть'), findsOneWidget);
    expect(find.bySemanticsLabel('Ключ'), findsOneWidget);
    expect(find.bySemanticsLabel('Выход'), findsOneWidget);
    final secret = base64.decode(model.vault.secretKey!);
    final publicKey = model.vault.publicKey;

    await tester.tap(find.bySemanticsLabel('Ключ'));
    await _until(tester, () => files.saved != null);
    expect(files.savedName, secretKeyFileName);
    expect(decodeSecretKeyFile(files.saved!), secret);

    await tester.tap(find.bySemanticsLabel('Выход'));
    await _waitFor(tester, 'Вход');
    expect(model.vault.hasKey, isFalse);
    expect(find.bySemanticsLabel('Регистрация'), findsOneWidget);
    expect(find.bySemanticsLabel('Настройки'), findsNothing);

    files.nextPick = files.saved;
    await tester.tap(find.bySemanticsLabel('Вход'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Загрузка ключа'));
    await _waitFor(tester, 'Настройки');
    expect(model.vault.publicKey, publicKey);
    expect(base64.decode(model.vault.secretKey!), secret);

    await tester.tap(find.bySemanticsLabel('Выход'));
    await _waitFor(tester, 'Вход');
    files.nextPick = Uint8List.fromList(const [1, 2, 3]);
    await tester.tap(find.bySemanticsLabel('Вход'));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel('Загрузка ключа'));
    await _waitFor(tester, 'Ошибка');
    expect(find.text('Это не приватный ключ ML-DSA-87'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Ошибка'));
    await tester.pump();
    expect(find.byType(SelectableText), findsOneWidget);
    expect(find.text('Это не приватный ключ ML-DSA-87'), findsOneWidget);
    expect(find.bySemanticsLabel('Загрузка ключа'), findsOneWidget);
    expect(find.bySemanticsLabel('Назад'), findsOneWidget);

    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    await tester.tap(find.bySemanticsLabel('Скопировать'));
    await tester.pump();
    expect(copied, 'Это не приватный ключ ML-DSA-87');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );

    files.nextPick = Uint8List(0);
    await tester.tap(find.bySemanticsLabel('Загрузка ключа'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Это не приватный ключ ML-DSA-87'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Ошибка'));
    await tester.pump();
    expect(find.text('Файл пустой'), findsOneWidget);
    expect(find.bySemanticsLabel('Загрузка ключа'), findsOneWidget);
    expect(tester.takeException(), isNull);
  }, timeout: const Timeout(Duration(minutes: 3)));
}

Future<void> _waitFor(WidgetTester tester, String label) {
  return _until(
    tester,
    () => find.bySemanticsLabel(label).evaluate().isNotEmpty,
  );
}

Future<void> _until(WidgetTester tester, bool Function() ready) async {
  for (var i = 0; i < 400; i++) {
    if (ready()) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
  fail('timed out');
}
