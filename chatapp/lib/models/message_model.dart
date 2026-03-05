import 'user_model.dart';

enum MessageType { text, image, file, audio }
enum MsgStatus { sent, delivered, read }

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String? text;
  final String? mediaUrl;
  final String? fileName;
  final MessageType type;
  final MsgStatus status;
  final List<String> seenBy;
  final DateTime sentAt;
  final UserModel? sender;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.text,
    this.mediaUrl,
    this.fileName,
    required this.type,
    required this.status,
    required this.seenBy,
    required this.sentAt,
    this.sender,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chatId'] as String,
      senderId: json['senderId'] as String,
      text: json['text'] as String?,
      mediaUrl: json['mediaUrl'] as String?,
      fileName: json['fileName'] as String?,
      type: _parseType(json['type'] as String? ?? 'TEXT'),
      status: _parseStatus(json['status'] as String? ?? 'SENT'),
      seenBy: List<String>.from(json['seenBy'] as List? ?? []),
      sentAt: DateTime.parse(json['sentAt'] as String),
      sender: json['sender'] != null
          ? UserModel.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
    );
  }

  static MessageType _parseType(String t) {
    switch (t.toUpperCase()) {
      case 'IMAGE': return MessageType.image;
      case 'FILE': return MessageType.file;
      case 'AUDIO': return MessageType.audio;
      default: return MessageType.text;
    }
  }

  static MsgStatus _parseStatus(String s) {
    switch (s.toUpperCase()) {
      case 'DELIVERED': return MsgStatus.delivered;
      case 'READ': return MsgStatus.read;
      default: return MsgStatus.sent;
    }
  }

  MessageModel copyWith({MsgStatus? status, List<String>? seenBy}) {
    return MessageModel(
      id: id,
      chatId: chatId,
      senderId: senderId,
      text: text,
      mediaUrl: mediaUrl,
      fileName: fileName,
      type: type,
      status: status ?? this.status,
      seenBy: seenBy ?? this.seenBy,
      sentAt: sentAt,
      sender: sender,
    );
  }
}
