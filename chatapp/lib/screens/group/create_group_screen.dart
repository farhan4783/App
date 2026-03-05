import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';

class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key});
  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  final _nameCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  final _selectedUsers = <UserModel>[];
  List<UserModel> _searchResults = [];
  bool _searching = false;
  bool _creating = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    try {
      final results = await ChatService().searchUsers(query);
      final currentId = ref.read(currentUserProvider)?.id ?? '';
      setState(() {
        _searchResults = results.where((u) => u.id != currentId && !_selectedUsers.any((s) => s.id == u.id)).toList();
      });
    } finally {
      setState(() => _searching = false);
    }
  }

  Future<void> _createGroup() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a group name')));
      return;
    }
    if (_selectedUsers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least 2 members')));
      return;
    }

    setState(() => _creating = true);
    try {
      await ref.read(chatListProvider.notifier).createGroupChat(
        memberIds: _selectedUsers.map((u) => u.id).toList(),
        groupName: _nameCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group'),
        actions: [
          TextButton(
            onPressed: _creating ? null : _createGroup,
            child: _creating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Create'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Group Name', prefixIcon: Icon(Icons.group_outlined)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  onChanged: _search,
                  decoration: InputDecoration(
                    hintText: 'Search users to add...',
                    prefixIcon: _searching ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))) : const Icon(Icons.person_search_outlined),
                  ),
                ),
              ],
            ),
          ),
          if (_selectedUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _selectedUsers.map((u) => Chip(
                  avatar: CircleAvatar(
                    backgroundColor: cs.primary.withOpacity(0.15),
                    child: Text(u.displayName[0], style: TextStyle(color: cs.primary, fontSize: 12)),
                  ),
                  label: Text(u.displayName),
                  onDeleted: () => setState(() => _selectedUsers.remove(u)),
                )).toList(),
              ),
            ),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: _searchResults.length,
              itemBuilder: (ctx, i) {
                final user = _searchResults[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primary.withOpacity(0.15),
                    child: Text(user.displayName[0], style: TextStyle(color: cs.primary)),
                  ),
                  title: Text(user.displayName),
                  subtitle: Text('@${user.username}', style: TextStyle(color: cs.onBackground.withOpacity(0.4), fontSize: 12)),
                  onTap: () {
                    setState(() {
                      _selectedUsers.add(user);
                      _searchResults.removeAt(i);
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
