import 'dart:math';
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../account/icon_file.dart';
import '../../app_model.dart';
import '../../app_scope.dart';
import '../../features/account/account_nav.dart';
import '../../features/account/error_reader.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../instances/settings_catalog.dart';
import '../../locale/languages.dart';
import 'network_chrome.dart';

/// Instance administration hub (`/peers/tune`).
///
/// Back stays in the center. The action list stays within the first ring.
class InstanceTunePage extends StatefulWidget {
  const InstanceTunePage({super.key});

  @override
  State<InstanceTunePage> createState() => _InstanceTunePageState();
}

class _InstanceTunePageState extends State<InstanceTunePage> {
  String? _failure;
  var _open = false;
  var _busy = false;
  var _dragHot = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final model = AppScope.of(context);
      final target = model.target;
      if (target == null || !target.managesPeers) return;
      if (!target.ownsInstance) return;
      try {
        await model.loadSettings();
      } catch (error) {
        if (!mounted) return;
        setState(() => _failure = '$error');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = networkColor;
    final target = model.target;
    final owner = target?.ownsInstance ?? false;
    final staff = target?.managesPeers ?? false;
    final portrait = target == null ? null : model.portraitOf(target.url);
    final federation = portrait?.federation != false;

    final ids = tuneActions(owner: owner, staff: staff, federation: federation);
    final wide = hexWide(MediaQuery.sizeOf(context));
    final frame = hexFrame(count: ids.length, back: HexBack.center, wide: wide);
    final back = frame.back!;
    final placed = <BoardSlot>[
      BoardSlot('back', back.$1, back.$2),
      for (var i = 0; i < ids.length && i < frame.cells.length; i++)
        BoardSlot(ids[i], frame.cells[i].$1, frame.cells[i].$2),
    ];
    final slots = <HexSlot>[
      for (final slot in placed) _slot(slot, model, language, color),
    ];
    if (_failure != null) {
      final spot = errorSpot(placed, wide: wide);
      slots.add(
        HexSlot(
          id: 'error',
          title: netText(language, 'Ошибка', 'Error'),
          color: errorColor,
          titleColor: errorColor,
          q: spot.$1,
          r: spot.$2,
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
        onTap: (id) => _tap(id, language, owner),
        wrap: (slot, child) {
          if (slot.id != 'icon' || !owner) return child;
          return DropTarget(
            enable: !_busy,
            onDragEntered: (_) {
              if (!_dragHot) setState(() => _dragHot = true);
            },
            onDragExited: (_) {
              if (_dragHot) setState(() => _dragHot = false);
            },
            onDragDone: (detail) => _dropped(detail, language),
            child: child,
          );
        },
      ),
    );
  }

  HexSlot _slot(BoardSlot slot, AppModel model, String language, Color color) {
    final targetUrl = model.target?.url ?? '';
    final portrait = targetUrl.isEmpty ? null : model.portraitOf(targetUrl);
    final active = _busy ? const Color(0xFFFFFFFF) : color;
    switch (slot.id) {
      case 'back':
        return HexSlot(
          id: 'back',
          title: netText(language, 'Назад', 'Back'),
          color: hexMuted,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/back.svg',
        );
      case 'identity':
        return instanceMark(
          id: 'identity',
          url: targetUrl,
          language: language,
          q: slot.q,
          r: slot.r,
          color: color,
          current: true,
          version: portrait?.version,
          image: targetUrl.isEmpty ? null : model.iconOf(targetUrl),
          tappable: false,
        );
      case 'icon':
        final image = targetUrl.isEmpty ? null : model.iconOf(targetUrl);
        return HexSlot(
          id: 'icon',
          title: netText(language, 'Аватар инстанса', 'Instance icon'),
          footer: portrait?.version,
          color: _busy || _dragHot ? const Color(0xFFFFFFFF) : color,
          q: slot.q,
          r: slot.r,
          icon: image == null ? 'assets/icons/icon_load.svg' : null,
          image: image,
          iconScale: 1.15,
        );
      case 'ops':
        return HexSlot(
          id: 'ops',
          title: netText(language, 'Операции', 'Operations'),
          footer: portrait?.testsStatus,
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/power.svg',
        );
      case 'flags':
        return HexSlot(
          id: 'flags',
          title: netText(language, 'Флаги', 'Flags'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/check.svg',
        );
      case 'tests':
        return HexSlot(
          id: 'tests',
          title: netText(language, 'Тесты', 'Tests'),
          footer: portrait?.testsStatus,
          color: active,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/reload.svg',
        );
      case 'scan-all':
        return HexSlot(
          id: 'scan-all',
          title: netText(language, 'Опросить все', 'Scan all'),
          color: active,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/instances.svg',
        );
      default:
        final group = settingGroup(slot.id);
        if (group != null) {
          return HexSlot(
            id: group.id,
            title: phrase(language, group.titles),
            color: color,
            q: slot.q,
            r: slot.r,
            icon: group.icon,
          );
        }
        return HexSlot(
          id: slot.id,
          title: slot.id,
          color: color,
          q: slot.q,
          r: slot.r,
        );
    }
  }

  Future<void> _tap(String id, String language, bool owner) async {
    final model = AppScope.of(context);
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'icon':
        if (owner) await _pick(language);
      case 'tests':
        await _run(model.runIntegrationTests);
      case 'scan-all':
        await _run(model.scanAll);
      case 'ops':
      case 'flags':
      case 'core':
      case 'services':
      case 'transport':
        context.push('/peers/tune/$id');
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
      _open = false;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => _busy = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = '$error';
      });
    }
  }

  Future<void> _pick(String language) async {
    if (_busy) return;
    final model = AppScope.of(context);
    final bytes = await model.files.pick(
      dialogTitle: netText(language, 'Картинка инстанса', 'Instance picture'),
    );
    if (bytes == null || !mounted) return;
    await _accept(bytes, language);
  }

  Future<void> _dropped(DropDoneDetails detail, String language) async {
    if (_dragHot) setState(() => _dragHot = false);
    if (_busy || detail.files.isEmpty) return;
    final bytes = await detail.files.first.readAsBytes();
    if (!mounted) return;
    await _accept(bytes, language);
  }

  Future<void> _accept(Uint8List bytes, String language) async {
    final problem = iconProblem(bytes);
    if (problem != null) {
      setState(() {
        _failure = _iconText(problem, language);
        _open = false;
      });
      return;
    }
    await _run(() => AppScope.of(context).setInstanceIcon(bytes));
  }
}

/// Renders either:
/// - `ops`: the 1-ring instance operations menu (`tests`, `scan-all`, `reboot`)
/// - a `SettingGroup` (`core`, `services`, `transport`): 1-ring submenu of categories
/// - a leaf `SettingCategory` (`flags`, `contacts`, `users`, ...): 1-ring cluster
///   where every setting field is its own hexagon around Back!
class SettingCategoryPage extends StatefulWidget {
  const SettingCategoryPage({required this.categoryId, super.key});

  final String categoryId;

  @override
  State<SettingCategoryPage> createState() => _SettingCategoryPageState();
}

class _SettingCategoryPageState extends State<SettingCategoryPage> {
  String? _failure;
  var _open = false;
  var _busy = false;
  final Map<String, String> _drafts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final model = AppScope.of(context);
      if (model.targetSettings != null) return;
      if (model.target?.ownsInstance != true) return;
      try {
        await model.loadSettings();
      } catch (error) {
        if (!mounted) return;
        setState(() => _failure = '$error');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = networkColor;
    final id = widget.categoryId;

    final wide = hexWide(MediaQuery.sizeOf(context));
    final List<HexSlot> slots;
    if (id == 'ops') {
      slots = _opsSlots(model, language, color, wide);
    } else if (settingGroup(id) != null) {
      slots = _groupSlots(settingGroup(id)!, language, color, wide);
    } else if (settingCategory(id) != null) {
      slots = _categorySlots(
        settingCategory(id)!,
        model,
        language,
        color,
        wide,
      );
    } else {
      final back = hexBackCell(HexBack.center)!;
      slots = [
        HexSlot(
          id: 'back',
          title: netText(language, 'Назад', 'Back'),
          color: hexMuted,
          q: back.$1,
          r: back.$2,
          icon: 'assets/icons/back.svg',
        ),
      ];
    }

    if (_failure != null) {
      final spot = errorSpot(
        slots.map((slot) => BoardSlot(slot.id, slot.q, slot.r)),
        wide: wide,
      );
      slots.add(
        HexSlot(
          id: 'error',
          title: netText(language, 'Ошибка', 'Error'),
          color: errorColor,
          titleColor: errorColor,
          q: spot.$1,
          r: spot.$2,
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
      child: HexScene(slots: slots, onTap: _tap),
    );
  }

  List<HexSlot> _opsSlots(
    AppModel model,
    String language,
    Color color,
    bool wide,
  ) {
    final target = model.target;
    final owner = target?.ownsInstance ?? false;
    final staff = target?.managesPeers ?? false;
    final targetUrl = target?.url ?? '';
    final portrait = targetUrl.isEmpty ? null : model.portraitOf(targetUrl);
    final federation = portrait?.federation != false;
    final active = _busy ? const Color(0xFFFFFFFF) : color;
    final ops = operationActions(
      owner: owner,
      staff: staff,
      federation: federation,
    );
    final items = ['identity', ...ops];
    final frame = hexFrame(
      count: items.length,
      back: HexBack.center,
      wide: wide,
    );
    final spots = frame.cells;
    final back = frame.back!;
    return [
      HexSlot(
        id: 'back',
        title: netText(language, 'Назад', 'Back'),
        color: hexMuted,
        q: back.$1,
        r: back.$2,
        icon: 'assets/icons/back.svg',
      ),
      for (var i = 0; i < items.length && i < spots.length; i++)
        switch (items[i]) {
          'identity' => instanceMark(
            id: 'identity',
            url: targetUrl,
            language: language,
            q: spots[i].$1,
            r: spots[i].$2,
            color: color,
            current: true,
            version: portrait?.version,
            image: targetUrl.isEmpty ? null : model.iconOf(targetUrl),
            tappable: false,
          ),
          'tests' => HexSlot(
            id: 'tests',
            title: netText(language, 'Тесты', 'Tests'),
            footer: portrait?.testsStatus,
            color: active,
            q: spots[i].$1,
            r: spots[i].$2,
            icon: 'assets/icons/reload.svg',
          ),
          'scan-all' => HexSlot(
            id: 'scan-all',
            title: netText(language, 'Опросить все', 'Scan all'),
            color: active,
            q: spots[i].$1,
            r: spots[i].$2,
            icon: 'assets/icons/instances.svg',
          ),
          'reboot' => HexSlot(
            id: 'reboot',
            title: netText(language, 'Перезапуск', 'Reboot'),
            color: _busy ? const Color(0xFFFFFFFF) : errorColor,
            q: spots[i].$1,
            r: spots[i].$2,
            icon: 'assets/icons/power.svg',
          ),
          _ => HexSlot(
            id: items[i],
            title: items[i],
            color: color,
            q: spots[i].$1,
            r: spots[i].$2,
          ),
        },
    ];
  }

  List<HexSlot> _groupSlots(
    SettingGroup group,
    String language,
    Color color,
    bool wide,
  ) {
    final categories = [
      for (final id in group.categoryIds)
        if (settingCategory(id) != null) settingCategory(id)!,
    ];
    final frame = hexFrame(
      count: categories.length,
      back: HexBack.center,
      wide: wide,
    );
    final spots = frame.cells;
    final back = frame.back!;
    return [
      HexSlot(
        id: 'back',
        title: netText(language, 'Назад', 'Back'),
        color: hexMuted,
        q: back.$1,
        r: back.$2,
        icon: 'assets/icons/back.svg',
      ),
      for (var i = 0; i < categories.length && i < spots.length; i++)
        HexSlot(
          id: 'cat:${categories[i].id}',
          title: phrase(language, categories[i].titles),
          footer: '${categories[i].fields.length}',
          color: color,
          q: spots[i].$1,
          r: spots[i].$2,
          icon: categories[i].icon,
        ),
    ];
  }

  List<HexSlot> _categorySlots(
    SettingCategory category,
    AppModel model,
    String language,
    Color color,
    bool wide,
  ) {
    final values = model.targetSettings ?? const <String, Object?>{};
    final frame = hexFrame(
      count: category.fields.length,
      back: HexBack.center,
      wide: wide,
    );
    final spots = frame.cells;
    final back = frame.back!;
    return [
      HexSlot(
        id: 'back',
        title: netText(language, 'Назад', 'Back'),
        color: hexMuted,
        q: back.$1,
        r: back.$2,
        icon: 'assets/icons/back.svg',
      ),
      for (var i = 0; i < category.fields.length && i < spots.length; i++)
        _fieldSlot(
          category,
          category.fields[i],
          spots[i].$1,
          spots[i].$2,
          values,
          language,
          color,
        ),
    ];
  }

  HexSlot _fieldSlot(
    SettingCategory category,
    SettingField field,
    int q,
    int r,
    Map<String, Object?> values,
    String language,
    Color color,
  ) {
    final current = values[field.key];
    final title = field.label(language);
    if (field.kind == 'bool') {
      final enabled = current == true;
      return HexSlot(
        id: 'bool:${field.key}',
        title: title,
        footer: enabled
            ? netText(language, 'вкл', 'on')
            : netText(language, 'выкл', 'off'),
        color: _busy ? const Color(0xFFFFFFFF) : (enabled ? color : hexMuted),
        q: q,
        r: r,
        icon: enabled ? 'assets/icons/check.svg' : 'assets/icons/close.svg',
      );
    }
    if (field.kind == 'enum') {
      return HexSlot(
        id: 'enum:${field.key}',
        title: title,
        footer: current == null ? null : '$current',
        color: _busy ? const Color(0xFFFFFFFF) : color,
        q: q,
        r: r,
        body: EnumSettingCell(
          field: field,
          current: current == null ? '' : '$current',
          onSelect: (option) => _send({field.key: option}),
        ),
      );
    }
    return HexSlot(
      id: 'field:${field.key}',
      title: title,
      footer: field.rangeHint(),
      color: _busy ? const Color(0xFFFFFFFF) : color,
      q: q,
      r: r,
      body: ValueSettingCell(
        field: field,
        value: current,
        color: color,
        language: language,
        onChanged: (raw) => _drafts[field.key] = raw,
        onSubmit: (raw) => _submitField(category, field, raw, values),
      ),
    );
  }

  Future<void> _tap(String id) async {
    final model = AppScope.of(context);
    if (id.startsWith('cat:')) {
      context.push('/peers/tune/${id.substring(4)}');
      return;
    }
    if (id.startsWith('bool:')) {
      final key = id.substring(5);
      final current = model.targetSettings?[key] == true;
      await _send({key: !current});
      return;
    }
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'tests':
        await _run(model.runIntegrationTests);
      case 'scan-all':
        await _run(model.scanAll);
      case 'reboot':
        await _run(model.reboot);
    }
  }

  Future<void> _submitField(
    SettingCategory category,
    SettingField field,
    String raw,
    Map<String, Object?> currentValues,
  ) async {
    final language = AppScope.of(context).vault.language;
    final parsed = parseSetting(field, raw);
    if (parsed == null && raw.trim().isNotEmpty) {
      setState(() {
        _failure = netText(
          language,
          'Некорректное значение (${field.rangeHint() ?? field.kind})',
          'Invalid value (${field.rangeHint() ?? field.kind})',
        );
        _open = false;
      });
      return;
    }
    if (parsed == null && !field.nullable) {
      setState(() {
        _failure = netText(language, 'Пустое значение', 'Empty value');
        _open = false;
      });
      return;
    }
    if (category.id == 'github') {
      final nameKey = 'pu_instance_github_token_name';
      final patKey = 'pu_instance_github_token_pat';
      final nameVal = field.key == nameKey
          ? '$parsed'
          : (_drafts[nameKey] ?? '${currentValues[nameKey] ?? ''}').trim();
      final patVal = field.key == patKey
          ? '$parsed'
          : (_drafts[patKey] ?? '${currentValues[patKey] ?? ''}').trim();
      if (nameVal.isNotEmpty != patVal.isNotEmpty) {
        setState(() {
          _failure = netText(
            language,
            'Заполните оба поля GitHub и нажмите Enter',
            'Fill both GitHub fields and press Enter',
          );
          _open = false;
        });
        return;
      }
      await _send({nameKey: nameVal, patKey: patVal});
      return;
    }
    await _send({field.key: parsed});
  }

  Future<void> _send(Map<String, Object?> patch) async {
    await _run(() => AppScope.of(context).patchSettings(patch));
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
      _open = false;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => _busy = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = '$error';
      });
    }
  }
}

class EnumSettingCell extends StatelessWidget {
  const EnumSettingCell({
    required this.field,
    required this.current,
    required this.onSelect,
    super.key,
  });

  final SettingField field;
  final String current;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final font = max(10.0, side * 0.068);
        return Padding(
          padding: EdgeInsets.fromLTRB(
            side * 0.16,
            side * 0.24,
            side * 0.16,
            side * 0.22,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final option in field.options)
                Flexible(
                  child: Semantics(
                    button: true,
                    selected: option == current,
                    label: option,
                    excludeSemantics: true,
                    onTap: () => onSelect(option),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onSelect(option),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            option,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: option == current
                                  ? const Color(0xFFFFFFFF)
                                  : hexMuted,
                              fontFamily: 'OpenGost Type B',
                              fontSize: font,
                              height: 1.1,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class ValueSettingCell extends StatefulWidget {
  const ValueSettingCell({
    required this.field,
    required this.value,
    required this.color,
    required this.language,
    required this.onChanged,
    required this.onSubmit,
    super.key,
  });

  final SettingField field;
  final Object? value;
  final Color color;
  final String language;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmit;

  @override
  State<ValueSettingCell> createState() => _ValueSettingCellState();
}

class _ValueSettingCellState extends State<ValueSettingCell> {
  late final TextEditingController _controller;
  final _focus = FocusNode();
  var _dirty = false;

  String get _serverText => widget.value == null ? '' : '${widget.value}';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _serverText);
  }

  @override
  void didUpdateWidget(ValueSettingCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_focus.hasFocus) {
      _controller.text = _serverText;
      _dirty = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    _dirty = false;
    widget.onSubmit(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final hint =
        widget.field.hint ??
        (widget.field.nullable
            ? netText(widget.language, 'пусто', 'empty')
            : '');
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final font = max(11.0, side * 0.075);
        return Material(
          type: MaterialType.transparency,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _focus.requestFocus(),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                side * 0.16,
                side * 0.26,
                side * 0.16,
                side * 0.22,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    height: side * 0.16,
                    child: TextField(
                      key: ValueKey('setting-${widget.field.key}'),
                      controller: _controller,
                      focusNode: _focus,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFFFFFFFF),
                        fontFamily: 'OpenGost Type B',
                        fontSize: font,
                        height: 1,
                        decoration: TextDecoration.none,
                      ),
                      cursorColor: widget.color,
                      decoration: InputDecoration(
                        isCollapsed: true,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                        hintText: hint,
                        hintStyle: TextStyle(
                          color: hexMuted,
                          fontFamily: 'OpenGost Type B',
                          fontSize: font,
                          height: 1,
                        ),
                        border: InputBorder.none,
                      ),
                      onChanged: (text) {
                        widget.onChanged(text);
                        final changed = text.trim() != _serverText.trim();
                        if (changed != _dirty) {
                          setState(() => _dirty = changed);
                        }
                      },
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  SizedBox(height: side * 0.03),
                  Container(
                    height: max(1, side * 0.008),
                    color: _dirty ? const Color(0xFFFFFFFF) : widget.color,
                  ),
                  if (_dirty) ...[
                    SizedBox(height: side * 0.03),
                    Semantics(
                      button: true,
                      label: netText(widget.language, 'Сохранить', 'Save'),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _submit,
                        child: Text(
                          'OK',
                          style: TextStyle(
                            color: widget.color,
                            fontFamily: 'OpenGost Type B',
                            fontSize: max(10.0, side * 0.058),
                            height: 1,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _iconText(String code, String language) {
  switch (code) {
    case 'empty':
      return netText(language, 'Файл пустой', 'The file is empty');
    case 'large':
      return netText(
        language,
        'Картинка больше 128 КБ',
        'The picture is larger than 128 KB',
      );
    case 'png':
      return netText(language, 'Нужен файл PNG', 'A PNG file is required');
    case 'size':
      return netText(
        language,
        'Нужен размер 192x192',
        'The picture must be 192x192',
      );
    default:
      return code;
  }
}
