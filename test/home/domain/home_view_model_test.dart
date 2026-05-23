import 'package:flutter_test/flutter_test.dart';
import 'package:hei_dev/auth/data/repositories/auth_repository.dart';
import 'package:hei_dev/expenses/data/models/expense_model.dart';
import 'package:hei_dev/home/data/models/dashboard_data.dart';
import 'package:hei_dev/home/data/repositories/home_repository.dart';
import 'package:hei_dev/home/domain/logic/home_view_model.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockDashboardRepository extends Mock implements DashboardRepository {}

const _emptyDashboard = DashboardData(
  totalIncome: 0,
  totalExpenses: 0,
  totalPaid: 0,
  totalOpen: 0,
  balance: 0,
  pctCommitted: 0,
  dueSoon: <ExpenseModel>[],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthRepository mockAuth;
  late _MockDashboardRepository mockDash;
  late HomeViewModel viewModel;

  setUp(() {
    mockAuth = _MockAuthRepository();
    mockDash = _MockDashboardRepository();
    viewModel = HomeViewModel(mockAuth, mockDash);
  });
  tearDown(() => viewModel.onDisposed());

  group('initial state (before init)', () {
    test('isLoading is true', () => expect(viewModel.state.value.isLoading, isTrue));
    test('errorMessage is null', () => expect(viewModel.state.value.errorMessage, isNull));
    test('dashboard is null', () => expect(viewModel.state.value.dashboard, isNull));
  });

  group('init', () {
    test('sets dashboard and clears loading on success', () async {
      when(() => mockDash.fetchDashboard(month: any(named: 'month'))).thenAnswer((_) async => _emptyDashboard);

      await viewModel.init();

      expect(viewModel.state.value.isLoading, isFalse);
      expect(viewModel.state.value.dashboard, isNotNull);
      expect(viewModel.state.value.errorMessage, isNull);
    });

    test('sets errorMessage on failure', () async {
      when(() => mockDash.fetchDashboard(month: any(named: 'month'))).thenThrow(Exception('fail'));

      await viewModel.init();

      expect(viewModel.state.value.isLoading, isFalse);
      expect(viewModel.state.value.errorMessage, isNotNull);
    });
  });
}
