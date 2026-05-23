import 'package:equatable/equatable.dart';

class HomeState extends Equatable {
  final bool isLoading;
  final String? errorMessage;

  const HomeState({this.isLoading = false, this.errorMessage});

  factory HomeState.initial() => const HomeState();

  HomeState copyWith({bool? isLoading, String? errorMessage, bool resetError = false}) => HomeState(
    isLoading: isLoading ?? this.isLoading,
    errorMessage: resetError ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [isLoading, errorMessage];
}
