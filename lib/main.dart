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
import 'features/dashboards/dashboard_page.dart';
import 'features/dashboards/dashboards_chrome.dart';
import 'features/dashboards/dashboards_menu_page.dart';
import 'features/dashboards/dashboards_page.dart';
import 'features/dashboards/panel_pages.dart';
import 'features/home/home_page.dart';
import 'features/library/docs_page.dart';
import 'features/library/library_menu_page.dart';
import 'features/library/library_modal.dart';
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
import 'features/registry/registry_create_page.dart';
import 'features/registry/registry_creds_page.dart';
import 'features/registry/registry_menu_page.dart';
import 'features/registry/registry_page.dart';
import 'features/registry/repo_page.dart';
import 'features/units/commit_pick_page.dart';
import 'features/units/name_pick_page.dart';
import 'features/units/unit_access_page.dart';
import 'features/units/unit_create_page.dart';
import 'features/units/unit_forms.dart';
import 'features/units/unit_group_pages.dart';
import 'features/units/unit_info_page.dart';
import 'features/units/unit_io_pages.dart';
import 'features/units/unit_pipe_pages.dart';
import 'features/units/unit_page.dart';
import 'features/units/unit_work_pages.dart';
import 'features/units/units_menu_page.dart';
import 'features/units/units_page.dart';
import 'dashboards/dashboard.dart';
import 'hive/background.dart';
import 'hive/grain.dart';
import 'hive/hex_order.dart';
import 'hive/hint.dart';
import 'hive/hex_scene.dart';
import 'hive/page_transition.dart';
import 'library/library.dart';
import 'registry/registry_view.dart';

Future<void> main() async {
  // push and replace are how every screen opens. Without this the web
  // address stays on the page that was loaded first.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();
  final model = AppModel(store: PlatformVaultStore());
  await model.load();
  await Library.instance.load();
  runApp(AppScope(model: model, child: const PepeunitApp()));
}

class PepeunitApp extends StatefulWidget {
  /// [background] is false in tests: the mosaic keeps a timer running.
  const PepeunitApp({this.background = true, super.key});

  final bool background;

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
        builder: (context, state) => const RegistryMenuPage(),
        routes: [
          GoRoute(
            path: 'search',
            builder: (context, state) => RegistryPage(
              scope: scaleTickOf(state.uri, fallback: searchScaleTick),
            ),
          ),
          GoRoute(
            path: 'new',
            builder: (context, state) => const RegistryCreatePage(),
            routes: [
              GoRoute(
                path: 'credentials',
                builder: (context, state) {
                  final draft = state.extra;
                  return RegistryCredsPage(
                    draft: draft is RepoCredsDraft
                        ? draft
                        : const RepoCredsDraft(),
                  );
                },
              ),
            ],
          ),
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
              outputsOnly: state.uri.queryParameters['outputs'] == '1',
              anyNode: state.uri.queryParameters['nodes'] == '1',
            ),
          ),
          GoRoute(
            path: 'pick-user',
            builder: (context, state) => UsersPage(
              scope: scaleTickOf(state.uri, fallback: searchScaleTick),
              pick: true,
            ),
          ),
          GoRoute(
            path: 'outputs',
            builder: (context, state) => UnitIoListPage(
              uuid: state.uri.queryParameters['unit'] ?? '',
              scope: scaleTickOf(state.uri),
              pickOutput: true,
              anyNode: state.uri.queryParameters['nodes'] == '1',
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
                  final query = state.uri.queryParameters;
                  return CommitPickPage(
                    repoUuid: query['repo'] ?? '',
                    branch: query['branch'] ?? '',
                    compilable: query['compilable'] == '1',
                    scope: scaleTickOf(state.uri, fallback: searchScaleTick),
                  );
                },
              ),
              GoRoute(
                path: 'updates',
                builder: (context, state) {
                  final query = state.uri.queryParameters;
                  String? kept(String key) {
                    final value = query[key];
                    if (value == null || value.isEmpty) return null;
                    return value;
                  }

                  return UnitUpdatesPage(
                    repoUuid: query['repo'] ?? '',
                    branch: query['branch'] ?? '',
                    compilable: query['compilable'] == '1',
                    auto: query['auto'] != '0',
                    tagsOnly: query['tags'] != '0',
                    commit: kept('commit'),
                    platform: kept('platform'),
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
                    icon: 'assets/icons/objects/brick.svg',
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
                path: 'info',
                builder: (context, state) =>
                    UnitInfoPage(uuid: state.pathParameters['uuid']!),
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
                    path: 'archives',
                    builder: (context, state) =>
                        UnitArchivesPage(uuid: state.pathParameters['uuid']!),
                  ),
                  GoRoute(
                    path: 'platforms',
                    builder: (context, state) =>
                        UnitPlatformsPage(uuid: state.pathParameters['uuid']!),
                  ),
                  GoRoute(
                    path: 'delete',
                    builder: (context, state) =>
                        UnitDeletePage(uuid: state.pathParameters['uuid']!),
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
        path: '/dashboards',
        builder: (context, state) => const DashboardsMenuPage(),
        routes: [
          GoRoute(
            path: 'search',
            builder: (context, state) => DashboardsPage(
              scope: scaleTickOf(state.uri, fallback: searchScaleTick),
            ),
          ),
          GoRoute(
            path: 'new',
            builder: (context, state) => const DashboardCreatePage(),
          ),
          GoRoute(
            path: 'type',
            builder: (context, state) => NamePickPage(
              title: dashText(
                AppScope.of(context).vault.language,
                'Тип',
                'Type',
              ),
              icon: 'assets/icons/objects/brick.svg',
              color: dashboardsColor,
              scope: scaleTickOf(state.uri),
              path: '/dashboards/type',
              paged: true,
              load: () async => [
                for (final type in panelTypes)
                  (id: type.value, label: type.label),
              ],
            ),
          ),
          GoRoute(
            path: ':uuid',
            builder: (context, state) =>
                DashboardPage(uuid: state.pathParameters['uuid']!),
            routes: [
              GoRoute(
                path: 'delete',
                builder: (context, state) =>
                    DashboardDeletePage(uuid: state.pathParameters['uuid']!),
              ),
              GoRoute(
                path: 'panels',
                builder: (context, state) => PanelsPage(
                  uuid: state.pathParameters['uuid']!,
                  scope: scaleTickOf(state.uri),
                ),
                routes: [
                  GoRoute(
                    path: 'new',
                    builder: (context, state) =>
                        PanelCreatePage(uuid: state.pathParameters['uuid']!),
                  ),
                  GoRoute(
                    path: ':pid',
                    builder: (context, state) => PanelPage(
                      dashboardUuid: state.pathParameters['uuid']!,
                      uuid: state.pathParameters['pid']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'nodes',
                        builder: (context, state) => PanelNodesPage(
                          dashboardUuid: state.pathParameters['uuid']!,
                          uuid: state.pathParameters['pid']!,
                          scope: scaleTickOf(state.uri),
                        ),
                        routes: [
                          GoRoute(
                            path: 'new',
                            builder: (context, state) => PanelNodeFormPage(
                              panelUuid: state.pathParameters['pid']!,
                              ioUuid: state.uri.queryParameters['io'] ?? '',
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
        ],
      ),
      GoRoute(
        path: '/library',
        builder: (context, state) => const LibraryMenuPage(),
        routes: [
          GoRoute(
            path: 'presentation',
            builder: (context, state) =>
                const LibraryMenuPage(open: LibraryOpen.presentation),
          ),
          GoRoute(
            path: 'about',
            builder: (context, state) =>
                const LibraryMenuPage(open: LibraryOpen.about),
          ),
          GoRoute(
            path: 'docs',
            builder: (context, state) => DocsPage(
              dir: state.uri.queryParameters['dir'] ?? '',
              doc: state.uri.queryParameters['doc'],
              scope: scaleTickOf(state.uri),
            ),
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

  /// The tip file of a cell on the screen that is open now, or null.
  String? _tipKey(BuildContext context, String id) {
    final library = Library.instance;
    if (!library.ready || !tipCellOk(id)) return null;
    final language = AppScope.of(context).vault.language;
    final screen = tipScreenOf(
      _router.routerDelegate.currentConfiguration.fullPath,
    );
    return library.tipKey(language, screen, id);
  }

  Future<void> _openTip(
    BuildContext context,
    String id,
    String title,
    Color color,
  ) async {
    final key = _tipKey(context, id);
    if (key == null) return;
    final language = AppScope.of(context).vault.language;
    final library = Library.instance;
    final text = await library.text(key);
    final tree = await library.docs(language);
    if (!context.mounted) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Закрыть подсказку',
      barrierColor: const Color(0x00000000),
      pageBuilder: (dialog, _, _) => Material(
        type: MaterialType.transparency,
        child: LibraryModal(
          title: title,
          color: color,
          source: text,
          docs: tree,
          onClose: () => Navigator.of(dialog).pop(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pepeunit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'OpenGost Type B',
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            for (final platform in TargetPlatform.values)
              platform: InstantPageTransitions(),
          },
        ),
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
      // One mosaic under the router, so it stays put while screens change.
      builder: (context, child) => HintHost(
        has: (cell, id) => _tipKey(cell, id) != null,
        open: _openTip,
        child: GrainBox(
          tile: sceneGrain,
          child: Stack(
            fit: StackFit.expand,
            children: [if (widget.background) const HiveBackground(), ?child],
          ),
        ),
      ),
    );
  }
}
