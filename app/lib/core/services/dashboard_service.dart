// lib/core/services/dashboard_service.dart

import '../../models/models.dart';
import '../data/repositories.dart';

export '../../models/dashboard_model.dart';
export '../data/repositories.dart' show KpiMetric;

class DashboardService {
  DashboardService._();

  static Future<MonthlySummary> getSummary({int? month, int? year}) =>
      Repos.dashboard.getSummary(month: month, year: year);

  static Future<List<RecentTx>> getRecentTransactions({int limit = 5}) =>
      Repos.dashboard.getRecentTransactions(limit: limit);

  static Future<List<TaxDeadline>> getDeadlines({int limit = 3}) =>
      Repos.dashboard.getDeadlines(limit: limit);

  /// Riwayat bulanan untuk grafik KPI di dashboard.
  static Future<List<KpiPoint>> getKpiHistory(KpiMetric metric) =>
      Repos.dashboard.getKpiHistory(metric);
}
