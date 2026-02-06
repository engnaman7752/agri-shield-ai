import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:farmer_app/core/constants/app_constants.dart';

class DioClient {
  late Dio _dio;
  static const String serverIpKey = 'server_ip';
  static const String defaultIp = '172.22.9.203'; // Fallback IP

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiBaseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
        contentType: 'application/json',
      ),
    );

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        
        // Dynamic base URL from saved IP
        final savedIp = prefs.getString(serverIpKey) ?? defaultIp;
        options.baseUrl = 'http://$savedIp:8085/api/';
        
        final token = prefs.getString(AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;

  /// Update server IP at runtime
  static Future<void> setServerIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(serverIpKey, ip);
  }

  /// Get current server IP
  static Future<String> getServerIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(serverIpKey) ?? defaultIp;
  }
}
