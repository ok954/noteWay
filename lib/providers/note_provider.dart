import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';
import '../repositories/note_repository.dart';

final noteRepositoryProvider = Provider((ref) => NoteRepository());

final notesProvider = FutureProvider<List<Note>>((ref) async {
  final repo = ref.watch(noteRepositoryProvider);
  return await repo.getAllNotes();
});

final noteSearchProvider = FutureProvider.family<List<Note>, String>((ref, query) async {
  final repo = ref.watch(noteRepositoryProvider);
  if (query.isEmpty) return await repo.getAllNotes();
  return await repo.searchNotes(query);
});

class NoteNotifier extends StateNotifier<AsyncValue<List<Note>>> {
  final NoteRepository _repository;

  NoteNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadNotes();
  }

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    try {
      final notes = await _repository.getAllNotes();
      state = AsyncValue.data(notes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addNote(Note note) async {
    await _repository.insertNote(note);
    await loadNotes();
  }

  Future<void> updateNote(Note note) async {
    await _repository.updateNote(note);
    await loadNotes();
  }

  Future<void> deleteNote(String id) async {
    await _repository.deleteNote(id);
    await loadNotes();
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      await loadNotes();
      return;
    }
    try {
      final notes = await _repository.searchNotes(query);
      state = AsyncValue.data(notes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final noteNotifierProvider = StateNotifierProvider<NoteNotifier, AsyncValue<List<Note>>>((ref) {
  final repo = ref.watch(noteRepositoryProvider);
  return NoteNotifier(repo);
});
