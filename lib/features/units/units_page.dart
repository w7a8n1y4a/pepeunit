import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../units/unit.dart';
import '../../units/unit_view.dart';
import '../hex_page.dart';
import '../line_input.dart';
import '../network/network_chrome.dart';
import 'units_chrome.dart';

/// Unit search. [pick] returns the chosen uuid with [pop] instead of opening
/// the card, and hides the group cell.
class UnitsPage extends StatefulWidget {
  const UnitsPage({required this.scope, this.pick = false, super.key});

  final int scope;
  final bool pick;

  @override
  State<UnitsPage> createState() => _UnitsPageState();
}

class _UnitsPageState extends State<UnitsPage> {
  var _offset = 0;
  var _loading = false;
  var _failureOpen = false;
  String? _failure;
  var _ticket = 0;
  final _typing = SearchDelay();
  List<Unit> _units = const [];
  var _count = 0;
  late final UnitQuery _local = UnitQuery();

  UnitQuery _query(BuildContext context) =>
      widget.pick ? _local : AppScope.of(context).unitQuery;

  int _rowLimit() {
    final asked = widget.pick
        ? headPageLimit(widget.scope)
        : unitPageLimit(widget.scope);
    return AppScope.of(context).cappedLimit(asked);
  }

  int _capacity() =>
      widget.pick ? headPageLimit(scaleTickMax) : unitPageLimit(scaleTickMax);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void didUpdateWidget(UnitsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope == widget.scope) return;
    _offset = 0;
    _load();
  }

  @override
  void dispose() {
    _typing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = unitsBoard(
      tick: widget.scope,
      uuids: [for (final unit in _units) unit.uuid],
      picking: widget.pick,
      wide: wide,
    );
    final limit = _rowLimit();
    final slots = <HexSlot>[
      for (final slot in board.slots) _slot(slot, language, limit, model),
    ];
    appendError(
      slots,
      message: _failure,
      open: _failureOpen,
      language: language,
      text: unitText,
      wide: wide,
    );
    return HexPage(
      slots: slots,
      onTap: _tap,
      frame: (scene) => ScopeFrame(
        scope: widget.scope,
        canZoomIn: widget.scope < scaleTickMax,
        path: widget.pick ? '/units/pick' : '/units',
        child: scene,
      ),
    );
  }

  HexSlot _slot(BoardSlot slot, String language, int limit, AppModel model) {
    final color = unitsColor;
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: unitText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'query':
        return HexSlot(
          id: 'query',
          title: unitText(language, 'Фильтр', 'Filter'),
          color: color,
          q: slot.q,
          r: slot.r,
          body: _QueryCell(
            query: _query(context),
            local: widget.pick,
            onSearch: _searchLater,
            onRetune: _retune,
          ),
        );
      case 'groups':
        return HexSlot(
          id: 'groups',
          title: unitText(language, 'Группы', 'Groups'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/instances.svg',
        );
      case 'window':
        return HexSlot(
          id: 'window',
          title: unitText(language, 'Страница', 'Page'),
          color: color,
          busy: _loading,
          q: slot.q,
          r: slot.r,
          body: UnitWindow(
            language: language,
            offset: _offset,
            limit: limit,
            count: _count,
            capacity: _capacity(),
            order: _query(context).order,
            onOrder: _order,
            onStep: _step,
          ),
        );
      default:
        final uuid = slot.id.startsWith('unit:') ? slot.id.substring(5) : '';
        Unit? unit;
        for (final item in _units) {
          if (item.uuid == uuid) unit = item;
        }
        if (unit == null) {
          return HexSlot(
            id: slot.id,
            title: '',
            color: color,
            q: slot.q,
            r: slot.r,
          );
        }
        return unitMark(
          id: 'unit:${unit.uuid}',
          unit: unit,
          language: language,
          q: slot.q,
          r: slot.r,
          image: model.cachedIcon(unit.iconUuid),
        );
    }
  }

  Future<void> _tap(String id) async {
    if (id.startsWith('unit:')) {
      final uuid = id.substring(5);
      if (widget.pick) {
        context.pop(uuid);
      } else {
        context.push('/units/$uuid');
      }
      return;
    }
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _failureOpen = true);
      case 'groups':
        context.push('/units/groups');
    }
  }

  void _searchLater() {
    _typing.later(() {
      if (!mounted) return;
      setState(() => _offset = 0);
      _load();
    });
  }

  void _retune() {
    _typing.cancel();
    setState(() => _offset = 0);
    _load();
  }

  void _order(String value) {
    final changed = widget.pick
        ? _query(context).setOrder(value)
        : AppScope.of(context).setUnitOrder(value);
    if (!changed) return;
    _retune();
  }

  void _step(int direction) {
    if (_loading) return;
    final limit = _rowLimit();
    final next = pageShift(
      direction: direction,
      offset: _offset,
      limit: limit,
      count: _count,
      capacity: _capacity(),
    );
    if (next == null) return;
    setState(() => _offset = next);
    _load();
  }

  Future<void> _load() async {
    final ticket = ++_ticket;
    final model = AppScope.of(context);
    final language = model.vault.language;
    if (model.target?.signedIn != true) {
      setState(() {
        _loading = false;
        _failure = unitText(language, 'Нет входа', 'Not signed in');
      });
      return;
    }
    setState(() {
      _loading = true;
      _failure = null;
      _failureOpen = false;
    });
    try {
      final limit = _rowLimit();
      final page = await model.listUnits(
        offset: _offset,
        limit: limit,
        query: _query(context),
      );
      if (!mounted || ticket != _ticket) return;
      unawaited(
        model.ensureIcons([for (final unit in page.units) unit.iconUuid]),
      );
      setState(() {
        _units = page.units;
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

class _QueryCell extends StatefulWidget {
  const _QueryCell({
    required this.query,
    required this.local,
    required this.onSearch,
    required this.onRetune,
  });

  final UnitQuery query;
  final bool local;
  final VoidCallback onSearch;
  final VoidCallback onRetune;

  @override
  State<_QueryCell> createState() => _QueryCellState();
}

class _QueryCellState extends State<_QueryCell> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query.text);
  }

  @override
  void didUpdateWidget(_QueryCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text == widget.query.text) return;
    _controller.value = TextEditingValue(
      text: widget.query.text,
      selection: TextSelection.collapsed(offset: widget.query.text.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final query = widget.query;
    return LineInput(
      color: unitsColor,
      controller: _controller,
      fieldKey: const ValueKey('unit-search'),
      hint: unitText(language, 'Поиск', 'Search'),
      leading: 'assets/icons/search.svg',
      roomyCaption: true,
      onChanged: (text) {
        if (widget.local) {
          query.text = text;
        } else {
          AppScope.of(context).setUnitSearch(text);
        }
        widget.onSearch();
      },
      caption: Column(
        children: [
          Expanded(
            child: FilterLine(
              choices: [
                for (final owner in const ['mine', 'all'])
                  (id: owner, label: unitOwnerLabel(language, owner)),
              ],
              selected: (id) => query.owner == id,
              onTap: (id) {
                final changed = widget.local
                    ? query.setOwner(id)
                    : AppScope.of(context).setUnitOwner(id);
                if (!changed) return;
                widget.onRetune();
              },
            ),
          ),
          Expanded(
            child: FilterLine(
              choices: [
                for (final level in unitVisibilities)
                  (id: level, label: unitVisibilityLabel(language, level)),
              ],
              selected: query.visibility.contains,
              onTap: (id) {
                final changed = widget.local
                    ? query.toggleVisibility(id)
                    : AppScope.of(context).toggleUnitVisibility(id);
                if (!changed) return;
                widget.onRetune();
              },
            ),
          ),
          Expanded(
            child: FilterLine(
              choices: [
                for (final auto in const ['on', 'off'])
                  (id: auto, label: unitAutoLabel(language, auto)),
              ],
              selected: query.autos.contains,
              onTap: (id) {
                final changed = widget.local
                    ? query.toggleAuto(id)
                    : AppScope.of(context).toggleUnitAuto(id);
                if (!changed) return;
                widget.onRetune();
              },
            ),
          ),
        ],
      ),
    );
  }
}
