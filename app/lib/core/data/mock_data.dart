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
  //
  // taxRelevant pada INCOME = masuk peredaran bruto PPh Final, yaitu dasar
  // pengenaan pajak sekaligus akumulasi ambang Rp500 juta.
  // Dasar: PP 55/2022 Ps. 56, 60; PMK 164/2023 Ps. 3, 6.
  //
  // Pada EXPENSE field ini tidak punya makna hukum: di bawah PPh Final tidak ada
  // biaya yang mengurangi apa pun. Diisi false seluruhnya sampai field dipisah
  // menjadi grossTurnover khusus INCOME (F-11).
  //
  // Pemetaan lengkap beserta pasalnya: wiki/domain/pajak/spek-kategori.md (#47)

  static List<TxCategoryData> get txCategories => const [
    // INCOME — masuk peredaran bruto
    TxCategoryData(
      id: 'ic1',
      name: 'Penjualan Produk',
      type: 'INCOME',
      taxRelevant: true,
      isCogs: false,
      icon: '🛍️',
      color: '#059669',
    ),
    // Catat bruto, sebelum potongan penjualan/tunai (PMK 164/2023 Ps. 6 ayat 2).
    TxCategoryData(
      id: 'ic2',
      name: 'Penjualan Jasa',
      type: 'INCOME',
      taxRelevant: true,
      isCogs: false,
      icon: '🔧',
      color: '#059669',
    ),
    // TODO(Q-47-6): komisi perantara/agen asuransi/MLM termasuk pekerjaan bebas
    // (PMK 164/2023 Ps. 3 ayat 4 huruf h, j, k) → bukan objek PPh Final UMKM
    // bagi orang pribadi. Sementara tetap dihitung, menunggu keputusan.
    TxCategoryData(
      id: 'ic3',
      name: 'Komisi',
      type: 'INCOME',
      taxRelevant: true,
      isCogs: false,
      icon: '💼',
      color: '#059669',
    ),
    // TODO(Q-47-3): kategori campuran; dihitung sebagai default konservatif.
    TxCategoryData(
      id: 'ic4',
      name: 'Pendapatan Lain',
      type: 'INCOME',
      taxRelevant: true,
      isCogs: false,
      icon: '💰',
      color: '#059669',
    ),

    // INCOME — di luar peredaran bruto (F-10)
    TxCategoryData(
      id: 'ic5',
      name: 'Modal Masuk',
      type: 'INCOME',
      taxRelevant: false,
      isCogs: false,
      icon: '🏦',
      color: '#0891B2',
    ),
    TxCategoryData(
      id: 'ic6',
      name: 'Pinjaman Diterima',
      type: 'INCOME',
      taxRelevant: false,
      isCogs: false,
      icon: '🤝',
      color: '#0891B2',
    ),
    TxCategoryData(
      id: 'ic7',
      name: 'Hibah & Bantuan',
      type: 'INCOME',
      taxRelevant: false,
      isCogs: false,
      icon: '🎁',
      color: '#0891B2',
    ),
    // Sewa tanah/bangunan, bunga bank, jasa konstruksi: sudah final tersendiri
    // (PMK 164/2023 Ps. 3 ayat 3 huruf c).
    TxCategoryData(
      id: 'ic8',
      name: 'Penghasilan Final Lainnya',
      type: 'INCOME',
      taxRelevant: false,
      isCogs: false,
      icon: '📄',
      color: '#0891B2',
    ),

    // EXPENSE
    TxCategoryData(
      id: 'ec1',
      name: 'Bahan Baku',
      type: 'EXPENSE',
      taxRelevant: false,
      isCogs: true,
      icon: '📦',
      color: '#DC2626',
    ),
    TxCategoryData(
      id: 'ec2',
      name: 'Barang Dagangan',
      type: 'EXPENSE',
      taxRelevant: false,
      isCogs: true,
      icon: '🏪',
      color: '#DC2626',
    ),
    // TODO(Q-47-4): upah produksi langsung seharusnya HPP; kategori ini belum memisahkan.
    TxCategoryData(
      id: 'ec3',
      name: 'Gaji Karyawan',
      type: 'EXPENSE',
      taxRelevant: false,
      isCogs: false,
      icon: '👥',
      color: '#F59E0B',
    ),
    TxCategoryData(
      id: 'ec4',
      name: 'Sewa Tempat',
      type: 'EXPENSE',
      taxRelevant: false,
      isCogs: false,
      icon: '🏠',
      color: '#F59E0B',
    ),
    TxCategoryData(
      id: 'ec5',
      name: 'Listrik & Air',
      type: 'EXPENSE',
      taxRelevant: false,
      isCogs: false,
      icon: '⚡',
      color: '#F59E0B',
    ),
    TxCategoryData(
      id: 'ec6',
      name: 'Internet & Telepon',
      type: 'EXPENSE',
      taxRelevant: false,
      isCogs: false,
      icon: '📱',
      color: '#F59E0B',
    ),
    // TODO(Q-47-7): angkut pembelian seharusnya HPP; kategori ini belum memisahkan.
    TxCategoryData(
      id: 'ec7',
      name: 'Transportasi',
      type: 'EXPENSE',
      taxRelevant: false,
      isCogs: false,
      icon: '🚗',
      color: '#F59E0B',
    ),
    TxCategoryData(
      id: 'ec8',
      name: 'Iklan & Marketing',
      type: 'EXPENSE',
      taxRelevant: false,
      isCogs: false,
      icon: '📢',
      color: '#F59E0B',
    ),
    TxCategoryData(
      id: 'ec9',
      name: 'Perlengkapan Kantor',
      type: 'EXPENSE',
      taxRelevant: false,
      isCogs: false,
      icon: '📎',
      color: '#9CA3AF',
    ),
    // Mengurangi laba, TIDAK mengurangi peredaran bruto (F-02).
    TxCategoryData(
      id: 'eca',
      name: 'Potongan Penjualan',
      type: 'EXPENSE',
      taxRelevant: false,
      isCogs: false,
      icon: '🏷️',
      color: '#9CA3AF',
    ),
    TxCategoryData(
      id: 'ec0',
      name: 'Pajak Dibayar',
      type: 'EXPENSE',
      taxRelevant: false,
      isCogs: false,
      icon: '🧾',
      color: '#9CA3AF',
    ),
    // TODO(K-11..K-13): prive, pokok pinjaman, dan pembelian aset belum punya
    // kategori karena butuh field affectsProfit. Sementara tertampung di sini
    // dan keliru mengurangi laba.
    TxCategoryData(
      id: 'ecx',
      name: 'Pengeluaran Lain',
      type: 'EXPENSE',
      taxRelevant: false,
      isCogs: false,
      icon: '💸',
      color: '#9CA3AF',
    ),
  ];

  /// Ambil kategori berdasarkan id, bukan indeks, supaya penambahan kategori
  /// baru tidak menggeser acuan data contoh.
  static TxCategoryData _cat(String id) =>
      txCategories.firstWhere((c) => c.id == id);

  // ── Transaksi ───────────────────────────────────────────────────────────────

  static List<TxData> get transactions {
    final now = DateTime.now();
    return [
      TxData(
        id: 't1',
        businessId: 'b1',
        date: now.subtract(const Duration(days: 1)),
        type: 'INCOME',
        amount: 5200000,
        category: _cat('ic1'),
        description: 'Penjualan produk online',
        paymentMethod: 'QRIS',
        createdAt: now,
      ),
      TxData(
        id: 't2',
        businessId: 'b1',
        date: now.subtract(const Duration(days: 2)),
        type: 'EXPENSE',
        amount: 2800000,
        category: _cat('ec1'),
        description: 'Restock bahan baku kain',
        paymentMethod: 'TRANSFER',
        createdAt: now,
      ),
      TxData(
        id: 't3',
        businessId: 'b1',
        date: now.subtract(const Duration(days: 5)),
        type: 'EXPENSE',
        amount: 9000000,
        category: _cat('ec3'),
        description: 'Gaji 3 karyawan Oktober',
        paymentMethod: 'TRANSFER',
        createdAt: now,
      ),
      TxData(
        id: 't4',
        businessId: 'b1',
        date: now.subtract(const Duration(days: 6)),
        type: 'INCOME',
        amount: 8500000,
        category: _cat('ic2'),
        description: 'Order custom seragam',
        paymentMethod: 'TRANSFER',
        createdAt: now,
      ),
      TxData(
        id: 't5',
        businessId: 'b1',
        date: now.subtract(const Duration(days: 7)),
        type: 'EXPENSE',
        amount: 620000,
        category: _cat('ec5'),
        description: 'PLN Oktober',
        paymentMethod: 'TRANSFER',
        createdAt: now,
      ),
      TxData(
        id: 't6',
        businessId: 'b1',
        date: now.subtract(const Duration(days: 9)),
        type: 'INCOME',
        amount: 3200000,
        category: _cat('ic1'),
        description: 'Penjualan batik tulis',
        paymentMethod: 'CASH',
        createdAt: now,
      ),
      // Perbaikan: sebelumnya memakai cats[5] (Barang Dagangan) untuk tagihan internet.
      TxData(
        id: 't7',
        businessId: 'b1',
        date: now.subtract(const Duration(days: 12)),
        type: 'EXPENSE',
        amount: 1500000,
        category: _cat('ec6'),
        description: 'Internet Biznet Oktober',
        paymentMethod: 'TRANSFER',
        createdAt: now,
      ),
      TxData(
        id: 't8',
        businessId: 'b1',
        date: now.subtract(const Duration(days: 14)),
        type: 'INCOME',
        amount: 12000000,
        category: _cat('ic2'),
        description: 'Proyek website client',
        paymentMethod: 'TRANSFER',
        createdAt: now,
      ),
      // Contoh non-omzet: tidak boleh menambah akumulasi ambang Rp500 juta,
      // ytdOmzet, maupun pkpPercent.
      TxData(
        id: 't9',
        businessId: 'b1',
        date: now.subtract(const Duration(days: 20)),
        type: 'INCOME',
        amount: 15000000,
        category: _cat('ic6'),
        description: 'Pencairan pinjaman modal kerja',
        paymentMethod: 'TRANSFER',
        createdAt: now,
      ),
    ];
  }

  // ── Dashboard ───────────────────────────────────────────────────────────────

  // Catatan: pkpPercent mengukur akumulasi tahun berjalan terhadap Rp4,8 miliar.
  // Itu ambang kewajiban lapor PKP (PMK 164/2023 Ps. 17), BUKAN ambang kelayakan
  // PPh Final, yang diukur dari peredaran bruto Tahun Pajak sebelumnya
  // (PP 55/2022 Ps. 58 ayat 1). Label di UI harus membedakan keduanya (F-03).
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
      RecentTx(
        id: '1',
        categoryName: 'Penjualan Produk',
        categoryIcon: '🛍️',
        categoryColor: '#059669',
        type: 'INCOME',
        amount: 5200000,
        description: 'Penjualan produk online',
        date: now.subtract(const Duration(days: 1)),
      ),
      RecentTx(
        id: '2',
        categoryName: 'Bahan Baku',
        categoryIcon: '📦',
        categoryColor: '#DC2626',
        type: 'EXPENSE',
        amount: 2800000,
        description: 'Restock bahan baku',
        date: now.subtract(const Duration(days: 2)),
      ),
      RecentTx(
        id: '3',
        categoryName: 'Gaji Karyawan',
        categoryIcon: '👥',
        categoryColor: '#F59E0B',
        type: 'EXPENSE',
        amount: 9000000,
        description: 'Gaji 3 karyawan',
        date: now.subtract(const Duration(days: 5)),
      ),
      RecentTx(
        id: '4',
        categoryName: 'Penjualan Jasa',
        categoryIcon: '🔧',
        categoryColor: '#059669',
        type: 'INCOME',
        amount: 8500000,
        description: 'Order custom seragam',
        date: now.subtract(const Duration(days: 6)),
      ),
      RecentTx(
        id: '5',
        categoryName: 'Listrik & Air',
        categoryIcon: '⚡',
        categoryColor: '#F59E0B',
        type: 'EXPENSE',
        amount: 620000,
        description: 'PLN Oktober',
        date: now.subtract(const Duration(days: 7)),
      ),
    ];
  }

  static List<TaxDeadline> get deadlines {
    final now = DateTime.now();
    return [
      // Setor PPh Final paling lambat tanggal 15 bulan berikutnya
      // (PMK 164/2023 Ps. 7 ayat 2). Tidak muncul pada bulan yang akumulasi
      // peredaran brutonya belum melewati Rp500 juta (Ps. 7 ayat 4 huruf c).
      TaxDeadline(
        id: '1',
        label: 'PPh Final Masa Oktober',
        taxType: 'PPH_FINAL',
        deadline: now.add(const Duration(days: 3)),
        status: 'PENDING',
      ),
      TaxDeadline(
        id: '2',
        label: 'PPh 21 Karyawan Oktober',
        taxType: 'PPH21',
        deadline: now.add(const Duration(days: 8)),
        status: 'PENDING',
      ),
      // Perbaikan (F-13): SPT Tahunan WP orang pribadi jatuh tempo 31 Maret,
      // bukan 30 April yang berlaku untuk WP badan.
      TaxDeadline(
        id: '3',
        label: 'SPT Tahunan OP ${now.year}',
        taxType: 'SPT',
        deadline: DateTime(now.year + 1, 3, 31),
        status: 'PENDING',
      ),
    ];
  }

  static const _kpiMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
  ];

  static const _kpiValues = <String, List<double>>{
    'income': [
      19200000,
      21500000,
      18800000,
      23100000,
      24600000,
      22300000,
      26100000,
      25400000,
      25400000,
      28500000,
    ],
    'expense': [
      13100000,
      14200000,
      13500000,
      15800000,
      16200000,
      14900000,
      17100000,
      16800000,
      16800000,
      18200000,
    ],
    'profit': [
      6100000,
      7300000,
      5300000,
      7300000,
      8400000,
      7400000,
      9000000,
      8600000,
      8600000,
      10300000,
    ],
    'ytd': [
      19200000,
      40700000,
      59500000,
      82600000,
      107200000,
      129500000,
      155600000,
      181000000,
      206400000,
      285000000,
    ],
  };

  static List<KpiPoint> kpiHistory(String metric) {
    final values = _kpiValues[metric] ?? _kpiValues['income']!;
    return List.generate(
      _kpiMonths.length,
      (i) => KpiPoint(month: _kpiMonths[i], value: values[i]),
    );
  }

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
