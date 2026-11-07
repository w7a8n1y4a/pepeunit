import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../account/icon_file.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../navigation/pick.dart';
import '../../units/unit.dart';
import '../file_drop.dart';
import '../hex_page.dart';
import '../line_input.dart';
import 'unit_create_page.dart';
import 'units_chrome.dart';

class UnitSettingsPage extends StatefulWidget {
  const UnitSettingsPage({required this.uuid, super.key});

  final String uuid;

  @override
  State<UnitSettingsPage> createState() => _UnitSettingsPageState();
}

class _UnitSettingsPageState extends State<UnitSettingsPage> {
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  Unit? _unit;
  String _visibility = 'Internal';
  var _compilable = false;
  var _auto = true;
  var _tags = true;
  String _branch = '';
  String? _commit;
  String? _platform;
  String? _failure;
  String? _issue;
  var _open = false;
  var _loading = true;
  var _busy = false;
  var _hot = false;

  bool get _ready => _unit != null && !_loading;

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
    final model = AppScope.of(context);
    final language = model.vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    const ids = ['avatar', 'name', 'visibility', 'branch', 'updates', 'save'];
    final placed = cardBoard(ids, wide: wide);
    final image = model.cachedIcon(_unit?.iconUuid);
    final slots = <HexSlot>[
      for (final slot in placed) _slot(slot, language, image),
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
      wrap: (slot, child) {
        if (slot.id != 'avatar') return child;
        return FileDrop(
          enable: _ready,
          hot: _hot,
          onHot: (hot) => setState(() => _hot = hot),
          onDrop: _drop,
          child: child,
        );
      },
    );
  }

  HexSlot _slot(BoardSlot slot, String language, Uint8List? image) {
    final color = unitsColor;
    final ready = _ready;
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: unitText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'avatar':
        return HexSlot(
          id: 'avatar',
          title: unitText(language, 'Загрузить аватар', 'Upload avatar'),
          color: dropColor(_hot, color),
          busy: _loading,
          enabled: ready,
          q: slot.q,
          r: slot.r,
          icon: image == null ? 'assets/icons/actions/icon_load.svg' : null,
          image: image,
        );
      case 'name':
        return HexSlot(
          id: 'name',
          title: unitText(language, 'Имя', 'Name'),
          color: color,
          q: slot.q,
          r: slot.r,
          tappable: false,
          enabled: ready,
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
          enabled: ready,
          body: ChoiceWords(
            center: true,
            choices: [
              for (final level in unitVisibilities)
                (id: level, label: unitVisibilityLabel(language, level)),
            ],
            selected: (id) => _visibility == id,
            onTap: (id) => setState(() => _visibility = id),
          ),
        );
      case 'branch':
        return HexSlot(
          id: 'branch',
          title: unitText(language, 'Ветка', 'Branch'),
          footer: _branch.isEmpty ? null : _branch,
          color: color,
          enabled: ready,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/objects/repo.svg',
        );
      case 'updates':
        return HexSlot(
          id: 'updates',
          title: unitText(language, 'Обновления', 'Updates'),
          footer: unitRunLabel(language, _compilable),
          footerLeft: unitHandsLabel(language, _auto),
          color: color,
          enabled: ready,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/actions/updates.svg',
        );
      case 'save':
        return HexSlot(
          id: 'save',
          title: unitText(language, 'Сохранить', 'Save'),
          color: unitAddColor,
          busy: _busy,
          enabled: ready,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/actions/check.svg',
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
      case 'avatar':
        if (!_ready) return;
        await _pickIcon();
      case 'branch':
        final repo = _unit?.repoUuid ?? '';
        if (!_ready || repo.isEmpty) return;
        final picked = await openPick<String>(
          context,
          '/units/new/branch?repo=$repo',
        );
        if (picked == null || !mounted) return;
        setState(() {
          _branch = picked;
          _commit = null;
          _platform = null;
        });
      case 'updates':
        if (!_ready) return;
        final picked = await context.push<UnitUpdateDraft>(
          unitUpdatesPath(
            repo: _unit?.repoUuid ?? '',
            branch: _branch,
            compilable: _compilable,
            auto: _auto,
            tags: _compilable || _tags,
            commit: _commit,
            platform: _platform,
          ),
        );
        if (picked == null || !mounted) return;
        setState(() {
          _compilable = picked.compilable;
          _auto = picked.auto;
          _tags = picked.compilable || picked.tagsOnly;
          _commit = picked.commit;
          _platform = picked.platform;
        });
      case 'save':
        await _save();
    }
  }

  Future<void> _load() async {
    final model = AppScope.of(context);
    if (!model.signedIn) {
      setState(() {
        _loading = false;
        _failure = model.notSignedIn;
      });
      return;
    }
    try {
      final unit = await model.readUnit(widget.uuid);
      if (!mounted) return;
      _name.text = unit.name;
      setState(() {
        _unit = unit;
        _visibility = unit.visibility.isEmpty ? 'Internal' : unit.visibility;
        _compilable = unit.compilable;
        _auto = unit.auto;
        _tags = unit.compilable || unit.tagsOnly;
        _branch = unit.branch;
        _commit = unit.commit;
        _platform = unit.platform;
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

  Future<void> _save() async {
    if (_busy || !_ready) return;
    final language = AppScope.of(context).vault.language;
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
    if (_branch.isEmpty) {
      setState(() {
        _issue = null;
        _failure = unitText(language, 'Нужна ветка', 'A branch is required');
      });
      return;
    }
    if (!_auto && (_commit == null || _commit!.isEmpty)) {
      setState(() {
        _issue = null;
        _failure = unitText(language, 'Нужен коммит', 'A commit is required');
      });
      return;
    }
    if (_compilable && (_platform == null || _platform!.isEmpty)) {
      setState(() {
        _issue = null;
        _failure = unitText(
          language,
          'Нужна платформа',
          'A platform is required',
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
      final unit = await AppScope.of(context).updateUnit(widget.uuid, {
        'name': name,
        'visibility_level': _visibility,
        'target_branch': _branch,
        'is_auto_update_unit': _auto,
        'is_compilable_unit': _compilable,
        'is_only_tag_update': _compilable || _tags,
        'target_commit': _auto ? null : _commit,
        'target_firmware_platform': _compilable ? _platform : null,
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
      dialogTitle: unitText(model.vault.language, 'Аватар', 'Avatar'),
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
