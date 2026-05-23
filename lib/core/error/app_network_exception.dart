import 'app_exception.dart';

enum AppNetworkExceptionReason { noInternet, timeout, serverError, unauthorized, notFound, unknown }

final class AppNetworkException extends AppException {
  final AppNetworkExceptionReason reason;
  final int? statusCode;

  const AppNetworkException({
    required String message,
    required this.reason,
    this.statusCode,
  }) : super(message);
}
