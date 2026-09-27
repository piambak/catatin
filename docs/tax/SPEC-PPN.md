# SPEC — PPN: Kapan Pemungutan Menjadi Wajib

**Issue:** #63 (D-8 masuk cakupan)
**Status:** Bagian 1 dan 2 selesai untuk review.
**Dasar:** PMK 164/2023 Bab VIII (Ps. 17–21) dan Lampiran huruf I; PMK 131/2024 (Ps. 2–6)
**Log keputusan:** `docs/tax/DECISIONS.md`

---

## 1. Kenapa ini rezim yang terpisah

PPN dan PPh Final UMKM adalah dua kewajiban yang berdiri sendiri. Pengguna yang membayar PPh Final 0,5% tetap bisa wajib dikukuhkan sebagai Pengusaha Kena Pajak dan memungut PPN. Keduanya tidak saling menggantikan, dan tidak saling meniadakan.

Tiga perbedaan yang paling sering tertukar:

| | PPh Final UMKM | Kewajiban PKP / PPN |
| --- | --- | --- |
| Periode ukur | Tahun Pajak | **Tahun buku** |
| Dasar ukur | Peredaran bruto **Tahun Pajak sebelumnya** | Akumulasi **tahun buku berjalan**, "sampai dengan suatu bulan" |
| Akibat terlewatinya batas | Tahun berjalan tetap final; ketentuan umum berlaku tahun berikutnya | Wajib melapor untuk dikukuhkan; kewajiban memungut mulai tahun buku berikutnya |

Lihat juga F-03 di `DECISIONS.md`. Indikator `pkpPercent` di dashboard mengukur yang kedua, bukan yang pertama.

*Dasar: PP 55/2022 Ps. 58 ayat (1), Ps. 61; PMK 164/2023 Ps. 17 ayat (1), Ps. 18 ayat (1).*

## 2. Cakupan

**Termasuk:** penentuan kapan kewajiban melapor untuk dikukuhkan PKP timbul, kapan kewajiban memungut dimulai, dan akibat keterlambatan.

**Termasuk (bagian 2):** tarif dan dasar pengenaan menurut PMK 131/2024, serta status pajak masukan.

**Di luar cakupan M5:** faktur pajak, e-Faktur, SPT Masa PPN, mekanisme pengkreditan pajak masukan, penyerahan yang dibebaskan atau tidak dipungut, dan PPnBM. Catatin memberi tahu posisi, tenggat, dan besaran PPN atas satu transaksi; ia tidak menghitung PPN kurang/lebih bayar satu masa.

## 3. Definisi yang dipakai

| Istilah | Arti di dokumen ini | Dasar |
| --- | --- | --- |
| Batasan pengusaha kecil | Peredaran bruto dan/atau penerimaan bruto selama satu tahun buku. Bunyi asli PMK 68/2010 menyebut Rp600 juta; angka itu **sudah tidak berlaku** karena diubah PMK 197/PMK.03/2013. Nilai yang berlaku diyakini Rp4,8 miliar, tetapi teks PMK 197/2013 belum diverifikasi `[CEK]` | PMK 68/2010 Ps. 1 ayat (1) jo. PMK 197/2013 |
| Peredaran bruto untuk batas PKP | Jumlah **keseluruhan penyerahan BKP dan/atau JKP** dalam rangka kegiatan usaha. Basisnya berbeda dari peredaran bruto PPh Final — lihat §3.1 | PMK 68/2010 Ps. 1 ayat (2) |
| Tahun buku | Periode pembukuan pengguna. Bagi pengusaha orang pribadi yang dikecualikan dari kewajiban menyelenggarakan pembukuan, tahun buku **adalah tahun kalender** | PMK 68/2010 Ps. 1 ayat (3) |

### 3.1 Dua basis akumulasi yang berbeda

Batas PKP menjumlahkan **penyerahan BKP dan JKP**. Peredaran bruto PPh Final menjumlahkan **penghasilan dari usaha yang dikenai PPh Final**. Keduanya tidak identik:

| Penerimaan | PPh Final | Batas PKP | Alasan |
| --- | --- | --- | --- |
| Penjualan barang dan jasa usaha | Ya | Ya | Penghasilan usaha sekaligus penyerahan BKP/JKP |
| Jasa pekerjaan bebas (konsultan, perantara, komisi) | **Tidak** | **Ya** | Dikecualikan dari PPh Final, tetapi tetap penyerahan JKP |
| Sewa bangunan | **Tidak** | **Ya** | Final tersendiri untuk PPh, tetapi persewaan adalah JKP `[CEK]` |
| Jasa konstruksi | **Tidak** | **Ya** | Final tersendiri untuk PPh, tetapi tetap JKP |
| Bunga tabungan/deposito | Tidak | Tidak | Bukan penyerahan |
| Modal, pinjaman, hibah | Tidak | Tidak | Bukan penyerahan |
| Penyerahan yang bukan objek PPN | tergantung | **Tidak** | Tidak termasuk BKP/JKP `[CEK daftar]` |

Konsekuensinya: pengguna yang PPh Final-nya nol karena penghasilannya dari pekerjaan bebas tetap bisa melewati batas PKP. Akumulasi `pkpPercent` **tidak boleh** memakai kolom `taxRelevant` yang sama dengan PPh Final.
| Masa Pajak dikukuhkan | Masa saat kewajiban memungut mulai berjalan | PMK 164/2023 Ps. 18 ayat (2) |

## 4. Aturan penentuan

### 4.1 Kewajiban melapor

Kewajiban melapor untuk dikukuhkan sebagai PKP timbul saat akumulasi peredaran bruto dan/atau penerimaan bruto **sampai dengan suatu bulan dalam tahun buku** melebihi batasan pengusaha kecil. Pelaporannya paling lambat **akhir tahun buku** saat batas itu terlewati.

*Dasar: PMK 164/2023 Ps. 17 ayat (1) dan (3).*

Batas waktu ini menggantikan ketentuan lama "paling lama akhir bulan berikutnya" di PMK 68/2010 Ps. 4 ayat (2), yang sudah dicabut oleh PMK 164/2023 Ps. 24 huruf a. Materi apa pun yang masih memakai tenggat akhir bulan berikutnya sudah usang.

Perhatikan bahwa yang dipakai adalah akumulasi berjalan, bukan angka akhir tahun. Pengusaha yang melewati batas di Agustus lalu omzetnya turun tetap wajib melapor.

### 4.2 Kapan mulai memungut

Empat jalur, dengan titik mulai yang berbeda:

| Jalur | Mulai memungut | Dasar |
| --- | --- | --- |
| **A.** Melapor tepat waktu, tanpa memilih masa pajak | Masa Pajak pertama **tahun buku berikutnya** | Ps. 18 ayat (1) |
| **B.** Melapor tepat waktu dan memilih masa pajak lebih awal | Masa Pajak yang dipilih | Ps. 20 ayat (4) |
| **C.** Terlambat melapor | Masa Pajak saat dikukuhkan, **ditambah** kewajiban atas periode sejak masa pajak pertama tahun buku berikutnya sampai sebelum dikukuhkan | Ps. 19 ayat (1)–(2) |
| **D.** Dikukuhkan secara jabatan | Sama dengan jalur C | Ps. 19 ayat (1) huruf b |

Jalur C adalah yang paling mahal, dan justru paling mudah terjadi pada pengguna yang tidak sadar batasnya sudah terlewat. Di sinilah nilai Catatin untuk segmen ini: memberi tahu **sebelum** akhir tahun buku, bukan sesudah.

### 4.3 Pengusaha kecil yang memilih dikukuhkan

Pengusaha yang belum melewati batas boleh memilih dikukuhkan. Ia menyampaikan permohonan disertai pemberitahuan masa pajak untuk mulai memungut.

*Dasar: PMK 164/2023 Ps. 21 ayat (1)–(5).*

Catatan dari contoh resmi: masa pajak yang dipilih tidak boleh melewati Masa Pajak Januari tahun berikutnya.

### 4.4 Pencabutan pengukuhan

PKP yang peredaran bruto dan/atau penerimaan brutonya dalam satu tahun buku tidak melebihi batas dapat mengajukan pencabutan pengukuhan (PMK 68/2010 Ps. 7). Catatin cukup menampilkan informasinya bila kondisi itu terpenuhi; prosesnya di luar cakupan.

## 5. Kasus resmi sebagai jangkar validasi

Enam kasus di bawah disalin dari PMK 164/2023 Lampiran huruf I. Angka dan tanggalnya dipakai apa adanya sebagai dasar `CASES-PPN.csv`.

| ID | Subjek | Lewat batas | Melapor | Dikukuhkan | Mulai memungut | Jalur |
| --- | --- | --- | --- | --- | --- | --- |
| PN-01 | Tuan A (terdaftar 31 Jan 2024) | 23 Agu 2024 | 14 Okt 2024, tanpa pemberitahuan masa | 1 Jan 2025 | Masa Jan 2025 | A |
| PN-02 | PT B | 2 Jun 2024 | 22 Agu 2025 (terlambat; batas 31 Des 2024) | 1 Jan 2026 | Masa Jan 2026, **ditambah** kewajiban periode 1 Jan – 31 Des 2025 | C |
| PN-03 | CV C (terdaftar 16 Mei 2024) | 14 Okt 2024 | tidak melapor | 15 Sep 2025, secara jabatan | 15 Sep 2025, **ditambah** kewajiban periode 1 Jan – 14 Sep 2025 | D |
| PN-04 | PT D | 13 Jul 2024 | 9 Sep 2024, memilih Masa Okt 2024 | 1 Okt 2024 | Masa Okt 2024 | B |
| PN-05 | Nyonya E | belum lewat | 14 Okt 2024, memilih Masa Des 2024 | 1 Des 2024 | Masa Des 2024 | Pilihan |
| PN-06 | CV F | belum lewat | 9 Sep 2024, memilih Masa Sep 2024 | 10 Sep 2024 | 10 Sep 2024 | Pilihan |

PN-02 dan PN-03 adalah kasus terpenting untuk produk: keduanya menunjukkan bahwa keterlambatan tidak sekadar menggeser tanggal mulai, melainkan menimbulkan kewajiban atas periode yang sudah lewat.

## 6. Yang harus ditampilkan Catatin

1. **Akumulasi tahun buku berjalan terhadap batasan pengusaha kecil**, diperbarui tiap transaksi. Ini yang sekarang ditampilkan sebagai `pkpPercent`.
2. **Label yang membedakan dua ambang.** "Ambang PKP" tidak boleh dibaca sebagai ambang PPh Final. Keduanya kebetulan bernilai sama, tetapi diukur dari periode yang berbeda (F-03).
3. **Peringatan saat batas terlewati**, berisi dua tenggat: batas melapor (akhir tahun buku) dan perkiraan mulai memungut (masa pajak pertama tahun buku berikutnya).
4. **Bukan** perhitungan PPN terutang. Catatin memberi tahu posisi dan tenggat, titik.

## 7. Pertanyaan terbuka

| ID | Pertanyaan | Berdampak ke |
| --- | --- | --- |
| Q-63-1 | Besaran batasan pengusaha kecil. **Sebagian terjawab:** mekanismenya dari PMK 68/2010 Ps. 1; angka Rp600 juta di teks aslinya sudah diubah PMK 197/2013. Perlu teks PMK 197/2013 untuk memastikan Rp4,8 miliar | Seluruh perhitungan bagian ini |
| Q-63-2 | Tahun buku = tahun kalender? **Terjawab untuk OP pencatatan** (PMK 68/2010 Ps. 1 ayat (3)). Masih terbuka untuk pengguna badan atau OP yang menyelenggarakan pembukuan dengan tahun buku berbeda | Model data |
| Q-63-3 | Basis akumulasi batas PKP. **Terjawab:** berbeda dari PPh Final — lihat §3.1 | SPEC-Kategori, mesin tarif |
| Q-63-8 | Daftar penyerahan yang bukan objek PPN yang relevan bagi pengguna UMKM | §3.1, SPEC-Kategori |
| Q-63-4 | PMK 131/2024: status keberlakuan menjelang rilis. **Terjawab sementara:** berlaku sejak 1 Jan 2025 dan dinyatakan tidak berubah untuk 2026; perlu ditengok ulang sebelum M5 | Bagian 2 |
| Q-63-6 | Pembulatan nilai lain 11/12 yang menghasilkan pecahan rupiah, dan apakah pembulatan dilakukan pada DPP atau pada PPN terutang. Terkait Q-46-2 | Mesin tarif |
| Q-63-7 | Apakah skema besaran tertentu dan nilai lain tersendiri (PMK 131/2024 Ps. 4) masuk cakupan, atau pengguna skema itu dinyatakan tidak didukung? | Cakupan, label UI |
| Q-63-5 | Apakah pengguna perlu diberi tahu opsi memilih dikukuhkan lebih awal (Ps. 21), atau itu di luar cakupan? | Cakupan produk |

---

# Bagian 2 — Tarif dan Dasar Pengenaan

**Dasar:** PMK 131/2024, berlaku sejak 1 Januari 2025.

## 9. Dua jalur perhitungan

| Jalur | Objek | Rumus | Tarif efektif | Dasar |
| --- | --- | --- | --- | --- |
| **Mewah** | Impor dan penyerahan BKP tergolong mewah: kendaraan bermotor dan selain kendaraan bermotor yang dikenai PPnBM | 12% × harga jual atau nilai impor | 12% | Ps. 2 ayat (1)–(3) |
| **Umum** | Seluruh sisanya: BKP selain yang di atas, **semua** JKP, serta pemanfaatan BKP tidak berwujud dan JKP dari luar Daerah Pabean | 12% × nilai lain, dengan nilai lain = 11/12 × harga jual, penggantian, atau nilai impor | 11% | Ps. 3 ayat (1)–(3) |

**Untuk Catatin, praktis hanya jalur umum yang relevan.** Pengguna UMKM menyerahkan barang biasa dan jasa, bukan kendaraan bermotor atau barang yang dikenai PPnBM. Jalur mewah tetap dicatat di sini supaya pemetaannya lengkap, tetapi tidak perlu dimodelkan di M5.

### 9.1 Cara menuliskannya

Tarifnya **12% dengan dasar pengenaan berupa nilai lain**, bukan tarif 11%. Hasil akhirnya memang sama, tetapi bentuk hukumnya berbeda, dan Catatin memilih menunjukkan dasar hukum apa adanya. Label di UI karena itu sebaiknya menyebut keduanya: besaran yang harus dipungut, dan rumus yang melahirkannya.

Contoh untuk penyerahan Rp600.000:

```text
Nilai lain (DPP) = 11/12 × Rp600.000 = Rp550.000
PPN terutang    = 12% × Rp550.000   = Rp66.000
```

### 9.2 Pengecualian

PKP yang memungut dengan dasar pengenaan nilai lain yang sudah diatur tersendiri, atau dengan besaran tertentu, dikecualikan dari kedua jalur di atas (Ps. 4). Skema semacam ini ada untuk kegiatan usaha tertentu. Catatin belum memodelkannya (Q-63-7), dan sampai itu diputuskan, hasil hitung PPN hanya boleh ditampilkan sebagai perkiraan untuk skema umum.

### 9.3 Pajak masukan

Pajak masukan atas perolehan yang berkaitan dengan penyerahan pada kedua jalur **dapat dikreditkan** sesuai ketentuan yang berlaku (Ps. 2 ayat (4) dan Ps. 3 ayat (4)). Artinya angka yang ditampilkan Catatin adalah PPN atas satu transaksi penjualan, bukan jumlah yang harus disetor satu masa. Perbedaan ini wajib dinyatakan di UI; kalau tidak, pengguna akan membaca angka itu sebagai utang pajaknya.

Mekanisme pengkreditannya sendiri di luar cakupan M5.

## 10. Status keberlakuan

PMK 131/2024 berlaku sejak 1 Januari 2025 (Ps. 6). Ketentuan transisi di Ps. 5 — penyerahan BKP mewah kepada konsumen akhir memakai nilai lain selama 1–31 Januari 2025 — sudah lewat dan tidak perlu dimodelkan.

Pemerintah menyatakan pada Agustus 2025 bahwa tidak ada perubahan kebijakan tarif PPN untuk 2026, sehingga ketentuan PMK 131/2024 masih berlaku. Ini pernyataan pejabat yang dikutip media, bukan peraturan; status berlakunya tetap perlu ditengok ulang sebelum rilis (Q-63-4).

## 11. Yang harus ditampilkan Catatin untuk bagian ini

1. Besaran PPN per transaksi penjualan, hanya bagi pengguna berstatus PKP.
2. Rumusnya ditampilkan, bukan hanya hasilnya: nilai lain 11/12, lalu tarif 12%.
3. Penegasan bahwa angka itu belum memperhitungkan pajak masukan.
4. Tidak ada perhitungan PPN kurang atau lebih bayar satu masa.
