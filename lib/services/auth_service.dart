import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'api_client.dart';

class AuthResponse {
  final String id;
  final String name;
  final String email;
  final String? image;

  AuthResponse({
    required this.id,
    required this.name,
    required this.email,
    this.image,
  });

  factory AuthResponse.from(dynamic data) {
    if (data is AuthResponse) return data;
    final map = data is Map ? Map.from(data) : {};
    return AuthResponse(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? 'User',
      email: map['email']?.toString() ?? '',
      image: map['image']?.toString(),
    );
  }
}

class AuthService {
  Future signInWithEmail({
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
      return Map.from(response.data as Map);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Login gagal, periksa email & password';
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      } else if (e.response?.statusCode != null) {
        message =
            'Error ${e.response?.statusCode}: ${e.response?.statusMessage}';
      } else {
        message = 'Koneksi gagal: ${e.message}';
      }
      throw Exception(message);
    }
  }

  Future signUpWithEmail({
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
      return Map.from(response.data as Map);
    } on DioException catch (e) {
      final data = e.response?.data;
      String message = 'Registrasi gagal, coba lagi';
      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      } else if (e.response?.statusCode != null) {
        message =
            'Error ${e.response?.statusCode}: ${e.response?.statusMessage}';
      } else {
        message = 'Koneksi gagal: ${e.message}';
      }
      throw Exception(message);
    }
  }

  Future getSession() async {
    if (!kIsWeb) {
      final cookie = await ApiClient.getSavedCookie();
      if (cookie == null || cookie.isEmpty) return null;
    }

    try {
      final response = await ApiClient.dio.get('/api/auth/get-session');
      if (response.data == null) return null;

      final data = Map.from(response.data as Map);
      if (data['user'] == null) return null;

      return data;
    } on DioException {
      return null;
    }
  }

  Future<void> updateUserName(String newName) async {
    try {
      await ApiClient.dio.post(
        '/api/auth/update-user',
        data: {
          'name': newName.trim(),
        },
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Gagal memperbarui username';
      throw Exception(message);
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