import 'package:flutter/material.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../registry/registry_view.dart';
import '../../registry/repo.dart';
import '../hex_page.dart';
import '../network/network_chrome.dart';
import 'registry_chrome.dart';

/// Branches are names, so each one is a cell with the name across the top.
/// Tick 1 holds a short list. A higher tick shows more. A pager appears
/// only when the last tick is still too small.
class BranchesPage extends StatefulWidget {
  const BranchesPage({required this.uuid, required this.scope, super.key});

  final String uuid;
  final int scope;

  @override
  State<BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<BranchesPage> {
  RegistryRepo? _repo;
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
  void didUpdateWidget(BranchesPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope) _page = 0;
    if (oldWidget.uuid != widget.uuid) _load();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = registryColor;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final names = _repo?.branches ?? const <String>[];
    final board = names.isEmpty
        ? null
        : branchesBoard(
            tick: widget.scope,
            page: _page,
            names: names,
            wide: wide,
          );
    final slots = <HexSlot>[];
    if (board == null) {
      final frame = hexFrame(count: 1, back: HexBack.center, wide: wide);
      final back = frame.back!;
      slots.add(
        backSlot(
          title: regText(language, 'Назад', 'Back'),
          q: back.$1,
          r: back.$2,
        ),
      );
      if (!_loading && _failure == null) {
        slots.add(
          HexSlot(
            id: 'empty',
            title: regText(language, 'Нет веток', 'No branches'),
            color: color,
            q: frame.cells.first.$1,
            r: frame.cells.first.$2,
            tappable: false,
          ),
        );
      } else if (_loading) {
        slots.add(
          HexSlot(
            id: 'wait',
            title: regText(language, 'Ветки', 'Branches'),
            color: color,
            busy: true,
            q: frame.cells.first.$1,
            r: frame.cells.first.$2,
            tappable: false,
            icon: 'assets/icons/repo.svg',
          ),
        );
      }
    } else {
      for (final slot in board.slots) {
        slots.add(_slot(slot, language, color, board));
      }
    }
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: regText,
      wide: wide,
    );
    return HexPage(
      slots: slots,
      onTap: (id) {
        switch (id) {
          case 'back':
            popOrHome(context);
          case 'error':
            setState(() => _open = true);
        }
      },
      frame: board == null
          ? null
          : (scene) => ScopeFrame(
              scope: widget.scope,
              canZoomIn: board.canZoomIn,
              path: '/registry/repo/${widget.uuid}/branches',
              child: scene,
            ),
    );
  }

  HexSlot _slot(
    BoardSlot slot,
    String language,
    Color color,
    NetworkBoard board,
  ) {
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: regText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'prev':
        return pageStepSlot(
          id: 'prev',
          left: true,
          language: language,
          color: color,
          q: slot.q,
          r: slot.r,
          page: board.page,
          pages: board.pages,
          enabled: board.page > 0,
          onTap: () => setState(() => _page = board.page - 1),
        );
      case 'next':
        return pageStepSlot(
          id: 'next',
          left: false,
          language: language,
          color: color,
          q: slot.q,
          r: slot.r,
          page: board.page,
          pages: board.pages,
          enabled: board.page + 1 < board.pages,
          onTap: () => setState(() => _page = board.page + 1),
        );
      default:
        final name = slot.url ?? '';
        return HexSlot(
          id: slot.id,
          title: tailText(name, 24),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/repo.svg',
          tappable: false,
        );
    }
  }

  Future<void> _load() async {
    final model = AppScope.of(context);
    final language = model.vault.language;
    if (model.target?.signedIn != true) {
      setState(() {
        _loading = false;
        _failure = regText(language, 'Нет входа', 'Not signed in');
      });
      return;
    }
    setState(() {
      _loading = true;
      _failure = null;
      _open = false;
    });
    try {
      final repo = await model.readRepo(widget.uuid);
      if (!mounted) return;
      setState(() {
        _repo = repo;
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
