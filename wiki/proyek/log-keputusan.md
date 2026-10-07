---
title: Log Keputusan
description: "Satu tabel untuk setiap keputusan yang menahan pekerjaan orang lain: siapa pemiliknya, kapan tenggatnya, apa default-nya kalau lewat, dan apa yang akhirnya diputus."
tags:
  - proyek
  - keputusan
---

Audit 12 September menemukan **≥ 12 keputusan terbuka tanpa pemilik dan tanpa
tenggat**, tersebar di issue, PRD, dan brief desain. Setiap satu di antaranya
menahan minimal satu tugas. Halaman ini memberi mereka satu tempat.

> **Aturan mainnya**
>
> 1. Setiap keputusan punya **pemilik** (satu orang, bukan peran kolektif) dan
>    **tenggat** maksimal 5 hari kerja sejak diajukan.
> 2. Kalau tenggat lewat, **default berlaku otomatis**. Itu bukan hukuman —
>    itu supaya pekerjaan tidak berhenti menunggu rapat.
> 3. Keputusan yang hanya hidup di chat **tidak dianggap ada**. Kalau tidak
>    tercatat di tabel ini, ia masih terbuka.
> 4. Mengubah keputusan yang sudah diputus boleh, tapi lewat baris baru
>    (D-xx revisi), bukan dengan menyunting baris lama. Riwayatnya harus kebaca.

Kolom **Keputusan** diisi hasil akhirnya; **Diputus** diisi tanggal + nama.
Selama keduanya kosong, yang berlaku adalah kolom **Default**.

---

## Terbuka & sudah lewat tenggat

Default di bawah **sudah berlaku** sesuai aturan 2. PO tinggal mengkonfirmasi
(isi dua kolom terakhir) atau menimpanya dengan keputusan lain.

| ID | Diajukan | Pertanyaan | Pemilik | Tenggat | Default (berlaku) | Keputusan | Diputus |
| --- | --- | --- | --- | --- | --- | --- | --- |
| D-1 | 12 Sep | [Linimasa](linimasa.md) adalah satu-satunya jadwal; kanvas "Peta Jalan Catatin" dinyatakan usang? | PO | 14 Sep | Ya | Ya | 15 Sep 2026 · PO (issue [#143](https://github.com/piambak/catatin/issues/143) ditutup) |
| D-2 | 8 Sep | Redesain UI masuk Fase Dua sebagai jalur kerja Frontend resmi? | PO | 14 Sep | Ya | **Ya** (default). Redesain dikerjakan sebagai jalur Frontend: [PRD redesain UI](../desain/prd-redesain-ui.md) dan [Rencana Frontend](rencana-frontend.md); diterapkan mulai PR [#3](https://github.com/piambak/catatin/pull/3) | Default berlaku sejak 14 Sep 2026 (aturan 2) · dicatat BE 24 Sep, belum dikonfirmasi PO ([#144](https://github.com/piambak/catatin/issues/144)) |
| D-3 | 8 Sep | Dashboard berpusat pada "kewajiban berikutnya"? | PO | 14 Sep | Ya | **Ya** (default). Blok "Kewajiban berikutnya" sudah ada di Dashboard dan membawa chip kepercayaan ([#9](https://github.com/piambak/catatin/issues/9)) | Default berlaku sejak 14 Sep 2026 (aturan 2) · dicatat BE 24 Sep, belum dikonfirmasi PO ([#145](https://github.com/piambak/catatin/issues/145)) |
| D-4 | 8 Sep | Nama fitur tetap "Pembukuan"? | PO | 14 Sep | Ya | **Tidak** — nama fitur **Pencatatan**, sama dengan label tab dan judul layar sejak redesain 8 Sep | 15 Sep 2026 · PO ([#146](https://github.com/piambak/catatin/issues/146)) |
| D-5 | 8 Sep | Hapus 3.684 baris kode yatim (T-14, T-32)? | PO | 16 Sep | Ya, setelah tag `pra-hapus-orphan` | **Ya** (default). Tag `pra-hapus-orphan` sudah dibuat; penghapusan lewat PR [#185](https://github.com/piambak/catatin/pull/185) untuk [#32](https://github.com/piambak/catatin/issues/32) | Default berlaku sejak 16 Sep 2026 (aturan 2) · dicatat BE 24 Sep · **dikonfirmasi PO 27 Sep 2026** ([#147](https://github.com/piambak/catatin/issues/147)) |
| D-6 | 8 Sep | Navigation rail di lebar desktop? | PO | 14 Sep | Ya | **Ya** (default). `AppNavRail` diaktifkan di lebar `expanded` lewat [#67](https://github.com/piambak/catatin/issues/67) (Minggu 4) | Default berlaku sejak 14 Sep 2026 (aturan 2) · dicatat BE 24 Sep, belum dikonfirmasi PO ([#148](https://github.com/piambak/catatin/issues/148)) |
| D-8 | 7 Sep | Modul PPN & proyeksi SPT Tahunan masuk fase ini? | Pakar → PO | 18 Sep | Ditunda ke Fase Tiga | **Ditunda ke Fase Tiga.** Tiga alasan: (1) D-9, D-11, D-12, dan D-13 belum dijawab dan keempatnya sudah menahan Minggu 5 — menambah lingkup pajak sebelum yang dasar selesai memperbesar risiko yang sama; (2) PMK 131/2024 mengubah tarif **dan** dasar pengenaan PPN, jadi salah hitung di sini adalah jenis kesalahan yang paling mahal untuk aplikasi pajak; (3) `AppConstants.ppnRate` 11 % sudah dicabut karena memang salah (11 % × omzet tanpa pajak masukan), jadi tidak ada yang mundur — PPN memang belum pernah benar di aplikasi ini. Konsekuensinya: Minggu 6 Frontend tidak membangun UI PPN/proyeksi SPT, Backend tidak membuat `POST /tax/ppn` dan `GET /tax/spt-projection`, dan Pakar tidak perlu menulis `SPEC-PPN.md`. Target rilis 13 Nov dipertahankan. | 27 Sep 2026 · PO |
| D-9 | 8 Sep | T-3: pengecualian Rp500 juta & batas waktu PP 23 masuk lingkup? Untuk profil WP mana? | Pakar | 18 Sep | Masuk, WP OP saja | | |
| D-10 | 8 Sep | T-4: angka apa yang tampil di hasil PPh 21; rekalkulasi Desember di fase ini? | Pakar | 18 Sep | Tampilkan bruto, TER, potongan; Desember ditunda | Wajib tampil: kategori TER beserta status PTKP, tarif efektif, penanda masa Januari–November. Tidak tampil: angka PKP dan "pajak tahunan" hasil bulanan × 12. Rekalkulasi Desember ditunda sampai besaran biaya jabatan bersumber. Rinciannya di [Spek PPh 21 TER §6–§7](../domain/pajak/spek-pph21-ter.md#7-aturan-tampilan-d-10) | 18 Sep 2026 · TAX ([Keputusan TAX](../domain/pajak/keputusan-tax.md), [#152](https://github.com/piambak/catatin/issues/152)) |
| D-11 | 12 Sep | T-17: rezim per profesi — karyawan → PPh 21, usaha sendiri → PPh Final? | Pakar | 18 Sep | Ya | | |
| D-12 | 12 Sep | T-25: SPT OP 31 Maret; tenggat masa PPh Final tanggal 15 bulan berikutnya? | Pakar | 16 Sep | Ya | | |
| D-13 | 12 Sep | T-26: omzet di atas Rp4,8 M tampil "di luar skema final", bukan 0? | Pakar | 18 Sep | Ya | | |

## Terbuka, tenggat belum lewat

Kosong. D-14, D-15, dan D-16 diputus 24 Sep (issue #29) — lihat di bawah.

## Sudah diputus

| ID | Diajukan | Pertanyaan | Pemilik | Keputusan | Diputus |
| --- | --- | --- | --- | --- | --- |
| D-7 | 12 Sep | Stack backend: BaaS atau tulis sendiri? | Backend → PO | **Supabase.** Alasan & lingkupnya di [sumber issue #149](../sumber/github-issue-149-d7-stack-backend.md); penerapannya di [Supabase](../arsitektur/supabase.md) dan [Backend & API](../arsitektur/backend-dan-api.md) | 15 Sep 2026 |
| D-14 | 8 Sep | T-11: refresh token boleh disimpan di browser? Umur token? | Backend + Frontend → PO | **Access token 15 menit, refresh token dirotasi; refresh token boleh disimpan di browser** (`localStorage` klien Supabase; secure storage di mode REST). Cookie HTTP-only tidak dipakai karena logika aplikasi berjalan di browser dan harus bisa membaca token untuk memperbaruinya — rinciannya di [Supabase §Sesi dan token](../arsitektur/supabase.md#sesi-dan-token-d-14). Tindak lanjut Backend: pasang 900 detik di dashboard proyek **produksi** (staging sudah). Tindak lanjut Frontend: klien REST menyimpan refresh token hasil rotasi (issue #34) | 24 Sep 2026 · PO (default dikonfirmasi) |
| D-15 | 8 Sep | T-12: aplikasi multi-bahasa di fase ini? | PO | **Tidak.** Fase Dua hanya Bahasa Indonesia; multi-bahasa ke backlog Fase Tiga. Dicatat di [Arsitektur](../arsitektur/gambaran-umum.md#bahasa--orientasi) | 24 Sep 2026 · PO (default dikonfirmasi) |
| D-16 | 8 Sep | Kunci orientasi dibuka untuk web saja atau tablet juga? | PO | **Web + tablet.** Potret hanya dikunci di ponsel (sisi terpendek layar < 600 dp); diterapkan di `main.dart` lewat issue #37 | 24 Sep 2026 · PO (default dikonfirmasi) |

---

## D-17 … D-21 — artboard Catatin UI v2

Ditinjau 27 Sep 2026 (issue [#7](https://github.com/piambak/catatin/issues/7) PO dan
[#15](https://github.com/piambak/catatin/issues/15) Frontend).

> **Semua artboard diterima dengan status _masih tentatif_.** Artinya: cukup
> untuk dipakai sebagai spesifikasi kerja Minggu 3–4 sekarang, tapi boleh
> direvisi tanpa dianggap perubahan lingkup. Kalau revisinya datang setelah
> kodenya jalan, revisi itu jadi issue baru, bukan koreksi diam-diam.

| ID | Artboard / pertanyaan | Hasil | Catatan | Diputus |
| --- | --- | --- | --- | --- |
| D-17 | Seluruh artboard kanvas Catatin UI v2 | **Diterima** | Masih tentatif — lihat catatan di atas | 27 Sep 2026 · PO + FE |
| D-18 | Navigation rail di lebar desktop (menegaskan D-6) | **Ya** | Diterapkan `AppNavRail` pada lebar `expanded` lewat issue [#67](https://github.com/piambak/catatin/issues/67) | 27 Sep 2026 · PO + FE |
| D-19 | Pembukuan versi web: dua panel? | **Ya** | Daftar + detail berdampingan, artboard `PembukuanWeb`; issue [#67](https://github.com/piambak/catatin/issues/67) | 27 Sep 2026 · PO + FE |
| D-20 | Lebar maksimum konten di layar lebar | **1200 px** | Berlaku untuk semua layar, bukan hanya Pembukuan | 27 Sep 2026 · PO + FE |
| D-21 | Keadaan kosong: ilustrasi atau teks? | **Ilustrasi** — tapi teks lebih dulu | Aset ilustrasi belum ada. Minggu 3 mengirim keadaan kosong berbasis teks; ilustrasi menyusul Minggu 4. Lihat utang di bawah | 27 Sep 2026 · PO + FE |

### Utang yang lahir dari D-21

**Aset ilustrasi keadaan kosong — jatuh tempo Minggu 4 (5–9 Okt).**

Yang dikirim Minggu 3 adalah keadaan kosong teks-saja (`EmptyState` yang sudah
ada). Itu keputusan sadar supaya issue [#52](https://github.com/piambak/catatin/issues/52)
dan [#69](https://github.com/piambak/catatin/issues/69) tidak menunggu aset.

Minggu 4 harus: menyiapkan ilustrasi untuk Pembukuan kosong, Kalender tanpa
transaksi, dan hasil filter kosong; mendaftarkannya di `pubspec.yaml` dan
[Aset](../arsitektur/aset.md); lalu menambahkan parameter gambar opsional ke
`EmptyState`. **Jangan** menandai artboard keadaan kosong selesai sebelum ini
beres — teks-saja adalah kondisi sementara, bukan hasil akhir yang disepakati.
