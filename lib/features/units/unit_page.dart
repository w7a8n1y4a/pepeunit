import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_motion.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../registry/repo.dart';
import '../../units/unit.dart';
import '../../units/unit_read.dart';
import '../../units/unit_view.dart';
import '../hex_page.dart';
import 'unit_panels.dart';
import 'units_chrome.dart';

class UnitPage extends StatefulWidget {
  const UnitPage({required this.uuid, super.key});

  final String uuid;

  @override
  State<UnitPage> createState() => _UnitPageState();
}

class _UnitPageState extends State<UnitPage> {
  Unit? _unit;
  ({int inputs, int outputs})? _ios;
  int? _access;
  String? _failure;
  var _open = false;
  var _loading = true;
  HexEcho? _echo;
  var _env = false;
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
    _ios = null;
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
      for (final slot in placed) _slot(slot, language, model, unit),
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: unitText,
      wide: wide,
    );
    final scene = HexPage(
      slots: slots,
      onTap: (id) => _tap(id, unit),
      echo: _echo,
    );
    if (!_env) return scene;
    return Stack(
      children: [
        scene,
        UnitEnvPanel(
          uuid: widget.uuid,
          onClose: () {
            if (mounted) setState(() => _env = false);
          },
        ),
      ],
    );
  }

  HexSlot _slot(BoardSlot slot, String language, AppModel model, Unit? unit) {
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
            icon: 'assets/icons/sections/micro.svg',
          );
        }
        return unitMark(
          id: 'card',
          unit: unit,
          language: language,
          q: slot.q,
          r: slot.r,
          image: model.cachedIcon(unit.iconUuid),
          busy: _loading,
        );
      case 'info':
        return HexSlot(
          id: 'info',
          title: unitText(language, 'Информация', 'Information'),
          footer: unit == null
              ? null
              : deviceTimeEdge(unit.state?.millis, language),
          center:
              (unit == null
                      ? const ['—', '—', '—']
                      : unitGlance(unit, language))
                  .join('\n'),
          color: color,
          q: slot.q,
          r: slot.r,
        );
      case 'nodes':
        return HexSlot(
          id: 'nodes',
          title: unitText(language, 'Входы и выходы', 'Inputs and outputs'),
          footer: _ios == null
              ? null
              : pieceCount(language, _ios!.inputs + _ios!.outputs),
          color: unitIoColor,
          rim: _ioRim(),
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/objects/io.svg',
        );
      case 'settings':
        return HexSlot(
          id: 'settings',
          title: unitText(language, 'Настройки', 'Settings'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/actions/settings.svg',
        );
      case 'env':
        return HexSlot(
          id: 'env',
          title: unitText(
            language,
            'Переменные окружения',
            'Environment variables',
          ),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/objects/env.svg',
        );
      case 'operate':
        return HexSlot(
          id: 'operate',
          title: unitText(language, 'Управление аппаратом', 'Manage unit'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/status/bulb.svg',
        );
      case 'access':
        return HexSlot(
          id: 'access',
          title: unitText(language, 'Доступы', 'Access'),
          color: accessColor,
          q: slot.q,
          r: slot.r,
          footer: _access == null ? null : pieceCount(language, _access!),
          icon: 'assets/icons/objects/users.svg',
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
        await _reloadCard();
      case 'info':
        context.push('/units/${widget.uuid}/info');
      case 'nodes':
        context.push('/units/${widget.uuid}/io');
      case 'settings':
        context.push('/units/${widget.uuid}/settings');
      case 'env':
        setState(() => _env = true);
      case 'operate':
        context.push('/units/${widget.uuid}/work');
      case 'access':
        context.push('/units/${widget.uuid}/access');
    }
  }

  /// Inputs and outputs alternate around the border in proportion to their
  /// counts. Inputs take segment 0.
  List<Color>? _ioRim() {
    final counts = _ios;
    if (counts == null) return null;
    return rimMix([
      (unitIoColor, counts.inputs),
      (unitOutputColor, counts.outputs),
    ]);
  }

  /// Users and units together. Only the creator of a private unit sees the cell.
  Future<void> _loadAccess(Unit unit) async {
    final model = AppScope.of(context);
    if (unit.visibility != 'Private' ||
        !unitOwnedBy(unit.creatorUuid, model.target?.userUuid)) {
      if (_access != null) setState(() => _access = null);
      return;
    }
    try {
      final page = await model.accessGrants(
        resourceUuid: widget.uuid,
        resourceType: 'Unit',
        offset: 0,
        limit: 1,
      );
      if (mounted) setState(() => _access = page.count);
    } catch (_) {
      // The cell stays without a count; the access screen shows the error.
    }
  }

  Future<void> _loadIos() async {
    final model = AppScope.of(context);
    try {
      final inputs = model.listIos(
        offset: 0,
        limit: 1,
        unitUuid: widget.uuid,
        types: const ['Input'],
      );
      final outputs = model.listIos(
        offset: 0,
        limit: 1,
        unitUuid: widget.uuid,
        types: const ['Output'],
      );
      final counts = (
        inputs: (await inputs).count,
        outputs: (await outputs).count,
      );
      if (!mounted) return;
      setState(() => _ios = counts);
    } catch (_) {
      // The border stays one color; the list screen shows the error.
    }
  }

  /// A tap on the card reads the entity again and shows how it went.
  Future<void> _reloadCard() async {
    await _load();
    if (!mounted) return;
    setState(() => _echo = HexEcho(ok: _failure == null));
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
      unawaited(_loadIos());
      unawaited(_loadAccess(unit));
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

/// Commands, logs, archives, storage, platforms and delete.
class UnitWorkPage extends StatefulWidget {
  const UnitWorkPage({required this.uuid, super.key});

  final String uuid;

  @override
  State<UnitWorkPage> createState() => _UnitWorkPageState();
}

class _UnitWorkPageState extends State<UnitWorkPage> {
  Unit? _unit;
  String? _failure;
  var _open = false;
  var _logs = false;
  var _storage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final ids = [...unitOperateIds, if (_unit?.compilable == true) 'platforms'];
    final placed = cardBoard(ids, wide: wide);
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
            'objects/terminal.svg',
          ),
          'logs' => _cell(slot, language, 'Логи', 'Logs', 'objects/timber.svg'),
          'archives' => _cell(
            slot,
            language,
            'Архивы программ',
            'Program archives',
            'objects/archive.svg',
          ),
          'state' => _cell(
            slot,
            language,
            'Хранилище',
            'Storage',
            'objects/fridge.svg',
          ),
          'platforms' => _cell(
            slot,
            language,
            'Платформы',
            'Platforms',
            'objects/brick.svg',
          ),
          'delete' => HexSlot(
            id: 'delete',
            title: unitText(language, 'Удалить аппарат', 'Delete unit'),
            color: errorColor,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/actions/trash.svg',
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
    final scene = HexPage(slots: slots, onTap: _tap);
    if (!_logs && !_storage) return scene;
    return Stack(
      children: [
        scene,
        if (_logs)
          UnitLogPanel(
            uuid: widget.uuid,
            onClose: () {
              if (mounted) setState(() => _logs = false);
            },
          ),
        if (_storage)
          UnitStoragePanel(
            uuid: widget.uuid,
            onClose: () {
              if (mounted) setState(() => _storage = false);
            },
          ),
      ],
    );
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
        setState(() => _logs = true);
      case 'archives':
        context.push('/units/${widget.uuid}/work/archives');
      case 'state':
        setState(() => _storage = true);
      case 'platforms':
        context.push('/units/${widget.uuid}/work/platforms');
      case 'delete':
        context.push('/units/${widget.uuid}/work/delete');
    }
  }

  Future<void> _load() async {
    try {
      final unit = await AppScope.of(context).readUnit(widget.uuid);
      if (!mounted) return;
      setState(() => _unit = unit);
    } catch (error) {
      if (!mounted) return;
      setState(() => _failure = '$error');
    }
  }
}
