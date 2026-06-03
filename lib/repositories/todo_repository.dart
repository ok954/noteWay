import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/todo.dart';

class TodoRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Todo>> getAllTodos() async {
    final db = await _dbHelper.database;
    return _getSortedTodos(db);
  }

  Future<List<Todo>> _getSortedTodos(Database db) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
    final maps = await db.rawQuery('''
      SELECT * FROM todos
      ORDER BY
        is_pinned DESC,
        is_completed ASC,
        CASE
          WHEN due_date IS NOT NULL AND due_date BETWEEN ? AND ? AND is_completed = 0 THEN 0
          WHEN is_completed = 1 THEN 2
          ELSE 1
        END ASC,
        CASE WHEN due_date IS NOT NULL AND is_completed = 0 THEN due_date END ASC,
        CASE priority
          WHEN 'high' THEN 0
          WHEN 'medium' THEN 1
          ELSE 2
        END ASC,
        updated_at DESC
    ''', [startOfDay, endOfDay]);
    return maps.map((m) => Todo.fromMap(m)).toList();
  }

  Future<List<Todo>> getTodosByType(String? type) async {
    final db = await _dbHelper.database;
    if (type == null) return getAllTodos();
    final maps = await db.query('todos', where: 'type = ?', whereArgs: [type], orderBy: 'created_at DESC');
    return maps.map((m) => Todo.fromMap(m)).toList();
  }

  Future<Todo?> getTodoById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('todos', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Todo.fromMap(maps.first);
  }

  Future<String> insertTodo(Todo todo) async {
    final db = await _dbHelper.database;
    await db.insert('todos', todo.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return todo.id;
  }

  Future<int> updateTodo(Todo todo) async {
    final db = await _dbHelper.database;
    return await db.update('todos', todo.toMap(), where: 'id = ?', whereArgs: [todo.id]);
  }

  Future<int> deleteTodo(String id) async {
    final db = await _dbHelper.database;
    return await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Todo>> searchTodos(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'todos',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
    );
    return maps.map((m) => Todo.fromMap(m)).toList();
  }

  Future<List<TodoType>> getTodoTypes() async {
    final db = await _dbHelper.database;
    final maps = await db.query('todo_types', orderBy: 'sort_order ASC');
    return maps.map((m) => TodoType.fromMap(m)).toList();
  }

  Future<void> insertTodoType(TodoType type) async {
    final db = await _dbHelper.database;
    await db.insert('todo_types', type.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> deleteTodoType(String id) async {
    final db = await _dbHelper.database;
    return await db.delete('todo_types', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getCompletedCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM todos WHERE is_completed = 1');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> getTotalCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM todos');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> getTodayDueCount() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59).millisecondsSinceEpoch;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM todos WHERE due_date BETWEEN ? AND ? AND is_completed = 0',
      [startOfDay, endOfDay],
    );
    return (result.first['count'] as int?) ?? 0;
  }
}
