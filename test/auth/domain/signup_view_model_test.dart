import 'package:flutter_test/flutter_test.dart';
import 'package:hei_dev/auth/data/repositories/auth_repository.dart';
import 'package:hei_dev/auth/domain/logic/signup_view_model.dart';
import 'package:hei_dev/core/error/app_auth_exception.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockAuthRepository mockRepo;
  late SignupViewModel viewModel;

  setUp(() {
    mockRepo = _MockAuthRepository();
    viewModel = SignupViewModel(mockRepo);
  });
  tearDown(() => viewModel.onDisposed());

  group('initial state', () {
    test('isLoading is false', () => expect(viewModel.state.value.isLoading, isFalse));
    test('errorMessage is null', () => expect(viewModel.state.value.errorMessage, isNull));
    test('emailConfirmationPending is false', () => expect(viewModel.state.value.emailConfirmationPending, isFalse));
  });

  group('signUp', () {
    test('sets emailConfirmationPending false when session created', () async {
      when(
        () => mockRepo.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => false);

      await viewModel.signUp(email: 'test@test.com', password: '123456');

      expect(viewModel.state.value.isLoading, isFalse);
      expect(viewModel.state.value.emailConfirmationPending, isFalse);
    });

    test('sets emailConfirmationPending true when confirmation required', () async {
      when(
        () => mockRepo.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => true);

      await viewModel.signUp(email: 'test@test.com', password: '123456');

      expect(viewModel.state.value.isLoading, isFalse);
      expect(viewModel.state.value.emailConfirmationPending, isTrue);
    });

    test('sets errorMessage on AppAuthException', () async {
      const error = AppAuthException(
        message: 'Este e-mail já está em uso.',
        reason: AppAuthExceptionReason.emailAlreadyInUse,
      );
      when(
        () => mockRepo.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(error);

      await viewModel.signUp(email: 'used@test.com', password: '123456');

      expect(viewModel.state.value.isLoading, isFalse);
      expect(viewModel.state.value.errorMessage, equals('Este e-mail já está em uso.'));
    });

    test('sets generic errorMessage on unexpected exception', () async {
      when(
        () => mockRepo.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(Exception('unexpected'));

      await viewModel.signUp(email: 'test@test.com', password: '123456');

      expect(viewModel.state.value.isLoading, isFalse);
      expect(viewModel.state.value.errorMessage, isNotNull);
    });
  });
}
