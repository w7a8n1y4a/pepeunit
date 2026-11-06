import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../units/unit.dart';
import '../../units/unit_view.dart';
import '../hex_page.dart';
import '../line_input.dart';
import '../network/line_cell.dart';
import '../network/network_chrome.dart';
import 'units_chrome.dart';

class UnitIoListPage extends StatefulWidget {
  const UnitIoListPage({required this.uuid, required this.scope, super.key});

  final String uuid;
  final int scope;

  @override
  State<UnitIoListPage> createState() => _UnitIoListPageState();
}

class _UnitIoListPageState extends State<UnitIoListPage> {
  List<UnitIo> _ios = const [];
  String? _failure;
  var _open = false;
  var _loading = true;
  var _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(UnitIoListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope) _page = 0;
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = _ios.isEmpty
        ? null
        : tailBoard(
            tick: widget.scope,
            page: _page,
            ids: [for (final io in _ios) io.uuid],
            wide: wide,
          );
    final slots = <HexSlot>[];
    if (board == null) {
      final frame = hexFrame(count: 1, back: HexBack.center, wide: wide);
      slots.add(
        backSlot(
          title: unitText(language, 'Назад', 'Back'),
          q: frame.back!.$1,
          r: frame.back!.$2,
        ),
      );
      slots.add(
        HexSlot(
          id: 'empty',
          title: _loading
              ? unitText(language, 'Входы и выходы', 'Inputs and outputs')
              : unitText(language, 'Пусто', 'Empty'),
          color: unitIoColor,
          busy: _loading,
          tappable: false,
          q: frame.cells.first.$1,
          r: frame.cells.first.$2,
        ),
      );
    } else {
      for (final slot in board.slots) {
        slots.add(_slot(slot, language, board));
      }
    }
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: unitText,
      wide: wide,
    );
    return HexPage(
      slots: slots,
      onTap: (id) {
        if (id == 'back') {
          popOrHome(context);
        } else if (id == 'error') {
          setState(() => _open = true);
        } else if (_ios.any((io) => io.uuid == id)) {
          context.push('/units/${widget.uuid}/io/$id');
        }
      },
      frame: board == null
          ? null
          : (scene) => ScopeFrame(
              scope: widget.scope,
              canZoomIn: board.canZoomIn,
              path: '/units/${widget.uuid}/io',
              child: scene,
            ),
    );
  }

  HexSlot _slot(BoardSlot slot, String language, NetworkBoard board) {
    if (slot.id == 'back') {
      return backSlot(
        title: unitText(language, 'Назад', 'Back'),
        q: slot.q,
        r: slot.r,
      );
    }
    if (slot.id == 'prev' || slot.id == 'next') {
      final forward = slot.id == 'next';
      return pageStepSlot(
        id: slot.id,
        left: !forward,
        language: language,
        color: unitIoColor,
        q: slot.q,
        r: slot.r,
        page: board.page,
        pages: board.pages,
        enabled: forward ? board.page < board.pages - 1 : board.page > 0,
        onTap: () => setState(() => _page = board.page + (forward ? 1 : -1)),
      );
    }
    UnitIo? io;
    for (final item in _ios) {
      if (item.uuid == slot.id) io = item;
    }
    return HexSlot(
      id: slot.id,
      title: io?.topic ?? slot.id,
      sideRight: io?.type,
      footer: io == null ? null : unitVisibilityLabel(language, io.visibility),
      color: unitIoColor,
      q: slot.q,
      r: slot.r,
      icon: 'assets/icons/io.svg',
    );
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
      final ios = <UnitIo>[];
      var offset = 0;
      final limit = model.pageLimit;
      while (true) {
        final page = await model.listIos(
          offset: offset,
          limit: limit,
          unitUuid: widget.uuid,
        );
        ios.addAll(page.ios);
        offset += page.ios.length;
        if (page.ios.isEmpty || offset >= page.count) break;
      }
      if (!mounted) return;
      setState(() {
        _ios = ios;
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

class UnitIoPage extends StatefulWidget {
  const UnitIoPage({required this.unitUuid, required this.uuid, super.key});

  final String unitUuid;
  final String uuid;

  @override
  State<UnitIoPage> createState() => _UnitIoPageState();
}

class _UnitIoPageState extends State<UnitIoPage> {
  UnitIo? _io;
  String? _failure;
  var _open = false;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final io = _io;
    final owned = unitOwnedBy(io?.creatorUuid ?? '', model.target?.userUuid);
    final datapipe =
        model.portraitOf(model.target?.url ?? '')?.datapipe != false;
    final placed = cardBoard(
      ioMenuIds(
        owned: owned,
        input: io?.input ?? false,
        private: io?.visibility == 'Private',
        datapipe: datapipe,
      ),
      wide: wide,
    );
    final slots = <HexSlot>[
      for (final slot in placed) _slot(slot, language, io),
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: unitText,
      wide: wide,
    );
    return HexPage(slots: slots, onTap: (id) => _tap(id, io));
  }

  HexSlot _slot(BoardSlot slot, String language, UnitIo? io) {
    final color = unitIoColor;
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: unitText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'card':
        return HexSlot(
          id: 'card',
          title: io?.topic ?? unitText(language, 'Топик', 'Topic'),
          footer: io?.type,
          color: color,
          busy: _loading,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/io.svg',
        );
      case 'summary':
        final lines = io == null
            ? const ['—']
            : [
                unitVisibilityLabel(language, io.visibility),
                '${unitText(language, 'Связи', 'Links')} ${io.maxConnections}',
                if (io.state != null) io.state!,
                if (io.pipeActive)
                  io.pipeError ??
                      io.pipeStatus ??
                      unitText(language, 'DataPipe', 'DataPipe'),
              ];
        return HexSlot(
          id: 'summary',
          title: unitText(language, 'Сводка', 'Summary'),
          color: color,
          q: slot.q,
          r: slot.r,
          tappable: false,
          body: MetricsCell(lines: lines),
        );
      case 'settings':
        return _nav(slot, language, 'Настройки', 'Settings', 'settings.svg');
      case 'value':
        return _nav(slot, language, 'Значение', 'Value', 'terminal.svg');
      case 'links':
        return _nav(slot, language, 'Связи', 'Links', 'chain.svg');
      case 'pipe':
        return _nav(slot, language, 'DataPipe', 'DataPipe', 'pipe.svg');
      case 'access':
        return _nav(slot, language, 'Доступы', 'Access', 'users.svg');
      default:
        return HexSlot(
          id: slot.id,
          title: slot.id,
          color: color,
          q: slot.q,
          r: slot.r,
        );
    }
  }

  HexSlot _nav(
    BoardSlot slot,
    String language,
    String ru,
    String en,
    String icon,
  ) {
    return HexSlot(
      id: slot.id,
      title: unitText(language, ru, en),
      color: unitIoColor,
      q: slot.q,
      r: slot.r,
      icon: 'assets/icons/$icon',
    );
  }

  Future<void> _tap(String id, UnitIo? io) async {
    final base = '/units/${widget.unitUuid}/io/${widget.uuid}';
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'card':
        await _load();
      case 'settings':
        context.push('$base/settings');
      case 'value':
        context.push('$base/value');
      case 'links':
        context.push('$base/links');
      case 'pipe':
        context.push('$base/pipe');
      case 'access':
        context.push('$base/access');
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

class UnitIoSettingsPage extends StatefulWidget {
  const UnitIoSettingsPage({required this.uuid, super.key});

  final String uuid;

  @override
  State<UnitIoSettingsPage> createState() => _UnitIoSettingsPageState();
}

class _UnitIoSettingsPageState extends State<UnitIoSettingsPage> {
  UnitIo? _io;
  String _visibility = 'Private';
  var _rewritable = false;
  var _pipe = false;
  final _max = TextEditingController();
  String? _failure;
  var _open = false;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final input = _io?.input ?? false;
    final ids = ['visibility', 'max', if (input) 'rewrite', 'pipe', 'save'];
    final placed = cardBoard(ids, wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        switch (slot.id) {
          'back' => backSlot(
            title: unitText(language, 'Назад', 'Back'),
            q: slot.q,
            r: slot.r,
          ),
          'visibility' => HexSlot(
            id: 'visibility',
            title: unitText(language, 'Видимость', 'Visibility'),
            color: unitIoColor,
            q: slot.q,
            r: slot.r,
            tappable: false,
            body: ChoiceWords(
              choices: [
                for (final level in unitVisibilities)
                  (id: level, label: unitVisibilityLabel(language, level)),
              ],
              selected: (id) => _visibility == id,
              onTap: (id) => setState(() => _visibility = id),
            ),
          ),
          'max' => HexSlot(
            id: 'max',
            title: unitText(language, 'Связи', 'Links'),
            color: unitIoColor,
            q: slot.q,
            r: slot.r,
            tappable: false,
            body: LineInput(
              color: unitIoColor,
              controller: _max,
              hint: '0',
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ),
          'rewrite' => HexSlot(
            id: 'rewrite',
            title: _rewritable
                ? unitText(language, 'Перезапись', 'Rewritable')
                : unitText(language, 'Без перезаписи', 'Not rewritable'),
            color: unitIoColor,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/terminal.svg',
          ),
          'pipe' => HexSlot(
            id: 'pipe',
            title: _pipe
                ? unitText(language, 'DataPipe включён', 'DataPipe on')
                : unitText(language, 'DataPipe выключен', 'DataPipe off'),
            color: unitIoColor,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/pipe.svg',
          ),
          'save' => HexSlot(
            id: 'save',
            title: unitText(language, 'Сохранить', 'Save'),
            color: unitIoColor,
            busy: _busy,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/check.svg',
          ),
          _ => HexSlot(
            id: slot.id,
            title: slot.id,
            color: unitIoColor,
            q: slot.q,
            r: slot.r,
          ),
        },
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: unitText,
      wide: wide,
    );
    return HexPage(
      slots: slots,
      onTap: (id) async {
        switch (id) {
          case 'back':
            popOrHome(context);
          case 'error':
            setState(() => _open = true);
          case 'rewrite':
            setState(() => _rewritable = !_rewritable);
          case 'pipe':
            setState(() => _pipe = !_pipe);
          case 'save':
            await _save();
        }
      },
    );
  }

  Future<void> _load() async {
    try {
      final io = await AppScope.of(context).readUnitIo(widget.uuid);
      if (!mounted) return;
      _max.text = '${io.maxConnections}';
      setState(() {
        _io = io;
        _visibility = io.visibility.isEmpty ? 'Private' : io.visibility;
        _rewritable = io.rewritable;
        _pipe = io.pipeActive;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _failure = '$error');
    }
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final io = await AppScope.of(context).updateUnitIo(widget.uuid, {
        'visibility_level': _visibility,
        'max_connections': int.tryParse(_max.text.trim()) ?? 0,
        'is_rewritable_input': _rewritable,
        'is_data_pipe_active': _pipe,
      });
      if (!mounted) return;
      setState(() {
        _io = io;
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
}

class UnitIoValuePage extends StatefulWidget {
  const UnitIoValuePage({required this.uuid, super.key});

  final String uuid;

  @override
  State<UnitIoValuePage> createState() => _UnitIoValuePageState();
}

class _UnitIoValuePageState extends State<UnitIoValuePage> {
  final _value = TextEditingController();
  String? _failure;
  var _open = false;
  var _busy = false;

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(const ['value'], wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        slot.id == 'back'
            ? backSlot(
                title: unitText(language, 'Назад', 'Back'),
                q: slot.q,
                r: slot.r,
              )
            : HexSlot(
                id: 'value',
                title: unitText(language, 'Значение', 'Value'),
                color: unitIoColor,
                busy: _busy,
                q: slot.q,
                r: slot.r,
                tappable: false,
                body: LineInput(
                  color: unitIoColor,
                  controller: _value,
                  hint: unitText(language, 'значение', 'value'),
                  onSubmitted: (_) => _send(),
                ),
              ),
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: unitText,
      wide: wide,
    );
    return HexPage(
      slots: slots,
      onTap: (id) {
        if (id == 'back') popOrHome(context);
        if (id == 'error') setState(() => _open = true);
      },
    );
  }

  Future<void> _send() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      await AppScope.of(context).setInputState(widget.uuid, _value.text);
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

class UnitLinksPage extends StatefulWidget {
  const UnitLinksPage({required this.unitUuid, required this.uuid, super.key});

  final String unitUuid;
  final String uuid;

  @override
  State<UnitLinksPage> createState() => _UnitLinksPageState();
}

class _UnitLinksPageState extends State<UnitLinksPage> {
  List<Unit> _linked = const [];
  String? _failure;
  var _open = false;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final ids = ['add', for (final unit in _linked) 'unit:${unit.uuid}'];
    final placed = cardBoard(ids, wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        if (slot.id == 'back')
          backSlot(
            title: unitText(language, 'Назад', 'Back'),
            q: slot.q,
            r: slot.r,
          )
        else if (slot.id == 'add')
          HexSlot(
            id: 'add',
            title: unitText(language, 'Добавить', 'Add'),
            color: unitIoColor,
            busy: _loading,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/plus.svg',
          )
        else
          HexSlot(
            id: slot.id,
            title: _name(slot.id),
            color: unitIoColor,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/micro.svg',
          ),
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: unitText,
      wide: wide,
    );
    return HexPage(slots: slots, onTap: _tap);
  }

  String _name(String id) {
    final uuid = id.startsWith('unit:') ? id.substring(5) : id;
    for (final unit in _linked) {
      if (unit.uuid == uuid) {
        final topics = [
          for (final io in unit.ios)
            if (io.type == 'Output') io.topic,
        ];
        if (topics.isEmpty) return unit.name;
        return '${unit.name} · ${topics.first}';
      }
    }
    return uuid;
  }

  Future<void> _tap(String id) async {
    if (id == 'back') {
      popOrHome(context);
      return;
    }
    if (id == 'error') {
      setState(() => _open = true);
      return;
    }
    if (id == 'add') {
      final unit = await context.push<String>('/units/pick');
      if (unit == null || !mounted) return;
      final output = await context.push<String>('/units/outputs?unit=$unit');
      if (output == null || !mounted) return;
      try {
        await AppScope.of(context)
            .createIoLink(outputUuid: output, inputUuid: widget.uuid);
        await _load();
      } catch (error) {
        if (!mounted) return;
        setState(() => _failure = '$error');
      }
      return;
    }
    if (id.startsWith('unit:')) {
      context.push('/units/${id.substring(5)}');
    }
  }

  Future<void> _load() async {
    final model = AppScope.of(context);
    try {
      final page = await model.listUnits(
        offset: 0,
        limit: model.pageLimit,
        query: UnitQuery()..owner = 'all',
        inputUuid: widget.uuid,
        includeIos: true,
      );
      if (!mounted) return;
      setState(() {
        _linked = page.units;
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

class UnitOutputsPage extends StatefulWidget {
  const UnitOutputsPage({required this.unitUuid, super.key});

  final String unitUuid;

  @override
  State<UnitOutputsPage> createState() => _UnitOutputsPageState();
}

class _UnitOutputsPageState extends State<UnitOutputsPage> {
  List<UnitIo> _ios = const [];
  String? _failure;
  var _open = false;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard([for (final io in _ios) io.uuid], wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        slot.id == 'back'
            ? backSlot(
                title: unitText(language, 'Назад', 'Back'),
                q: slot.q,
                r: slot.r,
              )
            : HexSlot(
                id: slot.id,
                title:
                    _ios
                        .cast<UnitIo?>()
                        .firstWhere(
                          (io) => io!.uuid == slot.id,
                          orElse: () => null,
                        )
                        ?.topic ??
                    slot.id,
                color: unitIoColor,
                busy: _loading && _ios.isEmpty,
                q: slot.q,
                r: slot.r,
                icon: 'assets/icons/io.svg',
              ),
    ];
    if (_ios.isEmpty && !_loading) {
      final frame = hexFrame(count: 1, back: HexBack.center, wide: wide);
      slots
        ..clear()
        ..add(
          backSlot(
            title: unitText(language, 'Назад', 'Back'),
            q: frame.back!.$1,
            r: frame.back!.$2,
          ),
        )
        ..add(
          HexSlot(
            id: 'empty',
            title: unitText(language, 'Нет выходов', 'No outputs'),
            color: unitIoColor,
            tappable: false,
            q: frame.cells.first.$1,
            r: frame.cells.first.$2,
          ),
        );
    }
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: unitText,
      wide: wide,
    );
    return HexPage(
      slots: slots,
      onTap: (id) {
        if (id == 'back') {
          popOrHome(context);
        } else if (id == 'error') {
          setState(() => _open = true);
        } else if (_ios.any((io) => io.uuid == id)) {
          context.pop(id);
        }
      },
    );
  }

  Future<void> _load() async {
    try {
      final page = await AppScope.of(context).listIos(
        offset: 0,
        limit: AppScope.of(context).pageLimit,
        unitUuid: widget.unitUuid,
        types: const ['Output'],
      );
      if (!mounted) return;
      setState(() {
        _ios = page.ios;
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

class UnitPipePage extends StatefulWidget {
  const UnitPipePage({required this.uuid, super.key});

  final String uuid;

  @override
  State<UnitPipePage> createState() => _UnitPipePageState();
}

class _UnitPipePageState extends State<UnitPipePage> {
  final _editor = TextEditingController();
  String? _failure;
  String? _note;
  var _open = false;
  String? _pending;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(pipeMenuIds, wide: wide);
    final slots = <HexSlot>[for (final slot in placed) _slot(slot, language)];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: unitText,
      wide: wide,
    );
    return HexPage(slots: slots, onTap: _tap);
  }

  HexSlot _slot(BoardSlot slot, String language) {
    if (slot.id == 'back') {
      return backSlot(
        title: unitText(language, 'Назад', 'Back'),
        q: slot.q,
        r: slot.r,
      );
    }
    if (slot.id == 'editor') {
      return HexSlot(
        id: 'editor',
        title: 'YAML',
        footer: _note,
        color: unitIoColor,
        busy: _pending == 'load',
        q: slot.q,
        r: slot.r,
        tappable: false,
        body: Material(
          type: MaterialType.transparency,
          child: TextField(
            controller: _editor,
            maxLines: null,
            cursorColor: unitIoColor,
            style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontFamily: 'JetBrains Mono',
              fontSize: 12,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      );
    }
    final labels = {
      'check': unitText(language, 'Проверить', 'Check'),
      'save': unitText(language, 'Записать', 'Save'),
      'export': unitText(language, 'Скачать', 'Download'),
      'import': unitText(language, 'Загрузить', 'Upload'),
      'data': unitText(language, 'Данные', 'Data'),
      'csvOut': unitText(language, 'CSV скачать', 'CSV out'),
      'csvIn': unitText(language, 'CSV загрузить', 'CSV in'),
      'clear': unitText(language, 'Очистить', 'Clear'),
    };
    return HexSlot(
      id: slot.id,
      title: labels[slot.id] ?? slot.id,
      color: slot.id == 'clear' ? errorColor : unitIoColor,
      busy: _pending == slot.id,
      q: slot.q,
      r: slot.r,
      icon: slot.id == 'clear'
          ? 'assets/icons/close.svg'
          : 'assets/icons/pipe.svg',
    );
  }

  Future<void> _tap(String id) async {
    final model = AppScope.of(context);
    if (id == 'back') {
      popOrHome(context);
      return;
    }
    if (id == 'error') {
      setState(() => _open = true);
      return;
    }
    if (id == 'data') {
      context.push('/units/pipe/${widget.uuid}/data');
      return;
    }
    setState(() {
      _pending = id;
      _failure = null;
      _note = null;
    });
    try {
      final bytes = Uint8List.fromList(utf8.encode(_editor.text));
      switch (id) {
        case 'check':
          final issues = await model.checkPipe(bytes);
          if (!mounted) return;
          setState(() {
            _pending = null;
            if (issues.isEmpty) {
              _note = unitText(model.vault.language, 'Чисто', 'Clear');
            } else {
              _failure = [
                for (final issue in issues) '${issue.stage}: ${issue.message}',
              ].join('\n');
            }
          });
        case 'save':
          await model.setPipe(widget.uuid, bytes);
          if (!mounted) return;
          setState(() => _pending = null);
        case 'export':
          final file = await model.pipeConfig(widget.uuid);
          await model.saveBytes('pipe.yml', file);
          if (!mounted) return;
          setState(() => _pending = null);
        case 'import':
          final file = await model.files.pick();
          if (file == null || !mounted) {
            setState(() => _pending = null);
            return;
          }
          setState(() {
            _editor.text = utf8.decode(file);
            _pending = null;
          });
        case 'csvOut':
          final file = await model.pipeCsv(widget.uuid);
          await model.saveBytes('pipe.csv', file);
          if (!mounted) return;
          setState(() => _pending = null);
        case 'csvIn':
          final file = await model.files.pick();
          if (file == null || !mounted) {
            setState(() => _pending = null);
            return;
          }
          await model.uploadPipeCsv(widget.uuid, file);
          if (!mounted) return;
          setState(() => _pending = null);
        case 'clear':
          await model.deletePipeData(widget.uuid);
          if (!mounted) return;
          setState(() => _pending = null);
        default:
          setState(() => _pending = null);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
    }
  }

  Future<void> _load() async {
    setState(() => _pending = 'load');
    try {
      final bytes = await AppScope.of(context).pipeConfig(widget.uuid);
      if (!mounted) return;
      setState(() {
        _editor.text = utf8.decode(bytes);
        _pending = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
    }
  }
}

class UnitPipeDataPage extends StatefulWidget {
  const UnitPipeDataPage({required this.uuid, required this.scope, super.key});

  final String uuid;
  final int scope;

  @override
  State<UnitPipeDataPage> createState() => _UnitPipeDataPageState();
}

class _UnitPipeDataPageState extends State<UnitPipeDataPage> {
  String _type = 'LastValue';
  var _offset = 0;
  var _count = 0;
  List<PipeRow> _rows = const [];
  String? _failure;
  var _open = false;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final limit = AppScope.of(context).cappedLimit(headPageLimit(widget.scope));
    final board = headBoard(
      tick: widget.scope,
      head: const ['filter', 'window'],
      ids: [for (var i = 0; i < _rows.length; i++) '$i'],
      prefix: 'row:',
      total: _count,
      wide: wide,
    );
    final slots = <HexSlot>[
      for (final slot in board.slots)
        switch (slot.id) {
          'back' => backSlot(
            title: unitText(language, 'Назад', 'Back'),
            q: slot.q,
            r: slot.r,
          ),
          'filter' => HexSlot(
            id: 'filter',
            title: unitText(language, 'Политика', 'Policy'),
            color: unitIoColor,
            q: slot.q,
            r: slot.r,
            tappable: false,
            body: ChoiceWords(
              choices: [
                for (final type in pipePolicies) (id: type, label: type),
              ],
              selected: (id) => _type == id,
              onTap: (id) {
                setState(() {
                  _type = id;
                  _offset = 0;
                });
                _load();
              },
            ),
          ),
          'window' => HexSlot(
            id: 'window',
            title: unitText(language, 'Страница', 'Page'),
            color: unitIoColor,
            busy: _loading,
            q: slot.q,
            r: slot.r,
            body: UnitWindow(
              language: language,
              offset: _offset,
              limit: limit,
              count: _count,
              capacity: headPageLimit(scaleTickMax),
              onStep: (direction) {
                final next = pageShift(
                  direction: direction,
                  offset: _offset,
                  limit: limit,
                  count: _count,
                  capacity: headPageLimit(scaleTickMax),
                );
                if (next == null) return;
                setState(() => _offset = next);
                _load();
              },
            ),
          ),
          _ => HexSlot(
            id: slot.id,
            title: _rowTitle(slot.id),
            footer: _rowTime(slot.id),
            color: unitIoColor,
            q: slot.q,
            r: slot.r,
            tappable: false,
          ),
        },
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: unitText,
      wide: wide,
    );
    return HexPage(
      slots: slots,
      onTap: (id) {
        if (id == 'back') popOrHome(context);
        if (id == 'error') setState(() => _open = true);
      },
      frame: (scene) => ScopeFrame(
        scope: widget.scope,
        canZoomIn: board.canZoomIn,
        path: '/units/pipe/${widget.uuid}/data',
        child: scene,
      ),
    );
  }

  String _rowTitle(String id) {
    final index = int.tryParse(id.startsWith('row:') ? id.substring(4) : '');
    if (index == null || index < 0 || index >= _rows.length) return '';
    return _rows[index].text;
  }

  String? _rowTime(String id) {
    final index = int.tryParse(id.startsWith('row:') ? id.substring(4) : '');
    if (index == null || index < 0 || index >= _rows.length) return null;
    return _rows[index].time;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final page = await AppScope.of(context).pipeData(
        uuid: widget.uuid,
        type: _type,
        offset: _offset,
        limit: AppScope.of(context).cappedLimit(headPageLimit(widget.scope)),
      );
      if (!mounted) return;
      setState(() {
        _rows = page.rows;
        _count = page.count;
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
