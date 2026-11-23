import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'api_client.dart';

class CollaborationSocketService {
  IO.Socket? _socket;

  bool get isConnected => _socket?.connected == true;

  Future<void> connect({
    required String roomId,
    required Function(int count) onParticipantCount,
    required Function(Map data) onInterimTranscript,
    required Function(Map data) onFinalTranscript,
    required Function(String message) onRoomEnded,
    Function(String error)? onError,
  }) async {
    disconnect();

    final optionBuilder = IO.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .disableAutoConnect()
        .enableForceNew();

    if (kIsWeb) {
      final options = optionBuilder.build();
      options['withCredentials'] = true;
      _socket = IO.io(ApiClient.baseUrl, options);
    } else {
      final cookie = await ApiClient.getSavedCookie() ?? '';
      optionBuilder.setExtraHeaders({'Cookie': cookie});
      _socket = IO.io(ApiClient.baseUrl, optionBuilder.build());
    }

    _socket!.onConnect((_) {
      _socket!.emit('join_room', roomId);
    });

    _socket!.on('participant_count', (data) {
      if (data is Map && data['count'] != null) {
        final count = int.tryParse(data['count'].toString()) ?? 1;
        onParticipantCount(count);
      }
    });

    _socket!.on('transcript_interim', (data) {
      if (data is Map) {
        onInterimTranscript(Map.from(data));
      }
    });

    _socket!.on('transcript_final', (data) {
      if (data is Map) {
        onFinalTranscript(Map.from(data));
      }
    });

    _socket!.on('room_ended', (data) {
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Host telah mengakhiri ruangan';
      onRoomEnded(message);
    });

    _socket!.on('error_message', (data) {
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : 'Terjadi kesalahan koneksi room';
      if (onError != null) onError(message);
    });

    _socket!.onConnectError((err) {
      if (onError != null) {
        onError('Gagal terhubung ke server live transcript');
      }
    });

    _socket!.connect();
  }

  void sendInterimTranscript({
    required String roomId,
    required String text,
  }) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('transcript_interim', {
      'roomId': roomId,
      'text': text,
    });
  }

  void sendFinalTranscript({
    required String roomId,
    required String text,
  }) {
    if (_socket == null || !_socket!.connected) return;
    _socket!.emit('transcript_final', {
      'roomId': roomId,
      'text': text,
    });
  }

  void leaveRoom(String roomId) {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('leave_room', roomId);
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.clearListeners();
      _socket!.disconnect();
      _socket!.dispose();
      _socket = null;
    }
  }
}