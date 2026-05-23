import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../app_context.dart';
import 'app_navigation.dart';
import 'app_route_config.dart';
import 'route_repository.dart';

part 'routes/home_routes.dart';

abstract final class AppRouter {
  static late GoRouter _router;

  @visibleForTesting
  static set router(GoRouter router) => _router = router;

  static GoRouter init(AppRouteConfig initialLocation) {
    return _router = GoRouter(
      routes: _routes,
      initialLocation: initialLocation.path,
      navigatorKey: AppContext.navigatorKey,
    );
  }

  static Future<T?> push<T>(AppNavigation route) async {
    return _router.pushNamed<T>(
      route.config.name,
      pathParameters: _toStringMap(route.pathParameters),
      queryParameters: _toStringMap(route.queryParameters),
      extra: route.extra,
    );
  }

  static void replaceRouteStack(AppNavigation route) {
    _router.goNamed(
      route.config.name,
      pathParameters: _toStringMap(route.pathParameters),
      queryParameters: _toStringMap(route.queryParameters),
      extra: route.extra,
    );
  }

  static Future<T?> pushReplacement<T>(AppNavigation route) async {
    return _router.pushReplacementNamed<T>(
      route.config.name,
      pathParameters: _toStringMap(route.pathParameters),
      queryParameters: _toStringMap(route.queryParameters),
      extra: route.extra,
    );
  }

  static void pop<T>([T? result]) {
    if (canPop()) _router.pop<T>(result);
  }

  static bool canPop() => _router.canPop();

  static Map<String, String> _toStringMap(Map<String, Object> params) =>
      params.map((key, value) => MapEntry(key, value.toString()));
}
