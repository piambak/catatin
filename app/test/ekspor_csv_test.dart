// test/ekspor_csv_test.dart
//
// Ekspor CSV transaksi (issue #72): pemformat murni `TransactionCsv` (BOM,
// CRLF, tata letak empat baris pembuka, kutip RFC 4180, penangkal formula,
// format nominal, pemetaan kolom pajak, urutan baris) dan `ExportService`
// dengan repository palsu yang disuntik lewat `Repos.transaction`.
//
// Jalankan: flutter test test/ekspor_csv_test.dart

import 'package:catatin/core/data/mock_repositories.dart';
import 'package:catatin/core/data/repositories.dart';
import 'package:catatin/core/network/api_client.dart';
import 'package:catatin/core/services/export_service.dart';
import 'package:catatin/core/utils/transaction_csv.dart';
import 'package:catatin/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

const _bom = '﻿';

// Label wajib (SPEC-Ekspor §6) sebagai satu baris — sengaja ditulis ulang di
// sini, bukan memakai konstanta pemformat, supaya perubahan teks ketahuan.
// Di berkas, label itu satu bidang yang dikutip karena memuat koma.
const _disclaimer =
    'Dokumen ini adalah catatan peredaran bruto dan penghasilan sesuai '
    'Pasal 28 Undang-Undang KUP. Ini BUKAN laporan keuangan dan BUKAN Surat '
    'Pemberitahuan (SPT). Angka PPh Final dan status batas PKP adalah '
    'simulasi berdasarkan data yang Anda catat sendiri, belum diverifikasi '
    'terhadap kalkulator resmi Direktorat Jenderal Pajak.';

const _header =
    'tanggal,kategori,arah,deskripsi,nominal_rupiah,mata_uang_asal,'
    'kurs_dipakai,masuk_peredaran_bruto_pph,masuk_batas_pkp,'
    'status_konfirmasi,metode_pembayaran';

final _exportedAt = DateTime(2026, 10, 7, 14, 30);

TxCategoryData _cat({
  String id = 'ic1',
  String name = 'Penjualan',
  String type = 'INCOME',
  bool taxRelevant = true,
}) => TxCategoryData(
  id: id,
  name: name,
  type: type,
  taxRelevant: taxRelevant,
  isCogs: false,
  icon: '💰',
  color: '#6B7280',
);

TxData _tx({
  String id = 'tx1',
  DateTime? date,
  String type = 'INCOME',
  double amount = 5000000,
  TxCategoryData? category,
  String? description = 'Jual kopi',
  String paymentMethod = 'CASH',
  String? receiptNote,
  DateTime? createdAt,
  String? recurringTemplateId,
}) => TxData(
  id: id,
  businessId: 'b1',
  date: date ?? DateTime(2026, 9, 18),
  type: type,
  amount: amount,
  category: category ?? _cat(),
  description: description,
  paymentMethod: paymentMethod,
  receiptNote: receiptNote,
  createdAt: createdAt ?? DateTime(2026, 9, 18, 10),
  recurringTemplateId: recurringTemplateId,
);

String _build(
  List<TxData> txs, {
  DateTime? from,
  DateTime? to,
  String? categoryLabel,
}) => TransactionCsv.build(
  txs,
  exportedAt: _exportedAt,
  from: from,
  to: to,
  categoryLabel: categoryLabel,
);

/// Baris data pertama (baris ke-5) dari berkas yang berisi [tx] saja.
String _dataRow(TxData tx) => _build([tx]).split('\r\n')[4];

/// Repository palsu: mencatat parameter setiap panggilan, lalu mengembalikan
/// [rows] apa adanya (penyaringan tanggal adalah urusan repository asli).
class _FakeTx implements TransactionRepository {
  _FakeTx(this.rows, {this.error});

  final List<TxData> rows;
  final Object? error;
  final calls =
      <
        ({
          int? month,
          int? year,
          DateTime? from,
          DateTime? to,
          String? businessId,
        })
      >[];

  @override
  Future<List<TxData>> getTransactions({
    int? month,
    int? year,
    DateTime? from,
    DateTime? to,
    String? businessId,
  }) async {
    calls.add((
      month: month,
      year: year,
      from: from,
      to: to,
      businessId: businessId,
    ));
    if (error != null) throw error!;
    return rows;
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  group('TransactionCsv — bentuk berkas', () {
    test('diawali BOM UTF-8 dan setiap baris diakhiri CRLF', () {
      final csv = _build([_tx(id: 'a'), _tx(id: 'b')]);

      expect(csv.startsWith(_bom), isTrue);
      expect(csv.endsWith('\r\n'), isTrue);
      // Tanpa CRLF, tidak boleh tersisa CR atau LF lepas (data contoh tidak
      // berisi baris baru).
      final sisa = csv.replaceAll('\r\n', '');
      expect(sisa.contains('\r'), isFalse);
      expect(sisa.contains('\n'), isFalse);
      expect(csv.split('\r\n'), hasLength(2 + 4 + 1)); // data + pembuka + ekor
    });

    test('baris 1–4: label, metadata, baris kosong, judul kolom', () {
      final csv = _build(
        [_tx(id: 'a'), _tx(id: 'b')],
        from: DateTime(2026),
        to: DateTime(2026, 9, 30),
      );
      final lines = csv.split('\r\n');

      expect(lines[0], '$_bom"$_disclaimer"');
      expect(
        lines[1],
        'Diekspor 2026-10-07; rentang 2026-01-01 s.d. 2026-09-30; '
        '2 transaksi',
      );
      expect(lines[2], '');
      expect(lines[3], _header);
      expect(lines[3], TransactionCsv.header);
    });

    test('metadata seluruh riwayat dan metadata saringan kategori', () {
      final semua = _build([_tx()]).split('\r\n')[1];
      expect(
        semua,
        'Diekspor 2026-10-07; rentang: seluruh riwayat; 1 transaksi',
      );

      final perKategori = _build([
        _tx(),
      ], categoryLabel: 'Penjualan').split('\r\n')[1];
      expect(
        perKategori,
        'Diekspor 2026-10-07; rentang: seluruh riwayat; '
        'kategori Penjualan; 1 transaksi',
      );
    });

    test('metadata satu bidang: kategori ber-koma dikutip', () {
      final line = _build([], categoryLabel: 'Jasa, Lainnya').split('\r\n')[1];
      expect(
        line,
        '"Diekspor 2026-10-07; rentang: seluruh riwayat; '
        'kategori Jasa, Lainnya; 0 transaksi"',
      );
    });

    test('tanpa transaksi: hanya empat baris pembuka, tetap berkas sah', () {
      final csv = _build([]);

      expect(
        csv,
        '$_bom"$_disclaimer"\r\n'
        'Diekspor 2026-10-07; rentang: seluruh riwayat; 0 transaksi\r\n'
        '\r\n'
        '$_header\r\n',
      );
    });

    test('nama berkas: rentang, seluruh riwayat, dan sebelah saja', () {
      expect(TransactionCsv.fileName(), 'catatin-transaksi-semua.csv');
      expect(
        TransactionCsv.fileName(
          from: DateTime(2026),
          to: DateTime(2026, 9, 30),
        ),
        'catatin-transaksi-20260101-20260930.csv',
      );
      expect(
        TransactionCsv.fileName(from: DateTime(2026, 3, 5)),
        'catatin-transaksi-20260305-20991231.csv',
      );
      expect(
        TransactionCsv.fileName(to: DateTime(2026, 3, 5)),
        'catatin-transaksi-20000101-20260305.csv',
      );
    });
  });

  group('TransactionCsv — kutip RFC 4180', () {
    test('teks biasa tidak dikutip', () {
      expect(
        _dataRow(_tx(description: 'Jual kopi')),
        '2026-09-18,Penjualan,Pemasukan,Jual kopi,5000000,,,Ya,CEK,,CASH',
      );
    });

    test('koma, kutip, baris baru, dan spasi di tepi memicu kutip', () {
      expect(
        _dataRow(_tx(description: 'kopi, gula')),
        contains(',"kopi, gula",'),
      );
      expect(
        _dataRow(_tx(description: 'kata "hemat"')),
        contains(',"kata ""hemat""",'),
      );
      expect(
        _dataRow(_tx(description: 'baris1\nbaris2')),
        contains(',"baris1\nbaris2",'),
      );
      expect(
        _dataRow(_tx(description: ' spasi awal')),
        contains('," spasi awal",'),
      );
      expect(
        _dataRow(_tx(description: 'spasi akhir ')),
        contains(',"spasi akhir ",'),
      );
    });

    test('CRLF di dalam bidang tetap utuh dan dikutip', () {
      final csv = _build([_tx(description: 'a\r\nb')]);
      expect(csv, contains(',"a\r\nb",'));
    });

    test(
      'spasi di tengah tidak memicu kutip; deskripsi kosong tetap kosong',
      () {
        expect(_dataRow(_tx(description: 'a b')), contains(',a b,'));
        expect(
          _dataRow(_tx(description: null)),
          '2026-09-18,Penjualan,Pemasukan,,5000000,,,Ya,CEK,,CASH',
        );
      },
    );

    test('nama kategori ikut dikutip', () {
      expect(
        _dataRow(_tx(category: _cat(name: 'Jasa, Konsultasi'))),
        startsWith('2026-09-18,"Jasa, Konsultasi",Pemasukan,'),
      );
    });
  });

  group('TransactionCsv — penangkal formula', () {
    test(
      'kategori dan deskripsi yang diawali = + - @ tab CR diberi awalan \'',
      () {
        for (final awal in ['=', '+', '-', '@', '\t']) {
          final row = _dataRow(
            _tx(
              category: _cat(name: '${awal}Kat'),
              description: '${awal}Desk',
            ),
          );
          expect(
            row,
            '2026-09-18,\'${awal}Kat,Pemasukan,\'${awal}Desk,5000000,,,Ya,CEK,,CASH',
            reason: 'awalan ${awal.codeUnitAt(0)}',
          );
        }
      },
    );

    test('CR di awal: diberi awalan lalu dikutip karena memuat CR', () {
      final csv = _build([_tx(description: '\rx')]);
      expect(csv, contains(',"\'\rx",'));
    });

    test('awalan dipasang sebelum aturan kutip', () {
      expect(_dataRow(_tx(description: '=1,2')), contains(',"\'=1,2",'));
    });

    test('hanya di awal nilai: tanda di tengah dibiarkan', () {
      expect(
        _dataRow(
          _tx(
            category: _cat(name: 'A=B'),
            description: 'tak-ada+@',
          ),
        ),
        '2026-09-18,A=B,Pemasukan,tak-ada+@,5000000,,,Ya,CEK,,CASH',
      );
    });

    test(
      'bidang lain tidak disentuh (metode pembayaran, tanggal, nominal)',
      () {
        expect(_dataRow(_tx(paymentMethod: '=OTHER')), endsWith(',=OTHER'));
        expect(
          _dataRow(_tx(paymentMethod: '-X', recurringTemplateId: 'rec1')),
          endsWith(',terjadwal,-X'),
        );
      },
    );
  });

  group('TransactionCsv — nominal', () {
    String nominal(double amount) =>
        _dataRow(_tx(amount: amount)).split(',')[4];

    test('bulat: bilangan bulat tanpa pemisah ribuan', () {
      expect(nominal(5000000), '5000000');
      expect(nominal(1000000000), '1000000000');
      expect(nominal(1), '1');
      expect(nominal(250000.0), '250000');
    });

    test('pecahan: tepat dua desimal bertitik', () {
      expect(nominal(1234.5), '1234.50');
      expect(nominal(0.07), '0.07');
      expect(nominal(1234.56), '1234.56');
      expect(nominal(99.999), '100');
    });
  });

  group('TransactionCsv — kolom pajak dan status', () {
    test('pemasukan kategori kena peredaran bruto: Ya + CEK', () {
      expect(
        _dataRow(_tx(category: _cat(taxRelevant: true))),
        '2026-09-18,Penjualan,Pemasukan,Jual kopi,5000000,,,Ya,CEK,,CASH',
      );
    });

    test('pemasukan kategori non-peredaran (mis. modal): Tidak + CEK', () {
      expect(
        _dataRow(
          _tx(
            category: _cat(id: 'ic5', name: 'Modal', taxRelevant: false),
          ),
        ),
        '2026-09-18,Modal,Pemasukan,Jual kopi,5000000,,,Tidak,CEK,,CASH',
      );
    });

    test('pengeluaran: Tidak + Tidak, apa pun taxRelevant kategorinya', () {
      for (final taxRelevant in [true, false]) {
        expect(
          _dataRow(
            _tx(
              type: 'EXPENSE',
              category: _cat(
                id: 'ec1',
                name: 'Bahan Baku',
                type: 'EXPENSE',
                taxRelevant: taxRelevant,
              ),
              description: 'Beli biji kopi',
              amount: 1234.5,
              paymentMethod: 'TRANSFER',
            ),
          ),
          '2026-09-18,Bahan Baku,Pengeluaran,Beli biji kopi,1234.50,,,Tidak,'
          'Tidak,,TRANSFER',
        );
      }
    });

    test('transaksi dari template berulang: terjadwal; manual: kosong', () {
      expect(
        _dataRow(_tx(recurringTemplateId: 'rec_01')),
        endsWith(',Ya,CEK,terjadwal,CASH'),
      );
      expect(_dataRow(_tx()), endsWith(',Ya,CEK,,CASH'));
    });

    test(
      'mata uang asal dan kurs selalu kosong; catatan struk tidak diekspor',
      () {
        final csv = _build([_tx(receiptNote: 'catatan-struk-rahasia')]);
        expect(csv.contains('catatan-struk-rahasia'), isFalse);
        expect(csv.split('\r\n')[4].split(',').sublist(5, 7), ['', '']);
      },
    );

    test('metode pembayaran diekspor sebagai kode apa adanya', () {
      for (final code in [
        'CASH',
        'TRANSFER',
        'QRIS',
        'KARTU_DEBIT',
        'KARTU_KREDIT',
        'COD',
        'OTHER',
      ]) {
        expect(_dataRow(_tx(paymentMethod: code)), endsWith(',$code'));
      }
    });
  });

  group('TransactionCsv — urutan baris', () {
    // Id dipakai sebagai deskripsi supaya urutannya terbaca dari berkas.
    List<String> urutan(List<TxData> txs) => _build(txs)
        .split('\r\n')
        .skip(4)
        .where((l) => l.isNotEmpty)
        .map((l) => l.split(',')[3])
        .toList();

    test('tanggal naik, lalu createdAt, lalu id', () {
      final txs = [
        _tx(id: 'A', description: 'A', createdAt: DateTime(2026, 9, 18, 10)),
        _tx(
          id: 'B',
          description: 'B',
          date: DateTime(2026, 9, 17),
          createdAt: DateTime(2026, 9, 17, 12),
        ),
        _tx(id: 'Z', description: 'Z', createdAt: DateTime(2026, 9, 18, 9)),
        _tx(id: 'D', description: 'D', createdAt: DateTime(2026, 9, 18, 10)),
        _tx(
          id: 'Y',
          description: 'Y',
          date: DateTime(2026, 9, 18, 23, 59), // hari sama, jam berbeda
          createdAt: DateTime(2026, 9, 18, 8),
        ),
        _tx(
          id: 'F',
          description: 'F',
          date: DateTime(2025, 12, 31),
          createdAt: DateTime(2026, 1, 1),
        ),
      ];

      // F (2025) → B (17 Sep) → hari 18 Sep: Y (08.00), Z (09.00), lalu A dan D
      // yang createdAt-nya kembar (10.00) dibedakan id.
      expect(urutan(txs), ['F', 'B', 'Y', 'Z', 'A', 'D']);
    });

    test(
      'urutannya tidak bergantung pada urutan masukan, dan masukan utuh',
      () {
        final txs = [
          _tx(id: '3', description: '3', date: DateTime(2026, 9, 20)),
          _tx(id: '1', description: '1', date: DateTime(2026, 9, 1)),
          _tx(id: '2', description: '2', date: DateTime(2026, 9, 10)),
        ];
        final salinan = [...txs];

        expect(urutan(txs), ['1', '2', '3']);
        expect(urutan(txs.reversed.toList()), ['1', '2', '3']);
        expect(txs, salinan);
      },
    );
  });

  group('ExportService', () {
    tearDown(() => Repos.useDemo(false));

    _FakeTx pasang(List<TxData> rows, {Object? error}) {
      final fake = _FakeTx(rows, error: error);
      Repos.transaction = fake;
      return fake;
    }

    final penjualan = _cat();
    final bahan = _cat(
      id: 'ec1',
      name: 'Bahan Baku',
      type: 'EXPENSE',
      taxRelevant: false,
    );
    final rows = [
      _tx(id: 'a', category: penjualan, description: 'A'),
      _tx(id: 'b', category: bahan, type: 'EXPENSE', description: 'B'),
      _tx(id: 'c', category: penjualan, description: 'C'),
    ];

    test(
      'seluruh riwayat: repository dipanggil tanpa filter apa pun',
      () async {
        final fake = pasang(rows);

        final hasil = await ExportService.exportTransactionsCsv(
          now: _exportedAt,
        );

        expect(fake.calls, hasLength(1));
        final call = fake.calls.single;
        expect(call.from, isNull);
        expect(call.to, isNull);
        expect(call.month, isNull);
        expect(call.year, isNull);
        expect(call.businessId, isNull);
        expect(hasil.rowCount, 3);
        expect(hasil.suggestedFileName, 'catatin-transaksi-semua.csv');
        expect(
          hasil.csv.split('\r\n')[1],
          'Diekspor 2026-10-07; rentang: seluruh riwayat; 3 transaksi',
        );
      },
    );

    test('rentang from/to diteruskan apa adanya ke repository', () async {
      final fake = pasang(rows);
      final from = DateTime(2026, 1, 1);
      final to = DateTime(2026, 9, 30);

      final hasil = await ExportService.exportTransactionsCsv(
        from: from,
        to: to,
        now: _exportedAt,
      );

      expect(fake.calls.single.from, from);
      expect(fake.calls.single.to, to);
      expect(fake.calls.single.month, isNull);
      expect(fake.calls.single.year, isNull);
      expect(
        hasil.suggestedFileName,
        'catatin-transaksi-20260101-20260930.csv',
      );
      expect(
        hasil.csv.split('\r\n')[1],
        'Diekspor 2026-10-07; rentang 2026-01-01 s.d. 2026-09-30; 3 transaksi',
      );
    });

    test(
      'rentang sebelah: ujung yang kosong diisi 2000-01-01 / 2099-12-31',
      () async {
        final fake = pasang(rows);

        final hanyaFrom = await ExportService.exportTransactionsCsv(
          from: DateTime(2026, 3, 5),
          now: _exportedAt,
        );
        expect(fake.calls.last.from, DateTime(2026, 3, 5));
        expect(fake.calls.last.to, DateTime(2099, 12, 31));
        expect(
          hanyaFrom.suggestedFileName,
          'catatin-transaksi-20260305-20991231.csv',
        );
        expect(
          hanyaFrom.csv.split('\r\n')[1],
          contains('rentang 2026-03-05 s.d. 2099-12-31'),
        );

        final hanyaTo = await ExportService.exportTransactionsCsv(
          to: DateTime(2026, 3, 5),
          now: _exportedAt,
        );
        expect(fake.calls.last.from, DateTime(2000, 1, 1));
        expect(fake.calls.last.to, DateTime(2026, 3, 5));
        expect(
          hanyaTo.suggestedFileName,
          'catatin-transaksi-20000101-20260305.csv',
        );
      },
    );

    test('from setelah to: ArgumentError, repository tidak disentuh', () async {
      final fake = pasang(rows);

      await expectLater(
        ExportService.exportTransactionsCsv(
          from: DateTime(2026, 10, 1),
          to: DateTime(2026, 9, 30),
        ),
        throwsArgumentError,
      );
      // Sebelah saja pun terbalik kalau melewati ujung lainnya.
      await expectLater(
        ExportService.exportTransactionsCsv(from: DateTime(2100)),
        throwsArgumentError,
      );
      expect(fake.calls, isEmpty);
    });

    test('from dan to di hari yang sama diterima, jam diabaikan', () async {
      pasang(rows);

      final hasil = await ExportService.exportTransactionsCsv(
        from: DateTime(2026, 9, 18, 23),
        to: DateTime(2026, 9, 18, 1),
        now: _exportedAt,
      );

      expect(
        hasil.suggestedFileName,
        'catatin-transaksi-20260918-20260918.csv',
      );
    });

    test(
      'categoryId menyaring di sisi klien; rowCount dan metadata ikut',
      () async {
        final fake = pasang(rows);

        final hasil = await ExportService.exportTransactionsCsv(
          categoryId: 'ic1',
          now: _exportedAt,
        );

        expect(
          fake.calls.single.from,
          isNull,
        ); // saringan bukan urusan repository
        expect(hasil.rowCount, 2);
        final lines = hasil.csv.split('\r\n');
        expect(
          lines[1],
          'Diekspor 2026-10-07; rentang: seluruh riwayat; '
          'kategori Penjualan; 2 transaksi',
        );
        expect(lines.skip(4).where((l) => l.isNotEmpty), hasLength(2));
        expect(hasil.csv.contains('Bahan Baku'), isFalse);
      },
    );

    test('categoryId tanpa transaksi: berkas kosong berlabel id-nya', () async {
      pasang(rows);

      final hasil = await ExportService.exportTransactionsCsv(
        categoryId: 'ic9',
        now: _exportedAt,
      );

      expect(hasil.rowCount, 0);
      expect(
        hasil.csv.split('\r\n')[1],
        'Diekspor 2026-10-07; rentang: seluruh riwayat; kategori ic9; '
        '0 transaksi',
      );
    });

    test('rowCount sama dengan jumlah baris data di berkas', () async {
      pasang(rows);

      final hasil = await ExportService.exportTransactionsCsv(now: _exportedAt);

      final baris = hasil.csv.split('\r\n').skip(4).where((l) => l.isNotEmpty);
      expect(baris, hasLength(hasil.rowCount));
    });

    test('tanpa transaksi sama sekali: berkas sah, rowCount nol', () async {
      pasang(const []);

      final hasil = await ExportService.exportTransactionsCsv(now: _exportedAt);

      expect(hasil.rowCount, 0);
      expect(hasil.csv, startsWith(_bom));
      expect(hasil.csv.endsWith('$_header\r\n'), isTrue);
    });

    test('galat repository naik apa adanya', () async {
      const galat = ApiException(statusCode: 500, message: 'gagal');
      pasang(rows, error: galat);

      await expectLater(
        ExportService.exportTransactionsCsv(),
        throwsA(same(galat)),
      );
    });

    test(
      'repository mock: seluruh riwayat memuat semua transaksinya',
      () async {
        final repo = MockTransactionRepository();
        Repos.transaction = repo;
        final semua = await repo.getTransactions();

        final hasil = await ExportService.exportTransactionsCsv(
          now: _exportedAt,
        );

        expect(semua, isNotEmpty);
        expect(hasil.rowCount, semua.length);
        expect(hasil.csv.startsWith(_bom), isTrue);
      },
    );
  });
}
