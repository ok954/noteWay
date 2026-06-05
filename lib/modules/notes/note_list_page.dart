import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../models/note.dart';
import '../../providers/note_provider.dart';
import '../../router.dart';

class NoteListPage extends ConsumerStatefulWidget {
  const NoteListPage({super.key});

  @override
  ConsumerState<NoteListPage> createState() => _NoteListPageState();
}

class _NoteListPageState extends ConsumerState<NoteListPage> {
  String _searchQuery = '';
  final _searchController = TextEditingController();
  String _sortField = 'updated_at';
  bool _sortAscending = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(noteSearchProvider(_searchQuery));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('笔记列表'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Theme.of(context).colorScheme.onSurfaceVariant),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜索笔记',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value.trim()),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showSortBottomSheet(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sort, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(_getSortLabel(), style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                var filtered = List<Note>.from(notes);
                filtered.sort((a, b) {
                  int cmp;
                  switch (_sortField) {
                    case 'created_at':
                      cmp = a.createdAt.compareTo(b.createdAt);
                      break;
                    case 'title':
                      cmp = (a.title ?? '').compareTo(b.title ?? '');
                      break;
                    default: // updated_at
                      cmp = a.updatedAt.compareTo(b.updatedAt);
                      break;
                  }
                  return _sortAscending ? cmp : -cmp;
                });
                if (filtered.isEmpty) {
                  return Center(
                    child: Text('暂无笔记，点击右下角添加', style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                  );
                }
                return MasonryGridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final note = filtered[index];
                    return _NoteCard(note: note);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('错误: $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.noteEdit),
        backgroundColor: const Color(0xFFFFA726),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  String _getSortLabel() {
    String field;
    switch (_sortField) {
      case 'created_at':
        field = '创建时间';
        break;
      case 'title':
        field = '标题';
        break;
      default:
        field = '最近编辑';
    }
    return field;
  }

  void _showSortBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('排序方式', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 12),
                  RadioListTile<String>(
                    title: const Text('最近编辑'),
                    value: 'updated_at',
                    groupValue: _sortField,
                    onChanged: (value) {
                      setModalState(() => _sortField = value!);
                      setState(() {});
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('创建时间'),
                    value: 'created_at',
                    groupValue: _sortField,
                    onChanged: (value) {
                      setModalState(() => _sortField = value!);
                      setState(() {});
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text('标题'),
                    value: 'title',
                    groupValue: _sortField,
                    onChanged: (value) {
                      setModalState(() => _sortField = value!);
                      setState(() {});
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: Text(_sortAscending ? '升序' : '降序'),
                    subtitle: Text(_sortAscending ? '从旧到新 / A-Z' : '从新到旧 / Z-A'),
                    value: _sortAscending,
                    onChanged: (value) {
                      setModalState(() => _sortAscending = value);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  final dynamic note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.fromMillisecondsSinceEpoch(note.updatedAt);
    final timeStr = '${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    // 从 imagePaths 字段提取第一张图片作为封面
    final coverImage = _getFirstImage(note.imagePaths);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.noteEdit, arguments: note.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (coverImage != null && File(coverImage).existsSync())
              Image.file(
                File(coverImage),
                width: double.infinity,
                height: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (note.title != null && note.title!.isNotEmpty)
                    Text(
                      note.title!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (note.plainText != null && note.plainText!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      note.plainText!,
                      style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.4),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    timeStr,
                    style: const TextStyle(fontSize: 11, color: Color(0xFFAAAAAA)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _getFirstImage(String? imagePaths) {
    if (imagePaths == null || imagePaths.isEmpty) return null;
    try {
      final decoded = jsonDecode(imagePaths);
      if (decoded is List && decoded.isNotEmpty) {
        return decoded.first as String?;
      }
    } catch (_) {
      return imagePaths.split(',').first.trim();
    }
    return null;
  }
}
