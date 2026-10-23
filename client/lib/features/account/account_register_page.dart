import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../account/identity.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../navigation/sections.dart';
import 'account_nav.dart';
import 'error_reader.dart';

class AccountRegisterPage extends StatefulWidget {
  const AccountRegisterPage({super.key});

  @override
  State<AccountRegisterPage> createState() => _AccountRegisterPageState();
}

class _AccountRegisterPageState extends State<AccountRegisterPage> {
  String? _failure;
  var _failureOpen = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (AppScope.of(context).vault.hasKey) context.go('/people');
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final color = sectionById('people')?.color ?? const Color(0xFFFF3333);
    final slots = <HexSlot>[
      HexSlot(
        id: 'generate',
        title: accountText(language, 'Генерация ключа', 'Generate key'),
        color: _busy ? const Color(0xFFFFFFFF) : color,
        q: 0,
        r: -1,
        icon: 'assets/icons/key_gen.svg',
        iconScale: 1.4,
      ),
      HexSlot(
        id: 'back',
        title: accountText(language, 'Назад', 'Back'),
        color: const Color(0xFFA1A1AA),
        q: 0,
        r: 0,
        icon: 'assets/icons/back.svg',
      ),
    ];
    if (_failure != null) {
      slots.add(
        HexSlot(
          id: 'error',
          title: accountText(language, 'Ошибка', 'Error'),
          color: color,
          titleColor: color,
          q: 1,
          r: -1,
          icon: 'assets/icons/error.svg',
          iconScale: 1.35,
          body: _failureOpen
              ? ErrorCell(
                  message: _failure!,
                  copyLabel: accountText(language, 'Скопировать', 'Copy'),
                  color: color,
                )
              : null,
        ),
      );
    }
    return ColoredBox(
      color: sceneBackground,
      child: HexScene(slots: slots, onTap: (id) => _tap(id, language)),
    );
  }

  Future<void> _tap(String id, String language) async {
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _failureOpen = true);
      case 'generate':
        await _generate(language);
    }
  }

  Future<void> _generate(String language) async {
    if (_busy) return;
    final model = AppScope.of(context);
    setState(() => _busy = true);
    try {
      final (publicKey, secretKey) = await compute(generateMlDsa87KeyPair, 0);
      if (!mounted) return;
      await model.adoptIdentity(
        Identity(publicKey: publicKey, secretKey: secretKey),
      );
      if (!mounted) return;
      context.pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = accountText(
          language,
          'Не удалось создать ключ',
          'The key could not be created',
        );
        _failureOpen = false;
      });
    }
  }
}
