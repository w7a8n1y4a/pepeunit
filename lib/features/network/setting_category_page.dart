import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../account/icon_file.dart';
import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../instances/settings_catalog.dart';
import '../../locale/languages.dart';
import '../../navigation/back.dart';
import '../file_drop.dart';
import '../hex_page.dart';
import 'network_chrome.dart';
import 'setting_cells.dart';

/// Renders either:
/// - `ops`: the 1-ring instance commands menu (`tests`, `scan-all`, `reboot`)
/// - `settings`: instance, MQTT, DataPipe, notifications, Telegram, avatar
/// - a `SettingCategory`: child screens and, on a leaf, one cell per field
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
  var _dragHot = false;
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
    } else if (id == 'settings') {
      slots = _setupSlots(model, language, color, wide);
    } else if (settingCategory(id) != null) {
      slots = _screenSlots(settingCategory(id)!, model, language, color, wide);
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
    return HexPage(
      slots: slots,
      onTap: _tap,
      wrap: widget.categoryId == 'settings'
          ? (slot, child) {
              if (slot.id != 'icon') return child;
              return FileDrop(
                enable: _pending == null,
                hot: _dragHot,
                onHot: (hot) => setState(() => _dragHot = hot),
                onDrop: (detail) => _dropped(detail, language),
                child: child,
              );
            }
          : null,
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
            title: netText(language, 'Опросить соседей', 'Poll neighbors'),
            color: color,
            busy: _pending == 'scan-all',
            q: spots[i].$1,
            r: spots[i].$2,
            icon: 'assets/icons/instances.svg',
          ),
          'track' => HexSlot(
            id: 'track',
            title: netText(language, 'Отслеживать инстанс', 'Track instance'),
            color: color,
            q: spots[i].$1,
            r: spots[i].$2,
            icon: 'assets/icons/sight.svg',
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

  List<HexSlot> _setupSlots(
    AppModel model,
    String language,
    Color color,
    bool wide,
  ) {
    final frame = hexFrame(
      count: ownerSettingSections.length,
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
      for (var i = 0; i < ownerSettingSections.length && i < spots.length; i++)
        _sectionSlot(
          model,
          ownerSettingSections[i],
          spots[i].$1,
          spots[i].$2,
          language,
          color,
        ),
    ];
  }

  HexSlot _sectionSlot(
    AppModel model,
    String id,
    int q,
    int r,
    String language,
    Color color,
  ) {
    if (id == 'icon') {
      final targetUrl = model.target?.url ?? '';
      final portrait = targetUrl.isEmpty ? null : model.portraitOf(targetUrl);
      final image = targetUrl.isEmpty ? null : model.iconOf(targetUrl);
      return HexSlot(
        id: 'icon',
        title: netText(language, 'Загрузить аватар', 'Upload avatar'),
        footer: portrait?.version,
        color: dropColor(_dragHot, color),
        busy: _pending == 'icon',
        q: q,
        r: r,
        icon: image == null ? 'assets/icons/icon_load.svg' : null,
        image: image,
        iconScale: 1.15,
      );
    }
    final category = settingCategory(id);
    if (category != null) {
      return HexSlot(
        id: category.id,
        title: phrase(language, category.titles),
        color: color,
        q: q,
        r: r,
        icon: category.icon,
      );
    }
    return HexSlot(id: id, title: id, color: color, q: q, r: r);
  }

  List<HexSlot> _screenSlots(
    SettingCategory category,
    AppModel model,
    String language,
    Color color,
    bool wide,
  ) {
    final values = model.targetSettings ?? const <String, Object?>{};
    final links = [
      for (final id in category.links)
        if (settingCategory(id) != null) settingCategory(id)!,
    ];
    final frame = hexFrame(
      count: category.fields.length + links.length,
      back: HexBack.center,
      wide: wide,
    );
    final spots = frame.cells;
    final back = frame.back!;
    final flagLocked = !settingFieldsReady(category, values);
    final slots = <HexSlot>[
      backSlot(
        title: netText(language, 'Назад', 'Back'),
        q: back.$1,
        r: back.$2,
      ),
    ];
    var index = 0;
    for (final field in category.fields) {
      if (index >= spots.length) break;
      slots.add(
        _fieldSlot(
          category,
          field,
          spots[index].$1,
          spots[index].$2,
          values,
          language,
          color,
          flagLocked: flagLocked,
        ),
      );
      index++;
    }
    for (final link in links) {
      if (index >= spots.length) break;
      final open = settingSectionOpen(link, values);
      slots.add(
        HexSlot(
          id: link.id,
          title: phrase(language, link.titles),
          color: open ? color : hexMuted,
          enabled: open,
          q: spots[index].$1,
          r: spots[index].$2,
          icon: link.icon,
        ),
      );
      index++;
    }
    return slots;
  }

  HexSlot _fieldSlot(
    SettingCategory category,
    SettingField field,
    int q,
    int r,
    Map<String, Object?> values,
    String language,
    Color color, {
    required bool flagLocked,
  }) {
    final current = values[field.key];
    final title = field.label(language);
    if (field.kind == 'bool') {
      final on = current == true;
      final locked = flagLocked;
      return HexSlot(
        id: 'bool:${field.key}',
        title: title,
        footer: on
            ? netText(language, 'вкл', 'on')
            : netText(language, 'выкл', 'off'),
        color: on && !locked ? color : hexMuted,
        enabled: !locked,
        busy: _pending == 'bool:${field.key}',
        q: q,
        r: r,
        icon: on ? 'assets/icons/check.svg' : 'assets/icons/close.svg',
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
    final values = model.targetSettings ?? const <String, Object?>{};
    if (id.startsWith('bool:')) {
      final screen = settingCategory(widget.categoryId);
      if (screen != null && !settingFieldsReady(screen, values)) return;
      final key = id.substring(5);
      final current = values[key] == true;
      await _send(id, {key: !current});
      return;
    }
    final screen = settingCategory(id);
    if (screen != null) {
      if (!settingSectionOpen(screen, values)) return;
      context.push('/peers/tune/$id');
      return;
    }
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'icon':
        await _pick(model.vault.language);
      case 'tests':
        await _run('tests', model.runIntegrationTests);
      case 'scan-all':
        await _run('scan-all', model.scanAll);
      case 'track':
        context.push('/peers/track');
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

  Future<void> _pick(String language) async {
    if (_pending != null) return;
    final model = AppScope.of(context);
    final bytes = await model.files.pick(
      dialogTitle: netText(language, 'Картинка инстанса', 'Instance picture'),
    );
    if (bytes == null || !mounted) return;
    await _accept(bytes, language);
  }

  Future<void> _dropped(DropDoneDetails detail, String language) async {
    if (_dragHot) setState(() => _dragHot = false);
    if (_pending != null || detail.files.isEmpty) return;
    final bytes = await detail.files.first.readAsBytes();
    if (!mounted) return;
    await _accept(bytes, language);
  }

  Future<void> _accept(Uint8List bytes, String language) async {
    final problem = iconProblem(bytes);
    if (problem != null) {
      setState(() {
        _failure = iconProblemText(problem, language) ?? problem;
        _open = false;
      });
      return;
    }
    await _run('icon', () => AppScope.of(context).setInstanceIcon(bytes));
  }
}
