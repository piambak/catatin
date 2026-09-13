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
| `api` | Semua dari backend REST. Kegagalan dilempar sebagai `ApiException` supaya benar-benar kelihatan di UI, bukan disembunyikan. |
| `supabase` | Akun lewat Supabase Auth, data dari Postgres Supabase. Kegagalan dilempar sebagai `ApiException`, sama seperti `api`. |

```bash
# Data contoh — default, tanpa backend
flutter run -d chrome

# Supabase proyek ini — konfigurasi yang sama dengan situs publik.
# Database-nya dipakai pengguna sungguhan: jangan dipakai untuk data coba-coba.
flutter run -d chrome --dart-define-from-file=dart_define.pages.json

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

Tanpa `SUPABASE_URL` maupun `API_BASE_URL`, aplikasi jalan mode `mock`. Artinya
`flutter run` polos selalu berhasil untuk kontributor baru — tidak ada langkah
konfigurasi tersembunyi. `SUPABASE_URL` yang terisi otomatis memilih mode
`supabase`.

Kalau kombinasinya tidak masuk akal (`DATA_SOURCE=api` tapi `API_BASE_URL`
kosong, atau `DATA_SOURCE=supabase` tanpa publishable key), aplikasi **tidak**
dilempar error: ia jalan mode mock dan mencetak peringatan sekali di konsol saat
mode debug. Karena itu `dart_define.pages.json` yang belum diisi pun aman.

Tombol "Masuk sebagai pengguna demo" selalu memakai data contoh, apa pun
modenya.

Di mode Supabase, layar masuk dan daftar menampilkan tombol **Masuk dengan
Google**. Dari `localhost` tombol itu kembali ke alamat lokal yang sedang
dibuka — berfungsi selama `http://localhost:*/**` terdaftar di Redirect URLs
proyek ([Supabase](../arsitektur/supabase.md#masuk-dengan-google)). Form daftar
dengan email sengaja disembunyikan di mode ini; tampilkan untuk uji lokal
dengan `--dart-define=EMAIL_SIGNUP=true`.

### Pakai berkas, bukan flag panjang

```bash
cp dart_define.example.json dart_define.json   # dart_define.json di-gitignore
flutter run --dart-define-from-file=dart_define.json
```

Selain `API_BASE_URL`, `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY`, dan
`DATA_SOURCE`, berkas itu mengenal `ENABLE_API_LOG` (cetak request/response ke
konsol — **jangan** diaktifkan di rilis publik), `API_CONNECT_TIMEOUT_MS`, dan
`API_RECEIVE_TIMEOUT_MS` (keduanya default 15000).

Dua berkas define, dua fungsi:

| Berkas | Di-commit? | Untuk |
| --- | --- | --- |
| `app/dart_define.pages.json` | Ya | Konfigurasi situs publik — Supabase proyek ini. Nilainya publik |
| `app/dart_define.json` | Tidak (di-gitignore) | Konfigurasi pribadi, mis. backend REST lokal atau proyek Supabase sendiri |

Menyiapkan proyek Supabase dari nol dijelaskan di
[Supabase](../arsitektur/supabase.md).

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
