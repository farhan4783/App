import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _sectionHeader(context, 'Appearance'),
          SwitchListTile(
            secondary: Icon(isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
            title: const Text('Dark Mode'),
            subtitle: Text(isDark ? 'Switch to light theme' : 'Switch to dark theme'),
            value: isDark,
            activeColor: cs.primary,
            onChanged: (v) {
              ref.read(themeModeProvider.notifier).state = v ? ThemeMode.dark : ThemeMode.light;
            },
          ),
          const Divider(),
          _sectionHeader(context, 'Account'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('My Profile'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/profile'),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red.shade400),
            title: Text('Logout', style: TextStyle(color: Colors.red.shade400)),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Log out?'),
                  content: const Text('You will be signed out of your account.'),
                  actions: [
                    TextButton(onPressed: () => ctx.pop(false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => ctx.pop(true),
                      child: Text('Logout', style: TextStyle(color: Colors.red.shade400)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authServiceProvider).logout();
                ref.read(currentUserProvider.notifier).state = null;
                if (context.mounted) context.go('/login');
              }
            },
          ),
          const Divider(),
          _sectionHeader(context, 'About'),
          ListTile(
            leading: Icon(Icons.info_outline, color: cs.onBackground.withOpacity(0.5)),
            title: const Text('ChatApp'),
            subtitle: const Text('Version 1.0.0 • WebSocket Messaging'),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
