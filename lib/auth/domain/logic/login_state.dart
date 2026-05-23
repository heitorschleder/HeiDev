import 'package:equatable/equatable.dart';

class LoginState extends Equatable {
  final bool isLoading;
  final String? errorMessage;

  const LoginState({this.isLoading = false, this.errorMessage});

  factory LoginState.initial() => const LoginState();

  LoginState copyWith({bool? isLoading, String? errorMessage, bool resetError = false}) => LoginState(
    isLoading: isLoading ?? this.isLoading,
    errorMessage: resetError ? null : errorMessage ?? this.errorMessage,
  );

  @override
  List<Object?> get props => [isLoading, errorMessage];
}
