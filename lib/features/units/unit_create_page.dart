import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../navigation/pick.dart';
import '../../registry/repo.dart';
import '../../units/unit.dart';
import '../hex_page.dart';
import 'unit_form_parts.dart';
import 'units_chrome.dart';
import '../../locale/languages.dart';

/// Creates a unit. A repository may already be chosen via `repo`.
class UnitCreatePage extends StatefulWidget {
  const UnitCreatePage({this.repoUuid = '', super.key});

  final String repoUuid;

  @override
  State<UnitCreatePage> createState() => _UnitCreatePageState();
}

class _UnitCreatePageState extends State<UnitCreatePage> {
  final _name = TextEditingController();
  final _nameFocus = FocusNode();
  final _form = UnitFormFields();
  RegistryRepo? _repo;
  String? _failure;
  String? _issue;
  var _open = false;
  var _loading = false;
  var _busy = false;

  bool get _ready => _repo != null && !_loading;

  @override
  void initState() {
    super.initState();
    if (widget.repoUuid.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _loadRepo(widget.repoUuid),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    const ids = ['repo', 'name', 'visibility', 'branch', 'updates', 'create'];
    final placed = cardBoard(ids, wide: wide);
    final image = model.cachedIcon(_repo?.iconUuid);
    final slots = <HexSlot>[
      for (final slot in placed) _slot(slot, language, image),
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      wide: wide,
    );
    return HexPage(slots: slots, onTap: _tap);
  }

  HexSlot _slot(BoardSlot slot, String language, Uint8List? image) {
    final color = unitsColor;
    final ready = _ready;
    switch (slot.id) {
      case 'back':
        return backSlot(language, q: slot.q, r: slot.r);
      case 'repo':
        final caption = _repo == null
            ? null
            : repoCaption(_repo!.repositoryUrl);
        return HexSlot(
          id: 'repo',
          title: localized(language, 'Выбрать репозиторий', 'Select repository'),
          footer: caption,
          color: color,
          busy: _loading,
          q: slot.q,
          r: slot.r,
          icon: image == null ? 'assets/icons/objects/repo.svg' : null,
          image: image,
        );
      case 'name':
        return unitFormNameSlot(
          slot,
          language,
          controller: _name,
          focusNode: _nameFocus,
          issue: _issue,
          enabled: ready,
        );
      case 'visibility':
        return unitFormVisibilitySlot(
          slot,
          language,
          fields: _form,
          enabled: ready,
          onPick: (id) => setState(() => _form.visibility = id),
        );
      case 'branch':
        return unitFormBranchSlot(slot, language, fields: _form, enabled: ready);
      case 'updates':
        return unitFormUpdatesSlot(
          slot,
          language,
          fields: _form,
          enabled: ready,
        );
      case 'create':
        return HexSlot(
          id: 'create',
          title: localized(language, 'Создать', 'Create'),
          color: unitAddColor,
          busy: _busy,
          enabled: ready,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/actions/unit_add.svg',
        );
      default:
        return unitFormFallbackSlot(slot);
    }
  }

  Future<void> _tap(String id) async {
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'repo':
        if (_loading) return;
        final picked = await openPick<String>(context, '/units/new/repo');
        if (picked == null || picked.isEmpty || !mounted) return;
        if (picked == _repo?.uuid) return;
        await _loadRepo(picked);
      case 'branch':
        final repo = _repo;
        if (!_ready || repo == null) return;
        final picked = await openPick<String>(
          context,
          '/units/new/branch?repo=${repo.uuid}',
          items: [for (final name in repo.branches) (id: name, label: name)],
        );
        if (picked == null || !mounted) return;
        setState(() => _form.takeBranch(picked));
      case 'updates':
        final repo = _repo;
        if (!_ready || repo == null) return;
        final picked = await _form.pickUpdates(context, repo.uuid);
        if (picked == null || !mounted) return;
        setState(() => _form.takeUpdates(picked));
      case 'create':
        await _create();
    }
  }

  Future<void> _loadRepo(String uuid) async {
    final model = AppScope.of(context);
    if (!model.signedIn || uuid.isEmpty) {
      setState(() {
        _loading = false;
        _failure = model.notSignedIn;
      });
      return;
    }
    setState(() {
      _loading = true;
      _failure = null;
      _open = false;
    });
    try {
      final repo = await model.readRepo(uuid);
      if (!mounted) return;
      setState(() {
        _repo = repo;
        _form.takeBranch(repo.branches.isEmpty ? '' : repo.branches.first);
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

  Future<void> _create() async {
    if (_busy || !_ready) return;
    final model = AppScope.of(context);
    final language = model.vault.language;
    final repo = _repo;
    final name = _name.text.trim();
    if (repo == null) {
      setState(() {
        _failure = localized(
          language,
          'Выберите репозиторий',
          'Select a repository',
        );
      });
      return;
    }
    final problem = _form.problem(language, name);
    if (problem != null) {
      setState(() {
        _issue = problem.issue;
        _failure = problem.failure;
      });
      return;
    }
    setState(() {
      _busy = true;
      _issue = null;
      _failure = null;
      _open = false;
    });
    try {
      final unit = await model.createUnit({
        ..._form.body(name),
        'repo_uuid': repo.uuid,
      });
      if (!mounted) return;
      context.pushReplacement('/units/${unit.uuid}');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = '$error';
      });
    }
  }
}

/// Compilable, auto-update, tags, commit and platform for a new unit.
class UnitUpdatesPage extends StatefulWidget {
  const UnitUpdatesPage({
    required this.repoUuid,
    required this.branch,
    required this.compilable,
    required this.auto,
    required this.tagsOnly,
    this.commit,
    this.platform,
    super.key,
  });

  final String repoUuid;
  final String branch;
  final bool compilable;
  final bool auto;
  final bool tagsOnly;
  final String? commit;
  final String? platform;

  @override
  State<UnitUpdatesPage> createState() => _UnitUpdatesPageState();
}

class _UnitUpdatesPageState extends State<UnitUpdatesPage> {
  late bool _compilable;
  late bool _auto;
  late bool _tags;
  String? _commit;
  String? _platform;

  @override
  void initState() {
    super.initState();
    _compilable = widget.compilable;
    _auto = widget.auto;
    _tags = widget.compilable || widget.tagsOnly;
    _commit = widget.commit;
    _platform = widget.platform;
  }

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final ids = [
      'compilable',
      'auto',
      if (_auto) 'tags',
      if (!_auto) 'commit',
      if (_compilable) 'platform',
    ];
    final placed = cardBoard(ids, wide: wide);
    final slots = <HexSlot>[for (final slot in placed) _slot(slot, language)];
    return HexPage(slots: slots, onTap: _tap);
  }

  String _tagsTitle(String language) {
    if (_compilable) return localized(language, 'Последний тег', 'Last tag');
    if (_tags) return localized(language, 'Только теги', 'Tags only');
    return localized(language, 'Последний коммит', 'Last commit');
  }

  HexSlot _slot(BoardSlot slot, String language) {
    final color = unitsColor;
    switch (slot.id) {
      case 'back':
        return backSlot(language, q: slot.q, r: slot.r);
      case 'compilable':
        return HexSlot(
          id: 'compilable',
          title: _compilable
              ? localized(language, 'Компилируемый', 'Compilable')
              : localized(language, 'Интерпретируемый', 'Interpreted'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/status/flag.svg',
        );
      case 'auto':
        return HexSlot(
          id: 'auto',
          title: _auto
              ? localized(language, 'Автообновление', 'Auto-update')
              : localized(language, 'Руками', 'Manual'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/status/flag.svg',
        );
      case 'tags':
        return HexSlot(
          id: 'tags',
          title: _tagsTitle(language),
          color: color,
          enabled: !_compilable,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/status/flag.svg',
        );
      case 'commit':
        return HexSlot(
          id: 'commit',
          title: localized(language, 'Коммит', 'Commit'),
          footer: shortCommit(_commit).isEmpty ? null : shortCommit(_commit),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/objects/commits.svg',
        );
      case 'platform':
        return HexSlot(
          id: 'platform',
          title: localized(language, 'Платформа', 'Platform'),
          footer: _platform,
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/objects/platform.svg',
        );
      default:
        return HexSlot(
          id: slot.id,
          title: slot.id,
          color: color,
          q: slot.q,
          r: slot.r,
        );
    }
  }

  Future<void> _tap(String id) async {
    switch (id) {
      case 'back':
        _close();
      case 'compilable':
        setState(() {
          _compilable = !_compilable;
          if (_compilable) _tags = true;
        });
      case 'auto':
        setState(() => _auto = !_auto);
      case 'tags':
        if (_compilable) return;
        setState(() => _tags = !_tags);
      case 'commit':
        if (widget.branch.isEmpty || widget.repoUuid.isEmpty) return;
        final picked = await openPick<String>(
          context,
          '/units/new/commit?repo=${widget.repoUuid}'
          '&branch=${Uri.encodeQueryComponent(widget.branch)}'
          '&compilable=${_compilable ? '1' : '0'}',
        );
        if (picked == null || !mounted) return;
        setState(() => _commit = picked);
      case 'platform':
        if (widget.repoUuid.isEmpty) return;
        final pinned = !_auto && _commit != null && _commit!.isNotEmpty
            ? '&commit=${Uri.encodeQueryComponent(_commit!)}'
            : '';
        final branch = widget.branch.isEmpty
            ? ''
            : '&branch=${Uri.encodeQueryComponent(widget.branch)}';
        final picked = await openPick<String>(
          context,
          '/units/new/platform?repo=${widget.repoUuid}$branch$pinned',
        );
        if (picked == null || !mounted) return;
        setState(() => _platform = picked);
    }
  }

  void _close() {
    final draft = UnitUpdateDraft(
      compilable: _compilable,
      auto: _auto,
      tagsOnly: _compilable || _tags,
      commit: _commit,
      platform: _compilable ? _platform : null,
    );
    if (context.canPop()) {
      context.pop(draft);
    } else {
      popOrHome(context);
    }
  }
}
