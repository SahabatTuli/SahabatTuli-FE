import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import 'api_client.dart';

class HistoryService {
  static const String _savedCollabKey = 'saved_collaboration_history';
  static const String _savedConvKey = 'saved_conversation_history';

  DateTime _parseDate(dynamic rawDate) {
    if (rawDate == null) return DateTime.now();
    return DateTime.tryParse(rawDate.toString())?.toLocal() ?? DateTime.now();
  }

  Future _getLocalMap(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) return Map.from(decoded);
    } catch (_) {}
    return {};
  }

  Future<void> saveCollaborationHistory({
    required String roomId,
    required String title,
    required String hostName,
    required String transcriptText,
  }) async {
    final cleanTitle = title.trim().isEmpty ? 'Percakapan 1' : title.trim();

    final prefs = await SharedPreferences.getInstance();
    final savedMap = await _getLocalMap(_savedCollabKey);

    savedMap[roomId] = {
      'id': roomId,
      'type': 'collaboration',
      'title': cleanTitle,
      'creator': hostName,
      'content': transcriptText,
      'savedAt': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_savedCollabKey, jsonEncode(savedMap));

    try {
      await ApiClient.dio.post(
        '/api/collaborations/$roomId/save',
        data: {
          'title': cleanTitle,
          'transcript': transcriptText,
        },
      );
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        final data = e.response?.data;
        final message = (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Gagal menyinkronkan riwayat kolaborasi ke server';
        throw Exception(message);
      }
    }
  }

  Future<void> saveConversationHistory({
    required String title,
    required List<Message> messages,
  }) async {
    final cleanTitle = title.trim().isEmpty ? 'Percakapan 1' : title.trim();
    final serializedMessages = messages
        .map((m) => {
              'text': m.text,
              'isFromUser': m.isFromUser,
              'timestamp': m.timestamp.toIso8601String(),
            })
        .toList();

    final plainContent = messages
        .map((m) => '${m.isFromUser ? "Saya" : "Lawan Bicara"}: ${m.text}')
        .join('\n');

    String recordId = 'conv-${DateTime.now().millisecondsSinceEpoch}';

    try {
      final response = await ApiClient.dio.post(
        '/api/conversations',
        data: {
          'title': cleanTitle,
          'messages': serializedMessages,
          'content': plainContent,
        },
      );

      final raw = response.data is Map && response.data['data'] is Map
          ? Map.from(response.data['data'] as Map)
          : (response.data is Map ? Map.from(response.data as Map) : {});

      if (raw['id'] != null && raw['id'].toString().isNotEmpty) {
        recordId = raw['id'].toString();
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 404) {
        final data = e.response?.data;
        final message = (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Gagal menyimpan percakapan ke server';
        throw Exception(message);
      }
    }

    // Simpan salinan lokal agar detail bubble tetap terbaca cepat
    final prefs = await SharedPreferences.getInstance();
    final savedMap = await _getLocalMap(_savedConvKey);

    savedMap[recordId] = {
      'id': recordId,
      'type': 'conversation',
      'title': cleanTitle,
      'messages': serializedMessages,
      'content': plainContent,
      'savedAt': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_savedConvKey, jsonEncode(savedMap));
  }

  Future<List> getCollaborationHistory() async {
    final savedMap = await _getLocalMap(_savedCollabKey);
    if (savedMap.isEmpty) return [];

    Map backendRoomsById = {};
    try {
      final response = await ApiClient.dio.get('/api/collaborations/history');
      final rawList = response.data is Map && response.data['data'] is List
          ? response.data['data'] as List
          : (response.data is List ? response.data : []);

      for (final item in rawList) {
        if (item is Map && item['id'] != null) {
          backendRoomsById[item['id'].toString()] = Map.from(item);
        }
      }
    } on DioException {
      // Gunakan cache lokal jika sedang offline
    }

    final List results = [];
    savedMap.forEach((key, value) {
      if (value is Map) {
        final roomId = key.toString();
        final backendItem = backendRoomsById[roomId];
        final host = (backendItem is Map && backendItem['host'] is Map)
            ? Map.from(backendItem['host'] as Map)
            : {};

        results.add({
          'id': roomId,
          'type': 'collaboration',
          'title': value['title']?.toString() ??
              (backendItem is Map ? backendItem['title']?.toString() : null) ??
              'Collaboration Room',
          'creator': value['creator']?.toString() ??
              host['name']?.toString() ??
              'Host',
          'content': value['content']?.toString() ?? '',
          'date': _parseDate(
            value['savedAt'] ??
                (backendItem is Map
                    ? (backendItem['endedAt'] ?? backendItem['createdAt'])
                    : null),
          ),
        });
      }
    });

    return results;
  }

  Future<List> getConversationHistory() async {
    final localMap = await _getLocalMap(_savedConvKey);
    final Map mergedById = {};

    localMap.forEach((key, value) {
      if (value is Map) {
        mergedById[key.toString()] = {
          'id': key.toString(),
          'type': 'conversation',
          'title': value['title']?.toString() ?? 'Percakapan',
          'messages': value['messages'] is List ? value['messages'] : [],
          'content': value['content']?.toString() ?? '',
          'date': _parseDate(value['savedAt']),
        };
      }
    });

    try {
      final response = await ApiClient.dio.get('/api/conversations');
      final rawList = response.data is Map && response.data['data'] is List
          ? response.data['data'] as List
          : (response.data is List ? response.data : []);

      for (final item in rawList) {
        if (item is Map) {
          final map = Map.from(item);
          final id = map['id']?.toString() ?? '';
          if (id.isEmpty) continue;

          final existingLocal = mergedById[id];
          mergedById[id] = {
            'id': id,
            'type': 'conversation',
            'title': map['title']?.toString() ??
                (existingLocal is Map ? existingLocal['title'] : 'Percakapan'),
            'messages': map['messages'] is List
                ? map['messages']
                : (existingLocal is Map ? existingLocal['messages'] : []),
            'content': map['content']?.toString() ??
                map['transcript']?.toString() ??
                (existingLocal is Map ? existingLocal['content'] : ''),
            'date': _parseDate(map['updatedAt'] ?? map['createdAt']),
          };
        }
      }
    } on DioException catch (e) {
      if (e.response?.statusCode != 404 && mergedById.isEmpty) {
        final data = e.response?.data;
        final message = (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Gagal memuat riwayat percakapan';
        throw Exception(message);
      }
    }

    return mergedById.values.toList();
  }

  Future<List> getAllHistory() async {
    final results = await Future.wait([
      getCollaborationHistory(),
      getConversationHistory(),
    ]);

    final combined = [...results[0], ...results[1]];
    combined.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );
    return combined;
  }

  Future getHistoryDetail({
    required String id,
    required String type,
  }) async {
    if (type == 'collaboration') {
      final savedMap = await _getLocalMap(_savedCollabKey);
      final localSaved = savedMap[id];

      try {
        final response = await ApiClient.dio.get('/api/collaborations/$id');
        final raw = response.data is Map && response.data['data'] is Map
            ? Map.from(response.data['data'] as Map)
            : Map.from(response.data as Map);

        if (localSaved is Map &&
            (raw['transcripts'] == null ||
                (raw['transcripts'] is List &&
                    (raw['transcripts'] as List).isEmpty))) {
          raw['content'] = localSaved['content']?.toString() ?? '';
        }
        return raw;
      } on DioException {
        if (localSaved is Map) {
          return Map.from(localSaved);
        }
        rethrow;
      }
    }

    final savedConvMap = await _getLocalMap(_savedConvKey);
    final localConv = savedConvMap[id];

    try {
      final response = await ApiClient.dio.get('/api/conversations/$id');
      final raw = response.data is Map && response.data['data'] is Map
          ? Map.from(response.data['data'] as Map)
          : Map.from(response.data as Map);

      if ((raw['messages'] == null ||
              (raw['messages'] is List && (raw['messages'] as List).isEmpty)) &&
          localConv is Map &&
          localConv['messages'] is List) {
        raw['messages'] = localConv['messages'];
      }
      return raw;
    } on DioException {
      if (localConv is Map) {
        return Map.from(localConv);
      }
      rethrow;
    }
  }
}