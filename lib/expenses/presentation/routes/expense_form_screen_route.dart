import '../../../core/routing/routing.dart';
import '../../data/models/expense_model.dart';
import '../screens/expense_form_screen.dart';

final class ExpenseFormScreenRoute extends AppPayloadBoundRouteConfig<ExpenseModel?> {
  ExpenseFormScreenRoute()
    : super(
        name: 'ExpenseFormScreen',
        path: 'form',
        builder: (expense) => ExpenseFormScreen(expense: expense),
        payloadParser: (state) => state.extra as ExpenseModel?,
      );

  @override
  AppNavigation<ExpenseModel?> makeNavigation(ExpenseModel? payload) => AppNavigation(config: this, extra: payload);
}
