import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/todo.dart';
import '../repositories/todo_repository.dart';

final todoRepositoryProvider = Provider((ref) => TodoRepository());

final todosProvider = FutureProvider<List<Todo>>((ref) async {
  final repo = ref.watch(todoRepositoryProvider);
  return await repo.getAllTodos();
});

final todoTypesProvider = FutureProvider<List<TodoType>>((ref) async {
  final repo = ref.watch(todoRepositoryProvider);
  return await repo.getTodoTypes();
});

class TodoNotifier extends AsyncNotifier<List<Todo>> {
  @override
  Future<List<Todo>> build() async {
    final repo = ref.read(todoRepositoryProvider);
    return await repo.getAllTodos();
  }

  Future<void> loadTodos() async {
    state = const AsyncValue.loading();
    final repo = ref.read(todoRepositoryProvider);
    state = await AsyncValue.guard(() => repo.getAllTodos());
  }

  Future<void> addTodo(Todo todo) async {
    final repo = ref.read(todoRepositoryProvider);
    await repo.insertTodo(todo);
    ref.invalidateSelf();
  }

  Future<void> updateTodo(Todo todo) async {
    final repo = ref.read(todoRepositoryProvider);
    await repo.updateTodo(todo);
    ref.invalidateSelf();
  }

  Future<void> deleteTodo(String id) async {
    final repo = ref.read(todoRepositoryProvider);
    await repo.deleteTodo(id);
    ref.invalidateSelf();
  }

  Future<void> toggleComplete(Todo todo) async {
    final updated = todo.copyWith(isCompleted: !todo.isCompleted);
    final repo = ref.read(todoRepositoryProvider);
    await repo.updateTodo(updated);
    ref.invalidateSelf();
  }
}

final todoNotifierProvider = AsyncNotifierProvider<TodoNotifier, List<Todo>>(() => TodoNotifier());
