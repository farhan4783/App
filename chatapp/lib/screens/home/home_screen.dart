import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../models/chat_model.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/auth_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatList = ref.watch(chatListProvider);
    final currentUser = ref.watch(currentUserProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatApp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.push('/search'),
            tooltip: 'Search users',
          ),
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () => context.push('/group/create'),
            tooltip: 'Create group',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'profile') context.push('/profile');
              if (value == 'settings') context.push('/settings');
              if (value == 'logout') {
                await ref.read(authServiceProvider).logout();
                ref.read(currentUserProvider.notifier).state = null;
                if (context.mounted) context.go('/login');
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'profile', child: Text('My Profile')),
              const PopupMenuItem(value: 'settings', child: Text('Settings')),
              const PopupMenuItem(value: 'logout', child: Text('Logout')),
            ],
          ),
        ],
      ),
      body: chatList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (chats) {
          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline_rounded, size: 64, color: cs.onSurface.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('No chats yet', style: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('Tap 🔍 to find people to chat with',
                      style: TextStyle(color: cs.onSurface.withOpacity(0.3), fontSize: 13)),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: chats.length,
            separatorBuilder: (_, __) => const Divider(height: 0.5, indent: 80),
            itemBuilder: (ctx, i) => _ChatTile(chat: chats[i], currentUserId: currentUser?.id ?? ''),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/search'),
        backgroundColor: cs.primary,
        child: const Icon(Icons.chat_rounded, color: Colors.white),
      ),
    );
  }
}

class _ChatTile extends ConsumerWidget {
  final ChatModel chat;
  final String currentUserId;

  const _ChatTile({required this.chat, required this.currentUserId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onlineStatus = ref.watch(userStatusProvider);
    final cs = Theme.of(context).colorScheme;
    final other = chat.otherUser(currentUserId);
    final isOtherOnline = other != null && (onlineStatus[other.id] ?? other.isOnline);
    final lastMsg = chat.lastMessage;
    final photoUrl = chat.displayPhoto(currentUserId);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: cs.primary.withOpacity(0.15),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null
                ? Text(
                    chat.displayName(currentUserId).isNotEmpty
                        ? chat.displayName(currentUserId)[0].toUpperCase()
                        : '?',
                    style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: 20),
                  )
                : null,
          ),
          if (!chat.isGroup && isOtherOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 13,
                height: 13,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        chat.displayName(currentUserId),
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: lastMsg != null
          ? Row(
              children: [
                if (lastMsg.senderId == currentUserId) ...[
                  Icon(
                    lastMsg.status == MsgStatus.read
                        ? Icons.done_all
                        : lastMsg.status == MsgStatus.delivered
                            ? Icons.done_all
                            : Icons.done,
                    size: 14,
                    color: lastMsg.status == MsgStatus.read ? cs.primary : cs.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    lastMsg.type == MessageType.text
                        ? (lastMsg.text ?? '')
                        : lastMsg.type == MessageType.image
                            ? '📷 Photo'
                            : lastMsg.type == MessageType.audio
                                ? '🎵 Audio'
                                : '📎 File',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cs.onSurface.withOpacity(0.5), fontSize: 13),
                  ),
                ),
              ],
            )
          : Text('No messages yet', style: TextStyle(color: cs.onSurface.withOpacity(0.3), fontSize: 13)),
      trailing: lastMsg != null
          ? Text(
              timeago.format(lastMsg.sentAt, allowFromNow: true),
              style: TextStyle(fontSize: 11, color: cs.onSurface.withOpacity(0.4)),
            )
          : null,
      onTap: () => context.push('/chat/${chat.id}', extra: {'chatName': chat.displayName(currentUserId)}),
    );
  }
}
