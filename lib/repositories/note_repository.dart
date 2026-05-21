import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../models/note.dart';

class NoteRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<List<Note>> getAllNotes() async {
    final db = await _dbHelper.database;
    final maps = await db.query('notes', orderBy: 'updated_at DESC');
    return maps.map((m) => Note.fromMap(m)).toList();
  }

  Future<Note?> getNoteById(String id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('notes', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Note.fromMap(maps.first);
  }

  Future<String> insertNote(Note note) async {
    final db = await _dbHelper.database;
    await db.insert('notes', note.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return note.id;
  }

  Future<int> updateNote(Note note) async {
    final db = await _dbHelper.database;
    return await db.update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]);
  }

  Future<int> deleteNote(String id) async {
    final db = await _dbHelper.database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Note>> searchNotes(String query) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'notes',
      where: 'title LIKE ? OR plain_text LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => Note.fromMap(m)).toList();
  }
}
