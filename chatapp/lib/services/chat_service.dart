import 'package:dio/dio.dart';
import '../core/constants/app_constants.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';

class ChatService {
  final _api = ApiService();

  Future<List<ChatModel>> getChats() async {
    final response = await _api.get('/api/chats');
    final data = response.data as Map<String, dynamic>;
    return (data['chats'] as List)
        .map((c) => ChatModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<ChatModel> createOrGetDirectChat(String targetUserId) async {
    final response = await _api.post('/api/chats/direct', data: {'targetUserId': targetUserId});
    final data = response.data as Map<String, dynamic>;
    return ChatModel.fromJson(data['chat'] as Map<String, dynamic>);
  }

  Future<ChatModel> createGroupChat({
    required List<String> memberIds,
    required String groupName,
    String? groupPhoto,
  }) async {
    final response = await _api.post('/api/chats/group', data: {
      'memberIds': memberIds,
      'groupName': groupName,
      'groupPhoto': groupPhoto,
    });
    final data = response.data as Map<String, dynamic>;
    return ChatModel.fromJson(data['chat'] as Map<String, dynamic>);
  }

  Future<List<MessageModel>> getMessages(String chatId, {String? cursor}) async {
    final response = await _api.get(
      '/api/chats/$chatId/messages',
      queryParams: {
        'limit': AppConstants.messagesPageSize,
        if (cursor != null) 'cursor': cursor,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return (data['messages'] as List)
        .map((m) => MessageModel.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final response = await _api.get('/api/users/search', queryParams: {'q': query});
    final data = response.data as Map<String, dynamic>;
    return (data['users'] as List)
        .map((u) => UserModel.fromJson(u as Map<String, dynamic>))
        .toList();
  }

  Future<UserModel> updateProfile({
    String? displayName,
    String? bio,
    String? photoUrl,
  }) async {
    final response = await _api.patch('/api/users/me', data: {
      if (displayName != null) 'displayName': displayName,
      if (bio != null) 'bio': bio,
      if (photoUrl != null) 'photoUrl': photoUrl,
    });
    final data = response.data as Map<String, dynamic>;
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<String?> uploadMedia(String filePath, String mimeType) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, contentType: DioMediaType.parse(mimeType)),
    });
    final response = await _api.uploadFile('/api/media/upload', formData);
    final data = response.data as Map<String, dynamic>;
    return data['url'] as String?;
  }
}
