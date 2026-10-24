import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../features/account/account_nav.dart';
import '../../features/account/error_reader.dart';
import '../../hive/hex_scene.dart';
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
    final color = _busy ? const Color(0xFFFFFFFF) : networkColor;
    final slots = <HexSlot>[
      HexSlot(
        id: 'url',
        title: netText(language, 'Ссылка current', 'Current link'),
        color: color,
        q: 0,
        r: -1,
        body: LineCell(
          hint: '/instances/current',
          color: networkColor,
          onSubmit: _submit,
        ),
      ),
      HexSlot(
        id: 'back',
        title: netText(language, 'Назад', 'Back'),
        color: hexMuted,
        q: 0,
        r: 0,
        icon: 'assets/icons/back.svg',
      ),
    ];
    if (_failure != null) {
      slots.add(
        HexSlot(
          id: 'error',
          title: netText(language, 'Ошибка', 'Error'),
          color: errorColor,
          titleColor: errorColor,
          q: 1,
          r: -1,
          icon: 'assets/icons/error.svg',
          iconScale: 1.2,
          body: _open
              ? ErrorCell(
                  message: _failure!,
                  copyLabel: netText(language, 'Скопировать', 'Copy'),
                )
              : null,
        ),
      );
    }
    return ColoredBox(
      color: sceneBackground,
      child: HexScene(
        slots: slots,
        onTap: (id) {
          if (id == 'back') popOrHome(context);
          if (id == 'error') setState(() => _open = true);
        },
      ),
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
