// lib/models/document_model.dart

enum DocType { uu, pp, pmk, perDjp, se, kep, panduan }

extension DocTypeExt on DocType {
  String get label => const {
        DocType.uu: 'UU',
        DocType.pp: 'PP',
        DocType.pmk: 'PMK',
        DocType.perDjp: 'PER DJP',
        DocType.se: 'SE',
        DocType.kep: 'KEP',
        DocType.panduan: 'Panduan',
      }[this]!;

  /// Kode yang dipakai di payload API (`UU`, `PER_DJP`, …).
  String get apiValue => const {
        DocType.uu: 'UU',
        DocType.pp: 'PP',
        DocType.pmk: 'PMK',
        DocType.perDjp: 'PER_DJP',
        DocType.se: 'SE',
        DocType.kep: 'KEP',
        DocType.panduan: 'PANDUAN',
      }[this]!;

  static DocType fromString(String s) => const {
        'UU': DocType.uu,
        'PP': DocType.pp,
        'PMK': DocType.pmk,
        'PER_DJP': DocType.perDjp,
        'SE': DocType.se,
        'KEP': DocType.kep,
        'PANDUAN': DocType.panduan,
      }[s] ??
      DocType.panduan;
}

// ── Kategori dokumen ──────────────────────────────────────────────────────────

class DocCategory {
  final String id;
  final String name;
  final String slug;
  final String? icon;
  final String? color;

  const DocCategory({
    required this.id,
    required this.name,
    required this.slug,
    this.icon,
    this.color,
  });

  factory DocCategory.fromJson(Map<String, dynamic> j) => DocCategory(
        id: j['id'] as String,
        name: j['name'] as String,
        slug: j['slug'] as String,
        icon: j['icon'] as String?,
        color: j['color'] as String?,
      );
}

// ── Dokumen / peraturan ───────────────────────────────────────────────────────

class Document {
  final String id;
  final String title;
  final DocType type;
  final String categoryId;
  final String? summary;
  final DateTime? effectiveDate;
  final bool isActive;
  final List<String> tags;
  final String? bodyHtml;

  const Document({
    required this.id,
    required this.title,
    required this.type,
    required this.categoryId,
    this.summary,
    this.effectiveDate,
    required this.isActive,
    this.tags = const [],
    this.bodyHtml,
  });

  factory Document.fromJson(Map<String, dynamic> j) => Document(
        id: j['id'] as String,
        title: j['title'] as String,
        type: DocTypeExt.fromString(j['type'] as String),
        categoryId: j['category_id'] as String? ?? '',
        summary: j['summary'] as String?,
        effectiveDate: j['effective_date'] != null
            ? DateTime.tryParse(j['effective_date'] as String)
            : null,
        isActive: (j['status'] as String?) == 'ACTIVE',
        tags: (j['tags'] as List<dynamic>?)
                ?.map((t) => (t is Map ? t['label'] : t) as String)
                .toList() ??
            [],
        bodyHtml: j['body_html'] as String?,
      );
}
