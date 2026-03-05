import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider);
    _nameCtrl.text = user?.displayName ?? '';
    _bioCtrl.text = user?.bio ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      final updated = await ChatService().updateProfile(
        displayName: _nameCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
      );
      ref.read(currentUserProvider.notifier).state = updated;
      setState(() => _editing = false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Update failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changePhoto() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (file == null) return;
    setState(() => _saving = true);
    try {
      final url = await ChatService().uploadMedia(file.path, 'image/jpeg');
      if (url != null) {
        final updated = await ChatService().updateProfile(photoUrl: url);
        ref.read(currentUserProvider.notifier).state = updated;
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo upload failed')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          if (!_editing)
            IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => setState(() => _editing = true))
          else
            TextButton(
              onPressed: _saving ? null : _saveProfile,
              child: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            GestureDetector(
              onTap: _changePhoto,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: cs.primary.withOpacity(0.15),
                    backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                    child: user?.photoUrl == null
                        ? Text(
                            user?.displayName.isNotEmpty == true ? user!.displayName[0].toUpperCase() : '?',
                            style: TextStyle(fontSize: 40, color: cs.primary, fontWeight: FontWeight.w700),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('@${user?.username ?? ''}', style: TextStyle(color: cs.onBackground.withOpacity(0.4), fontSize: 13)),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameCtrl,
              enabled: _editing,
              decoration: const InputDecoration(labelText: 'Display Name', prefixIcon: Icon(Icons.person_outline)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bioCtrl,
              enabled: _editing,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Bio', prefixIcon: Icon(Icons.info_outline), alignLabelWithHint: true),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.email_outlined, color: cs.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(child: Text(user?.email ?? '', style: const TextStyle(fontSize: 14))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
