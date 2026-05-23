import 'package:dio/dio.dart';

import 'app_network_exception.dart';

abstract final class ExceptionMapper {
  static AppNetworkException fromDio(DioException exception) {
    return switch (exception.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const AppNetworkException(
        message: 'Tempo de conexão esgotado.',
        reason: AppNetworkExceptionReason.timeout,
      ),
      DioExceptionType.connectionError => const AppNetworkException(
        message: 'Sem conexão com a internet.',
        reason: AppNetworkExceptionReason.noInternet,
      ),
      DioExceptionType.badResponse => _fromStatusCode(exception.response?.statusCode),
      _ => const AppNetworkException(message: 'Erro inesperado.', reason: AppNetworkExceptionReason.unknown),
    };
  }

  static AppNetworkException _fromStatusCode(int? code) {
    return switch (code) {
      401 => AppNetworkException(
        message: 'Não autorizado.',
        reason: AppNetworkExceptionReason.unauthorized,
        statusCode: code,
      ),
      404 => AppNetworkException(
        message: 'Recurso não encontrado.',
        reason: AppNetworkExceptionReason.notFound,
        statusCode: code,
      ),
      _ => AppNetworkException(
        message: 'Erro no servidor (código $code).',
        reason: AppNetworkExceptionReason.serverError,
        statusCode: code,
      ),
    };
  }
}
