import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../account/secret_key_file.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../navigation/sections.dart';
import 'account_nav.dart';
import 'error_reader.dart';

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
    final color = sectionById('people')?.color ?? const Color(0xFFFF3333);
    final back = accountText(language, 'Назад', 'Back');
    final slots = model.vault.hasKey
        ? _signedIn(language, color, back)
        : _signedOut(language, color, back);
    if (_failure != null) {
      slots.add(
        HexSlot(
          id: 'error',
          title: accountText(language, 'Ошибка', 'Error'),
          color: color,
          titleColor: color,
          q: -1,
          r: 0,
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

  List<HexSlot> _signedOut(String language, Color color, String back) {
    return [
      HexSlot(
        id: 'login',
        title: accountText(language, 'Вход', 'Login'),
        color: color,
        q: 0,
        r: -1,
        icon: 'assets/icons/signin.svg',
        iconScale: 1.2,
      ),
      HexSlot(
        id: 'registration',
        title: accountText(language, 'Регистрация', 'Registration'),
        color: color,
        q: 1,
        r: -1,
        icon: 'assets/icons/registration.svg',
      ),
      HexSlot(
        id: 'back',
        title: back,
        color: const Color(0xFFA1A1AA),
        q: 0,
        r: 0,
        icon: 'assets/icons/back.svg',
      ),
    ];
  }

  List<HexSlot> _signedIn(String language, Color color, String back) {
    final active = _busy ? const Color(0xFFFFFFFF) : color;
    return [
      HexSlot(
        id: 'back',
        title: back,
        color: const Color(0xFFA1A1AA),
        q: 0,
        r: 0,
        icon: 'assets/icons/back.svg',
      ),
      HexSlot(
        id: 'settings',
        title: accountText(language, 'Настройки', 'Settings'),
        color: color,
        q: 0,
        r: -1,
        icon: 'assets/icons/settings.svg',
        iconScale: 1.4,
      ),
      HexSlot(
        id: 'key',
        title: accountText(language, 'Ключ', 'Key'),
        color: active,
        q: 1,
        r: -1,
        icon: 'assets/icons/key.svg',
        iconScale: 1.4,
      ),
      HexSlot(
        id: 'signout',
        title: accountText(language, 'Выход', 'Sign out'),
        color: color,
        q: 0,
        r: 1,
        icon: 'assets/icons/signout.svg',
        iconScale: 1.08,
      ),
      HexSlot(
        id: 'sync',
        title: accountText(language, 'Отправить в сеть', 'Send to network'),
        color: color,
        q: -1,
        r: 1,
        icon: 'assets/icons/rocket.svg',
        iconScale: 1.45,
      ),
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
      case 'sync':
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
