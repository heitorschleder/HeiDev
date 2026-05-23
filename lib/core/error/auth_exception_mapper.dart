import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_auth_exception.dart';

abstract final class AuthExceptionMapper {
  static AppAuthException fromAuth(AuthException exception) {
    final msg = exception.message.toLowerCase();
    if (msg.contains('invalid login credentials') || msg.contains('invalid email or password')) {
      return const AppAuthException(
        message: 'E-mail ou senha incorretos.',
        reason: AppAuthExceptionReason.invalidCredentials,
      );
    }
    if (msg.contains('user already registered')) {
      return const AppAuthException(
        message: 'Este e-mail já está em uso.',
        reason: AppAuthExceptionReason.emailAlreadyInUse,
      );
    }
    if (msg.contains('password should be at least')) {
      return const AppAuthException(
        message: 'A senha deve ter pelo menos 6 caracteres.',
        reason: AppAuthExceptionReason.weakPassword,
      );
    }
    return AppAuthException(message: exception.message, reason: AppAuthExceptionReason.unknown);
  }
}
