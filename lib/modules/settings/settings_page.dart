import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_colors.dart';
import '../../core/database/database_helper.dart';
import '../../providers/habit_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/todo_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    String themeLabel;
    switch (themeMode) {
      case ThemeMode.light:
        themeLabel = '浅色';
        break;
      case ThemeMode.dark:
        themeLabel = '深色';
        break;
      case ThemeMode.system:
        themeLabel = '跟随系统';
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          _buildSectionTitle('数据管理'),
          ListTile(
            leading: const Icon(Icons.download, color: AppColors.primary),
            title: const Text('导出数据'),
            subtitle: const Text('将笔记、待办、打卡数据导出为CSV文件'),
            onTap: () => _exportData(context),
          ),
          ListTile(
            leading: const Icon(Icons.upload, color: AppColors.secondary),
            title: const Text('导入数据'),
            subtitle: const Text('从CSV文件恢复数据'),
            onTap: () => _importData(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.danger),
            title: const Text('清除所有数据', style: TextStyle(color: AppColors.danger)),
            subtitle: const Text('删除所有笔记、待办和打卡记录'),
            onTap: () => _showClearConfirm(context, ref),
          ),
          _buildSectionTitle('个性化'),
          ListTile(
            leading: const Icon(Icons.dark_mode),
            title: const Text('深色模式'),
            trailing: Text(themeLabel, style: TextStyle(color: AppColors.textSecondary)),
            onTap: () => _showThemePicker(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.volume_up),
            title: const Text('提醒音效'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          _buildSectionTitle('其他'),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('使用帮助'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('分享应用'),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于'),
            subtitle: const Text('记途 v1.1.0'),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(themeModeProvider);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('选择主题', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('跟随系统'),
              value: ThemeMode.system,
              groupValue: current,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('浅色模式'),
              value: ThemeMode.light,
              groupValue: current,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('深色模式'),
              value: ThemeMode.dark,
              groupValue: current,
              onChanged: (value) {
                if (value != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final db = await DatabaseHelper().database;
      final notes = await db.query('notes');
      final todos = await db.query('todos');
      final habits = await db.query('habits');
      final records = await db.query('checkin_records');

      final List<List<dynamic>> csvData = [];
      csvData.add(['==NOTES==']);
      csvData.add(['id', 'title', 'content', 'plain_text', 'image_paths', 'created_at', 'updated_at']);
      for (final row in notes) {
        csvData.add([
          row['id'],
          row['title'],
          row['content'],
          row['plain_text'],
          row['image_paths'],
          row['created_at'],
          row['updated_at'],
        ]);
      }
      csvData.add(['==TODOS==']);
      csvData.add(['id', 'title', 'content', 'type', 'due_date', 'priority', 'is_completed', 'is_pinned', 'created_at', 'updated_at']);
      for (final row in todos) {
        csvData.add([
          row['id'],
          row['title'],
          row['content'],
          row['type'],
          row['due_date'],
          row['priority'],
          row['is_completed'],
          row['is_pinned'],
          row['created_at'],
          row['updated_at'],
        ]);
      }
      csvData.add(['==HABITS==']);
      csvData.add(['id', 'name', 'tag', 'habit_type', 'plan_duration', 'total_duration', 'today_duration', 'checkin_count', 'today_count', 'is_pinned', 'is_timing', 'current_record_id', 'last_checkin_at', 'created_at', 'updated_at']);
      for (final row in habits) {
        csvData.add([
          row['id'],
          row['name'],
          row['tag'],
          row['habit_type'],
          row['plan_duration'],
          row['total_duration'],
          row['today_duration'],
          row['checkin_count'],
          row['today_count'],
          row['is_pinned'],
          row['is_timing'],
          row['current_record_id'],
          row['last_checkin_at'],
          row['created_at'],
          row['updated_at'],
        ]);
      }
      csvData.add(['==CHECKIN_RECORDS==']);
      csvData.add(['id', 'habit_id', 'record_type', 'start_time', 'end_time', 'duration', 'is_completed', 'created_at']);
      for (final row in records) {
        csvData.add([
          row['id'],
          row['habit_id'],
          row['record_type'],
          row['start_time'],
          row['end_time'],
          row['duration'],
          row['is_completed'],
          row['created_at'],
        ]);
      }

      final csvString = const ListToCsvConverter().convert(csvData);
      final now = DateTime.now();
      final fileName = 'noteWay_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.csv';

      String? outputPath;
      if (Platform.isAndroid) {
        final dir = await getExternalStorageDirectory();
        if (dir != null) {
          outputPath = p.join(dir.path, fileName);
        }
      }
      outputPath ??= p.join((await getApplicationDocumentsDirectory()).path, fileName);

      final file = File(outputPath);
      await file.writeAsString(csvString);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('数据已导出至: $outputPath')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Future<void> _importData(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入数据'),
        content: const Text('导入将合并数据，已有数据（按ID判断）会自动跳过，是否继续？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('继续')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final csvString = await file.readAsString();
      final csvData = const CsvToListConverter().convert(csvString);

      final db = await DatabaseHelper().database;
      String currentSection = '';

      await db.transaction((txn) async {
        for (final row in csvData) {
          if (row.isEmpty) continue;
          final first = row[0].toString();
          if (first.startsWith('==') && first.endsWith('==')) {
            currentSection = first;
            continue;
          }
          if (first == 'id') continue; // skip header

          switch (currentSection) {
            case '==NOTES==':
              await _insertOrSkip(txn, 'notes', {
                'id': row[0],
                'title': row[1],
                'content': row[2],
                'plain_text': row[3],
                'image_paths': row[4],
                'created_at': row[5],
                'updated_at': row[6],
              });
              break;
            case '==TODOS==':
              await _insertOrSkip(txn, 'todos', {
                'id': row[0],
                'title': row[1],
                'content': row[2],
                'type': row[3],
                'due_date': row[4],
                'priority': row[5],
                'is_completed': row[6],
                'is_pinned': row[7],
                'created_at': row[8],
                'updated_at': row[9],
              });
              break;
            case '==HABITS==':
              await _insertOrSkip(txn, 'habits', {
                'id': row[0],
                'name': row[1],
                'tag': row[2],
                'habit_type': row[3],
                'plan_duration': row[4],
                'total_duration': row[5],
                'today_duration': row[6],
                'checkin_count': row[7],
                'today_count': row[8],
                'is_pinned': row[9],
                'is_timing': row[10],
                'current_record_id': row[11],
                'last_checkin_at': row[12],
                'created_at': row[13],
                'updated_at': row[14],
              });
              break;
            case '==CHECKIN_RECORDS==':
              await _insertOrSkip(txn, 'checkin_records', {
                'id': row[0],
                'habit_id': row[1],
                'record_type': row[2],
                'start_time': row[3],
                'end_time': row[4],
                'duration': row[5],
                'is_completed': row[6],
                'created_at': row[7],
              });
              break;
          }
        }
      });

      // Refresh all providers
      ref.invalidate(noteNotifierProvider);
      ref.invalidate(todoNotifierProvider);
      ref.invalidate(habitNotifierProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据导入成功')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  Future<void> _insertOrSkip(Transaction txn, String table, Map<String, dynamic> values) async {
    final id = values['id']?.toString();
    if (id == null || id.isEmpty) return;
    final existing = await txn.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (existing.isEmpty) {
      await txn.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  void _showClearConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除所有数据'),
        content: const Text(
          '此操作将删除所有笔记、待办、打卡记录及设置，且不可恢复。确定要继续吗？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _clearAllData(context, ref);
            },
            child: const Text('清除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    try {
      // Close database
      await DatabaseHelper().close();

      // Delete database file
      final dbPath = p.join(await getDatabasesPath(), 'memo_app.db');
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
      }

      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear image directory
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory(p.join(appDir.path, 'images'));
      if (await imageDir.exists()) {
        await imageDir.delete(recursive: true);
      }

      // Re-initialize database with default data
      await DatabaseHelper().database;

      // Refresh providers
      ref.invalidate(noteNotifierProvider);
      ref.invalidate(todoNotifierProvider);
      ref.invalidate(habitNotifierProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('数据已清除，应用已重置')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清除失败: $e')),
        );
      }
    }
  }
}
