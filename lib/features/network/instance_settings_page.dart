import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../account/icon_file.dart';
import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../instances/settings_catalog.dart';
import '../../locale/languages.dart';
import '../../navigation/back.dart';
import '../file_drop.dart';
import '../hex_page.dart';
import 'network_chrome.dart';

/// Instance administration hub (`/peers/tune`).
///
/// Back stays in the center. The action list stays within the first ring.
class InstanceTunePage extends StatefulWidget {
  const InstanceTunePage({super.key});

  @override
  State<InstanceTunePage> createState() => _InstanceTunePageState();
}

class _InstanceTunePageState extends State<InstanceTunePage> {
  String? _failure;
  var _open = false;
  String? _pending;
  var _dragHot = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final model = AppScope.of(context);
      final target = model.target;
      if (target == null || !target.managesPeers) return;
      if (!target.ownsInstance) return;
      try {
        await model.loadSettings();
      } catch (error) {
        if (!mounted) return;
        setState(() => _failure = '$error');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = networkColor;
    final target = model.target;
    final owner = target?.ownsInstance ?? false;
    final ids = tuneActions(owner: owner);
    final wide = hexWide(MediaQuery.sizeOf(context));
    final frame = hexFrame(count: ids.length, back: HexBack.center, wide: wide);
    final back = frame.back!;
    final placed = <BoardSlot>[
      BoardSlot('back', back.$1, back.$2),
      for (var i = 0; i < ids.length && i < frame.cells.length; i++)
        BoardSlot(ids[i], frame.cells[i].$1, frame.cells[i].$2),
    ];
    final slots = <HexSlot>[
      for (final slot in placed) _slot(slot, model, language, color),
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: netText,
      wide: wide,
      iconScale: 1.2,
    );
    return HexPage(
      slots: slots,
      onTap: (id) => _tap(id, language, owner),
      wrap: (slot, child) {
        if (slot.id != 'icon' || !owner) return child;
        return FileDrop(
          enable: _pending == null,
          hot: _dragHot,
          onHot: (hot) => setState(() => _dragHot = hot),
          onDrop: (detail) => _dropped(detail, language),
          child: child,
        );
      },
    );
  }

  HexSlot _slot(BoardSlot slot, AppModel model, String language, Color color) {
    final targetUrl = model.target?.url ?? '';
    final portrait = targetUrl.isEmpty ? null : model.portraitOf(targetUrl);
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: netText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'icon':
        final image = targetUrl.isEmpty ? null : model.iconOf(targetUrl);
        return HexSlot(
          id: 'icon',
          title: netText(language, 'Загрузить аватар', 'Upload avatar'),
          footer: portrait?.version,
          color: dropColor(_dragHot, color),
          busy: _pending == 'icon',
          q: slot.q,
          r: slot.r,
          icon: image == null ? 'assets/icons/icon_load.svg' : null,
          image: image,
          iconScale: 1.15,
        );
      case 'settings':
        return HexSlot(
          id: 'settings',
          title: netText(language, 'Настройки', 'Settings'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/settings.svg',
          iconScale: 1.4,
        );
      case 'ops':
        return HexSlot(
          id: 'ops',
          title: netText(language, 'Команды', 'Commands'),
          footer: portrait?.testsStatus,
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/power.svg',
        );
      default:
        final group = settingGroup(slot.id);
        if (group != null) {
          return HexSlot(
            id: group.id,
            title: phrase(language, group.titles),
            color: color,
            q: slot.q,
            r: slot.r,
            icon: group.icon,
          );
        }
        return HexSlot(
          id: slot.id,
          title: slot.id,
          color: color,
          q: slot.q,
          r: slot.r,
        );
    }
  }

  Future<void> _tap(String id, String language, bool owner) async {
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'icon':
        if (owner) await _pick(language);
      case 'settings':
        context.push('/peers/tune/settings');
      case 'ops':
        context.push('/peers/tune/ops');
    }
  }

  Future<void> _run(String id, Future<void> Function() action) async {
    if (_pending != null) return;
    setState(() {
      _pending = id;
      _failure = null;
      _open = false;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => _pending = null);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
    }
  }

  Future<void> _pick(String language) async {
    if (_pending != null) return;
    final model = AppScope.of(context);
    final bytes = await model.files.pick(
      dialogTitle: netText(language, 'Картинка инстанса', 'Instance picture'),
    );
    if (bytes == null || !mounted) return;
    await _accept(bytes, language);
  }

  Future<void> _dropped(DropDoneDetails detail, String language) async {
    if (_dragHot) setState(() => _dragHot = false);
    if (_pending != null || detail.files.isEmpty) return;
    final bytes = await detail.files.first.readAsBytes();
    if (!mounted) return;
    await _accept(bytes, language);
  }

  Future<void> _accept(Uint8List bytes, String language) async {
    final problem = iconProblem(bytes);
    if (problem != null) {
      setState(() {
        _failure = iconProblemText(problem, language) ?? problem;
        _open = false;
      });
      return;
    }
    await _run('icon', () => AppScope.of(context).setInstanceIcon(bytes));
  }
}
