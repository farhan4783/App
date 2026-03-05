import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final currentUserProvider = StateProvider<UserModel?>((ref) => null);

final authStateProvider = FutureProvider<UserModel?>((ref) async {
  final auth = ref.read(authServiceProvider);
  final user = await auth.tryAutoLogin();
  if (user != null) {
    ref.read(currentUserProvider.notifier).state = user;
  }
  return user;
});
