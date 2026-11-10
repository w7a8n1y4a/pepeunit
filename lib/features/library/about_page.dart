import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../api/self_update.dart';
import '../../app_scope.dart';
import '../../client_version.dart';
import '../../hive/hex_motion.dart';
import '../../hive/hex_scene.dart';
import '../../instances/link.dart';
import '../../instances/network_view.dart';
import '../../library/updates.dart';
import '../../navigation/back.dart';
import '../code/code_modal.dart';
import '../hex_page.dart';
import 'library_menu_page.dart';
import 'library_modal.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  var _checking = false;
  var _updating = false;
  UpdateCheck? _result;
  String? _failure;
  var _failureOpen = false;
  String? _note;
  var _noteOk = false;
  HexEcho? _echo;

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = cardBoard(const [
      'version',
      'updates',
      'apps',
      'social',
      'support',
    ], wide: wide);
    final slots = [
      for (final slot in board)
        switch (slot.id) {
          'back' => backSlot(
            title: libText(language, 'Назад'),
            q: slot.q,
            r: slot.r,
          ),
          'version' => HexSlot(
            id: 'version',
            title: libText(language, 'Версия клиента'),
            color: libraryColor,
            q: slot.q,
            r: slot.r,
            center: clientVersion,
            centerScale: 2.2,
            tappable: false,
          ),
          'updates' => HexSlot(
            id: 'updates',
            title: libText(language, 'Проверить обновления'),
            color: libraryColor,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/actions/updates.svg',
            busy: _checking,
          ),
          'apps' => HexSlot(
            id: 'apps',
            title: libText(language, 'Нативные приложения'),
            color: libraryColor,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/objects/platform.svg',
          ),
          'social' => HexSlot(
            id: 'social',
            title: libText(language, 'Соцсети'),
            color: libraryColor,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/objects/links.svg',
          ),
          _ => HexSlot(
            id: 'support',
            title: libText(language, 'Поддержать проект'),
            color: libraryColor,
            q: slot.q,
            r: slot.r,
            icon: 'assets/icons/services/bitcoin.svg',
          ),
        },
    ];
    appendError(
      slots,
      message: _failure,
      open: _failureOpen,
      language: language,
      text: libErrorText,
      wide: wide,
    );
    final scene = HexPage(
      slots: slots,
      echo: _echo,
      onTap: (id) {
        switch (id) {
          case 'back':
            popOrHome(context);
          case 'updates':
            _checkUpdates(language);
          case 'apps':
            context.push('/library/about/apps');
          case 'social':
            context.push('/library/about/social');
          case 'support':
            context.push('/library/about/support');
          case 'error':
            setState(() => _failureOpen = true);
        }
      },
    );
    final result = _result;
    if (result == null) return scene;
    return Stack(
      children: [
        scene,
        Material(
          type: MaterialType.transparency,
          child: _modal(result, language),
        ),
      ],
    );
  }

  Widget _modal(UpdateCheck result, String language) {
    final binary = result.binary;
    final native = nativePlatform() != null;
    final title = switch (result.state) {
      UpdateState.available => libText(language, 'Версия ${result.latest}'),
      _ => libText(language, 'Обновления'),
    };
    final source = switch (result.state) {
      UpdateState.current => libText(
        language,
        'Установлена последняя версия: $clientVersion.',
      ),
      UpdateState.noAssets => libText(
        language,
        'Вышла версия ${result.latest}, но у неё пока нет файлов. '
        'Попробуйте позже.',
      ),
      UpdateState.available =>
        result.notes ?? libText(language, 'Описание изменений недоступно.'),
    };
    final missing =
        result.state == UpdateState.available && native && binary == null;
    return LibraryModal(
      title: title,
      color: libraryColor,
      source: source,
      onClose: _closeModal,
      note:
          _note ??
          (missing
              ? libText(language, 'В релизе нет файла для этой платформы.')
              : null),
      noteColor: _note != null && _noteOk ? addColor : errorColor,
      footer: binary == null
          ? null
          : (font) => [
              CodeWordButton(
                label: libText(language, 'Обновиться до ${result.latest}'),
                font: font,
                color: libraryColor,
                busy: _updating,
                enabled: !_updating,
                onTap: () => _update(binary, language),
                hint: 'button-update',
              ),
            ],
    );
  }

  void _closeModal() {
    if (_updating) return;
    setState(() {
      _result = null;
      _note = null;
    });
  }

  void _fail(String message) {
    setState(() {
      _checking = false;
      _failure = message;
      _failureOpen = false;
      _echo = HexEcho(ok: false);
    });
  }

  Future<void> _checkUpdates(String language) async {
    if (_checking) return;
    final model = AppScope.of(context);
    setState(() {
      _checking = true;
      _failure = null;
      _failureOpen = false;
      _note = null;
    });
    try {
      final result = await model.checkUpdates();
      if (!mounted) return;
      setState(() {
        _checking = false;
        _result = result;
        _echo = HexEcho(ok: true);
      });
    } on TimeoutException {
      if (!mounted) return;
      _fail(
        libErrorText(
          language,
          'Проверка заняла больше минуты',
          'The check took longer than a minute',
        ),
      );
    } catch (_) {
      if (!mounted) return;
      _fail(
        libErrorText(
          language,
          'Не удалось проверить обновления',
          'Updates could not be checked',
        ),
      );
    }
  }

  /// Downloads the file of this platform and puts it in place of the running
  /// client when the platform allows. Otherwise the person saves it.
  Future<void> _update(ReleaseAsset binary, String language) async {
    if (_updating) return;
    final model = AppScope.of(context);
    final platform = nativePlatform();
    if (platform == null) return;
    setState(() {
      _updating = true;
      _note = null;
    });
    String? note;
    var ok = false;
    try {
      final bytes = await model
          .downloadFile(Uri.parse(binary.url))
          .timeout(const Duration(minutes: 10));
      if (!mounted) return;
      if (await replaceRunningApp(bytes, platform)) {
        ok = true;
        note = libText(
          language,
          'Обновлено. Перезапустите приложение, чтобы начать с новой версии.',
        );
      } else if (await model.saveBytes(binary.name, bytes)) {
        ok = true;
        note = libText(
          language,
          'Файл сохранён. Установите его, чтобы обновиться.',
        );
      }
    } catch (_) {
      note = libErrorText(
        language,
        'Не удалось скачать обновление',
        'The update could not be downloaded',
      );
    }
    if (!mounted) return;
    setState(() {
      _updating = false;
      _note = note;
      _noteOk = ok;
      if (note != null) _echo = HexEcho(ok: ok);
    });
  }
}

const _platforms = <({String id, String title, String icon})>[
  (id: 'android', title: 'Android', icon: 'assets/icons/services/android.svg'),
  (id: 'ios', title: 'iOS', icon: 'assets/icons/services/ios.svg'),
  (id: 'linux', title: 'Linux', icon: 'assets/icons/services/linux.svg'),
  (id: 'macos', title: 'macOS', icon: 'assets/icons/services/macos.svg'),
  (id: 'windows', title: 'Windows', icon: 'assets/icons/services/windows.svg'),
];

class NativeAppsPage extends StatelessWidget {
  const NativeAppsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = cardBoard([
      for (final platform in _platforms) platform.id,
    ], wide: wide);
    return HexPage(
      slots: [
        for (final slot in board)
          if (slot.id == 'back')
            backSlot(title: libText(language, 'Назад'), q: slot.q, r: slot.r)
          else
            HexSlot(
              id: slot.id,
              title: _platforms.firstWhere((item) => item.id == slot.id).title,
              color: libraryColor,
              q: slot.q,
              r: slot.r,
              icon: _platforms.firstWhere((item) => item.id == slot.id).icon,
              footer: clientVersion,
              footerLeft: '.${platformExtensions[slot.id]}',
            ),
      ],
      onTap: (id) {
        if (id == 'back') {
          popOrHome(context);
          return;
        }
        // The link comes from the version of this client, with no request.
        launchExternal(assetUri(githubSource, clientVersion, id));
      },
    );
  }
}

const _socialLinks = <({String id, String title, String icon, String url})>[
  (
    id: 'gitlab',
    title: 'GitLab',
    icon: 'assets/icons/services/gitlab.svg',
    url: 'https://git.pepemoss.com/pepe/pepeunit/pepeunit',
  ),
  (
    id: 'github',
    title: 'GitHub',
    icon: 'assets/icons/services/github.svg',
    url: 'https://github.com/w7a8n1y4a/pepeunit',
  ),
  (
    id: 'discord',
    title: 'Discord',
    icon: 'assets/icons/services/discord.svg',
    url: 'https://discord.gg/bTAF2mxzuN',
  ),
  (
    id: 'telegram',
    title: 'Telegram',
    icon: 'assets/icons/services/telegram.svg',
    url: 'https://t.me/pepeunit',
  ),
  (
    id: 'youtube',
    title: 'YouTube',
    icon: 'assets/icons/services/youtube.svg',
    url: 'https://www.youtube.com/@pepeunit',
  ),
];

class SocialLinksPage extends StatelessWidget {
  const SocialLinksPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final board = cardBoard([
      for (final link in _socialLinks) link.id,
    ], wide: wide);
    return HexPage(
      slots: [
        for (final slot in board)
          if (slot.id == 'back')
            backSlot(title: libText(language, 'Назад'), q: slot.q, r: slot.r)
          else
            HexSlot(
              id: slot.id,
              title: _socialLinks
                  .firstWhere((link) => link.id == slot.id)
                  .title,
              color: libraryColor,
              q: slot.q,
              r: slot.r,
              icon: _socialLinks.firstWhere((link) => link.id == slot.id).icon,
            ),
      ],
      onTap: (id) {
        if (id == 'back') {
          popOrHome(context);
          return;
        }
        for (final link in _socialLinks) {
          if (link.id == id) launchExternal(Uri.parse(link.url));
        }
      },
    );
  }
}
