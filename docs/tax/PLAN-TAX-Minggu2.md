# Rencana & Kerangka Kerja TAX — Minggu 2

**Periode:** Senin 21 – Jumat 25 September 2026
**Fase:** Clean foundation
**Role:** TAX (Pakar Regulasi DJP & Kemenkeu) — @abrorhd
**Issue:** #45, #46, #47, #48
**Muara:** sign-off M1 (#31, PO) pada Jumat 25 September

---

## 1. Tujuan dan definisi selesai

Sebuah issue baru boleh ditutup kalau semua butir di bawahnya tercentang **dan** bukti sudah ditautkan di komentar issue.

### #46 — Kasus uji PPh Final

- [ ] `docs/tax/CASES-PPhFinal.csv` ter-commit, mengikuti skema kolom di §3
- [ ] Minimal 10 kasus berstatus `valid` yang mencakup kelas A–D (§3.2)
- [ ] Setiap kasus `valid` punya output per bulan, bukan hanya total tahunan
- [ ] Setiap kasus mencantumkan `legal_basis`
- [ ] Kasus yang belum pasti berstatus `cek`, dan kasus di luar cakupan berstatus `out_of_scope`. Keduanya tidak diisi angka tebakan.
- [ ] Kasus yang masih `cek` terdaftar di komentar penutup issue

### #47 — Pemetaan kategori transaksi

- [ ] Tabel matriks (§4) ter-commit di `SPEC-Kategori.md`
- [ ] Semua kategori di `mock_data.dart` / `tx-categories` tercakup, tanpa ada yang terlewat
- [ ] Setiap kategori ambigu punya keputusan eksplisit **atau** status `CEK` dengan pertanyaan yang jelas
- [ ] Selisih antara tabel dan kode dilaporkan ke FE/BE sebagai issue terpisah

### #45 — Review skema konfigurasi tarif

- [ ] Checklist §5 terisi lengkap dengan hasil *Lolos*, *Gagal*, atau *Tidak dapat dinilai*
- [ ] Setiap butir *Gagal* diberi tingkat keparahan dan usulan perbaikan
- [ ] Kasus dari #46 sudah diuji di atas kertas terhadap skema
- [ ] Temuan diposting sebagai satu komentar terstruktur di issue/PR BE

### #48 — Menjawab pertanyaan pajak dari FE/BE

- [ ] Tidak ada issue berlabel `tax` yang dibiarkan tanpa respons lebih dari 2 hari kerja
- [ ] Setiap jawaban memakai templat §6 dan tercatat di log keputusan

---

## 2. Jadwal dan dependensi

| Hari | Fokus utama | Rutin | Keluaran hari itu |
| --- | --- | --- | --- |
| Senin 21 | #46 — susun kasus kelas A–C | #48 (pagi) | Draf CSV; tanyakan ke BE jadwal skema siap |
| Selasa 22 | #47 — matriks kategori | #48 | Draf tabel + daftar kategori ambigu |
| Rabu 23 | #45 — checklist terhadap skema BE | #48 | Hasil checklist sementara |
| Kamis 24 | #45 — uji kasus #46 ke skema; finalisasi #46 kelas D | #48 | Komentar temuan ke BE; CSV final |
| Jumat 25 | Penutupan (§8) sebelum sign-off M1 | #48 | Semua issue tertaut ke bukti |

### Dependensi

- **#45 bergantung pada skema BE.** Status kesiapannya dikonfirmasi ke BE pada Senin.
- **#45 memakai hasil #46** sebagai bahan uji, jadi #46 harus sudah berbentuk draf sebelum Rabu.
- **#47 bergantung pada akses ke `mock_data.dart` / `tx-categories`** versi terbaru di branch utama.

### Rencana cadangan

| Kondisi | Tindakan |
| --- | --- |
| Skema BE belum ada sampai Rabu | Kirim checklist §5 ke BE sebagai *kebutuhan* (bukan review), tandai #45 "menunggu skema", laporkan ke PO sebelum sign-off M1 |
| Pertanyaan usaha < 12 bulan belum terjawab | Kasus kelas D tetap `cek`; #46 tetap bisa ditutup asalkan ada ≥ 10 kasus `valid` |
| Volume #48 tinggi | #48 didahulukan dari #45 — pertanyaan yang tak dijawab menghambat dua role sekaligus |

---

## 3. Kerangka #46 — Kasus uji PPh Final

### 3.1 Skema kolom CSV

| Kolom | Isi |
| --- | --- |
| `case_id` | `PF-<kelas><nomor>`, contoh `PF-B02` |
| `kelas` | A, B, C, D, atau E (lihat §3.2) |
| `deskripsi` | Satu kalimat: apa yang diuji |
| `subjek` | `OP` (orang pribadi). Subjek lain berstatus `out_of_scope` kecuali SPEC mencakupnya |
| `tahun_pajak` | Contoh `2026` |
| `bulan_mulai_usaha` | `1` untuk usaha yang sudah berjalan sebelum tahun pajak |
| `omzet_m01` … `omzet_m12` | Peredaran bruto per bulan, rupiah bulat |
| `kumulatif_akhir` | Jumlah `omzet_m01`–`m12` |
| `pph_m01` … `pph_m12` | PPh Final terutang per bulan yang diharapkan |
| `pph_total` | Jumlah `pph_m01`–`m12` |
| `status` | `valid` / `cek` / `out_of_scope` |
| `legal_basis` | Peraturan dan pasal. Kalau nomor pasal belum dipastikan, tulis `[CEK pasal]` |
| `catatan` | Asumsi, pertanyaan terbuka, atau alasan `out_of_scope` |

Kolom `pph_*` pada kasus `cek` dan `out_of_scope` dibiarkan kosong.

### 3.2 Kelas kasus

Kasus disusun berdasarkan batas aturan, bukan angka acak. Tiap batas diuji dari bawah, tepat di batas, dan dari atas.

| Kelas | Yang diuji | Kasus minimal |
| --- | --- | --- |
| **A — Di bawah ambang Rp500 juta** | Kumulatif setahun < Rp500 juta; tepat Rp500 juta | A01 jauh di bawah; A02 tepat Rp500.000.000 |
| **B — Melewati Rp500 juta di tengah tahun** | Bulan saat ambang terlewati, pajak hanya atas kelebihan di bulan itu | B01 lewat di bulan tengah; B02 lewat di Januari; B03 lewat di Desember; B04 kelebihan sangat kecil (uji pembulatan) |
| **C — Rentang Rp500 juta – Rp4,8 miliar** | Seluruh tahun di atas ambang, sampai batas atas | C01 omzet menengah; C02 mendekati Rp4,8 miliar; C03 tepat Rp4,8 miliar |
| **D — Usaha < 12 bulan** | Usaha mulai di tengah tahun | D01 mulai tengah tahun, tetap di bawah ambang; D02 mulai tengah tahun, melewati ambang → `cek` |
| **E — Di luar cakupan** | Hal yang belum dimodelkan produk | E01 kumulatif > Rp4,8 miliar dalam tahun berjalan (D-13); E02 jangka waktu tarif final terlampaui (tahun pertama pemakaian belum disimpan) |

Kasus tambahan yang disarankan kalau waktunya cukup: bulan dengan omzet nol di tengah tahun, dan omzet yang terkonsentrasi di satu bulan.

### 3.3 Pertanyaan terbuka yang harus diputuskan

| ID | Pertanyaan | Berdampak ke |
| --- | --- | --- |
| Q-46-1 | Untuk usaha yang mulai di tengah tahun, apakah ambang Rp500 juta dan batas Rp4,8 miliar disetahunkan atau tidak? | D02, dan logika mesin tarif |
| Q-46-2 | Aturan pembulatan PPh terutang per bulan (dibulatkan ke rupiah penuh, dan arah pembulatannya) | B04, semua kasus |
| Q-46-3 | Apakah "tepat Rp4,8 miliar" masih memenuhi syarat (dibaca "tidak melebihi")? | C03 |

Setiap jawaban dicatat di log keputusan (§6.3) beserta sumbernya, lalu status kasus terkait dinaikkan dari `cek` ke `valid`.

---

## 4. Kerangka #47 — Pemetaan kategori transaksi

### 4.1 Kolom matriks

| Kolom | Isi |
| --- | --- |
| `kategori` | Nama persis seperti di kode |
| `arah` | Masuk / Keluar |
| `peredaran_bruto` | Ya / Tidak / CEK — apakah dihitung ke omzet untuk ambang dan PPh Final |
| `hpp` | Ya / Tidak / CEK — apakah masuk harga pokok penjualan di dashboard untung |
| `dasar` | Rujukan aturan atau definisi yang dipakai |
| `catatan` | Alasan, contoh transaksi, atau pertanyaan terbuka |
| `diputuskan` | Tanggal dan nama pengambil keputusan |

### 4.2 Urutan pertanyaan keputusan

Untuk setiap kategori **masuk**:

1. Apakah ini penerimaan dari kegiatan usaha? Kalau tidak (misalnya setoran modal, pinjaman, atau uang pribadi), jawabannya `peredaran_bruto = Tidak`.
2. Apakah penghasilan ini sudah dikenai PPh final dengan skema lain atau bukan objek PPh Final UMKM? Kalau ya, jawabannya `Tidak`, dan dasarnya dicatat.
3. Apakah ini bruto (sebelum dikurangi biaya)? Kategori yang tercatat neto harus ditandai. Mesin tarif membutuhkan angka bruto.

Untuk setiap kategori **keluar**:

1. Apakah biaya ini melekat langsung pada barang atau jasa yang dijual? Kalau ya, `hpp = Ya`.
2. Apakah ini biaya operasional, pengeluaran pribadi, atau pembayaran utang pokok? Kalau ya, `hpp = Tidak`, dan dicatat apakah kategori itu masih boleh muncul di perhitungan untung.

### 4.3 Kategori yang sudah bisa diperkirakan ambigu

Bagian ini diisi ulang setelah `mock_data.dart` dibaca. Kandidat awalnya:

- Penjualan aset usaha (kendaraan, peralatan)
- Setoran modal pemilik dan pinjaman masuk
- Hibah, bantuan program, dan hadiah
- Retur dan diskon penjualan
- Penerimaan uang muka atau DP
- Kategori "Lain-lain" atau kategori campuran

Kategori yang tidak bisa diputuskan minggu ini diberi status `CEK`, **dan** diberi perilaku default yang aman di kode. Keputusan perilaku default ini ikut dilaporkan ke FE/BE.

---

## 5. Kerangka #45 — Checklist representabilitas skema tarif

### 5.1 Checklist

| ID | Kebutuhan | Uji dengan |
| --- | --- | --- |
| S-01 | Tarif flat persentase (0,5%) | Kelas C |
| S-02 | Ambang bebas pajak per subjek (Rp500 juta, OP) yang dihitung kumulatif per tahun pajak | Kelas A, B |
| S-03 | Pajak hanya atas kelebihan dari ambang pada bulan terlewatinya ambang | B01–B04 |
| S-04 | Batas atas kelayakan skema (Rp4,8 miliar) sebagai atribut terpisah dari ambang | C02, C03, E01 |
| S-05 | Jangka waktu maksimal pemakaian skema per jenis subjek | E02 |
| S-06 | Tarif bertingkat dengan banyak lapisan (TER kategori A/B/C) | Tabel TER di SPEC PPh 21 |
| S-07 | Pemetaan status PTKP ke kategori TER | SPEC PPh 21 |
| S-08 | `effective_from` dan `effective_to` pada tiap baris, termasuk pergantian tarif di tengah tahun | Uji skenario perubahan tarif |
| S-09 | `legal_basis` per baris, cukup rinci sampai pasal | Semua |
| S-10 | `config_version` dan status `approved` yang tidak bisa diubah setelah disetujui | Uji skenario revisi |
| S-11 | Hasil hitung bisa menunjuk versi config yang dipakai | Semua |
| S-12 | Aturan pembulatan dapat dikonfigurasi atau terdokumentasi | B04 |

### 5.2 Tingkat keparahan temuan

| Tingkat | Arti | Konsekuensi |
| --- | --- | --- |
| **Blocker** | Aturan di SPEC tidak bisa direpresentasikan sama sekali | Menahan M1 sampai diperbaiki atau diputuskan ditunda |
| **Major** | Bisa direpresentasikan, tapi hanya lewat hardcode atau logika di luar config | Perbaikan dijadwalkan sebelum M4 |
| **Minor** | Penamaan, dokumentasi, atau kerapian | Masuk backlog |

### 5.3 Format komentar ke BE

```text
Review skema config tarif — #45

Ringkasan: X lolos, Y gagal (B blocker, M major, m minor), Z tidak dapat dinilai.

[S-0n] <kebutuhan>
Hasil: Gagal — <Blocker/Major/Minor>
Temuan: <apa yang tidak bisa direpresentasikan>
Contoh kasus: <case_id dari CASES-PPhFinal.csv>
Usulan: <perubahan minimal pada skema>
Dasar: <peraturan/pasal>
```

---

## 6. Protokol #48 — Tanya-jawab FE/BE

### 6.1 Aturan main

- Cek issue berlabel `tax` setiap pagi.
- Respons pertama maksimal 2 hari kerja. Kalau jawaban final belum bisa diberikan, respons pertama tetap wajib diposting dengan isi: apa yang sudah diketahui, apa yang sedang dicek, dan kapan jawabannya menyusul.
- Pertanyaan yang jawabannya mengubah perilaku perhitungan juga harus masuk ke SPEC, tidak cukup di komentar issue saja.

### 6.2 Templat jawaban

```text
Pertanyaan: <diringkas dalam satu kalimat>
Jawaban: <langsung, bisa diimplementasikan>
Dasar hukum: <peraturan, pasal, ayat>
Keyakinan: Pasti / Kemungkinan besar / [CEK] — <alasan kalau bukan Pasti>
Dampak ke kode: <modul/fungsi/config yang berubah, atau "tidak ada">
Perlu update SPEC: Ya (<file>) / Tidak
```

### 6.3 Log keputusan

Semua jawaban final dan jawaban atas pertanyaan terbuka (Q-46-x, kategori `CEK`) dicatat di `docs/tax/DECISIONS.md`, dengan format:

| ID | Tanggal | Pertanyaan | Keputusan | Dasar | Issue terkait |
| --- | --- | --- | --- | --- | --- |

---

## 7. Aturan sumber dan penanda

### 7.1 Hierarki sumber

1. Undang-undang (UU 7/2021 HPP, UU PPh)
2. Peraturan Pemerintah (PP 55/2022, PP 58/2023)
3. Peraturan Menteri Keuangan (termasuk PMK 168/2023)
4. Peraturan dan Surat Edaran Dirjen Pajak
5. Materi resmi DJP (situs, kalkulator, panduan). Boleh dipakai sebagai konfirmasi, tapi tidak boleh menjadi satu-satunya dasar.

Artikel media, blog konsultan, dan forum **tidak** boleh dijadikan dasar. Sumber jenis ini hanya boleh dipakai sebagai petunjuk untuk mencari sumber resmi.

### 7.2 Penanda

| Penanda | Dipakai saat |
| --- | --- |
| `[CEK]` | Isi belum dipastikan ke sumber resmi |
| `[CEK pasal]` | Isinya diyakini benar, tapi nomor pasal atau ayatnya belum diverifikasi |
| `out_of_scope` | Produk memang belum memodelkan hal ini. Ini bukan soal ketidakpastian aturan |

Penanda tidak boleh dihapus tanpa entri di log keputusan.

---

## 8. Serah terima Jumat

Diselesaikan sebelum sign-off M1.

- [ ] #46: CSV ter-commit, jumlah kasus `valid` ≥ 10, daftar `cek` tercantum di komentar penutup
- [ ] #47: `SPEC-Kategori.md` ter-commit, selisih dengan kode sudah menjadi issue FE/BE
- [ ] #45: komentar temuan terposting; blocker (kalau ada) dilaporkan langsung ke PO
- [ ] #48: tidak ada issue `tax` yang melewati SLA
- [ ] `DECISIONS.md` memuat semua keputusan minggu ini
- [ ] Ringkasan satu paragraf untuk PO: apa yang selesai, apa yang masih `CEK`, dan apa yang berisiko bagi M1
