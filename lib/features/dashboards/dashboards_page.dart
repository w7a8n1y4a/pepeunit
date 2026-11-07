import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../dashboards/dashboard.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../units/unit_view.dart';
import '../hex_page.dart';
import '../line_input.dart';
import '../network/network_chrome.dart';
import '../units/units_chrome.dart';
import 'dashboards_chrome.dart';

/// Search over the dashboards of the signed-in user. The backend lists no
/// one else's, so there is no owner switch. Opens on scale tick 3.
class DashboardsPage extends StatefulWidget {
  const DashboardsPage({required this.scope, super.key});

  final int scope;

  @override
  State<DashboardsPage> createState() => _DashboardsPageState();
}

class _DashboardsPageState extends State<DashboardsPage> {
  final _search = TextEditingController();
  final _typing = SearchDelay();
  var _ticket = 0;
  String _order = 'desc';
  var _offset = 0;
  var _count = 0;
  List<Dashboard> _dashboards = const [];
  String? _failure;
  var _open = false;
  var _loading = true;

  /// Cells ahead of the cards: the filter, create and the page window.
  static const _head = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(DashboardsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope == widget.scope) return;
    _offset = 0;
    _load();
  }

  @override
  void dispose() {
    _typing.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final limit = model.cappedLimit(headPageLimit(widget.scope, head: _head));
    final capacity = headPageLimit(scaleTickMax, head: _head);
    final board = headBoard(
      tick: widget.scope,
      head: const ['query', 'create', 'window'],
      ids: [for (final dashboard in _dashboards) dashboard.uuid],
      prefix: 'dashboard:',
      total: _count,
      wide: wide,
    );
    final slots = <HexSlot>[
      for (final slot in board.slots)
        switch (slot.id) {
          'back' => backSlot(
            title: dashText(language, 'Назад', 'Back'),
            q: slot.q,
            r: slot.r,
          ),
          'query' => HexSlot(
            id: 'query',
            title: dashText(language, 'Фильтр', 'Filter'),
            color: dashboardsColor,
            q: slot.q,
            r: slot.r,
            body: LineInput(
              color: dashboardsColor,
              controller: _search,
              hint: dashText(language, 'Поиск', 'Search'),
              leading: 'assets/icons/search.svg',
              onChanged: (_) {
                _typing.later(() {
                  if (!mounted) return;
                  setState(() => _offset = 0);
                  _load();
                });
              },
            ),
          ),
          'create' => HexSlot(
            id: 'create',
            title: dashText(language, 'Создать панель', 'Create dashboard'),
            color: addColor,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/plus.svg',
          ),
          'window' => HexSlot(
            id: 'window',
            title: dashText(language, 'Страница', 'Page'),
            color: dashboardsColor,
            busy: _loading,
            q: slot.q,
            r: slot.r,
            body: UnitWindow(
              language: language,
              offset: _offset,
              limit: limit,
              count: _count,
              capacity: capacity,
              order: _order,
              orderLabel: (order) => dashboardOrderLabel(language, order),
              onOrder: (value) {
                if (value == _order) return;
                _typing.cancel();
                setState(() {
                  _order = value;
                  _offset = 0;
                });
                _load();
              },
              onStep: (direction) => _step(direction, limit, capacity),
            ),
          ),
          _ => _card(slot, language),
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
      onTap: (id) {
        if (id == 'back') {
          popOrHome(context);
        } else if (id == 'error') {
          setState(() => _open = true);
        } else if (id == 'create') {
          context.push('/dashboards/new');
        } else if (id.startsWith('dashboard:')) {
          context.push('/dashboards/${id.substring(10)}');
        }
      },
      frame: (scene) => ScopeFrame(
        scope: widget.scope,
        canZoomIn: board.canZoomIn,
        path: '/dashboards',
        child: scene,
      ),
    );
  }

  HexSlot _card(BoardSlot slot, String language) {
    final uuid = slot.id.startsWith('dashboard:') ? slot.id.substring(10) : '';
    for (final dashboard in _dashboards) {
      if (dashboard.uuid != uuid) continue;
      return dashboardMark(
        id: slot.id,
        dashboard: dashboard,
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

  void _step(int direction, int limit, int capacity) {
    if (_loading) return;
    final next = pageShift(
      direction: direction,
      offset: _offset,
      limit: limit,
      count: _count,
      capacity: capacity,
    );
    if (next == null) return;
    setState(() => _offset = next);
    _load();
  }

  Future<void> _load() async {
    final ticket = ++_ticket;
    final model = AppScope.of(context);
    if (model.target?.signedIn != true) {
      setState(() {
        _loading = false;
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
      final page = await model.listDashboards(
        offset: _offset,
        limit: headPageLimit(widget.scope, head: _head),
        search: _search.text,
        order: _order,
      );
      if (!mounted || ticket != _ticket) return;
      setState(() {
        _dashboards = page.dashboards;
        _count = page.count;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || ticket != _ticket) return;
      setState(() {
        _loading = false;
        _failure = '$error';
      });
    }
  }
}

/// Name of a new dashboard. Created, it opens on its own card.
class DashboardCreatePage extends StatefulWidget {
  const DashboardCreatePage({super.key});

  @override
  State<DashboardCreatePage> createState() => _DashboardCreatePageState();
}

class _DashboardCreatePageState extends State<DashboardCreatePage> {
  final _name = TextEditingController();
  String? _failure;
  String? _issue;
  var _open = false;
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(const ['name', 'create'], wide: wide);
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
            title: dashText(language, 'Имя', 'Name'),
            color: dashboardsColor,
            q: slot.q,
            r: slot.r,
            tappable: false,
            body: LineInput(
              color: dashboardsColor,
              controller: _name,
              fieldKey: const ValueKey('dashboard-name'),
              hint: dashText(language, 'имя', 'name'),
              issue: _issue ?? '',
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_.-]')),
                LengthLimitingTextInputFormatter(20),
              ],
              onSubmitted: (_) => _create(),
            ),
          ),
          'create' => HexSlot(
            id: 'create',
            title: dashText(language, 'Создать панель', 'Create dashboard'),
            color: addColor,
            busy: _busy,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/plus.svg',
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
      onTap: (id) {
        if (id == 'back') popOrHome(context);
        if (id == 'error') setState(() => _open = true);
        if (id == 'create') _create();
      },
    );
  }

  Future<void> _create() async {
    if (_busy) return;
    final model = AppScope.of(context);
    final name = _name.text.trim();
    if (!dashboardNameOk(name)) {
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
      final dashboard = await model.createDashboard(name);
      if (!mounted) return;
      context.pushReplacement('/dashboards/${dashboard.uuid}');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = '$error';
      });
    }
  }
}
