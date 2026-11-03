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
import 'features/alerts/alert_types_page.dart';
import 'features/alerts/alerts_page.dart';
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
import 'features/units/name_pick_page.dart';
import 'features/units/unit_access_page.dart';
import 'features/units/unit_create_page.dart';
import 'features/units/unit_forms.dart';
import 'features/units/unit_group_pages.dart';
import 'features/units/unit_io_pages.dart';
import 'features/units/unit_page.dart';
import 'features/units/unit_work_pages.dart';
import 'features/units/units_menu_page.dart';
import 'features/units/units_page.dart';
import 'hive/hex_order.dart';
import 'hive/hex_scene.dart';

Future<void> main() async {
  // push and replace are how every screen opens. Without this the web
  // address stays on the page that was loaded first.
  GoRouter.optionURLReflectsImperativeAPIs = true;
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
        path: '/alerts',
        builder: (context, state) => AlertsPage(
          scope: scaleTickOf(state.uri, fallback: searchScaleTick),
        ),
        routes: [
          GoRoute(
            path: 'types',
            builder: (context, state) => const AlertTypesPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/units',
        builder: (context, state) => const UnitsMenuPage(),
        routes: [
          GoRoute(
            path: 'search',
            builder: (context, state) => UnitsPage(
              scope: scaleTickOf(state.uri, fallback: searchScaleTick),
            ),
          ),
          GoRoute(
            path: 'pick',
            builder: (context, state) => UnitsPage(
              scope: scaleTickOf(state.uri, fallback: searchScaleTick),
              pick: true,
            ),
          ),
          GoRoute(
            path: 'pick-user',
            builder: (context, state) => const UserPickPage(),
          ),
          GoRoute(
            path: 'outputs',
            builder: (context, state) => UnitOutputsPage(
              unitUuid: state.uri.queryParameters['unit'] ?? '',
            ),
          ),
          GoRoute(
            path: 'access/kind',
            builder: (context, state) => const AccessKindPage(),
          ),
          GoRoute(
            path: 'pipe/:uuid/data',
            builder: (context, state) => UnitPipeDataPage(
              uuid: state.pathParameters['uuid']!,
              scope: scaleTickOf(state.uri),
            ),
          ),
          GoRoute(
            path: 'new',
            builder: (context, state) => UnitCreatePage(
              repoUuid: state.uri.queryParameters['repo'] ?? '',
            ),
            routes: [
              GoRoute(
                path: 'repo',
                builder: (context, state) => RegistryPage(
                  scope: scaleTickOf(state.uri, fallback: searchScaleTick),
                  forUnit: true,
                ),
              ),
              GoRoute(
                path: 'branch',
                builder: (context, state) {
                  final repo = state.uri.queryParameters['repo'] ?? '';
                  return NamePickPage(
                    title: 'Branch',
                    scope: scaleTickOf(state.uri),
                    path: '/units/new/branch?repo=$repo',
                    load: () async {
                      final read = await AppScope.of(context).readRepo(repo);
                      return [
                        for (final name in read.branches)
                          (id: name, label: name),
                      ];
                    },
                  );
                },
              ),
              GoRoute(
                path: 'commit',
                builder: (context, state) {
                  final repo = state.uri.queryParameters['repo'] ?? '';
                  final branch = state.uri.queryParameters['branch'] ?? '';
                  return NamePickPage(
                    title: 'Commit',
                    scope: scaleTickOf(state.uri),
                    path:
                        '/units/new/commit?repo=$repo&branch=${Uri.encodeQueryComponent(branch)}',
                    load: () async {
                      final rows = await AppScope.of(context)
                          .branchCommits(repo, branch);
                      return [
                        for (final row in rows)
                          (id: row.commit, label: row.tag ?? row.summary),
                      ];
                    },
                  );
                },
              ),
              GoRoute(
                path: 'platform',
                builder: (context, state) {
                  final repo = state.uri.queryParameters['repo'] ?? '';
                  final branch = state.uri.queryParameters['branch'];
                  final commit = state.uri.queryParameters['commit'];
                  return NamePickPage(
                    title: 'Platform',
                    scope: scaleTickOf(state.uri),
                    path: state.uri
                        .replace(
                          queryParameters: {
                            'repo': repo,
                            'branch': ?branch,
                            'commit': ?commit,
                          },
                        )
                        .toString(),
                    load: () async {
                      final rows = await AppScope.of(
                        context,
                      ).firmwarePlatforms(repo, branch: branch, commit: commit);
                      return [
                        for (final row in rows) (id: row.name, label: row.name),
                      ];
                    },
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: 'groups',
            builder: (context, state) =>
                GroupsPage(scope: scaleTickOf(state.uri)),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const GroupCreatePage(),
              ),
              GoRoute(
                path: ':gid',
                builder: (context, state) =>
                    GroupPage(uuid: state.pathParameters['gid']!),
                routes: [
                  GoRoute(
                    path: 'members',
                    builder: (context, state) => GroupMembersPage(
                      uuid: state.pathParameters['gid']!,
                      scope: scaleTickOf(state.uri),
                    ),
                  ),
                  GoRoute(
                    path: 'unit/:uid',
                    builder: (context, state) => MembershipPage(
                      groupUuid: state.pathParameters['gid']!,
                      unitUuid: state.pathParameters['uid']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: ':uuid',
            builder: (context, state) =>
                UnitPage(uuid: state.pathParameters['uuid']!),
            routes: [
              GoRoute(
                path: 'settings',
                builder: (context, state) =>
                    UnitSettingsPage(uuid: state.pathParameters['uuid']!),
              ),
              GoRoute(
                path: 'env',
                builder: (context, state) => UnitEnvPage(
                  uuid: state.pathParameters['uuid']!,
                  scope: scaleTickOf(state.uri),
                ),
              ),
              GoRoute(
                path: 'work',
                builder: (context, state) =>
                    UnitWorkPage(uuid: state.pathParameters['uuid']!),
                routes: [
                  GoRoute(
                    path: 'commands',
                    builder: (context, state) =>
                        UnitCommandsPage(uuid: state.pathParameters['uuid']!),
                  ),
                  GoRoute(
                    path: 'logs',
                    builder: (context, state) => UnitLogsPage(
                      uuid: state.pathParameters['uuid']!,
                      scope: scaleTickOf(state.uri),
                    ),
                  ),
                  GoRoute(
                    path: 'firmware',
                    builder: (context, state) =>
                        UnitFirmwarePage(uuid: state.pathParameters['uuid']!),
                  ),
                  GoRoute(
                    path: 'schema',
                    builder: (context, state) => UnitTextPage(
                      uuid: state.pathParameters['uuid']!,
                      kind: 'schema',
                    ),
                  ),
                  GoRoute(
                    path: 'state',
                    builder: (context, state) => UnitTextPage(
                      uuid: state.pathParameters['uuid']!,
                      kind: 'state',
                    ),
                  ),
                ],
              ),
              GoRoute(
                path: 'access',
                builder: (context, state) => AccessPage(
                  resourceUuid: state.pathParameters['uuid']!,
                  resourceType: 'Unit',
                  scope: scaleTickOf(state.uri),
                  path: '/units/${state.pathParameters['uuid']}/access',
                ),
              ),
              GoRoute(
                path: 'io',
                builder: (context, state) => UnitIoListPage(
                  uuid: state.pathParameters['uuid']!,
                  scope: scaleTickOf(state.uri),
                ),
                routes: [
                  GoRoute(
                    path: ':io',
                    builder: (context, state) => UnitIoPage(
                      unitUuid: state.pathParameters['uuid']!,
                      uuid: state.pathParameters['io']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'settings',
                        builder: (context, state) => UnitIoSettingsPage(
                          uuid: state.pathParameters['io']!,
                        ),
                      ),
                      GoRoute(
                        path: 'value',
                        builder: (context, state) =>
                            UnitIoValuePage(uuid: state.pathParameters['io']!),
                      ),
                      GoRoute(
                        path: 'links',
                        builder: (context, state) => UnitLinksPage(
                          unitUuid: state.pathParameters['uuid']!,
                          uuid: state.pathParameters['io']!,
                        ),
                      ),
                      GoRoute(
                        path: 'pipe',
                        builder: (context, state) =>
                            UnitPipePage(uuid: state.pathParameters['io']!),
                      ),
                      GoRoute(
                        path: 'access',
                        builder: (context, state) => AccessPage(
                          resourceUuid: state.pathParameters['io']!,
                          resourceType: 'UnitIO',
                          scope: scaleTickOf(state.uri),
                          path:
                              '/units/${state.pathParameters['uuid']}/io/${state.pathParameters['io']}/access',
                        ),
                      ),
                    ],
                  ),
                ],
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
