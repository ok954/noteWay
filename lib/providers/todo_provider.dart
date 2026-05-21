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

class TodoNotifier extends StateNotifier<AsyncValue<List<Todo>>> {
  final TodoRepository _repository;

  TodoNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTodos();
  }

  Future<void> loadTodos() async {
    state = const AsyncValue.loading();
    try {
      final todos = await _repository.getAllTodos();
      state = AsyncValue.data(todos);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTodo(Todo todo) async {
    await _repository.insertTodo(todo);
    await loadTodos();
  }

  Future<void> updateTodo(Todo todo) async {
    await _repository.updateTodo(todo);
    await loadTodos();
  }

  Future<void> deleteTodo(String id) async {
    await _repository.deleteTodo(id);
    await loadTodos();
  }

  Future<void> toggleComplete(Todo todo) async {
    final updated = todo.copyWith(isCompleted: !todo.isCompleted);
    await _repository.updateTodo(updated);
    await loadTodos();
  }
}

final todoNotifierProvider = StateNotifierProvider<TodoNotifier, AsyncValue<List<Todo>>>((ref) {
  final repo = ref.watch(todoRepositoryProvider);
  return TodoNotifier(repo);
});
