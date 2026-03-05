import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/socket_service.dart';
import 'auth_provider.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());
final socketServiceProvider = Provider<SocketService>((ref) => SocketService());

// ── Chat List ─────────────────────────────────────────────────────────────────
class ChatListNotifier extends AsyncNotifier<List<ChatModel>> {
  @override
  Future<List<ChatModel>> build() async {
    final chats = await ref.read(chatServiceProvider).getChats();

    // Join all socket rooms
    final socket = ref.read(socketServiceProvider);
    socket.joinChats(chats.map((c) => c.id).toList());

    // Listen for new messages to update last message in chat list
    socket.onNewMessage.listen((msg) {
      state.whenData((chats) {
        final index = chats.indexWhere((c) => c.id == msg.chatId);
        if (index != -1) {
          final updated = List<ChatModel>.from(chats);
          updated[index] = updated[index].copyWith(lastMessage: msg);
          // Move to top
          final chat = updated.removeAt(index);
          updated.insert(0, chat);
          state = AsyncData(updated);
        }
      });
    });

    return chats;
  }

  Future<ChatModel> createDirectChat(String targetUserId) async {
    final chat = await ref.read(chatServiceProvider).createOrGetDirectChat(targetUserId);
    state.whenData((chats) {
      if (!chats.any((c) => c.id == chat.id)) {
        ref.read(socketServiceProvider).joinChats([chat.id]);
        state = AsyncData([chat, ...chats]);
      }
    });
    return chat;
  }

  Future<ChatModel> createGroupChat({
    required List<String> memberIds,
    required String groupName,
  }) async {
    final chat = await ref.read(chatServiceProvider).createGroupChat(
          memberIds: memberIds,
          groupName: groupName,
        );
    state.whenData((chats) {
      ref.read(socketServiceProvider).joinChats([chat.id]);
      state = AsyncData([chat, ...chats]);
    });
    return chat;
  }
}

final chatListProvider = AsyncNotifierProvider<ChatListNotifier, List<ChatModel>>(
  ChatListNotifier.new,
);

// ── Messages for a specific chat ─────────────────────────────────────────────
class MessagesNotifier extends FamilyAsyncNotifier<List<MessageModel>, String> {
  late StreamSubscription _sub;
  late String _chatId;

  @override
  Future<List<MessageModel>> build(String chatId) async {
    _chatId = chatId;
    final currentUserId = ref.read(currentUserProvider)?.id ?? '';

    final messages = await ref.read(chatServiceProvider).getMessages(chatId);

    // Mark last unread messages as read
    if (messages.isNotEmpty) {
      final lastMsg = messages.last;
      if (lastMsg.senderId != currentUserId && lastMsg.status != MsgStatus.read) {
        ref.read(socketServiceProvider).markRead(chatId, lastMsg.id);
      }
    }

    // Subscribe to new messages
    _sub = ref.read(socketServiceProvider).onNewMessage.listen((msg) {
      if (msg.chatId == chatId) {
        state.whenData((msgs) => state = AsyncData([...msgs, msg]));
        // Auto-mark as read
        if (msg.senderId != currentUserId) {
          ref.read(socketServiceProvider).markRead(chatId, msg.id);
        }
      }
    });

    // Update message status
    ref.read(socketServiceProvider).onMessageStatus.listen((event) {
      state.whenData((msgs) {
        final updated = msgs.map((m) {
          if (m.id == event.messageId) {
            return m.copyWith(status: event.status, seenBy: event.seenBy);
          }
          return m;
        }).toList();
        state = AsyncData(updated);
      });
    });

    ref.onDispose(() => _sub.cancel());
    return messages;
  }

  Future<void> loadMore() async {
    state.whenData((msgs) async {
      if (msgs.isEmpty) return;
      final cursor = msgs.first.sentAt.toIso8601String();
      final older = await ref.read(chatServiceProvider).getMessages(_chatId, cursor: cursor);
      state = AsyncData([...older, ...msgs]);
    });
  }
}

final messagesProvider = AsyncNotifierProviderFamily<MessagesNotifier, List<MessageModel>, String>(
  MessagesNotifier.new,
);

// ── Typing indicators ─────────────────────────────────────────────────────────
final typingUsersProvider = StreamProvider.family<Map<String, DateTime>, String>((ref, chatId) {
  final controller = StreamController<Map<String, DateTime>>.broadcast();
  final typingMap = <String, DateTime>{};

  ref.read(socketServiceProvider).onTyping.listen((event) {
    if (event.chatId == chatId) {
      typingMap[event.userId] = DateTime.now();
      controller.add(Map.from(typingMap));

      // Auto-remove after 3s
      Future.delayed(const Duration(seconds: 3), () {
        typingMap.remove(event.userId);
        controller.add(Map.from(typingMap));
      });
    }
  });

  return controller.stream;
});

// ── Online status ─────────────────────────────────────────────────────────────
final userStatusProvider = StateNotifierProvider<UserStatusNotifier, Map<String, bool>>((ref) {
  return UserStatusNotifier(ref.read(socketServiceProvider));
});

class UserStatusNotifier extends StateNotifier<Map<String, bool>> {
  UserStatusNotifier(SocketService socket) : super({}) {
    socket.onUserStatus.listen((event) {
      state = {...state, event.userId: event.isOnline};
    });
  }
}
