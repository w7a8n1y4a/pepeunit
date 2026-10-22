import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_scope.dart';
import '../../hive/hex_scene.dart';
import '../../navigation/sections.dart';

class AccountMenuPage extends StatelessWidget {
  const AccountMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    final language = AppScope.of(context).vault.language;
    final color = sectionById('people')?.color ?? const Color(0xFFFF3333);
    final login = language == 'en' ? 'Login' : 'Вход';
    final registration = language == 'en' ? 'Registration' : 'Регистрация';
    final back = language == 'en' ? 'Back' : 'Назад';
    return ColoredBox(
      color: sceneBackground,
      child: HexScene(
        slots: [
          HexSlot(
            id: 'login',
            title: login,
            color: color,
            q: 0,
            r: -1,
            icon: 'assets/icons/signin.svg',
          ),
          HexSlot(
            id: 'registration',
            title: registration,
            color: color,
            q: 1,
            r: -1,
            icon: 'assets/icons/registration.svg',
          ),
          HexSlot(
            id: 'back',
            title: back,
            color: const Color(0xFFA1A1AA),
            q: 0,
            r: 0,
            icon: 'assets/icons/back.svg',
          ),
        ],
        onTap: (id) {
          if (id == 'back') {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          }
        },
      ),
    );
  }
}
