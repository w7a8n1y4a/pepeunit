import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/link.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../units/pipe.dart';
import '../../units/unit.dart';
import '../code/code_highlight.dart';
import '../code/code_modal.dart';
import '../code/code_panel.dart';
import '../code/code_view.dart';
import '../hex_page.dart';
import 'units_chrome.dart';
import '../../locale/languages.dart';

/// DataPipe of one node. The whole section wears the DataPipe cell color of
/// the node menu, the node's own direction color stays out of it.
///
/// The flag switches the pipe. Off, every other cell is shown and does
/// nothing. The editor is a panel over the menu, and clearing the stored data
/// asks once more on a menu of its own.
class UnitPipePage extends StatefulWidget {
  const UnitPipePage({required this.uuid, super.key});

  final String uuid;

  @override
  State<UnitPipePage> createState() => _UnitPipePageState();
}

class _UnitPipePageState extends State<UnitPipePage> {
  UnitIo? _io;
  String? _failure;
  var _open = false;
  var _loading = true;

  /// Id of the cell whose request is running.
  String? _pending;
  var _editing = false;
  var _confirming = false;

  /// Cell that just finished, for a short «done» on its lower edge.
  String? _done;
  Timer? _doneTimer;

  bool get _ready => _io != null && !_loading;
  bool get _on => _io?.pipeActive == true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _doneTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    // LastValue keeps its one record only in Postgres: there is nothing to
    // upload or download, so those cells are not drawn.
    final lastValue = pipePolicyOfStored(_io?.pipeYml) == 'LastValue';
    final ids = _confirming
        ? const ['confirm']
        : [
            'flag',
            'editor',
            if (!lastValue) ...['import', 'export'],
            'clear',
          ];
    final placed = cardBoard(ids, wide: wide);
    final slots = <HexSlot>[for (final slot in placed) _slot(slot, language)];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      wide: wide,
    );
    final scene = HexPage(slots: slots, onTap: _tap);
    if (!_editing) return scene;
    final io = _io;
    return Stack(
      children: [
        scene,
        UnitPipePanel(
          uuid: widget.uuid,
          topic: io?.topic ?? '',
          filled: (io?.pipeYml ?? '').trim().isNotEmpty,
          onSaved: _load,
          onClose: () {
            if (mounted) setState(() => _editing = false);
          },
        ),
      ],
    );
  }

  HexSlot _slot(BoardSlot slot, String language) {
    final live = _ready && _pending == null;
    final usable = live && _on;
    switch (slot.id) {
      case 'back':
        return backSlot(language, q: slot.q, r: slot.r);
      case 'flag':
        return HexSlot(
          id: 'flag',
          title: 'DataPipe',
          footer: _on
              ? localized(language, 'вкл', 'on')
              : localized(language, 'выкл', 'off'),
          color: unitPipeColor,
          enabled: _ready,
          busy: _pending == 'flag',
          q: slot.q,
          r: slot.r,
          icon: _on
              ? 'assets/icons/status/flag.svg'
              : 'assets/icons/actions/close.svg',
        );
      case 'editor':
        final policy = pipePolicyOfStored(_io?.pipeYml);
        return HexSlot(
          id: 'editor',
          title: localized(language, 'Редактор', 'Editor'),
          footer: policy == null ? null : pipePolicyLabel(language, policy),
          color: unitPipeColor,
          enabled: usable,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/objects/file.svg',
          center: '.yml',
        );
      case 'import':
        return _action(
          slot,
          language,
          enabled: usable,
          ru: 'Загрузить данные',
          en: 'Upload data',
          icon: 'actions/upload.svg',
        );
      case 'export':
        return _action(
          slot,
          language,
          enabled: usable,
          ru: 'Выгрузить данные',
          en: 'Download data',
          icon: 'actions/download.svg',
        );
      case 'clear':
        return _action(
          slot,
          language,
          enabled: usable,
          ru: 'Удалить все данные',
          en: 'Delete all data',
          icon: 'actions/trash.svg',
          color: errorColor,
        );
      case 'confirm':
        return HexSlot(
          id: 'confirm',
          title: localized(language, 'Удалить все данные', 'Delete all data'),
          color: errorColor,
          busy: _pending == 'confirm',
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/actions/trash.svg',
        );
    }
    return HexSlot(
      id: slot.id,
      title: slot.id,
      color: unitPipeColor,
      q: slot.q,
      r: slot.r,
    );
  }

  HexSlot _action(
    BoardSlot slot,
    String language, {
    required bool enabled,
    required String ru,
    required String en,
    required String icon,
    Color color = unitPipeColor,
  }) {
    return HexSlot(
      id: slot.id,
      title: localized(language, ru, en),
      footer: _done == slot.id ? localized(language, 'готово', 'done') : null,
      color: color,
      enabled: enabled,
      busy: _pending == slot.id,
      q: slot.q,
      r: slot.r,
      icon: 'assets/icons/$icon',
    );
  }

  Future<void> _tap(String id) async {
    switch (id) {
      case 'back':
        if (_confirming && _pending == null) {
          setState(() => _confirming = false);
        } else {
          popOrHome(context);
        }
      case 'error':
        setState(() => _open = true);
      case 'flag':
        await _toggle();
      case 'editor':
        if (_ready && _on && _pending == null) {
          setState(() => _editing = true);
        }
      case 'import':
        await _importData();
      case 'export':
        await _exportData();
      case 'clear':
        if (_ready && _on && _pending == null) {
          setState(() => _confirming = true);
        }
      case 'confirm':
        await _clear();
    }
  }

  /// Runs [job] with the cell busy. A refusal goes to the error cell.
  Future<bool> _run(String id, Future<void> Function() job) async {
    if (_pending != null) return false;
    setState(() {
      _pending = id;
      _failure = null;
      _open = false;
    });
    try {
      await job();
      if (!mounted) return false;
      setState(() => _pending = null);
      return true;
    } catch (error) {
      if (!mounted) return false;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
      return false;
    }
  }

  void _flash(String id) {
    _doneTimer?.cancel();
    setState(() => _done = id);
    _doneTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _done = null);
    });
  }

  Future<void> _toggle() async {
    final io = _io;
    if (io == null || !_ready) return;
    final model = AppScope.of(context);
    UnitIo? saved;
    await _run('flag', () async {
      saved = await model.updateUnitIo(widget.uuid, {
        'is_data_pipe_active': !io.pipeActive,
      });
    });
    final next = saved;
    if (next != null && mounted) setState(() => _io = next);
  }

  Future<void> _importData() async {
    if (!_ready || !_on || _pending != null) return;
    final model = AppScope.of(context);
    final language = model.vault.language;
    Uint8List? file;
    try {
      file = await model.files.pick(
        dialogTitle: localized(language, 'CSV с данными', 'CSV with data'),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _failure = '$error');
      return;
    }
    if (file == null || !mounted) return;
    final picked = file;
    final sent = await _run(
      'import',
      () => model.uploadPipeCsv(widget.uuid, picked),
    );
    if (sent) _flash('import');
  }

  Future<void> _exportData() async {
    if (!_ready || !_on || _pending != null) return;
    final model = AppScope.of(context);
    var saved = false;
    final stem = pipeFileStem(_io?.topic ?? '', 'data_pipe');
    final finished = await _run('export', () async {
      // The backend answers with a zip that holds the csv.
      final bytes = await model.pipeCsv(widget.uuid);
      saved = await model.saveBytes('$stem.zip', bytes);
    });
    if (finished && saved) _flash('export');
  }

  Future<void> _clear() async {
    if (!_ready || !_on) return;
    final model = AppScope.of(context);
    final cleared = await _run(
      'confirm',
      () => model.deletePipeData(widget.uuid),
    );
    if (!mounted) return;
    if (cleared) {
      setState(() => _confirming = false);
      _flash('clear');
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
      final io = await model.readUnitIo(widget.uuid);
      if (!mounted) return;
      setState(() {
        _io = io;
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
}

/// The DataPipe config as YAML, in a panel over the menu. The text is checked
/// as it is typed: the syntax here, the rules by the backend. Errors stand
/// under the editor.
class UnitPipePanel extends StatefulWidget {
  const UnitPipePanel({
    required this.uuid,
    required this.topic,
    required this.filled,
    required this.onClose,
    required this.onSaved,
    super.key,
  });

  final String uuid;
  final String topic;

  /// The backend already stores a config. Without one the editor starts from
  /// [pipeConfigTemplate].
  final bool filled;
  final VoidCallback onClose;
  final VoidCallback onSaved;

  @override
  State<UnitPipePanel> createState() => _UnitPipePanelState();
}

class _UnitPipePanelState extends State<UnitPipePanel> with CodePanelState {
  static const _debounce = Duration(milliseconds: 500);

  final _text = CodeController(language: CodeLanguage.yaml);
  String _baseline = '';
  String? _saved;
  var _generation = 0;
  Timer? _timer;

  PipeSyntax? _syntax;
  List<PipeIssue> _issues = const [];

  /// The text the backend's verdict in [_issues] is about.
  String? _verdictFor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _text.dispose();
    super.dispose();
  }

  bool get _clean => _text.text == _baseline;
  bool get _verified => _verdictFor == _text.text;
  bool get _flawed => _syntax != null || (_verified && _issues.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final idle = !loading && pending == null;
    final notice = _notice(language);
    return CodeModal(
      title: localized(language, 'Редактор DataPipe', 'DataPipe editor'),
      color: unitPipeColor,
      onClose: widget.onClose,
      barrierCloses: _clean && pending == null,
      note: notice.$1,
      noteColor: notice.$2,
      noteLines: 4,
      stackActions: true,
      text: _text.text,
      copy: () => _text.text,
      intro: (font) => Link(
        uri: Uri.parse('/library/docs?doc=user/datapipe/datapipe'),
        builder: (context, followLink) => Semantics(
          link: true,
          child: HoverPop(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () =>
                  context.push('/library/docs?doc=user/datapipe/datapipe'),
              child: Text(
                localized(
                  language,
                  'Ссылка на документацию',
                  'Documentation link',
                ),
                style: TextStyle(
                  color: unitPipeColor,
                  fontFamily: 'OpenGost Type B',
                  fontSize: font * CodeWordButton.scale,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
      strip: (font) => [
        Text(
          localized(language, 'Примеры в буфер:', 'Examples to clipboard:'),
          style: codeMono(font * 0.95, color: hexMuted),
        ),
        SizedBox(width: font * 0.3),
        for (final name in pipeExamples.keys)
          CodeChip(
            label: name,
            on: true,
            font: font,
            color: unitPipeColor,
            onTap: () => _copyExample(name),
            hint: 'button-pipe-example-${name.toLowerCase()}',
          ),
      ],
      actions: (font) => [
        CodeWordButton(
          label: localized(language, 'Сохранить', 'Save'),
          font: font,
          color: unitAddColor,
          enabled: idle && !_flawed,
          busy: pending == 'save',
          onTap: _save,
          hint: 'button-pipe-save',
        ),
        CodeWordButton(
          label: localized(language, 'Проверить', 'Check'),
          font: font,
          color: Colors.yellow,
          enabled: idle,
          busy: pending == 'check',
          onTap: _checkTap,
          hint: 'button-pipe-check',
        ),
        CodeWordButton(
          label: localized(language, 'Загрузить', 'Upload'),
          font: font,
          enabled: idle,
          busy: pending == 'import',
          onTap: _import,
          hint: 'button-pipe-import',
        ),
        CodeWordButton(
          label: localized(language, 'Выгрузить', 'Download'),
          font: font,
          enabled: idle,
          busy: pending == 'export',
          onTap: _export,
          hint: 'button-pipe-export',
        ),
      ],
      body: (_, layout) => CodeEditor(
        controller: _text,
        layout: layout!,
        errorLine: _syntax?.line,
        onChanged: _changed,
      ),
    );
  }

  /// What stands under the editor, and its color.
  (String, Color) _notice(String language) {
    final failed = failure;
    if (failed != null) return (failed, errorColor);
    final syntax = _syntax;
    if (syntax != null) return (pipeSyntaxText(language, syntax), errorColor);
    if (_verified && _issues.isNotEmpty) {
      return (
        [for (final issue in _issues) pipeIssueText(issue)].join('\n'),
        errorColor,
      );
    }
    final saved = _saved;
    if (saved != null) return (saved, addColor);
    return ('', errorColor);
  }

  Future<void> _load() async {
    final text = await ask(
      (model) async => widget.filled
          ? utf8.decode(
              await model.pipeConfig(widget.uuid),
              allowMalformed: true,
            )
          : pipeConfigTemplate,
    );
    if (text == null) return;
    _put(text);
    setState(() {
      _baseline = text;
      loading = false;
    });
    await _check();
  }

  void _put(String text) {
    _text.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _changed() {
    _timer?.cancel();
    setState(() {
      failure = null;
      _saved = null;
      _syntax = pipeSyntaxIssue(_text.text);
    });
    if (_syntax == null) _timer = Timer(_debounce, _check);
  }

  /// Syntax first, then the backend. False when the text has problems or the
  /// text changed while the answer was on its way.
  Future<bool> _check() async {
    _timer?.cancel();
    final text = _text.text;
    final ticket = ++_generation;
    final syntax = pipeSyntaxIssue(text);
    if (syntax != null) {
      setState(() => _syntax = syntax);
      return false;
    }
    setState(() => _syntax = null);
    final issues = await ask(
      (model) => model.checkPipe(Uint8List.fromList(utf8.encode(text))),
    );
    if (issues == null || ticket != _generation) return false;
    setState(() {
      _issues = issues;
      _verdictFor = text;
    });
    return issues.isEmpty;
  }

  Future<void> _checkTap() async {
    if (pending != null) return;
    final language = AppScope.of(context).vault.language;
    setState(() {
      pending = 'check';
      failure = null;
      _saved = null;
    });
    final watch = Stopwatch()..start();
    final ok = await _check();
    await holdSpinner(watch);
    if (!mounted) return;
    setState(() {
      pending = null;
      if (ok) {
        _saved = localized(language, 'Конфиг корректен', 'The config is valid');
      }
    });
  }

  Future<void> _save() async {
    if (pending != null || loading || _flawed) return;
    final model = AppScope.of(context);
    final language = model.vault.language;
    final text = _text.text;
    var skipped = false;
    _saved = null;
    final saved = await work('save', () async {
      if (!_verified && !await _check()) {
        skipped = true;
        return;
      }
      await model.setPipe(widget.uuid, Uint8List.fromList(utf8.encode(text)));
    });
    if (!saved || skipped) return;
    setState(() {
      _baseline = text;
      _saved = localized(language, 'Сохранено', 'Saved');
    });
    widget.onSaved();
  }

  /// Puts the example [name] on the clipboard. The editor text stays.
  Future<void> _copyExample(String name) async {
    final text = pipeExamples[name];
    if (text == null) return;
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    final language = AppScope.of(context).vault.language;
    setState(() {
      failure = null;
      _saved = localized(
        language,
        'Пример $name скопирован в буфер обмена',
        'Example $name copied to the clipboard',
      );
    });
  }

  Future<void> _import() async {
    final model = AppScope.of(context);
    final language = model.vault.language;
    String? text;
    final picked = await work('import', () async {
      final file = await model.files.pick(
        dialogTitle: localized(language, 'Конфиг DataPipe', 'DataPipe config'),
      );
      if (file != null) text = utf8.decode(file, allowMalformed: true);
    }, hold: false);
    if (!picked || text == null) return;
    _put(text!);
    _changed();
  }

  Future<void> _export() async {
    final model = AppScope.of(context);
    final stem = pipeFileStem(widget.topic, 'data_pipe');
    await work(
      'export',
      () => model.saveBytes(
        '$stem.yml',
        Uint8List.fromList(utf8.encode(_text.text)),
      ),
      hold: false,
    );
  }
}
