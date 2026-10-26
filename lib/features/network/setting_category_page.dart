import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../instances/settings_catalog.dart';
import '../../locale/languages.dart';
import '../../navigation/back.dart';
import '../hex_page.dart';
import 'network_chrome.dart';
import 'setting_cells.dart';

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
  String? _pending;
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
        backSlot(
          title: netText(language, 'Назад', 'Back'),
          q: back.$1,
          r: back.$2,
        ),
      ];
    }

    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: netText,
      wide: wide,
      iconScale: 1.2,
    );
    return HexPage(slots: slots, onTap: _tap);
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
      backSlot(
        title: netText(language, 'Назад', 'Back'),
        q: back.$1,
        r: back.$2,
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
            color: color,
            busy: _pending == 'tests',
            q: spots[i].$1,
            r: spots[i].$2,
            icon: 'assets/icons/reload.svg',
          ),
          'scan-all' => HexSlot(
            id: 'scan-all',
            title: netText(language, 'Опросить все', 'Scan all'),
            color: color,
            busy: _pending == 'scan-all',
            q: spots[i].$1,
            r: spots[i].$2,
            icon: 'assets/icons/instances.svg',
          ),
          'reboot' => HexSlot(
            id: 'reboot',
            title: netText(language, 'Перезапуск', 'Reboot'),
            color: errorColor,
            busy: _pending == 'reboot',
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
      backSlot(
        title: netText(language, 'Назад', 'Back'),
        q: back.$1,
        r: back.$2,
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
      backSlot(
        title: netText(language, 'Назад', 'Back'),
        q: back.$1,
        r: back.$2,
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
        color: enabled ? color : hexMuted,
        busy: _pending == 'bool:${field.key}',
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
        color: color,
        busy: _pending == 'enum:${field.key}',
        q: q,
        r: r,
        body: EnumSettingCell(
          field: field,
          current: current == null ? '' : '$current',
          onSelect: (option) => _send('enum:${field.key}', {field.key: option}),
        ),
      );
    }
    return HexSlot(
      id: 'field:${field.key}',
      title: title,
      footer: field.rangeHint(),
      color: color,
      busy: _pending == 'field:${field.key}',
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
      await _send(id, {key: !current});
      return;
    }
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'tests':
        await _run('tests', model.runIntegrationTests);
      case 'scan-all':
        await _run('scan-all', model.scanAll);
      case 'reboot':
        await _run('reboot', model.reboot);
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
      await _send('field:${field.key}', {nameKey: nameVal, patKey: patVal});
      return;
    }
    await _send('field:${field.key}', {field.key: parsed});
  }

  Future<void> _send(String id, Map<String, Object?> patch) async {
    await _run(id, () => AppScope.of(context).patchSettings(patch));
  }

  Future<void> _run(String id, Future<void> Function() action) async {
    if (_pending != null) return;
    setState(() {
      _pending = id;
      _failure = null;
      _open = false;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => _pending = null);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
    }
  }
}
