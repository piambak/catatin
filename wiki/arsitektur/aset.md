# Aset

## Font

Aplikasi memakai dua keluarga font, keduanya **di-bundle** di dalam aplikasi:

| Keluarga | Dipakai untuk | Berat yang dibundel |
| --- | --- | --- |
| `DMSans` | Seluruh teks isi, tombol, label | 400, 500, 600, 700 |
| `DMSerif` | Judul besar, judul AppBar | 400 |

Hanya berat yang benar-benar dipakai kode yang ikut dibundel. Menambah berat
baru = taruh `.ttf`-nya di `app/assets/fonts/` lalu daftarkan di bagian `fonts:`
pada `app/pubspec.yaml`. Kalau tidak didaftarkan, Flutter diam-diam mensintesis
tebalnya dan hasilnya terlihat berbeda dari desain.

### Kenapa di-bundle, bukan lewat `google_fonts`

Paket `google_fonts` mengunduh font dari `fonts.gstatic.com` saat runtime.
Untuk aplikasi ini itu berarti: teks sempat berkedip saat pertama dibuka, gagal
total kalau perangkat offline, dan setiap pengguna menembak domain pihak
ketiga. Font di-bundle menghilangkan ketiganya dengan biaya ~290 KB.

### Lisensi

* **DM Sans** — SIL Open Font License 1.1, oleh Colophon Foundry, Jonny Pinhorn,
  Indian Type Foundry.
* **DM Serif Display** — SIL Open Font License 1.1, oleh Colophon Foundry,
  Jonny Pinhorn.

OFL mengizinkan pemakaian, penggandaan, dan penyertaan dalam produk komersial,
termasuk membundelnya di aplikasi. Syaratnya: font tidak dijual sendirian dan
nama font yang dimodifikasi harus diganti. Kami tidak memodifikasi keduanya.

## Gambar

`app/assets/images/` masih kosong dan sudah terdaftar di `pubspec.yaml`, siap
diisi. Taruh berkas di sana lalu panggil dengan
`Image.asset('assets/images/nama.png')` — tidak perlu menyunting `pubspec.yaml`
lagi karena seluruh folder sudah didaftarkan.

Sebelum menambah gambar, pertimbangkan dulu: ikon Material dan emoji sudah
menutupi hampir semua kebutuhan aplikasi ini, dan keduanya tidak menambah berat
unduhan web.

## Ikon aplikasi & PWA

| Berkas | Dipakai |
| --- | --- |
| `app/web/favicon.png` | Ikon tab peramban |
| `app/web/icons/Icon-192.png`, `Icon-512.png` | Ikon PWA standar |
| `app/web/icons/Icon-maskable-*.png` | Ikon PWA maskable (Android adaptive) |
| `app/android/app/src/main/res/mipmap-*/` | Ikon Android |
| `app/ios/Runner/Assets.xcassets/AppIcon.appiconset/` | Ikon iOS |

Warna tema PWA (`#FFA400`) diatur di `app/web/manifest.json` dan
`app/web/index.html` — keduanya harus diubah bareng kalau warna merek berganti.

## Ukuran bundel web

Yang paling berpengaruh ke berat unduhan:

1. `main.dart.js` (~3,6 MB) — hasil kompilasi Dart, sudah tree-shaken.
2. `canvaskit/` — mesin render; pemuat Flutter memilih sendiri varian yang
   cocok dengan peramban pengguna, jadi seluruh varian perlu tetap ada.
3. Font (~290 KB).

Menambah paket pub baru adalah cara tercepat membengkakkan `main.dart.js`.
Sebelum menambah dependensi, cek dulu apakah kebutuhannya bisa dipenuhi widget
bawaan Flutter.
