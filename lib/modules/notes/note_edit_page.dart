import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
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
  final _contentController = TextEditingController();
  final _contentFocusNode = FocusNode();
  String? _noteId;
  bool _isSaving = false;
  final List<String> _imagePaths = [];

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
        _contentController.text = _extractPlainText(note.content);
        if (note.imagePaths != null && note.imagePaths!.isNotEmpty) {
          try {
            final decoded = jsonDecode(note.imagePaths!);
            if (decoded is List) {
              _imagePaths.addAll(decoded.map((e) => e.toString()));
            }
          } catch (_) {
            // 旧格式，尝试作为逗号分隔
            _imagePaths.addAll(note.imagePaths!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty));
          }
        }
      });
    }
  }

  String _extractPlainText(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        final buffer = StringBuffer();
        for (final op in decoded) {
          if (op is Map && op['insert'] is String) {
            buffer.write(op['insert']);
          }
        }
        return buffer.toString().trim();
      }
    } catch (_) {}
    return content;
  }

  String _toDeltaJson(String plainText) {
    final text = plainText.trim();
    if (text.isEmpty) return jsonEncode([{'insert': '\n'}]);
    return jsonEncode([{'insert': '$text\n'}]);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _contentFocusNode.dispose();
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
            onPressed: _showImagePicker,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  TextField(
                    controller: _contentController,
                    focusNode: _contentFocusNode,
                    decoration: const InputDecoration(
                      hintText: '开始写作...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(12),
                    ),
                    maxLines: null,
                    minLines: 8,
                    textAlignVertical: TextAlignVertical.top,
                  ),
                ],
              ),
            ),
          ),
          // 图片预览区域
          if (_imagePaths.isNotEmpty) ...[
            const Divider(height: 1),
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _imagePaths.length,
                itemBuilder: (context, index) => _buildImageThumbnail(index),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(int index) {
    final path = _imagePaths[index];
    final file = File(path);
    final exists = file.existsSync();

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: exists
                ? Image.file(
                    file,
                    width: 84,
                    height: 84,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
          ),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: const Color(0xFFEEEEEE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.broken_image, color: Color(0xFFAAAAAA)),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF5B8DEF)),
                title: const Text('从相册选择'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF34A853)),
                title: const Text('拍照'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final imageDir = Directory(p.join(appDir.path, 'images'));
      if (!await imageDir.exists()) {
        await imageDir.create(recursive: true);
      }
      final fileName = '${const Uuid().v4()}${p.extension(picked.path)}';
      final destPath = p.join(imageDir.path, fileName);
      await File(picked.path).copy(destPath);

      setState(() => _imagePaths.add(destPath));

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

  void _removeImage(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除图片'),
        content: const Text('确定要删除这张图片吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final path = _imagePaths[index];
              try {
                File(path).deleteSync();
              } catch (_) {}
              setState(() => _imagePaths.removeAt(index));
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveNote() async {
    if (_isSaving) return;
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty && content.isEmpty && _imagePaths.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now().millisecondsSinceEpoch;
    final note = Note(
      id: _noteId ?? const Uuid().v4(),
      title: title.isEmpty ? null : title,
      content: _toDeltaJson(content),
      plainText: content.isEmpty ? null : content,
      imagePaths: _imagePaths.isEmpty ? null : jsonEncode(_imagePaths),
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
      // 删除关联的图片文件
      for (final path in _imagePaths) {
        try {
          File(path).deleteSync();
        } catch (_) {}
      }
      await ref.read(noteNotifierProvider.notifier).deleteNote(_noteId!);
      if (mounted) Navigator.pop(context);
    }
  }
}
