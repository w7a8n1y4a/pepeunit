import 'dart:convert';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../account/icon_file.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../units/unit.dart';
import '../../units/unit_view.dart';
import '../file_drop.dart';
import '../hex_page.dart';
import '../line_input.dart';
import '../network/network_chrome.dart';
import 'units_chrome.dart';

class UnitSettingsPage extends StatefulWidget {
  const UnitSettingsPage({required this.uuid, super.key});

  final String uuid;

  @override
  State<UnitSettingsPage> createState() => _UnitSettingsPageState();
}

class _UnitSettingsPageState extends State<UnitSettingsPage> {
  final _name = TextEditingController();
  Unit? _unit;
  String _visibility = 'Private';
  var _auto = true;
  var _tags = false;
  String _branch = '';
  String? _commit;
  String? _platform;
  List<String> _platforms = const [];
  String? _failure;
  var _open = false;
  var _loading = true;
  var _busy = false;
  var _hot = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final ids = [
      'name',
      'visibility',
      'auto',
      'tags',
      'branch',
      if (!_auto) 'commit',
      if (_platforms.isNotEmpty || (_unit?.compilable ?? false)) 'platform',
      'icon',
      'save',
    ];
    final placed = cardBoard(ids, wide: wide);
    final slots = <HexSlot>[for (final slot in placed) _slot(slot, language)];
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
      wrap: (slot, child) {
        if (slot.id != 'icon') return child;
        return FileDrop(
          enable: true,
          hot: _hot,
          onHot: (hot) => setState(() => _hot = hot),
          onDrop: _drop,
          child: child,
        );
      },
    );
  }

  HexSlot _slot(BoardSlot slot, String language) {
    final color = unitsColor;
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: unitText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'name':
        return HexSlot(
          id: 'name',
          title: unitText(language, 'Имя', 'Name'),
          color: color,
          busy: _loading,
          q: slot.q,
          r: slot.r,
          tappable: false,
          body: LineInput(
            color: color,
            controller: _name,
            hint: unitText(language, 'имя', 'name'),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_.-]')),
              LengthLimitingTextInputFormatter(20),
            ],
          ),
        );
      case 'visibility':
        return HexSlot(
          id: 'visibility',
          title: unitText(language, 'Видимость', 'Visibility'),
          color: color,
          q: slot.q,
          r: slot.r,
          tappable: false,
          body: ChoiceWords(
            choices: [
              for (final level in unitVisibilities)
                (id: level, label: unitVisibilityLabel(language, level)),
            ],
            selected: (id) => _visibility == id,
            onTap: (id) => setState(() => _visibility = id),
          ),
        );
      case 'auto':
        return HexSlot(
          id: 'auto',
          title: _auto
              ? unitText(language, 'Автообновление', 'Auto-update')
              : unitText(language, 'Вручную', 'Manual'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/reload.svg',
        );
      case 'tags':
        return HexSlot(
          id: 'tags',
          title: _tags
              ? unitText(language, 'Только теги', 'Tags only')
              : unitText(language, 'Любой коммит', 'Any commit'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/flag.svg',
        );
      case 'branch':
        return HexSlot(
          id: 'branch',
          title: unitText(language, 'Ветка', 'Branch'),
          footer: _branch.isEmpty ? null : _branch,
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/repo.svg',
        );
      case 'commit':
        return HexSlot(
          id: 'commit',
          title: unitText(language, 'Коммит', 'Commit'),
          footer: shortCommit(_commit).isEmpty ? null : shortCommit(_commit),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/check.svg',
        );
      case 'platform':
        return HexSlot(
          id: 'platform',
          title: unitText(language, 'Платформа', 'Platform'),
          footer: _platform,
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/micro.svg',
        );
      case 'icon':
        return HexSlot(
          id: 'icon',
          title: unitText(language, 'Иконка', 'Icon'),
          color: dropColor(_hot, color),
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/icon_load.svg',
        );
      case 'save':
        return HexSlot(
          id: 'save',
          title: unitText(language, 'Сохранить', 'Save'),
          color: color,
          busy: _busy,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/check.svg',
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
    final repo = _unit?.repoUuid ?? '';
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'auto':
        setState(() => _auto = !_auto);
      case 'tags':
        setState(() => _tags = !_tags);
      case 'branch':
        final picked = await context.push<String>(
          '/units/new/branch?repo=$repo',
        );
        if (picked == null || !mounted) return;
        setState(() => _branch = picked);
        await _platformsFor();
      case 'commit':
        final picked = await context.push<String>(
          '/units/new/commit?repo=$repo&branch=${Uri.encodeQueryComponent(_branch)}',
        );
        if (picked == null || !mounted) return;
        setState(() => _commit = picked);
        await _platformsFor();
      case 'platform':
        final picked = await context.push<String>(
          '/units/new/platform?repo=$repo&branch=${Uri.encodeQueryComponent(_branch)}'
          '${_commit == null ? '' : '&commit=${Uri.encodeQueryComponent(_commit!)}'}',
        );
        if (picked == null || !mounted) return;
        setState(() => _platform = picked);
      case 'icon':
        await _pickIcon();
      case 'save':
        await _save();
    }
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
      final unit = await model.readUnit(widget.uuid);
      if (!mounted) return;
      _name.text = unit.name;
      setState(() {
        _unit = unit;
        _visibility = unit.visibility.isEmpty ? 'Private' : unit.visibility;
        _auto = unit.auto;
        _tags = unit.tagsOnly;
        _branch = unit.branch;
        _commit = unit.commit;
        _platform = unit.platform;
        _loading = false;
      });
      await _platformsFor();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failure = '$error';
      });
    }
  }

  Future<void> _platformsFor() async {
    final repo = _unit?.repoUuid ?? '';
    if (repo.isEmpty || _branch.isEmpty) return;
    try {
      final rows = await AppScope.of(context)
          .firmwarePlatforms(repo, branch: _branch, commit: _commit);
      if (!mounted) return;
      setState(() {
        _platforms = [for (final row in rows) row.name];
      });
    } catch (_) {}
  }

  Future<void> _save() async {
    if (_busy) return;
    final language = AppScope.of(context).vault.language;
    final name = _name.text.trim();
    if (!unitNameOk(name)) {
      setState(() {
        _failure = unitText(
          language,
          'От 4 до 20: буквы, цифры, _ . -',
          '4 to 20: letters, digits, _ . -',
        );
      });
      return;
    }
    setState(() {
      _busy = true;
      _failure = null;
      _open = false;
    });
    try {
      final unit = await AppScope.of(context).updateUnit(widget.uuid, {
        'name': name,
        'visibility_level': _visibility,
        'target_branch': _branch,
        'is_auto_update_unit': _auto,
        'is_only_tag_update': _tags,
        'is_compilable_unit': _platform != null && _platform!.isNotEmpty,
        'target_commit': _auto ? null : _commit,
        'target_firmware_platform': _platform,
      });
      if (!mounted) return;
      setState(() {
        _unit = unit;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = '$error';
      });
    }
  }

  Future<void> _pickIcon() async {
    final model = AppScope.of(context);
    final bytes = await model.files.pick(
      dialogTitle: unitText(model.vault.language, 'Иконка', 'Icon'),
    );
    if (bytes == null) return;
    await _storeIcon(bytes);
  }

  Future<void> _drop(DropDoneDetails details) async {
    setState(() => _hot = false);
    if (details.files.isEmpty) return;
    try {
      await _storeIcon(await details.files.first.readAsBytes());
    } catch (error) {
      if (!mounted) return;
      setState(() => _failure = '$error');
    }
  }

  Future<void> _storeIcon(Uint8List bytes) async {
    final language = AppScope.of(context).vault.language;
    final problem = iconProblemText(iconProblem(bytes), language);
    if (problem != null) {
      setState(() => _failure = problem);
      return;
    }
    try {
      await AppScope.of(context).uploadEntityIcon(widget.uuid, 'Unit', bytes);
      if (!mounted) return;
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _failure = '$error');
    }
  }
}

class UnitEnvPage extends StatefulWidget {
  const UnitEnvPage({required this.uuid, required this.scope, super.key});

  final String uuid;
  final int scope;

  @override
  State<UnitEnvPage> createState() => _UnitEnvPageState();
}

class _UnitEnvPageState extends State<UnitEnvPage> {
  Map<String, Object?> _original = {};
  final Map<String, TextEditingController> _fields = {};
  String? _failure;
  var _open = false;
  var _loading = true;
  String? _pending;
  var _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(UnitEnvPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope) _page = 0;
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final keys = _fields.keys.toList();
    final board = tailBoard(
      tick: widget.scope,
      page: _page,
      head: const ['save', 'reset'],
      ids: [for (final key in keys) 'field:$key'],
      wide: wide,
    );
    final slots = <HexSlot>[
      for (final slot in board.slots) _slot(slot, language, board),
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
      onTap: (id) async {
        switch (id) {
          case 'back':
            popOrHome(context);
          case 'error':
            setState(() => _open = true);
          case 'save':
            await _save();
          case 'reset':
            await _reset();
        }
      },
      frame: (scene) => ScopeFrame(
        scope: widget.scope,
        canZoomIn: board.canZoomIn,
        path: '/units/${widget.uuid}/env',
        child: scene,
      ),
    );
  }

  HexSlot _slot(BoardSlot slot, String language, NetworkBoard board) {
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: unitText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'save':
        return HexSlot(
          id: 'save',
          title: unitText(language, 'Сохранить', 'Save'),
          color: unitsColor,
          busy: _loading || _pending == 'save',
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/check.svg',
        );
      case 'reset':
        return HexSlot(
          id: 'reset',
          title: unitText(language, 'Сбросить', 'Reset'),
          footer: unitText(language, 'PU_ до сохранения', 'PU_ until save'),
          color: unitsColor,
          busy: _loading || _pending == 'reset',
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/reload.svg',
        );
      case 'prev':
      case 'next':
        final forward = slot.id == 'next';
        return pageStepSlot(
          id: slot.id,
          left: !forward,
          language: language,
          color: unitsColor,
          q: slot.q,
          r: slot.r,
          page: board.page,
          pages: board.pages,
          enabled: forward ? board.page < board.pages - 1 : board.page > 0,
          onTap: () => setState(() => _page = board.page + (forward ? 1 : -1)),
        );
      default:
        final key = slot.id.startsWith('field:')
            ? slot.id.substring(6)
            : slot.id;
        final field = _fields[key];
        return HexSlot(
          id: slot.id,
          title: key,
          color: unitsColor,
          tappable: false,
          q: slot.q,
          r: slot.r,
          body: field == null
              ? null
              : LineInput(
                  color: unitsColor,
                  controller: field,
                  hint: unitText(language, 'значение', 'value'),
                ),
        );
    }
  }

  void _fill(Map<String, Object?> env) {
    final next = <String, TextEditingController>{};
    for (final entry in env.entries) {
      final shown = _show(entry.value);
      final existing = _fields[entry.key];
      if (existing == null) {
        next[entry.key] = TextEditingController(text: shown);
      } else {
        if (existing.text != shown) existing.text = shown;
        next[entry.key] = existing;
      }
    }
    for (final entry in _fields.entries) {
      if (!next.containsKey(entry.key)) entry.value.dispose();
    }
    _fields
      ..clear()
      ..addAll(next);
    _original = env;
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
      final env = await model.unitEnv(widget.uuid);
      if (!mounted) return;
      setState(() {
        _fill(env);
        _loading = false;
        _failure = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failure = '$error';
      });
    }
  }

  Future<void> _save() async {
    if (_pending != null) return;
    setState(() {
      _pending = 'save';
      _failure = null;
      _open = false;
    });
    final next = <String, Object?>{};
    for (final entry in _fields.entries) {
      next[entry.key] = _keep(entry.value.text, _original[entry.key]);
    }
    try {
      await AppScope.of(context).setUnitEnv(widget.uuid, next);
      if (!mounted) return;
      setState(() => _pending = null);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
    }
  }

  Future<void> _reset() async {
    if (_pending != null) return;
    setState(() {
      _pending = 'reset';
      _failure = null;
      _open = false;
    });
    try {
      await AppScope.of(context).resetUnitEnv(widget.uuid);
      if (!mounted) return;
      setState(() => _pending = null);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
    }
  }
}

String _show(Object? value) {
  if (value == null) return '';
  if (value is String) return value;
  return jsonEncode(value);
}

Object? _keep(String text, Object? previous) {
  if (previous is num) return num.tryParse(text.trim()) ?? text;
  if (previous is bool) {
    if (text.trim() == 'true') return true;
    if (text.trim() == 'false') return false;
  }
  return text;
}
