import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../core/constants/app_colors.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(noteNotifierProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '笔记列表',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF666666)),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜索笔记',
                      hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFBBBBBB)),
                      prefixIcon: const Icon(Icons.search, color: Color(0xFFBBBBBB)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18, color: Color(0xFFBBBBBB)),
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
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('排序筛选'),
                        content: const Text('「排序筛选」功能正在开发中，敬请期待！'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('知道了')),
                        ],
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.sort, size: 18, color: Color(0xFF666666)),
                        SizedBox(width: 4),
                        Text('排序筛选', style: TextStyle(fontSize: 13, color: Color(0xFF666666))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 笔记列表
          Expanded(
            child: notesAsync.when(
              data: (notes) {
                var filtered = notes;
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((n) {
                    final title = n.title?.toLowerCase() ?? '';
                    final text = n.plainText?.toLowerCase() ?? '';
                    final q = _searchQuery.toLowerCase();
                    return title.contains(q) || text.contains(q);
                  }).toList();
                }
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('暂无笔记，点击右下角添加', style: TextStyle(color: Color(0xFF999999))),
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
}

class _NoteCard extends StatelessWidget {
  final dynamic note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    final dt = DateTime.fromMillisecondsSinceEpoch(note.updatedAt);
    final timeStr = '${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    // 尝试提取图片路径
    final imagePath = _extractFirstImage(note.content);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, AppRoutes.noteEdit, arguments: note.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imagePath != null && File(imagePath).existsSync())
              Image.file(
                File(imagePath),
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
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (note.plainText != null && note.plainText!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      note.plainText!,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF666666), height: 1.4),
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

  String? _extractFirstImage(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        for (final op in decoded) {
          if (op is Map && op['insert'] is Map) {
            final insert = op['insert'] as Map;
            if (insert.containsKey('image')) {
              return insert['image'] as String?;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
