---
title: Spesifikasi PPh Final UMKM 0,5%
description: Spesifikasi TAX untuk PPh Final UMKM — tarif, dasar pengenaan, pengecualian omzet, batas jangka waktu, perlakuan transisi ambang Rp4,8 M, dan tenggat pelaporan.
tags:
  - domain
  - pajak
  - spesifikasi
---

**Pemilik dokumen:** TAX (Pakar Regulasi DJP & Kemenkeu).
**Status:** kerangka Minggu 1, dikunci untuk M0. **Sebagian besar angka dan
seluruh rujukan pasal masih `[CEK]`** — lihat §7.

**Catatan sumber:** materi yang diserahkan TAX pada 18 September 2026 hanya
memuat PMK 168/2023 (PPh Pasal 21). **Salinan PP 23/2018 dan PP 55/2022 belum
tersedia di berkas maupun konteks yang diberikan.** Karena itu angka dan pasal di
halaman ini tidak ditulis dari ingatan: yang dicantumkan adalah nilai yang
**dipakai kode saat ini**, ditandai `[CEK]` sampai dicocokkan dengan salinan
resmi dari JDIH.

---

## 1. Lingkup

PPh Final atas peredaran bruto tertentu untuk wajib pajak UMKM, sebagaimana
disimulasikan Catatin: tarif tunggal atas omzet, tanpa pengurang biaya.

## 2. Tarif dan dasar pengenaan

| Hal | Nilai yang dipakai kode | Status |
| --- | --- | --- |
| Tarif | 0,5% dari peredaran bruto | `[CEK]` terhadap PP 23/2018 |
| Ambang peredaran bruto | Rp 4.800.000.000 setahun | `[CEK]` terhadap PP 23/2018 |
| Dasar pengenaan | peredaran bruto (omzet), bukan laba | `[CEK]` |

Tepat **di** ambang Rp 4,8 miliar wajib pajak masih berhak skema final; yang
melewatinya tidak. Perilaku ini sudah berlaku di kode dan dipertahankan.

## 3. Pengecualian peredaran bruto Rp 500 juta (D-9)

Pengecualian atas bagian peredaran bruto tertentu untuk wajib pajak orang
pribadi. **Belum dimodelkan sama sekali di kode** — ini temuan
[T-3](../../proyek/backlog-teknis.md).

| Pertanyaan yang harus dijawab | Status |
| --- | --- |
| Besaran bagian yang dikecualikan | `[CEK]` — kode tidak memuatnya |
| Berlaku untuk jenis wajib pajak apa saja (orang pribadi saja, atau juga badan) | `[CEK]` |
| Dihitung kumulatif sejak awal tahun atau per masa | `[CEK]` |
| Dasar hukum | `[CEK]` — PP 55/2022 belum tersedia |

**Keputusan D-9 belum dapat diambil tanpa salinan peraturannya.** Menulis
besarannya dari ingatan dilarang oleh aturan kerja dokumen ini.

## 4. Batas jangka waktu pemakaian tarif final

Skema PPh Final UMKM hanya boleh dipakai selama jangka waktu tertentu sejak wajib
pajak terdaftar atau sejak peraturan berlaku. **Kode tidak punya input "sejak
tahun berapa" sama sekali**, sehingga batas ini tidak pernah bisa dievaluasi
(bagian kedua dari [T-3](../../proyek/backlog-teknis.md)).

| Pertanyaan | Status |
| --- | --- |
| Lama jangka waktu per jenis wajib pajak (orang pribadi, PT, CV/firma, koperasi) | `[CEK]` |
| Titik mulai penghitungan jangka waktu | `[CEK]` |
| Perlakuan setelah jangka waktu habis | `[CEK]` |

**Konsekuensi untuk backend:** kalau jangka waktunya berbeda per jenis wajib
pajak, parameter tunggal di tabel `tax_parameters`
([Backend & API §7.7 pertanyaan 3](../../arsitektur/backend-dan-api.md#77-pertanyaan-untuk-tax-45))
tidak cukup — dibutuhkan kolom jenis wajib pajak. Jawaban final menunggu §4 ini
terisi.

**Kebutuhan data baru untuk frontend:** profil usaha perlu menyimpan tahun
pertama wajib pajak memakai skema final. Tanpa itu, batas jangka waktu tidak
dapat diimplementasi berapa pun angkanya.

## 5. Transisi melewati ambang Rp 4,8 M di tengah tahun (D-13)

Perilaku kode sekarang: begitu omzet tahunan melewati ambang, PPh Final
dijadikan **nol**, dan rezim penggantinya tidak dimodelkan. Untuk skenario
"optimistis" di Simulator, ini menghasilkan total pajak yang lebih kecil daripada
skenario base case — hasil yang menyesatkan pengguna.

| Pertanyaan | Status |
| --- | --- |
| Apakah tarif final tetap berlaku sampai akhir tahun berjalan, lalu berubah tahun berikutnya | `[CEK]` |
| Rezim pengganti setelah melewati ambang | `[CEK]` |
| Apakah rezim pengganti masuk lingkup Fase Dua | lihat [Keputusan TAX D-8](keputusan-tax.md) |

**Aturan sementara sampai D-13 terjawab:** skenario yang melewati ambang tidak
boleh menampilkan angka pajak sama sekali. Ganti dengan penanda "melewati ambang
Rp 4,8 M — skema pajak berubah, belum disimulasikan". Menampilkan nol adalah
kesalahan yang lebih berbahaya daripada tidak menampilkan apa pun.

## 6. Tenggat pelaporan (D-12)

| Jenis | Tenggat | Status |
| --- | --- | --- |
| PPh Final masa | tanggal 15 bulan berikutnya | `[CEK]` |
| SPT Tahunan PPh Orang Pribadi | **31 Maret** tahun berikutnya | **ditetapkan TAX, 18 September 2026** |
| PPh Pasal 21 masa | tanggal 10 bulan berikutnya | `[CEK]` |
| PPN masa | tanggal 30 bulan berikutnya | `[CEK]` |

**Temuan: kode salah.** `generateCalendar()` memakai **30 April** untuk SPT
Tahunan PPh Orang Pribadi. Tanggal yang benar adalah **31 Maret**. Seluruh
tenggat SPT Tahunan yang pernah ditampilkan aplikasi meleset satu bulan.
Perbaikan ini menutup [#154 (T-25)](https://github.com/piambak/catatin/issues/154)
dan harus masuk sebelum M1.

## 7. Daftar `[CEK]`

| # | Item | Yang dibutuhkan |
| --- | --- | --- |
| 1 | Seluruh angka di §2 | Salinan PP 23/2018 dari JDIH |
| 2 | Pengecualian Rp 500 juta (§3, D-9) | Salinan PP 55/2022 dari JDIH |
| 3 | Batas jangka waktu per jenis wajib pajak (§4) | Salinan PP 23/2018 dan PP 55/2022 |
| 4 | Perlakuan transisi ambang (§5, D-13) | Rujukan resmi |
| 5 | Tenggat masa PPh Final, PPh 21, dan PPN (§6) | Rujukan resmi |
| 6 | Kasus uji PPh Final (`kasus-pph-final.csv`, [#46](https://github.com/piambak/catatin/issues/46)) | §2–§5 terisi lebih dulu |

## 8. Disclaimer resmi (E1)

Teks yang sama dengan [spesifikasi PPh 21](spek-pph21-ter.md#10-disclaimer-resmi-e1),
dengan dasar hukum disesuaikan:

```text
Hasil ini adalah simulasi berdasarkan PP 23/2018 dan belum diverifikasi terhadap
kalkulator resmi Direktorat Jenderal Pajak. Simulasi ini bukan nasihat pajak dan
tidak menggantikan kewajiban pelaporan Anda.
```

## Halaman terkait

- [Keputusan TAX](keputusan-tax.md) — D-8 sampai D-13.
- [Spesifikasi PPh 21 TER](spek-pph21-ter.md).
- [Aturan pajak](../aturan-pajak.md) — aturan yang dipakai kode saat ini.
