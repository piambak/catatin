// lib/screens/library/doc_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import '../../core/services/library_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../widgets/library/lib_widgets.dart';
import '../../widgets/library/related_docs.dart';
import '../../widgets/common/app_widgets.dart';

class DocDetailScreen extends StatefulWidget {
  final String docId;
  const DocDetailScreen({super.key, required this.docId});

  @override
  State<DocDetailScreen> createState() => _DocDetailScreenState();
}

class _DocDetailScreenState extends State<DocDetailScreen> {
  Document? _doc;
  bool _loading      = true;
  bool _bookmarked   = false;
  bool _bookmarkBusy = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final doc = await LibraryService.getDocument(widget.docId);
    final bk  = await LibraryService.isBookmarked(widget.docId);
    setState(() { _doc = doc; _bookmarked = bk; _loading = false; });
  }

  Future<void> _toggleBookmark() async {
    if (_doc == null) return;
    setState(() => _bookmarkBusy = true);
    final next = !_bookmarked;
    await LibraryService.setBookmark(widget.docId, next);
    setState(() { _bookmarked = next; _bookmarkBusy = false; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(next ? 'Disimpan ke bookmark' : 'Bookmark dihapus'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: AppColors.brand))
          : _doc == null
              ? ErrorState(message: 'Dokumen tidak ditemukan.', onRetry: _load)
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final doc = _doc!;
    return CustomScrollView(
      slivers: [
        // ── AppBar — single row: back | badge | title | bookmark ──
        SliverAppBar(
          backgroundColor:
              Theme.of(context).appBarTheme.backgroundColor,
          pinned: true,
          automaticallyImplyLeading: false,
          toolbarHeight: 56,
          title: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => context.pop(),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Theme.of(context).appBarTheme.foregroundColor),
              ),
              const SizedBox(width: 10),
              // Type badge — hide on very narrow screens
              LayoutBuilder(builder: (_, box) {
                // box.maxWidth here is the title area width
                final showBadge = box.maxWidth > 260;
                return Row(mainAxisSize: MainAxisSize.min, children: [
                  if (showBadge) ...[
                    DocTypeBadge(doc.type),
                    const SizedBox(width: 10),
                  ],
                ]);
              }),
              // Title — fills remaining space
              Expanded(
                child: Text(
                  doc.title,
                  style: AppTextStyles.body(13,
                    color: Theme.of(context).appBarTheme.foregroundColor,
                    weight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              // Bookmark button
              BookmarkButton(
                isBookmarked: _bookmarked,
                isLoading:    _bookmarkBusy,
                onTap:        _toggleBookmark,
              ),
            ],
          ),
        ),

        // ── Body ────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          sliver: SliverToBoxAdapter(
            child: LayoutBuilder(builder: (_, box) {
              final wide = box.maxWidth > 700;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 280, child: _SidePanel(doc: doc)),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _MainContent(doc: doc)),
                  ],
                );
              }
              // Narrow: main content only + desktop hint (web only)
              return Column(children: [
                if (kIsWeb) const _DesktopHintBanner(),
                _MainContent(doc: doc),
              ]);
            }),
          ),
        ),
      ],
    );
  }
}

// ─── Main Content (left column) ───────────────────────────────────────────────

class _MainContent extends StatelessWidget {
  final Document doc;
  const _MainContent({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Meta card
        AppCard(child: Column(children: [
          _MetaRow(icon: Icons.category_outlined,
            label: 'Jenis', value: doc.type.label),
          const Divider(height: 1),
          _MetaRow(
            icon: Icons.check_circle_outline_rounded,
            label: 'Status',
            value: doc.isActive ? 'Berlaku' : 'Tidak Berlaku / Diganti',
            valueColor: doc.isActive ? AppColors.income : AppColors.stone400),
          if (doc.effectiveDate != null) ...[
            const Divider(height: 1),
            _MetaRow(
              icon: Icons.event_rounded,
              label: 'Tanggal Berlaku',
              value: Tanggal.long(doc.effectiveDate!)),
          ],
          if (doc.bodyHtml != null) ...[
            const Divider(height: 1),
            _MetaRow(
              icon: Icons.link_rounded,
              label: 'Sumber Resmi',
              value: 'pajak.go.id / jdih.kemenkeu.go.id',
              valueColor: AppColors.navy),
          ],
        ])),
        const SizedBox(height: 14),

        // Tags
        if (doc.tags.isNotEmpty) ...[
          Wrap(spacing: 6, runSpacing: 6,
            children: doc.tags.map<Widget>((t) => TagChip(t)).toList()),
          const SizedBox(height: 14),
        ],

        // Summary
        if (doc.summary != null) ...[
          AppCard(
            backgroundColor: AppColors.navyLight,
            borderColor: AppColors.navyBorder,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.summarize_outlined,
                    size: 15, color: AppColors.navy),
                  const SizedBox(width: 6),
                  Text('Ringkasan', style: AppTextStyles.body(13,
                    color: AppColors.navy, weight: FontWeight.w600)),
                ]),
                const SizedBox(height: 8),
                Text(doc.summary!,
                  style: AppTextStyles.body(13, color: AppColors.navy)),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Body text
        _buildBody(context, doc),
        const SizedBox(height: 14),

        // Source hint
        AppCard(
          backgroundColor: AppColors.stone100,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.info_outline_rounded,
              size: 15, color: AppColors.stone400),
            const SizedBox(width: 8),
            Expanded(child: Text(
              'Konten ini hanya untuk referensi. Untuk keputusan perpajakan, '
              'selalu rujuk teks resmi dari pajak.go.id atau konsultasikan '
              'dengan konsultan pajak.',
              style: AppTextStyles.body(11, color: AppColors.stone400))),
          ]),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, Document doc) {
    if (doc.bodyHtml == null || doc.bodyHtml!.isEmpty) {
      return AppCard(
        child: Center(child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.article_outlined, size: 36, color: AppColors.stone300),
            const SizedBox(height: 10),
            Text('Teks lengkap belum tersedia',
              style: AppTextStyles.body(14, color: AppColors.stone400)),
            const SizedBox(height: 6),
            Text('Kunjungi sumber resmi untuk teks peraturan lengkap.',
              style: AppTextStyles.body(12, color: AppColors.stone400),
              textAlign: TextAlign.center),
          ]),
        )),
      );
    }

    final plain = doc.bodyHtml!
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();

    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Isi Peraturan', style: AppTextStyles.display(15)),
        const SizedBox(height: 12),
        Text(plain, style: AppTextStyles.body(14, color: AppColors.stone700)),
      ]),
    );
  }
}

// ─── Side Panel (right column, tab-based) ────────────────────────────────────

class _SidePanel extends StatefulWidget {
  final Document doc;
  const _SidePanel({required this.doc});

  @override
  State<_SidePanel> createState() => _SidePanelState();
}

class _SidePanelState extends State<_SidePanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.stone200, width: 0.5),
      ),
      child: Column(children: [
        // Tab bar
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.stone200, width: 0.5))),
          child: TabBar(
            controller: _tabCtrl,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelStyle: AppTextStyles.body(
              11, weight: FontWeight.w500),
            unselectedLabelStyle: AppTextStyles.body(
              11, color: AppColors.stone400),
            labelColor:
                Theme.of(context).appBarTheme.foregroundColor,
            unselectedLabelColor: AppColors.stone400,
            indicatorColor: AppColors.brand,
            indicatorWeight: 2,
            indicatorSize: TabBarIndicatorSize.label,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'Indeks'),
              Tab(text: 'Lampiran'),
              Tab(text: 'Riwayat'),
              Tab(text: 'Terkait'),
            ],
          ),
        ),

        // Tab views
        SizedBox(
          height: 480,
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _IndexTab(doc: widget.doc),
              _AttachmentTab(doc: widget.doc),
              _HistoryTab(doc: widget.doc),
              _RelatedTab(doc: widget.doc),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── Tab: Indeks Peraturan ────────────────────────────────────────────────────

class _IndexTab extends StatelessWidget {
  final Document doc;
  const _IndexTab({required this.doc});

  List<String> _extractHeaders(Document doc) {
    if (doc.bodyHtml == null) return [];
    final matches = RegExp(r'<h[1-3][^>]*>(.*?)<\/h[1-3]>',
      caseSensitive: false)
        .allMatches(doc.bodyHtml!)
        .map((m) => m.group(1)
            ?.replaceAll(RegExp(r'<[^>]*>'), '')
            .trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    // Fallback: generate dummy index from pasal numbering
    if (matches.isEmpty) {
      return [
        'Pasal 1 — Ketentuan Umum',
        'Pasal 2 — Subjek Pajak',
        'Pasal 3 — Objek Pajak',
        'Pasal 4 — Tarif dan Dasar Pengenaan',
        'Pasal 5 — Tata Cara Penyetoran',
        'Pasal 6 — Pelaporan',
        'Pasal 7 — Sanksi',
        'Pasal 8 — Ketentuan Peralihan',
        'Pasal 9 — Ketentuan Penutup',
      ];
    }
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    final headers = _extractHeaders(doc);
    if (headers.isEmpty) return _emptyTab(
      Icons.list_alt_rounded, 'Indeks tidak tersedia');

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: headers.length,
      separatorBuilder: (_, __) =>
          Divider(height: 0.5, indent: 42, color: AppColors.stone100),
      itemBuilder: (_, i) => ListTile(
        dense: true,
        leading: Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: AppColors.brand.withOpacity(0.1),
            borderRadius: BorderRadius.circular(5)),
          child: Center(child: Text('${i + 1}',
            style: AppTextStyles.body(9,
              color: AppColors.brand, weight: FontWeight.w600))),
        ),
        title: Text(headers[i],
          style: AppTextStyles.body(12),
          maxLines: 2,
          overflow: TextOverflow.ellipsis),
        trailing: Icon(Icons.chevron_right_rounded,
          size: 14, color: AppColors.stone300),
      ),
    );
  }
}

// ─── Tab: Lampiran ────────────────────────────────────────────────────────────

class _AttachmentTab extends StatelessWidget {
  final Document doc;
  const _AttachmentTab({required this.doc});

  @override
  Widget build(BuildContext context) {
    // Dummy attachment list — replace with real data when backend ready
    final attachments = [
      _Attachment(
        name: 'Lampiran I — Format SPT',
        type: 'PDF',
        size: '245 KB'),
      _Attachment(
        name: 'Lampiran II — Tabel Tarif',
        type: 'PDF',
        size: '88 KB'),
      _Attachment(
        name: 'Lampiran III — Contoh Perhitungan',
        type: 'XLSX',
        size: '120 KB'),
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (attachments.isEmpty)
          _emptyTab(Icons.attach_file_rounded, 'Tidak ada lampiran')
        else ...[
          Text('Lampiran resmi dokumen ini',
            style: AppTextStyles.body(11, color: AppColors.stone400)),
          const SizedBox(height: 10),
          ...attachments.map((a) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.stone200, width: 0.5)),
            child: Row(children: [
              Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: a.type == 'PDF'
                    ? AppColors.expenseLight
                    : const Color(0xFFE6F7EE),
                  borderRadius: BorderRadius.circular(6)),
                child: Center(child: Text(a.type,
                  style: AppTextStyles.body(8,
                    color: a.type == 'PDF'
                      ? AppColors.expense
                      : AppColors.income,
                    weight: FontWeight.w700))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(a.name, style: AppTextStyles.body(12),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(a.size, style: AppTextStyles.body(
                    10, color: AppColors.stone400)),
                ],
              )),
              Icon(Icons.download_outlined,
                size: 16, color: AppColors.stone400),
            ]),
          )),
        ],
      ],
    );
  }
}

class _Attachment {
  final String name, type, size;
  const _Attachment({
    required this.name, required this.type, required this.size});
}

// ─── Tab: Riwayat Perubahan ───────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final Document doc;
  const _HistoryTab({required this.doc});

  @override
  Widget build(BuildContext context) {
    // Dummy history — replace with real data
    final history = [
      _HistoryItem(
        title: doc.title,
        year: doc.effectiveDate?.year.toString() ?? '2024',
        note: 'Versi berlaku saat ini',
        isCurrent: true),
      _HistoryItem(
        title: '${doc.type.label} sebelumnya',
        year: ((doc.effectiveDate?.year ?? 2020) - 3).toString(),
        note: 'Diubah oleh regulasi ini',
        isCurrent: false),
      _HistoryItem(
        title: '${doc.type.label} (versi awal)',
        year: ((doc.effectiveDate?.year ?? 2020) - 6).toString(),
        note: 'Regulasi pertama kali diterbitkan',
        isCurrent: false),
    ];

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('Riwayat perubahan regulasi ini',
          style: AppTextStyles.body(11, color: AppColors.stone400)),
        const SizedBox(height: 12),
        ...history.asMap().entries.map((e) {
          final isLast = e.key == history.length - 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Timeline dot + line
              Column(children: [
                Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: e.value.isCurrent
                      ? AppColors.brand : AppColors.stone300,
                    shape: BoxShape.circle,
                    border: e.value.isCurrent
                      ? Border.all(
                          color: AppColors.brand.withOpacity(0.3),
                          width: 3)
                      : null)),
                if (!isLast) Container(
                  width: 1.5, height: 52,
                  color: AppColors.stone200),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: e.value.isCurrent
                              ? AppColors.incomeLight
                              : AppColors.stone100,
                            borderRadius: BorderRadius.circular(4)),
                          child: Text(e.value.year,
                            style: AppTextStyles.body(9,
                              color: e.value.isCurrent
                                ? AppColors.income : AppColors.stone500,
                              weight: FontWeight.w600))),
                        if (e.value.isCurrent) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.brand.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4)),
                            child: Text('Berlaku',
                              style: AppTextStyles.body(9,
                                color: AppColors.brand,
                                weight: FontWeight.w600))),
                        ],
                      ]),
                      const SizedBox(height: 4),
                      Text(e.value.title,
                        style: AppTextStyles.body(12,
                          weight: FontWeight.w500),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(e.value.note,
                        style: AppTextStyles.body(
                          10, color: AppColors.stone400)),
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

class _HistoryItem {
  final String title, year, note;
  final bool isCurrent;
  const _HistoryItem({
    required this.title, required this.year,
    required this.note, required this.isCurrent});
}

// ─── Tab: Peraturan Terkait ───────────────────────────────────────────────────

class _RelatedTab extends StatelessWidget {
  final Document doc;
  const _RelatedTab({required this.doc});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: RelatedDocs(docId: doc.id, tags: doc.tags),
    );
  }
}

// ─── Desktop Hint Banner (web narrow only) ──────────────────────────────────

class _DesktopHintBanner extends StatelessWidget {
  const _DesktopHintBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.navyLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.navyBorder, width: 0.5),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.desktop_windows_outlined,
          size: 15, color: AppColors.navy),
        const SizedBox(width: 8),
        Text(
          'Buka di desktop untuk fitur lengkap.',
          style: AppTextStyles.body(11, color: AppColors.navy),
        ),
      ]),
    );
  }
}

// ─── Empty tab placeholder ────────────────────────────────────────────────────

Widget _emptyTab(IconData icon, String message) {
  return Center(child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 32, color: AppColors.stone300),
      const SizedBox(height: 8),
      Text(message, style: AppTextStyles.body(
        13, color: AppColors.stone400)),
    ],
  ));
}

// ─── Meta Row ─────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color? valueColor;

  const _MetaRow({
    required this.icon, required this.label,
    required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Icon(icon, size: 16, color: AppColors.stone400),
      const SizedBox(width: 10),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.body(11, color: AppColors.stone400)),
          const SizedBox(height: 2),
          Text(value, style: AppTextStyles.body(14,
            color: valueColor ?? AppColors.stone900,
            weight: FontWeight.w500)),
        ],
      )),
    ]),
  );
}