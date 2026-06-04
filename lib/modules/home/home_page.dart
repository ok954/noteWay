import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('记途'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTodoCard(context, todoStats, cs),
            const SizedBox(height: 12),
            _buildHabitCard(context, habitStats, habitsAsync, cs),
            const SizedBox(height: 12),
            _buildNoteCard(context, notesAsync, cs),
          ],
        ),
      ),
      floatingActionButton: _buildFAB(context, cs),
    );
  }

  Widget _buildFAB(BuildContext context, ColorScheme cs) {
    return FloatingActionButton(
      onPressed: () => _showQuickAddSheet(context),
      backgroundColor: cs.primary,
      shape: const CircleBorder(),
      child: Icon(Icons.add, color: cs.onPrimary, size: 28),
    );
  }

  Widget _buildTodoCard(BuildContext context, AsyncValue<Map<String, int>> todoStats, ColorScheme cs) {
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
    ColorScheme cs,
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
                      Text('今日已打卡 ${s['today'] ?? 0} 项', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.circle_outlined, size: 14),
                      const SizedBox(width: 4),
                      Text('今日未打卡 ${(s['total'] ?? 0) - (s['today'] ?? 0)} 项', style: TextStyle(fontSize: 13, color: cs.outline)),
                    ],
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 12),
          Divider(color: cs.outlineVariant, height: 1),
          const SizedBox(height: 8),
          habitsAsync.when(
            data: (habits) {
              final previewHabits = habits.take(4).toList();
              if (previewHabits.isEmpty) {
                return Text('暂无打卡项', style: TextStyle(fontSize: 13, color: cs.outline));
              }
              return Column(
                children: previewHabits.map((h) => _buildHabitPreviewItem(h, cs)).toList(),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitPreviewItem(Habit habit, ColorScheme cs) {
    final isCompleted = habit.todayCount > 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isCompleted ? const Color(0xFFE6F4EA) : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _habitIcon(habit.name),
              size: 16,
              color: isCompleted ? const Color(0xFF34A853) : cs.outline,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              habit.name,
              style: TextStyle(
                fontSize: 13,
                color: isCompleted ? cs.outline : cs.onSurface,
                decoration: isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (isCompleted) ...[
            Icon(Icons.check, size: 14, color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            if (habit.habitType != 'count')
              Text(
                _formatDuration(habit.todayDuration),
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
          ] else
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                border: Border.all(color: cs.outlineVariant),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoteCard(BuildContext context, AsyncValue<List<dynamic>> notesAsync, ColorScheme cs) {
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
            return Text('暂无笔记，点击添加第一条笔记', style: TextStyle(fontSize: 13, color: cs.outline));
          }
          final latest = notes.first;
          final dt = DateTime.fromMillisecondsSinceEpoch(latest.updatedAt);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '上一次编辑：${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}',
                style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                latest.title ?? latest.plainText ?? '无标题笔记',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: cs.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (latest.plainText != null && latest.plainText!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  latest.plainText!,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline, size: 20),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: Theme.of(context).colorScheme.outlineVariant, height: 1),
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
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  void _showQuickAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
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
                  color: Theme.of(context).colorScheme.outlineVariant,
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
      title: Text(title),
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
