import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
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
  late final QuillController _quillController;
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  String? _noteId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _quillController = QuillController.basic(
      configurations: const QuillControllerConfigurations(),
    );
  }

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
      });
      _loadContent(note.content);
    }
  }

  void _loadContent(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        _quillController.document = Document.fromJson(decoded);
        return;
      }
    } catch (_) {
      // 不是 JSON，作为纯文本处理
    }
    _quillController.document = Document()..insert(0, content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _quillController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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
            icon: const Icon(Icons.image),
            onPressed: _insertImage,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '标题',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          QuillToolbar(
            controller: _quillController,
            configurations: const QuillToolbarConfigurations(),
          ),
          const Divider(height: 1),
          Expanded(
            child: QuillEditor(
              controller: _quillController,
              scrollController: _scrollController,
              focusNode: _focusNode,
              configurations: const QuillEditorConfigurations(
                placeholder: '开始写作...',
                padding: EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _insertImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory(p.join(appDir.path, 'images'));
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      final fileName = '${const Uuid().v4()}${p.extension(picked.path)}';
      final destPath = p.join(imageDir.path, fileName);
      await File(picked.path).copy(destPath);

      final index = _quillController.selection.baseOffset;
      _quillController.replaceText(
        index,
        0,
        BlockEmbed.image(destPath),
        TextSelection.collapsed(offset: index + 1),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('插入图片失败: $e')),
        );
      }
    }
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;
    final title = _titleController.text.trim();
    final delta = _quillController.document.toDelta();
    final contentJson = jsonEncode(delta.toJson());
    final plainText = _quillController.document.toPlainText().trim();

    if (title.isEmpty && plainText.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now().millisecondsSinceEpoch;
    final note = Note(
      id: _noteId ?? const Uuid().v4(),
      title: title.isEmpty ? null : title,
      content: contentJson,
      plainText: plainText.isEmpty ? null : plainText,
      createdAt: _noteId == null
          ? now
          : (await ref.read(noteRepositoryProvider).getNoteById(_noteId!))?.createdAt ?? now,
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
