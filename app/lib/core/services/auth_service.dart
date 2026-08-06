// lib/core/services/auth_service.dart
//
// Fasad tipis di atas `Repos.auth`. Layar memanggil kelas ini, bukan
// repository, supaya urusan lintas-lapisan (menyimpan token, membersihkan
// sesi) tetap di satu tempat.

import '../../models/models.dart';
import '../data/repositories.dart';
import 'storage_service.dart';

export '../../models/user_model.dart';

class AuthService {
  AuthService._();

  static Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final auth = await Repos.auth.register(
      name: name,
      email: email,
      password: password,
    );
    await _persist(auth);
    return auth;
  }

  static Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final auth = await Repos.auth.login(email: email, password: password);
    await _persist(auth);
    return auth;
  }

  static Future<UserModel> me() => Repos.auth.me();

  static Future<void> logout() => StorageService.clearAll();

  static Future<void> _persist(AuthResponse auth) => Future.wait([
        StorageService.saveTokens(
          accessToken: auth.accessToken,
          refreshToken: auth.refreshToken,
        ),
        StorageService.saveUserInfo(
          id: auth.user.id,
          name: auth.user.name,
          email: auth.user.email,
        ),
      ]);
}
