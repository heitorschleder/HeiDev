import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/app_context.dart';
import 'core/l10n/app_localizations/app_localizations.dart';
import 'core/l10n/l10n.dart';
import 'core/routing/app_router.dart';
import 'core/routing/route_repository.dart';
import 'core/theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = AppRouter.init(RouteRepository.homeScreen);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      scaffoldMessengerKey: AppContext.snackBarKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      builder: (_, child) => LocalizationScope(child: child ?? const SizedBox.shrink()),
    );
  }
}
