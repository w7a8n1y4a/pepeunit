import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../locale/failure.dart';
import '../../registry/repo.dart';
import '../../units/code_format.dart';
import '../../units/unit.dart';
import '../../units/unit_read.dart';
import '../code/code_highlight.dart';
import '../code/code_modal.dart';
import '../code/code_panel.dart';
import '../code/code_view.dart';
import 'units_chrome.dart';
import '../../locale/languages.dart';

Color logLevelColor(String level) {
  switch (level.toLowerCase()) {
    case 'info':
      return const Color(0xFF00C853);
    case 'warning':
      return const Color(0xFFFFC107);
    case 'error':
      return errorColor;
    case 'critical':
      return const Color(0xFFC77DFF);
    default:
      return const Color(0xFFFFFFFF);
  }
}

String _logRow(UnitLog log) =>
    '${log.level.toUpperCase()} - ${shortStamp(log.created)} - ${log.text}';

/// Console of one unit. The newest line is in view. Scrolling up asks for
/// the older page. Line numbers stay off.
class UnitLogPanel extends StatefulWidget {
  const UnitLogPanel({required this.uuid, required this.onClose, super.key});

  final String uuid;
  final VoidCallback onClose;

  @override
  State<UnitLogPanel> createState() => _UnitLogPanelState();
}

class _UnitLogPanelState extends State<UnitLogPanel> with CodePanelState {
  final Set<String> _levels = {...logLevels};

  /// Newest first. Older pages are added at the end.
  List<UnitLog> _logs = const [];
  var _count = 0;
  var _offset = 0;
  var _loadingOlder = false;
  var _saving = false;
  var _generation = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    return CodeModal(
      title: localized(language, 'Логи', 'Logs'),
      color: unitsColor,
      onClose: widget.onClose,
      note: failure,
      rows: _logs.length,
      copy: _transcript,
      onDownload: _download,
      downloading: _saving,
      actions: (font) => [
        for (final level in logLevels)
          CodeChip(
            label: level,
            on: _levels.contains(level),
            font: font,
            color: logLevelColor(level),
            onTap: () => _toggle(level),
            hint: 'button-log-level',
          ),
        SizedBox(width: font * 0.3),
      ],
      body: (codeFont, _) => loading && _logs.isEmpty
          ? const SizedBox.expand()
          : LogView(
              count: _logs.length,
              fontSize: codeFont,
              canLoadOlder: !loading && !_loadingOlder && _offset < _count,
              onOlder: _older,
              itemBuilder: (context, index) {
                final log = _logs[index];
                return Text.rich(
                  TextSpan(
                    style: codeMono(codeFont),
                    children: [
                      TextSpan(
                        text: log.level.toUpperCase(),
                        style: codeMono(
                          codeFont,
                          color: logLevelColor(log.level),
                        ),
                      ),
                      TextSpan(
                        text: ' - ${shortStamp(log.created)} - ${log.text}',
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  /// Oldest line first, as a person reads a file.
  String _transcript() => _logs.reversed.map(_logRow).join('\n');

  List<String>? get _filter =>
      _levels.length == logLevels.length ? null : _levels.toList();

  void _toggle(String level) {
    if (_levels.contains(level)) {
      if (_levels.length == 1) return;
      _levels.remove(level);
    } else {
      _levels.add(level);
    }
    _reload();
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    setState(() {
      loading = true;
      _logs = const [];
      _offset = 0;
      failure = null;
    });
    final page = await ask(
      (model) => model.unitLogs(
        uuid: widget.uuid,
        offset: 0,
        limit: model.pageLimit,
        levels: _filter,
      ),
    );
    if (page == null || generation != _generation) return;
    setState(() {
      _logs = page.logs;
      _count = page.count;
      _offset = page.logs.length;
      loading = false;
    });
  }

  Future<void> _older() async {
    if (_loadingOlder || loading || _offset >= _count) return;
    final generation = _generation;
    setState(() => _loadingOlder = true);
    final page = await ask(
      (model) => model.unitLogs(
        uuid: widget.uuid,
        offset: _offset,
        limit: model.pageLimit,
        levels: _filter,
      ),
    );
    if (generation != _generation) return;
    if (page == null) {
      if (mounted) setState(() => _loadingOlder = false);
      return;
    }
    final known = {for (final log in _logs) log.uuid};
    final fresh = [
      for (final log in page.logs)
        if (!known.contains(log.uuid)) log,
    ];
    setState(() {
      _loadingOlder = false;
      if (fresh.isEmpty) {
        _offset = _count;
      } else {
        _logs = [..._logs, ...fresh];
        _offset += page.logs.length;
      }
    });
  }

  Future<void> _download() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      failure = null;
    });
    await ask(
      (model) async => model.saveBytes(
        'unit-${widget.uuid}.log',
        await model.downloadUnitLogs(widget.uuid),
      ),
    );
    if (mounted) setState(() => _saving = false);
  }
}

/// State storage of one unit, with line numbers.
class UnitStoragePanel extends StatefulWidget {
  const UnitStoragePanel({
    required this.uuid,
    required this.onClose,
    super.key,
  });

  final String uuid;
  final VoidCallback onClose;

  @override
  State<UnitStoragePanel> createState() => _UnitStoragePanelState();
}

class _UnitStoragePanelState extends State<UnitStoragePanel>
    with CodePanelState {
  String _text = '';
  var _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    return CodeModal(
      title: localized(language, 'Хранилище аппарата', 'Unit storage'),
      color: unitsColor,
      onClose: widget.onClose,
      note: failure,
      text: _text,
      copy: () => _text,
      onDownload: _download,
      downloading: _saving,
      body: (_, layout) => CodeView(layout: layout!),
    );
  }

  Future<void> _load() async {
    final raw = await ask((model) => model.unitStateStorage(widget.uuid));
    if (raw == null) return;
    setState(() {
      _text = presentStorage(raw);
      loading = false;
    });
  }

  Future<void> _download() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      failure = null;
    });
    final name =
        'storage-${widget.uuid}.${prettyJson(_text) == null ? 'txt' : 'json'}';
    await ask(
      (model) => model.saveBytes(name, Uint8List.fromList(utf8.encode(_text))),
    );
    if (mounted) setState(() => _saving = false);
  }
}

/// JSON editor for the unit environment.
class UnitEnvPanel extends StatefulWidget {
  const UnitEnvPanel({required this.uuid, required this.onClose, super.key});

  final String uuid;
  final VoidCallback onClose;

  @override
  State<UnitEnvPanel> createState() => _UnitEnvPanelState();
}

class _UnitEnvPanelState extends State<UnitEnvPanel> with CodePanelState {
  final _text = CodeController(language: CodeLanguage.json);
  String _baseline = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final syntax = loading ? null : envIssue(language, _text.text);
    final clean = _text.text == _baseline;
    return CodeModal(
      title: localized(
        language,
        'Переменные окружения',
        'Environment variables',
      ),
      color: unitsColor,
      onClose: widget.onClose,
      barrierCloses: clean && pending == null,
      note: syntax?.text ?? failure,
      text: _text.text,
      copy: () => _text.text,
      actions: (font) => [
        CodeWordButton(
          label: localized(language, 'Сохранить', 'Save'),
          font: font,
          color: unitAddColor,
          enabled: !loading && pending == null && syntax == null,
          busy: pending == 'save',
          onTap: _save,
          hint: 'button-env-save',
        ),
        CodeWordButton(
          label: localized(language, 'Сброс', 'Reset'),
          font: font,
          color: const Color(0xFFFFC107),
          enabled: !loading && pending == null,
          busy: pending == 'reset',
          onTap: _reset,
          hint: 'button-env-reset',
        ),
      ],
      body: (_, layout) => CodeEditor(
        controller: _text,
        layout: layout!,
        errorLine: syntax?.line,
        onChanged: () => setState(() => failure = null),
      ),
    );
  }

  Future<void> _load() async {
    final env = await ask((model) => model.unitEnv(widget.uuid));
    if (env == null) return;
    final pretty = envText(env);
    _text.value = TextEditingValue(
      text: pretty,
      selection: TextSelection.collapsed(offset: pretty.length),
    );
    setState(() {
      _baseline = pretty;
      loading = false;
      failure = null;
    });
  }

  Future<void> _save() async {
    final language = AppScope.of(context).vault.language;
    if (envIssue(language, _text.text) != null) return;
    final env = envObject(_text.text);
    if (env == null) return;
    final model = AppScope.of(context);
    if (await work('save', () => model.setUnitEnv(widget.uuid, env))) {
      await _load();
    }
  }

  Future<void> _reset() async {
    final model = AppScope.of(context);
    if (await work('reset', () => model.resetUnitEnv(widget.uuid))) {
      await _load();
    }
  }
}

/// Value of an input or an output, as code with line numbers. An output only
/// reads. An input the user created may be edited and sent.
class UnitIoValuePanel extends StatefulWidget {
  const UnitIoValuePanel({
    required this.uuid,
    required this.input,
    required this.editable,
    required this.onClose,
    this.onSent,
    super.key,
  });

  final String uuid;
  final bool input;
  final bool editable;
  final VoidCallback onClose;

  /// The value went out, so the screen under the panel reads the node again.
  final VoidCallback? onSent;

  @override
  State<UnitIoValuePanel> createState() => _UnitIoValuePanelState();
}

class _UnitIoValuePanelState extends State<UnitIoValuePanel>
    with CodePanelState {
  final _text = CodeController();
  String _baseline = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final clean = _text.text == _baseline;
    return CodeModal(
      title: localized(language, 'Значение', 'Value'),
      color: unitIoTone(widget.input),
      onClose: widget.onClose,
      barrierCloses: !widget.editable || (clean && pending == null),
      note: failure,
      text: _text.text,
      copy: () => _text.text,
      actions: widget.editable
          ? (font) => [
              CodeWordButton(
                label: localized(language, 'Отправить', 'Send'),
                font: font,
                color: unitAddColor,
                enabled: !loading && pending == null,
                busy: pending == 'send',
                onTap: _send,
                hint: 'button-value-send',
              ),
            ]
          : null,
      body: (_, layout) => widget.editable
          ? CodeEditor(
              controller: _text,
              layout: layout!,
              onChanged: () => setState(() => failure = null),
            )
          : CodeView(layout: layout!),
    );
  }

  Future<void> _load() async {
    final io = await ask((model) => model.readUnitIo(widget.uuid));
    if (io == null) return;
    final shown = ioValueShown(io.state);
    _text.value = TextEditingValue(
      text: shown,
      selection: TextSelection.collapsed(offset: shown.length),
    );
    setState(() {
      _baseline = shown;
      loading = false;
      failure = null;
    });
  }

  /// The text goes out as typed. Only the view indents JSON.
  Future<void> _send() async {
    final model = AppScope.of(context);
    final sent = _text.text;
    final ok = await work('send', () async {
      // The broker drops a message over `pu_mqtt_max_payload_size`; say so
      // before the request instead of after it.
      final limit = model.payloadLimitBytes;
      final size = utf8.encode(sent).length;
      if (limit != null && size > limit) {
        throw LocalFailure(
          'Значение занимает $size Б, а инстанс принимает не больше '
              '$limit Б (${limit ~/ 1024} КБ).',
          'The value is $size B, but the instance takes at most '
              '$limit B (${limit ~/ 1024} KB).',
        );
      }
      await model.setInputState(widget.uuid, sent);
    });
    if (ok) {
      setState(() => _baseline = sent);
      widget.onSent?.call();
    }
  }
}
