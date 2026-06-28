part of '../app_router.dart';

final StatefulShellRoute _shellRoute = StatefulShellRoute.indexedStack(
  builder: (_, _, navigationShell) => AppShell(navigationShell: navigationShell),
  branches: [
    StatefulShellBranch(routes: [RouteRepository.homeScreen.toGoRoute()]),
    StatefulShellBranch(
      routes: [
        RouteRepository.expenseListScreen.toGoRoute(
          childrenRoutes: [
            RouteRepository.expenseFormScreen.toGoRoute(),
            RouteRepository.billTemplatesScreen.toGoRoute(),
            RouteRepository.expenseImportScreen.toGoRoute(),
          ],
        ),
      ],
    ),
    StatefulShellBranch(routes: [RouteRepository.incomeScreen.toGoRoute()]),
  ],
);
