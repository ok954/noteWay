import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../models/cloud_backup.dart';
import '../models/user.dart';

final cloudRepositoryProvider = Provider((ref) => CloudRepository());

/// ============================================
/// ⚠️ 重要：请替换为您的服务器地址
/// ============================================
const String API_BASE_URL = 'https://your-api-server.com';

class CloudRepository {
  static final CloudRepository _instance = CloudRepository._internal();
  factory CloudRepository() => _instance;
  CloudRepository._internal();

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // ========== 认证 ==========

  /// 注册账号
  Future<User> register(String username, String password) async {
    final response = await http.post(
      Uri.parse('$API_BASE_URL/api/auth/register'),
      headers: _headers,
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      _token = data['token'] as String?;
      return User.fromMap(data['user'] as Map<String, dynamic>);
    }
    throw _parseError(response);
  }

  /// 登录账号
  Future<User> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$API_BASE_URL/api/auth/login'),
      headers: _headers,
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['token'] as String?;
      return User.fromMap(data['user'] as Map<String, dynamic>);
    }
    throw _parseError(response);
  }

  /// 获取用户信息
  Future<User?> getProfile() async {
    if (_token == null) return null;
    final response = await http.get(
      Uri.parse('$API_BASE_URL/api/auth/profile'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromMap(data['user'] as Map<String, dynamic>);
    }
    return null;
  }

  // ========== 云端同步 ==========

  /// 上传备份
  Future<CloudBackup> uploadBackup({
    required String backupJson,
    required int noteCount,
    required int todoCount,
    required int habitCount,
  }) async {
    if (_token == null) throw Exception('未登录');

    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = '${Platform.operatingSystem} ${Platform.operatingSystemVersion} v${packageInfo.version}';

    final response = await http.post(
      Uri.parse('$API_BASE_URL/api/sync/upload'),
      headers: _headers,
      body: jsonEncode({
        'backup_json': backupJson,
        'note_count': noteCount,
        'todo_count': todoCount,
        'habit_count': habitCount,
        'device_info': deviceInfo,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return CloudBackup.fromMap(data['backup'] as Map<String, dynamic>);
    }
    throw _parseError(response);
  }

  /// 获取备份列表
  Future<List<CloudBackup>> getBackups() async {
    if (_token == null) throw Exception('未登录');

    final response = await http.get(
      Uri.parse('$API_BASE_URL/api/sync/backups'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['backups'] as List<dynamic>;
      return list.map((e) => CloudBackup.fromMap(e as Map<String, dynamic>)).toList();
    }
    throw _parseError(response);
  }

  /// 下载备份
  Future<String> downloadBackup(String backupId) async {
    if (_token == null) throw Exception('未登录');

    final response = await http.get(
      Uri.parse('$API_BASE_URL/api/sync/backups/$backupId'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['backup_json'] as String;
    }
    throw _parseError(response);
  }

  /// 删除备份
  Future<void> deleteBackup(String backupId) async {
    if (_token == null) throw Exception('未登录');

    final response = await http.delete(
      Uri.parse('$API_BASE_URL/api/sync/backups/$backupId'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw _parseError(response);
    }
  }

  Exception _parseError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return Exception(data['message'] ?? '请求失败: ${response.statusCode}');
    } catch (_) {
      return Exception('请求失败: ${response.statusCode}');
    }
  }
}
