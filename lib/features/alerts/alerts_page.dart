import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../alerts/notice.dart';
import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../hex_page.dart';
import '../network/network_chrome.dart';
import '../page_window.dart';
import '../slanted_choices.dart';
import 'alerts_chrome.dart';
import 'notice_log.dart';
import 'notice_sheet.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({required this.scope, super.key});

  final int scope;

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  var _offset = 0;
  var _loading = true;
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
    final limit = noticePageLimit(widget.scope);
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
    final close = () => setState(() => _open = null);
    final copyLabel = alertText(language, 'Скопировать', 'Copy');
    final closeLabel = alertText(language, 'Закрыть', 'Close');
    return Stack(
      children: [
        scene,
        if (open.hasLog)
          NoticeLog(
            text: open.bigText,
            title: alertText(language, 'Результаты тестов', 'Test results'),
            color: color,
            copyLabel: copyLabel,
            closeLabel: closeLabel,
            onClose: close,
          )
        else
          NoticeSheet(
            text: open.tableText,
            slots: slots,
            color: color,
            copyLabel: copyLabel,
            closeLabel: closeLabel,
            onClose: close,
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
          icon: 'assets/icons/settings.svg',
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

  void _step(int direction) {
    if (_loading) return;
    final model = AppScope.of(context);
    final count = model.notices?.count ?? 0;
    final limit = noticePageLimit(widget.scope);
    if (direction < 0 && !noticeCanPageBack(offset: _offset, count: count)) {
      return;
    }
    if (direction > 0 &&
        !noticeCanPageForward(offset: _offset, limit: limit, count: count)) {
      return;
    }
    setState(() => _offset += direction * limit);
    _load();
  }

  Future<void> _load() async {
    final model = AppScope.of(context);
    final language = model.vault.language;
    if (model.target?.signedIn != true) {
      setState(() {
        _loading = false;
        _failure = alertText(language, 'Нет входа', 'Not signed in');
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
        limit: noticePageLimit(widget.scope),
      );
      if (!mounted || !fresh) return;
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
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
    final range = _range(language);
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
        final line = side * 0.76;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            side * 0.12,
            side * 0.20,
            side * 0.12,
            side * 0.14,
          ),
          child: Column(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: side * 0.26),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    width: line,
                    child: _ReadWords(onRead: onRead, side: side),
                  ),
                ),
              ),
              SizedBox(height: side * 0.09),
              Semantics(
                button: true,
                label: alertText(language, 'Прочитать все', 'Read all'),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onReadAll,
                  child: HoverPop(
                    child: Text(
                      alertText(language, 'Прочитать все', 'Read all'),
                      key: const ValueKey('notice-read-all'),
                      style: style.copyWith(color: color),
                    ),
                  ),
                ),
              ),
              Container(
                height: 1,
                margin: EdgeInsets.fromLTRB(
                  side * 0.04,
                  side * 0.012,
                  side * 0.04,
                  side * 0.008,
                ),
                color: hexMuted,
              ),
              SizedBox(
                height: side * 0.13,
                child: PageWindow(
                  range: range,
                  canBack: back,
                  canForward: forward,
                  previousLabel: alertText(language, 'Предыдущие', 'Previous'),
                  nextLabel: alertText(language, 'Следующие', 'Next'),
                  onStep: onStep,
                  style: style,
                  chevronExtent: side * 0.14,
                ),
              ),
              const Spacer(),
            ],
          ),
        );
      },
    );
  }

  String _range(String language) {
    if (count <= 0) {
      return '0 ${alertText(language, 'из', 'of')} 0';
    }
    final start = offset + 1;
    if (start > count) {
      return '0 ${alertText(language, 'из', 'of')} $count';
    }
    final end = offset + limit < count ? offset + limit : count;
    return '$start-$end ${alertText(language, 'из', 'of')} $count';
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
