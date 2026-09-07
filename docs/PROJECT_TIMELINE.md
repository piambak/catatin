# Linimasa Proyek — Catatin Fase Dua

> **Cara pakai dokumen ini:** ini bukan dokumen sekali baca — ini *tracker* hidup.
> Setiap kali menyelesaikan tugas, centang kotaknya (`- [ ]` → `- [x]`) dan ubah
> **Status** minggu itu kalau semua tugasnya sudah selesai. Tambahkan entri baru
> di **Log Progres** (paling bawah) setiap ada kemajuan, walau kecil — tanggal,
> siapa, apa yang berubah. Kalau jadwal bergeser, jangan hapus tanggal lama;
> coret dan tulis tanggal baru di sebelahnya supaya riwayatnya tetap kebaca.

**Mulai:** Senin, 14 September 2026
**Target rilis:** Jumat, 13 November 2026 (9 minggu kerja / ±2 bulan)
**Tim:** 1 Backend Engineer · 1 Frontend Engineer (Flutter) · 1 Pakar Regulasi DJP & Kemenkeu

**Tujuan fase ini:** mencabut fitur **Pustaka peraturan**, lalu memperdalam dua
fitur yang tersisa — **Pembukuan** dan **Simulator pajak** — sampai simulator
bisa menghitung dari data pembukuan asli, bukan input manual ulang.

---

## Ringkasan status

| Minggu | Tanggal | Fase | Status |
| --- | --- | --- | --- |
| 1 | 14–18 Sep | Kickoff, audit, kunci spesifikasi | ⬜ Belum mulai |
| 2 | 21–25 Sep | Cabut Pustaka peraturan + fondasi backend | ⬜ Belum mulai |
| 3 | 28 Sep–2 Okt | Pembukuan naik kelas (1/2) — transaksi berulang, lampiran | ⬜ Belum mulai |
| 4 | 5–9 Okt | Pembukuan naik kelas (2/2) — ekspor/impor, filter, ringkasan | ⬜ Belum mulai |
| 5 | 12–16 Okt | Simulator naik kelas (1/2) — tarik data asli, mesin tarif | ⬜ Belum mulai |
| 6 | 19–23 Okt | Simulator naik kelas (2/2) — skenario, PPN, proyeksi tahunan | ⬜ Belum mulai |
| 7 | 26–30 Okt | Integrasi lintas fitur + validasi pajak ronde 1 | ⬜ Belum mulai |
| 8 | 2–6 Nov | Perbaikan bug, polish UI, validasi pajak ronde 2 | ⬜ Belum mulai |
| 9 | 9–13 Nov | Regresi final, rilis, pemantauan pasca-rilis | ⬜ Belum mulai |

Legenda status: ⬜ Belum mulai · 🔵 Berjalan · ✅ Selesai · 🔴 Terhambat

---

## Minggu 1 — 14–18 Sep — Kickoff, audit, kunci spesifikasi

**Target minggu:** semua orang punya pemahaman sama soal kondisi kode saat ini
dan formula pajak yang benar, sebelum satu baris kode fitur baru ditulis.

### Backend
- [ ] Audit `app/lib/core/data/repositories.dart`, `mock_repositories.dart`,
      `api_repositories.dart`, `hybrid_repositories.dart` — pahami pola 3 mode
      sumber data (contoh/hybrid/API)
- [ ] Audit kontrak di `docs/BACKEND.md`, tandai endpoint mana yang sudah
      terpakai nyata vs baru rencana
- [ ] Rancang skema data mesin tarif pajak berbasis konfigurasi (tarif PPh
      Final, lapisan PTKP, TER, ambang PKP Rp4,8 M) — supaya pakar pajak bisa
      memperbarui angka tanpa rilis aplikasi baru
- [ ] Siapkan lingkungan dev backend (repo, DB lokal/staging, CI dasar)

### Frontend
- [ ] Audit `app_router.dart` & `app_constants.dart` — petakan semua rute yang
      menyentuh `/library/*`
- [ ] Petakan setiap widget dashboard yang menaut ke Pustaka peraturan
      (`regulation_card.dart`, `tax_tips_card.dart`, `deadline_card.dart`,
      `notification_screen.dart`) dan tentukan pengganti kontennya
- [ ] Review file Flutter original yang diberikan user, bandingkan dengan
      `app/lib/` saat ini — catat perbedaan/bagian yang perlu diselaraskan
- [ ] Setup branch kerja & pastikan `flutter pub get` + `flutter run -d chrome`
      jalan mulus di mesin sendiri

### Pakar Regulasi DJP & Kemenkeu
- [ ] Audit formula PPh Final 0,5% (`pph_final_tab.dart`) terhadap PP 23/2018
      — cek masa berlaku, batas omzet Rp4,8 M/tahun
- [ ] Audit formula PPh 21 TER (`pph21_tab.dart`) terhadap PMK 168/2023 —
      cek kelengkapan kategori TER A/B/C
- [ ] Tulis spesifikasi tertulis: apa saja yang berubah di kalkulator (modul
      PPN? proyeksi SPT Tahunan? kategori apa saja?) — jadi acuan backend &
      frontend minggu depan
- [ ] Tentukan konten regulasi ringkas apa yang **wajib tetap tampil** di
      aplikasi setelah Pustaka peraturan dicabut (mis. teks bantuan singkat
      di kartu tenggat pajak)

**Sinkron akhir minggu (Jumat 18 Sep):** kunci spesifikasi bersama —
setelah ini, ubah spesifikasi berarti ubah jadwal.

---

## Minggu 2 — 21–25 Sep — Cabut Pustaka peraturan + fondasi backend

**Target minggu:** aplikasi berjalan normal tanpa fitur Pustaka peraturan;
fondasi data untuk peningkatan berikutnya siap.

### Backend
- [ ] Cabut bagian **"Pustaka peraturan"** dari `docs/BACKEND.md`
      (`GET /documents/categories`, `GET /documents`, `GET /documents/{id}`)
- [ ] Cabut method terkait dokumen dari `repositories.dart` dan ketiga
      implementasinya
- [ ] Mulai endpoint agregasi bulanan (income/expense/HPP per periode) —
      ini basis data yang nanti dipakai Simulator
- [ ] Definisikan kontrak endpoint mesin tarif pajak (draf, belum
      diimplementasi penuh) berdasarkan skema Minggu 1

### Frontend
- [ ] Hapus `library_screen.dart`, `doc_detail_screen.dart`,
      `bookmark_screen.dart`, `lib_widgets.dart`, `related_docs.dart`,
      `library_service.dart`, `document_model.dart`
- [ ] Cabut rute `/library/*` dan `/library/bookmarks` dari `app_router.dart`,
      cabut entri terkait dari `app_constants.dart`
- [ ] Hapus tab/menu Pustaka dari bottom navigation (`MainShell`)
- [ ] Ganti konten `regulation_card.dart` / `tax_tips_card.dart` dengan versi
      yang tidak bergantung pada data dokumen (pakai konten inline dari
      pakar pajak)
- [ ] Uji manual: seluruh alur (splash → login → dashboard → pembukuan →
      simulator → settings) tidak ada link mati ke `/library/*`

### Pakar Regulasi DJP & Kemenkeu
- [ ] Tuliskan matriks lengkap PPh 21 TER (semua kombinasi status
      kawin/tanggungan × kategori TER) untuk dipakai backend
- [ ] Sign-off tertulis formula PPh Final & PPh 21 TER dengan backend
      (paraf/approve di PR atau dokumen spesifikasi)
- [ ] Validasi pemetaan kategori transaksi → relevansi pajak & HPP di
      `accounting_screen.dart` — cek apakah kategori saat ini sudah benar
      secara pajak

**Milestone M1 (Jumat 25 Sep):** Pustaka peraturan hilang total dari kode
dan dokumentasi; tidak ada regresi di fitur lain.

---

## Minggu 3 — 28 Sep–2 Okt — Pembukuan naik kelas (1/2)

**Target minggu:** transaksi berulang dan lampiran struk berjalan end-to-end.

### Backend
- [ ] Endpoint template transaksi berulang (buat/edit/hentikan pengulangan)
- [ ] Endpoint upload lampiran struk (foto), simpan referensi ke transaksi
- [ ] Tulis test untuk kedua endpoint di atas

### Frontend
- [ ] UI tambah transaksi berulang di `new_transaction_screen.dart` (pilih
      frekuensi: mingguan/bulanan, tanggal berakhir opsional)
- [ ] UI unggah foto struk dari kamera/galeri, preview di `tx_detail_screen.dart`
- [ ] State management untuk transaksi berulang yang otomatis muncul di
      `accounting_screen.dart` sesuai jadwalnya

### Pakar Regulasi DJP & Kemenkeu
- [ ] Susun kebutuhan modul PPN untuk usaha berstatus PKP (kapan wajib
      pungut, tarif berlaku, cara hitung dasar pengenaan pajak)
- [ ] Review implikasi pajak transaksi berulang (mis. cicilan/leasing —
      apakah bunga jadi komponen HPP atau bukan)

---

## Minggu 4 — 5–9 Okt — Pembukuan naik kelas (2/2)

**Target minggu:** ekspor/impor data dan pengalaman pencarian/filter selesai.

### Backend
- [ ] Endpoint ekspor transaksi ke CSV (per rentang tanggal/kategori)
- [ ] Endpoint impor CSV dengan validasi baris gagal
- [ ] Endpoint ringkasan tutup bulan (total masuk/keluar/laba, siap dipakai
      dashboard & simulator)

### Frontend
- [ ] UI ekspor CSV (pilih rentang, unduh/bagikan)
- [ ] UI impor CSV (preview sebelum commit, tampilkan baris error)
- [ ] Filter & pencarian transaksi (per kategori, rentang tanggal, status
      relevansi pajak) di `accounting_screen.dart`
- [ ] Kartu ringkasan tutup bulan di dashboard

### Pakar Regulasi DJP & Kemenkeu
- [ ] Validasi format ekspor CSV cukup untuk kebutuhan pembukuan UMKM
      (kolom apa saja yang wajib ada untuk keperluan pajak)
- [ ] Review kasus tepi impor: transaksi lintas tahun pajak, mata uang,
      pembulatan Rupiah

**Milestone M2 (Jumat 9 Okt):** Pembukuan v2 selesai — transaksi berulang,
lampiran, ekspor/impor, filter, ringkasan bulanan semua jalan.

---

## Minggu 5 — 12–16 Okt — Simulator naik kelas (1/2)

**Target minggu:** simulator berhenti minta input manual, mulai menarik data
pembukuan asli.

### Backend
- [ ] Implementasi penuh endpoint mesin tarif pajak (PPh Final & PPh 21 TER,
      baca dari konfigurasi, bukan hardcode)
- [ ] Endpoint yang menggabungkan agregasi transaksi (dari Minggu 2) sebagai
      input siap pakai untuk kalkulasi simulator
- [ ] Test: hasil endpoint mesin tarif cocok dengan contoh kasus dari pakar
      pajak (unit test berbasis kasus nyata)

### Frontend
- [ ] Rombak `pph_final_tab.dart` & `pph21_tab.dart`: tarik omzet/laba dari
      data Pembukuan asli, tampilkan asalnya jelas ("dihitung dari transaksi
      Sep 2026"), tetap izinkan override manual untuk simulasi "bagaimana jika"
- [ ] Loading/error state saat data agregasi backend belum siap

### Pakar Regulasi DJP & Kemenkeu
- [ ] Input tarif & lapisan final ke skema konfigurasi backend, validasi
      terhadap kalkulator resmi DJP (bandingkan hasil satu-satu)
- [ ] Uji kasus tepi: usaha baru berjalan <12 bulan, omzet mendekati ambang
      Rp4,8 M di tengah tahun berjalan

---

## Minggu 6 — 19–23 Okt — Simulator naik kelas (2/2)

**Target minggu:** simpan/bandingkan skenario, modul PPN, proyeksi tahunan.

### Backend
- [ ] Endpoint simpan & ambil skenario simulasi (nama, asumsi, hasil)
- [ ] Endpoint kalkulasi PPN (untuk usaha PKP) sesuai kebutuhan Minggu 3
- [ ] Endpoint proyeksi SPT Tahunan sederhana berbasis data 12 bulan terakhir

### Frontend
- [ ] UI simpan skenario dengan nama custom, daftar skenario tersimpan
- [ ] UI bandingkan 2–3 skenario berdampingan (`scenario_tab.dart`)
- [ ] UI modul PPN (kalau usaha berstatus PKP di Profil usaha)
- [ ] Ekspor hasil simulasi ke PDF/bagikan

### Pakar Regulasi DJP & Kemenkeu
- [ ] Validasi kalkulasi PPN terhadap regulasi Kemenkeu terbaru
- [ ] Validasi logika proyeksi SPT Tahunan — pastikan disclaimer jelas bahwa
      ini simulasi, bukan pengganti konsultasi resmi
- [ ] Uji kasus tepi: transisi status non-PKP → PKP di tengah tahun

**Milestone M3 (Jumat 23 Okt):** Simulator v2 selesai — data otomatis dari
Pembukuan, skenario tersimpan, PPN, proyeksi tahunan.

---

## Minggu 7 — 26–30 Okt — Integrasi lintas fitur + validasi pajak ronde 1

**Target minggu:** semua bagian yang dibangun terpisah terbukti benar
saat dipakai bersamaan.

### Backend
- [ ] Uji beban ringan pada endpoint agregasi & mesin tarif (pastikan
      responsif dengan data 12 bulan transaksi)
- [ ] Perbaiki bug dari uji integrasi
- [ ] Perkuat validasi input (nominal negatif, tanggal tidak valid, dsb.)

### Frontend
- [ ] Uji alur penuh: catat transaksi baru → cek muncul di dashboard →
      cek terhitung otomatis di simulator → simpan skenario → ekspor PDF
- [ ] Perbaiki bug dari uji integrasi
- [ ] Cek konsistensi mode gelap di semua layar baru

### Pakar Regulasi DJP & Kemenkeu
- [ ] **Uji penerimaan ronde 1:** ambil 5–10 kasus UMKM nyata (data contoh),
      jalankan lewat aplikasi, cocokkan manual dengan kalkulator resmi DJP
- [ ] Catat semua selisih sebagai bug, prioritaskan berdasarkan dampak

---

## Minggu 8 — 2–6 Nov — Perbaikan bug, polish UI, validasi pajak ronde 2

**Target minggu:** daftar bug dari Minggu 7 mendekati nol.

### Backend
- [ ] Selesaikan semua bug berlabel backend dari Minggu 7
- [ ] Finalisasi `docs/BACKEND.md` — dokumentasikan semua endpoint baru
      (agregasi, mesin tarif, skenario, PPN, ekspor/impor)
- [ ] Siapkan deploy staging untuk uji akhir

### Frontend
- [ ] Selesaikan semua bug berlabel frontend dari Minggu 7
- [ ] Polish UI: spacing, animasi transisi, konsistensi komponen di fitur baru
- [ ] Cek performa (waktu muat dashboard, ukuran bundel web)

### Pakar Regulasi DJP & Kemenkeu
- [ ] **Uji penerimaan ronde 2:** ulangi kasus Minggu 7 setelah perbaikan,
      pastikan semua cocok dengan kalkulator resmi DJP
- [ ] Tulis catatan rilis logika pajak & disclaimer pengguna (mis. "simulasi
      ini bukan pengganti konsultasi pajak resmi")

**Milestone M4 (Jumat 6 Nov):** Tidak ada bug kritikal terbuka; hasil
kalkulasi tervalidasi penuh terhadap contoh resmi DJP.

---

## Minggu 9 — 9–13 Nov — Regresi final, rilis, pemantauan pasca-rilis

**Target minggu:** Catatin v2 tayang — hanya Pembukuan dan Simulator pajak,
keduanya lebih dalam dari sebelumnya.

### Backend
- [ ] Deploy produksi, pastikan monitoring/log aktif
- [ ] Siaga selama 48 jam pertama pasca-rilis untuk isu backend

### Frontend
- [ ] Build rilis web (`flutter build web`, sinkron ke root sesuai alur
      `tool/build_web.sh`) dan mobile bila sudah waktunya
- [ ] Regresi manual penuh sebelum rilis (checklist semua fitur)
- [ ] Siaga selama 48 jam pertama pasca-rilis untuk isu UI

### Pakar Regulasi DJP & Kemenkeu
- [ ] Sign-off regulasi final sebelum tombol rilis ditekan
- [ ] Siapkan rencana pemantauan: siapa yang memeriksa kalau ada perubahan
      tarif/aturan DJP & Kemenkeu setelah rilis, dan seberapa sering

**Milestone M5 (Jumat 13 Nov) — RILIS:** Catatin v2 tayang di
[piambak.github.io/catatin](https://piambak.github.io/catatin/).

---

## Risiko yang sudah diketahui

- **Urutan tidak boleh ditukar** — Minggu 5 (Simulator tarik data asli)
  butuh endpoint agregasi dari Minggu 2 sudah beres. Kalau Minggu 2 molor,
  seluruh Minggu 5–6 ikut molor.
- **Pakar pajak adalah gerbang, bukan penonton** — sign-off Minggu 1 dan
  Minggu 2 wajib tuntas sebelum backend mulai endpoint mesin tarif.
- **Ruang lingkup PPN & SPT Tahunan opsional** — kalau mayoritas pengguna
  target non-PKP, modul ini (Minggu 6) bisa ditunda ke fase berikutnya
  tanpa mengubah tanggal rilis fitur inti.
- **File Flutter original dari user** — belum direview saat dokumen ini
  ditulis; kalau ada perbedaan besar dari `app/lib/` saat ini, jadwal
  Minggu 1–2 frontend perlu ditinjau ulang.

---

## Log Progres

> Tambahkan baris baru di atas (paling baru di atas), format:
> `- **YYYY-MM-DD** — [Nama/Peran] — apa yang selesai/berubah`

- **2026-09-07** — Tim — Dokumen linimasa ini dibuat, jadwal dikunci mulai
  14 September 2026.
