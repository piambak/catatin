# Panduan Kontribusi

Terima kasih sudah mau ikut membangun Catatin. Dokumen ini singkat saja —
tujuannya supaya kamu bisa mengirim perubahan pertama dalam 15 menit.

## 1. Menyiapkan proyek

Butuh **Flutter 3.38.4 atau lebih baru** (versi yang dipakai CI). Cek dengan
`flutter --version`; kalau lebih tua, jalankan `flutter upgrade`.

```bash
git clone https://github.com/piambak/catatin.git
cd catatin/app
flutter pub get
flutter run -d chrome
```

Tanpa konfigurasi tambahan, aplikasi jalan dengan **data contoh** — tidak butuh
backend, tidak butuh akun. Cara menyambungkannya ke backend ada di
[`docs/BACKEND.md`](docs/BACKEND.md).

## 2. Yang boleh dan tidak boleh disunting

```
app/          ← SUNTING DI SINI
docs/ tool/ .github/   ← boleh
```

```
index.html  main.dart.js  flutter*.js  version.json  manifest.json
assets/  canvaskit/  icons/  .last_build_id
```

Semua itu di root repo adalah **hasil build otomatis**. Menyuntingnya sia-sia:
build berikutnya menimpanya. Kalau ada yang salah di situs, perbaikannya ada di
`app/`.

## 3. Alur kerja

```bash
git switch -c fitur/nama-singkat     # atau perbaikan/nama-singkat
# … kerjakan …
cd app && flutter analyze && flutter test
git commit -m "feat(dashboard): tambah kartu ringkasan PPN"
git push -u origin fitur/nama-singkat
```

Lalu buka Pull Request ke `main`. CI otomatis menjalankan analisis, tes, dan
build web. PR yang CI-nya merah tidak digabung.

### Nama branch

| Awalan | Untuk |
| --- | --- |
| `fitur/` | Fitur baru |
| `perbaikan/` | Perbaikan bug |
| `docs/` | Dokumentasi saja |
| `tooling/` | CI, skrip, konfigurasi |

### Pesan commit

Format [Conventional Commits](https://www.conventionalcommits.org/), badan
pesan boleh Bahasa Indonesia:

```
feat(simulator): tambah skenario PPh 21 untuk karyawan tidak tetap
fix(accounting): tanggal transaksi tergeser satu hari di zona WITA
docs(backend): lengkapi kontrak endpoint /tax-calendar
```

Cakupan (`dashboard`, `accounting`, `library`, `simulator`, `settings`, `auth`,
`data`, `ci`) membantu saat menelusuri riwayat per fitur.

## 4. Gaya kode

* Jalankan `flutter analyze` sebelum push — CI menggagalkan warning dan error.
* Kode lama memakai perataan kolom manual (`title:      'Catatin',`). **Jangan**
  menjalankan `dart format` pada berkas yang tidak kamu sentuh: hasilnya diff
  ratusan baris yang menenggelamkan perubahan aslimu.
* Komentar dan teks yang dilihat pengguna dalam Bahasa Indonesia. Nama variabel,
  kelas, dan fungsi dalam Bahasa Inggris.
* Widget baru yang dipakai lebih dari satu layar → taruh di
  `app/lib/widgets/common/`.

## 5. Menambah data baru

Kalau layarmu butuh data yang belum ada:

1. Tambah method di kontrak `app/lib/core/data/repositories.dart`.
2. Implementasikan di `mock_repositories.dart` **dan** `api_repositories.dart` —
   analyzer menolak kalau salah satu lupa.
3. Teruskan lewat fasad di `app/lib/core/services/`.
4. Catat kontrak endpoint-nya di [`docs/BACKEND.md`](docs/BACKEND.md).

Layar **tidak boleh** memanggil Dio langsung. Kalau terasa perlu, itu tanda
kontraknya yang kurang.

## 6. Tes

```bash
cd app
flutter test
```

Tes ada di `app/test/`. Yang paling berharga di proyek ini: logika perhitungan
pajak di `core/services/simulator_service.dart` dan perilaku repository mock.
Untuk tes yang butuh data, suntik repository palsu:

```dart
Repos.dashboard = FakeDashboardRepository();
addTearDown(Repos.reset);
```

## 7. Rahasia

Jangan pernah meng-commit URL backend, token, atau kunci API. Konfigurasi
lingkungan masuk lewat `--dart-define` (lihat `app/dart_define.example.json`).

Khusus web: apa pun yang masuk `--dart-define` **ikut ter-compile ke bundel JS
publik** dan bisa dibaca siapa saja. URL backend boleh; API key tidak pernah
boleh.

## 8. Butuh bantuan?

Buka [isu baru](https://github.com/piambak/catatin/issues/new/choose) atau
tanya di Discussions. Pertanyaan "ini kenapa dibuat begini?" sangat diterima —
biasanya artinya dokumentasinya yang kurang.
