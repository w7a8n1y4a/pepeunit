import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../features/account/account_nav.dart';
import '../../features/account/error_reader.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../instances/portrait.dart';
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
  var _busy = false;
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
          federation: federation,
          telegram: portrait?.telegram == true,
          trust: peer?.trust,
        ),
      ];
    }

    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(actions, wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        _slot(slot, model, language, color, url, isTarget, owner, staff),
    ];
    if (_failure != null) {
      final spot = errorSpot(placed, wide: wide);
      slots.add(
        HexSlot(
          id: 'error',
          title: netText(language, 'Ошибка', 'Error'),
          color: errorColor,
          titleColor: errorColor,
          q: spot.$1,
          r: spot.$2,
          icon: 'assets/icons/error.svg',
          iconScale: 1.62,
          body: _open
              ? ErrorCell(
                  message: _failure!,
                  copyLabel: netText(language, 'Скопировать', 'Copy'),
                )
              : null,
        ),
      );
    }
    return ColoredBox(
      color: sceneBackground,
      child: HexScene(
        slots: slots,
        onTap: (id) => _tap(id, language, canModerate),
      ),
    );
  }

  HexSlot _slot(
    BoardSlot slot,
    AppModel model,
    String language,
    Color color,
    String url,
    bool isTarget,
    bool owner,
    bool staff,
  ) {
    final portrait = model.portraitOf(url);
    final peer = model.peers[url];
    final record = model.vault.recordFor(url);
    final active = _busy ? const Color(0xFFFFFFFF) : color;
    switch (slot.id) {
      case 'back':
        return HexSlot(
          id: 'back',
          title: netText(language, 'Назад', 'Back'),
          color: hexMuted,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/back.svg',
        );
      case 'identity':
        final String? leftCaption;
        if (isTarget) {
          leftCaption = netText(language, 'Текущий', 'Target');
        } else if (peer != null) {
          leftCaption = trustLabel(language, peer.trust);
        } else {
          leftCaption = null;
        }
        return instanceMark(
          id: 'identity',
          url: url,
          language: language,
          q: slot.q,
          r: slot.r,
          color: isTarget ? color : trustColor(peer?.trust, color),
          current: isTarget,
          footerLeft: leftCaption,
          footerLeftColor: isTarget
              ? const Color(0xFFFFFFFF)
              : trustColor(peer?.trust, const Color(0xFFFFFFFF)),
          version: portrait?.version,
          image: model.iconOf(url),
          tappable: false,
        );
      case 'relogin':
        return HexSlot(
          id: 'relogin',
          title: netText(language, 'Перезайти', 'Sign in again'),
          footer: record?.role,
          color: active,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/reload.svg',
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
          'Сделать Текущим',
          'Make current',
          color,
          'assets/icons/sight.svg',
        );
      case 'clear':
        return _action(
          slot,
          language,
          'Отменить выбор',
          'Clear selection',
          color,
          'assets/icons/close.svg',
        );
      case 'telegram':
        return _action(
          slot,
          language,
          'Telegram',
          'Telegram',
          active,
          'assets/icons/send.svg',
        );
      case 'settings':
        return HexSlot(
          id: 'settings',
          title: owner
              ? netText(language, 'Параметры', 'Parameters')
              : netText(language, 'Управление', 'Control'),
          footer: record?.role,
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/settings.svg',
          iconScale: 1.35,
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
          active,
          'assets/icons/check.svg',
        );
      case 'block':
        return _action(
          slot,
          language,
          'Блокировать',
          'Block',
          active,
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
          active,
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
      case 'relogin':
        if (!model.vault.hasKey) {
          setState(() {
            _failure = netText(language, 'Нет ключа', 'No key');
          });
          return;
        }
        await _run(() => model.resign(url));
      case 'target':
        await _run(() => model.selectTarget(url));
      case 'clear':
        await _run(model.clearTarget);
      case 'telegram':
        await _telegram(language);
      case 'settings':
        context.push('/peers/tune');
      case 'trust':
        await _run(() => model.setTrust(url, 'Trust'));
      case 'block':
        await _run(() => model.setTrust(url, 'Blocking'));
      case 'delete':
        await _run(() => model.deletePeer(url));
        if (mounted && _failure == null) popOrHome(context);
      case 'scan':
        await _run(() => model.scanPeer(url));
    }
  }

  Future<void> _telegram(String language) async {
    final model = AppScope.of(context);
    if (!model.vault.hasKey) {
      final botUrl = model.portraitOf(widget.url)?.telegramBot ?? '';
      if (botUrl.isNotEmpty) {
        await _run(() => model.openExternal(Uri.parse(botUrl)));
        return;
      }
      setState(() => _failure = netText(language, 'Нет ключа', 'No key'));
      return;
    }
    await _run(() async {
      final link = await model.verificationLink(widget.url);
      await model.openExternal(Uri.parse(link));
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
      _open = false;
    });
    try {
      await action();
      if (!mounted) return;
      setState(() => _busy = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = '$error';
      });
    }
  }
}
