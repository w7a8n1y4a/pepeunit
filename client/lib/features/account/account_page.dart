import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_model.dart';
import '../../app_scope.dart';
import '../../hive/hex_scene.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late final TextEditingController _login;
  late final TextEditingController _zone;
  late final TextEditingController _url;
  String _language = 'ru';
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _login = TextEditingController();
    _zone = TextEditingController();
    _url = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    _loaded = true;
    final vault = AppScope.of(context).vault;
    _login.text = vault.login;
    _zone.text = vault.timeZone;
    _language = vault.language;
  }

  @override
  void dispose() {
    _login.dispose();
    _zone.dispose();
    _url.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = AppScope.of(context);
    final en = _language == 'en';
    final icon = model.vault.iconPng == null ? null : base64Decode(model.vault.iconPng!);
    final status = model.vault.hasKey
        ? (en ? 'Key is on this device' : 'Ключ на этом устройстве')
        : (en ? 'No account yet' : 'Аккаунта ещё нет');
    return Scaffold(
      backgroundColor: sceneBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFFFFFFF)),
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: Text(en ? 'Back' : 'Назад'),
                  ),
                ),
                Text(
                  en ? 'Account' : 'Аккаунт',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: const Color(0xFFFF3333)),
                ),
                const SizedBox(height: 8),
                Text(status, style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 16)),
                const SizedBox(height: 16),
                _action(
                  label: en ? 'Create account' : 'Создать аккаунт',
                  onPressed: model.busy || model.vault.hasKey ? null : model.createAccount,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _login,
                  style: const TextStyle(color: Color(0xFFFFFFFF)),
                  decoration: InputDecoration(labelText: en ? 'Login' : 'Логин'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _language,
                  dropdownColor: hexFill,
                  style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 16),
                  decoration: InputDecoration(labelText: en ? 'Language' : 'Язык'),
                  items: const [
                    DropdownMenuItem(value: 'ru', child: Text('Русский')),
                    DropdownMenuItem(value: 'en', child: Text('English')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _language = value);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _zone,
                  style: const TextStyle(color: Color(0xFFFFFFFF)),
                  decoration: InputDecoration(labelText: en ? 'Time zone' : 'Часовой пояс'),
                ),
                const SizedBox(height: 12),
                _action(
                  label: en ? 'Save on this device' : 'Сохранить на устройстве',
                  onPressed: model.busy
                      ? null
                      : () => model.saveProfile(login: _login.text, language: _language, timeZone: _zone.text),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      color: hexFill,
                      child: icon == null ? null : Image.memory(icon, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _action(
                        label: en ? 'PNG icon' : 'Картинка PNG',
                        onPressed: model.busy ? null : () => _pickIcon(model),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(en ? 'Instances' : 'Инстансы', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                for (final instance in model.vault.instances)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: hexFill,
                      child: InkWell(
                        onTap: model.busy ? null : () => model.selectInstance(instance.url),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            border: Border.all(color: instance.active ? const Color(0xFFFF9800) : const Color(0xFFA1A1AA)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(instance.url, style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 15)),
                              const SizedBox(height: 4),
                              Text(
                                instance.signedIn ? (en ? 'signed in' : 'вход есть') : (en ? 'signed out' : 'входа нет'),
                                style: const TextStyle(color: Color(0xFFA1A1AA), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                TextField(
                  controller: _url,
                  style: const TextStyle(color: Color(0xFFFFFFFF)),
                  decoration: InputDecoration(labelText: en ? 'Instance URL' : 'Адрес инстанса'),
                  onSubmitted: model.busy ? null : (value) => _add(model, value),
                ),
                const SizedBox(height: 12),
                _action(
                  label: en ? 'Add instance' : 'Добавить инстанс',
                  onPressed: model.busy ? null : () => _add(model, _url.text),
                ),
                const SizedBox(height: 8),
                _action(label: en ? 'Sign in' : 'Войти', onPressed: model.busy ? null : model.signInActive),
                const SizedBox(height: 8),
                _action(label: en ? 'Send profile' : 'Разослать профиль', onPressed: model.busy ? null : model.pushProfile),
                if (model.busy) const Padding(padding: EdgeInsets.only(top: 16), child: LinearProgressIndicator()),
                if (model.notice.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: SelectableText(model.notice, style: const TextStyle(color: Color(0xFFFFFFFF), fontSize: 14)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _action({required String label, required VoidCallback? onPressed}) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFFFFFFFF),
        side: const BorderSide(color: Color(0xFFFF9800)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      child: Text(label),
    );
  }

  Future<void> _add(AppModel model, String value) async {
    await model.addInstance(value);
    if (mounted) _url.clear();
  }

  Future<void> _pickIcon(AppModel model) async {
    final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['png']);
    if (file == null) return;
    await model.setIcon(await file.readAsBytes());
  }
}
