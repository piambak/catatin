# Arsitektur

## Bentuk repo

Repo ini menyimpan **dua hal sekaligus**: kode sumber Flutter dan hasil build
web yang tayang.

```text
catatin/
├── app/            ← kode sumber Flutter (yang kamu sunting)
├── wiki/           ← basis pengetahuan (OpenKnowledge)
├── supabase/       ← migrasi database Supabase (skema, RLS)
├── tool/           ← skrip build & sinkron
├── .github/        ← CI dan template kolaborasi
│
├── index.html      ┐
├── main.dart.js    │
├── flutter*.js     ├─ hasil `flutter build web`, digenerate otomatis.
├── assets/         │  JANGAN disunting manual.
├── canvaskit/      │
└── icons/          ┘
```

Kenapa output ada di root: GitHub Pages repo ini bersumber dari branch `main`
folder `/ (root)`, dan setting itu hanya bisa diubah pemilik repo. Selama belum
diubah, root `main` adalah satu-satunya yang tayang. Alur lengkapnya di
[Rilis & Deploy](../panduan/rilis-dan-deploy.md).

## Lapisan aplikasi

```text
┌──────────────────────────────────────────────────┐
│ screens/            layar penuh, punya state      │
│ widgets/            komponen yang dipakai ulang   │
└───────────────┬──────────────────────────────────┘
                │ hanya lewat fasad statis
┌───────────────▼──────────────────────────────────┐
│ core/services/      AuthService, DashboardService…│
│                     urusan lintas-lapisan:        │
│                     simpan token, cache, onboard  │
└───────────────┬──────────────────────────────────┘
                │ Repos.auth, Repos.dashboard, …
┌───────────────▼──────────────────────────────────┐
│ core/data/          kontrak + 4 implementasi      │
│   repositories.dart      abstrak + pemilih        │
│   api_repositories.dart  HTTP (Dio)               │
│   mock_repositories.dart data lokal               │
│   hybrid_repositories.dart  API → fallback mock   │
│   supabase_repositories.dart  Supabase            │
│   mock_data.dart         seluruh data contoh      │
└───────────────┬──────────────────────────────────┘
                │
┌───────────────▼──────────────────────────────────┐
│ core/network/       Dio, interceptor auth, error  │
│                     klien Supabase + galat        │
│ core/config/        AppConfig (--dart-define)     │
└──────────────────────────────────────────────────┘
```

Aturan yang dijaga:

1. **Layar tidak pernah menyentuh Dio.** Kalau butuh data baru, tambahkan
   method di kontrak `core/data/repositories.dart`.
2. **Model tidak tahu asal datanya.** `models/` hanya berisi struktur data dan
   `fromJson` — tidak ada data contoh, tidak ada HTTP.
3. **Data contoh terkumpul di satu file.** `core/data/mock_data.dart` tetap
   dibutuhkan walau backend sudah tayang: mode demo selalu memakainya.
4. **Konfigurasi lewat `--dart-define`,** bukan konstanta di kode Dart. Nilai
   publik untuk situs tayang ada di `app/dart_define.pages.json`.

## Isi `app/lib/`

| Folder | Isi |
| --- | --- |
| `main.dart` | Bootstrap: orientasi, locale `id_ID`, tema, router |
| `core/config/` | `AppConfig` — URL backend, mode data, timeout |
| `core/constants/` | Tarif pajak, PTKP, tabel TER, nama route, path endpoint |
| `core/data/` | Kontrak repository dan implementasinya: mock, api, hybrid, supabase |
| `core/network/` | `ApiClient` (Dio + refresh token), `SupabaseBackend` (klien Supabase + penerjemah galat), `app_router` (go_router) |
| `core/services/` | Fasad yang dipanggil layar; `storage_service`, `theme_notifier`, `simulator_service` |
| `core/theme/` | `design_tokens.dart` — `DS`, `Typo`, `Space`, `Radii`: **sistem token yang berlaku**, dipakai semua kode baru · `breakpoints.dart` — `Bp`, satu-satunya tempat angka breakpoint boleh ditulis · `app_theme.dart` — `AppTheme` terang & gelap, plus `AppColors`/`AppTextStyles` yang **akan dihapus** setelah migrasi tema (issue #53); jangan tambah pemakaian baru |
| `core/utils/` | Format rupiah dan tanggal |
| `models/` | Struktur data murni + `fromJson`/`toJson` |
| `screens/` | Satu folder per fitur: auth, dashboard, accounting, simulator, settings, splash |
| `widgets/` | Komponen per fitur + `widgets/common/` |

## Fitur

| Fitur | Layar | Butuh backend? |
| --- | --- | --- |
| Masuk & daftar | `screens/auth/` | Ya |
| Dashboard | `screens/dashboard/` | Ya |
| Pembukuan transaksi | `screens/accounting/` | Ya |
| Simulator pajak | `screens/simulator/` | **Tidak** — murni hitungan lokal |
| Profil usaha & pengaturan | `screens/settings/` | Ya (dengan cadangan lokal) |

## Tema

`AppColors` memakai *getter*, bukan konstanta, sehingga seluruh aplikasi ikut
berubah begitu `themeNotifier` diganti — tanpa membangun ulang widget tree
secara manual. Konsekuensinya: jangan menandai widget yang memakai `AppColors`
sebagai `const`, karena nilainya bergantung mode terang/gelap saat runtime.

## Aset

Font di-*bundle*, bukan diunduh saat runtime, supaya aplikasi tetap konsisten
saat offline dan tidak menarik permintaan ke domain pihak ketiga. Hanya berat
font yang benar-benar dipakai yang ikut dibundel — detailnya di
[Aset](aset.md).
