import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../units/unit.dart';
import '../../units/unit_view.dart';
import '../hex_page.dart';
import '../network/line_cell.dart';
import 'units_chrome.dart';

class UnitPage extends StatefulWidget {
  const UnitPage({required this.uuid, super.key});

  final String uuid;

  @override
  State<UnitPage> createState() => _UnitPageState();
}

class _UnitPageState extends State<UnitPage> {
  Unit? _unit;
  String? _failure;
  var _open = false;
  var _loading = true;
  var _current = false;
  var _seen = false;
  Timer? _poll;
  var _polls = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final now = ModalRoute.of(context)?.isCurrent ?? true;
    if (now && !_current && _seen) _load();
    _current = now;
  }

  @override
  void didUpdateWidget(UnitPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uuid == widget.uuid) return;
    _stop();
    _load();
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final unit = _unit;
    final owned = unitOwnedBy(unit?.creatorUuid ?? '', model.target?.userUuid);
    final placed = cardBoard(
      unitMenuIds(owned: owned, private: unit?.visibility == 'Private'),
      wide: wide,
    );
    final slots = <HexSlot>[
      for (final slot in placed) _slot(slot, language, model, unit, owned),
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: unitText,
      wide: wide,
    );
    return HexPage(slots: slots, onTap: (id) => _tap(id, unit));
  }

  HexSlot _slot(
    BoardSlot slot,
    String language,
    AppModel model,
    Unit? unit,
    bool owned,
  ) {
    final color = unitsColor;
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: unitText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'card':
        if (unit == null) {
          return HexSlot(
            id: 'card',
            title: unitText(language, 'Аппарат', 'Unit'),
            color: color,
            busy: _loading,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/micro.svg',
          );
        }
        return unitMark(
          id: 'card',
          unit: unit,
          language: language,
          q: slot.q,
          r: slot.r,
          image: model.cachedIcon(unit.iconUuid),
          busy: _loading || unit.firmwareStatus == 'RequestSent',
        );
      case 'summary':
        final pages = unit == null
            ? const <SummaryPage>[]
            : [
                for (final page in unitSheets(unit, language))
                  SummaryPage(title: page.title, lines: page.lines),
              ];
        return HexSlot(
          id: 'summary',
          title: unitText(language, 'Сводка', 'Summary'),
          color: color,
          q: slot.q,
          r: slot.r,
          tappable: false,
          body: MetricsCell(
            lines: pages.isEmpty ? const ['—'] : pages.first.lines,
            pages: pages,
            prevLabel: unitText(
              language,
              'Предыдущая сводка',
              'Previous summary',
            ),
            nextLabel: unitText(language, 'Следующая сводка', 'Next summary'),
          ),
        );
      case 'repo':
        return HexSlot(
          id: 'repo',
          title: unitText(language, 'Репозиторий', 'Repository'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/repo.svg',
        );
      case 'nodes':
        return HexSlot(
          id: 'nodes',
          title: unitText(language, 'Входы и выходы', 'Inputs and outputs'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/chain.svg',
        );
      case 'settings':
        return HexSlot(
          id: 'settings',
          title: unitText(language, 'Настройки', 'Settings'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/settings.svg',
        );
      case 'env':
        return HexSlot(
          id: 'env',
          title: unitText(language, 'Окружение', 'Environment'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/key.svg',
        );
      case 'operate':
        return HexSlot(
          id: 'operate',
          title: unitText(language, 'Работа', 'Operate'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/power.svg',
        );
      case 'access':
        return HexSlot(
          id: 'access',
          title: unitText(language, 'Доступы', 'Access'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/users.svg',
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

  Future<void> _tap(String id, Unit? unit) async {
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'card':
        await _load();
      case 'repo':
        final repo = unit?.repoUuid ?? '';
        if (repo.isEmpty) return;
        context.push('/registry/repo/$repo');
      case 'nodes':
        context.push('/units/${widget.uuid}/io');
      case 'settings':
        context.push('/units/${widget.uuid}/settings');
      case 'env':
        context.push('/units/${widget.uuid}/env');
      case 'operate':
        context.push('/units/${widget.uuid}/work');
      case 'access':
        context.push('/units/${widget.uuid}/access');
    }
  }

  Future<void> _load() async {
    final model = AppScope.of(context);
    final language = model.vault.language;
    if (model.target?.signedIn != true) {
      setState(() {
        _loading = false;
        _seen = true;
        _failure = unitText(language, 'Нет входа', 'Not signed in');
      });
      return;
    }
    setState(() {
      _loading = true;
      _failure = null;
      _open = false;
    });
    try {
      final unit = await model.readUnit(widget.uuid);
      if (!mounted) return;
      setState(() {
        _unit = unit;
        _loading = false;
        _seen = true;
      });
      _watch(unit);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _seen = true;
        _failure = '$error';
      });
    }
  }

  void _watch(Unit unit) {
    if (unit.firmwareStatus != 'RequestSent') {
      _stop();
      return;
    }
    if (_poll != null) return;
    _polls = 0;
    _poll = Timer.periodic(const Duration(seconds: 10), (_) => _again());
  }

  Future<void> _again() async {
    _polls++;
    if (_polls > 6) {
      _stop();
      if (mounted) setState(() {});
      return;
    }
    try {
      final unit = await AppScope.of(context).readUnit(widget.uuid);
      if (!mounted) return;
      setState(() => _unit = unit);
      if (unit.firmwareStatus != 'RequestSent') _stop();
    } catch (_) {}
  }

  void _stop() {
    _poll?.cancel();
    _poll = null;
  }
}

/// Commands, logs, firmware, schema, state storage and delete.
class UnitWorkPage extends StatefulWidget {
  const UnitWorkPage({required this.uuid, super.key});

  final String uuid;

  @override
  State<UnitWorkPage> createState() => _UnitWorkPageState();
}

class _UnitWorkPageState extends State<UnitWorkPage> {
  String? _failure;
  var _open = false;
  String? _pending;

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(unitOperateIds, wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        switch (slot.id) {
          'back' => backSlot(
            title: unitText(language, 'Назад', 'Back'),
            q: slot.q,
            r: slot.r,
          ),
          'commands' => _cell(
            slot,
            language,
            'Команды',
            'Commands',
            'send.svg',
          ),
          'logs' => _cell(slot, language, 'Логи', 'Logs', 'terminal.svg'),
          'firmware' => _cell(
            slot,
            language,
            'Прошивка',
            'Firmware',
            'rocket.svg',
          ),
          'schema' => _cell(slot, language, 'Схема', 'Schema', 'copy.svg'),
          'state' => _cell(slot, language, 'Хранилище', 'Storage', 'sight.svg'),
          'delete' => HexSlot(
            id: 'delete',
            title: unitText(language, 'Удалить', 'Delete'),
            color: errorColor,
            busy: _pending == 'delete',
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/close.svg',
          ),
          _ => HexSlot(
            id: slot.id,
            title: slot.id,
            color: unitsColor,
            q: slot.q,
            r: slot.r,
          ),
        },
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: unitText,
      wide: wide,
    );
    return HexPage(slots: slots, onTap: _tap);
  }

  HexSlot _cell(
    BoardSlot slot,
    String language,
    String ru,
    String en,
    String icon,
  ) {
    return HexSlot(
      id: slot.id,
      title: unitText(language, ru, en),
      color: unitsColor,
      q: slot.q,
      r: slot.r,
      icon: 'assets/icons/$icon',
    );
  }

  Future<void> _tap(String id) async {
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'commands':
        context.push('/units/${widget.uuid}/work/commands');
      case 'logs':
        context.push('/units/${widget.uuid}/work/logs');
      case 'firmware':
        context.push('/units/${widget.uuid}/work/firmware');
      case 'schema':
        context.push('/units/${widget.uuid}/work/schema');
      case 'state':
        context.push('/units/${widget.uuid}/work/state');
      case 'delete':
        await _delete();
    }
  }

  Future<void> _delete() async {
    if (_pending != null) return;
    setState(() {
      _pending = 'delete';
      _failure = null;
      _open = false;
    });
    try {
      await AppScope.of(context).deleteUnit(widget.uuid);
      if (!mounted) return;
      context.go('/units');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
    }
  }
}
