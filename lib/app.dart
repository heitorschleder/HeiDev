import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/app_context.dart';
import 'core/auth/auth_service.dart';
import 'core/di/injectable.dart';
import 'core/l10n/app_localizations/app_localizations.dart';
import 'core/l10n/l10n.dart';
import 'core/routing/app_router.dart';
import 'core/routing/go_router_refresh_stream.dart';
import 'core/routing/route_repository.dart';
import 'core/theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router;
  late final GoRouterRefreshStream _authRefresh;

  @override
  void initState() {
    super.initState();
    final authService = getIt<AuthService>();
    _authRefresh = GoRouterRefreshStream(authService.authStateChanges);
    _router = AppRouter.init(
      RouteRepository.loginScreen,
      redirect: (context, state) {
        final isLoggedIn = authService.isAuthenticated;
        final location = state.matchedLocation;
        final isOnAuth = location.startsWith('/login') || location.startsWith('/signup');
        if (!isLoggedIn && !isOnAuth) return RouteRepository.loginScreen.path;
        if (isLoggedIn && isOnAuth) return RouteRepository.homeScreen.path;
        return null;
      },
      refreshListenable: _authRefresh,
    );
  }

  @override
  void dispose() {
    _authRefresh.dispose();
    _router.dispose();
    super.dispose();
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
