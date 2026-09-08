// test/simulator_service_test.dart
//
// Tes untuk mesin pajak — menutup temuan T-2 di docs/PROJECT_TIMELINE.md.
//
// `simulator_service.dart` adalah satu-satunya kode di repo yang kesalahannya
// langsung berujung ke angka pajak salah di layar pengguna, dan sampai berkas
// ini dibuat ia nol tes. Milestone M4 mensyaratkan hasilnya cocok dengan
// kalkulator resmi DJP; tanpa tes, verifikasi itu manual dan tidak berulang.
//
// Yang diuji di sini adalah **konsistensi internal dan sifat struktural** —
// bukan kebenaran tarif terhadap peraturan. Kebenaran tarif adalah wewenang
// pakar pajak (T-1, T-3, T-4) dan sengaja tidak dikunci di tes ini, supaya tes
// tidak mengabadikan angka yang mungkin memang salah.
//
// Jalankan: flutter test test/simulator_service_test.dart

import 'package:catatin/core/constants/app_constants.dart';
import 'package:catatin/core/services/simulator_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ── PPh Final (PP 23/2018) ────────────────────────────────────────────────

  group('calculatePPhFinal', () {
    test('omzet nol menghasilkan pajak nol dan tetap eligible', () {
      final r = calculatePPhFinal(0);
      expect(r.pajakBulanan, 0);
      expect(r.pajakTahunanEst, 0);
      expect(r.pkpThresholdPercent, 0);
      expect(r.eligible, isTrue);
    });

    test('pajak bulanan = omzet x tarif final', () {
      const omzet = 24500000.0;
      final r = calculatePPhFinal(omzet);
      expect(r.pajakBulanan, omzet * AppConstants.pphFinalRate);
      expect(r.rate, AppConstants.pphFinalRate);
    });

    test('estimasi tahunan = dua belas kali estimasi bulanan', () {
      final r = calculatePPhFinal(24500000);
      expect(r.omzetTahunanEst, closeTo(r.omzetBulanan * 12, 0.001));
      expect(r.pajakTahunanEst, closeTo(r.pajakBulanan * 12, 0.001));
    });

    test('tepat di ambang PKP masih eligible', () {
      // Ambang berlaku per tahun, sedangkan input fungsinya per bulan.
      final r = calculatePPhFinal(AppConstants.pkpThreshold / 12);
      expect(r.omzetTahunanEst, closeTo(AppConstants.pkpThreshold, 0.001));
      expect(r.eligible, isTrue,
          reason: 'batas ambang bersifat inklusif (<=), bukan eksklusif');
      expect(r.pkpThresholdPercent, closeTo(100, 0.001));
    });

    test('di atas ambang PKP tidak lagi eligible', () {
      final r = calculatePPhFinal((AppConstants.pkpThreshold / 12) + 1);
      expect(r.eligible, isFalse);
    });

    test('persentase ambang dibatasi 100 walau omzet jauh di atasnya', () {
      final r = calculatePPhFinal(AppConstants.pkpThreshold); // 12x ambang
      expect(r.pkpThresholdPercent, 100);
      expect(r.isPkpDanger, isTrue);
    });

    group('penanda ambang', () {
      // 80% dan 95% dari ambang tahunan, dibagi 12 supaya jadi input bulanan.
      double monthlyForPercent(double pct) =>
          (AppConstants.pkpThreshold * pct) / 12;

      test('di bawah 80% tidak memicu peringatan apa pun', () {
        final r = calculatePPhFinal(monthlyForPercent(0.79));
        expect(r.isPkpWarning, isFalse);
        expect(r.isPkpDanger, isFalse);
      });

      test('tepat 80% memicu peringatan, belum bahaya', () {
        final r = calculatePPhFinal(monthlyForPercent(0.80));
        expect(r.isPkpWarning, isTrue);
        expect(r.isPkpDanger, isFalse);
      });

      test('tepat 95% memicu bahaya', () {
        final r = calculatePPhFinal(monthlyForPercent(0.95));
        expect(r.isPkpWarning, isTrue);
        expect(r.isPkpDanger, isTrue);
      });
    });
  });

  // ── PPh 21 metode TER (PMK 168/2023) ──────────────────────────────────────

  group('calculatePPh21', () {
    test('setiap status PTKP punya nilai dan tidak melempar', () {
      for (final status in PtkpStatus.values) {
        expect(() => calculatePPh21(10000000, status), returnsNormally,
            reason: 'status $status gagal dipetakan ke nilai PTKP');
        final r = calculatePPh21(10000000, status);
        expect(r.ptkp, greaterThan(0));
      }
    });

    // Penjaga T-5. `ptkpAmount` memakai `!` pada pencarian Map; ini yang
    // membuat null-assertion itu aman. Kalau pakar pajak mengubah kunci di
    // AppConstants.ptkp, tes ini gagal sebelum pengguna kena crash.
    test('setiap status punya kunci yang benar-benar ada di AppConstants', () {
      for (final status in PtkpStatus.values) {
        expect(AppConstants.ptkp.containsKey(status.ptkpKey), isTrue,
            reason: 'kunci "${status.ptkpKey}" tidak ada di AppConstants.ptkp');
      }
    });

    test('kunci PTKP unik per status', () {
      final keys = PtkpStatus.values.map((s) => s.ptkpKey).toList();
      expect(keys.toSet(), hasLength(keys.length));
    });

    test('nilai PTKP naik seiring bertambahnya tanggungan', () {
      double ptkpOf(PtkpStatus s) => calculatePPh21(10000000, s).ptkp;

      expect(ptkpOf(PtkpStatus.tk0), lessThan(ptkpOf(PtkpStatus.tk1)));
      expect(ptkpOf(PtkpStatus.tk1), lessThan(ptkpOf(PtkpStatus.tk2)));
      expect(ptkpOf(PtkpStatus.tk2), lessThan(ptkpOf(PtkpStatus.tk3)));
      expect(ptkpOf(PtkpStatus.k0), lessThan(ptkpOf(PtkpStatus.k1)));
      expect(ptkpOf(PtkpStatus.k1), lessThan(ptkpOf(PtkpStatus.k2)));
      expect(ptkpOf(PtkpStatus.k2), lessThan(ptkpOf(PtkpStatus.k3)));
    });

    test('gaji nol menghasilkan pajak nol', () {
      final r = calculatePPh21(0, PtkpStatus.tk0);
      expect(r.pajakBulanan, 0);
      expect(r.pajakTahunanEst, 0);
      expect(r.netGaji, 0);
    });

    test('gaji di lapisan TER terendah tidak dipotong', () {
      // Lapisan pertama terTableA bertarif 0%.
      final r = calculatePPh21(5000000, PtkpStatus.tk0);
      expect(r.terRate, 0);
      expect(r.pajakBulanan, 0);
    });

    test('pajak = gaji kotor x tarif TER, dan gaji bersih adalah sisanya', () {
      final r = calculatePPh21(12000000, PtkpStatus.tk0);
      expect(r.pajakBulanan, closeTo(12000000 * r.terRate, 0.001));
      expect(r.netGaji, closeTo(12000000 - r.pajakBulanan, 0.001));
      expect(r.pajakTahunanEst, closeTo(r.pajakBulanan * 12, 0.001));
    });

    test('tarif TER tidak pernah turun saat gaji naik', () {
      var previous = -1.0;
      for (var gaji = 1000000.0; gaji <= 80000000; gaji += 1000000) {
        final rate = calculatePPh21(gaji, PtkpStatus.tk0).terRate;
        expect(rate, greaterThanOrEqualTo(previous),
            reason: 'tarif turun di gaji $gaji');
        previous = rate;
      }
    });

    test('tepat di batas lapisan memakai tarif lapisan itu, bukan berikutnya',
        () {
      for (final row in AppConstants.terTableA) {
        final max = (row['max'] as num).toDouble();
        if (max.isInfinite) continue;
        final expected = (row['rate'] as num).toDouble();
        final actual = calculatePPh21(max, PtkpStatus.tk0).terRate;
        expect(actual, expected,
            reason: 'gaji tepat $max seharusnya memakai tarif lapisan itu');
      }
    });

    test('gaji sangat besar memakai lapisan tertinggi', () {
      final highest =
          (AppConstants.terTableA.last['rate'] as num).toDouble();
      expect(calculatePPh21(999000000, PtkpStatus.tk0).terRate, highest);
    });

    // ── Penanda T-1 ─────────────────────────────────────────────────────────
    //
    // Tes ini SENGAJA di-skip. Ia mendokumentasikan perilaku yang seharusnya
    // berlaku setelah T-1 selesai: kategori TER ditentukan status PTKP
    // (A: TK/0, TK/1, K/0 · B: TK/2, TK/3, K/1, K/2 · C: K/3), sehingga dua
    // status di kategori berbeda tidak boleh menghasilkan tarif identik.
    //
    // Saat ini `calculatePPh21` selalu membaca `terTableA`, jadi tes ini pasti
    // gagal. Hapus `skip` begitu tabel B dan C dari pakar pajak masuk — itu
    // sekaligus jadi verifikasi bahwa perbaikannya benar-benar bekerja.
    test('status di kategori TER berbeda menghasilkan tarif berbeda', () {
      final a = calculatePPh21(12000000, PtkpStatus.tk0); // kategori A
      final c = calculatePPh21(12000000, PtkpStatus.k3); // kategori C
      expect(a.terRate, isNot(equals(c.terRate)));
    }, skip: 'Menunggu T-1: terTableB & terTableC belum ada di app_constants');
  });

  // ── Tabel TER untuk tampilan ──────────────────────────────────────────────

  group('buildTerTable', () {
    test('selalu mengembalikan daftar tidak kosong', () {
      expect(buildTerTable(0), isNotEmpty);
      expect(buildTerTable(12000000), isNotEmpty);
    });

    test('gaji nol tidak menyorot baris mana pun', () {
      expect(buildTerTable(0).where((r) => r.isActive), isEmpty);
    });

    test('gaji positif menyorot tepat satu baris', () {
      for (final gaji in [3000000.0, 8000000.0, 12000000.0, 45000000.0]) {
        final active = buildTerTable(gaji).where((r) => r.isActive);
        expect(active.length, 1, reason: 'gaji $gaji menyorot ${active.length} baris');
      }
    });

    // Temuan T-13. Baris yang disorot di tabel tampilan harus menyebut tarif
    // yang sama dengan yang dipakai menghitung — kalau tidak, pengguna melihat
    // dua angka berbeda untuk hal yang sama di satu layar.
    test('tarif baris tersorot sama dengan tarif hasil hitung', () {
      for (final gaji in [
        3000000.0,
        8000000.0,
        9000000.0,
        12000000.0,
        20000000.0,
        40000000.0,
      ]) {
        final shown =
            buildTerTable(gaji).firstWhere((r) => r.isActive).rate;
        final used = calculatePPh21(gaji, PtkpStatus.tk0).terRate;
        expect(shown, used,
            reason: 'gaji $gaji: tabel menampilkan $shown, hitungan memakai $used');
      }
    });
  });

  // ── Perencana skenario ────────────────────────────────────────────────────

  group('calculateScenarios', () {
    const base = ScenarioInput(
      omzetBulanan: 24500000,
      employeeCount: 3,
      avgGaji: 8000000,
      ptkpStatus: PtkpStatus.tk0,
      isPkp: false,
    );

    test('mengembalikan tiga skenario dengan satu unggulan', () {
      final results = calculateScenarios(base);
      expect(results, hasLength(3));
      expect(results.where((r) => r.isFeatured), hasLength(1));
      expect(results.map((r) => r.label),
          containsAll(['Konservatif', 'Base Case', 'Optimistis']));
    });

    test('omzet naik dari konservatif ke optimistis', () {
      final r = calculateScenarios(base);
      expect(r[0].omzetBulanan, lessThan(r[1].omzetBulanan));
      expect(r[1].omzetBulanan, lessThan(r[2].omzetBulanan));
    });

    test('skenario base memakai omzet apa adanya', () {
      final baseCase =
          calculateScenarios(base).firstWhere((r) => r.label == 'Base Case');
      expect(baseCase.omzetBulanan, closeTo(base.omzetBulanan, 0.001));
      expect(baseCase.omzetTahunan, closeTo(base.omzetBulanan * 12, 0.001));
    });

    test('non-PKP tidak dikenai PPN', () {
      for (final r in calculateScenarios(base)) {
        expect(r.ppn, 0);
      }
    });

    test('PKP dikenai PPN sebesar tarif yang berlaku', () {
      const pkpBase = ScenarioInput(
        omzetBulanan: 24500000,
        employeeCount: 3,
        avgGaji: 8000000,
        ptkpStatus: PtkpStatus.tk0,
        isPkp: true,
      );
      for (final r in calculateScenarios(pkpBase)) {
        expect(r.ppn, closeTo(r.omzetTahunan * AppConstants.ppnRate, 0.001));
      }
    });

    test('total pajak adalah jumlah komponennya', () {
      for (final r in calculateScenarios(base)) {
        expect(r.totalPajak,
            closeTo(r.pphFinal + r.pph21Total + r.ppn, 0.001));
      }
    });

    test('tarif efektif = total pajak dibagi omzet tahunan', () {
      for (final r in calculateScenarios(base)) {
        expect(r.effectiveRate,
            closeTo(r.totalPajak / r.omzetTahunan, 0.000001));
      }
    });

    test('omzet nol tidak menyebabkan pembagian nol', () {
      const zero = ScenarioInput(
        omzetBulanan: 0,
        employeeCount: 0,
        avgGaji: 0,
        ptkpStatus: PtkpStatus.tk0,
        isPkp: false,
      );
      for (final r in calculateScenarios(zero)) {
        expect(r.effectiveRate, 0);
        expect(r.effectiveRate.isNaN, isFalse);
      }
    });

    test('PPh 21 dihitung per karyawan lalu dikalikan jumlahnya', () {
      final perEmployee =
          calculatePPh21(base.avgGaji, base.ptkpStatus).pajakTahunanEst;
      for (final r in calculateScenarios(base)) {
        expect(r.pph21Total,
            closeTo(perEmployee * base.employeeCount, 0.001));
      }
    });

    test('omzet di atas ambang membuat PPh Final nol, bukan tetap dihitung',
        () {
      // Harus cukup besar supaya skenario Konservatif (0,7x) pun masih di atas
      // ambang: 0,7 x 600 jt x 12 = 5,04 M > 4,8 M.
      const huge = ScenarioInput(
        omzetBulanan: 600000000,
        employeeCount: 0,
        avgGaji: 0,
        ptkpStatus: PtkpStatus.tk0,
        isPkp: false,
      );
      for (final r in calculateScenarios(huge)) {
        expect(r.pphFinal, 0,
            reason: 'skema final tidak berlaku di atas ambang PKP');
      }
    });

    test('skenario yang turun ke bawah ambang tetap dapat skema final', () {
      // Base di atas ambang, tapi Konservatif (0,7x) jatuh ke bawahnya —
      // eligibility dinilai per skenario, bukan sekali untuk semuanya.
      const straddling = ScenarioInput(
        omzetBulanan: 500000000, // 6 M/tahun; 0,7x → 4,2 M/tahun
        employeeCount: 0,
        avgGaji: 0,
        ptkpStatus: PtkpStatus.tk0,
        isPkp: false,
      );
      final results = calculateScenarios(straddling);
      final konservatif =
          results.firstWhere((r) => r.label == 'Konservatif');
      final optimistis = results.firstWhere((r) => r.label == 'Optimistis');

      expect(konservatif.pphFinal, greaterThan(0));
      expect(optimistis.pphFinal, 0);
    });
  });
}
