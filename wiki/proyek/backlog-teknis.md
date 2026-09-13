# Backlog Teknis — Temuan Audit Kode

Temuan audit `app/lib` dan risiko yang sudah diketahui. Dipisah dari
[linimasa](linimasa.md) karena isinya bukan jadwal: ini daftar utang teknis yang
harus **dimasukkan** ke minggu yang relevan saat sinkron mingguan.

Tabel ringkasan di bawah adalah sumber kebenaran status; judul tiap bagian detail
mengikutinya.

---

## Temuan audit kode — usulan perbaikan

> Ditambahkan **8 September 2026** setelah audit `app/lib` (53 file, ±14.500
> baris) pada branch `claude/flutter-project-review-plan-pzmo22`. Semua temuan
> di bawah **belum tercakup** tugas Minggu 1–9 di atas. Masukkan ke minggu yang
> relevan saat sinkron mingguan, jangan dikerjakan diam-diam di luar jadwal.
>
> Prioritas: 🔴 wajib beres sebelum **M4** (validasi pajak) · 🟡 sebaiknya masuk
> fase ini · ⬜ boleh ditunda ke fase berikutnya

| # | Temuan | Prioritas | Pemilik | Usul masuk |
| --- | --- | --- | --- | --- |
| T-1 | Kategori TER B & C tidak ada — PPh 21 salah hitung | 🔴 | Pakar pajak → Frontend | Minggu 5 |
| T-2 | Nol tes untuk mesin pajak | ✅ **Selesai** | Frontend | 8 Sep 2026 |
| T-3 | PPh Final: pengecualian omzet Rp500 juta & batas jangka waktu belum ada | 🔴 | Pakar pajak → Frontend | Minggu 5 |
| T-4 | Angka PKP di layar PPh 21 menyesatkan; rekalkulasi Desember belum ada | 🟡 | Pakar pajak → Frontend | Minggu 6 |
| T-5 | Null-assertion rawan crash di pemetaan PTKP | ✅ **Selesai** | Frontend | 8 Sep 2026 |
| T-6 | 66 pemakaian `withOpacity` yang sudah deprecated | ✅ **Selesai** | Frontend | 8 Sep 2026 |
| T-7 | Dua `BuildContext` dipakai lewat async gap | ✅ **Selesai** | Frontend | 8 Sep 2026 |
| T-8 | Aksesibilitas nol — tidak ada satu pun `Semantics` | 🟨 **Sebagian** | Frontend | 8 Sep 2026 |
| T-9 | CI tidak menegakkan `dart format` | 🟡 | Frontend | Minggu 3 |
| T-10 | CI tanpa laporan coverage | ⬜ | Frontend | Minggu 8 |
| T-11 | `flutter_secure_storage` di web perlu diverifikasi sebelum JWT asli | ⬜ | Backend + Frontend | Minggu 5 |
| T-12 | Belum ada kerangka l10n | ⬜ | Frontend | Fase berikutnya |
| T-13 | Tabel TER tampilan menyimpang dari tabel hitung | ✅ **Selesai** | Frontend | 8 Sep 2026 |
| T-14 | 3.225 baris widget dashboard jadi yatim setelah redesain | 🟡 | Frontend | Perlu keputusan |
| T-15 | Kelas tipografi bernama `T` bentrok dengan parameter generic | ✅ **Selesai** | Frontend | 8 Sep 2026 |
| T-16 | Tenggat PPN Masa meluap ke bulan berikutnya | 🟡 | Pakar pajak → Frontend | Perlu keputusan |
| T-17 | Login pertama di peramban bersih macet karena token ditulis serentak | ✅ **Selesai** | Frontend | 13 Sep 2026 |
| T-18 | Pendaftaran situs publik tanpa verifikasi email dan tanpa "Lupa kata sandi?" | 🟡 | Backend + Frontend | Perlu keputusan |
| T-19 | Proyek Supabase paket Free dijeda setelah seminggu tidak aktif | 🟡 | Backend | Perlu keputusan |

---

### 🟡 T-19 — Proyek Supabase paket Free dijeda setelah seminggu tidak aktif

Proyek Supabase situs publik memakai paket Free. Di paket itu proyek dijeda
setelah satu minggu tidak aktif; di paket Pro tidak pernah
([sumber](../sumber/supabase-pricing-pausing.md)).

Selama proyek terjeda, daftar dan masuk di situs publik gagal dengan pesan
koneksi. Tombol demo tetap jalan karena tidak menyentuh Supabase. Apa persisnya
yang dihitung sebagai "aktivitas" belum dipastikan (TODO: needs source).

- [ ] **Backend** — pilih: terima risikonya selama masa uji, pasang pemantau
      yang memberi tahu tim saat proyek terjeda, atau naik ke paket berbayar
      sebelum situs dipromosikan ke pengguna umum

---

### 🟡 T-18 — Pendaftaran situs publik tanpa verifikasi email

**Keputusan 13 Sep 2026:** *Confirm email* di proyek Supabase situs publik
**dimatikan**. SMTP bawaan Supabase hanya mengirim ke alamat anggota tim
organisasi, jadi dengan konfirmasi menyala pengunjung umum tidak akan pernah
menerima tautannya ([sumber](../sumber/supabase-auth-smtp.md)). Custom SMTP
butuh domain pengirim sendiri, sedangkan situs ini masih di `github.io`.

Konsekuensi yang diterima dengan sadar:

- Siapa pun bisa mendaftar memakai email orang lain. Dokumen Supabase menyebut
  mematikan konfirmasi email sebagai celah yang dicari penyerang
  ([sumber](../sumber/supabase-auth-smtp.md)).
- Tautan "Lupa kata sandi?" di layar masuk masih kosong, dan fitur itu juga
  butuh email. Pengguna yang salah ketik email atau lupa sandi tidak bisa
  memulihkan akunnya.
- *Leaked password protection* tidak tersedia di paket Free
  ([sumber](../sumber/supabase-pricing-pausing.md)).

- [ ] **Backend** — siapkan domain + custom SMTP, lalu nyalakan lagi
      *Confirm email*. Aplikasi sudah menangani alurnya: setelah daftar,
      pengguna diminta membuka tautan di email lalu masuk
- [ ] **Frontend** — alur "Lupa kata sandi?" (`resetPasswordForEmail` + layar
      sandi baru) setelah SMTP siap
- [ ] **Backend** — pertimbangkan CAPTCHA pendaftaran selama konfirmasi email
      masih mati

---

### ✅ T-17 — Login pertama di peramban bersih macet *(selesai 13 Sep 2026)*

Ditemukan saat menguji build web mode Supabase, lalu terbukti juga terjadi di
build yang sedang tayang: di peramban tanpa data tersimpan, klik pertama
"Masuk sebagai pengguna demo" tidak berpindah ke dashboard. Konsol mencatat
`GoException: Exception during redirect: OperationError`; klik kedua berhasil.

Penyebabnya `StorageService.saveTokens()` menulis access token dan refresh token
serentak (`Future.wait`). Di web, `flutter_secure_storage_web` 2.1.1 memeriksa
apakah kunci enkripsi sudah ada di `localStorage` dan membuatnya kalau belum
(`_getEncryptionKey`). Dua penulisan serentak di peramban bersih sama-sama
melihat kunci belum ada, masing-masing membuat kunci, dan kunci yang disimpan
belakangan menimpa yang pertama. Token pertama tidak bisa didekripsi lagi, dan
penjaga rute yang membacanya melempar galat.

Dengan backend asli yang kena bukan hanya tombol demo: login pertama setiap
pengguna baru di situs publik akan macet dengan cara yang sama.

**Perbaikan:** kedua token ditulis berurutan, dan `isLoggedIn()` memperlakukan
token yang tak bisa didekripsi sebagai sesi kosong (tokennya dibersihkan)
alih-alih melempar galat ke penjaga rute. Diverifikasi di peramban dengan
penyimpanan bersih: klik pertama langsung masuk, nol galat di konsol.

---

### 🟡 T-16 — Tenggat PPN Masa meluap ke bulan berikutnya

`generateCalendar()` di `simulator_service.dart` menghitung tenggat PPN Masa
sebagai `DateTime(year, m + 1, 30)`. Untuk masa Januari itu berarti 30 Februari,
yang oleh Dart digeser jadi 2 Maret (atau 1 Maret di tahun kabisat).

Sejak dashboard mode Supabase mengambil tenggat dari fungsi ini, tanggal yang
salah ikut tampil untuk usaha berstatus PKP.

- [ ] **Pakar pajak** — pastikan aturannya: tanggal 30 bulan berikutnya, atau
      akhir bulan berikutnya
- [ ] **Frontend** — terapkan aturan itu tanpa meluap, dan kunci dengan tes per
      bulan (terutama Februari)

---

### ✅ T-15 — Kelas tipografi bernama `T` bentrok dengan parameter generic *(selesai 8 Sep 2026)*

`design_tokens.dart` mengekspor kelas gaya teks bernama **`T`** (`T.sans`,
`T.serif`, `T.mono`). `T` juga nama konvensional untuk parameter generic di
Dart, jadi di dalam kelas generic apa pun nama itu tertutup:

```dart
class _SheetDropdown<T> ... {
  Text('x', style: T.sans(14))  // error: 'sans' isn't defined for type 'T'
}
```

Terjadi nyata saat menggayakan ulang `tx_add_sheet.dart`, yang punya
`_DdItem<T>` dan `_SheetDropdown<T>`. Ditambal sementara dengan mengganti
parameter generic-nya jadi `V` — **itu memperbaiki gejala di tempat yang salah**:
kode pemanggil dipaksa menghindari nama yang lazim gara-gara token.

- [x] **Frontend** — kelas `T` diganti nama jadi **`Typo`** (142 pemakaian di
      15 berkas), lalu generic `V` di `tx_add_sheet.dart` dikembalikan ke `T`.
      `Typo` dipilih supaya sebaris dengan token lain (`DS`, `Space`, `Radii`)
      dan tidak tertukar dengan `AppTextStyles` lama yang masih dipakai layar
      yang belum didesain ulang.

---

### 🟡 T-14 — Widget dashboard lama jadi yatim setelah redesain

Setelah `dashboard_screen.dart` ditulis ulang mengikuti artboard 1b, seluruh
widget dashboard lama tidak lagi dirujuk siapa pun. Nol referensi eksternal
untuk kesepuluhnya:

`KpiCard` · `IncomeChartCard` · `PkpBar` · `RecentTransactions` ·
`DeadlineCard` · `QuickActions` · `TaxTipsCard` · `RegulationCard` ·
`CalDeadlineCard` · `TaxCalendarCard`

Totalnya **3.225 baris** di `lib/widgets/dashboard/`. Kompilator tidak
mengeluhkannya karena masing-masing berkas tetap valid — hanya tidak pernah
dipakai.

Hal serupa berlaku untuk `pph_final_tab.dart` dan `pph21_tab.dart` di
simulator, yang sengaja dipertahankan sebagai rujukan saat T-1 dikerjakan.

**Butuh keputusan, bukan aksi otomatis:**

- [ ] **Frontend + pemilik produk** — putuskan mana yang dihapus dan mana yang
      ditahan sebagai rujukan. Menghapusnya mengecilkan repo dan menghilangkan
      kebingungan "berkas mana yang hidup"; menahannya berguna sampai Pembukuan
      selesai didesain ulang dan T-1 beres.
- [ ] Apa pun keputusannya, kerjakan sebagai PR tersendiri — penghapusan 3.000+
      baris tidak boleh bercampur dengan perubahan lain.

Sampai diputuskan, jangan buang tenaga memperbaiki apa pun di dalamnya —
pembersihan `withOpacity` (T-6) sudah menyentuh berkas-berkas ini, tapi
pekerjaan aksesibilitas (T-8) sengaja melewatinya.

---

### ✅ T-13 — Tabel TER tampilan menyimpang dari tabel hitung *(selesai 8 Sep 2026)*

Ditemukan saat menulis tes T-2, bukan dari pembacaan kode biasa.

`buildTerTable()` di `simulator_service.dart` menyimpan **daftar tarif kedua**
yang ditulis tangan, terpisah dari `AppConstants.terTableA` yang dipakai
`calculatePPh21()` untuk menghitung. Keduanya sudah menyimpang:

| Gaji bulanan | Ditampilkan tabel | Dipakai hitungan |
| --- | --- | --- |
| Rp 8.000.000 | 1,5% | **2,0%** |
| Rp 9.000.000 | 1,5% | **2,5%** |
| Rp 12.000.000 | 5,0% | **6,0%** |
| Rp 40.000.000 | 19,0% | **27,0%** |

Artinya pengguna bisa melihat baris tersorot yang menyebut satu tarif, sementara
angka rupiah di layar yang sama dihitung dengan tarif lain.

**Dampak nyata saat ini: nihil.** `buildTerTable()` hanya dipakai
`pph21_tab.dart`, dan tab itu sudah tidak terpasang sejak simulator diganti alur
percakapan. Jadi ini cacat laten — perangkap untuk siapa pun yang menghidupkan
kembali tab tersebut atau memakai ulang fungsinya, bukan bug yang sedang
dirasakan pengguna.

**Perbaikan:** `buildTerTable()` sekarang diturunkan dari `terTableA`, dengan
lapisan berurutan bertarif sama digabung jadi satu rentang. Tidak ada lagi
daftar kedua yang bisa menyimpang. Tidak ada satu pun tarif yang diubah — ini
murni menghapus duplikasi, bukan keputusan pajak, jadi tidak menyentuh wewenang
pakar pajak.

Tes `buildTerTable tarif baris tersorot sama dengan tarif hasil hitung`
mengunci perbaikannya.

---

### 🔴 T-1 — Kategori TER B & C tidak ada, PPh 21 salah hitung

`calculatePPh21()` di `app/lib/core/services/simulator_service.dart:102` selalu
membaca `AppConstants.terTableA`, apa pun status PTKP yang dipilih pengguna.
`terTableB` dan `terTableC` **tidak ada sama sekali** di `app_constants.dart` —
yang ada hanya `terTableA` (baris 32).

Akibatnya pengguna yang memilih status seperti K/2 atau K/3 tetap mendapat tarif
kategori A, jadi angka pajaknya salah. Ini persis tugas Minggu 1 pakar pajak
yang masih terbuka ("cek kelengkapan kategori TER A/B/C") — sekarang
terkonfirmasi sebagai bug, bukan sekadar hal yang perlu dicek.

- [ ] **Pakar pajak** — kunci pemetaan status PTKP → kategori TER menurut
      PMK 168/2023, lengkap dengan tabel tarif B dan C
- [ ] **Frontend** — tambah `terTableB`/`terTableC`, ganti pemilihan tabel jadi
      fungsi dari status PTKP, bukan konstanta

**Catatan:** jangan implementasi dari sumber sekunder. Tunggu tabel resmi dari
pakar pajak — satu tarif salah berarti seluruh hasil M4 ikut salah.

### ✅ T-2 — Mesin pajak tidak punya satu pun tes *(selesai 8 Sep 2026)*

`test/widget_test.dart` berisi 5 tes, semuanya menguji `MockDashboardRepository`.
`simulator_service.dart` — `calculatePPhFinal()`, `calculatePPh21()`, dan
kalkulasi skenario — nol tes. Padahal ini satu-satunya kode di repo yang
kesalahannya langsung berujung ke angka pajak salah di layar pengguna.

Milestone **M4** mensyaratkan hasil kalkulasi cocok dengan kalkulator resmi DJP.
Tanpa tes, verifikasi itu manual dan tidak berulang — begitu Minggu 5 merombak
kedua tab simulator, tidak ada jaring pengaman yang memberi tahu kalau angkanya
bergeser.

- [x] **Frontend** — tes unit `calculatePPhFinal()`: di bawah ambang, tepat di
      ambang Rp4,8 M, di atas ambang, dan omzet nol
- [x] **Frontend** — tes unit `calculatePPh21()`: satu kasus per status PTKP,
      plus batas antar-lapisan TER (nilai tepat di `max` tiap baris)
- [ ] **Frontend** — begitu pakar pajak menyerahkan kasus uji resmi (tugas
      Minggu 7), jadikan tes otomatis — bukan cuma dicek manual sekali

**Perbaikan:** `app/test/simulator_service_test.dart` kini berisi 35 tes dalam
lima grup — `calculatePPhFinal`, `penanda ambang`, `calculatePPh21`,
`buildTerTable`, dan `calculateScenarios`. Termasuk di dalamnya kasus batas yang
dulu diminta: omzet nol, tepat di ambang Rp 4,8 M, di atas ambang, satu kasus per
status PTKP, dan nilai tepat di `max` tiap lapisan TER. Tes inilah yang justru
memunculkan T-13.

### 🔴 T-3 — PPh Final: pengecualian Rp500 juta & batas jangka waktu belum dimodelkan

`calculatePPhFinal()` mengenakan 0,5% dari rupiah pertama, dan `eligible` hanya
diuji terhadap ambang Rp4,8 M/tahun. Dua hal belum ada di model:

1. **Pengecualian omzet Rp500 juta pertama** untuk WP orang pribadi
   (UU HPP 2021 / PP 55/2022). Kalau ini berlaku untuk pengguna target Catatin,
   omzet di bawah Rp500 juta/tahun mestinya menghasilkan pajak nol — sekarang
   tidak.
2. **Batas jangka waktu** pemakaian tarif final PP 23/2018, yang berbeda antara
   WP OP dan badan. Tidak ada input apa pun soal "sejak tahun berapa".

- [ ] **Pakar pajak** — putuskan apakah keduanya masuk lingkup Catatin, dan
      untuk profil WP yang mana saja
- [ ] **Frontend** — kalau ya, `PPhFinalResult` butuh field baru dan Profil
      usaha butuh input tahun mulai. Ini mengubah kontrak data, jadi harus
      diputus **sebelum** Minggu 5 mulai, bukan di tengah jalan

### 🟡 T-4 — Angka PKP di layar PPh 21 menyesatkan

`calculatePPh21()` menghitung `pkp = (gajiKotor × 12) − PTKP` lalu
menampilkannya, padahal:

- Biaya jabatan (5%, ada batas atas) dan iuran pensiun tidak dikurangkan
- Pada metode TER bulanan, PKP **tidak dipakai sama sekali** untuk menghitung
  pajaknya — tarif diambil dari tabel TER berdasar penghasilan bruto

Jadi pengguna melihat angka berlabel "PKP" yang bukan PKP menurut definisi mana
pun, dan yang tidak dipakai dalam hasil hitung. Terpisah dari itu, **rekalkulasi
Desember** (Pasal 17 progresif untuk masa pajak terakhir) belum dimodelkan —
TER hanya berlaku Januari–November.

- [ ] **Pakar pajak** — tentukan angka apa yang layak ditampilkan di tab PPh 21,
      dan apakah rekalkulasi Desember masuk lingkup fase ini
- [ ] **Frontend** — sesuaikan `PPh21Result` dan `pph21_tab.dart` mengikuti
      keputusan di atas

### ✅ T-5 — Null-assertion rawan crash di pemetaan PTKP *(selesai 8 Sep 2026)*

`simulator_service.dart:79` dan `:103` memakai pola yang sama:

```dart
AppConstants.ptkp[status.shortLabel.replaceAll('/','')]!
```

Nilai enum diubah jadi label tampilan, tanda `/` dibuang, hasilnya dipakai
sebagai kunci Map, lalu di-`!`. Tiga langkah rapuh untuk sesuatu yang bisa
dipetakan langsung. Menambah satu status PTKP tanpa menambah entri Map akan
crash saat runtime, bukan gagal saat compile.

- [ ] **Frontend** — ganti jadi pemetaan langsung `PtkpStatus` → `double`
      (extension `ptkpAmount` dengan `switch` lengkap), hapus tanda `!`

**Perbaikan:** pemetaan status PTKP tidak lagi diturunkan dari teks tampilan.
`simulator_service.dart` sekarang memakai `switch` exhaustive atas enum statusnya,
jadi menambah status baru tanpa memetakannya gagal saat *compile* — bukan crash di
tangan pengguna. Nilai PTKP-nya sengaja tetap tinggal di `AppConstants.ptkp`
supaya tidak lahir daftar kedua seperti yang terjadi di T-13.

### ✅ T-6 — 66 pemakaian `withOpacity` yang sudah deprecated *(selesai 8 Sep 2026)*

Tersebar di ±20 file widget (dashboard, simulator, accounting). CI menjalankan
`flutter analyze --no-fatal-infos`, jadi ini tidak pernah menggagalkan PR —
sampai suatu saat Flutter mengangkatnya jadi error dan build rilis berhenti.

Perbaikannya mekanis: `withOpacity(0.5)` → `withValues(alpha: 0.5)`.

- [ ] **Frontend** — kerjakan sebagai **satu PR terpisah** (menyentuh ±20 file).
      Jangan dititipkan ke PR fitur; diff-nya akan menenggelamkan review

**Perbaikan:** nol pemakaian `withOpacity` tersisa di `app/lib`; 58 pemakaian
`withValues(alpha: …)` menggantikannya.

### ✅ T-7 — Dua `BuildContext` dipakai lewat async gap *(selesai 8 Sep 2026)*

- `screens/settings/settings_screen.dart:68` — `mounted` dicek **sebelum**
  `await AuthService.logout()`, lalu `context.go()` dipanggil sesudahnya. Cek
  `mounted`-nya ada di sisi yang salah dari `await`: kalau logout lambat dan
  layar keburu dilepas, `context.go` dilempar ke widget yang sudah mati.
- `widgets/accounting/month_picker.dart:389` — `context` dipakai di dalam
  `Future.microtask` setelah `Navigator.pop(context)` dipanggil.

- [ ] **Frontend** — pindahkan cek `mounted` ke sesudah `await` di
      `settings_screen.dart`; di `month_picker.dart` ambil `NavigatorState`
      sebelum pop, jangan bawa `context` masuk ke microtask

**Perbaikan:** kedua lokasi sudah dibereskan. Di `settings_screen.dart` cek
`mounted` dipindah ke **sesudah** `await AuthService.logout()`. Di
`month_picker.dart` `NavigatorState` diambil sebelum `pop()` lalu dipakai di dalam
microtask, jadi tidak ada `BuildContext` mati yang disentuh.

### 🟨 T-8 — Aksesibilitas nol *(sebagian, 8 Sep 2026)*

Nol pemakaian `Semantics`, `semanticLabel`, atau `excludeSemantics` di seluruh
53 file. Untuk aplikasi yang tayang sebagai web publik, artinya pembaca layar
tidak bisa membacakan grafik `fl_chart`, kartu KPI, maupun progress bar ambang
PKP.

- [ ] **Frontend** — `semanticLabel` untuk semua grafik dan progress bar
      (minimal: bacakan angkanya)
- [ ] **Frontend** — cek target sentuh ≥48dp dan kontras warna di mode terang
      dan gelap. Ini melengkapi tugas "polish UI" Minggu 8, bukan menggantikannya

**Kemajuan:** dari nol, kini ada 52 pemakaian
`Semantics`/`semanticLabel`/`excludeSemantics` di `app/lib`. Statusnya tetap 🟨
sebagian: cakupannya belum diaudit per layar, dan belum ada pengujian dengan
pembaca layar sungguhan.

### 🟡 T-9 — CI tidak menegakkan `dart format`

`analysis_options.yaml` menulis "Jalankan `dart format .` sebelum commit", tapi
tidak ada yang memeriksanya. Format yang tidak konsisten memicu konflik merge
yang sebenarnya tidak perlu — persis hal yang bisa dihindari kalau tim sepakat
soal format sejak awal.

- [ ] **Frontend** — tambahkan langkah `dart format --set-exit-if-changed .` di
      `ci.yml`. Jalankan `dart format .` sekali di seluruh repo lebih dulu
      supaya langkah barunya tidak langsung merah

### ⬜ T-10 — CI tanpa laporan coverage

`flutter test` jalan tanpa `--coverage`, jadi tidak ada yang tahu cakupan tes
naik atau turun antar-PR. Baru benar-benar berguna setelah T-2 selesai.

- [ ] **Frontend** — `flutter test --coverage` dan unggah `lcov.info` sebagai
      artifact CI

### ⬜ T-11 — `flutter_secure_storage` di web perlu diverifikasi

`storage_service.dart:3` menulis token disimpan di "Keychain/Keystore, WebCrypto
di web". Penyimpanan di browser punya model ancaman yang berbeda dari Keychain,
dan itu perlu dipastikan sebelum JWT asli menggantikan data contoh.

- [ ] **Backend + Frontend** — sebelum Minggu 5, sepakati umur token, mekanisme
      refresh, dan apakah refresh token boleh disimpan di browser sama sekali

**Perkembangan 13 Sep 2026:** dengan backend Supabase, sesi aslinya — termasuk
refresh token — dikelola klien Supabase di SharedPreferences (`localStorage`
di web), bukan di secure storage. Umur dan pembaruan token kini diatur Supabase
Auth; yang tersisa untuk diputuskan adalah apakah penyimpanan di `localStorage`
itu bisa diterima. Secure storage sendiri sempat membuat login pertama macet —
lihat T-17.

### ⬜ T-12 — Belum ada kerangka l10n

Semua string Indonesia ditulis langsung di widget; `intl` hanya dipakai untuk
format rupiah dan tanggal. Tidak mendesak selama produk hanya berbahasa
Indonesia, tapi biaya memisahkannya naik terus seiring bertambahnya layar.

- [ ] **Frontend** — ambil keputusan sadar: kalau memang tidak akan multi-bahasa,
      tulis itu di `wiki/arsitektur/gambaran-umum.md` supaya tidak jadi pertanyaan berulang

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

## Halaman terkait

- [Linimasa proyek](linimasa.md) — jadwal Minggu 1–9 dan milestone.
- [Log progres](log-progres.md) — catatan kemajuan harian.
