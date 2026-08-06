// lib/widgets/library/related_docs.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/library_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../common/app_widgets.dart';
import 'lib_widgets.dart';

// ─── Related Documents Widget ─────────────────────────────────────────────────

class RelatedDocs extends StatefulWidget {
  final String docId;
  final List<String> tags;

  const RelatedDocs({
    super.key,
    required this.docId,
    required this.tags,
  });

  @override
  State<RelatedDocs> createState() => _RelatedDocsState();
}

class _RelatedDocsState extends State<RelatedDocs> {
  List<Document> _related = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.tags.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    final docs = await LibraryService.getDocuments();
    final related = docs
        .where((d) =>
            d.id != widget.docId &&
            d.tags.any((t) => widget.tags.contains(t)))
        .take(4)
        .toList();
    setState(() {
      _related = related;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dokumen Terkait',
            style: AppTextStyles.display(16)),
          const SizedBox(height: 12),
          const ShimmerBox(width: double.infinity, height: 90),
          const SizedBox(height: 8),
          const ShimmerBox(width: double.infinity, height: 90),
        ],
      );
    }

    if (_related.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dokumen Terkait', style: AppTextStyles.display(16)),
        const SizedBox(height: 12),
        ..._related.map((doc) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _RelatedDocCard(doc: doc),
        )),
      ],
    );
  }
}

// ─── Compact doc card for related section ─────────────────────────────────────

class _RelatedDocCard extends StatelessWidget {
  final Document doc;
  const _RelatedDocCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/library/${doc.id}'),
      padding: const EdgeInsets.all(12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Type badge column
        DocTypeBadge(doc.type),
        const SizedBox(width: 10),

        // Content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(doc.title,
                style: AppTextStyles.body(13, weight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
              if (doc.summary != null) ...[
                const SizedBox(height: 4),
                Text(doc.summary!,
                  style: AppTextStyles.body(11, color: AppColors.stone400),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              ],
              if (doc.effectiveDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Berlaku: ${Tanggal.long(doc.effectiveDate!)}',
                  style: AppTextStyles.body(10, color: AppColors.stone400),
                ),
              ],
            ],
          ),
        ),

        Icon(Icons.chevron_right_rounded,
          size: 18, color: AppColors.stone300),
      ]),
    );
  }
}

// ─── Bookmark Button (reusable) ───────────────────────────────────────────────

class BookmarkButton extends StatelessWidget {
  final bool isBookmarked;
  final bool isLoading;
  final VoidCallback onTap;

  const BookmarkButton({
    super.key,
    required this.isBookmarked,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        width: 20, height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2, color: AppColors.brand),
      );
    }
    return IconButton(
      icon: Icon(
        isBookmarked
            ? Icons.bookmark_rounded
            : Icons.bookmark_border_rounded,
        color: isBookmarked ? AppColors.brand : AppColors.stone400,
      ),
      tooltip: isBookmarked ? 'Hapus bookmark' : 'Simpan bookmark',
      onPressed: onTap,
    );
  }
}