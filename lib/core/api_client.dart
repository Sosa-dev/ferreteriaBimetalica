import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://68.211.144.188/api/',
  //
);

class ApiClient {
  bool _sessionExpirationHandled = false;

  ApiClient._({
    Dio? client,
    Future<String?> Function()? readToken,
    Future<void> Function()? removeToken,
  }) : dio =
           client ??
           Dio(
             BaseOptions(
               baseUrl: '${Uri.parse(apiBaseUrl).origin}/',
               connectTimeout: const Duration(seconds: 12),
               receiveTimeout: const Duration(seconds: 20),
               headers: const {'Accept': 'application/json'},
             ),
           ),
       _readToken = readToken ?? _readStoredToken,
       _removeToken = removeToken ?? _removeStoredToken {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final configuredPath = Uri.parse(apiBaseUrl).path;
          final prefix = configuredPath == '/'
              ? ''
              : configuredPath.replaceAll(RegExp(r'/+$'), '');
          if (prefix.isNotEmpty && !options.path.startsWith('$prefix/')) {
            options.path =
                '$prefix/${options.path.replaceFirst(RegExp(r'^/+'), '')}';
          }
          if (_isPublicRequest(options.path)) {
            handler.next(options);
            return;
          }
          final token = await _readToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              error.requestOptions.headers['Authorization'] != null &&
              !_sessionExpirationHandled) {
            _sessionExpirationHandled = true;
            await clearToken();
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient instance = ApiClient._();
  factory ApiClient.forTesting({
    required Dio dio,
    required Future<String?> Function() readToken,
    required Future<void> Function() removeToken,
  }) =>
      ApiClient._(client: dio, readToken: readToken, removeToken: removeToken);

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  final Dio dio;
  final Future<String?> Function() _readToken;
  final Future<void> Function() _removeToken;
  void Function()? onUnauthorized;

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
    _sessionExpirationHandled = false;
  }

  Future<void> clearToken() => _removeToken();

  static Future<String?> _readStoredToken() => _storage.read(key: 'jwt_token');

  static Future<void> _removeStoredToken() => _storage.delete(key: 'jwt_token');

  bool _isPublicRequest(String path) =>
      path.endsWith('/auth/login') ||
      path.endsWith('/usuarios/registro') ||
      path.endsWith('/catalogo/productos') ||
      path.endsWith('/pedidos/invitado') ||
      path.endsWith('/pedidos/consulta') ||
      path.endsWith('/pedidos/consulta/factura');

  String errorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['detail'] != null) {
        final detail = data['detail'];
        if (detail is String) return detail;
        if (detail is List) {
          return detail
              .map((item) => item is Map ? item['msg'] : item.toString())
              .join('\n');
        }
      }
      if (error.response?.statusCode == 401) {
        return 'La sesión venció. Inicia sesión nuevamente.';
      }
      if (error.response?.statusCode == 429) {
        return 'Has realizado demasiadas consultas. Intenta de nuevo más tarde.';
      }
      if (error.response?.statusCode == 403) {
        return 'Tu usuario no tiene permisos para esta acción.';
      }
      if ((error.response?.statusCode ?? 0) >= 500) {
        return 'No se pudo completar la solicitud. Intenta de nuevo más tarde.';
      }
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError) {
        return 'No se pudo conectar con el servicio. Verifica tu conexión e inténtalo nuevamente.';
      }
    }
    return 'Ocurrió un error inesperado. Intenta nuevamente.';
  }
}
