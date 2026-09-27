# SPEC — Pemetaan Kategori Transaksi ke Relevansi Pajak dan HPP

**Issue:** #47
**Status:** Selesai untuk review — dicocokkan dengan `app/lib/core/data/mock_data.dart` (15 kategori: 4 INCOME, 11 EXPENSE)
**Dasar hukum:** PP 55/2022 Bab X; PMK 164/2023; UU PPh s.t.d.d. UU 7/2021
**Log keputusan:** `docs/tax/DECISIONS.md`

---

## 1. Dua kolom, dua fungsi yang berbeda

| Kolom | Dipakai untuk | Efek pajak |
| --- | --- | --- |
| `peredaran_bruto` | Dasar pengenaan PPh Final, akumulasi ambang Rp500 juta, dan batas Rp4,8 miliar | **Langsung.** Salah petakan berarti angka pajak salah |
| `hpp` | Perhitungan laba kotor di dashboard | **Tidak ada.** PPh Final dihitung dari bruto, bukan dari laba. HPP hanya memengaruhi tampilan untung |

Konsekuensinya, keraguan pada kolom `peredaran_bruto` harus diselesaikan dengan dasar hukum. Keraguan pada kolom `hpp` cukup diselesaikan dengan konvensi akuntansi yang konsisten.

## 2. Aturan keputusan

### 2.1 Kategori pemasukan

Pertanyaan diajukan berurutan. Jawaban pertama yang "Tidak" menghentikan penilaian.

1. **Apakah ini imbalan dari kegiatan usaha?** Setoran modal, pinjaman, dan uang pribadi bukan imbalan usaha → `peredaran_bruto = Tidak`.
   *Dasar: PP 55/2022 Ps. 56 ayat (1); PMK 164/2023 Ps. 6 ayat (2).*
2. **Apakah penghasilan ini dikecualikan dari PPh Final UMKM?** Ada empat kelompok yang dikecualikan → `Tidak`:
   - jasa sehubungan dengan pekerjaan bebas yang diterima orang pribadi;
   - penghasilan dari luar negeri;
   - penghasilan yang sudah dikenai PPh final dengan ketentuan tersendiri;
   - penghasilan yang bukan objek pajak.

   *Dasar: PP 55/2022 Ps. 56 ayat (3)–(4); PMK 164/2023 Ps. 3 ayat (3)–(4), Lampiran B Contoh 1 dan 2.*
3. **Apakah nilainya bruto?** Nilai harus dicatat **sebelum** potongan penjualan, potongan tunai, dan potongan sejenis. Kategori yang menyimpan angka neto adalah cacat data, bukan soal pemetaan.
   *Dasar: PP 55/2022 Ps. 60 ayat (4); PMK 164/2023 Ps. 6 ayat (2).*

Pengecualian di langkah 2 juga berlaku untuk **batas Rp4,8 miliar**, bukan hanya untuk dasar pajak (PMK 164/2023 Lampiran B Contoh 1 dan 2).

### 2.2 Kategori pengeluaran

1. **Apakah biaya ini melekat langsung pada barang atau jasa yang dijual?** Kalau ya → `hpp = Ya`.
2. **Apakah ini pengeluaran usaha sama sekali?** Pengambilan pribadi (prive), pembayaran pokok pinjaman, dan pembelian aset **bukan beban**. Kategori seperti ini tidak boleh mengurangi laba di dashboard.

Tidak ada kategori pengeluaran yang mengurangi `peredaran_bruto`, termasuk diskon penjualan (F-02).

### 2.3 Status dan perilaku default

| Status | Arti | Perilaku di kode |
| --- | --- | --- |
| `Ya` / `Tidak` | Sudah diputuskan, ada dasarnya | Dipakai apa adanya |
| `CEK` | Belum dipastikan | Pakai default di kolom catatan, dan tampilkan penanda di UI |

Untuk kolom `peredaran_bruto`, default kategori `CEK` dipilih **konservatif**, yaitu dihitung sebagai bruto. Alasannya, lebih aman pengguna melihat angka yang mungkin terlalu tinggi dan bertanya, daripada melihat angka nol lalu tidak menyetor.

## 3. Matriks arketipe

Kolom `kategori_kode` diisi setelah `mock_data.dart` / `tx-categories` dibaca. Satu arketipe boleh dipetakan ke lebih dari satu kategori di kode. Kategori di kode yang tidak cocok dengan arketipe mana pun harus ditambahkan sebagai baris baru, bukan dipaksakan masuk.

### 3.1 Pemasukan

| ID | Arketipe | `kategori_kode` | `peredaran_bruto` | `taxRelevant` di kode | Dasar | Catatan |
| --- | --- | --- | --- | --- | --- | --- |
| M-01 | Penjualan barang dagangan / produk | `ic1` Penjualan Produk | **Ya** | true — cocok | PP 55 Ps. 56(1); PMK 164 Ps. 6(2) | Dicatat bruto, sebelum diskon |
| M-02 | Penjualan jasa usaha | `ic2` Penjualan Jasa | **Ya** | true — cocok, tapi lihat M-03 | PP 55 Ps. 56(1) | |
| M-03 | Jasa pekerjaan bebas oleh orang pribadi | — (tidak ada) | **Tidak** | — | PP 55 Ps. 56(3)a, (4); PMK 164 Ps. 3(3)a, (4) | **Celah.** Konsultan, pengajar, perantara, agen asuransi, distributor MLM. Saat ini akan tercatat di `ic2` atau `ic3` dan ikut dihitung |
| M-04 | Penghasilan usaha dari luar negeri | — | **Tidak** | — | PMK 164 Ps. 3(3)b; Lampiran B Contoh 2 | Tidak dihitung, termasuk untuk batas Rp4,8 M |
| M-05 | Sewa tanah dan/atau bangunan | — (masuk `ic4`) | **Tidak** | — | PMK 164 Ps. 3(3)c; UU PPh Ps. 4 ayat (2) | Sudah final tersendiri |
| M-06 | Jasa konstruksi | — (masuk `ic2`) | **Tidak** | — | PMK 164 Ps. 3(3)c; Lampiran B Contoh 1 | Sudah final tersendiri |
| M-07 | Bunga tabungan / deposito | — (masuk `ic4`) | **Tidak** | — | PMK 164 Ps. 3(3)c; UU PPh Ps. 4 ayat (2) | |
| M-08 | Setoran modal pemilik | — (tidak ada) | **Tidak** | — | PP 55 Ps. 56(1) | **Celah paling berbahaya.** Lihat §6 |
| M-09 | Pinjaman masuk | — (tidak ada) | **Tidak** | — | PMK 164 Ps. 6(2) | Idem |
| M-10 | Hibah, bantuan program, hadiah | — (masuk `ic4`) | **Tidak** | — | PMK 164 Ps. 3(3)d, Ps. 6(2) | |
| M-11 | Penjualan aset usaha | — (masuk `ic4`) | **CEK** | — | — | Q-47-1. Default konservatif: Ya |
| M-12 | Uang muka / DP dari pelanggan | — (masuk `ic1`/`ic2`) | **CEK** | — | PMK 164 Ps. 6(2) | Q-47-2. Default: Ya saat diterima |
| M-13 | Komisi | `ic3` Komisi | **CEK** | true — **berisiko** | PMK 164 Ps. 3(4) huruf h, j, k | Komisi perantara, agen asuransi, dan distributor MLM adalah pekerjaan bebas, jadi **bukan** objek PPh Final UMKM bagi orang pribadi. Q-47-6 |
| M-14 | Pendapatan lain-lain (campuran) | `ic4` Pendapatan Lain | **CEK** | true | — | Menampung M-05, M-07, M-10, M-11 sekaligus. Q-47-3 |

### 3.2 Pengeluaran

Di bawah PPh Final, tidak ada satu pun kategori pengeluaran yang memengaruhi pajak. Kolom `taxRelevant` pada kategori EXPENSE karena itu tidak punya makna hukum — lihat §6.

| ID | Arketipe | `kategori_kode` | `hpp` | `isCogs` di kode | Mengurangi laba? | Catatan |
| --- | --- | --- | --- | --- | --- | --- |
| K-01 | Pembelian barang dagangan | `ec2` Barang Dagangan | **Ya** | true — cocok | Ya | |
| K-02 | Bahan baku / bahan penolong | `ec1` Bahan Baku | **Ya** | true — cocok | Ya | |
| K-03 | Ongkos angkut pembelian | — (masuk `ec7`) | **Ya** | false | Ya | Q-47-7: `ec7` Transportasi menampung angkut pembelian (HPP) dan transportasi operasional (bukan HPP) |
| K-04 | Upah tenaga kerja produksi langsung | — (masuk `ec3`) | **CEK** | false | Ya | Q-47-4. `ec3` tidak membedakan produksi dan administrasi |
| K-05 | Gaji / upah administrasi | `ec3` Gaji Karyawan | Tidak | false — cocok | Ya | |
| K-06 | Sewa tempat usaha | `ec4` Sewa Tempat | Tidak | false — cocok | Ya | |
| K-07 | Listrik, air, internet | `ec5`, `ec6` | Tidak | false — cocok | Ya | |
| K-08 | Pemasaran / iklan | `ec8` Iklan & Marketing | Tidak | false — cocok | Ya | |
| K-09 | Perlengkapan kantor | `ec9` Perlengkapan Kantor | Tidak | false — cocok | Ya | |
| K-10 | Diskon / potongan penjualan | — (tidak ada) | Tidak | — | Ya | **Tidak mengurangi peredaran bruto** (F-02) |
| K-11 | Pembayaran pokok pinjaman | — (masuk `ecx`) | Tidak | — | **Tidak** | Bukan beban |
| K-12 | Pengambilan pribadi (prive) | — (masuk `ecx`) | Tidak | — | **Tidak** | Bukan beban |
| K-13 | Pembelian aset | — (masuk `ecx`) | Tidak | — | **Tidak** | Penyusutan di luar cakupan M5 |
| K-14 | Pembayaran pajak | `ec0` Pajak Dibayar | Tidak | false | CEK | Q-47-5. `taxRelevant: true` di sini menyesatkan — lihat §6 |
| K-15 | Pengeluaran lain-lain | `ecx` Pengeluaran Lain | Tidak | false | Ya | Menampung K-11 s.d. K-13 yang seharusnya **tidak** mengurangi laba |

## 4. Pertanyaan terbuka

| ID | Pertanyaan | Default sementara |
| --- | --- | --- |
| Q-47-1 | Apakah penjualan aset usaha termasuk peredaran bruto PPh Final UMKM? PP 55/2022 dan PMK 164/2023 tidak menyebutnya secara eksplisit. | Ya |
| Q-47-2 | Saat pengakuan uang muka: saat diterima atau saat penyerahan barang/jasa? | Ya, saat diterima |
| Q-47-3 | Apakah `ic4` Pendapatan Lain dan `ecx` Pengeluaran Lain dipertahankan? | Ya, dengan penanda di UI |
| Q-47-6 | Komisi: dipisah antara komisi usaha dan komisi pekerjaan bebas, atau dikeluarkan dari akumulasi? | Tetap dihitung, dengan penanda |
| Q-47-7 | `ec7` Transportasi: angkut pembelian (HPP) atau operasional? | Bukan HPP |
| Q-47-4 | `ec3` Gaji Karyawan: dipisah antara upah produksi (HPP) dan administrasi? | Bukan HPP |
| Q-47-5 | Apakah PPh Final yang dibayar ditampilkan sebagai pengurang laba? | Belum diputuskan (keputusan produk, bukan pajak) |

## 5. Syarat bagi kode (untuk FE/BE)

1. Setiap kategori pemasukan wajib punya atribut `peredaran_bruto` bernilai `Ya`, `Tidak`, atau `CEK`. Tidak boleh ada nilai kosong.
2. Nilai transaksi penjualan disimpan **bruto**. Diskon disimpan sebagai transaksi atau field terpisah, tidak dikurangkan dari nominal penjualan.
3. Akumulasi ambang Rp500 juta hanya menjumlahkan kategori `peredaran_bruto = Ya`, ditambah `CEK` sesuai default, **lintas seluruh profil usaha milik orang yang sama** (F-05).
4. Kategori K-11, K-12, dan K-13 tidak boleh mengurangi laba di dashboard. Saat ini ketiganya tertampung di `ecx`.
5. `pkpPercent` di dashboard mengukur akumulasi tahun berjalan terhadap Rp4,8 miliar. Itu ambang **pelaporan PKP**, bukan ambang kelayakan PPh Final, yang diukur dari peredaran bruto tahun sebelumnya (F-03). Label di UI harus membedakan keduanya.

---

## 6. Selisih antara kode dan pemetaan ini

Lima hal berikut perlu dijadikan issue tersendiri untuk FE/BE.

### 6.1 Tidak ada kategori pemasukan non-omzet — prioritas tertinggi

Keempat kategori INCOME bernilai `taxRelevant: true`. Artinya setoran modal, pinjaman cair, hibah, dan bantuan program **tidak punya tempat** selain `ic4` Pendapatan Lain, dan begitu masuk ke sana, semuanya ikut menambah akumulasi ambang Rp500 juta.

Akibatnya bukan sekadar angka laba yang meleset, melainkan pengguna yang belum wajib bayar bisa dinyatakan sudah wajib. Ini persis kesalahan yang paling mahal bagi kepercayaan produk.

Usulan minimal: tambah kategori INCOME dengan `taxRelevant: false`, misalnya "Modal Masuk", "Pinjaman Diterima", dan "Hibah/Bantuan".

### 6.2 `taxRelevant` menanggung dua arti sekaligus

Pada kategori INCOME, `taxRelevant` berarti "masuk peredaran bruto". Pada kategori EXPENSE, tidak ada makna hukum yang bisa dilekatkan padanya: di bawah PPh Final tidak ada biaya yang mengurangi apa pun.

Isinya juga tidak konsisten — `ec1` Bahan Baku `true`, `ec5` Listrik `false`, `ec0` Pajak Dibayar `true` — tanpa aturan yang bisa dijelaskan. Kalau dibiarkan, siapa pun yang membaca kode akan menyimpulkan aturan yang salah.

Usulan: ganti nama field menjadi `grossTurnover` dan berlaku hanya untuk INCOME. Untuk EXPENSE, isi `false` atau `null` seluruhnya.

### 6.3 Komisi kemungkinan besar bukan objek PPh Final

`ic3` Komisi bernilai `taxRelevant: true`. Padahal komisi perantara, agen asuransi, dan distributor pemasaran berjenjang termasuk jasa sehubungan dengan pekerjaan bebas (PMK 164/2023 Ps. 3 ayat (4) huruf h, j, k), sehingga bagi orang pribadi **tidak** dikenai PPh Final UMKM.

Ini membuat hitungan pajak terlalu tinggi bagi pengguna yang penghasilannya dari komisi. Perlu diputuskan: pisahkan komisi usaha dari komisi pekerjaan bebas, atau keluarkan kategori ini dari akumulasi dan beri penjelasan di UI.

### 6.4 `ecx` Pengeluaran Lain menampung yang bukan beban

Prive, pembayaran pokok pinjaman, dan pembelian aset akan tercatat di sini, lalu mengurangi laba seolah-olah beban usaha. Laba yang ditampilkan menjadi lebih rendah dari yang sebenarnya.

### 6.5 Tenggat SPT Tahunan di data contoh

`MockData.deadlines` memakai 30 April untuk SPT Tahunan. Untuk **Wajib Pajak orang pribadi**, batasnya 3 bulan setelah akhir Tahun Pajak, yaitu 31 Maret; 30 April berlaku untuk Wajib Pajak badan.

*Dasar: UU KUP Ps. 3 ayat (3) `[CEK huruf]`.*

Catatan tambahan untuk kalender pajak: pada bulan yang akumulasi peredaran brutonya belum melewati Rp500 juta, tidak ada kewajiban menyampaikan SPT Masa PPh Unifikasi (PMK 164/2023 Ps. 7 ayat (4) huruf c). Tenggat tanggal 15 tetap hanya muncul bila ada PPh yang harus disetor.

---

## 7. Transaksi berulang (#62)

Fitur transaksi berulang menerbitkan transaksi secara otomatis dari templat lewat daily job. Bagian ini mengatur dua hal: kapan transaksi terbitan otomatis boleh dihitung, dan bagaimana cicilan serta leasing dipetakan.

### 7.1 Transaksi terbitan otomatis — aturan yang berdampak pajak

**R-1. Transaksi terbitan otomatis berstatus `terjadwal` sampai dikonfirmasi pengguna.** Selama berstatus itu, transaksi **tidak** masuk ke:

- akumulasi peredaran bruto dan ambang Rp500 juta;
- `ytdOmzet` dan `pkpPercent`;
- perhitungan PPh Final bulanan;
- laba di dashboard.

*Dasar:* peredaran bruto adalah imbalan yang **diterima atau diperoleh** (PMK 164/2023 Ps. 6 ayat (2)). Templat yang menerbitkan transaksi belum membuktikan uangnya diterima. Pengguna yang lupa menghentikan templat pemasukan bisa dinyatakan wajib setor atas uang yang tidak pernah masuk.

**R-2. Tanggal transaksi adalah tanggal uang diterima atau dibayar, bukan tanggal terbit.** Saat mengonfirmasi, pengguna harus bisa mengoreksi tanggalnya. Tanggal menentukan masa pajak (PMK 164/2023 Ps. 6 ayat (1)), dan pada bulan saat ambang terlewati, selisih satu hari bisa memindahkan pajak ke masa yang berbeda.

**R-3. Konfirmasi yang terlambat bisa mengubah hitungan masa yang sudah lewat.** Kalau transaksi Juni baru dikonfirmasi Agustus, akumulasi Juni berubah, dan PPh Final Juni–Juli ikut berubah. Aplikasi wajib memberi tahu masa mana yang hitungannya berubah, karena itu bisa berarti ada kurang setor di masa sebelumnya.

**R-4. Templat pemasukan yang sering berulang harus dipetakan dengan benar sejak awal.** Contoh yang paling umum adalah sewa bangunan atau kamar yang diterima tiap bulan. Itu masuk `ic8` Penghasilan Final Lainnya, bukan `ic1`/`ic2`, karena sudah final tersendiri (PMK 164/2023 Ps. 3 ayat (3) huruf c). Salah petakan di templat berarti salah dua belas kali setahun.

### 7.2 Cicilan dan leasing — pemetaan kategori

Di bawah PPh Final, tidak ada satu pun pembayaran di bawah ini yang memengaruhi pajak. Pemetaannya hanya menentukan angka **laba**.

| Pembayaran berulang | Bagian | `isCogs` | Mengurangi laba? | Catatan |
| --- | --- | --- | --- | --- |
| Cicilan pembelian aset (kendaraan, mesin) | Pokok | Tidak | **Tidak** | Pelunasan utang, bukan beban (K-11/K-13) |
| | Bunga | Tidak | Ya | Beban keuangan, **bukan HPP** — tidak melekat pada barang yang dijual |
| Cicilan utang ke pemasok barang dagangan | Pokok | Ya | Ya | Basis kas: diakui sebagai Barang Dagangan saat dibayar (Q-62-1) |
| | Bunga / denda | Tidak | Ya | Beban keuangan |
| Pinjaman modal kerja | Pokok | Tidak | **Tidak** | K-11 |
| | Bunga | Tidak | Ya | Beban keuangan |
| Leasing dengan hak opsi | Pokok | Tidak | **Tidak** | Diperlakukan seperti pembelian dengan cicilan `[CEK dasar]` (Q-62-2) |
| | Bunga | Tidak | Ya | Beban keuangan |
| Leasing tanpa hak opsi | Seluruhnya | Tidak | Ya | Diperlakukan seperti sewa, beban operasional `[CEK dasar]` (Q-62-2) |

**Konsekuensi untuk templat:** satu pembayaran cicilan berisi dua bagian dengan perlakuan berbeda. Templat cicilan harus bisa menerbitkan **dua baris** (pokok dan bunga), atau menyimpan porsi pokok dan bunga dalam satu transaksi. Satu baris tunggal dengan satu kategori pasti salah di salah satu bagian.

**Kategori yang dibutuhkan** (menunggu field `affectsProfit`, lihat §6.4):

| Kategori usulan | type | `isCogs` | `affectsProfit` |
| --- | --- | --- | --- |
| Angsuran Pokok Pinjaman | EXPENSE | false | **false** |
| Bunga Pinjaman | EXPENSE | false | true |
| Sewa Guna Usaha (tanpa hak opsi) | EXPENSE | false | true |

### 7.3 Di luar cakupan M5

- **Pemotongan PPh atas bunga yang dibayar pengguna.** Bunga yang dibayar kepada pemberi pinjaman selain bank bisa menjadi objek pemotongan, tetapi orang pribadi UMKM umumnya bukan pemotong kecuali ditunjuk `[CEK]`.
- **Templat gaji berulang.** Memicu kewajiban PPh 21 bulanan. Fitur PPh 21 hanya berlaku masa Januari–November, dan batasan itu harus tampil di templat gaji, bukan hanya di simulator.
- **Penyusutan aset** dari cicilan pembelian aset.

### 7.4 Pertanyaan terbuka

| ID | Pertanyaan | Default sementara |
| --- | --- | --- |
| Q-62-1 | Catatin memakai basis kas atau akrual? R-1 dan tabel §7.2 disusun dengan asumsi basis kas. | Basis kas |
| Q-62-2 | Dasar perlakuan pajak leasing dengan dan tanpa hak opsi yang berlaku sekarang. | Seperti tabel §7.2 |
| Q-62-3 | Batas waktu transaksi `terjadwal` yang tidak pernah dikonfirmasi: dihapus otomatis, atau tetap menunggu? | Tetap menunggu, tidak dihitung |

---

## 8. Kolom ketiga: masuk akumulasi batas PKP

Batas PKP menjumlahkan seluruh penyerahan BKP dan JKP dalam rangka kegiatan usaha (PMK 68/2010 Ps. 1 ayat (2)), bukan peredaran bruto PPh Final. Karena itu setiap kategori INCOME butuh atribut kedua, terpisah dari `taxRelevant`/`grossTurnover`. Rincian alasannya ada di SPEC-PPN §3.1.

| Kategori | PPh Final | Batas PKP | Catatan |
| --- | --- | --- | --- |
| `ic1` Penjualan Produk | Ya | Ya | |
| `ic2` Penjualan Jasa | Ya | Ya | Termasuk jasa pekerjaan bebas yang tercampur di sini |
| `ic3` Komisi | CEK | **Ya** | Jasa perantara tetap JKP meski bukan objek PPh Final |
| `ic4` Pendapatan Lain | CEK | CEK | Campuran |
| `ic5` Modal Masuk | Tidak | Tidak | Bukan penyerahan |
| `ic6` Pinjaman Diterima | Tidak | Tidak | Bukan penyerahan |
| `ic7` Hibah & Bantuan | Tidak | Tidak | Bukan penyerahan |
| `ic8` Penghasilan Final Lainnya | Tidak | **CEK** | Sewa bangunan dan jasa konstruksi adalah JKP; bunga bank bukan. Kategori ini perlu dipecah (Q-63-9) |

Usulan nama field: `vatTurnover` (boolean atau `CEK`), khusus INCOME. `pkpPercent` di dashboard harus menjumlahkan kategori `vatTurnover = true`, bukan `taxRelevant = true`.
