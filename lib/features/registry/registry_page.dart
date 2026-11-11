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
import '../paged_search.dart';
import '../slanted_choices.dart';
import 'registry_chrome.dart';
import '../../locale/languages.dart';

/// Repository search. [forUnit] gives the chosen repository to the unit form
/// that opened this search, through [givePick].
class RegistryPage extends StatefulWidget {
  const RegistryPage({required this.scope, this.forUnit = false, super.key});

  final int scope;
  final bool forUnit;

  @override
  State<RegistryPage> createState() => _RegistryPageState();
}

class _RegistryPageState extends State<RegistryPage>
    with PagedSearch<RegistryPage> {
  @override
  int scopeOf(RegistryPage widget) => widget.scope;

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
      message: failure,
      open: failureOpen,
      language: language,
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
        return backSlot(language, q: slot.q, r: slot.r);
      case 'query':
        return HexSlot(
          id: 'query',
          title: localized(language, 'Фильтр', 'Filter'),
          color: color,
          q: slot.q,
          r: slot.r,
          body: _QueryCell(
            color: color,
            onSearch: searchLater,
            onRetune: retune,
          ),
        );
      case 'window':
        return HexSlot(
          id: 'window',
          title: localized(language, 'Страница', 'Page'),
          color: color,
          busy: loading,
          q: slot.q,
          r: slot.r,
          body: _WindowCell(
            offset: offset,
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
        setState(() => failureOpen = true);
    }
  }

  int _limit(AppModel model) => model.cappedLimit(headPageLimit(widget.scope));

  void _order(String value) {
    final model = AppScope.of(context);
    if (!model.setRepoOrder(value)) return;
    retune();
  }

  void _step(int direction) {
    final model = AppScope.of(context);
    step(
      direction,
      limit: _limit(model),
      count: model.registry?.count ?? 0,
      capacity: model.pageCapacity(headPageLimit(scaleTickMax)),
    );
  }

  @override
  Future<VoidCallback?> fetch(AppModel model) async {
    final fresh = await model.loadRegistry(
      offset: offset,
      limit: _limit(model),
    );
    return fresh ? () {} : null;
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
      hint: localized(language, 'Поиск', 'Search'),
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
      ofWord: localized(language, 'из', 'of'),
    );
    return OrderWindow(
      orders: [
        for (final value in const ['asc', 'desc'])
          (value: value, label: repoOrderLabel(language, value)),
      ],
      selected: order,
      onOrder: onOrder,
      range: range,
      canBack: listCanBack(
        offset: offset,
        count: count,
        cap: model.pageLimit,
      ),
      canForward: listCanForward(
        offset: offset,
        limit: limit,
        count: count,
        cap: model.pageLimit,
      ),
      previousLabel: localized(language, 'Предыдущие', 'Previous'),
      nextLabel: localized(language, 'Следующие', 'Next'),
      onStep: onStep,
    );
  }
}
