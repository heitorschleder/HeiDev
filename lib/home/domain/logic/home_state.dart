import 'package:equatable/equatable.dart';

import '../../data/models/dashboard_data.dart';

class HomeState extends Equatable {
  final bool isLoading;
  final DashboardData? dashboard;
  final String? errorMessage;

  const HomeState({this.isLoading = false, this.dashboard, this.errorMessage});

  factory HomeState.initial() => const HomeState(isLoading: true);

  HomeState copyWith({
    bool? isLoading,
    DashboardData? dashboard,
    String? errorMessage,
    bool resetError = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      dashboard: dashboard ?? this.dashboard,
      errorMessage: resetError ? null : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, dashboard, errorMessage];
}
