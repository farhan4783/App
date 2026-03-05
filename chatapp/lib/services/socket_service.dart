import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../core/constants/app_constants.dart';
import '../models/message_model.dart';

class SocketEvent {
  static const String newMessage = 'new_message';
  static const String userTyping = 'user_typing';
  static const String userStopTyping = 'user_stop_typing';
  static const String messageStatus = 'message_status';
  static const String userStatus = 'user_status';
  static const String error = 'error';
}

class TypingEvent {
  final String chatId;
  final String userId;
  final String? displayName;
  const TypingEvent({required this.chatId, required this.userId, this.displayName});
}

class StatusEvent {
  final String userId;
  final bool isOnline;
  final DateTime lastSeen;
  const StatusEvent({required this.userId, required this.isOnline, required this.lastSeen});
}

class MessageStatusEvent {
  final String messageId;
  final MsgStatus status;
  final List<String> seenBy;
  const MessageStatusEvent({required this.messageId, required this.status, required this.seenBy});
}

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;

  final _messageController = StreamController<MessageModel>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();
  final _statusController = StreamController<StatusEvent>.broadcast();
  final _msgStatusController = StreamController<MessageStatusEvent>.broadcast();

  Stream<MessageModel> get onNewMessage => _messageController.stream;
  Stream<TypingEvent> get onTyping => _typingController.stream;
  Stream<StatusEvent> get onUserStatus => _statusController.stream;
  Stream<MessageStatusEvent> get onMessageStatus => _msgStatusController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String token) {
    if (_socket?.connected == true) return;

    _socket = IO.io(
      AppConstants.socketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionDelay(1000)
          .build(),
    );

    _socket!.onConnect((_) => print('[Socket] Connected ✅'));
    _socket!.onDisconnect((_) => print('[Socket] Disconnected'));
    _socket!.onConnectError((err) => print('[Socket] Connect error: $err'));

    _socket!.on(SocketEvent.newMessage, (data) {
      try {
        _messageController.add(MessageModel.fromJson(data as Map<String, dynamic>));
      } catch (e) {
        print('[Socket] newMessage parse error: $e');
      }
    });

    _socket!.on(SocketEvent.userTyping, (data) {
      final d = data as Map<String, dynamic>;
      _typingController.add(TypingEvent(
        chatId: d['chatId'] as String,
        userId: d['userId'] as String,
        displayName: d['displayName'] as String?,
      ));
    });

    _socket!.on(SocketEvent.userStopTyping, (data) {
      final d = data as Map<String, dynamic>;
      _typingController.add(TypingEvent(chatId: d['chatId'] as String, userId: d['userId'] as String));
    });

    _socket!.on(SocketEvent.messageStatus, (data) {
      final d = data as Map<String, dynamic>;
      _msgStatusController.add(MessageStatusEvent(
        messageId: d['messageId'] as String,
        status: _parseStatus(d['status'] as String),
        seenBy: List<String>.from(d['seenBy'] as List? ?? []),
      ));
    });

    _socket!.on(SocketEvent.userStatus, (data) {
      final d = data as Map<String, dynamic>;
      _statusController.add(StatusEvent(
        userId: d['userId'] as String,
        isOnline: d['isOnline'] as bool? ?? false,
        lastSeen: DateTime.parse(d['lastSeen'] as String),
      ));
    });

    _socket!.connect();
  }

  MsgStatus _parseStatus(String s) {
    switch (s.toUpperCase()) {
      case 'DELIVERED': return MsgStatus.delivered;
      case 'READ': return MsgStatus.read;
      default: return MsgStatus.sent;
    }
  }

  void joinChats(List<String> chatIds) {
    _socket?.emit('join_chats', {'chatIds': chatIds});
  }

  void sendMessage({
    required String chatId,
    String? text,
    String type = 'TEXT',
    String? mediaUrl,
    String? fileName,
  }) {
    _socket?.emit('send_message', {
      'chatId': chatId,
      'text': text,
      'type': type,
      'mediaUrl': mediaUrl,
      'fileName': fileName,
    });
  }

  void sendTyping(String chatId, bool isTyping) {
    _socket?.emit(isTyping ? 'typing_start' : 'typing_stop', {'chatId': chatId});
  }

  void markRead(String chatId, String messageId) {
    _socket?.emit('message_read', {'chatId': chatId, 'messageId': messageId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _typingController.close();
    _statusController.close();
    _msgStatusController.close();
  }
}
