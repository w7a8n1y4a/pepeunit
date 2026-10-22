import 'package:flutter_test/flutter_test.dart';
import 'package:pepeunit_client/account/vault.dart';
import 'package:pepeunit_client/account/vault_store.dart';
import 'package:pepeunit_client/api/backend_version.dart';
import 'package:pepeunit_client/app_model.dart';
import 'package:pepeunit_client/app_scope.dart';
import 'package:pepeunit_client/instances/instance.dart';
import 'package:pepeunit_client/main.dart';

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
}
