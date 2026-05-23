import 'package:flutter_test/flutter_test.dart';
import 'package:hei_dev/auth/data/repositories/auth_repository.dart';
import 'package:hei_dev/auth/domain/logic/login_view_model.dart';
import 'package:hei_dev/core/error/app_auth_exception.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthRepository mockRepo;
  late LoginViewModel viewModel;

  setUp(() {
    mockRepo = _MockAuthRepository();
    viewModel = LoginViewModel(mockRepo);
  });
  tearDown(() => viewModel.onDisposed());

  group('initial state', () {
    test('isLoading is false', () => expect(viewModel.state.value.isLoading, isFalse));
    test('errorMessage is null', () => expect(viewModel.state.value.errorMessage, isNull));
  });

  group('signIn', () {
    test('shows loading then clears on success', () async {
      when(
        () => mockRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});

      await viewModel.signIn(email: 'test@test.com', password: '123456');

      expect(viewModel.state.value.errorMessage, isNull);
    });

    test('sets errorMessage on AppAuthException', () async {
      const error = AppAuthException(
        message: 'E-mail ou senha incorretos.',
        reason: AppAuthExceptionReason.invalidCredentials,
      );
      when(
        () => mockRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(error);

      await viewModel.signIn(email: 'bad@test.com', password: 'wrong');

      expect(viewModel.state.value.isLoading, isFalse);
      expect(viewModel.state.value.errorMessage, equals('E-mail ou senha incorretos.'));
    });

    test('sets generic errorMessage on unexpected exception', () async {
      when(
        () => mockRepo.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('unexpected'));

      await viewModel.signIn(email: 'test@test.com', password: '123456');

      expect(viewModel.state.value.isLoading, isFalse);
      expect(viewModel.state.value.errorMessage, isNotNull);
    });
  });
}
