import '../../../core/routing/routing.dart';
import '../screens/expense_list_screen.dart';

final class ExpenseListScreenRoute extends AppNoPayloadRouteConfig {
  ExpenseListScreenRoute()
    : super(name: 'ExpenseListScreen', path: '/expenses', builder: () => const ExpenseListScreen());
}
