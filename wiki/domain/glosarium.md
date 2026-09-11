# Glosarium

Istilah yang muncul di kode, antarmuka, dan dokumen Catatin. Disusun supaya
kontributor yang paham Flutter tapi bukan orang pajak — atau sebaliknya — bisa
membaca repo ini tanpa menebak.

## Istilah pajak

| Istilah | Arti |
| --- | --- |
| **DJP** | Direktorat Jenderal Pajak. Otoritas pajak Indonesia. |
| **HPP** | Di Catatin: **Harga Pokok Penjualan** — biaya langsung barang/jasa yang dijual, dipakai menghitung laba kotor. Hati-hati: di luar konteks ini "UU HPP" berarti **Harmonisasi Peraturan Perpajakan** (UU 7/2021) — dua hal berbeda yang kebetulan sama singkatannya. |
| **NPWP** | Nomor Pokok Wajib Pajak. Identitas wajib pajak. |
| **Omzet** | Peredaran bruto — total penjualan sebelum dikurangi biaya apa pun. Dasar pengenaan PPh Final. |
| **PKP** | Punya dua arti, dan keduanya dipakai di repo ini: <br>1. **Pengusaha Kena Pajak** — status usaha yang wajib memungut PPN, dipicu omzet melewati Rp 4,8 M/tahun. Ini arti yang dipakai di profil usaha dan `isPkp`. <br>2. **Penghasilan Kena Pajak** — dasar pengenaan PPh setelah dikurangi PTKP. Ini arti `PPh21Result.pkp`. |
| **PP 23/2018** | Peraturan Pemerintah yang mengatur PPh Final 0,5% untuk UMKM. |
| **PMK 168/2023** | Peraturan Menteri Keuangan yang memperkenalkan metode TER untuk PPh 21. |
| **PPh Badan** | PPh untuk wajib pajak badan (PT, CV). Tarifnya ada sebagai konstanta di repo, tapi belum dipakai. |
| **PPh Final** | PPh yang selesai saat dibayar — tidak diperhitungkan lagi di SPT Tahunan. Tarif UMKM-nya 0,5% dari omzet. |
| **PPh 21** | PPh atas penghasilan karyawan, dipotong pemberi kerja. |
| **PPN** | Pajak Pertambahan Nilai, 11%. Hanya dipungut oleh PKP. |
| **PTKP** | Penghasilan Tidak Kena Pajak. Batas penghasilan yang bebas PPh, besarnya tergantung status kawin dan jumlah tanggungan. |
| **SPT Tahunan** | Surat Pemberitahuan Tahunan. Laporan pajak setahun, jatuh tempo 30 April tahun berikutnya. |
| **TER** | Tarif Efektif Rata-rata. Satu tarif yang langsung dikalikan gaji kotor, tanpa hitung PKP bulanan. Terbagi kategori A/B/C menurut status PTKP. |
| **TK/0, K/2, …** | Kode status PTKP. `TK` = tidak kawin, `K` = kawin; angkanya jumlah tanggungan. `K/2` = kawin dengan 2 tanggungan. |
| **UMKM** | Usaha Mikro, Kecil, dan Menengah. Pengguna sasaran Catatin. |
| **WP / WP OP** | Wajib Pajak / Wajib Pajak Orang Pribadi. |

Rincian cara tiap aturan dipakai ada di [Aturan pajak](aturan-pajak.md).

## Istilah teknis khas repo ini

| Istilah | Arti |
| --- | --- |
| **`DS`** | Kelas token desain (warna permukaan, teks, aksen) di `app/lib/core/theme/design_tokens.dart`. |
| **`Typo`** | Kelas gaya teks (`Typo.sans`, `Typo.serif`). Dulu bernama `T`, diganti karena bentrok dengan parameter generic — lihat T-15. |
| **`Space`, `Radii`** | Token jarak dan radius sudut, sekeluarga dengan `DS` dan `Typo`. |
| **Mode data** | Pemilihan sumber data saat build: `sample`, `hybrid`, atau `api`. Lihat [Mulai cepat](../panduan/mulai-cepat.md). |
| **`--dart-define`** | Cara Flutter menyuntikkan konfigurasi saat build tanpa mengubah kode. Dipakai memilih mode data dan URL backend. |
| **Repository / fasad** | Lapisan yang memisahkan layar dari sumber data. Seluruh kode HTTP terkumpul di `app/lib/core/data/api_repositories.dart`; layar tidak pernah memanggil jaringan langsung. |
| **Hasil build di root** | `index.html`, `main.dart.js`, `assets/`, `canvaskit/`, `icons/` di root repo. Digenerate `flutter build web` dan **di-commit sengaja** — itulah yang disajikan GitHub Pages. |
| **Daftar `KEEP`** | Allowlist di `tool/sync_build.sh`. Apa pun di root yang tidak terdaftar di sana akan dihapus saat build berikutnya. Menambah folder baru di root berarti mendaftarkannya. |
| **`T-1`, `T-2`, …** | Nomor temuan audit kode. Dipakai di dokumen *dan* di komentar kode, jadi keduanya bisa dicocokkan dengan `grep`. Daftarnya di [backlog teknis](../proyek/backlog-teknis.md). |
| **Fase Dua** | Periode kerja 14 Sep – 13 Nov 2026: mencabut Pustaka peraturan, memperdalam Pembukuan dan Simulator. Lihat [linimasa](../proyek/linimasa.md). |

---

## Halaman terkait

- [Aturan pajak](aturan-pajak.md) — rumus, tarif, dan batasan yang dipakai Catatin.
- [Arsitektur](../arsitektur/gambaran-umum.md) — lapisan aplikasi dan isi `app/lib/`.
