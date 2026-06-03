import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';
import '../repositories/cloud_repository.dart';
import 'settings_provider.dart';

final authRepositoryProvider = Provider((ref) => CloudRepository());

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isLoggedIn => user != null;

  AuthState copyWith({User? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  @override
  Future<AuthState> build() async {
    // 尝试从本地恢复登录状态
    final prefs = ref.read(sharedPreferencesProvider);
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);

    if (token != null && userJson != null) {
      try {
        final repo = ref.read(authRepositoryProvider);
        repo.setToken(token);
        final user = await repo.getProfile();
        if (user != null) {
          return AuthState(user: user);
        }
      } catch (e) {
        debugPrint('恢复登录状态失败: $e');
      }
    }
    return const AuthState();
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.login(username, password);
      await _saveAuth(repo.token, user);
      state = AsyncValue.data(AuthState(user: user));
    } catch (e) {
      state = AsyncValue.data(AuthState(error: e.toString()));
    }
  }

  Future<void> register(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.register(username, password);
      await _saveAuth(repo.token, user);
      state = AsyncValue.data(AuthState(user: user));
    } catch (e) {
      state = AsyncValue.data(AuthState(error: e.toString()));
    }
  }

  Future<void> logout() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    ref.read(authRepositoryProvider).setToken(null);
    state = const AsyncValue.data(AuthState());
  }

  Future<void> _saveAuth(String? token, User user) async {
    if (token == null) return;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, _userToJson(user));
  }

  String _userToJson(User user) {
    return '{"id":"${user.id}","username":"${user.username}","created_at":${user.createdAt}}';
  }
}
