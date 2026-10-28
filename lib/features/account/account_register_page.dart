import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../account/identity.dart';
import '../../app_scope.dart';
import '../../hive/hex_order.dart';
import '../../hive/hex_scene.dart';
import '../../navigation/sections.dart';
import '../hex_page.dart';
import 'account_nav.dart';

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
    final color = peopleColor;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final frame = hexFrame(count: 1, back: HexBack.center, wide: wide);
    final generate = frame.cells.first;
    final backAt = frame.back!;
    final slots = <HexSlot>[
      HexSlot(
        id: 'generate',
        title: accountText(language, 'Генерация ключа', 'Generate key'),
        color: color,
        busy: _busy,
        q: generate.$1,
        r: generate.$2,
        icon: 'assets/icons/key_gen.svg',
      ),
      backSlot(
        title: accountText(language, 'Назад', 'Back'),
        q: backAt.$1,
        r: backAt.$2,
      ),
    ];
    appendError(
      slots,
      message: _failure,
      open: _failureOpen,
      language: language,
      text: accountText,
      wide: wide,
    );
    return HexPage(slots: slots, onTap: (id) => _tap(id, language));
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
