# Catatin 📊

[![CI](https://github.com/piambak/catatin/actions/workflows/ci.yml/badge.svg)](https://github.com/piambak/catatin/actions/workflows/ci.yml)
[![Publikasi web](https://github.com/piambak/catatin/actions/workflows/publish-web.yml/badge.svg)](https://github.com/piambak/catatin/actions/workflows/publish-web.yml)
[![Flutter](https://img.shields.io/badge/Flutter-3.38.4%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)

Catat transaksi, hitung pajak, dan pahami aturan perpajakan UMKM — dalam satu
aplikasi. Dibangun dengan Flutter, tayang sebagai PWA.

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
| **Pustaka peraturan** | UU, PP, PMK, PER DJP, SE, dan panduan — dengan pencarian dan bookmark |
| **Profil usaha** | NPWP, status PKP, jenis usaha, jumlah karyawan |
| **Mode gelap** | Seluruh aplikasi, berganti seketika |

## Isi repo

Repo ini menyimpan dua hal sekaligus: kode sumber, dan hasil build yang tayang.

```
catatin/
├── app/        Kode sumber Flutter — di sinilah kamu bekerja
├── docs/       Dokumentasi arsitektur, backend, deploy, aset
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

Sumber data dipilih saat build lewat `--dart-define`, tanpa mengubah kode:

```bash
# Data contoh — default, tanpa backend
flutter run -d chrome

# Backend sedang dibangun: pakai API kalau endpoint-nya ada,
# jatuh ke data contoh kalau belum
flutter run -d chrome \
  --dart-define=API_BASE_URL=http://localhost:8080/api/v1 \
  --dart-define=DATA_SOURCE=hybrid

# Produksi: semua dari backend, error naik ke UI
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://api.catatin.id/api/v1 \
  --dart-define=DATA_SOURCE=api
```

Seluruh kode HTTP terkumpul di satu berkas,
[`app/lib/core/data/api_repositories.dart`](app/lib/core/data/api_repositories.dart).
Tidak ada layar yang memanggil jaringan langsung, jadi menambah backend berarti
mengisi satu berkas — bukan menyunting puluhan file antarmuka.

Kontrak tiap endpoint, lengkap dengan contoh JSON dan bentuk error, ada di
**[docs/BACKEND.md](docs/BACKEND.md)**.

## Rilis

Push ke `main` yang menyentuh `app/` → workflow **Publikasi web** membangun
ulang dan memperbarui root repo → GitHub Pages tayang dalam 1–2 menit.

Perlu rilis manual? `tool/build_web.ps1` (Windows) atau `tool/build_web.sh`.
Rinciannya, termasuk cara rollback, ada di [docs/DEPLOY.md](docs/DEPLOY.md).

## Dokumentasi

| Dokumen | Isi |
| --- | --- |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Menyiapkan proyek, alur branch dan PR, gaya kode |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Struktur folder, lapisan aplikasi, aturan yang dijaga |
| [docs/BACKEND.md](docs/BACKEND.md) | Kontrak API lengkap dan cara memasang backend |
| [docs/DEPLOY.md](docs/DEPLOY.md) | Alur rilis, build manual, rollback |
| [docs/ASSETS.md](docs/ASSETS.md) | Font, ikon, dan pertimbangan ukuran bundel |

## Teknologi

Flutter · `go_router` · `dio` · `fl_chart` · `shared_preferences` ·
`flutter_secure_storage`

## Kontribusi

Isu dan pull request terbuka untuk siapa saja. Baca
[CONTRIBUTING.md](CONTRIBUTING.md) dulu — isinya singkat, dan menjelaskan satu
hal yang sering bikin bingung: berkas mana yang boleh disunting dan mana yang
digenerate.

Repo ini belum punya berkas lisensi, jadi hak ciptanya sepenuhnya di pemilik
repo. Kalau kamu berencana memakai kodenya di luar kontribusi ke proyek ini,
tanyakan dulu lewat isu.
