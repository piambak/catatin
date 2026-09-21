---
title: Supabase
description: "Backend Catatin di Supabase: proyek produksi dan staging, menyiapkan dari nol, skema & RLS, pemetaan kontrak, pengaturan Auth, kunci yang boleh di-commit, data contoh staging, dan CI database."
tags:
  - arsitektur
  - backend
  - supabase
---

Backend Catatin untuk pengembangan lokal, staging, dan situs publik. Halaman ini
menjelaskan cara menyiapkannya dari nol, isi skemanya, bagaimana kontrak
`repositories.dart` dipetakan ke Supabase, nilai mana yang boleh masuk repo,
serta staging dan CI database-nya.

Mode sumber data lain dan kontrak REST ada di [Backend & API](backend-dan-api.md).

---

## 1. Gambaran

```text
screens/ → core/services/ → core/data/repositories.dart
                               └─ supabase_repositories.dart
                                    ├─ Supabase Auth       akun & sesi
                                    ├─ PostgREST           tabel, dijaga RLS
                                    └─ rpc monthly_totals  agregasi bulanan
```

Tidak ada server buatan sendiri. Klien bicara langsung ke Postgres lewat
PostgREST, jadi **yang menjaga data adalah Row Level Security (RLS) di
database**, bukan kode aplikasi. Setiap kunci API dipetakan ke peran Postgres —
`anon` sebelum masuk, `authenticated` sesudahnya — dan kebijakan RLS ditulis
untuk peran itu ([sumber](../sumber/supabase-api-keys.md)).

| Berkas | Isi |
| --- | --- |
| `app/lib/core/network/supabase_client.dart` | Inisialisasi klien, penerjemah galat → `ApiException`, pendengar sesi berakhir |
| `app/lib/core/data/supabase_repositories.dart` | Empat repository + helper murni yang dites |
| `supabase/migrations/` | Skema, RLS, data kategori, fungsi agregasi |
| `app/dart_define.pages.json` | URL proyek + publishable key untuk situs publik dan uji lokal |
| `app/test/supabase_mapping_test.dart` | Tes pemetaan galat, agregasi bulanan, tenggat, dan helper login Google |
| `app/lib/widgets/auth/google_sign_in_button.dart` | Tombol masuk/daftar dengan Google |
| `app/lib/screens/settings/password_dialog.dart` | Pasang/ganti kata sandi dari Pengaturan → Cara masuk |
| `app/dart_define.staging.json` | URL + publishable key proyek staging, daftar email menyala ([§8](#8-staging-dan-data-contoh)) |
| `supabase/config.toml` | Konfigurasi stack lokal dan CI, dari template `supabase init` CLI 2.117.0 |
| `supabase/tests/database/` | Tes pgTAP skema, hak akses, dan isolasi RLS ([§9](#9-ci-database)) |
| `supabase/staging/` | Skrip data contoh staging beserta tesnya ([§8](#8-staging-dan-data-contoh)) |
| `.github/workflows/supabase.yml` | CI database: build migrasi, lint, tes ([§9](#9-ci-database)) |

Mode ini aktif lewat `DATA_SOURCE=supabase` (atau otomatis kalau
`SUPABASE_URL` terisi). Selama URL atau publishable key kosong, aplikasi jalan
dengan data contoh — jadi berkas Pages yang belum diisi tidak merusak situs.

**Proyek remote.** Keduanya di organisasi `catatin`, paket Free:

| | Produksi | Staging |
| --- | --- | --- |
| Nama / ref | `catatin` / `mhoadvaiarjbbzlltqxy` | `catatin-staging` / `herafvadqziftszhxqeq` |
| Dipakai | Situs publik | Uji FE/BE sebelum produksi ([§8](#8-staging-dan-data-contoh)) |
| Dibuat | 13 Sep 2026 | 15 Sep 2026 |
| Region | `ap-southeast-1` (Singapore), Postgres 17 | `ap-southeast-1` (Singapore), Postgres 17 |
| Project URL | `https://mhoadvaiarjbbzlltqxy.supabase.co` | `https://herafvadqziftszhxqeq.supabase.co` |
| Berkas define | `app/dart_define.pages.json` | `app/dart_define.staging.json` |
| Login | Google (daftar email disembunyikan) | Daftar dan masuk dengan email |
| Migrasi terpasang | `20260913101045_catatin_skema_awal`, `20260913135347_fungsi_has_password` | Sama persis |

Proyek paket Free dijeda setelah seminggu tidak aktif — berlaku untuk keduanya,
lihat T-19 di [backlog teknis](../proyek/backlog-teknis.md).

## 2. Menyiapkan dari nol

Sekali per proyek. Butuh Node.js (untuk `npx`) dan akun Supabase.

1. **Buat proyek** di dashboard Supabase. Simpan password database di password
   manager — tidak pernah di repo.
2. **Hubungkan CLI** dari root repo. `supabase/config.toml` sudah di-commit, jadi
   `init` tidak perlu dijalankan lagi. `link` meminta password database:

   ```bash
   npx supabase login
   npx supabase link --project-ref <ref>
   ```

3. **Terapkan skema**, periksa dulu apa yang akan dijalankan:

   ```bash
   npx supabase db push --dry-run
   npx supabase db push
   ```

4. **Buka Security Advisor** di dashboard dan pastikan tidak ada temuan RLS.
   Advisor itu memeriksa masalah umum pada peran bawaan Postgres
   ([sumber](../sumber/supabase-api-keys.md)).
5. **Atur Auth** — lihat [bagian 5](#5-pengaturan-auth).
6. **Isi `app/dart_define.pages.json`** dengan Project URL dan publishable key
   dari *Settings → API Keys*, lalu jalankan:

   ```bash
   cd app
   flutter run -d chrome --dart-define-from-file=dart_define.pages.json
   ```

7. Setelah alur daftar → onboarding → catat transaksi lulus di lokal, commit
   berkas itu lewat PR. Situs publik ikut tersambung saat PR digabung ke `main`
   ([Rilis & deploy](../panduan/rilis-dan-deploy.md)).

**Cara proyek yang tayang disiapkan.** Proyek `catatin` tidak dibuat lewat
langkah di atas, melainkan lewat konektor Supabase (MCP) di Claude: proyek
dibuat dengan password database acak dari Supabase, lalu migrasi diterapkan
dengan `apply_migration`. Dua akibatnya:

- **Versi migrasi mengikuti waktu penerapan**, bukan nama berkas lokal. Berkas
  lokal karena itu diganti nama jadi `20260913101045_catatin_skema_awal.sql`
  supaya `supabase db push` kelak tidak mencoba menjalankannya ulang. Kalau
  migrasi berikutnya juga diterapkan lewat konektor, samakan lagi nama
  berkasnya dengan versi di *Database → Migrations*.
- **`supabase/config.toml` baru ada sejak 15 Sep 2026.** Berkas itu diturunkan
  dari template `supabase init` CLI 2.117.0 — versi yang di-pin CI (§9) —
  dengan setelan Auth lokal disamakan dengan keputusan §5. Isinya hanya untuk
  stack lokal dan CI; setelan proyek remote tetap diatur di dashboard, jadi
  jangan pernah menjalankan `supabase config push`. Password database acak itu
  tidak pernah ditampilkan; kalau `link` memintanya, buat password baru dari
  dashboard (TODO: needs source untuk letak menunya).
- **Staging disiapkan dengan cara yang sama** (15 Sep 2026), termasuk
  penyamaan versi migrasi — lihat [§8](#8-staging-dan-data-contoh).

## 3. Skema

Semuanya ada di `supabase/migrations/`. Nama kolom sengaja sama dengan kunci
JSON di `app/lib/models/`, jadi `fromJson` membaca baris PostgREST tanpa
pemetaan tambahan.

| Tabel | Isi | Hak pengguna yang masuk |
| --- | --- | --- |
| `tx_categories` | 15 kategori bersama, id sama dengan data contoh (`ic1`…`ecx`) | Baca saja |
| `business_profiles` | Satu profil usaha per akun (`unique (user_id)`) | Baca & tulis barisnya sendiri |
| `transactions` | Transaksi; `business_id` wajib milik akun yang sama | Baca & tulis barisnya sendiri |

- **Fungsi `monthly_totals(p_year)`** mengembalikan 12 baris — pemasukan,
  pengeluaran, HPP, dan jumlah transaksi per bulan milik pemanggil. Berjalan
  dengan hak pemanggil (`security invoker`), jadi RLS tetap berlaku. Kolom HPP
  disiapkan untuk Simulator yang menarik data pembukuan asli.
- **Peran `anon` tidak mendapat hak apa pun.** Hak tabel diberikan eksplisit
  dengan `GRANT` karena Postgres memeriksa hak tabel lebih dulu, baru RLS:
  hak yang hilang menghasilkan galat izin, sedangkan kebijakan yang tidak cocok
  hanya mengembalikan hasil kosong ([sumber](../sumber/supabase-api-keys.md)).
  Karena itu penolakan RLS diterjemahkan jadi 403 (atau 401 kalau sesi sudah
  habis), dan hapus/ubah yang tidak menyentuh baris apa pun jadi 404.
- **Kategori diisi di migrasi**, bukan `supabase/seed.sql`, supaya ikut
  `db push` ke proyek remote.
- **Validasi transaksi ada di database** (#40), jadi berlaku untuk klien apa
  pun, bukan hanya form aplikasi:

  | Aturan | Constraint | Kode |
  | --- | --- | --- |
  | Nominal lebih dari 0 | `transactions_amount_check` | `23514` |
  | Tanggal 1 Jan 2000 s.d. 31 Des 2099 | `transactions_date_range_check` | `23514` |
  | Tanggal kalender yang ada (bukan 30 Februari) | tipe `date` | `22008` |
  | Kategori ada | `transactions_category_id_fkey` | `23503` |
  | Kategori sejenis dengan transaksi (`INCOME`/`EXPENSE`) | `transactions_category_type_fkey` — FK komposit ke `tx_categories (id, type)` | `23503` |
  | `type` dan `payment_method` dari daftar tetap | `transactions_type_check`, `transactions_payment_method_check` | `23514` |

  Batas tanggal sengaja konstanta, bukan `current_date`, supaya constraint-nya
  immutable. Kategori yang tidak ada sama sekali tetap dilaporkan lewat FK
  lama, jadi "tidak ditemukan" dan "salah jenis" bisa dibedakan.
  `supabaseException()` di `supabase_client.dart` membaca nama constraint dari
  pesan galat dan mengubahnya jadi 400 dengan pesan per field di
  `ApiException.errors` — mis. "Kategori tidak cocok dengan jenis transaksi."
  — alih-alih "Data tidak valid." umum. Nama constraint karena itu bagian dari
  kontrak: mengganti namanya berarti mengganti peta di klien dan tesnya.
- **Transaksi berulang** (#58, kontrak di
  [Backend & API](backend-dan-api.md#transaksi-berulang)) — tabel
  `recurring_templates`, dibaca dan ditulis pemiliknya lewat RLS (tanpa hapus;
  berhenti = `is_active` jadi `false`). `next_date` dan `is_active` selalu
  dihitung trigger, bukan klien: jadwal dihitung dari jangkar `start_date`
  (`recurring_first_on_or_after`), tanpa pengisian mundur, dan template yang
  sudah berhenti membeku. Penerbitnya `issue_recurring_transactions()` — tidak
  bisa dipanggil pengguna — dijalankan **pg_cron** tiap hari pukul 17.05 UTC
  (00.05 WIB, job `catatin-transaksi-berulang`) dan langsung saat template
  dibuat atau diubah, untuk kemunculan yang jatuh hari itu. Transaksi terbitan
  membawa `recurring_template_id`; indeks unik `(recurring_template_id, date)`
  membuat penerbitan ulang tidak pernah ganda, dan trigger menolak klien
  mengisi kolom itu sendiri. Pembeda "penerbit" dari "pengguna" adalah
  `current_user`: permintaan PostgREST berjalan sebagai `authenticated`,
  penerbit sebagai pemilik fungsinya (`postgres`). Proyek Free yang dijeda
  (T-19) tidak menjalankan pg_cron; kemunculan yang tertinggal diterbitkan pada
  penerbitan pertama setelah proyek dipulihkan.
- **Lampiran struk** (#59, kontrak di
  [Backend & API](backend-dan-api.md#lampiran-struk)) — berkasnya di bucket
  Storage privat `receipts` (5 MB, JPEG/PNG/WebP), metadatanya di tabel
  `transaction_attachments`. Lokasi berkas wajib
  `<user_id>/<transaction_id>/<id>.<jpg|png|webp>` — dijaga constraint
  `transaction_attachments_path_check` di tabel dan kebijakan `catatin: …` di
  `storage.objects`, sehingga pengguna hanya bisa mengunggah ke foldernya
  sendiri, untuk transaksinya sendiri, dan hanya bisa membaca atau menghapus
  berkas di foldernya. Klien membuka berkas lewat signed URL 1 jam.
  Menghapus transaksi ikut menghapus baris lampirannya (cascade), tapi
  **berkasnya harus dihapus lewat Storage API**: Supabase menolak penghapusan
  langsung dari `storage.objects` lewat SQL
  ([sumber](../sumber/staging-storage-uji.md)). Karena itu
  `deleteTransaction` di klien menghapus berkas lampirannya lebih dulu; kalau
  langkah itu gagal, transaksi tetap terhapus dan berkasnya tertinggal sebagai
  yatim. Batas ukuran dan tipe dipasang di bucket hanya bila kolomnya ada —
  stack lokal CI memakai skema Storage minimal tanpa kolom itu.
- **Fungsi `has_password()`** menjawab apakah akun pemanggil punya kata sandi.
  Satu-satunya fungsi `security definer` di skema ini, karena `authenticated`
  tidak boleh membaca `auth.users`: tanpa parameter, hanya membaca baris
  `auth.uid()`, hanya mengembalikan boolean, dan tidak bisa dipanggil `anon`.
  Security Advisor karena itu sengaja dibiarkan melaporkan lint
  `authenticated_security_definer_function_executable` untuk fungsi ini.

Mengubah skema: `npx supabase migration new <nama>`, tulis SQL-nya, lalu
`db push`. Migrasi yang sudah di-push jangan disunting — buat migrasi baru.

Semua sifat di atas — RLS menyala, kebijakan persis, `anon` tanpa hak,
`has_password()` satu-satunya security definer, isolasi data antar-akun, dan
validasi transaksi — dites otomatis setiap kali `supabase/` berubah ([§9](#9-ci-database)). Kalau
migrasi baru sengaja mengubahnya, perbarui tesnya bersama bagian ini.

## 4. Pemetaan kontrak

| Method kontrak | Di Supabase |
| --- | --- |
| `AuthRepository.register` | `auth.signUp`, nama disimpan di user metadata. Sesi `null` (konfirmasi email menyala) → 409 "Akun dibuat. Buka tautan konfirmasi…" |
| `AuthRepository.login` / `me` / `logout` | `signInWithPassword` / `currentUser` / `signOut` |
| `AuthRepository.signInWithGoogle` | `signInWithOAuth(google)` — web: halaman yang sama pindah ke Google lalu kembali dengan `?code=` (PKCE); Android: browser eksternal kembali lewat deep link `com.catatin.catatin://login-callback` |
| `AuthRepository.currentSession` | `currentSession` — dipakai `AuthService` untuk mengadopsi sesi hasil login Google |
| `AuthRepository.signInProviders` | provider dari `currentUser.identities`, ditambah `email` bila `rpc('has_password')` bernilai `true` |
| `AuthRepository.setPassword` | `updateUser(password:, currentPassword:)` |
| `BusinessRepository.getCurrent` | select `business_profiles` (paling banyak satu baris) |
| `BusinessRepository.create` / `update` | upsert pada `user_id` / update per id |
| `TransactionRepository.getCategories` | select `tx_categories` urut `sort_order` |
| `TransactionRepository.getTransactions` | select + `category:tx_categories(*)`, diambil per halaman 1000 baris. Filter `month`/`year` atau `from`/`to` diubah `dateRangeFor` menjadi `date >= from` dan `date < until`; ujung yang kosong tidak difilter |
| `TransactionRepository.getAggregate` | `rpc('monthly_totals')` → `YearAggregate`; kolom `hpp` menjadi `cogs`, omzet YTD dijumlahkan `monthAggregates()` |
| `TransactionRepository.getTransaction` | per id; id non-UUID (sisa data contoh) → `null` |
| `TransactionRepository.createTransaction` | insert; `business_id` diambil dari server, bukan dari perangkat |
| `TransactionRepository.updateTransaction` / `deleteTransaction` | per id; tidak ada baris tersentuh → 404 |
| `DashboardRepository.getSummary` / `getKpiHistory` | `rpc('monthly_totals')` |
| `DashboardRepository.getRecentTransactions` | select + kategori, `limit` |
| `DashboardRepository.getDeadlines` | `generateCalendar()` di aplikasi, memakai status PKP dan jumlah karyawan profil usaha |

Tenggat pajak sengaja **tidak** dihitung di SQL: aturan kalendernya sudah ada
di `simulator_service.dart`, dan dua salinan aturan pasti menyimpang — pelajaran
T-13 di [backlog teknis](../proyek/backlog-teknis.md).

`getTransactions` menganggap halaman yang berisi kurang dari 1000 baris adalah
halaman terakhir. Pengaturan *Max rows* API proyek karena itu tidak boleh
diturunkan di bawah 1000, atau daftar transaksi terpotong diam-diam.

## 5. Pengaturan Auth

Diatur di dashboard, *Authentication*:

- **URL Configuration** — Site URL `https://piambak.github.io/catatin/`;
  tambahkan `http://localhost:*` di Redirect URLs.
- **Confirm email** — keputusan yang harus diambil sadar:

| Pilihan | Akibat |
| --- | --- |
| SMTP bawaan + Confirm email **menyala** | Pendaftaran di situs publik macet: SMTP bawaan hanya mengirim ke alamat anggota tim organisasi, maksimal 2 pesan per jam, dan tidak dimaksudkan untuk produksi ([sumber](../sumber/supabase-auth-smtp.md)) |
| Confirm email **dimatikan** | Pendaftaran langsung aktif. Siapa pun bisa mendaftar memakai email orang lain; dokumen Supabase menyebut mematikan konfirmasi email sebagai celah yang dicari penyerang dan menyarankan tidak mematikannya ([sumber](../sumber/supabase-auth-smtp.md)). Cukup untuk pengembangan dan uji terbatas — **tapi tidak bersama login Google**, lihat keputusan di bawah |
| Custom SMTP + Confirm email **menyala** | Disarankan untuk situs publik. Aplikasi sudah menangani alurnya: setelah daftar, pengguna diminta membuka tautan di email lalu masuk |

**Keputusan untuk proyek yang tayang (13 Sep 2026, direvisi hari yang sama):
Confirm email tetap MENYALA, dan pendaftaran lewat Google.**

Keputusan awal mematikan Confirm email dibatalkan sebelum sempat diterapkan.
Supabase menggabungkan identitas dengan email yang sama ke satu akun, dan hanya
melewati identitas yang emailnya belum terverifikasi
([sumber](../sumber/supabase-identity-linking.md)). Di kode Supabase Auth,
saat Confirm email mati (`Mailer.Autoconfirm`) pendaftaran email langsung
dikonfirmasi dan alamatnya dihitung terverifikasi
([sumber](../sumber/supabase-identity-linking.md)). Akibatnya: orang lain bisa
mendaftar lebih dulu dengan Gmail korban dan sandi buatannya, lalu saat korban
masuk dengan Google, keduanya jadi satu akun yang sandinya dipegang penyerang.
Untuk aplikasi berisi data keuangan usaha, risiko itu tidak diterima.

Akibatnya di aplikasi: form **daftar** dengan email disembunyikan di mode
Supabase (`AppConfig.emailSignUpEnabled`, bisa dipaksa lewat define
`EMAIL_SIGNUP=true|false`), karena SMTP bawaan tidak akan mengirim tautan
konfirmasinya. Form **masuk** dengan email tetap ada. Sisa pekerjaannya —
custom SMTP lalu `EMAIL_SIGNUP=true` — dicatat di T-18
[backlog teknis](../proyek/backlog-teknis.md).

### Masuk dengan Google

Sekali per proyek, oleh pemilik akun — Client Secret tidak pernah lewat repo
maupun asisten AI.

1. **Google Cloud → Google Auth Platform:** buat project, isi Branding,
   Audience *External*, lalu **Publish app** (selama *Testing*, hanya test user
   yang bisa masuk).
2. **Clients → Create client → Web application**
   ([sumber](../sumber/supabase-auth-google.md)):
   - Authorized JavaScript origins: `https://piambak.github.io`
   - Authorized redirect URIs: `https://mhoadvaiarjbbzlltqxy.supabase.co/auth/v1/callback`
3. **Supabase → Authentication → Sign In / Providers → Google:** nyalakan,
   tempel Client ID dan Client Secret.
4. **Supabase → Authentication → URL Configuration → Redirect URLs:**
   `https://piambak.github.io/catatin/**`, `http://localhost:*/**`, dan
   `com.catatin.catatin://login-callback`. Alamat kembali yang tidak terdaftar
   membuat Supabase mengirim pengguna ke Site URL.

Android tidak butuh OAuth client tersendiri: login berjalan di browser terhadap
client Web di atas, lalu kembali lewat deep link.

Layar izin Google menampilkan `mhoadvaiarjbbzlltqxy.supabase.co`, bukan nama
situs. Dokumen Supabase menyebut ini mengurangi kepercayaan dan menyarankan
custom domain ([sumber](../sumber/supabase-auth-google.md)).

Cek cepat tanpa akun: `GET /auth/v1/settings` → `external.google: true`, dan
`GET /auth/v1/authorize?provider=google&redirect_to=…` → 302 ke
`accounts.google.com`.

Cek cepat tanpa dashboard: `GET /auth/v1/settings` dengan publishable key
mengembalikan `mailer_autoconfirm: true` saat Confirm email mati.

### Satu akun, dua cara masuk

Akun yang daftar lewat Google bisa memasang kata sandi di **Pengaturan → Cara
masuk**, lalu masuk ke akun yang sama dengan email Google itu + kata sandi.
Tidak ada akun kedua dan tidak ada email konfirmasi.

- Kata sandi pertama dipasang lewat `updateUser` tanpa kata sandi lama. Login
  kata sandi hanya mensyaratkan akun punya kata sandi dan emailnya
  terkonfirmasi — akun Google sudah terkonfirmasi
  ([sumber](../sumber/supabase-auth-update-password.md)). Terbukti di situs
  publik 13 Sep 2026: pasang kata sandi → keluar → masuk dengan email + kata
  sandi, tetap satu akun.
- **Identitas `email` tidak ikut dibuat.** Supabase Auth hanya membuatnya bila
  flag eksperimental `CreateEmailIdentityOnPasswordSetEnabled` menyala
  ([sumber](../sumber/supabase-auth-update-password.md)), dan di proyek ini
  tidak — akun tetap hanya punya identitas `google`. Karena itu status "Aktif"
  di Pengaturan dibaca dari fungsi `has_password()`, bukan dari identitas.
- Kalau *Secure password change* dinyalakan di dashboard, sesi yang dibuat
  lebih dari 24 jam lalu ditolak dengan `reauthentication_needed`
  ([sumber](../sumber/supabase-auth-update-password.md)). Verifikasi ulangnya
  lewat email, yang belum bisa terkirim — aplikasi karena itu meminta pengguna
  keluar lalu masuk lagi dengan Google.
- Mengganti kata sandi yang sudah ada meminta kata sandi saat ini; server hanya
  memeriksanya bila opsi kata sandi saat ini diwajibkan
  ([sumber](../sumber/supabase-auth-update-password.md)).
- "Lupa kata sandi?" di layar masuk mengarahkan ke jalur ini: masuk dengan
  Google, lalu ganti kata sandi di Pengaturan. Pemulihan lewat email masih
  menunggu custom SMTP (T-18).

## 6. Kunci dan rahasia

| Nilai | Boleh di repo? |
| --- | --- |
| Project URL | Ya |
| Publishable key `sb_publishable_…` | Ya — di `app/dart_define.pages.json` |
| Secret key `sb_secret_…` atau `service_role` lama | **Tidak pernah** |
| Password database | **Tidak pernah** |
| Google OAuth Client Secret (dan berkas unduhan `client_secret_*.json`) | **Tidak pernah** — hanya di dashboard Supabase; pola berkasnya diabaikan `.gitignore` |

Publishable key memang dirancang untuk komponen publik — dokumentasi Supabase
menyebutnya aman di halaman web, aplikasi, GitHub Actions, dan kode sumber —
dan hanya menjangkau apa yang diizinkan RLS. Secret key melewati seluruh RLS dan
harus dijauhkan dari kontrol versi, termasuk skrip CI
([sumber](../sumber/supabase-api-keys.md)).

Dokumen yang sama menganjurkan membaca kunci dari `.env` sebagai kebiasaan.
Repo ini tetap meng-commit publishable key karena build situs publik membaca
berkas yang di-commit, bukan repo Variables, dan nilainya toh ikut ter-compile
ke `main.dart.js` yang bisa diunduh siapa saja.

Kalau publishable key disalahgunakan, buat kunci baru di *Settings → API Keys*,
ganti isi berkas Pages, lalu nonaktifkan yang lama.

## 7. Sesi, demo, dan galat

- **Sesi** dikelola klien Supabase dan diperbarui otomatis. Token di secure
  storage hanya salinan penanda "sudah masuk" untuk penjaga rute (komentar di
  `storage_service.dart`).
- **Keluar** memanggil `signOut`, yang mencabut sesi di server
  (`POST /auth/v1/logout?scope=local`) — terbukti di log proyek 13 Sep 2026 —
  lalu `AuthService` membersihkan penyimpanan lokal.
- **Sesi berakhir dari sisi server** (refresh token dicabut atau kedaluwarsa)
  memicu `signedOut`; `AuthService` membersihkan penyimpanan lokal dan router
  langsung pindah ke layar masuk lewat `refreshListenable`.
- **Saat aplikasi dibuka**, penanda "sudah masuk" tanpa sesi Supabase dianggap
  sisa sesi lama dan dibersihkan beserta `onboarded` dan `business_id`-nya.
- **Kembali dari Google.** Di web, `SupabaseBackend.init` menyalakan
  `detectSessionInUri`, jadi `Supabase.initialize` menukar `?code=` jadi sesi
  sebelum frame pertama; `AuthService.restoreSession` lalu menyalin sesi itu ke
  penyimpanan lokal dan menyelaraskan onboarding. Di Android sesi tiba lewat
  event `signedIn` saat aplikasi berjalan dan diadopsi dengan cara yang sama.
  Penanda milik akun lain di perangkat itu dibuang dulu.
- **Login Google gagal atau dibatalkan** tampil sebagai banner di layar masuk,
  lalu parameter `?error=` dihapus dari alamat (Supabase hanya membersihkannya
  saat login berhasil). Stream Auth memutar ulang event lama ke pendengar baru,
  jadi galat callback web dibaca dari alamat, bukan dari stream.
- **Mode demo** selalu memakai data contoh dan tidak mengirim satu pun request
  ke Supabase — tombol demo tetap berfungsi di situs publik.
- **Onboarding** diselaraskan setelah masuk: akun yang sudah punya profil usaha
  langsung ke dashboard, di perangkat mana pun.
- **Galat** Supabase diterjemahkan jadi `ApiException` berbahasa Indonesia di
  `supabase_client.dart`. Kode yang tidak dikenali tampil sebagai pesan umum;
  di mode debug pesan aslinya dicetak ke konsol — biasanya tanda migrasi belum
  di-push.

## 8. Staging dan data contoh

Proyek `catatin-staging` (§1) adalah salinan skema produksi untuk uji FE/BE.
Ia padanan Supabase untuk "staging environment" di issue #17 dan "contract mock
server ... running on staging" di issue #18
([sumber](../sumber/github-issue-17-20-backend-minggu-1.md)), sesuai poin 5
keputusan D-7 ([sumber](../sumber/github-issue-149-d7-stack-backend.md)).

### Cara disiapkan (15 Sep 2026)

- Dibuat lewat konektor Supabase (MCP) di organisasi `catatin`, paket Free
  dengan biaya proyek $0/bulan, region `ap-southeast-1`, Postgres 17 — sama
  dengan produksi.
- Kedua migrasi diterapkan dengan `apply_migration`, lalu versinya di
  `supabase_migrations.schema_migrations` disamakan dengan nama berkas lokal.
  Riwayat migrasi staging kini identik dengan produksi.
- Sidik jari katalog kedua proyek dibandingkan dan identik: kolom, constraint,
  kebijakan RLS, fungsi beserta hak eksekusinya, hak tabel, indeks, isi 15
  kategori, dan status RLS.
- Security Advisor staging hanya melaporkan lint 0029 untuk `has_password()` —
  sama dengan produksi dan disengaja (§3). REST tanpa sesi ditolak `401`.

### Auth staging

`GET /auth/v1/settings` staging mengembalikan `external.google: false` dan
`mailer_autoconfirm: false`: login Google tidak dinyalakan dan *Confirm email*
menyala. Tanpa identitas Google, celah penggabungan akun di §5 tidak berlaku,
jadi daftar dengan email dibuka lewat `EMAIL_SIGNUP=true` di
`app/dart_define.staging.json`.

Tautan konfirmasinya dikirim SMTP bawaan, yang hanya sampai ke alamat anggota
tim organisasi ([sumber](../sumber/supabase-auth-smtp.md)). **Jangan nyalakan
login Google di staging tanpa mematikan lagi daftar email dan meninjau ulang
§5.** Site URL dan Redirect URLs staging belum diatur; kalau halaman setelah
membuka tautan konfirmasi tidak terbuka, kembali ke aplikasi dan coba masuk.

### Data contoh

`supabase/staging/data_contoh.sql` mengisi satu akun dengan data yang angkanya
persis contoh kontrak di [Backend & API §3](backend-dan-api.md#3-kontrak-api):

| Method kontrak | Hasil untuk akun itu |
| --- | --- |
| `BusinessRepository.getCurrent` | Batik Kencana, pemilik Rizal, `DAGANG`, non-PKP, 3 karyawan |
| `TransactionRepository.getTransactions` | 60 transaksi Januari–September 2026, termasuk transaksi contoh 5 Agustus 2026 |
| `DashboardRepository.getSummary(month: 8, year: 2026)` | Pemasukan 28.500.000, pengeluaran 18.200.000, YTD 285.000.000, 12 transaksi |
| `DashboardRepository.getKpiHistory(KpiMetric.income)` | Januari 19.200.000, Februari 21.500.000, dan seterusnya |
| `TransactionRepository.getAggregate(year: 2026)` | 12 bulan dari data yang sama |
| `DashboardRepository.getDeadlines` | Dihitung aplikasi dari status PKP dan jumlah karyawan |

Skrip itu hanya mendefinisikan fungsi sementara
`pg_temp.isi_data_contoh(p_email, p_timpa)`, yang hilang saat sesi ditutup.
Fungsinya menolak email yang belum terdaftar, dan menolak akun yang sudah punya
profil usaha kecuali dipanggil dengan `p_timpa => true` — yang menghapus profil
beserta seluruh transaksinya lalu mengisi ulang. Kesesuaiannya dengan contoh
kontrak dijaga tes pgTAP (§9), dan sudah dicoba di staging dalam transaksi
yang dibatalkan: 1 profil, 60 transaksi, angka per bulan sesuai, tanpa akun
atau data yang tertinggal.

### Alur uji FE: login → dashboard → transaksi

1. Pemilik organisasi Supabase mengundang akun email FE ke organisasi `catatin`,
   supaya email konfirmasi sampai.
2. FE menjalankan aplikasi dengan berkas staging, mendaftar dengan email, lalu
   membuka tautan konfirmasi:

   ```bash
   cd app
   flutter run -d chrome --dart-define-from-file=dart_define.staging.json
   ```

3. BE membuka SQL Editor proyek staging, menempel seluruh isi
   `supabase/staging/data_contoh.sql`, menambahkan baris berikut di eksekusi
   yang sama, lalu menjalankannya:

   ```sql
   select pg_temp.isi_data_contoh('email-fe@contoh.id');
   ```

4. FE masuk, onboarding terlewati karena profil usaha sudah ada, lalu mencatat,
   mengubah, dan menghapus satu transaksi dan memastikan dashboard ikut berubah.

Staging juga dijeda setelah seminggu tidak aktif (T-19 di
[backlog teknis](../proyek/backlog-teknis.md)). Migrasi baru diterapkan ke
staging lebih dulu, baru ke produksi
([Rilis & deploy](../panduan/rilis-dan-deploy.md)).

## 9. CI database

Workflow `.github/workflows/supabase.yml` berjalan pada setiap push dan PR yang
menyentuh `supabase/**` atau workflow itu sendiri. Ia tidak menyentuh proyek
remote mana pun dan tidak butuh secret: semuanya di Postgres lokal runner.

| Langkah | Perintah | Menangkap |
| --- | --- | --- |
| Build | `supabase db start` | Migrasi yang tidak bisa dijalankan berurutan di database kosong ([sumber](../sumber/supabase-setup-cli-action.md)) |
| Lint | `supabase db lint --level warning --fail-on warning` | Galat fungsi yang baru muncul saat dijalankan, lewat `plpgsql_check`. Tanpa `--fail-on`, perintah ini selalu keluar dengan status 0 ([sumber](../sumber/supabase-testing-pgtap.md)) |
| Tes | `supabase test db` | `supabase/tests/database/*.test.sql` |
| Tes data contoh | `supabase test db supabase/staging/data_contoh.test.sql` | Skrip data contoh menyimpang dari contoh kontrak |

CLI di-pin ke versi 2.117.0 lewat `supabase/setup-cli@v3`
([sumber](../sumber/supabase-setup-cli-action.md)); `supabase/config.toml`
diturunkan dari template versi yang sama.

**Isi tes pgTAP:**

- `01_skema.test.sql` (26 tes) — tabel ada, RLS menyala, kebijakan persis
  sesuai migrasi, `anon` tanpa hak tabel maupun fungsi, hak `authenticated`,
  dan `has_password()` satu-satunya security definer dengan `search_path`
  kosong.
- `02_rls_isolasi.test.sql` (17 tes) — uji isolasi 13 Sep 2026 yang dulu manual
  ([log progres](../proyek/log-progres.md)): B tidak melihat, mengubah, atau
  menghapus data A, dan tidak bisa mencatat ke usaha A maupun menyamar sebagai
  A; A tidak bisa memindahkan transaksi ke usaha B; `monthly_totals` dan
  `has_password()` benar; `anon` ditolak.
- `04_validasi_transaksi.test.sql` (14 tes) — semua aturan validasi di
  [§3](#3-skema), dijalankan sebagai `authenticated`, dengan pesan galat yang
  dicocokkan persis karena nama constraint di dalamnya dibaca klien (#40).
- `05_transaksi_berulang.test.sql` (51 tes) — jadwal (jangkar akhir bulan,
  mingguan), tanpa pengisian mundur, penerbitan kejar-ketinggalan yang tidak
  pernah ganda, `end_date` inklusif, berhenti permanen, tautan
  `recurring_template_id` yang tidak bisa dipalsukan, validasi, dan isolasi
  antar-akun (#58). Tanggal "hari ini" dipatok lewat setelan
  `catatin.hari_ini`.
- `06_lampiran_struk.test.sql` (16 tes) — lokasi berkas terikat ke pemilik
  dan transaksinya, tipe dan ukuran, isolasi antar-akun, cascade saat
  transaksi dihapus, dan kebijakan `storage.objects` (dilewati bila skema
  Storage tidak ada) (#59).
- `supabase/staging/data_contoh.test.sql` (10 tes) — skrip data contoh
  menghasilkan angka contoh kontrak.

Pengguna fiktif dibuat langsung di `auth.users` dan sesi dipasang dengan
`set local role authenticated` plus klaim JWT, di dalam transaksi yang
di-rollback ([sumber](../sumber/supabase-testing-pgtap.md)).

**Kenapa tes data contoh terpisah.** Tanpa argumen, `supabase test db` hanya
me-mount `supabase/tests` ke container `pg_prove`, sehingga `\ir` ke berkas di
luar folder itu gagal — run CI pertama membuktikannya. Kalau diberi path berkas,
CLI me-mount folder induknya, jadi tes bisa meng-include skrip di sebelahnya
([sumber](../sumber/supabase-cli-test-db-mount.md)). Jangan beri path folder
`supabase/staging`: `pg_prove` menjalankan semua berkas `.sql` di sana sebagai
tes, termasuk `data_contoh.sql` ([sumber](../sumber/supabase-cli-test-db-mount.md)).

Run hijau pertama pada 15 Sep 2026: build menjalankan kedua migrasi, lint
"No schema errors found", 43 tes pgTAP dan 10 tes data contoh lulus. Menjalankan
secara lokal butuh Docker dan Supabase CLI:

```bash
npx supabase db start
npx supabase db lint --level warning --fail-on warning
npx supabase test db
npx supabase test db supabase/staging/data_contoh.test.sql
```

## Halaman terkait

- [Backend & API](backend-dan-api.md) — mode sumber data, lingkungan, kontrak REST, dan draf skema mesin tarif (§7).
- [Rilis & deploy](../panduan/rilis-dan-deploy.md) — urutan push skema dan rilis.
- [Kontribusi](../panduan/kontribusi.md) — aturan rahasia di repo.
- [Backlog teknis](../proyek/backlog-teknis.md) — T-11 (sesi di web), T-16, T-17, T-18 (daftar email menunggu SMTP), T-19 (proyek Free dijeda), T-20 (uji login Google di Android).
