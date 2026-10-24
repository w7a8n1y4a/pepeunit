import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../features/account/account_nav.dart';
import '../../features/account/error_reader.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../instances/settings_catalog.dart';
import '../../locale/languages.dart';
import 'network_chrome.dart';

class InstanceTunePage extends StatefulWidget {
  const InstanceTunePage({super.key});

  @override
  State<InstanceTunePage> createState() => _InstanceTunePageState();
}

class _InstanceTunePageState extends State<InstanceTunePage> {
  String? _failure;
  var _open = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await AppScope.of(context).loadSettings();
      } catch (error) {
        if (!mounted) return;
        setState(() => _failure = '$error');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final color = networkColor;
    final spots = hexDisk(2).skip(1).toList();
    final slots = <HexSlot>[
      HexSlot(
        id: 'back',
        title: netText(language, 'Назад', 'Back'),
        color: hexMuted,
        q: 0,
        r: 0,
        icon: 'assets/icons/back.svg',
      ),
      for (var i = 0; i < settingCategories.length && i < spots.length; i++)
        HexSlot(
          id: settingCategories[i].id,
          title: phrase(language, settingCategories[i].titles),
          color: color,
          q: spots[i].$1,
          r: spots[i].$2,
        ),
    ];
    if (_failure != null) {
      slots.add(
        HexSlot(
          id: 'error',
          title: netText(language, 'Ошибка', 'Error'),
          color: errorColor,
          titleColor: errorColor,
          q: 0,
          r: 2,
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
        onTap: (id) {
          if (id == 'back') {
            popOrHome(context);
          } else if (id == 'error') {
            setState(() => _open = true);
          } else {
            context.push('/peers/tune/$id');
          }
        },
      ),
    );
  }
}

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
  String? _editing;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = networkColor;
    final category = settingCategory(widget.categoryId);
    final slots = <HexSlot>[
      HexSlot(
        id: 'back',
        title: netText(language, 'Назад', 'Back'),
        color: hexMuted,
        q: 0,
        r: 0,
        icon: 'assets/icons/back.svg',
      ),
      if (category != null)
        HexSlot(
          id: 'form',
          title: phrase(language, category.titles),
          color: _busy ? const Color(0xFFFFFFFF) : color,
          q: 0,
          r: -1,
          body: SettingForm(
            category: category,
            values: model.targetSettings ?? const {},
            editing: _editing,
            color: color,
            language: language,
            onToggle: _toggle,
            onEdit: (key) => setState(() => _editing = key),
            onSubmit: _submit,
          ),
        ),
    ];
    if (_failure != null) {
      slots.add(
        HexSlot(
          id: 'error',
          title: netText(language, 'Ошибка', 'Error'),
          color: errorColor,
          titleColor: errorColor,
          q: 1,
          r: -1,
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
        onTap: (id) {
          if (id == 'back') popOrHome(context);
          if (id == 'error') setState(() => _open = true);
        },
      ),
    );
  }

  Future<void> _toggle(SettingField field) async {
    final model = AppScope.of(context);
    final current = model.targetSettings?[field.key];
    if (field.kind == 'enum') {
      final options = field.options;
      final index = options.indexOf('$current');
      final next = options[(index + 1) % options.length];
      await _send(field.key, next);
      return;
    }
    if (field.kind == 'bool') {
      await _send(field.key, current != true);
    }
  }

  Future<void> _submit(SettingField field, String raw) async {
    final value = parseSetting(field, raw);
    if (value == null && raw.trim().isNotEmpty) {
      setState(
        () => _failure = netText(
          AppScope.of(context).vault.language,
          'Значение вне диапазона',
          'Value is out of range',
        ),
      );
      return;
    }
    if (value == null && !field.nullable) {
      setState(
        () => _failure = netText(
          AppScope.of(context).vault.language,
          'Пустое значение',
          'Empty value',
        ),
      );
      return;
    }
    await _send(field.key, value);
  }

  Future<void> _send(String key, Object? value) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
      _open = false;
    });
    try {
      await AppScope.of(context).patchSetting(key, value);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _editing = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = '$error';
      });
    }
  }
}

class SettingForm extends StatefulWidget {
  const SettingForm({
    required this.category,
    required this.values,
    required this.editing,
    required this.color,
    required this.language,
    required this.onToggle,
    required this.onEdit,
    required this.onSubmit,
    super.key,
  });

  final SettingCategory category;
  final Map<String, Object?> values;
  final String? editing;
  final Color color;
  final String language;
  final ValueChanged<SettingField> onToggle;
  final ValueChanged<String> onEdit;
  final void Function(SettingField field, String raw) onSubmit;

  @override
  State<SettingForm> createState() => _SettingFormState();
}

class _SettingFormState extends State<SettingForm> {
  final _controller = TextEditingController();

  @override
  void didUpdateWidget(SettingForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.editing != oldWidget.editing && widget.editing != null) {
      final value = widget.values[widget.editing];
      _controller.text = value == null ? '' : '$value';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.category.fields.where(
      (field) => field.key == widget.editing,
    );
    final field = editing.isEmpty ? null : editing.first;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final font = max(10.0, side * 0.055);
        return Material(
          type: MaterialType.transparency,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              side * 0.14,
              side * 0.24,
              side * 0.14,
              side * 0.12,
            ),
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      for (final item in widget.category.fields)
                        _row(item, font),
                    ],
                  ),
                ),
                if (field != null &&
                    field.kind != 'bool' &&
                    field.kind != 'enum')
                  TextField(
                    controller: _controller,
                    style: TextStyle(
                      color: const Color(0xFFFFFFFF),
                      fontFamily: 'OpenGost Type B',
                      fontSize: font,
                    ),
                    cursorColor: widget.color,
                    decoration: const InputDecoration(
                      isCollapsed: true,
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) => widget.onSubmit(field, value),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(SettingField field, double font) {
    final value = widget.values[field.key];
    final shown = value == null ? '—' : '$value';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (field.kind == 'bool' || field.kind == 'enum') {
          widget.onToggle(field);
        } else {
          widget.onEdit(field.key);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          '${field.label()}: $shown',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: widget.editing == field.key
                ? const Color(0xFFFFFFFF)
                : hexMuted,
            decoration: TextDecoration.none,
            fontFamily: 'OpenGost Type B',
            fontSize: font,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
