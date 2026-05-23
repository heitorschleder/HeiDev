import 'package:flutter_test/flutter_test.dart';
import 'package:hei_dev/auth/data/repositories/auth_repository.dart';
import 'package:hei_dev/home/domain/logic/home_state.dart';
import 'package:hei_dev/home/domain/logic/home_view_model.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthRepository mockRepo;
  late HomeViewModel viewModel;

  setUp(() {
    mockRepo = _MockAuthRepository();
    viewModel = HomeViewModel(mockRepo);
  });
  tearDown(() => viewModel.onDisposed());

  group('initial state', () {
    test('isLoading is false', () => expect(viewModel.state.value.isLoading, isFalse));
    test('errorMessage is null', () => expect(viewModel.state.value.errorMessage, isNull));
  });

  group('init', () {
    test('state unchanged after init', () {
      viewModel.init();
      expect(viewModel.state.value, HomeState.initial());
    });
  });
}
