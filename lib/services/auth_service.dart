import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'api_client.dart';

typedef AuthResponse = Map<String, dynamic>;

class AuthService {
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/api/auth/sign-in/email',
        data: {
          'email': email.trim(),
          'password': password,
        },
      );
      return AuthResponse.from(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Login gagal, periksa email & password';
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      } else if (e.response?.statusCode != null) {
        message = 'Error ${e.response?.statusCode}: ${e.response?.statusMessage}';
      } else {
        message = 'Koneksi gagal: ${e.message}';
      }
      throw Exception(message);
    }
  }

  Future<AuthResponse> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.dio.post(
        '/api/auth/sign-up/email',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        },
      );
      return AuthResponse.from(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Registrasi gagal, coba lagi';
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      } else if (e.response?.statusCode != null) {
        message = 'Error ${e.response?.statusCode}: ${e.response?.statusMessage}';
      } else {
        message = 'Koneksi gagal: ${e.message}';
      }
      throw Exception(message);
    }
  }

  Future<AuthResponse?> getSession() async {
    if (!kIsWeb) {
      final cookie = await ApiClient.getSavedCookie();
      if (cookie == null || cookie.isEmpty) return null;
    }

    try {
      final response = await ApiClient.dio.get('/api/auth/get-session');
      if (response.data == null) return null;

      final data = AuthResponse.from(response.data);
      if (data['user'] == null) return null;

      return data;
    } on DioException {
      return null;
    }
  }

  Future<void> signOut() async {
    try {
      await ApiClient.dio.post('/api/auth/sign-out');
    } finally {
      await ApiClient.clearCookie();
    }
  }
}