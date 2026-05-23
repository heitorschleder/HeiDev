import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../error/exception_mapper.dart';
import 'auth_interceptor.dart';
import 'network_config.dart';

abstract class AppHttpClient {
  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters});
  Future<T> post<T>(String path, {Object? data});
  Future<T> put<T>(String path, {Object? data});
  Future<T> delete<T>(String path);
}

@Singleton(as: AppHttpClient)
class DioHttpClient implements AppHttpClient {
  late final Dio _dio;

  DioHttpClient(NetworkConfig config, AuthInterceptor authInterceptor) {
    const timeout = Duration(seconds: 30);
    _dio =
        Dio(BaseOptions(baseUrl: config.baseUrl, connectTimeout: timeout, receiveTimeout: timeout, sendTimeout: timeout))
          ..interceptors.add(authInterceptor);
  }

  @override
  Future<T> get<T>(String path, {Map<String, dynamic>? queryParameters}) =>
      _makeRequest(() => _dio.get<T>(path, queryParameters: queryParameters));

  @override
  Future<T> post<T>(String path, {Object? data}) => _makeRequest(() => _dio.post<T>(path, data: data));

  @override
  Future<T> put<T>(String path, {Object? data}) => _makeRequest(() => _dio.put<T>(path, data: data));

  @override
  Future<T> delete<T>(String path) => _makeRequest(() => _dio.delete<T>(path));

  Future<T> _makeRequest<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (e) {
      throw ExceptionMapper.fromDio(e);
    }
  }
}
