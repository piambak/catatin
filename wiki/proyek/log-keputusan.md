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
| D-1 | 12 Sep | [Linimasa](linimasa.md) adalah satu-satunya jadwal; kanvas "Peta Jalan Catatin" dinyatakan usang? | PO | 14 Sep | Ya | | |
| D-2 | 8 Sep | Redesain UI masuk Fase Dua sebagai jalur kerja Frontend resmi? | PO | 14 Sep | Ya | | |
| D-3 | 8 Sep | Dashboard berpusat pada "kewajiban berikutnya"? | PO | 14 Sep | Ya | | |
| D-4 | 8 Sep | Nama fitur tetap "Pembukuan"? | PO | 14 Sep | Ya | | |
| D-5 | 8 Sep | Hapus 3.684 baris kode yatim (T-14, T-32)? | PO | 16 Sep | Ya, setelah tag `pra-hapus-orphan` | | |
| D-6 | 8 Sep | Navigation rail di lebar desktop? | PO | 14 Sep | Ya | | |
| D-8 | 7 Sep | Modul PPN & proyeksi SPT Tahunan masuk fase ini? | Pakar → PO | 18 Sep | Ditunda ke Fase Tiga | | |
| D-9 | 8 Sep | T-3: pengecualian Rp500 juta & batas waktu PP 23 masuk lingkup? Untuk profil WP mana? | Pakar | 18 Sep | Masuk, WP OP saja | | |
| D-10 | 8 Sep | T-4: angka apa yang tampil di hasil PPh 21; rekalkulasi Desember di fase ini? | Pakar | 18 Sep | Tampilkan bruto, TER, potongan; Desember ditunda | | |
| D-11 | 12 Sep | T-17: rezim per profesi — karyawan → PPh 21, usaha sendiri → PPh Final? | Pakar | 18 Sep | Ya | | |
| D-12 | 12 Sep | T-25: SPT OP 31 Maret; tenggat masa PPh Final tanggal 15 bulan berikutnya? | Pakar | 16 Sep | Ya | | |
| D-13 | 12 Sep | T-26: omzet di atas Rp4,8 M tampil "di luar skema final", bukan 0? | Pakar | 18 Sep | Ya | | |

## Terbuka, tenggat belum lewat

| ID | Diajukan | Pertanyaan | Pemilik | Tenggat | Default | Keputusan | Diputus |
| --- | --- | --- | --- | --- | --- | --- | --- |
| D-14 | 8 Sep | T-11: refresh token boleh disimpan di browser? Umur token? | Backend + Frontend | 25 Sep | Access 15 menit, refresh dirotasi | | |
| D-15 | 8 Sep | T-12: aplikasi multi-bahasa di fase ini? | PO | 25 Sep | Tidak; dicatat di [Arsitektur](../arsitektur/gambaran-umum.md) | | |
| D-16 | 8 Sep | Kunci orientasi dibuka untuk web saja atau tablet juga? | PO | 25 Sep | Web + tablet | | |

## Sudah diputus

| ID | Diajukan | Pertanyaan | Pemilik | Keputusan | Diputus |
| --- | --- | --- | --- | --- | --- |
| D-7 | 12 Sep | Stack backend: BaaS atau tulis sendiri? | Backend → PO | **Supabase.** Alasan & lingkupnya di [sumber issue #149](../sumber/github-issue-149-d7-stack-backend.md); penerapannya di [Supabase](../arsitektur/supabase.md) dan [Backend & API](../arsitektur/backend-dan-api.md) | 15 Sep 2026 |

---

## D-17 dan seterusnya — artboard Catatin UI v2

Issue #7 (PO) dan #15 (Frontend) meminta kanvas **Catatin UI v2** ditinjau
artboard per artboard, lalu hasilnya dicatat sebagai D-17 dan seterusnya.
Kanvasnya ada di luar repo, jadi barisnya belum bisa diisi dari sini.

Saat peninjauan berlangsung, tambahkan satu baris per artboard ke tabel di
bawah — **diterima**, **ditolak**, atau **diterima dengan catatan**. Empat yang
paling mendesak karena jadi spesifikasi Minggu 3–4: `Pembukuan`, `Kalender`,
`keadaan kosong/memuat`, dan `PembukuanWeb`.

| ID | Artboard | Hasil | Catatan | Diputus |
| --- | --- | --- | --- | --- |
| D-17 | | | | |

Pertanyaan yang perlu dijawab Frontend saat sesi itu, karena keempatnya
langsung jadi kode: apakah navigation rail desktop disetujui (D-6)? Pembukuan
web dua panel? berapa lebar maksimum konten? keadaan kosong pakai ilustrasi
atau teks saja?
