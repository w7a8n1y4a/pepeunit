import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../hex_page.dart';
import 'line_cell.dart';
import 'network_chrome.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
  String? _failure;
  var _failureOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      AppScope.of(context).refreshTarget();
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = networkColor;
    final target = model.target;
    final failure = _failure ?? model.networkFailure;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = networkBoard(target: target?.url, wide: wide);
    final slots = [
      for (final slot in board.slots) _slot(slot, model, language, color),
    ];
    appendError(
      slots,
      message: failure,
      open: _failureOpen,
      language: language,
      text: netText,
      wide: wide,
    );
    return HexPage(slots: slots, onTap: _tap);
  }

  HexSlot _slot(BoardSlot slot, AppModel model, String language, Color color) {
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: netText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'search':
        final text = model.query.text.trim();
        return HexSlot(
          id: 'search',
          title: netText(language, 'Поиск пиров', 'Search peers'),
          footer: text.isEmpty ? null : text,
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/search.svg',
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
      case 'address':
        return HexSlot(
          id: 'address',
          title: netText(language, 'Адрес', 'Address'),
          color: color,
          q: slot.q,
          r: slot.r,
          body: LineCell(
            hint: 'host',
            color: color,
            error: _failure,
            onSubmit: (value) => _select(value),
          ),
        );
      case 'target':
        final url = slot.url!;
        return instanceMark(
          id: 'open:$url',
          url: url,
          language: language,
          q: slot.q,
          r: slot.r,
          color: color,
          current: true,
          version: model.portraitOf(url)?.version,
          image: model.iconOf(url),
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

  Future<void> _tap(String id) async {
    if (id.startsWith('open:')) {
      final url = id.substring(5);
      context.push('/peers/instance?url=${Uri.encodeQueryComponent(url)}');
      return;
    }
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'search':
        context.push('/peers/search');
      case 'settings':
        context.push('/peers/lists');
      case 'error':
        setState(() => _failureOpen = true);
    }
  }

  Future<void> _select(String raw) async {
    final model = AppScope.of(context);
    try {
      await model.selectTarget(raw);
      if (!mounted) return;
      setState(() {
        _failure = null;
        _failureOpen = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _failure = '$error';
        _failureOpen = false;
      });
    }
  }
}
