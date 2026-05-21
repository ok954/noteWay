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

class HabitNotifier extends StateNotifier<AsyncValue<List<Habit>>> {
  final HabitRepository _repository;

  HabitNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadHabits();
  }

  Future<void> loadHabits() async {
    state = const AsyncValue.loading();
    try {
      final habits = await _repository.getAllHabits();
      state = AsyncValue.data(habits);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addHabit(Habit habit) async {
    await _repository.insertHabit(habit);
    await loadHabits();
  }

  Future<void> updateHabit(Habit habit) async {
    await _repository.updateHabit(habit);
    await loadHabits();
  }

  Future<void> deleteHabit(String id) async {
    await _repository.deleteHabit(id);
    await loadHabits();
  }
}

final habitNotifierProvider = StateNotifierProvider<HabitNotifier, AsyncValue<List<Habit>>>((ref) {
  final repo = ref.watch(habitRepositoryProvider);
  return HabitNotifier(repo);
});
