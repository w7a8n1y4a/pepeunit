import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/directory_user.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../navigation/sections.dart';
import '../../units/unit.dart';
import '../../units/unit_view.dart';
import '../hex_page.dart';
import '../network/network_chrome.dart';
import 'units_chrome.dart';
import '../../locale/languages.dart';

/// The agent chosen on the kind screen: `User` or `Unit`, and its uuid.
typedef AccessPick = ({String kind, String uuid});

/// Grants of one resource: a unit or a node. A tap on a grant removes it.
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
  final _units = <String, Unit>{};
  final _users = <String, DirectoryUser>{};
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
    final model = AppScope.of(context);
    final language = model.vault.language;
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
    if (slot.id == 'back') {
      return backSlot(language, q: slot.q, r: slot.r);
    }
    if (slot.id == 'add') {
      return HexSlot(
        id: 'add',
        title: localized(language, 'Добавить', 'Add'),
        color: accessColor,
        busy: _loading,
        q: slot.q,
        r: slot.r,
        icon: 'assets/icons/actions/plus.svg',
      );
    }
    if (slot.id == 'prev' || slot.id == 'next') {
      final forward = slot.id == 'next';
      return pageStepSlot(
        id: slot.id,
        left: !forward,
        language: language,
        color: accessColor,
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
    return _grantCard(slot, language, grant);
  }

  /// A unit grant looks like a unit card, a user grant like a user card.
  /// Until the agent is read, the cell shows its kind and a short uuid.
  HexSlot _grantCard(BoardSlot slot, String language, AccessGrant? grant) {
    final model = AppScope.of(context);
    final isUnit = grant?.agentType == 'Unit';
    if (grant != null) {
      final unit = isUnit ? _units[grant.agentUuid] : null;
      if (unit != null) {
        return unitMark(
          id: slot.id,
          hint: 'grant',
          unit: unit,
          language: language,
          q: slot.q,
          r: slot.r,
          image: model.cachedIcon(unit.iconUuid),
        );
      }
      final user = isUnit ? null : _users[grant.agentUuid];
      if (user != null) {
        return userMark(
          id: slot.id,
          hint: 'grant',
          user: user,
          language: language,
          q: slot.q,
          r: slot.r,
          accent: peopleColor,
          image: model.cachedIcon(user.iconUuid),
        );
      }
    }
    return HexSlot(
      id: slot.id,
      hint: 'grant',
      title: isUnit
          ? localized(language, 'Аппарат', 'Unit')
          : localized(language, 'Пользователь', 'User'),
      footer: grant == null ? null : shortCommit(grant.agentUuid),
      color: isUnit ? unitsColor : peopleColor,
      q: slot.q,
      r: slot.r,
      icon: isUnit
          ? 'assets/icons/sections/micro.svg'
          : 'assets/icons/sections/account.svg',
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
      final picked = await context.push<AccessPick>('/units/access/kind');
      if (picked == null || !mounted) return;
      setState(() {
        _loading = true;
        _failure = null;
        _open = false;
      });
      try {
        await AppScope.of(context).createAccess(
          agentUuid: picked.uuid,
          agentType: picked.kind,
          resourceUuid: widget.resourceUuid,
          resourceType: widget.resourceType,
        );
        await _load();
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _failure = '$error';
        });
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
    if (!model.signedIn) {
      setState(() {
        _loading = false;
        _failure = model.notSignedIn;
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
      for (final grant in page.grants) {
        unawaited(_describe(grant));
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failure = '$error';
      });
    }
  }

  /// Reads the agent of one grant for its card. A refusal leaves the plain
  /// cell; the grant stays removable.
  Future<void> _describe(AccessGrant grant) async {
    final model = AppScope.of(context);
    try {
      if (grant.agentType == 'Unit') {
        if (_units.containsKey(grant.agentUuid)) return;
        final unit = await model.readUnit(grant.agentUuid);
        if (!mounted) return;
        setState(() => _units[grant.agentUuid] = unit);
      } else {
        if (_users.containsKey(grant.agentUuid)) return;
        final user = await model.readMember(grant.agentUuid);
        if (!mounted) return;
        setState(() => _users[grant.agentUuid] = user);
      }
    } catch (_) {
      // The cell keeps the kind and the short uuid.
    }
  }
}

/// Chooses who gets access. A tap opens that agent's search; the chosen
/// agent goes back to the grant list.
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
              ? backSlot(language, q: slot.q, r: slot.r)
              : HexSlot(
                  id: slot.id,
                  hint: slot.id == 'User' ? 'user' : 'unit',
                  title: slot.id == 'User'
                      ? localized(language, 'Пользователь', 'User')
                      : localized(language, 'Аппарат', 'Unit'),
                  color: slot.id == 'User' ? peopleColor : unitsColor,
                  q: slot.q,
                  r: slot.r,
                  icon: slot.id == 'User'
                      ? 'assets/icons/sections/account.svg'
                      : 'assets/icons/sections/micro.svg',
                ),
      ],
      onTap: (id) => _tap(context, id),
    );
  }

  Future<void> _tap(BuildContext context, String id) async {
    if (id == 'back') {
      popOrHome(context);
      return;
    }
    if (id != 'User' && id != 'Unit') return;
    final uuid = await context.push<String>(
      id == 'User' ? '/units/pick-user' : '/units/pick',
    );
    if (uuid == null || !context.mounted) return;
    final AccessPick picked = (kind: id, uuid: uuid);
    if (context.canPop()) {
      context.pop(picked);
    } else {
      popOrHome(context);
    }
  }
}
