// lib/core/services/accounting_service.dart

import '../../models/models.dart';
import '../data/repositories.dart';

export '../../models/transaction_model.dart';

class AccountingService {
  AccountingService._();

  static Future<List<TxCategoryData>> getCategories() =>
      Repos.transaction.getCategories();

  static Future<List<TxData>> getTransactions({
    int? month,
    int? year,
    String? businessId,
  }) =>
      Repos.transaction.getTransactions(
        month: month,
        year: year,
        businessId: businessId,
      );

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
  }) =>
      Repos.transaction.createTransaction(TransactionDraft(
        businessId: businessId,
        date: date,
        type: type,
        amount: amount,
        categoryId: categoryId,
        description: description,
        paymentMethod: paymentMethod,
        receiptNote: receiptNote,
      ));

  static Future<bool> deleteTransaction(String id) =>
      Repos.transaction.deleteTransaction(id);
}
