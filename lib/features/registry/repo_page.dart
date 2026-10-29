import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../account/alerts.dart';
import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../registry/registry_view.dart';
import '../../registry/repo.dart';
import '../hex_page.dart';
import '../network/line_cell.dart';
import 'registry_chrome.dart';

class RepoPage extends StatefulWidget {
  const RepoPage({required this.uuid, super.key});

  final String uuid;

  @override
  State<RepoPage> createState() => _RepoPageState();
}

class _RepoPageState extends State<RepoPage> {
  RegistryRepo? _repo;
  String? _failure;
  var _open = false;
  String? _pending;
  var _loading = true;
  Timer? _clock;
  Timer? _poll;
  DateTime? _syncUntil;
  var _sawUpdating = false;
  var _polling = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(RepoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uuid == widget.uuid) return;
    _stopWatch();
    _load();
  }

  @override
  void dispose() {
    _stopWatch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = registryColor;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final repo = _repo;
    final placed = cardBoard(
      repoMenuIds(
        private: repo != null && !repo.public,
        owned: repoOwnedBy(repo, model.target?.userUuid),
      ),
      wide: wide,
    );
    final slots = <HexSlot>[
      for (final slot in placed) _slot(slot, language, color, model),
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: regText,
      wide: wide,
    );
    return HexPage(slots: slots, onTap: _tap);
  }

  HexSlot _slot(BoardSlot slot, String language, Color color, AppModel model) {
    final repo = _repo;
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: regText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'card':
        if (repo == null) {
          return HexSlot(
            id: 'card',
            title: regText(language, 'Репозиторий', 'Repository'),
            color: color,
            busy: _loading || _pending == 'card',
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/repo.svg',
          );
        }
        return repoMark(
          id: 'card',
          repo: repo,
          language: language,
          q: slot.q,
          r: slot.r,
          image: model.cachedIcon(repo.iconUuid),
          busy: _loading || _pending == 'card',
        );
      case 'summary':
        final pages = repo == null
            ? const <SummaryPage>[]
            : [
                for (final page in repoSummaries(repo, language))
                  SummaryPage(title: page.title, lines: page.lines),
              ];
        return HexSlot(
          id: 'summary',
          title: regText(language, 'Сводка', 'Summary'),
          color: color,
          q: slot.q,
          r: slot.r,
          tappable: false,
          body: MetricsCell(
            lines: pages.isEmpty ? const ['—'] : pages.first.lines,
            pages: pages,
            copyText: repo?.repositoryUrl,
            copyLabel: regText(language, 'Скопировать ссылку', 'Copy link'),
            prevLabel: regText(
              language,
              'Предыдущая сводка',
              'Previous summary',
            ),
            nextLabel: regText(language, 'Следующая сводка', 'Next summary'),
          ),
        );
      case 'unit':
        return HexSlot(
          id: 'unit',
          title: regText(language, 'Создать аппарат', 'Create unit'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/micro.svg',
          enabled: false,
        );
      case 'sync':
        final watching = _syncUntil != null;
        return HexSlot(
          id: 'sync',
          title: regText(language, 'Синхронизировать репо', 'Synchronize repo'),
          footer: _syncFooter(language, repo),
          color: watching
              ? hexMuted
              : (repo?.syncStatus == 'Error' ? errorColor : color),
          enabled: !watching,
          busy: _pending == 'sync',
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/reload.svg',
        );
      case 'credentials':
        return HexSlot(
          id: 'credentials',
          title: regText(language, 'Креды', 'Credentials'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/key.svg',
        );
      case 'branches':
        final count = repo?.branches.length;
        return HexSlot(
          id: 'branches',
          title: regText(language, 'Ветки', 'Branches'),
          footer: count == null ? null : '$count',
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/repo.svg',
        );
      case 'delete':
        return HexSlot(
          id: 'delete',
          title: regText(language, 'Удалить', 'Delete'),
          color: errorColor,
          busy: _pending == 'delete',
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/close.svg',
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
      case 'card':
        await _refresh();
      case 'sync':
        if (_syncUntil != null) return;
        await _sync();
      case 'delete':
        await _delete();
      case 'credentials':
        context.push('/registry/repo/${widget.uuid}/credentials');
      case 'branches':
        context.push('/registry/repo/${widget.uuid}/branches');
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

  Future<void> _refresh() async {
    if (_pending != null || _loading) return;
    final model = AppScope.of(context);
    setState(() {
      _pending = 'card';
      _failure = null;
      _open = false;
    });
    try {
      final repo = await model.readRepo(widget.uuid);
      if (!mounted) return;
      setState(() {
        _repo = repo;
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
    if (_pending != null) return;
    final model = AppScope.of(context);
    setState(() {
      _pending = 'delete';
      _failure = null;
      _open = false;
    });
    try {
      await model.deleteRepo(widget.uuid);
      if (!mounted) return;
      setState(() => _pending = null);
      popOrHome(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
    }
  }

  String? _syncFooter(String language, RegistryRepo? repo) {
    final until = _syncUntil;
    if (until != null) return cooldownClock(until.difference(DateTime.now()));
    if (repo == null) return null;
    return repoSyncLabel(language, repo.syncStatus);
  }

  void _stopWatch() {
    _clock?.cancel();
    _poll?.cancel();
    _clock = null;
    _poll = null;
    _syncUntil = null;
    _sawUpdating = false;
    _polling = false;
  }

  void _finishWatch() {
    if (_syncUntil == null && _clock == null && _poll == null) return;
    _stopWatch();
    if (mounted) setState(() {});
  }

  void _tickWatch() {
    final until = _syncUntil;
    if (!mounted || until == null) return;
    if (!DateTime.now().isBefore(until)) {
      _finishWatch();
      return;
    }
    setState(() {});
  }

  Future<void> _pollRepo() async {
    final until = _syncUntil;
    if (_polling || until == null || !mounted) return;
    if (!DateTime.now().isBefore(until)) {
      _finishWatch();
      return;
    }
    _polling = true;
    final model = AppScope.of(context);
    try {
      final repo = await model.readRepo(widget.uuid);
      if (!mounted || _syncUntil != until) return;
      final updating = repo.syncStatus == 'Processing';
      final done = _sawUpdating && !updating;
      if (updating) _sawUpdating = true;
      setState(() => _repo = repo);
      if (done || !DateTime.now().isBefore(until)) _finishWatch();
    } catch (_) {
      // One missed read should not end the minute.
    } finally {
      if (_syncUntil == until) _polling = false;
    }
  }

  Future<void> _sync() async {
    if (_pending != null || _syncUntil != null) return;
    final model = AppScope.of(context);
    setState(() {
      _pending = 'sync';
      _failure = null;
      _open = false;
    });
    try {
      await model.updateLocalRepo(widget.uuid);
      if (!mounted) return;
      _stopWatch();
      _syncUntil = DateTime.now().add(const Duration(minutes: 1));
      setState(() => _pending = null);
      _clock = Timer.periodic(const Duration(seconds: 1), (_) => _tickWatch());
      _poll = Timer.periodic(const Duration(seconds: 10), (_) {
        unawaited(_pollRepo());
      });
      await _pollRepo();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
    }
  }
}
