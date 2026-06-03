import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'app.dart';
import 'core/database/database_helper.dart';
import 'providers/settings_provider.dart';
import 'repositories/habit_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // 每日重置检查
  await _checkDailyReset();

  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const MemoApp(),
  ));
}

Future<void> _checkDailyReset() async {
  try {
    final db = await DatabaseHelper().database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['last_launch_date'],
    );

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;

    if (result.isNotEmpty) {
      final lastLaunch = int.tryParse(result.first['value'] as String? ?? '0') ?? 0;
      final lastDate = DateTime.fromMillisecondsSinceEpoch(lastLaunch);
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day).millisecondsSinceEpoch;

      if (lastDay < today) {
        // 日期变化，执行重置
        await HabitRepository().resetTodayData();
      }
    }

    // 更新最后启动日期
    await db.insert(
      'settings',
      {
        'key': 'last_launch_date',
        'value': today.toString(),
        'updated_at': now.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  } catch (e) {
    // 静默处理初始化错误，避免阻塞应用启动
    debugPrint('Daily reset check failed: $e');
  }
}
