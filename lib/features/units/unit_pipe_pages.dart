import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../units/pipe.dart';
import '../../units/unit.dart';
import '../alerts/notice_copy.dart';
import '../code_highlight.dart';
import '../hex_page.dart';
import 'unit_panels.dart';
import 'units_chrome.dart';

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
      text: unitText,
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
            if (!mounted) return;
            setState(() => _editing = false);
            _load();
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
        return backSlot(
          title: unitText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'flag':
        return HexSlot(
          id: 'flag',
          title: 'DataPipe',
          footer: _on
              ? unitText(language, 'вкл', 'on')
              : unitText(language, 'выкл', 'off'),
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
          title: unitText(language, 'Редактор', 'Editor'),
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
          title: unitText(language, 'Удалить все данные', 'Delete all data'),
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
      title: unitText(language, ru, en),
      footer: _done == slot.id ? unitText(language, 'готово', 'done') : null,
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
        dialogTitle: unitText(language, 'CSV с данными', 'CSV with data'),
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
    if (model.target?.signedIn != true) {
      setState(() {
        _loading = false;
        _failure = unitText(model.vault.language, 'Нет входа', 'Not signed in');
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

class _UnitPipePanelState extends State<UnitPipePanel> {
  static const _debounce = Duration(milliseconds: 500);

  final _text = CodeController(language: CodeLanguage.yaml);
  String _baseline = '';
  String? _failure;
  String? _saved;
  String? _pending;
  var _loading = true;
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
    final idle = !_loading && _pending == null;
    final notice = _notice(language);
    return UnitModal(
      title: unitText(language, 'Редактор DataPipe', 'DataPipe editor'),
      color: unitPipeColor,
      onClose: widget.onClose,
      barrierCloses: _clean && _pending == null,
      note: notice.$1,
      noteColor: notice.$2,
      noteLines: 4,
      stackActions: true,
      bodyHeight: (font, width) {
        final codeFont = max(11.0, font * 0.72);
        final layout = UnitCodeLayout(context, codeFont, width, _text.text);
        return max(layout.total, layout.lineHeight * 4) + 8;
      },
      actions: (font) => [
        UnitWordButton(
          label: unitText(language, 'Сохранить', 'Save'),
          font: font,
          color: unitAddColor,
          scale: 1.25,
          enabled: idle && !_flawed,
          busy: _pending == 'save',
          onTap: _save,
        ),
        UnitWordButton(
          label: unitText(language, 'Проверить', 'Check'),
          font: font,
          color: unitPipeColor,
          scale: 1.25,
          enabled: idle,
          busy: _pending == 'check',
          onTap: _checkTap,
        ),
        UnitWordButton(
          label: unitText(language, 'Загрузить', 'Upload'),
          font: font,
          scale: 1.25,
          enabled: idle,
          busy: _pending == 'import',
          onTap: _import,
        ),
        UnitWordButton(
          label: unitText(language, 'Выгрузить', 'Download'),
          font: font,
          scale: 1.25,
          enabled: idle,
          busy: _pending == 'export',
          onTap: _export,
        ),
        NoticeCopyButton(
          text: _text.text,
          label: unitText(language, 'Скопировать', 'Copy'),
          extent: font * 2.2,
        ),
        SizedBox(width: font * 0.2),
        NoticeCloseButton(
          label: unitText(language, 'Закрыть', 'Close'),
          extent: font * 2.2,
          onTap: widget.onClose,
        ),
      ],
      body: (font) => UnitCodeEditor(
        controller: _text,
        fontSize: max(11.0, font * 0.72),
        errorLine: _syntax?.line,
        onChanged: _changed,
      ),
    );
  }

  /// What stands under the editor, and its color.
  (String, Color) _notice(String language) {
    final failure = _failure;
    if (failure != null) return (failure, errorColor);
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
    final model = AppScope.of(context);
    final language = model.vault.language;
    if (model.target?.signedIn != true) {
      setState(() {
        _loading = false;
        _failure = unitText(language, 'Нет входа', 'Not signed in');
      });
      return;
    }
    try {
      final text = widget.filled
          ? utf8.decode(
              await model.pipeConfig(widget.uuid),
              allowMalformed: true,
            )
          : pipeConfigTemplate;
      if (!mounted) return;
      _text.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      setState(() {
        _baseline = text;
        _loading = false;
      });
      await _check();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failure = '$error';
      });
    }
  }

  void _changed() {
    _timer?.cancel();
    setState(() {
      _failure = null;
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
    try {
      final issues = await AppScope.of(context)
          .checkPipe(Uint8List.fromList(utf8.encode(text)));
      if (!mounted || ticket != _generation) return false;
      setState(() {
        _issues = issues;
        _verdictFor = text;
      });
      return issues.isEmpty;
    } catch (error) {
      if (!mounted || ticket != _generation) return false;
      setState(() => _failure = '$error');
      return false;
    }
  }

  Future<void> _checkTap() async {
    if (_pending != null) return;
    final language = AppScope.of(context).vault.language;
    setState(() {
      _pending = 'check';
      _failure = null;
      _saved = null;
    });
    final watch = Stopwatch()..start();
    final ok = await _check();
    await unitSpinnerHold(watch);
    if (!mounted) return;
    setState(() {
      _pending = null;
      if (ok)
        _saved = unitText(language, 'Конфиг корректен', 'The config is valid');
    });
  }

  Future<void> _save() async {
    if (_pending != null || _loading || _flawed) return;
    final model = AppScope.of(context);
    final language = model.vault.language;
    setState(() {
      _pending = 'save';
      _failure = null;
      _saved = null;
    });
    final watch = Stopwatch()..start();
    final text = _text.text;
    try {
      if (!_verified && !await _check()) {
        if (mounted) setState(() => _pending = null);
        return;
      }
      await model.setPipe(widget.uuid, Uint8List.fromList(utf8.encode(text)));
      await unitSpinnerHold(watch);
      if (!mounted) return;
      setState(() {
        _pending = null;
        _baseline = text;
        _saved = unitText(language, 'Сохранено', 'Saved');
      });
      widget.onSaved();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
    }
  }

  Future<void> _import() async {
    if (_pending != null) return;
    final model = AppScope.of(context);
    final language = model.vault.language;
    setState(() {
      _pending = 'import';
      _failure = null;
    });
    try {
      final file = await model.files.pick(
        dialogTitle: unitText(language, 'Конфиг DataPipe', 'DataPipe config'),
      );
      if (!mounted) return;
      if (file == null) {
        setState(() => _pending = null);
        return;
      }
      final text = utf8.decode(file, allowMalformed: true);
      _text.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
      setState(() => _pending = null);
      _changed();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
    }
  }

  Future<void> _export() async {
    if (_pending != null) return;
    final model = AppScope.of(context);
    setState(() {
      _pending = 'export';
      _failure = null;
    });
    try {
      final stem = pipeFileStem(widget.topic, 'data_pipe');
      await model.saveBytes(
        '$stem.yml',
        Uint8List.fromList(utf8.encode(_text.text)),
      );
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
