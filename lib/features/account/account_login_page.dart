import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../account/identity.dart';
import '../../account/secret_key_file.dart';
import '../../app_scope.dart';
import '../../hive/hex_order.dart';
import '../../hive/hex_scene.dart';
import '../../navigation/sections.dart';
import '../file_drop.dart';
import '../hex_page.dart';
import 'account_nav.dart';

class AccountLoginPage extends StatefulWidget {
  const AccountLoginPage({super.key});

  @override
  State<AccountLoginPage> createState() => _AccountLoginPageState();
}

class _AccountLoginPageState extends State<AccountLoginPage> {
  String? _failure;
  var _failureOpen = false;
  var _busy = false;
  var _dragHot = false;

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
    final loadColor = busyColor(_busy || _dragHot, color);
    final wide = hexWide(MediaQuery.sizeOf(context));
    final frame = hexFrame(count: 1, back: HexBack.center, wide: wide);
    final load = frame.cells.first;
    final backAt = frame.back!;
    final slots = <HexSlot>[
      HexSlot(
        id: 'load',
        title: accountText(language, 'Загрузка ключа', 'Load key'),
        color: loadColor,
        q: load.$1,
        r: load.$2,
        icon: 'assets/icons/key_load.svg',
        iconScale: 1.2,
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
    return HexPage(
      slots: slots,
      onTap: (id) => _tap(id, language),
      wrap: (slot, child) {
        if (slot.id != 'load') return child;
        return FileDrop(
          enable: !_busy,
          hot: _dragHot,
          onHot: (hot) => setState(() => _dragHot = hot),
          onDrop: (detail) => _dropped(detail, language),
          child: child,
        );
      },
    );
  }

  Future<void> _tap(String id, String language) async {
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _failureOpen = true);
      case 'load':
        await _pick(language);
    }
  }

  Future<void> _pick(String language) async {
    if (_busy) return;
    final model = AppScope.of(context);
    setState(() => _busy = true);
    try {
      final bytes = await model.files.pick(
        dialogTitle: accountText(language, 'Выбрать ключ', 'Choose a key'),
      );
      if (!mounted) return;
      if (bytes == null) {
        setState(() => _busy = false);
        return;
      }
      await _accept(bytes, language);
    } catch (_) {
      if (!mounted) return;
      _fail(
        accountText(
          language,
          'Не удалось прочитать файл',
          'The file could not be read',
        ),
      );
    }
  }

  Future<void> _dropped(DropDoneDetails detail, String language) async {
    if (_dragHot) setState(() => _dragHot = false);
    if (_busy || detail.files.isEmpty) return;
    setState(() => _busy = true);
    try {
      final bytes = await detail.files.first.readAsBytes();
      if (!mounted) return;
      await _accept(bytes, language);
    } catch (_) {
      if (!mounted) return;
      _fail(
        accountText(
          language,
          'Не удалось прочитать файл',
          'The file could not be read',
        ),
      );
    }
  }

  Future<void> _accept(Uint8List bytes, String language) async {
    final model = AppScope.of(context);
    if (bytes.isEmpty) {
      _fail(accountText(language, 'Файл пустой', 'The file is empty'));
      return;
    }
    final secret = decodeSecretKeyFile(bytes);
    if (secret == null) {
      _fail(
        accountText(
          language,
          'Это не приватный ключ ML-DSA-87',
          'This is not an ML-DSA-87 private key',
        ),
      );
      return;
    }
    final derived = await compute(deriveMlDsa87Public, secret);
    if (!mounted) return;
    if (derived == null) {
      _fail(
        accountText(
          language,
          'Это не приватный ключ ML-DSA-87',
          'This is not an ML-DSA-87 private key',
        ),
      );
      return;
    }
    await model.adoptIdentity(
      Identity(publicKey: derived.$1, secretKey: derived.$2),
    );
    if (!mounted) return;
    context.pop();
  }

  void _fail(String message) {
    setState(() {
      _busy = false;
      _failure = message;
      _failureOpen = false;
    });
  }
}
