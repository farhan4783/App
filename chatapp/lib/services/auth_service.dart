import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'socket_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  final _api = ApiService();
  final _socket = SocketService();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  Future<UserModel> register({
    required String email,
    required String username,
    required String password,
    required String displayName,
  }) async {
    final response = await _api.post('/api/auth/register', data: {
      'email': email,
      'username': username,
      'password': password,
      'displayName': displayName,
    });

    final data = response.data as Map<String, dynamic>;
    await _saveTokens(data['accessToken'] as String, data['refreshToken'] as String);
    _currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    _socket.connect(data['accessToken'] as String);
    return _currentUser!;
  }

  Future<UserModel> login({required String email, required String password}) async {
    final response = await _api.post('/api/auth/login', data: {
      'email': email,
      'password': password,
    });

    final data = response.data as Map<String, dynamic>;
    await _saveTokens(data['accessToken'] as String, data['refreshToken'] as String);
    _currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    _socket.connect(data['accessToken'] as String);
    return _currentUser!;
  }

  Future<UserModel?> tryAutoLogin() async {
    try {
      final token = await _storage.read(key: AppConstants.accessTokenKey);
      if (token == null) return null;

      final response = await _api.get('/api/users/me');
      final data = response.data as Map<String, dynamic>;
      _currentUser = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      _socket.connect(token);
      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    _socket.disconnect();
    await _storage.deleteAll();
    _currentUser = null;
  }

  Future<void> _saveTokens(String accessToken, String refreshToken) async {
    await _storage.write(key: AppConstants.accessTokenKey, value: accessToken);
    await _storage.write(key: AppConstants.refreshTokenKey, value: refreshToken);
  }

  Future<String?> getToken() => _storage.read(key: AppConstants.accessTokenKey);
}
