import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../account/icon_file.dart';
import '../../account/key_mark.dart';
import '../../account/secret_key_file.dart';
import '../../app_scope.dart';
import '../../hive/hex_order.dart';
import '../../hive/hex_scene.dart';
import '../../navigation/sections.dart';
import '../hex_page.dart';
import 'account_nav.dart';

class AccountMenuPage extends StatefulWidget {
  const AccountMenuPage({super.key});

  @override
  State<AccountMenuPage> createState() => _AccountMenuPageState();
}

class _AccountMenuPageState extends State<AccountMenuPage> {
  String? _failure;
  var _failureOpen = false;
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = peopleColor;
    final back = accountText(language, 'Назад', 'Back');
    final wide = hexWide(MediaQuery.sizeOf(context));
    final slots = model.vault.hasKey
        ? _signedIn(language, color, back, wide)
        : _signedOut(language, color, back, wide);
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

  List<HexSlot> _signedOut(
    String language,
    Color color,
    String back,
    bool wide,
  ) {
    final frame = hexFrame(count: 2, back: HexBack.center, wide: wide);
    final spot = frame.cells;
    final backAt = frame.back!;
    return [
      HexSlot(
        id: 'login',
        title: accountText(language, 'Вход', 'Login'),
        color: color,
        q: spot[0].$1,
        r: spot[0].$2,
        icon: 'assets/icons/signin.svg',
      ),
      HexSlot(
        id: 'registration',
        title: accountText(language, 'Регистрация', 'Registration'),
        color: color,
        q: spot[1].$1,
        r: spot[1].$2,
        icon: 'assets/icons/registration.svg',
      ),
      backSlot(title: back, q: backAt.$1, r: backAt.$2),
    ];
  }

  List<HexSlot> _signedIn(
    String language,
    Color color,
    String back,
    bool wide,
  ) {
    final model = AppScope.of(context);
    final png = iconBytes(model.vault.iconPng);
    final login = model.vault.login;
    final frame = hexFrame(count: 4, back: HexBack.center, wide: wide);
    final spot = frame.cells;
    final backAt = frame.back!;
    return [
      HexSlot(
        id: 'profile',
        title: login.isEmpty ? accountText(language, 'Логин', 'Login') : login,
        color: color,
        q: spot[0].$1,
        r: spot[0].$2,
        icon: png == null ? 'assets/icons/account.svg' : null,
        image: png,
        tappable: false,
      ),
      HexSlot(
        id: 'settings',
        title: accountText(language, 'Настройки', 'Settings'),
        color: color,
        q: spot[1].$1,
        r: spot[1].$2,
        icon: 'assets/icons/settings.svg',
      ),
      HexSlot(
        id: 'key',
        title: accountText(language, 'Скачать ключ', 'Download key'),
        footer: keyMarkFromBase64(model.vault.publicKey),
        color: color,
        busy: _busy,
        q: spot[2].$1,
        r: spot[2].$2,
        icon: 'assets/icons/key.svg',
      ),
      HexSlot(
        id: 'signout',
        title: accountText(language, 'Выход', 'Sign out'),
        color: color,
        q: spot[3].$1,
        r: spot[3].$2,
        icon: 'assets/icons/signout.svg',
      ),
      backSlot(title: back, q: backAt.$1, r: backAt.$2),
    ];
  }

  Future<void> _tap(String id, String language) async {
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'login':
        context.push('/people/login');
      case 'registration':
        context.push('/people/register');
      case 'error':
        setState(() => _failureOpen = true);
      case 'signout':
        setState(() {
          _failure = null;
          _failureOpen = false;
        });
        await AppScope.of(context).signOut();
      case 'key':
        await _saveKey(language);
      case 'settings':
        context.push('/people/settings');
      case 'profile':
        break;
    }
  }

  Future<void> _saveKey(String language) async {
    if (_busy) return;
    final model = AppScope.of(context);
    final encoded = model.vault.secretKey;
    if (encoded == null) return;
    setState(() => _busy = true);
    try {
      final saved = await model.files.save(
        fileName: secretKeyFileName,
        bytes: Uint8List.fromList(
          utf8.encode(encodeSecretKeyFile(base64.decode(encoded))),
        ),
        dialogTitle: accountText(language, 'Сохранить ключ', 'Save the key'),
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (saved) {
          _failure = null;
          _failureOpen = false;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = accountText(
          language,
          'Не удалось записать ключ',
          'The key could not be saved',
        );
        _failureOpen = false;
      });
    }
  }
}
