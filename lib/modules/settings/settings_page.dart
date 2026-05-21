import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_helper.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            subtitle: const Text('将笔记、待办、打卡数据导出为文件'),
            onTap: () => _showExportDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.upload, color: AppColors.secondary),
            title: const Text('导入数据'),
            subtitle: const Text('从文件恢复数据'),
            onTap: () => _showImportDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.danger),
            title: const Text('清除所有数据', style: TextStyle(color: AppColors.danger)),
            subtitle: const Text('删除所有笔记、待办和打卡记录'),
            onTap: () => _showClearConfirm(context),
          ),
          _buildSectionTitle('个性化'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('深色模式'),
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (value) {
              // TODO: implement theme switching
            },
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
            subtitle: const Text('记途 v1.0.0'),
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

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导出数据'),
        content: const Text('导出功能将在后续版本中支持。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入数据'),
        content: const Text('导入功能将在后续版本中支持。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showClearConfirm(BuildContext context) {
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
              await DatabaseHelper().close();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('数据已清除')),
                );
              }
            },
            child: const Text('清除', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}
