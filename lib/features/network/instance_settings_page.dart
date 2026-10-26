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
  var _busy = false;
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
    final staff = target?.managesPeers ?? false;
    final portrait = target == null ? null : model.portraitOf(target.url);
    final federation = portrait?.federation != false;

    final ids = tuneActions(owner: owner, staff: staff, federation: federation);
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
          enable: !_busy,
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
    final active = busyColor(_busy, color);
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: netText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'identity':
        return instanceMark(
          id: 'identity',
          url: targetUrl,
          language: language,
          q: slot.q,
          r: slot.r,
          color: color,
          current: true,
          version: portrait?.version,
          image: targetUrl.isEmpty ? null : model.iconOf(targetUrl),
          tappable: false,
        );
      case 'icon':
        final image = targetUrl.isEmpty ? null : model.iconOf(targetUrl);
        return HexSlot(
          id: 'icon',
          title: netText(language, 'Аватар инстанса', 'Instance icon'),
          footer: portrait?.version,
          color: busyColor(_busy || _dragHot, color),
          q: slot.q,
          r: slot.r,
          icon: image == null ? 'assets/icons/icon_load.svg' : null,
          image: image,
          iconScale: 1.15,
        );
      case 'ops':
        return HexSlot(
          id: 'ops',
          title: netText(language, 'Операции', 'Operations'),
          footer: portrait?.testsStatus,
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/power.svg',
        );
      case 'flags':
        return HexSlot(
          id: 'flags',
          title: netText(language, 'Флаги', 'Flags'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/check.svg',
        );
      case 'tests':
        return HexSlot(
          id: 'tests',
          title: netText(language, 'Тесты', 'Tests'),
          footer: portrait?.testsStatus,
          color: active,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/reload.svg',
        );
      case 'scan-all':
        return HexSlot(
          id: 'scan-all',
          title: netText(language, 'Опросить все', 'Scan all'),
          color: active,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/instances.svg',
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
    final model = AppScope.of(context);
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'icon':
        if (owner) await _pick(language);
      case 'tests':
        await _run(model.runIntegrationTests);
      case 'scan-all':
        await _run(model.scanAll);
      case 'ops':
      case 'flags':
      case 'core':
      case 'services':
      case 'transport':
        context.push('/peers/tune/$id');
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
      _open = false;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => _busy = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = '$error';
      });
    }
  }

  Future<void> _pick(String language) async {
    if (_busy) return;
    final model = AppScope.of(context);
    final bytes = await model.files.pick(
      dialogTitle: netText(language, 'Картинка инстанса', 'Instance picture'),
    );
    if (bytes == null || !mounted) return;
    await _accept(bytes, language);
  }

  Future<void> _dropped(DropDoneDetails detail, String language) async {
    if (_dragHot) setState(() => _dragHot = false);
    if (_busy || detail.files.isEmpty) return;
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
    await _run(() => AppScope.of(context).setInstanceIcon(bytes));
  }
}
