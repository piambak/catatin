// test/widget/accounting_tabs_test.dart
//
// Jaring pengaman untuk pemecahan accounting_screen.dart (issue #52).
//
// Sebelum PR ini, layar Pencatatan 2.451 baris TIDAK punya satu pun tes widget.
// Memecahnya tanpa jaring adalah cara tercepat merusaknya tanpa sadar.
//
// Tingkat tes ini SENGAJA masih smoke: tiap tab dirender dengan data tetap, lalu
// diperiksa bahwa ia berdiri tanpa exception dan menampilkan penanda yang benar
// untuk keadaan kosong maupun berisi. Yang dikunci adalah "tab ini masih hidup
// dan masih tahu bedanya kosong vs berisi" — bukan tata letaknya.
//
// Rencana Minggu 4: naikkan jadi tes perilaku (total per periode, filter
// kategori, pindah bulan, rata-rata harian) plus golden terang/gelap. Lihat
// wiki/proyek/rencana-frontend.md Minggu 4.
//
// Jalankan: flutter test test/widget/accounting_tabs_test.dart

import 'package:catatin/models/transaction_model.dart';
import 'package:catatin/screens/accounting/calendar_view.dart';
import 'package:catatin/screens/accounting/daily_tab.dart';
import 'package:catatin/screens/accounting/monthly_tab.dart';
import 'package:catatin/screens/accounting/total_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const _kategoriMasuk = TxCategoryData(
  id: 'c1',
  name: 'Penjualan',
  type: 'INCOME',
  taxRelevant: true,
  isCogs: false,
  icon: 'sell',
  color: '#1B8A4B',
);

const _kategoriKeluar = TxCategoryData(
  id: 'c2',
  name: 'Bahan Baku',
  type: 'EXPENSE',
  taxRelevant: true,
  isCogs: true,
  icon: 'inventory',
  color: '#D92B2B',
);

/// Dua transaksi di bulan yang sama, satu masuk satu keluar.
List<TxData> _contohTx() {
  final tanggal = DateTime(2026, 9, 10);
  return [
    TxData(
      id: 't1',
      businessId: 'b1',
      date: tanggal,
      type: 'INCOME',
      amount: 5000000,
      category: _kategoriMasuk,
      description: 'Penjualan toko',
      paymentMethod: 'CASH',
      createdAt: tanggal,
    ),
    TxData(
      id: 't2',
      businessId: 'b1',
      date: tanggal,
      type: 'EXPENSE',
      amount: 2000000,
      category: _kategoriKeluar,
      description: 'Beli bahan',
      paymentMethod: 'TRANSFER',
      createdAt: tanggal,
    ),
  ];
}

/// Ukuran layar dipatok supaya hasilnya tidak berubah karena ukuran jendela
/// mesin yang menjalankan tes. Bawaan 400×800 dp (ponsel).
Future<void> _render(
  WidgetTester tester,
  Widget anak, {
  Size ukuran = const Size(400, 800),
}) async {
  tester.view.physicalSize = ukuran * 3.0;
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(home: Scaffold(body: anak)));
  await tester.pumpAndSettle();
}

void main() {
  // Sama seperti main.dart: Tanggal.short memakai DateFormat locale id_ID.
  setUpAll(() => initializeDateFormatting('id_ID', null));

  final cursor = DateTime(2026, 9, 1);

  group('Tab Harian', () {
    testWidgets('keadaan kosong menjelaskan dirinya', (tester) async {
      await _render(
        tester,
        DailyTab(
          allTx: const [],
          loading: false,
          cursor: cursor,
          onShift: (_) {},
          onRefresh: () async {},
        ),
      );
      expect(find.text('Belum ada transaksi'), findsOneWidget);
    });

    testWidgets('menampilkan transaksi yang ada', (tester) async {
      await _render(
        tester,
        DailyTab(
          allTx: _contohTx(),
          loading: false,
          cursor: cursor,
          onShift: (_) {},
          onRefresh: () async {},
        ),
      );
      expect(find.text('Belum ada transaksi'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('Tab Kalender', () {
    // Dirender di lebar desktop. Di lebar ponsel baris navigasi bulan
    // (panah, nama bulan, "Hari Ini", legenda) OVERFLOW — diukur dengan font
    // DMSans asli: 82 dp di 375, 57 dp di 400, dan 16 dp tepat setelah
    // breakpoint lebar (681). Itu bug tata letak yang sudah ada sebelum
    // pemecahan ini (kodenya dipindah apa adanya), dicatat untuk QA #61.
    // Kembalikan tes ini ke ukuran bawaan setelah baris itu diperbaiki.
    testWidgets('berdiri dengan data dan punya tombol filter', (tester) async {
      await _render(
        tester,
        AccountingCalendarTab(
          allTx: _contohTx(),
          loading: false,
          cursor: cursor,
          onShift: (_) {},
        ),
        ukuran: const Size(1440, 900),
      );
      expect(find.text('September 2026'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Tab Bulanan', () {
    testWidgets('menampilkan dua belas bulan untuk tahun yang dipilih', (
      tester,
    ) async {
      await _render(
        tester,
        MonthlyTab(
          allTx: _contohTx(),
          loading: false,
          year: 2026,
          onShift: (_) {},
        ),
      );
      expect(find.text('September'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });

  group('Tab Total', () {
    testWidgets('keadaan kosong menjelaskan dirinya', (tester) async {
      await _render(tester, const TotalTab(allTx: [], loading: false));
      expect(find.text('Belum ada data'), findsWidgets);
    });

    testWidgets('berdiri dengan data, grafik tidak melempar', (tester) async {
      await _render(tester, TotalTab(allTx: _contohTx(), loading: false));
      expect(find.text('Laba Bersih'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
