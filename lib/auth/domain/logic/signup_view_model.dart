import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_auth_exception.dart';
import '../../data/repositories/auth_repository.dart';
import 'signup_state.dart';

@injectable
final class SignupViewModel {
  final AuthRepository _authRepository;

  SignupViewModel(this._authRepository);

  final ValueNotifier<SignupState> _state = ValueNotifier(SignupState.initial());

  ValueListenable<SignupState> get state => _state;

  void init() {}

  Future<void> signUp({required String email, required String password}) async {
    _state.value = _state.value.copyWith(isLoading: true, resetError: true);
    try {
      final emailConfirmationPending = await _authRepository.signUp(email: email, password: password);
      _state.value = _state.value.copyWith(isLoading: false, emailConfirmationPending: emailConfirmationPending);
      // If not pending → GoRouter redirect fires automatically
    } on AppAuthException catch (e) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: 'Erro inesperado. Tente novamente.');
    }
  }

  void onDisposed() => _state.dispose();
}
