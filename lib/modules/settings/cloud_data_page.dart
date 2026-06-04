import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cloud_sync_provider.dart';

class CloudDataPage extends ConsumerWidget {
  const CloudDataPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(cloudSyncProvider);

    // 进入页面时自动获取备份列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (syncState.value?.backups.isEmpty ?? true) {
        ref.read(cloudSyncProvider.notifier).fetchBackups();
      }
    });

    final backups = syncState.value?.backups ?? [];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '云端数据管理',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 存储空间概览
          Card(
            elevation: 0,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '存储空间',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: backups.isEmpty ? 0 : 0.3,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFEEEEEE),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5B8DEF)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '已使用 30% (约 300MB / 1GB)',
                    style: TextStyle(fontSize: 12, color: Color(0xFF999999)),
                  ),
                ],
              ),
            ),
          ),
          // 备份列表
          Expanded(
            child: syncState.isLoading && backups.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : backups.isEmpty
                    ? const Center(
                        child: Text(
                          '暂无云端备份\n同步后会在此显示',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0xFF999999)),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: backups.length,
                        itemBuilder: (context, index) {
                          final backup = backups[index];
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.backup, color: Color(0xFF5B8DEF)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              backup.formattedTime,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              '${backup.noteCount}条笔记 · ${backup.todoCount}条待办 · ${backup.habitCount}条打卡',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF999999),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (backup.deviceInfo != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      '设备: ${backup.deviceInfo}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFFAAAAAA),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _confirmRestore(context, ref, backup.id),
                                          icon: const Icon(Icons.restore, size: 16),
                                          label: const Text('恢复此版本'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFF5B8DEF),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () => _confirmDelete(context, ref, backup.id),
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // 底部操作
          if (backups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _confirmRestoreLatest(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B8DEF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('恢复最新备份'),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _confirmRestore(BuildContext context, WidgetRef ref, String backupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('恢复数据'),
        content: const Text('恢复后当前数据将被覆盖，确定要恢复吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(cloudSyncProvider.notifier).restoreBackup(backupId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('数据恢复成功')),
                );
              }
            },
            child: const Text('恢复', style: TextStyle(color: Color(0xFF5B8DEF))),
          ),
        ],
      ),
    );
  }

  void _confirmRestoreLatest(BuildContext context, WidgetRef ref) {
    final backups = ref.read(cloudSyncProvider).value?.backups ?? [];
    if (backups.isEmpty) return;
    _confirmRestore(context, ref, backups.first.id);
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String backupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除备份'),
        content: const Text('删除后无法恢复，确定要删除吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(cloudSyncProvider.notifier).deleteBackup(backupId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('备份已删除')),
                );
              }
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
