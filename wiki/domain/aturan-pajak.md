---
title: Aturan Pajak yang Dipakai Catatin
description: Aturan dan batasan PPh Final 0,5% (PP 23/2018), PPh 21 TER (PMK 168/2023), PTKP, PPN, simulasi skenario, kalender jatuh tempo, bug tarif yang diketahui, dan rencana konfigurasi tarif berversi.
tags:
  - domain
  - pajak
---

Seluruh perhitungan pajak Catatin hidup di satu berkas:
`app/lib/core/services/simulator_service.dart` (415 baris), dengan konstantanya
di `app/lib/core/constants/app_constants.dart`. Tidak ada satu pun layar yang
memuat tarif atau rumus sendiri — itu keputusan sadar, supaya kesalahan tarif
tinggal di satu tempat dan tidak ikut tersalin.

Halaman ini menjelaskan **aturan dan batasannya**. Untuk angka yang
sesungguhnya, kodenya adalah sumber kebenaran (alasannya di
[Kenapa halaman ini tidak menyalin tabel TER](#kenapa-halaman-ini-tidak-menyalin-tabel-ter)).

> **Bukan nasihat pajak.** Catatin adalah alat bantu hitung. Angka yang
> dikeluarkannya belum divalidasi terhadap kalkulator resmi DJP — validasi itu
> adalah milestone **M4** yang belum tercapai. Bug tarif yang sudah
> diketahui ada di bagian [Yang belum benar](#yang-belum-benar).

---

## 1. PPh Final 0,5% — PP 23/2018

Skema pajak penghasilan final untuk UMKM: tarifnya rata 0,5% dari **peredaran
bruto** (omzet), bukan dari laba.

| Hal | Nilai | Konstanta |
| --- | --- | --- |
| Tarif | 0,5% | `AppConstants.pphFinalRate` |
| Ambang omzet | Rp 4,8 miliar/tahun | `AppConstants.pkpThreshold` |

Cara Catatin menghitungnya (`calculatePPhFinal()`):

- Omzet tahunan diestimasi sebagai **omzet bulanan × 12** — bukan penjumlahan
  transaksi riil. Ini estimasi proyektif, bukan pelaporan.
- Wajib pajak dianggap masih berhak skema final selama
  `omzet tahunan ≤ Rp 4,8 M`. Tepat **di** ambang masih berhak.
- Pajaknya `omzet × 0,5%`, dikenakan dari rupiah pertama.

### Penanda ambang PKP

Dashboard menampilkan progres menuju ambang Rp 4,8 M dengan dua batas:

| Kondisi | Penanda |
| --- | --- |
| ≥ 80% ambang | `isPkpWarning` — peringatan |
| ≥ 95% ambang | `isPkpDanger` — bahaya |

Persentasenya dibatasi maksimum 100 walau omzet jauh melewatinya, supaya bar
progres tidak meluber.

---

## 2. PPh 21 Karyawan — metode TER, PMK 168/2023

TER (Tarif Efektif Rata-rata) menyederhanakan pemotongan PPh 21 bulanan:
satu tarif dikalikan gaji kotor, tanpa menghitung PKP tiap bulan.

Cara Catatin menghitungnya (`calculatePPh21()`):

- Cari lapisan TER pertama yang `gaji kotor ≤ max`, ambil `rate`-nya.
- `pajak bulanan = gaji kotor × rate`
- `gaji bersih = gaji kotor − pajak bulanan`
- `pajak tahunan (estimasi) = pajak bulanan × 12`

### PTKP 2026

Penghasilan Tidak Kena Pajak, delapan status. Nilai di bawah adalah **salinan
untuk dibaca manusia** — sumber kebenarannya `AppConstants.ptkp`. Kalau keduanya
berbeda, kodenya yang benar.

| Status | Arti | PTKP setahun |
| --- | --- | --- |
| TK/0 | Tidak kawin, 0 tanggungan | Rp 54.000.000 |
| TK/1 | Tidak kawin, 1 tanggungan | Rp 58.500.000 |
| TK/2 | Tidak kawin, 2 tanggungan | Rp 63.000.000 |
| TK/3 | Tidak kawin, 3 tanggungan | Rp 67.500.000 |
| K/0 | Kawin, 0 tanggungan | Rp 58.500.000 |
| K/1 | Kawin, 1 tanggungan | Rp 63.000.000 |
| K/2 | Kawin, 2 tanggungan | Rp 67.500.000 |
| K/3 | Kawin, 3 tanggungan | Rp 72.000.000 |

Catatan: PKP yang ditampilkan di layar dihitung `(gaji kotor × 12) − PTKP`,
dibatasi minimum nol. Angka ini **tidak** dipakai untuk menghitung pajak —
metode TER tidak memerlukannya. Kehadirannya di layar justru menyesatkan; itu
temuan [T-4](../proyek/backlog-teknis.md).

---

## 3. PPN — 11%

`AppConstants.ppnRate = 0.11`. Hanya dikenakan kalau profil usaha ditandai
**PKP**. Non-PKP mendapat PPN nol, bukan PPN yang disembunyikan.

Dalam simulasi skenario, PPN dihitung `omzet tahunan × 11%` — penyederhanaan
kasar, karena PPN sesungguhnya adalah selisih pajak keluaran dan masukan.

---

## 4. Simulasi skenario

`calculateScenarios()` menghasilkan tepat tiga skenario dari satu masukan:

| Skenario | Pengali omzet | Unggulan |
| --- | --- | --- |
| Konservatif | 0,70× | — |
| Base Case | 1,00× | ✔ |
| Optimistis | 1,40× | — |

Untuk tiap skenario: `total pajak = PPh Final + (PPh 21 per karyawan × jumlah
karyawan) + PPN`, lalu `tarif efektif = total pajak ÷ omzet tahunan`.

Perilaku penting: skenario yang omzetnya **melewati** ambang Rp 4,8 M
mendapat PPh Final **nol**, bukan tetap dihitung 0,5%. Ini disengaja — begitu
tidak berhak skema final, tarif finalnya tidak berlaku sama sekali. Skema
penggantinya (tarif umum) belum dimodelkan.

---

## 5. Kalender jatuh tempo

`generateCalendar()` membangkitkan tenggat setahun penuh:

| Jenis | Jatuh tempo | Syarat |
| --- | --- | --- |
| PPh Final Masa | tanggal **15** bulan berikutnya | selalu |
| PPh 21 Masa | tanggal **10** bulan berikutnya | punya karyawan |
| PPN Masa | tanggal **30** bulan berikutnya | berstatus PKP |
| SPT Tahunan PPh OP | **30 April** tahun berikutnya | selalu |

Status tiap tenggat: `overdue` (lewat), `urgent` (≤ 7 hari), `warning`
(≤ 30 hari), `upcoming` (sisanya).

---

## Yang belum benar

Temuan yang sudah dikonfirmasi. Semuanya wajib beres sebelum milestone
**M4** (validasi terhadap kalkulator resmi DJP):

- **[T-1](../proyek/backlog-teknis.md) — kategori TER B & C tidak ada.**
  `app_constants.dart` hanya punya `terTableA`. Apa pun status PTKP yang
  dipilih pengguna, tarif yang dipakai selalu kategori A. Pengguna berstatus
  K/2 atau K/3 mendapat angka yang salah.
- **[T-3](../proyek/backlog-teknis.md) — PPh Final belum lengkap.**
  Pengecualian omzet Rp 500 juta pertama untuk WP orang pribadi dan batas
  jangka waktu pemakaian tarif PP 23/2018 sama-sekali belum dimodelkan.
  Tidak ada input "sejak tahun berapa".
- **Tabel TER kategori A sendiri tidak sesuai tabel resmi.** Ditemukan
  18 Sep 2026 saat audit TAX terhadap PMK 168/2023: tabel resmi punya
  44 lapisan, `terTableA` punya 32, dan 28 di antaranya salah tarif atau salah
  batas. Dua belas lapisan teratas hilang. Rinciannya, berikut tabel resmi
  penggantinya, ada di
  [Spesifikasi PPh 21 TER](pajak/spek-pph21-ter.md#8-temuan-audit-terhadap-kode-saat-ini).
- **Tenggat SPT Tahunan PPh Orang Pribadi salah.** `generateCalendar()`
  memakai 30 April; yang benar 31 Maret
  ([Spek PPh Final §6](pajak/spek-pph-final-umkm.md#6-tenggat-pelaporan-d-12)).

**Aturan kerja untuk semuanya:** jangan mengimplementasikan dari sumber
sekunder. Tabel resmi harus datang dari pakar regulasi DJP & Kemenkeu — satu
tarif salah membuat seluruh hasil validasi M4 ikut salah.

### Konstanta yang menganggur

`AppConstants.pphBadanRate` (22%) dideklarasikan tapi **tidak dipanggil di mana
pun**. Entah PPh Badan memang belum dikerjakan, atau konstanta ini sisa rencana
yang batal. Perlu diputuskan sebelum ia dikira sudah berfungsi.

---

## Kenapa halaman ini tidak menyalin tabel TER

Tabel TER kategori A punya 32 lapisan dan seluruhnya ada di
`AppConstants.terTableA`. Halaman ini **sengaja tidak menyalinnya**.

Alasannya sudah terbukti mahal sekali di proyek ini. Temuan
[T-13](../proyek/backlog-teknis.md): `buildTerTable()` dulu menyimpan daftar
tarif kedua yang ditulis tangan, dan daftar itu menyimpang dari tabel yang
dipakai menghitung — gaji Rp 8 juta ditampilkan 1,5% padahal dihitung 2,0%,
dan lapisan tertinggi ditulis 19% padahal 34%. Pengguna bisa melihat satu tarif
sementara rupiah di layar yang sama dihitung dengan tarif lain.

Menyalin 32 baris itu ke wiki akan mengulang persis kesalahan yang sama, hanya
di tempat yang lebih sulit diuji. Satu daftar, di `app_constants.dart`, dijaga
tes.

---

## Rencana: angka pindah ke konfigurasi berversi

Konstanta di `app_constants.dart` direncanakan pindah ke tabel konfigurasi pajak
berversi di database, supaya pakar pajak bisa memperbarui angka tanpa rilis
aplikasi. Drafnya — tabel `tax_rates`, `ptkp`, versi yang dikunci setelah
disetujui, dan hanya peran TAX yang boleh menulis — ada di
[Backend & API §7](../arsitektur/backend-dan-api.md#7-skema-mesin-tarif-pajak-draf-untuk-review-tax)
dan menunggu review pakar pajak. Draf itu juga tidak memuat angka: aturan "satu
daftar, dijaga tes" di atas tetap berlaku, hanya tempat daftarnya yang berpindah.
Sampai migrasinya diterapkan, kode di `simulator_service.dart` tetap sumber
kebenaran.

---

## Halaman terkait

- [Spesifikasi PPh 21 TER](pajak/spek-pph21-ter.md) — tabel TER resmi milik TAX.
- [Spesifikasi PPh Final UMKM](pajak/spek-pph-final-umkm.md) — spesifikasi TAX.
- [Glosarium](glosarium.md) — arti PKP, PTKP, TER, HPP, dan istilah lain.
- [Backlog teknis](../proyek/backlog-teknis.md) — temuan T-1, T-3, T-4, T-13 selengkapnya.
- [Arsitektur](../arsitektur/gambaran-umum.md) — di mana mesin pajak duduk dalam lapisan aplikasi.
