import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../models/checkin_record.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../providers/stats_provider.dart';
import '../../repositories/habit_repository.dart';
import '../../router.dart';

class HabitListPage extends ConsumerWidget {
  const HabitListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '习惯打卡',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF333333)),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('更多选项'),
                  content: const Text('「更多选项」功能正在开发中，敬请期待！'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('知道了')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: habitsAsync.when(
        data: (habits) {
          if (habits.isEmpty) {
            return const Center(
              child: Text('暂无打卡项，点击右下角添加', style: TextStyle(color: Color(0xFF999999))),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: habits.length,
            itemBuilder: (context, index) {
              final habit = habits[index];
              return _HabitItem(
                habit: habit,
                onCheckin: () => _checkinHabit(context, ref, habit),
                onTimer: () => Navigator.pushNamed(
                  context,
                  AppRoutes.timer,
                  arguments: habit.id,
                ),
                onDelete: () async {
                  await ref.read(habitNotifierProvider.notifier).deleteHabit(habit.id);
                  ref.invalidate(habitStatsProvider);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        backgroundColor: const Color(0xFF34A853),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<void> _checkinHabit(BuildContext context, WidgetRef ref, Habit habit) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final record = CheckinRecord(
      id: const Uuid().v4(),
      habitId: habit.id,
      recordType: 'count',
      startTime: now,
      endTime: now,
      duration: 0,
      isCompleted: true,
      createdAt: now,
    );
    await ref.read(habitRepositoryProvider).insertCheckinRecord(record);
    final updated = habit.copyWith(
      todayCount: habit.todayCount + 1,
      checkinCount: habit.checkinCount + 1,
      lastCheckinAt: now,
      updatedAt: now,
    );
    await ref.read(habitNotifierProvider.notifier).updateHabit(updated);
    ref.invalidate(habitStatsProvider);
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String habitType = 'count';
    int? planDuration;
    String? selectedTag;

    final mq = MediaQuery.of(context);
    final isWide = mq.size.width > 600;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: EdgeInsets.symmetric(
            horizontal: isWide ? mq.size.width * 0.25 : 20,
            vertical: 20,
          ),
          title: const Text('新建打卡', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          content: ConstrainedBox(
            constraints: BoxConstraints(minWidth: isWide ? 420 : 280),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: '输入打卡内容',
                      prefixIcon: Icon(Icons.edit),
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 16),
                  const Text('标签', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF999999))),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['健康', '学习', '习惯'].map((tag) {
                      final isSelected = selectedTag == tag;
                      return ChoiceChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => selectedTag = selected ? tag : null);
                        },
                        selectedColor: const Color(0xFFE6F4EA),
                        backgroundColor: const Color(0xFFF5F5F5),
                        labelStyle: TextStyle(
                          color: isSelected ? const Color(0xFF34A853) : const Color(0xFF666666),
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('类型', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF999999))),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'countdown', label: Text('倒计时')),
                      ButtonSegment(value: 'timer', label: Text('正向计时')),
                      ButtonSegment(value: 'count', label: Text('不计时')),
                    ],
                    selected: {habitType},
                    onSelectionChanged: (selected) {
                      if (selected.isNotEmpty) {
                        setState(() => habitType = selected.first);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 60,
                    child: switch (habitType) {
                      'countdown' => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('时长', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF999999))),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                _buildDurationChip('10分钟', 10, planDuration, (v) => setState(() => planDuration = v)),
                                _buildDurationChip('30分钟', 30, planDuration, (v) => setState(() => planDuration = v)),
                                _buildDurationChip('60分钟', 60, planDuration, (v) => setState(() => planDuration = v)),
                              ],
                            ),
                          ],
                        ),
                      'timer' => const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('适合碎片时间记录', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                        ),
                      _ => const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('适合不需要计时的打卡内容，比如吃药', style: TextStyle(fontSize: 12, color: Color(0xFF999999))),
                        ),
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('请输入打卡名称')),
                  );
                  return;
                }
                final now = DateTime.now().millisecondsSinceEpoch;
                await ref.read(habitNotifierProvider.notifier).addHabit(
                  Habit(
                    id: const Uuid().v4(),
                    name: name,
                    tag: selectedTag,
                    habitType: habitType,
                    planDuration: habitType == 'countdown' ? (planDuration ?? 30) * 60 : null,
                    createdAt: now,
                    updatedAt: now,
                  ),
                );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationChip(
    String label,
    int minutes,
    int? selected,
    ValueChanged<int?> onSelected,
  ) {
    final isSelected = selected == minutes;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (sel) => onSelected(sel ? minutes : null),
      selectedColor: const Color(0xFFE8F0FE),
      backgroundColor: const Color(0xFFF5F5F5),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF5B8DEF) : const Color(0xFF666666),
        fontSize: 13,
      ),
    );
  }
}

class _HabitItem extends StatelessWidget {
  final Habit habit;
  final VoidCallback onCheckin;
  final VoidCallback onTimer;
  final VoidCallback onDelete;

  const _HabitItem({
    required this.habit,
    required this.onCheckin,
    required this.onTimer,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompletedToday = habit.todayCount > 0;
    final typeLabel = _getTypeLabel(habit.habitType);
    final typeColor = _getTypeColor(habit.habitType);

    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _habitIcon(habit.name),
                  color: typeColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: typeColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            typeLabel,
                            style: TextStyle(fontSize: 11, color: typeColor),
                          ),
                        ),
                        if (habit.habitType == 'countdown' && habit.planDuration != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${habit.planDuration! ~/ 60}分钟',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (habit.habitType != 'count')
                      Text(
                        '累计时长: ${_formatDuration(habit.totalDuration)}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF999999)),
                      )
                    else
                      Text(
                        isCompletedToday ? '今日已完成' : '今日未完成',
                        style: TextStyle(
                          fontSize: 12,
                          color: isCompletedToday ? const Color(0xFF34A853) : const Color(0xFF999999),
                        ),
                      ),
                  ],
                ),
              ),
              if (isCompletedToday && habit.habitType == 'count')
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('已完成', style: TextStyle(fontSize: 13, color: Color(0xFF34A853))),
                )
              else
                ElevatedButton(
                  onPressed: habit.habitType == 'count' ? onCheckin : onTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isCompletedToday ? const Color(0xFFE8E8E8) : const Color(0xFF5B8DEF),
                    foregroundColor: isCompletedToday ? const Color(0xFF999999) : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    isCompletedToday ? '已完成' : (habit.habitType == 'count' ? '完成' : '开始'),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'countdown':
        return '倒计时';
      case 'timer':
        return '正向计时';
      case 'count':
        return '不计时';
      default:
        return '不计时';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'countdown':
        return const Color(0xFFEA4335);
      case 'timer':
        return const Color(0xFF5B8DEF);
      case 'count':
        return const Color(0xFF34A853);
      default:
        return const Color(0xFF34A853);
    }
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
