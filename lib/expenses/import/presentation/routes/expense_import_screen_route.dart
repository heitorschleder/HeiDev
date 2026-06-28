import '../../../../core/routing/app_route_config.dart';
import '../screens/expense_import_screen.dart';

final class ExpenseImportScreenRoute extends AppNoPayloadRouteConfig {
  ExpenseImportScreenRoute()
    : super(name: 'ExpenseImportScreen', path: 'import', builder: () => const ExpenseImportScreen());
}
