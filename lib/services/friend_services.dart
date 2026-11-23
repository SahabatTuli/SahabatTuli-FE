import 'package:dio/dio.dart';
import 'api_client.dart';

typedef FriendItem = Map<String, dynamic>;
typedef FriendList = List<FriendItem>;

class FriendService {
  FriendList _extractList(dynamic responseData) {
    final rawList = responseData is Map && responseData['data'] is List
        ? responseData['data'] as List
        : (responseData is List ? responseData : <dynamic>[]);

    return rawList.map((item) {
      final map = FriendItem.from(item as Map);
      return <String, dynamic>{
        'id': map['id']?.toString() ?? '',
        'name': map['name']?.toString() ?? 'Unknown User',
        'email': map['email']?.toString() ?? '',
        'image': map['image'],
        'isAdded': map['isFriend'] == true || map['isAdded'] == true,
      };
    }).toList();
  }

  Future<FriendList> getFriends() async {
    try {
      final response = await ApiClient.dio.get('/api/friends');
      final list = _extractList(response.data);
      for (final item in list) {
        item['isAdded'] = true;
      }
      return list;
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Gagal memuat daftar teman';
      throw Exception(message);
    }
  }

  Future<FriendList> searchUsers(String query) async {
    try {
      final response = await ApiClient.dio.get(
        '/api/friends/search',
        queryParameters: {'q': query.trim()},
      );
      return _extractList(response.data);
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Gagal mencari pengguna';
      throw Exception(message);
    }
  }

  Future<void> addFriend(String friendId) async {
    try {
      await ApiClient.dio.post(
        '/api/friends',
        data: {'friendId': friendId},
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Gagal menambahkan teman';
      throw Exception(message);
    }
  }

  Future<void> removeFriend(String friendId) async {
    try {
      await ApiClient.dio.delete('/api/friends/$friendId');
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Gagal menghapus teman';
      throw Exception(message);
    }
  }
}