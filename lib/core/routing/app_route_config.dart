import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_navigation.dart';

sealed class AppRouteConfig {
  final String name;
  final String path;

  const AppRouteConfig({required this.name, required this.path});

  GoRoute toGoRoute({List<GoRoute> childrenRoutes = const []});
}

abstract class AppPayloadBoundRouteConfig<T> extends AppRouteConfig {
  final Widget Function(T payload) builder;
  final T Function(GoRouterState state) payloadParser;

  const AppPayloadBoundRouteConfig({
    required super.name,
    required super.path,
    required this.builder,
    required this.payloadParser,
  });

  AppNavigation<T> makeNavigation(T payload);

  @override
  GoRoute toGoRoute({List<GoRoute> childrenRoutes = const []}) {
    return GoRoute(
      name: name,
      path: path,
      pageBuilder: (_, state) {
        final payload = payloadParser(state);
        return MaterialPage(key: ValueKey((name, payload)), name: name, child: builder(payload));
      },
      routes: childrenRoutes,
    );
  }
}

abstract class AppNoPayloadRouteConfig extends AppRouteConfig {
  final Widget Function() builder;

  const AppNoPayloadRouteConfig({required super.name, required super.path, required this.builder});

  AppNavigation<void> makeNavigation() => AppNavigation(config: this, extra: null);

  @override
  GoRoute toGoRoute({List<GoRoute> childrenRoutes = const []}) {
    return GoRoute(
      name: name,
      path: path,
      builder: (_, _) => builder(),
      routes: childrenRoutes,
    );
  }
}
