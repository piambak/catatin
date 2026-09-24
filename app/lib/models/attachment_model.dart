// lib/models/attachment_model.dart
//
// Lampiran struk per transaksi (issue #59): satu atau lebih foto struk boleh
// menempel ke satu transaksi. Berkas sungguhannya tidak pernah lewat model
// ini — hanya metadata dan URL yang sudah ditandatangani (berlaku 1 jam),
// persis bentuk yang dikembalikan kontrak REST dan Supabase.

import 'dart:typed_data';

import '../core/network/api_client.dart';

// ── Batas berkas ──────────────────────────────────────────────────────────────

/// Ukuran maksimal berkas lampiran, dalam byte (5 MB) — sama dengan batas di
/// migrasi `supabase/migrations/…_lampiran_struk.sql` dan kontrak REST.
const kAttachmentMaxBytes = 5242880;

/// Tipe berkas yang diterima — foto struk saja, bukan dokumen apa pun.
const kAttachmentAllowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp'];

/// Memvalidasi berkas SEBELUM permintaan jaringan dikirim, jadi berkas yang
/// jelas ditolak tidak pernah sampai ke server atau Storage.
///
/// Dipanggil setiap implementasi `AttachmentRepository.uploadAttachment` —
/// mock, REST, dan Supabase — persis seperti [checkTransactionFilter] (lihat
/// `core/data/repositories.dart`) untuk filter transaksi. Melempar
/// [ApiException] 400 dengan pesan di `errors['file']`.
void checkAttachmentUpload({
  required Uint8List bytes,
  required String mimeType,
}) {
  if (bytes.isEmpty) {
    throw const ApiException(
      statusCode: 400,
      message: 'Foto kosong.',
      errors: {'file': 'Foto kosong.'},
    );
  }
  if (bytes.length > kAttachmentMaxBytes) {
    throw const ApiException(
      statusCode: 400,
      message: 'Ukuran foto maksimal 5 MB.',
      errors: {'file': 'Ukuran foto maksimal 5 MB.'},
    );
  }
  if (!kAttachmentAllowedMimeTypes.contains(mimeType)) {
    throw const ApiException(
      statusCode: 400,
      message: 'Format foto harus JPEG, PNG, atau WebP.',
      errors: {'file': 'Format foto harus JPEG, PNG, atau WebP.'},
    );
  }
}

// ── Lampiran ──────────────────────────────────────────────────────────────────

class TxAttachment {
  final String id;
  final String transactionId;
  final String fileName;
  final String mimeType;
  final int sizeBytes;

  /// URL bertanda tangan, berlaku sampai [urlExpiresAt] (1 jam sejak diminta
  /// dari server) — tidak pernah disimpan, diminta ulang setiap dibaca.
  final String url;
  final DateTime urlExpiresAt;
  final DateTime createdAt;

  const TxAttachment({
    required this.id,
    required this.transactionId,
    required this.fileName,
    required this.mimeType,
    required this.sizeBytes,
    required this.url,
    required this.urlExpiresAt,
    required this.createdAt,
  });

  factory TxAttachment.fromJson(Map<String, dynamic> j) => TxAttachment(
    id: j['id'] as String,
    transactionId: j['transaction_id'] as String,
    fileName: j['file_name'] as String,
    mimeType: j['mime_type'] as String,
    sizeBytes: (j['size_bytes'] as num).toInt(),
    url: j['url'] as String,
    // Server mengirim UTC; disamakan dengan `TxData.createdAt` supaya jam
    // yang tampil ke pengguna sesuai zona waktu perangkat.
    urlExpiresAt: DateTime.parse(j['url_expires_at'] as String).toLocal(),
    createdAt: DateTime.parse(j['created_at'] as String).toLocal(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'transaction_id': transactionId,
    'file_name': fileName,
    'mime_type': mimeType,
    'size_bytes': sizeBytes,
    'url': url,
    'url_expires_at': urlExpiresAt.toUtc().toIso8601String(),
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}
