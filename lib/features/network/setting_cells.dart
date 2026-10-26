import 'dart:math';

import 'package:flutter/material.dart';

import '../../hive/hex_scene.dart';
import '../../instances/settings_catalog.dart';
import '../line_input.dart';
import 'network_chrome.dart';

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
    return LineInput(
      color: widget.color,
      controller: _controller,
      focusNode: _focus,
      fieldKey: ValueKey('setting-${widget.field.key}'),
      hint: hint,
      issue: '',
      lineColor: _dirty ? const Color(0xFFFFFFFF) : widget.color,
      caption: _dirty ? _save() : null,
      onChanged: (text) {
        widget.onChanged(text);
        final changed = text.trim() != _serverText.trim();
        if (changed != _dirty) setState(() => _dirty = changed);
      },
      onSubmitted: (_) => _submit(),
    );
  }

  Widget _save() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final band = constraints.maxHeight;
        final font = band.isFinite
            ? min(max(10.0, band * 0.36), band * 0.72)
            : 14.0;
        return Semantics(
          button: true,
          label: netText(widget.language, 'Сохранить', 'Save'),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _submit,
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'OK',
                style: TextStyle(
                  color: widget.color,
                  fontFamily: 'OpenGost Type B',
                  fontSize: font,
                  height: 1,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
