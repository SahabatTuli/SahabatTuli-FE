import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_client_stub.dart' if (dart.library.html) 'api_client_web.dart';

class ApiClient {
  static const String baseUrl = 'https://api.sahabattuli.com';
  static const String _cookieKey = 'better_auth_cookie';

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (!kIsWeb) 'Origin': baseUrl,
      },
    ),
  );

  static Future<void> init() async {
    configurePlatformDio(dio);

    if (kIsWeb) return;

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final cookie = prefs.getString(_cookieKey);
          if (cookie != null && cookie.isNotEmpty) {
            options.headers['Cookie'] = cookie;
          }
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          final setCookies = response.headers['set-cookie'];
          if (setCookies != null && setCookies.isNotEmpty) {
            final rawCookie = setCookies
                .map((c) => c.split(';').first)
                .join('; ');
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_cookieKey, rawCookie);
          }
          return handler.next(response);
        },
      ),
    );
  }

  static Future<String?> getSavedCookie() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cookieKey);
  }

  static Future<void> clearCookie() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cookieKey);
  }
}