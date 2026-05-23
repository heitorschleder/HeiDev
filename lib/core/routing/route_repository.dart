import '../../auth/presentation/routes/login_screen_route.dart';
import '../../auth/presentation/routes/signup_screen_route.dart';
import '../../expenses/presentation/routes/bill_templates_screen_route.dart';
import '../../expenses/presentation/routes/expense_form_screen_route.dart';
import '../../expenses/presentation/routes/expense_list_screen_route.dart';
import '../../home/presentation/routes/home_screen_route.dart';
import '../../income/presentation/routes/income_screen_route.dart';

abstract final class RouteRepository {
  static final loginScreen = LoginScreenRoute();
  static final signupScreen = SignupScreenRoute();
  static final homeScreen = HomeScreenRoute();
  static final expenseListScreen = ExpenseListScreenRoute();
  static final expenseFormScreen = ExpenseFormScreenRoute();
  static final billTemplatesScreen = BillTemplatesScreenRoute();
  static final incomeScreen = IncomeScreenRoute();
}
