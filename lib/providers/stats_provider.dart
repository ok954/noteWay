import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/habit_provider.dart';
import '../providers/todo_provider.dart';

/// 首页待办统计
final todoStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(todoRepositoryProvider);
  final total = await repo.getTotalCount();
  final completed = await repo.getCompletedCount();
  final today = await repo.getTodayDueCount();
  return {'total': total, 'completed': completed, 'today': today};
});

/// 首页打卡统计
final habitStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.watch(habitRepositoryProvider);
  final total = await repo.getTotalHabitCount();
  final today = await repo.getTodayCheckedCount();
  return {'total': total, 'today': today};
});
