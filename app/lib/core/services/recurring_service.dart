// lib/core/services/recurring_service.dart

import '../../models/models.dart';
import '../data/repositories.dart';
import 'accounting_service.dart';

export '../../models/recurring_model.dart';

/// Fasad tipis di atas [Repos.recurring] — layar tidak pernah menyentuh
/// [RecurringRepository] langsung, sama seperti [AccountingService] untuk
/// transaksi biasa.
class RecurringService {
  RecurringService._();

  static Future<List<RecurringTemplate>> getTemplates() =>
      Repos.recurring.getTemplates();

  static Future<RecurringTemplate> createTemplate({
    required String type,
    required double amount,
    required String categoryId,
    String? description,
    required String paymentMethod,
    required String frequency,
    required String startDate,
    String? endDate,
  }) =>
      _notify(Repos.recurring.createTemplate(RecurringDraft(
        type: type,
        amount: amount,
        categoryId: categoryId,
        description: description,
        paymentMethod: paymentMethod,
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
      )));

  static Future<RecurringTemplate> updateTemplate({
    required String id,
    required String type,
    required double amount,
    required String categoryId,
    String? description,
    required String paymentMethod,
    required String frequency,
    required String startDate,
    String? endDate,
  }) =>
      _notify(Repos.recurring.updateTemplate(
        id,
        RecurringDraft(
          type: type,
          amount: amount,
          categoryId: categoryId,
          description: description,
          paymentMethod: paymentMethod,
          frequency: frequency,
          startDate: startDate,
          endDate: endDate,
        ),
      ));

  static Future<RecurringTemplate> stopTemplate(String id) =>
      _notify(Repos.recurring.stopTemplate(id));

  /// Membuat, mengubah, atau menghentikan template bisa langsung menerbitkan
  /// transaksi hari ini di server, jadi Dashboard dan Pencatatan ikut dimuat
  /// ulang lewat penanda yang sama dengan [AccountingService.changes].
  static Future<T> _notify<T>(Future<T> action) async {
    final result = await action;
    AccountingService.changes.value++;
    return result;
  }
}
