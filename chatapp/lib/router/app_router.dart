import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/chat/chat_screen.dart';
import '../screens/search/search_users_screen.dart';
import '../screens/group/create_group_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUser = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isLoggedIn = currentUser != null || authState.valueOrNull != null;
      final loc = state.matchedLocation;

      if (isLoading && loc != '/splash') return '/splash';
      if (!isLoading && !isLoggedIn && loc != '/login' && loc != '/register') return '/login';
      if (!isLoading && isLoggedIn && (loc == '/login' || loc == '/register' || loc == '/splash')) {
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (ctx, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (ctx, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (ctx, state) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (ctx, state) => const HomeScreen()),
      GoRoute(
        path: '/chat/:chatId',
        builder: (ctx, state) {
          final chatId = state.pathParameters['chatId']!;
          final extra = state.extra as Map<String, dynamic>?;
          return ChatScreen(chatId: chatId, chatName: extra?['chatName'] as String? ?? '');
        },
      ),
      GoRoute(path: '/search', builder: (ctx, state) => const SearchUsersScreen()),
      GoRoute(path: '/group/create', builder: (ctx, state) => const CreateGroupScreen()),
      GoRoute(path: '/profile', builder: (ctx, state) => const ProfileScreen()),
      GoRoute(path: '/settings', builder: (ctx, state) => const SettingsScreen()),
    ],
  );
});
