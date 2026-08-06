// lib/screens/library/bookmark_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/library_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/library/lib_widgets.dart';

class BookmarkScreen extends StatefulWidget {
  const BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen> {
  List<Document> _docs    = [];
  bool           _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final docs = await LibraryService.getBookmarkedDocs();
    setState(() { _docs = docs; _loading = false; });
  }

  Future<void> _removeBookmark(String docId) async {
    await LibraryService.setBookmark(docId, false);
    setState(() => _docs.removeWhere((d) => d.id == docId));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Bookmark dihapus'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: Theme.of(context).appBarTheme.foregroundColor),
          onPressed: () => context.pop(),
        ),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bookmark Saya',
            style: AppTextStyles.display(17,
              color: Theme.of(context).appBarTheme.foregroundColor)),
          if (!_loading)
            Text('${_docs.length} regulasi tersimpan',
              style: AppTextStyles.body(11, color: AppColors.stone500)),
        ]),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: AppColors.brand))
          : _docs.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.brand,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
                    itemCount: _docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _BookmarkCard(
                      doc:      _docs[i],
                      onTap:    () => context.push('/library/${_docs[i].id}'),
                      onRemove: () => _removeBookmark(_docs[i].id),
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.bookmark_border_rounded,
        size: 52, color: AppColors.stone300),
      const SizedBox(height: 12),
      Text('Belum ada bookmark',
        style: AppTextStyles.body(15,
          color: AppColors.stone400, weight: FontWeight.w500)),
      const SizedBox(height: 6),
      Text('Simpan regulasi dengan ketuk ikon bookmark\ndi halaman detail peraturan.',
        style: AppTextStyles.body(12, color: AppColors.stone400),
        textAlign: TextAlign.center),
    ]),
  );
}

// ─── Bookmark Card ────────────────────────────────────────────────────────────

class _BookmarkCard extends StatelessWidget {
  final Document      doc;
  final VoidCallback  onTap;
  final VoidCallback  onRemove;

  const _BookmarkCard({
    required this.doc,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.stone200, width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    DocTypeBadge(doc.type),
                    const SizedBox(width: 8),
                    if (!doc.isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.stone100,
                          borderRadius: BorderRadius.circular(4)),
                        child: Text('Tidak Berlaku',
                          style: AppTextStyles.body(9,
                            color: AppColors.stone400))),
                  ]),
                  const SizedBox(height: 8),
                  Text(doc.title,
                    style: AppTextStyles.body(
                      13, weight: FontWeight.w500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                  if (doc.summary != null) ...[
                    const SizedBox(height: 4),
                    Text(doc.summary!,
                      style: AppTextStyles.body(
                        11, color: AppColors.stone500),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  ],
                  if (doc.tags.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 5, runSpacing: 4,
                      children: doc.tags.take(3)
                          .map((t) => TagChip(t)).toList()),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Remove bookmark button
            GestureDetector(
              onTap: onRemove,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.bookmark_rounded,
                  size: 20, color: AppColors.brand),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
