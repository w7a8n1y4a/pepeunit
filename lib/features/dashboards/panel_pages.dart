import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../dashboards/dashboard.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../registry/repo.dart';
import '../../units/unit.dart';
import '../../units/unit_view.dart';
import '../hex_page.dart';
import '../line_input.dart';
import '../network/network_chrome.dart';
import '../units/units_chrome.dart';
import 'dashboards_chrome.dart';

/// Panel card in a list: title above, type on the lower right and the count
/// of linked nodes along the right edge.
HexSlot panelMark({
  required String id,
  required DashboardPanel panel,
  required String language,
  required int q,
  required int r,
  bool tappable = true,
  bool busy = false,
}) {
  return HexSlot(
    id: id,
    title: panel.title,
    footer: panelTypeLabel(panel.type),
    sideRight: pieceCount(language, panel.links.length),
    color: dashboardsColor,
    q: q,
    r: r,
    icon: 'assets/icons/objects/brick.svg',
    tappable: tappable,
    busy: busy,
  );
}

/// Border of a link card: the unit's color and the node's direction, half each.
List<Color> panelLinkRim(bool input) =>
    rimMix([(unitsColor, 1), (unitIoTone(input), 1)])!;

/// Panels of one dashboard. The backend sends them whole, so the screen pages
/// them itself: tick 1 first, growing while another card still fits.
class PanelsPage extends StatefulWidget {
  const PanelsPage({required this.uuid, required this.scope, super.key});

  final String uuid;
  final int scope;

  @override
  State<PanelsPage> createState() => _PanelsPageState();
}

class _PanelsPageState extends State<PanelsPage> {
  List<DashboardPanel> _panels = const [];
  String? _failure;
  var _open = false;
  var _loading = true;
  var _page = 0;
  var _current = false;
  var _seen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final now = ModalRoute.of(context)?.isCurrent ?? true;
    if (now && !_current && _seen) _load();
    _current = now;
  }

  @override
  void didUpdateWidget(PanelsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope) _page = 0;
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = tailBoard(
      tick: widget.scope,
      page: _page,
      head: const ['add'],
      ids: [for (final panel in _panels) panel.uuid],
      wide: wide,
    );
    final slots = <HexSlot>[
      for (final slot in board.slots) _slot(slot, language, board),
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: dashText,
      wide: wide,
    );
    return HexPage(
      slots: slots,
      onTap: (id) {
        if (id == 'back') {
          popOrHome(context);
        } else if (id == 'error') {
          setState(() => _open = true);
        } else if (id == 'add') {
          context.push('/dashboards/${widget.uuid}/panels/new');
        } else if (_panels.any((panel) => panel.uuid == id)) {
          context.push('/dashboards/${widget.uuid}/panels/$id');
        }
      },
      frame: (scene) => ScopeFrame(
        scope: widget.scope,
        canZoomIn: board.canZoomIn,
        path: '/dashboards/${widget.uuid}/panels',
        child: scene,
      ),
    );
  }

  HexSlot _slot(BoardSlot slot, String language, NetworkBoard board) {
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: dashText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'add':
        return HexSlot(
          id: 'add',
          title: dashText(language, 'Добавить', 'Add'),
          color: addColor,
          busy: _loading,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/actions/plus.svg',
        );
      case 'prev' || 'next':
        final forward = slot.id == 'next';
        return pageStepSlot(
          id: slot.id,
          left: !forward,
          language: language,
          color: dashboardsColor,
          q: slot.q,
          r: slot.r,
          page: board.page,
          pages: board.pages,
          enabled: forward ? board.page < board.pages - 1 : board.page > 0,
          onTap: () => setState(() => _page = board.page + (forward ? 1 : -1)),
        );
    }
    for (final panel in _panels) {
      if (panel.uuid != slot.id) continue;
      return panelMark(
        id: slot.id,
        panel: panel,
        language: language,
        q: slot.q,
        r: slot.r,
      );
    }
    return HexSlot(
      id: slot.id,
      title: '',
      color: dashboardsColor,
      q: slot.q,
      r: slot.r,
    );
  }

  Future<void> _load() async {
    final model = AppScope.of(context);
    if (model.target?.signedIn != true) {
      setState(() {
        _loading = false;
        _seen = true;
        _failure = dashText(model.vault.language, 'Нет входа', 'Not signed in');
      });
      return;
    }
    setState(() {
      _loading = true;
      _failure = null;
      _open = false;
    });
    try {
      final panels = await model.dashboardPanels(widget.uuid);
      if (!mounted) return;
      setState(() {
        _panels = panels;
        _loading = false;
        _seen = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _seen = true;
        _failure = '$error';
      });
    }
  }
}

/// Title and type of a new panel. Created, it opens on its own card.
class PanelCreatePage extends StatefulWidget {
  const PanelCreatePage({required this.uuid, super.key});

  final String uuid;

  @override
  State<PanelCreatePage> createState() => _PanelCreatePageState();
}

class _PanelCreatePageState extends State<PanelCreatePage> {
  final _title = TextEditingController();
  String _type = panelTypes.first.value;
  String? _failure;
  String? _issue;
  var _open = false;
  var _busy = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(const ['name', 'type', 'create'], wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        switch (slot.id) {
          'back' => backSlot(
            title: dashText(language, 'Назад', 'Back'),
            q: slot.q,
            r: slot.r,
          ),
          'name' => HexSlot(
            id: 'name',
            title: dashText(language, 'Название', 'Title'),
            color: dashboardsColor,
            q: slot.q,
            r: slot.r,
            tappable: false,
            body: LineInput(
              color: dashboardsColor,
              controller: _title,
              fieldKey: const ValueKey('panel-title'),
              hint: dashText(language, 'название', 'title'),
              issue: _issue ?? '',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_.-]')),
                LengthLimitingTextInputFormatter(20),
              ],
              onSubmitted: (_) => _create(),
            ),
          ),
          'type' => HexSlot(
            id: 'type',
            title: dashText(language, 'Тип', 'Type'),
            footer: panelTypeLabel(_type),
            color: dashboardsColor,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/objects/brick.svg',
          ),
          'create' => HexSlot(
            id: 'create',
            title: dashText(language, 'Создать', 'Create'),
            color: addColor,
            busy: _busy,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/actions/plus.svg',
          ),
          _ => HexSlot(
            id: slot.id,
            title: slot.id,
            color: dashboardsColor,
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
      text: dashText,
      wide: wide,
    );
    return HexPage(slots: slots, onTap: _tap);
  }

  Future<void> _tap(String id) async {
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'type':
        final pick = AppScope.of(context).beginPick();
        context.push('/dashboards/type');
        final picked = await pick;
        if (picked == null || !mounted) return;
        setState(() => _type = picked);
      case 'create':
        await _create();
    }
  }

  Future<void> _create() async {
    if (_busy) return;
    final model = AppScope.of(context);
    final title = _title.text.trim();
    if (!dashboardNameOk(title)) {
      setState(() {
        _issue = dashboardNameIssue(model.vault.language);
        _failure = null;
      });
      return;
    }
    setState(() {
      _busy = true;
      _issue = null;
      _failure = null;
      _open = false;
    });
    try {
      final panel = await model.createPanel(
        dashboardUuid: widget.uuid,
        title: title,
        type: _type,
      );
      if (!mounted) return;
      context.pushReplacement(
        '/dashboards/${widget.uuid}/panels/${panel.uuid}',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = '$error';
      });
    }
  }
}

/// One panel: its identity, the nodes it reads and the delete. The backend has
/// no read of a single panel, so the card finds itself in the dashboard's list.
class PanelPage extends StatefulWidget {
  const PanelPage({required this.dashboardUuid, required this.uuid, super.key});

  final String dashboardUuid;
  final String uuid;

  @override
  State<PanelPage> createState() => _PanelPageState();
}

class _PanelPageState extends State<PanelPage> {
  DashboardPanel? _panel;
  String? _failure;
  var _open = false;
  var _loading = true;
  var _deleting = false;
  var _current = false;
  var _seen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final now = ModalRoute.of(context)?.isCurrent ?? true;
    if (now && !_current && _seen) _load();
    _current = now;
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(panelMenuIds, wide: wide);
    final panel = _panel;
    final slots = <HexSlot>[
      for (final slot in placed)
        switch (slot.id) {
          'back' => backSlot(
            title: dashText(language, 'Назад', 'Back'),
            q: slot.q,
            r: slot.r,
          ),
          'card' =>
            panel == null
                ? HexSlot(
                    id: 'card',
                    title: dashText(language, 'Визуализация', 'Panel'),
                    color: dashboardsColor,
                    busy: _loading,
                    q: slot.q,
                    r: slot.r,
                    icon: 'assets/icons/objects/brick.svg',
                  )
                : panelMark(
                    id: 'card',
                    panel: panel,
                    language: language,
                    q: slot.q,
                    r: slot.r,
                    busy: _loading,
                  ),
          'nodes' => HexSlot(
            id: 'nodes',
            title: dashText(language, 'Входы и выходы', 'Inputs and outputs'),
            footer: panel == null
                ? null
                : pieceCount(language, panel.links.length),
            color: unitIoColor,
            rim: panel == null
                ? null
                : rimMix([
                    (unitIoColor, panel.inputs),
                    (unitOutputColor, panel.outputs),
                  ]),
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/objects/io.svg',
          ),
          'delete' => HexSlot(
            id: 'delete',
            title: dashText(language, 'Удалить', 'Delete'),
            color: errorColor,
            busy: _deleting,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/actions/trash.svg',
          ),
          _ => HexSlot(
            id: slot.id,
            title: slot.id,
            color: dashboardsColor,
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
      text: dashText,
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
          case 'card':
            await _load();
          case 'nodes':
            context.push(
              '/dashboards/${widget.dashboardUuid}/panels/${widget.uuid}/nodes',
            );
          case 'delete':
            await _delete();
        }
      },
    );
  }

  Future<void> _load() async {
    final model = AppScope.of(context);
    if (model.target?.signedIn != true) {
      setState(() {
        _loading = false;
        _seen = true;
        _failure = dashText(model.vault.language, 'Нет входа', 'Not signed in');
      });
      return;
    }
    setState(() {
      _loading = true;
      _failure = null;
      _open = false;
    });
    try {
      final panels = await model.dashboardPanels(widget.dashboardUuid);
      if (!mounted) return;
      DashboardPanel? found;
      for (final panel in panels) {
        if (panel.uuid == widget.uuid) found = panel;
      }
      setState(() {
        _panel = found;
        _loading = false;
        _seen = true;
        if (found == null) {
          _failure = dashText(
            model.vault.language,
            'Визуализация не найдена',
            'Panel not found',
          );
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _seen = true;
        _failure = '$error';
      });
    }
  }

  Future<void> _delete() async {
    if (_deleting) return;
    setState(() {
      _deleting = true;
      _failure = null;
      _open = false;
    });
    try {
      await AppScope.of(context).deletePanel(widget.uuid);
      if (!mounted) return;
      context.go('/dashboards/${widget.dashboardUuid}/panels');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _failure = '$error';
      });
    }
  }
}

/// Nodes linked to one panel. A card names the unit above and the topic
/// below. «Добавить» picks a node of any unit, and a tap on a card removes the
/// link, as on the links of an input.
class PanelNodesPage extends StatefulWidget {
  const PanelNodesPage({
    required this.dashboardUuid,
    required this.uuid,
    required this.scope,
    super.key,
  });

  final String dashboardUuid;
  final String uuid;
  final int scope;

  @override
  State<PanelNodesPage> createState() => _PanelNodesPageState();
}

class _PanelNodesPageState extends State<PanelNodesPage> {
  List<PanelLink> _links = const [];
  String? _failure;
  var _open = false;
  var _loading = true;
  var _page = 0;
  var _current = false;
  var _seen = false;

  /// Node uuid of the link being removed.
  String? _deleting;

  String get _path =>
      '/dashboards/${widget.dashboardUuid}/panels/${widget.uuid}/nodes';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final now = ModalRoute.of(context)?.isCurrent ?? true;
    if (now && !_current && _seen) _load();
    _current = now;
  }

  @override
  void didUpdateWidget(PanelNodesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope) _page = 0;
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = tailBoard(
      tick: widget.scope,
      page: _page,
      head: const ['add'],
      ids: [for (final link in _links) 'link:${link.io.uuid}'],
      wide: wide,
    );
    final slots = <HexSlot>[
      for (final slot in board.slots) _slot(slot, language, board),
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: dashText,
      wide: wide,
    );
    return HexPage(
      slots: slots,
      onTap: _tap,
      frame: (scene) => ScopeFrame(
        scope: widget.scope,
        canZoomIn: board.canZoomIn,
        path: _path,
        child: scene,
      ),
    );
  }

  HexSlot _slot(BoardSlot slot, String language, NetworkBoard board) {
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: dashText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'add':
        return HexSlot(
          id: 'add',
          title: dashText(language, 'Добавить', 'Add'),
          color: addColor,
          busy: _loading,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/actions/plus.svg',
        );
      case 'prev' || 'next':
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
    final link = _find(slot.id);
    final input = link?.io.input ?? true;
    final flags = [
      if (link != null && link.lastOnly)
        dashText(language, 'Последнее', 'Last'),
      if (link != null && link.asJson) 'JSON',
    ];
    return HexSlot(
      id: slot.id,
      title: link?.unitName ?? '',
      footer: link?.io.topic,
      sideRight: link == null ? null : unitIoTypeLabel(language, link.io.type),
      sideLeft: flags.isEmpty ? null : flags.join(' · '),
      color: unitIoTone(input),
      rim: panelLinkRim(input),
      busy: link != null && link.io.uuid == _deleting,
      q: slot.q,
      r: slot.r,
      icon: unitIoIcon(input),
    );
  }

  PanelLink? _find(String id) {
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
      await _add();
      return;
    }
    final link = _find(id);
    if (link != null) await _delete(link);
  }

  /// Search shows units that have a node. Its card opens the nodes of that
  /// unit, and the chosen node comes back here to get its two flags.
  Future<void> _add() async {
    final pick = AppScope.of(context).beginPick();
    context.push('/units/pick?nodes=1');
    final node = await pick;
    if (node == null || !mounted) return;
    context.push('$_path/new?io=$node');
  }

  Future<void> _delete(PanelLink link) async {
    if (_deleting != null) return;
    setState(() {
      _deleting = link.io.uuid;
      _failure = null;
      _open = false;
    });
    try {
      await AppScope.of(context)
          .deletePanelLink(panelUuid: widget.uuid, ioUuid: link.io.uuid);
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
    final model = AppScope.of(context);
    if (model.target?.signedIn != true) {
      setState(() {
        _loading = false;
        _seen = true;
        _failure = dashText(model.vault.language, 'Нет входа', 'Not signed in');
      });
      return;
    }
    try {
      final panels = await model.dashboardPanels(widget.dashboardUuid);
      if (!mounted) return;
      var links = const <PanelLink>[];
      for (final panel in panels) {
        if (panel.uuid == widget.uuid) links = panel.links;
      }
      setState(() {
        _links = links;
        _loading = false;
        _seen = true;
        _failure = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _seen = true;
        _failure = '$error';
      });
    }
  }
}

/// The two flags of a link, chosen once: the backend has no call to change
/// them later. Create sends the link and returns to the nodes.
class PanelNodeFormPage extends StatefulWidget {
  const PanelNodeFormPage({
    required this.panelUuid,
    required this.ioUuid,
    super.key,
  });

  final String panelUuid;
  final String ioUuid;

  @override
  State<PanelNodeFormPage> createState() => _PanelNodeFormPageState();
}

class _PanelNodeFormPageState extends State<PanelNodeFormPage> {
  UnitIo? _io;
  var _last = false;
  var _json = false;
  String? _failure;
  var _open = false;
  var _loading = true;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(const [
      'node',
      'last',
      'json',
      'create',
    ], wide: wide);
    final io = _io;
    final ready = io != null && !_busy;
    final slots = <HexSlot>[
      for (final slot in placed)
        switch (slot.id) {
          'back' => backSlot(
            title: dashText(language, 'Назад', 'Back'),
            q: slot.q,
            r: slot.r,
          ),
          'node' => HexSlot(
            id: 'node',
            title: io?.topic ?? dashText(language, 'Узел', 'Node'),
            sideRight: io == null ? null : unitIoTypeLabel(language, io.type),
            footer: io == null
                ? null
                : unitVisibilityLabel(language, io.visibility),
            color: unitIoTone(io?.input ?? true),
            busy: _loading,
            tappable: false,
            q: slot.q,
            r: slot.r,
            icon: unitIoIcon(io?.input ?? true),
          ),
          'last' => _flag(
            slot,
            language,
            dashText(language, 'Только последнее', 'Only last value'),
            _last,
            ready,
          ),
          'json' => _flag(
            slot,
            language,
            dashText(language, 'Значение как JSON', 'Value as JSON'),
            _json,
            ready,
          ),
          'create' => HexSlot(
            id: 'create',
            title: dashText(language, 'Связать', 'Link'),
            color: addColor,
            busy: _busy,
            enabled: ready,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/actions/plus.svg',
          ),
          _ => HexSlot(
            id: slot.id,
            title: slot.id,
            color: dashboardsColor,
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
      text: dashText,
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
          case 'last':
            if (ready) setState(() => _last = !_last);
          case 'json':
            if (ready) setState(() => _json = !_json);
          case 'create':
            await _create();
        }
      },
    );
  }

  HexSlot _flag(
    BoardSlot slot,
    String language,
    String title,
    bool on,
    bool enabled,
  ) {
    return HexSlot(
      id: slot.id,
      title: title,
      footer: dashText(language, on ? 'вкл' : 'выкл', on ? 'on' : 'off'),
      color: on ? dashboardsColor : hexMuted,
      enabled: enabled,
      q: slot.q,
      r: slot.r,
      icon: on
          ? 'assets/icons/status/flag.svg'
          : 'assets/icons/actions/close.svg',
    );
  }

  Future<void> _load() async {
    final model = AppScope.of(context);
    if (model.target?.signedIn != true) {
      setState(() {
        _loading = false;
        _failure = dashText(model.vault.language, 'Нет входа', 'Not signed in');
      });
      return;
    }
    try {
      final io = await model.readUnitIo(widget.ioUuid);
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

  Future<void> _create() async {
    if (_busy || _io == null) return;
    setState(() {
      _busy = true;
      _failure = null;
      _open = false;
    });
    try {
      await AppScope.of(context).linkPanelIo(
        panelUuid: widget.panelUuid,
        ioUuid: widget.ioUuid,
        lastOnly: _last,
        asJson: _json,
      );
      if (!mounted) return;
      popOrHome(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = '$error';
      });
    }
  }
}
