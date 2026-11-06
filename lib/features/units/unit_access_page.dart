import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

class AccessPage extends StatefulWidget {
  const AccessPage({
    required this.resourceUuid,
    required this.resourceType,
    required this.scope,
    required this.path,
    super.key,
  });

  final String resourceUuid;
  final String resourceType;
  final int scope;
  final String path;

  @override
  State<AccessPage> createState() => _AccessPageState();
}

class _AccessPageState extends State<AccessPage> {
  List<AccessGrant> _grants = const [];
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
  void didUpdateWidget(AccessPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope != widget.scope) _page = 0;
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = tailBoard(
      tick: widget.scope,
      page: _page,
      head: const ['add'],
      ids: [for (final grant in _grants) grant.uuid],
      wide: wide,
    );
    final slots = <HexSlot>[
      for (final slot in board.slots) _slot(slot, language, board),
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
      onTap: (id) => _tap(id),
      frame: (scene) => ScopeFrame(
        scope: widget.scope,
        canZoomIn: board.canZoomIn,
        path: widget.path,
        child: scene,
      ),
    );
  }

  HexSlot _slot(BoardSlot slot, String language, NetworkBoard board) {
    final color = widget.resourceType == 'UnitIO' ? unitIoColor : unitsColor;
    if (slot.id == 'back') {
      return backSlot(
        title: unitText(language, 'Назад', 'Back'),
        q: slot.q,
        r: slot.r,
      );
    }
    if (slot.id == 'add') {
      return HexSlot(
        id: 'add',
        title: unitText(language, 'Добавить', 'Add'),
        color: color,
        busy: _loading,
        q: slot.q,
        r: slot.r,
        icon: 'assets/icons/plus.svg',
      );
    }
    if (slot.id == 'prev' || slot.id == 'next') {
      final forward = slot.id == 'next';
      return pageStepSlot(
        id: slot.id,
        left: !forward,
        language: language,
        color: color,
        q: slot.q,
        r: slot.r,
        page: board.page,
        pages: board.pages,
        enabled: forward ? board.page < board.pages - 1 : board.page > 0,
        onTap: () => setState(() => _page = board.page + (forward ? 1 : -1)),
      );
    }
    AccessGrant? grant;
    for (final item in _grants) {
      if (item.uuid == slot.id) grant = item;
    }
    return HexSlot(
      id: slot.id,
      title: grant == null ? slot.id : grant.agentType,
      footer: grant == null ? null : shortCommit(grant.agentUuid),
      color: color,
      q: slot.q,
      r: slot.r,
      icon: grant?.agentType == 'Unit'
          ? 'assets/icons/micro.svg'
          : 'assets/icons/account.svg',
    );
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
    if (id == 'add') {
      final kind = await context.push<String>('/units/access/kind');
      if (kind == null || !mounted) return;
      final agent = kind == 'Unit'
          ? await context.push<String>('/units/pick')
          : await context.push<String>('/units/pick-user');
      if (agent == null || !mounted) return;
      try {
        await AppScope.of(context).createAccess(
          agentUuid: agent,
          agentType: kind,
          resourceUuid: widget.resourceUuid,
          resourceType: widget.resourceType,
        );
        await _load();
      } catch (error) {
        if (!mounted) return;
        setState(() => _failure = '$error');
      }
      return;
    }
    AccessGrant? grant;
    for (final item in _grants) {
      if (item.uuid == id) grant = item;
    }
    if (grant == null) return;
    try {
      await AppScope.of(context).deleteAccess(grant);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _failure = '$error');
    }
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
      final page = await model.accessGrants(
        resourceUuid: widget.resourceUuid,
        resourceType: widget.resourceType,
        offset: 0,
        limit: model.pageLimit,
      );
      if (!mounted) return;
      setState(() {
        _grants = page.grants;
        _loading = false;
        _failure = null;
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

class AccessKindPage extends StatelessWidget {
  const AccessKindPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(const ['User', 'Unit'], wide: wide);
    return HexPage(
      slots: [
        for (final slot in placed)
          slot.id == 'back'
              ? backSlot(
                  title: unitText(language, 'Назад', 'Back'),
                  q: slot.q,
                  r: slot.r,
                )
              : HexSlot(
                  id: slot.id,
                  title: slot.id == 'User'
                      ? unitText(language, 'Пользователь', 'User')
                      : unitText(language, 'Аппарат', 'Unit'),
                  color: unitsColor,
                  q: slot.q,
                  r: slot.r,
                  icon: slot.id == 'User'
                      ? 'assets/icons/account.svg'
                      : 'assets/icons/micro.svg',
                ),
      ],
      onTap: (id) {
        if (id == 'back') {
          popOrHome(context);
        } else if (id == 'User' || id == 'Unit') {
          context.pop(id);
        }
      },
    );
  }
}

class UserPickPage extends StatefulWidget {
  const UserPickPage({super.key});

  @override
  State<UserPickPage> createState() => _UserPickPageState();
}

class _UserPickPageState extends State<UserPickPage> {
  final _search = TextEditingController();
  List<({String uuid, String login})> _users = const [];
  String? _failure;
  var _open = false;
  var _loading = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard([
      'query',
      for (final user in _users) user.uuid,
    ], wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        if (slot.id == 'back')
          backSlot(
            title: unitText(language, 'Назад', 'Back'),
            q: slot.q,
            r: slot.r,
          )
        else if (slot.id == 'query')
          HexSlot(
            id: 'query',
            title: unitText(language, 'Поиск', 'Search'),
            color: unitsColor,
            busy: _loading,
            q: slot.q,
            r: slot.r,
            body: LineInput(
              color: unitsColor,
              controller: _search,
              hint: unitText(language, 'логин', 'login'),
              leading: 'assets/icons/search.svg',
              onSubmitted: (_) => _load(),
            ),
          )
        else
          HexSlot(
            id: slot.id,
            title: _users
                .firstWhere(
                  (user) => user.uuid == slot.id,
                  orElse: () => (uuid: slot.id, login: slot.id),
                )
                .login,
            color: unitsColor,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/account.svg',
          ),
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
      onTap: (id) {
        if (id == 'back') {
          popOrHome(context);
        } else if (id == 'error') {
          setState(() => _open = true);
        } else if (_users.any((user) => user.uuid == id)) {
          context.pop(id);
        }
      },
    );
  }

  Future<void> _load() async {
    final model = AppScope.of(context);
    final previous = model.userQuery.text;
    model.setUserSearch(_search.text.trim());
    setState(() {
      _loading = true;
      _failure = null;
    });
    try {
      final page = await model.loadDirectory(
        offset: 0,
        limit: model.cappedLimit(16),
      );
      if (!mounted || !page) return;
      final users = model.directory?.users ?? const [];
      setState(() {
        _users = [
          for (final user in users)
            (uuid: user.uuid, login: user.login ?? user.uuid),
        ];
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failure = '$error';
      });
    } finally {
      model.setUserSearch(previous);
    }
  }
}
