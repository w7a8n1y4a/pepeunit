import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../registry/registry_view.dart';
import '../../registry/repo.dart';
import '../hex_page.dart';
import '../line_input.dart';
import '../units/units_chrome.dart';
import 'registry_chrome.dart';

/// Adds a repository: link, platform, access and, for a private one,
/// the credentials.
class RegistryCreatePage extends StatefulWidget {
  const RegistryCreatePage({super.key});

  @override
  State<RegistryCreatePage> createState() => _RegistryCreatePageState();
}

class _RegistryCreatePageState extends State<RegistryCreatePage> {
  final _url = TextEditingController();
  var _creds = const RepoCredsDraft();
  var _platform = 'Gitlab';
  var _public = true;
  String? _failure;
  var _open = false;
  var _busy = false;

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  bool get _linkOk => repoUrlOk(_url.text);

  bool get _ready => _linkOk && (_public || _creds.ready);

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final language = model.vault.language;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(repoCreateIds(public: _public), wide: wide);
    final slots = <HexSlot>[for (final slot in placed) _slot(slot, language)];
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

  HexSlot _slot(BoardSlot slot, String language) {
    final color = registryColor;
    switch (slot.id) {
      case 'back':
        return backSlot(
          title: regText(language, 'Назад', 'Back'),
          q: slot.q,
          r: slot.r,
        );
      case 'url':
        return HexSlot(
          id: 'url',
          title: regText(language, 'Ссылка', 'Link'),
          color: color,
          q: slot.q,
          r: slot.r,
          tappable: false,
          body: LineInput(
            color: color,
            controller: _url,
            fieldKey: const ValueKey('repo-url'),
            hint: 'https://…/name.git',
            issue: _url.text.trim().isNotEmpty && !_linkOk
                ? regText(
                    language,
                    'Нужна ссылка http(s):// … .git',
                    'A http(s):// … .git link is required',
                  )
                : '',
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _create(),
          ),
        );
      case 'platform':
        return HexSlot(
          id: 'platform',
          title: regText(language, 'Платформа', 'Platform'),
          color: color,
          q: slot.q,
          r: slot.r,
          tappable: false,
          body: ChoiceWords(
            center: true,
            choices: [
              for (final value in repoPlatforms)
                (id: value, label: repoPlatformLabel(language, value)),
            ],
            fontScale: 1.45,
            selected: (id) => _platform == id,
            onTap: (id) => setState(() => _platform = id),
          ),
        );
      case 'access':
        return HexSlot(
          id: 'access',
          title: repoAccessLabel(language, _public),
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/status/flag.svg',
        );
      case 'credentials':
        return HexSlot(
          id: 'credentials',
          title: regText(language, 'Креды', 'Credentials'),
          footer: _creds.ready ? _creds.username.trim() : null,
          color: color,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/objects/key.svg',
        );
      default:
        return HexSlot(
          id: 'create',
          title: regText(language, 'Добавить', 'Add'),
          color: addColor,
          busy: _busy,
          enabled: _ready,
          q: slot.q,
          r: slot.r,
          icon: 'assets/icons/actions/plus.svg',
        );
    }
  }

  Future<void> _tap(String id) async {
    switch (id) {
      case 'back':
        popOrHome(context);
      case 'error':
        setState(() => _open = true);
      case 'access':
        setState(() => _public = !_public);
      case 'credentials':
        final picked = await context.push<RepoCredsDraft>(
          '/registry/new/credentials',
          extra: _creds,
        );
        if (picked == null || !mounted) return;
        setState(() => _creds = picked);
      case 'create':
        _create();
    }
  }

  Future<void> _create() async {
    if (_busy) return;
    final model = AppScope.of(context);
    if (!model.signedIn) {
      setState(() {
        _failure = model.notSignedIn;
        _open = false;
      });
      return;
    }
    if (!_ready) return;
    setState(() {
      _busy = true;
      _failure = null;
      _open = false;
    });
    try {
      final repo = await model.createRepo(
        url: _url.text.trim(),
        platform: _platform,
        public: _public,
        username: _public ? null : _creds.username.trim(),
        pat: _public ? null : _creds.token.trim(),
      );
      if (!mounted) return;
      context.pushReplacement('/registry/repo/${repo.uuid}');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _failure = '$error';
      });
    }
  }
}
