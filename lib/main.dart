import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

import 'account/vault_store.dart';
import 'app_model.dart';
import 'app_scope.dart';
import 'features/account/account_alerts_page.dart';
import 'features/account/account_login_page.dart';
import 'features/account/account_menu_page.dart';
import 'features/account/account_register_page.dart';
import 'features/account/account_settings_page.dart';
import 'features/home/home_page.dart';
import 'features/menu/placeholder_page.dart';
import 'features/network/instance_page.dart';
import 'features/network/instance_settings_page.dart';
import 'features/network/member_page.dart';
import 'features/network/setting_category_page.dart';
import 'features/network/network_add_page.dart';
import 'features/network/network_chrome.dart';
import 'features/network/network_lists_page.dart';
import 'features/network/network_page.dart';
import 'features/network/network_search_page.dart';
import 'features/network/users_page.dart';
import 'features/registry/branches_page.dart';
import 'features/registry/credentials_page.dart';
import 'features/registry/registry_page.dart';
import 'features/registry/repo_page.dart';
import 'hive/hex_order.dart';
import 'hive/hex_scene.dart';

Future<void> main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  final model = AppModel(store: PlatformVaultStore());
  await model.load();
  runApp(AppScope(model: model, child: const PepeunitApp()));
}

class PepeunitApp extends StatefulWidget {
  const PepeunitApp({super.key});

  @override
  State<PepeunitApp> createState() => _PepeunitAppState();
}

class _PepeunitAppState extends State<PepeunitApp> {
  late final GoRouter _router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/people',
        builder: (context, state) => const AccountMenuPage(),
        routes: [
          GoRoute(
            path: 'login',
            builder: (context, state) => const AccountLoginPage(),
          ),
          GoRoute(
            path: 'register',
            builder: (context, state) => const AccountRegisterPage(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const AccountSettingsPage(),
            routes: [
              GoRoute(
                path: 'alerts',
                builder: (context, state) => const AccountAlertsPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/peers',
        builder: (context, state) => const NetworkPage(),
        routes: [
          GoRoute(
            path: 'search',
            builder: (context, state) => NetworkSearchPage(
              scope: scaleTickOf(state.uri, fallback: searchScaleTick),
            ),
            routes: [
              GoRoute(
                path: 'settings',
                builder: (context, state) => const NetworkSearchSettingsPage(),
              ),
            ],
          ),
          GoRoute(
            path: 'allow',
            builder: (context, state) =>
                NetworkListPage(deny: false, scope: scaleTickOf(state.uri)),
          ),
          GoRoute(
            path: 'deny',
            builder: (context, state) =>
                NetworkListPage(deny: true, scope: scaleTickOf(state.uri)),
          ),
          GoRoute(
            path: 'add',
            builder: (context, state) => const NetworkAddPage(),
          ),
          GoRoute(
            path: 'track',
            builder: (context, state) => const NetworkAddPage(track: true),
          ),
          GoRoute(
            path: 'instance',
            builder: (context, state) =>
                InstancePage(url: state.uri.queryParameters['url'] ?? ''),
          ),
          GoRoute(
            path: 'users',
            builder: (context, state) => UsersPage(
              scope: scaleTickOf(state.uri, fallback: searchScaleTick),
            ),
            routes: [
              GoRoute(
                path: 'member',
                builder: (context, state) =>
                    MemberPage(uuid: state.uri.queryParameters['uuid'] ?? ''),
              ),
            ],
          ),
          GoRoute(
            path: 'tune',
            builder: (context, state) => const InstanceTunePage(),
            routes: [
              GoRoute(
                path: ':category',
                builder: (context, state) => SettingCategoryPage(
                  categoryId: state.pathParameters['category']!,
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/registry',
        builder: (context, state) => RegistryPage(
          scope: scaleTickOf(state.uri, fallback: searchScaleTick),
        ),
        routes: [
          GoRoute(
            path: 'repo/:uuid',
            builder: (context, state) =>
                RepoPage(uuid: state.pathParameters['uuid']!),
            routes: [
              GoRoute(
                path: 'credentials',
                builder: (context, state) =>
                    CredentialsPage(uuid: state.pathParameters['uuid']!),
              ),
              GoRoute(
                path: 'branches',
                builder: (context, state) => BranchesPage(
                  uuid: state.pathParameters['uuid']!,
                  scope: scaleTickOf(state.uri),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/:section',
        builder: (context, state) =>
            PlaceholderPage(sectionId: state.pathParameters['section']!),
      ),
    ],
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pepeunit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'OpenGost Type B',
        scaffoldBackgroundColor: sceneBackground,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF9800),
          surface: sceneBackground,
          onSurface: Color(0xFFFFFFFF),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFFFFFFF), fontSize: 16),
          titleMedium: TextStyle(color: Color(0xFFFFFFFF), fontSize: 18),
          headlineSmall: TextStyle(color: Color(0xFFFFFFFF), fontSize: 28),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: false,
          isDense: true,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
      routerConfig: _router,
    );
  }
}
