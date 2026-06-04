import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_colors.dart';
import '../../core/database/database_helper.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/todo_provider.dart';
import '../../router.dart';
import 'cloud_data_page.dart';
import 'cloud_sync_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final themeLabel = switch (themeMode) {
      ThemeMode.light => '浅色',
      ThemeMode.dark => '深色',
      ThemeMode.system => '跟随系统',
    };
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState.value?.isLoggedIn ?? false;
    final username = authState.value?.user?.username ?? '';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 账户与云端
          _buildSectionTitle('账户与云端'),
          if (!isLoggedIn)
            _buildSettingItem(
              icon: Icons.person_outline,
              iconColor: const Color(0xFF5B8DEF),
              title: '登录账号',
              trailingText: '未登录',
              onTap: () => Navigator.pushNamed(context, AppRoutes.login),
            )
          else ...[
            _buildSettingItem(
              icon: Icons.person,
              iconColor: const Color(0xFF5B8DEF),
              title: username,
              trailingText: '已登录',
              onTap: null,
            ),
            _buildSettingItem(
              icon: Icons.cloud_sync_outlined,
              iconColor: const Color(0xFF5B8DEF),
              title: '云端同步',
              trailingText: '自动同步: 关闭',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CloudSyncPage()),
              ),
            ),
            _buildSettingItem(
              icon: Icons.cloud_download_outlined,
              iconColor: const Color(0xFF5B8DEF),
              title: '云端数据管理',
              trailingText: '查看备份',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CloudDataPage()),
              ),
            ),
            _buildSettingItem(
              icon: Icons.logout,
              iconColor: Colors.red,
              title: '退出登录',
              trailingText: '',
              showArrow: false,
              onTap: () => _confirmLogout(context, ref),
            ),
          ],
          // 数据管理
          _buildSectionTitle('数据管理'),
          _buildSettingItem(
            icon: Icons.download_outlined,
            iconColor: const Color(0xFF34A853),
            title: '导出数据',
            trailingText: 'JSON格式',
            onTap: () => _exportData(context),
          ),
          _buildSettingItem(
            icon: Icons.upload_outlined,
            iconColor: const Color(0xFF34A853),
            title: '导入数据',
            onTap: () => _importData(context, ref),
          ),
          _buildSettingItem(
            icon: Icons.delete_outline,
            iconColor: const Color(0xFF34A853),
            title: '回收站',
            trailingText: '0条待恢复',
            onTap: () => _showDevNotice(context, '回收站'),
          ),
          _buildSettingItem(
            icon: Icons.delete_forever,
            iconColor: AppColors.danger,
            title: '清除所有数据',
            trailingText: '',
            showArrow: false,
            onTap: () => _showClearConfirm(context, ref),
          ),
          // 个性化
          _buildSectionTitle('个性化'),
          _buildSettingItem(
            icon: Icons.dark_mode_outlined,
            iconColor: const Color(0xFFFFA726),
            title: '主题',
            trailingText: themeLabel,
            onTap: () => _showThemePicker(context, ref),
          ),
          _buildSettingItem(
            icon: Icons.font_download_outlined,
            iconColor: const Color(0xFFFFA726),
            title: '字体设置',
            trailingText: '标准',
            onTap: () => _showDevNotice(context, '字体设置'),
          ),
          _buildSettingItem(
            icon: Icons.volume_up_outlined,
            iconColor: const Color(0xFFFFA726),
            title: '提醒音效',
            trailingText: '已开启',
            onTap: () => _showDevNotice(context, '提醒音效'),
          ),
          // 安全与隐私
          _buildSectionTitle('安全与隐私'),
          _buildSettingItem(
            icon: Icons.lock_outline,
            iconColor: const Color(0xFFEA4335),
            title: '应用锁',
            trailingText: '未开启',
            onTap: () => _showDevNotice(context, '应用锁'),
          ),
          // 其他
          _buildSectionTitle('其他'),
          _buildSettingItem(
            icon: Icons.help_outline,
            iconColor: const Color(0xFF9E9E9E),
            title: '使用帮助',
            onTap: () => _showDevNotice(context, '使用帮助'),
          ),
          _buildSettingItem(
            icon: Icons.share_outlined,
            iconColor: const Color(0xFF9E9E9E),
            title: '分享应用',
            onTap: () => _showDevNotice(context, '分享应用'),
          ),
          _buildSettingItem(
            icon: Icons.info_outline,
            iconColor: const Color(0xFF9E9E9E),
            title: '关于',
            trailingText: 'v1.1.0',
            onTap: () => _showAboutDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF999999))),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? trailingText,
    VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 15))),
              if (trailingText != null && trailingText.isNotEmpty)
                Text(trailingText, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
              if (showArrow) const SizedBox(width: 4),
              if (showArrow) const Icon(Icons.chevron_right, size: 18, color: Color(0xFFCCCCCC)),
            ],
          ),
        ),
      ),
    );
  }

  void _showDevNotice(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(featureName),
        content: Text('「$featureName」功能正在开发中，敬请期待！'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('知道了')),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('退出后将无法使用云端同步功能，确定要退出吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已退出登录')),
                );
              }
            },
            child: const Text('退出', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context, WidgetRef ref) {
    final current = ref.read(themeModeProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              const Text('选择主题', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
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

      final exportData = {
        'version': 1,
        'exported_at': DateTime.now().millisecondsSinceEpoch,
        'notes': notes,
        'todos': todos,
        'habits': habits,
        'checkin_records': records,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final now = DateTime.now();
      final fileName = 'noteWay_backup_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';

      String? outputPath;
      if (Platform.isAndroid) {
        final dir = await getExternalStorageDirectory();
        if (dir != null) outputPath = p.join(dir.path, fileName);
      }
      outputPath ??= p.join((await getApplicationDocumentsDirectory()).path, fileName);

      final file = File(outputPath);
      await file.writeAsString(jsonString);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('数据已导出至: $outputPath')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导出失败: $e')));
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
      final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.single.path == null) return;

      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final data = jsonDecode(jsonString) as Map<String, dynamic>;

      final db = await DatabaseHelper().database;

      await db.transaction((txn) async {
        for (final row in (data['notes'] as List<dynamic>? ?? [])) {
          await _insertOrSkip(txn, 'notes', _castMap(row));
        }
        for (final row in (data['todos'] as List<dynamic>? ?? [])) {
          await _insertOrSkip(txn, 'todos', _castMap(row));
        }
        for (final row in (data['habits'] as List<dynamic>? ?? [])) {
          await _insertOrSkip(txn, 'habits', _castMap(row));
        }
        for (final row in (data['checkin_records'] as List<dynamic>? ?? [])) {
          await _insertOrSkip(txn, 'checkin_records', _castMap(row));
        }
      });

      ref.invalidate(noteNotifierProvider);
      ref.invalidate(todoNotifierProvider);
      ref.invalidate(habitNotifierProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数据导入成功')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('导入失败: $e')));
      }
    }
  }

  Map<String, dynamic> _castMap(dynamic row) {
    final map = row as Map<String, dynamic>;
    // JSON decode 会将数字转为 int/double，确保与数据库兼容
    return map.map((key, value) {
      if (value is double && value == value.toInt().toDouble()) {
        return MapEntry(key, value.toInt());
      }
      return MapEntry(key, value);
    });
  }

  Future<void> _insertOrSkip(Transaction txn, String table, Map<String, dynamic> values) async {
    final id = values['id']?.toString();
    if (id == null || id.isEmpty) return;
    final existing = await txn.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    if (existing.isEmpty) {
      await txn.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于记途'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_note, size: 48, color: Color(0xFF5B8DEF)),
            SizedBox(height: 12),
            Text('记途', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('v1.1.0', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
            SizedBox(height: 12),
            Text(
              '一款完全离线的个人备忘录应用，\n数据完全存储在本地设备。',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF666666)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('确定')),
        ],
      ),
    );
  }

  void _showClearConfirm(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除所有数据'),
        content: const Text('此操作将删除所有笔记、待办、打卡记录及设置，且不可恢复。确定要继续吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
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
      await DatabaseHelper().close();
      final dbPath = p.join(await getDatabasesPath(), 'memo_app.db');
      final dbFile = File(dbPath);
      if (await dbFile.exists()) await dbFile.delete();
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory(p.join(appDir.path, 'images'));
      if (await imageDir.exists()) await imageDir.delete(recursive: true);
      await DatabaseHelper().database;
      ref.invalidate(noteNotifierProvider);
      ref.invalidate(todoNotifierProvider);
      ref.invalidate(habitNotifierProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('数据已清除，应用已重置')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('清除失败: $e')));
      }
    }
  }
}
