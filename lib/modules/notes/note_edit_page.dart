import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/note.dart';
import '../../providers/note_provider.dart';

class NoteEditPage extends ConsumerStatefulWidget {
  const NoteEditPage({super.key});

  @override
  ConsumerState<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends ConsumerState<NoteEditPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String? _noteId;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final noteId = ModalRoute.of(context)?.settings.arguments as String?;
    if (noteId != null && _noteId == null) {
      _noteId = noteId;
      _loadNote(noteId);
    }
  }

  Future<void> _loadNote(String id) async {
    final repo = ref.read(noteRepositoryProvider);
    final note = await repo.getNoteById(id);
    if (note != null && mounted) {
      setState(() {
        _titleController.text = note.title ?? '';
        _contentController.text = note.plainText ?? note.content;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_noteId == null ? '新建笔记' : '编辑笔记'),
        actions: [
          if (_noteId != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _deleteNote,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '标题',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  hintText: '开始写作...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now().millisecondsSinceEpoch;
    final note = Note(
      id: _noteId ?? const Uuid().v4(),
      title: title.isEmpty ? null : title,
      content: content,
      plainText: content,
      createdAt: _noteId == null ? now : (await ref.read(noteRepositoryProvider).getNoteById(_noteId!))?.createdAt ?? now,
      updatedAt: now,
    );

    if (_noteId == null) {
      await ref.read(noteNotifierProvider.notifier).addNote(note);
    } else {
      await ref.read(noteNotifierProvider.notifier).updateNote(note);
    }

    if (mounted) Navigator.pop(context);
  }

  Future<void> _deleteNote() async {
    if (_noteId == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，确定删除这条笔记吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(noteNotifierProvider.notifier).deleteNote(_noteId!);
      if (mounted) Navigator.pop(context);
    }
  }
}
