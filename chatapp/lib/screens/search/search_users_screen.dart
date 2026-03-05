import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';

final _searchProvider = StateProvider<String>((ref) => '');
final _searchResultsProvider = FutureProvider.family<List<UserModel>, String>((ref, query) async {
  if (query.length < 2) return [];
  return ref.read(chatServiceProvider).searchUsers(query);
});

class SearchUsersScreen extends ConsumerStatefulWidget {
  const SearchUsersScreen({super.key});
  @override
  ConsumerState<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends ConsumerState<SearchUsersScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(_searchProvider);
    final results = ref.watch(_searchResultsProvider(query));
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search by username or email...',
            border: InputBorder.none,
            filled: false,
            hintStyle: TextStyle(color: cs.onBackground.withOpacity(0.4)),
          ),
          onChanged: (v) => ref.read(_searchProvider.notifier).state = v.trim(),
        ),
        actions: [
          if (_ctrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _ctrl.clear();
                ref.read(_searchProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: results.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (users) {
          if (query.length < 2) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 56, color: cs.onBackground.withOpacity(0.15)),
                  const SizedBox(height: 12),
                  Text('Type a username or email', style: TextStyle(color: cs.onBackground.withOpacity(0.3))),
                ],
              ),
            );
          }
          if (users.isEmpty) {
            return Center(
              child: Text('No users found for "$query"', style: TextStyle(color: cs.onBackground.withOpacity(0.4))),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (ctx, i) => _UserResultTile(user: users[i]),
          );
        },
      ),
    );
  }
}

class _UserResultTile extends ConsumerWidget {
  final UserModel user;
  const _UserResultTile({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: cs.primary.withOpacity(0.15),
        backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
        child: user.photoUrl == null
            ? Text(user.displayName[0].toUpperCase(), style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700))
            : null,
      ),
      title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text('@${user.username}', style: TextStyle(color: cs.onBackground.withOpacity(0.4), fontSize: 12)),
      trailing: user.isOnline
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('online', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 11, fontWeight: FontWeight.w600)),
            )
          : null,
      onTap: () async {
        try {
          final chat = await ref.read(chatListProvider.notifier).createDirectChat(user.id);
          if (context.mounted) {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/chat/${chat.id}',
                arguments: {'chatName': user.displayName});
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
        }
      },
    );
  }
}
