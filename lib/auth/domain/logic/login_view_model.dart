import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../core/error/app_auth_exception.dart';
import '../../data/repositories/auth_repository.dart';
import 'login_state.dart';

@injectable
final class LoginViewModel {
  final AuthRepository _authRepository;

  LoginViewModel(this._authRepository);

  final ValueNotifier<LoginState> _state = ValueNotifier(LoginState.initial());

  ValueListenable<LoginState> get state => _state;

  void init() {}

  Future<void> signIn({required String email, required String password}) async {
    _state.value = _state.value.copyWith(isLoading: true, resetError: true);
    try {
      await _authRepository.signIn(email: email, password: password);
      // GoRouter redirect fires automatically when auth state changes
    } on AppAuthException catch (e) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: 'Erro inesperado. Tente novamente.');
    }
  }

  void onDisposed() => _state.dispose();
}
