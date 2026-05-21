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

class NoteNotifier extends AsyncNotifier<List<Note>> {
  @override
  Future<List<Note>> build() async {
    final repo = ref.read(noteRepositoryProvider);
    return await repo.getAllNotes();
  }

  Future<void> loadNotes() async {
    state = const AsyncValue.loading();
    final repo = ref.read(noteRepositoryProvider);
    state = await AsyncValue.guard(() => repo.getAllNotes());
  }

  Future<void> addNote(Note note) async {
    final repo = ref.read(noteRepositoryProvider);
    await repo.insertNote(note);
    ref.invalidateSelf();
  }

  Future<void> updateNote(Note note) async {
    final repo = ref.read(noteRepositoryProvider);
    await repo.updateNote(note);
    ref.invalidateSelf();
  }

  Future<void> deleteNote(String id) async {
    final repo = ref.read(noteRepositoryProvider);
    await repo.deleteNote(id);
    ref.invalidateSelf();
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      await loadNotes();
      return;
    }
    final repo = ref.read(noteRepositoryProvider);
    state = await AsyncValue.guard(() => repo.searchNotes(query));
  }
}

final noteNotifierProvider = AsyncNotifierProvider<NoteNotifier, List<Note>>(() => NoteNotifier());
