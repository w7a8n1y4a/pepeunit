import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../navigation/pick.dart';
import '../../registry/registry_view.dart';
import '../../registry/repo.dart';
import '../hex_page.dart';
import '../line_input.dart';
import '../network/network_chrome.dart';
import '../page_window.dart';
import '../slanted_choices.dart';
import 'registry_chrome.dart';

/// Repository search. [forUnit] gives the chosen repository to the unit form
/// that opened this search, through [givePick].
class RegistryPage extends StatefulWidget {
  const RegistryPage({required this.scope, this.forUnit = false, super.key});

  final int scope;
  final bool forUnit;

  @override
  State<RegistryPage> createState() => _RegistryPageState();
}

class _RegistryPageState extends State<RegistryPage> {
  var _offset = 0;
  var _loading = false;
  var _failureOpen = false;
  String? _failure;
  var _ticket = 0;
  final _typing = SearchDelay();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void didUpdateWidget(RegistryPage oldWidget) {
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
    final color = registryColor;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final page = model.registry;
    final repos = page?.repos ?? const <RegistryRepo>[];
    final board = reposBoard(
      tick: widget.scope,
      uuids: [for (final repo in repos) repo.uuid],
      wide: wide,
    );
    final limit = _limit(model);
    final slots = <HexSlot>[
      for (final slot in board.slots)
        _slot(slot, language, color, repos, page?.count ?? 0, limit, model),
    ];
    appendError(
      slots,
      message: _failure,
      open: _failureOpen,
      language: language,
      text: regText,
      wide: wide,
    );
    return HexPage(
      slots: slots,
      onTap: (id) => _tap(id),
      frame: (scene) => ScopeFrame(
        scope: widget.scope,
        canZoomIn: widget.scope < scaleTickMax,
        path: widget.forUnit ? '/units/new/repo' : '/registry/search',
        child: scene,
      ),
    );
  }

  HexSlot _slot(
    BoardSlot slot,
    String language,
    Color color,
    List<RegistryRepo> repos,
    int count,
    int limit,
    AppModel model,
  ) {
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: regText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'query':
        return HexSlot(
          id: 'query',
          title: regText(language, 'Фильтр', 'Filter'),
          color: color,
          q: slot.q,
          r: slot.r,
          body: _QueryCell(
            color: color,
            onSearch: _searchLater,
            onRetune: _retune,
          ),
        );
      case 'window':
        return HexSlot(
          id: 'window',
          title: regText(language, 'Страница', 'Page'),
          color: color,
          busy: _loading,
          q: slot.q,
          r: slot.r,
          body: _WindowCell(
            offset: _offset,
            limit: limit,
            count: count,
            onStep: _step,
            onOrder: _order,
          ),
        );
      default:
        final uuid = slot.id.startsWith('repo:') ? slot.id.substring(5) : '';
        RegistryRepo? repo;
        for (final item in repos) {
          if (item.uuid == uuid) repo = item;
        }
        if (repo == null) {
          return HexSlot(
            id: slot.id,
            title: '',
            color: color,
            q: slot.q,
            r: slot.r,
          );
        }
        return repoMark(
          id: 'repo:${repo.uuid}',
          repo: repo,
          language: language,
          q: slot.q,
          r: slot.r,
          image: model.cachedIcon(repo.iconUuid),
        );
    }
  }

  void _tap(String id) {
    if (id.startsWith('repo:')) {
      final uuid = id.substring(5);
      if (widget.forUnit) {
        if (context.canPop()) {
          givePick(context, uuid);
        } else {
          context.push('/units/new?repo=$uuid');
        }
        return;
      }
      context.push('/registry/repo/$uuid');
      return;
    }
    switch (id) {
      case 'back':
        widget.forUnit ? givePick(context, null) : popOrHome(context);
      case 'error':
        setState(() => _failureOpen = true);
    }
  }

  int _limit(AppModel model) => model.cappedLimit(repoPageLimit(widget.scope));

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
    final model = AppScope.of(context);
    if (!model.setRepoOrder(value)) return;
    _retune();
  }

  void _step(int direction) {
    if (_loading) return;
    final model = AppScope.of(context);
    final count = model.registry?.count ?? 0;
    final limit = _limit(model);
    final next = pageShift(
      direction: direction,
      offset: _offset,
      limit: limit,
      count: count,
      capacity: repoPageLimit(scaleTickMax),
    );
    if (next == null) return;
    setState(() => _offset = next);
    _load();
  }

  Future<void> _load() async {
    final ticket = ++_ticket;
    final model = AppScope.of(context);
    if (!model.signedIn) {
      setState(() {
        _loading = false;
        _failure = model.notSignedIn;
      });
      return;
    }
    setState(() {
      _loading = true;
      _failure = null;
      _failureOpen = false;
    });
    try {
      final fresh = await model.loadRegistry(
        offset: _offset,
        limit: _limit(model),
      );
      if (!mounted || ticket != _ticket || !fresh) return;
      setState(() => _loading = false);
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
    required this.color,
    required this.onSearch,
    required this.onRetune,
  });

  final Color color;
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
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final text = AppScope.of(context).repoQuery.text;
    if (_controller.text == text) return;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
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
    return LineInput(
      color: widget.color,
      controller: _controller,
      fieldKey: const ValueKey('registry-search'),
      hint: regText(language, 'Поиск', 'Search'),
      leading: 'assets/icons/actions/search.svg',
      roomyCaption: true,
      onChanged: (text) {
        AppScope.of(context).setRepoSearch(text);
        widget.onSearch();
      },
      caption: _KindWords(onKind: widget.onRetune),
    );
  }
}

class _KindWords extends StatelessWidget {
  const _KindWords({required this.onKind});

  final VoidCallback onKind;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final query = model.repoQuery;
    return LayoutBuilder(
      builder: (context, constraints) {
        final font = cellFont(constraints.maxWidth) * 1.55;
        return SlantedChoices(
          fontSize: font,
          maxWidth: searchLineWidth(constraints.maxWidth),
          choices: [
            for (final kind in repoKinds)
              SlantedChoice(
                label: repoKindLabel(language, kind),
                selected: query.kinds.contains(kind),
                onTap: () {
                  if (model.toggleRepoKind(kind)) onKind();
                },
              ),
          ],
        );
      },
    );
  }
}

class _WindowCell extends StatelessWidget {
  const _WindowCell({
    required this.offset,
    required this.limit,
    required this.count,
    required this.onStep,
    required this.onOrder,
  });

  final int offset;
  final int limit;
  final int count;
  final ValueChanged<int> onStep;
  final ValueChanged<String> onOrder;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final order = model.repoQuery.order;
    final range = pageWindowText(
      offset: offset,
      limit: limit,
      count: count,
      ofWord: regText(language, 'из', 'of'),
    );
    return OrderWindow(
      orders: [
        for (final value in const ['asc', 'desc'])
          (value: value, label: repoOrderLabel(language, value)),
      ],
      selected: order,
      onOrder: onOrder,
      range: range,
      canBack: repoCanPageBack(offset: offset, count: count),
      canForward: repoCanPageForward(
        offset: offset,
        limit: limit,
        count: count,
      ),
      previousLabel: regText(language, 'Предыдущие', 'Previous'),
      nextLabel: regText(language, 'Следующие', 'Next'),
      onStep: onStep,
    );
  }
}
