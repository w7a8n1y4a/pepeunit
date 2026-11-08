import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../alerts/notice.dart';
import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../hive/hint.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../hex_page.dart';
import '../network/network_chrome.dart';
import '../page_window.dart';
import '../slanted_choices.dart';
import '../code/code_modal.dart';
import '../code/code_view.dart';
import 'alerts_chrome.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({required this.scope, super.key});

  final int scope;

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  var _offset = 0;
  var _loading = true;
  var _ticket = 0;
  var _failureOpen = false;
  String? _failure;
  var _revision = -1;
  String? _pending;
  Notice? _open;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final revision = AppScope.of(context).noticeRevision;
    if (revision == _revision) return;
    _revision = revision;
    _offset = 0;
    _scheduleLoad();
  }

  @override
  void didUpdateWidget(AlertsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scope == widget.scope) return;
    _offset = 0;
    _scheduleLoad();
  }

  void _scheduleLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = alertsColor;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final page = model.notices;
    final items = page?.items ?? const <Notice>[];
    final board = noticesBoard(
      tick: widget.scope,
      uuids: [for (final item in items) item.uuid],
      wide: wide,
    );
    final limit = _limit(model);
    final slots = <HexSlot>[
      for (final slot in board.slots)
        _slot(slot, language, color, items, page?.count ?? 0, limit, model),
    ];
    appendError(
      slots,
      message: _failure,
      open: _failureOpen,
      language: language,
      text: alertText,
      wide: wide,
    );
    final scene = HexPage(
      slots: slots,
      onTap: (id) => _tap(id, items),
      frame: (child) => ScopeFrame(
        scope: widget.scope,
        canZoomIn: board.canZoomIn,
        path: '/alerts',
        child: child,
      ),
    );
    final open = _open;
    if (open == null) return scene;
    void close() => setState(() => _open = null);
    final text = open.hasLog ? open.bigText : open.tableText;
    return Stack(
      children: [
        scene,
        CodeModal(
          title: open.hasLog
              ? alertText(language, 'Результаты тестов', 'Test results')
              : alertText(language, 'Уведомление', 'Notification'),
          color: color,
          onClose: close,
          text: text,
          copy: () => text,
          body: (_, layout) => CodeView(layout: layout!),
        ),
      ],
    );
  }

  HexSlot _slot(
    BoardSlot slot,
    String language,
    Color color,
    List<Notice> items,
    int count,
    int limit,
    AppModel model,
  ) {
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: alertText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'filter':
        return HexSlot(
          id: 'filter',
          title: alertText(language, 'Фильтр', 'Filter'),
          color: color,
          busy: _loading,
          q: slot.q,
          r: slot.r,
          tappable: false,
          body: _FilterCell(
            color: color,
            offset: _offset,
            limit: limit,
            count: count,
            onRead: _setRead,
            onReadAll: _readAll,
            onStep: _step,
          ),
        );
      case 'types':
        return HexSlot(
          id: 'types',
          title: alertText(language, 'Видимые типы', 'Visible types'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/actions/settings.svg',
        );
      default:
        final uuid = slot.id.startsWith('notice:') ? slot.id.substring(7) : '';
        Notice? notice;
        for (final item in items) {
          if (item.uuid == uuid) notice = item;
        }
        if (notice == null) {
          return HexSlot(
            id: slot.id,
            title: '',
            color: color,
            q: slot.q,
            r: slot.r,
          );
        }
        return HexSlot(
          id: 'notice:${notice.uuid}',
          title: notice.type,
          footerLeft: noticeStatusLabel(language, read: notice.isRead),
          footer: noticeWhen(notice.created, model.vault.timeZone),
          center: notice.smallText,
          centerColor: color,
          color: color,
          busy: _pending == notice.uuid,
          q: slot.q,
          r: slot.r,
        );
    }
  }

  void _tap(String id, List<Notice> items) {
    if (id.startsWith('notice:')) {
      final uuid = id.substring(7);
      for (final item in items) {
        if (item.uuid == uuid) {
          _openNotice(item);
          return;
        }
      }
      return;
    }
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'types':
        context.push('/alerts/types');
      case 'error':
        setState(() => _failureOpen = true);
    }
  }

  Future<void> _openNotice(Notice notice) async {
    setState(() {
      _open = notice;
      _pending = notice.isRead ? null : notice.uuid;
      _failure = null;
      _failureOpen = false;
    });
    if (notice.isRead) return;
    final model = AppScope.of(context);
    try {
      await model.markNoticeRead(notice.uuid);
      if (!mounted) return;
      setState(() => _pending = null);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _pending = null;
        _failure = '$error';
      });
    }
  }

  void _setRead(String value) {
    if (!AppScope.of(context).setNoticeRead(value)) return;
  }

  Future<void> _readAll() async {
    if (_loading) return;
    final model = AppScope.of(context);
    setState(() {
      _loading = true;
      _failure = null;
      _failureOpen = false;
    });
    try {
      await model.markAllNoticesRead();
      if (!mounted) return;
      setState(() => _loading = false);
      await _load();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failure = '$error';
      });
    }
  }

  int _limit(AppModel model) =>
      model.cappedLimit(noticePageLimit(widget.scope));

  void _step(int direction) {
    if (_loading) return;
    final model = AppScope.of(context);
    final count = model.notices?.count ?? 0;
    final limit = _limit(model);
    final next = pageShift(
      direction: direction,
      offset: _offset,
      limit: limit,
      count: count,
      capacity: noticePageLimit(scaleTickMax),
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
      final fresh = await model.loadNotices(
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

class _FilterCell extends StatelessWidget {
  const _FilterCell({
    required this.color,
    required this.offset,
    required this.limit,
    required this.count,
    required this.onRead,
    required this.onReadAll,
    required this.onStep,
  });

  final Color color;
  final int offset;
  final int limit;
  final int count;
  final ValueChanged<String> onRead;
  final VoidCallback onReadAll;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final range = pageWindowText(
      offset: offset,
      limit: limit,
      count: count,
      ofWord: alertText(language, 'из', 'of'),
    );
    final back = noticeCanPageBack(offset: offset, count: count);
    final forward = noticeCanPageForward(
      offset: offset,
      limit: limit,
      count: count,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth;
        final font = cellFont(side);
        final style = TextStyle(
          fontFamily: 'OpenGost Type B',
          fontSize: font,
          decoration: TextDecoration.none,
          height: 1.05,
        );
        // The rule stays inside the hex flats. The enum uses that same width.
        final padX = side * 0.12;
        final ruleInset = side * 0.04;
        final rule = side - 2 * padX - 2 * ruleInset;
        final readAllSize = font * 1.35;
        return Padding(
          padding: EdgeInsets.fromLTRB(padX, side * 0.26, padX, side * 0.15),
          child: Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: side * 0.26),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: rule,
                    child: _ReadWords(onRead: onRead, side: side),
                  ),
                ),
              ),
              SizedBox(height: side * 0.06),
              HintTarget(
                id: 'button-read-all',
                title: alertText(language, 'Прочитать все', 'Read all'),
                color: color,
                child: Semantics(
                  button: true,
                  label: alertText(language, 'Прочитать все', 'Read all'),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onReadAll,
                    child: HoverPop(
                      child: SizedBox(
                        width: rule,
                        height: readAllSize * 1.08,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            alertText(language, 'Прочитать все', 'Read all'),
                            key: const ValueKey('notice-read-all'),
                            style: style.copyWith(
                              color: color,
                              fontSize: readAllSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  ruleInset,
                  side * 0.012,
                  ruleInset,
                  side * 0.008,
                ),
                child: const ColoredBox(
                  key: ValueKey('notice-filter-rule'),
                  color: hexMuted,
                  child: SizedBox(height: 1, width: double.infinity),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: side * 0.06),
                child: SizedBox(
                  height: side * 0.13,
                  child: PageWindow(
                    range: range,
                    canBack: back,
                    canForward: forward,
                    previousLabel: alertText(
                      language,
                      'Предыдущие',
                      'Previous',
                    ),
                    nextLabel: alertText(language, 'Следующие', 'Next'),
                    onStep: onStep,
                    style: style,
                    chevronExtent: side * 0.14,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        );
      },
    );
  }
}

class _ReadWords extends StatelessWidget {
  const _ReadWords({required this.onRead, required this.side});

  final ValueChanged<String> onRead;
  final double side;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final selected = model.noticeQuery.read;
    return SlantedChoices(
      fontSize: cellFont(side) * 1.1,
      maxWidth: double.infinity,
      spanLine: true,
      lineGapShare: 0.05,
      choices: [
        for (final read in noticeReads)
          SlantedChoice(
            label: noticeReadLabel(language, read),
            selected: selected == read,
            onTap: () => onRead(read),
          ),
      ],
    );
  }
}
