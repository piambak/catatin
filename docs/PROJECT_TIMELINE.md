# Linimasa Proyek — Catatin Fase Dua

> **Cara pakai dokumen ini:** ini bukan dokumen sekali baca — ini *tracker* hidup.
> Setiap kali menyelesaikan tugas, centang kotaknya (`- [ ]` → `- [x]`) dan ubah
> **Status** minggu itu kalau semua tugasnya sudah selesai. Tambahkan entri baru
> di **Log Progres** (paling bawah) setiap ada kemajuan, walau kecil — tanggal,
> siapa, apa yang berubah. Kalau jadwal bergeser, jangan hapus tanggal lama;
> coret dan tulis tanggal baru di sebelahnya supaya riwayatnya tetap kebaca.

**Mulai:** Senin, 14 September 2026
**Target rilis:** Jumat, 13 November 2026 (9 minggu kerja / ±2 bulan)
**Tim:** 1 Backend Engineer · 1 Frontend Engineer (Flutter) · 1 Pakar Regulasi DJP & Kemenkeu

**Tujuan fase ini:** mencabut fitur **Pustaka peraturan**, lalu memperdalam dua
fitur yang tersisa — **Pembukuan** dan **Simulator pajak** — sampai simulator
bisa menghitung dari data pembukuan asli, bukan input manual ulang.

---

## Ringkasan status

| Minggu | Tanggal | Fase | Status |
| --- | --- | --- | --- |
| 1 | 14–18 Sep | Kickoff, audit, kunci spesifikasi | 🔵 Berjalan |
| 2 | 21–25 Sep | Cabut Pustaka peraturan + fondasi backend | 🔵 Berjalan |
| 3 | 28 Sep–2 Okt | Pembukuan naik kelas (1/2) — transaksi berulang, lampiran | ⬜ Belum mulai |
| 4 | 5–9 Okt | Pembukuan naik kelas (2/2) — ekspor/impor, filter, ringkasan | ⬜ Belum mulai |
| 5 | 12–16 Okt | Simulator naik kelas (1/2) — tarik data asli, mesin tarif | ⬜ Belum mulai |
| 6 | 19–23 Okt | Simulator naik kelas (2/2) — skenario, PPN, proyeksi tahunan | ⬜ Belum mulai |
| 7 | 26–30 Okt | Integrasi lintas fitur + validasi pajak ronde 1 | ⬜ Belum mulai |
| 8 | 2–6 Nov | Perbaikan bug, polish UI, validasi pajak ronde 2 | ⬜ Belum mulai |
| 9 | 9–13 Nov | Regresi final, rilis, pemantauan pasca-rilis | ⬜ Belum mulai |

Legenda status: ⬜ Belum mulai · 🔵 Berjalan · ✅ Selesai · 🔴 Terhambat

---

## Minggu 1 — 14–18 Sep — Kickoff, audit, kunci spesifikasi

**Target minggu:** semua orang punya pemahaman sama soal kondisi kode saat ini
dan formula pajak yang benar, sebelum satu baris kode fitur baru ditulis.

### Backend
- [ ] Audit `app/lib/core/data/repositories.dart`, `mock_repositories.dart`,
      `api_repositories.dart`, `hybrid_repositories.dart` — pahami pola 3 mode
      sumber data (contoh/hybrid/API)
- [ ] Audit kontrak di `docs/BACKEND.md`, tandai endpoint mana yang sudah
      terpakai nyata vs baru rencana
- [ ] Rancang skema data mesin tarif pajak berbasis konfigurasi (tarif PPh
      Final, lapisan PTKP, TER, ambang PKP Rp4,8 M) — supaya pakar pajak bisa
      memperbarui angka tanpa rilis aplikasi baru
- [ ] Siapkan lingkungan dev backend (repo, DB lokal/staging, CI dasar)

### Frontend
- [x] Audit `app_router.dart` & `app_constants.dart` — petakan semua rute yang
      menyentuh `/library/*`
- [x] Petakan setiap widget dashboard yang menaut ke Pustaka peraturan
      (`regulation_card.dart`, `tax_tips_card.dart`, `deadline_card.dart`,
      `notification_screen.dart`) dan tentukan pengganti kontennya
- [x] Review file Flutter original yang diberikan user, bandingkan dengan
      `app/lib/` saat ini — catat perbedaan/bagian yang perlu diselaraskan
- [x] Setup branch kerja & pastikan `flutter pub get` + `flutter run -d chrome`
      jalan mulus di mesin sendiri

### Pakar Regulasi DJP & Kemenkeu
- [ ] Audit formula PPh Final 0,5% (`pph_final_tab.dart`) terhadap PP 23/2018
      — cek masa berlaku, batas omzet Rp4,8 M/tahun
- [ ] Audit formula PPh 21 TER (`pph21_tab.dart`) terhadap PMK 168/2023 —
      cek kelengkapan kategori TER A/B/C
- [ ] Tulis spesifikasi tertulis: apa saja yang berubah di kalkulator (modul
      PPN? proyeksi SPT Tahunan? kategori apa saja?) — jadi acuan backend &
      frontend minggu depan
- [ ] Tentukan konten regulasi ringkas apa yang **wajib tetap tampil** di
      aplikasi setelah Pustaka peraturan dicabut (mis. teks bantuan singkat
      di kartu tenggat pajak)

**Sinkron akhir minggu (Jumat 18 Sep):** kunci spesifikasi bersama —
setelah ini, ubah spesifikasi berarti ubah jadwal.

---

## Minggu 2 — 21–25 Sep — Cabut Pustaka peraturan + fondasi backend

**Target minggu:** aplikasi berjalan normal tanpa fitur Pustaka peraturan;
fondasi data untuk peningkatan berikutnya siap.

### Backend
- [ ] Cabut bagian **"Pustaka peraturan"** dari `docs/BACKEND.md`
      (`GET /documents/categories`, `GET /documents`, `GET /documents/{id}`)
- [x] Cabut method terkait dokumen dari `repositories.dart` dan ketiga
      implementasinya (dikerjakan bareng penghapusan frontend supaya `app/`
      tetap bisa di-build — lihat Log Progres)
- [ ] Mulai endpoint agregasi bulanan (income/expense/HPP per periode) —
      ini basis data yang nanti dipakai Simulator
- [ ] Definisikan kontrak endpoint mesin tarif pajak (draf, belum
      diimplementasi penuh) berdasarkan skema Minggu 1

### Frontend
- [x] Hapus `library_screen.dart`, `doc_detail_screen.dart`,
      `bookmark_screen.dart`, `lib_widgets.dart`, `related_docs.dart`,
      `library_service.dart`, `document_model.dart`
- [x] Cabut rute `/library/*` dan `/library/bookmarks` dari `app_router.dart`,
      cabut entri terkait dari `app_constants.dart`
- [x] Hapus tab/menu Pustaka dari bottom navigation (`MainShell`)
- [x] Ganti konten `regulation_card.dart` / `tax_tips_card.dart` dengan versi
      yang tidak bergantung pada data dokumen (pakai konten inline dari
      pakar pajak)
- [x] Uji manual: seluruh alur (splash → login → dashboard → pembukuan →
      simulator → settings) tidak ada link mati ke `/library/*`

### Pakar Regulasi DJP & Kemenkeu
- [ ] Tuliskan matriks lengkap PPh 21 TER (semua kombinasi status
      kawin/tanggungan × kategori TER) untuk dipakai backend
- [ ] Sign-off tertulis formula PPh Final & PPh 21 TER dengan backend
      (paraf/approve di PR atau dokumen spesifikasi)
- [ ] Validasi pemetaan kategori transaksi → relevansi pajak & HPP di
      `accounting_screen.dart` — cek apakah kategori saat ini sudah benar
      secara pajak

**Milestone M1 (Jumat 25 Sep):** Pustaka peraturan hilang total dari kode
dan dokumentasi; tidak ada regresi di fitur lain.

---

## Minggu 3 — 28 Sep–2 Okt — Pembukuan naik kelas (1/2)

**Target minggu:** transaksi berulang dan lampiran struk berjalan end-to-end.

### Backend
- [ ] Endpoint template transaksi berulang (buat/edit/hentikan pengulangan)
- [ ] Endpoint upload lampiran struk (foto), simpan referensi ke transaksi
- [ ] Tulis test untuk kedua endpoint di atas

### Frontend
- [ ] UI tambah transaksi berulang di `new_transaction_screen.dart` (pilih
      frekuensi: mingguan/bulanan, tanggal berakhir opsional)
- [ ] UI unggah foto struk dari kamera/galeri, preview di `tx_detail_screen.dart`
- [ ] State management untuk transaksi berulang yang otomatis muncul di
      `accounting_screen.dart` sesuai jadwalnya

### Pakar Regulasi DJP & Kemenkeu
- [ ] Susun kebutuhan modul PPN untuk usaha berstatus PKP (kapan wajib
      pungut, tarif berlaku, cara hitung dasar pengenaan pajak)
- [ ] Review implikasi pajak transaksi berulang (mis. cicilan/leasing —
      apakah bunga jadi komponen HPP atau bukan)

---

## Minggu 4 — 5–9 Okt — Pembukuan naik kelas (2/2)

**Target minggu:** ekspor/impor data dan pengalaman pencarian/filter selesai.

### Backend
- [ ] Endpoint ekspor transaksi ke CSV (per rentang tanggal/kategori)
- [ ] Endpoint impor CSV dengan validasi baris gagal
- [ ] Endpoint ringkasan tutup bulan (total masuk/keluar/laba, siap dipakai
      dashboard & simulator)

### Frontend
- [ ] UI ekspor CSV (pilih rentang, unduh/bagikan)
- [ ] UI impor CSV (preview sebelum commit, tampilkan baris error)
- [ ] Filter & pencarian transaksi (per kategori, rentang tanggal, status
      relevansi pajak) di `accounting_screen.dart`
- [ ] Kartu ringkasan tutup bulan di dashboard

### Pakar Regulasi DJP & Kemenkeu
- [ ] Validasi format ekspor CSV cukup untuk kebutuhan pembukuan UMKM
      (kolom apa saja yang wajib ada untuk keperluan pajak)
- [ ] Review kasus tepi impor: transaksi lintas tahun pajak, mata uang,
      pembulatan Rupiah

**Milestone M2 (Jumat 9 Okt):** Pembukuan v2 selesai — transaksi berulang,
lampiran, ekspor/impor, filter, ringkasan bulanan semua jalan.

---

## Minggu 5 — 12–16 Okt — Simulator naik kelas (1/2)

**Target minggu:** simulator berhenti minta input manual, mulai menarik data
pembukuan asli.

### Backend
- [ ] Implementasi penuh endpoint mesin tarif pajak (PPh Final & PPh 21 TER,
      baca dari konfigurasi, bukan hardcode)
- [ ] Endpoint yang menggabungkan agregasi transaksi (dari Minggu 2) sebagai
      input siap pakai untuk kalkulasi simulator
- [ ] Test: hasil endpoint mesin tarif cocok dengan contoh kasus dari pakar
      pajak (unit test berbasis kasus nyata)

### Frontend
- [ ] Rombak `pph_final_tab.dart` & `pph21_tab.dart`: tarik omzet/laba dari
      data Pembukuan asli, tampilkan asalnya jelas ("dihitung dari transaksi
      Sep 2026"), tetap izinkan override manual untuk simulasi "bagaimana jika"
- [ ] Loading/error state saat data agregasi backend belum siap

### Pakar Regulasi DJP & Kemenkeu
- [ ] Input tarif & lapisan final ke skema konfigurasi backend, validasi
      terhadap kalkulator resmi DJP (bandingkan hasil satu-satu)
- [ ] Uji kasus tepi: usaha baru berjalan <12 bulan, omzet mendekati ambang
      Rp4,8 M di tengah tahun berjalan

---

## Minggu 6 — 19–23 Okt — Simulator naik kelas (2/2)

**Target minggu:** simpan/bandingkan skenario, modul PPN, proyeksi tahunan.

### Backend
- [ ] Endpoint simpan & ambil skenario simulasi (nama, asumsi, hasil)
- [ ] Endpoint kalkulasi PPN (untuk usaha PKP) sesuai kebutuhan Minggu 3
- [ ] Endpoint proyeksi SPT Tahunan sederhana berbasis data 12 bulan terakhir

### Frontend
- [ ] UI simpan skenario dengan nama custom, daftar skenario tersimpan
- [ ] UI bandingkan 2–3 skenario berdampingan (`scenario_tab.dart`)
- [ ] UI modul PPN (kalau usaha berstatus PKP di Profil usaha)
- [ ] Ekspor hasil simulasi ke PDF/bagikan

### Pakar Regulasi DJP & Kemenkeu
- [ ] Validasi kalkulasi PPN terhadap regulasi Kemenkeu terbaru
- [ ] Validasi logika proyeksi SPT Tahunan — pastikan disclaimer jelas bahwa
      ini simulasi, bukan pengganti konsultasi resmi
- [ ] Uji kasus tepi: transisi status non-PKP → PKP di tengah tahun

**Milestone M3 (Jumat 23 Okt):** Simulator v2 selesai — data otomatis dari
Pembukuan, skenario tersimpan, PPN, proyeksi tahunan.

---

## Minggu 7 — 26–30 Okt — Integrasi lintas fitur + validasi pajak ronde 1

**Target minggu:** semua bagian yang dibangun terpisah terbukti benar
saat dipakai bersamaan.

### Backend
- [ ] Uji beban ringan pada endpoint agregasi & mesin tarif (pastikan
      responsif dengan data 12 bulan transaksi)
- [ ] Perbaiki bug dari uji integrasi
- [ ] Perkuat validasi input (nominal negatif, tanggal tidak valid, dsb.)

### Frontend
- [ ] Uji alur penuh: catat transaksi baru → cek muncul di dashboard →
      cek terhitung otomatis di simulator → simpan skenario → ekspor PDF
- [ ] Perbaiki bug dari uji integrasi
- [ ] Cek konsistensi mode gelap di semua layar baru

### Pakar Regulasi DJP & Kemenkeu
- [ ] **Uji penerimaan ronde 1:** ambil 5–10 kasus UMKM nyata (data contoh),
      jalankan lewat aplikasi, cocokkan manual dengan kalkulator resmi DJP
- [ ] Catat semua selisih sebagai bug, prioritaskan berdasarkan dampak

---

## Minggu 8 — 2–6 Nov — Perbaikan bug, polish UI, validasi pajak ronde 2

**Target minggu:** daftar bug dari Minggu 7 mendekati nol.

### Backend
- [ ] Selesaikan semua bug berlabel backend dari Minggu 7
- [ ] Finalisasi `docs/BACKEND.md` — dokumentasikan semua endpoint baru
      (agregasi, mesin tarif, skenario, PPN, ekspor/impor)
- [ ] Siapkan deploy staging untuk uji akhir

### Frontend
- [ ] Selesaikan semua bug berlabel frontend dari Minggu 7
- [ ] Polish UI: spacing, animasi transisi, konsistensi komponen di fitur baru
- [ ] Cek performa (waktu muat dashboard, ukuran bundel web)

### Pakar Regulasi DJP & Kemenkeu
- [ ] **Uji penerimaan ronde 2:** ulangi kasus Minggu 7 setelah perbaikan,
      pastikan semua cocok dengan kalkulator resmi DJP
- [ ] Tulis catatan rilis logika pajak & disclaimer pengguna (mis. "simulasi
      ini bukan pengganti konsultasi pajak resmi")

**Milestone M4 (Jumat 6 Nov):** Tidak ada bug kritikal terbuka; hasil
kalkulasi tervalidasi penuh terhadap contoh resmi DJP.

---

## Minggu 9 — 9–13 Nov — Regresi final, rilis, pemantauan pasca-rilis

**Target minggu:** Catatin v2 tayang — hanya Pembukuan dan Simulator pajak,
keduanya lebih dalam dari sebelumnya.

### Backend
- [ ] Deploy produksi, pastikan monitoring/log aktif
- [ ] Siaga selama 48 jam pertama pasca-rilis untuk isu backend

### Frontend
- [ ] Build rilis web (`flutter build web`, sinkron ke root sesuai alur
      `tool/build_web.sh`) dan mobile bila sudah waktunya
- [ ] Regresi manual penuh sebelum rilis (checklist semua fitur)
- [ ] Siaga selama 48 jam pertama pasca-rilis untuk isu UI

### Pakar Regulasi DJP & Kemenkeu
- [ ] Sign-off regulasi final sebelum tombol rilis ditekan
- [ ] Siapkan rencana pemantauan: siapa yang memeriksa kalau ada perubahan
      tarif/aturan DJP & Kemenkeu setelah rilis, dan seberapa sering

**Milestone M5 (Jumat 13 Nov) — RILIS:** Catatin v2 tayang di
[piambak.github.io/catatin](https://piambak.github.io/catatin/).

---

## Temuan audit kode — usulan perbaikan

> Ditambahkan **8 September 2026** setelah audit `app/lib` (53 file, ±14.500
> baris) pada branch `claude/flutter-project-review-plan-pzmo22`. Semua temuan
> di bawah **belum tercakup** tugas Minggu 1–9 di atas. Masukkan ke minggu yang
> relevan saat sinkron mingguan, jangan dikerjakan diam-diam di luar jadwal.
>
> Prioritas: 🔴 wajib beres sebelum **M4** (validasi pajak) · 🟡 sebaiknya masuk
> fase ini · ⬜ boleh ditunda ke fase berikutnya

| # | Temuan | Prioritas | Pemilik | Usul masuk |
| --- | --- | --- | --- | --- |
| T-1 | Kategori TER B & C tidak ada — PPh 21 salah hitung | 🔴 | Pakar pajak → Frontend | Minggu 5 |
| T-2 | Nol tes untuk mesin pajak | ✅ **Selesai** | Frontend | 8 Sep 2026 |
| T-3 | PPh Final: pengecualian omzet Rp500 juta & batas jangka waktu belum ada | 🔴 | Pakar pajak → Frontend | Minggu 5 |
| T-4 | Angka PKP di layar PPh 21 menyesatkan; rekalkulasi Desember belum ada | 🟡 | Pakar pajak → Frontend | Minggu 6 |
| T-5 | Null-assertion rawan crash di pemetaan PTKP | ✅ **Selesai** | Frontend | 8 Sep 2026 |
| T-6 | 66 pemakaian `withOpacity` yang sudah deprecated | ✅ **Selesai** | Frontend | 8 Sep 2026 |
| T-7 | Dua `BuildContext` dipakai lewat async gap | ✅ **Selesai** | Frontend | 8 Sep 2026 |
| T-8 | Aksesibilitas nol — tidak ada satu pun `Semantics` | 🟨 **Sebagian** | Frontend | 8 Sep 2026 |
| T-9 | CI tidak menegakkan `dart format` | 🟡 | Frontend | Minggu 3 |
| T-10 | CI tanpa laporan coverage | ⬜ | Frontend | Minggu 8 |
| T-11 | `flutter_secure_storage` di web perlu diverifikasi sebelum JWT asli | ⬜ | Backend + Frontend | Minggu 5 |
| T-12 | Belum ada kerangka l10n | ⬜ | Frontend | Fase berikutnya |
| T-13 | Tabel TER tampilan menyimpang dari tabel hitung | ✅ **Selesai** | Frontend | 8 Sep 2026 |
| T-14 | 3.225 baris widget dashboard jadi yatim setelah redesain | 🟡 | Frontend | Perlu keputusan |
| T-15 | Kelas tipografi bernama `T` bentrok dengan parameter generic | ✅ **Selesai** | Frontend | 8 Sep 2026 |

---

### ✅ T-15 — Kelas tipografi bernama `T` bentrok dengan parameter generic *(selesai 8 Sep 2026)*

`design_tokens.dart` mengekspor kelas gaya teks bernama **`T`** (`T.sans`,
`T.serif`, `T.mono`). `T` juga nama konvensional untuk parameter generic di
Dart, jadi di dalam kelas generic apa pun nama itu tertutup:

```dart
class _SheetDropdown<T> ... {
  Text('x', style: T.sans(14))  // error: 'sans' isn't defined for type 'T'
}
```

Terjadi nyata saat menggayakan ulang `tx_add_sheet.dart`, yang punya
`_DdItem<T>` dan `_SheetDropdown<T>`. Ditambal sementara dengan mengganti
parameter generic-nya jadi `V` — **itu memperbaiki gejala di tempat yang salah**:
kode pemanggil dipaksa menghindari nama yang lazim gara-gara token.

- [x] **Frontend** — kelas `T` diganti nama jadi **`Typo`** (142 pemakaian di
      15 berkas), lalu generic `V` di `tx_add_sheet.dart` dikembalikan ke `T`.
      `Typo` dipilih supaya sebaris dengan token lain (`DS`, `Space`, `Radii`)
      dan tidak tertukar dengan `AppTextStyles` lama yang masih dipakai layar
      yang belum didesain ulang.

---

### 🟡 T-14 — Widget dashboard lama jadi yatim setelah redesain

Setelah `dashboard_screen.dart` ditulis ulang mengikuti artboard 1b, seluruh
widget dashboard lama tidak lagi dirujuk siapa pun. Nol referensi eksternal
untuk kesepuluhnya:

`KpiCard` · `IncomeChartCard` · `PkpBar` · `RecentTransactions` ·
`DeadlineCard` · `QuickActions` · `TaxTipsCard` · `RegulationCard` ·
`CalDeadlineCard` · `TaxCalendarCard`

Totalnya **3.225 baris** di `lib/widgets/dashboard/`. Kompilator tidak
mengeluhkannya karena masing-masing berkas tetap valid — hanya tidak pernah
dipakai.

Hal serupa berlaku untuk `pph_final_tab.dart` dan `pph21_tab.dart` di
simulator, yang sengaja dipertahankan sebagai rujukan saat T-1 dikerjakan.

**Butuh keputusan, bukan aksi otomatis:**

- [ ] **Frontend + pemilik produk** — putuskan mana yang dihapus dan mana yang
      ditahan sebagai rujukan. Menghapusnya mengecilkan repo dan menghilangkan
      kebingungan "berkas mana yang hidup"; menahannya berguna sampai Pembukuan
      selesai didesain ulang dan T-1 beres.
- [ ] Apa pun keputusannya, kerjakan sebagai PR tersendiri — penghapusan 3.000+
      baris tidak boleh bercampur dengan perubahan lain.

Sampai diputuskan, jangan buang tenaga memperbaiki apa pun di dalamnya —
pembersihan `withOpacity` (T-6) sudah menyentuh berkas-berkas ini, tapi
pekerjaan aksesibilitas (T-8) sengaja melewatinya.

---

### ✅ T-13 — Tabel TER tampilan menyimpang dari tabel hitung *(selesai 8 Sep 2026)*

Ditemukan saat menulis tes T-2, bukan dari pembacaan kode biasa.

`buildTerTable()` di `simulator_service.dart` menyimpan **daftar tarif kedua**
yang ditulis tangan, terpisah dari `AppConstants.terTableA` yang dipakai
`calculatePPh21()` untuk menghitung. Keduanya sudah menyimpang:

| Gaji bulanan | Ditampilkan tabel | Dipakai hitungan |
| --- | --- | --- |
| Rp 8.000.000 | 1,5% | **2,0%** |
| Rp 9.000.000 | 1,5% | **2,5%** |
| Rp 12.000.000 | 5,0% | **6,0%** |
| Rp 40.000.000 | 19,0% | **27,0%** |

Artinya pengguna bisa melihat baris tersorot yang menyebut satu tarif, sementara
angka rupiah di layar yang sama dihitung dengan tarif lain.

**Dampak nyata saat ini: nihil.** `buildTerTable()` hanya dipakai
`pph21_tab.dart`, dan tab itu sudah tidak terpasang sejak simulator diganti alur
percakapan. Jadi ini cacat laten — perangkap untuk siapa pun yang menghidupkan
kembali tab tersebut atau memakai ulang fungsinya, bukan bug yang sedang
dirasakan pengguna.

**Perbaikan:** `buildTerTable()` sekarang diturunkan dari `terTableA`, dengan
lapisan berurutan bertarif sama digabung jadi satu rentang. Tidak ada lagi
daftar kedua yang bisa menyimpang. Tidak ada satu pun tarif yang diubah — ini
murni menghapus duplikasi, bukan keputusan pajak, jadi tidak menyentuh wewenang
pakar pajak.

Tes `buildTerTable tarif baris tersorot sama dengan tarif hasil hitung`
mengunci perbaikannya.

---

### 🔴 T-1 — Kategori TER B & C tidak ada, PPh 21 salah hitung

`calculatePPh21()` di `app/lib/core/services/simulator_service.dart:102` selalu
membaca `AppConstants.terTableA`, apa pun status PTKP yang dipilih pengguna.
`terTableB` dan `terTableC` **tidak ada sama sekali** di `app_constants.dart` —
yang ada hanya `terTableA` (baris 32).

Akibatnya pengguna yang memilih status seperti K/2 atau K/3 tetap mendapat tarif
kategori A, jadi angka pajaknya salah. Ini persis tugas Minggu 1 pakar pajak
yang masih terbuka ("cek kelengkapan kategori TER A/B/C") — sekarang
terkonfirmasi sebagai bug, bukan sekadar hal yang perlu dicek.

- [ ] **Pakar pajak** — kunci pemetaan status PTKP → kategori TER menurut
      PMK 168/2023, lengkap dengan tabel tarif B dan C
- [ ] **Frontend** — tambah `terTableB`/`terTableC`, ganti pemilihan tabel jadi
      fungsi dari status PTKP, bukan konstanta

**Catatan:** jangan implementasi dari sumber sekunder. Tunggu tabel resmi dari
pakar pajak — satu tarif salah berarti seluruh hasil M4 ikut salah.

### 🔴 T-2 — Mesin pajak tidak punya satu pun tes

`test/widget_test.dart` berisi 5 tes, semuanya menguji `MockDashboardRepository`.
`simulator_service.dart` — `calculatePPhFinal()`, `calculatePPh21()`, dan
kalkulasi skenario — nol tes. Padahal ini satu-satunya kode di repo yang
kesalahannya langsung berujung ke angka pajak salah di layar pengguna.

Milestone **M4** mensyaratkan hasil kalkulasi cocok dengan kalkulator resmi DJP.
Tanpa tes, verifikasi itu manual dan tidak berulang — begitu Minggu 5 merombak
kedua tab simulator, tidak ada jaring pengaman yang memberi tahu kalau angkanya
bergeser.

- [ ] **Frontend** — tes unit `calculatePPhFinal()`: di bawah ambang, tepat di
      ambang Rp4,8 M, di atas ambang, dan omzet nol
- [ ] **Frontend** — tes unit `calculatePPh21()`: satu kasus per status PTKP,
      plus batas antar-lapisan TER (nilai tepat di `max` tiap baris)
- [ ] **Frontend** — begitu pakar pajak menyerahkan kasus uji resmi (tugas
      Minggu 7), jadikan tes otomatis — bukan cuma dicek manual sekali

### 🔴 T-3 — PPh Final: pengecualian Rp500 juta & batas jangka waktu belum dimodelkan

`calculatePPhFinal()` mengenakan 0,5% dari rupiah pertama, dan `eligible` hanya
diuji terhadap ambang Rp4,8 M/tahun. Dua hal belum ada di model:

1. **Pengecualian omzet Rp500 juta pertama** untuk WP orang pribadi
   (UU HPP 2021 / PP 55/2022). Kalau ini berlaku untuk pengguna target Catatin,
   omzet di bawah Rp500 juta/tahun mestinya menghasilkan pajak nol — sekarang
   tidak.
2. **Batas jangka waktu** pemakaian tarif final PP 23/2018, yang berbeda antara
   WP OP dan badan. Tidak ada input apa pun soal "sejak tahun berapa".

- [ ] **Pakar pajak** — putuskan apakah keduanya masuk lingkup Catatin, dan
      untuk profil WP yang mana saja
- [ ] **Frontend** — kalau ya, `PPhFinalResult` butuh field baru dan Profil
      usaha butuh input tahun mulai. Ini mengubah kontrak data, jadi harus
      diputus **sebelum** Minggu 5 mulai, bukan di tengah jalan

### 🟡 T-4 — Angka PKP di layar PPh 21 menyesatkan

`calculatePPh21()` menghitung `pkp = (gajiKotor × 12) − PTKP` lalu
menampilkannya, padahal:

- Biaya jabatan (5%, ada batas atas) dan iuran pensiun tidak dikurangkan
- Pada metode TER bulanan, PKP **tidak dipakai sama sekali** untuk menghitung
  pajaknya — tarif diambil dari tabel TER berdasar penghasilan bruto

Jadi pengguna melihat angka berlabel "PKP" yang bukan PKP menurut definisi mana
pun, dan yang tidak dipakai dalam hasil hitung. Terpisah dari itu, **rekalkulasi
Desember** (Pasal 17 progresif untuk masa pajak terakhir) belum dimodelkan —
TER hanya berlaku Januari–November.

- [ ] **Pakar pajak** — tentukan angka apa yang layak ditampilkan di tab PPh 21,
      dan apakah rekalkulasi Desember masuk lingkup fase ini
- [ ] **Frontend** — sesuaikan `PPh21Result` dan `pph21_tab.dart` mengikuti
      keputusan di atas

### 🟡 T-5 — Null-assertion rawan crash di pemetaan PTKP

`simulator_service.dart:79` dan `:103` memakai pola yang sama:

```dart
AppConstants.ptkp[status.shortLabel.replaceAll('/','')]!
```

Nilai enum diubah jadi label tampilan, tanda `/` dibuang, hasilnya dipakai
sebagai kunci Map, lalu di-`!`. Tiga langkah rapuh untuk sesuatu yang bisa
dipetakan langsung. Menambah satu status PTKP tanpa menambah entri Map akan
crash saat runtime, bukan gagal saat compile.

- [ ] **Frontend** — ganti jadi pemetaan langsung `PtkpStatus` → `double`
      (extension `ptkpAmount` dengan `switch` lengkap), hapus tanda `!`

### 🟡 T-6 — 66 pemakaian `withOpacity` yang sudah deprecated

Tersebar di ±20 file widget (dashboard, simulator, accounting). CI menjalankan
`flutter analyze --no-fatal-infos`, jadi ini tidak pernah menggagalkan PR —
sampai suatu saat Flutter mengangkatnya jadi error dan build rilis berhenti.

Perbaikannya mekanis: `withOpacity(0.5)` → `withValues(alpha: 0.5)`.

- [ ] **Frontend** — kerjakan sebagai **satu PR terpisah** (menyentuh ±20 file).
      Jangan dititipkan ke PR fitur; diff-nya akan menenggelamkan review

### 🟡 T-7 — Dua `BuildContext` dipakai lewat async gap

- `screens/settings/settings_screen.dart:68` — `mounted` dicek **sebelum**
  `await AuthService.logout()`, lalu `context.go()` dipanggil sesudahnya. Cek
  `mounted`-nya ada di sisi yang salah dari `await`: kalau logout lambat dan
  layar keburu dilepas, `context.go` dilempar ke widget yang sudah mati.
- `widgets/accounting/month_picker.dart:389` — `context` dipakai di dalam
  `Future.microtask` setelah `Navigator.pop(context)` dipanggil.

- [ ] **Frontend** — pindahkan cek `mounted` ke sesudah `await` di
      `settings_screen.dart`; di `month_picker.dart` ambil `NavigatorState`
      sebelum pop, jangan bawa `context` masuk ke microtask

### 🟡 T-8 — Aksesibilitas nol

Nol pemakaian `Semantics`, `semanticLabel`, atau `excludeSemantics` di seluruh
53 file. Untuk aplikasi yang tayang sebagai web publik, artinya pembaca layar
tidak bisa membacakan grafik `fl_chart`, kartu KPI, maupun progress bar ambang
PKP.

- [ ] **Frontend** — `semanticLabel` untuk semua grafik dan progress bar
      (minimal: bacakan angkanya)
- [ ] **Frontend** — cek target sentuh ≥48dp dan kontras warna di mode terang
      dan gelap. Ini melengkapi tugas "polish UI" Minggu 8, bukan menggantikannya

### 🟡 T-9 — CI tidak menegakkan `dart format`

`analysis_options.yaml` menulis "Jalankan `dart format .` sebelum commit", tapi
tidak ada yang memeriksanya. Format yang tidak konsisten memicu konflik merge
yang sebenarnya tidak perlu — persis hal yang bisa dihindari kalau tim sepakat
soal format sejak awal.

- [ ] **Frontend** — tambahkan langkah `dart format --set-exit-if-changed .` di
      `ci.yml`. Jalankan `dart format .` sekali di seluruh repo lebih dulu
      supaya langkah barunya tidak langsung merah

### ⬜ T-10 — CI tanpa laporan coverage

`flutter test` jalan tanpa `--coverage`, jadi tidak ada yang tahu cakupan tes
naik atau turun antar-PR. Baru benar-benar berguna setelah T-2 selesai.

- [ ] **Frontend** — `flutter test --coverage` dan unggah `lcov.info` sebagai
      artifact CI

### ⬜ T-11 — `flutter_secure_storage` di web perlu diverifikasi

`storage_service.dart:3` menulis token disimpan di "Keychain/Keystore, WebCrypto
di web". Penyimpanan di browser punya model ancaman yang berbeda dari Keychain,
dan itu perlu dipastikan sebelum JWT asli menggantikan data contoh.

- [ ] **Backend + Frontend** — sebelum Minggu 5, sepakati umur token, mekanisme
      refresh, dan apakah refresh token boleh disimpan di browser sama sekali

### ⬜ T-12 — Belum ada kerangka l10n

Semua string Indonesia ditulis langsung di widget; `intl` hanya dipakai untuk
format rupiah dan tanggal. Tidak mendesak selama produk hanya berbahasa
Indonesia, tapi biaya memisahkannya naik terus seiring bertambahnya layar.

- [ ] **Frontend** — ambil keputusan sadar: kalau memang tidak akan multi-bahasa,
      tulis itu di `docs/ARCHITECTURE.md` supaya tidak jadi pertanyaan berulang

---

## Risiko yang sudah diketahui

- **Urutan tidak boleh ditukar** — Minggu 5 (Simulator tarik data asli)
  butuh endpoint agregasi dari Minggu 2 sudah beres. Kalau Minggu 2 molor,
  seluruh Minggu 5–6 ikut molor.
- **Pakar pajak adalah gerbang, bukan penonton** — sign-off Minggu 1 dan
  Minggu 2 wajib tuntas sebelum backend mulai endpoint mesin tarif.
- **Ruang lingkup PPN & SPT Tahunan opsional** — kalau mayoritas pengguna
  target non-PKP, modul ini (Minggu 6) bisa ditunda ke fase berikutnya
  tanpa mengubah tanggal rilis fitur inti.
- **File Flutter original dari user** — belum direview saat dokumen ini
  ditulis; kalau ada perbedaan besar dari `app/lib/` saat ini, jadwal
  Minggu 1–2 frontend perlu ditinjau ulang.

---

## Log Progres

> Tambahkan baris baru di atas (paling baru di atas), format:
> `- **YYYY-MM-DD** — [Nama/Peran] — apa yang selesai/berubah`

- **2026-09-08** — Frontend — **T-15 selesai.** Kelas tipografi `T` di
  `design_tokens.dart` diganti nama jadi `Typo` — 142 pemakaian di 15 berkas —
  lalu parameter generic di `tx_add_sheet.dart` dikembalikan dari `V` ke `T`.
  Ini menghapus tambalan yang dipasang saat menggayakan ulang alur transaksi:
  waktu itu generic-nya yang mengalah, padahal token-lah yang memakai nama
  konvensional milik generic. Sekarang `_DdItem<T>` dan `_SheetDropdown<T>`
  memakai `T` seperti lazimnya, dan `Typo.sans()` tetap resolve di dalamnya.
  `Typo` dipilih agar sebaris dengan `DS`, `Space`, dan `Radii`, sekaligus
  tidak tertukar dengan `AppTextStyles` lama yang masih dipakai layar yang
  belum didesain ulang.
  Nol perubahan perilaku — murni penggantian nama.
  `flutter analyze` → 0 error, 0 warning, 39 info. `flutter test` → 39 lulus,
  1 di-skip. `flutter build web --release` → berhasil.

- **2026-09-08** — Frontend — Alur transaksi diseragamkan gayanya, dan **T-15**
  (baru) dicatat.
  **`tx_form_widgets.dart`** ditulis ulang — ini titik ungkit alur transaksi
  karena dipakai `new_transaction_screen.dart` **dan** `tx_add_sheet.dart`
  sekaligus. `TypeToggle` jadi pil segmented; `AmountInput` memakai pola yang
  sama persis dengan input penghasilan di Simulator (garis bawah warna merek,
  angka besar, tanpa kotak) sehingga "masukkan nominal rupiah" kini satu pola
  di seluruh aplikasi; `CategoryGrid` berubah dari grid rasio 2,8 jadi pil yang
  membungkus dengan target sentuh ≥46; `PaymentMethodPicker` juga — sebelumnya
  padding vertikalnya cuma 7, jauh di bawah ambang target sentuh.
  **`new_transaction_screen.dart`** dan **`tx_detail_screen.dart`** ditulis
  ulang penuh. Di detail, nominal jadi satu angka besar di puncak layar
  alih-alih kartu berwarna, sisanya turun jadi daftar baris berpemisah tipis.
  Konfirmasi hapus tetap inline, bukan dialog — menjaga R-5.
  **`tx_add_sheet.dart`** (770 baris) hanya dipetakan tokennya, tidak ditulis
  ulang: berkas itu memuat `TxEditSheet` dan dropdown generik dengan logika
  sendiri, dan menulis ulangnya utuh berisiko tanpa tes yang menjaganya.
  **T-15 (baru)** — kelas tipografi bernama `T` bentrok dengan parameter
  generic `T` di `tx_add_sheet.dart`. Ditambal dengan mengganti generic-nya
  jadi `V`; nama kelasnya sendiri yang sebaiknya diganti. Lihat entrinya.
  **Emoji sebagai ikon** kategori dan metode bayar dipertahankan — nilainya
  datang dari data (`cat.icon`, `pm.icon`), jadi menggantinya butuh perubahan
  di sisi data, bukan di UI.
  `flutter analyze` → 0 error, 0 warning, 39 info. `flutter test` → 39 lulus,
  1 di-skip. `flutter build web --release` → berhasil.

- **2026-09-08** — Frontend — Lanjutan kerja tanpa ketergantungan Backend/Pakar
  pajak: **T-7** dan **T-6** selesai, **T-8** sebagian, layar auth dan Profil
  usaha diseragamkan gayanya, dan **T-14** (baru) dicatat.
  **T-7** — `month_picker.dart` mengambil `NavigatorState` sebelum `pop()`,
  jadi `context` tidak lagi dibawa masuk ke `Future.microtask` setelah
  route-nya dilepas. Nol `use_build_context_synchronously` tersisa di repo.
  **Layar masuk & daftar** — wordmark masih tertulis "NamaAppmu", sisa scaffold
  yang tidak pernah diganti padahal itu layar pertama yang dilihat siapa pun.
  Sekarang memakai `DsWordmark` yang sama dengan rail navigasi. Keduanya
  memakai `DsField`/`DsButton`, dan form dibatasi 420px lalu ditengahkan di
  layar lebar (sebelumnya membentang penuh).
  **Profil usaha** — ditulis ulang dengan gaya yang sama. Mengikuti R-6, form
  kini terbuka dengan tiga hal (nama usaha, jenis usaha, status PKP); nama
  pemilik, NPWP, dan jumlah karyawan pindah ke "Detail tambahan" yang otomatis
  terbuka kalau sudah terisi atau kalau validasinya gagal. Mode onboarding,
  tombol lewati, formatter NPWP, dan layar sukses semuanya dipertahankan.
  **T-6** — 52 pemakaian `withOpacity` tersisa diganti `withValues(alpha:)` di
  17 berkas. Nol tersisa. Total isu `flutter analyze` turun dari 92 jadi 40.
  **T-8 (sebagian)** — label semantik ditambahkan ke seluruh grafik dan
  indikator yang **benar-benar terjangkau**: empat grafik di tab Total
  Pencatatan, grafik batang skenario, dan progress bar ambang PKP di
  `sim_widgets.dart`. Layar hasil redesain (Dashboard, Simulator, Pengaturan,
  auth, Profil usaha) sudah membawa semantiknya sendiri sejak ditulis.
  **Belum:** pengukuran kontras dan uji pembaca layar sungguhan — keduanya
  perlu perangkat, bukan pembacaan kode.
  **T-14 (baru)** — sepuluh widget dashboard lama (3.225 baris) jadi yatim
  setelah redesain; nol referensi eksternal. Butuh keputusan hapus-atau-tahan,
  dan harus jadi PR tersendiri.
  **T-9 tetap ditahan** sesuai permintaan, dikerjakan setelah semua ini.
  `flutter analyze` → 0 error, 0 warning, 40 info. `flutter test` → 39 lulus,
  1 di-skip. `flutter build web --release` → berhasil.
  **Catatan proses — analyze lokal tidak sama dengan CI.** PR #3 sempat merah
  karena `unnecessary_non_null_assertion` di `simulator_service.dart`, padahal
  `flutter analyze` lokal melaporkan nol warning. Sebabnya beda versi: mesin
  lokal memakai Flutter **3.44.0**, CI memakai **3.44.8**, dan analyzer versi
  baru menaikkan lint itu jadi warning. Karena `ci.yml` memakai
  `--no-fatal-infos`, warning menggagalkan build sementara info tidak — jadi
  "nol warning di lokal" **bukan** jaminan CI hijau. Samakan versi Flutter
  lokal dengan pin CI, atau perlakukan hasil CI sebagai satu-satunya sumber
  kebenaran sebelum menyatakan sebuah PR bersih.

- **2026-09-08** — Frontend — Menyelesaikan tiga temuan yang tidak bergantung
  Backend maupun Pakar pajak: **T-2**, **T-5**, dan **T-13** (baru).
  **T-2** — `test/simulator_service_test.dart` dibuat: 34 tes untuk
  `calculatePPhFinal`, `calculatePPh21`, `buildTerTable`, dan
  `calculateScenarios`. Total tes repo naik dari 5 jadi 39, semuanya lulus.
  Yang diuji sengaja dibatasi pada **konsistensi internal dan sifat
  struktural** — batas lapisan, monotonisitas tarif, jumlah komponen, tepi
  ambang PKP, pembagian nol — bukan kebenaran tarif terhadap peraturan.
  Kebenaran tarif tetap wewenang pakar pajak (T-1, T-3, T-4), dan mengunci
  angkanya di tes justru akan mengabadikan yang mungkin salah. Satu tes sengaja
  di-`skip` sebagai penanda T-1: ia menyatakan dua status di kategori TER
  berbeda tidak boleh menghasilkan tarif sama. Hapus `skip`-nya begitu tabel B
  dan C masuk — itu sekaligus jadi verifikasi perbaikannya.
  **T-13 (baru, ditemukan lewat T-2)** — `buildTerTable()` ternyata menyimpan
  daftar tarif kedua yang ditulis tangan dan sudah menyimpang dari
  `terTableA`: Rp 8 jt ditampilkan 1,5% tapi dihitung 2,0%, Rp 12 jt
  ditampilkan 5,0% tapi dihitung 6,0%, lapisan tertinggi ditulis 19% padahal
  34%. Sekarang diturunkan dari `terTableA` sehingga tidak bisa menyimpang
  lagi. Nol tarif diubah — murni menghapus duplikasi, bukan keputusan pajak.
  Dampak ke pengguna saat ini nihil: `buildTerTable()` cuma dipakai
  `pph21_tab.dart` yang sudah tidak terpasang.
  **T-5** — pemetaan PTKP tidak lagi lewat label tampilan
  (`shortLabel.replaceAll('/','')`). Ditambahkan `ptkpKey` dengan `switch`
  exhaustive, jadi status baru yang belum dipetakan gagal saat compile.
  Nilainya tetap di `AppConstants.ptkp` — menyalinnya ke service akan
  mengulang persis masalah T-13 — dan kelengkapannya dijaga dua tes baru.
  **Belum dikerjakan:** T-9 (`dart format` di CI). `dart format` akan mengubah
  **57 dari 60 berkas**, jadi harus jadi PR tersendiri supaya tidak
  menenggelamkan review. T-6, T-7, T-8, T-10 juga masih terbuka dan semuanya
  tidak terblokir.
  `flutter analyze` → 0 error, 0 warning. `flutter test` → 39 lulus, 1 di-skip.

- **2026-09-08** — Frontend — Tindak lanjut review PR #2: beresi 4 temuan
  prioritas sebelum merge. (1) `regulation_card.dart` — poin **PPN** dan **PPh
  Badan** dicabut dari kartu: tarif PPN sedang bergerak (UU HPP 7/2021 → PMK
  131/2024, konstruksi DPP nilai lain) dan PPh Badan 22% salah sasaran untuk
  UMKM yang dominan WP orang pribadi (yang berlaku tarif Pasal 17 OP). Keduanya
  menunggu angka tertulis dari Pakar Regulasi — sejalan dengan temuan T-3.
  (2) Kata "**tetap**" pada judul PPh Final dibuang, dan body-nya menyebut ada
  syarat jangka waktu serta ambang omzet tidak kena pajak yang belum dirinci;
  `maxLines` body dinaikkan 2 → 3 supaya syaratnya tidak terpotong ellipsis.
  Subtitle jadi "Ringkasan sementara, belum ditinjau pakar pajak". (3) Angka
  kartu **benar-benar** dirangkai dari `AppConstants.pphFinalRate` dan
  `pkpThreshold` lewat helper baru `Pct.id()` dan `Rupiah.miliar()` di
  `core/utils/formatters.dart` — jadi kartu dan Simulator tidak bisa lagi
  menampilkan tarif yang berbeda. Warna chip sekalian dipindah ke getter tema
  (`AppColors.expenseLight/expenseBadgeFg`, `warningLight/warningBadgeFg`)
  karena baris yang sama memang sedang ditulis ulang — sebelumnya literal mode
  terang yang tidak ikut mode Gelap. (4) Dokumentasi mati dibersihkan sesuai
  syarat **M1**: blok "Pustaka peraturan" (±40 baris, 3 endpoint) dan catatan
  "Bookmark peraturan" di `docs/BACKEND.md`, baris fitur di `README.md` +
  tagline-nya, baris fitur & daftar folder `screens/` di
  `docs/ARCHITECTURE.md`, opsi area di `.github/ISSUE_TEMPLATE/feature_request.yml`,
  dan cakupan commit `library` di `CONTRIBUTING.md`. Karena kontraknya sudah
  tidak ada di `BACKEND.md`, `ApiEndpoints.documents*` ikut dicabut dari
  `app_constants.dart` (sebelumnya sengaja ditinggal sebagai kontrak backend).
  **Belum dikerjakan, menyusul:** `StorageKeys.bookmarks` masih ada — mencabutnya
  perlu keputusan migrasi karena build yang sudah tayang menulis id dokumen ke
  `localStorage` pengguna; redirect `/library*` → dashboard + `errorBuilder`
  router; parameter `compact` dan efek hover mati di `_RegItem`. Ketiganya
  masuk daftar temuan audit di atas.

- **2026-09-08** — Frontend — Audit kode `app/lib` (53 file, ±14.546 baris) di
  atas branch `claude/flutter-project-review-plan-pzmo22`; hasilnya jadi bagian
  baru **"Temuan audit kode — usulan perbaikan"** (T-1 s/d T-12) di dokumen ini.
  Tidak ada kode aplikasi yang diubah — bagian ini murni tambahan dokumentasi.
  Basis pemeriksaan: `flutter pub get` bersih, `flutter analyze` → **0 error,
  0 warning, 103 info** (66 `withOpacity` deprecated, 21 `unnecessary_underscores`,
  7 `curly_braces_in_flow_control_structures`, sisanya tersebar). Penghapusan
  Pustaka peraturan terverifikasi bersih — nol referensi menggantung ke
  `library_screen.dart`, `doc_detail_screen.dart`, `bookmark_screen.dart`, atau
  `document_model.dart`.
  **Tiga temuan berprioritas 🔴** yang menyentuh benar-tidaknya angka pajak:
  (T-1) `calculatePPh21()` selalu memakai `terTableA` apa pun status PTKP-nya,
  dan `terTableB`/`terTableC` tidak ada di `app_constants.dart` — jadi status
  seperti K/2 dan K/3 dihitung dengan tarif kategori A. Ini mengonfirmasi tugas
  Minggu 1 pakar pajak yang masih terbuka sebagai bug nyata, bukan sekadar hal
  yang perlu dicek. (T-2) `simulator_service.dart` nol tes — 5 tes yang ada
  semuanya menguji `MockDashboardRepository`, sementara kode kalkulasi pajaknya
  sendiri tidak diuji sama sekali; ini menggantung di depan milestone M4.
  (T-3) `calculatePPhFinal()` belum memodelkan pengecualian omzet Rp500 juta
  pertama untuk WP OP maupun batas jangka waktu PP 23/2018.
  T-1, T-3, dan T-4 **butuh keputusan pakar pajak dulu** sebelum frontend boleh
  menyentuhnya — jangan diimplementasi dari sumber sekunder. Sisanya (T-5 s/d
  T-12) murni frontend dan bisa jalan sekarang: null-assertion rawan crash di
  pemetaan PTKP, dua `BuildContext` lewat async gap, aksesibilitas nol,
  `dart format` tidak ditegakkan CI, dan pembersihan `withOpacity`.
  Usul penjadwalan tiap temuan ada di kolom "Usul masuk" pada tabel ringkasnya —
  perlu dikonfirmasi saat sinkron mingguan, belum disepakati siapa pun.


- **2026-09-07** — Frontend — Selesai 4 tugas frontend Minggu 2 (cabut Pustaka
  peraturan) di `app/lib/` pada branch `fitur/audit-original-flutter-vs-app-lib`:
  (1) hapus `library_screen.dart`, `doc_detail_screen.dart`,
  `bookmark_screen.dart`, `lib_widgets.dart`, `related_docs.dart`,
  `library_service.dart`, `document_model.dart` beserta folder
  `screens/library/` dan `widgets/library/`. (2) Cabut rute `/library`,
  `/library/bookmarks`, `/library/:id` dari `app_router.dart`; cabut
  `AppRoutes.library`/`libDetail` dari `app_constants.dart` (entri
  `ApiEndpoints.documents*` dibiarkan — itu bagian kontrak backend di
  `docs/BACKEND.md`, belum dicabut). (3) Hapus tab & item bottom-nav
  "Perpustakaan" dari `MainShell`, sesuaikan indeks `_tabs`/`_screens`.
  (4) `regulation_card.dart` ditulis ulang jadi kartu statis "Info Pajak
  UMKM" berisi 4 poin inline (PPh Final 0,5%, ambang PKP, PPN 11%, PPh Badan
  22% — ~~dari `AppConstants`~~ **koreksi 8 Sep: angkanya ditulis ulang sebagai
  literal string, berkas ini tidak meng-import `app_constants.dart`; sudah
  dibetulkan, lihat entri 8 Sep di bawah**, bukan input pakar pajak yang belum
  ada);
  `QuickActions` di `deadline_card.dart` kehilangan tombol "Cari Regulasi"
  dan parameter `onLibrary`; 3 titik pemanggilan di `dashboard_screen.dart`
  disesuaikan. `tax_tips_card.dart` tidak disentuh (memang tidak terkopel,
  lihat log Minggu 1). Uji manual: `flutter run -d web-server`, login demo,
  jalan penuh splash → dashboard → pembukuan → simulator → pengaturan →
  notifikasi — nol referensi `/library`, nol network request ke `library`,
  bottom nav cuma 4 tab. Satu `GoException` di console saat boot (sebelum
  login) tidak terkait — tidak menyebut "library", tidak berulang, seluruh
  alur tetap jalan.
  **Efek samping tak terduga:** menghapus `document_model.dart` mematahkan
  build `core/data/` (backend), karena `LibraryRepository` dan 3
  implementasinya (`mock_repositories.dart`, `api_repositories.dart`,
  `hybrid_repositories.dart`) serta `MockData.documents`/`docCategories`
  masih memakai tipe `Document`/`DocCategory`/`DocType`. Supaya branch ini
  tetap bisa di-build, tugas Backend Minggu 2 "cabut method terkait dokumen
  dari `repositories.dart` dan ketiga implementasinya" ikut dikerjakan di
  sini (dicentang di atas). `docs/BACKEND.md` **belum** disentuh — itu masih
  perlu di-cross-check oleh Backend. Test `MockLibraryRepository` di
  `test/widget_test.dart` juga dihapus (target ujinya sudah tidak ada).
  `flutter analyze` → 0 error/warning, `flutter test` → 5/5 lulus.
  ~~Belum di-push~~ — sudah di-push sebagai commit `151df2e` di PR #2
  (branch `claude/flutter-project-review-plan-pzmo22`).

- **2026-09-07** — Frontend — Selesai 4 tugas audit Minggu 1: (1) peta rute
  `/library/*` — `library` → `LibraryScreen` (tab nav), `library/bookmarks` →
  `BookmarkScreen`, `library/:id` → `DocDetailScreen`; `app_router.dart`
  identik byte-per-byte antara kode original user dan `app/lib/`, jadi peta
  ini berlaku untuk keduanya. (2) Widget dashboard yang perlu diganti
  kontennya: `regulation_card.dart` (kopling keras — impor `LibraryService`,
  panggil `getDocuments()`, push ke `/library/:id`) dan `QuickActions` di
  `deadline_card.dart` (callback `onLibrary`); `notification_screen.dart`
  hanya kopling lunak (kategori `NotifType.regulation` berisi notifikasi
  contoh, bukan panggilan service). `tax_tips_card.dart` dan
  `cal_deadline_card.dart` ternyata **tidak** terkopel ke Pustaka
  peraturan — daftar di dokumen ini bisa diabaikan untuk keduanya.
  (3) Diff kode Flutter original user vs `app/lib/`: layar & widget nyaris
  identik (cuma beda `dart format`), tapi lapisan data/servis beda total —
  `app/lib/core/data/` (`repositories.dart` + 3 implementasi mock/api/hybrid)
  dan model yang dipecah per file (`models/*_model.dart`) belum ada sama
  sekali di kode original user; semua service (`accounting_service.dart`,
  `library_service.dart`, dll.) karena itu berbeda besar. Rekomendasi:
  lanjutkan kerja dari `app/lib/` (sudah backend-ready), bukan dari kode
  original user. (4) Branch kerja `fitur/audit-original-flutter-vs-app-lib`
  dibuat; `flutter pub get` bersih, `flutter analyze` di `app/` → 0
  error/warning (120 info pre-existing soal `withOpacity` deprecated, tidak
  terkait audit ini).
