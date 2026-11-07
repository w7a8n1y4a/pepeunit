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
import '../slanted_choices.dart';
import 'units_chrome.dart';

/// Unit search. [pick] returns the chosen uuid with [pop] instead of opening
/// the card. [outputsOnly] lists only units that have an output, and a tap
/// opens that unit's outputs; the chosen output goes to
/// [AppModel.finishPick]. [anyNode] does the same for units with a node of
/// either direction, as a panel takes inputs and outputs alike.
class UnitsPage extends StatefulWidget {
  const UnitsPage({
    required this.scope,
    this.pick = false,
    this.outputsOnly = false,
    this.anyNode = false,
    super.key,
  });

  final int scope;
  final bool pick;
  final bool outputsOnly;
  final bool anyNode;

  /// Types of node the list is limited to, or null for plain units.
  List<String>? get _nodeTypes {
    if (outputsOnly) return const ['Output'];
    if (anyNode) return const ['Input', 'Output'];
    return null;
  }

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

  int _rowLimit() =>
      AppScope.of(context)
          .cappedLimit(headPageLimit(widget.scope, head: unitsHead));

  int _capacity() => headPageLimit(scaleTickMax, head: unitsHead);

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
        path: widget.pick
            ? (widget.outputsOnly
                  ? '/units/pick?outputs=1'
                  : widget.anyNode
                  ? '/units/pick?nodes=1'
                  : '/units/pick')
            : '/units/search',
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
          title: unitText(language, 'Поиск', 'Search'),
          color: color,
          q: slot.q,
          r: slot.r,
          body: _QueryCell(
            query: _query(context),
            local: widget.pick,
            onSearch: _searchLater,
          ),
        );
      case 'filter':
        return HexSlot(
          id: 'filter',
          title: unitText(language, 'Показать', 'Show'),
          color: color,
          q: slot.q,
          r: slot.r,
          tappable: false,
          body: _ShowCell(
            query: _query(context),
            local: widget.pick,
            onRetune: _retune,
          ),
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
      if (widget.pick && widget._nodeTypes != null) {
        // The node screen hands the answer over and closes this one too.
        final kind = widget.anyNode ? '&nodes=1' : '';
        context.push('/units/outputs?unit=$uuid$kind');
      } else if (widget.pick) {
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
        ioTypes: widget._nodeTypes,
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
  });

  final UnitQuery query;
  final bool local;
  final VoidCallback onSearch;

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
      hint: unitText(language, 'Название', 'Name'),
      leading: 'assets/icons/actions/search.svg',
      onChanged: (text) {
        if (widget.local) {
          query.text = text;
        } else {
          AppScope.of(context).setUnitSearch(text);
        }
        widget.onSearch();
      },
    );
  }
}

/// Owner, visibility and auto mode: one enum each, one shared size.
class _ShowCell extends StatelessWidget {
  const _ShowCell({
    required this.query,
    required this.local,
    required this.onRetune,
  });

  final UnitQuery query;
  final bool local;
  final VoidCallback onRetune;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    const owners = ['mine', 'all'];
    const autos = ['on', 'off'];
    final groups = [
      [for (final owner in owners) unitOwnerLabel(language, owner)],
      [
        for (final level in unitVisibilities)
          unitVisibilityLabel(language, level),
      ],
      [for (final auto in autos) unitAutoLabel(language, auto)],
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final line = side * (1 - 2 * _showInset);
        final font = _showFont(
          ceiling: cellFont(side) * 1.55,
          line: line,
          band: side * _showBand,
          scaler: MediaQuery.textScalerOf(context),
          groups: groups,
        );
        Widget block(List<SlantedChoice> choices) => SlantedChoices(
          fontSize: font,
          maxWidth: line,
          lineGapShare: _showGapShare,
          choices: choices,
        );
        return Padding(
          padding: EdgeInsets.only(top: side * _showDrop),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                block([
                  for (final owner in owners)
                    SlantedChoice(
                      label: unitOwnerLabel(language, owner),
                      selected: query.owner == owner,
                      onTap: () {
                        final changed = local
                            ? query.setOwner(owner)
                            : model.setUnitOwner(owner);
                        if (changed) onRetune();
                      },
                    ),
                ]),
                SizedBox(height: font * _showBlockGap),
                block([
                  for (final level in unitVisibilities)
                    SlantedChoice(
                      label: unitVisibilityLabel(language, level),
                      selected: query.visibility.contains(level),
                      onTap: () {
                        final changed = local
                            ? query.toggleVisibility(level)
                            : model.toggleUnitVisibility(level);
                        if (changed) onRetune();
                      },
                    ),
                ]),
                SizedBox(height: font * _showBlockGap),
                block([
                  for (final auto in autos)
                    SlantedChoice(
                      label: unitAutoLabel(language, auto),
                      selected: query.autos.contains(auto),
                      onTap: () {
                        final changed = local
                            ? query.toggleAuto(auto)
                            : model.toggleUnitAuto(auto);
                        if (changed) onRetune();
                      },
                    ),
                ]),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// How far the enums sit below the cell center, under the title.
const _showDrop = 0.06;

/// Side inset of the enums, as a share of the cell.
const _showInset = 0.13;

/// Height the enums may use, as a share of the cell.
const _showBand = 0.54;

const _showGapShare = 0.2;

/// Clear space between two enums, in font heights.
const _showBlockGap = 0.5;

/// Largest size at or under [ceiling] whose enums fit in [line] and [band].
double _showFont({
  required double ceiling,
  required double line,
  required double band,
  required TextScaler scaler,
  required List<List<String>> groups,
}) {
  if (!line.isFinite || line <= 0) return ceiling;
  bool fits(double font) {
    var total = font * _showBlockGap * (groups.length - 1);
    for (final labels in groups) {
      final height = slantedEnumHeight(
        labels: labels,
        fontSize: font,
        maxWidth: line,
        scaler: scaler,
        lineGapShare: _showGapShare,
      );
      if (height == null) return false;
      total += height;
    }
    return total <= band + 0.5;
  }

  if (fits(ceiling)) return ceiling;
  var low = 1.0;
  var high = ceiling;
  if (high <= low || !fits(low)) return low;
  for (var step = 0; step < 14; step++) {
    final mid = (low + high) / 2;
    if (fits(mid)) {
      low = mid;
    } else {
      high = mid;
    }
  }
  return low;
}
