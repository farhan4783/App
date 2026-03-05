import 'user_model.dart';
import 'message_model.dart';

class ChatMemberModel {
  final String userId;
  final String chatId;
  final bool isAdmin;
  final UserModel user;

  const ChatMemberModel({
    required this.userId,
    required this.chatId,
    required this.isAdmin,
    required this.user,
  });

  factory ChatMemberModel.fromJson(Map<String, dynamic> json) {
    return ChatMemberModel(
      userId: json['userId'] as String,
      chatId: json['chatId'] as String,
      isAdmin: json['isAdmin'] as bool? ?? false,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class ChatModel {
  final String id;
  final bool isGroup;
  final String? groupName;
  final String? groupPhoto;
  final List<ChatMemberModel> members;
  final MessageModel? lastMessage;
  final DateTime createdAt;

  const ChatModel({
    required this.id,
    required this.isGroup,
    this.groupName,
    this.groupPhoto,
    required this.members,
    this.lastMessage,
    required this.createdAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      isGroup: json['isGroup'] as bool? ?? false,
      groupName: json['groupName'] as String?,
      groupPhoto: json['groupPhoto'] as String?,
      members: (json['members'] as List? ?? [])
          .map((m) => ChatMemberModel.fromJson(m as Map<String, dynamic>))
          .toList(),
      lastMessage: json['lastMessage'] != null
          ? MessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // For 1-on-1 chats, get the other user (not the current user)
  UserModel? otherUser(String currentUserId) {
    if (isGroup) return null;
    try {
      return members.firstWhere((m) => m.userId != currentUserId).user;
    } catch (_) {
      return null;
    }
  }

  String displayName(String currentUserId) {
    if (isGroup) return groupName ?? 'Group';
    return otherUser(currentUserId)?.displayName ?? 'Unknown';
  }

  String? displayPhoto(String currentUserId) {
    if (isGroup) return groupPhoto;
    return otherUser(currentUserId)?.photoUrl;
  }

  ChatModel copyWith({MessageModel? lastMessage}) {
    return ChatModel(
      id: id,
      isGroup: isGroup,
      groupName: groupName,
      groupPhoto: groupPhoto,
      members: members,
      lastMessage: lastMessage ?? this.lastMessage,
      createdAt: createdAt,
    );
  }
}
