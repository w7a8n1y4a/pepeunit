import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../dashboards/dashboard.dart';
import '../../hive/hex_motion.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../registry/repo.dart';
import '../hex_page.dart';
import 'dashboards_chrome.dart';

/// One dashboard: its state, the panels it holds, the sync to Grafana, the
/// link into Grafana and the delete. Only the creator reaches it, because the
/// backend lists and reads no one else's dashboards.
class DashboardPage extends StatefulWidget {
  const DashboardPage({required this.uuid, super.key});

  final String uuid;

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Dashboard? _dashboard;
  int? _panels;
  String? _pending;
  String? _failure;
  var _open = false;
  var _loading = true;
  HexEcho? _echo;
  var _current = false;
  var _seen = false;

  /// A failed request, or the error Grafana gave back at the last sync.
  String? get _shown {
    if (_failure != null) return _failure;
    final dashboard = _dashboard;
    if (dashboard?.syncStatus == 'Error') return dashboard!.syncError;
    return null;
  }

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
  void didUpdateWidget(DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uuid == widget.uuid) return;
    _panels = null;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(dashboardMenuIds, wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed) _slot(slot, language, model),
    ];
    appendError(
      slots,
      message: _shown,
      open: _open,
      language: language,
      text: dashText,
      wide: wide,
    );
    return HexPage(slots: slots, onTap: _tap, echo: _echo);
  }

  HexSlot _slot(BoardSlot slot, String language, AppModel model) {
    final dashboard = _dashboard;
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: dashText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'card':
        if (dashboard == null) {
          return HexSlot(
            id: 'card',
            title: dashText(language, 'Панель', 'Dashboard'),
            color: dashboardsColor,
            busy: _loading,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/sections/panel.svg',
          );
        }
        return dashboardMark(
          id: 'card',
          dashboard: dashboard,
          language: language,
          q: slot.q,
          r: slot.r,
          busy: _loading,
        );
      case 'info':
        return HexSlot(
          id: 'info',
          title: dashText(language, 'Информация', 'Information'),
          center: dashboardLines(
            dashboard,
            language,
            model.vault.timeZone,
          ).join('\n'),
          color: dashboardsColor,
          tappable: false,
          q: slot.q,
          r: slot.r,
        );
      case 'panels':
        return HexSlot(
          id: 'panels',
          title: dashText(language, 'Визуализации', 'Panels'),
          footer: _panels == null ? null : pieceCount(language, _panels!),
          color: dashboardsColor,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/objects/brick.svg',
        );
      case 'sync':
        return HexSlot(
          id: 'sync',
          title: dashText(language, 'Отправить в Grafana', 'Send to Grafana'),
          color: dashboardsColor,
          busy: _pending == 'sync',
          enabled: dashboard != null && _pending == null,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/actions/cloud_up.svg',
        );
      case 'open':
        return HexSlot(
          id: 'open',
          title: dashText(language, 'Открыть в Grafana', 'Open in Grafana'),
          color: dashboardsColor,
          busy: _pending == 'open',
          enabled: dashboard?.opens == true && _pending == null,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/services/grafana.svg',
        );
      case 'delete':
        return HexSlot(
          id: 'delete',
          title: dashText(language, 'Удалить панель', 'Delete dashboard'),
          color: errorColor,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/actions/trash.svg',
        );
      default:
        return HexSlot(
          id: slot.id,
          title: slot.id,
          color: dashboardsColor,
          q: slot.q,
          r: slot.r,
        );
    }
  }

  Future<void> _tap(String id) async {
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'card':
        await _reloadCard();
      case 'panels':
        context.push('/dashboards/${widget.uuid}/panels');
      case 'sync':
        await _sync();
      case 'open':
        await _openInGrafana();
      case 'delete':
        context.push('/dashboards/${widget.uuid}/delete');
    }
  }

  /// A tap on the card reads the entity again and shows how it went.
  Future<void> _reloadCard() async {
    await _load();
    if (!mounted) return;
    setState(() => _echo = HexEcho(ok: _failure == null));
  }

  Future<void> _load() async {
    final model = AppScope.of(context);
    final language = model.vault.language;
    if (model.target?.signedIn != true) {
      setState(() {
        _loading = false;
        _seen = true;
        _failure = dashText(language, 'Нет входа', 'Not signed in');
      });
      return;
    }
    setState(() {
      _loading = true;
      _failure = null;
      _open = false;
    });
    try {
      final dashboard = await model.readDashboard(widget.uuid);
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _loading = false;
        _seen = true;
      });
      unawaited(_loadPanels());
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _seen = true;
        _failure = '$error';
      });
    }
  }

  Future<void> _loadPanels() async {
    try {
      final panels = await AppScope.of(context).dashboardPanels(widget.uuid);
      if (mounted) setState(() => _panels = panels.length);
    } catch (_) {
      // The cell stays without a count; the panels screen shows the error.
    }
  }

  /// Grafana's own refusal lands on the dashboard as `sync_error`, and
  /// [_shown] reads it from there.
  Future<void> _sync() async {
    if (_pending != null) return;
    setState(() {
      _pending = 'sync';
      _failure = null;
      _open = false;
    });
    try {
      final dashboard = await AppScope.of(context).syncDashboard(widget.uuid);
      if (!mounted) return;
      setState(() {
        _dashboard = dashboard;
        _pending = null;
        _open = dashboard.syncStatus == 'Error';
        _echo = HexEcho(ok: dashboard.syncStatus != 'Error');
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
        _echo = HexEcho(ok: false);
      });
    }
  }

  Future<void> _openInGrafana() async {
    final dashboard = _dashboard;
    if (_pending != null || dashboard == null || !dashboard.opens) return;
    final model = AppScope.of(context);
    setState(() {
      _pending = 'open';
      _failure = null;
      _open = false;
    });
    try {
      final uri = await model.dashboardUri(dashboard);
      await model.openExternal(uri);
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

/// Last step before a dashboard goes. Its panels and links go with it. Back
/// leaves it in place.
class DashboardDeletePage extends StatefulWidget {
  const DashboardDeletePage({required this.uuid, super.key});

  final String uuid;

  @override
  State<DashboardDeletePage> createState() => _DashboardDeletePageState();
}

class _DashboardDeletePageState extends State<DashboardDeletePage> {
  String? _failure;
  var _open = false;
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(const ['confirm'], wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        slot.id == 'back'
            ? backSlot(
                title: dashText(language, 'Назад', 'Back'),
                q: slot.q,
                r: slot.r,
              )
            : HexSlot(
                id: 'confirm',
                title: dashText(language, 'Удалить панель', 'Delete dashboard'),
                color: errorColor,
                busy: _busy,
                q: slot.q,
                r: slot.r,
                icon: 'assets/icons/actions/trash.svg',
              ),
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
    if (id == 'back') {
      popOrHome(context);
      return;
    }
    if (id == 'error') {
      setState(() => _open = true);
      return;
    }
    if (id != 'confirm' || _busy) return;
    setState(() {
      _busy = true;
      _failure = null;
      _open = false;
    });
    try {
      await AppScope.of(context).deleteDashboard(widget.uuid);
      if (!mounted) return;
      context.go('/dashboards/search');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = '$error';
      });
    }
  }
}
