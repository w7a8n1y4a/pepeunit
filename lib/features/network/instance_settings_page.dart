import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
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
      for (final slot in placed) _slot(slot, language, color),
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: netText,
      wide: wide,
    );
    return HexPage(slots: slots, onTap: _tap);
  }

  HexSlot _slot(BoardSlot slot, String language, Color color) {
    final targetUrl = AppScope.of(context).target?.url ?? '';
    final portrait = targetUrl.isEmpty
        ? null
        : AppScope.of(context).portraitOf(targetUrl);
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: netText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'settings':
        return HexSlot(
          id: 'settings',
          title: netText(language, 'Настройки', 'Settings'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/settings.svg',
        );
      case 'ops':
        return HexSlot(
          id: 'ops',
          title: netText(language, 'Команды', 'Commands'),
          footer: portrait?.testsStatus,
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/terminal.svg',
        );
      default:
        return HexSlot(
          id: slot.id,
          title: slot.id,
          color: color,
          q: slot.q,
          r: slot.r,
        );
    }
  }

  void _tap(String id) {
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'settings':
        context.push('/peers/tune/settings');
      case 'ops':
        context.push('/peers/tune/ops');
    }
  }
}
