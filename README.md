# Catatin Web 📊

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Web](https://img.shields.io/badge/Platform-Web-blue?style=for-the-badge)](https://flutter.dev/multi-platform/web)
[![PWA](https://img.shields.io/badge/PWA-Supported-orange?style=for-the-badge)](https://developer.mozilla.org/en-US/docs/Web/Progressive_web_apps)

**Catatin** adalah aplikasi pencatatan keuangan pribadi dan pembukuan bisnis yang dikembangkan menggunakan framework Flutter. Repositori ini berisi berkas hasil kompilasi produksi (production build) dari aplikasi **Catatin Web** yang siap dideploy dan dijalankan di peramban web.

---

## 📁 Struktur Folder & Berkas

Berikut adalah penjelasan mengenai peran dan kegunaan dari masing-masing folder dan berkas utama di dalam repositori ini:

| Folder / Berkas | Tipe | Deskripsi / Kegunaan |
| :--- | :---: | :--- |
| `assets/` | Folder | Menyimpan berkas statis aplikasi seperti font utama (Fredoka, Nunito), shader, berkas manifes aset/font, serta dokumen lisensi (`NOTICES`). |
| `canvaskit/` | Folder | Berisi pustaka WebAssembly (WASM) dan JavaScript CanvasKit yang digunakan oleh Flutter Web untuk merender antarmuka grafis secara optimal via WebGL. |
| `icons/` | Folder | Menyimpan ikon-ikon aplikasi dengan berbagai ukuran yang diperlukan oleh Progressive Web App (PWA). |
| `favicon.png` | Berkas | Gambar ikon yang muncul pada tab peramban ketika aplikasi dibuka. |
| `flutter.js` | Berkas | Pustaka JavaScript resmi dari Flutter untuk menginisialisasi proses pemuatan dan siklus hidup aplikasi di web. |
| `flutter_bootstrap.js` | Berkas | Berkas konfigurasi awal untuk melakukan bootstrap pada mesin Flutter Web sebelum aplikasi dijalankan. |
| `flutter_service_worker.js` | Berkas | Mengelola mekanisme *service worker* untuk PWA, memfasilitasi caching berkas secara luring (offline) dan meningkatkan kecepatan pemuatan. |
| `index.html` | Berkas | Pintu masuk utama (entrypoint) HTML untuk aplikasi web. Berisi konfigurasi dasar, tautan manifes PWA, dan penyiapan skrip bootstrap. |
| `main.dart.js` | Berkas | Berkas JavaScript utama berukuran besar yang menampung seluruh kompilasi logika bisnis dan antarmuka aplikasi Flutter dari Dart ke JavaScript. |
| `manifest.json` | Berkas | Berkas manifes PWA yang mendefinisikan nama aplikasi, warna tema, warna latar belakang, dan struktur ikon agar aplikasi dapat diinstal di perangkat pengguna. |
| `version.json` | Berkas | Berisi informasi versi aplikasi saat ini (`1.0.0`), nomor build (`1`), serta nama paket aplikasi untuk kebutuhan manajemen rilis. |
| `.last_build_id` | Berkas | Berkas pelacak metadata untuk mengidentifikasi build unik terakhir dari proses kompilasi Flutter. |

---

## ⚙️ Panduan Instalasi & Cara Menjalankan

Karena repositori ini menyimpan hasil kompilasi web statis, Anda tidak memerlukan proses kompilasi ulang (compiling) untuk menjalankannya. Anda hanya memerlukan server web statis.

### Persyaratan Utama
*   [Node.js](https://nodejs.org/) (opsional, jika ingin menggunakan web server berbasis Node) atau Python.
*   Peramban Web modern (Chrome, Edge, Firefox, Safari).

### Menjalankan secara Lokal

#### Metode 1: Menggunakan Node.js (`http-server`)
1. Pastikan Anda memiliki Node.js terinstal di komputer Anda.
2. Buka terminal atau Command Prompt pada direktori repositori ini (`d:\GitHub\catatin`).
3. Jalankan perintah berikut untuk menjalankan server lokal:
   ```bash
   npx http-server -p 8080
   ```
4. Buka peramban dan akses aplikasi melalui alamat:
   ```
   http://localhost:8080/catatin/
   ```
   *(Catatan: Pastikan menyertakan sub-path `/catatin/` di akhir URL karena aplikasi dikonfigurasi dengan `<base href="/catatin/">`)*.

#### Metode 2: Menggunakan Python
Jika komputer Anda memiliki Python terinstal, Anda dapat menjalankan server bawaan Python:
1. Buka terminal pada direktori proyek.
2. Jalankan perintah berikut (untuk Python 3):
   ```bash
   python -m http.server 8080
   ```
3. Buka peramban dan akses aplikasi pada alamat `http://localhost:8080/catatin/`.

---

## 🚀 Panduan Pengembangan & Pembaruan

Jika Anda ingin melakukan perubahan pada kode sumber dan memperbarui repositori rilis ini, ikuti langkah-langkah berikut pada repositori utama Flutter Anda:

1. Lakukan pengembangan dan modifikasi fitur pada repositori kode sumber (source code) utama Catatin.
2. Kompilasi ulang proyek ke versi web dengan perintah:
   ```bash
   flutter build web --base-href "/catatin/" --release
   ```
3. Setelah proses build selesai, salin seluruh isi dari folder hasil build (`build/web/`) di proyek utama Anda.
4. Tempel dan timpa berkas yang ada di dalam repositori deployment ini (`d:\GitHub\catatin\`).
5. Lakukan commit dan push pembaruan tersebut ke GitHub:
   ```bash
   git add .
   git commit -m "Update rilis: [deskripsi perubahan]"
   git push origin main
   ```
6. Aplikasi Anda akan otomatis terbarui di hosting tujuan (misalnya GitHub Pages).

---

## 🛠️ Catatan Penting Mengenai Base Href

Aplikasi ini menggunakan tag `<base href="/catatin/">` pada berkas `index.html`. Ini disesuaikan agar aplikasi dapat berjalan dengan benar di bawah sub-direktori (seperti GitHub Pages `https://<username>.github.io/catatin/`).

*   **Jika Anda memindahkan hosting ke domain utama** (misalnya `https://catatin.com/`), buka berkas `index.html` dan ubah:
    ```html
    <base href="/catatin/">
    ```
    menjadi:
    ```html
    <base href="/">
    ```
