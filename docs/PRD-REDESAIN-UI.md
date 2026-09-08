# PRD — Redesain UI Catatin

**Versi:** 0.1 (draf) · **Tanggal:** 8 September 2026 · **Penulis:** Frontend
**Status:** belum disepakati — butuh review desainer & pemilik produk

> Dokumen ini hasil *reverse engineering* aplikasi Catatin yang sekarang
> (`app/lib`, 53 file, 14.546 baris, 122 kelas widget) plus build web yang
> tayang di [piambak.github.io/catatin](https://piambak.github.io/catatin/).
> Isinya dua hal: **apa yang ada sekarang** (bagian 2–4) dan **apa yang harus
> jadi** (bagian 5–8). Bagian 2–4 deskriptif — itu fakta kode, bukan usulan.
>
> Spesifikasi warna, tipografi, spasi, dan komponen ada di dokumen terpisah:
> **[`DESIGN-TOKENS.md`](DESIGN-TOKENS.md)**.

---

## 1. Tujuan & lingkup

### Yang ingin dicapai

Menyusun ulang tampilan Catatin dengan gaya baru yang **lebih tenang, lebih
sedikit input, dan benar-benar responsif** — tanpa mengubah satu pun kemampuan
yang sudah ada.

Tiga arah yang sudah disepakati:

| Arah | Artinya di produk |
| --- | --- |
| **Kurangi kekacauan visual** | Hentikan kartu-di-dalam-kartu, kecilkan jumlah warna yang bersaing, jarak antar-elemen yang konsisten |
| **Kurangi bayangan** | Tuntaskan arah *flat* yang sudah 95% jalan — sisa 3 `BoxShadow` dihapus, kedalaman dinyatakan lewat garis & spasi |
| **Kurangi dropdown/input** | Layar form saat ini padat *picker* buatan sendiri; sederhanakan jalur input, kurangi dialog |

Plus satu arah teknis:

| Arah | Artinya di produk |
| --- | --- |
| **Responsif sungguhan** | Satu sistem *breakpoint* untuk ponsel **dan** web desktop — bukan lima ambang berbeda yang ditulis inline seperti sekarang |

### Di luar lingkup

- Menambah/menghapus fitur produk (Pustaka peraturan sudah dicabut di PR
  terpisah — jangan dihidupkan lagi di sini)
- Mengubah logika perhitungan pajak (itu urusan T-1/T-3/T-4 di
  [`PROJECT_TIMELINE.md`](PROJECT_TIMELINE.md), butuh pakar pajak)
- Mengganti backend atau kontrak API (`docs/BACKEND.md` tetap berlaku)
- Mengganti framework — tetap Flutter, tetap `go_router`

### Prinsip yang mengikat

1. **Nol regresi fungsi.** Setiap layar, rute, dan aksi yang ada sekarang harus
   tetap ada sesudahnya. Daftar lengkapnya di bagian 3.
2. **Data contoh harus tetap jalan tanpa backend.** `flutter run` polos wajib
   tetap menampilkan aplikasi penuh — ini kontrak kontributor baru di README.
3. **Mode gelap bukan tambalan.** Setiap keputusan visual berlaku untuk kedua
   mode sejak awal, bukan disesuaikan belakangan.

---

## 2. Arsitektur informasi saat ini

### Peta rute

Dari `app/lib/core/network/app_router.dart` — `go_router` dengan
`StatefulShellRoute` untuk 4 tab utama, plus rute layar-penuh di luar shell.

```
/                          Splash          — cek sesi, lalu redirect
/login                     Login
/register                  Register
/onboarding/business       Setup usaha     — wajib sebelum masuk shell
│
├─ SHELL (bottom nav, 4 tab)
│  /dashboard              Dashboard
│  /accounting             Pembukuan
│  /simulator              Simulator pajak
│  /settings               Pengaturan
│
/accounting/new            Transaksi baru  — layar penuh
/accounting/:id            Detail transaksi
/settings/business         Profil usaha
/notifications             Notifikasi
```

**Penjaga rute (`_guard`)** menjalankan dua aturan berurutan: belum login →
`/login`; sudah login tapi belum onboarding → `/onboarding/business`. Keduanya
wajib dipertahankan.

### Navigasi utama

`BottomNavigationBar` 4 item, label bahasa Indonesia, ikon Material *outlined*:

| # | Label | Ikon | Rute |
| --- | --- | --- | --- |
| 1 | Dashboard | `dashboard_outlined` | `/dashboard` |
| 2 | Pembukuan | `receipt_long_outlined` | `/accounting` |
| 3 | Simulator | `calculate_outlined` | `/simulator` |
| 4 | Pengaturan | `settings_outlined` | `/settings` |

> **Catatan responsif:** bottom nav 4 tab masuk akal di ponsel, tapi di layar
> desktop ≥1024px ini membuang ruang horizontal besar. Lihat R-4.

---

## 3. Inventaris layar — apa yang wajib dipertahankan

Bagian ini adalah **kontrak nol-regresi**. Desain baru boleh mengubah bentuk
apa pun, tapi setiap baris di bawah harus tetap bisa dilakukan pengguna.

### 3.1 Dashboard (`dashboard_screen.dart`, 479 baris)

Susunannya vertikal, dengan satu blok yang sudah punya percabangan responsif
kasar (3 kolom di >700px, 2 kolom di >480px, tumpuk di bawah itu).

| Bagian | Widget | Isi |
| --- | --- | --- |
| Kartu KPI | `kpi_card.dart` (753 baris) | Pemasukan, pengeluaran, laba bulan berjalan |
| Grafik tren | `income_chart_card.dart` (524) | Tren bulanan `fl_chart` |
| Progres PKP | `pkp_bar.dart` (101) | Omzet YTD terhadap ambang Rp4,8 M |
| Transaksi terakhir | `recent_transactions.dart` (202) | Daftar ringkas, ketuk → detail |
| Tips pajak | `tax_tips_card.dart` (191) | Konten statis |
| Aksi cepat | `QuickActions` di `deadline_card.dart` | Pintasan ke aksi umum |
| Info pajak | `regulation_card.dart` (190) | 4 poin statis (pasca-pencabutan Pustaka) |
| Kalender & tenggat | `cal_deadline_card.dart` (513) | Tenggat pajak terdekat |

### 3.2 Pembukuan (`accounting_screen.dart`, **1731 baris**)

File terbesar di repo. Berisi `TabBar` 2 tab plus **12 kelas privat** di dalam
satu file — termasuk dua implementasi kalender terpisah.

| Bagian | Kemampuan |
| --- | --- |
| Tab Harian (`_DailyTab`) | Transaksi dikelompokkan per hari, navigasi bulan |
| Tab Kalender (`_CalendarTab`) | Grid kalender penuh + mini kalender, penanda per tanggal |
| Navigasi periode | `_MonthNav`, `_YearNav` |
| Filter (`_FilterCard`) | Saring per kategori/jenis, legenda warna |
| Tambah transaksi | `tx_add_sheet.dart` (770) — bottom sheet |
| Detail transaksi | `tx_detail_screen.dart` (309) |
| Pemilih bulan | `month_picker.dart` (497) — dialog terpisah |

### 3.3 Simulator pajak (`simulator_screen.dart`, 106 baris + 4 tab)

`TabBar` 4 tab. Layarnya tipis; isinya ada di tab masing-masing.

| Tab | File | Isi |
| --- | --- | --- |
| PPh Final | `pph_final_tab.dart` (224) | Input omzet bulanan → pajak 0,5%, indikator ambang PKP |
| PPh 21 | `pph21_tab.dart` (235) | Input gaji + status PTKP → pajak TER bulanan |
| Skenario | `scenario_tab.dart` (304) | Bandingkan asumsi |
| Kalender | `calendar_tab.dart` (360) | Kalender tenggat pajak |

> Semua kalkulasi memanggil `core/services/simulator_service.dart` — **murni,
> tanpa jaringan.** Redesain tidak boleh memindahkan logika ini ke widget.

### 3.4 Pengaturan (`settings_screen.dart`, 356 baris)

Profil pengguna, sakelar mode gelap (`themeNotifier`, berlaku seketika), tautan
ke Profil usaha, logout dengan dialog konfirmasi.

### 3.5 Profil usaha (`business_screen.dart`, 617 baris)

Form: nama usaha, nama pemilik, NPWP, jenis usaha, status PKP, jumlah karyawan.
Dipakai dua kali — sebagai onboarding wajib dan sebagai layar edit.

### 3.6 Auth & lain-lain

| Layar | File | Catatan |
| --- | --- | --- |
| Splash | `splash_screen.dart` (109) | Animasi + cek sesi |
| Login | `login_screen.dart` (203) | Email + kata sandi |
| Register | `register_screen.dart` (164) | |
| Notifikasi | `notification_screen.dart` (356) | Daftar berkategori |

---

## 4. Temuan — kenapa perlu didesain ulang

Semua angka di bawah terukur dari kode, bukan kesan.

### 4.1 Kekacauan visual

- **Kartu di dalam kartu.** `AppCard` (radius 12, border 0,5px) dipakai sebagai
  pembungkus hampir setiap bagian, dan di beberapa layar kartu berisi kartu
  lagi. Hasilnya garis tipis bertumpuk yang tidak menyampaikan hierarki apa pun.
- **Palet terlalu ramai.** `app_theme.dart` mendefinisikan brand (amber
  `#FFA400`), accent (biru `#009FFD`), dark (`#2A2A72`), plus **5 pasang warna
  semantik** (income/expense/warning/navy + badge foreground), masing-masing
  dengan varian light/border/badge. Total lebih dari 30 token warna untuk
  aplikasi 4 layar.
- **Tiga keluarga huruf.** DMSerif (judul), DMSans (teks), dan `monospace`
  (angka) dipakai bersamaan di satu layar.

### 4.2 Terlalu banyak modal

| Pola | Jumlah |
| --- | --- |
| `showDialog` | **11** |
| `showDatePicker` | 3 |
| `showModalBottomSheet` | 1 |

Alur menambah transaksi sekarang: bottom sheet → dalamnya date picker → lalu
dialog konfirmasi. Tiga lapis modal untuk satu tugas.

### 4.3 Picker buatan sendiri, bukan komponen standar

Nol `DropdownButton` di seluruh repo — bukan karena input sedikit, tapi karena
semuanya dibuat manual: `month_picker.dart` sendirian 497 baris untuk memilih
satu bulan. Ini sumber utama "terlalu banyak input" yang dirasakan.

### 4.4 Responsif yang tidak konsisten

Lima ambang berbeda, ditulis langsung di lima file:

| Nilai | Lokasi |
| --- | --- |
| 480 | `dashboard_screen.dart:163` |
| 500 | `accounting_screen.dart:1266` |
| 600 | `kpi_card.dart:50` |
| 680 | `accounting_screen.dart:478` |
| 700 | `dashboard_screen.dart:162` |

Tidak ada konstanta bersama. Di atas ~700px tidak ada penanganan sama sekali,
padahal build web-nya justru paling sering dibuka di layar lebar. Aplikasi juga
dikunci portrait di `main.dart` — wajar untuk ponsel, tapi ikut membatasi web.

### 4.5 Komponen tidak bisa dipakai ulang

122 kelas widget, **71 di antaranya privat** (`class _Foo`) dan terkunci di
dalam file layar. `accounting_screen.dart` sendiri memuat 12. Artinya hampir
tidak ada yang bisa dipakai ulang saat menyusun layar baru.

### 4.6 Logika kalender terduplikasi

Perhitungan tanggal muncul di **4 file terpisah**: `accounting_screen.dart`,
`cal_deadline_card.dart`, `tax_calendar_card.dart`, `income_chart_card.dart` —
ditambah `calendar_tab.dart` di simulator. Lima tampilan kalender, tidak satu
pun berbagi kode.

### 4.7 Aksesibilitas nol

Nol `Semantics`, `semanticLabel`, atau `excludeSemantics` di seluruh 53 file
(temuan T-8). Untuk produk yang tayang sebagai web publik, grafik dan progress
bar sepenuhnya tak terbaca pembaca layar.

---

## 5. Kebutuhan desain baru

Ditulis supaya bisa diuji — tiap butir bisa dijawab "sudah" atau "belum".

### R-1 — Hierarki tanpa kartu bertumpuk

- Maksimal **satu tingkat** permukaan berkartu. Bagian di dalam kartu dipisah
  spasi dan label, bukan kartu lagi.
- Bagian yang mengisi lebar layar penuh tidak perlu border sama sekali.
- **Kriteria:** nol `AppCard` di dalam `AppCard` di seluruh pohon widget.

### R-2 — Nol bayangan

- Hapus 3 `BoxShadow` yang tersisa. Kedalaman dinyatakan lewat warna permukaan,
  garis 1px, dan spasi.
- **Kriteria:** `grep -r "BoxShadow" app/lib` tidak mengembalikan apa pun.

### R-3 — Palet & tipografi yang dipangkas

- Turun ke **satu warna brand + satu aksen + skala netral + 3 warna semantik**
  (pemasukan/pengeluaran/peringatan). Detail di `DESIGN-TOKENS.md`.
- Turun ke **dua** keluarga huruf. Angka memakai *tabular figures* dari
  keluarga teks, bukan `monospace` terpisah.
- **Kriteria:** jumlah token warna ≤ 16; nol `fontFamily: 'monospace'`.

### R-4 — Responsif dengan satu sistem breakpoint

- Satu sumber kebenaran, mis. `core/theme/breakpoints.dart`:
  `compact <600`, `medium 600–1023`, `expanded ≥1024`.
- Tata letak per rentang:

| Rentang | Navigasi | Dashboard | Pembukuan |
| --- | --- | --- | --- |
| `compact` | Bottom nav | 1 kolom | Daftar penuh |
| `medium` | Bottom nav | 2 kolom | Daftar + panel detail |
| `expanded` | **Navigation rail kiri** | 3 kolom, lebar konten dibatasi | Daftar + detail berdampingan |

- Buka kunci orientasi untuk web; ponsel boleh tetap portrait.
- **Kriteria:** nol angka breakpoint literal di luar file breakpoints; layar
  1440px tidak menampilkan kolom teks selebar layar penuh.

### R-5 — Kurangi lapisan modal

- Maksimal **satu** lapisan modal untuk satu tugas. Tidak boleh modal di atas
  modal.
- Tambah transaksi jadi rute tersendiri (`/accounting/new` sudah ada) di
  `compact`, dan panel samping di `expanded` — bukan bottom sheet berlapis.
- Konfirmasi destruktif (hapus, logout) boleh tetap dialog; sisanya inline.
- **Kriteria:** `showDialog` turun dari 11 jadi ≤4, semuanya konfirmasi
  destruktif.

### R-6 — Input yang lebih sedikit dan lebih standar

- Pemilih bulan/tanggal memakai satu komponen bersama, bukan
  `month_picker.dart` 497 baris.
- Form Profil usaha: kelompokkan 6 field jadi maksimal 2 grup dengan
  *progressive disclosure* — NPWP dan jumlah karyawan tidak perlu terlihat
  sampai relevan.
- Simulator: nilai awal ditarik dari data Pembukuan bila ada (sejalan dengan
  rencana Minggu 5), input manual jadi *override*, bukan langkah wajib.
- **Kriteria:** jumlah field yang terlihat saat pertama membuka form Profil
  usaha turun dari 6 jadi ≤3.

### R-7 — Pustaka komponen bersama

- Komponen yang dipakai >1 layar naik ke `lib/widgets/common/` dan jadi publik.
- Target: kelas widget privat turun dari 71 jadi <40.
- **Kriteria:** `accounting_screen.dart` di bawah 400 baris.

### R-8 — Satu komponen kalender

- Satu sumber logika tanggal dipakai kelima tampilan kalender.
- **Kriteria:** perhitungan tanggal hanya ada di satu file.

### R-9 — Aksesibilitas sebagai syarat, bukan tambahan

- `semanticLabel` pada setiap grafik, progress bar, dan ikon-saja-tanpa-teks.
- Target sentuh ≥48dp. Kontras teks ≥4,5:1 di kedua mode.
- **Kriteria:** setiap `fl_chart` dan `percent_indicator` punya label semantik.

### R-10 — Mode gelap setara

- Setiap token punya nilai terang dan gelap yang keduanya diputuskan sengaja.
  Sekarang banyak varian gelap yang jatuh ke `#232528` yang sama, sehingga
  perbedaan semantik (income/expense/warning) hilang di mode gelap.
- **Kriteria:** nol token berbeda yang menghasilkan warna gelap identik.

---

## 6. Brief per layar

### Dashboard

Masalahnya kepadatan: 8 bagian bersaing tanpa hierarki. Usulan — tiga tingkat
kepentingan yang jelas:

1. **Utama** — KPI bulan berjalan + progres ambang PKP
2. **Sekunder** — grafik tren, transaksi terakhir
3. **Pendukung** — tenggat pajak, tips, info pajak (boleh diringkas/dilipat)

Di `expanded`, tingkat 1 dan 2 berdampingan; tingkat 3 jadi kolom samping.

### Pembukuan

Prioritas tertinggi untuk dipecah — 1731 baris dan dua kalender. Usulan:

- Pisah `_DailyTab`, `_CalendarTab`, `_FilterCard` ke file masing-masing
- Tab Harian jadi tampilan utama; kalender jadi **mode tampilan**, bukan tab
  sejajar, supaya filter dan navigasi periode berlaku untuk keduanya
- Di `expanded`: daftar kiri, detail transaksi kanan (bukan navigasi ke layar
  lain)

### Simulator

Struktur 4 tab dipertahankan — sudah cocok. Yang berubah cuma input: nilai awal
otomatis dari Pembukuan, dan hasil ditampilkan sebagai satu angka besar dengan
rinciannya bisa dibuka, bukan tabel penuh sekaligus.

> **Jangan** menyentuh `simulator_service.dart` dalam pekerjaan redesain.
> Perubahan di sana menunggu keputusan pakar pajak (T-1, T-3, T-4).

### Pengaturan & Profil usaha

Gabungkan jadi satu alur. Di `expanded`, pengaturan jadi dua panel (daftar
kategori kiri, isi kanan) alih-alih navigasi berlapis.

### Auth

Paling sedikit berubah. Yang perlu: lebar form dibatasi (~400px) dan
ditengahkan di layar lebar — sekarang membentang selebar layar.

---

## 7. Kriteria penerimaan

Redesain dianggap selesai bila **semuanya** terpenuhi:

- [ ] Setiap rute dan aksi di bagian 3 masih berfungsi
- [ ] `flutter analyze` → 0 error, 0 warning
- [ ] `flutter test` → seluruh tes lulus (termasuk tes baru dari T-2)
- [ ] Nol `BoxShadow` (R-2)
- [ ] Nol `AppCard` bersarang (R-1)
- [ ] Token warna ≤16, keluarga huruf ≤2 (R-3)
- [ ] Nol breakpoint literal di luar file breakpoints (R-4)
- [ ] `showDialog` ≤4 (R-5)
- [ ] `accounting_screen.dart` <400 baris (R-7)
- [ ] Logika tanggal di satu file (R-8)
- [ ] Setiap grafik & progress bar punya `semanticLabel` (R-9)
- [ ] Diperiksa manual di 375px, 768px, dan 1440px, mode terang & gelap
- [ ] Data contoh tetap jalan tanpa backend

---

## 8. Pertanyaan terbuka

Butuh keputusan sebelum implementasi dimulai:

1. **Navigation rail di desktop** — apakah disetujui menambah pola navigasi
   kedua, atau bottom nav dipertahankan di semua ukuran demi kesederhanaan?
2. **Portrait lock** — dibuka untuk web saja, atau juga untuk tablet?
3. **Urutan kerja** — redesain sekaligus, atau per layar? Kalau per layar,
   dua gaya akan hidup berdampingan sementara. Mana yang lebih bisa diterima?
4. **Hubungan dengan linimasa Fase Dua** — redesain ini belum ada di
   [`PROJECT_TIMELINE.md`](PROJECT_TIMELINE.md) Minggu 1–9. Masuk fase ini
   (menggeser tanggal rilis 13 Nov) atau jadi fase tersendiri sesudahnya?
5. **Siapa pemilik desain visualnya** — PRD ini menetapkan batasan dan struktur,
   bukan tampilan akhir. Arah visual (mood, ilustrasi, kepribadian merek) masih
   butuh desainer.

---

## Lampiran — ringkasan angka

| Metrik | Sekarang | Target |
| --- | --- | --- |
| Baris Dart (`lib/`) | 14.546 | — |
| Kelas widget | 122 | — |
| Kelas widget privat | 71 | <40 |
| File terbesar | `accounting_screen.dart` 1731 | <400 |
| `BoxShadow` | 3 | 0 |
| `showDialog` | 11 | ≤4 |
| Nilai breakpoint berbeda | 5 (inline) | 3 (terpusat) |
| Token warna | >30 | ≤16 |
| Keluarga huruf | 3 | 2 |
| File dengan logika tanggal | 4 | 1 |
| Pemakaian `Semantics` | 0 | setiap grafik & progress bar |
| `withOpacity` deprecated | 66 | 0 |
