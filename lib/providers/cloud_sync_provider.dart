import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/database_helper.dart';
import '../models/cloud_backup.dart';
import '../providers/habit_provider.dart';
import '../providers/note_provider.dart';
import '../providers/todo_provider.dart';
import '../repositories/cloud_repository.dart';

final cloudSyncProvider = AsyncNotifierProvider<CloudSyncNotifier, CloudSyncState>(CloudSyncNotifier.new);

class CloudSyncState {
  final bool isSyncing;
  final String? error;
  final List<CloudBackup> backups;
  final String? lastSyncTime;

  const CloudSyncState({
    this.isSyncing = false,
    this.error,
    this.backups = const [],
    this.lastSyncTime,
  });

  CloudSyncState copyWith({
    bool? isSyncing,
    String? error,
    List<CloudBackup>? backups,
    String? lastSyncTime,
  }) {
    return CloudSyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      error: error,
      backups: backups ?? this.backups,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

class CloudSyncNotifier extends AsyncNotifier<CloudSyncState> {
  @override
  Future<CloudSyncState> build() async {
    return const CloudSyncState();
  }

  /// 立即同步：将本地数据打包上传到云端
  Future<void> syncNow() async {
    state = const AsyncValue.loading();
    try {
      final db = await DatabaseHelper().database;
      final notes = await db.query('notes');
      final todos = await db.query('todos');
      final habits = await db.query('habits');
      final records = await db.query('checkin_records');

      final backupData = {
        'notes': notes,
        'todos': todos,
        'habits': habits,
        'checkin_records': records,
        'sync_at': DateTime.now().millisecondsSinceEpoch,
      };

      final repo = ref.read(cloudRepositoryProvider);
      final backup = await repo.uploadBackup(
        backupJson: jsonEncode(backupData),
        noteCount: notes.length,
        todoCount: todos.length,
        habitCount: habits.length,
      );

      state = AsyncValue.data(CloudSyncState(
        backups: [...(state.value?.backups ?? []), backup],
        lastSyncTime: backup.formattedTime,
      ));
    } catch (e) {
      state = AsyncValue.data(CloudSyncState(
        error: e.toString(),
        backups: state.value?.backups ?? [],
      ));
    }
  }

  /// 获取云端备份列表
  Future<void> fetchBackups() async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(cloudRepositoryProvider);
      final backups = await repo.getBackups();
      state = AsyncValue.data(CloudSyncState(
        backups: backups,
        lastSyncTime: backups.isNotEmpty ? backups.first.formattedTime : null,
      ));
    } catch (e) {
      state = AsyncValue.data(CloudSyncState(
        error: e.toString(),
        backups: state.value?.backups ?? [],
      ));
    }
  }

  /// 下载并恢复指定备份
  Future<void> restoreBackup(String backupId) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(cloudRepositoryProvider);
      final backupJson = await repo.downloadBackup(backupId);
      final data = jsonDecode(backupJson) as Map<String, dynamic>;

      final db = await DatabaseHelper().database;
      await db.transaction((txn) async {
        // 先清空现有数据（保留表结构）
        await txn.delete('notes');
        await txn.delete('todos');
        await txn.delete('habits');
        await txn.delete('checkin_records');

        // 恢复数据
        for (final row in (data['notes'] as List<dynamic>? ?? [])) {
          await txn.insert('notes', row as Map<String, dynamic>);
        }
        for (final row in (data['todos'] as List<dynamic>? ?? [])) {
          await txn.insert('todos', row as Map<String, dynamic>);
        }
        for (final row in (data['habits'] as List<dynamic>? ?? [])) {
          await txn.insert('habits', row as Map<String, dynamic>);
        }
        for (final row in (data['checkin_records'] as List<dynamic>? ?? [])) {
          await txn.insert('checkin_records', row as Map<String, dynamic>);
        }
      });

      // 刷新所有Provider
      ref.invalidate(noteNotifierProvider);
      ref.invalidate(todoNotifierProvider);
      ref.invalidate(habitNotifierProvider);

      state = AsyncValue.data(CloudSyncState(
        backups: state.value?.backups ?? [],
        lastSyncTime: DateTime.now().toString(),
      ));
    } catch (e) {
      state = AsyncValue.data(CloudSyncState(
        error: e.toString(),
        backups: state.value?.backups ?? [],
      ));
    }
  }

  /// 删除云端备份
  Future<void> deleteBackup(String backupId) async {
    try {
      final repo = ref.read(cloudRepositoryProvider);
      await repo.deleteBackup(backupId);
      final backups = (state.value?.backups ?? []).where((b) => b.id != backupId).toList();
      state = AsyncValue.data(CloudSyncState(
        backups: backups,
        lastSyncTime: state.value?.lastSyncTime,
      ));
    } catch (e) {
      state = AsyncValue.data(CloudSyncState(
        error: e.toString(),
        backups: state.value?.backups ?? [],
      ));
    }
  }
}
