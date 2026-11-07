import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../registry/repo.dart';
import '../../units/unit.dart';
import '../../units/unit_view.dart';
import '../hex_page.dart';
import '../line_input.dart';
import '../network/network_chrome.dart';
import '../slanted_choices.dart';
import 'units_chrome.dart';

/// Commit search. A tap returns the hash. A compilable unit shows tags only.
class CommitPickPage extends StatefulWidget {
  const CommitPickPage({
    required this.repoUuid,
    required this.branch,
    required this.compilable,
    required this.scope,
    super.key,
  });

  final String repoUuid;
  final String branch;
  final bool compilable;
  final int scope;

  @override
  State<CommitPickPage> createState() => _CommitPickPageState();
}

class _CommitPickPageState extends State<CommitPickPage> {
  static const _head = 2;

  var _offset = 0;
  var _count = 0;
  var _onlyTag = false;
  var _search = '';
  var _loading = false;
  var _open = false;
  String? _failure;
  var _ticket = 0;
  List<RepoCommit> _rows = const [];
  final _typing = SearchDelay();

  int _limit(AppModel model) =>
      model.cappedLimit(headPageLimit(widget.scope, head: _head));

  int _capacity() => headPageLimit(scaleTickMax, head: _head);

  String get _path =>
      '/units/new/commit?repo=${widget.repoUuid}'
      '&branch=${Uri.encodeQueryComponent(widget.branch)}'
      '&compilable=${widget.compilable ? '1' : '0'}';

  @override
  void initState() {
    super.initState();
    _onlyTag = widget.compilable;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  void didUpdateWidget(CommitPickPage oldWidget) {
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
    final board = headBoard(
      tick: widget.scope,
      head: const ['query', 'window'],
      ids: [for (final row in _rows) row.commit],
      prefix: 'sha:',
      total: _count,
      wide: wide,
    );
    final limit = _limit(model);
    final slots = <HexSlot>[
      for (final slot in board.slots) _slot(slot, language, limit),
    ];
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
      onTap: _tap,
      frame: (scene) => ScopeFrame(
        scope: widget.scope,
        canZoomIn: board.canZoomIn,
        path: _path,
        child: scene,
      ),
    );
  }

  HexSlot _slot(BoardSlot slot, String language, int limit) {
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
            compilable: widget.compilable,
            tags: _onlyTag,
            onSearch: (text) {
              _search = text;
              _searchLater();
            },
            onTags: (tags) {
              if (widget.compilable || tags == _onlyTag) return;
              setState(() => _onlyTag = tags);
              _retune();
            },
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
            onStep: _step,
          ),
        );
      default:
        final hash = slot.id.startsWith('sha:') ? slot.id.substring(4) : '';
        RepoCommit? row;
        for (final item in _rows) {
          if (item.commit == hash) row = item;
        }
        if (row == null) {
          return HexSlot(
            id: slot.id,
            title: '',
            color: color,
            q: slot.q,
            r: slot.r,
          );
        }
        final title = _title(row);
        final hashLabel = shortCommit(row.commit);
        return HexSlot(
          id: 'sha:${row.commit}',
          title: title,
          footer: hashLabel.isEmpty || hashLabel == title ? null : hashLabel,
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/objects/commit.svg',
        );
    }
  }

  String _title(RepoCommit row) {
    final tag = row.tag?.trim() ?? '';
    if (tag.isNotEmpty) return tailText(tag, 24);
    final summary = row.summary.trim();
    if (summary.isNotEmpty) return tailText(summary, 24);
    return shortCommit(row.commit);
  }

  void _tap(String id) {
    if (id.startsWith('sha:')) {
      context.pop(id.substring(4));
      return;
    }
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
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

  void _step(int direction) {
    if (_loading) return;
    final next = pageShift(
      direction: direction,
      offset: _offset,
      limit: _limit(AppScope.of(context)),
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
    if (model.target?.signedIn != true ||
        widget.repoUuid.isEmpty ||
        widget.branch.isEmpty) {
      setState(() {
        _loading = false;
        _failure = unitText(language, 'Нет входа', 'Not signed in');
      });
      return;
    }
    setState(() {
      _loading = true;
      _failure = null;
      _open = false;
    });
    try {
      final page = await model.branchCommits(
        widget.repoUuid,
        widget.branch,
        onlyTag: widget.compilable || _onlyTag,
        search: _search,
        offset: _offset,
        limit: _limit(model),
      );
      if (!mounted || ticket != _ticket) return;
      setState(() {
        _rows = page.commits;
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
    required this.compilable,
    required this.tags,
    required this.onSearch,
    required this.onTags,
  });

  final bool compilable;
  final bool tags;
  final ValueChanged<String> onSearch;
  final ValueChanged<bool> onTags;

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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    return LineInput(
      color: unitsColor,
      controller: _controller,
      fieldKey: const ValueKey('commit-search'),
      hint: unitText(language, 'Хеш или тег', 'Hash or tag'),
      leading: 'assets/icons/actions/search.svg',
      roomyCaption: !widget.compilable,
      onChanged: widget.onSearch,
      caption: widget.compilable
          ? null
          : _TagWords(tags: widget.tags, onTags: widget.onTags),
    );
  }
}

class _TagWords extends StatelessWidget {
  const _TagWords({required this.tags, required this.onTags});

  final bool tags;
  final ValueChanged<bool> onTags;

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    return LayoutBuilder(
      builder: (context, constraints) {
        final font = cellFont(constraints.maxWidth) * 1.55;
        return SlantedChoices(
          fontSize: font,
          maxWidth: searchLineWidth(constraints.maxWidth),
          choices: [
            SlantedChoice(
              label: unitText(language, 'Все', 'All'),
              selected: !tags,
              onTap: () => onTags(false),
            ),
            SlantedChoice(
              label: unitText(language, 'Только теги', 'Tags only'),
              selected: tags,
              onTap: () => onTags(true),
            ),
          ],
        );
      },
    );
  }
}
