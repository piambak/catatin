// lib/core/services/simulator_input_service.dart
//
// Fasad nilai awal Simulator (#89). Sengaja terpisah dari
// simulator_service.dart, yang murni hitungan pajak tanpa jaringan.

import '../../models/models.dart';
import '../data/repositories.dart';

export '../../models/simulator_model.dart';

class SimulatorInputService {
  SimulatorInputService._();

  /// Rata-rata tiga bulan penuh sebelum bulan acuan, angka bulan acuan, omzet
  /// YTD, dan profil usaha. [month]/[year] default bulan berjalan.
  static Future<SimulatorInputs> getInputs({int? month, int? year}) =>
      Repos.simulator.getInputs(month: month, year: year);
}
