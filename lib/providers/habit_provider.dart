import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/habit.dart';
import '../repositories/habit_repository.dart';

final habitRepositoryProvider = Provider((ref) => HabitRepository());

final habitsProvider = FutureProvider<List<Habit>>((ref) async {
  final repo = ref.watch(habitRepositoryProvider);
  return await repo.getAllHabits();
});

final habitTagsProvider = FutureProvider<List<HabitTag>>((ref) async {
  final repo = ref.watch(habitRepositoryProvider);
  return await repo.getHabitTags();
});

class HabitNotifier extends AsyncNotifier<List<Habit>> {
  @override
  Future<List<Habit>> build() async {
    final repo = ref.read(habitRepositoryProvider);
    return await repo.getAllHabits();
  }

  Future<void> loadHabits() async {
    state = const AsyncValue.loading();
    final repo = ref.read(habitRepositoryProvider);
    state = await AsyncValue.guard(() => repo.getAllHabits());
  }

  Future<void> addHabit(Habit habit) async {
    final repo = ref.read(habitRepositoryProvider);
    await repo.insertHabit(habit);
    ref.invalidateSelf();
  }

  Future<void> updateHabit(Habit habit) async {
    final repo = ref.read(habitRepositoryProvider);
    await repo.updateHabit(habit);
    ref.invalidateSelf();
  }

  Future<void> deleteHabit(String id) async {
    final repo = ref.read(habitRepositoryProvider);
    await repo.deleteHabit(id);
    ref.invalidateSelf();
  }
}

final habitNotifierProvider = AsyncNotifierProvider<HabitNotifier, List<Habit>>(() => HabitNotifier());
