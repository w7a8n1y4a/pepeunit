import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../instances/portrait.dart';
import '../../navigation/back.dart';
import '../hex_page.dart';
import 'line_cell.dart';
import 'network_chrome.dart';

class InstancePage extends StatefulWidget {
  const InstancePage({required this.url, super.key});

  final String url;

  @override
  State<InstancePage> createState() => _InstancePageState();
}

class _InstancePageState extends State<InstancePage> {
  String? _failure;
  var _open = false;
  String? _pending;
  var _moderating = false;

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final color = networkColor;
    final url = widget.url;
    final portrait = model.portraitOf(url);
    final target = model.target;
    final isTarget = target?.url == url;
    final owner = isTarget && (target?.ownsInstance ?? false);
    final staff = target?.managesPeers ?? false;
    final federation = model.portraitOf(target?.url ?? '')?.federation != false;
    final peer = model.peers[url];
    final canModerate = !isTarget && staff && peer != null;

    final List<String> actions;
    if (_moderating && canModerate) {
      actions = [
        'identity',
        ...peerActions(trust: peer.trust, federation: federation),
      ];
    } else {
      actions = [
        'identity',
        ...cardActions(
          isTarget: isTarget,
          owner: owner,
          staff: staff,
          signedIn: target?.signedIn ?? false,
          telegram: portrait?.telegram == true,
          trust: peer?.trust,
        ),
      ];
    }

    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(actions, wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        _slot(slot, model, language, color, url, isTarget),
    ];
    appendError(
      slots,
      message: _failure,
      open: _open,
      language: language,
      text: netText,
      wide: wide,
    );
    return HexPage(
      slots: slots,
      onTap: (id) => _tap(id, language, canModerate),
    );
  }

  HexSlot _slot(
    BoardSlot slot,
    AppModel model,
    String language,
    Color color,
    String url,
    bool isTarget,
  ) {
    final portrait = model.portraitOf(url);
    final peer = model.peers[url];
    final record = model.vault.recordFor(url);
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: netText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'identity':
        final ping = peer?.lastPing;
        final pingText = ping == null
            ? null
            : '${ping.round()} ${netText(language, 'мс', 'ms')}';
        return instanceMark(
          id: 'identity',
          url: url,
          language: language,
          q: slot.q,
          r: slot.r,
          color: isTarget ? color : trustColor(peer?.trust, color),
          current: isTarget,
          footerLeft: isTarget ? null : pingText,
          version: portrait?.version,
          image: model.iconOf(url),
          tappable: isTarget,
          busy: _pending == 'identity',
        );
      case 'metrics':
        final pages = _summaryPages(language, portrait, peer);
        return HexSlot(
          id: 'metrics',
          title: netText(language, 'Сводка', 'Summary'),
          color: color,
          q: slot.q,
          r: slot.r,
          tappable: false,
          body: MetricsCell(
            lines: pages.first.lines,
            pages: pages,
            copyText: url,
            copyLabel: netText(language, 'Скопировать ссылку', 'Copy link'),
            prevLabel: netText(
              language,
              'Предыдущая сводка',
              'Previous summary',
            ),
            nextLabel: netText(language, 'Следующая сводка', 'Next summary'),
          ),
        );
      case 'target':
        return _action(
          slot,
          language,
          'Сделать избранным',
          'Make favorite',
          const Color(0xFF4CAF50),
          'assets/icons/sight.svg',
        );
      case 'clear':
        return _action(
          slot,
          language,
          'Разжаловать',
          'Demote',
          errorColor,
          'assets/icons/demote.svg',
        );
      case 'telegram':
        return _action(
          slot,
          language,
          'Телеграм бот',
          'Telegram Bot',
          color,
          'assets/icons/telegram.svg',
        );
      case 'settings':
        return HexSlot(
          id: 'settings',
          title: netText(language, 'Управление инстансом', 'Manage instance'),
          footer: record?.role,
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/settings.svg',
        );
      case 'users':
        return HexSlot(
          id: 'users',
          title: netText(language, 'Пользователи', 'Users'),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/users.svg',
        );
      case 'peer':
        final trust = peer?.trust ?? '';
        final peerIcon = switch (trust) {
          'Trust' => 'assets/icons/check.svg',
          'Blocking' => 'assets/icons/ban.svg',
          _ => 'assets/icons/settings.svg',
        };
        return HexSlot(
          id: 'peer',
          title: netText(language, 'Модерация', 'Moderation'),
          footer: trust.isEmpty ? null : trustLabel(language, trust),
          color: trustColor(trust, color),
          q: slot.q,
          r: slot.r,
          icon: peerIcon,
        );
      case 'trust':
        return _action(
          slot,
          language,
          'Доверять',
          'Trust',
          color,
          'assets/icons/check.svg',
        );
      case 'block':
        return _action(
          slot,
          language,
          'Блокировать',
          'Block',
          color,
          'assets/icons/ban.svg',
        );
      case 'delete':
        return _action(
          slot,
          language,
          'Удалить',
          'Delete',
          errorColor,
          'assets/icons/close.svg',
        );
      case 'scan':
        return _action(
          slot,
          language,
          'Опрос',
          'Scan',
          color,
          'assets/icons/reload.svg',
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

  List<SummaryPage> _summaryPages(
    String language,
    InstancePortrait? portrait,
    PeerHead? peer,
  ) {
    final metricsLines = <String>[
      netText(
        language,
        'Юзеры ${portrait?.users ?? '—'}',
        'Users ${portrait?.users ?? '—'}',
      ),
      netText(
        language,
        'Устройства ${portrait?.units ?? '—'}',
        'Units ${portrait?.units ?? '—'}',
      ),
      netText(
        language,
        'Репозитории ${portrait?.repos ?? '—'}',
        'Repos ${portrait?.repos ?? '—'}',
      ),
      if (portrait?.unitIos != null)
        netText(
          language,
          'UnitIO ${portrait!.unitIos}',
          'UnitIO ${portrait.unitIos}',
        ),
      if (portrait?.testsStatus != null)
        '${portrait!.testsStatus} ${portrait.testsPercent?.round() ?? ''}%',
    ];
    final pages = <SummaryPage>[
      SummaryPage(
        title: netText(language, 'Метрики', 'Metrics'),
        lines: metricsLines,
      ),
    ];

    final statusLines = <String>[
      if (peer != null)
        '${netText(language, 'Статус', 'Status')}: ${peer.collectionStatus ?? peer.trust}',
      if (peer?.lastPing != null)
        '${netText(language, 'Пинг', 'Ping')}: ${peer!.lastPing!.round()} ${netText(language, 'мс', 'ms')}',
      if (peer != null && peer.consecutiveSuccessCount > 0)
        '${netText(language, 'Серия', 'Streak')}: ${peer.consecutiveSuccessCount}',
      if (portrait != null && portrait.email.isNotEmpty) portrait.email,
      if (portrait != null && portrait.telegramContact.isNotEmpty)
        portrait.telegramContact,
      if (portrait != null && portrait.license.isNotEmpty) portrait.license,
    ];
    if (statusLines.isNotEmpty) {
      pages.add(
        SummaryPage(
          title: netText(language, 'Инфо', 'Info'),
          lines: statusLines,
        ),
      );
    }

    if (portrait != null &&
        (portrait.datapipe != null ||
            portrait.federation != null ||
            portrait.grafana != null ||
            portrait.notifications != null)) {
      String mark(bool? v) => v == true ? '+' : '-';
      pages.add(
        SummaryPage(
          title: netText(language, 'Флаги', 'Flags'),
          lines: [
            'Pipe ${mark(portrait.datapipe)} · Fed ${mark(portrait.federation)}',
            'Graf ${mark(portrait.grafana)} · Alert ${mark(portrait.notifications)}',
            'Prom ${mark(portrait.prometheus)} · TG ${mark(portrait.telegram)}',
          ],
        ),
      );
    }
    return pages;
  }

  HexSlot _action(
    BoardSlot slot,
    String language,
    String ru,
    String en,
    Color color,
    String icon,
  ) {
    return HexSlot(
      id: slot.id,
      title: netText(language, ru, en),
      color: color,
      busy: _pending == slot.id,
      q: slot.q,
      r: slot.r,
      icon: icon,
    );
  }

  Future<void> _tap(String id, String language, bool canModerate) async {
    final model = AppScope.of(context);
    final url = widget.url;
    switch (id) {
      case 'back':
        if (_moderating) {
          setState(() {
            _moderating = false;
            _failure = null;
            _open = false;
          });
          return;
        }
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'peer':
        if (canModerate) {
          setState(() {
            _moderating = true;
            _failure = null;
            _open = false;
          });
        }
      case 'identity':
        if (model.target?.url != url) return;
        if (!model.vault.hasKey) {
          setState(() {
            _failure = netText(language, 'Нет ключа', 'No key');
          });
          return;
        }
        await _run('identity', () => model.resign(url));
      case 'target':
        await _run('target', () => model.selectTarget(url));
      case 'clear':
        await _run('clear', model.clearTarget);
      case 'telegram':
        await _telegram(language);
      case 'settings':
        context.push('/peers/tune');
      case 'users':
        context.push('/peers/users');
      case 'trust':
        await _run('trust', () => model.setTrust(url, 'Trust'));
      case 'block':
        await _run('block', () => model.setTrust(url, 'Blocking'));
      case 'delete':
        await _run('delete', () => model.deletePeer(url));
        if (mounted && _failure == null) popOrHome(context);
      case 'scan':
        await _run('scan', () => model.scanPeer(url));
    }
  }

  Future<void> _telegram(String language) async {
    final model = AppScope.of(context);
    if (!model.vault.hasKey) {
      final botUrl = model.portraitOf(widget.url)?.telegramBot ?? '';
      if (botUrl.isNotEmpty) {
        await _run('telegram', () => model.openExternal(Uri.parse(botUrl)));
        return;
      }
      setState(() => _failure = netText(language, 'Нет ключа', 'No key'));
      return;
    }
    await _run('telegram', () async {
      final link = await model.verificationLink(widget.url);
      await model.openExternal(Uri.parse(link));
    });
  }

  Future<void> _run(String id, Future<void> Function() action) async {
    if (_pending != null) return;
    setState(() {
      _pending = id;
      _failure = null;
      _open = false;
    });
    try {
      await action();
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
}
