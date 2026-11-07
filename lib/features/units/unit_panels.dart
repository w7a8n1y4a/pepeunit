import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../registry/repo.dart';
import '../../units/unit.dart';
import '../../units/unit_read.dart';
import '../alerts/alerts_chrome.dart';
import '../alerts/notice_copy.dart';
import '../code_highlight.dart';
import 'units_chrome.dart';

/// Framed panel used for logs, storage and the environment editor.
class UnitModal extends StatelessWidget {
  const UnitModal({
    required this.title,
    required this.color,
    required this.onClose,
    required this.actions,
    required this.body,
    this.note,
    this.noteColor = errorColor,
    this.noteLines = 2,
    this.bodyHeight,
    this.barrierCloses = true,
    this.stackActions = false,
    super.key,
  });

  final String title;
  final Color color;
  final VoidCallback onClose;
  final List<Widget> Function(double font) actions;
  final Widget Function(double font) body;

  /// Desired body height at the given font. The panel shrinks to it when
  /// the text fits, and stops at the screen when it does not.
  final double Function(double font, double width)? bodyHeight;
  final String? note;
  final Color noteColor;

  /// Lines the note keeps in view. A longer note scrolls.
  final int noteLines;
  final bool barrierCloses;

  /// Many actions: on a narrow screen they take a row under the title, so
  /// the title keeps its place.
  final bool stackActions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final margin = min(size.width, size.height) * 0.06;
        final font = max(12.0, size.shortestSide * 0.018);
        final shown = note?.trim() ?? '';
        final rowH = font * 2.35;
        final gap = font * 0.35;
        final errorH = font * 1.25 * noteLines;
        final noteStyle = TextStyle(
          color: noteColor,
          fontFamily: 'OpenGost Type B',
          fontSize: font,
          decoration: TextDecoration.none,
        );
        final stacked = stackActions && size.width < 640;
        final chrome =
            font * 0.6 + rowH * (stacked ? 2 : 1) + gap + gap + errorH + font;
        final maxH = max(chrome + font * 4, size.height - margin * 2);
        final wanted =
            bodyHeight?.call(font, size.width - margin * 2 - font * 1.4) ??
            (maxH - chrome);
        final bodyH = wanted.clamp(font * 4, maxH - chrome).toDouble();
        final height = (chrome + bodyH)
            .clamp(chrome + font * 4, maxH)
            .toDouble();
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  if (barrierCloses) onClose();
                },
              ),
            ),
            Positioned(
              left: margin,
              top: margin,
              right: margin,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: hexFill,
                  border: Border.all(
                    color: color,
                    width: max(1.4, font * 0.12),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    font,
                    font * 0.6,
                    font * 0.4,
                    font,
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: rowH,
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: const Color(0xFFFFFFFF),
                                  fontFamily: 'OpenGost Type B',
                                  fontSize: font * 1.55,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            if (!stacked)
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(children: actions(font)),
                              ),
                          ],
                        ),
                      ),
                      if (stacked)
                        SizedBox(
                          height: rowH,
                          width: double.infinity,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(children: actions(font)),
                          ),
                        ),
                      SizedBox(height: gap),
                      Expanded(child: body(font)),
                      SizedBox(height: gap),
                      SizedBox(
                        height: errorH,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: noteLines > 2
                              ? SingleChildScrollView(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: Text(shown, style: noteStyle),
                                  ),
                                )
                              : Text(
                                  shown,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: noteStyle,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class UnitWordButton extends StatelessWidget {
  const UnitWordButton({
    required this.label,
    required this.font,
    required this.onTap,
    this.color = const Color(0xFFFFFFFF),
    this.enabled = true,
    this.busy = false,
    this.scale = 1.05,
    super.key,
  });

  final String label;
  final double font;
  final VoidCallback onTap;
  final Color color;
  final bool enabled;

  /// A request started by this button is running. The label keeps its
  /// color and a spinner stands before it.
  final bool busy;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return HoverPop(
      enabled: enabled,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: font * 0.45),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (busy) ...[
                  _ModalSpinner(extent: font * scale * 0.8, color: color),
                  SizedBox(width: font * 0.4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: enabled || busy ? color : hexMuted,
                    fontFamily: 'OpenGost Type B',
                    fontSize: font * scale,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// How long a modal button keeps its spinner at least. A fast answer would
/// otherwise end it before a frame is drawn.
const _spinnerMin = Duration(milliseconds: 600);

/// Waits out what is left of [_spinnerMin] since [watch] started.
Future<void> unitSpinnerHold(Stopwatch watch) async {
  final left = _spinnerMin - watch.elapsed;
  if (left > Duration.zero) await Future<void>.delayed(left);
}

/// Small arc that turns while a modal button waits on its request.
class _ModalSpinner extends StatelessWidget {
  const _ModalSpinner({required this.extent, required this.color});

  final double extent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: extent,
      height: extent,
      child: CircularProgressIndicator(
        strokeWidth: max(1.5, extent * 0.14),
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _DownButton extends StatelessWidget {
  const _DownButton({
    required this.label,
    required this.extent,
    required this.onTap,
    this.busy = false,
  });

  final String label;
  final double extent;
  final VoidCallback onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return HoverPop(
      child: Semantics(
        button: true,
        label: label,
        child: GestureDetector(
          onTap: busy ? null : onTap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: extent,
            height: extent,
            child: busy
                ? Padding(
                    padding: EdgeInsets.all(extent * 0.26),
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFFFFFFF),
                      ),
                    ),
                  )
                : const CustomPaint(painter: _DownPainter(Color(0xFFFFFFFF))),
          ),
        ),
      ),
    );
  }
}

class _DownPainter extends CustomPainter {
  const _DownPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final w = size.width;
    final h = size.height;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.14),
      Offset(w * 0.5, h * 0.58),
      paint,
    );
    canvas.drawLine(Offset(w * 0.28, h * 0.4), Offset(w * 0.5, h * 0.6), paint);
    canvas.drawLine(Offset(w * 0.72, h * 0.4), Offset(w * 0.5, h * 0.6), paint);
    final tray = Path()
      ..moveTo(w * 0.18, h * 0.72)
      ..lineTo(w * 0.18, h * 0.88)
      ..lineTo(w * 0.82, h * 0.88)
      ..lineTo(w * 0.82, h * 0.72);
    canvas.drawPath(tray, paint);
  }

  @override
  bool shouldRepaint(covariant _DownPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LevelChip extends StatelessWidget {
  const _LevelChip({
    required this.label,
    required this.on,
    required this.font,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool on;
  final double font;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HoverPop(
      child: Semantics(
        button: true,
        selected: on,
        label: label,
        child: GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: font * 0.35),
            child: Text(
              label,
              style: noticeMono(font * 0.95, color: on ? color : hexMuted),
            ),
          ),
        ),
      ),
    );
  }
}

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

/// Console of one unit. The newest line is in view. Scrolling up asks for
/// the older page. Line numbers stay off.
class UnitLogPanel extends StatefulWidget {
  const UnitLogPanel({required this.uuid, required this.onClose, super.key});

  final String uuid;
  final VoidCallback onClose;

  @override
  State<UnitLogPanel> createState() => _UnitLogPanelState();
}

class _UnitLogPanelState extends State<UnitLogPanel> {
  final _scroll = ScrollController();
  final Set<String> _levels = {...logLevels};
  List<UnitLog> _logs = const [];
  var _count = 0;
  var _offset = 0;
  var _loading = true;
  var _loadingOlder = false;
  var _pinned = false;
  var _saving = false;
  var _generation = 0;
  String? _failure;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final copy = _transcript();
    return UnitModal(
      title: unitText(language, 'Логи', 'Logs'),
      color: unitsColor,
      onClose: widget.onClose,
      note: _failure,
      bodyHeight: (font, _) => _linesHeight(font, _logs.length),
      actions: (font) => [
        for (final level in logLevels)
          _LevelChip(
            label: level,
            on: _levels.contains(level),
            font: font,
            color: logLevelColor(level),
            onTap: () => _toggle(level),
          ),
        SizedBox(width: font * 0.3),
        NoticeCopyButton(
          text: copy,
          label: unitText(language, 'Скопировать', 'Copy'),
          extent: font * 2.2,
        ),
        _DownButton(
          label: unitText(language, 'Скачать', 'Download'),
          extent: font * 2.2,
          busy: _saving,
          onTap: _download,
        ),
        SizedBox(width: font * 0.2),
        NoticeCloseButton(
          label: unitText(language, 'Закрыть', 'Close'),
          extent: font * 2.2,
          onTap: widget.onClose,
        ),
      ],
      body: (font) => _console(font),
    );
  }

  Widget _console(double font) {
    if (_loading && _logs.isEmpty) {
      return const SizedBox.expand();
    }
    final codeFont = max(11.0, font * 0.72);
    return Scrollbar(
      controller: _scroll,
      thumbVisibility: true,
      child: SelectionArea(
        child: ListView.builder(
          controller: _scroll,
          padding: EdgeInsets.only(right: font, bottom: font),
          itemCount: _logs.length,
          itemBuilder: (context, index) {
            final log = _logs[index];
            return Text.rich(
              TextSpan(
                style: noticeMono(codeFont),
                children: [
                  TextSpan(
                    text: log.level.toUpperCase(),
                    style: noticeMono(
                      codeFont,
                      color: logLevelColor(log.level),
                    ),
                  ),
                  TextSpan(text: ' - ${shortStamp(log.created)} - ${log.text}'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _transcript() {
    return [
      for (final log in _logs)
        '${log.level.toUpperCase()} - ${shortStamp(log.created)} - ${log.text}',
    ].join('\n');
  }

  void _toggle(String level) {
    if (_levels.contains(level)) {
      if (_levels.length == 1) return;
      _levels.remove(level);
    } else {
      _levels.add(level);
    }
    _reload();
  }

  void _onScroll() {
    if (!_pinned || !_scroll.hasClients || _loading || _loadingOlder) return;
    final position = _scroll.position;
    if (position.pixels <= 48 &&
        position.pixels < position.maxScrollExtent - 8) {
      _older();
    }
  }

  Future<void> _reload() async {
    final generation = ++_generation;
    final model = AppScope.of(context);
    final language = model.vault.language;
    if (model.target?.signedIn != true) {
      setState(() {
        _loading = false;
        _failure = unitText(language, 'Нет входа', 'Not signed in');
      });
      return;
    }
    final levels = _levels.length == logLevels.length ? null : _levels.toList();
    setState(() {
      _loading = true;
      _pinned = false;
      _logs = const [];
      _offset = 0;
      _failure = null;
    });
    try {
      final page = await model.unitLogs(
        uuid: widget.uuid,
        offset: 0,
        limit: model.pageLimit,
        levels: levels,
      );
      if (!mounted || generation != _generation) return;
      setState(() {
        _logs = page.logs.reversed.toList();
        _count = page.count;
        _offset = page.logs.length;
        _loading = false;
      });
      _pinBottom();
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _failure = '$error';
      });
    }
  }

  Future<void> _older() async {
    if (_loadingOlder || _loading || _offset >= _count) return;
    final generation = _generation;
    final model = AppScope.of(context);
    setState(() => _loadingOlder = true);
    final levels = _levels.length == logLevels.length ? null : _levels.toList();
    final before = _scroll.hasClients ? _scroll.position.maxScrollExtent : 0.0;
    final anchor = _scroll.hasClients ? _scroll.offset : 0.0;
    try {
      final page = await model.unitLogs(
        uuid: widget.uuid,
        offset: _offset,
        limit: model.pageLimit,
        levels: levels,
      );
      if (!mounted || generation != _generation) return;
      final known = {for (final log in _logs) log.uuid};
      final fresh = [
        for (final log in page.logs.reversed)
          if (!known.contains(log.uuid)) log,
      ];
      setState(() {
        _loadingOlder = false;
        if (fresh.isEmpty) {
          _offset = _count;
        } else {
          _logs = [...fresh, ..._logs];
          _offset += page.logs.length;
        }
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients || generation != _generation) {
          return;
        }
        final delta = _scroll.position.maxScrollExtent - before;
        if (delta > 0) _scroll.jumpTo(anchor + delta);
        if (_scroll.position.maxScrollExtent <= 0 && _offset < _count) {
          _older();
        }
      });
    } catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loadingOlder = false;
        _failure = '$error';
      });
    }
  }

  void _pinBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final position = _scroll.position;
      if (position.maxScrollExtent > 0) {
        _scroll.jumpTo(position.maxScrollExtent);
      }
      _pinned = true;
      if (position.maxScrollExtent <= 0 && _offset < _count) _older();
    });
  }

  Future<void> _download() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failure = null;
    });
    try {
      final model = AppScope.of(context);
      final bytes = await model.downloadUnitLogs(widget.uuid);
      if (!mounted) return;
      await model.saveBytes('unit-${widget.uuid}.log', bytes);
    } catch (error) {
      if (!mounted) return;
      setState(() => _failure = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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

class _UnitStoragePanelState extends State<UnitStoragePanel> {
  String _text = '';
  String? _failure;
  var _loading = true;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    return UnitModal(
      title: unitText(language, 'Хранилище аппарата', 'Unit storage'),
      color: unitsColor,
      onClose: widget.onClose,
      note: _failure,
      bodyHeight: (font, _) => _linesHeight(font, _lineCount(_text)),
      actions: (font) => [
        NoticeCopyButton(
          text: _text,
          label: unitText(language, 'Скопировать', 'Copy'),
          extent: font * 2.2,
        ),
        _DownButton(
          label: unitText(language, 'Скачать', 'Download'),
          extent: font * 2.2,
          busy: _saving,
          onTap: _download,
        ),
        SizedBox(width: font * 0.2),
        NoticeCloseButton(
          label: unitText(language, 'Закрыть', 'Close'),
          extent: font * 2.2,
          onTap: widget.onClose,
        ),
      ],
      body: (font) => _NumberedText(
        text: _loading ? '' : _text,
        fontSize: max(11.0, font * 0.72),
      ),
    );
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
      final raw = await model.unitStateStorage(widget.uuid);
      if (!mounted) return;
      setState(() {
        _text = presentStorage(raw);
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

  Future<void> _download() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _failure = null;
    });
    final json =
        _text.trimLeft().startsWith('{') || _text.trimLeft().startsWith('[');
    final name = 'storage-${widget.uuid}.${json ? 'json' : 'txt'}';
    try {
      final saved = await AppScope.of(context)
          .saveBytes(name, Uint8List.fromList(utf8.encode(_text)));
      if (!mounted) return;
      setState(() => _saving = false);
      if (!saved) return;
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _failure = '$error';
      });
    }
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

class _UnitEnvPanelState extends State<UnitEnvPanel> {
  final _text = CodeController(language: CodeLanguage.json);
  String _baseline = '';
  String? _failure;
  var _loading = true;
  String? _pending;

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
    final syntax = _loading ? null : envIssue(language, _text.text);
    final clean = _text.text == _baseline;
    return UnitModal(
      title: unitText(
        language,
        'Переменные окружения',
        'Environment variables',
      ),
      color: unitsColor,
      onClose: widget.onClose,
      barrierCloses: clean && _pending == null,
      note: syntax?.text ?? _failure,
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
          scale: 1.5,
          enabled: !_loading && _pending == null && syntax == null,
          busy: _pending == 'save',
          onTap: _save,
        ),
        UnitWordButton(
          label: unitText(language, 'Сброс', 'Reset'),
          font: font,
          color: const Color(0xFFFFC107),
          scale: 1.5,
          enabled: !_loading && _pending == null,
          busy: _pending == 'reset',
          onTap: _reset,
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
        errorLine: syntax?.line,
        onChanged: () => setState(() => _failure = null),
      ),
    );
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
      final env = await model.unitEnv(widget.uuid);
      if (!mounted) return;
      final pretty = envText(env);
      _text.value = TextEditingValue(
        text: pretty,
        selection: TextSelection.collapsed(offset: pretty.length),
      );
      setState(() {
        _baseline = pretty;
        _loading = false;
        _failure = null;
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
    if (_pending != null) return;
    final language = AppScope.of(context).vault.language;
    if (envIssue(language, _text.text) != null) return;
    final env = envObject(_text.text);
    if (env == null) return;
    setState(() {
      _pending = 'save';
      _failure = null;
    });
    final watch = Stopwatch()..start();
    try {
      await AppScope.of(context).setUnitEnv(widget.uuid, env);
      await unitSpinnerHold(watch);
      if (!mounted) return;
      setState(() => _pending = null);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
    }
  }

  Future<void> _reset() async {
    if (_pending != null) return;
    setState(() {
      _pending = 'reset';
      _failure = null;
    });
    final watch = Stopwatch()..start();
    try {
      await AppScope.of(context).resetUnitEnv(widget.uuid);
      await unitSpinnerHold(watch);
      if (!mounted) return;
      setState(() => _pending = null);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
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
    super.key,
  });

  final String uuid;
  final bool input;
  final bool editable;
  final VoidCallback onClose;

  @override
  State<UnitIoValuePanel> createState() => _UnitIoValuePanelState();
}

class _UnitIoValuePanelState extends State<UnitIoValuePanel> {
  final _text = CodeController();
  String _baseline = '';
  String? _failure;
  var _loading = true;
  var _sending = false;

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
    final color = unitIoTone(widget.input);
    final clean = _text.text == _baseline;
    return UnitModal(
      title: unitText(language, 'Значение', 'Value'),
      color: color,
      onClose: widget.onClose,
      barrierCloses: !widget.editable || (clean && !_sending),
      note: _failure,
      bodyHeight: widget.editable
          ? (font, width) {
              final codeFont = max(11.0, font * 0.72);
              final layout = UnitCodeLayout(context, codeFont, width, _text.text);
              return max(layout.total, layout.lineHeight * 4) + 8;
            }
          : (font, _) => _linesHeight(font, _lineCount(_text.text)) + 14,
      actions: (font) => [
        if (widget.editable)
          UnitWordButton(
            label: unitText(language, 'Отправить', 'Send'),
            font: font,
            color: unitAddColor,
            scale: 1.5,
            enabled: !_loading && !_sending,
            busy: _sending,
            onTap: _send,
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
      body: (font) => widget.editable
          ? UnitCodeEditor(
              controller: _text,
              fontSize: max(11.0, font * 0.72),
              onChanged: () => setState(() => _failure = null),
            )
          : _NumberedText(text: _text.text, fontSize: max(11.0, font * 0.72)),
    );
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
      final io = await model.readUnitIo(widget.uuid);
      if (!mounted) return;
      final shown = ioValueShown(io.state);
      _text.value = TextEditingValue(
        text: shown,
        selection: TextSelection.collapsed(offset: shown.length),
      );
      setState(() {
        _baseline = shown;
        _loading = false;
        _failure = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failure = '$error';
      });
    }
  }

  /// The text goes out as typed. Only the view indents JSON.
  Future<void> _send() async {
    if (_sending) return;
    final sent = _text.text;
    setState(() {
      _sending = true;
      _failure = null;
    });
    final watch = Stopwatch()..start();
    try {
      await AppScope.of(context).setInputState(widget.uuid, sent);
      await unitSpinnerHold(watch);
      if (!mounted) return;
      setState(() {
        _sending = false;
        _baseline = sent;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _failure = '$error';
      });
    }
  }
}

int _lineCount(String text) {
  if (text.isEmpty) return 1;
  return '\n'.allMatches(text).length + 1;
}

StrutStyle unitCodeStrut(double fontSize) {
  return StrutStyle(
    fontFamily: noticeMonoFamily,
    fontSize: fontSize,
    height: 1.35,
    forceStrutHeight: true,
  );
}

/// One code row, measured the same way the field lays lines out.
double unitCodeLineHeight(BuildContext context, double fontSize) {
  final painter = TextPainter(
    text: TextSpan(text: '0', style: noticeMono(fontSize)),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
    strutStyle: unitCodeStrut(fontSize),
  )..layout(maxWidth: double.infinity);
  final height = painter.preferredLineHeight;
  painter.dispose();
  return height;
}

double _linesHeight(double font, int lines) {
  final codeFont = max(11.0, font * 0.72);
  return max(4, lines) * codeFont * 1.35 + font * 0.4;
}

/// Row heights of the env text at a given width. A line that does not fit
/// wraps inside its own block, so it keeps one number.
class UnitCodeLayout {
  UnitCodeLayout(BuildContext context, double fontSize, double width, String text)
    : lineHeight = unitCodeLineHeight(context, fontSize) {
    final style = noticeMono(fontSize);
    final strut = unitCodeStrut(fontSize);
    final scaler = MediaQuery.textScalerOf(context);
    final lines = text.split('\n');
    final digits = lines.length.toString().length;
    final gutter = TextPainter(
      text: TextSpan(text: '0' * digits, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      strutStyle: strut,
    )..layout();
    gutterWidth = gutter.width + fontSize;
    gutter.dispose();
    // The field keeps room for the caret: gap 1 plus cursor width 2.
    final available = max(1.0, width - gutterWidth - 3.0);
    for (final line in lines) {
      final painter = TextPainter(
        text: TextSpan(text: line.isEmpty ? ' ' : line, style: style),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        strutStyle: strut,
      )..layout(maxWidth: available);
      heights.add(max(lineHeight, painter.height));
      painter.dispose();
    }
  }

  final double lineHeight;
  late final double gutterWidth;
  final heights = <double>[];

  double get total => heights.fold(0.0, (sum, h) => sum + h);
}

class UnitCodeEditor extends StatefulWidget {
  const UnitCodeEditor({
    required this.controller,
    required this.fontSize,
    required this.onChanged,
    this.errorLine,
    super.key,
  });

  final TextEditingController controller;
  final double fontSize;
  final int? errorLine;
  final VoidCallback onChanged;

  @override
  State<UnitCodeEditor> createState() => _UnitCodeEditorState();
}

class _UnitCodeEditorState extends State<UnitCodeEditor> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = noticeMono(widget.fontSize);
    final strut = unitCodeStrut(widget.fontSize);
    return Material(
      type: MaterialType.transparency,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final layout = UnitCodeLayout(
            context,
            widget.fontSize,
            constraints.maxWidth,
            widget.controller.text,
          );
          return Scrollbar(
            controller: _scroll,
            child: SingleChildScrollView(
              controller: _scroll,
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: layout.gutterWidth,
                      child: IgnorePointer(
                        child: Column(
                          children: [
                            for (var i = 0; i < layout.heights.length; i++)
                              SizedBox(
                                height: layout.heights[i],
                                child: Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: widget.fontSize * 0.7,
                                    ),
                                    child: Text(
                                      '${i + 1}',
                                      strutStyle: strut,
                                      style: style.copyWith(
                                        color: i + 1 == widget.errorLine
                                            ? errorColor
                                            : const Color(0xFFE8E8EE),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        key: const ValueKey('unit-env'),
                        controller: widget.controller,
                        maxLines: null,
                        autocorrect: false,
                        enableSuggestions: false,
                        smartDashesType: SmartDashesType.disabled,
                        smartQuotesType: SmartQuotesType.disabled,
                        style: style,
                        strutStyle: strut,
                        cursorColor: const Color(0xFFFFFFFF),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (_) => widget.onChanged(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NumberedText extends StatefulWidget {
  const _NumberedText({required this.text, required this.fontSize});

  final String text;
  final double fontSize;

  @override
  State<_NumberedText> createState() => _NumberedTextState();
}

class _NumberedTextState extends State<_NumberedText> {
  final _vertical = ScrollController();
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.text.isEmpty ? const [''] : widget.text.split('\n');
    final colored = codeTokens(widget.text, CodeLanguage.auto);
    final style = noticeMono(widget.fontSize);
    final numberStyle = style.copyWith(color: hexMuted);
    final sample = TextPainter(
      text: TextSpan(text: '0', style: style),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final lineHeight = sample.height;
    sample.dispose();
    final digits = lines.length.toString().length;
    final gutter = TextPainter(
      text: TextSpan(text: '0' * digits, style: numberStyle),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final gutterWidth = gutter.width + widget.fontSize;
    gutter.dispose();
    var codeWidth = 0.0;
    for (final line in lines) {
      if (line.isEmpty) continue;
      final painter = TextPainter(
        text: TextSpan(text: line, style: style),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      if (painter.width > codeWidth) codeWidth = painter.width;
      painter.dispose();
    }
    const bar = 8.0;
    final theme = ScrollbarThemeData(
      thumbVisibility: const WidgetStatePropertyAll(true),
      trackVisibility: const WidgetStatePropertyAll(true),
      thickness: const WidgetStatePropertyAll(bar),
      radius: const Radius.circular(4),
      thumbColor: const WidgetStatePropertyAll(Color(0xFF8A8A92)),
      trackColor: const WidgetStatePropertyAll(Color(0xFF2C2C32)),
      trackBorderColor: const WidgetStatePropertyAll(Color(0x00000000)),
    );
    return ScrollbarTheme(
      data: theme,
      child: Scrollbar(
        controller: _vertical,
        thumbVisibility: true,
        child: Scrollbar(
          controller: _horizontal,
          thumbVisibility: true,
          notificationPredicate: (notification) =>
              notification.metrics.axis == Axis.horizontal,
          child: SingleChildScrollView(
            controller: _vertical,
            padding: const EdgeInsets.only(bottom: bar + 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: gutterWidth,
                  child: Column(
                    children: [
                      for (var i = 0; i < lines.length; i++)
                        SizedBox(
                          height: lineHeight,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: widget.fontSize * 0.7,
                              ),
                              child: Text('${i + 1}', style: numberStyle),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _horizontal,
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: max(codeWidth, 1) + widget.fontSize,
                      child: SelectionArea(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final tokens in colored)
                              SizedBox(
                                height: lineHeight,
                                child: Text.rich(
                                  TextSpan(
                                    style: style,
                                    children: codeLineSpans(tokens, style),
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
