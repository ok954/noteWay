import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/todo_provider.dart';
import '../../providers/habit_provider.dart';
import '../../providers/note_provider.dart';
import '../../router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoStats = ref.watch(_todoStatsProvider);
    final habitStats = ref.watch(_habitStatsProvider);
    final notesAsync = ref.watch(noteNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('记途', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard(
              context,
              icon: Icons.check_circle_outline,
              iconColor: AppColors.todoHigh,
              title: '待办事项',
              subtitle: todoStats.when(
                data: (s) => '共 ${s['total']} 条 · 已完成 ${s['completed']} · 今日截止 ${s['today']}',
                loading: () => '加载中...',
                error: (_, __) => '加载失败',
              ),
              onTap: () => Navigator.pushNamed(context, AppRoutes.todos),
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              context,
              icon: Icons.timer_outlined,
              iconColor: AppColors.secondary,
              title: '打卡记录',
              subtitle: habitStats.when(
                data: (s) => '今日已打卡 ${s['today']} / ${s['total']}',
                loading: () => '加载中...',
                error: (_, __) => '加载失败',
              ),
              onTap: () => Navigator.pushNamed(context, AppRoutes.habits),
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              context,
              icon: Icons.note_outlined,
              iconColor: AppColors.primary,
              title: '笔记',
              subtitle: notesAsync.when(
                data: (notes) {
                  if (notes.isEmpty) return '暂无笔记';
                  final latest = notes.first;
                  return '最近: ${latest.title ?? latest.plainText ?? '无标题'}';
                },
                loading: () => '加载中...',
                error: (_, __) => '加载失败',
              ),
              onTap: () => Navigator.pushNamed(context, AppRoutes.notes),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickAddSheet(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.note_add, color: AppColors.primary),
              title: const Text('新建笔记'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.noteEdit);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_box, color: AppColors.todoHigh),
              title: const Text('新建待办'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.todos);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timer, color: AppColors.secondary),
              title: const Text('新建打卡'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.habits);
              },
            ),
          ],
        ),
      ),
    );
  }
}

final _todoStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(todoRepositoryProvider);
  final total = await repo.getTotalCount();
  final completed = await repo.getCompletedCount();
  final today = await repo.getTodayDueCount();
  return {'total': total, 'completed': completed, 'today': today};
});

final _habitStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(habitRepositoryProvider);
  final total = await repo.getTotalHabitCount();
  final today = await repo.getTodayCheckedCount();
  return {'total': total, 'today': today};
});
