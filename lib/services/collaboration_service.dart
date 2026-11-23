import 'package:dio/dio.dart';
import 'api_client.dart';

class CollaborationService {
  Map _normalizeRoom(Map raw) {
    final host = raw['host'] is Map ? Map.from(raw['host'] as Map) : {};
    return {
      'id': raw['id']?.toString() ?? '',
      'title': raw['title']?.toString() ?? 'Untitled Room',
      'status': raw['status']?.toString() ?? 'ACTIVE',
      'hostId': raw['hostId']?.toString() ?? host['id']?.toString() ?? '',
      'creator': host['name']?.toString() ??
          raw['creatorName']?.toString() ??
          'Unknown',
      'participantCount': raw['participantCount'] ??
          (raw['_count'] is Map ? raw['_count']['participants'] : 1),
      'createdAt': raw['createdAt']?.toString() ?? '',
      'endedAt': raw['endedAt']?.toString(),
    };
  }

  List _extractRoomList(dynamic responseData) {
    final rawList = responseData is Map && responseData['data'] is List
        ? responseData['data'] as List
        : (responseData is List ? responseData : []);

    return rawList
        .map((item) => _normalizeRoom(Map.from(item as Map)))
        .toList();
  }

  Future<List> getActiveRooms() async {
    try {
      final response = await ApiClient.dio.get('/api/collaborations');
      return _extractRoomList(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Gagal memuat daftar room kolaborasi';
      throw Exception(message);
    }
  }

  Future createRoom(String title) async {
    try {
      final response = await ApiClient.dio.post(
        '/api/collaborations',
        data: {'title': title.trim()},
      );
      final raw = response.data is Map && response.data['data'] is Map
          ? Map.from(response.data['data'] as Map)
          : Map.from(response.data as Map);
      return _normalizeRoom(raw);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Gagal membuat room baru';
      throw Exception(message);
    }
  }

  Future joinRoom(String roomId) async {
    try {
      final response = await ApiClient.dio.post(
        '/api/collaborations/$roomId/join',
      );
      if (response.data is Map) {
        final raw = response.data['data'] is Map
            ? Map.from(response.data['data'] as Map)
            : Map.from(response.data as Map);
        return raw;
      }
      return {'id': roomId};
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Gagal bergabung ke room';
      throw Exception(message);
    }
  }

  Future<void> leaveRoom(String roomId) async {
    try {
      await ApiClient.dio.post('/api/collaborations/$roomId/leave');
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Gagal keluar dari room';
      throw Exception(message);
    }
  }

  Future getRoomDetail(String roomId) async {
    try {
      final response = await ApiClient.dio.get('/api/collaborations/$roomId');
      final raw = response.data is Map && response.data['data'] is Map
          ? Map.from(response.data['data'] as Map)
          : Map.from(response.data as Map);
      return raw;
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Gagal memuat detail room';
      throw Exception(message);
    }
  }

  Future<List> getHistory() async {
    try {
      final response = await ApiClient.dio.get('/api/collaborations/history');
      return _extractRoomList(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Gagal memuat riwayat kolaborasi';
      throw Exception(message);
    }
  }
}