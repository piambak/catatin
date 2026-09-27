# SPEC — Kolom Wajib Ekspor CSV

**Issue:** #77
**Status:** Draf untuk review
**Dasar:** UU KUP Ps. 28; PMK 164/2023 Lampiran huruf D.1; PP 55/2022; PMK 168/2023
**Log keputusan:** `docs/tax/DECISIONS.md`

---

## 1. Apa yang sedang ditulis, dan apa yang bukan

Catatin melakukan **pencatatan**, bukan pembukuan (F-17): UU KUP Pasal 28 ayat (2) mengizinkan Wajib Pajak orang pribadi yang boleh memakai Norma Penghitungan Penghasilan Neto, atau yang tidak melakukan kegiatan usaha, untuk cukup mencatat. Pembukuan penuh mensyaratkan catatan harta, kewajiban, dan modal (ayat (7)); Catatin belum mencatat ketiganya.

Karena itu ekspor Catatin adalah **catatan peredaran bruto dan penghasilan**, bukan laporan keuangan dan bukan SPT. Label di setiap file ekspor harus menyatakan ini secara eksplisit, supaya tidak dibaca sebagai dokumen yang lebih dari yang sebenarnya.

**Termasuk:** kolom wajib untuk dua jenis ekspor (rincian transaksi, rekap bulanan), aturan isi berdasarkan Pasal 28, dan aturan akses.

**Di luar cakupan:** ekspor PDF, e-Faktur, dan format yang dipersyaratkan khusus oleh aplikasi pelaporan pihak ketiga (F-01 di dokumen segmen promosi mikro sudah melarang klaim "diterima bank/program bantuan").

## 2. Dasar hukum yang membentuk isi

### 2.1 Apa yang wajib ada dalam pencatatan

Pencatatan terdiri atas data yang dikumpulkan secara teratur tentang peredaran atau penerimaan bruto dan/atau penghasilan bruto sebagai dasar menghitung pajak terutang, **termasuk penghasilan yang bukan objek pajak dan/atau yang dikenai pajak final**.

*Dasar: UU KUP Ps. 28 ayat (9).*

Konsekuensi langsung: kategori `ic5`–`ic8` (modal, pinjaman, hibah, penghasilan final lainnya) **wajib ikut diekspor**, dengan status yang jelas bahwa mereka dikecualikan dari akumulasi pajak — bukan dihilangkan dari catatan.

### 2.2 Bahasa, aksara, dan mata uang

Pencatatan diselenggarakan di Indonesia dengan huruf Latin, angka Arab, satuan mata uang Rupiah, disusun dalam bahasa Indonesia (atau bahasa asing yang diizinkan Menteri Keuangan).

*Dasar: UU KUP Ps. 28 ayat (4).*

Konsekuensi: transaksi valuta asing wajib dikonversi ke Rupiah saat dicatat, dengan kurs dan tanggal kurs yang dipakai ikut tersimpan (lihat F-19, terkait #78). Ekspor tidak menampilkan mata uang asing sebagai nilai utama.

### 2.3 Masa simpan dan hak akses

Buku, catatan, dan dokumen yang menjadi dasar pencatatan, termasuk hasil pengolahan data dari aplikasi online, wajib disimpan **10 tahun**.

*Dasar: UU KUP Ps. 28 ayat (11).*

Konsekuensi (F-18): kewajiban ini ada pada pengguna, bukan pada Catatin, tetapi Catatin tidak boleh menjadi penghalang untuk memenuhinya. Batasan "riwayat 12 bulan" di tingkat gratis pada proposal promosi (segmen mendekati PKP) tidak boleh berarti data lama tidak bisa diekspor. Lihat §5.

## 3. Ekspor 1 — Rincian Transaksi

Satu baris per transaksi. Ini bentuk paling dasar, dan yang paling dekat dengan definisi "pencatatan" di UU KUP.

| Kolom | Wajib | Isi | Dasar |
| --- | --- | --- | --- |
| `tanggal` | Ya | Tanggal transaksi diterima/dibayar (bukan tanggal templat terbit — F-14) | UU KUP Ps. 28 ayat (9) |
| `kategori` | Ya | Nama kategori sesuai `tx-categories` | |
| `arah` | Ya | Pemasukan / Pengeluaran | |
| `deskripsi` | Ya | Teks bebas dari pengguna | |
| `nominal_rupiah` | Ya | Bruto, dalam Rupiah, sudah dikonversi bila asalnya valuta asing | UU KUP Ps. 28 ayat (4) |
| `mata_uang_asal` | Kondisional | Diisi bila transaksi awalnya bukan Rupiah; kosong bila Rupiah | F-19 |
| `kurs_dipakai` | Kondisional | Kurs konversi, kosong bila Rupiah | F-19 |
| `masuk_peredaran_bruto_pph` | Ya | Ya/Tidak/CEK — nilai `taxRelevant`/`grossTurnover` kategori saat transaksi dicatat | F-11 |
| `masuk_batas_pkp` | Ya | Ya/Tidak/CEK — nilai `vatTurnover` kategori saat transaksi dicatat | F-15 |
| `status_konfirmasi` | Kondisional | Untuk transaksi dari templat berulang: terjadwal/dikonfirmasi | F-14 |
| `metode_pembayaran` | Ya | Sesuai field yang sudah ada di `TxData` | |

**Catatan penting:** kolom `masuk_peredaran_bruto_pph` dan `masuk_batas_pkp` merekam nilai kategori **pada saat transaksi dicatat**, bukan nilai kategori saat ini. Kalau kategori diubah di kemudian hari (misalnya `ic3` Komisi dipisah per Q-47-6), riwayat ekspor lama tidak boleh ikut berubah retroaktif — itu akan mengubah dasar SPT yang sudah dilaporkan.

## 4. Ekspor 2 — Rekap Bulanan

Mengikuti struktur baris resmi PMK 164/2023 Lampiran D.1 (Laporan Rincian Peredaran Bruto bagi WP Orang Pribadi), supaya bisa dipetakan langsung ke lampiran SPT Tahunan tanpa penyusunan ulang oleh pengguna.

| Baris | Isi | Dasar |
| --- | --- | --- |
| a. Jumlah peredaran bruto | Total kategori `masuk_peredaran_bruto_pph = Ya` per bulan | Lampiran D.1 baris a |
| b. Akumulasi peredaran bruto | Kumulatif sejak awal Tahun Pajak | Lampiran D.1 baris b |
| c. Peredaran bruto tidak kena pajak | Bagian sampai Rp500 juta | Lampiran D.1 baris c |
| d. Peredaran bruto kena pajak | b dikurangi bagian yang sudah dipakai di c | Lampiran D.1 baris d |
| e. PPh Final terutang | 0,5% × d | Lampiran D.1 baris e |
| f. PPh Final disetor sendiri | Dari catatan pembayaran pajak (`ec0`), bila pengguna mencatatnya | Lampiran D.1 baris f |
| g. PPh Final dipotong pihak lain | Di luar cakupan M5 (F-08); ditampilkan kosong dengan keterangan | Lampiran D.1 baris g |
| h. Selisih | e dikurangi (f + g) | Lampiran D.1 baris h |

Baris tambahan di luar format resmi, ditaruh terpisah supaya tidak mengaburkan struktur resmi:

| Baris tambahan | Isi |
| --- | --- |
| Peredaran bruto batas PKP | Total kategori `masuk_batas_pkp = Ya`, kumulatif tahun buku berjalan |
| Penghasilan dikecualikan | Total `ic5`–`ic8`, ditampilkan terpisah supaya pengguna tahu itu tercatat tapi tidak dihitung |

## 5. Aturan akses

1. **Ekspor riwayat penuh gratis di semua tingkat**, tanpa batas 12 bulan, sesuai kewajiban simpan 10 tahun yang melekat pada pengguna (F-18). Yang boleh dibatasi di tingkat gratis adalah kenyamanan (impor balik, penyimpanan skenario), bukan akses ke data sendiri.
2. **Penghapusan akun wajib menawarkan ekspor lebih dulu**, dengan peringatan eksplisit tentang kewajiban simpan 10 tahun.
3. Ekspor mencakup seluruh riwayat pengguna secara default; rentang tanggal adalah penyaring opsional, bukan pembatas akses.

## 6. Label wajib pada setiap file ekspor

```text
Dokumen ini adalah catatan peredaran bruto dan penghasilan sesuai Pasal 28
Undang-Undang KUP. Ini BUKAN laporan keuangan dan BUKAN Surat Pemberitahuan
(SPT). Angka PPh Final dan status batas PKP adalah simulasi berdasarkan data
yang Anda catat sendiri, belum diverifikasi terhadap kalkulator resmi
Direktorat Jenderal Pajak.
```

Kalimat terakhir disesuaikan begitu M4 tercapai, mengikuti aturan disclaimer di dokumen ringkasan strategi promosi.

## 7. Pertanyaan terbuka

| ID | Pertanyaan |
| --- | --- |
| Q-77-1 | Format file: CSV saja, atau juga XLSX? CSV lebih sederhana dan cukup untuk kewajiban Pasal 28; XLSX lebih ramah bagi pengguna yang akan menyerahkannya ke konsultan. |
| Q-77-2 | Apakah rekap bulanan dihitung ulang saat ekspor, atau disimpan sebagai snapshot per bulan yang sudah lewat? Terkait §3 soal riwayat yang tidak boleh berubah retroaktif. |
| Q-77-3 | Ekspor untuk pengguna dengan lebih dari satu profil usaha: satu file gabungan (mengikuti F-05, ambang dipakai bersama) atau file terpisah per profil dengan catatan bahwa ambangnya gabungan? |
