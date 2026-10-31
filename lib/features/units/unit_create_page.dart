import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../units/unit.dart';
import '../hex_page.dart';
import '../line_input.dart';
import 'units_chrome.dart';

/// Creates a unit from the repository passed as `repo`.
class UnitCreatePage extends StatefulWidget {
  const UnitCreatePage({required this.repoUuid, super.key});

  final String repoUuid;

  @override
  State<UnitCreatePage> createState() => _UnitCreatePageState();
}

class _UnitCreatePageState extends State<UnitCreatePage> {
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  String _visibility = 'Private';
  var _auto = true;
  String _branch = '';
  String? _commit;
  String? _platform;
  List<String> _platforms = const [];
  String? _failure;
  String? _issue;
  var _open = false;
  var _loading = true;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
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
      'branch',
      if (!_auto) 'commit',
      if (_platforms.isNotEmpty) 'platform',
      'create',
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
    return HexPage(slots: slots, onTap: _tap);
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
            focusNode: _nameFocus,
            fieldKey: const ValueKey('unit-name'),
            hint: unitText(language, 'имя', 'name'),
            issue: _issue ?? '',
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
      case 'branch':
        return HexSlot(
          id: 'branch',
          title: unitText(language, 'Ветка', 'Branch'),
          footer: _branch.isEmpty ? null : _branch,
          color: color,
          busy: _loading,
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
      case 'create':
        return HexSlot(
          id: 'create',
          title: unitText(language, 'Создать', 'Create'),
          color: color,
          busy: _busy,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/plus.svg',
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
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'auto':
        setState(() {
          _auto = !_auto;
          if (_auto) _commit = null;
        });
        await _loadPlatforms();
      case 'branch':
        final picked = await context.push<String>(
          '/units/new/branch?repo=${widget.repoUuid}',
        );
        if (picked == null || !mounted) return;
        setState(() {
          _branch = picked;
          _commit = null;
        });
        await _loadPlatforms();
      case 'commit':
        if (_branch.isEmpty) return;
        final picked = await context.push<String>(
          '/units/new/commit?repo=${widget.repoUuid}&branch=${Uri.encodeQueryComponent(_branch)}',
        );
        if (picked == null || !mounted) return;
        setState(() => _commit = picked);
        await _loadPlatforms();
      case 'platform':
        final picked = await context.push<String>(
          '/units/new/platform?repo=${widget.repoUuid}&branch=${Uri.encodeQueryComponent(_branch)}'
          '${_commit == null ? '' : '&commit=${Uri.encodeQueryComponent(_commit!)}'}',
        );
        if (picked == null || !mounted) return;
        setState(() => _platform = picked);
      case 'create':
        await _create();
    }
  }

  Future<void> _load() async {
    final model = AppScope.of(context);
    final language = model.vault.language;
    if (model.target?.signedIn != true || widget.repoUuid.isEmpty) {
      setState(() {
        _loading = false;
        _failure = unitText(language, 'Нет входа', 'Not signed in');
      });
      return;
    }
    try {
      final repo = await model.readRepo(widget.repoUuid);
      if (!mounted) return;
      setState(() {
        _branch = repo.branches.isEmpty ? '' : repo.branches.first;
        _loading = false;
      });
      await _loadPlatforms();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failure = '$error';
      });
    }
  }

  Future<void> _loadPlatforms() async {
    if (_branch.isEmpty) return;
    final model = AppScope.of(context);
    try {
      final rows = await model.firmwarePlatforms(
        widget.repoUuid,
        branch: _branch,
        commit: _auto ? null : _commit,
      );
      if (!mounted) return;
      setState(() {
        _platforms = [for (final row in rows) row.name];
        if (_platform != null && !_platforms.contains(_platform)) {
          _platform = null;
        }
        _platform ??= _platforms.isEmpty ? null : _platforms.first;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _failure = '$error');
    }
  }

  Future<void> _create() async {
    if (_busy) return;
    final model = AppScope.of(context);
    final language = model.vault.language;
    final name = _name.text.trim();
    if (!unitNameOk(name)) {
      setState(() {
        _issue = unitText(
          language,
          'От 4 до 20: буквы, цифры, _ . -',
          '4 to 20: letters, digits, _ . -',
        );
        _failure = null;
      });
      return;
    }
    if (_branch.isEmpty || (!_auto && (_commit == null || _commit!.isEmpty))) {
      setState(() {
        _issue = null;
        _failure = unitText(
          language,
          'Нужны ветка и коммит',
          'A branch and a commit are required',
        );
      });
      return;
    }
    setState(() {
      _busy = true;
      _issue = null;
      _failure = null;
      _open = false;
    });
    try {
      final unit = await model.createUnit({
        'name': name,
        'repo_uuid': widget.repoUuid,
        'visibility_level': _visibility,
        'target_branch': _branch,
        'is_auto_update_unit': _auto,
        'is_compilable_unit': _platform != null,
        if (!_auto) 'target_commit': _commit,
        if (_platform != null) 'target_firmware_platform': _platform,
      });
      if (!mounted) return;
      context.pushReplacement('/units/${unit.uuid}');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = '$error';
      });
    }
  }
}
