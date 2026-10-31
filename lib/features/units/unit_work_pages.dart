import 'dart:async';

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../registry/registry_view.dart';
import '../../registry/repo.dart';
import '../../units/unit.dart';
import '../../units/unit_view.dart';
import '../hex_page.dart';
import '../network/line_cell.dart';
import '../network/network_chrome.dart';
import 'units_chrome.dart';

class UnitCommandsPage extends StatefulWidget {
  const UnitCommandsPage({required this.uuid, super.key});

  final String uuid;

  @override
  State<UnitCommandsPage> createState() => _UnitCommandsPageState();
}

class _UnitCommandsPageState extends State<UnitCommandsPage> {
  String? _pending;
  String? _failure;
  var _open = false;
  String? _status;
  Timer? _poll;
  var _left = 0;

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(unitCommands, wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        slot.id == 'back'
            ? backSlot(
                title: unitText(language, 'Назад', 'Back'),
                q: slot.q,
                r: slot.r,
              )
            : HexSlot(
                id: slot.id,
                title: unitCommandLabel(language, slot.id),
                footer: slot.id == 'Update' ? _status : null,
                color: unitsColor,
                busy: _pending == slot.id,
                enabled: _pending == null,
                q: slot.q,
                r: slot.r,
                icon: 'assets/icons/send.svg',
              ),
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

  Future<void> _tap(String id) async {
    if (id == 'back') {
      popOrHome(context);
      return;
    }
    if (id == 'error') {
      setState(() => _open = true);
      return;
    }
    if (_pending != null || !unitCommands.contains(id)) return;
    setState(() {
      _pending = id;
      _failure = null;
      _open = false;
    });
    try {
      await AppScope.of(context).sendUnitCommand(widget.uuid, id);
      if (!mounted) return;
      setState(() => _pending = null);
      if (id == 'Update') _watch();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
    }
  }

  void _watch() {
    _poll?.cancel();
    _left = 6;
    _poll = Timer.periodic(const Duration(seconds: 10), (_) async {
      _left--;
      if (_left < 0) {
        _poll?.cancel();
        return;
      }
      try {
        final unit = await AppScope.of(context).readUnit(widget.uuid);
        if (!mounted) return;
        setState(() {
          _status = firmwareStatusLabel(
            AppScope.of(context).vault.language,
            unit.firmwareStatus,
          );
        });
        if (unit.firmwareStatus != 'RequestSent') _poll?.cancel();
      } catch (_) {}
    });
  }
}

class UnitLogsPage extends StatefulWidget {
  const UnitLogsPage({required this.uuid, required this.scope, super.key});

  final String uuid;
  final int scope;

  @override
  State<UnitLogsPage> createState() => _UnitLogsPageState();
}

class _UnitLogsPageState extends State<UnitLogsPage> {
  final Set<String> _levels = {...logLevels};
  var _offset = 0;
  var _count = 0;
  List<UnitLog> _logs = const [];
  String? _failure;
  var _open = false;
  var _loading = true;
  String? _openLog;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(UnitLogsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope == widget.scope) return;
    _offset = 0;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final limit = AppScope.of(context)
        .cappedLimit(headPageLimit(widget.scope, head: 3));
    final board = headBoard(
      tick: widget.scope,
      head: const ['filter', 'download', 'window'],
      ids: [for (final log in _logs) log.uuid],
      prefix: 'log:',
      total: _count,
      wide: wide,
    );
    final slots = <HexSlot>[
      for (final slot in board.slots) _slot(slot, language, limit),
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: unitText,
      wide: wide,
    );
    return HexPage(
      slots: slots,
      onTap: _tap,
      frame: (scene) => ScopeFrame(
        scope: widget.scope,
        canZoomIn: board.canZoomIn,
        path: '/units/${widget.uuid}/work/logs',
        child: scene,
      ),
    );
  }

  HexSlot _slot(BoardSlot slot, String language, int limit) {
    final color = unitsColor;
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: unitText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'filter':
        return HexSlot(
          id: 'filter',
          title: unitText(language, 'Уровни', 'Levels'),
          color: color,
          q: slot.q,
          r: slot.r,
          tappable: false,
          body: ChoiceWords(
            choices: [for (final level in logLevels) (id: level, label: level)],
            selected: _levels.contains,
            onTap: (id) {
              if (_levels.contains(id)) {
                if (_levels.length == 1) return;
                _levels.remove(id);
              } else {
                _levels.add(id);
              }
              setState(() => _offset = 0);
              _load();
            },
          ),
        );
      case 'download':
        return HexSlot(
          id: 'download',
          title: unitText(language, 'Скачать', 'Download'),
          color: color,
          busy: _loading && _logs.isEmpty,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/icon_load.svg',
        );
      case 'window':
        return HexSlot(
          id: 'window',
          title: unitText(language, 'Страница', 'Page'),
          color: color,
          busy: _loading,
          q: slot.q,
          r: slot.r,
          body: UnitWindow(
            language: language,
            offset: _offset,
            limit: limit,
            count: _count,
            onStep: _step,
          ),
        );
      default:
        final uuid = slot.id.startsWith('log:') ? slot.id.substring(4) : '';
        UnitLog? log;
        for (final item in _logs) {
          if (item.uuid == uuid) log = item;
        }
        return HexSlot(
          id: slot.id,
          title: log?.level ?? '',
          footer: log == null ? null : shortStamp(log.created),
          color: log?.level == 'Error' || log?.level == 'Critical'
              ? errorColor
              : color,
          q: slot.q,
          r: slot.r,
          body: log != null && _openLog == log.uuid
              ? MetricsCell(
                  lines: [log.text],
                  copyText: log.text,
                  copyLabel: unitText(language, 'Скопировать', 'Copy'),
                )
              : null,
        );
    }
  }

  Future<void> _tap(String id) async {
    if (id == 'back') {
      popOrHome(context);
      return;
    }
    if (id == 'error') {
      setState(() => _open = true);
      return;
    }
    if (id == 'download') {
      await _download();
      return;
    }
    if (!id.startsWith('log:')) return;
    final uuid = id.substring(4);
    for (final log in _logs) {
      if (log.uuid != uuid) continue;
      setState(() => _openLog = log.uuid);
    }
  }

  void _step(int direction) {
    final limit = AppScope.of(context)
        .cappedLimit(headPageLimit(widget.scope, head: 3));
    if (direction < 0 && !repoCanPageBack(offset: _offset, count: _count)) {
      return;
    }
    if (direction > 0 &&
        !repoCanPageForward(offset: _offset, limit: limit, count: _count)) {
      return;
    }
    setState(() => _offset += direction * limit);
    _load();
  }

  Future<void> _load() async {
    final model = AppScope.of(context);
    if (model.target?.signedIn != true) {
      setState(() {
        _loading = false;
        _failure = unitText(model.vault.language, 'Нет входа', 'Not signed in');
      });
      return;
    }
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final page = await model.unitLogs(
        uuid: widget.uuid,
        offset: _offset,
        limit: model.cappedLimit(headPageLimit(widget.scope, head: 3)),
        levels: _levels.length == logLevels.length ? null : _levels.toList(),
      );
      if (!mounted) return;
      setState(() {
        _logs = page.logs;
        _count = page.count;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failure = '$error';
      });
    }
  }

  Future<void> _download() async {
    final model = AppScope.of(context);
    try {
      final bytes = await model.downloadUnitLogs(widget.uuid);
      await model.saveBytes('unit-${widget.uuid}.log', bytes);
    } catch (error) {
      if (!mounted) return;
      setState(() => _failure = '$error');
    }
  }
}

class UnitFirmwarePage extends StatefulWidget {
  const UnitFirmwarePage({required this.uuid, super.key});

  final String uuid;

  @override
  State<UnitFirmwarePage> createState() => _UnitFirmwarePageState();
}

class _UnitFirmwarePageState extends State<UnitFirmwarePage> {
  Unit? _unit;
  List<({String name, String link})> _platforms = const [];
  String? _failure;
  var _open = false;
  String? _pending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final ids = [
      'zip',
      'tar',
      'tgz',
      for (final row in _platforms) 'platform:${row.name}',
    ];
    final placed = cardBoard(ids, wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        slot.id == 'back'
            ? backSlot(
                title: unitText(language, 'Назад', 'Back'),
                q: slot.q,
                r: slot.r,
              )
            : HexSlot(
                id: slot.id,
                title: slot.id.startsWith('platform:')
                    ? slot.id.substring(9)
                    : slot.id,
                color: unitsColor,
                busy: _pending == slot.id,
                q: slot.q,
                r: slot.r,
                icon: 'assets/icons/rocket.svg',
              ),
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

  Future<void> _load() async {
    final model = AppScope.of(context);
    try {
      final unit = await model.readUnit(widget.uuid);
      final platforms = unit.compilable
          ? await model.firmwarePlatforms(
              unit.repoUuid,
              branch: unit.branch,
              commit: unit.commit ?? unit.currentCommit,
            )
          : const [];
      if (!mounted) return;
      setState(() {
        _unit = unit;
        _platforms = [
          for (final row in platforms) (name: row.name, link: row.link),
        ];
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _failure = '$error');
    }
  }

  Future<void> _tap(String id) async {
    if (id == 'back') {
      popOrHome(context);
      return;
    }
    if (id == 'error') {
      setState(() => _open = true);
      return;
    }
    if (id.startsWith('platform:')) {
      final name = id.substring(9);
      for (final row in _platforms) {
        if (row.name != name || row.link.isEmpty) continue;
        await AppScope.of(context).openExternal(Uri.parse(row.link));
      }
      return;
    }
    if (id != 'zip' && id != 'tar' && id != 'tgz') return;
    final model = AppScope.of(context);
    setState(() {
      _pending = id;
      _failure = null;
    });
    try {
      final bytes = await model.unitFirmware(widget.uuid, id);
      final saved = await model.saveBytes(
        '${_unit?.name ?? widget.uuid}.$id',
        bytes,
      );
      if (!mounted) return;
      setState(() => _pending = null);
      if (!saved) return;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
    }
  }
}

class UnitTextPage extends StatefulWidget {
  const UnitTextPage({required this.uuid, required this.kind, super.key});

  final String uuid;

  /// `schema` or `state`.
  final String kind;

  @override
  State<UnitTextPage> createState() => _UnitTextPageState();
}

class _UnitTextPageState extends State<UnitTextPage> {
  String _text = '';
  String? _failure;
  var _open = false;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final title = widget.kind == 'schema'
        ? unitText(language, 'Схема', 'Schema')
        : unitText(language, 'Хранилище', 'Storage');
    final placed = cardBoard(const ['text'], wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        slot.id == 'back'
            ? backSlot(
                title: unitText(language, 'Назад', 'Back'),
                q: slot.q,
                r: slot.r,
              )
            : HexSlot(
                id: 'text',
                title: title,
                color: unitsColor,
                busy: _loading,
                q: slot.q,
                r: slot.r,
                tappable: false,
                body: MetricsCell(
                  lines: [_text.isEmpty ? '—' : _text],
                  copyText: _text,
                  copyLabel: unitText(language, 'Скопировать', 'Copy'),
                ),
              ),
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: unitText,
      wide: wide,
    );
    return HexPage(
      slots: slots,
      onTap: (id) {
        if (id == 'back') popOrHome(context);
        if (id == 'error') setState(() => _open = true);
      },
    );
  }

  Future<void> _load() async {
    final model = AppScope.of(context);
    if (model.target?.signedIn != true) {
      setState(() {
        _loading = false;
        _failure = unitText(model.vault.language, 'Нет входа', 'Not signed in');
      });
      return;
    }
    try {
      final text = widget.kind == 'schema'
          ? await model.unitSchema(widget.uuid)
          : await model.unitStateStorage(widget.uuid);
      if (!mounted) return;
      setState(() {
        _text = text;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failure = '$error';
      });
    }
  }
}
