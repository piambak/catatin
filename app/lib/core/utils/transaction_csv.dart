// lib/core/utils/transaction_csv.dart
//
// Pemformat CSV rincian transaksi (issue #72). Murni — tanpa I/O, tanpa
// jaringan — jadi satu pemformat ini melayani semua sumber data (mock, api,
// hybrid, supabase). Pengambilan datanya ada di `core/services/export_service.dart`.

import '../../models/models.dart';

/// Pemformat CSV rincian transaksi.
///
/// Kolomnya mengikuti `docs/tax/SPEC-Ekspor.md` §3 (draf, #77). Tiga kolom
/// masih sementara:
///
/// * `masuk_peredaran_bruto_pph` memakai nilai kategori SAAT EKSPOR. Spesifikasi
///   meminta nilai saat transaksi dicatat; itu butuh migrasi snapshot setelah
///   #47.
/// * `masuk_batas_pkp` bernilai `CEK` untuk pemasukan sampai atribut kategori
///   `vatTurnover` ada (#47/#63).
/// * `status_konfirmasi` bernilai `terjadwal` untuk baris dari transaksi
///   berulang, karena belum ada langkah konfirmasi (F-14, Q-62-3).
class TransactionCsv {
  TransactionCsv._();

  /// Penanda UTF-8 di awal berkas supaya Excel membaca aksara dengan benar.
  static const bom = '﻿';

  /// Label wajib di baris pertama setiap berkas ekspor (SPEC-Ekspor §6).
  static const disclaimer =
      'Dokumen ini adalah catatan peredaran bruto dan penghasilan sesuai '
      'Pasal 28 Undang-Undang KUP. Ini BUKAN laporan keuangan dan BUKAN Surat '
      'Pemberitahuan (SPT). Angka PPh Final dan status batas PKP adalah '
      'simulasi berdasarkan data yang Anda catat sendiri, belum diverifikasi '
      'terhadap kalkulator resmi Direktorat Jenderal Pajak.';

  /// Judul kolom, baris keempat berkas.
  static const header =
      'tanggal,kategori,arah,deskripsi,nominal_rupiah,mata_uang_asal,'
      'kurs_dipakai,masuk_peredaran_bruto_pph,masuk_batas_pkp,'
      'status_konfirmasi,metode_pembayaran';

  /// Batas rentang tanggal yang diterima database (constraint 2000–2099),
  /// dipakai untuk ujung yang tidak diisi pada rentang sebelah.
  static final firstDate = DateTime(2000);
  static final lastDate = DateTime(2099, 12, 31);

  static const _eol = '\r\n';
  static final _needsQuote = RegExp(r'[,"\r\n]');

  /// Menyusun berkas CSV: BOM, label, metadata, baris kosong, judul kolom,
  /// lalu satu baris per transaksi — urut tanggal, lalu `createdAt`, lalu id.
  /// Semua baris diakhiri CRLF, termasuk yang terakhir. Tanpa transaksi, hanya
  /// empat baris pertama yang keluar.
  ///
  /// [from] dan [to] adalah rentang yang dipakai untuk metadata. Keduanya
  /// `null` berarti seluruh riwayat; kalau hanya satu yang diisi, ujung lainnya
  /// memakai [firstDate] atau [lastDate]. [categoryLabel] diisi hanya saat
  /// ekspor disaring per kategori.
  static String build(
    List<TxData> transactions, {
    required DateTime exportedAt,
    DateTime? from,
    DateTime? to,
    String? categoryLabel,
  }) {
    final sorted = [...transactions]..sort(_compare);
    final out = StringBuffer(bom)
      ..write(_quote(disclaimer))
      ..write(_eol)
      ..write(
        _quote(
          _metadata(
            exportedAt: exportedAt,
            from: from,
            to: to,
            categoryLabel: categoryLabel,
            rowCount: sorted.length,
          ),
        ),
      )
      ..write(_eol)
      ..write(_eol)
      ..write(header)
      ..write(_eol);
    for (final tx in sorted) {
      out
        ..write(_row(tx))
        ..write(_eol);
    }
    return out.toString();
  }

  /// Nama berkas yang disarankan: `catatin-transaksi-<YYYYMMDD>-<YYYYMMDD>.csv`
  /// untuk rentang, atau `catatin-transaksi-semua.csv` untuk seluruh riwayat
  /// ([from] dan [to] sama-sama `null`).
  static String fileName({DateTime? from, DateTime? to}) {
    if (from == null && to == null) return 'catatin-transaksi-semua.csv';
    final start = _ymd(from ?? firstDate).replaceAll('-', '');
    final end = _ymd(to ?? lastDate).replaceAll('-', '');
    return 'catatin-transaksi-$start-$end.csv';
  }

  static String _metadata({
    required DateTime exportedAt,
    required DateTime? from,
    required DateTime? to,
    required String? categoryLabel,
    required int rowCount,
  }) {
    final range = from == null && to == null
        ? 'rentang: seluruh riwayat'
        : 'rentang ${_ymd(from ?? firstDate)} s.d. ${_ymd(to ?? lastDate)}';
    return 'Diekspor ${_ymd(exportedAt)}; $range'
        '${categoryLabel == null ? '' : '; kategori $categoryLabel'}'
        '; $rowCount transaksi';
  }

  static String _row(TxData tx) {
    final income = tx.isIncome;
    return [
      _ymd(tx.date),
      _quote(_neutralize(tx.category.name)),
      income ? 'Pemasukan' : 'Pengeluaran',
      _quote(_neutralize(tx.description ?? '')),
      _amount(tx.amount),
      '', // mata_uang_asal: aplikasi hanya mencatat Rupiah
      '', // kurs_dipakai
      income && tx.category.taxRelevant ? 'Ya' : 'Tidak',
      income ? 'CEK' : 'Tidak',
      tx.recurringTemplateId == null ? '' : 'terjadwal',
      _quote(tx.paymentMethod),
    ].join(',');
  }

  /// Urut tanggal (tanpa jam), lalu `createdAt`, lalu id — supaya hasilnya
  /// sama setiap kali, apa pun urutan dari repository.
  static int _compare(TxData a, TxData b) {
    final byDay = _dayKey(a.date).compareTo(_dayKey(b.date));
    if (byDay != 0) return byDay;
    final byCreated = a.createdAt.compareTo(b.createdAt);
    if (byCreated != 0) return byCreated;
    return a.id.compareTo(b.id);
  }

  static int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;

  /// Bulat → bilangan bulat (`5000000`); pecahan → tepat dua desimal bertitik
  /// (`1234.50`). Tanpa pemisah ribuan.
  static String _amount(double value) {
    final fixed = value.toStringAsFixed(2);
    return fixed.endsWith('.00') ? fixed.substring(0, fixed.length - 3) : fixed;
  }

  /// `YYYY-MM-DD` dari tanggal kalender [d], tanpa bergantung pada intl.
  static String _ymd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  /// Penangkal formula spreadsheet untuk teks bebas dari pengguna: nilai yang
  /// diawali `=`, `+`, `-`, `@`, tab, atau CR diberi awalan `'` supaya dibaca
  /// sebagai teks, bukan rumus.
  static String _neutralize(String value) {
    if (value.isEmpty) return value;
    return switch (value[0]) {
      '=' || '+' || '-' || '@' || '\t' || '\r' => "'$value",
      _ => value,
    };
  }

  /// Aturan kutip RFC 4180: bungkus dengan `"` kalau ada koma, kutip, CR, LF,
  /// atau spasi di awal/akhir; `"` di dalam digandakan.
  static String _quote(String value) {
    if (value.isEmpty) return value;
    final needsQuote =
        _needsQuote.hasMatch(value) || value.trim().length != value.length;
    return needsQuote ? '"${value.replaceAll('"', '""')}"' : value;
  }
}
