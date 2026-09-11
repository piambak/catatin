# Mulai Cepat

Menjalankan Catatin di mesin sendiri, dan memilih dari mana datanya diambil.

## Prasyarat

Flutter **3.38.4** atau lebih baru (`sdk: >=3.11.0 <4.0.0`). CI memakai
**3.44.8** — kalau ingin persis sama dengan yang memverifikasi repo, pakai itu.

Batas 3.38.4 bukan angka sembarangan: `fl_chart` 1.2.x butuh `vector_math`
^2.2.0 yang baru tersedia sejak Flutter 3.38, jadi SDK lebih tua gagal saat
`pub get`.

## Jalankan

```bash
git clone https://github.com/piambak/catatin.git
cd catatin/app
flutter pub get
flutter run -d chrome
```

Selesai. Tanpa konfigurasi apa pun aplikasi memakai **data contoh** — tidak
butuh backend, tidak butuh akun, dan tidak ada satu pun request jaringan.

## Memilih sumber data

Sumber data dipilih **saat build** lewat `--dart-define`, tanpa mengubah kode.
Seluruh konfigurasi lingkungan tinggal di
`app/lib/core/config/app_config.dart`.

| Mode | Perilaku |
| --- | --- |
| `mock` | Semua dari seed lokal. Nol request jaringan. Dipakai demo publik, screenshot, dan tes widget. |
| `hybrid` | Coba backend dulu, jatuh ke seed lokal kalau endpoint belum ada atau jaringan mati. Mode transisi selagi backend dibangun bertahap. |
| `api` | Semua dari backend. Kegagalan dilempar sebagai `ApiException` supaya benar-benar kelihatan di UI, bukan disembunyikan. |

```bash
# Data contoh — default, tanpa backend
flutter run -d chrome

# Backend sedang dibangun
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8080/api/v1 \
  --dart-define=DATA_SOURCE=hybrid

# Produksi
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://api.catatin.id/api/v1 \
  --dart-define=DATA_SOURCE=api
```

### Default yang sengaja dibuat "pintar"

Tanpa `API_BASE_URL`, `DATA_SOURCE` apa pun akan jatuh ke `mock`. Artinya
`flutter run` polos selalu berhasil untuk kontributor baru — tidak ada langkah
konfigurasi tersembunyi.

Kalau kombinasinya tidak masuk akal (`DATA_SOURCE=api` tapi `API_BASE_URL`
kosong), aplikasi **tidak** dilempar error: ia mencetak peringatan sekali saat
startup lalu jalan mode mock. Pesannya juga muncul di layar Pengaturan.

### Pakai berkas, bukan flag panjang

```bash
cp dart_define.example.json dart_define.json   # dart_define.json di-gitignore
flutter run --dart-define-from-file=dart_define.json
```

Selain `API_BASE_URL` dan `DATA_SOURCE`, berkas itu mengenal
`ENABLE_API_LOG` (cetak request/response ke konsol — **jangan** diaktifkan di
rilis publik), `API_CONNECT_TIMEOUT_MS`, dan `API_RECEIVE_TIMEOUT_MS`
(keduanya default 15000).

## Sebelum membuka PR

```bash
cd app
flutter analyze
flutter test
```

CI menjalankan keduanya plus `flutter build web --release`. `flutter analyze`
dijalankan dengan `--no-fatal-infos`, jadi temuan level *info* tidak menahan
PR — tapi *warning* dan *error* tetap menggagalkan build.

## Ke mana selanjutnya

- [Kontribusi](kontribusi.md) — berkas mana yang boleh disunting, alur branch dan PR.
- [Arsitektur](../arsitektur/gambaran-umum.md) — bentuk repo dan lapisan aplikasi.
- [Backend & API](../arsitektur/backend-dan-api.md) — kontrak tiap endpoint.
- [Aturan pajak](../domain/aturan-pajak.md) — dari mana angka-angka pajaknya datang.
