// lib/widgets/dashboard/regulation_card.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/library_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/app_widgets.dart';

// ─── Regulation Card ──────────────────────────────────────────────────────────

class RegulationCard extends StatefulWidget {
  final VoidCallback? onViewAll;
  final bool compact;

  const RegulationCard({super.key, this.onViewAll, this.compact = false});

  @override
  State<RegulationCard> createState() => _RegulationCardState();
}

class _RegulationCardState extends State<RegulationCard> {
  List<Document> _docs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final docs = await LibraryService.getDocuments();
    if (mounted) {
      setState(() {
        _docs    = docs.take(4).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stone200, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Regulasi Terbaru',
                style: AppTextStyles.display(13)),
              GestureDetector(
                onTap: widget.onViewAll,
                child: Text('Lihat semua',
                  style: AppTextStyles.body(
                    10, color: AppColors.navy,
                    weight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('Peraturan & kebijakan pajak terkini',
            style: AppTextStyles.body(
              10, color: AppColors.stone400)),
          const SizedBox(height: 10),

          // Items
          if (_loading)
            Column(
              children: List.generate(4, (_) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: const [
                  ShimmerBox(width: 30, height: 14, radius: 4),
                  SizedBox(width: 8),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBox(width: 120, height: 11),
                      SizedBox(height: 4),
                      ShimmerBox(width: 180, height: 10),
                    ],
                  )),
                ]),
              )),
            )
          else
            Column(
                children: _docs.asMap().entries.map((e) =>
                  _RegItem(
                    doc:     e.value,
                    isLast:  e.key == _docs.length - 1,
                    compact: widget.compact,
                    onTap:   () => context.push('/library/\${e.value.id}'),
                  ),
                ).toList(),
            ),
        ],
      ),
    );
  }
}

// ─── Single regulation row ────────────────────────────────────────────────────

class _RegItem extends StatefulWidget {
  final Document doc;
  final bool isLast;
  final bool compact;
  final VoidCallback onTap;

  const _RegItem({
    required this.doc,
    required this.isLast,
    required this.onTap,
    this.compact = false,
  });

  @override
  State<_RegItem> createState() => _RegItemState();
}

class _RegItemState extends State<_RegItem> {
  bool _hovered = false;

  (Color bg, Color fg) get _typeColors {
    switch (widget.doc.type) {
      case DocType.uu:
        return (const Color(0xFFFCEBEB), const Color(0xFF791F1F));
      case DocType.pp:
        return (const Color(0xFFFAEEDA), const Color(0xFF633806));
      case DocType.pmk:
        return (const Color(0xFFE6F1FB), const Color(0xFF0C447C));
      case DocType.perDjp:
        return (const Color(0xFFEDE9FC), const Color(0xFF3C3489));
      case DocType.se:
        return (const Color(0xFFE6F7EE), const Color(0xFF27500A));
      case DocType.kep:
        return (const Color(0xFFFFF3E0), const Color(0xFF5F3B0A));
      case DocType.panduan:
        return (AppColors.stone100, AppColors.stone600);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _typeColors;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        color: _hovered ? AppColors.brand.withOpacity(0.04) : Colors.transparent,
        child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: EdgeInsets.only(
            top: 8, bottom: widget.isLast ? 0 : 8),
          decoration: widget.isLast
              ? null
              : BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppColors.stone200, width: 0.5))),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.doc.type.label,
                  style: AppTextStyles.body(
                    9, color: fg, weight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.doc.title,
                      style: AppTextStyles.body(
                        11, weight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!widget.compact) ...[
                      const SizedBox(height: 1),
                      Text(
                        widget.doc.summary ?? '',
                        style: AppTextStyles.body(
                          10, color: AppColors.stone500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.doc.effectiveDate != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Berlaku: \${widget.doc.effectiveDate!.year}',
                          style: AppTextStyles.body(
                            9, color: AppColors.stone400),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                size: 13, color: AppColors.stone300),
            ],
          ),
        ),
      ),
    ),
    );
  }
}