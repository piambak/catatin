// lib/widgets/library/lib_widgets.dart

import 'package:flutter/material.dart';
import '../../core/services/library_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';

// ─── Doc Type Color Map ───────────────────────────────────────────────────────

extension DocTypeColor on DocType {
  Color get fg => const {
    DocType.uu:     Color(0xFFA32D2D),
    DocType.pp:     Color(0xFF854F0B),
    DocType.pmk:    Color(0xFF185FA5),
    DocType.perDjp: Color(0xFF6B21A8),
    DocType.se:     Color(0xFF27500A),
    DocType.kep:    Color(0xFF8A6200),
    DocType.panduan:Color(0xFF444441),
  }[this]!;

  Color get bg => const {
    DocType.uu:     Color(0xFFFCEBEB),
    DocType.pp:     Color(0xFFFAEEDA),
    DocType.pmk:    Color(0xFFE6F1FB),
    DocType.perDjp: Color(0xFFF3E8FF),
    DocType.se:     Color(0xFFEAF3DE),
    DocType.kep:    Color(0xFFFEF9C3),
    DocType.panduan:Color(0xFFF1EFE8),
  }[this]!;
}

// ─── Doc Type Badge ───────────────────────────────────────────────────────────

class DocTypeBadge extends StatelessWidget {
  final DocType type;
  final double fontSize;

  const DocTypeBadge(this.type, {super.key, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: type.bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        type.label,
        style: AppTextStyles.body(
          fontSize, color: type.fg, weight: FontWeight.w600),
      ),
    );
  }
}

// ─── Status Badge (Berlaku / Diganti) ─────────────────────────────────────────

class DocStatusBadge extends StatelessWidget {
  final bool isActive;
  const DocStatusBadge(this.isActive, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.incomeLight
            : AppColors.stone100,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        isActive ? 'Berlaku' : 'Diganti',
        style: AppTextStyles.body(
          10,
          color: isActive ? AppColors.income : AppColors.stone400,
          weight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Tag Chip ─────────────────────────────────────────────────────────────────

class TagChip extends StatelessWidget {
  final String label;
  const TagChip(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.stone100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stone200, width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.tag, size: 9, color: AppColors.stone400),
        const SizedBox(width: 2),
        Text(label,
          style: AppTextStyles.body(10, color: AppColors.stone500)),
      ]),
    );
  }
}

// ─── Category Filter Pill ─────────────────────────────────────────────────────

class CategoryPill extends StatelessWidget {
  final DocCategory? category; // null = "Semua"
  final bool selected;
  final VoidCallback onTap;

  const CategoryPill({
    super.key,
    this.category,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.dark : AppColors.bgCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.dark : AppColors.stone200,
            width: 0.5,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (category?.icon != null) ...[
            Text(category!.icon!,
              style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 5),
          ],
          Text(
            category?.name ?? 'Semua',
            style: AppTextStyles.body(
              12,
              color: selected ? Colors.white : AppColors.stone600,
              weight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Type Filter Pill (PP, PMK, dll) ─────────────────────────────────────────

class TypePill extends StatelessWidget {
  final DocType? type; // null = "Semua Jenis"
  final bool selected;
  final VoidCallback onTap;

  const TypePill({
    super.key,
    this.type,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected
              ? (type?.bg ?? AppColors.stone100)
              : AppColors.bgCard,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: selected
                ? (type?.fg ?? AppColors.stone500)
                : AppColors.stone200,
            width: selected ? 1.2 : 0.5,
          ),
        ),
        child: Text(
          type?.label ?? 'Semua',
          style: AppTextStyles.body(
            11,
            color: selected
                ? (type?.fg ?? AppColors.stone600)
                : AppColors.stone500,
            weight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

// ─── Document List Card ───────────────────────────────────────────────────────

class DocCard extends StatelessWidget {
  final Document doc;
  final bool bookmarked;
  final VoidCallback onTap;

  const DocCard({
    super.key,
    required this.doc,
    this.bookmarked = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.stone200, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge + status + bookmark
            Row(children: [
              DocTypeBadge(doc.type),
              const SizedBox(width: 6),
              DocStatusBadge(doc.isActive),
              const Spacer(),
              if (bookmarked)
                Icon(Icons.bookmark_rounded,
                  size: 16, color: AppColors.brand),
              Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.stone300),
            ]),
            const SizedBox(height: 8),

            // Title
            Text(
              doc.title,
              style: AppTextStyles.body(
                14, weight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            // Summary
            if (doc.summary != null) ...[
              const SizedBox(height: 5),
              Text(
                doc.summary!,
                style: AppTextStyles.body(
                  12, color: AppColors.stone500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Tags + date
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  children: doc.tags
                      .take(3)
                      .map((t) => TagChip(t))
                      .toList(),
                ),
              ),
              if (doc.effectiveDate != null)
                Text(
                  Tanggal.short(doc.effectiveDate!),
                  style: AppTextStyles.body(
                    10, color: AppColors.stone400),
                ),
            ]),
          ],
        ),
      ),
    );
  }
}

// ─── Search Input ─────────────────────────────────────────────────────────────

class LibSearchBar extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;

  const LibSearchBar({
    super.key,
    this.initialValue = '',
    required this.onChanged,
    this.onClear,
  });

  @override
  State<LibSearchBar> createState() => _LibSearchBarState();
}

class _LibSearchBarState extends State<LibSearchBar> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _ctrl,
      onChanged: widget.onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Cari regulasi... (PPh Final, PKP, e-Faktur)',
        prefixIcon: Icon(
          Icons.search_rounded, size: 20, color: AppColors.stone400),
        suffixIcon: _ctrl.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.close_rounded,
                  size: 18, color: AppColors.stone400),
                onPressed: () {
                  _ctrl.clear();
                  widget.onChanged('');
                  widget.onClear?.call();
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.bgCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.stone200, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.stone200, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.brand, width: 1.5),
        ),
      ),
    );
  }
}

// ─── Empty Search State ───────────────────────────────────────────────────────

class LibEmptySearch extends StatelessWidget {
  final String query;
  const LibEmptySearch({super.key, required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded,
              size: 48, color: AppColors.stone300),
            const SizedBox(height: 14),
            Text(
              'Tidak ada regulasi ditemukan',
              style: AppTextStyles.body(
                15, color: AppColors.stone500,
                weight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              'untuk "$query"',
              style: AppTextStyles.body(
                13, color: AppColors.stone400),
            ),
            const SizedBox(height: 16),
            Text(
              'Coba kata kunci lain atau hapus filter kategori',
              style: AppTextStyles.body(
                12, color: AppColors.stone400),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}