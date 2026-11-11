import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_motion.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../units/unit.dart';
import '../hex_page.dart';
import 'units_chrome.dart';
import '../../locale/languages.dart';

class UnitCommandsPage extends StatefulWidget {
  const UnitCommandsPage({required this.uuid, super.key});

  final String uuid;

  @override
  State<UnitCommandsPage> createState() => _UnitCommandsPageState();
}

class _UnitCommandsPageState extends State<UnitCommandsPage> {
  String? _pending;
  HexEcho? _echo;
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
            ? backSlot(language, q: slot.q, r: slot.r)
            : HexSlot(
                id: slot.id,
                hint: slot.id.toLowerCase(),
                title: unitCommandLabel(language, slot.id),
                footer: slot.id == 'Update' ? _status : null,
                color: unitsColor,
                busy: _pending == slot.id,
                enabled: _pending == null,
                q: slot.q,
                r: slot.r,
                icon: 'assets/icons/objects/terminal.svg',
              ),
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      wide: wide,
    );
    return HexPage(slots: slots, onTap: _tap, echo: _echo);
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
      setState(() {
        _pending = null;
        _echo = HexEcho(ok: true);
      });
      if (id == 'Update') _watch();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
        _echo = HexEcho(ok: false);
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

/// Zip, tar and tgz of the program. Every cell uses the archive mark.
class UnitArchivesPage extends StatefulWidget {
  const UnitArchivesPage({required this.uuid, super.key});

  final String uuid;

  @override
  State<UnitArchivesPage> createState() => _UnitArchivesPageState();
}

class _UnitArchivesPageState extends State<UnitArchivesPage> {
  Unit? _unit;
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
    const ids = ['zip', 'tar', 'tgz'];
    final placed = cardBoard(ids, wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        slot.id == 'back'
            ? backSlot(language, q: slot.q, r: slot.r)
            : HexSlot(
                id: slot.id,
                title: slot.id,
                color: unitsColor,
                busy: _pending == slot.id,
                q: slot.q,
                r: slot.r,
                icon: 'assets/icons/objects/archive.svg',
              ),
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      wide: wide,
    );
    return HexPage(slots: slots, onTap: _tap);
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

  Future<void> _tap(String id) async {
    if (id == 'back') {
      popOrHome(context);
      return;
    }
    if (id == 'error') {
      setState(() => _open = true);
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

/// Binary of a compilable unit. A tap starts the download.
class UnitPlatformsPage extends StatefulWidget {
  const UnitPlatformsPage({required this.uuid, super.key});

  final String uuid;

  @override
  State<UnitPlatformsPage> createState() => _UnitPlatformsPageState();
}

class _UnitPlatformsPageState extends State<UnitPlatformsPage> {
  List<({String name, String link})> _platforms = const [];
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
    final ids = [for (final row in _platforms) 'platform:${row.name}'];
    final slots = <HexSlot>[];
    if (ids.isEmpty) {
      final frame = hexFrame(count: 1, back: HexBack.center, wide: wide);
      slots.add(
        backSlot(language, q: frame.back!.$1, r: frame.back!.$2),
      );
      slots.add(
        HexSlot(
          id: 'empty',
          title: _loading
              ? localized(language, 'Платформы', 'Platforms')
              : localized(language, 'Пусто', 'Empty'),
          color: unitsColor,
          busy: _loading,
          tappable: false,
          q: frame.cells.first.$1,
          r: frame.cells.first.$2,
          icon: 'assets/icons/objects/brick.svg',
        ),
      );
    } else {
      final placed = cardBoard(ids, wide: wide);
      for (final slot in placed) {
        slots.add(
          slot.id == 'back'
              ? backSlot(language, q: slot.q, r: slot.r)
              : HexSlot(
                  id: slot.id,
                  title: slot.id.startsWith('platform:')
                      ? slot.id.substring(9)
                      : slot.id,
                  color: unitsColor,
                  q: slot.q,
                  r: slot.r,
                  icon: 'assets/icons/objects/brick.svg',
                ),
        );
      }
    }
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
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
        _platforms = [
          for (final row in platforms) (name: row.name, link: row.link),
        ];
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

  Future<void> _tap(String id) async {
    if (id == 'back') {
      popOrHome(context);
      return;
    }
    if (id == 'error') {
      setState(() => _open = true);
      return;
    }
    if (!id.startsWith('platform:')) return;
    final name = id.substring(9);
    for (final row in _platforms) {
      if (row.name != name || row.link.isEmpty) continue;
      await AppScope.of(context).openExternal(Uri.parse(row.link));
    }
  }
}

/// Last step before a unit is removed. Back leaves it in place.
class UnitDeletePage extends StatefulWidget {
  const UnitDeletePage({required this.uuid, super.key});

  final String uuid;

  @override
  State<UnitDeletePage> createState() => _UnitDeletePageState();
}

class _UnitDeletePageState extends State<UnitDeletePage> {
  String? _failure;
  var _open = false;
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(const ['confirm'], wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        slot.id == 'back'
            ? backSlot(language, q: slot.q, r: slot.r)
            : HexSlot(
                id: 'confirm',
                title: localized(language, 'Удалить аппарат', 'Delete unit'),
                color: errorColor,
                busy: _busy,
                q: slot.q,
                r: slot.r,
                icon: 'assets/icons/actions/trash.svg',
              ),
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
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
    if (id != 'confirm' || _busy) return;
    setState(() {
      _busy = true;
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
        _busy = false;
        _failure = '$error';
      });
    }
  }
}
