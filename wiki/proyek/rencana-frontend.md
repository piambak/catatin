---
title: Rencana Kerja Frontend — Fase Dua
description: "Rencana FE sembilan minggu (14 Sep–13 Nov 2026): tema per minggu, temuan yang ditutup, target skor PRD, dan berkas yang paling sering disentuh."
tags:
  - proyek
  - frontend
  - rencana
---

> **Status per 18 September 2026 — baca ini dulu.**
>
> Dokumen ini ditulis 12 September, sebelum wiki ini ada (dulu di `docs/`).
> Empat hal sudah berubah sejak itu; isi di bawah belum tentu mencerminkannya:
>
> * **D-7 sudah diputus: backend memakai Supabase**, bukan "belum ada stack".
>   Staging, auth Google, dan agregat bulanan sudah jalan. Bagian yang
>   mengandaikan backend nol perlu dibaca ulang.
> * **Tugas Minggu 1 sudah jadi isu GitHub #9–#15**; nomor PR internal di
>   dokumen ini (PR #1, #2, …) adalah urutan kerja, bukan nomor PR GitHub.
> * **T-18 (loop onboarding) sudah selesai di `main`** — `setOnboarded()` kini
>   dipanggil di `BusinessService.update()`. Abaikan bagian yang memintanya.
> * Repo pindah dari `docs/` ke `wiki/`; seluruh tautan di bawah sudah
>   disesuaikan. `alur-kerja.md` yang dirujuk beberapa kali **belum dibuat** —
>   isinya masih tersebar di [Kontribusi](../panduan/kontribusi.md) dan
>   [Linimasa](linimasa.md).

---

# Rencana Kerja Frontend — Catatin Fase Dua

**Versi:** 1.0 · **Dibuat:** 12 September 2026 · **Peran:** Frontend Engineer (FE), 1 orang
**Sumber:** [`backlog-teknis.md`](backlog-teknis.md) §1–§5 · [`linimasa.md`](linimasa.md) (v2) · `alur-kerja.md` (belum dibuat) · [`../desain/prd-redesain-ui.md`](../desain/prd-redesain-ui.md) §7 · [`../desain/design-tokens.md`](../desain/design-tokens.md)
**Periode:** Senin 14 Sep 2026 – Jumat 13 Nov 2026 (9 minggu kerja)

> **Kedudukan dokumen ini.** `linimasa.md` tetap satu-satunya linimasa dan tracker
> lintas peran. Dokumen ini **tidak menambah lingkup** — ia hanya memecah baris FE di
> linimasa itu menjadi langkah harian: berkas mana yang dibuka, apa yang diubah, bagaimana
> diverifikasi, dan kapan boleh dicentang. Kalau bertentangan, `linimasa.md` menang
> untuk *apa* & *kapan*, `alur-kerja.md` menang untuk *proses*, dokumen ini menang untuk
> *bagaimana urutan teknisnya*.

---

## English summary (1 page)

**What this is.** A day-by-day frontend execution plan for the 9-week Catatin Phase Two
schedule, derived from the 12 Sep audit (findings T-1…T-42, P-1…P-12) and the rewritten
project timeline. It covers only the FE role; PO/BE/PJ tasks appear solely as *inputs FE
waits for* or *outputs FE hands over*.

**The shape of the nine weeks.**

| Week | Dates | FE theme | Gate |
| --- | --- | --- | --- |
| 1 | 14–18 Sep | Stop the bleeding: trust chip on live numbers, CI gates publish, safe build script, 5 pure-FE bug fixes (T-16/18/19/22/24) | **M0** spec freeze |
| 2 | 21–25 Sep | Clean foundation: delete 3,684 orphan lines, one-shot `dart format`, fix token refresh, replace hand-rolled shell with `StatefulShellRoute` | **M1** |
| 3 | 28 Sep–2 Okt | Split `accounting_screen.dart` (1,827 → <400 lines), migrate last 5 files to `DS`/`Typo`, recurring transactions + receipt upload UI | |
| 4 | 5–9 Okt | One calendar component, responsive + nav rail, CSV export/import, filter & search, month-close card | **M2** Pembukuan v2 |
| 5 | 12–16 Okt | Tax engine wired to spec: TER B/C, PPh Final exemptions, regime branching, simulator pre-filled from bookkeeping aggregates | |
| 6 | 19–23 Okt | Saved & compared scenarios, simulation export, widget tests for the conversation flow | **M3** Simulator v2 |
| 7 | 26–30 Okt | Cross-feature integration, accessibility sweep (contrast, 48 dp, keyboard, screen reader), dark mode consistency | |
| 8 | 2–6 Nov | Bug burn-down, polish, performance, **lift the provisional disclaimer**, version + changelog | **M4** validated |
| 9 | 9–13 Nov | Full regression (run by BE, fixed by FE), release build, tag `v2.0.0`, 48h standby | **M5** RELEASE |

**Three rules that make the plan work.**

1. **Week 1 and 2 depend on nobody.** Every FE task before 25 Sep is pure frontend or CI.
   If the tax expert or backend slips, FE is not blocked — the slip only moves Week 5.
2. **One finding, one PR.** Each T-number gets its own branch and PR, with the screenshot
   or test named in the Definition of Done. No mixed PRs; a formatting PR contains only
   formatting.
3. **The PRD score is a ratchet.** `tool/prd_score.sh` lands in Week 1 as non-blocking,
   becomes blocking in Week 3, and a number is never allowed to go up again. Two metrics
   already regressed once (`BoxShadow` 3→6, `accounting_screen.dart` 1,731→1,827 lines);
   this is what stops it happening a third time.

**Biggest FE risks.** (a) Splitting `accounting_screen.dart` in Week 3 has no test safety
net today — Week 2 must land basic widget tests first. (b) The theme migration leaves two
visual systems alive until Week 3; Simulator tab 1 and tabs 2–3 look different in
production until then. (c) Weeks 5–6 depend on BE aggregation and PJ spec files; the
fallback if either is missing is written into Week 5.

---

## 0. Konvensi kerja FE

**Cabang & PR.** Satu temuan = satu cabang = satu PR.
`perbaikan/T-16-hybrid-auth-fallback`, `fitur/T-32-hapus-yatim`, `wiki/P-12-drift`.
Judul PR: `T-16: fallback hybrid tidak pernah untuk auth`.

**Definition of Done FE** (turunan `alur-kerja.md` §4 — semua wajib, tanpa kecuali):

| # | Syarat | Cara membuktikan di PR |
| --- | --- | --- |
| 1 | `flutter analyze` 0 error, 0 warning | tempel ringkasan keluaran |
| 2 | `flutter test` hijau; tes baru untuk perilaku yang diperbaiki | jumlah tes sebelum → sesudah |
| 3 | `flutter build web --release` sukses | ✓ |
| 4 | Tangkapan layar **terang & gelap** untuk setiap perubahan visual | 2 gambar minimal |
| 5 | Skor PRD tidak naik | keluaran `tool/prd_score.sh` sebelum/sesudah |
| 6 | Satu baris Log Progres di `linimasa.md` Lampiran B | di PR yang sama |
| 7 | Direview peran lain (BE atau PO), bukan self-merge | — |

**Verifikasi lokal sebelum push** (jalankan berurutan, hentikan di kegagalan pertama):

```bash
cd app
flutter pub get --enforce-lockfile
dart format --set-exit-if-changed .     # mulai berlaku Minggu 2
flutter analyze                          # --fatal-infos mulai Minggu 2
flutter test
flutter build web --release
../tool/prd_score.sh                     # mulai Minggu 1
```

**Versi Flutter.** CI = satu-satunya sumber kebenaran (3.44.8). Analyzer lokal versi lain
sudah pernah meloloskan PR yang merah di CI (catatan 8 Sep). Samakan versi lokal ke pin CI
di Minggu 1.

**Aturan menunggu.** Kalau sebuah tugas menunggu SPEC dari PJ atau endpoint dari BE, FE
**tidak** mengarang angka atau bentuk data dari sumber sekunder. Tugas ditandai 🔴 Terhambat
di papan Projects, dan FE mengambil tugas berikutnya dari minggu yang sama.

---

## Ringkasan beban FE per minggu

| Minggu | PR yang direncanakan | Temuan yang ditutup | Berkas paling berisiko |
| --- | --- | --- | --- |
| 1 | 8 | T-16, T-18, T-19, T-22, T-24, T-29, T-42, P-12 | `hybrid_repositories.dart`, `app_router.dart` |
| 2 | 6 | T-9, T-10, T-20b, T-23, T-27, T-28, T-32, T-37, T-38 | `api_client.dart`, `app_router.dart` |
| 3 | 7 | T-33, R-3, R-7 (sebagian) | `accounting_screen.dart` |
| 4 | 6 | T-39, T-40 (sebagian), T-41, R-4, R-5, R-6, R-8 | komponen kalender baru |
| 5 | 5 | T-1, T-3, T-17, T-25, T-26, T-35 | `simulator_service.dart` |
| 6 | 4 | — (fitur baru) | `scenario_tab.dart` |
| 7 | 5 | T-8, T-30, T-40 (sisa), R-9, R-10 | `design_tokens.dart` |
| 8 | 4 | sisa isu ronde 1 | `publish-web.yml` |
| 9 | 3 | sisa isu regresi | rilis |

---

# Minggu 1 — 14–18 September — Hotfix & bug frontend murni

**Target FE:** situs tayang jujur tentang status angkanya; publikasi tidak bisa lagi mendahului
CI; skrip build tidak bisa lagi menghapus berkas pengembang; lima bug yang tidak menunggu
siapa pun tertutup.
**Menunggu siapa pun?** Tidak. Satu-satunya masukan eksternal adalah **teks chip dari PJ**;
kalau belum ada Senin pagi, pakai teks kanvas E1 dan buka PR follow-up saat teks resmi turun.
**Keluaran minggu ini:** 8 PR tergabung, 3 di antaranya tayang ke produksi.

> **Runbook harian:** [`runbook-frontend-minggu-1.md`](runbook-frontend-minggu-1.md) memuat versi langkah-demi-langkah
> minggu ini — perintah git, prompt Claude Code siap tempel, daftar periksa manual, dan
> perintah verifikasi per PR. Bagian di bawah adalah ringkasannya.

### Senin 14 Sep — PR #1 `hotfix/H-1-chip-perkiraan` (🔴 T-17, prioritas tertinggi)

Situs publik sekarang menampilkan "Perkiraan pajak Anda" dengan tarif yang diketahui salah,
tanpa satu pun peringatan. Ini yang pertama dikerjakan, bukan yang paling menarik.

1. Buat komponen sekali pakai-ulang: `app/lib/widgets/common/ds_widgets.dart` → tambahkan
   `DsTrustChip({required String label, required TrustLevel level})` dengan dua level:
   `TrustLevel.draft` ("Perkiraan · belum ditinjau pakar pajak") dan `TrustLevel.verified`
   ("Tervalidasi pakar pajak · <tanggal>"). Level & tanggal dari satu konstanta di
   `app/lib/core/constants/app_constants.dart` (`taxReviewStatus`, `taxReviewDate`) supaya
   Minggu 8 cukup mengubah satu baris.
2. Pasang di `app/lib/screens/simulator/tax_conversation_tab.dart` — panel hasil (sekitar
   baris 395 & 434), tepat di atas angka, bukan di kaki layar.
3. Pasang di `app/lib/screens/dashboard/dashboard_screen.dart` blok kewajiban (baris 392–399).
4. `SimDisclaimer` **sudah ada** di `app/lib/widgets/simulator/sim_widgets.dart:310` dan
   dipakai `pph21_tab.dart:187`, tapi tidak dibawa ke tab baru. Jangan membuat ulang — tapi
   jangan pula memakainya di tab baru: `sim_widgets.dart` masih sistem tema lama
   (`AppColors`) sampai migrasi Minggu 3. Tab baru pakai `DsTrustChip` berbasis `DS`.
5. Gaya chip pakai token, bukan literal: `DS.warnBg` / `DS.warnFg` (tambahkan kalau belum ada
   di `design_tokens.dart`) — dan **cek kontras ≥ 4,5:1 di kedua mode** sebelum push.

*DoD tambahan:* tangkapan layar produksi terang & gelap dilampirkan setelah deploy; teks
final dicatat di isu `pajak` supaya PJ bisa mengoreksi tanpa membuka kode.

### Senin 14 Sep (sore) — PR #2 `hotfix/H-2-publish-setelah-ci` (🔴 T-42)

1. `.github/workflows/publish-web.yml`: ganti pemicu
   `on: push: branches: [main]` → `on: workflow_run: workflows: ["CI"] types: [completed] branches: [main]`,
   lalu jaga dengan `if: github.event.workflow_run.conclusion == 'success'`.
2. Di langkah publikasi (sekitar baris 121–131), sisipkan `git pull --rebase origin main`
   sebelum `git push`, supaya dua merge berurutan tidak menghasilkan kegagalan
   non-fast-forward.
3. Hapus `[skip ci]` dari pesan commit publikasi, atau — kalau tetap diperlukan supaya CI
   tidak berputar — tambahkan langkah verifikasi `version.json` setelah deploy.

*Verifikasi:* push commit dummy yang sengaja membuat satu tes gagal di cabang uji →
publikasi **tidak** boleh jalan. Hapus cabang setelahnya.

### Selasa 15 Sep — PR #3 `hotfix/H-3-sync-build-aman` (🔴 T-29)

`tool/sync_build.sh:57-63` dan `tool/build_web.ps1:67-70` menghapus **semua** isi root yang
tidak ada di daftar `KEEP`, termasuk dotfile (`.vscode`, `.idea`, `.env`). Ini jalan di mesin
pengembang.

1. Ganti strategi: tulis manifes `tool/.last_build_files` berisi daftar berkas yang disalin
   pada build sebelumnya; hanya berkas di manifes itu yang boleh dihapus.
2. Tambahkan `--dry-run` (default) dan wajibkan `--yes` untuk benar-benar menghapus.
3. Tambahkan penjaga: `set -euo pipefail` di bash, `$ErrorActionPreference = 'Stop'` di
   PowerShell; tolak jalan kalau `pwd` bukan root repo.
4. Perbarui `../panduan/rilis-dan-deploy.md` dengan pemakaian baru.

*Verifikasi:* di klon bersih, buat `.env` dan `.vscode/settings.json` palsu → jalankan skrip →
keduanya masih ada.

### Selasa 15 Sep (sore) — PR #4 `perkakas/prd-score`

Buat `tool/prd_score.sh` yang mencetak tabel dan keluar dengan kode 0 (non-blocking dulu):

| Metrik | Perintah |
| --- | --- |
| `BoxShadow` | `grep -rn "BoxShadow" app/lib \| wc -l` — target 0 |
| `showDialog` | `grep -rn "showDialog" app/lib \| wc -l` — target ≤ 4 |
| Breakpoint literal | `grep -rn "\b\(500\|680\)\b" app/lib --include=*.dart \| grep -v breakpoints.dart` — target 0 |
| `monospace` | `grep -rn "fontFamily: 'monospace'" app/lib \| wc -l` — target 0 |
| Token warna | hitung anggota `AppColors` + `DS` — target ≤ 16 |
| Kelas widget privat | `grep -rn "^class _" app/lib \| wc -l` — target < 40 |
| Baris `accounting_screen.dart` | `wc -l` — target < 400 |
| `withOpacity` | target 0 |

Tambahkan langkah di `ci.yml` yang menjalankannya dan menempelkan hasil sebagai komentar PR.
**Non-blocking Minggu 1–2, blocking mulai Minggu 3.** Simpan hasil hari ini sebagai baseline
di komentar PR — inilah angka yang tidak boleh naik lagi.

### Rabu 16 Sep — PR #5 `perbaikan/T-16-T-24-hybrid-tidak-menelan-error` (🔴)

Bug paling berbahaya di lapisan data: kata sandi salah → backend 401 → jatuh ke mock yang
menerima kredensial apa pun → pengguna "masuk" sebagai Budi Santoso.

1. `app/lib/core/data/hybrid_repositories.dart:17-26` — `_orFallback` sekarang menangkap
   **semua** `ApiException`. Persempit: fallback **hanya** bila
   `e.statusCode == 0` (jaringan mati), `404`, atau `501` (endpoint belum ada).
2. Tambahkan parameter `bool allowFallback` dan set `false` untuk **semua** operasi auth
   (baris 48–55). Login/register/refresh tidak pernah boleh jatuh ke mock, apa pun alasannya.
3. Baris 128–137 (`createTransaction` / `deleteTransaction`): 400/422 adalah penolakan
   validasi backend — **lempar ulang**, jangan tulis ke mock dan jangan kembalikan sukses.
4. `app/lib/core/data/mock_repositories.dart:43-59` — `mock.login()` menerima kredensial apa
   pun. Biarkan begitu untuk mode `mock` murni, tapi beri komentar `// hanya mode mock` dan
   pastikan tidak terjangkau dari jalur hybrid setelah langkah 2.
5. **Tes** (`app/test/hybrid_repositories_test.dart`, baru): pakai setter injeksi
   `ApiClient.instance` yang sudah ada tapi belum pernah dipakai. Tiga kasus: 401 → lempar,
   tidak fallback · 503/timeout → fallback ke mock · 422 pada createTransaction → lempar.

*DoD tambahan:* tes untuk ketiga kasus di atas; `Repos.reset()` dipakai di `tearDown`.

### Rabu 16 Sep (sore) — PR #6 `perbaikan/T-18-loop-onboarding` (🔴)

1. `app/lib/core/services/business_service.dart:35-54` — `update()` tidak pernah memanggil
   `setOnboarded()`; hanya `create()` yang melakukannya. Tambahkan di `update()`.
2. `app/lib/screens/auth/login_screen.dart:46-65` — setelah login berhasil dan profil usaha
   ditemukan, panggil `setOnboarded()` sebelum navigasi.
3. `app/lib/core/network/app_router.dart:129-133` — `_guard` memantulkan ke onboarding; beri
   jalan keluar: kalau profil usaha ada di backend tapi flag lokal kosong, set flag lalu
   lanjut, jangan memantul.
4. **Tes** (`app/test/router_guard_test.dart`, baru): simulasikan prefs kosong + profil usaha
   ada → tidak boleh berakhir di `/onboarding`.

### Kamis 17 Sep — PR #7 `perbaikan/T-19-navigasi-push` (🔴)

`context.go` ke rute tingkat atas lalu `context.pop()` → `GoError: There is nothing to pop`.

1. `app/lib/screens/dashboard/dashboard_screen.dart:261-305` — ganti `context.go(...)` →
   `context.push(...)` untuk `/accounting/new`, `/accounting/:id`, `/notifications`.
2. `app/lib/screens/accounting/tx_detail_screen.dart:90` dan
   `new_transaction_screen.dart:146,217,259` — pastikan setiap `pop()` punya pasangan `push()`.
   Kalau layar bisa dicapai dari dua arah, pakai `if (context.canPop()) context.pop(); else context.go('/accounting');`
3. `app/lib/screens/dashboard/notification_screen.dart` — tambahkan tombol kembali di
   `AppBar`; di ponsel layar ini sekarang tanpa kembali **dan** tanpa bottom nav, pengguna
   terjebak.
4. `app/lib/core/network/app_router.dart:42-60` — pertimbangkan memindahkan ketiga rute ini
   menjadi rute bersarang di dalam shell. Kalau ya, catat sebagai persiapan T-27 Minggu 2 dan
   **jangan** kerjakan sekaligus di PR ini.

*Verifikasi manual (wajib, dari sudut pengguna):* Dashboard → notifikasi → kembali ·
Dashboard → transaksi baru → batal · Dashboard → detail transaksi → kembali · ulangi di
375 px dan 1440 px.

### Kamis 17 Sep (sore) — PR #8 `perbaikan/T-22-error-state` (🟡)

`ErrorState` sudah ada di `app/lib/widgets/common/app_widgets.dart:180` tapi tidak dipakai
satu pun. Akibatnya empat layar shimmer selamanya saat `ApiException`.

Bungkus pemanggilan repositori dengan try/catch → `ErrorState(message:, onRetry:)` di:

- `app/lib/screens/accounting/accounting_screen.dart:46-50`
- `app/lib/screens/settings/settings_screen.dart:49-61`
- `app/lib/screens/settings/business_screen.dart:78-99`
- `app/lib/screens/accounting/new_transaction_screen.dart:108-147` (di sini: tombol simpan
  tidak boleh mati diam — tampilkan pesan dan kembalikan tombol ke keadaan aktif)

Pesan pakai `ApiException.userMessage` — tapi perhatikan `userMessage` **crash** `No element`
bila `details` kosong (T-37). Kalau menyentuhnya di sini, perbaiki sekalian dengan
`firstOrNull` dan catat T-37 sebagian selesai.

### Jumat 18 Sep — PR docs + tinjau kanvas

1. PR `wiki/P-12-drift` (tidak menyentuh kode Dart):
   - `../panduan/kontribusi.md` §4 — hapus "jangan jalankan `dart format`" (bertentangan dengan T-9
     yang dijadwalkan Minggu 2).
   - `../arsitektur/gambaran-umum.md` — tabel `core/theme` belum menyebut `design_tokens.dart` dan
     `breakpoints.dart`.
   - `README.md` — "Flutter 3.38.4+" → samakan dengan pin CI (3.44.8).
   - `app/lib/core/theme/breakpoints.dart` — header mengklaim breakpoint literal 500/680
     sudah diganti; belum. Perbaiki komentarnya, jangan klaim palsu.
2. Tinjau kanvas **Catatin UI v2** bersama PO: terima/tolak per artboard, catat sebagai
   D-17… di Log Keputusan `linimasa.md`. Artboard Pembukuan & Simulator yang
   diterima menjadi spesifikasi tampilan Minggu 3–6.
3. Sinkron M0. Konfirmasi di PR PJ bahwa `../domain/pajak/spek-pph21-ter.md` & `../domain/pajak/spek-pph-final-umkm.md`
   **cukup untuk diimplementasi** — ini tanda tangan FE, jangan basa-basi: kalau ada kolom
   yang tidak bisa dipetakan ke kode, tulis sekarang, bukan Minggu 5.

### ✅ Checklist akhir Minggu 1

- [ ] Chip "Perkiraan · belum ditinjau pakar pajak" tayang di produksi (Dashboard + Simulator)
- [ ] Commit dengan tes merah terbukti **tidak** tayang
- [ ] `sync_build.sh` terbukti tidak menghapus `.env` di klon bersih
- [ ] `tool/prd_score.sh` berjalan di CI, baseline tercatat
- [ ] T-16, T-18, T-19, T-22, T-24 tergabung, masing-masing dengan tes atau langkah verifikasi
- [ ] 4 dokumen drift diperbaiki
- [ ] Artboard yang diterima tercatat sebagai keputusan, bukan chat

---

# Minggu 2 — 21–25 September — Fondasi bersih

**Target FE:** repo tanpa kode mati, format seragam ditegakkan mesin, sesi yang tidak rusak,
shell navigasi yang benar. Ini minggu terakhir yang sepenuhnya mandiri — kerjakan sampai
habis.
**Menunggu:** D-5 (izin hapus kode yatim) dan D-14 (umur token) dari PO/BE. D-5 punya
tenggat 16 Sep; kalau lewat, default = "ya, dengan tag `pra-hapus-orphan`" berlaku otomatis.
**Urutan penting:** PR yatim **sebelum** PR format. Memformat 3.684 baris yang akan dihapus
adalah pemborosan dan membuat diff format mustahil dibaca.

### Senin 22 Sep — PR #9 `fitur/T-32-hapus-yatim` (🟡, 3.684 baris)

1. **Sebelum menghapus apa pun**, buktikan keyatiman dengan skrip, jangan dengan ingatan.
   Tambahkan `tool/find_orphans.sh`: untuk setiap berkas di `app/lib`, cari `import` yang
   menyebutnya; nol penyebut = kandidat yatim. Tempel keluarannya di deskripsi PR.
2. Tag titik aman: `git tag pra-hapus-orphan && git push --tags`.
3. Hapus 11 berkas yatim — kandidat dari audit: 10 widget di `app/lib/widgets/dashboard/`
   (3.225 baris) + `app/lib/screens/simulator/pph_final_tab.dart` (224) +
   `pph21_tab.dart` (235). **Verifikasi ulang tiap berkas dengan skrip** — `regulation_card.dart`
   dan `tax_tips_card.dart` pernah dipakai, jangan hapus berdasarkan daftar saja.
4. Kode mati di berkas hidup:
   - `app/lib/widgets/accounting/month_picker.dart` — `MonthPicker` &
     `AccountingSummaryRow` (±150 baris) tidak diimpor siapa pun; hanya `TxListTile` yang
     dipakai. **Pindahkan `TxListTile` ke `app/lib/widgets/accounting/tx_list_tile.dart`**
     dan hapus sisa berkasnya.
   - `app/lib/widgets/common/app_widgets.dart` — `SectionLabel`, `LabelDivider` (dan
     `ErrorState` **hanya kalau** PR #8 Minggu 1 tidak jadi memakainya — periksa dulu).
   - `buildTerTable` (pemanggilnya yatim), `StorageKeys.bookmarks`,
     `StorageKeys.themeMode` (notifier hardcode kuncinya sendiri di
     `theme_notifier.dart:20` — satukan, jangan hapus dua-duanya).
   - `TxData.isFavorite` di `app/lib/models/transaction_model.dart` — tidak pernah `true`,
     tombol ★ selalu kosong. Hapus field + tombol.
5. `pubspec.yaml`: cabut `percent_indicator` (hanya dipakai `pkp_bar.dart` yang yatim).
   Jalankan `flutter pub get` dan commit `pubspec.lock`.
6. **T-20a sekalian:** `TxListTile` yang baru dipindah harus **menghormati `onTap`** —
   sekarang diabaikan (`month_picker.dart:214`) dan semua pemanggil memberi `onTap: () {}`.
   Arahkan ke `context.push('/accounting/${tx.id}')`.

*DoD tambahan:* skor PRD "kelas widget privat" turun tajam; `flutter build web --release`
membandingkan ukuran `main.dart.js` sebelum/sesudah (catat di PR — ini angka yang enak
dipamerkan ke PO).

### Selasa 23 Sep — PR #10 `perkakas/T-9-T-10-format-coverage` (**hanya format, nol logika**)

1. `cd app && dart format .` — sekitar 57 dari 60 berkas akan berubah. **Tidak ada perubahan
   lain di PR ini.** Reviewer harus bisa memakai `git diff --ignore-all-space` dan melihat
   nol perubahan nyata.
2. `ci.yml`: tambah `dart format --set-exit-if-changed .`
3. `ci.yml`: `flutter test --coverage` + unggah `coverage/lcov.info` sebagai artifact (T-10).
   Belum ada ambang minimum — cukup angka yang terlihat, ambang ditetapkan Minggu 7.
4. `ci.yml`: `flutter pub get --enforce-lockfile`.
5. `flutter analyze --fatal-infos`: bersihkan ~40 info yang tersisa **di PR terpisah kecil**
   kalau perbaikannya menyentuh logika; kalau hanya gaya, boleh di sini.
6. Sekalian: pin action ke SHA, bukan tag (supply chain), dan tambahkan job build Android
   `flutter build apk --debug` supaya platform kedua tidak diam-diam rusak.

### Selasa 23 Sep (sore) — PR #11 `perbaikan/T-37-T-28-kebersihan-lapisan-data` (🟡)

Lima perbaikan kecil yang semuanya di lapisan data/konfigurasi:

1. `app/lib/core/config/app_config.dart:60-84` — `configError` mengatakan "jalan dengan data
   mock" padahal `dataSource` tetap `api` dengan `baseUrl: ''`. Buat pernyataan itu benar:
   URL kosong → `dataSource = mock`.
2. `app/lib/core/network/api_client.dart:37` — `ApiException.userMessage` crash `No element`
   bila `details` kosong → `firstOrNull`.
3. `app/lib/core/data/mock_repositories.dart:166-171` — `getTransaction(id)` mengembalikan
   `all.first` untuk id tak dikenal; artinya detail **dan hapus** bisa mengenai transaksi
   orang lain. Kembalikan `null` dan tangani di pemanggil.
4. `app/lib/widgets/accounting/tx_add_sheet.dart:111,122` — `businessId: 'b1'` hardcode →
   ambil dari `StorageService`.
5. **T-28:** `api_client.dart:83-91` — `PrettyDioLogger` mencetak `Authorization`, kata sandi,
   refresh token. Jaga dengan `AppConfig.enableApiLog && kDebugMode`, dan tambahkan redaksi
   header (`Authorization: ***`) supaya build rilis tidak bisa membocorkannya walau flag
   salah pasang.

### Rabu 24 Sep — PR #12 `perbaikan/T-23-refresh-token` (🔴, bersama BE)

Tiga bug berlapis di satu alur. Kerjakan berurutan dan tes tiap lapis.

1. **Konkurensi.** `api_client.dart:142-167` — Dashboard menembak 3 request; saat ketiganya
   kena 401, request ke-2 dan ke-3 melihat `_isRefreshing` dan langsung ditolak "Sesi
   berakhir" walau refresh berhasil. Ganti flag boolean dengan satu
   `Completer<void>? _refreshCompleter` yang dibagi: request yang datang saat refresh
   berjalan **menunggu** completer lalu diulang, bukan ditolak.
2. **Bearer basi.** Baris 123–127 — request ke `/auth/refresh` tetap membawa Bearer
   kedaluwarsa karena `onRequest` menimpa header `null`. Tambahkan
   `options.extra['skipAuth'] == true` yang dihormati `onRequest`, dan set di panggilan
   refresh.
3. **`clearAll` merusak.** `app/lib/core/services/storage_service.dart:94-97` —
   `clearAll()` = `prefs.clear()`, menghapus tema, onboarding, dan profil usaha. Ganti
   dengan `clearSession()` yang menghapus **hanya** kunci sesi (`token`, `refreshToken`,
   `user`). Tambahkan `refreshListenable` di router supaya gagal refresh benar-benar
   menavigasi ke `/login`, bukan meninggalkan layar mati.
4. **Tes** (`app/test/api_client_test.dart`, baru): 401 → refresh → retry berhasil ·
   tiga request bersamaan kena 401 → satu panggilan refresh, tiga retry · refresh gagal →
   `clearSession` dipanggil, `clearAll` tidak.

*Koordinasi BE:* konfirmasi bentuk respons `/auth/refresh` dan apakah refresh token dirotasi
(D-14). Kalau D-14 belum diputus Rabu, implementasikan default (access 15 mnt, rotasi) dan
tulis di PR bahwa ini mengikuti default.

### Kamis 25 Sep — PR #13 `refaktor/T-27-T-38-shell-router` (🟡)

1. `app/lib/core/network/app_router.dart:150-225` — `MainShell` menerima `child` tapi tidak
   pernah memakainya; `IndexedStack` buatan sendiri membangun keempat tab saat boot, jadi
   Dashboard + Pengaturan + Pembukuan menembak request bersamaan (inilah yang memicu
   konkurensi 401 di T-23). Ganti dengan `StatefulShellRoute.indexedStack` bawaan go_router.
   Efek samping yang diinginkan: transisi `_fade` akhirnya jalan, dan Dashboard dibangun
   ulang setelah transaksi baru dicatat.
2. Tambahkan `errorBuilder` di router (sekarang tidak ada — rute salah = layar kosong).
3. `_guard` membaca prefs 2× setiap navigasi → cache di memori, invalidasi saat login/logout.
4. `app/lib/main.dart:23-26` — kunci orientasi tanpa `!kIsWeb`. Bungkus sesuai D-16
   (default: buka untuk web + tablet).
5. `app/lib/screens/auth/login_screen.dart:67-80` — tombol demo (`'demo-token'`) tampil di
   mode hybrid/api dan langsung 401 → refresh gagal → sesi terhapus. Tampilkan **hanya**
   bila `AppConfig.dataSource == mock`.

*Verifikasi:* buka DevTools Network di mode `api` → saat boot hanya request Dashboard yang
jalan, bukan tiga layar sekaligus.

### Kamis 25 Sep (sore) — PR #14 `perbaikan/T-20b-edit-transaksi`

Tombol "Edit" sekarang bohong: `TxEditSheet._save` di
`app/lib/widgets/accounting/tx_add_sheet.dart:639-647` hanya `Future.delayed(400ms)` lalu
snackbar "berhasil diperbarui". Tidak ada `updateTransaction` di kontrak.

- **Kalau** BE sudah menggabungkan `PATCH /transactions/{id}` (kontrak Minggu 1): implementasikan
  `AccountingService.updateTransaction()` di
  `app/lib/core/services/accounting_service.dart` dan sambungkan ke ketiga repositori
  (`api_`, `mock_`, `hybrid_`).
- **Kalau belum:** sembunyikan kedua tombol Edit di balik
  `if (AppConfig.featureEditTransaction)` yang default `false`. Berbohong ke pengguna lebih
  buruk daripada tidak punya fitur.

### Jumat 25 Sep — Topi QA & M1

1. **Topi QA FE minggu ini:** uji auth ke staging BE. Kata sandi salah **harus** ditolak —
   T-16 tidak boleh muncul lagi. Uji juga: token kedaluwarsa di tengah pemakaian, logout,
   login ulang, tema tetap bertahan setelah logout (bukti `clearAll` sudah diganti).
2. Latihan rollback bersama tim (15 menit, `../panduan/rilis-dan-deploy.md`).
3. Jalankan `tool/prd_score.sh` dan catat di `linimasa.md` — bandingkan dengan
   baseline Minggu 1.

### ✅ Checklist akhir Minggu 2 (M1)

- [ ] `tool/find_orphans.sh` melaporkan **nol** berkas yatim
- [ ] `dart format --set-exit-if-changed` hijau di CI
- [ ] Coverage lcov terunggah sebagai artifact
- [ ] Tiga request bersamaan yang kena 401 menghasilkan **satu** refresh (ada tesnya)
- [ ] Logout tidak menghapus tema/onboarding
- [ ] Boot hanya membangun satu tab
- [ ] Tombol Edit benar-benar menyimpan, atau tidak ada
- [ ] Kata sandi salah ditolak di staging
- [ ] Skor PRD: `BoxShadow` ≤ 4, kelas privat < 60, `withOpacity` 0

---

# Minggu 3 — 28 September – 2 Oktober — Pembukuan naik kelas (1/2)

**Target FE:** `accounting_screen.dart` berhenti jadi berkas 1.827 baris; dua sistem tema
menjadi satu; transaksi berulang & lampiran struk jalan end-to-end.
**Menunggu:** endpoint berulang & lampiran dari BE (kontrak disepakati Rabu). UI boleh
dibangun lebih dulu di mode `mock`.
**Peringatan:** mulai minggu ini `tool/prd_score.sh` **blocking** di CI. Pecah berkas dulu,
fitur belakangan — kalau fitur masuk duluan, skornya naik dan CI menolak.

### Senin 28 Sep — PR #15 `refaktor/R-7-pecah-accounting-screen` (bagian 1: jaring pengaman)

Memecah 1.827 baris tanpa tes adalah cara tercepat merusak Pembukuan. Jadi jaringnya dulu.

1. Buat `app/test/widget/accounting_screen_test.dart`: `testWidgets` yang merender layar
   dengan repositori mock berisi data tetap, lalu memeriksa **yang terlihat**, bukan
   internal — jumlah baris transaksi, teks total bulan, tab yang aktif, keadaan kosong,
   keadaan memuat, keadaan error.
2. Empat tes minimum: tab Harian, Kalender, Bulanan, Total. Simpan keluaran total sebagai
   nilai harapan — inilah yang harus identik setelah dipecah.
3. Jalankan, pastikan hijau, **commit ini dulu sebagai PR sendiri.** Diff pecah berkas dan
   diff tes tidak boleh bercampur.

### Selasa 29 – Rabu 30 Sep — PR #16 `refaktor/R-7-pecah-accounting-screen` (bagian 2)

Pecah `app/lib/screens/accounting/accounting_screen.dart` menjadi:

| Berkas baru | Isi |
| --- | --- |
| `accounting_screen.dart` (tinggal) | scaffold, state tab, pemanggilan repositori — target **< 400 baris** |
| `daily_tab.dart` | tab Harian |
| `calendar_view.dart` | `_FullCalGrid` (baris 644–677) + `_MiniCalendar` (835–880) — **satukan jadi satu implementasi** |
| `filter_row.dart` | chip filter + checkbox (512–527, 746–760) |
| `monthly_tab.dart` | `_MonthlyTab` |
| `total_tab.dart` | `_TotalTab` |

Aturan saat memindah:

- Kelas privat yang dipakai > 1 layar naik ke `app/lib/widgets/common/`, bukan disalin.
- Ganti 50+ angka spasi mentah dengan `Space.*` — berkas ini memakai `Space.*` **nol kali**
  sekarang. Ini tidak mengubah tampilan kalau nilainya sama; kalau berbeda, catat di PR.
- **Nol perubahan perilaku.** Tes dari PR #15 harus tetap hijau tanpa disentuh. Kalau sebuah
  tes perlu diubah, itu tandanya perilaku berubah — hentikan dan pisahkan jadi PR sendiri.
- Bug logika di berkas ini (T-39) **jangan** diperbaiki di sini — dijadwalkan Minggu 4,
  supaya diff pecah tetap bisa dibaca.

*DoD tambahan:* `wc -l` sebelum/sesudah untuk setiap berkas di deskripsi PR; skor PRD
"kelas widget privat" dan "baris `accounting_screen.dart`" keduanya turun.

### Rabu 30 Sep – Kamis 1 Okt — PR #17…#21 `refaktor/R-3-migrasi-tema` (satu PR per berkas)

Lima berkas hidup masih memakai `AppColors`/`AppTextStyles` (2.051 baris). Akibatnya layar
Simulator tampil campur: tab 1 gaya baru, tab 2–3 gaya lama. Satu PR per berkas, urut dari
yang paling terlihat:

1. `app/lib/screens/simulator/calendar_tab.dart` (12,9 KB)
2. `app/lib/screens/simulator/scenario_tab.dart` (10,5 KB) — akan dipakai berat Minggu 6
3. `app/lib/widgets/simulator/sim_widgets.dart` (16,0 KB)
4. `app/lib/screens/dashboard/notification_screen.dart` (12,3 KB)
5. `app/lib/widgets/accounting/tx_list_tile.dart` (hasil pindahan Minggu 2)

Setelah kelima tergabung: **hapus `AppColors` dan `AppTextStyles`** dari
`app/lib/core/theme/app_theme.dart`. Ini yang menurunkan skor token warna dari 64 → ≤ 16
dan menutup R-3. Sekalian: hapus `fontFamily: 'monospace'` di `app_theme.dart:111` dan
`design_tokens.dart:159` — `Typo.mono` yang dipakai 60+ tempat harus menunjuk ke satu
definisi, bukan dua.

### Kamis 1 Okt — PR #22 `fitur/transaksi-berulang-ui`

Di `app/lib/screens/accounting/new_transaction_screen.dart`:

1. Bagian "Ulangi transaksi ini" — toggle + frekuensi (mingguan / bulanan) + tanggal akhir
   opsional. Pakai komponen dari `tx_form_widgets.dart` yang sudah diseragamkan, jangan
   bikin gaya baru.
2. Model: tambahkan `RecurrenceRule` di `app/lib/models/transaction_model.dart`
   (`frequency`, `interval`, `endDate`, `sourceTemplateId`).
3. Daftar transaksi menandai baris yang berasal dari template (ikon kecil + semantik
   "transaksi berulang").
4. Sambungkan ke endpoint template BE kalau sudah ada; kalau belum, mode `mock` dulu dan
   tandai di PR.

### Jumat 2 Okt — PR #23 `fitur/lampiran-struk-ui` + PR #24 `perbaikan/T-33-notifikasi-palsu`

**Lampiran struk.** Kamera/galeri di mobile, file picker di web. `pubspec.yaml` saat ini
**tidak** punya `image_picker` — ini satu-satunya dependensi baru yang direncanakan sepanjang
9 minggu, jadi sebutkan alasannya di PR dan periksa dukungan webnya sebelum menambah. Preview di
`app/lib/screens/accounting/tx_detail_screen.dart`. Batas 5 MB, hanya gambar — validasi di
klien **dan** percaya penolakan server.

**T-33.** `app/lib/screens/dashboard/notification_screen.dart:288-335` menampilkan notifikasi
contoh ("Omzet YTD Anda sudah mencapai 85% dari batas PKP…") sebagai notifikasi nyata ke
semua pengguna. Hapus data contoh; badge di `dashboard_screen.dart:303` hanya menyala kalau
ada notifikasi nyata yang belum dibaca; kalau tidak ada, tampilkan keadaan kosong yang jujur.

### ✅ Checklist akhir Minggu 3

- [ ] `accounting_screen.dart` < 400 baris, tes widget tetap hijau tanpa diubah
- [ ] `AppColors` & `AppTextStyles` tidak ada lagi di `app/lib`
- [ ] Token warna ≤ 16, `monospace` 0
- [ ] Satu implementasi grid kalender di Pembukuan (bukan dua)
- [ ] Transaksi berulang & lampiran jalan (mode mock minimal)
- [ ] Notifikasi tidak lagi menampilkan data karangan
- [ ] `prd_score.sh` blocking dan hijau

---

# Minggu 4 — 5–9 Oktober — Pembukuan naik kelas (2/2) · **M2**

**Target FE:** satu komponen kalender untuk seluruh aplikasi; tata letak responsif dengan
nav rail; ekspor/impor CSV; filter & pencarian; bug logika `accounting_screen` tuntas.

### Senin 5 – Selasa 6 Okt — PR #25 `refaktor/R-8-satu-kalender`

Sekarang ada **empat** implementasi tanggal: `_FullCalGrid`, `_MiniCalendar` (keduanya di
Pembukuan), grid di `calendar_tab.dart`, dan 3 pemanggilan `showDatePicker`.

1. Buat `app/lib/widgets/common/app_calendar.dart` — grid bulan dengan penanda hari
   (`Map<DateTime, MarkerStyle>`), rentang yang dipilih, dan callback.
2. Buat `app/lib/widgets/common/app_date_picker.dart` — pembungkus tunggal; semua
   `showDatePicker` memanggil ini, sehingga gaya & lokalisasi ada di satu tempat.
3. Ganti keempat pemakaian. `calendar_tab.dart` (Simulator) dan `calendar_view.dart`
   (Pembukuan) memakai komponen yang sama dengan konfigurasi berbeda.
4. **T-41:** nama bulan ditulis tangan di **8 tempat** meski `Tanggal.month()` (intl) sudah
   ada di `app/lib/core/utils/formatters.dart`. Ganti semuanya. Cari dengan
   `grep -rn "Januari\|Jan'" app/lib`.
5. Sekalian bersihkan literal lain yang ditemukan audit: `Color(0xFF185FA5)` dan `_catColors`
   yang tidak sadar mode gelap → token; `'1.0.0'` → `AppConstants.appVersion`
   (`settings_screen.dart:340`); "Rp 4,8 M" → `Rupiah.miliar()`
   (`simulator_service.dart:350`, `dashboard_screen.dart:568`).

*DoD tambahan:* skor `showDialog` turun; tangkapan layar kalender di terang/gelap dan di
375/768/1440.

### Selasa 6 Okt (sore) — PR #26 `fitur/R-4-responsif`

1. `app/lib/core/theme/breakpoints.dart` — 3 breakpoint literal (500/680) masih tersebar.
   Ganti ke `Bp.*`. Header berkas yang mengklaim ini sudah beres diperbaiki Minggu 1;
   sekarang buat klaimnya jadi benar.
2. `AppNavRail` di `app/lib/widgets/common/app_nav.dart` aktif di lebar `expanded` (D-6).
3. Pembukuan di web = dua panel (daftar + detail) sesuai artboard `PembukuanWeb`.
4. Konten dibatasi 1200 px di layar lebar — teks selebar layar 27" tidak terbaca.
5. Kunci orientasi: konfirmasi `!kIsWeb` dari Minggu 2 sesuai D-16 (web + tablet dibuka).

### Rabu 7 Okt — PR #27 `fitur/ekspor-impor-csv`

1. **Ekspor:** pemilih rentang (pakai `app_date_picker.dart` yang baru), pilihan kategori,
   unduh di web / bagikan di mobile. Kolom mengikuti `SPEC-Ekspor.md` dari PJ — kalau
   SPEC belum ada, **jangan tebak kolomnya**; kerjakan UI rentang & tombol, sambungkan
   kolomnya saat SPEC turun.
2. **Impor:** unggah CSV → **preview** (10 baris pertama + jumlah total) → daftar baris
   error dengan nomor baris → konfirmasi. Laporan gagal dari server ditampilkan apa adanya.
3. **R-5:** seluruh alur ini **tanpa modal bertumpuk**. Target `showDialog` ≤ 4 dan semuanya
   konfirmasi destruktif. Pakai halaman atau bottom sheet penuh, bukan dialog di atas dialog.

### Kamis 8 Okt — PR #28 `fitur/filter-pencarian` + PR #29 `fitur/kartu-tutup-bulan`

**Filter & pencarian** di Pembukuan: kategori, rentang tanggal, relevansi pajak, HPP —
sebagai chip seperti artboard `Pembukuan`. Pencarian teks pada catatan & nominal. State
filter hidup di `accounting_screen.dart` (yang sekarang ramping), bukan di tiap tab.

**Kartu ringkasan tutup bulan** di Dashboard: "Bulan ini" + laba, dari endpoint agregasi BE
(`GET /dashboard/close?month&year`). Tampilkan keadaan memuat dan error — bukan shimmer
selamanya (pelajaran T-22).

### Kamis 8 Okt (sore) — PR #30 `perbaikan/T-39-T-40-bug-pembukuan`

**T-39** — empat bug logika di Pembukuan:

1. `accounting_screen.dart:53-127` — filter bulan memakai `DateTime.now().month` tanpa
   melihat `widget.year`; buka tahun lalu, dapat bulan ini.
2. Baris 1074–1076 — "Rata-rata Harian" = total **sepanjang masa** ÷ 22. Harus total periode
   yang dipilih ÷ hari kerja periode itu.
3. Baris 1179–1196 — `_TotalTab` / `_MonthlyTab` menerima `loading` tapi tidak memakainya.
4. `tx_add_sheet.dart:151-164` — `TxAddSheet` bergaya bottom sheet tapi dipasang lewat
   `showDialog` di tengah layar, dan `DraggableScrollableSheet` di dalam `showDialog`. Ganti
   ke `showModalBottomSheet`. Alur daftar → detail → edit → date picker sekarang **3 lapis
   modal**; setelah PR #25 & #27 harus tinggal 1.

**T-40 (bagian target sentuh)** — semua < 48 dp:
`_NavBtn` 28×28 (`accounting_screen.dart:272-292`), chevron mini-kalender `GestureDetector`
16 px (512–527), checkbox filter 14 px (746–760), tombol tutup sheet 28 px
(`tx_add_sheet.dart:172-180`). Perbesar area sentuh tanpa mengubah ukuran visual
(`Padding` + `behavior: HitTestBehavior.opaque`, atau `IconButton` dengan `constraints`).
Sisa T-40 (semantik & keyboard) dikerjakan Minggu 7 saat markup stabil.

### Jumat 9 Okt — M2

- Demo Pembukuan v2 di staging bersama PO.
- Jalankan `../panduan/checklist-regresi-ui.md` sendiri dulu sebelum demo.
- Catat skor PRD; targetnya semua kriteria tata letak sudah ✅ kecuali aksesibilitas
  (Minggu 7) dan `accounting_screen` yang sudah beres Minggu 3.

### ✅ Checklist akhir Minggu 4 (M2)

- [ ] Satu `AppCalendar` + satu `AppDatePicker`, empat implementasi lama hilang
- [ ] Nol breakpoint literal; nav rail aktif di desktop
- [ ] `showDialog` ≤ 4, semuanya konfirmasi destruktif
- [ ] Ekspor & impor CSV jalan di staging (mode `api`)
- [ ] Filter, pencarian, kartu tutup bulan jalan
- [ ] Nol target sentuh < 48 dp di Pembukuan
- [ ] Nama bulan hanya dari `Tanggal.month()`

---

# Minggu 5 — 12–16 Oktober — Simulator naik kelas (1/2)

**Target FE:** angka pajak akhirnya benar dan berasal dari spesifikasi tertulis; simulator
berhenti meminta input manual sebagai langkah wajib.
**Menunggu (keras):** `../domain/pajak/spek-pph21-ter.md`, `../domain/pajak/spek-pph-final-umkm.md`,
`../domain/pajak/kasus-pph21.csv`, `../domain/pajak/kasus-pph-final.csv` dari PJ (seharusnya tergabung 18 Sep), dan endpoint
agregasi BE (`GET /transactions/aggregate`, `GET /simulator/inputs`).

> **Kalau SPEC belum ada Senin pagi:** jangan mengarang tarif dari sumber sekunder. Tandai
> minggu ini 🔴 Terhambat di papan, beri tahu PO hari itu juga, dan pindah ke jalur cadangan:
> tes widget alur percakapan (dijadwalkan Minggu 6), polish artboard Simulator, dan mulai
> sapuan aksesibilitas Minggu 7 lebih awal. Minggu 5 bergeser — bukan kualitas angkanya.

### Senin 12 Okt — PR #31 `perbaikan/T-1-ter-b-c`

1. `app/lib/core/services/simulator_service.dart` — tambahkan `terTableB` dan `terTableC`
   persis dari `../domain/pajak/spek-pph21-ter.md` (PMK 168/2023). Salin **dari berkas SPEC**, jangan dari
   ingatan atau blog.
2. Tambahkan `TerCategory terCategoryFor(PtkpStatus status)` dari tabel pemetaan di SPEC.
3. Buka tes yang di-`skip` di `app/test/simulator_service_test.dart` (penanda T-1).
4. **Tes dibangkitkan dari CSV:** tambahkan `app/test/cases_pph21_test.dart` yang membaca
   `../domain/pajak/kasus-pph21.csv` dan membuat satu `test()` per baris. Ini yang membuat koreksi
   PJ berikutnya cukup mengubah CSV, bukan kode.
5. Hapus `buildTerTable` kalau sudah tidak ada pemanggil hidup (sisa T-32).

### Selasa 13 Okt — PR #32 `perbaikan/T-3-T-26-pph-final`

1. `PPhFinalResult` di `simulator_service.dart` — tambahkan:
   - pengecualian Rp500 juta pertama (D-9: WP OP saja),
   - batas jangka waktu PP 23 (butuh field baru **`tahunMulaiUsaha`** di Profil usaha —
     tambahkan di `app/lib/models/business_model.dart` dan
     `app/lib/screens/settings/business_screen.dart`),
   - transisi di atas Rp4,8 M.
2. **T-26 (🔴):** `simulator_service.dart:283-284` sekarang mengembalikan **0** untuk omzet di
   atas ambang, sehingga skenario "Optimistis" tampak paling murah pajaknya. Ganti dengan
   status eksplisit `PPhFinalStatus.diLuarSkemaFinal` dan tampilkan sebagai teks, bukan
   angka nol.
3. **Perbaiki tesnya, bukan hanya kodenya:** `app/test/simulator_service_test.dart:323-338`
   saat ini **mengunci** perilaku salah itu. Tulis ulang tes tersebut agar mengharapkan
   status baru.
4. `app/test/cases_pph_final_test.dart` dari `../domain/pajak/kasus-pph-final.csv`.

### Rabu 14 Okt — PR #33 `fitur/T-17-E3-percabangan-rezim`

Ini yang menutup temuan 🔴 paling memalukan: persona "pedagang online / driver" dihitung
dengan TER karyawan.

1. `app/lib/screens/simulator/tax_conversation_tab.dart:27-35` — pertanyaan 1 bercabang:
   **karyawan** → jalur PPh 21 TER · **usaha sendiri** → jalur PPh Final UMKM. Matriks
   profesi → rezim dari D-11 / `SPEC-*.md`.
2. Baris 80–84 & 395: panggil kalkulator sesuai cabang, bukan `calculatePPh21` untuk semua.
3. Tampilkan **chip skema** ("PPh Final UMKM 0,5%") + **dasar hukum** ("PP 23/2018") di panel
   hasil, sesuai artboard E3.
4. Kalimat pembanding satu baris ("Kalau Anda karyawan dengan penghasilan sama, …") — teks
   dari PJ.
5. Tes widget: tiga persona → tiga rezim yang benar.

### Rabu 14 Okt (sore) — PR #34 `perbaikan/T-25-tanggal-tenggat`

Tiga bug tanggal, semuanya terlihat di Dashboard:

1. `simulator_service.dart:370-374` — `DateTime(year+1, 4, 30)` berlabel "SPT Tahunan PPh OP".
   SPT **OP jatuh tempo 31 Maret**; 30 April untuk badan (D-12). Perbaiki dan beri label yang
   benar.
2. Baris 399 — tenggat masa `DateTime(year, m+1, 30)`; untuk Januari jadi "30 Februari" yang
   bergulir ke Maret. Pakai tanggal 15 bulan berikutnya sesuai D-12, dengan penjagaan akhir
   bulan.
3. Baris 358, `app/lib/models/dashboard_model.dart:104`,
   `app/lib/core/utils/formatters.dart:114-115` — `difference(...).inDays` dengan
   `DateTime.now()` membawa jam, jadi hitung mundur **kurang satu hari**; "jatuh tempo hari
   ini" muncul sehari lebih awal. Hitung berbasis tanggal saja:
   `DateTime(a.year,a.month,a.day).difference(DateTime(b.year,b.month,b.day)).inDays`.
4. `app/lib/core/data/mock_data.dart:85` ikut diperbaiki supaya data contoh tidak
   mengajarkan tanggal yang salah.
5. **Tes:** `app/test/formatters_test.dart` — `Tanggal.daysUntil` untuk 31 Des→1 Jan,
   tahun kabisat, dan hari yang sama pada jam berbeda. Tes `generateCalendar` untuk 12 bulan.

### Kamis 15 Okt — PR #35 `fitur/R-6-E2-simulator-dari-pembukuan`

Simulator saat ini **nol** kali mengimpor `BusinessService` / `StorageService`, padahal
Pengaturan mengklaim sebaliknya (T-35).

1. Nilai awal ditarik dari `GET /simulator/inputs` (atau agregasi Pembukuan): rata-rata 3
   bulan terakhir atau bulan berjalan.
2. Input manual menjadi **override**, bukan langkah wajib.
3. Baris sumber di bawah angka: "Dihitung dari 47 transaksi (Jul–Sep) · Ubah" — artboard E2.
4. Profil usaha benar-benar dipakai: status PKP, `tahunMulaiUsaha` (dari PR #32).
5. **T-35:** setelah ini, klaim di `settings_screen.dart:394-397` dan
   `business_screen.dart:261-262` menjadi benar. Kalau PR ini mundur, **hapus klaimnya**
   minggu ini juga — jangan biarkan teks berbohong.
6. Keadaan memuat & error untuk penarikan agregasi (`ErrorState`, bukan shimmer selamanya).

### Jumat 16 Okt — PR #36 `perbaikan/T-34-nominal-kewajiban`

`app/lib/screens/dashboard/dashboard_screen.dart:80-81, 257-274` — `_obligationAmount`
(PPh Final dari omzet bulan ini) ditempel ke `_deadlines.first` dan "≈" ke `[1]` tanpa
melihat `taxType`; dengan data contoh, `[1]` adalah PPh 21 Karyawan. Angka yang salah
dilekatkan ke tenggat yang salah.

1. Hitung nominal **per `taxType`**; tenggat tanpa nominal yang diketahui tampil tanpa angka.
2. Baris 451–455 — CTA "Tandai sudah dibayar" hanya menampilkan snackbar "menunggu backend".
   Sembunyikan sampai endpointnya ada, atau ganti jadi tautan ke panduan bayar.
3. **T-36** (koordinasi PJ): `AppConstants.ppnRate` 11% dipakai sebagai beban = 11% × omzet
   tanpa pajak masukan, dan tarif/DPP sudah berubah per PMK 131/2024. Kalau D-8 = ditunda,
   **cabut** perhitungan PPN dari simulator, jangan biarkan angka yang salah. Hapus juga
   `pphBadanRate = 0.22` di `app_constants.dart:17` yang diekspor tapi tidak dipakai.

### ✅ Checklist akhir Minggu 5

- [ ] `../domain/pajak/kasus-pph21.csv` & `../domain/pajak/kasus-pph-final.csv` jalan sebagai tes otomatis, semua hijau
- [ ] Tes yang di-`skip` sudah dibuka; tes yang mengunci nilai 0 sudah ditulis ulang
- [ ] Persona usaha sendiri memakai PPh Final, bukan TER karyawan
- [ ] SPT OP = 31 Maret; hitung mundur tidak lagi kurang sehari
- [ ] Simulator terisi otomatis dari Pembukuan, dengan baris sumber
- [ ] Klaim "Simulator memakai data ini" di Pengaturan sudah benar (atau dicabut)
- [ ] Nominal kewajiban cocok dengan jenis pajak tenggatnya

---

# Minggu 6 — 19–23 Oktober — Simulator naik kelas (2/2) · **M3**

**Target FE:** skenario bisa disimpan & dibandingkan; hasil bisa dibagikan dengan disclaimer
tercetak; alur percakapan punya tes.

### Senin 19 – Selasa 20 Okt — PR #37 `fitur/simpan-skenario`

1. UI simpan: nama skenario, asumsi yang dipakai, hasil, dan **`config_version`** dari mesin
   tarif — tanpa versi konfigurasi, skenario lama jadi tidak bisa dijelaskan saat tarif
   berubah.
2. Daftar skenario tersimpan sesuai artboard `SimulatorWeb`.
3. Sambungkan ke `/scenarios` CRUD dari BE. Mode `mock` sebagai cadangan kalau endpoint
   telat, tapi **jangan** menelan error penyimpanan (pelajaran T-24).

### Selasa 20 – Rabu 21 Okt — PR #38 `fitur/bandingkan-skenario`

`app/lib/screens/simulator/scenario_tab.dart` (sudah bermigrasi tema di Minggu 3):
perbandingan 2–3 skenario berdampingan. Di ponsel: kartu bertumpuk dengan geser horizontal,
bukan tabel yang terpotong. Setiap kolom menampilkan skema & dasar hukumnya sendiri — dua
skenario bisa berada di rezim berbeda.

### Rabu 21 Okt (sore) — PR #39 `fitur/ekspor-hasil-simulasi`

PDF / bagikan, dengan **disclaimer PJ tercetak di dokumen**, bukan hanya di layar. Sertakan
tanggal perhitungan dan `config_version`. Kalau chip masih "Perkiraan · belum ditinjau",
teks itu ikut tercetak.

*Bila D-8 = masuk:* UI modul PPN (hanya untuk PKP) & proyeksi SPT Tahunan. Kalau D-8 =
ditunda (default), lewati — dan pastikan sisa jejak PPN sudah dicabut di Minggu 5 (T-36).

### Kamis 22 Okt — PR #40 `tes/widget-simulator`

Belum ada satu pun `testWidgets` bermakna di seluruh repo. Mulai dari alur yang paling
berisiko:

1. Alur percakapan 3 pertanyaan → hasil, untuk dua persona (karyawan & usaha sendiri).
2. Chip skema & dasar hukum muncul dan sesuai rezim.
3. Golden test terang & gelap untuk panel hasil (ini juga yang menangkap regresi kontras
   sebelum Minggu 7).
4. Keadaan error agregasi → `ErrorState`, bukan layar kosong.

### Kamis 22 Okt (sore) — Topi QA

BE menguji Simulator dari sudut pengguna awam. Pertanyaan yang dijawab: apakah bahasanya
manusia? apakah istilah pajak hanya muncul di keterangan, bukan di judul? apakah pengguna
tahu angka ini perkiraan? Isu masuk berlabel `ui`.

### Jumat 23 Okt — M3

Demo Simulator v2 di staging; ttd PO.

### ✅ Checklist akhir Minggu 6 (M3)

- [ ] Skenario tersimpan berikut `config_version`
- [ ] Perbandingan 2–3 skenario jalan di ponsel & desktop
- [ ] Ekspor hasil membawa disclaimer & tanggal
- [ ] Tes widget alur percakapan hijau, terang & gelap
- [ ] T-1, T-3, T-17, T-25, T-26 semuanya tertutup dengan tes dari CASES

---

# Minggu 7 — 26–30 Oktober — Integrasi & aksesibilitas

**Target FE:** semua bagian terbukti benar saat dipakai bersamaan; aksesibilitas dituntaskan
sekarang, saat markup sudah stabil dan sebelum polish.
**Kenapa aksesibilitas baru sekarang:** menambahkan semantik ke markup yang masih berubah =
mengerjakannya dua kali. Setelah Minggu 6, markup tidak berubah lagi kecuali perbaikan bug.

### Senin 26 Okt — Uji alur penuh (bukan PR, tapi wajib dilaporkan)

Mode `api` ke staging, di 375 px / 768 px / 1440 px, terang & gelap:
catat transaksi → muncul di Dashboard → Simulator terhitung otomatis dari transaksi itu →
simpan skenario → ekspor CSV → impor kembali → bandingkan skenario.
Setiap keanehan jadi isu berlabel `frontend` + langkah reproduksi. Tulis hasilnya sebagai
komentar di isu integrasi, termasuk yang **berhasil** — itu baseline regresi Minggu 9.

### Selasa 27 Okt — PR #41 `a11y/T-30-kontras` (🟡)

Ini bukan selera; ini angka. Ukur dengan alat, tempel rasionya di PR.

| Masalah | Lokasi | Tindakan |
| --- | --- | --- |
| `DS.faint` #8898AA = **2,95:1**, dipakai sebagai teks di 51 tempat | `design_tokens.dart:36` | Batasi `faint` **hanya** untuk label 11px/600 uppercase (yang diizinkan WCAG sebagai non-teks dekoratif hanya kalau bukan pembawa informasi — kalau pembawa informasi, gelapkan). Teks biasa → `DS.muted` |
| `DS.soft` terang = **2,01:1** | `design_tokens.dart:39` | Hanya untuk garis/pembatas, tidak pernah teks |
| `DS.income` terang = **4,39:1** | `design_tokens.dart` | Gelapkan sedikit ke ≥ 4,5:1 |
| `Colors.white` di atas `DS.brand` = **1,99:1** | `tx_add_sheet.dart:266,753`, `month_picker.dart:436`→`tx_list_tile.dart` | Ganti ke `DS.onBrand` (**8,75:1**) — `DsButton` sudah benar, tiga tempat ini yang menyimpang |
| Hint `color: DS.border` = **1,44:1** | `tx_add_sheet.dart:354,534` | → `DS.muted` |
| Mode gelap: `faint == soft` (R-10) | `design_tokens.dart` | Beri nilai berbeda; dua peran berbeda tidak boleh warna sama |

### Rabu 28 Okt — PR #42 `a11y/T-40-semantik-keyboard` (sisa T-40)

1. **Semantik** untuk semua grafik, bar, dan tombol ikon-saja. Sudah ✅ untuk `fl_chart`
   hidup; yang masih **nol**: `tx_list_tile.dart` (eks `month_picker`), `tx_add_sheet.dart`,
   `calendar_tab.dart`, `notification_screen.dart`.
2. **Sel kalender** sekarang hanya punya `Tooltip` hover + warna — tidak terjangkau keyboard
   dan tidak terbaca pembaca layar. Beri `Semantics(label: '12 Oktober, 3 transaksi, Rp …')`
   dan buat bisa difokus.
3. **Dropdown overlay buatan sendiri** (`accounting_screen.dart:959-985` → `filter_row.dart`)
   tanpa `FocusNode` dan tanpa Esc. Tambahkan `FocusScope`, tutup dengan Esc, kembalikan
   fokus ke pemicu.
4. Sapu sisa target sentuh < 48 dp di luar Pembukuan (Simulator, Pengaturan, Notifikasi).

### Kamis 29 Okt — PR #43 `a11y/pembaca-layar` + PR #44 `a11y/mode-gelap`

1. **Uji pembaca layar sungguhan**, bukan hanya `flutter test`: TalkBack (Android),
   VoiceOver (iOS/macOS), NVDA (Windows/web). Jalankan satu alur penuh di masing-masing.
   Rekam temuan sebagai daftar; perbaiki yang menghalangi penyelesaian tugas minggu ini,
   sisanya jadi isu Fase Tiga.
2. **Mode gelap konsisten** di semua layar yang lahir Minggu 3–6. Periksa satu per satu
   dengan golden test kalau sudah ada, manual kalau belum.
3. Tambahkan ambang coverage minimum di CI sekarang (angkanya dari lcov Minggu 2–6, dibulatkan
   ke bawah) supaya Minggu 8–9 tidak menurunkannya.

### Jumat 30 Okt — Perbaikan isu integrasi

Habiskan isu berlabel `frontend` dari uji Senin dan dari validasi PJ ronde 1. Prioritas:
apa pun yang menghalangi pengguna menyelesaikan tugas > tampilan.

### ✅ Checklist akhir Minggu 7

- [ ] Nol kombinasi teks/latar < 4,5:1 di kedua mode (diukur, bukan dikira)
- [ ] `faint` ≠ `soft` di mode gelap
- [ ] Semua grafik, bar, dan ikon-saja punya semantik
- [ ] Kalender & dropdown bisa dipakai keyboard penuh, Esc menutup
- [ ] Satu alur penuh selesai dengan TalkBack, VoiceOver, dan NVDA
- [ ] Ambang coverage aktif di CI

---

# Minggu 8 — 2–6 November — Polish, performa, cabut disclaimer · **M4**

**Target FE:** isu ronde 1 habis; performa terukur; chip berganti "Tervalidasi" **hanya**
untuk topik yang ada di `SIGNOFF.md`; versi & changelog siap.

### Senin 2 – Selasa 3 Nov — PR #45 `perbaikan/isu-ronde-1`

Habiskan semua isu `frontend` dari uji penerimaan PJ ronde 1. Satu PR per isu kalau
menyentuh kalkulasi; boleh digabung kalau murni tampilan. Setiap isu yang menyentuh angka
**harus** ditutup dengan tes dari CASES, bukan dengan pemeriksaan mata.

### Selasa 3 Nov (sore) — PR #46 `polish/konsistensi-komponen`

1. Spasi: `Space.*` di seluruh layar baru; nol angka mentah.
2. Transisi & animasi konsisten (durasi & kurva dari `design_tokens.dart`, bukan literal).
3. Bandingkan setiap komponen dengan papan `Komponen` di kanvas UI v2; yang menyimpang
   diseragamkan atau papannya diperbarui — salah satu, bukan dibiarkan berbeda.
4. Jalankan `tool/prd_score.sh` terakhir kali sebagai gerbang: **semua kriteria hijau**.

### Rabu 4 Nov — PR #47 `perf/ukuran-dan-waktu-muat`

1. `main.dart.js` sekarang **3,4 MB**. Ukur setelah semua pembersihan; targetkan turun, catat
   angkanya. `flutter build web --release --analyze-size` untuk melihat penyumbang terbesar.
2. Cabut dependensi yang tidak terpakai dari `pubspec.yaml` (audit ulang setelah Minggu 2).
3. Waktu muat Dashboard: ukur dengan DevTools, bandingkan sebelum/sesudah `StatefulShellRoute`
   (Minggu 2 seharusnya sudah memangkas 3 request boot jadi 1).
4. `--source-maps` mati di rilis; `ENABLE_API_LOG` eksplisit `false`.

### Kamis 5 Nov — PR #48 `rilis/cabut-disclaimer` (butuh `SIGNOFF.md`)

Ini PR yang paling mudah salah. Aturannya ketat:

1. Buka `../domain/pajak/sign-off.md`. **Hanya** topik yang tercantum di sana (PPh Final, PPh 21 TER,
   kalender, [PPN]) yang boleh berganti chip.
2. `AppConstants.taxReviewStatus` → `verified`, `taxReviewDate` → tanggal sign-off,
   `taxConfigVersion` → versi konfigurasi yang ditandatangani. Chip jadi
   "Tervalidasi pakar pajak · <tanggal>" (E1).
3. Topik yang **tidak** ada di `SIGNOFF.md` tetap memakai chip "Perkiraan". Kalau
   `DsTrustChip` dari Minggu 1 dibuat per-topik (dan seharusnya begitu), ini cukup data, bukan
   kode.
4. Disclaimer permanen (teks final dari PJ) tetap tampil di kaki hasil — yang dicabut adalah
   peringatan "belum ditinjau", bukan disclaimer itu sendiri.
5. **Tanpa `SIGNOFF.md` lengkap, PR ini tidak boleh digabung.** Tidak ada pengecualian; ini
   hak veto PJ.

### Kamis 5 Nov (sore) — PR #49 `rilis/versi-changelog`

1. `app/pubspec.yaml`: `version: 1.0.0+1` → `2.0.0+N`. Versi ini **tidak pernah naik** sejak
   awal proyek (P-11) — mulai sekarang naik setiap rilis.
2. Buat `CHANGELOG.md` di root: bagian `## 2.0.0 — 2026-11-13` dengan Pembukuan v2,
   Simulator v2, angka tervalidasi, backend nyata, UI v2. Kelompokkan per pengguna, bukan
   per temuan T-.
3. Verifikasi `version.json` yang tayang mencerminkan versi baru setelah deploy.
4. PR untuk `publish-web.yml` mode `api`
   (`--dart-define=API_BASE_URL=${{ vars.API_BASE_URL }} --dart-define=DATA_SOURCE=api`,
   `ENABLE_API_LOG=false`) — **buat di cabang, jangan gabung minggu ini.** Digabung Minggu 9.

### ✅ Checklist akhir Minggu 8 (M4)

- [ ] Nol isu `🔴` terbuka
- [ ] Skor PRD: **12 dari 12 kriteria hijau**
- [ ] Chip "Tervalidasi" hanya untuk topik ber-sign-off
- [ ] `version: 2.0.0+N`, `CHANGELOG.md` ada
- [ ] Ukuran bundle & waktu muat tercatat (sebelum vs sesudah)
- [ ] PR mode `api` siap di cabang, belum digabung

---

# Minggu 9 — 9–13 November — Regresi, rilis, pemantauan · **M5**

**Aturan minggu ini:** FE **tidak** menguji karyanya sendiri. Regresi manual penuh dijalankan
**BE** memakai `../panduan/checklist-regresi-ui.md`; FE memperbaiki. Inilah yang seharusnya menangkap
T-19 dan T-20 dulu (P-4).

### Senin 9 – Selasa 10 Nov — Regresi

- BE menjalankan `../panduan/checklist-regresi-ui.md` penuh di staging, di tiga lebar & dua mode.
- FE memperbaiki temuan **saat itu juga**, satu PR per temuan, prioritas pemblokir dulu.
- FE **tidak** menambah fitur minggu ini. Isu baru → Fase Tiga, kecuali 🔴.

### Rabu 11 Nov — Go / no-go

1. PO memutuskan berdasarkan checklist rilis `alur-kerja.md` §8.1.
2. FE menyiapkan: build rilis dari `main` yang sudah hijau, ukuran bundle final, catatan
   perubahan, dan **rencana rollback yang sudah dilatih** (Minggu 2).
3. Konfirmasi terakhir: PJ sudah sign-off regulasi di isu rilis (hak veto).

### Kamis 12 Nov — Persiapan rilis

1. Gabung PR `publish-web.yml` mode `api` dari Minggu 8.
2. Build rilis; verifikasi di staging bahwa mode `api` benar-benar menunjuk ke produksi BE.
3. Majukan branch `backup(stable-version)` ke `v1.x` terakhir — titik kembali kalau rilis
   bermasalah.

### Jumat 13 Nov — Rilis

1. PO menekan rilis; publikasi menunggu CI (H-2 Minggu 1 memastikan ini).
2. Verifikasi `version.json` di produksi menunjukkan `2.0.0+N`.
3. Tag `v2.0.0` dan push tag.
4. Smoke test produksi bersama BE dari perangkat berbeda: login → catat transaksi →
   simulator → ekspor.
5. **Siaga 48 jam** untuk isu `ui`. Hotfix mengikuti prosedur `alur-kerja.md` §8.3 — bukan
   push langsung ke `main`.
6. Retrospektif 30 menit bersama tim.

### ✅ Checklist akhir Minggu 9 (M5 — RILIS)

- [ ] Regresi dijalankan BE, bukan FE; semua temuan tertutup
- [ ] `v2.0.0` tertag, `version.json` produksi cocok
- [ ] Mode `api` menunjuk produksi, `ENABLE_API_LOG` mati
- [ ] `backup(stable-version)` menunjuk ke versi stabil sebelumnya
- [ ] Smoke test produksi lulus dari ≥ 2 perangkat
- [ ] Siaga 48 jam aktif

---

# Lampiran A — Peta temuan → minggu (khusus FE)

| Temuan | Prioritas | Minggu | PR |
| --- | --- | --- | --- |
| T-17 chip perkiraan (hotfix) | 🔴 | 1 | #1 |
| T-42 publikasi menunggu CI | 🔴 | 1 | #2 |
| T-29 `sync_build.sh` menghapus dotfile | 🔴 | 1 | #3 |
| T-16 + T-24 fallback hybrid | 🔴 | 1 | #5 |
| T-18 loop onboarding | 🔴 | 1 | #6 |
| T-19 `go`+`pop` GoError | 🔴 | 1 | #7 |
| T-22 `ApiException` tak ditangani | 🟡 | 1 | #8 |
| P-12 dokumen drift | — | 1 | docs |
| T-32 + T-14 kode yatim | 🟡 | 2 | #9 |
| T-20a `TxListTile` abaikan `onTap` | 🔴 | 2 | #9 |
| T-9 + T-10 format & coverage | 🟡 | 2 | #10 |
| T-37 kebersihan lapisan data | 🟡 | 2 | #11 |
| T-28 logger membocorkan token | 🟡 | 2 | #11 |
| T-23 refresh token | 🔴 | 2 | #12 |
| T-27 + T-38 shell & router | 🟡 | 2 | #13 |
| T-20b edit transaksi palsu | 🔴 | 2 | #14 |
| R-7 pecah `accounting_screen` | — | 3 | #15–16 |
| R-3 migrasi tema & token | — | 3 | #17–21 |
| T-33 notifikasi palsu | 🟡 | 3 | #24 |
| R-8 + T-41 satu kalender, nama bulan | — | 4 | #25 |
| R-4 responsif & nav rail | — | 4 | #26 |
| R-5 `showDialog` ≤ 4 | — | 4 | #27 |
| T-39 bug logika Pembukuan | 🟡 | 4 | #30 |
| T-40 target sentuh (Pembukuan) | 🟡 | 4 | #30 |
| T-1 TER B & C | 🔴 | 5 | #31 |
| T-3 + T-26 PPh Final | 🔴 | 5 | #32 |
| T-17 percabangan rezim (penuh) | 🔴 | 5 | #33 |
| T-25 tanggal & hitung mundur | 🔴 | 5 | #34 |
| R-6 + T-35 simulator dari Pembukuan | 🟡 | 5 | #35 |
| T-34 nominal kewajiban | 🟡 | 5 | #36 |
| T-36 PPN & tarif tak terpakai | 🟡 | 5 | #36 |
| T-30 kontras | 🟡 | 7 | #41 |
| T-40 semantik & keyboard (sisa) | 🟡 | 7 | #42 |
| T-8 + R-9 + R-10 aksesibilitas | 🟨 | 7 | #42–44 |

# Lampiran B — Target skor PRD per minggu

Angka yang **tidak boleh naik**. `tool/prd_score.sh` menegakkan ini (blocking sejak Minggu 3).

| Kriteria | Target akhir | Sekarang | M1 (25 Sep) | M2 (9 Okt) | M3 (23 Okt) | M4 (6 Nov) |
| --- | --- | --- | --- | --- | --- | --- |
| `BoxShadow` | 0 | 6 | ≤ 4 | ≤ 2 | 0 | 0 |
| `showDialog` | ≤ 4 | 9 | ≤ 7 | **≤ 4** | ≤ 4 | ≤ 4 |
| Breakpoint literal | 0 | 3 | ≤ 2 | **0** | 0 | 0 |
| `monospace` | 0 | 2 | 2 | **0** | 0 | 0 |
| Token warna | ≤ 16 | 64 | 64 | **≤ 16** | ≤ 16 | ≤ 16 |
| Kelas widget privat | < 40 | 90 | ≤ 60 | ≤ 45 | **< 40** | < 40 |
| `accounting_screen.dart` | < 400 | 1.827 | 1.827 | **< 400** | < 400 | < 400 |
| Berkas logika tanggal | 1 | 4 | 4 | **1** | 1 | 1 |
| `Semantics` grafik & bar | semua | sebagian | sebagian | sebagian | sebagian | **semua** (M7) |
| `withOpacity` | 0 | 0 | 0 | 0 | 0 | 0 |
| Orientasi dibuka web | ya | tidak | **ya** | ya | ya | ya |
| `AppCard` bersarang | 0 | 0 | 0 | 0 | 0 | 0 |

*Kolom "Sekarang" = pengukuran audit 12 Sep atas seluruh `app/lib`. Setelah PR yatim
(Minggu 2), beberapa angka turun tanpa usaha tambahan — catat sebagai efek penghapusan,
jangan diklaim sebagai perbaikan desain.*

# Lampiran C — Berkas yang paling sering disentuh

Urutkan review dengan hati-hati di berkas ini; hampir semua konflik merge akan terjadi di sini.

| Berkas | Disentuh di minggu |
| --- | --- |
| `core/network/app_router.dart` | 1, 2, 4 |
| `core/network/api_client.dart` | 1, 2 |
| `core/data/hybrid_repositories.dart` | 1 |
| `screens/accounting/accounting_screen.dart` | 1, 3, 4 |
| `screens/dashboard/dashboard_screen.dart` | 1, 4, 5 |
| `screens/simulator/tax_conversation_tab.dart` | 1, 5 |
| `core/services/simulator_service.dart` | 4, 5 |
| `core/theme/design_tokens.dart` | 1, 3, 4, 7 |
| `widgets/accounting/tx_add_sheet.dart` | 2, 4, 7 |

**Aturan:** kalau dua PR akan menyentuh berkas yang sama di minggu yang sama, gabungkan
urutannya (selesaikan satu, rebase yang lain), jangan kerjakan paralel di dua cabang.
