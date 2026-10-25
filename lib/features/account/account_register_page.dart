import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../account/identity.dart';
import '../../app_scope.dart';
import '../../hive/hex_order.dart';
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
    final wide = hexWide(MediaQuery.sizeOf(context));
    final frame = hexFrame(count: 1, back: HexBack.center, wide: wide);
    final generate = frame.cells.first;
    final backAt = frame.back!;
    final slots = <HexSlot>[
      HexSlot(
        id: 'generate',
        title: accountText(language, 'Генерация ключа', 'Generate key'),
        color: _busy ? const Color(0xFFFFFFFF) : color,
        q: generate.$1,
        r: generate.$2,
        icon: 'assets/icons/key_gen.svg',
        iconScale: 1.4,
      ),
      HexSlot(
        id: 'back',
        title: accountText(language, 'Назад', 'Back'),
        color: const Color(0xFFA1A1AA),
        q: backAt.$1,
        r: backAt.$2,
        icon: 'assets/icons/back.svg',
      ),
    ];
    if (_failure != null) {
      final spot = nextHex([
        for (final slot in slots) (slot.q, slot.r),
      ], wide: wide);
      slots.add(
        HexSlot(
          id: 'error',
          title: accountText(language, 'Ошибка', 'Error'),
          color: errorColor,
          titleColor: errorColor,
          q: spot.$1,
          r: spot.$2,
          icon: 'assets/icons/error.svg',
          iconScale: 1.62,
          body: _failureOpen
              ? ErrorCell(
                  message: _failure!,
                  copyLabel: accountText(language, 'Скопировать', 'Copy'),
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
