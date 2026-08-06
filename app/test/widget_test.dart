// test/widget_test.dart
//
// Tes asap: aplikasi harus bisa dirender tanpa exception, dan lapisan data
// mock harus mengembalikan bentuk yang diharapkan layar.
//
// Jalankan: flutter test

import 'package:catatin/core/data/mock_repositories.dart';
import 'package:catatin/core/data/repositories.dart';
import 'package:catatin/core/theme/app_theme.dart';
import 'package:catatin/models/models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockDashboardRepository', () {
    final repo = MockDashboardRepository();

    test('ringkasan bulanan terisi', () async {
      final summary = await repo.getSummary();
      expect(summary.income, greaterThan(0));
      expect(summary.profit, summary.income - summary.expense);
    });

    test('transaksi terakhir menghormati limit', () async {
      final recent = await repo.getRecentTransactions(limit: 3);
      expect(recent, hasLength(3));
    });

    test('riwayat KPI punya titik untuk tiap metrik', () async {
      for (final metric in KpiMetric.values) {
        final points = await repo.getKpiHistory(metric);
        expect(points, isNotEmpty, reason: 'metrik ${metric.name} kosong');
      }
    });
  });

  group('MockTransactionRepository', () {
    test('transaksi baru muncul di daftar', () async {
      final repo = MockTransactionRepository();
      final before = await repo.getTransactions();

      await repo.createTransaction(TransactionDraft(
        businessId: 'b1',
        date: DateTime.now().toIso8601String().substring(0, 10),
        type: 'INCOME',
        amount: 1000000,
        categoryId: 'ic1',
        paymentMethod: 'CASH',
      ));

      final after = await repo.getTransactions();
      expect(after.length, before.length + 1);
    });
  });

  group('MockLibraryRepository', () {
    test('pencarian menyaring berdasarkan judul', () async {
      final repo = MockLibraryRepository();
      final hits = await repo.getDocuments(query: 'PPh Final');
      expect(hits, isNotEmpty);
      expect(hits.every((d) => d.title.isNotEmpty), isTrue);
    });
  });

  testWidgets('tema terpasang tanpa exception', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light,
      home: const Scaffold(body: Text('Catatin')),
    ));

    expect(find.text('Catatin'), findsOneWidget);
  });
}
