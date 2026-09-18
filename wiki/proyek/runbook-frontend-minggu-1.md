---
title: Runbook Frontend — Minggu 1
description: "Langkah harian Minggu 1 (14–18 Sep 2026): perintah git, prompt Claude Code siap tempel, daftar periksa manual, dan perintah verifikasi untuk tiap PR."
tags:
  - proyek
  - frontend
  - runbook
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

# Runbook Frontend — Minggu 1 (14–18 September 2026)

**Versi:** 1.0 · **Dibuat:** 12 September 2026 · **Untuk:** Frontend Engineer, 1 orang
**Induk:** [`rencana-frontend.md`](rencana-frontend.md) §Minggu 1 · **Sumber temuan:** [`backlog-teknis.md`](backlog-teknis.md)
**Alat:** Claude Code (CLI) di repo `catatin-git`, cabang kerja dari `main`

> **Apa ini.** `rencana-frontend.md` menjawab *apa* dan *kapan*. Dokumen ini menjawab *persis
> bagaimana*: perintah git yang dijalankan, prompt yang ditempel ke Claude Code,
> berkas yang berubah, apa yang **wajib diperiksa manusia** setelah AI selesai, dan
> perintah verifikasi sebelum push. Setiap PR punya satu blok lengkap.
>
> Semua nomor baris di dokumen ini sudah diverifikasi terhadap kode per 12 Sep 2026.
> Kalau tidak cocok saat kamu membukanya, kode sudah berubah — baca ulang sebelum edit.

---

## English summary

Eight PRs in five days, all pure-frontend or CI — none of them waits on the backend
engineer or the tax expert. Three ship to production (the trust chip on live tax numbers,
the CI gate on publishing, the build script that currently deletes developer dotfiles).
Five fix data-layer and navigation bugs the audit rated 🔴.

Each PR block below gives: the branch command, a ready-to-paste Claude Code prompt written
in Indonesian (to match the codebase's comment language), the exact files and line numbers
involved, a human review checklist of the things an AI reliably gets wrong on this
codebase, the verification commands, and the one-line progress-log entry to append.

The governing rule for the week: **the AI writes, you verify against the real behaviour.**
Four of these eight findings exist *because* code looked correct and was never clicked
through. Do not merge anything on this list without running it.

---

## Hari 0 — Minggu 13 Sep (±90 menit) — Persiapan

Kerjakan ini sebelum Senin pagi. Kalau dikerjakan Senin, Senin habis untuk setup.

### 0.1 Samakan versi Flutter dengan CI

CI memakai **3.44.8** (`.github/workflows/ci.yml`). Catatan log 8 Sep: analyzer lokal versi
berbeda membuat PR #3 hijau lokal tapi merah di CI. Ini pemborosan yang bisa dicegah sekali.

```bash
flutter --version                 # kalau bukan 3.44.8, ganti
# fvm (disarankan):
dart pub global activate fvm
fvm install 3.44.8
fvm use 3.44.8
# lalu pakai `fvm flutter …` di semua perintah di bawah, atau set alias.
```

### 0.2 Klon & baseline

```bash
cd ~/Projects
git clone https://github.com/piambak/catatin.git catatin-git
cd catatin-git/app
flutter pub get
flutter analyze          # catat angkanya: 0 error / 0 warning / ~39 info
flutter test             # catat: 39 lulus, 1 di-skip
flutter build web --release --base-href "/catatin/"
```

Simpan keempat angka itu. Setiap PR minggu ini dibandingkan dengan baseline ini.

### 0.3 Buat `CLAUDE.md` di root repo — **ini langkah terpenting hari ini**

Tanpa berkas ini, setiap sesi Claude Code harus kamu jelaskan ulang aturan proyeknya, dan
ia akan menebak yang salah: menulis komentar bahasa Inggris, memakai `AppColors` yang mau
dihapus, menyentuh berkas build di root, atau memperbaiki tiga temuan sekaligus dalam satu
PR.

**Prompt 0 — tempel ke Claude Code di root repo:**

```
Buat berkas CLAUDE.md di root repo ini. Isinya konteks tetap untuk setiap sesi
coding di repo Catatin. Baca dulu README.md, ../panduan/kontribusi.md, ../arsitektur/gambaran-umum.md,
../desain/design-tokens.md, dan app/lib/core/theme/design_tokens.dart supaya isinya akurat.

CLAUDE.md harus memuat, ringkas dan dalam Bahasa Indonesia:

1. Struktur repo: kode Flutter ada di app/, hasil build web ada di ROOT repo dan
   digenerate otomatis oleh workflow "Publikasi web" — JANGAN PERNAH menyunting
   main.dart.js, index.html, assets/, canvaskit/, flutter_bootstrap.js di root.
2. Bahasa: semua komentar kode, pesan commit, judul PR, dan teks UI dalam Bahasa
   Indonesia. Kode (nama variabel, kelas) tetap Inggris.
3. Sistem tema: ada DUA sistem yang hidup berdampingan. DS/Typo/Space/Radii di
   app/lib/core/theme/design_tokens.dart adalah sistem BARU dan satu-satunya yang
   boleh dipakai di kode baru. AppColors/AppTextStyles di app/lib/core/theme/app_theme.dart
   adalah sistem LAMA yang akan dihapus di Minggu 3 — jangan tambah pemakaian baru.
4. Jangan pernah pakai warna literal (Color(0xFF...)), angka spasi mentah, atau
   withOpacity. Pakai token: DS.*, Space.x1..x7, Radii.*, dan .withValues(alpha:).
5. Satu PR = satu temuan. Jangan memperbaiki masalah lain yang kebetulan terlihat;
   laporkan saja di akhir jawabanmu sebagai "Temuan sampingan (tidak saya ubah)".
6. Perintah verifikasi wajib sebelum selesai:
   cd app && flutter analyze && flutter test && flutter build web --release
7. Versi Flutter yang benar 3.44.8 (samakan dengan .github/workflows/ci.yml).
8. Dokumen proses: alur-kerja.md (peran & Definition of Done),
   linimasa.md (jadwal), wiki/rencana-frontend.md (rencana frontend),
   backlog-teknis.md (daftar temuan T-1..T-42).
9. Daftar jebakan yang sudah diketahui di repo ini, satu baris masing-masing:
   - core/data/hybrid_repositories.dart menelan semua ApiException (T-16, T-24)
   - core/network/api_client.dart: refresh token tidak aman untuk request bersamaan (T-23)
   - core/network/app_router.dart: MainShell mengabaikan parameter child (T-27)
   - screens/accounting/accounting_screen.dart 1.827 baris, akan dipecah Minggu 3 (R-7)
   - widgets/accounting/month_picker.dart: TxListTile mengabaikan onTap (T-20)

Tulis padat — maksimal 120 baris. Jangan mengarang isi yang tidak ada di berkas
yang kamu baca; kalau ragu, tanya saya.
```

Setelah Claude selesai: **baca sendiri** hasilnya sebelum commit. Berkas ini akan
memengaruhi setiap sesi minggu ini.

```bash
git checkout -b wiki/claude-md
git add CLAUDE.md && git commit -m "docs: konteks tetap Claude Code (CLAUDE.md)"
git push -u origin wiki/claude-md
```

### 0.4 Label & papan (kalau PO belum membuatnya)

```bash
gh label create frontend  --color 1D76DB
gh label create backend   --color 0E8A16
gh label create pajak     --color D93F0B
gh label create ui        --color FBCA04
gh label create kontrak   --color 5319E7
gh label create hotfix    --color B60205
```

---

## Kalender minggu

| Hari | Slot | PR | Temuan | Est. | Tayang produksi? |
| --- | --- | --- | --- | --- | --- |
| Sen 14 | pagi | **#1** chip "Perkiraan" | 🔴 T-17 | 3 j | **ya** |
| Sen 14 | sore | **#2** publikasi menunggu CI | 🔴 T-42 | 1,5 j | **ya** |
| Sel 15 | pagi | **#3** `sync_build.sh` aman | 🔴 T-29 | 2 j | **ya** |
| Sel 15 | sore | **#4** `tool/prd_score.sh` | — | 2 j | tidak |
| Rab 16 | pagi | **#5** fallback hybrid | 🔴 T-16, T-24 | 3 j | tidak |
| Rab 16 | sore | **#6** loop onboarding | 🔴 T-18 | 2 j | tidak |
| Kam 17 | pagi | **#7** navigasi `push` | 🔴 T-19 | 2,5 j | tidak |
| Kam 17 | sore | **#8** `ErrorState` 4 layar | 🟡 T-22 | 2 j | tidak |
| Jum 18 | pagi | **#9** dokumen drift | P-12 | 1,5 j | — |
| Jum 18 | siang | tinjau kanvas UI v2 + sinkron **M0** | — | 2 j | — |

Total ±22 jam kerja. Sisanya buffer — dan minggu ini **akan** butuh buffer, karena tiga PR
tayang ke produksi dan produksi selalu punya kejutan.

---

## Aturan vibecoding untuk repo ini

Delapan PR ini dikerjakan dengan Claude Code. Yang membuatnya berhasil atau gagal bukan
kualitas promptnya, tapi apa yang kamu periksa setelahnya.

**Pola satu PR:**

1. `git checkout -b <cabang>` — **selalu** cabang baru sebelum memanggil Claude.
2. Tempel prompt. Biarkan Claude membaca berkas sendiri; jangan tempel kode ke prompt
   (ia punya akses berkas, dan kode yang ditempel cepat basi).
3. Baca diff sendiri: `git diff`. Bukan sekadar melihat — baca.
4. Jalankan verifikasi (perintah ada di tiap blok).
5. **Klik aplikasinya.** Empat dari delapan temuan minggu ini ada justru karena kode
   terlihat benar dan tidak pernah diklik.
6. Commit, push, buka PR, minta review peran lain.

**Empat kesalahan yang konsisten dilakukan AI di repo ini** — periksa keempatnya tiap PR:

| Kesalahan | Cara mendeteksi |
| --- | --- |
| Memakai `AppColors`/`AppTextStyles` (sistem lama) di kode baru | `git diff \| grep -n "AppColors\|AppTextStyles"` — harus kosong untuk kode baru |
| Menambahkan warna/angka literal alih-alih token | `git diff \| grep -nE "Color\(0xFF\|EdgeInsets.all\([0-9]"` |
| Memperbaiki temuan lain sekaligus (PR jadi campur) | `git diff --stat` — berkas di luar daftar "Berkas yang berubah" = tanda bahaya |
| Menulis komentar dalam Bahasa Inggris | `git diff \| grep "^+.*//"` — baca sekilas |

**Satu kesalahan yang lebih berbahaya:** Claude cenderung *menambahkan* penanganan error,
bukan **mempersempit** penangkapan error. Di PR #5 yang dibutuhkan justru kebalikannya —
lebih sedikit yang ditangkap. Kalau diff-nya bertambah `try/catch`, kemungkinan besar
salah arah.

---

# SENIN 14 SEPTEMBER

## PR #1 — Chip "Perkiraan · belum ditinjau pakar pajak" 🔴 T-17

**Kenapa ini yang pertama.** Situs publik saat ini menampilkan panel berlabel
**"Perkiraan pajak Anda"** (`tax_conversation_tab.dart:434`) dengan tarif TER yang
diketahui salah untuk kategori B dan C (T-1), dihitung dengan `calculatePPh21` bahkan untuk
persona "Pedagang online" dan "Driver / kurir" yang seharusnya PPh Final (T-17) — dan
**tanpa satu pun peringatan**. Dashboard juga menyebut "PP 23/2018" seolah angkanya sudah
diverifikasi (`dashboard_screen.dart:394-397`).

Komentar di kode bahkan mengakuinya (`tax_conversation_tab.dart:24-26`):
*"jawaban ini tidak memengaruhi hasil hitung — sama seperti di mockup"*. Pengguna tidak
membaca komentar kode.

Perbaikan rezim yang sebenarnya dijadwalkan Minggu 5 (butuh SPEC dari PJ). Yang bisa
dilakukan **hari ini** adalah berhenti mengklaim angka ini benar.

### Berkas yang berubah

| Berkas | Perubahan |
| --- | --- |
| `app/lib/core/constants/app_constants.dart` | + `taxReviewStatus`, `taxReviewDate`, `taxReviewNote` |
| `app/lib/widgets/common/ds_widgets.dart` | + kelas `DsTrustChip` (sistem baru, di samping `DsStatusPill` yang sudah ada di baris 30) |
| `app/lib/core/theme/design_tokens.dart` | + token `DS.warnBg` / `DS.warnFg` bila belum ada |
| `app/lib/screens/simulator/tax_conversation_tab.dart` | pasang chip di panel hasil (±baris 434) |
| `app/lib/screens/dashboard/dashboard_screen.dart` | pasang chip di blok "Kewajiban berikutnya" (±baris 382) |

> **Catatan yang menghemat waktumu:** `SimDisclaimer` **sudah ada** dan hidup di
> `app/lib/widgets/simulator/sim_widgets.dart:310`; ia dipakai di `pph21_tab.dart:187` tapi
> **tidak dibawa** ke `tax_conversation_tab.dart`. Jangan membuat ulang. Tapi jangan pula
> memakainya di tab baru: `sim_widgets.dart` masih sistem tema lama (`AppColors`) dan akan
> bermigrasi Minggu 3. Tab baru pakai `DsTrustChip` yang berbasis `DS`.

### Perintah

```bash
cd ~/Projects/catatin-git
git checkout main && git pull
git checkout -b hotfix/T-17-chip-perkiraan
```

### Prompt Claude Code

```
Konteks: temuan T-17 di backlog-teknis.md. Aplikasi menampilkan hasil
perhitungan pajak sebagai fakta, padahal tarifnya belum ditinjau pakar pajak dan
untuk sebagian persona memakai rezim yang salah. Tugasmu HANYA menambahkan penanda
kepercayaan yang jujur — JANGAN mengubah satu pun perhitungan pajak.

Baca dulu:
- app/lib/widgets/common/ds_widgets.dart (lihat pola DsStatusPill di baris 30 dan
  DsLabel di baris 17 — ikuti gaya penulisan kelas yang sama)
- app/lib/core/theme/design_tokens.dart (token DS, Space, Radii, Typo)
- app/lib/screens/simulator/tax_conversation_tab.dart (panel hasil, sekitar baris 412-450)
- app/lib/screens/dashboard/dashboard_screen.dart (blok "Kewajiban berikutnya",
  sekitar baris 375-412)
- app/lib/widgets/simulator/sim_widgets.dart baris 310 (SimDisclaimer yang sudah ada —
  JANGAN dipakai dan JANGAN diubah, hanya untuk referensi nada bahasa)

Yang saya minta:

1. Di app/lib/core/constants/app_constants.dart, di dalam class AppConstants, tambahkan:
     static const taxReviewStatus = 'draft';   // 'draft' | 'verified'
     static const taxReviewDate   = '';        // diisi saat sign-off pakar (Minggu 8)
   Beri komentar singkat bahwa Minggu 8 cukup mengubah dua baris ini.

2. Di app/lib/widgets/common/ds_widgets.dart, tambahkan:
     enum TrustLevel { draft, verified }
     class DsTrustChip extends StatelessWidget { const DsTrustChip({super.key, this.level}); ... }
   - Kalau `level` tidak diberikan, turunkan dari AppConstants.taxReviewStatus.
   - draft   → teks "Perkiraan · belum ditinjau pakar pajak", ikon info kecil
   - verified→ teks "Tervalidasi pakar pajak · <AppConstants.taxReviewDate>", ikon centang
   - Ukuran teks 12-13, padding pakai Space.*, radius pakai Radii.pill.
   - WAJIB punya Semantics label yang membaca teks lengkapnya.
   - Chip harus terbaca di atas DUA latar: latar terang biasa (Dashboard) dan latar
     gelap DS.invSurface (panel hasil Simulator). Tambahkan parameter
     `bool onDark = false` dan pilih pasangan warna yang sesuai.

3. Kalau token warna peringatan belum ada di design_tokens.dart, tambahkan
   DS.warnBg dan DS.warnFg untuk mode terang dan gelap, mengikuti pola getter yang
   sudah dipakai token lain di berkas itu. Rasio kontras teks terhadap latarnya
   harus >= 4,5:1 di kedua mode — sebutkan rasio yang kamu pilih di jawabanmu.

4. Pasang `const DsTrustChip(onDark: true)` di tax_conversation_tab.dart, di dalam
   panel hasil, TEPAT DI BAWAH DsLabel('Perkiraan pajak Anda') di baris 434 —
   sebelum angkanya, bukan di kaki panel.

5. Pasang `const DsTrustChip()` di dashboard_screen.dart di blok "Kewajiban berikutnya",
   di bawah DsLabel('Kewajiban berikutnya') di baris 382.

Batasan keras:
- Jangan menyentuh app/lib/core/services/simulator_service.dart sama sekali.
- Jangan mengubah SimDisclaimer atau pph21_tab.dart.
- Jangan memakai AppColors/AppTextStyles — hanya DS/Typo/Space/Radii.
- Jangan pakai Color(0xFF...) langsung di luar design_tokens.dart.
- Komentar dalam Bahasa Indonesia.

Terakhir, jalankan: cd app && flutter analyze && flutter test
dan laporkan hasilnya apa adanya.
```

### Yang wajib kamu periksa sendiri

- [ ] Chip **di atas** angka, bukan di kaki panel. Peringatan di bawah lipatan layar tidak
      dibaca siapa pun.
- [ ] Kontras di panel gelap (`DS.invSurface` = `#0D1B2A`). Ukur, jangan kira-kira —
      pakai ekstensi kontras atau [webaim.org/resources/contrastchecker](https://webaim.org/resources/contrastchecker/).
- [ ] Chip tidak memotong teks di lebar 375 px (uji `flutter run -d chrome` lalu kecilkan
      jendela, atau emulator ponsel).
- [ ] `git diff --stat` — hanya 5 berkas. Kalau `simulator_service.dart` ikut berubah,
      **batalkan dan ulangi**: itu perubahan perhitungan pajak, dan FE tidak berwenang
      (`alur-kerja.md` §2).

### Verifikasi

```bash
cd app
flutter analyze                       # 0 error, 0 warning
flutter test                          # 39 lulus, 1 skip — jumlah tidak boleh turun
flutter run -d chrome                 # buka Simulator & Dashboard, terang + gelap
flutter build web --release --base-href "/catatin/"
```

Ambil 4 tangkapan layar: Simulator terang, Simulator gelap, Dashboard terang,
Dashboard gelap.

### PR

```bash
git add -A
git commit -m "T-17: chip kepercayaan pada hasil pajak yang belum ditinjau pakar

Panel hasil Simulator dan blok kewajiban Dashboard menampilkan angka sebagai
fakta padahal tarif TER kategori B/C belum benar (T-1) dan persona usaha sendiri
masih dihitung dengan rezim PPh 21 (T-17). Chip DsTrustChip menyatakan statusnya
sampai sign-off pakar di Minggu 8, yang cukup mengubah AppConstants.taxReviewStatus.

Tidak ada perhitungan pajak yang diubah."
git push -u origin hotfix/T-17-chip-perkiraan
gh pr create --label hotfix,frontend,pajak --title "T-17: chip kepercayaan pada hasil pajak" --body-file -
```

Isi bagian **Cara mengujinya** di template PR dengan:
`cd app && flutter run -d chrome` → Simulator, jawab 3 pertanyaan → chip terlihat di atas
angka → ulangi di mode gelap → Dashboard, blok "Kewajiban berikutnya".

### Log Progres (tambahkan ke `linimasa.md` Lampiran B, di PR yang sama)

```
- **2026-09-14** — Frontend — PR #1 — T-17 (sebagian): DsTrustChip di panel hasil Simulator & blok kewajiban Dashboard. Dampak: situs tidak lagi menyajikan angka yang belum ditinjau sebagai fakta; percabangan rezim menyusul Minggu 5. Tes: 39+1 skip (tidak berubah). Analyze 0/0. Build ✓.
```

### Setelah tergabung

Tunggu deploy, buka [piambak.github.io/catatin](https://piambak.github.io/catatin/), ambil
tangkapan layar **produksi**, tempel di PR. Lalu buka isu `pajak` berjudul
"Teks resmi chip kepercayaan (E1)" dan mention PJ — teks final adalah wewenang mereka
(`alur-kerja.md` §2), yang kamu pasang hari ini adalah teks sementara dari kanvas.

---

## PR #2 — Publikasi menunggu CI 🔴 T-42

**Masalahnya, dalam satu kalimat:** `ci.yml` dan `publish-web.yml` sama-sama dipicu
`push: branches: [main]`, **tanpa hubungan apa pun di antara keduanya** — jadi commit yang
tesnya merah tetap tayang ke publik. Verifikasi sendiri: `publish-web.yml` baris 15–22
tidak punya `needs:` maupun `workflow_run:`.

Masalah kedua: langkah "Commit" (baris ±74–81) melakukan `git push` tanpa `git pull --rebase`.
Dua merge berurutan ke `main` = push kedua gagal non-fast-forward, dan publikasi diam-diam
tidak jalan.

### Berkas yang berubah

`.github/workflows/publish-web.yml` — **hanya** berkas ini.

### Perintah

```bash
git checkout main && git pull
git checkout -b hotfix/T-42-publish-setelah-ci
```

### Prompt Claude Code

```
Konteks: temuan T-42 di backlog-teknis.md. Workflow publikasi web berjalan
paralel dengan CI, bukan setelahnya, sehingga commit yang tesnya gagal tetap tayang
ke GitHub Pages.

Baca .github/workflows/ci.yml dan .github/workflows/publish-web.yml lebih dulu.

Ubah .github/workflows/publish-web.yml saja:

1. Ganti pemicu `on: push: branches: [main]` menjadi `workflow_run` yang menunggu
   workflow bernama "CI" selesai di branch main. Pertahankan `workflow_dispatch`.
2. Tambahkan penjaga di level job: hanya jalan kalau
   github.event.workflow_run.conclusion == 'success' — ATAU kalau pemicunya
   workflow_dispatch manual. Tulis kondisinya supaya dispatch manual tetap bisa dipakai
   untuk rilis darurat.
3. Karena workflow_run selalu checkout default branch pada commit terbaru, pastikan
   langkah actions/checkout mengambil commit yang BENAR-BENAR diuji CI:
   gunakan `ref: ${{ github.event.workflow_run.head_sha }}` saat pemicunya workflow_run.
   Jelaskan dalam komentar kenapa ini perlu.
4. Di langkah "Commit", tambahkan `git pull --rebase origin main` sebelum `git push`,
   dan tambahkan satu kali percobaan ulang kalau push gagal. Jelaskan dalam komentar
   bahwa ini mencegah kegagalan non-fast-forward saat dua PR digabung berurutan.
5. Pertahankan seluruh komentar Bahasa Indonesia yang sudah ada di berkas itu, termasuk
   penjelasan soal setting GitHub Pages dan 403. Jangan menghapus konteks yang ada.
6. Jangan ubah .github/workflows/ci.yml.
7. Jangan ubah versi Flutter (3.44.8 di kedua berkas harus tetap sama).

Setelah selesai, tampilkan berkas hasilnya secara utuh dan jelaskan dalam 3 kalimat
apa yang berubah pada urutan eksekusinya.
```

### Yang wajib kamu periksa sendiri

- [ ] `ref: head_sha` benar-benar ada. Ini yang paling sering dilewatkan, dan tanpa itu
      kamu memublikasikan commit yang berbeda dari yang diuji — bug yang sangat sulit
      dilacak nanti.
- [ ] Nama workflow di `workflows: ["CI"]` **persis** sama dengan `name:` di `ci.yml`
      (`CI`, huruf besar semua). Salah satu huruf = tidak pernah jalan, tanpa error.
- [ ] `workflow_dispatch` masih ada. Kamu akan membutuhkannya minggu ini.
- [ ] Komentar lama tidak dihapus.

### Verifikasi — **wajib, jangan lewati**

```bash
git push -u origin hotfix/T-42-publish-setelah-ci
# Gabungkan PR-nya lebih dulu, lalu uji di cabang sekali pakai:
git checkout main && git pull
git checkout -b uji/ci-gate
# Rusak satu tes dengan sengaja:
sed -i 's/expect(1, 1)/expect(1, 2)/' app/test/simulator_service_test.dart   # sesuaikan
git commit -am "uji: sengaja merah" && git push -u origin uji/ci-gate
gh pr create --title "UJI — jangan gabung" --body "Menguji gerbang CI. Akan ditutup."
```

Buka PR itu → CI harus merah → **publikasi tidak boleh jalan**. Tutup PR, hapus cabang:

```bash
gh pr close --delete-branch
```

### Log Progres

```
- **2026-09-14** — Frontend — PR #2 — T-42 selesai: publish-web.yml dipicu workflow_run setelah CI sukses, checkout head_sha yang diuji, git pull --rebase sebelum push. Dampak: commit dengan tes merah tidak bisa lagi tayang. Diuji dengan PR sengaja-merah. Analyze 0/0. Build ✓.
```

---

# SELASA 15 SEPTEMBER

## PR #3 — `sync_build.sh` berhenti menghapus berkas pengembang 🔴 T-29

**Masalahnya.** `tool/sync_build.sh` baris 56–64 menjalankan `shopt -s dotglob` lalu
`rm -rf` pada **semua** isi root yang tidak ada di daftar `KEEP` (baris 18–32). `dotglob`
berarti dotfile ikut: `.vscode`, `.idea`, `.env`, folder scratch, apa pun. Di CI ini tidak
terasa (runner sekali pakai). Di mesin pengembang, ini menghapus pekerjaan.

`tool/build_web.ps1` baris ±67–70 punya masalah yang sama di Windows — dan ini yang kamu
pakai sehari-hari.

Skripnya sudah punya pemeriksaan keamanan yang bagus (baris 34–46: cek `pubspec.yaml`, cek
`build/web` ada, cek `index.html` ada). Yang kurang: ia tidak tahu berkas mana yang
**miliknya sendiri**.

### Berkas yang berubah

`tool/sync_build.sh`, `tool/build_web.ps1`, `../panduan/rilis-dan-deploy.md`, `.gitignore`

### Perintah

```bash
git checkout main && git pull
git checkout -b hotfix/T-29-sync-build-aman
```

### Prompt Claude Code

```
Konteks: temuan T-29 di backlog-teknis.md. tool/sync_build.sh menghapus semua
isi root repo yang tidak ada di daftar KEEP, termasuk dotfile, sehingga di mesin
pengembang bisa menghapus .env, .vscode, .idea, dan folder kerja pribadi tanpa
peringatan. tool/build_web.ps1 punya masalah yang sama.

Baca tool/sync_build.sh, tool/build_web.ps1, tool/build_web.sh, dan ../panduan/rilis-dan-deploy.md.

Ganti strateginya dari "hapus semua yang tidak di-KEEP" menjadi "hapus hanya yang
saya buat sendiri sebelumnya":

1. Setelah menyalin hasil build ke root, tulis manifes tool/.last_build_files berisi
   daftar path relatif setiap berkas yang disalin, satu per baris, urut.
2. Pada jalan berikutnya, yang boleh dihapus HANYA path yang tercantum di manifes itu
   dan benar-benar masih ada. Daftar KEEP tetap dipertahankan sebagai lapisan kedua
   (jangan pernah hapus apa pun yang ada di KEEP, walau tercantum di manifes).
3. Kalau manifes belum ada (pemakaian pertama, atau klon baru), JANGAN menghapus apa pun
   — cukup salin dan tulis manifes. Cetak peringatan bahwa pembersihan dilewati.
4. Tambahkan mode kerja:
   - default: dry-run. Cetak daftar berkas yang AKAN dihapus dan disalin, lalu berhenti
     tanpa mengubah apa pun.
   - dengan flag --yes (atau -Yes di PowerShell): benar-benar jalankan.
   - Di GitHub Actions, jangan minta interaksi: kalau variabel lingkungan CI bernilai
     "true", anggap --yes.
5. Pertahankan semua pemeriksaan keamanan yang sudah ada (pubspec.yaml, build/web,
   index.html) dan tolak jalan kalau root bukan repo catatin.
6. Pertahankan `set -euo pipefail` di bash; tambahkan $ErrorActionPreference = 'Stop'
   di PowerShell kalau belum ada.
7. Terapkan perubahan yang setara di build_web.ps1 supaya perilakunya identik di Windows.
8. Tambahkan tool/.last_build_files ke .gitignore.
9. Perbarui ../panduan/rilis-dan-deploy.md: jelaskan flag baru dan bahwa default-nya dry-run.
10. Semua komentar dan pesan di terminal dalam Bahasa Indonesia, ikuti gaya yang sudah
    ada di skrip itu (memakai → dan ✓ dan ✗).

PENTING: .github/workflows/publish-web.yml memanggil `bash tool/sync_build.sh`.
Jangan sampai perubahanmu membuat workflow itu berhenti bekerja — sesuaikan
pemanggilannya di workflow kalau perlu, dan sebutkan di jawabanmu kalau kamu mengubahnya.
```

### Yang wajib kamu periksa sendiri — **uji di klon sekali pakai, bukan di repo kerjamu**

```bash
cd /tmp
git clone ~/Projects/catatin-git uji-sync && cd uji-sync
mkdir -p .vscode && echo '{}' > .vscode/settings.json
echo "API_BASE_URL=rahasia" > .env
mkdir -p coretan && echo "catatan" > coretan/ide.md
cd app && flutter build web --release --base-href "/catatin/" && cd ..

bash tool/sync_build.sh            # harus dry-run, tidak menghapus apa pun
ls -la .env .vscode coretan        # ketiganya HARUS masih ada

bash tool/sync_build.sh --yes      # jalan sungguhan
ls -la .env .vscode coretan        # ketiganya HARUS TETAP ada
ls tool/.last_build_files          # manifes terbentuk

bash tool/sync_build.sh --yes      # jalan kedua, sekarang manifes ada
ls -la .env .vscode coretan        # masih ada
git status                         # output build tersinkron, tidak ada yang hilang
```

Kalau salah satu dari ketiganya hilang, **jangan gabung**. Ulangi prompt dengan
menyebutkan persis apa yang terhapus.

- [ ] Uji juga dari direktori lain: `bash /tmp/uji-sync/tool/sync_build.sh` — skrip harus
      tetap menemukan root sendiri (baris 14 sudah menangani ini; pastikan tidak rusak).
- [ ] Windows: jalankan `tool\build_web.ps1` di klon sekali pakai dengan cara yang sama.
- [ ] `publish-web.yml` masih memanggil skrip dengan benar. Kalau Claude menambahkan
      `--yes` di workflow, pastikan itu memang tertulis.

### Log Progres

```
- **2026-09-15** — Frontend — PR #3 — T-29 selesai: sync_build.sh & build_web.ps1 hanya menghapus berkas dari manifes build sebelumnya, default dry-run, butuh --yes (otomatis di CI). Dampak: skrip build tidak bisa lagi menghapus .env/.vscode/folder kerja di mesin pengembang. Diuji di klon sekali pakai. Analyze 0/0. Build ✓.
```

---

## PR #4 — `tool/prd_score.sh` (pengukur yang menghentikan kemunduran)

**Kenapa perlu.** Dua kriteria PRD **mundur** antara penulisan PRD dan audit:
`BoxShadow` 3 → 6, dan `accounting_screen.dart` 1.731 → 1.827 baris. Tidak ada yang
memperhatikan karena tidak ada yang mengukur. Skrip ini membuat angkanya muncul di setiap
PR.

Minggu ini **non-blocking** — ia hanya mencetak. Blocking mulai Minggu 3, setelah
`accounting_screen.dart` dipecah.

### Berkas yang berubah

`tool/prd_score.sh` (baru), `.github/workflows/ci.yml`

### Perintah

```bash
git checkout main && git pull
git checkout -b perkakas/prd-score
```

### Prompt Claude Code

```
Konteks: ../desain/prd-redesain-ui.md bagian 7 mendefinisikan kriteria terukur untuk
redesain UI. backlog-teknis.md bagian 1 mengukurnya dan menemukan 8 dari 12
gagal, dua di antaranya MUNDUR sejak PRD ditulis karena tidak ada yang mengukur
secara otomatis.

Baca ../desain/prd-redesain-ui.md bagian 7 dan backlog-teknis.md bagian 1 lebih dulu
supaya definisi tiap metrik persis sama dengan yang sudah dipakai audit.

Buat tool/prd_score.sh:

1. Dijalankan dari mana saja; temukan root repo sendiri seperti tool/sync_build.sh
   melakukannya.
2. Ukur, hanya di dalam app/lib:
   - jumlah kemunculan BoxShadow                         (target 0)
   - jumlah kemunculan showDialog                        (target <= 4)
   - breakpoint literal 500 atau 680 di luar core/theme/breakpoints.dart  (target 0)
   - jumlah "fontFamily: 'monospace'"                    (target 0)
   - jumlah anggota warna di class AppColors + class DS  (target <= 16)
   - jumlah kelas widget privat (baris yang diawali "class _")  (target < 40)
   - jumlah baris screens/accounting/accounting_screen.dart     (target < 400)
   - jumlah kemunculan withOpacity                       (target 0)
   - jumlah berkas yang memuat logika tanggal/kalender   (target 1)
3. Cetak tabel sejajar: Metrik | Nilai | Target | status (OK / GAGAL).
4. Flag --strict membuat skrip keluar dengan kode 1 kalau ada metrik yang GAGAL.
   Tanpa flag, selalu keluar 0.
5. Flag --markdown mencetak tabel dalam format Markdown untuk ditempel ke komentar PR.
6. Semua keluaran dalam Bahasa Indonesia.

Lalu tambahkan langkah di .github/workflows/ci.yml yang menjalankan
`bash tool/prd_score.sh --markdown` TANPA --strict (jadi tidak menggagalkan build),
dan menempelkan hasilnya ke ringkasan job lewat $GITHUB_STEP_SUMMARY.
Beri komentar di workflow bahwa --strict akan dinyalakan mulai Minggu 3 sesuai
wiki/rencana-frontend.md.

Terakhir, jalankan skripnya dan tunjukkan keluarannya kepada saya.
```

### Yang wajib kamu periksa sendiri

- [ ] Bandingkan keluaran dengan tabel di `backlog-teknis.md` §1. Angkanya harus **sama
      atau sangat dekat**. Kalau `BoxShadow` melaporkan 2 padahal audit bilang 6,
      skripnya salah, bukan kodenya yang membaik.
- [ ] Skrip tidak menghitung di `app/build/` atau di root repo (output build berisi
      ribuan false positive).
- [ ] Jalankan `bash tool/prd_score.sh --strict; echo $?` → harus `1` sekarang (banyak yang
      gagal). Itu bukti flag-nya bekerja.

Simpan keluaran hari ini di komentar PR dengan judul **"Baseline 15 Sep"**. Inilah angka
yang tidak boleh naik lagi sampai 13 November.

### Log Progres

```
- **2026-09-15** — Frontend — PR #4 — Perkakas: tool/prd_score.sh mengukur 9 kriteria PRD §7 dan menempelkan hasilnya ke ringkasan CI (non-blocking; --strict mulai Minggu 3). Baseline tercatat di PR. Analyze 0/0. Build ✓.
```

---

# RABU 16 SEPTEMBER

## PR #5 — Fallback hybrid berhenti menelan penolakan backend 🔴 T-16 + T-24

**Bug paling berbahaya di repo ini.** `app/lib/core/data/hybrid_repositories.dart` baris
17–26:

```dart
Future<T> _orFallback<T>(
  Future<T> Function() primary,
  Future<T> Function() fallback,
) async {
  try {
    return await primary();
  } on ApiException {        // ← menangkap SEMUA, termasuk 401 dan 422
    return fallback();
  }
}
```

Dipakai untuk `login` di baris 52–55. Jadi: kata sandi salah → backend membalas 401 →
`_orFallback` menangkapnya → memanggil `mock.login()` yang menerima kredensial apa pun →
pengguna **masuk sebagai Budi Santoso**. Itu bukan bug tampilan, itu autentikasi yang
tidak berfungsi.

Hal yang sama di baris 128–137: `createTransaction` dan `deleteTransaction` menelan
penolakan validasi 400/422 dari backend, menulis ke mock in-memory, dan UI melaporkan
"berhasil". Transaksi itu hilang saat halaman dimuat ulang.

**Yang dibutuhkan adalah menangkap LEBIH SEDIKIT, bukan lebih banyak.** Komentar di kepala
berkas sudah menyatakan niat yang benar ("kalau semua endpoint sudah siap, pindah ke
`DATA_SOURCE=api` supaya kegagalan benar-benar kelihatan") — implementasinya yang tidak
mengikuti.

### Berkas yang berubah

| Berkas | Perubahan |
| --- | --- |
| `app/lib/core/data/hybrid_repositories.dart` | `_orFallback` dipersempit; auth tidak pernah fallback; tulis-operasi tidak menelan 4xx |
| `app/lib/core/data/mock_repositories.dart` | komentar penanda "hanya mode mock" di `login` (baris ±43–59) |
| `app/test/hybrid_repositories_test.dart` | **baru** |

### Perintah

```bash
git checkout main && git pull
git checkout -b perbaikan/T-16-T-24-hybrid
```

### Prompt Claude Code

```
Konteks: temuan T-16 dan T-24 di backlog-teknis.md, prioritas tertinggi.

Baca dulu, seluruhnya:
- app/lib/core/data/hybrid_repositories.dart
- app/lib/core/data/repositories.dart (lihat kelas Repos dan setter injeksinya)
- app/lib/core/data/mock_repositories.dart
- app/lib/core/network/api_client.dart baris 13-54 (definisi ApiException; perhatikan
  komentar bahwa statusCode == 0 berarti gagal di level jaringan)

Masalahnya: fungsi _orFallback di baris 17-26 menangkap SEMUA ApiException lalu jatuh
ke implementasi mock. Akibatnya kata sandi salah (401) membuat pengguna masuk sebagai
pengguna demo, dan penolakan validasi backend (400/422) saat membuat transaksi ditelan
lalu dilaporkan berhasil ke pengguna.

ARAH PERBAIKANNYA ADALAH MENANGKAP LEBIH SEDIKIT, BUKAN MENAMBAH PENANGANAN ERROR.
Kalau diff-mu menambah blok try/catch baru, kemungkinan besar kamu salah arah.

Yang saya minta:

1. Ubah _orFallback supaya hanya jatuh ke fallback bila ApiException.statusCode
   bernilai 0 (jaringan mati / timeout), 404, atau 501 — yaitu "endpoint ini belum
   ada atau tidak terjangkau". Semua status lain dilempar ulang apa adanya.
   Jadikan daftar status itu satu konstanta privat ber-nama dengan komentar yang
   menjelaskan alasannya, jangan angka telanjang di dalam if.

2. Tambahkan parameter bernama `bool allowFallback = true` pada _orFallback.
   Untuk SELURUH operasi di HybridAuthRepository (register, login, me), panggil dengan
   allowFallback: false. Auth tidak boleh jatuh ke mock dengan alasan apa pun,
   termasuk jaringan mati — lebih baik pengguna melihat error jaringan daripada
   masuk sebagai orang lain.

3. Untuk createTransaction dan deleteTransaction di HybridTransactionRepository
   (baris 127-137): operasi tulis tidak boleh menulis ke mock ketika backend
   MENOLAK (4xx). Fallback hanya sah kalau backend tidak terjangkau sama sekali.
   Aturan di langkah 1 sudah mencakup ini — pastikan tidak ada jalur lain yang
   melewatinya.

4. Perhatikan HybridBusinessRepository.create dan update (baris 76-93): keduanya
   punya try/catch SENDIRI yang juga menangkap semua ApiException. Pola di sana
   memang disengaja (tulis lokal dulu supaya profil tidak hilang) — pertahankan
   niatnya, tapi samakan syarat fallback-nya dengan langkah 1, dan tulis komentar
   yang menjelaskan kenapa perilakunya berbeda dari transaksi.

5. Di mock_repositories.dart, pada MockAuthRepository.login (sekitar baris 43-59),
   tambahkan komentar Bahasa Indonesia yang menyatakan bahwa metode ini sengaja
   menerima kredensial apa pun dan hanya sah untuk DATA_SOURCE=mock; jangan ubah
   perilakunya.

6. Buat app/test/hybrid_repositories_test.dart dengan tes berikut, memakai fake
   AuthRepository/TransactionRepository sederhana yang kamu tulis sendiri di berkas
   tes itu (jangan tambah dependensi mocking baru ke pubspec.yaml):
   - login: api melempar ApiException(statusCode: 401) → hybrid HARUS melempar,
     dan mock.login TIDAK BOLEH pernah dipanggil
   - login: api melempar ApiException(statusCode: 0) → hybrid TETAP melempar
     (auth tidak pernah fallback)
   - getSummary: api melempar ApiException(statusCode: 0) → hybrid mengembalikan
     hasil mock
   - getSummary: api melempar ApiException(statusCode: 500) → hybrid melempar
   - createTransaction: api melempar ApiException(statusCode: 422) → hybrid melempar,
     dan mock.createTransaction TIDAK dipanggil
   - createTransaction: api melempar ApiException(statusCode: 404) → hybrid memakai mock
   Pakai Repos.reset() di tearDown kalau kelas Repos menyediakannya.

Batasan:
- Jangan ubah app/lib/core/data/api_repositories.dart.
- Jangan ubah pubspec.yaml.
- Jangan mengubah pesan error yang dilihat pengguna di layar login — itu PR lain.
- Komentar dalam Bahasa Indonesia.

Jalankan cd app && flutter analyze && flutter test, dan tunjukkan jumlah tes
sebelum dan sesudah.
```

### Yang wajib kamu periksa sendiri

- [ ] **Baca `_orFallback` yang baru baris demi baris.** Ini sepuluh baris kode yang
      menentukan apakah autentikasi aplikasimu berfungsi.
- [ ] `git diff | grep -c "try {"` — jumlah `try` **tidak boleh bertambah**. Kalau
      bertambah, Claude menambah penanganan error alih-alih mempersempitnya.
- [ ] Semua tiga metode `HybridAuthRepository` (`register`, `login`, `me`) memakai
      `allowFallback: false`. Mudah terlewat pada `me()` di baris 58 yang bentuknya
      berbeda (`_orFallback(api.me, mock.me)`).
- [ ] Tes benar-benar memeriksa bahwa mock **tidak dipanggil**, bukan hanya bahwa
      exception dilempar. Itu dua hal berbeda.

### Verifikasi — uji manual, bukan hanya tes

```bash
cd app
flutter analyze && flutter test          # jumlah tes harus naik dari 39 → 45
# Uji perilaku sesungguhnya (butuh backend/mock server; kalau belum ada, tunggu Jumat):
flutter run -d chrome --dart-define=DATA_SOURCE=hybrid --dart-define=API_BASE_URL=<staging>
```

Ketik kata sandi yang **salah**. Yang harus terjadi: pesan error di layar login.
Yang tidak boleh terjadi: masuk ke Dashboard sebagai "Budi Santoso".

Kalau mock server BE belum hidup (dijadwalkan Jumat), tandai PR sebagai
"diverifikasi lewat tes; uji manual menyusul Jumat" dan jadwalkan ulang uji itu —
**jangan** lupakan.

### Log Progres

```
- **2026-09-16** — Frontend — PR #5 — T-16 & T-24 selesai: _orFallback hanya jatuh ke mock untuk statusCode 0/404/501; seluruh operasi auth tidak pernah fallback; operasi tulis tidak lagi menelan penolakan 4xx. Dampak: kata sandi salah tidak bisa lagi membuat pengguna masuk sebagai pengguna demo; transaksi yang ditolak backend tidak lagi dilaporkan berhasil. Tes: 39 → 45. Analyze 0/0. Build ✓.
```

---

## PR #6 — Loop onboarding untuk pengguna yang kembali 🔴 T-18

**Alur bugnya**, yang bisa kamu telusuri sendiri di kode:

1. `StorageService.setOnboarded()` (`storage_service.dart:84`) hanya dipanggil dari
   `BusinessService.create()` (`business_service.dart:31`). **`update()` di baris 35–54
   tidak memanggilnya.**
2. `login_screen.dart:_submit` (baris 46–65) juga tidak memanggilnya.
3. `StorageService.clearAll()` (baris 94–97) menjalankan `prefs.clear()` — menghapus flag
   `onboarded` beserta tema dan `businessId`. Ini terjadi pada setiap kegagalan refresh
   token (`api_client.dart:164`).
4. Setelah itu, `_guard` (`app_router.dart:132-134`) memantulkan pengguna ke
   `/onboarding/business` selamanya. Layar itu menemukan profil yang sudah ada, memanggil
   `update()` — yang tidak menyetel flag — lalu `go(dashboard)` → guard memantul lagi.

Satu-satunya jalan keluar adalah tombol "Lewati".

> Perbaikan `clearAll()` sendiri adalah T-23, dijadwalkan **Minggu 2**. PR ini menutup
> lubang lainnya, sehingga loop tidak terjadi walau flag hilang.

### Berkas yang berubah

`app/lib/core/services/business_service.dart`, `app/lib/screens/auth/login_screen.dart`,
`app/lib/core/network/app_router.dart`, `app/test/router_guard_test.dart` (baru)

### Perintah

```bash
git checkout main && git pull
git checkout -b perbaikan/T-18-loop-onboarding
```

### Prompt Claude Code

```
Konteks: temuan T-18 di backlog-teknis.md — pengguna backend yang kembali
terjebak di loop onboarding.

Baca dulu:
- app/lib/core/services/business_service.dart (perhatikan: create() di baris 14-33
  memanggil StorageService.setOnboarded(), tapi update() di baris 35-54 TIDAK)
- app/lib/core/services/storage_service.dart baris 78-97
- app/lib/core/network/app_router.dart baris 106-137 (fungsi _guard)
- app/lib/screens/auth/login_screen.dart baris 46-80
- app/lib/screens/settings/business_screen.dart (lihat bagaimana isOnboarding dipakai
  dan apa yang terjadi setelah simpan)

Alur bug: flag `onboarded` di SharedPreferences bisa hilang (mis. karena
StorageService.clearAll() saat refresh token gagal), sementara profil usaha pengguna
tetap ada di backend. _guard lalu memantulkan ke /onboarding/business; layar itu
menemukan profil yang ada, memanggil BusinessService.update() yang TIDAK menyetel flag,
lalu navigasi ke dashboard, lalu guard memantul lagi. Loop.

Yang saya minta:

1. BusinessService.update() juga memanggil StorageService.setBusinessId(profile.id)
   dan StorageService.setOnboarded() setelah update berhasil, persis seperti create().
   Perhatikan bahwa update() sekarang berbentuk expression body (=>) — ubah jadi
   async body supaya bisa await.

2. Di login_screen.dart _submit(): setelah AuthService.login berhasil, periksa apakah
   pengguna sudah punya profil usaha (BusinessService.getCurrent()). Kalau ada,
   panggil setBusinessId + setOnboarded sebelum navigasi, lalu go(dashboard).
   Kalau tidak ada, go('/onboarding/business') secara eksplisit.
   Tangani kegagalan pemanggilan getCurrent() dengan tidak menggagalkan login —
   kalau gagal, biarkan _guard yang memutuskan.

3. Di _guard (app_router.dart): sebagai jaring pengaman terakhir, kalau pengguna sudah
   login dan flag onboarded false TAPI StorageService.getBusinessId() mengembalikan
   nilai, anggap sudah onboarded — setel flag lalu lanjutkan, jangan memantul.
   Tulis komentar yang menjelaskan bahwa ini memulihkan keadaan setelah prefs terhapus.

4. Buat app/test/router_guard_test.dart yang menguji _guard sebagai fungsi:
   - belum login, membuka /dashboard → diarahkan ke /login
   - sudah login, sudah onboarded, membuka /dashboard → null (tidak diarahkan)
   - sudah login, flag onboarded false, businessId ADA → null (tidak diarahkan),
     dan flag onboarded menjadi true setelahnya
   - sudah login, flag onboarded false, businessId tidak ada → diarahkan ke
     /onboarding/business
   Pakai SharedPreferences.setMockInitialValues untuk menyiapkan keadaan.
   Kalau _guard privat, ubah jadi @visibleForTesting alih-alih membuatnya publik penuh.

Batasan:
- JANGAN mengubah StorageService.clearAll() — itu temuan T-23, dijadwalkan Minggu 2,
  dan akan dikerjakan di PR terpisah. Kalau kamu melihat masalah di sana, tulis saja
  di akhir jawabanmu sebagai temuan sampingan.
- Jangan mengubah tampilan layar onboarding.
- Komentar dalam Bahasa Indonesia.

Jalankan cd app && flutter analyze && flutter test.
```

### Yang wajib kamu periksa sendiri

- [ ] `clearAll()` **tidak** berubah. Cek: `git diff app/lib/core/services/storage_service.dart`
      harus kosong.
- [ ] `update()` tidak lagi `=>` tapi `async {}` — dan masih mengembalikan `BusinessProfile`.
- [ ] Reproduksi bug lamanya secara manual, lalu buktikan hilang:

```bash
cd app && flutter run -d chrome --dart-define=DATA_SOURCE=mock
```

Login → selesaikan onboarding → di DevTools Application → Local Storage, hapus kunci
`flutter.onboarded` → muat ulang halaman. **Sebelum PR:** terjebak di onboarding.
**Sesudah PR:** masuk ke Dashboard.

### Log Progres

```
- **2026-09-16** — Frontend — PR #6 — T-18 selesai: setOnboarded dipanggil di BusinessService.update() dan setelah login yang menemukan profil; _guard memulihkan flag dari businessId. Dampak: pengguna yang flag lokalnya terhapus tidak lagi terjebak di onboarding. Tes: 45 → 49 (router_guard_test.dart baru). Analyze 0/0. Build ✓.
```

---

# KAMIS 17 SEPTEMBER

## PR #7 — `context.go` + `pop()` = `GoError` 🔴 T-19

**Yang terjadi.** Dashboard menavigasi dengan `context.go` — yang **mengganti** tumpukan
navigasi, bukan menambahinya:

```
dashboard_screen.dart:261   void _openTx(RecentTx tx) => context.go('/accounting/${tx.id}');
dashboard_screen.dart:264   void _openNewTx()         => context.go(AppRoutes.newTx);
dashboard_screen.dart:305   onTap: () => context.go(AppRoutes.notifications),
```

Layar tujuannya lalu memanggil `pop()`:

```
tx_detail_screen.dart:90            onPressed: () => context.pop(),
new_transaction_screen.dart:146     context.pop();
new_transaction_screen.dart:217     onPressed: () => context.pop(),
new_transaction_screen.dart:259     onPressed: () => context.pop(),
```

Tidak ada yang bisa di-`pop` → `GoError: There is nothing to pop`. Layar itu sendiri
mendefinisikan rute tingkat atas di luar `ShellRoute` (`app_router.dart:42-60`), jadi
tidak ada bottom nav juga.

`NotificationScreen` paling parah: dicapai lewat `go`, tanpa tombol kembali, **dan** di
luar shell — di ponsel pengguna benar-benar terjebak. (Menariknya, baris 133 di layar itu
sendiri sudah memakai `context.push` dengan benar — polanya sudah dikenal di repo, hanya
tidak diterapkan konsisten.)

### Berkas yang berubah

`app/lib/screens/dashboard/dashboard_screen.dart`,
`app/lib/screens/dashboard/notification_screen.dart`,
`app/lib/screens/accounting/tx_detail_screen.dart`,
`app/lib/screens/accounting/new_transaction_screen.dart`

### Perintah

```bash
git checkout main && git pull
git checkout -b perbaikan/T-19-navigasi-push
```

### Prompt Claude Code

```
Konteks: temuan T-19 di backlog-teknis.md. Dashboard menavigasi ke rute
tingkat atas dengan context.go (yang MENGGANTI tumpukan), sedangkan layar tujuannya
memanggil context.pop() — menghasilkan "GoError: There is nothing to pop".

Baca dulu:
- app/lib/core/network/app_router.dart (perhatikan bahwa /accounting/new,
  /accounting/:id, dan /notifications adalah rute tingkat atas di baris 41-60,
  DI LUAR ShellRoute di baris 63-84)
- app/lib/screens/dashboard/dashboard_screen.dart baris 255-310
- app/lib/screens/accounting/tx_detail_screen.dart
- app/lib/screens/accounting/new_transaction_screen.dart
- app/lib/screens/dashboard/notification_screen.dart (perhatikan baris 133 yang
  SUDAH memakai context.push dengan benar — ikuti pola itu)

Yang saya minta:

1. Di dashboard_screen.dart, ganti context.go menjadi context.push untuk ketiga
   navigasi ke rute tingkat atas:
   - baris 261 _openTx  → /accounting/:id
   - baris 264 _openNewTx → /accounting/new
   - baris 305 → /notifications
   JANGAN mengubah baris 262 (_openAccounting) dan 263 (_openSimulator): keduanya
   menuju tab di dalam ShellRoute, dan context.go memang benar untuk berpindah tab.
   Tulis komentar singkat yang menjelaskan perbedaan itu supaya tidak diubah orang lain.

2. Di semua layar tujuan, ganti context.pop() telanjang dengan pola aman:
   kalau context.canPop() maka pop, kalau tidak maka context.go ke rute induk yang
   masuk akal (tx_detail dan new_transaction → /accounting; notifications → /dashboard).
   Buat satu helper kecil untuk pola ini — letakkan di
   app/lib/core/network/app_router.dart sebagai extension pada BuildContext,
   misalnya `context.popOr('/accounting')` — lalu pakai di keempat tempat.
   Perhatikan tx_detail_screen.dart baris 62 yang sudah memakai context.go('/accounting')
   setelah hapus transaksi: itu memang benar (transaksi sudah tidak ada, jangan
   kembali ke detailnya) — biarkan, tapi beri komentar kenapa.

3. Di notification_screen.dart, tambahkan tombol kembali di AppBar yang memakai
   helper yang sama. Saat ini layar ini tidak punya tombol kembali dan berada di luar
   bottom nav, jadi di ponsel pengguna terjebak.

4. Jangan memindahkan rute mana pun ke dalam ShellRoute di PR ini. Penggantian
   ShellRoute dengan StatefulShellRoute adalah temuan T-27, dijadwalkan Minggu 2.

Batasan:
- Jangan ubah tampilan layar mana pun selain menambah tombol kembali di Notifikasi.
- Komentar dalam Bahasa Indonesia.

Setelah selesai, buat daftar SETIAP pemanggilan context.go, context.push, dan
context.pop yang tersisa di app/lib beserta nomor barisnya, dan untuk masing-masing
sebutkan apakah sudah benar. Saya akan memakai daftar itu untuk uji manual.
```

### Yang wajib kamu periksa sendiri

- [ ] `_openAccounting` (baris 262) dan `_openSimulator` (263) **masih** `context.go`.
      Kalau keduanya berubah jadi `push`, berpindah tab akan menumpuk halaman tanpa batas
      — bug baru yang lebih halus dari yang diperbaiki.
- [ ] Daftar navigasi yang diminta di akhir prompt benar-benar dibuat. Pakai untuk uji.

### Verifikasi — enam alur, klik semuanya

```bash
cd app && flutter run -d chrome --dart-define=DATA_SOURCE=mock
```

| # | Alur | Harapan |
| --- | --- | --- |
| 1 | Dashboard → ketuk transaksi terakhir → kembali | kembali ke Dashboard, tanpa error konsol |
| 2 | Dashboard → "Catat transaksi" → batal | kembali ke Dashboard |
| 3 | Dashboard → "Catat transaksi" → simpan | kembali ke Dashboard, transaksi muncul |
| 4 | Dashboard → ikon lonceng → kembali | kembali ke Dashboard |
| 5 | Pembukuan → detail transaksi → hapus | ke daftar Pembukuan, bukan detail kosong |
| 6 | Dashboard → tab Pembukuan → tab Simulator → tab Dashboard | tidak menumpuk; tombol kembali browser tidak menelusuri puluhan langkah |

Ulangi keenamnya di **375 px** (ponsel) dan **1440 px**. Perhatikan konsol browser: nol
`GoError`.

### Log Progres

```
- **2026-09-17** — Frontend — PR #7 — T-19 selesai: navigasi Dashboard ke rute tingkat atas memakai context.push; pop diganti helper popOr(rute induk); tombol kembali ditambahkan di layar Notifikasi. Dampak: "GoError: There is nothing to pop" hilang dari tiga alur; pengguna ponsel tidak lagi terjebak di Notifikasi. Diuji 6 alur di 375/1440 px. Analyze 0/0. Build ✓.
```

---

## PR #8 — `ErrorState` dipakai di empat layar 🟡 T-22

**Ironinya.** `ErrorState` sudah ada, lengkap, di
`app/lib/widgets/common/app_widgets.dart:180` — dan **nol** layar memakainya. Empat layar
memanggil repositori tanpa `try/catch`, jadi `ApiException` membuat shimmer berputar
selamanya atau tombol simpan mati tanpa pesan:

| Layar | Baris |
| --- | --- |
| `screens/accounting/accounting_screen.dart` | 46–50 |
| `screens/settings/settings_screen.dart` | 49–61 |
| `screens/settings/business_screen.dart` | 78–99 |
| `screens/accounting/new_transaction_screen.dart` | 108–147 |

**Jebakan yang harus ikut diperbaiki:** `ApiException.userMessage`
(`api_client.dart:34-53`) memanggil `errors?.values.first` pada kasus 400. Kalau server
mengirim `details` kosong, itu melempar `StateError: No element` — jadi kode penanganan
error-mu sendiri yang crash. Ini bagian dari T-37 (dijadwalkan Minggu 2), tapi karena PR
ini menjadikan `userMessage` jalur yang aktif, perbaiki sekarang.

### Perintah

```bash
git checkout main && git pull
git checkout -b perbaikan/T-22-error-state
```

### Prompt Claude Code

```
Konteks: temuan T-22 di backlog-teknis.md. Widget ErrorState sudah ada di
app/lib/widgets/common/app_widgets.dart baris 180 tapi tidak dipakai satu layar pun.
Empat layar memanggil repositori tanpa try/catch, sehingga ApiException membuat
skeleton berputar selamanya atau tombol simpan mati tanpa pesan apa pun.

Baca dulu:
- app/lib/widgets/common/app_widgets.dart (ErrorState baris 180, EmptyState baris 134,
  ShimmerBox baris 103 — pahami parameter dan tampilannya)
- app/lib/core/network/api_client.dart baris 13-54 (ApiException.userMessage)
- keempat layar: screens/accounting/accounting_screen.dart baris 40-60,
  screens/settings/settings_screen.dart baris 40-70,
  screens/settings/business_screen.dart baris 70-105,
  screens/accounting/new_transaction_screen.dart baris 100-155

Yang saya minta:

1. Di api_client.dart baris 37, ganti `errors?.values.first?.toString()` dengan
   bentuk yang aman untuk map kosong (firstOrNull dari dart:collection, atau
   pemeriksaan isNotEmpty). Saat ini kode ini melempar StateError: No element
   kalau server mengirim details kosong — yaitu penanganan error yang crash sendiri.
   Ini bagian dari T-37; sebutkan di pesan commit bahwa T-37 selesai sebagian.

2. Di accounting_screen.dart, settings_screen.dart, dan business_screen.dart:
   bungkus pemanggilan repositori dengan try/catch on ApiException, simpan pesannya
   di state (`String? _error`), dan tampilkan ErrorState dengan tombol coba lagi
   yang memanggil ulang fungsi pemuatan. Urutan yang benar dalam build:
   error > loading > kosong > isi. Sekarang loading dicek lebih dulu, jadi error
   tidak akan pernah terlihat kalau _loading tidak pernah jadi false — pastikan
   _loading DISETEL false di blok finally.

3. Di new_transaction_screen.dart, kasusnya berbeda: ini aksi simpan, bukan pemuatan.
   Jangan pakai ErrorState seluruh layar. Yang benar: tangkap ApiException, tampilkan
   pesannya (pakai DsErrorBanner yang sudah ada di
   app/lib/widgets/common/ds_widgets.dart baris 565, atau SnackBar kalau lebih cocok
   dengan pola layar itu), DAN kembalikan tombol simpan ke keadaan aktif supaya
   pengguna bisa mencoba lagi. Yang tidak boleh: tombol mati permanen tanpa pesan.

4. Semua pesan yang dilihat pengguna memakai ApiException.userMessage
   (sudah Bahasa Indonesia), bukan e.toString().

5. Jangan tangkap Exception secara umum — hanya ApiException. Bug pemrograman harus
   tetap naik ke atas dan terlihat, sesuai komentar di kepala
   app/lib/core/data/hybrid_repositories.dart.

Batasan:
- Jangan mengubah tata letak atau gaya visual keempat layar selain menambahkan
  keadaan error.
- Jangan ubah ErrorState itu sendiri.
- Komentar dalam Bahasa Indonesia.

Jalankan cd app && flutter analyze && flutter test.
```

### Yang wajib kamu periksa sendiri

- [ ] `_loading = false` ada di blok `finally` di keempat layar. Tanpa itu, keadaan error
      tertutup skeleton dan kamu tidak akan pernah melihatnya.
- [ ] Urutan pengecekan di `build`: error dulu, baru loading. Mudah salah.
- [ ] Tidak ada `catch (e)` telanjang. Cek: `git diff | grep -n "catch (e)"` — semuanya
      harus `on ApiException catch (e)`.
- [ ] **Uji error sungguhan**, jangan hanya membaca kode:

```bash
cd app
flutter run -d chrome --dart-define=DATA_SOURCE=api --dart-define=API_BASE_URL=http://localhost:9999
```

Port 9999 tidak ada yang mendengarkan → semua request gagal. Buka keempat layar. Yang harus
terlihat: `ErrorState` dengan tombol "Coba lagi" di tiga layar, banner error di layar
transaksi baru dengan tombol simpan yang masih bisa ditekan. Yang tidak boleh: shimmer
abadi, layar putih, atau tombol mati.

### Log Progres

```
- **2026-09-17** — Frontend — PR #8 — T-22 selesai, T-37 sebagian: ErrorState dipakai di Pembukuan/Pengaturan/Profil usaha, banner + tombol aktif kembali di Transaksi baru; ApiException.userMessage tidak lagi melempar StateError saat details kosong. Dampak: empat layar tidak lagi menampilkan skeleton abadi saat backend mati. Diuji dengan API_BASE_URL yang sengaja salah. Analyze 0/0. Build ✓.
```

---

# JUMAT 18 SEPTEMBER

## PR #9 — Dokumen yang bertentangan dengan kenyataan (P-12)

Empat dokumen memberi instruksi yang salah kepada siapa pun yang membacanya. Ini PR
**tanpa kode Dart sama sekali** — 30 menit kerja, dan menghentikan kontributor berikutnya
mengikuti petunjuk yang keliru.

| Berkas | Yang salah | Yang benar |
| --- | --- | --- |
| `../panduan/kontribusi.md` §4 | "jangan jalankan `dart format`" | T-9 Minggu 2 justru akan menegakkannya di CI |
| `../arsitektur/gambaran-umum.md` | tabel `core/theme` tidak menyebut `design_tokens.dart` & `breakpoints.dart` | keduanya ada dan justru yang utama |
| `README.md` | "Flutter 3.38.4+" | CI memakai 3.44.8; beda versi analyzer pernah memerahkan PR #3 |
| `app/lib/core/theme/breakpoints.dart` (header) | mengklaim breakpoint literal 500/680 "sudah diganti" | belum — `prd_score.sh` PR #4 melaporkan 3 |

### Prompt Claude Code

```
Konteks: temuan P-12 di backlog-teknis.md — dokumen proyek bertentangan dengan
kode dan dengan rencana yang sudah disepakati.

Perbaiki empat hal berikut. Ini PR dokumentasi — JANGAN ubah kode Dart apa pun
kecuali komentar header yang disebut di poin 4.

1. ../panduan/kontribusi.md bagian 4: hapus instruksi "jangan jalankan dart format".
   Ganti dengan: format kode dijalankan sekali menyeluruh di Minggu 2 (temuan T-9 di
   wiki/rencana-frontend.md), setelah itu `dart format --set-exit-if-changed` ditegakkan di CI
   dan setiap PR wajib terformat. Baca wiki/rencana-frontend.md Minggu 2 dulu supaya rujukannya
   akurat.

2. ../arsitektur/gambaran-umum.md: perbarui tabel struktur folder supaya
   app/lib/core/theme/design_tokens.dart dan app/lib/core/theme/breakpoints.dart
   ikut tercantum dengan deskripsi satu baris masing-masing. Baca kedua berkas itu
   dulu. Sebutkan juga bahwa app_theme.dart memuat sistem lama (AppColors/AppTextStyles)
   yang akan dihapus di Minggu 3.

3. README.md: ganti syarat versi Flutter menjadi 3.44.8, sama persis dengan pin di
   .github/workflows/ci.yml dan .github/workflows/publish-web.yml. Tambahkan satu
   kalimat bahwa CI adalah sumber kebenaran versi, karena analyzer versi berbeda
   pernah membuat PR hijau di lokal tapi merah di CI.

4. app/lib/core/theme/breakpoints.dart: komentar header mengklaim breakpoint literal
   500 dan 680 sudah diganti di seluruh kode. Itu tidak benar — masih ada 3 tempat.
   Perbaiki komentar itu supaya jujur, dan sebutkan bahwa penggantian tuntas
   dijadwalkan Minggu 4 (R-4 di wiki/rencana-frontend.md). Jangan ubah kode di berkas itu,
   hanya komentarnya.

Jangan memperbaiki drift dokumen lain yang kamu temukan — daftarkan saja di akhir
jawabanmu. Semua dalam Bahasa Indonesia.
```

**Periksa sendiri:** `git diff --stat` harus menunjukkan tepat 4 berkas, dan diff pada
`breakpoints.dart` hanya baris komentar.

```bash
git checkout -b wiki/P-12-drift
# … prompt …
git commit -am "docs: P-12 — samakan CONTRIBUTING, ARCHITECTURE, README, header breakpoints dengan kenyataan"
```

---

## Jumat siang — Tinjau kanvas "Catatin UI v2" bersama PO

Bukan tugas koding, tapi ini yang menentukan pekerjaanmu tiga minggu ke depan.

1. Buka kanvas bersama PO, **artboard per artboard**, 17 total.
2. Untuk setiap artboard: **terima**, **tolak**, atau **terima dengan catatan**.
3. Catat hasilnya sebagai **D-17 dan seterusnya** di tabel Log Keputusan
   `linimasa.md` — bukan di chat. Keputusan yang hanya hidup di chat adalah
   temuan P-3, dan itu sudah menahan 12 keputusan lain.
4. Artboard **Pembukuan**, **Kalender**, **keadaan kosong/memuat**, dan **PembukuanWeb**
   adalah yang paling mendesak: keempatnya menjadi spesifikasi Minggu 3–4.
5. Yang perlu kamu tanyakan sebagai FE, konkret: apakah nav rail di desktop disetujui
   (D-6)? apakah Pembukuan web dua panel? berapa lebar maksimum konten? apakah keadaan
   kosong punya ilustrasi atau hanya teks?

## Jumat sore — Sinkron M0

Tanda tanganmu di M0 berarti: **"spesifikasi pajak cukup untuk saya implementasikan."**
Perlakukan itu serius, karena Minggu 5 dibangun di atasnya.

Sebelum menyetujui, buka `../domain/pajak/spek-pph21-ter.md` dan `../domain/pajak/spek-pph-final-umkm.md` dari PJ
dan periksa keempat hal ini:

- [ ] Tabel TER **A, B, dan C lengkap** — bukan hanya A. Setiap lapisan punya batas bawah,
      batas atas, dan tarif dalam bentuk yang bisa langsung jadi `List<TerBracket>`.
- [ ] Pemetaan **8 nilai `PtkpStatus`** yang ada di kode → kategori TER. Delapan, bukan
      lima seperti di mockup (lihat komentar `tax_conversation_tab.dart:39-40`).
- [ ] **Matriks profesi → rezim** (D-11) mencakup ketujuh nilai di `_professions`
      (`tax_conversation_tab.dart:27-35`), termasuk "Lainnya".
- [ ] `../domain/pajak/kasus-pph21.csv` punya kolom yang bisa dibaca program: input, hasil harapan, dan
      sumber. Minggu 5 akan membangkitkan tes langsung dari berkas ini.

Kalau ada kolom yang tidak bisa kamu petakan ke kode — **katakan hari ini**, bukan Minggu 5.
Itulah gunanya tanda tangan ini.

---

## ✅ Checklist akhir Minggu 1

**Tergabung & tayang:**

- [ ] PR #1 — chip terlihat di produksi, tangkapan layar terang & gelap terlampir
- [ ] PR #2 — PR sengaja-merah terbukti tidak tayang
- [ ] PR #3 — `.env` & `.vscode` terbukti selamat di klon uji

**Tergabung:**

- [ ] PR #4 — baseline skor PRD tercatat
- [ ] PR #5 — kata sandi salah ditolak (tes; uji manual menyusul kalau staging telat)
- [ ] PR #6 — flag onboarded dihapus manual → tidak terjebak
- [ ] PR #7 — enam alur navigasi bersih, nol `GoError`
- [ ] PR #8 — empat layar menampilkan error, bukan skeleton abadi
- [ ] PR #9 — empat dokumen jujur

**Proses:**

- [ ] `CLAUDE.md` ada di root
- [ ] Tujuh belas artboard diputus dan tercatat sebagai D-17…
- [ ] M0 ditandatangani, atau **tidak** ditandatangani dengan alasan tertulis
- [ ] Sembilan baris Log Progres ada di `linimasa.md` Lampiran B

**Angka yang dilaporkan Jumat:**

| | Baseline Sen | Target Jum |
| --- | --- | --- |
| `flutter test` | 39 lulus, 1 skip | ≥ 49 lulus, 1 skip |
| `flutter analyze` | 0 error / 0 warning / ~39 info | 0 / 0 / ≤ 39 |
| Temuan 🔴 terbuka (FE) | 8 | 2 (T-20, T-23 → Minggu 2) |

---

## Lampiran — Kalau ada yang macet

| Gejala | Kemungkinan besar | Tindakan |
| --- | --- | --- |
| PR hijau lokal, merah di CI | versi Flutter lokal ≠ 3.44.8 | Hari 0 §0.1; CI adalah sumber kebenaran, bukan mesinmu |
| Publikasi tidak jalan setelah PR #2 | nama workflow di `workflows: ["CI"]` tidak persis sama dengan `name:` di `ci.yml` | cocokkan huruf per huruf |
| Publikasi gagal 403 | izin workflow | Settings → Actions → General → Workflow permissions → "Read and write" (komentar ini sudah ada di `publish-web.yml`) |
| Tes mendadak gagal setelah PR #5 | tes lama diam-diam mengandalkan fallback hybrid | itu **temuan**, bukan gangguan — perbaiki tesnya dan catat di PR |
| Claude mengubah `simulator_service.dart` | prompt kurang tegas | batalkan (`git checkout -- <berkas>`), ulangi dengan batasan eksplisit. FE tidak berwenang mengubah angka pajak tanpa SPEC (`alur-kerja.md` §2) |
| Claude memperbaiki tiga temuan sekaligus | konteks terlalu luas | `git reset --hard`, buka sesi baru, satu temuan per sesi |
| Mock server BE belum ada Jumat | risiko yang sudah diketahui | tidak memblokir FE minggu ini; jadwalkan ulang uji manual PR #5 dan catat sebagai utang di PR |
| SPEC pajak belum ada Jumat | risiko yang sudah diketahui | **jangan tanda tangan M0**. Minggu 5 bergeser — itu keputusan PO, dan konsekuensinya jauh lebih kecil daripada mengarang tarif |
