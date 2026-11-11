import 'package:flutter/material.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/pick.dart';
import '../../units/unit_view.dart';
import '../hex_page.dart';
import '../network/network_chrome.dart';
import 'units_chrome.dart';
import '../../locale/languages.dart';

/// A short named list. A tap gives the id to the opener through [givePick];
/// the opener awaits it with [openPick].
///
/// With [paged] a page window cell stands right after Back and the items
/// follow it, so a long list shows its range and the arrows instead of
/// leaving the person to find the zoom.
class NamePickPage extends StatefulWidget {
  const NamePickPage({
    required this.title,
    required this.scope,
    required this.path,
    required this.load,
    this.icon,
    this.color,
    this.paged = false,
    super.key,
  });

  final String title;
  final int scope;
  final String path;
  final Future<List<PickItem>> Function() load;
  final String? icon;
  final Color? color;
  final bool paged;

  @override
  State<NamePickPage> createState() => _NamePickPageState();
}

class _NamePickPageState extends State<NamePickPage> {
  List<PickItem> _items = const [];
  String? _failure;
  var _open = false;
  var _loading = true;
  var _page = 0;
  var _offset = 0;

  /// Cell ahead of the items in a paged list: the page window.
  static const _head = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(NamePickPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope == widget.scope) return;
    _page = 0;
    _offset = 0;
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final limit = headPageLimit(widget.scope, head: _head);
    final capacity = headPageLimit(scaleTickMax, head: _head);
    final shown = widget.paged
        ? _items.skip(_offset).take(limit).toList()
        : _items;
    final board = _items.isEmpty
        ? null
        : widget.paged
        ? listBoard(
            tick: widget.scope,
            head: const ['window'],
            ids: [for (final item in shown) item.id],
            prefix: _prefix,
            total: _items.length,
            wide: wide,
          )
        : tailBoard(
            tick: widget.scope,
            page: _page,
            ids: [for (final item in _items) item.id],
            wide: wide,
          );
    final slots = <HexSlot>[];
    if (board == null) {
      final frame = hexFrame(count: 1, back: HexBack.center, wide: wide);
      slots.add(
        backSlot(language, q: frame.back!.$1, r: frame.back!.$2),
      );
      slots.add(
        HexSlot(
          id: 'empty',
          title: _loading ? widget.title : localized(language, 'Пусто', 'Empty'),
          color: widget.color ?? unitsColor,
          busy: _loading,
          tappable: false,
          q: frame.cells.first.$1,
          r: frame.cells.first.$2,
        ),
      );
    } else {
      for (final slot in board.slots) {
        if (slot.id == 'back') {
          slots.add(
            backSlot(language, q: slot.q, r: slot.r),
          );
        } else if (slot.id == 'window') {
          slots.add(
            HexSlot(
              id: 'window',
              title: localized(language, 'Страница', 'Page'),
              color: widget.color ?? unitsColor,
              q: slot.q,
              r: slot.r,
              body: UnitWindow(
                language: language,
                offset: _offset,
                limit: limit,
                count: _items.length,
                capacity: capacity,
                onStep: (direction) => _step(direction, limit, capacity),
              ),
            ),
          );
        } else if (slot.id == 'prev' || slot.id == 'next') {
          final forward = slot.id == 'next';
          slots.add(
            pageStepSlot(
              id: slot.id,
              left: !forward,
              language: language,
              color: widget.color ?? unitsColor,
              q: slot.q,
              r: slot.r,
              page: board.page,
              pages: board.pages,
              enabled: forward ? board.page < board.pages - 1 : board.page > 0,
              onTap: () =>
                  setState(() => _page = board.page + (forward ? 1 : -1)),
            ),
          );
        } else {
          final id = slot.id.substring(_prefix.length);
          final item = _items.cast<PickItem?>().firstWhere(
            (row) => row!.id == id,
            orElse: () => null,
          );
          slots.add(
            HexSlot(
              id: slot.id,
              hint: 'item',
              title: item?.label ?? slot.id,
              color: widget.color ?? unitsColor,
              q: slot.q,
              r: slot.r,
              icon: widget.icon,
            ),
          );
        }
      }
    }
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
        if (id == 'back') {
          givePick(context, null);
        } else if (id == 'error') {
          setState(() => _open = true);
        } else if (id.startsWith(_prefix) &&
            _items.any((item) => item.id == id.substring(_prefix.length))) {
          givePick(context, id.substring(_prefix.length));
        }
      },
      frame: board == null
          ? null
          : (scene) => ScopeFrame(
              scope: widget.scope,
              canZoomIn: board.canZoomIn,
              path: widget.path,
              child: scene,
            ),
    );
  }

  String get _prefix => widget.paged ? 'item:' : '';

  void _step(int direction, int limit, int capacity) {
    final next = pageShift(
      direction: direction,
      offset: _offset,
      limit: limit,
      count: _items.length,
      capacity: capacity,
    );
    if (next == null) return;
    setState(() => _offset = next);
  }

  Future<void> _load() async {
    final model = AppScope.of(context);
    if (!model.signedIn) {
      setState(() {
        _loading = false;
        _failure = model.notSignedIn;
      });
      return;
    }
    try {
      final items = model.pickItems ?? await widget.load();
      if (!mounted) return;
      setState(() {
        _items = items;
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
