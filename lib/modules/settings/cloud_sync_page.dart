import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/cloud_sync_provider.dart';

class CloudSyncPage extends ConsumerWidget {
  const CloudSyncPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(cloudSyncProvider);

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
          '云端同步',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 同步状态卡片
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Icon(Icons.cloud_done, size: 48, color: Color(0xFF5B8DEF)),
                  const SizedBox(height: 12),
                  const Text(
                    '云端同步',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    syncState.value?.lastSyncTime != null
                        ? '上次同步: ${syncState.value!.lastSyncTime}'
                        : '尚未同步',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: syncState.isLoading
                          ? null
                          : () => ref.read(cloudSyncProvider.notifier).syncNow(),
                      icon: syncState.isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.sync),
                      label: Text(syncState.isLoading ? '同步中...' : '立即同步'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5B8DEF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 自动同步开关
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('自动同步'),
                  subtitle: const Text('数据变更后自动上传至云端'),
                  value: false,
                  onChanged: (_) {},
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                SwitchListTile(
                  title: const Text('仅在Wi-Fi下同步'),
                  subtitle: const Text('避免消耗移动数据流量'),
                  value: true,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 同步内容选择
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '同步内容',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  _buildSyncContentItem('笔记', true),
                  _buildSyncContentItem('待办事项', true),
                  _buildSyncContentItem('打卡记录', true),
                  _buildSyncContentItem('设置偏好', false),
                ],
              ),
            ),
          ),
          if (syncState.value?.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                '同步出错: ${syncState.value!.error}',
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSyncContentItem(String title, bool enabled) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: enabled,
      onChanged: (_) {},
    );
  }
}
