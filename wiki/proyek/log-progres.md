---
title: Log Progres
description: Catatan kemajuan harian Catatin Fase Dua — entri terbaru di atas dan tidak pernah dikoreksi ke belakang.
tags:
  - proyek
  - log
---

Catatan kemajuan harian Catatin Fase Dua. Dipisah dari
[linimasa](linimasa.md) supaya jadwalnya tetap enak dibaca sementara log ini
tumbuh terus.

> **Path pada entri lama:** entri sebelum 11 Sep 2026 menyebut berkas di
> `docs/`. Itu memang lokasinya saat itu — seluruh dokumentasi pindah ke
> `wiki/` pada 11 Sep 2026. Sengaja tidak ditulis ulang supaya catatannya
> tetap jujur.
>
> Tambahkan baris baru di atas (paling baru di atas), format:
> `- **YYYY-MM-DD** — [Nama/Peran] — apa yang selesai/berubah`

- **2026-09-22** — Produksi — lima migrasi yang tertunda diterapkan ke
  `catatin` atas izin pemilik tugas BE: `validasi_transaksi`,
  `transaksi_berulang` (pg_cron dipasang), `lampiran_struk` (bucket privat
  `receipts`), `pengerasan_validasi`, dan `pemantauan`. Sebelumnya dicek tidak
  ada baris produksi yang melanggar constraint baru; versi riwayat disamakan
  dengan nama berkas. Sidik katalog (constraint, kebijakan RLS, fungsi, hak
  tabel/kolom/fungsi, job pg_cron, bucket) identik dengan staging, jadi
  produksi = staging = main (7 migrasi). Workflow pemantauan kini mendapat
  HTTP 200 dari `catatin_health()` produksi. Temuan advisor baru hanya yang
  memang disengaja (`catatin_health` untuk `anon`, `latency_snapshots` tanpa
  kebijakan). Job transaksi berulang produksi pertama kali jalan 00:05 WIB
  23 Sep.

- **2026-09-22** — Backend — **Issue #103: pemantauan.** Migrasi `pemantauan`:
  tabel `app_errors` (galat terstruktur dari klien, tanpa pesan bebas, hanya
  bisa ditambah, dibatasi 30 laporan per 10 menit), cuplikan latensi
  `monthly_totals` dari `pg_stat_statements` tiap 15 menit lewat pg_cron, dan
  `catatin_health()` yang boleh dipanggil `anon`. Klien melaporkan 403 (bersesi),
  5xx, dan galat tak dikenal dari `runSupabase`. Workflow `pemantauan.yml`
  memanggilnya tiap 30 menit dengan publishable key — tanpa secret baru — dan
  gagal kalau galat, latensi, atau job transaksi berulang melewati ambang.
  Bagian khusus cloud (hak kolom, batas laju, `pg_stat_statements`, jadwal
  pg_cron) dibuktikan di staging dengan pola rollback. Detail:
  [Supabase §11](../arsitektur/supabase.md#11-pemantauan).

- **2026-09-22** — Backend — **Issue #89: nilai awal Simulator
  (`GET /simulator/inputs`).** `SimulatorRepository.getInputs` di keempat mode
  dan fasad `SimulatorInputService`: rata-rata tiga bulan penuh sebelum bulan
  acuan (dibagi bulan yang berdata), angka bulan acuan, omzet YTD, dan profil
  usaha — tanpa hitungan pajak. Satu aturan (`simulatorInputsFrom`) dipakai mock
  dan Supabase; Supabase memakai `monthly_totals` yang sudah ada, jadi tanpa
  migrasi. Contoh kontrak diambil dari data contoh staging dan dikunci tes.
  Siap untuk PR FE #35 (Simulator dari Pembukuan, 15 Okt).

- **2026-09-22** — Backend — **Issue #75: uji beban ringan agregasi.**
  `supabase/staging/uji_beban_agregasi.sql` (aman: digulung balik) dijalankan
  di staging dengan 50 akun × 12 bulan × 200 transaksi = 120.000 baris.
  p95 di database: `monthly_totals` 4,2 ms, satu bulan Pembukuan 1,1 ms,
  setahun tiga halaman (jalur ekspor) 30,4 ms; indeks
  `transactions_user_date_idx` terpakai dan isolasi RLS tetap benar. Hasil
  lengkap dan batasannya di [Supabase §10](../arsitektur/supabase.md#10-uji-beban).
  Bagian ekspor CSV diukur ulang setelah #72.

- **2026-09-22** — Staging — migrasi `pengerasan_validasi` (#115) diterapkan
  ke staging setelah PR #178 merge; staging kini sama dengan main (6 migrasi).

- **2026-09-22** — Backend — **Issue #115: pengerasan validasi input, dan
  staging disamakan dengan main.** Migrasi `pengerasan_validasi`: FK komposit
  `(…, user_id)` membuat transaksi, templat berulang, dan lampiran mustahil
  menempel ke data akun lain — juga untuk peran yang melewati RLS seperti
  pg_cron; batas 500 karakter untuk keterangan/catatan struk dan 100 untuk
  kolom profil usaha; NPWP hanya angka, titik, tanda hubung. Nominal dan
  tanggal sudah dijaga sejak #40. Klien memetakan tiap constraint baru ke
  pesan per field. Sebelum migrasi itu, tiga migrasi yang sudah merge
  (`validasi_transaksi`, `transaksi_berulang`, `lampiran_struk`) diterapkan ke
  staging lewat MCP dan versinya disamakan dengan nama berkas — secret deploy
  staging belum dipasang. Migrasi #115 dibuktikan di staging dengan pola
  rollback: 23 hasil sama persis dengan tes pgTAP-nya.

- **2026-09-22** — Backend — **Issue #74: ringkasan tutup bulan.**
  `DashboardRepository.getMonthClose(month, year)` dan model `MonthClose`
  (pemasukan, pengeluaran, laba, HPP, jumlah transaksi, omzet YTD) di keempat
  mode. Supabase memakai `rpc('monthly_totals')` yang sudah ada, jadi tanpa
  migrasi dan angkanya identik dengan agregat tahunan serta ringkasan
  dashboard. Mock dihitung dari agregat transaksi contoh, bukan angka tetap.
  Bulan di luar 1–12 ditolak di klien dengan `400 validation_failed`
  sebelum permintaan dikirim. Kartu "Bulan ini" di Dashboard (PR FE #29)
  tinggal memanggil `DashboardService.getMonthClose`.

- **2026-09-18** — Frontend — **Issue #9, #10, #12, #13, #14: hotfix tayang,
  gerbang CI, skrip build aman, dan bug lapisan data.** Lima cabang, satu issue
  masing-masing.
  **#9 (T-17) — chip kepercayaan.** Panel hasil Simulator dan blok "Kewajiban
  berikutnya" di Dashboard menampilkan angka sebagai fakta, padahal tarif TER
  kategori B/C belum benar (T-1) dan persona usaha sendiri masih dihitung dengan
  rezim PPh 21. Keduanya kini membawa `DsTrustChip`, dipasang **di atas** angka.
  Levelnya dibaca dari `AppConstants.taxReviewStatus`, jadi saat sign-off pakar
  turun cukup mengubah dua baris konstanta. Token baru `DS.warnBg/warnFg` +
  varian `OnDark`; kontras teks terukur 6,75:1 terang, 8,44:1 gelap, 9,32:1 di
  panel simulator. Nol perhitungan pajak diubah.
  **#10 (T-42) — publikasi menunggu CI.** `publish-web.yml` dulu dipicu
  `push: main`, pemicu yang sama dengan `ci.yml` dan tanpa hubungan di antara
  keduanya, sehingga commit dengan tes merah tetap tayang. Kini `workflow_run`
  setelah CI sukses, checkout memakai `workflow_run.head_sha` (commit yang
  benar-benar diuji, bukan yang terbaru di branch), dan `git pull --rebase`
  sebelum push.
  **#12 (T-29) — skrip build berhenti menghapus berkas pengembang.**
  `sync_build.sh` dan `build_web.ps1` menghapus semua isi root di luar daftar
  `KEEP`, dan karena `dotglob`/`-Force` dotfile ikut. Kini hanya jejak build
  sebelumnya (manifes `tool/.last_build_files`) yang dihapus, default dry-run,
  butuh `--yes` (`CI=true` menyiratkannya). Diuji di root palsu: skrip lama
  menghapus `.env`, `.vscode/settings.json`, dan `coretan/ide.md`; skrip baru
  menyisakan ketiganya dan tetap membuang sisa build sungguhan.
  **#13 (T-16, T-24, T-19, T-22) — bug frontend murni.** `_orFallback` di
  `hybrid_repositories.dart` menangkap setiap `ApiException` lalu jatuh ke mock:
  kata sandi salah (401) membuka sesi sebagai pengguna demo, dan penolakan
  validasi backend (400/422) dilaporkan "berhasil" lalu hilang saat muat ulang.
  Fallback kini hanya untuk statusCode 0/404/501, dan seluruh operasi auth
  memakai `allowFallback: false`. Jumlah blok `try` tidak bertambah —
  perbaikannya menangkap lebih sedikit, bukan menambah penanganan error.
  Dashboard membuka rute penuh-layar dengan `context.push`, bukan `context.go`
  (tab di dalam ShellRoute sengaja tetap `go`); layar Notifikasi mendapat tombol
  kembali eksplisit. `accounting_screen` memakai `ErrorState` + Coba Lagi
  alih-alih SnackBar sekilas di atas daftar kosong. Tes baru
  `test/hybrid_fallback_test.dart`, 6 kasus, memeriksa juga bahwa jalur mock
  **tidak** tersentuh. T-18 sudah selesai lebih dulu di `main`.
  **#14 (P-12) — dokumen vs kenyataan.** Larangan `dart format` di
  [Kontribusi](../panduan/kontribusi.md) ditandai sementara dengan kapan ia
  terbalik (PR format Minggu 2); baris `core/theme/` di
  [Arsitektur](../arsitektur/gambaran-umum.md) kini menyebut `design_tokens.dart`
  dan `breakpoints.dart` sebagai sistem yang berlaku; header `breakpoints.dart`
  berhenti mengklaim penggantian breakpoint literal sudah tuntas — belum, masih
  ada di empat berkas. Versi Flutter di README sengaja **tidak** disamakan:
  3.38.4 adalah lantai sungguhan (`fl_chart` 1.2.x butuh `vector_math` ^2.2.0),
  dan 3.44.8 memang versi CI — keduanya sudah benar.
  **Verifikasi** (Flutter 3.44.8, per cabang): `flutter analyze` 0 error di
  kelimanya; #9/#10/#12/#14 tetap 40 info, #13 jadi 41 (satu info baru, bukan
  error). `flutter test` 105 lulus + 1 di-skip di empat cabang, **111 + 1** di
  #13 — tepat enam tes baru. `flutter build web --release` sukses.

- **2026-09-18** — TAX — **Spesifikasi pajak Minggu 1 dikunci (#21–#27).**
  Folder baru `wiki/domain/pajak/` berisi
  [spek PPh 21 TER](../domain/pajak/spek-pph21-ter.md),
  [spek PPh Final UMKM](../domain/pajak/spek-pph-final-umkm.md),
  [keputusan TAX](../domain/pajak/keputusan-tax.md),
  serta dua berkas data: `ter-bulanan.csv` (tabel TER bulanan, bentuk normatif)
  dan `kasus-pph21.csv` (15 kasus uji pada batas lapisan). Sumbernya slide
  sosialisasi PMK 168/2023 yang diserahkan TAX, disimpan di
  [wiki/sumber](../sumber/pmk-168-2023-slide-ter.md).
  **Temuan 1 — `terTableA` salah, bukan sekadar kurang.** Tabel resmi kategori A
  punya 44 lapisan, kode punya 32, dan 28 di antaranya salah tarif atau salah
  batas; dua belas lapisan teratas (Rp 62.200.001–Rp 1.400.000.000, 21%–33%)
  hilang sama sekali. Bruto Rp 20 juta dihitung 11% padahal tarif resminya 9%.
  Ini memperberat T-1 dan belum punya nomor temuan sendiri.
  **Temuan 2 — tenggat SPT Tahunan OP salah.** `generateCalendar()` memakai
  30 April; yang benar 31 Maret. Membuka jalan untuk #154 (T-25).
  **Keputusan.** D-8: tarif PPN 11% ditetapkan (dasar hukum masih `[CEK]`);
  lingkup modul PPN dan proyeksi SPT Tahunan direkomendasikan keluar dari Fase
  Dua, `kind` `PPN` dihapus dari skema mesin tarif tetapi `PPH_PASAL_17`
  dipertahankan karena dipakai pada masa pajak terakhir — ratifikasinya masih
  menunggu di #26. D-10: aturan tampilan, termasuk larangan menampilkan angka
  PKP di layar PPh 21 (T-4). D-11: matriks profesi ke rezim pajak, dengan batas
  bahwa Catatin hanya memodelkan dua profil.
  **Yang sengaja dibiarkan terbuka:** besaran biaya jabatan tidak tercantum di
  sumber mana pun yang tersedia, dan seluruh angka PPh Final menunggu salinan
  PP 23/2018 serta PP 55/2022. Semuanya terdaftar sebagai `[CEK]` dan tidak ada
  yang menjadi prasyarat pekerjaan FE/BE Minggu 2.

- **2026-09-15** — Backend — **Issue #17–#20: staging Supabase, CI database,
  kontrak transaksi, dan draf skema mesin tarif.** Keempat issue ditulis PO
  sebelum D-7 ([sumber](../sumber/github-issue-17-20-backend-minggu-1.md)); #17
  dan #18 dikerjakan sebagai padanan Supabase sesuai poin 5 D-7
  ([sumber](../sumber/github-issue-149-d7-stack-backend.md)) — tanpa repo
  `catatin-api` dan tanpa mock server Prism.
  **#17 — lingkungan & CI.** Proyek `catatin-staging` (ref
  `herafvadqziftszhxqeq`, paket Free, $0/bulan) dibuat lewat konektor Supabase;
  migrasi diterapkan lalu versinya disamakan dengan berkas lokal. URL kedua
  proyek dicatat di [Backend & API §1](../arsitektur/backend-dan-api.md).
  `supabase/config.toml` diturunkan dari template CLI 2.117.0. Workflow
  `supabase.yml` membangun migrasi dari nol, menjalankan `db lint --fail-on
  warning`, lalu pgTAP — uji isolasi RLS 13 Sep yang dulu manual kini otomatis
  ([Supabase §9](../arsitektur/supabase.md#9-ci-database)).
  **#18 — staging mengembalikan contoh kontrak.** `supabase/staging/data_contoh.sql`
  mengisi satu akun dengan angka persis contoh JSON di wiki. Login staging lewat
  daftar email: `EMAIL_SIGNUP=true` hanya di `dart_define.staging.json`, dan
  Google tidak dinyalakan di staging sehingga celah penggabungan akun tidak
  berlaku ([Supabase §8](../arsitektur/supabase.md#8-staging-dan-data-contoh)).
  Karena bukan server REST, FE menguji di mode `supabase`, bukan `hybrid`.
  **#19 — kontrak.** `getTransactions` menerima `from`/`to` inklusif dan
  `getAggregate(year)` mengembalikan `YearAggregate`, di keempat mode — Supabase
  memakai `monthly_totals`, tanpa migrasi. Galat REST `{error, code, details}`
  diurai `apiExceptionFromResponse`. Kontrak PATCH dilengkapi; implementasinya
  sudah ada sejak 13 Sep. **Bug yang ikut dibereskan:** mode `api` memaksa filter
  bulan berjalan saat tanpa filter, jadi layar Pencatatan mode api/hybrid hanya
  menampilkan satu bulan sementara mock dan Supabase menampilkan semuanya.
  `monthAggregates()` kini satu-satunya tempat omzet YTD dihitung di klien
  (pelajaran T-13).
  **#20 — draf skema** di
  [Backend & API §7](../arsitektur/backend-dan-api.md#7-skema-mesin-tarif-pajak-draf-untuk-review-tax):
  versi konfigurasi yang dikunci setelah disetujui, lapisan `(tier_min, tier_max]`
  yang dijaga exclusion constraint, `ptkp`, usulan `tax_parameters`, dan hak tulis
  hanya untuk `app_metadata.role = 'tax_admin'`. Tanpa satu pun angka tarif;
  menunggu review pakar pajak (#45).
  **Catatan penomoran:** T-20 dan T-21 di judul #19 memakai penomoran PO
  (bandingkan #36 "T-20b"), bukan T-20 di [backlog teknis](backlog-teknis.md)
  yang berarti uji login Google di Android.
  **Terverifikasi:** `flutter analyze` 0 warning/error, 40 info (turun dari 41);
  `flutter test` 105 lulus, 1 di-skip. Workflow Supabase hijau: kedua migrasi
  dari nol, lint "No schema errors found", 43 tes pgTAP dan 10 tes data contoh.
  Run sebelumnya sempat merah karena `supabase test db` hanya me-mount
  `supabase/tests`, lalu tes data contoh dipindah ke sebelah skripnya. Staging:
  sidik jari katalog identik dengan produksi, Security Advisor hanya lint 0029
  yang disengaja, `auth/v1/settings` menunjukkan Google mati dan autoconfirm mati,
  REST tanpa sesi ditolak 401. Skrip data contoh dan DDL §7 (24 pemeriksaan
  constraint, trigger, dan RLS) dijalankan di staging dalam transaksi yang
  dibatalkan; sesudahnya 0 akun, 0 profil, 0 transaksi, dan tabel pajak tidak ada.
  **Belum:** uji FE login → dashboard → transaksi di staging dengan akun
  sungguhan (FE perlu diundang ke organisasi Supabase dulu), review TAX atas §7,
  dan keputusan T-19 yang kini berlaku untuk dua proyek.

- **2026-09-15** — Backend + PO — **D-7: backend tetap Supabase (BaaS), bukan
  server buatan sendiri.** Diputuskan bersama PO untuk issue #16; rationale
  lima barisnya dicatat di komentar issue #149
  ([sumber](../sumber/github-issue-149-d7-stack-backend.md)).
  **Alasan:** Supabase sudah tayang dan teruji sejak 13 Sep — Auth dengan login
  Google, tiga tabel ber-RLS, `monthly_totals` ([Supabase](../arsitektur/supabase.md)).
  Tim hanya satu backend untuk sembilan minggu ([linimasa](linimasa.md)), jadi
  tidak ada server, TLS, CORS, rotasi token, atau hosting yang perlu dirawat.
  Kebutuhan roadmap direncanakan memakai padanan di platform: konfigurasi tarif
  berversi di tabel Postgres + RLS peran admin, lampiran struk di Storage,
  transaksi berulang lewat `pg_cron`, mesin tarif dan CSV lewat fungsi SQL atau
  Edge Functions yang dites dengan pgTAP terhadap `kasus-*.csv`.
  **Risiko yang diterima:** paket Free dijeda setelah seminggu tidak aktif,
  tanpa backup otomatis, dan maksimal dua proyek aktif
  ([sumber](../sumber/supabase-pricing-pausing.md)) — T-19 di
  [backlog teknis](backlog-teknis.md) wajib diputuskan sebelum M5.
  **Konsekuensi:** issue yang ditulis untuk backend REST kustom (#17, #18, #39,
  #43, #129) perlu disesuaikan PO ke padanan Supabase; mode `api` (Dio) tetap
  ada sebagai cadangan, bukan target.

- **2026-09-15** — Backend — **Rujukan `docs/` di issue GitHub diarahkan ke
  `wiki/`.** 33 issue terbuka masih menyebut `docs/…` atau nama berkas lama di
  judul, catatan, dan komentar penugasannya; semuanya kini menunjuk path wiki.
  Berkas yang sudah ada dipetakan ke halamannya dengan nomor § tetap, mis.
  `BACKEND.md` → [Backend & API](../arsitektur/backend-dan-api.md). Dokumen
  rencana yang belum pernah dibuat diberi path mengikuti konvensi wiki:
  spesifikasi, kasus uji, sign-off, dan catatan rilis pajak di
  `wiki/domain/pajak/` (`spek-*.md`, `kasus-*.csv`, `sign-off.md`,
  `catatan-rilis.md`), checklist regresi di
  `wiki/panduan/checklist-regresi-ui.md`, alur kerja di
  `wiki/proyek/alur-kerja.md`. Buat berkasnya di path itu supaya issue tetap
  cocok. Dua sisa rujukan di repo ikut dibereskan: komentar
  `design_tokens.dart` dan [brief Claude Design](../desain/brief-claude-design.md).

- **2026-09-13** — Backend + Frontend — **Status kata sandi dari `has_password()`.**
  Uji pemilik di situs publik: pasang kata sandi (`PUT /user` 200) → keluar
  (`POST /logout` 204) → masuk dengan email + kata sandi (`grant_type=password`
  200), tetap satu akun. Tapi Pengaturan tetap menulis "Belum dipasang":
  Supabase Auth hanya membuat identitas `email` bila flag eksperimental
  `CreateEmailIdentityOnPasswordSetEnabled` menyala, dan klaim sebaliknya di wiki
  keliru. **Perbaikan:** migrasi `20260913135347_fungsi_has_password` — fungsi
  `security definer` tanpa parameter yang hanya menjawab true/false untuk
  `auth.uid()`; `signInProviders()` memakainya. Diuji dalam transaksi yang
  dibatalkan: akun pemilik `true`, akun lain `false`, `authenticated` tetap
  ditolak membaca `auth.users`, `anon` ditolak memanggil fungsi. Security
  Advisor kini melaporkan lint 0029 untuk fungsi ini — disengaja. Catatan: akun
  pemilik sengaja dihapus pemiliknya sendiri lewat dashboard pukul 13:49 untuk
  menguji pendaftaran dari awal (dikonfirmasi), jadi profil usaha dan transaksi
  uji sebelumnya ikut terhapus lewat `on delete cascade`.
  **Keadaan akhir hari ini:** situs publik tersambung ke proyek `catatin`;
  pendaftaran lewat Google (Confirm email tetap menyala, form daftar email
  disembunyikan); akun Google bisa memasang kata sandi dan masuk dengan email +
  kata sandi; tombol Keluar mencabut sesi di server. Semua alur itu sudah diuji
  pemilik di situs publik dan dicek di database. Sisa: T-18 (custom SMTP),
  T-19 (proyek Free dijeda), T-20 (uji Android).

- **2026-09-13** — Frontend — **Satu akun, dua cara masuk.** Akun yang daftar
  lewat Google bisa memasang kata sandi di Pengaturan → Cara masuk, lalu masuk
  ke akun yang sama dengan email Google + kata sandi — tanpa akun kedua dan
  tanpa SMTP. Kontrak `AuthRepository` dapat `signInProviders()` dan
  `setPassword()`; galat `same_password`, `current_password_required`,
  `current_password_invalid`, dan `reauthentication_needed` diterjemahkan.
  "Lupa kata sandi?" kini mengarahkan ke jalur Google → Pengaturan. Label
  `DsButton` yang tidak melebar kini tertengah vertikal (sebelumnya menempel di
  atas, mis. "Isi profil usaha").
  **Uji ujung-ke-ujung Google di situs publik (akun pemilik):** daftar →
  onboarding → catat transaksi → keluar → masuk lagi, dicek di database —
  identitas `google`, satu profil usaha, transaksi di usaha milik akun yang sama.
  Percobaan pertama sempat dikembalikan ke `localhost:3000` karena Site URL dan
  Redirect URLs belum tersimpan di dashboard. Tombol Keluar diuji dengan sesi
  palsu dan terbukti mengirim `POST /auth/v1/logout`; satu sesi lama pemilik
  masih tercatat aktif karena logout-nya tidak lewat tombol itu.
  **Terverifikasi:** `flutter analyze` 41 info, `flutter test` 86 lulus. Di
  build lokal dengan sesi palsu akun Google: Pengaturan menampilkan Google
  "Terhubung" dan Email & kata sandi "Belum dipasang", dialog memvalidasi
  kolom kosong, "Lupa kata sandi?" menampilkan petunjuk.
  **Belum:** memasang kata sandi lalu masuk dengan email + kata sandi memakai
  akun sungguhan.

- **2026-09-13** — Frontend + Backend — **Masuk & daftar dengan Google.**
  Tombol Google di layar masuk dan daftar (web + Android) lewat
  `signInWithOAuth` Supabase; provider Google dan Redirect URLs disetel pemilik
  akun di dashboard, Client Secret tidak pernah lewat repo. Sesi hasil login
  diadopsi `AuthService` (web: saat halaman dimuat ulang; Android: event
  `signedIn` dari deep link). **Keputusan direvisi:** *Confirm email* tetap
  menyala — kode Supabase Auth menganggap email terverifikasi saat konfirmasi
  mati, sehingga login Google bisa tergabung ke akun yang didaftarkan orang
  lain lebih dulu. Form daftar email disembunyikan sampai custom SMTP siap
  (T-18); Android belum diuji di perangkat (T-20).
  **Ditemukan saat uji di peramban:** stream Auth Supabase memutar ulang galat
  lama ke pendengar baru sehingga "dibatalkan" tertimpa "gagal", dan Supabase
  tidak membersihkan `?error=` dari alamat — keduanya dibereskan. Berkas unduhan
  `client_secret_*.json` sempat tersimpan di `supabase/`; tidak pernah
  di-commit, dan polanya kini diabaikan `.gitignore`.
  **Terverifikasi:** `flutter analyze` 41 info (0 warning/error), `flutter test`
  83 lulus. `/auth/v1/settings` → `google: true`, `mailer_autoconfirm: false`;
  `/auth/v1/authorize?provider=google` → 302 ke `accounts.google.com` dengan
  callback proyek. Build lokal: tombol membuka Google dengan `redirect_to`
  alamat lokal + PKCE; kembalian `?error=access_denied` menampilkan "Masuk
  dengan Google dibatalkan." dan alamat bersih; layar daftar hanya tombol
  Google.
  **Belum:** login Google sampai selesai dengan akun sungguhan.

- **2026-09-13** — Backend — **Situs publik memakai database Supabase
  asli.** Proyek `catatin` (ref `mhoadvaiarjbbzlltqxy`, Singapore, paket Free)
  dibuat lewat konektor Supabase di Claude, bukan CLI: Node.js belum terpasang,
  dan alur CLI butuh kode login serta password database yang harus diketik
  pemilik akun. Migrasi diterapkan dengan `apply_migration` sehingga versinya
  `20260913101045`; berkas lokal diganti nama menyamainya.
  `app/dart_define.pages.json` diisi URL + publishable key.
  **Keputusan:** *Confirm email* dimatikan karena belum ada domain untuk custom
  SMTP — risikonya jadi **T-18**; proyek Free yang dijeda saat sepi jadi
  **T-19**. Push `ce4639e` sebelumnya ternyata tidak memicu workflow apa pun;
  cara memicu manual dicatat di [Rilis & deploy](../panduan/rilis-dan-deploy.md).
  **Terverifikasi:** Security Advisor 0 temuan (Performance hanya 3 info indeks
  belum terpakai di database kosong). RLS aktif di tiga tabel, 15 kategori,
  9 policy, `anon` tanpa hak apa pun. Uji isolasi di satu transaksi yang
  dibatalkan: pengguna B melihat 0 transaksi dan 0 profil milik A, ubah/hapus
  transaksi A mengenai 0 baris, insert ke usaha A dan menyamar sebagai A
  ditolak `42501`; `monthly_totals` A benar. REST dengan publishable key tanpa
  sesi ditolak `401/42501`. `flutter analyze` 41 info, `flutter test` 71 lulus,
  build web berisi URL proyek; di peramban mode demo jalan tanpa request ke
  Supabase dan bertahan setelah reload.
  **Belum:** daftar → onboarding → catat transaksi dengan akun sungguhan di
  situs yang tayang.

- **2026-09-13** — Frontend — **Aplikasi tersambung ke Supabase** (branch
  `fitur/supabase`), belum aktif karena proyek Supabase-nya belum dibuat.
  **Keputusan:** Supabase dipasang sebagai implementasi repository keempat
  (`DATA_SOURCE=supabase`) di samping mock, REST, dan hybrid — Dio tidak
  dihapus. Skema lewat Supabase CLI di `supabase/migrations/`. Situs publik ikut
  tersambung lewat `app/dart_define.pages.json` yang di-commit, karena
  publishable key memang publik dan akun kontributor tidak bisa menyetel repo
  Variables. Hybrid sengaja tidak dipasangkan dengan Supabase: fallback-nya
  menutupi login gagal dengan login palsu.
  **Isi:** `supabase_client.dart` (inisialisasi + penerjemah galat ke
  `ApiException`), `supabase_repositories.dart`, migrasi tiga tabel ber-RLS +
  fungsi `monthly_totals`, halaman [Supabase](../arsitektur/supabase.md).
  Kontrak dapat `logout()` dan `updateTransaction()` — lembar "Edit transaksi"
  selama ini melapor sukses tanpa menyimpan apa pun.
  **Bug yang baru kelihatan dengan data asli, ikut dibereskan:** lembar tambah
  transaksi mengirim `DEBIT` padahal model memakai `KARTU_DEBIT`; pengguna lama
  bisa terpental bolak-balik antara dashboard dan onboarding; layar Pencatatan,
  detail, Pengaturan, dan Profil usaha macet di spinner saat request gagal;
  tombol kembali di detail transaksi dan tambah transaksi melempar galat karena
  rutenya dibuka dengan `context.go`; dashboard tidak memuat ulang setelah
  transaksi dicatat; `AppConfig` tidak benar-benar jatuh ke mock walau
  `configError` bilang begitu; **T-17** — klik pertama tombol demo (dan nanti
  login pertama pengguna baru) macet karena token ditulis serentak ke secure
  storage web. Mode demo kini selalu memakai data contoh, juga di build
  tersambung backend. **T-16** (tenggat PPN meluap) dicatat, menunggu pakar
  pajak.
  **Terverifikasi:** `flutter analyze` → 0 error, 0 warning, 41 info (sama
  persis dengan sebelum perubahan). `flutter test` → 71 lulus, 1 di-skip.
  `flutter build web --release` dengan berkas Pages → berhasil; `main.dart.js`
  3.564.704 byte, naik ±143 KB dari build yang tayang. Di peramban: build
  berkas Pages kosong jatuh ke data contoh; build mode Supabase ke alamat yang
  sengaja mati memanggil `/auth/v1/token`, menampilkan pesan koneksi tanpa
  spinner macet, mode demonya jalan tanpa satu pun request ke Supabase, sesi
  demo lama dibersihkan saat dibuka, dan keluar kembali ke layar masuk.
  **Belum:** migrasi belum pernah dijalankan ke Postgres sungguhan (Docker lokal
  mati, proyek belum ada) dan alur daftar → onboarding → catat transaksi
  belum diuji ujung-ke-ujung.

- **2026-09-08** — Frontend — **T-15 selesai.** Kelas tipografi `T` di
  `design_tokens.dart` diganti nama jadi `Typo` — 142 pemakaian di 15 berkas —
  lalu parameter generic di `tx_add_sheet.dart` dikembalikan dari `V` ke `T`.
  Ini menghapus tambalan yang dipasang saat menggayakan ulang alur transaksi:
  waktu itu generic-nya yang mengalah, padahal token-lah yang memakai nama
  konvensional milik generic. Sekarang `_DdItem<T>` dan `_SheetDropdown<T>`
  memakai `T` seperti lazimnya, dan `Typo.sans()` tetap resolve di dalamnya.
  `Typo` dipilih agar sebaris dengan `DS`, `Space`, dan `Radii`, sekaligus
  tidak tertukar dengan `AppTextStyles` lama yang masih dipakai layar yang
  belum didesain ulang.
  Nol perubahan perilaku — murni penggantian nama.
  `flutter analyze` → 0 error, 0 warning, 39 info. `flutter test` → 39 lulus,
  1 di-skip. `flutter build web --release` → berhasil.

- **2026-09-08** — Frontend — Alur transaksi diseragamkan gayanya, dan **T-15**
  (baru) dicatat.
  **`tx_form_widgets.dart`** ditulis ulang — ini titik ungkit alur transaksi
  karena dipakai `new_transaction_screen.dart` **dan** `tx_add_sheet.dart`
  sekaligus. `TypeToggle` jadi pil segmented; `AmountInput` memakai pola yang
  sama persis dengan input penghasilan di Simulator (garis bawah warna merek,
  angka besar, tanpa kotak) sehingga "masukkan nominal rupiah" kini satu pola
  di seluruh aplikasi; `CategoryGrid` berubah dari grid rasio 2,8 jadi pil yang
  membungkus dengan target sentuh ≥46; `PaymentMethodPicker` juga — sebelumnya
  padding vertikalnya cuma 7, jauh di bawah ambang target sentuh.
  **`new_transaction_screen.dart`** dan **`tx_detail_screen.dart`** ditulis
  ulang penuh. Di detail, nominal jadi satu angka besar di puncak layar
  alih-alih kartu berwarna, sisanya turun jadi daftar baris berpemisah tipis.
  Konfirmasi hapus tetap inline, bukan dialog — menjaga R-5.
  **`tx_add_sheet.dart`** (770 baris) hanya dipetakan tokennya, tidak ditulis
  ulang: berkas itu memuat `TxEditSheet` dan dropdown generik dengan logika
  sendiri, dan menulis ulangnya utuh berisiko tanpa tes yang menjaganya.
  **T-15 (baru)** — kelas tipografi bernama `T` bentrok dengan parameter
  generic `T` di `tx_add_sheet.dart`. Ditambal dengan mengganti generic-nya
  jadi `V`; nama kelasnya sendiri yang sebaiknya diganti. Lihat entrinya.
  **Emoji sebagai ikon** kategori dan metode bayar dipertahankan — nilainya
  datang dari data (`cat.icon`, `pm.icon`), jadi menggantinya butuh perubahan
  di sisi data, bukan di UI.
  `flutter analyze` → 0 error, 0 warning, 39 info. `flutter test` → 39 lulus,
  1 di-skip. `flutter build web --release` → berhasil.

- **2026-09-08** — Frontend — Lanjutan kerja tanpa ketergantungan Backend/Pakar
  pajak: **T-7** dan **T-6** selesai, **T-8** sebagian, layar auth dan Profil
  usaha diseragamkan gayanya, dan **T-14** (baru) dicatat.
  **T-7** — `month_picker.dart` mengambil `NavigatorState` sebelum `pop()`,
  jadi `context` tidak lagi dibawa masuk ke `Future.microtask` setelah
  route-nya dilepas. Nol `use_build_context_synchronously` tersisa di repo.
  **Layar masuk & daftar** — wordmark masih tertulis "NamaAppmu", sisa scaffold
  yang tidak pernah diganti padahal itu layar pertama yang dilihat siapa pun.
  Sekarang memakai `DsWordmark` yang sama dengan rail navigasi. Keduanya
  memakai `DsField`/`DsButton`, dan form dibatasi 420px lalu ditengahkan di
  layar lebar (sebelumnya membentang penuh).
  **Profil usaha** — ditulis ulang dengan gaya yang sama. Mengikuti R-6, form
  kini terbuka dengan tiga hal (nama usaha, jenis usaha, status PKP); nama
  pemilik, NPWP, dan jumlah karyawan pindah ke "Detail tambahan" yang otomatis
  terbuka kalau sudah terisi atau kalau validasinya gagal. Mode onboarding,
  tombol lewati, formatter NPWP, dan layar sukses semuanya dipertahankan.
  **T-6** — 52 pemakaian `withOpacity` tersisa diganti `withValues(alpha:)` di
  17 berkas. Nol tersisa. Total isu `flutter analyze` turun dari 92 jadi 40.
  **T-8 (sebagian)** — label semantik ditambahkan ke seluruh grafik dan
  indikator yang **benar-benar terjangkau**: empat grafik di tab Total
  Pencatatan, grafik batang skenario, dan progress bar ambang PKP di
  `sim_widgets.dart`. Layar hasil redesain (Dashboard, Simulator, Pengaturan,
  auth, Profil usaha) sudah membawa semantiknya sendiri sejak ditulis.
  **Belum:** pengukuran kontras dan uji pembaca layar sungguhan — keduanya
  perlu perangkat, bukan pembacaan kode.
  **T-14 (baru)** — sepuluh widget dashboard lama (3.225 baris) jadi yatim
  setelah redesain; nol referensi eksternal. Butuh keputusan hapus-atau-tahan,
  dan harus jadi PR tersendiri.
  **T-9 tetap ditahan** sesuai permintaan, dikerjakan setelah semua ini.
  `flutter analyze` → 0 error, 0 warning, 40 info. `flutter test` → 39 lulus,
  1 di-skip. `flutter build web --release` → berhasil.
  **Catatan proses — analyze lokal tidak sama dengan CI.** PR #3 sempat merah
  karena `unnecessary_non_null_assertion` di `simulator_service.dart`, padahal
  `flutter analyze` lokal melaporkan nol warning. Sebabnya beda versi: mesin
  lokal memakai Flutter **3.44.0**, CI memakai **3.44.8**, dan analyzer versi
  baru menaikkan lint itu jadi warning. Karena `ci.yml` memakai
  `--no-fatal-infos`, warning menggagalkan build sementara info tidak — jadi
  "nol warning di lokal" **bukan** jaminan CI hijau. Samakan versi Flutter
  lokal dengan pin CI, atau perlakukan hasil CI sebagai satu-satunya sumber
  kebenaran sebelum menyatakan sebuah PR bersih.

- **2026-09-08** — Frontend — Menyelesaikan tiga temuan yang tidak bergantung
  Backend maupun Pakar pajak: **T-2**, **T-5**, dan **T-13** (baru).
  **T-2** — `test/simulator_service_test.dart` dibuat: 34 tes untuk
  `calculatePPhFinal`, `calculatePPh21`, `buildTerTable`, dan
  `calculateScenarios`. Total tes repo naik dari 5 jadi 39, semuanya lulus.
  Yang diuji sengaja dibatasi pada **konsistensi internal dan sifat
  struktural** — batas lapisan, monotonisitas tarif, jumlah komponen, tepi
  ambang PKP, pembagian nol — bukan kebenaran tarif terhadap peraturan.
  Kebenaran tarif tetap wewenang pakar pajak (T-1, T-3, T-4), dan mengunci
  angkanya di tes justru akan mengabadikan yang mungkin salah. Satu tes sengaja
  di-`skip` sebagai penanda T-1: ia menyatakan dua status di kategori TER
  berbeda tidak boleh menghasilkan tarif sama. Hapus `skip`-nya begitu tabel B
  dan C masuk — itu sekaligus jadi verifikasi perbaikannya.
  **T-13 (baru, ditemukan lewat T-2)** — `buildTerTable()` ternyata menyimpan
  daftar tarif kedua yang ditulis tangan dan sudah menyimpang dari
  `terTableA`: Rp 8 jt ditampilkan 1,5% tapi dihitung 2,0%, Rp 12 jt
  ditampilkan 5,0% tapi dihitung 6,0%, lapisan tertinggi ditulis 19% padahal
  34%. Sekarang diturunkan dari `terTableA` sehingga tidak bisa menyimpang
  lagi. Nol tarif diubah — murni menghapus duplikasi, bukan keputusan pajak.
  Dampak ke pengguna saat ini nihil: `buildTerTable()` cuma dipakai
  `pph21_tab.dart` yang sudah tidak terpasang.
  **T-5** — pemetaan PTKP tidak lagi lewat label tampilan
  (`shortLabel.replaceAll('/','')`). Ditambahkan `ptkpKey` dengan `switch`
  exhaustive, jadi status baru yang belum dipetakan gagal saat compile.
  Nilainya tetap di `AppConstants.ptkp` — menyalinnya ke service akan
  mengulang persis masalah T-13 — dan kelengkapannya dijaga dua tes baru.
  **Belum dikerjakan:** T-9 (`dart format` di CI). `dart format` akan mengubah
  **57 dari 60 berkas**, jadi harus jadi PR tersendiri supaya tidak
  menenggelamkan review. T-6, T-7, T-8, T-10 juga masih terbuka dan semuanya
  tidak terblokir.
  `flutter analyze` → 0 error, 0 warning. `flutter test` → 39 lulus, 1 di-skip.

- **2026-09-08** — Frontend — Tindak lanjut review PR #2: beresi 4 temuan
  prioritas sebelum merge. (1) `regulation_card.dart` — poin **PPN** dan **PPh
  Badan** dicabut dari kartu: tarif PPN sedang bergerak (UU HPP 7/2021 → PMK
  131/2024, konstruksi DPP nilai lain) dan PPh Badan 22% salah sasaran untuk
  UMKM yang dominan WP orang pribadi (yang berlaku tarif Pasal 17 OP). Keduanya
  menunggu angka tertulis dari Pakar Regulasi — sejalan dengan temuan T-3.
  (2) Kata "**tetap**" pada judul PPh Final dibuang, dan body-nya menyebut ada
  syarat jangka waktu serta ambang omzet tidak kena pajak yang belum dirinci;
  `maxLines` body dinaikkan 2 → 3 supaya syaratnya tidak terpotong ellipsis.
  Subtitle jadi "Ringkasan sementara, belum ditinjau pakar pajak". (3) Angka
  kartu **benar-benar** dirangkai dari `AppConstants.pphFinalRate` dan
  `pkpThreshold` lewat helper baru `Pct.id()` dan `Rupiah.miliar()` di
  `core/utils/formatters.dart` — jadi kartu dan Simulator tidak bisa lagi
  menampilkan tarif yang berbeda. Warna chip sekalian dipindah ke getter tema
  (`AppColors.expenseLight/expenseBadgeFg`, `warningLight/warningBadgeFg`)
  karena baris yang sama memang sedang ditulis ulang — sebelumnya literal mode
  terang yang tidak ikut mode Gelap. (4) Dokumentasi mati dibersihkan sesuai
  syarat **M1**: blok "Pustaka peraturan" (±40 baris, 3 endpoint) dan catatan
  "Bookmark peraturan" di `docs/BACKEND.md`, baris fitur di `README.md` +
  tagline-nya, baris fitur & daftar folder `screens/` di
  `docs/ARCHITECTURE.md`, opsi area di `.github/ISSUE_TEMPLATE/feature_request.yml`,
  dan cakupan commit `library` di `CONTRIBUTING.md`. Karena kontraknya sudah
  tidak ada di `BACKEND.md`, `ApiEndpoints.documents*` ikut dicabut dari
  `app_constants.dart` (sebelumnya sengaja ditinggal sebagai kontrak backend).
  **Belum dikerjakan, menyusul:** `StorageKeys.bookmarks` masih ada — mencabutnya
  perlu keputusan migrasi karena build yang sudah tayang menulis id dokumen ke
  `localStorage` pengguna; redirect `/library*` → dashboard + `errorBuilder`
  router; parameter `compact` dan efek hover mati di `_RegItem`. Ketiganya
  masuk daftar temuan audit di atas.

- **2026-09-08** — Frontend — Audit kode `app/lib` (53 file, ±14.546 baris) di
  atas branch `claude/flutter-project-review-plan-pzmo22`; hasilnya jadi bagian
  baru **"Temuan audit kode — usulan perbaikan"** (T-1 s/d T-12) di dokumen ini.
  Tidak ada kode aplikasi yang diubah — bagian ini murni tambahan dokumentasi.
  Basis pemeriksaan: `flutter pub get` bersih, `flutter analyze` → **0 error,
  0 warning, 103 info** (66 `withOpacity` deprecated, 21 `unnecessary_underscores`,
  7 `curly_braces_in_flow_control_structures`, sisanya tersebar). Penghapusan
  Pustaka peraturan terverifikasi bersih — nol referensi menggantung ke
  `library_screen.dart`, `doc_detail_screen.dart`, `bookmark_screen.dart`, atau
  `document_model.dart`.
  **Tiga temuan berprioritas 🔴** yang menyentuh benar-tidaknya angka pajak:
  (T-1) `calculatePPh21()` selalu memakai `terTableA` apa pun status PTKP-nya,
  dan `terTableB`/`terTableC` tidak ada di `app_constants.dart` — jadi status
  seperti K/2 dan K/3 dihitung dengan tarif kategori A. Ini mengonfirmasi tugas
  Minggu 1 pakar pajak yang masih terbuka sebagai bug nyata, bukan sekadar hal
  yang perlu dicek. (T-2) `simulator_service.dart` nol tes — 5 tes yang ada
  semuanya menguji `MockDashboardRepository`, sementara kode kalkulasi pajaknya
  sendiri tidak diuji sama sekali; ini menggantung di depan milestone M4.
  (T-3) `calculatePPhFinal()` belum memodelkan pengecualian omzet Rp500 juta
  pertama untuk WP OP maupun batas jangka waktu PP 23/2018.
  T-1, T-3, dan T-4 **butuh keputusan pakar pajak dulu** sebelum frontend boleh
  menyentuhnya — jangan diimplementasi dari sumber sekunder. Sisanya (T-5 s/d
  T-12) murni frontend dan bisa jalan sekarang: null-assertion rawan crash di
  pemetaan PTKP, dua `BuildContext` lewat async gap, aksesibilitas nol,
  `dart format` tidak ditegakkan CI, dan pembersihan `withOpacity`.
  Usul penjadwalan tiap temuan ada di kolom "Usul masuk" pada tabel ringkasnya —
  perlu dikonfirmasi saat sinkron mingguan, belum disepakati siapa pun.

- **2026-09-07** — Frontend — Selesai 4 tugas frontend Minggu 2 (cabut Pustaka
  peraturan) di `app/lib/` pada branch `fitur/audit-original-flutter-vs-app-lib`:
  (1) hapus `library_screen.dart`, `doc_detail_screen.dart`,
  `bookmark_screen.dart`, `lib_widgets.dart`, `related_docs.dart`,
  `library_service.dart`, `document_model.dart` beserta folder
  `screens/library/` dan `widgets/library/`. (2) Cabut rute `/library`,
  `/library/bookmarks`, `/library/:id` dari `app_router.dart`; cabut
  `AppRoutes.library`/`libDetail` dari `app_constants.dart` (entri
  `ApiEndpoints.documents*` dibiarkan — itu bagian kontrak backend di
  `docs/BACKEND.md`, belum dicabut). (3) Hapus tab & item bottom-nav
  "Perpustakaan" dari `MainShell`, sesuaikan indeks `_tabs`/`_screens`.
  (4) `regulation_card.dart` ditulis ulang jadi kartu statis "Info Pajak
  UMKM" berisi 4 poin inline (PPh Final 0,5%, ambang PKP, PPN 11%, PPh Badan
  22% — ~~dari `AppConstants`~~ **koreksi 8 Sep: angkanya ditulis ulang sebagai
  literal string, berkas ini tidak meng-import `app_constants.dart`; sudah
  dibetulkan, lihat entri 8 Sep di bawah**, bukan input pakar pajak yang belum
  ada);
  `QuickActions` di `deadline_card.dart` kehilangan tombol "Cari Regulasi"
  dan parameter `onLibrary`; 3 titik pemanggilan di `dashboard_screen.dart`
  disesuaikan. `tax_tips_card.dart` tidak disentuh (memang tidak terkopel,
  lihat log Minggu 1). Uji manual: `flutter run -d web-server`, login demo,
  jalan penuh splash → dashboard → pembukuan → simulator → pengaturan →
  notifikasi — nol referensi `/library`, nol network request ke `library`,
  bottom nav cuma 4 tab. Satu `GoException` di console saat boot (sebelum
  login) tidak terkait — tidak menyebut "library", tidak berulang, seluruh
  alur tetap jalan.
  **Efek samping tak terduga:** menghapus `document_model.dart` mematahkan
  build `core/data/` (backend), karena `LibraryRepository` dan 3
  implementasinya (`mock_repositories.dart`, `api_repositories.dart`,
  `hybrid_repositories.dart`) serta `MockData.documents`/`docCategories`
  masih memakai tipe `Document`/`DocCategory`/`DocType`. Supaya branch ini
  tetap bisa di-build, tugas Backend Minggu 2 "cabut method terkait dokumen
  dari `repositories.dart` dan ketiga implementasinya" ikut dikerjakan di
  sini (dicentang di atas). `docs/BACKEND.md` **belum** disentuh — itu masih
  perlu di-cross-check oleh Backend. Test `MockLibraryRepository` di
  `test/widget_test.dart` juga dihapus (target ujinya sudah tidak ada).
  `flutter analyze` → 0 error/warning, `flutter test` → 5/5 lulus.
  ~~Belum di-push~~ — sudah di-push sebagai commit `151df2e` di PR #2
  (branch `claude/flutter-project-review-plan-pzmo22`).

- **2026-09-07** — Frontend — Selesai 4 tugas audit Minggu 1: (1) peta rute
  `/library/*` — `library` → `LibraryScreen` (tab nav), `library/bookmarks` →
  `BookmarkScreen`, `library/:id` → `DocDetailScreen`; `app_router.dart`
  identik byte-per-byte antara kode original user dan `app/lib/`, jadi peta
  ini berlaku untuk keduanya. (2) Widget dashboard yang perlu diganti
  kontennya: `regulation_card.dart` (kopling keras — impor `LibraryService`,
  panggil `getDocuments()`, push ke `/library/:id`) dan `QuickActions` di
  `deadline_card.dart` (callback `onLibrary`); `notification_screen.dart`
  hanya kopling lunak (kategori `NotifType.regulation` berisi notifikasi
  contoh, bukan panggilan service). `tax_tips_card.dart` dan
  `cal_deadline_card.dart` ternyata **tidak** terkopel ke Pustaka
  peraturan — daftar di dokumen ini bisa diabaikan untuk keduanya.
  (3) Diff kode Flutter original user vs `app/lib/`: layar & widget nyaris
  identik (cuma beda `dart format`), tapi lapisan data/servis beda total —
  `app/lib/core/data/` (`repositories.dart` + 3 implementasi mock/api/hybrid)
  dan model yang dipecah per file (`models/*_model.dart`) belum ada sama
  sekali di kode original user; semua service (`accounting_service.dart`,
  `library_service.dart`, dll.) karena itu berbeda besar. Rekomendasi:
  lanjutkan kerja dari `app/lib/` (sudah backend-ready), bukan dari kode
  original user. (4) Branch kerja `fitur/audit-original-flutter-vs-app-lib`
  dibuat; `flutter pub get` bersih, `flutter analyze` di `app/` → 0
  error/warning (120 info pre-existing soal `withOpacity` deprecated, tidak
  terkait audit ini).

---

## Halaman terkait

- [Linimasa proyek](linimasa.md) — jadwal Minggu 1–9 dan milestone.
- [Backlog teknis](backlog-teknis.md) — temuan audit T-1..T-15.
