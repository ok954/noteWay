class Todo {
  final String id;
  final String title;
  final String? content;
  final String? type;
  final int? dueDate;
  final String priority;
  final bool isCompleted;
  final bool isPinned;
  final int createdAt;
  final int updatedAt;

  Todo({
    required this.id,
    required this.title,
    this.content,
    this.type,
    this.dueDate,
    this.priority = 'medium',
    this.isCompleted = false,
    this.isPinned = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String?,
      type: map['type'] as String?,
      dueDate: map['due_date'] as int?,
      priority: map['priority'] as String? ?? 'medium',
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      isPinned: (map['is_pinned'] as int? ?? 0) == 1,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type,
      'due_date': dueDate,
      'priority': priority,
      'is_completed': isCompleted ? 1 : 0,
      'is_pinned': isPinned ? 1 : 0,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Todo copyWith({
    String? id,
    String? title,
    String? content,
    String? type,
    int? dueDate,
    String? priority,
    bool? isCompleted,
    bool? isPinned,
    int? createdAt,
    int? updatedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      isPinned: isPinned ?? this.isPinned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TodoType {
  final String id;
  final String name;
  final bool isBuiltin;
  final int? sortOrder;

  TodoType({
    required this.id,
    required this.name,
    this.isBuiltin = false,
    this.sortOrder,
  });

  factory TodoType.fromMap(Map<String, dynamic> map) {
    return TodoType(
      id: map['id'] as String,
      name: map['name'] as String,
      isBuiltin: (map['is_builtin'] as int? ?? 0) == 1,
      sortOrder: map['sort_order'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'is_builtin': isBuiltin ? 1 : 0,
      'sort_order': sortOrder,
    };
  }
}
