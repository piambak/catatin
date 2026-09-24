// test/storage_cache_test.dart
//
// T-27 — penjaga rute membaca status masuk & onboarding di setiap navigasi.
// StorageService kini menyimpan salinannya di memori, diperbarui bersamaan
// dengan setiap penulisan (write-through). Tes ini mengunci satu hal yang
// membuat cache seperti itu berbahaya kalau salah: nilainya tidak boleh
// tertinggal dari penulisan terakhir — onboarding yang basi pernah membuat
// pengguna terjebak di loop onboarding (T-18).
//
// Jalankan: flutter test test/storage_cache_test.dart

import 'package:catatin/core/constants/app_constants.dart';
import 'package:catatin/core/services/storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    StorageService.resetCache();
  });

  test('status masuk mengikuti saveTokens dan clearTokens', () async {
    expect(await StorageService.isLoggedIn(), isFalse);

    await StorageService.saveTokens(accessToken: 'a', refreshToken: 'r');
    expect(await StorageService.isLoggedIn(), isTrue);

    await StorageService.clearTokens();
    expect(await StorageService.isLoggedIn(), isFalse);
  });

  test('onboarding mengikuti setOnboarded, clearBusiness, clearSession',
      () async {
    expect(await StorageService.isOnboarded(), isFalse);

    await StorageService.setOnboarded();
    expect(await StorageService.isOnboarded(), isTrue);

    await StorageService.clearBusiness();
    expect(await StorageService.isOnboarded(), isFalse);

    await StorageService.setOnboarded();
    await StorageService.clearSession();
    expect(await StorageService.isOnboarded(), isFalse);
  });

  test('bacaan pertama tetap dari penyimpanan', () async {
    SharedPreferences.setMockInitialValues({StorageKeys.onboarded: true});
    FlutterSecureStorage.setMockInitialValues(
        {StorageKeys.accessToken: 'tersimpan'});
    StorageService.resetCache();

    expect(await StorageService.isOnboarded(), isTrue);
    expect(await StorageService.isLoggedIn(), isTrue);
  });

  test('penulisan selama pembacaan pertama tidak tertimpa hasil baca lama',
      () async {
    // Baca pertama dimulai sebelum masuk berhasil. Apa pun urutan selesainya,
    // hasil bacanya ("belum masuk") lebih tua dari penulisan token dan tidak
    // boleh menang.
    final reading = StorageService.isLoggedIn();
    await StorageService.saveTokens(accessToken: 'a', refreshToken: 'r');
    await reading;

    expect(await StorageService.isLoggedIn(), isTrue);
  });
}
