import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../../../auth/data/repositories/auth_repository.dart';
import '../../../core/error/app_auth_exception.dart';
import '../../../core/error/app_network_exception.dart';
import '../../data/repositories/home_repository.dart';
import 'home_state.dart';

@injectable
final class HomeViewModel {
  final AuthRepository _authRepository;
  final DashboardRepository _dashboardRepository;

  HomeViewModel(this._authRepository, this._dashboardRepository);

  final ValueNotifier<HomeState> _state = ValueNotifier(HomeState.initial());

  ValueListenable<HomeState> get state => _state;

  String? get userEmail => _authRepository.currentUserEmail;

  Future<void> init() async {
    _state.value = HomeState.initial();
    try {
      final dashboard = await _dashboardRepository.fetchDashboard(
        month: DateTime(DateTime.now().year, DateTime.now().month),
      );
      _state.value = _state.value.copyWith(isLoading: false, dashboard: dashboard, resetError: true);
    } on AppNetworkException catch (e) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: 'Erro ao carregar resumo.');
    }
  }

  Future<void> signOut() async {
    _state.value = _state.value.copyWith(isLoading: true, resetError: true);
    try {
      await _authRepository.signOut();
    } on AppAuthException catch (e) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      _state.value = _state.value.copyWith(isLoading: false, errorMessage: 'Erro inesperado ao sair.');
    }
  }

  void onDisposed() => _state.dispose();
}
