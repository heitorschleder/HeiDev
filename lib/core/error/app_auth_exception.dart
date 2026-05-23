import 'app_exception.dart';

enum AppAuthExceptionReason { invalidCredentials, emailAlreadyInUse, weakPassword, unknown }

final class AppAuthException extends AppException {
  final AppAuthExceptionReason reason;

  const AppAuthException({required String message, required this.reason}) : super(message);
}
