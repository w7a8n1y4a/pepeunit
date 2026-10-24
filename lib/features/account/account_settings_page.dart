import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../account/icon_file.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../locale/languages.dart';
import '../../navigation/sections.dart';
import 'account_nav.dart';
import 'error_reader.dart';
import 'login_cell.dart';
import 'parameters_cell.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  String? _failure;
  String? _report;
  var _failureOpen = false;
  var _busy = false;
  var _dragHot = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!AppScope.of(context).vault.hasKey) context.go('/people');
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = sectionById('people')?.color ?? const Color(0xFFFF3333);
    final png = iconBytes(model.vault.iconPng);
    final iconColor = _busy || _dragHot ? const Color(0xFFFFFFFF) : color;
    final muted = const Color(0xFFA1A1AA);
    final failure = _report ?? _failureText(language);
    final slots = <HexSlot>[
      HexSlot(
        id: 'icon',
        title: phrase(language, {
          'ru': 'Загрузить аватар',
          'en': 'Upload avatar',
        }),
        color: iconColor,
        q: 0,
        r: -1,
        icon: png == null ? 'assets/icons/icon_load.svg' : null,
        image: png,
        iconScale: 1.15,
      ),
      HexSlot(
        id: 'login',
        title: phrase(language, {'ru': 'Изменить логин', 'en': 'Change login'}),
        color: color,
        q: 1,
        r: -1,
        body: LoginCell(color: color),
      ),
      HexSlot(
        id: 'back',
        title: phrase(language, {'ru': 'Назад', 'en': 'Back'}),
        color: muted,
        q: 0,
        r: 0,
        icon: 'assets/icons/back.svg',
      ),
      HexSlot(
        id: 'sync',
        title: phrase(language, {
          'ru': 'Отправить в сеть',
          'en': 'Send to network',
        }),
        color: _busy ? const Color(0xFFFFFFFF) : color,
        q: 0,
        r: 1,
        icon: 'assets/icons/rocket.svg',
        iconScale: 1.45,
      ),
      HexSlot(
        id: 'parameters',
        title: phrase(language, {'ru': 'Параметры', 'en': 'Parameters'}),
        color: color,
        q: -1,
        r: 1,
        body: const ParametersCell(),
      ),
    ];
    if (failure != null) {
      slots.add(
        HexSlot(
          id: 'error',
          title: phrase(language, {'ru': 'Ошибка', 'en': 'Error'}),
          color: errorColor,
          titleColor: errorColor,
          q: -1,
          r: 0,
          icon: 'assets/icons/error.svg',
          iconScale: 1.62,
          body: _failureOpen
              ? ErrorCell(
                  message: failure,
                  copyLabel: phrase(language, {
                    'ru': 'Скопировать',
                    'en': 'Copy',
                  }),
                )
              : null,
        ),
      );
    }
    return ColoredBox(
      color: sceneBackground,
      child: HexScene(
        slots: slots,
        onTap: (id) => _tap(id, language),
        wrap: (slot, child) {
          if (slot.id != 'icon') return child;
          return DropTarget(
            enable: !_busy,
            onDragEntered: (_) {
              if (!_dragHot) setState(() => _dragHot = true);
            },
            onDragExited: (_) {
              if (_dragHot) setState(() => _dragHot = false);
            },
            onDragDone: _dropped,
            child: child,
          );
        },
      ),
    );
  }

  String? _failureText(String language) {
    switch (_failure) {
      case 'empty':
        return phrase(language, {
          'ru': 'Файл пустой',
          'en': 'The file is empty',
        });
      case 'large':
        return phrase(language, {
          'ru': 'Картинка больше 128 КБ',
          'en': 'The picture is larger than 128 KB',
        });
      case 'png':
        return phrase(language, {
          'ru': 'Нужен файл PNG',
          'en': 'A PNG file is required',
        });
      case 'size':
        return phrase(language, {
          'ru': 'Нужен размер 192x192',
          'en': 'The picture must be 192x192',
        });
      case 'read':
        return phrase(language, {
          'ru': 'Не удалось прочитать файл',
          'en': 'The file could not be read',
        });
      default:
        return null;
    }
  }

  Future<void> _tap(String id, String language) async {
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _failureOpen = true);
      case 'icon':
        await _pick(language);
      case 'login':
      case 'parameters':
        break;
      case 'sync':
        await _sync(language);
    }
  }

  Future<void> _pick(String language) async {
    if (_busy) return;
    final model = AppScope.of(context);
    setState(() => _busy = true);
    try {
      final bytes = await model.files.pick(
        dialogTitle: phrase(language, {
          'ru': 'Выбрать иконку',
          'en': 'Choose an icon',
        }),
      );
      if (!mounted) return;
      if (bytes == null) {
        setState(() => _busy = false);
        return;
      }
      await _accept(bytes);
    } catch (_) {
      if (!mounted) return;
      _fail('read');
    }
  }

  Future<void> _dropped(DropDoneDetails detail) async {
    if (_dragHot) setState(() => _dragHot = false);
    if (_busy || detail.files.isEmpty) return;
    setState(() => _busy = true);
    try {
      final bytes = await detail.files.first.readAsBytes();
      if (!mounted) return;
      await _accept(bytes);
    } catch (_) {
      if (!mounted) return;
      _fail('read');
    }
  }

  Future<void> _accept(Uint8List bytes) async {
    final problem = iconProblem(bytes);
    if (problem != null) {
      _fail(problem);
      return;
    }
    final model = AppScope.of(context);
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final matches = image.width == iconSide && image.height == iconSide;
      image.dispose();
      codec.dispose();
      if (!mounted) return;
      if (!matches) {
        _fail('size');
        return;
      }
    } catch (_) {
      if (!mounted) return;
      _fail('png');
      return;
    }
    await model.setIcon(bytes);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _failure = null;
      _report = null;
      _failureOpen = false;
    });
  }

  Future<void> _sync(String language) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
      _report = null;
      _failureOpen = false;
    });
    final report = await AppScope.of(context).broadcast();
    if (!mounted) return;
    final String? message;
    if (report.empty) {
      message = phrase(language, {'ru': 'Нет инстансов', 'en': 'No instances'});
    } else if (report.problems.isNotEmpty) {
      message = report.problems.join('\n');
    } else {
      message = null;
    }
    setState(() {
      _busy = false;
      _report = message;
    });
  }

  void _fail(String reason) {
    setState(() {
      _busy = false;
      _failure = reason;
      _report = null;
      _failureOpen = false;
    });
  }
}
