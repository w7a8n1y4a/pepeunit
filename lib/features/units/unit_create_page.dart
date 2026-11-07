import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../registry/repo.dart';
import '../../units/unit.dart';
import '../hex_page.dart';
import '../line_input.dart';
import 'units_chrome.dart';

/// Update flags collected on the updates menu and returned to the form.
class UnitUpdateDraft {
  const UnitUpdateDraft({
    required this.compilable,
    required this.auto,
    required this.tagsOnly,
    this.commit,
    this.platform,
  });

  final bool compilable;
  final bool auto;
  final bool tagsOnly;
  final String? commit;
  final String? platform;
}

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
  RegistryRepo? _repo;
  String _visibility = 'Internal';
  var _compilable = false;
  var _auto = true;
  var _tags = true;
  String _branch = '';
  String? _commit;
  String? _platform;
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
      text: unitText,
      wide: wide,
    );
    return HexPage(slots: slots, onTap: _tap);
  }

  HexSlot _slot(BoardSlot slot, String language, Uint8List? image) {
    final color = unitsColor;
    final ready = _ready;
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: unitText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'repo':
        final caption = _repo == null
            ? null
            : repoCaption(_repo!.repositoryUrl);
        return HexSlot(
          id: 'repo',
          title: unitText(language, 'Выбрать репозиторий', 'Select repository'),
          footer: caption,
          color: color,
          busy: _loading,
          q: slot.q,
          r: slot.r,
          icon: image == null ? 'assets/icons/objects/repo.svg' : null,
          image: image,
        );
      case 'name':
        return HexSlot(
          id: 'name',
          title: unitText(language, 'Имя', 'Name'),
          color: color,
          q: slot.q,
          r: slot.r,
          tappable: false,
          enabled: ready,
          body: LineInput(
            color: color,
            controller: _name,
            focusNode: _nameFocus,
            fieldKey: const ValueKey('unit-name'),
            hint: unitText(language, 'имя', 'name'),
            issue: _issue ?? '',
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9_.-]')),
              LengthLimitingTextInputFormatter(20),
            ],
          ),
        );
      case 'visibility':
        return HexSlot(
          id: 'visibility',
          title: unitText(language, 'Видимость', 'Visibility'),
          color: color,
          q: slot.q,
          r: slot.r,
          tappable: false,
          enabled: ready,
          body: ChoiceWords(
            center: true,
            choices: [
              for (final level in unitVisibilities)
                (id: level, label: unitVisibilityLabel(language, level)),
            ],
            selected: (id) => _visibility == id,
            onTap: (id) => setState(() => _visibility = id),
          ),
        );
      case 'branch':
        return HexSlot(
          id: 'branch',
          title: unitText(language, 'Ветка', 'Branch'),
          footer: _branch.isEmpty ? null : _branch,
          color: color,
          enabled: ready,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/objects/repo.svg',
        );
      case 'updates':
        return HexSlot(
          id: 'updates',
          title: unitText(language, 'Обновления', 'Updates'),
          footer: unitRunLabel(language, _compilable),
          footerLeft: unitHandsLabel(language, _auto),
          color: color,
          enabled: ready,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/actions/updates.svg',
        );
      case 'create':
        return HexSlot(
          id: 'create',
          title: unitText(language, 'Создать', 'Create'),
          color: unitAddColor,
          busy: _busy,
          enabled: ready,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/actions/unit_add.svg',
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
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'repo':
        if (_loading) return;
        final picked = await context.push<String>('/units/new/repo');
        if (picked == null || picked.isEmpty || !mounted) return;
        if (picked == _repo?.uuid) return;
        await _loadRepo(picked);
      case 'branch':
        final repo = _repo;
        if (!_ready || repo == null) return;
        final picked = await context.push<String>(
          '/units/new/branch?repo=${repo.uuid}',
        );
        if (picked == null || !mounted) return;
        setState(() {
          _branch = picked;
          _commit = null;
          _platform = null;
        });
      case 'updates':
        if (!_ready || _repo == null) return;
        final picked = await context.push<UnitUpdateDraft>(_updatesPath());
        if (picked == null || !mounted) return;
        setState(() {
          _compilable = picked.compilable;
          _auto = picked.auto;
          _tags = picked.compilable || picked.tagsOnly;
          _commit = picked.commit;
          _platform = picked.platform;
        });
      case 'create':
        await _create();
    }
  }

  String _updatesPath() {
    final repo = _repo?.uuid ?? '';
    final query = <String, String>{
      'repo': repo,
      'branch': _branch,
      'compilable': _compilable ? '1' : '0',
      'auto': _auto ? '1' : '0',
      'tags': (_compilable || _tags) ? '1' : '0',
      if (_commit != null && _commit!.isNotEmpty) 'commit': _commit!,
      if (_platform != null && _platform!.isNotEmpty) 'platform': _platform!,
    };
    return Uri(path: '/units/new/updates', queryParameters: query).toString();
  }

  Future<void> _loadRepo(String uuid) async {
    final model = AppScope.of(context);
    final language = model.vault.language;
    if (model.target?.signedIn != true || uuid.isEmpty) {
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
      final repo = await model.readRepo(uuid);
      if (!mounted) return;
      setState(() {
        _repo = repo;
        _branch = repo.branches.isEmpty ? '' : repo.branches.first;
        _commit = null;
        _platform = null;
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
        _failure = unitText(
          language,
          'Выберите репозиторий',
          'Select a repository',
        );
      });
      return;
    }
    if (!unitNameOk(name)) {
      setState(() {
        _issue = unitText(
          language,
          'От 4 до 20: буквы, цифры, _ . -',
          '4 to 20: letters, digits, _ . -',
        );
        _failure = null;
      });
      return;
    }
    if (_branch.isEmpty) {
      setState(() {
        _issue = null;
        _failure = unitText(language, 'Нужна ветка', 'A branch is required');
      });
      return;
    }
    if (!_auto && (_commit == null || _commit!.isEmpty)) {
      setState(() {
        _issue = null;
        _failure = unitText(language, 'Нужен коммит', 'A commit is required');
      });
      return;
    }
    if (_compilable && (_platform == null || _platform!.isEmpty)) {
      setState(() {
        _issue = null;
        _failure = unitText(
          language,
          'Нужна платформа',
          'A platform is required',
        );
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
        'name': name,
        'repo_uuid': repo.uuid,
        'visibility_level': _visibility,
        'target_branch': _branch,
        'is_auto_update_unit': _auto,
        'is_compilable_unit': _compilable,
        'is_only_tag_update': _compilable || _tags,
        if (!_auto) 'target_commit': _commit,
        if (_compilable) 'target_firmware_platform': _platform,
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
    if (_compilable) return unitText(language, 'Последний тег', 'Last tag');
    if (_tags) return unitText(language, 'Только теги', 'Tags only');
    return unitText(language, 'Последний коммит', 'Last commit');
  }

  HexSlot _slot(BoardSlot slot, String language) {
    final color = unitsColor;
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: unitText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'compilable':
        return HexSlot(
          id: 'compilable',
          title: _compilable
              ? unitText(language, 'Компилируемый', 'Compilable')
              : unitText(language, 'Интерпретируемый', 'Interpreted'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/status/flag.svg',
        );
      case 'auto':
        return HexSlot(
          id: 'auto',
          title: _auto
              ? unitText(language, 'Автообновление', 'Auto-update')
              : unitText(language, 'Руками', 'Manual'),
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
          title: unitText(language, 'Коммит', 'Commit'),
          footer: shortCommit(_commit).isEmpty ? null : shortCommit(_commit),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/objects/commits.svg',
        );
      case 'platform':
        return HexSlot(
          id: 'platform',
          title: unitText(language, 'Платформа', 'Platform'),
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
        final picked = await context.push<String>(
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
        final picked = await context.push<String>(
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
