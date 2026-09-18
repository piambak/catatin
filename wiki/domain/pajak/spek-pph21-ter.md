---
title: Spesifikasi PPh Pasal 21 — Metode TER
description: Spesifikasi TAX untuk pemotongan PPh Pasal 21 pegawai tetap dengan tarif efektif rata-rata (TER) — pemetaan status PTKP ke kategori, tabel TER bulanan A/B/C, TER harian, perlakuan masa pajak terakhir, dan aturan tampilan.
tags:
  - domain
  - pajak
  - spesifikasi
---

**Pemilik dokumen:** TAX (Pakar Regulasi DJP & Kemenkeu).
**Status:** draf Minggu 1, dikunci untuk M0 — angka TER sudah bersumber, item
bertanda `[CEK]` belum.
**Sumber angka:** [Slide sosialisasi PMK 168/2023](../../sumber/pmk-168-2023-slide-ter.md)
yang diserahkan TAX pada 18 September 2026.
**Berlaku sejak:** 1 Januari 2024 (PP 58/2023 dinyatakan berlaku pada tanggal itu
di sumber; nomor pasal PMK 168/2023 untuk tiap ketentuan `[CEK]`).

Dokumen ini adalah **sumber angka milik TAX**. Backend memuatnya ke tabel
konfigurasi berversi ([Backend & API §7](../../arsitektur/backend-dan-api.md#7-skema-mesin-tarif-pajak-draf-untuk-review-tax));
frontend memakainya lewat `AppConstants`. Kalau ketiganya berbeda, **dokumen ini
yang benar**.

---

## 1. Lingkup

Spesifikasi ini mengatur pemotongan PPh Pasal 21 yang disimulasikan Catatin:
pegawai tetap dengan penghasilan teratur, dihitung per masa pajak selain masa
pajak terakhir. Perlakuan masa pajak terakhir ada di §6; penerima penghasilan
selain pegawai tetap ada di §7.

## 2. Dasar pengenaan dan rumus per masa

Untuk masa pajak Januari sampai November:

```text
PPh Pasal 21 sebulan = penghasilan bruto sebulan x tarif efektif bulanan
```

Penghasilan bruto sebulan adalah seluruh penghasilan pegawai tetap dalam satu
bulan digabung — gaji, tunjangan, tunjangan hari raya, bonus, uang lembur, dan
premi JKK/JKM yang dibayar pemberi kerja termasuk di dalamnya.

Tidak ada pengurang apa pun pada perhitungan masa: biaya jabatan, iuran pensiun,
PTKP, dan zakat **tidak** mengurangi dasar pengenaan bulanan. Ketiganya baru
muncul pada masa pajak terakhir (§6). Status PTKP tetap dibutuhkan, tetapi hanya
untuk **memilih kategori tarif** (§3), bukan sebagai pengurang.

## 3. Pemetaan status PTKP ke kategori TER

| Kategori | Status PTKP | PTKP setahun |
| --- | --- | --- |
| A | TK/0 | Rp 54.000.000 |
| A | TK/1, K/0 | Rp 58.500.000 |
| B | TK/2, K/1 | Rp 63.000.000 |
| B | TK/3, K/2 | Rp 67.500.000 |
| C | K/3 | Rp 72.000.000 |

Delapan status PTKP, tiga kategori tarif. Kategori C hanya dipakai satu status.

## 4. Tabel TER bulanan

**Bentuk normatif tabel ini adalah [`ter-bulanan.csv`](ter-bulanan.csv)**
(125 baris: A 44 lapisan, B 40 lapisan, C 41 lapisan). Tabel di bawah dan potongan
Dart di §9 adalah penyajian ulang dari berkas itu. Kalau ada selisih, berkas CSV
yang benar — aturan ini dipasang karena temuan
[T-13](../../proyek/backlog-teknis.md): dua daftar tarif yang ditulis terpisah
pernah menyimpang dan membuat layar menampilkan tarif yang berbeda dari yang
dipakai menghitung.

Batas lapisan bersifat **inklusif di kedua ujung** sebagaimana tertulis di sumber
(lapisan berikutnya mulai dari batas atas sebelumnya ditambah satu rupiah).
Pencarian lapisan memakai `penghasilan bruto <= batas atas` pada daftar menaik —
bentuk ini identik dengan `(batas_bawah, batas_atas]` yang dipakai skema backend.

### 4.1 Kategori A

| Lapisan | Penghasilan bruto sebulan (Rp) | Tarif |
| ---: | --- | ---: |
| 1 | sampai dengan 5.400.000 | 0,00% |
| 2 | 5.400.001 s.d. 5.650.000 | 0,25% |
| 3 | 5.650.001 s.d. 5.950.000 | 0,50% |
| 4 | 5.950.001 s.d. 6.300.000 | 0,75% |
| 5 | 6.300.001 s.d. 6.750.000 | 1,00% |
| 6 | 6.750.001 s.d. 7.500.000 | 1,25% |
| 7 | 7.500.001 s.d. 8.550.000 | 1,50% |
| 8 | 8.550.001 s.d. 9.650.000 | 1,75% |
| 9 | 9.650.001 s.d. 10.050.000 | 2,00% |
| 10 | 10.050.001 s.d. 10.350.000 | 2,25% |
| 11 | 10.350.001 s.d. 10.700.000 | 2,50% |
| 12 | 10.700.001 s.d. 11.050.000 | 3,00% |
| 13 | 11.050.001 s.d. 11.600.000 | 3,50% |
| 14 | 11.600.001 s.d. 12.500.000 | 4,00% |
| 15 | 12.500.001 s.d. 13.750.000 | 5,00% |
| 16 | 13.750.001 s.d. 15.100.000 | 6,00% |
| 17 | 15.100.001 s.d. 16.950.000 | 7,00% |
| 18 | 16.950.001 s.d. 19.750.000 | 8,00% |
| 19 | 19.750.001 s.d. 24.150.000 | 9,00% |
| 20 | 24.150.001 s.d. 26.450.000 | 10,00% |
| 21 | 26.450.001 s.d. 28.000.000 | 11,00% |
| 22 | 28.000.001 s.d. 30.050.000 | 12,00% |
| 23 | 30.050.001 s.d. 32.400.000 | 13,00% |
| 24 | 32.400.001 s.d. 35.400.000 | 14,00% |
| 25 | 35.400.001 s.d. 39.100.000 | 15,00% |
| 26 | 39.100.001 s.d. 43.850.000 | 16,00% |
| 27 | 43.850.001 s.d. 47.800.000 | 17,00% |
| 28 | 47.800.001 s.d. 51.400.000 | 18,00% |
| 29 | 51.400.001 s.d. 56.300.000 | 19,00% |
| 30 | 56.300.001 s.d. 62.200.000 | 20,00% |
| 31 | 62.200.001 s.d. 68.600.000 | 21,00% |
| 32 | 68.600.001 s.d. 77.500.000 | 22,00% |
| 33 | 77.500.001 s.d. 89.000.000 | 23,00% |
| 34 | 89.000.001 s.d. 103.000.000 | 24,00% |
| 35 | 103.000.001 s.d. 125.000.000 | 25,00% |
| 36 | 125.000.001 s.d. 157.000.000 | 26,00% |
| 37 | 157.000.001 s.d. 206.000.000 | 27,00% |
| 38 | 206.000.001 s.d. 337.000.000 | 28,00% |
| 39 | 337.000.001 s.d. 454.000.000 | 29,00% |
| 40 | 454.000.001 s.d. 550.000.000 | 30,00% |
| 41 | 550.000.001 s.d. 695.000.000 | 31,00% |
| 42 | 695.000.001 s.d. 910.000.000 | 32,00% |
| 43 | 910.000.001 s.d. 1.400.000.000 | 33,00% |
| 44 | lebih dari 1.400.000.000 | 34,00% |

### 4.2 Kategori B

| Lapisan | Penghasilan bruto sebulan (Rp) | Tarif |
| ---: | --- | ---: |
| 1 | sampai dengan 6.200.000 | 0,00% |
| 2 | 6.200.001 s.d. 6.500.000 | 0,25% |
| 3 | 6.500.001 s.d. 6.850.000 | 0,50% |
| 4 | 6.850.001 s.d. 7.300.000 | 0,75% |
| 5 | 7.300.001 s.d. 9.200.000 | 1,00% |
| 6 | 9.200.001 s.d. 10.750.000 | 1,50% |
| 7 | 10.750.001 s.d. 11.250.000 | 2,00% |
| 8 | 11.250.001 s.d. 11.600.000 | 2,50% |
| 9 | 11.600.001 s.d. 12.600.000 | 3,00% |
| 10 | 12.600.001 s.d. 13.600.000 | 4,00% |
| 11 | 13.600.001 s.d. 14.950.000 | 5,00% |
| 12 | 14.950.001 s.d. 16.400.000 | 6,00% |
| 13 | 16.400.001 s.d. 18.450.000 | 7,00% |
| 14 | 18.450.001 s.d. 21.850.000 | 8,00% |
| 15 | 21.850.001 s.d. 26.000.000 | 9,00% |
| 16 | 26.000.001 s.d. 27.700.000 | 10,00% |
| 17 | 27.700.001 s.d. 29.350.000 | 11,00% |
| 18 | 29.350.001 s.d. 31.450.000 | 12,00% |
| 19 | 31.450.001 s.d. 33.950.000 | 13,00% |
| 20 | 33.950.001 s.d. 37.100.000 | 14,00% |
| 21 | 37.100.001 s.d. 41.100.000 | 15,00% |
| 22 | 41.100.001 s.d. 45.800.000 | 16,00% |
| 23 | 45.800.001 s.d. 49.500.000 | 17,00% |
| 24 | 49.500.001 s.d. 53.800.000 | 18,00% |
| 25 | 53.800.001 s.d. 58.500.000 | 19,00% |
| 26 | 58.500.001 s.d. 64.000.000 | 20,00% |
| 27 | 64.000.001 s.d. 71.000.000 | 21,00% |
| 28 | 71.000.001 s.d. 80.000.000 | 22,00% |
| 29 | 80.000.001 s.d. 93.000.000 | 23,00% |
| 30 | 93.000.001 s.d. 109.000.000 | 24,00% |
| 31 | 109.000.001 s.d. 129.000.000 | 25,00% |
| 32 | 129.000.001 s.d. 163.000.000 | 26,00% |
| 33 | 163.000.001 s.d. 211.000.000 | 27,00% |
| 34 | 211.000.001 s.d. 374.000.000 | 28,00% |
| 35 | 374.000.001 s.d. 459.000.000 | 29,00% |
| 36 | 459.000.001 s.d. 555.000.000 | 30,00% |
| 37 | 555.000.001 s.d. 704.000.000 | 31,00% |
| 38 | 704.000.001 s.d. 957.000.000 | 32,00% |
| 39 | 957.000.001 s.d. 1.405.000.000 | 33,00% |
| 40 | lebih dari 1.405.000.000 | 34,00% |

### 4.3 Kategori C

| Lapisan | Penghasilan bruto sebulan (Rp) | Tarif |
| ---: | --- | ---: |
| 1 | sampai dengan 6.600.000 | 0,00% |
| 2 | 6.600.001 s.d. 6.950.000 | 0,25% |
| 3 | 6.950.001 s.d. 7.350.000 | 0,50% |
| 4 | 7.350.001 s.d. 7.800.000 | 0,75% |
| 5 | 7.800.001 s.d. 8.850.000 | 1,00% |
| 6 | 8.850.001 s.d. 9.800.000 | 1,25% |
| 7 | 9.800.001 s.d. 10.950.000 | 1,50% |
| 8 | 10.950.001 s.d. 11.200.000 | 1,75% |
| 9 | 11.200.001 s.d. 12.050.000 | 2,00% |
| 10 | 12.050.001 s.d. 12.950.000 | 3,00% |
| 11 | 12.950.001 s.d. 14.150.000 | 4,00% |
| 12 | 14.150.001 s.d. 15.550.000 | 5,00% |
| 13 | 15.550.001 s.d. 17.050.000 | 6,00% |
| 14 | 17.050.001 s.d. 19.500.000 | 7,00% |
| 15 | 19.500.001 s.d. 22.700.000 | 8,00% |
| 16 | 22.700.001 s.d. 26.600.000 | 9,00% |
| 17 | 26.600.001 s.d. 28.100.000 | 10,00% |
| 18 | 28.100.001 s.d. 30.100.000 | 11,00% |
| 19 | 30.100.001 s.d. 32.600.000 | 12,00% |
| 20 | 32.600.001 s.d. 35.400.000 | 13,00% |
| 21 | 35.400.001 s.d. 38.900.000 | 14,00% |
| 22 | 38.900.001 s.d. 43.000.000 | 15,00% |
| 23 | 43.000.001 s.d. 47.400.000 | 16,00% |
| 24 | 47.400.001 s.d. 51.200.000 | 17,00% |
| 25 | 51.200.001 s.d. 55.800.000 | 18,00% |
| 26 | 55.800.001 s.d. 60.400.000 | 19,00% |
| 27 | 60.400.001 s.d. 66.700.000 | 20,00% |
| 28 | 66.700.001 s.d. 74.500.000 | 21,00% |
| 29 | 74.500.001 s.d. 83.200.000 | 22,00% |
| 30 | 83.200.001 s.d. 95.600.000 | 23,00% |
| 31 | 95.600.001 s.d. 110.000.000 | 24,00% |
| 32 | 110.000.001 s.d. 134.000.000 | 25,00% |
| 33 | 134.000.001 s.d. 169.000.000 | 26,00% |
| 34 | 169.000.001 s.d. 221.000.000 | 27,00% |
| 35 | 221.000.001 s.d. 390.000.000 | 28,00% |
| 36 | 390.000.001 s.d. 463.000.000 | 29,00% |
| 37 | 463.000.001 s.d. 561.000.000 | 30,00% |
| 38 | 561.000.001 s.d. 709.000.000 | 31,00% |
| 39 | 709.000.001 s.d. 965.000.000 | 32,00% |
| 40 | 965.000.001 s.d. 1.419.000.000 | 33,00% |
| 41 | lebih dari 1.419.000.000 | 34,00% |

## 5. TER harian — pegawai tidak tetap

Dipakai untuk penghasilan yang **tidak** dibayarkan bulanan:

| Penghasilan bruto sehari | Perlakuan |
| --- | --- |
| sampai dengan Rp 450.000 | 0% x penghasilan bruto harian |
| di atas Rp 450.000 s.d. Rp 2.500.000 | 0,5% x penghasilan bruto harian |
| di atas Rp 2.500.000 | tarif Pasal 17 x 50% x penghasilan bruto |

Kalau penghasilan pegawai tidak tetap dibayarkan bulanan, yang berlaku adalah
tarif efektif bulanan (§4), bukan tabel harian ini.

**Keputusan lingkup:** pegawai tidak tetap **tidak** disimulasikan Catatin pada
Fase Dua — Simulator hanya memodelkan pegawai tetap. Tabel ini dicatat supaya
batas lingkupnya eksplisit dan tidak diisi diam-diam dengan tarif bulanan.

## 6. Masa pajak terakhir (Desember)

Pada masa pajak terakhir, PPh Pasal 21 tidak dihitung dengan TER:

```text
PPh Pasal 21 setahun = (penghasilan bruto setahun
                        - biaya jabatan/pensiun
                        - iuran pensiun
                        - zakat/sumbangan keagamaan wajib lewat pemberi kerja
                        - PTKP) x tarif Pasal 17

PPh Pasal 21 masa terakhir = PPh Pasal 21 setahun
                             - PPh Pasal 21 yang sudah dipotong masa sebelumnya
```

Tarif Pasal 17 ayat (1) huruf a UU PPh, sesuai sumber:

| Lapisan penghasilan kena pajak | Tarif |
| --- | ---: |
| sampai dengan Rp 60.000.000 | 5% |
| di atas Rp 60.000.000 s.d. Rp 250.000.000 | 15% |
| di atas Rp 250.000.000 s.d. Rp 500.000.000 | 25% |
| di atas Rp 500.000.000 s.d. Rp 5.000.000.000 | 30% |
| di atas Rp 5.000.000.000 | 35% |

**Besaran biaya jabatan dan batas atasnya: TIDAK ADA DASAR DI SUMBER YANG
TERSEDIA.** Slide yang diserahkan menyebut biaya jabatan/pensiun sebagai
pengurang pada masa pajak terakhir, tetapi tidak memuat persentase maupun
batasnya. Angka itu harus datang dari PMK 168/2023 atau peraturan pelaksananya
sebelum rekalkulasi Desember boleh diimplementasi — lihat
[T-4](../../proyek/backlog-teknis.md) dan daftar `[CEK]` di §11.

**Konsekuensi untuk Fase Dua:** selama biaya jabatan belum bersumber, Simulator
hanya boleh menyimulasikan masa Januari–November dan wajib menyatakan batas itu
di layar (§7).

## 7. Aturan tampilan (D-10)

Yang **wajib** tampil pada hasil PPh 21:

1. Kategori TER yang dipakai (A, B, atau C) beserta status PTKP yang memilihnya.
2. Tarif efektif yang dipakai, dalam persen, sama persis dengan yang dipakai menghitung.
3. Penanda periode: hasil berlaku untuk masa Januari–November, bukan pajak setahun.

Yang **dilarang** tampil:

1. **Angka "PKP" pada layar PPh 21.** Layar sekarang menghitung
   `(gaji kotor x 12) - PTKP` dan menampilkannya, padahal metode TER tidak
   memakai PKP sama sekali dan angka itu tidak dipakai menghitung apa pun. Ini
   temuan [T-4](../../proyek/backlog-teknis.md): angka yang benar secara aritmetika
   tetapi menyesatkan secara pajak. Hapus dari layar.
2. **"Pajak tahunan" hasil `pajak bulanan x 12`.** Ekstrapolasi itu bukan PPh
   Pasal 21 setahun — PPh setahun dihitung dengan tarif Pasal 17 atas dasar
   pengenaan yang berbeda (§6). Kalau angka tahunan tetap ingin ditampilkan, ia
   harus diberi label "estimasi proyektif, bukan PPh Pasal 21 terutang setahun".
3. Tarif yang berasal dari daftar selain [`ter-bulanan.csv`](ter-bulanan.csv).

## 8. Temuan audit terhadap kode saat ini

Diaudit terhadap `app/lib/core/constants/app_constants.dart` (revisi `main`,
18 September 2026).

**Temuan 1 — kategori B dan C tidak ada.** Kode hanya memuat `terTableA`, dan
`calculatePPh21()` memakainya untuk semua status PTKP. Pegawai berstatus TK/2,
K/1, TK/3, K/2, dan K/3 dihitung dengan tabel yang bukan haknya. Ini
[T-1](../../proyek/backlog-teknis.md) sebagaimana sudah tercatat.

**Temuan 2 — `terTableA` sendiri tidak sesuai tabel resmi.** Ini belum tercatat
di backlog dan lebih berat daripada Temuan 1. Tabel resmi kategori A punya
**44 lapisan**; kode punya **32**. Dari 32 lapisan yang ada, **28 lapisan
salah tarif atau salah batas**. Dua belas lapisan teratas tabel resmi
(Rp 62.200.001 sampai Rp 1.400.000.000, tarif 21% sampai 33%) tidak ada sama
sekali — kode melompat dari batas Rp 62.200.000 ke Rp 74.750.000 pada 33%, lalu
langsung ke tarif tertinggi 34%.

Akibatnya bukan selisih kecil. Contoh, penghasilan bruto Rp 20.000.000 sebulan
(kategori A): tarif resmi 9,00% → Rp 1.800.000; kode memakai 11,00% →
Rp 2.200.000. Selisih Rp 400.000 sebulan pada satu pegawai, dan arah selisihnya
tidak konsisten di seluruh tabel.

Perbandingan lapisan per lapisan:

| Lapisan di kode | `max` | Tarif di kode | Tarif resmi | Status |
| ---: | ---: | ---: | ---: | --- |
| 1 | 5.400.000 | 0,00% | 0,00% | sesuai |
| 2 | 5.650.000 | 0,50% | 0,25% | **salah** |
| 3 | 5.950.000 | 0,50% | 0,50% | sesuai |
| 4 | 6.300.000 | 0,50% | 0,75% | **salah** |
| 5 | 6.750.000 | 1,00% | 1,00% | sesuai |
| 6 | 7.500.000 | 1,50% | 1,25% | **salah** |
| 7 | 8.550.000 | 2,00% | 1,50% | **salah** |
| 8 | 9.650.000 | 2,50% | 1,75% | **salah** |
| 9 | 10.050.000 | 3,00% | 2,00% | **salah** |
| 10 | 10.350.000 | 3,50% | 2,25% | **salah** |
| 11 | 10.700.000 | 4,00% | 2,50% | **salah** |
| 12 | 11.050.000 | 5,00% | 3,00% | **salah** |
| 13 | 11.600.000 | 5,00% | 3,50% | **salah** |
| 14 | 12.500.000 | 6,00% | 4,00% | **salah** |
| 15 | 13.750.000 | 7,00% | 5,00% | **salah** |
| 16 | 15.100.000 | 8,00% | 6,00% | **salah** |
| 17 | 16.950.000 | 9,00% | 7,00% | **salah** |
| 18 | 19.750.000 | 10,00% | 8,00% | **salah** |
| 19 | 24.150.000 | 11,00% | 9,00% | **salah** |
| 20 | 26.450.000 | 15,00% | 10,00% | **salah** |
| 21 | 28.000.000 | 17,00% | 11,00% | **salah** |
| 22 | 30.050.000 | 19,00% | 12,00% | **salah** |
| 23 | 32.400.000 | 21,00% | 13,00% | **salah** |
| 24 | 35.400.000 | 23,00% | 14,00% | **salah** |
| 25 | 39.100.000 | 25,00% | 15,00% | **salah** |
| 26 | 43.850.000 | 27,00% | 16,00% | **salah** |
| 27 | 47.800.000 | 29,00% | 17,00% | **salah** |
| 28 | 51.400.000 | 30,00% | 18,00% | **salah** |
| 29 | 56.300.000 | 31,00% | 19,00% | **salah** |
| 30 | 62.200.000 | 32,00% | 20,00% | **salah** |
| 31 | 74.750.000 | 33,00% | — (batas ini tidak ada di tabel resmi) | **salah** |
| 32 | (tanpa batas) | 34,00% | 34,00% | sesuai |

**Konsekuensi:** sebelum tabel di §4 dipasang, tidak ada gunanya menjalankan
validasi M4 terhadap kalkulator resmi DJP — hasilnya pasti tidak cocok.
Perbaikan ini memblokir [T-1](../../proyek/backlog-teknis.md) dan
[#22](kasus-pph21.csv).

## 9. Bentuk siap pakai untuk frontend

Penyajian ulang [`ter-bulanan.csv`](ter-bulanan.csv) dalam bentuk yang dipakai
`AppConstants`. Bentuk `max`/`rate` yang ada sekarang dipertahankan supaya
`calculatePPh21()` tidak perlu berubah strukturnya — yang berubah hanya isi
daftar, penambahan dua tabel, dan pemilihan tabel berdasarkan status PTKP.

**Syarat pemasangan:** tambahkan tes yang membaca `ter-bulanan.csv` dan
membandingkannya baris per baris dengan ketiga konstanta di bawah. Tanpa tes itu,
duplikasi ini mengulang [T-13](../../proyek/backlog-teknis.md).

```dart
  // ── TER bulanan PMK 168/2023 ──
  // Sumber: wiki/domain/pajak/ter-bulanan.csv (normatif).
  // Jangan sunting angka di sini tanpa mengubah berkas itu lebih dulu.

  static const terCategoryByPtkp = {
    'TK0': 'A', 'TK1': 'A', 'K0': 'A',
    'TK2': 'B', 'K1': 'B', 'TK3': 'B', 'K2': 'B',
    'K3': 'C',
  };

  static const terTableA = [
    {'max': 5400000.0, 'rate': 0.0000},
    {'max': 5650000.0, 'rate': 0.0025},
    {'max': 5950000.0, 'rate': 0.0050},
    {'max': 6300000.0, 'rate': 0.0075},
    {'max': 6750000.0, 'rate': 0.0100},
    {'max': 7500000.0, 'rate': 0.0125},
    {'max': 8550000.0, 'rate': 0.0150},
    {'max': 9650000.0, 'rate': 0.0175},
    {'max': 10050000.0, 'rate': 0.0200},
    {'max': 10350000.0, 'rate': 0.0225},
    {'max': 10700000.0, 'rate': 0.0250},
    {'max': 11050000.0, 'rate': 0.0300},
    {'max': 11600000.0, 'rate': 0.0350},
    {'max': 12500000.0, 'rate': 0.0400},
    {'max': 13750000.0, 'rate': 0.0500},
    {'max': 15100000.0, 'rate': 0.0600},
    {'max': 16950000.0, 'rate': 0.0700},
    {'max': 19750000.0, 'rate': 0.0800},
    {'max': 24150000.0, 'rate': 0.0900},
    {'max': 26450000.0, 'rate': 0.1000},
    {'max': 28000000.0, 'rate': 0.1100},
    {'max': 30050000.0, 'rate': 0.1200},
    {'max': 32400000.0, 'rate': 0.1300},
    {'max': 35400000.0, 'rate': 0.1400},
    {'max': 39100000.0, 'rate': 0.1500},
    {'max': 43850000.0, 'rate': 0.1600},
    {'max': 47800000.0, 'rate': 0.1700},
    {'max': 51400000.0, 'rate': 0.1800},
    {'max': 56300000.0, 'rate': 0.1900},
    {'max': 62200000.0, 'rate': 0.2000},
    {'max': 68600000.0, 'rate': 0.2100},
    {'max': 77500000.0, 'rate': 0.2200},
    {'max': 89000000.0, 'rate': 0.2300},
    {'max': 103000000.0, 'rate': 0.2400},
    {'max': 125000000.0, 'rate': 0.2500},
    {'max': 157000000.0, 'rate': 0.2600},
    {'max': 206000000.0, 'rate': 0.2700},
    {'max': 337000000.0, 'rate': 0.2800},
    {'max': 454000000.0, 'rate': 0.2900},
    {'max': 550000000.0, 'rate': 0.3000},
    {'max': 695000000.0, 'rate': 0.3100},
    {'max': 910000000.0, 'rate': 0.3200},
    {'max': 1400000000.0, 'rate': 0.3300},
    {'max': double.infinity, 'rate': 0.3400},
  ];

  static const terTableB = [
    {'max': 6200000.0, 'rate': 0.0000},
    {'max': 6500000.0, 'rate': 0.0025},
    {'max': 6850000.0, 'rate': 0.0050},
    {'max': 7300000.0, 'rate': 0.0075},
    {'max': 9200000.0, 'rate': 0.0100},
    {'max': 10750000.0, 'rate': 0.0150},
    {'max': 11250000.0, 'rate': 0.0200},
    {'max': 11600000.0, 'rate': 0.0250},
    {'max': 12600000.0, 'rate': 0.0300},
    {'max': 13600000.0, 'rate': 0.0400},
    {'max': 14950000.0, 'rate': 0.0500},
    {'max': 16400000.0, 'rate': 0.0600},
    {'max': 18450000.0, 'rate': 0.0700},
    {'max': 21850000.0, 'rate': 0.0800},
    {'max': 26000000.0, 'rate': 0.0900},
    {'max': 27700000.0, 'rate': 0.1000},
    {'max': 29350000.0, 'rate': 0.1100},
    {'max': 31450000.0, 'rate': 0.1200},
    {'max': 33950000.0, 'rate': 0.1300},
    {'max': 37100000.0, 'rate': 0.1400},
    {'max': 41100000.0, 'rate': 0.1500},
    {'max': 45800000.0, 'rate': 0.1600},
    {'max': 49500000.0, 'rate': 0.1700},
    {'max': 53800000.0, 'rate': 0.1800},
    {'max': 58500000.0, 'rate': 0.1900},
    {'max': 64000000.0, 'rate': 0.2000},
    {'max': 71000000.0, 'rate': 0.2100},
    {'max': 80000000.0, 'rate': 0.2200},
    {'max': 93000000.0, 'rate': 0.2300},
    {'max': 109000000.0, 'rate': 0.2400},
    {'max': 129000000.0, 'rate': 0.2500},
    {'max': 163000000.0, 'rate': 0.2600},
    {'max': 211000000.0, 'rate': 0.2700},
    {'max': 374000000.0, 'rate': 0.2800},
    {'max': 459000000.0, 'rate': 0.2900},
    {'max': 555000000.0, 'rate': 0.3000},
    {'max': 704000000.0, 'rate': 0.3100},
    {'max': 957000000.0, 'rate': 0.3200},
    {'max': 1405000000.0, 'rate': 0.3300},
    {'max': double.infinity, 'rate': 0.3400},
  ];

  static const terTableC = [
    {'max': 6600000.0, 'rate': 0.0000},
    {'max': 6950000.0, 'rate': 0.0025},
    {'max': 7350000.0, 'rate': 0.0050},
    {'max': 7800000.0, 'rate': 0.0075},
    {'max': 8850000.0, 'rate': 0.0100},
    {'max': 9800000.0, 'rate': 0.0125},
    {'max': 10950000.0, 'rate': 0.0150},
    {'max': 11200000.0, 'rate': 0.0175},
    {'max': 12050000.0, 'rate': 0.0200},
    {'max': 12950000.0, 'rate': 0.0300},
    {'max': 14150000.0, 'rate': 0.0400},
    {'max': 15550000.0, 'rate': 0.0500},
    {'max': 17050000.0, 'rate': 0.0600},
    {'max': 19500000.0, 'rate': 0.0700},
    {'max': 22700000.0, 'rate': 0.0800},
    {'max': 26600000.0, 'rate': 0.0900},
    {'max': 28100000.0, 'rate': 0.1000},
    {'max': 30100000.0, 'rate': 0.1100},
    {'max': 32600000.0, 'rate': 0.1200},
    {'max': 35400000.0, 'rate': 0.1300},
    {'max': 38900000.0, 'rate': 0.1400},
    {'max': 43000000.0, 'rate': 0.1500},
    {'max': 47400000.0, 'rate': 0.1600},
    {'max': 51200000.0, 'rate': 0.1700},
    {'max': 55800000.0, 'rate': 0.1800},
    {'max': 60400000.0, 'rate': 0.1900},
    {'max': 66700000.0, 'rate': 0.2000},
    {'max': 74500000.0, 'rate': 0.2100},
    {'max': 83200000.0, 'rate': 0.2200},
    {'max': 95600000.0, 'rate': 0.2300},
    {'max': 110000000.0, 'rate': 0.2400},
    {'max': 134000000.0, 'rate': 0.2500},
    {'max': 169000000.0, 'rate': 0.2600},
    {'max': 221000000.0, 'rate': 0.2700},
    {'max': 390000000.0, 'rate': 0.2800},
    {'max': 463000000.0, 'rate': 0.2900},
    {'max': 561000000.0, 'rate': 0.3000},
    {'max': 709000000.0, 'rate': 0.3100},
    {'max': 965000000.0, 'rate': 0.3200},
    {'max': 1419000000.0, 'rate': 0.3300},
    {'max': double.infinity, 'rate': 0.3400},
  ];
```

Pencarian lapisan tetap "ambil entri pertama yang `bruto <= max`" pada daftar
menaik, dan entri terakhir memakai `double.infinity`.

## 10. Disclaimer resmi (E1)

Teks berikut dipakai apa adanya pada hasil Simulator dan pada trust chip.
Dua kalimat, tidak boleh dipendekkan sebagian:

```text
Hasil ini adalah simulasi berdasarkan PMK 168/2023 dan belum diverifikasi
terhadap kalkulator resmi Direktorat Jenderal Pajak. Simulasi ini bukan nasihat
pajak dan tidak menggantikan kewajiban pelaporan Anda.
```

## 11. Daftar `[CEK]`

Item yang belum bersumber pada penguncian M0. Tidak boleh diimplementasi sebagai
angka sampai sumbernya masuk.

| # | Item | Yang dibutuhkan |
| --- | --- | --- |
| 1 | Nomor pasal PMK 168/2023 untuk tiap ketentuan di §2, §3, §5, §6 | Salinan PMK 168/2023 dari JDIH Kemenkeu |
| 2 | Besaran dan batas atas biaya jabatan/biaya pensiun | Dasar hukumnya; sampai ada, §6 tidak diimplementasi |
| 3 | Dasar hukum tabel Pasal 17 di §6 (Pasal 17 ayat (1) huruf a UU PPh — versi perubahan terakhir) | Rujukan UU yang berlaku |
| 4 | Perlakuan pegawai yang mulai atau berhenti bekerja di tengah tahun | Contoh penghitungan resmi |
| 5 | Verifikasi seluruh kasus di [`kasus-pph21.csv`](kasus-pph21.csv) terhadap kalkulator resmi DJP | Akses kalkulator DJP |

## Halaman terkait

- [`ter-bulanan.csv`](ter-bulanan.csv) — tabel TER bulanan, bentuk normatif.
- [`kasus-pph21.csv`](kasus-pph21.csv) — kasus uji dan hasil yang diharapkan.
- [Keputusan TAX](keputusan-tax.md) — D-8 sampai D-13.
- [Aturan pajak](../aturan-pajak.md) — aturan yang dipakai kode saat ini.
- [Sumber: slide PMK 168/2023](../../sumber/pmk-168-2023-slide-ter.md).
