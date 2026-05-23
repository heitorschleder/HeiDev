import '../../../core/routing/routing.dart';
import '../screens/income_screen.dart';

final class IncomeScreenRoute extends AppNoPayloadRouteConfig {
  IncomeScreenRoute() : super(name: 'IncomeScreen', path: '/income', builder: () => const IncomeScreen());
}
