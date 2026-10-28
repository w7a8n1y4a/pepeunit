import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../account/alerts.dart';
import '../../account/icon_file.dart';
import '../../app_scope.dart';
import '../../hive/hex_order.dart';
import '../../hive/hex_scene.dart';
import '../../locale/languages.dart';
import '../../navigation/sections.dart';
import '../file_drop.dart';
import '../hex_page.dart';
import 'account_nav.dart';
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
  String? _pending;
  var _dragHot = false;
  Timer? _cooldown;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!AppScope.of(context).vault.hasKey) {
        context.go('/people');
        return;
      }
      _watchCooldown();
    });
  }

  @override
  void dispose() {
    _cooldown?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = peopleColor;
    final png = iconBytes(model.vault.iconPng);
    final iconColor = dropColor(_dragHot, color);
    final failure = _report ?? iconProblemText(_failure, language);
    final wide = hexWide(MediaQuery.sizeOf(context));
    final waiting = _pending == 'sync';
    final ready = model.canSendProfile;
    final cooling = model.profileCooldownLeft;
    final frame = hexFrame(count: 5, back: HexBack.center, wide: wide);
    final spot = frame.cells;
    final backAt = frame.back!;
    final slots = <HexSlot>[
      HexSlot(
        id: 'icon',
        title: phrase(language, {
          'ru': 'Загрузить аватар',
          'en': 'Upload avatar',
        }),
        color: iconColor,
        busy: _pending == 'icon',
        q: spot[0].$1,
        r: spot[0].$2,
        icon: png == null ? 'assets/icons/icon_load.svg' : null,
        image: png,
        iconScale: 1.15,
      ),
      HexSlot(
        id: 'login',
        title: phrase(language, {'ru': 'Изменить логин', 'en': 'Change login'}),
        color: color,
        q: spot[1].$1,
        r: spot[1].$2,
        body: LoginCell(color: color),
      ),
      backSlot(
        title: phrase(language, {'ru': 'Назад', 'en': 'Back'}),
        q: backAt.$1,
        r: backAt.$2,
      ),
      HexSlot(
        id: 'sync',
        title: phrase(language, {
          'ru': 'Отправить в избранный',
          'en': 'Send to favorite',
        }),
        footer: !waiting && cooling > Duration.zero
            ? cooldownClock(cooling)
            : null,
        color: waiting || ready ? color : hexMuted,
        enabled: waiting || ready,
        busy: waiting,
        q: spot[2].$1,
        r: spot[2].$2,
        icon: 'assets/icons/rocket.svg',
        iconScale: 1.45,
      ),
      HexSlot(
        id: 'parameters',
        title: phrase(language, {'ru': 'Приложение', 'en': 'Application'}),
        color: color,
        q: spot[3].$1,
        r: spot[3].$2,
        body: const ParametersCell(),
      ),
      HexSlot(
        id: 'alerts',
        title: phrase(language, {'ru': 'Уведомления', 'en': 'Notifications'}),
        color: color,
        q: spot[4].$1,
        r: spot[4].$2,
        icon: 'assets/icons/notifications.svg',
      ),
    ];
    appendError(
      slots,
      message: failure,
      open: _failureOpen,
      language: language,
      text: accountText,
      wide: wide,
    );
    return HexPage(
      slots: slots,
      onTap: (id) => _tap(id, language),
      wrap: (slot, child) {
        if (slot.id != 'icon') return child;
        return FileDrop(
          enable: _pending == null,
          hot: _dragHot,
          onHot: (hot) => setState(() => _dragHot = hot),
          onDrop: _dropped,
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
      case 'icon':
        await _pick(language);
      case 'login':
      case 'parameters':
        break;
      case 'alerts':
        context.push('/people/settings/alerts');
      case 'sync':
        await _sync(language);
    }
  }

  Future<void> _pick(String language) async {
    if (_pending != null) return;
    final model = AppScope.of(context);
    setState(() => _pending = 'icon');
    try {
      final bytes = await model.files.pick(
        dialogTitle: phrase(language, {
          'ru': 'Выбрать иконку',
          'en': 'Choose an icon',
        }),
      );
      if (!mounted) return;
      if (bytes == null) {
        setState(() => _pending = null);
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
    if (_pending != null || detail.files.isEmpty) return;
    setState(() => _pending = 'icon');
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
      _pending = null;
      _failure = null;
      _report = null;
      _failureOpen = false;
    });
  }

  Future<void> _sync(String language) async {
    final model = AppScope.of(context);
    if (_pending != null || !model.canSendProfile) return;
    setState(() {
      _pending = 'sync';
      _failure = null;
      _report = null;
      _failureOpen = false;
    });
    final report = await model.broadcast();
    if (!mounted) return;
    final String? message;
    if (report.empty) {
      message = phrase(language, {'ru': 'Нет избранного', 'en': 'No favorite'});
    } else if (report.problems.isNotEmpty) {
      message = report.problems.join('\n');
    } else {
      message = null;
    }
    setState(() {
      _pending = null;
      _report = message;
    });
    _watchCooldown();
  }

  void _watchCooldown() {
    _cooldown?.cancel();
    if (!mounted || AppScope.of(context).profileCooldownLeft == Duration.zero) {
      _cooldown = null;
      return;
    }
    _cooldown = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (AppScope.of(context).profileCooldownLeft == Duration.zero) {
        _cooldown?.cancel();
        _cooldown = null;
      }
    });
  }

  void _fail(String reason) {
    setState(() {
      _pending = null;
      _failure = reason;
      _report = null;
      _failureOpen = false;
    });
  }
}
