import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/habit.dart';
import '../models/checkin_record.dart';

class HabitRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Habit>> getAllHabits() async {
    final db = await _dbHelper.database;
    final maps = await db.query('habits', orderBy: 'created_at DESC');
    return maps.map((m) => Habit.fromMap(m)).toList();
  }

  Future<Habit?> getHabitById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('habits', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Habit.fromMap(maps.first);
  }

  Future<String> insertHabit(Habit habit) async {
    final db = await _dbHelper.database;
    await db.insert('habits', habit.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return habit.id;
  }

  Future<int> updateHabit(Habit habit) async {
    final db = await _dbHelper.database;
    return await db.update('habits', habit.toMap(), where: 'id = ?', whereArgs: [habit.id]);
  }

  Future<int> deleteHabit(String id) async {
    final db = await _dbHelper.database;
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<HabitTag>> getHabitTags() async {
    final db = await _dbHelper.database;
    final maps = await db.query('habit_tags', orderBy: 'sort_order ASC');
    return maps.map((m) => HabitTag.fromMap(m)).toList();
  }

  Future<void> insertCheckinRecord(CheckinRecord record) async {
    final db = await _dbHelper.database;
    await db.insert('checkin_records', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateCheckinRecord(CheckinRecord record) async {
    final db = await _dbHelper.database;
    return await db.update('checkin_records', record.toMap(), where: 'id = ?', whereArgs: [record.id]);
  }

  Future<CheckinRecord?> getRecordById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('checkin_records', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return CheckinRecord.fromMap(maps.first);
  }

  Future<int> getTodayCheckedCount() async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).millisecondsSinceEpoch;
    final result = await db.rawQuery(
      'SELECT COUNT(DISTINCT habit_id) as count FROM checkin_records WHERE start_time >= ? AND is_completed = 1',
      [startOfDay],
    );
    return (result.first['count'] as int?) ?? 0;
  }

  Future<int> getTotalHabitCount() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM habits');
    return (result.first['count'] as int?) ?? 0;
  }

  Future<void> resetTodayData() async {
    final db = await _dbHelper.database;
    await db.update('habits', {
      'today_duration': 0,
      'today_count': 0,
      'is_timing': 0,
      'current_record_id': null,
    });
  }

  /// 事务性打卡：插入记录 + 更新习惯计数器在同一事务中完成
  Future<void> checkinWithRecord(CheckinRecord record, Habit updatedHabit) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.insert('checkin_records', record.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.update('habits', updatedHabit.toMap(),
          where: 'id = ?', whereArgs: [updatedHabit.id]);
    });
  }

  /// 事务性完成计时：更新记录 + 更新习惯在同一事务中完成
  Future<void> completeCheckin(CheckinRecord record, Habit updatedHabit) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      await txn.update('checkin_records', record.toMap(),
          where: 'id = ?', whereArgs: [record.id]);
      await txn.update('habits', updatedHabit.toMap(),
          where: 'id = ?', whereArgs: [updatedHabit.id]);
    });
  }
}
