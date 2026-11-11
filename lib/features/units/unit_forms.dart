import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../account/icon_file.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../navigation/pick.dart';
import '../../units/unit.dart';
import '../file_drop.dart';
import '../hex_page.dart';
import 'unit_form_parts.dart';
import 'units_chrome.dart';
import '../../locale/languages.dart';

class UnitSettingsPage extends StatefulWidget {
  const UnitSettingsPage({required this.uuid, super.key});

  final String uuid;

  @override
  State<UnitSettingsPage> createState() => _UnitSettingsPageState();
}

class _UnitSettingsPageState extends State<UnitSettingsPage> {
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  final _form = UnitFormFields();
  Unit? _unit;
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
        return backSlot(language, q: slot.q, r: slot.r);
      case 'avatar':
        return HexSlot(
          id: 'avatar',
          title: localized(language, 'Загрузить аватар', 'Upload avatar'),
          color: dropColor(_hot, color),
          busy: _loading,
          enabled: ready,
          q: slot.q,
          r: slot.r,
          icon: image == null ? 'assets/icons/actions/icon_load.svg' : null,
          image: image,
        );
      case 'name':
        return unitFormNameSlot(
          slot,
          language,
          controller: _name,
          focusNode: _nameFocus,
          issue: _issue,
          enabled: ready,
        );
      case 'visibility':
        return unitFormVisibilitySlot(
          slot,
          language,
          fields: _form,
          enabled: ready,
          onPick: (id) => setState(() => _form.visibility = id),
        );
      case 'branch':
        return unitFormBranchSlot(slot, language, fields: _form, enabled: ready);
      case 'updates':
        return unitFormUpdatesSlot(
          slot,
          language,
          fields: _form,
          enabled: ready,
        );
      case 'save':
        return HexSlot(
          id: 'save',
          title: localized(language, 'Сохранить', 'Save'),
          color: unitAddColor,
          busy: _busy,
          enabled: ready,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/actions/check.svg',
        );
      default:
        return unitFormFallbackSlot(slot);
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
        setState(() => _form.takeBranch(picked));
      case 'updates':
        if (!_ready) return;
        final picked = await _form.pickUpdates(context, _unit?.repoUuid ?? '');
        if (picked == null || !mounted) return;
        setState(() => _form.takeUpdates(picked));
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
        _form.takeUnit(unit);
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
    final problem = _form.problem(language, name);
    if (problem != null) {
      setState(() {
        _issue = problem.issue;
        _failure = problem.failure;
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
      final unit = await AppScope.of(context).updateUnit(
        widget.uuid,
        _form.body(name, clearUnused: true),
      );
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
      dialogTitle: localized(model.vault.language, 'Аватар', 'Avatar'),
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
