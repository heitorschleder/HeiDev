import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hei_dev/core/app_context.dart';
import 'package:hei_dev/core/l10n/app_localizations/app_localizations.dart';
import 'package:hei_dev/core/l10n/l10n.dart';
import 'package:hei_dev/core/routing/app_router.dart';

class AppWidgetTestMaterialApp extends StatefulWidget {
  final Widget child;
  final bool useRouter;
  final Locale? locale;

  const AppWidgetTestMaterialApp({super.key, required this.child, this.locale}) : useRouter = false;

  const AppWidgetTestMaterialApp.router({super.key, required this.child, this.locale}) : useRouter = true;

  @override
  State<AppWidgetTestMaterialApp> createState() => _AppWidgetTestMaterialAppState();
}

class _AppWidgetTestMaterialAppState extends State<AppWidgetTestMaterialApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final home = GoRoute(path: '/', builder: (_, _) => widget.child);
    _router = GoRouter(navigatorKey: AppContext.navigatorKey, routes: [home], initialLocation: '/');
    AppRouter.router = _router;
  }

  @override
  Widget build(BuildContext context) {
    const delegates = AppLocalizations.localizationsDelegates;
    const supported = AppLocalizations.supportedLocales;
    if (widget.useRouter) {
      return MaterialApp.router(
        routerConfig: _router,
        localizationsDelegates: delegates,
        supportedLocales: supported,
        locale: widget.locale,
        builder: (_, child) => LocalizationScope(child: child ?? const SizedBox.shrink()),
      );
    }
    return MaterialApp(
      navigatorKey: AppContext.navigatorKey,
      localizationsDelegates: delegates,
      supportedLocales: supported,
      locale: widget.locale,
      home: LocalizationScope(child: widget.child),
    );
  }
}
