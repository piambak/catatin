// test/widget_test.dart
//
// Tes asap: aplikasi harus bisa dirender tanpa exception, dan lapisan data
// mock harus mengembalikan bentuk yang diharapkan layar.
//
// Jalankan: flutter test

import 'package:catatin/core/config/app_config.dart';
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

      await repo.createTransaction(
        TransactionDraft(
          businessId: 'b1',
          date: DateTime.now().toIso8601String().substring(0, 10),
          type: 'INCOME',
          amount: 1000000,
          categoryId: 'ic1',
          paymentMethod: 'CASH',
        ),
      );

      final after = await repo.getTransactions();
      expect(after.length, before.length + 1);
    });

    test(
      'transaksi yang diubah menggantikan versi lama, tidak menggandakan',
      () async {
        final repo = MockTransactionRepository();
        final before = await repo.getTransactions();
        final target = before.first;

        final ok = await repo.updateTransaction(
          target.id,
          TransactionDraft(
            businessId: target.businessId,
            date: target.date.toIso8601String().substring(0, 10),
            type: target.type,
            amount: 4321000,
            categoryId: target.category.id,
            paymentMethod: 'KARTU_DEBIT',
          ),
        );

        final after = await repo.getTransactions();
        final updated = after.where((t) => t.id == target.id);
        expect(ok, isTrue);
        expect(after.length, before.length);
        expect(updated, hasLength(1));
        expect(updated.single.amount, 4321000);
        expect(updated.single.paymentMethod, 'KARTU_DEBIT');
      },
    );
  });

  group('Repos', () {
    tearDown(() => Repos.useDemo(false));

    test('sesi demo membuang implementasi yang tersimpan dan memakai mock', () {
      Repos.transaction = _FakeTransactionRepository();
      expect(Repos.transaction, isA<_FakeTransactionRepository>());

      Repos.useDemo(true);

      expect(Repos.isDemo, isTrue);
      expect(Repos.transaction, isA<MockTransactionRepository>());
      expect(Repos.auth, isA<MockAuthRepository>());
    });
  });

  group('MockAuthRepository', () {
    test(
      'tanpa Supabase tidak ada alur Google dan tidak ada sesi backend',
      () async {
        final repo = MockAuthRepository();
        await expectLater(
          repo.signInWithGoogle(),
          throwsA(same(googleSignInUnsupported)),
        );
        expect(await repo.currentSession(), isNull);
      },
    );

    test('akun demo masuk dengan email + kata sandi', () async {
      final repo = MockAuthRepository();
      expect(await repo.signInProviders(), {'email'});
      await repo.setPassword(newPassword: 'rahasia123');
    });
  });

  test('tanpa define, mode mock menampilkan form daftar email', () {
    expect(AppConfig.dataSource, DataSource.mock);
    expect(AppConfig.emailSignUpEnabled, isTrue);
  });

  testWidgets('tema terpasang tanpa exception', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(body: Text('Catatin')),
      ),
    );

    expect(find.text('Catatin'), findsOneWidget);
  });
}

/// Pengganti implementasi mana pun — cukup untuk memastikan [Repos] benar-benar
/// membuangnya.
class _FakeTransactionRepository extends MockTransactionRepository {}
