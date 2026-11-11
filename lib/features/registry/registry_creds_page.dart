import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../instances/network_view.dart';
import '../../navigation/back.dart';
import '../../registry/registry_view.dart';
import '../hex_page.dart';
import '../line_input.dart';
import 'registry_chrome.dart';
import '../../locale/languages.dart';

/// Name and token of a repository that is not saved yet. Back hands the
/// draft to the add form.
class RegistryCredsPage extends StatefulWidget {
  const RegistryCredsPage({this.draft = const RepoCredsDraft(), super.key});

  final RepoCredsDraft draft;

  @override
  State<RegistryCredsPage> createState() => _RegistryCredsPageState();
}

class _RegistryCredsPageState extends State<RegistryCredsPage> {
  late final TextEditingController _name;
  late final TextEditingController _token;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.draft.username);
    _token = TextEditingController(text: widget.draft.token);
  }

  @override
  void dispose() {
    _name.dispose();
    _token.dispose();
    super.dispose();
  }

  RepoCredsDraft get _draft =>
      RepoCredsDraft(username: _name.text.trim(), token: _token.text.trim());

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final color = registryColor;
    final wide = hexWide(MediaQuery.sizeOf(context));
    final placed = cardBoard(const ['name', 'token'], wide: wide);
    final slots = <HexSlot>[
      for (final slot in placed)
        switch (slot.id) {
          'back' => backSlot(language, q: slot.q, r: slot.r),
          'name' => HexSlot(
            id: 'name',
            title: localized(language, 'Имя', 'Name'),
            color: color,
            q: slot.q,
            r: slot.r,
            tappable: false,
            body: LineInput(
              color: color,
              controller: _name,
              fieldKey: const ValueKey('repo-create-name'),
              hint: localized(language, 'имя', 'name'),
              issue: '',
            ),
          ),
          _ => HexSlot(
            id: 'token',
            title: localized(language, 'Токен', 'Token'),
            color: color,
            q: slot.q,
            r: slot.r,
            tappable: false,
            body: LineInput(
              color: color,
              controller: _token,
              fieldKey: const ValueKey('repo-create-token'),
              hint: localized(language, 'токен', 'token'),
              issue: '',
              onSubmitted: (_) => _close(),
            ),
          ),
        },
    ];
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: HexPage(
        slots: slots,
        onTap: (id) {
          if (id == 'back') _close();
        },
      ),
    );
  }

  void _close() {
    if (context.canPop()) {
      context.pop(_draft);
    } else {
      popOrHome(context);
    }
  }
}
