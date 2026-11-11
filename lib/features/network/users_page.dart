import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/directory_user.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../navigation/sections.dart';
import '../hex_page.dart';
import '../line_input.dart';
import '../page_window.dart';
import '../paged_search.dart';
import '../slanted_choices.dart';
import 'network_chrome.dart';
import '../../locale/languages.dart';

/// User search. [pick] returns the chosen uuid with [pop] instead of opening
/// the card, and takes the Account colors.
class UsersPage extends StatefulWidget {
  const UsersPage({required this.scope, this.pick = false, super.key});

  final int scope;
  final bool pick;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> with PagedSearch<UsersPage> {
  @override
  int scopeOf(UsersPage widget) => widget.scope;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = widget.pick ? peopleColor : networkColor;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final page = model.directory;
    final users = page?.users ?? const <DirectoryUser>[];
    final board = usersBoard(
      tick: widget.scope,
      uuids: [for (final user in users) user.uuid],
      wide: wide,
    );
    final limit = _limit(model);
    final slots = <HexSlot>[
      for (final slot in board.slots)
        _slot(slot, language, color, users, page?.count ?? 0, limit, model),
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
      onTap: (id) => _tap(id, language),
      frame: (scene) => ScopeFrame(
        scope: widget.scope,
        canZoomIn: widget.scope < scaleTickMax,
        path: widget.pick ? '/units/pick-user' : '/peers/users',
        child: scene,
      ),
    );
  }

  HexSlot _slot(
    BoardSlot slot,
    String language,
    Color color,
    List<DirectoryUser> users,
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
          body: MemberQueryCell(
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
          body: MemberWindowCell(
            offset: offset,
            limit: limit,
            count: count,
            onStep: _step,
            onOrder: _order,
          ),
        );
      default:
        final uuid = slot.id.startsWith('user:') ? slot.id.substring(5) : '';
        DirectoryUser? user;
        for (final item in users) {
          if (item.uuid == uuid) user = item;
        }
        if (user == null) {
          return HexSlot(
            id: slot.id,
            title: '',
            color: color,
            q: slot.q,
            r: slot.r,
          );
        }
        return userMark(
          id: 'user:${user.uuid}',
          user: user,
          language: language,
          q: slot.q,
          r: slot.r,
          accent: color,
          image: model.cachedIcon(user.iconUuid),
        );
    }
  }

  Future<void> _tap(String id, String language) async {
    if (id.startsWith('user:')) {
      final uuid = id.substring(5);
      if (widget.pick) {
        context.pop(uuid);
      } else {
        context.push(
          '/peers/users/member?uuid=${Uri.encodeQueryComponent(uuid)}',
        );
      }
      return;
    }
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => failureOpen = true);
    }
  }

  int _limit(AppModel model) => model.cappedLimit(headPageLimit(widget.scope));

  void _order(String value) {
    final model = AppScope.of(context);
    if (!model.setUserOrder(value)) return;
    retune();
  }

  void _step(int direction) {
    final model = AppScope.of(context);
    step(
      direction,
      limit: _limit(model),
      count: model.directory?.count ?? 0,
      capacity: model.pageCapacity(headPageLimit(scaleTickMax)),
    );
  }

  @override
  Future<VoidCallback?> fetch(AppModel model) async {
    final fresh = await model.loadDirectory(
      offset: offset,
      limit: _limit(model),
    );
    return fresh ? () {} : null;
  }
}

class MemberQueryCell extends StatefulWidget {
  const MemberQueryCell({
    required this.color,
    required this.onSearch,
    required this.onRetune,
    super.key,
  });

  final Color color;
  final VoidCallback onSearch;
  final VoidCallback onRetune;

  @override
  State<MemberQueryCell> createState() => _MemberQueryCellState();
}

class _MemberQueryCellState extends State<MemberQueryCell> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final text = AppScope.of(context).userQuery.text;
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
      fieldKey: const ValueKey('member-search'),
      hint: localized(language, 'Поиск', 'Search'),
      leading: 'assets/icons/actions/search.svg',
      roomyCaption: true,
      captionGap: 0,
      onChanged: (text) {
        AppScope.of(context).setUserSearch(text);
        widget.onSearch();
      },
      caption: _MemberWords(onRole: widget.onRetune, onStatus: widget.onRetune),
    );
  }
}

class _MemberWords extends StatelessWidget {
  const _MemberWords({required this.onRole, required this.onStatus});

  final VoidCallback onRole;
  final VoidCallback onStatus;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final query = model.userQuery;
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth / (1 - 2 * roomySideInset);
        final line = searchLineWidth(constraints.maxWidth);
        // The caption runs past the vertical edges. The shared size is the
        // largest that still keeps both blocks above those edges.
        final band = max(0.0, constraints.maxHeight - side * 0.13);
        final roles = [for (final role in userRoles) roleLabel(language, role)];
        final statuses = [
          for (final status in userStatuses)
            memberStatusLabel(language, status),
        ];
        final font = _memberFont(
          ceiling: cellFont(side) * 1.1,
          line: line,
          band: band,
          scaler: MediaQuery.textScalerOf(context),
          roles: roles,
          statuses: statuses,
        );
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SlantedChoices(
              fontSize: font,
              maxWidth: line,
              spanLine: true,
              lineGapShare: 0.05,
              choices: [
                for (final role in userRoles)
                  SlantedChoice(
                    label: roleLabel(language, role),
                    selected: query.roles.contains(role),
                    onTap: () {
                      if (model.toggleUserRole(role)) onRole();
                    },
                  ),
              ],
            ),
            Transform.translate(
              offset: Offset(0, -font * 0.35),
              child: SlantedChoices(
                fontSize: font,
                maxWidth: line * 0.88,
                choices: [
                  for (final status in userStatuses)
                    SlantedChoice(
                      label: memberStatusLabel(language, status),
                      selected: query.statuses.contains(status),
                      onTap: () {
                        if (model.toggleUserStatus(status)) onStatus();
                      },
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Largest size at or under [ceiling] whose two blocks fit in [band].
double _memberFont({
  required double ceiling,
  required double line,
  required double band,
  required TextScaler scaler,
  required List<String> roles,
  required List<String> statuses,
}) {
  if (!line.isFinite || line <= 0) return ceiling;
  bool fits(double font) {
    final roleHeight = slantedEnumHeight(
      labels: roles,
      fontSize: font,
      maxWidth: line,
      scaler: scaler,
      lineGapShare: 0.05,
      span: true,
    );
    final statusHeight = slantedEnumHeight(
      labels: statuses,
      fontSize: font,
      maxWidth: line,
      scaler: scaler,
      lineGapShare: 0.05,
    );
    if (roleHeight == null || statusHeight == null) return false;
    return roleHeight + statusHeight + font * 0.5 <= band + 0.5;
  }

  if (fits(ceiling)) return ceiling;
  var low = 1.0;
  var high = ceiling;
  if (high <= low || !fits(low)) return max(1.0, low);
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

class MemberWindowCell extends StatelessWidget {
  const MemberWindowCell({
    required this.offset,
    required this.limit,
    required this.count,
    required this.onStep,
    required this.onOrder,
    super.key,
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
    final order = model.userQuery.order;
    final range = pageWindowText(
      offset: offset,
      limit: limit,
      count: count,
      ofWord: localized(language, 'из', 'of'),
    );
    return OrderWindow(
      orders: [
        for (final value in const ['desc', 'asc'])
          (value: value, label: memberOrderLabel(language, value)),
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
