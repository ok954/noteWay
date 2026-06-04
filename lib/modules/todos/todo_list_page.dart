import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants/app_colors.dart';
import '../../models/todo.dart';
import '../../providers/stats_provider.dart';
import '../../providers/todo_provider.dart';
import '../../repositories/todo_repository.dart';

class TodoListPage extends ConsumerStatefulWidget {
  const TodoListPage({super.key});

  @override
  ConsumerState<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends ConsumerState<TodoListPage> {
  String? _selectedType;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final todosAsync = ref.watch(todoNotifierProvider);
    final typesAsync = ref.watch(todoTypesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('待办事项', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
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
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜索待办事项',
                      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFFBBBBBB)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Color(0xFFBBBBBB)),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                typesAsync.when(
                  data: (types) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: _selectedType,
                        hint: const Text('全部类型', style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('全部类型', style: TextStyle(fontSize: 13))),
                          ...types.map((t) => DropdownMenuItem(value: t.name, child: Text(t.name, style: const TextStyle(fontSize: 13)))),
                        ],
                        onChanged: (value) => setState(() => _selectedType = value),
                      ),
                    ),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          // 列表
          Expanded(
            child: todosAsync.when(
              data: (todos) {
                var filtered = todos;
                if (_selectedType != null) {
                  filtered = filtered.where((t) => t.type == _selectedType).toList();
                }
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((t) =>
                    t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                    (t.content?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false),
                  ).toList();
                }
                if (filtered.isEmpty) {
                  return const Center(child: Text('暂无待办', style: TextStyle(color: Color(0xFF999999))));
                }
                return _buildGroupedList(filtered);
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('错误: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGroupedList(List<Todo> todos) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    final tomorrowStart = todayEnd;
    final tomorrowEnd = tomorrowStart.add(const Duration(days: 1));
    final weekEnd = todayStart.add(const Duration(days: 7));

    final today = <Todo>[];
    final tomorrow = <Todo>[];
    final thisWeek = <Todo>[];
    final completed = <Todo>[];
    final other = <Todo>[];

    for (final todo in todos) {
      if (todo.isCompleted) {
        completed.add(todo);
      } else if (todo.dueDate != null) {
        final due = DateTime.fromMillisecondsSinceEpoch(todo.dueDate!);
        if (due.isAfter(todayStart) && due.isBefore(todayEnd)) {
          today.add(todo);
        } else if (due.isAfter(tomorrowStart) && due.isBefore(tomorrowEnd)) {
          tomorrow.add(todo);
        } else if (due.isAfter(todayStart) && due.isBefore(weekEnd)) {
          thisWeek.add(todo);
        } else {
          other.add(todo);
        }
      } else {
        other.add(todo);
      }
    }

    final groups = <_TodoGroup>[];
    if (today.isNotEmpty) groups.add(_TodoGroup('今天', today.length, today));
    if (tomorrow.isNotEmpty) groups.add(_TodoGroup('明天', tomorrow.length, tomorrow));
    if (thisWeek.isNotEmpty) groups.add(_TodoGroup('本周', thisWeek.length, thisWeek));
    if (other.isNotEmpty) groups.add(_TodoGroup('稍后', other.length, other));
    if (completed.isNotEmpty) groups.add(_TodoGroup('已完成', completed.length, completed));

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: groups.length,
      itemBuilder: (context, groupIndex) {
        final group = groups[groupIndex];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              child: Row(
                children: [
                  Text(
                    group.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8E8E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${group.count}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF666666)),
                    ),
                  ),
                ],
              ),
            ),
            ...group.todos.map((todo) => _TodoItem(
              todo: todo,
              onToggle: () => _toggleWithDelay(todo),
              onDelete: () async {
                await ref.read(todoNotifierProvider.notifier).deleteTodo(todo.id);
                ref.invalidate(todoStatsProvider);
              },
              onPin: () => _togglePin(todo),
            )),
          ],
        );
      },
    );
  }

  Future<void> _toggleWithDelay(Todo todo) async {
    final updated = todo.copyWith(isCompleted: !todo.isCompleted);
    final repo = ref.read(todoRepositoryProvider);
    await repo.updateTodo(updated);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      ref.invalidate(todoNotifierProvider);
      ref.invalidate(todoStatsProvider);
    }
  }

  Future<void> _togglePin(Todo todo) async {
    final updated = todo.copyWith(isPinned: !todo.isPinned);
    final repo = ref.read(todoRepositoryProvider);
    await repo.updateTodo(updated);
    ref.invalidate(todoNotifierProvider);
    ref.invalidate(todoStatsProvider);
  }

  void _showAddDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const _TodoAddDialog());
  }
}

class _TodoGroup {
  final String title;
  final int count;
  final List<Todo> todos;
  _TodoGroup(this.title, this.count, this.todos);
}

class _TodoItem extends StatelessWidget {
  final Todo todo;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onPin;

  const _TodoItem({
    required this.todo,
    required this.onToggle,
    required this.onDelete,
    required this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(todo.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  value: todo.isCompleted,
                  onChanged: (_) => onToggle(),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  side: const BorderSide(color: Color(0xFFCCCCCC)),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        decoration: todo.isCompleted ? TextDecoration.lineThrough : null,
                        color: todo.isCompleted ? const Color(0xFFAAAAAA) : const Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: [
                        if (todo.type != null)
                          _buildTag(todo.type!, const Color(0xFFE8F0FE), const Color(0xFF5B8DEF)),
                        if (todo.dueDate != null)
                          _buildTag(
                            _formatDate(todo.dueDate!),
                            _isOverdue(todo.dueDate!) && !todo.isCompleted
                                ? const Color(0xFFFFEBEE)
                                : const Color(0xFFF5F5F5),
                            _isOverdue(todo.dueDate!) && !todo.isCompleted
                                ? const Color(0xFFEA4335)
                                : const Color(0xFF666666),
                          ),
                        _buildPriorityTag(todo.priority),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: Icon(
                      todo.isPinned ? Icons.star : Icons.star_border,
                      size: 20,
                      color: todo.isPinned ? const Color(0xFFFFB300) : const Color(0xFFCCCCCC),
                    ),
                    onPressed: onPin,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(4)),
      child: Text(text, style: TextStyle(fontSize: 11, color: textColor)),
    );
  }

  Widget _buildPriorityTag(String priority) {
    Color color;
    String label;
    switch (priority) {
      case 'high':
        color = const Color(0xFFEA4335);
        label = '高优先级';
        break;
      case 'low':
        color = const Color(0xFF34A853);
        label = '低优先级';
        break;
      default:
        color = const Color(0xFFFBBC04);
        label = '中优先级';
    }
    return _buildTag(label, color.withValues(alpha: 0.1), color);
  }

  String _formatDate(int ms) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ms);
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return '今天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    return '${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  bool _isOverdue(int ms) {
    return DateTime.fromMillisecondsSinceEpoch(ms).isBefore(DateTime.now());
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
    final mq = MediaQuery.of(context);
    final isWide = mq.size.width > 600;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isWide ? mq.size.width * 0.25 : 20,
        vertical: 20,
      ),
      title: const Text('新建待办', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      content: ConstrainedBox(
        constraints: BoxConstraints(minWidth: isWide ? 420 : 280),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSection(
                label: '标题',
                child: TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    hintText: '待办标题 *',
                    prefixIcon: Icon(Icons.title),
                  ),
                  autofocus: true,
                ),
              ),
              _buildSection(
                label: '备注',
                child: TextField(
                  controller: _contentController,
                  decoration: const InputDecoration(
                    hintText: '备注（可选）',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 3,
                  minLines: 2,
                ),
              ),
              _buildSection(
                label: '优先级',
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'high', label: Text('高')),
                    ButtonSegment(value: 'medium', label: Text('中')),
                    ButtonSegment(value: 'low', label: Text('低')),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (selected) {
                    if (selected.isNotEmpty) setState(() => _priority = selected.first);
                  },
                ),
              ),
              _buildSection(
                label: '截止日期',
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
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
              ),
              _buildSection(
                label: '类型',
                child: typesAsync.when(
                  data: (types) {
                    if (types.isEmpty) return const SizedBox.shrink();
                    return DropdownButtonFormField<String?>(
                      value: _selectedType,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.category),
                      ),
                      hint: const Text('选择类型'),
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
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
        TextButton(onPressed: _addTodo, child: const Text('添加')),
      ],
    );
  }

  Widget _buildSection({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF999999))),
        const SizedBox(height: 8),
        child,
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
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (time == null) return;
    setState(() => _dueDate = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _addTodo() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('请输入待办标题')));
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
    ref.invalidate(todoStatsProvider);
    if (_continuousAdd && mounted) {
      _titleController.clear();
      _contentController.clear();
      setState(() {
        _priority = 'medium';
        _dueDate = null;
        _selectedType = null;
        _isPinned = false;
      });
    } else if (mounted) {
      Navigator.pop(context);
    }
  }
}
