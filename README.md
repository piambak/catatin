# Catatin Web 📊

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Web](https://img.shields.io/badge/Platform-Web-blue?style=for-the-badge)](https://flutter.dev/multi-platform/web)
[![PWA](https://img.shields.io/badge/PWA-Supported-orange?style=for-the-badge)](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps)

**Catatin** adalah aplikasi pencatatan keuangan pribadi dan pembukuan bisnis yang dibangun dengan Flutter. Repositori ini **bukan** repositori kode sumber — isinya khusus berkas hasil kompilasi produksi (`flutter build web`) yang langsung disajikan sebagai situs statis.

| | |
| :--- | :--- |
| **Live** | <https://piambak.github.io/catatin/> |
| **Hosting** | GitHub Pages, sumber: branch `main` folder `/ (root)` |
| **Versi** | `1.0.0+1` (lihat `version.json`) |
| **Base href** | `/catatin/` |
| **Branch** | `main` (yang tayang) dan `backup(stable-version)` (cadangan) |

Karena Pages menyajikan langsung isi root `main`, **setiap push ke `main` otomatis memperbarui situs** tanpa proses build apa pun di CI.

---

## 📁 Struktur Repositori

```
catatin/
├── .claude/
│   └── launch.json                  Konfigurasi server pratinjau lokal (bukan bagian aplikasi)
├── assets/
│   ├── assets/fonts/                Fredoka (Regular, SemiBold) & Nunito (Regular, Medium, SemiBold, Bold)
│   ├── fonts/                       MaterialIcons-Regular.otf
│   ├── shaders/                     ink_sparkle.frag, stretch_effect.frag
│   ├── AssetManifest.bin            Manifes aset format biner (dibaca aplikasi saat runtime)
│   ├── AssetManifest.bin.json       Manifes aset versi JSON
│   ├── FontManifest.json            Pemetaan nama famili font ke berkas & ketebalannya
│   └── NOTICES                      Kumpulan lisensi seluruh pustaka yang dipakai
├── canvaskit/
│   ├── chromium/                    Varian CanvasKit khusus Chromium
│   ├── experimental_webparagraph/   Varian eksperimental tata letak teks
│   ├── canvaskit.js / .wasm         Mesin render CanvasKit (WebGL)
│   ├── skwasm.js / .wasm            Mesin render Skia-WASM, pilihan default
│   ├── skwasm_heavy.js / .wasm      Dipakai bila peramban tak punya image codec / break iterator bawaan
│   └── wimp.js / .wasm              Dipakai bila opsi `enableWimp` aktif
├── icons/
│   ├── Icon-192.png, Icon-512.png                  Ikon PWA standar
│   └── Icon-maskable-192.png, Icon-maskable-512.png Ikon PWA maskable
├── .last_build_id                   Penanda unik build terakhir dari Flutter
├── favicon.png                      Ikon di tab peramban
├── flutter.js                       Pemuat resmi Flutter Web
├── flutter_bootstrap.js             Skrip bootstrap mesin Flutter sebelum aplikasi jalan
├── flutter_service_worker.js        Service worker PWA (caching & dukungan luring)
├── index.html                       Entrypoint HTML, memuat <base href="/catatin/">
├── main.dart.js                     Seluruh logika & antarmuka aplikasi (kompilasi Dart → JS, ±3,6 MB)
├── manifest.json                    Manifes PWA (nama, warna tema #0175C2, ikon, orientasi)
├── version.json                     Nama, versi, dan nomor build aplikasi
└── README.md                        Berkas ini
```

Beberapa catatan:

* Berkas dan folder yang diawali titik (`.claude/`, `.last_build_id`) **tidak ikut disajikan** oleh GitHub Pages, karena Jekyll melewatkan entri berawalan `.` dan `_`.
* Path `assets/assets/fonts/` memang bertingkat dua. Itu perilaku normal `flutter build web`: folder `assets/` milik proyek disalin ke dalam direktori `assets/` hasil build.
* Setiap varian render di `canvaskit/` punya berkas pendamping `.js.symbols` untuk keperluan penerjemahan stack trace. Pemuat Flutter memilih sendiri varian yang cocok dengan kemampuan peramban pengguna, jadi seluruh varian perlu tetap ada.

---

## ⚙️ Menjalankan Secara Lokal

Tidak perlu kompilasi ulang — cukup server statis apa pun. **Yang penting: web root harus folder INDUK dari `catatin/`, bukan folder repo itu sendiri.** Sebabnya `index.html` memakai `<base href="/catatin/">`, sehingga semua aset diminta dari `/catatin/…`; kalau folder repo dijadikan root, seluruh permintaan aset akan 404 dan halaman blank.

### Metode 1 — Python (tanpa instalasi tambahan)

Dari dalam folder repo:

```bash
python -m http.server 8080 --directory ..
```

Lalu buka <http://localhost:8080/catatin/>.

### Metode 2 — Node.js (`http-server`)

Dari folder **induk** repo:

```bash
npx http-server -p 8080
```

Lalu buka <http://localhost:8080/catatin/>.

### Metode 3 — Lewat Claude Code

Konfigurasi `.claude/launch.json` sudah menyiapkan server di atas dengan nama `catatin-web` pada port `8011`. Setelah dijalankan, alamat aplikasinya <http://localhost:8011/catatin/>.

---

## 🚀 Memperbarui Rilis

Kode sumber Flutter berada di proyek terpisah, bukan di repositori ini. Alur pembaruannya:

1. Kerjakan perubahan di proyek kode sumber Catatin.
2. Kompilasi ulang ke web dengan base href yang sesuai:
   ```bash
   flutter build web --release --base-href "/catatin/"
   ```
3. Salin **seluruh isi** `build/web/` dari proyek sumber ke root repositori ini, timpa yang lama.
4. Pastikan `README.md` dan `.claude/` tidak ikut terhapus — keduanya milik repositori ini, bukan keluaran build.
5. Periksa hasilnya secara lokal lebih dulu (lihat bagian di atas), lalu:
   ```bash
   git add .
   git commit -m "Rilis: [deskripsi perubahan]"
   git push origin main
   ```
6. GitHub Pages menjalankan `pages build and deployment` otomatis; situs biasanya sudah terbarui dalam 1–2 menit.

> **Cadangan.** Branch `backup(stable-version)` menyimpan versi stabil yang tayang sekarang. Kalau rilis baru bermasalah, `main` bisa dikembalikan ke branch tersebut dan situs ikut kembali sendiri pada deployment berikutnya.

---

## 🛠️ Catatan Penting Mengenai Base Href

`index.html` memakai `<base href="/catatin/">` agar aplikasi berjalan benar di sub-direktori seperti `https://<username>.github.io/catatin/`.

Jika hosting dipindah ke domain utama (misalnya `https://catatin.com/`), ubah di `index.html`:

```html
<base href="/catatin/">
```

menjadi:

```html
<base href="/">
```

Kalau pembaruan dilakukan lewat `flutter build web`, cukup sesuaikan nilai `--base-href` pada perintah build sehingga tidak perlu menyunting `index.html` secara manual.
