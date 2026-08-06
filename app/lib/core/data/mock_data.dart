// lib/core/data/mock_data.dart
//
// Seluruh data contoh aplikasi berkumpul di SATU file ini.
//
// Kenapa dikumpulkan: begitu backend siap, file ini yang dihapus — bukan
// berburu `dummyList()` yang tersebar di service dan layar.
//
// Isinya sengaja realistis (rupiah, nama kategori, peraturan pajak asli)
// supaya demo publik di GitHub Pages tetap enak dilihat tanpa backend.

import '../../models/models.dart';

class MockData {
  MockData._();

  /// Jeda buatan supaya shimmer/skeleton di UI tetap kelihatan saat mode mock.
  static const latency = Duration(milliseconds: 220);

  // ── Kategori transaksi ──────────────────────────────────────────────────────

  static List<TxCategoryData> get txCategories => const [
        // INCOME
        TxCategoryData(id: 'ic1', name: 'Penjualan Produk', type: 'INCOME', taxRelevant: true, isCogs: false, icon: '🛍️', color: '#059669'),
        TxCategoryData(id: 'ic2', name: 'Penjualan Jasa', type: 'INCOME', taxRelevant: true, isCogs: false, icon: '🔧', color: '#059669'),
        TxCategoryData(id: 'ic3', name: 'Komisi', type: 'INCOME', taxRelevant: true, isCogs: false, icon: '💼', color: '#059669'),
        TxCategoryData(id: 'ic4', name: 'Pendapatan Lain', type: 'INCOME', taxRelevant: true, isCogs: false, icon: '💰', color: '#059669'),
        // EXPENSE
        TxCategoryData(id: 'ec1', name: 'Bahan Baku', type: 'EXPENSE', taxRelevant: true, isCogs: true, icon: '📦', color: '#DC2626'),
        TxCategoryData(id: 'ec2', name: 'Barang Dagangan', type: 'EXPENSE', taxRelevant: true, isCogs: true, icon: '🏪', color: '#DC2626'),
        TxCategoryData(id: 'ec3', name: 'Gaji Karyawan', type: 'EXPENSE', taxRelevant: true, isCogs: false, icon: '👥', color: '#F59E0B'),
        TxCategoryData(id: 'ec4', name: 'Sewa Tempat', type: 'EXPENSE', taxRelevant: true, isCogs: false, icon: '🏠', color: '#F59E0B'),
        TxCategoryData(id: 'ec5', name: 'Listrik & Air', type: 'EXPENSE', taxRelevant: false, isCogs: false, icon: '⚡', color: '#F59E0B'),
        TxCategoryData(id: 'ec6', name: 'Internet & Telepon', type: 'EXPENSE', taxRelevant: false, isCogs: false, icon: '📱', color: '#F59E0B'),
        TxCategoryData(id: 'ec7', name: 'Transportasi', type: 'EXPENSE', taxRelevant: false, isCogs: false, icon: '🚗', color: '#F59E0B'),
        TxCategoryData(id: 'ec8', name: 'Iklan & Marketing', type: 'EXPENSE', taxRelevant: false, isCogs: false, icon: '📢', color: '#F59E0B'),
        TxCategoryData(id: 'ec9', name: 'Perlengkapan Kantor', type: 'EXPENSE', taxRelevant: false, isCogs: false, icon: '📎', color: '#9CA3AF'),
        TxCategoryData(id: 'ec0', name: 'Pajak Dibayar', type: 'EXPENSE', taxRelevant: true, isCogs: false, icon: '🧾', color: '#9CA3AF'),
        TxCategoryData(id: 'ecx', name: 'Pengeluaran Lain', type: 'EXPENSE', taxRelevant: false, isCogs: false, icon: '💸', color: '#9CA3AF'),
      ];

  // ── Transaksi ───────────────────────────────────────────────────────────────

  static List<TxData> get transactions {
    final now = DateTime.now();
    final cats = txCategories;
    return [
      TxData(id: 't1', businessId: 'b1', date: now.subtract(const Duration(days: 1)), type: 'INCOME', amount: 5200000, category: cats[0], description: 'Penjualan produk online', paymentMethod: 'QRIS', createdAt: now),
      TxData(id: 't2', businessId: 'b1', date: now.subtract(const Duration(days: 2)), type: 'EXPENSE', amount: 2800000, category: cats[4], description: 'Restock bahan baku kain', paymentMethod: 'TRANSFER', createdAt: now),
      TxData(id: 't3', businessId: 'b1', date: now.subtract(const Duration(days: 5)), type: 'EXPENSE', amount: 9000000, category: cats[6], description: 'Gaji 3 karyawan Oktober', paymentMethod: 'TRANSFER', createdAt: now),
      TxData(id: 't4', businessId: 'b1', date: now.subtract(const Duration(days: 6)), type: 'INCOME', amount: 8500000, category: cats[1], description: 'Order custom seragam', paymentMethod: 'TRANSFER', createdAt: now),
      TxData(id: 't5', businessId: 'b1', date: now.subtract(const Duration(days: 7)), type: 'EXPENSE', amount: 620000, category: cats[8], description: 'PLN Oktober', paymentMethod: 'TRANSFER', createdAt: now),
      TxData(id: 't6', businessId: 'b1', date: now.subtract(const Duration(days: 9)), type: 'INCOME', amount: 3200000, category: cats[0], description: 'Penjualan batik tulis', paymentMethod: 'CASH', createdAt: now),
      TxData(id: 't7', businessId: 'b1', date: now.subtract(const Duration(days: 12)), type: 'EXPENSE', amount: 1500000, category: cats[5], description: 'Internet Biznet Oktober', paymentMethod: 'TRANSFER', createdAt: now),
      TxData(id: 't8', businessId: 'b1', date: now.subtract(const Duration(days: 14)), type: 'INCOME', amount: 12000000, category: cats[1], description: 'Proyek website client', paymentMethod: 'TRANSFER', createdAt: now),
    ];
  }

  // ── Dashboard ───────────────────────────────────────────────────────────────

  static const monthlySummary = MonthlySummary(
    income: 28500000,
    expense: 18200000,
    profit: 10300000,
    ytdOmzet: 285000000,
    pkpPercent: 5.9,
    txCount: 12,
  );

  static List<RecentTx> get recentTransactions {
    final now = DateTime.now();
    return [
      RecentTx(id: '1', categoryName: 'Penjualan Produk', categoryIcon: '🛍️', categoryColor: '#059669', type: 'INCOME', amount: 5200000, description: 'Penjualan produk online', date: now.subtract(const Duration(days: 1))),
      RecentTx(id: '2', categoryName: 'Bahan Baku', categoryIcon: '📦', categoryColor: '#DC2626', type: 'EXPENSE', amount: 2800000, description: 'Restock bahan baku', date: now.subtract(const Duration(days: 2))),
      RecentTx(id: '3', categoryName: 'Gaji Karyawan', categoryIcon: '👥', categoryColor: '#F59E0B', type: 'EXPENSE', amount: 9000000, description: 'Gaji 3 karyawan', date: now.subtract(const Duration(days: 5))),
      RecentTx(id: '4', categoryName: 'Penjualan Jasa', categoryIcon: '🔧', categoryColor: '#059669', type: 'INCOME', amount: 8500000, description: 'Order custom seragam', date: now.subtract(const Duration(days: 6))),
      RecentTx(id: '5', categoryName: 'Listrik & Air', categoryIcon: '⚡', categoryColor: '#F59E0B', type: 'EXPENSE', amount: 620000, description: 'PLN Oktober', date: now.subtract(const Duration(days: 7))),
    ];
  }

  static List<TaxDeadline> get deadlines {
    final now = DateTime.now();
    return [
      TaxDeadline(id: '1', label: 'PPh Final Masa Oktober', taxType: 'PPH_FINAL', deadline: now.add(const Duration(days: 3)), status: 'PENDING'),
      TaxDeadline(id: '2', label: 'PPh 21 Karyawan Oktober', taxType: 'PPH21', deadline: now.add(const Duration(days: 8)), status: 'PENDING'),
      TaxDeadline(id: '3', label: 'SPT Tahunan ${now.year}', taxType: 'SPT', deadline: DateTime(now.year + 1, 4, 30), status: 'PENDING'),
    ];
  }

  static const _kpiMonths = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt'];

  static const _kpiValues = <String, List<double>>{
    'income': [19200000, 21500000, 18800000, 23100000, 24600000, 22300000, 26100000, 25400000, 25400000, 28500000],
    'expense': [13100000, 14200000, 13500000, 15800000, 16200000, 14900000, 17100000, 16800000, 16800000, 18200000],
    'profit': [6100000, 7300000, 5300000, 7300000, 8400000, 7400000, 9000000, 8600000, 8600000, 10300000],
    'ytd': [19200000, 40700000, 59500000, 82600000, 107200000, 129500000, 155600000, 181000000, 206400000, 285000000],
  };

  static List<KpiPoint> kpiHistory(String metric) {
    final values = _kpiValues[metric] ?? _kpiValues['income']!;
    return List.generate(
      _kpiMonths.length,
      (i) => KpiPoint(month: _kpiMonths[i], value: values[i]),
    );
  }

  // ── Pustaka peraturan ───────────────────────────────────────────────────────

  static List<DocCategory> get docCategories => const [
        DocCategory(id: 'c1', name: 'PPh Final UMKM', slug: 'pph-final', icon: '📊', color: '#B85C38'),
        DocCategory(id: 'c2', name: 'PPN & PKP', slug: 'ppn', icon: '🧾', color: '#1A4A7A'),
        DocCategory(id: 'c3', name: 'PPh 21 Karyawan', slug: 'pph-21', icon: '👥', color: '#2E6B5E'),
        DocCategory(id: 'c4', name: 'SPT & Pelaporan', slug: 'spt', icon: '📋', color: '#7C3AED'),
        DocCategory(id: 'c5', name: 'Panduan Umum', slug: 'umum', icon: '📚', color: '#6B7280'),
      ];

  static List<Document> get documents => const [
        Document(
          id: 'd1',
          categoryId: 'c1',
          title: 'PP 23 Tahun 2018 — PPh Final UMKM',
          type: DocType.pp,
          isActive: true,
          summary: 'Mengatur tarif PPh Final sebesar 0,5% dari peredaran bruto '
              'untuk Wajib Pajak dengan omzet di bawah Rp 4,8 Miliar per tahun. '
              'Berlaku mulai Juli 2018.',
          tags: ['UMKM', 'Tarif 0.5%', 'PPh Final'],
        ),
        Document(
          id: 'd2',
          categoryId: 'c3',
          title: 'PMK 168/PMK.03/2023 — Tarif Efektif Rata-Rata PPh 21',
          type: DocType.pmk,
          isActive: true,
          summary: 'Menetapkan metode TER (Tarif Efektif Rata-Rata) untuk '
              'pemotongan PPh Pasal 21 karyawan. Berlaku mulai Januari 2024. '
              'Menggantikan metode lama dengan tabel tarif bulanan.',
          tags: ['TER', 'PPh 21', 'Karyawan'],
        ),
        Document(
          id: 'd3',
          categoryId: 'c2',
          title: 'UU No. 7 Tahun 2021 — Harmonisasi Peraturan Perpajakan',
          type: DocType.uu,
          isActive: true,
          summary: 'UU HPP mengubah tarif PPN menjadi 11% (dari 10%), '
              'memperkenalkan PPS (Program Pengungkapan Sukarela), dan '
              'melakukan penyesuaian berbagai ketentuan perpajakan nasional.',
          tags: ['PPN 11%', 'PKP', 'UU HPP'],
        ),
        Document(
          id: 'd4',
          categoryId: 'c4',
          title: 'SE-2/PJ/2024 — Panduan Pengisian e-Filling SPT Tahunan',
          type: DocType.se,
          isActive: true,
          summary: 'Surat edaran Dirjen Pajak tentang tata cara pengisian '
              'SPT Tahunan PPh Orang Pribadi melalui sistem e-Filing DJP Online.',
          tags: ['SPT', 'e-Filing', 'DJP Online'],
        ),
        Document(
          id: 'd5',
          categoryId: 'c1',
          title: 'PMK 164/PMK.03/2023 — Batas Omzet PKP UMKM',
          type: DocType.pmk,
          isActive: true,
          summary: 'Menetapkan batas peredaran bruto Rp 4.800.000.000 per tahun '
              'sebagai threshold wajib menjadi PKP (Pengusaha Kena Pajak).',
          tags: ['PKP', 'UMKM', 'Threshold'],
        ),
        Document(
          id: 'd6',
          categoryId: 'c5',
          title: 'Panduan UMKM: Memilih Rezim Perpajakan yang Tepat',
          type: DocType.panduan,
          isActive: true,
          summary: 'Panduan praktis memilih antara PPh Final 0,5%, Norma '
              'Penghitungan Penghasilan Neto (NPPN), dan pembukuan umum '
              'berdasarkan kondisi bisnis UMKM.',
          tags: ['UMKM', 'Panduan', 'Rezim Pajak'],
        ),
        Document(
          id: 'd7',
          categoryId: 'c3',
          title: 'PER-16/PJ/2016 — Pedoman Teknis PPh Pasal 21',
          type: DocType.perDjp,
          isActive: false,
          summary: 'Peraturan Dirjen Pajak tentang tata cara pemotongan, '
              'penyetoran, dan pelaporan PPh Pasal 21. Telah diganti sebagian '
              'oleh PMK 168/2023 untuk metode TER.',
          tags: ['PPh 21', 'Pemotongan'],
        ),
        Document(
          id: 'd8',
          categoryId: 'c2',
          title: 'Panduan e-Faktur Desktop 3.2 untuk PKP',
          type: DocType.panduan,
          isActive: true,
          summary: 'Panduan lengkap penggunaan aplikasi e-Faktur Desktop versi '
              '3.2 untuk Pengusaha Kena Pajak dalam menerbitkan Faktur Pajak '
              'Keluaran dan melaporkan PPN.',
          tags: ['e-Faktur', 'PKP', 'PPN'],
        ),
      ];

  // ── Akun demo ───────────────────────────────────────────────────────────────

  static UserModel get demoUser => UserModel(
        id: 'demo-user',
        name: 'Pengguna Demo',
        email: 'demo@catatin.id',
        createdAt: DateTime.now(),
      );

  static AuthResponse get demoSession => AuthResponse(
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
        user: demoUser,
      );
}
