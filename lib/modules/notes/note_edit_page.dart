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
    _quillController = QuillController.basic();
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
    } catch (_) {}
    // 旧数据：纯文本，插入为空
    if (content.trim().isNotEmpty) {
      _quillController.document.insert(0, content);
    }
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
            icon: const Icon(Icons.link),
            onPressed: _insertLink,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Column(
        children: [
          // 标题
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                hintText: '标题',
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          // 工具栏
          QuillSimpleToolbar(
            controller: _quillController,
            config: const QuillSimpleToolbarConfig(
              showFontFamily: false,
              showFontSize: false,
              showColorButton: false,
              showBackgroundColorButton: false,
              showClearFormat: true,
              showHeaderStyle: true,
              showListCheck: true,
              showCodeBlock: true,
              showSubscript: false,
              showSuperscript: false,
              showDirection: false,
              showSearchButton: false,
              showRedo: true,
              showUndo: true,
              showQuote: true,
              showIndent: false,
              showLink: true,
              showStrikeThrough: true,
              showInlineCode: true,
              showSmallButton: false,
              showLineHeightButton: false,
              multiRowsDisplay: true,
              showDividers: false,
              toolbarSectionSpacing: 8,
            ),
          ),
          const Divider(height: 1),
          // 编辑器
          Expanded(
            child: QuillEditor(
              controller: _quillController,
              scrollController: _scrollController,
              focusNode: _focusNode,
              config: const QuillEditorConfig(
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
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
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

      // 在光标位置插入图片
      final index = _quillController.selection.baseOffset;
      _quillController.replaceText(
        index,
        0,
        BlockEmbed.image(destPath),
        TextSelection.collapsed(offset: index + 1),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('图片已插入')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('插入图片失败: $e')),
        );
      }
    }
  }

  Future<void> _insertLink() async {
    final urlController = TextEditingController();
    final textController = TextEditingController();

    // Get selected text as default
    final selection = _quillController.selection;
    if (selection.isCollapsed == false) {
      final selectedText = _quillController.document.toPlainText().substring(
        selection.start,
        selection.end,
      );
      textController.text = selectedText;
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('插入链接'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: '链接文本（可选）',
                prefixIcon: Icon(Icons.text_fields),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(
                hintText: 'https://example.com',
                prefixIcon: Icon(Icons.link),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final url = urlController.text.trim();
              if (url.isNotEmpty) {
                Navigator.pop(context, {'url': url, 'text': textController.text.trim()});
              }
            },
            child: const Text('插入'),
          ),
        ],
      ),
    );

    if (result == null) return;

    final url = result['url']!;
    final linkText = result['text']?.isNotEmpty == true ? result['text']! : url;

    final index = _quillController.selection.baseOffset;
    final length = _quillController.selection.extentOffset - index;

    if (length > 0) {
      // Apply link to selected text
      _quillController.formatText(index, length, LinkAttribute(url));
    } else {
      // Insert link text with URL
      _quillController.replaceText(index, 0, linkText, null);
      _quillController.formatText(index, linkText.length, LinkAttribute(url));
      _quillController.moveCursorToPosition(index + linkText.length);
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
    // 保存时提取第一张图片路径作为封面
    String? imagePaths;
    try {
      final paths = <String>[];
      for (final op in delta.toJson()) {
        if (op['insert'] is Map) {
          final insert = op['insert'] as Map;
          if (insert.containsKey('image')) {
            final path = insert['image'] as String?;
            if (path != null && path.isNotEmpty) {
              paths.add(path);
            }
          }
        }
      }
      if (paths.isNotEmpty) {
        imagePaths = jsonEncode(paths);
      }
    } catch (_) {}

    final note = Note(
      id: _noteId ?? const Uuid().v4(),
      title: title.isEmpty ? null : title,
      content: contentJson,
      plainText: plainText.isEmpty ? null : plainText,
      imagePaths: imagePaths,
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
