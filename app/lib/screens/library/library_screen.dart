// lib/screens/library/library_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/library_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/library/lib_widgets.dart';
import '../../widgets/common/app_widgets.dart';

const _kPageSize = 10;

// ─── Sort ─────────────────────────────────────────────────────────────────────

enum SortOption { newest, oldest }
extension SortExt on SortOption {
  String get label => this == SortOption.newest ? 'Terbaru' : 'Terlama';
}

// ─── Advanced Filter ──────────────────────────────────────────────────────────

class AdvancedFilter {
  final String? perihal;
  final String? isiPeraturan;
  final String? nomorPeraturan;
  final DocType? docType;
  final int?    yearFrom;
  final int?    yearTo;
  final String? topic;

  const AdvancedFilter({
    this.perihal,
    this.isiPeraturan,
    this.nomorPeraturan,
    this.docType,
    this.yearFrom,
    this.yearTo,
    this.topic,
  });

  bool get isEmpty =>
      perihal == null && isiPeraturan == null && nomorPeraturan == null &&
      docType == null && yearFrom == null && yearTo == null && topic == null;

  int get activeCount => [
    perihal, isiPeraturan, nomorPeraturan, docType,
    yearFrom, yearTo, topic,
  ].where((x) => x != null).length;

  AdvancedFilter copyWith({
    Object? perihal       = _s, Object? isiPeraturan  = _s,
    Object? nomorPeraturan= _s, Object? docType        = _s,
    Object? yearFrom      = _s, Object? yearTo         = _s,
    Object? topic         = _s,
  }) => AdvancedFilter(
    perihal:        perihal        == _s ? this.perihal        : perihal as String?,
    isiPeraturan:   isiPeraturan   == _s ? this.isiPeraturan   : isiPeraturan as String?,
    nomorPeraturan: nomorPeraturan == _s ? this.nomorPeraturan : nomorPeraturan as String?,
    docType:        docType        == _s ? this.docType        : docType as DocType?,
    yearFrom:       yearFrom       == _s ? this.yearFrom       : yearFrom as int?,
    yearTo:         yearTo         == _s ? this.yearTo         : yearTo as int?,
    topic:          topic          == _s ? this.topic          : topic as String?,
  );

  static const _s = Object();
}

// ─── Library Screen ───────────────────────────────────────────────────────────

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  List<DocCategory> _categories = [];
  List<Document>    _allDocs    = [];
  List<Document>    _filtered   = [];
  bool _loading = true;

  final _searchCtrl = TextEditingController();
  String?        _selectedCategoryId;
  AdvancedFilter _advanced     = const AdvancedFilter();
  SortOption     _sort         = SortOption.newest;
  bool           _showAdvanced = false;
  int            _page         = 0;

  @override
  void initState() { super.initState(); _loadAll(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final cats = await LibraryService.getCategories();
    final docs = await LibraryService.getDocuments();
    setState(() { _categories = cats; _allDocs = docs; _loading = false; });
    _apply();
  }

  void _apply() {
    var r = List<Document>.from(_allDocs);
    final q = _searchCtrl.text.trim().toLowerCase();

    if (q.isNotEmpty) {
      r = r.where((d) =>
        d.title.toLowerCase().contains(q) ||
        (d.summary?.toLowerCase().contains(q) ?? false) ||
        d.tags.any((t) => t.toLowerCase().contains(q))
      ).toList();
    }
    if (_selectedCategoryId != null) {
      r = r.where((d) => d.categoryId == _selectedCategoryId).toList();
    }
    if (_advanced.perihal != null) {
      final p = _advanced.perihal!.toLowerCase();
      r = r.where((d) => d.title.toLowerCase().contains(p)).toList();
    }
    if (_advanced.isiPeraturan != null) {
      final ip = _advanced.isiPeraturan!.toLowerCase();
      r = r.where((d) =>
        (d.summary?.toLowerCase().contains(ip) ?? false) ||
        (d.bodyHtml?.toLowerCase().contains(ip) ?? false)
      ).toList();
    }
    if (_advanced.nomorPeraturan != null) {
      final n = _advanced.nomorPeraturan!.toLowerCase();
      r = r.where((d) => d.title.toLowerCase().contains(n)).toList();
    }
    if (_advanced.docType != null) {
      r = r.where((d) => d.type == _advanced.docType).toList();
    }
    if (_advanced.yearFrom != null) {
      r = r.where((d) =>
        d.effectiveDate != null &&
        d.effectiveDate!.year >= _advanced.yearFrom!).toList();
    }
    if (_advanced.yearTo != null) {
      r = r.where((d) =>
        d.effectiveDate != null &&
        d.effectiveDate!.year <= _advanced.yearTo!).toList();
    }
    if (_advanced.topic != null) {
      r = r.where((d) => d.tags.contains(_advanced.topic)).toList();
    }

    if (_sort == SortOption.newest) {
      r.sort((a, b) =>
        (b.effectiveDate ?? DateTime(2000))
          .compareTo(a.effectiveDate ?? DateTime(2000)));
    } else {
      r.sort((a, b) =>
        (a.effectiveDate ?? DateTime(2000))
          .compareTo(b.effectiveDate ?? DateTime(2000)));
    }

    setState(() { _filtered = r; _page = 0; });
  }

  bool get _hasFilter =>
      _searchCtrl.text.isNotEmpty ||
      _selectedCategoryId != null ||
      !_advanced.isEmpty;

  void _clearAll() {
    _searchCtrl.clear();
    setState(() {
      _selectedCategoryId = null;
      _advanced     = const AdvancedFilter();
      _showAdvanced = false;
    });
    _apply();
  }

  List<String> get _availTopics {
    final s = <String>{};
    for (final d in _allDocs) s.addAll(d.tags);
    return s.toList()..sort();
  }

  // pages
  int get _totalPages => (_filtered.length / _kPageSize).ceil().clamp(1, 999);
  List<Document> get _pageDocs {
    final start = _page * _kPageSize;
    final end   = (start + _kPageSize).clamp(0, _filtered.length);
    return _filtered.sublist(start, end);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(children: [
        _buildHeader(),
        Expanded(child: _loading ? _buildShimmer()
          : LayoutBuilder(builder: (_, box) {
            final wide = box.maxWidth > 700;
            return wide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SizedBox(width: 220, child: _FilterPanel(
                    categories:  _categories,
                    selectedCat: _selectedCategoryId,
                    advanced:    _advanced,
                    availTopics: _availTopics,
                    onCatChanged: (id) { setState(() => _selectedCategoryId = id); _apply(); },
                    onAdvChanged: (f)  { setState(() => _advanced = f); _apply(); },
                  )),
                  Expanded(child: _buildDocList(narrow: false)),
                ])
              : _buildDocList(narrow: true);
          })),
      ]),
    );
  }

  // ── Header ─────────────────────────────────────────────────

  Widget _buildHeader() {
    return Material(
      color: Theme.of(context).appBarTheme.backgroundColor,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Perpustakaan',
                style: AppTextStyles.display(17, weight: FontWeight.w600, color: Theme.of(context).appBarTheme.foregroundColor)),
              Text('Kebijakan & regulasi pajak UMKM',
                style: AppTextStyles.body(11, color: AppColors.stone500),
                overflow: TextOverflow.ellipsis),
            ])),
            IconButton(
              icon: Icon(Icons.bookmark_border_rounded,
                color: Theme.of(context).appBarTheme.foregroundColor),
              tooltip: 'Bookmark Saya',
              onPressed: () => context.push('/library/bookmarks'),
            ),
          ]),
        ),
        const SizedBox(height: 10),
        // Search bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _SearchBar(
            controller: _searchCtrl,
            onSearch:   _apply,
            onClear:    () { _searchCtrl.clear(); _apply(); },
          ),
        ),
        // Advanced toggle row + reset button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: advanced toggle
              GestureDetector(
                onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.tune_outlined, size: 13,
                    color: _showAdvanced ? AppColors.brand : AppColors.stone400),
                  const SizedBox(width: 4),
                  Text(
                    _showAdvanced
                      ? 'Sembunyikan pencarian lanjutan'
                      : _advanced.activeCount > 0
                        ? 'Pencarian lanjutan (${_advanced.activeCount})'
                        : 'Pencarian lanjutan',
                    style: AppTextStyles.body(11,
                      color: _showAdvanced ? AppColors.brand : AppColors.stone400,
                      weight: _showAdvanced ? FontWeight.w500 : FontWeight.w400)),
                  Icon(
                    _showAdvanced
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                    size: 13,
                    color: _showAdvanced ? AppColors.brand : AppColors.stone400),
                ]),
              ),
              // Right: reset button — only visible when there's something to reset
              if (_hasFilter)
                GestureDetector(
                  onTap: _clearAll,
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.refresh_rounded,
                      size: 13, color: AppColors.expense),
                    const SizedBox(width: 4),
                    Text('Ulang pencarian',
                      style: AppTextStyles.body(11,
                        color: AppColors.expense,
                        weight: FontWeight.w500)),
                  ]),
                ),
            ],
          ),
        ),
        if (_showAdvanced) _AdvancedPanel(
          advanced:    _advanced,
          availTopics: _availTopics,
          onChanged:   (f) { setState(() => _advanced = f); _apply(); },
        ),
        Divider(height: 0.5, color: AppColors.stone200),
      ]),
    );
  }

  // ── Doc list ───────────────────────────────────────────────

  Widget _buildDocList({required bool narrow}) {
    if (_filtered.isEmpty) {
      return _hasFilter
        ? LibEmptySearch(query: _searchCtrl.text)
        : const EmptyState(
            icon: Icons.menu_book_outlined,
            title: 'Belum ada regulasi',
            subtitle: 'Konten akan ditambahkan segera');
    }

    final pageDocs = _pageDocs;

    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppColors.brand,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: pageDocs.length + 2, // header + docs + pagination
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          if (i == 0) return _buildListHeader(narrow: narrow);
          if (i == pageDocs.length + 1) return _buildPagination();
          final doc = pageDocs[i - 1];
          return DocCard(doc: doc, bookmarked: false,
            onTap: () => context.push('/library/${doc.id}'));
        },
      ),
    );
  }

  // ── List header: count + sort + filter (narrow) ────────────

  Widget _buildListHeader({required bool narrow}) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 2),
      child: Row(children: [
        // Result info
        Expanded(
          child: Text(
            'Menampilkan ${_pageDocs.length} dari ${_filtered.length} peraturan',
            style: AppTextStyles.body(11, color: AppColors.stone400)),
        ),
        const SizedBox(width: 8),
        // Narrow: show filter dropdown button
        if (narrow) ...[
          _FilterDropdownBtn(
            categories:  _categories,
            selectedCat: _selectedCategoryId,
            advanced:    _advanced,
            availTopics: _availTopics,
            onCatChanged: (id) { setState(() => _selectedCategoryId = id); _apply(); },
            onAdvChanged: (f)  { setState(() => _advanced = f); _apply(); },
          ),
          const SizedBox(width: 6),
        ],
        // Sort
        _SortBtn(value: _sort, onChanged: (s) {
          setState(() => _sort = s); _apply();
        }),
        // Reset
        if (_hasFilter) ...[
          const SizedBox(width: 6),
          GestureDetector(
            onTap: _clearAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.expenseLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.expense.withOpacity(0.3))),
              child: Text('Reset',
                style: AppTextStyles.body(10,
                  color: AppColors.expense, weight: FontWeight.w500)),
            ),
          ),
        ],
      ]),
    );
  }

  // ── Pagination ─────────────────────────────────────────────

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Prev
          _PageBtn(
            icon: Icons.chevron_left_rounded,
            enabled: _page > 0,
            onTap: () => setState(() => _page--),
          ),
          const SizedBox(width: 4),
          // Page numbers
          ...List.generate(_totalPages, (i) {
            final active = i == _page;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                onTap: () => setState(() => _page = i),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: active ? AppColors.brand : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: active ? AppColors.brand : AppColors.stone200,
                      width: 0.5)),
                  child: Center(child: Text('${i + 1}',
                    style: AppTextStyles.body(11,
                      color: active ? Colors.white : AppColors.stone500,
                      weight: active ? FontWeight.w600 : FontWeight.w400))),
                ),
              ),
            );
          }),
          const SizedBox(width: 4),
          // Next
          _PageBtn(
            icon: Icons.chevron_right_rounded,
            enabled: _page < _totalPages - 1,
            onTap: () => setState(() => _page++),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() => ListView.separated(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
    itemCount: 5,
    separatorBuilder: (_, __) => const SizedBox(height: 10),
    itemBuilder: (_, __) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stone200, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Row(children: [ShimmerBox(width: 40, height: 20), SizedBox(width: 8), ShimmerBox(width: 50, height: 20)]),
        SizedBox(height: 10),
        ShimmerBox(width: double.infinity, height: 16),
        SizedBox(height: 5), ShimmerBox(width: 220, height: 14),
        SizedBox(height: 10), ShimmerBox(width: double.infinity, height: 12),
        SizedBox(height: 4),  ShimmerBox(width: 180, height: 12),
      ]),
    ),
  );
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSearch, onClear;
  const _SearchBar({required this.controller, required this.onSearch, required this.onClear});
  @override State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) => Container(
    height: 42,
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.stone200, width: 0.5)),
    child: Row(children: [
      const SizedBox(width: 12),
      Expanded(child: TextField(
        controller: widget.controller,
        onSubmitted: (_) => widget.onSearch(),
        style: AppTextStyles.body(13),
        decoration: InputDecoration(
          hintText: 'Cari regulasi... (PPh Final, PKP)',
          hintStyle: AppTextStyles.body(13, color: AppColors.stone400),
          border: InputBorder.none, isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10)),
      )),
      if (widget.controller.text.isNotEmpty)
        GestureDetector(onTap: widget.onClear,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Icon(Icons.close_rounded, size: 15, color: AppColors.stone400))),
      Container(width: 0.5, height: 20, color: AppColors.stone200,
        margin: const EdgeInsets.symmetric(horizontal: 4)),
      GestureDetector(onTap: widget.onSearch,
        child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Icon(Icons.search_rounded, size: 18,
            color: Theme.of(context).appBarTheme.foregroundColor))),
    ]),
  );
}

// ─── Advanced Panel ───────────────────────────────────────────────────────────

class _AdvancedPanel extends StatefulWidget {
  final AdvancedFilter advanced;
  final List<String>   availTopics;
  final ValueChanged<AdvancedFilter> onChanged;
  const _AdvancedPanel({required this.advanced, required this.availTopics, required this.onChanged});
  @override State<_AdvancedPanel> createState() => _AdvancedPanelState();
}

class _AdvancedPanelState extends State<_AdvancedPanel> {
  late final TextEditingController _perihal, _isi, _nomor, _yfrom, _yto;

  @override
  void initState() {
    super.initState();
    _perihal = TextEditingController(text: widget.advanced.perihal ?? '');
    _isi     = TextEditingController(text: widget.advanced.isiPeraturan ?? '');
    _nomor   = TextEditingController(text: widget.advanced.nomorPeraturan ?? '');
    _yfrom   = TextEditingController(
      text: widget.advanced.yearFrom?.toString() ?? '');
    _yto     = TextEditingController(
      text: widget.advanced.yearTo?.toString() ?? '');
  }

  @override
  void dispose() {
    _perihal.dispose(); _isi.dispose(); _nomor.dispose();
    _yfrom.dispose(); _yto.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(widget.advanced.copyWith(
    perihal:        _perihal.text.trim().isEmpty ? null : _perihal.text.trim(),
    isiPeraturan:   _isi.text.trim().isEmpty     ? null : _isi.text.trim(),
    nomorPeraturan: _nomor.text.trim().isEmpty   ? null : _nomor.text.trim(),
    yearFrom: int.tryParse(_yfrom.text.trim()),
    yearTo:   int.tryParse(_yto.text.trim()),
  ));

  Widget _field(String hint, TextEditingController ctrl,
      {TextInputType? keyboard}) => Container(
    height: 36,
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.stone200, width: 0.5)),
    child: TextField(
      controller: ctrl,
      onSubmitted: (_) => _emit(),
      onChanged: (_) => _emit(),
      keyboardType: keyboard,
      inputFormatters: keyboard == TextInputType.number
          ? [FilteringTextInputFormatter.digitsOnly,
             LengthLimitingTextInputFormatter(4)]
          : null,
      style: AppTextStyles.body(12),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body(12, color: AppColors.stone400),
        border: InputBorder.none, isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 9)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.stone200, width: 0.5)),
      child: Column(children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Perihal', style: AppTextStyles.body(10, color: AppColors.stone400)),
            const SizedBox(height: 4),
            _field('Masukkan perihal...', _perihal),
          ])),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Nomor Peraturan', style: AppTextStyles.body(10, color: AppColors.stone400)),
            const SizedBox(height: 4),
            _field('Cth: 23/2018', _nomor),
          ])),
        ]),
        const SizedBox(height: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Isi Peraturan', style: AppTextStyles.body(10, color: AppColors.stone400)),
          const SizedBox(height: 4),
          _field('Kata kunci dalam isi peraturan...', _isi),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          // Jenis
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Jenis', style: AppTextStyles.body(10, color: AppColors.stone400)),
            const SizedBox(height: 4),
            _ChipPicker<DocType>(
              value:    widget.advanced.docType,
              options:  DocType.values,
              optLabel: (t) => t.label,
              hint:     'Semua',
              onSelect: (t) => widget.onChanged(
                widget.advanced.copyWith(docType: t)),
            ),
          ])),
          const SizedBox(width: 10),
          // Topik
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Topik', style: AppTextStyles.body(10, color: AppColors.stone400)),
            const SizedBox(height: 4),
            _ChipPicker<String>(
              value:    widget.advanced.topic,
              options:  widget.availTopics,
              optLabel: (t) => t,
              hint:     'Semua',
              onSelect: (t) => widget.onChanged(
                widget.advanced.copyWith(topic: t)),
            ),
          ])),
        ]),
        const SizedBox(height: 8),
        // Year range
        Row(children: [
          Text('Tahun:', style: AppTextStyles.body(11, color: AppColors.stone500)),
          const SizedBox(width: 8),
          Expanded(child: _field('Dari (cth: 2018)', _yfrom,
            keyboard: TextInputType.number)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('sampai',
              style: AppTextStyles.body(11, color: AppColors.stone400))),
          Expanded(child: _field('Hingga (cth: 2024)', _yto,
            keyboard: TextInputType.number)),
        ]),
      ]),
    );
  }
}

// ─── Chip Picker (for Jenis + Topik in advanced) ─────────────────────────────

class _ChipPicker<T> extends StatelessWidget {
  final T? value;
  final List<T> options;
  final String Function(T) optLabel;
  final String hint;
  final void Function(T?) onSelect;

  const _ChipPicker({
    required this.value, required this.options,
    required this.optLabel, required this.hint,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final hasVal = value != null;
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: hasVal
            ? AppColors.brand.withOpacity(0.07)
            : Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasVal ? AppColors.brand : AppColors.stone200,
            width: hasVal ? 1.0 : 0.5)),
        child: Row(children: [
          Expanded(child: Text(
            hasVal ? optLabel(value as T) : hint,
            style: AppTextStyles.body(12,
              color: hasVal ? AppColors.brand : AppColors.stone400),
            overflow: TextOverflow.ellipsis)),
          if (hasVal)
            GestureDetector(
              onTap: () => onSelect(null),
              child: Icon(Icons.close_rounded, size: 13, color: AppColors.brand))
          else
            Icon(Icons.keyboard_arrow_down_rounded,
              size: 14, color: AppColors.stone400),
        ]),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.stone200,
              borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Text(hint,
              style: AppTextStyles.display(15))),
            if (value != null)
              GestureDetector(
                onTap: () { onSelect(null); Navigator.pop(context); },
                child: Text('Reset', style: AppTextStyles.body(12,
                  color: AppColors.brand))),
          ]),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: ListView(shrinkWrap: true, children: options.map((opt) {
              final sel = value == opt;
              return ListTile(dense: true, contentPadding: EdgeInsets.zero,
                trailing: sel ? Icon(Icons.check_rounded,
                  size: 16, color: AppColors.brand) : null,
                title: Text(optLabel(opt), style: AppTextStyles.body(13,
                  color: sel ? AppColors.brand : AppColors.stone700,
                  weight: sel ? FontWeight.w500 : FontWeight.w400)),
                onTap: () { onSelect(opt); Navigator.pop(context); });
            }).toList()),
          ),
        ])),
      )),
    ));
  }
}

// ─── Sort Button ──────────────────────────────────────────────────────────────

class _SortBtn extends StatelessWidget {
  final SortOption value;
  final ValueChanged<SortOption> onChanged;
  const _SortBtn({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(16,14,16,28),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width:36,height:4,
            decoration: BoxDecoration(color:AppColors.stone200,
              borderRadius:BorderRadius.circular(2))),
          const SizedBox(height:12),
          Text('Urutkan', style: AppTextStyles.display(15)),
          const SizedBox(height:8),
          ...SortOption.values.map((s) => ListTile(dense:true,
            contentPadding:EdgeInsets.zero,
            trailing: value==s ? Icon(Icons.check_rounded,
              size:16,color:AppColors.brand):null,
            title: Text(s.label, style: AppTextStyles.body(13,
              color: value==s ? AppColors.brand : AppColors.stone700,
              weight: value==s ? FontWeight.w500 : FontWeight.w400)),
            onTap: () { onChanged(s); Navigator.pop(context); })),
        ]),
      ),
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.stone200, width: 0.5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.sort_rounded, size: 12, color: AppColors.stone500),
        const SizedBox(width: 4),
        Text(value.label, style: AppTextStyles.body(10,
          color: AppColors.stone500, weight: FontWeight.w500)),
        const SizedBox(width: 2),
        Icon(Icons.keyboard_arrow_down_rounded,
          size: 12, color: AppColors.stone400),
      ]),
    ),
  );
}

// ─── Filter Dropdown Button (narrow mode) ────────────────────────────────────

class _FilterDropdownBtn extends StatelessWidget {
  final List<DocCategory> categories;
  final String?           selectedCat;
  final AdvancedFilter    advanced;
  final List<String>      availTopics;
  final ValueChanged<String?> onCatChanged;
  final ValueChanged<AdvancedFilter> onAdvChanged;

  const _FilterDropdownBtn({
    required this.categories, required this.selectedCat,
    required this.advanced, required this.availTopics,
    required this.onCatChanged, required this.onAdvChanged,
  });

  int get _activeCount {
    int c = 0;
    if (selectedCat != null) c++;
    c += advanced.activeCount;
    return c;
  }

  @override
  Widget build(BuildContext context) {
    final hasActive = _activeCount > 0;
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (ctx, scroll) => Container(
            decoration: BoxDecoration(
              color: Theme.of(ctx).cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16))),
            child: Column(children: [
              Container(margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.stone200,
                  borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
                child: Row(children: [
                  Text('Filter', style: AppTextStyles.display(15)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Icon(Icons.close_rounded,
                      size: 18, color: AppColors.stone400)),
                ])),
              Divider(height: 0.5, color: AppColors.stone200),
              Expanded(child: _FilterPanel(
                categories:   categories,
                selectedCat:  selectedCat,
                advanced:     advanced,
                availTopics:  availTopics,
                onCatChanged: (id) { onCatChanged(id); Navigator.pop(ctx); },
                onAdvChanged: (f)  { onAdvChanged(f);  Navigator.pop(ctx); },
              )),
            ]),
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: hasActive
            ? AppColors.brand.withOpacity(0.08)
            : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasActive ? AppColors.brand : AppColors.stone200,
            width: hasActive ? 1.0 : 0.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.filter_list_rounded, size: 12,
            color: hasActive ? AppColors.brand : AppColors.stone500),
          const SizedBox(width: 4),
          Text(
            hasActive ? 'Filter ($_activeCount)' : 'Filter',
            style: AppTextStyles.body(10,
              color: hasActive ? AppColors.brand : AppColors.stone500,
              weight: hasActive ? FontWeight.w500 : FontWeight.w400)),
          const SizedBox(width: 2),
          Icon(Icons.keyboard_arrow_down_rounded, size: 12,
            color: hasActive ? AppColors.brand : AppColors.stone400),
        ]),
      ),
    );
  }
}

// ─── Page Button ──────────────────────────────────────────────────────────────

class _PageBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _PageBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: enabled ? onTap : null,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: enabled ? AppColors.stone200 : AppColors.stone100,
          width: 0.5)),
      child: Icon(icon, size: 16,
        color: enabled ? AppColors.stone500 : AppColors.stone300),
    ),
  );
}

// ─── Filter Panel (wide sidebar) ─────────────────────────────────────────────

class _FilterPanel extends StatelessWidget {
  final List<DocCategory> categories;
  final String?           selectedCat;
  final AdvancedFilter    advanced;
  final List<String>      availTopics;
  final ValueChanged<String?> onCatChanged;
  final ValueChanged<AdvancedFilter> onAdvChanged;

  const _FilterPanel({
    required this.categories, required this.selectedCat,
    required this.advanced, required this.availTopics,
    required this.onCatChanged, required this.onAdvChanged,
  });

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(16, 12, 8, 100),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Filter', style: AppTextStyles.display(14)),
      const SizedBox(height: 10),

      _Section(title: 'Kategori', children: [
        _FItem(label: 'Semua', selected: selectedCat == null,
          onTap: () => onCatChanged(null)),
        ...categories.map((c) => _FItem(label: c.name,
          selected: selectedCat == c.id,
          onTap: () => onCatChanged(selectedCat == c.id ? null : c.id))),
      ]),
      const SizedBox(height: 10),

      _Section(title: 'Jenis Dokumen', children: [
        _FItem(label: 'Semua', selected: advanced.docType == null,
          onTap: () => onAdvChanged(advanced.copyWith(docType: null))),
        ...DocType.values.map((t) => _FItem(label: t.label,
          selected: advanced.docType == t,
          onTap: () => onAdvChanged(advanced.copyWith(
            docType: advanced.docType == t ? null : t)))),
      ]),

      if (availTopics.isNotEmpty) ...[
        const SizedBox(height: 10),
        _Section(title: 'Topik', children: [
          _FItem(label: 'Semua', selected: advanced.topic == null,
            onTap: () => onAdvChanged(advanced.copyWith(topic: null))),
          ...availTopics.map((t) => _FItem(label: t,
            selected: advanced.topic == t,
            onTap: () => onAdvChanged(advanced.copyWith(
              topic: advanced.topic == t ? null : t)))),
        ]),
      ],
    ]),
  );
}

class _Section extends StatefulWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});
  @override State<_Section> createState() => _SectionState();
}

class _SectionState extends State<_Section> {
  bool _open = true;
  @override Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.stone200, width: 0.5)),
    child: Column(children: [
      GestureDetector(
        onTap: () => setState(() => _open = !_open),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12,9,10,9),
          child: Row(children: [
            Expanded(child: Text(widget.title,
              style: AppTextStyles.body(12, weight: FontWeight.w500))),
            Icon(
              _open
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
              size: 15, color: AppColors.stone400),
          ]),
        ),
      ),
      if (_open) ...[
        Divider(height: 0.5, color: AppColors.stone200),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: Column(children: widget.children)),
      ],
    ]),
  );
}

class _FItem extends StatelessWidget {
  final String label;
  final bool   selected;
  final VoidCallback onTap;
  const _FItem({required this.label, required this.selected, required this.onTap});

  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Padding(padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Container(width:13, height:13,
          decoration: BoxDecoration(
            color: selected ? AppColors.brand : Colors.transparent,
            border: Border.all(
              color: selected ? AppColors.brand : AppColors.stone300,
              width: 1.5),
            borderRadius: BorderRadius.circular(3)),
          child: selected
            ? const Icon(Icons.check_rounded, size:9, color:Colors.white)
            : null),
        const SizedBox(width: 7),
        Expanded(child: Text(label, style: AppTextStyles.body(11,
          color: selected ? AppColors.brand : AppColors.stone600,
          weight: selected ? FontWeight.w500 : FontWeight.w400),
          overflow: TextOverflow.ellipsis)),
      ]),
    ),
  );
}