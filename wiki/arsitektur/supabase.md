# Supabase

Backend Catatin untuk pengembangan lokal dan situs publik. Halaman ini
menjelaskan cara menyiapkannya dari nol, isi skemanya, bagaimana kontrak
`repositories.dart` dipetakan ke Supabase, dan nilai mana yang boleh masuk
repo.

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
| `app/test/supabase_mapping_test.dart` | Tes pemetaan galat, agregasi bulanan, dan tenggat |

Mode ini aktif lewat `DATA_SOURCE=supabase` (atau otomatis kalau
`SUPABASE_URL` terisi). Selama URL atau publishable key kosong, aplikasi jalan
dengan data contoh — jadi berkas Pages yang belum diisi tidak merusak situs.

**Proyek yang dipakai situs publik** (dibuat 13 Sep 2026):

| | |
| --- | --- |
| Nama / ref | `catatin` / `mhoadvaiarjbbzlltqxy` |
| Organisasi | `catatin`, paket Free |
| Region | `ap-southeast-1` (Singapore), Postgres 17 |
| Project URL | `https://mhoadvaiarjbbzlltqxy.supabase.co` |
| Migrasi terpasang | `20260913101045_catatin_skema_awal` |

Proyek paket Free dijeda setelah seminggu tidak aktif — lihat T-19 di
[backlog teknis](../proyek/backlog-teknis.md).

## 2. Menyiapkan dari nol

Sekali per proyek. Butuh Node.js (untuk `npx`) dan akun Supabase.

1. **Buat proyek** di dashboard Supabase. Simpan password database di password
   manager — tidak pernah di repo.
2. **Hubungkan CLI** dari root repo. `link` meminta password database:

   ```bash
   npx supabase login
   npx supabase init
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
- **`supabase init` belum pernah dijalankan** — `supabase/config.toml` belum
  ada. Jalankan `init` sebelum `link` saat pertama kali memakai CLI di repo ini.
  Password database acak itu tidak pernah ditampilkan; kalau `link` memintanya,
  buat password baru dari dashboard (TODO: needs source untuk letak menunya).

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

Mengubah skema: `npx supabase migration new <nama>`, tulis SQL-nya, lalu
`db push`. Migrasi yang sudah di-push jangan disunting — buat migrasi baru.

## 4. Pemetaan kontrak

| Method kontrak | Di Supabase |
| --- | --- |
| `AuthRepository.register` | `auth.signUp`, nama disimpan di user metadata. Sesi `null` (konfirmasi email menyala) → 409 "Akun dibuat. Buka tautan konfirmasi…" |
| `AuthRepository.login` / `me` / `logout` | `signInWithPassword` / `currentUser` / `signOut` |
| `AuthRepository.signInWithGoogle` | `signInWithOAuth(google)` — web: halaman yang sama pindah ke Google lalu kembali dengan `?code=` (PKCE); Android: browser eksternal kembali lewat deep link `com.catatin.catatin://login-callback` |
| `AuthRepository.currentSession` | `currentSession` — dipakai `AuthService` untuk mengadopsi sesi hasil login Google |
| `BusinessRepository.getCurrent` | select `business_profiles` (paling banyak satu baris) |
| `BusinessRepository.create` / `update` | upsert pada `user_id` / update per id |
| `TransactionRepository.getCategories` | select `tx_categories` urut `sort_order` |
| `TransactionRepository.getTransactions` | select + `category:tx_categories(*)`, diambil per halaman 1000 baris |
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

Tautan "Lupa kata sandi?" di layar masuk belum tersambung.

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

## Halaman terkait

- [Backend & API](backend-dan-api.md) — mode sumber data dan kontrak REST.
- [Rilis & deploy](../panduan/rilis-dan-deploy.md) — urutan push skema dan rilis.
- [Kontribusi](../panduan/kontribusi.md) — aturan rahasia di repo.
- [Backlog teknis](../proyek/backlog-teknis.md) — T-11 (sesi di web), T-16, T-17, T-18 (daftar email menunggu SMTP), T-19 (proyek Free dijeda), T-20 (uji login Google di Android).
