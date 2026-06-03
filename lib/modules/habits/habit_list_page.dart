import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../models/checkin_record.dart';
import '../../models/habit.dart';
import '../../providers/habit_provider.dart';
import '../../repositories/habit_repository.dart';
import '../../router.dart';

class HabitListPage extends ConsumerWidget {
  const HabitListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('打卡'),
      ),
      body: habitsAsync.when(
        data: (habits) {
          if (habits.isEmpty) {
            return const Center(child: Text('暂无打卡项，点击右下角添加'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
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
                onDelete: () => ref.read(habitNotifierProvider.notifier).deleteHabit(habit.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add),
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
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String habitType = 'count';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('新建打卡'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(hintText: '打卡名称'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'count', label: Text('计数')),
                  ButtonSegment(value: 'timer', label: Text('正向计时')),
                  ButtonSegment(value: 'countdown', label: Text('倒计时')),
                ],
                selected: {habitType},
                onSelectionChanged: (selected) {
                  setState(() => habitType = selected.first);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final now = DateTime.now().millisecondsSinceEpoch;
                  await ref.read(habitNotifierProvider.notifier).addHabit(
                    Habit(
                      id: const Uuid().v4(),
                      name: name,
                      habitType: habitType,
                      createdAt: now,
                      updatedAt: now,
                    ),
                  );
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('添加'),
            ),
          ],
        ),
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
    return Dismissible(
      key: Key(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
                    ),
                    if (habit.tag != null)
                      Chip(
                        label: Text(habit.tag!, style: const TextStyle(fontSize: 10)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    Text(
                      '累计 ${habit.checkinCount} 次 · 今日 ${habit.todayCount} 次',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              if (habit.habitType == 'count')
                ElevatedButton(
                  onPressed: onCheckin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('完成'),
                )
              else
                ElevatedButton(
                  onPressed: onTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('开始'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
