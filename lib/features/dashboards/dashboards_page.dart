import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../dashboards/dashboard.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../hex_page.dart';
import '../paged_search.dart';
import '../line_input.dart';
import '../network/network_chrome.dart';
import '../units/units_chrome.dart';
import 'dashboards_chrome.dart';
import '../../locale/languages.dart';

/// Search over the dashboards of the signed-in user, one step below the
/// section menu. The backend lists no
/// one else's, so there is no owner switch. Opens on scale tick 3.
class DashboardsPage extends StatefulWidget {
  const DashboardsPage({required this.scope, super.key});

  final int scope;

  @override
  State<DashboardsPage> createState() => _DashboardsPageState();
}

class _DashboardsPageState extends State<DashboardsPage>
    with PagedSearch<DashboardsPage> {
  final _search = TextEditingController();
  String _order = 'desc';
  var _count = 0;
  List<Dashboard> _dashboards = const [];

  /// Cells ahead of the cards: the filter and the page window.
  static const _head = 2;

  @override
  int scopeOf(DashboardsPage widget) => widget.scope;

  @override
  void initState() {
    super.initState();
    loading = true;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final limit = model.cappedLimit(headPageLimit(widget.scope, head: _head));
    final capacity = model.pageCapacity(
      headPageLimit(scaleTickMax, head: _head),
    );
    final board = listBoard(
      tick: widget.scope,
      head: const ['query', 'window'],
      ids: [for (final dashboard in _dashboards) dashboard.uuid],
      prefix: 'dashboard:',
      total: _count,
      wide: wide,
    );
    final slots = <HexSlot>[
      for (final slot in board.slots)
        switch (slot.id) {
          'back' => backSlot(language, q: slot.q, r: slot.r),
          'query' => HexSlot(
            id: 'query',
            title: localized(language, 'Фильтр', 'Filter'),
            color: dashboardsColor,
            q: slot.q,
            r: slot.r,
            body: LineInput(
              color: dashboardsColor,
              controller: _search,
              hint: localized(language, 'Поиск', 'Search'),
              leading: 'assets/icons/actions/search.svg',
              onChanged: (_) => searchLater(),
            ),
          ),
          'window' => HexSlot(
            id: 'window',
            title: localized(language, 'Страница', 'Page'),
            color: dashboardsColor,
            busy: loading,
            q: slot.q,
            r: slot.r,
            body: UnitWindow(
              language: language,
              offset: offset,
              limit: limit,
              count: _count,
              capacity: capacity,
              order: _order,
              orderLabel: (order) => dashboardOrderLabel(language, order),
              onOrder: (value) {
                if (value == _order) return;
                setState(() => _order = value);
                retune();
              },
              onStep: (direction) =>
                  step(direction, limit: limit, count: _count, capacity: capacity),
            ),
          ),
          _ => _card(slot, language),
        },
    ];
    appendError(
      slots,
      message: failure,
      open: failureOpen,
      language: language,
      wide: wide,
    );
    return HexPage(
      slots: slots,
      onTap: (id) {
        if (id == 'back') {
          popOrHome(context);
        } else if (id == 'error') {
          setState(() => failureOpen = true);
        } else if (id.startsWith('dashboard:')) {
          context.push('/dashboards/${id.substring(10)}');
        }
      },
      frame: (scene) => ScopeFrame(
        scope: widget.scope,
        canZoomIn: board.canZoomIn,
        path: '/dashboards/search',
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

  @override
  Future<VoidCallback?> fetch(AppModel model) async {
    final page = await model.listDashboards(
      offset: offset,
      limit: headPageLimit(widget.scope, head: _head),
      search: _search.text,
      order: _order,
    );
    return () {
      _dashboards = page.dashboards;
      _count = page.count;
    };
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
          'back' => backSlot(language, q: slot.q, r: slot.r),
          'name' => HexSlot(
            id: 'name',
            title: localized(language, 'Имя', 'Name'),
            color: dashboardsColor,
            q: slot.q,
            r: slot.r,
            tappable: false,
            body: LineInput(
              color: dashboardsColor,
              controller: _name,
              fieldKey: const ValueKey('dashboard-name'),
              hint: localized(language, 'имя', 'name'),
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
            title: localized(language, 'Создать панель', 'Create dashboard'),
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
