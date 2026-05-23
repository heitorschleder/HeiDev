import 'package:equatable/equatable.dart';

class SignupState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final bool emailConfirmationPending;

  const SignupState({
    this.isLoading = false,
    this.errorMessage,
    this.emailConfirmationPending = false,
  });

  factory SignupState.initial() => const SignupState();

  SignupState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? emailConfirmationPending,
    bool resetError = false,
  }) => SignupState(
    isLoading: isLoading ?? this.isLoading,
    errorMessage: resetError ? null : errorMessage ?? this.errorMessage,
    emailConfirmationPending: emailConfirmationPending ?? this.emailConfirmationPending,
  );

  @override
  List<Object?> get props => [isLoading, errorMessage, emailConfirmationPending];
}
