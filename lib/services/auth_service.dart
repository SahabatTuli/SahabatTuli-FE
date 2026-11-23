import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
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

  Future<void> signInWithGoogle() async {
    try {
      final callbackUrl = kIsWeb
          ? Uri.base.origin
          : '${ApiClient.baseUrl}/api/auth/callback/google';

      final response = await ApiClient.dio.post(
        '/api/auth/sign-in/social',
        data: {
          'provider': 'google',
          'callbackURL': callbackUrl,
        },
      );

      final data = response.data is Map ? Map.from(response.data as Map) : {};
      final authUrl = data['url']?.toString() ?? '';

      if (authUrl.isEmpty) {
        throw Exception('URL Google OAuth tidak diterima dari server');
      }

      final uri = Uri.parse(authUrl);
      final launched = await launchUrl(
        uri,
        mode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.externalApplication,
        webOnlyWindowName: '_self',
      );

      if (!launched) {
        throw Exception('Gagal membuka halaman login Google');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Gagal memulai login Google';
      throw Exception(message);
    }
  }

  Future<void> requestPasswordReset({required String email}) async {
    final redirectTo = kIsWeb
        ? '${Uri.base.origin}/reset-password'
        : '${ApiClient.baseUrl}/reset-password';

    try {
      await ApiClient.dio.post(
        '/api/auth/request-password-reset',
        data: {
          'email': email.trim(),
          'redirectTo': redirectTo,
        },
      );
    } on DioException catch (e) {
      // Fallback untuk versi Better Auth yang memakai endpoint /forget-password
      if (e.response?.statusCode == 404) {
        try {
          await ApiClient.dio.post(
            '/api/auth/forget-password',
            data: {
              'email': email.trim(),
              'redirectTo': redirectTo,
            },
          );
          return;
        } on DioException catch (fallbackErr) {
          final data = fallbackErr.response?.data;
          final message = (data is Map && data['message'] != null)
              ? data['message'].toString()
              : 'Gagal mengirim tautan reset password';
          throw Exception(message);
        }
      }

      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Gagal mengirim tautan reset password';
      throw Exception(message);
    }
  }

  Future<void> resetPassword({
    required String newPassword,
    required String token,
  }) async {
    try {
      await ApiClient.dio.post(
        '/api/auth/reset-password',
        data: {
          'newPassword': newPassword,
          'token': token.trim(),
        },
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Token tidak valid atau sudah kedaluwarsa';
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