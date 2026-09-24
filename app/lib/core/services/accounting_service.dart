// lib/core/services/accounting_service.dart

import 'package:flutter/foundation.dart';

import '../../models/models.dart';
import '../data/repositories.dart';

export '../../models/transaction_model.dart';

class AccountingService {
  AccountingService._();

  /// Naik setiap transaksi dibuat, diubah, atau dihapus.
  ///
  /// Dashboard dan Pencatatan tetap hidup di `IndexedStack`, jadi tidak
  /// dibangun ulang saat tab berganti. Keduanya mendengarkan penanda ini untuk
  /// memuat ulang angkanya.
  static final changes = ValueNotifier<int>(0);

  static Future<List<TxCategoryData>> getCategories() =>
      Repos.transaction.getCategories();

  static Future<List<TxData>> getTransactions({
    int? month,
    int? year,
    DateTime? from,
    DateTime? to,
    String? businessId,
  }) => Repos.transaction.getTransactions(
    month: month,
    year: year,
    from: from,
    to: to,
    businessId: businessId,
  );

  static Future<YearAggregate> getAggregate({required int year}) =>
      Repos.transaction.getAggregate(year: year);

  static Future<TxData?> getTransaction(String id) =>
      Repos.transaction.getTransaction(id);

  static Future<bool> createTransaction({
    required String businessId,
    required String date,
    required String type,
    required double amount,
    required String categoryId,
    String? description,
    required String paymentMethod,
    String? receiptNote,
  }) => _notifyIfOk(
    Repos.transaction.createTransaction(
      TransactionDraft(
        businessId: businessId,
        date: date,
        type: type,
        amount: amount,
        categoryId: categoryId,
        description: description,
        paymentMethod: paymentMethod,
        receiptNote: receiptNote,
      ),
    ),
  );

  static Future<bool> updateTransaction({
    required String id,
    required String businessId,
    required String date,
    required String type,
    required double amount,
    required String categoryId,
    String? description,
    required String paymentMethod,
    String? receiptNote,
  }) => _notifyIfOk(
    Repos.transaction.updateTransaction(
      id,
      TransactionDraft(
        businessId: businessId,
        date: date,
        type: type,
        amount: amount,
        categoryId: categoryId,
        description: description,
        paymentMethod: paymentMethod,
        receiptNote: receiptNote,
      ),
    ),
  );

  static Future<bool> deleteTransaction(String id) =>
      _notifyIfOk(Repos.transaction.deleteTransaction(id));

  static Future<bool> _notifyIfOk(Future<bool> action) async {
    final ok = await action;
    if (ok) changes.value++;
    return ok;
  }
}
