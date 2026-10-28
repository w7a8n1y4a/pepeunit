import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_order.dart';
import '../../hive/hex_scene.dart';
import '../../locale/languages.dart';
import '../../navigation/sections.dart';
import '../hex_page.dart';
import 'account_nav.dart';
import 'alert_time_cell.dart';

class AccountAlertsPage extends StatefulWidget {
  const AccountAlertsPage({super.key});

  @override
  State<AccountAlertsPage> createState() => _AccountAlertsPageState();
}

class _AccountAlertsPageState extends State<AccountAlertsPage> {
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
    final color = peopleColor;
    final alerts = model.vault.alerts;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final frame = hexFrame(count: 4, back: HexBack.center, wide: wide);
    final spot = frame.cells;
    final backAt = frame.back!;
    return HexPage(
      slots: [
        _toggle(
          id: 'scheduled',
          title: phrase(language, {'ru': 'Сводки', 'en': 'Summaries'}),
          on: alerts.scheduled,
          language: language,
          color: color,
          q: spot[0].$1,
          r: spot[0].$2,
        ),
        HexSlot(
          id: 'time',
          title: phrase(language, {'ru': 'Время UTC', 'en': 'UTC time'}),
          color: color,
          q: spot[1].$1,
          r: spot[1].$2,
          body: const AlertTimeCell(),
        ),
        _toggle(
          id: 'pipe',
          title: phrase(language, {'ru': 'DataPipe', 'en': 'DataPipe'}),
          on: alerts.dataPipe,
          language: language,
          color: color,
          q: spot[2].$1,
          r: spot[2].$2,
        ),
        _toggle(
          id: 'telegram',
          title: 'Telegram',
          on: alerts.telegram,
          language: language,
          color: color,
          q: spot[3].$1,
          r: spot[3].$2,
        ),
        backSlot(
          title: phrase(language, {'ru': 'Назад', 'en': 'Back'}),
          q: backAt.$1,
          r: backAt.$2,
        ),
      ],
      onTap: _tap,
    );
  }

  HexSlot _toggle({
    required String id,
    required String title,
    required bool on,
    required String language,
    required Color color,
    required int q,
    required int r,
  }) {
    return HexSlot(
      id: id,
      title: title,
      footer: phrase(language, {
        'ru': on ? 'вкл' : 'выкл',
        'en': on ? 'on' : 'off',
      }),
      color: on ? color : hexMuted,
      q: q,
      r: r,
      icon: on ? 'assets/icons/check.svg' : 'assets/icons/close.svg',
    );
  }

  Future<void> _tap(String id) async {
    final model = AppScope.of(context);
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'scheduled':
        await model.setScheduledAlerts(!model.vault.alerts.scheduled);
      case 'pipe':
        await model.setDataPipeAlerts(!model.vault.alerts.dataPipe);
      case 'telegram':
        await model.setTelegramAlerts(!model.vault.alerts.telegram);
      case 'time':
        break;
    }
  }
}
