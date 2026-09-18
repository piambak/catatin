---
title: Keputusan TAX — D-8 sampai D-13
description: Register keputusan regulasi Catatin Fase Dua yang menjadi kewenangan TAX, beserta alasan, status, dan halaman tempat rinciannya hidup.
tags:
  - domain
  - pajak
  - keputusan
---

**Pemilik dokumen:** TAX (Pakar Regulasi DJP & Kemenkeu).

Satu keputusan satu bagian. Keputusan yang sudah ditetapkan tidak ditulis ulang
kalau berubah — tulis keputusan baru dan tandai yang lama sebagai dicabut, supaya
riwayatnya kebaca.

| Kode | Pokok | Status | Rincian |
| --- | --- | --- | --- |
| D-8 | Lingkup PPN dan proyeksi SPT Tahunan | tarif ditetapkan; lingkup menunggu ratifikasi | §1 |
| D-9 | Pengecualian peredaran bruto Rp 500 juta | terhambat sumber | [Spek PPh Final §3](spek-pph-final-umkm.md#3-pengecualian-peredaran-bruto-rp-500-juta-d-9) |
| D-10 | Apa yang boleh ditampilkan pada hasil PPh 21 | ditetapkan | [Spek PPh 21 §7](spek-pph21-ter.md#7-aturan-tampilan-d-10) |
| D-11 | Matriks profesi ke rezim pajak | ditetapkan sebagian | §2 |
| D-12 | Tenggat pelaporan | ditetapkan sebagian | [Spek PPh Final §6](spek-pph-final-umkm.md#6-tenggat-pelaporan-d-12) |
| D-13 | Transisi melewati ambang Rp 4,8 M | terhambat sumber | [Spek PPh Final §5](spek-pph-final-umkm.md#5-transisi-melewati-ambang-rp-48-m-di-tengah-tahun-d-13) |

---

## 1. D-8 — lingkup PPN dan proyeksi SPT Tahunan

### 1.1 Tarif PPN

**Ditetapkan TAX, 18 September 2026: tarif PPN yang dipakai Catatin adalah 11%.**
Nilai ini sama dengan `AppConstants.ppnRate` yang ada sekarang, jadi tidak ada
perubahan kode untuk tarifnya. Dasar hukum tarif: `[CEK]`.

Konsekuensi: pertanyaan tarif PPN pada [#63](https://github.com/piambak/catatin/issues/63)
selesai. Yang tersisa di issue itu adalah dasar pengenaan dan PPN masukan.

### 1.2 Lingkup modul PPN pada Fase Dua

**Rekomendasi TAX: PPN tidak dimodelkan sebagai modul tersendiri pada Fase Dua.**

Alasannya bukan soal tarif, melainkan dasar pengenaannya. PPN terutang adalah
selisih pajak keluaran dan pajak masukan. Catatin tidak mengumpulkan data faktur
pajak, sehingga PPN masukan tidak dapat diketahui aplikasi. Perhitungan yang ada
sekarang — `omzet tahunan x 11%` di `calculateScenarios()` — bukan
penyederhanaan yang kurang teliti, melainkan besaran yang berbeda: ia selalu
lebih besar daripada PPN yang sebenarnya terutang, dan selisihnya tidak bisa
diperkirakan tanpa data pembelian.

Yang harus dilakukan kalau rekomendasi ini diterima:

1. `AppConstants.ppnRate` dipertahankan pada 11%, tetapi pemakaiannya di
   `calculateScenarios()` diberi label eksplisit "estimasi kasar PPN keluaran,
   belum memperhitungkan PPN masukan" — atau dikeluarkan dari total pajak.
2. `kind` bernilai `PPN` **dihapus** dari skema mesin tarif
   ([Backend & API §7.6](../../arsitektur/backend-dan-api.md#7-skema-mesin-tarif-pajak-draf-untuk-review-tax)).
3. [#63](https://github.com/piambak/catatin/issues/63) dan
   [#105](https://github.com/piambak/catatin/issues/105) ditutup sebagai di luar
   lingkup, bukan dibiarkan menggantung.

### 1.3 Lingkup proyeksi SPT Tahunan

**Rekomendasi TAX: proyeksi SPT Tahunan tidak masuk Fase Dua.** Proyeksi tahunan
yang benar membutuhkan rekalkulasi masa pajak terakhir, dan rekalkulasi itu
membutuhkan besaran biaya jabatan yang belum bersumber
([Spek PPh 21 §6](spek-pph21-ter.md#6-masa-pajak-terakhir-desember)). Menerbitkan
proyeksi tahunan sebelum angka itu ada berarti menerbitkan angka yang tidak bisa
dipertanggungjawabkan.

### 1.4 `kind` PPH_PASAL_17 — tetap dipertahankan

Berbeda dengan `PPN`, `kind` bernilai `PPH_PASAL_17` **tidak dihapus** dari skema
mesin tarif. Tarif Pasal 17 bukan kandidat opsional: PMK 168/2023 memakainya
untuk menghitung PPh Pasal 21 pada masa pajak terakhir dan untuk penerima
penghasilan selain pegawai tetap. Skema harus mampu menampungnya walaupun
implementasinya baru menyusul setelah biaya jabatan bersumber. Ini mengubah
jawaban atas [pertanyaan 6 di Backend & API §7.7](../../arsitektur/backend-dan-api.md#77-pertanyaan-untuk-tax-45):
hapus `PPN`, pertahankan `PPH_PASAL_17`.

### 1.5 Ratifikasi

`[CEK]` — §1.2 sampai §1.4 adalah rekomendasi TAX yang menunggu ratifikasi pada
[#26](https://github.com/piambak/catatin/issues/26) sebelum PR M0 di-merge.

---

## 2. D-11 — matriks profesi ke rezim pajak

Dipakai untuk pertanyaan pertama Simulator: aplikasi harus tahu rezim mana yang
berlaku sebelum menanyakan apa pun tentang angka.

| Profil penerima penghasilan | Dasar pengenaan | Tarif | Status |
| --- | --- | --- | --- |
| Pegawai tetap, penghasilan teratur | penghasilan bruto sebulan | TER bulanan A/B/C | ditetapkan |
| Pegawai tetap, masa pajak terakhir | penghasilan kena pajak setahun | Pasal 17 | ditetapkan, implementasi ditunda |
| Pegawai tidak tetap, dibayar harian | bruto sehari | TER harian | di luar lingkup Fase Dua |
| Pegawai tidak tetap, dibayar bulanan | bruto bulanan | TER bulanan A/B/C | di luar lingkup Fase Dua |
| Bukan pegawai (jasa, pekerjaan bebas) | bruto x 50% | Pasal 17 | ditetapkan, di luar lingkup Fase Dua |
| Peserta kegiatan | bruto | Pasal 17 | ditetapkan, di luar lingkup Fase Dua |
| Pengusaha/pekerjaan bebas dengan peredaran bruto tertentu | peredaran bruto | PPh Final 0,5% | `[CEK]` — syarat dan pengecualiannya menunggu PP 23/2018 |

Sumber baris PPh Pasal 21:
[slide PMK 168/2023](../../sumber/pmk-168-2023-slide-ter.md). Baris PPh Final
belum bersumber.

**Batas yang harus dinyatakan di Simulator:** Catatin memodelkan dua profil saja
— pengusaha dengan PPh Final, dan pegawai tetap dengan TER bulanan. Profil lain
tidak boleh dihitung diam-diam dengan rumus salah satu dari keduanya; kalau
pengguna memilihnya, aplikasi menyatakan bahwa profil itu belum disimulasikan.
Ini menutup [#153 (T-17)](https://github.com/piambak/catatin/issues/153).

---

## Halaman terkait

- [Spesifikasi PPh 21 TER](spek-pph21-ter.md)
- [Spesifikasi PPh Final UMKM](spek-pph-final-umkm.md)
- [Backend & API §7](../../arsitektur/backend-dan-api.md#7-skema-mesin-tarif-pajak-draf-untuk-review-tax)
