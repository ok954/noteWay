import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../providers/note_provider.dart';
import '../../providers/stats_provider.dart';
import '../../providers/todo_provider.dart';
import '../../router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todoStats = ref.watch(todoStatsProvider);
    final habitStats = ref.watch(habitStatsProvider);
    final habitsAsync = ref.watch(habitNotifierProvider);
    final notesAsync = ref.watch(noteNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        title: const Text(
          '记途',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A2E),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF666666)),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 待办卡片
            _buildTodoCard(context, todoStats),
            const SizedBox(height: 12),
            // 打卡卡片
            _buildHabitCard(context, habitStats, habitsAsync),
            const SizedBox(height: 12),
            // 笔记卡片
            _buildNoteCard(context, notesAsync),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showQuickAddSheet(context),
        backgroundColor: AppColors.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildTodoCard(BuildContext context, AsyncValue<Map<String, int>> todoStats) {
    return _buildModuleCard(
      context,
      icon: Icons.check_circle_outline,
      iconColor: const Color(0xFF5B8DEF),
      bgColor: const Color(0xFFE8F0FE),
      title: '待办事项',
      onTap: () => Navigator.pushNamed(context, AppRoutes.todos),
      child: todoStats.when(
        data: (s) => Column(
          children: [
            _buildStatRow('总条数', '${s['total'] ?? 0}', const Color(0xFF5B8DEF)),
            _buildStatRow('已完成', '${s['completed'] ?? 0}', const Color(0xFF34A853)),
            _buildStatRow('今日截止', '${s['today'] ?? 0}', const Color(0xFFFBBC04)),
            _buildStatRow('未完成', '${(s['total'] ?? 0) - (s['completed'] ?? 0)}', const Color(0xFFEA4335)),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => const Center(child: Text('加载失败')),
      ),
    );
  }

  Widget _buildHabitCard(
    BuildContext context,
    AsyncValue<Map<String, int>> habitStats,
    AsyncValue<List<Habit>> habitsAsync,
  ) {
    return _buildModuleCard(
      context,
      icon: Icons.timer_outlined,
      iconColor: const Color(0xFF34A853),
      bgColor: const Color(0xFFE6F4EA),
      title: '习惯打卡',
      onTap: () => Navigator.pushNamed(context, AppRoutes.habits),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          habitStats.when(
            data: (s) => Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: Color(0xFF34A853)),
                      const SizedBox(width: 4),
                      Text('今日已打卡 ${s['today'] ?? 0} 项', style: const TextStyle(fontSize: 13, color: Color(0xFF34A853))),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.circle_outlined, size: 14, color: Color(0xFF999999)),
                      const SizedBox(width: 4),
                      Text('今日未打卡 ${(s['total'] ?? 0) - (s['today'] ?? 0)} 项', style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          habitsAsync.when(
            data: (habits) {
              final previewHabits = habits.take(4).toList();
              if (previewHabits.isEmpty) {
                return const Text('暂无打卡项', style: TextStyle(fontSize: 13, color: AppColors.textHint));
              }
              return Column(
                children: previewHabits.map((h) => _buildHabitPreviewItem(h)).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitPreviewItem(Habit habit) {
    final isCompleted = habit.todayCount > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFFE6F4EA) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _habitIcon(habit.name),
              size: 16,
              color: isCompleted ? const Color(0xFF34A853) : const Color(0xFF999999),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              habit.name,
              style: TextStyle(
                fontSize: 13,
                color: isCompleted ? const Color(0xFF999999) : const Color(0xFF333333),
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (isCompleted) ...[
            const Icon(Icons.check, size: 14, color: Color(0xFF34A853)),
            const SizedBox(width: 4),
            if (habit.habitType != 'count')
              Text(
                _formatDuration(habit.todayDuration),
                style: const TextStyle(fontSize: 12, color: Color(0xFF34A853)),
              ),
          ] else
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDDDDDD)),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, AsyncValue<List<dynamic>> notesAsync) {
    return _buildModuleCard(
      context,
      icon: Icons.note_outlined,
      iconColor: const Color(0xFFFFA726),
      bgColor: const Color(0xFFFFF3E0),
      title: '笔记',
      onTap: () => Navigator.pushNamed(context, AppRoutes.notes),
      child: notesAsync.when(
        data: (notes) {
          if (notes.isEmpty) {
            return const Text('暂无笔记，点击添加第一条笔记', style: TextStyle(fontSize: 13, color: AppColors.textHint));
          }
          final latest = notes.first;
          final dt = DateTime.fromMillisecondsSinceEpoch(latest.updatedAt);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '上一次编辑：${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(
                latest.title ?? latest.plainText ?? '无标题笔记',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF333333)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (latest.plainText != null && latest.plainText!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  latest.plainText!,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        error: (_, __) => const Center(child: Text('加载失败')),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                  ),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 20),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: valueColor.withValues(alpha: 0.4), shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF666666))),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor),
          ),
        ],
      ),
    );
  }

  void _showQuickAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              _buildQuickAddItem(
                icon: Icons.note_add,
                color: const Color(0xFFFFA726),
                title: '新建笔记',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.noteEdit);
                },
              ),
              _buildQuickAddItem(
                icon: Icons.check_box,
                color: const Color(0xFF5B8DEF),
                title: '新建待办',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.todos);
                },
              ),
              _buildQuickAddItem(
                icon: Icons.timer,
                color: const Color(0xFF34A853),
                title: '新建打卡',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.habits);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAddItem({
    required IconData icon,
    required Color color,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15)),
      onTap: onTap,
    );
  }

  IconData _habitIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('书') || n.contains('读')) return Icons.menu_book;
    if (n.contains('跑') || n.contains('步') || n.contains('运动')) return Icons.directions_run;
    if (n.contains('水')) return Icons.local_drink;
    if (n.contains('想') || n.contains('冥想')) return Icons.self_improvement;
    if (n.contains('琴') || n.contains('吉他')) return Icons.music_note;
    if (n.contains('写')) return Icons.edit;
    return Icons.star;
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final parts = <String>[];
    if (h > 0) parts.add('${h}小时');
    if (m > 0) parts.add('${m}分');
    parts.add('${s}秒');
    return parts.join('');
  }
}
