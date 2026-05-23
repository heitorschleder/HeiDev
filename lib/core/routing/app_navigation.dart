import 'app_route_config.dart';

class AppNavigation<T> {
  final AppRouteConfig config;
  final T? extra;
  final Map<String, Object> pathParameters;
  final Map<String, Object> queryParameters;

  const AppNavigation({
    required this.config,
    this.extra,
    this.pathParameters = const {},
    this.queryParameters = const {},
  });
}
