import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/constants/app_colors.dart';
import '../../models/todo.dart';
import '../../providers/todo_provider.dart';

class TodoListPage extends ConsumerStatefulWidget {
  const TodoListPage({super.key});

  @override
  ConsumerState<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends ConsumerState<TodoListPage> {
  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(todoNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('待办事项'),
      ),
      body: todosAsync.when(
        data: (todos) {
          if (todos.isEmpty) {
            return const Center(child: Text('暂无待办，点击右下角添加'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: todos.length,
            itemBuilder: (context, index) {
              final todo = todos[index];
              return _TodoItem(
                todo: todo,
                onToggle: () => ref.read(todoNotifierProvider.notifier).toggleComplete(todo),
                onDelete: () => ref.read(todoNotifierProvider.notifier).deleteTodo(todo.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('错误: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建待办'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: '输入待办事项'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                final now = DateTime.now().millisecondsSinceEpoch;
                await ref.read(todoNotifierProvider.notifier).addTodo(
                  Todo(
                    id: const Uuid().v4(),
                    title: title,
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
    );
  }
}

class _TodoItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TodoItem({
    required this.todo,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(todo.id),
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
        child: ListTile(
          leading: Checkbox(
            value: todo.isCompleted,
            onChanged: (_) => onToggle(),
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
              color: todo.isCompleted ? AppColors.textHint : AppColors.textPrimary,
            ),
          ),
          subtitle: todo.dueDate != null
              ? Text(
                  _formatDate(todo.dueDate!),
                  style: TextStyle(
                    fontSize: 12,
                    color: _isOverdue(todo.dueDate!) ? AppColors.danger : AppColors.textSecondary,
                  ),
                )
              : null,
          trailing: _PriorityBadge(priority: todo.priority),
        ),
      ),
    );
  }

  String _formatDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.month}/${dt.day}';
  }

  bool _isOverdue(int ms) {
    return DateTime.fromMillisecondsSinceEpoch(ms).isBefore(DateTime.now());
  }
}

class _PriorityBadge extends StatelessWidget {
  final String priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (priority) {
      case 'high':
        color = AppColors.todoHigh;
        break;
      case 'low':
        color = AppColors.todoLow;
        break;
      default:
        color = AppColors.todoMedium;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
