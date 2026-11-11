import 'dart:async';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../account/icon_file.dart';
import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../units/unit.dart';
import '../file_drop.dart';
import '../hex_page.dart';
import '../paged_search.dart';
import '../line_input.dart';
import '../network/network_chrome.dart';
import 'units_chrome.dart';
import '../../locale/languages.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({required this.scope, super.key});

  final int scope;

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> with PagedSearch<GroupsPage> {
  final _search = TextEditingController();
  String _order = 'asc';
  var _count = 0;
  List<UnitGroup> _groups = const [];

  @override
  int scopeOf(GroupsPage widget) => widget.scope;

  @override
  void initState() {
    super.initState();
    loading = true;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final limit = model.cappedLimit(headPageLimit(widget.scope, head: 3));
    final board = listBoard(
      tick: widget.scope,
      head: const ['query', 'create', 'window'],
      ids: [for (final group in _groups) group.uuid],
      prefix: 'group:',
      total: _count,
      wide: wide,
    );
    final slots = <HexSlot>[
      for (final slot in board.slots)
        switch (slot.id) {
          'back' => backSlot(language, q: slot.q, r: slot.r),
          'query' => HexSlot(
            id: 'query',
            title: localized(language, 'Фильтр', 'Filter'),
            color: unitGroupsColor,
            q: slot.q,
            r: slot.r,
            body: LineInput(
              color: unitGroupsColor,
              controller: _search,
              hint: localized(language, 'Поиск', 'Search'),
              leading: 'assets/icons/actions/search.svg',
              onChanged: (_) => searchLater(),
            ),
          ),
          'create' => HexSlot(
            id: 'create',
            title: localized(language, 'Создать группу', 'Create group'),
            color: addColor,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/actions/plus.svg',
          ),
          'window' => HexSlot(
            id: 'window',
            title: localized(language, 'Страница', 'Page'),
            color: unitGroupsColor,
            busy: loading,
            q: slot.q,
            r: slot.r,
            body: UnitWindow(
              language: language,
              offset: offset,
              limit: limit,
              count: _count,
              capacity: model.pageCapacity(headPageLimit(scaleTickMax, head: 3)),
              order: _order,
              onOrder: (value) {
                if (value == _order) return;
                setState(() => _order = value);
                retune();
              },
              onStep: (direction) => step(
                direction,
                limit: limit,
                count: _count,
                capacity: model.pageCapacity(
                  headPageLimit(scaleTickMax, head: 3),
                ),
              ),
            ),
          ),
          _ => HexSlot(
            id: slot.id,
            title: _title(slot.id),
            color: unitGroupsColor,
            q: slot.q,
            r: slot.r,
            icon: model.cachedIcon(_icon(slot.id)) == null
                ? 'assets/icons/sections/instances.svg'
                : null,
            image: model.cachedIcon(_icon(slot.id)),
          ),
        },
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
      onTap: (id) {
        if (id == 'back') {
          popOrHome(context);
        } else if (id == 'error') {
          setState(() => failureOpen = true);
        } else if (id == 'create') {
          context.push('/units/groups/new');
        } else if (id.startsWith('group:')) {
          context.push('/units/groups/${id.substring(6)}');
        }
      },
      frame: (scene) => ScopeFrame(
        scope: widget.scope,
        canZoomIn: board.canZoomIn,
        path: '/units/groups',
        child: scene,
      ),
    );
  }

  String _title(String id) {
    final uuid = id.startsWith('group:') ? id.substring(6) : '';
    for (final group in _groups) {
      if (group.uuid == uuid) return group.name;
    }
    return '';
  }

  String? _icon(String id) {
    final uuid = id.startsWith('group:') ? id.substring(6) : '';
    for (final group in _groups) {
      if (group.uuid == uuid) return group.iconUuid;
    }
    return null;
  }

  @override
  Future<VoidCallback?> fetch(AppModel model) async {
    final page = await model.listGroups(
      offset: offset,
      limit: model.cappedLimit(headPageLimit(widget.scope, head: 3)),
      search: _search.text,
      order: _order,
    );
    unawaited(
      model.ensureIcons([for (final group in page.groups) group.iconUuid]),
    );
    return () {
      _groups = page.groups;
      _count = page.count;
    };
  }
}

class GroupCreatePage extends StatefulWidget {
  const GroupCreatePage({super.key});

  @override
  State<GroupCreatePage> createState() => _GroupCreatePageState();
}

class _GroupCreatePageState extends State<GroupCreatePage> {
  final _name = TextEditingController();
  String? _failure;
  var _open = false;
  var _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(const ['name', 'create'], wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        switch (slot.id) {
          'back' => backSlot(language, q: slot.q, r: slot.r),
          'name' => HexSlot(
            id: 'name',
            title: localized(language, 'Имя', 'Name'),
            color: unitGroupsColor,
            q: slot.q,
            r: slot.r,
            tappable: false,
            body: LineInput(
              color: unitGroupsColor,
              controller: _name,
              hint: localized(language, 'группа', 'group'),
              onSubmitted: (_) => _create(),
            ),
          ),
          'create' => HexSlot(
            id: 'create',
            title: localized(language, 'Создать группу', 'Create group'),
            color: addColor,
            busy: _busy,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/actions/plus.svg',
          ),
          _ => HexSlot(
            id: slot.id,
            title: slot.id,
            color: unitGroupsColor,
            q: slot.q,
            r: slot.r,
          ),
        },
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
      onTap: (id) {
        if (id == 'back') popOrHome(context);
        if (id == 'error') setState(() => _open = true);
        if (id == 'create') _create();
      },
    );
  }

  Future<void> _create() async {
    final name = _name.text.trim();
    if (name.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    try {
      final group = await AppScope.of(context).createGroup(name);
      if (!mounted) return;
      context.pushReplacement('/units/groups/${group.uuid}');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = '$error';
      });
    }
  }
}

class GroupPage extends StatefulWidget {
  const GroupPage({required this.uuid, super.key});

  final String uuid;

  @override
  State<GroupPage> createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  UnitGroup? _group;
  final _name = TextEditingController();
  String? _failure;
  var _open = false;
  var _loading = true;
  String? _pending;
  var _hot = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(const [
      'name',
      'icon',
      'members',
      'delete',
    ], wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        switch (slot.id) {
          'back' => backSlot(language, q: slot.q, r: slot.r),
          'name' => HexSlot(
            id: 'name',
            title: localized(language, 'Имя', 'Name'),
            color: unitGroupsColor,
            busy: _loading || _pending == 'name',
            q: slot.q,
            r: slot.r,
            tappable: false,
            body: LineInput(
              color: unitGroupsColor,
              controller: _name,
              hint: localized(language, 'группа', 'group'),
              onSubmitted: (_) => _rename(),
            ),
          ),
          'icon' => HexSlot(
            id: 'icon',
            title: localized(language, 'Иконка', 'Icon'),
            color: dropColor(_hot, unitGroupsColor),
            q: slot.q,
            r: slot.r,
            icon: model.cachedIcon(_group?.iconUuid) == null
                ? 'assets/icons/actions/icon_load.svg'
                : null,
            image: model.cachedIcon(_group?.iconUuid),
          ),
          'members' => HexSlot(
            id: 'members',
            title: localized(language, 'Состав', 'Members'),
            color: unitGroupsColor,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/sections/micro.svg',
          ),
          'delete' => HexSlot(
            id: 'delete',
            title: localized(language, 'Удалить', 'Delete'),
            color: errorColor,
            busy: _pending == 'delete',
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/actions/trash.svg',
          ),
          _ => HexSlot(
            id: slot.id,
            title: slot.id,
            color: unitGroupsColor,
            q: slot.q,
            r: slot.r,
          ),
        },
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
      wrap: (slot, child) {
        if (slot.id != 'icon') return child;
        return FileDrop(
          enable: true,
          hot: _hot,
          onHot: (hot) => setState(() => _hot = hot),
          onDrop: _drop,
          child: child,
        );
      },
      onTap: (id) async {
        switch (id) {
          case 'back':
            popOrHome(context);
          case 'error':
            setState(() => _open = true);
          case 'icon':
            await _pick();
          case 'members':
            context.push('/units/groups/${widget.uuid}/members');
          case 'delete':
            await _delete();
        }
      },
    );
  }

  Future<void> _load() async {
    try {
      final group = await AppScope.of(context).readGroup(widget.uuid);
      if (!mounted) return;
      _name.text = group.name;
      setState(() {
        _group = group;
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

  Future<void> _rename() async {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    setState(() => _pending = 'name');
    try {
      final group = await AppScope.of(context).renameGroup(widget.uuid, name);
      if (!mounted) return;
      setState(() {
        _group = group;
        _pending = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
    }
  }

  Future<void> _delete() async {
    setState(() => _pending = 'delete');
    try {
      await AppScope.of(context).deleteGroup(widget.uuid);
      if (!mounted) return;
      context.go('/units/groups');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
    }
  }

  Future<void> _pick() async {
    final model = AppScope.of(context);
    final bytes = await model.files.pick();
    if (bytes == null) return;
    await _store(bytes);
  }

  Future<void> _drop(DropDoneDetails details) async {
    setState(() => _hot = false);
    if (details.files.isEmpty) return;
    await _store(await details.files.first.readAsBytes());
  }

  Future<void> _store(Uint8List bytes) async {
    final language = AppScope.of(context).vault.language;
    final problem = iconProblemText(iconProblem(bytes), language);
    if (problem != null) {
      setState(() => _failure = problem);
      return;
    }
    try {
      await AppScope.of(context)
          .uploadEntityIcon(widget.uuid, 'UnitGroup', bytes);
      if (!mounted) return;
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() => _failure = '$error');
    }
  }
}

class GroupMembersPage extends StatefulWidget {
  const GroupMembersPage({required this.uuid, required this.scope, super.key});

  final String uuid;
  final int scope;

  @override
  State<GroupMembersPage> createState() => _GroupMembersPageState();
}

class _GroupMembersPageState extends State<GroupMembersPage> {
  List<Unit> _units = const [];
  var _count = 0;
  var _offset = 0;
  String? _failure;
  var _open = false;
  var _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final limit = model.cappedLimit(headPageLimit(widget.scope));
    final board = listBoard(
      tick: widget.scope,
      head: const ['add', 'window'],
      ids: [for (final unit in _units) unit.uuid],
      prefix: 'unit:',
      total: _count,
      wide: wide,
    );
    final slots = <HexSlot>[
      for (final slot in board.slots)
        switch (slot.id) {
          'back' => backSlot(language, q: slot.q, r: slot.r),
          'add' => HexSlot(
            id: 'add',
            title: localized(language, 'Добавить', 'Add'),
            color: unitGroupsColor,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/actions/plus.svg',
          ),
          'window' => HexSlot(
            id: 'window',
            title: localized(language, 'Страница', 'Page'),
            color: unitGroupsColor,
            busy: _loading,
            q: slot.q,
            r: slot.r,
            body: UnitWindow(
              language: language,
              offset: _offset,
              limit: limit,
              count: _count,
              capacity: model.pageCapacity(headPageLimit(scaleTickMax)),
              onStep: (direction) {
                final next = pageShift(
                  direction: direction,
                  offset: _offset,
                  limit: limit,
                  count: _count,
                  capacity: model.pageCapacity(headPageLimit(scaleTickMax)),
                );
                if (next == null) return;
                setState(() => _offset = next);
                _load();
              },
            ),
          ),
          _ => unitMark(
            id: slot.id,
            unit:
                _unit(slot.id) ??
                Unit(
                  uuid: '',
                  iconUuid: '',
                  visibility: '',
                  name: '',
                  created: '',
                  auto: false,
                  compilable: false,
                  tagsOnly: false,
                  branch: '',
                  updated: '',
                  creatorUuid: '',
                  repoUuid: '',
                ),
            language: language,
            q: slot.q,
            r: slot.r,
            image: model.cachedIcon(_unit(slot.id)?.iconUuid),
            color: unitGroupsColor,
          ),
        },
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
      onTap: (id) async {
        if (id == 'back') {
          popOrHome(context);
          return;
        }
        if (id == 'error') {
          setState(() => _open = true);
          return;
        }
        if (id == 'add') {
          final model = AppScope.of(context);
          final picked = await context.push<String>('/units/pick');
          if (picked == null || !mounted) return;
          try {
            await model.linkGroupUnit(widget.uuid, picked);
            await _load();
          } catch (error) {
            if (!mounted) return;
            setState(() => _failure = '$error');
          }
          return;
        }
        if (id.startsWith('unit:')) {
          context.push('/units/groups/${widget.uuid}/unit/${id.substring(5)}');
        }
      },
      frame: (scene) => ScopeFrame(
        scope: widget.scope,
        canZoomIn: board.canZoomIn,
        path: '/units/groups/${widget.uuid}/members',
        child: scene,
      ),
    );
  }

  Unit? _unit(String id) {
    final uuid = id.startsWith('unit:') ? id.substring(5) : '';
    for (final unit in _units) {
      if (unit.uuid == uuid) return unit;
    }
    return null;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final page = await AppScope.of(context).groupUnits(
        uuid: widget.uuid,
        offset: _offset,
        limit: AppScope.of(context).cappedLimit(headPageLimit(widget.scope)),
      );
      if (!mounted) return;
      unawaited(
        AppScope.of(context)
            .ensureIcons([for (final unit in page.units) unit.iconUuid]),
      );
      setState(() {
        _units = page.units;
        _count = page.count;
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

class MembershipPage extends StatefulWidget {
  const MembershipPage({
    required this.groupUuid,
    required this.unitUuid,
    super.key,
  });

  final String groupUuid;
  final String unitUuid;

  @override
  State<MembershipPage> createState() => _MembershipPageState();
}

class _MembershipPageState extends State<MembershipPage> {
  String? _failure;
  var _open = false;
  var _busy = false;

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(const ['open', 'unlink'], wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        switch (slot.id) {
          'back' => backSlot(language, q: slot.q, r: slot.r),
          'open' => HexSlot(
            id: 'open',
            title: localized(language, 'Открыть', 'Open'),
            color: unitGroupsColor,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/sections/micro.svg',
          ),
          'unlink' => HexSlot(
            id: 'unlink',
            title: localized(language, 'Убрать', 'Remove'),
            color: errorColor,
            busy: _busy,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/actions/close.svg',
          ),
          _ => HexSlot(
            id: slot.id,
            title: slot.id,
            color: unitGroupsColor,
            q: slot.q,
            r: slot.r,
          ),
        },
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
      onTap: (id) async {
        switch (id) {
          case 'back':
            popOrHome(context);
          case 'error':
            setState(() => _open = true);
          case 'open':
            context.push('/units/${widget.unitUuid}');
          case 'unlink':
            final model = AppScope.of(context);
            setState(() {
              _busy = true;
              _failure = null;
            });
            try {
              await model.unlinkGroupUnit(widget.groupUuid, widget.unitUuid);
              if (!context.mounted) return;
              popOrHome(context);
            } catch (error) {
              if (!mounted) return;
              setState(() {
                _busy = false;
                _failure = '$error';
              });
            }
        }
      },
    );
  }
}
