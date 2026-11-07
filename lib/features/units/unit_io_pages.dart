import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../registry/repo.dart';
import '../../units/unit.dart';
import '../../units/unit_read.dart';
import '../../units/unit_view.dart';
import '../hex_page.dart';
import '../line_input.dart';
import '../network/network_chrome.dart';
import 'unit_panels.dart';
import 'units_chrome.dart';

/// Nodes of one unit. With [pickOutput] only its outputs are listed, and a tap
/// hands the output to [AppModel.finishPick] instead of opening the node.
/// [anyNode] keeps both directions in that pick, for a dashboard panel.
class UnitIoListPage extends StatefulWidget {
  const UnitIoListPage({
    required this.uuid,
    required this.scope,
    this.pickOutput = false,
    this.anyNode = false,
    super.key,
  });

  final String uuid;
  final int scope;
  final bool pickOutput;
  final bool anyNode;

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
              : widget.anyNode
              ? unitText(language, 'Нет узлов', 'No nodes')
              : widget.pickOutput
              ? unitText(language, 'Нет выходов', 'No outputs')
              : unitText(language, 'Пусто', 'Empty'),
          color: widget.pickOutput && !widget.anyNode
              ? unitOutputColor
              : unitIoColor,
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
          if (widget.pickOutput) {
            _chooseOutput(id);
          } else {
            context.push('/units/${widget.uuid}/io/$id');
          }
        }
      },
      frame: board == null
          ? null
          : (scene) => ScopeFrame(
              scope: widget.scope,
              canZoomIn: board.canZoomIn,
              path: widget.pickOutput
                  ? '/units/outputs?unit=${widget.uuid}'
                        '${widget.anyNode ? '&nodes=1' : ''}'
                  : '/units/${widget.uuid}/io',
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
        color: widget.pickOutput && !widget.anyNode
            ? unitOutputColor
            : unitIoColor,
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
      sideRight: io == null ? null : unitIoTypeLabel(language, io.type),
      footer: io == null ? null : unitVisibilityLabel(language, io.visibility),
      color: unitIoTone(io?.input ?? true),
      q: slot.q,
      r: slot.r,
      icon: unitIoIcon(io?.input ?? true),
    );
  }

  /// Gives the node to the screen that asked and closes this screen and the
  /// unit search under it. Opened without a pick, it just steps back.
  void _chooseOutput(String uuid) {
    final model = AppScope.of(context);
    final router = GoRouter.of(context);
    if (!model.pickOpen) {
      popOrHome(context);
      return;
    }
    model.finishPick(uuid);
    for (var step = 0; step < 2 && router.canPop(); step++) {
      router.pop();
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
      final ios = <UnitIo>[];
      var offset = 0;
      final limit = model.pageLimit;
      while (true) {
        final page = await model.listIos(
          offset: offset,
          limit: limit,
          unitUuid: widget.uuid,
          types: widget.pickOutput && !widget.anyNode ? const ['Output'] : null,
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
  int? _access;
  int? _links;
  String? _failure;
  var _open = false;
  var _loading = true;
  var _value = false;

  bool get _input =>
      _io?.input ?? AppScope.of(context).ioIsInput(widget.uuid) ?? true;

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
    // The instance keeps DataPipe on unless its portrait says otherwise. A
    // node can have the pipe only on a topic ending in `/pepeunit`, or when
    // it already has one.
    final featureOn =
        model.portraitOf(model.target?.url ?? '')?.datapipe != false;
    final datapipe =
        featureOn &&
        (io == null || unitIoPipeCapable(io.topic) || io.pipeActive);
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
    final scene = HexPage(slots: slots, onTap: (id) => _tap(id, io));
    if (!_value) return scene;
    return Stack(
      children: [
        scene,
        UnitIoValuePanel(
          uuid: widget.uuid,
          input: _input,
          // Only the creator may put a value into an input.
          editable: _input && owned,
          onClose: () {
            if (!mounted) return;
            setState(() => _value = false);
            _load();
          },
        ),
      ],
    );
  }

  HexSlot _slot(BoardSlot slot, String language, UnitIo? io) {
    final color = unitIoTone(_input);
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
          sideRight: io == null ? null : unitIoTypeLabel(language, io.type),
          footer: io == null
              ? null
              : unitVisibilityLabel(language, io.visibility),
          color: color,
          busy: _loading,
          q: slot.q,
          r: slot.r,
          icon: unitIoIcon(_input),
        );
      case 'settings':
        return _nav(
          slot,
          language,
          color,
          'Настройки',
          'Settings',
          'actions/settings.svg',
        );
      case 'value':
        return HexSlot(
          id: 'value',
          title: unitText(language, 'Значение', 'Value'),
          center: io == null ? null : ioValueGlance(io.state),
          color: color,
          q: slot.q,
          r: slot.r,
        );
      case 'links':
        return _nav(
          slot,
          language,
          unitLinkColor,
          'Связи',
          'Links',
          'objects/links.svg',
          footer: _links == null ? null : pieceCount(language, _links!),
        );
      case 'pipe':
        return _nav(
          slot,
          language,
          unitPipeColor,
          'DataPipe',
          'DataPipe',
          'objects/pipe.svg',
        );
      case 'access':
        return _nav(
          slot,
          language,
          accessColor,
          'Доступы',
          'Access',
          'objects/users.svg',
          footer: _access == null ? null : pieceCount(language, _access!),
        );
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
    Color color,
    String ru,
    String en,
    String icon, {
    String? footer,
  }) {
    return HexSlot(
      id: slot.id,
      title: unitText(language, ru, en),
      footer: footer,
      color: color,
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
      case 'value':
        setState(() => _value = true);
      case 'settings' || 'links' || 'pipe' || 'access':
        // The child may change the node, so the card is read again on return.
        await context.push('$base/$id');
        if (mounted) await _load();
    }
  }

  Future<void> _load() async {
    if (_loading && _io != null) return;
    final model = AppScope.of(context);
    if (model.target?.signedIn != true) {
      setState(() {
        _loading = false;
        _failure = unitText(model.vault.language, 'Нет входа', 'Not signed in');
      });
      return;
    }
    setState(() {
      _loading = true;
      _failure = null;
      _open = false;
    });
    try {
      final io = await model.readUnitIo(widget.uuid);
      if (!mounted) return;
      setState(() {
        _io = io;
        _loading = false;
      });
      await _loadAccess(io);
      await _loadLinks(io);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failure = '$error';
      });
    }
  }

  /// Outputs this input reads from. Only an input has the cell.
  Future<void> _loadLinks(UnitIo io) async {
    if (!io.input) {
      if (_links != null) setState(() => _links = null);
      return;
    }
    try {
      final links = await loadUnitLinks(AppScope.of(context), widget.uuid);
      if (mounted) setState(() => _links = links.length);
    } catch (_) {
      // The cell stays without a count; the links screen shows the error.
    }
  }

  /// Users and units together. Only the creator of a private node sees the cell.
  Future<void> _loadAccess(UnitIo io) async {
    final model = AppScope.of(context);
    if (io.visibility != 'Private' ||
        !unitOwnedBy(io.creatorUuid, model.target?.userUuid)) {
      if (_access != null) setState(() => _access = null);
      return;
    }
    try {
      final page = await model.accessGrants(
        resourceUuid: widget.uuid,
        resourceType: 'UnitIO',
        offset: 0,
        limit: 1,
      );
      if (mounted) setState(() => _access = page.count);
    } catch (_) {
      // The cell stays without a count; the access screen shows the error.
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
  final _max = TextEditingController();
  String? _failure;
  var _tried = false;
  var _open = false;
  var _loading = true;
  var _busy = false;

  /// The form edits a node the backend has returned. Until then a save would
  /// guess the node's direction and send fields it does not accept.
  bool get _ready => _io != null && !_loading;

  /// Direction of the node: the loaded one, else the one seen on the way in.
  bool? get _input => _io?.input ?? AppScope.of(context).ioIsInput(widget.uuid);

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

  String _maxIssue(String language) {
    final text = _max.text.trim();
    if (text.isEmpty && !_tried) return '';
    if (unitIoMaxConnections(text) != null) return '';
    return unitText(
      language,
      'От $unitIoMaxConnectionsFloor до $unitIoMaxConnectionsCeil',
      '$unitIoMaxConnectionsFloor to $unitIoMaxConnectionsCeil',
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final input = _input ?? false;
    final tone = unitIoTone(_input ?? true);
    final ready = _ready;
    final ids = [
      'max',
      'visibility',
      if (input) 'rewrite',
      'save',
    ];
    final placed = cardBoard(ids, wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        switch (slot.id) {
          'back' => backSlot(
            title: unitText(language, 'Назад', 'Back'),
            q: slot.q,
            r: slot.r,
          ),
          'max' => HexSlot(
            id: 'max',
            title: unitText(language, 'Максимум связей', 'Max links'),
            color: tone,
            q: slot.q,
            r: slot.r,
            tappable: false,
            enabled: ready,
            body: LineInput(
              color: tone,
              controller: _max,
              hint: '10',
              issue: _maxIssue(language),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(
                  '$unitIoMaxConnectionsCeil'.length,
                ),
              ],
            ),
          ),
          'visibility' => HexSlot(
            id: 'visibility',
            title: unitText(language, 'Видимость', 'Visibility'),
            color: tone,
            q: slot.q,
            r: slot.r,
            tappable: false,
            enabled: ready,
            body: ChoiceWords(
              center: true,
              choices: [
                for (final level in unitVisibilities)
                  (id: level, label: unitVisibilityLabel(language, level)),
              ],
              selected: (id) => _visibility == id,
              onTap: (id) => setState(() => _visibility = id),
            ),
          ),
          'rewrite' => HexSlot(
            id: 'rewrite',
            title: unitText(language, 'Перезаписываемый?', 'Rewritable?'),
            footer: _rewritable
                ? unitText(language, 'да', 'yes')
                : unitText(language, 'нет', 'no'),
            color: tone,
            enabled: ready,
            q: slot.q,
            r: slot.r,
            icon: _rewritable
                ? 'assets/icons/status/flag.svg'
                : 'assets/icons/actions/close.svg',
          ),
          'save' => HexSlot(
            id: 'save',
            title: unitText(language, 'Сохранить', 'Save'),
            color: unitAddColor,
            busy: _busy,
            enabled: ready,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/actions/check.svg',
          ),
          _ => HexSlot(
            id: slot.id,
            title: slot.id,
            color: tone,
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
            if (_ready) setState(() => _rewritable = !_rewritable);
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
        _loading = false;
        _visibility = io.visibility.isEmpty ? 'Private' : io.visibility;
        _rewritable = io.rewritable;
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
    final io = _io;
    if (_busy || !_ready || io == null) return;
    final max = unitIoMaxConnections(_max.text);
    if (max == null) {
      setState(() {
        _tried = true;
        _failure = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _failure = null;
      _open = false;
    });
    try {
      // The backend checks every field it receives. A rewritable flag is
      // refused on an output, so only what the node has is sent, and only
      // when the person changed it.
      final saved = await AppScope.of(context).updateUnitIo(widget.uuid, {
        'visibility_level': _visibility,
        'max_connections': max,
        if (io.input && _rewritable != io.rewritable)
          'is_rewritable_input': _rewritable,
      });
      if (!mounted) return;
      setState(() {
        _io = saved;
        _busy = false;
        _tried = false;
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

/// One link of an input: the unit it reads from and the output it reads.
typedef UnitLink = ({Unit unit, UnitIo io});

/// Every output linked to [inputUuid], with the unit that owns it.
Future<List<UnitLink>> loadUnitLinks(AppModel model, String inputUuid) async {
  final links = <UnitLink>[];
  var offset = 0;
  final limit = model.pageLimit;
  while (true) {
    final page = await model.listUnits(
      offset: offset,
      limit: limit,
      query: UnitQuery()..owner = 'all',
      inputUuid: inputUuid,
      includeIos: true,
    );
    for (final unit in page.units) {
      for (final io in unit.ios) {
        links.add((unit: unit, io: io));
      }
    }
    offset += page.units.length;
    if (page.units.isEmpty || offset >= page.count) break;
  }
  return links;
}

class UnitLinksPage extends StatefulWidget {
  const UnitLinksPage({required this.unitUuid, required this.uuid, super.key});

  final String unitUuid;
  final String uuid;

  @override
  State<UnitLinksPage> createState() => _UnitLinksPageState();
}

class _UnitLinksPageState extends State<UnitLinksPage> {
  List<UnitLink> _links = const [];
  String? _failure;
  var _open = false;
  var _loading = true;
  var _adding = false;

  /// Output uuid of the link being deleted.
  String? _deleting;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final ids = ['add', for (final link in _links) 'link:${link.io.uuid}'];
    final placed = cardBoard(ids, wide: wide);
    final mixed = Color.lerp(unitsColor, unitOutputColor, 0.5)!;
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
            color: unitLinkColor,
            busy: _loading || _adding,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/actions/plus.svg',
          )
        else
          _linkSlot(slot, mixed),
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

  /// The unit name above, the output topic below, the borders of both colors.
  HexSlot _linkSlot(BoardSlot slot, Color mixed) {
    final link = _find(slot.id);
    return HexSlot(
      id: slot.id,
      title: link?.unit.name ?? '',
      footer: link?.io.topic,
      color: mixed,
      rim: unitLinkRim(),
      busy: link != null && link.io.uuid == _deleting,
      q: slot.q,
      r: slot.r,
      icon: 'assets/icons/sections/micro.svg',
    );
  }

  UnitLink? _find(String id) {
    final uuid = id.startsWith('link:') ? id.substring(5) : id;
    for (final link in _links) {
      if (link.io.uuid == uuid) return link;
    }
    return null;
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
      if (_adding) return;
      // Search shows only units that have an output; its card opens the
      // outputs of that unit, and the chosen output comes back here.
      final pick = AppScope.of(context).beginOutputPick();
      context.push('/units/pick?outputs=1');
      final output = await pick;
      if (output == null || !mounted) return;
      setState(() {
        _adding = true;
        _failure = null;
        _open = false;
      });
      try {
        await AppScope.of(context)
            .createIoLink(outputUuid: output, inputUuid: widget.uuid);
        if (!mounted) return;
        setState(() => _adding = false);
        await _load();
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _adding = false;
          _failure = '$error';
        });
      }
      return;
    }
    final link = _find(id);
    if (link != null) await _delete(link);
  }

  /// A tap on a link asks the backend to remove it. A refusal is shown in the
  /// error cell and the link stays.
  Future<void> _delete(UnitLink link) async {
    if (_deleting != null || _adding) return;
    setState(() {
      _deleting = link.io.uuid;
      _failure = null;
      _open = false;
    });
    try {
      await AppScope.of(context)
          .deleteIoLink(outputUuid: link.io.uuid, inputUuid: widget.uuid);
      if (!mounted) return;
      setState(() => _deleting = null);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _deleting = null;
        _failure = '$error';
      });
    }
  }

  Future<void> _load() async {
    try {
      final links = await loadUnitLinks(AppScope.of(context), widget.uuid);
      if (!mounted) return;
      setState(() {
        _links = links;
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

  Color get _tone => unitPipeColor;

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
            color: _tone,
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
            color: _tone,
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
            color: _tone,
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
