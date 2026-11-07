import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../units/unit_view.dart';
import '../hex_page.dart';
import '../network/network_chrome.dart';
import 'units_chrome.dart';

/// A short named list. A tap returns the id to the page that opened it.
///
/// With [viaModel] the id goes to [AppModel.finishPick] instead of the route
/// result, for an opener that awaits [AppModel.beginPick]. Zooming replaces
/// this route, and a replaced route never delivers its result.
class NamePickPage extends StatefulWidget {
  const NamePickPage({
    required this.title,
    required this.scope,
    required this.path,
    required this.load,
    this.icon,
    this.color,
    this.viaModel = false,
    super.key,
  });

  final String title;
  final int scope;
  final String path;
  final Future<List<({String id, String label})>> Function() load;
  final String? icon;
  final Color? color;
  final bool viaModel;

  @override
  State<NamePickPage> createState() => _NamePickPageState();
}

class _NamePickPageState extends State<NamePickPage> {
  List<({String id, String label})> _items = const [];
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
  void didUpdateWidget(NamePickPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope) _page = 0;
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = _items.isEmpty
        ? null
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
        backSlot(
          title: unitText(language, 'Назад', 'Back'),
          q: frame.back!.$1,
          r: frame.back!.$2,
        ),
      );
      slots.add(
        HexSlot(
          id: 'empty',
          title: _loading ? widget.title : unitText(language, 'Пусто', 'Empty'),
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
            backSlot(
              title: unitText(language, 'Назад', 'Back'),
              q: slot.q,
              r: slot.r,
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
          final item = _items.cast<({String id, String label})?>().firstWhere(
            (row) => row!.id == slot.id,
            orElse: () => null,
          );
          slots.add(
            HexSlot(
              id: slot.id,
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
        } else if (_items.any((item) => item.id == id)) {
          if (widget.viaModel) {
            AppScope.of(context).finishPick(id);
            popOrHome(context);
          } else {
            context.pop(id);
          }
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
      final items = await widget.load();
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
