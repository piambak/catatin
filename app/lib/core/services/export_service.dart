// lib/core/services/export_service.dart
//
// Ekspor CSV transaksi (issue #72). Datanya diambil lewat
// `Repos.transaction.getTransactions` — yang di Supabase sudah memecah per
// 1.000 baris — lalu CSV disusun di Dart oleh `TransactionCsv`. Tidak ada
// server khusus, jadi satu jalur ini berlaku untuk mock, api, hybrid, dan
// supabase. UI ekspornya issue #68.

import '../data/repositories.dart';
import '../utils/transaction_csv.dart';

/// Hasil ekspor CSV: isi berkas, jumlah transaksi di dalamnya, dan nama berkas
/// yang disarankan untuk disimpan.
class CsvExportResult {
  /// Seluruh isi berkas, diawali BOM UTF-8.
  final String csv;

  /// Jumlah baris transaksi (di luar empat baris pembuka).
  final int rowCount;

  /// Mis. `catatin-transaksi-20260101-20260930.csv`, atau
  /// `catatin-transaksi-semua.csv` untuk seluruh riwayat.
  final String suggestedFileName;

  const CsvExportResult({
    required this.csv,
    required this.rowCount,
    required this.suggestedFileName,
  });
}

/// Fasad tipis di atas [Repos.transaction] untuk ekspor — layar tidak pernah
/// menyentuh [TransactionRepository] langsung, sama seperti `RecurringService`.
class ExportService {
  ExportService._();

  /// Mengekspor transaksi pengguna ke CSV. Format kolom dan catatan tiga kolom
  /// sementara ada di [TransactionCsv].
  ///
  /// [from] dan [to] inklusif dan boleh salah satunya saja; yang tidak diisi
  /// memakai [TransactionCsv.firstDate] / [TransactionCsv.lastDate]. Keduanya
  /// kosong berarti seluruh riwayat — ekspor penuh harus selalu bisa, karena
  /// pengguna wajib menyimpan catatan 10 tahun (UU KUP Ps. 28 ayat 11).
  /// [categoryId] menyaring per kategori di sisi klien. [now] hanya untuk tes.
  ///
  /// Melempar [ArgumentError] kalau rentangnya terbalik (from setelah to),
  /// dan `ApiException` dari repository kalau pengambilan data gagal.
  static Future<CsvExportResult> exportTransactionsCsv({
    DateTime? from,
    DateTime? to,
    String? categoryId,
    DateTime? now,
  }) async {
    final fullHistory = from == null && to == null;
    final start = fullHistory ? null : from ?? TransactionCsv.firstDate;
    final end = fullHistory ? null : to ?? TransactionCsv.lastDate;
    if (start != null &&
        end != null &&
        dateOnly(end).isBefore(dateOnly(start))) {
      throw ArgumentError.value(
        end,
        'to',
        'harus sama dengan atau setelah from',
      );
    }

    // Tanpa filter, repository mengembalikan seluruh transaksi (kontrak di
    // `TransactionRepository.getTransactions`).
    final fetched = await Repos.transaction.getTransactions(
      from: start,
      to: end,
    );
    final rows = categoryId == null
        ? fetched
        : fetched.where((tx) => tx.category.id == categoryId).toList();
    final categoryLabel = categoryId == null
        ? null
        : rows.firstOrNull?.category.name ?? categoryId;

    return CsvExportResult(
      csv: TransactionCsv.build(
        rows,
        exportedAt: now ?? DateTime.now(),
        from: start,
        to: end,
        categoryLabel: categoryLabel,
      ),
      rowCount: rows.length,
      suggestedFileName: TransactionCsv.fileName(from: start, to: end),
    );
  }
}
