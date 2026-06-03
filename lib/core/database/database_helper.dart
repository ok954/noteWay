import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (Platform.isWindows) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final path = p.join(await getDatabasesPath(), 'memo_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute(createNotesTable);
    await db.execute(createTodosTable);
    await db.execute(createTodoTypesTable);
    await db.execute(createHabitsTable);
    await db.execute(createHabitTagsTable);
    await db.execute(createCheckinRecordsTable);
    await db.execute(createSettingsTable);
    await _initDefaultData(db);
  }

  Future<void> _initDefaultData(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    // 默认待办类型
    await db.insert('todo_types', {
      'id': 'work',
      'name': '工作',
      'is_builtin': 1,
      'sort_order': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert('todo_types', {
      'id': 'life',
      'name': '生活',
      'is_builtin': 1,
      'sort_order': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert('todo_types', {
      'id': 'study',
      'name': '学习',
      'is_builtin': 1,
      'sort_order': 2,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    // 默认打卡标签
    await db.insert('habit_tags', {
      'id': 'health',
      'name': '健康',
      'sort_order': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert('habit_tags', {
      'id': 'learning',
      'name': '学习',
      'sort_order': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert('habit_tags', {
      'id': 'habit',
      'name': '习惯',
      'sort_order': 2,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    // 初始化最后启动日期
    await db.insert('settings', {
      'key': 'last_launch_date',
      'value': now.toString(),
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}

const String createNotesTable = '''
CREATE TABLE notes (
    id TEXT PRIMARY KEY,
    title TEXT,
    content TEXT NOT NULL,
    plain_text TEXT,
    image_paths TEXT,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
''';

const String createTodosTable = '''
CREATE TABLE todos (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    content TEXT,
    type TEXT,
    due_date INTEGER,
    priority TEXT DEFAULT 'medium',
    is_completed INTEGER DEFAULT 0,
    is_pinned INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
''';

const String createTodoTypesTable = '''
CREATE TABLE todo_types (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    is_builtin INTEGER DEFAULT 0,
    sort_order INTEGER
);
''';

const String createHabitsTable = '''
CREATE TABLE habits (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    tag TEXT,
    habit_type TEXT NOT NULL,
    plan_duration INTEGER,
    total_duration INTEGER DEFAULT 0,
    today_duration INTEGER DEFAULT 0,
    checkin_count INTEGER DEFAULT 0,
    today_count INTEGER DEFAULT 0,
    is_pinned INTEGER DEFAULT 0,
    is_timing INTEGER DEFAULT 0,
    current_record_id TEXT,
    last_checkin_at INTEGER,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);
''';

const String createHabitTagsTable = '''
CREATE TABLE habit_tags (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    sort_order INTEGER
);
''';

const String createCheckinRecordsTable = '''
CREATE TABLE checkin_records (
    id TEXT PRIMARY KEY,
    habit_id TEXT NOT NULL,
    record_type TEXT NOT NULL,
    start_time INTEGER NOT NULL,
    end_time INTEGER,
    duration INTEGER,
    is_completed INTEGER DEFAULT 0,
    created_at INTEGER NOT NULL,
    FOREIGN KEY (habit_id) REFERENCES habits(id) ON DELETE CASCADE
);
''';

const String createSettingsTable = '''
CREATE TABLE settings (
    key TEXT PRIMARY KEY,
    value TEXT,
    updated_at INTEGER
);
''';
