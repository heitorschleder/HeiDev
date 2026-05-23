import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/data/repositories/auth_repository.dart';
import '../../../core/error/app_auth_exception.dart';
import 'home_state.dart';

@injectable
final class HomeViewModel {
  final AuthRepository _authRepository;

  HomeViewModel(this._authRepository);

  final ValueNotifier<HomeState> _state = ValueNotifier(HomeState.initial());

  ValueListenable<HomeState> get state => _state;

  String? get userEmail => _authRepository.currentUserEmail;

  void init() {}

  Future<void> signOut() async {
    _state.value = _state.value.copyWith(isLoading: true, resetError: true);
    try {
      await _authRepository.signOut();
      // GoRouter redirect handles navigation back to login automatically
    } on AppAuthException catch (e) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: 'Erro inesperado ao sair.');
    }
  }

  void onDisposed() => _state.dispose();
}
