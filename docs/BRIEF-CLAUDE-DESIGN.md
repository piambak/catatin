# Brief Claude Design — Redesain UI Catatin

**Versi:** 0.1 · **Tanggal:** 8 September 2026
**Referensi visual:** `disen_baru.pdf` (5 halaman: 1a, 1b, 1B, 1c, 1C)
**Dokumen terkait:** [`PRD-REDESAIN-UI.md`](PRD-REDESAIN-UI.md) · [`DESIGN-TOKENS.md`](DESIGN-TOKENS.md)

> Isinya tiga hal: **prinsip** yang dibaca dari PDF referensi (bagian 1),
> **prompt siap tempel** untuk Claude Design (bagian 2), dan **alur kerja**
> dari kanvas sampai kode (bagian 3).

---

## 1. Apa yang ditetapkan PDF referensi

PDF-nya bukan sekadar contoh gaya — itu proposal desain dengan pendirian yang
jelas. Tujuh prinsip yang bisa dibaca darinya:

### P-1 — Satu jawaban utama per layar

Dashboard lama membuka dengan tiga KPI setara (pemasukan/pengeluaran/laba).
Dashboard baru membuka dengan **satu** angka: `Rp 122.500 — 8 hari lagi`,
kewajiban pajak berikutnya. Sisanya turun jadi pendukung.

Ini pergeseran dari "aplikasi pembukuan yang juga hitung pajak" menjadi
"aplikasi yang memberitahu apa kewajibanmu berikutnya". Perubahan produk, bukan
cuma tata letak.

### P-2 — Nol kartu

Keterangan 1b menyebutnya eksplisit: *"tanpa satu pun kartu"*. Hierarki dibawa
tipografi dan spasi — label huruf kecil (`KEWAJIBAN BERIKUTNYA`), angka besar,
penjelasan sebagai kalimat.

> Ini **lebih keras** dari R-1 di PRD, yang cuma melarang kartu bersarang.
> Lihat bagian 4.

### P-3 — Bahasa manusia, bukan istilah pajak

*"Tiga pertanyaan, tanpa istilah rumit."* Simulator tidak lagi meminta "Status
PTKP" — ia bertanya **"Status keluarga"** dan menawarkan *"Menikah, 1
tanggungan"*. Istilah teknis (K/1, TER 6,0%) muncul di hasil sebagai
keterangan, bukan sebagai syarat input.

### P-4 — Simulator sebagai percakapan

Tiga pertanyaan berurutan. Jawaban yang selesai **mengendap jadi ringkasan satu
baris** dengan tautan "Ubah", lalu pertanyaan berikutnya muncul. Hasil tumbuh di
bawah, bukan pindah layar.

### P-5 — Penjelasan berupa prosa yang bisa dilipat

Hasil hitung diikuti paragraf yang menjelaskan angkanya dalam kalimat biasa,
plus **pembanding**: *"Kalau Anda memakai skema UMKM 0,5%, angkanya Rp 60.000
per bulan."* Bisa ditutup lewat "Tutup penjelasan".

### P-6 — Setiap angka membawa aksi

`Tandai sudah dibayar`, `Lihat rinciannya`, `Hitung ulang dari awal`. Tidak ada
angka yang cuma dipajang.

### P-7 — Web = komposisi sama, lebih lapang

*"Alur identik di web dan aplikasi."* Web bukan tata letak lain — ia susunan
yang sama dengan ruang lebih besar dan kolom pendukung di kanan. Ini menyederhanakan
R-4 di PRD: bukan tiga tata letak berbeda, satu komposisi dua kerapatan.

### Yang belum dicakup PDF

Hanya **Dashboard** dan **Simulator** yang digambar. **Pencatatan/Pembukuan**
(layar terbesar, 1731 baris, dua kalender) dan **Pengaturan** belum ada. Alur
kerja di bagian 3 menutup celah itu.

### Catatan akurasi

Halaman 1a memberi label "kondisi sekarang" dengan bottom nav 5 item termasuk
**Perpustakaan**. Tab itu **sudah dicabut** di branch
`claude/flutter-project-review-plan-pzmo22`. Nav yang benar sekarang 4 item:
Dashboard · Pembukuan · Simulator · Pengaturan. PDF juga memakai nama
"Pencatatan" — perlu diputuskan apakah itu usulan penggantian nama.

---

## 2. Prompt untuk Claude Design

Tempel utuh. Ditulis untuk menghasilkan kanvas multi-artboard, bukan satu layar.

---

```
Buat kanvas desain untuk Catatin — aplikasi pencatatan transaksi dan
perhitungan pajak untuk UMKM Indonesia. Flutter, tayang sebagai PWA di
piambak.github.io/catatin dan sebagai aplikasi ponsel.

Seluruh teks antarmuka berbahasa Indonesia.

## Arah desain

Ini penyusunan ulang, bukan pemolesan. Tujuh prinsip yang mengikat:

1. SATU JAWABAN UTAMA PER LAYAR. Dashboard membuka dengan kewajiban pajak
   berikutnya sebagai satu angka besar, bukan tiga KPI setara. Sisanya
   pendukung.
2. NOL KARTU. Tidak ada kotak berbingkai, tidak ada bayangan, tidak ada
   permukaan bertumpuk. Hierarki dibawa ukuran huruf, ketebalan, dan spasi.
   Pemisah berupa garis 1px atau ruang kosong saja.
3. BAHASA MANUSIA. Jangan pakai istilah pajak sebagai label input. Tanya
   "Status keluarga", bukan "Status PTKP". Istilah teknis (K/1, TER 6,0%,
   PP 23/2018) hanya muncul di hasil sebagai keterangan kecil.
4. SIMULATOR SEBAGAI PERCAKAPAN. Tiga pertanyaan berurutan. Jawaban yang
   selesai mengendap jadi ringkasan satu baris dengan tautan "Ubah". Hasil
   tumbuh di bawah, tidak pindah layar.
5. PENJELASAN SEBAGAI PROSA YANG BISA DILIPAT. Setelah angka hasil, satu
   paragraf bahasa biasa yang menjelaskan asal angkanya plus pembanding
   skema lain. Bisa ditutup.
6. SETIAP ANGKA MEMBAWA AKSI. Tidak ada angka yang cuma dipajang.
7. WEB = KOMPOSISI SAMA, LEBIH LAPANG. Bukan tata letak berbeda — susunan
   yang sama dengan ruang lebih besar dan kolom pendukung di kanan.

## Token visual

Warna (terang / gelap):
- brand        #FFA400 / #FFB733   aksi utama
- accent       #009FFD / #3DB5FF   tautan, info
- income       #1B8A4B / #3FBF75   pemasukan
- expense      #D92B2B / #FF6B6B   pengeluaran
- warning      #B07D2A / #E0A845   tenggat, ambang PKP
- text         #1A2430 / #EDF2F7
- textMuted    #667788 / #9AAABB
- surface      #FFFFFF / #2D3035
- surfaceSunken #F4F9FF / #232528
- border       #CDD8E8 / #454B55

Pakai warna semantik sehemat mungkin — untuk angka dan status, bukan untuk
latar blok besar.

Tipografi — dua keluarga saja:
- DM Serif Display 400 — judul (28px) dan sub-judul (20px)
- DM Sans 400/500/600 — semua sisanya
- Angka rupiah: DM Sans dengan tabular figures, jangan monospace
- Skala: 11 / 12 / 14 / 16 / 20 / 28
- Label huruf kecil: 11px, tebal 600, letter-spacing 0.5, warna textMuted

Spasi — kelipatan 4: 4 / 8 / 12 / 16 / 24 / 32
Radius — 8 (tombol, input) / 12 (permukaan) / 20 (sheet) / penuh (pil)
Bayangan — TIDAK ADA, tanpa kecuali.

## Artboard yang dibutuhkan

Ponsel 375×812, web 1440×1024. Terang dan gelap.

A. Dashboard — ponsel (terang)
   - Baris tanggal: "SENIN, 7 SEP 2026"
   - Sapaan: "Selamat pagi, Rizky."
   - Label "KEWAJIBAN BERIKUTNYA"
   - Angka utama: Rp 122.500 · "8 hari lagi — 15 September"
   - Satu kalimat: "PPh Final Masa Agustus 2026, dari omzet Rp 24.500.000
     x 0,5%."
   - Tombol: "Tandai sudah dibayar"
   - Label "SETELAH ITU" lalu garis waktu dua kewajiban:
     PPh Final September — 15 Okt 2026 — Rp 128.000
     SPT Tahunan PPh OP — 30 Apr 2027 — Belum dihitung
   - Label "BULAN INI": Pemasukan Rp 24.500.000 · Pengeluaran Rp 9.320.000
     · Laba Rp 15.180.000
   - Bottom nav 4: Dashboard · Pembukuan · Simulator · Pengaturan

B. Dashboard — web 1440 (terang)
   Komposisi sama, dua kolom. Kiri: kewajiban berikutnya, garis waktu, bulan
   ini. Kanan: "OMZET TAHUN INI Rp 186.400.000 — 3,9% dari batas PKP
   Rp 4,8 M, Anda masih aman di skema UMKM 0,5%", lalu "TERAKHIR DICATAT"
   (Proyek desain logo +6.500.000 / Langganan software -850.000 / Retainer
   klien +4.000.000), lalu "CEPAT" (Catat transaksi baru · Hitung pajak saya).
   Lebar konten dibatasi 1200px, ditengahkan. Navigasi jadi rail kiri.

C. Dashboard — ponsel (gelap). Sama seperti A dengan token gelap.

D. Simulator — ponsel, keadaan awal
   Judul "Hitung pajak Anda", sub "Tiga pertanyaan, tanpa istilah rumit."
   Pertanyaan 1 aktif: "Pekerjaan". Pertanyaan 2 dan 3 belum muncul.

E. Simulator — ponsel, keadaan selesai
   Tiga jawaban mengendap jadi baris ringkas dengan tautan "Ubah":
     Pekerjaan — Desainer / kreatif
     Penghasilan per bulan — Rp 12.000.000
     Status keluarga — Menikah, 1 tanggungan
   Lalu "PERKIRAAN PAJAK ANDA", angka Rp 720.000, keterangan "per bulan ·
   tarif TER 6,0% · K/1", tautan "Tutup penjelasan", dan paragraf:
   "Penghasilan bulanan Anda Rp 12.000.000. Dengan status K/1, penghasilan
   tidak kena pajak Anda Rp 63.000.000 per tahun, dan tarif efektif bulanan
   (TER) yang berlaku 6,0%. Jadi kira-kira Rp 720.000 dipotong tiap bulan.
   Kalau Anda memakai skema UMKM 0,5%, angkanya Rp 60.000 per bulan."
   Terakhir: "Hitung ulang dari awal".

F. Simulator — web 1440, keadaan selesai. Alur identik, lebih lapang.

G. Pembukuan — ponsel
   Daftar transaksi dikelompokkan per hari, dengan navigasi bulan. Kalender
   sebagai MODE TAMPILAN yang bisa dipilih, bukan tab sejajar — supaya filter
   dan navigasi periode berlaku untuk keduanya. Tanpa kartu.

H. Pembukuan — web 1440
   Dua panel: daftar transaksi di kiri, detail transaksi terpilih di kanan.
   Tidak pindah halaman saat memilih transaksi.

I. Tambah transaksi — ponsel
   Halaman penuh, bukan bottom sheet. Maksimal satu lapis modal untuk
   keseluruhan tugas.

J. Pengaturan — ponsel dan web
   Web: dua panel (daftar kategori kiri, isi kanan). Termasuk sakelar mode
   gelap dan tautan ke Profil usaha.

K. Papan komponen
   Tombol (utama/sekunder/hantu/bahaya), field input, badge status, label
   bagian, keadaan kosong, keadaan galat, kerangka memuat, baris transaksi,
   baris garis waktu kewajiban. Terang dan gelap berdampingan.

## Batasan

- Jangan menambah atau menghapus fitur. Rute yang ada: /dashboard,
  /accounting, /accounting/new, /accounting/:id, /simulator, /settings,
  /settings/business, /notifications, /login, /register,
  /onboarding/business.
- Fitur "Pustaka peraturan" sudah dicabut — jangan dimunculkan lagi.
- Target sentuh minimal 48x48. Kontras teks minimal 4,5:1 di kedua mode.
- Angka rupiah pakai pemisah titik: Rp 24.500.000.
- Semua contoh data pakai angka di atas, jangan lorem ipsum.
```

---

## 3. Alur kerja

Enam fase. Fase 1–2 tidak butuh keputusan desain dan bisa jalan sekarang.

### Fase 0 — Sepakati dulu (sebelum menyentuh kanvas)

Empat pertanyaan yang mengubah hasil kalau dijawab belakangan:

| Pertanyaan | Kenapa penting |
| --- | --- |
| Dashboard berpusat pada kewajiban pajak? | P-1 mengubah posisi produk, bukan cuma tata letak. Butuh persetujuan pemilik produk |
| "Pembukuan" jadi "Pencatatan"? | PDF memakai nama berbeda; menyentuh nav, rute, dan dokumentasi |
| Redesain masuk Fase Dua atau fase sendiri? | Belum ada di `PROJECT_TIMELINE.md` Minggu 1–9; kalau dipaksa masuk, tanggal rilis 13 Nov bergeser |
| Sumber angka "kewajiban berikutnya"? | Butuh endpoint agregasi Minggu 2 yang **belum jadi**. Kalau belum ada, desainnya siap tapi datanya belum |

### Fase 1 — Fondasi kode, tanpa perubahan tampilan

Bisa jalan **paralel** dengan desain, tidak menunggu apa pun:

1. Buat `core/theme/tokens.dart` dan `core/theme/breakpoints.dart`, petakan
   nama lama ke baru lewat alias. Nol perubahan visual.
2. Bersihkan 66 `withOpacity` (T-6) — PR mekanis tersendiri.
3. Tambah tes untuk `simulator_service.dart` (T-2) — **wajib sebelum menyentuh
   tab simulator**, karena Fase 4 akan merombak tampilannya.

### Fase 2 — Kanvas Claude Design

1. Jalankan prompt bagian 2.
2. Tinjau artboard A–C dulu (Dashboard) sebelum lanjut. Kalau P-1 terasa salah,
   berhenti di sini — jangan telanjur menggambar sembilan artboard lain di atas
   premis yang ditolak.
3. Sunting langsung di kanvas: geser, ubah teks, atur spasi.
4. Simpan versi tiap kali ada keputusan yang disepakati, jangan menumpuk.

### Fase 3 — Kunci token dari kanvas

Setelah tata letak disepakati, tarik nilai finalnya kembali ke
[`DESIGN-TOKENS.md`](DESIGN-TOKENS.md), ganti nilai usulan yang sekarang masih
draf. **Verifikasi kontras di sini**, bukan nanti — nilai gelap di dokumen itu
belum diukur sama sekali.

### Fase 4 — Implementasi, satu PR per langkah

Urutan ini bukan selera; tiap langkah membuka langkah berikutnya:

| # | Langkah | Kenapa urutannya begini |
| --- | --- | --- |
| 1 | Terapkan skala spasi & radius | Perubahan terluas, paling baik dilihat lebih dulu |
| 2 | Pangkas palet, perbaiki mode gelap | Butuh langkah 1 supaya diff-nya kebaca |
| 3 | Pecah `accounting_screen.dart` (1731 baris) | Blokir semua kerja Pembukuan |
| 4 | Satukan kalender & date picker | Butuh langkah 3 |
| 5 | Tata letak responsif + rail | Butuh komponen dari langkah 3–4 |
| 6 | Dashboard baru | Butuh data kewajiban (lihat Fase 0) |
| 7 | Simulator percakapan | Butuh tes dari Fase 1 langkah 3 |
| 8 | Aksesibilitas | Terakhir, saat markup sudah stabil |

### Fase 5 — Verifikasi

Jalankan kriteria penerimaan di [`PRD-REDESAIN-UI.md`](PRD-REDESAIN-UI.md)
bagian 7. Tambahan khusus redesain ini:

- [ ] Nol `BoxShadow` di `app/lib`
- [ ] Nol kartu berbingkai di Dashboard dan Simulator (P-2)
- [ ] Nol istilah pajak sebagai label input (P-3)
- [ ] Diperiksa di 375px, 768px, 1440px, terang dan gelap
- [ ] `flutter analyze` → 0 error, 0 warning
- [ ] `flutter test` lulus, termasuk tes pajak baru

---

## 4. Yang berubah dari PRD

PDF referensi lebih tegas dari PRD di dua tempat. Usul: PRD menyesuaikan.

| Hal | PRD sekarang | Usul mengikuti referensi |
| --- | --- | --- |
| Kartu | R-1: maksimal satu tingkat kartu | **Nol kartu** di Dashboard & Simulator; sisanya menyusul |
| Responsif | R-4: tiga tata letak (`compact`/`medium`/`expanded`) | Satu komposisi, dua kerapatan — lebih murah dan lebih konsisten |
| Dashboard | 3 tingkat kepentingan, KPI di puncak | Kewajiban pajak berikutnya di puncak, KPI turun jadi pendukung |
| Simulator | "struktur 4 tab dipertahankan" | Tab PPh Final & PPh 21 jadi **satu alur percakapan**; Skenario & Kalender tetap terpisah |

Perubahan Simulator itu yang paling besar. Perlu dicatat: alur percakapan
menyembunyikan pilihan status PTKP di balik bahasa sehari-hari, sementara
**T-1 masih terbuka** — kategori TER B dan C belum ada, jadi status K/2 dan K/3
masih dihitung dengan tarif kategori A. Mendesain ulang tampilannya tidak
memperbaiki itu, dan tampilan yang lebih meyakinkan justru membuat angka yang
salah tampak lebih kredibel. **Selesaikan T-1 sebelum Fase 4 langkah 7.**
