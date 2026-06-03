import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../models/todo.dart';
import '../../providers/todo_provider.dart';
import '../../repositories/todo_repository.dart';

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
                onToggle: () => _toggleWithAnimation(todo),
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

  Future<void> _toggleWithAnimation(Todo todo) async {
    // 先更新数据库状态
    final updated = todo.copyWith(isCompleted: !todo.isCompleted);
    final repo = ref.read(todoRepositoryProvider);
    await repo.updateTodo(updated);
    // 延迟刷新让动画播放
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) {
      ref.invalidate(todoNotifierProvider);
    }
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _TodoAddDialog(),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 8),
      child: Dismissible(
        key: Key(todo.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (_) => onDelete(),
        child: Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            leading: Checkbox(
              value: todo.isCompleted,
              onChanged: (_) => onToggle(),
            ),
            title: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                color: todo.isCompleted ? AppColors.textHint : AppColors.textPrimary,
                fontSize: 16,
              ),
              child: Text(todo.title),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (todo.content != null && todo.content!.isNotEmpty)
                  Text(
                    todo.content!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                if (todo.dueDate != null)
                  Text(
                    _formatDate(todo.dueDate!),
                    style: TextStyle(
                      fontSize: 12,
                      color: _isOverdue(todo.dueDate!) && !todo.isCompleted
                          ? AppColors.danger
                          : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PriorityBadge(priority: todo.priority),
                if (todo.isPinned)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.push_pin, size: 14, color: AppColors.primary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${dt.month}月${dt.day}日 ${_formatTime(dt)}';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
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

class _TodoAddDialog extends ConsumerStatefulWidget {
  const _TodoAddDialog();

  @override
  ConsumerState<_TodoAddDialog> createState() => _TodoAddDialogState();
}

class _TodoAddDialogState extends ConsumerState<_TodoAddDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _priority = 'medium';
  DateTime? _dueDate;
  String? _selectedType;
  bool _continuousAdd = false;
  bool _isPinned = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(todoTypesProvider);

    return AlertDialog(
      title: const Text('新建待办'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '待办标题 *',
                prefixIcon: Icon(Icons.title),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                hintText: '备注（可选）',
                prefixIcon: Icon(Icons.notes),
              ),
              maxLines: 3,
              minLines: 2,
            ),
            const SizedBox(height: 16),
            const Text('优先级', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'high', label: Text('高'), icon: Icon(Icons.priority_high)),
                ButtonSegment(value: 'medium', label: Text('中')),
                ButtonSegment(value: 'low', label: Text('低')),
              ],
              selected: {_priority},
              onSelectionChanged: (selected) {
                if (selected.isNotEmpty) {
                  setState(() => _priority = selected.first);
                }
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('截止日期'),
              subtitle: Text(
                _dueDate != null
                    ? '${_dueDate!.month}月${_dueDate!.day}日 ${_dueDate!.hour.toString().padLeft(2, '0')}:${_dueDate!.minute.toString().padLeft(2, '0')}'
                    : '未设置',
              ),
              trailing: _dueDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _dueDate = null),
                    )
                  : null,
              onTap: _pickDueDate,
            ),
            const SizedBox(height: 8),
            typesAsync.when(
              data: (types) {
                if (types.isEmpty) return const SizedBox.shrink();
                return DropdownButtonFormField<String?>(
                  value: _selectedType,
                  decoration: const InputDecoration(
                    labelText: '类型',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('无类型')),
                    ...types.map((t) => DropdownMenuItem(value: t.name, child: Text(t.name))),
                  ],
                  onChanged: (value) => setState(() => _selectedType = value),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('置顶'),
              value: _isPinned,
              onChanged: (value) => setState(() => _isPinned = value ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('连续添加模式'),
              value: _continuousAdd,
              onChanged: (value) => setState(() => _continuousAdd = value ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _addTodo,
          child: const Text('添加'),
        ),
      ],
    );
  }

  Future<void> _pickDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;

    setState(() {
      _dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _addTodo() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请输入待办标题')),
        );
      }
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await ref.read(todoNotifierProvider.notifier).addTodo(
      Todo(
        id: const Uuid().v4(),
        title: title,
        content: _contentController.text.trim().isEmpty ? null : _contentController.text.trim(),
        type: _selectedType,
        dueDate: _dueDate?.millisecondsSinceEpoch,
        priority: _priority,
        isPinned: _isPinned,
        createdAt: now,
        updatedAt: now,
      ),
    );

    if (_continuousAdd && mounted) {
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _priority = 'medium';
        _dueDate = null;
        _selectedType = null;
        _isPinned = false;
      });
      // 保持弹窗打开
    } else if (mounted) {
      Navigator.pop(context);
    }
  }
}
