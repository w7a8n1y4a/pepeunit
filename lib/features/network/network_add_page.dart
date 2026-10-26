import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_order.dart';
import '../../hive/hex_scene.dart';
import '../../navigation/back.dart';
import '../hex_page.dart';
import 'line_cell.dart';
import 'network_chrome.dart';

class NetworkAddPage extends StatefulWidget {
  const NetworkAddPage({super.key});

  @override
  State<NetworkAddPage> createState() => _NetworkAddPageState();
}

class _NetworkAddPageState extends State<NetworkAddPage> {
  String? _failure;
  var _open = false;
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = busyColor(_busy, networkColor);
    final wide = hexWide(MediaQuery.sizeOf(context));
    final frame = hexFrame(count: 1, back: HexBack.center, wide: wide);
    final url = frame.cells.first;
    final backAt = frame.back!;
    final slots = <HexSlot>[
      HexSlot(
        id: 'url',
        title: netText(language, 'Ссылка current', 'Current link'),
        color: color,
        q: url.$1,
        r: url.$2,
        body: LineCell(
          hint: '/instances/current',
          color: networkColor,
          onSubmit: _submit,
        ),
      ),
      backSlot(
        title: netText(language, 'Назад', 'Back'),
        q: backAt.$1,
        r: backAt.$2,
      ),
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
      onTap: (id) {
        if (id == 'back') popOrHome(context);
        if (id == 'error') setState(() => _open = true);
      },
    );
  }

  Future<void> _submit(String value) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
      _open = false;
    });
    try {
      await AppScope.of(context).createPeer(value);
      if (!mounted) return;
      context.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = '$error';
      });
    }
  }
}
