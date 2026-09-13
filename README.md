# Catatin 📊

[![CI](https://github.com/piambak/catatin/actions/workflows/ci.yml/badge.svg)](https://github.com/piambak/catatin/actions/workflows/ci.yml)
[![Publikasi web](https://github.com/piambak/catatin/actions/workflows/publish-web.yml/badge.svg)](https://github.com/piambak/catatin/actions/workflows/publish-web.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.38.4%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)

Catat transaksi dan hitung pajak UMKM dalam satu aplikasi. Dibangun dengan
Flutter, tayang sebagai PWA.

**Coba sekarang → [piambak.github.io/catatin](https://piambak.github.io/catatin/)**

---

## Mulai cepat

Butuh Flutter **3.38.4** atau lebih baru (CI memakai 3.44.8).

```bash
git clone https://github.com/piambak/catatin.git
cd catatin/app
flutter pub get
flutter run -d chrome
```

Sudah jalan. Tanpa konfigurasi apa pun aplikasi memakai **data contoh** — tidak
butuh backend, tidak butuh akun, tidak ada satu pun request jaringan.

## Fitur

| Fitur | Isi |
| --- | --- |
| **Dashboard** | Ringkasan pemasukan, pengeluaran, dan laba; tren bulanan; progres ambang PKP Rp 4,8 M; tenggat pajak terdekat |
| **Pembukuan** | Catat transaksi per kategori, lengkap dengan penanda relevansi pajak dan HPP |
| **Simulator pajak** | PPh Final 0,5% (PP 23/2018), PPh 21 metode TER (PMK 168/2023), perbandingan skenario, kalender pajak |
| **Profil usaha** | NPWP, status PKP, jenis usaha, jumlah karyawan |
| **Mode gelap** | Seluruh aplikasi, berganti seketika |

## Isi repo

Repo ini menyimpan dua hal sekaligus: kode sumber, dan hasil build yang tayang.

```
catatin/
├── app/        Kode sumber Flutter — di sinilah kamu bekerja
├── wiki/       Seluruh pengetahuan proyek — basis pengetahuan OpenKnowledge
├── supabase/   Migrasi database Supabase (skema, Row Level Security)
├── tool/       Skrip build dan sinkron ke root
├── .github/    CI dan template kolaborasi
│
└── index.html, main.dart.js, assets/, canvaskit/, icons/, …
             Hasil `flutter build web`. Digenerate otomatis — jangan disunting.
```

Hasil build ada di root karena GitHub Pages repo ini bersumber dari branch
`main` folder `/ (root)`. Kamu tidak perlu menyentuhnya sama sekali: setiap push
ke `main` yang mengubah `app/` memicu workflow yang membangun ulang dan
memperbarui root sendiri.

## Menyambungkan backend

Backend Catatin adalah **Supabase**. Sumber data dipilih saat build lewat
`--dart-define`, tanpa mengubah kode:

```bash
# Data contoh — default, tanpa backend
flutter run -d chrome

# Supabase proyek ini — konfigurasi yang sama dengan situs publik
flutter run -d chrome --dart-define-from-file=dart_define.pages.json

# Backend REST buatan sendiri: pakai API kalau endpoint-nya ada,
# jatuh ke data contoh kalau belum
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8080/api/v1 \
  --dart-define=DATA_SOURCE=hybrid
```

Tidak ada layar yang memanggil jaringan langsung. Kode Supabase terkumpul di
[`app/lib/core/data/supabase_repositories.dart`](app/lib/core/data/supabase_repositories.dart),
kode REST di [`app/lib/core/data/api_repositories.dart`](app/lib/core/data/api_repositories.dart)
— menambah backend berarti mengisi satu berkas, bukan menyunting puluhan file
antarmuka.

`app/dart_define.pages.json` berisi URL proyek Supabase dan *publishable key*,
dan **sengaja di-commit**: kunci itu memang publik, data dijaga Row Level
Security. Secret key dan password database tidak pernah boleh masuk repo.

- Menyiapkan proyek Supabase dari nol, skema, dan kunci:
  **[wiki/arsitektur/supabase.md](wiki/arsitektur/supabase.md)**
- Mode sumber data dan kontrak REST tiap endpoint:
  **[wiki/arsitektur/backend-dan-api.md](wiki/arsitektur/backend-dan-api.md)**

## Rilis

Push ke `main` yang menyentuh `app/` → workflow **Publikasi web** membangun
ulang dan memperbarui root repo → GitHub Pages tayang dalam 1–2 menit.

Perlu rilis manual? `tool/build_web.ps1` (Windows) atau `tool/build_web.sh`.
Rinciannya, termasuk cara rollback, ada di [wiki/panduan/rilis-dan-deploy.md](wiki/panduan/rilis-dan-deploy.md).

## Dokumentasi

Seluruh pengetahuan proyek tinggal di satu folder: **[wiki/](wiki/README.md)**,
dikelola sebagai basis pengetahuan [OpenKnowledge](https://openknowledge.ai).

| Halaman | Isi |
| --- | --- |
| [Beranda wiki](wiki/README.md) | Peta seluruh halaman |
| [Mulai cepat](wiki/panduan/mulai-cepat.md) | Menjalankan proyek, memilih sumber data |
| [Kontribusi](wiki/panduan/kontribusi.md) | Alur branch dan PR, gaya kode, berkas mana yang boleh disunting |
| [Arsitektur](wiki/arsitektur/gambaran-umum.md) | Struktur folder, lapisan aplikasi, aturan yang dijaga |
| [Supabase](wiki/arsitektur/supabase.md) | Menyiapkan backend, skema & RLS, kunci yang boleh di-commit |
| [Backend & API](wiki/arsitektur/backend-dan-api.md) | Mode sumber data dan kontrak API REST lengkap |
| [Rilis & deploy](wiki/panduan/rilis-dan-deploy.md) | Alur rilis, build manual, rollback |
| [Aturan pajak](wiki/domain/aturan-pajak.md) | PPh Final 0,5%, PPh 21 TER, ambang PKP — dasar hukum tiap angka |
| [Aset](wiki/arsitektur/aset.md) | Font, ikon, dan pertimbangan ukuran bundel |

## Teknologi

Flutter · Supabase (`supabase_flutter`) · `go_router` · `dio` · `fl_chart` ·
`shared_preferences` · `flutter_secure_storage`

## Kontribusi

Isu dan pull request terbuka untuk siapa saja. Baca
[panduan kontribusi](wiki/panduan/kontribusi.md) dulu — isinya singkat, dan menjelaskan satu
hal yang sering bikin bingung: berkas mana yang boleh disunting dan mana yang
digenerate.

Repo ini belum punya berkas lisensi, jadi hak ciptanya sepenuhnya di pemilik
repo. Kalau kamu berencana memakai kodenya di luar kontribusi ke proyek ini,
tanyakan dulu lewat isu.
