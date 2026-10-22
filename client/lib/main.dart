import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

import 'account/vault_store.dart';
import 'app_model.dart';
import 'app_scope.dart';
import 'features/home/home_page.dart';
import 'features/menu/placeholder_page.dart';
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
        path: '/:section',
        builder: (context, state) => PlaceholderPage(sectionId: state.pathParameters['section']!),
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
          filled: true,
          fillColor: hexFill,
          labelStyle: TextStyle(color: Color(0xFFA1A1AA)),
          border: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFA1A1AA))),
          enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFA1A1AA))),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF9800))),
        ),
      ),
      routerConfig: _router,
    );
  }
}
