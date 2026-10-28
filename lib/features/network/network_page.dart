import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../hex_page.dart';
import 'network_chrome.dart';

class NetworkPage extends StatefulWidget {
  const NetworkPage({super.key});

  @override
  State<NetworkPage> createState() => _NetworkPageState();
}

class _NetworkPageState extends State<NetworkPage> {
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
    final failure = model.networkFailure;
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
          title: netText(language, 'Поиск инстансов', 'Search instances'),
          footer: text.isEmpty ? null : text,
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/search.svg',
        );
      case 'idle':
        return HexSlot(
          id: 'idle',
          title: netText(language, 'Найди инстанс', 'Find instance'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/exclaim.svg',
          tappable: false,
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
      case 'error':
        setState(() => _failureOpen = true);
    }
  }
}
