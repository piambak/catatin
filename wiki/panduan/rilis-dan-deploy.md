---
title: Rilis & Deploy
description: Alur publikasi web otomatis dan manual, urutan rilis yang mengubah skema database (CI, staging, produksi), menguji hasil build lokal, rollback, pindah domain, dan menaikkan versi.
tags:
  - panduan
  - rilis
  - deploy
---

## Ringkas

| | |
| --- | --- |
| **Live** | <https://piambak.github.io/catatin/> |
| **Sumber Pages** | branch `main`, folder `/ (root)` |
| **Base href** | `/catatin/` |
| **Pemicu** | push ke `main` yang menyentuh `app/**` |
| **Backend** | Supabase, dikonfigurasi di `app/dart_define.pages.json` — lihat [Supabase](../arsitektur/supabase.md) |
| **Staging** | Proyek Supabase `catatin-staging`, `app/dart_define.staging.json` — tidak pernah dipakai build situs publik |
| **CI database** | `.github/workflows/supabase.yml`, pemicu: perubahan `supabase/**` |
| **Cadangan** | branch `backup(stable-version)` |

## Alur otomatis

```text
push ke main (app/**)
        │
        ▼
.github/workflows/publish-web.yml
        │  flutter pub get
        │  flutter build web --release --base-href /catatin/
        │      --dart-define-from-file=dart_define.pages.json
        │  bash tool/sync_build.sh      ← salin build/web → root
        ▼
commit "build: publikasi web dari <sha> [skip ci]" ke main
        │
        ▼
GitHub Pages men-deploy root main (1–2 menit)
```

Commit dari bot hanya menyentuh berkas di root, sedangkan workflow disaring
`paths: app/**`, jadi tidak ada loop build.

### Kalau push ke `main` tidak memicu workflow sama sekali

Terjadi pada push `ce4639e` (13 Sep 2026): push tercatat, tetapi CI maupun
Publikasi web tidak membuat run apa pun, padahal push sebelumnya memicu run
dalam hitungan detik. Penyebabnya tidak terlihat dari akun berakses tulis —
API izin Actions hanya untuk admin. Picu manual; akses tulis sudah cukup:

```bash
gh workflow run publish-web.yml --ref main
gh workflow run ci.yml --ref main
```

Kalau dispatch pun ditolak, pakai jalur manual di bawah dan minta pemilik repo
memeriksa *Settings → Actions*.

### Kalau workflow gagal dengan `403` saat push

Token Actions belum punya izin tulis. Ini setting tingkat repo yang butuh akses
admin — minta pemilik repo membuka
**Settings → Actions → General → Workflow permissions** lalu pilih
**Read and write permissions**.

Sementara belum diubah, pakai jalur manual di bawah.

## Alur manual

Windows:

```powershell
.\tool\build_web.ps1
```

Linux / macOS / Git Bash:

```bash
./tool/build_web.sh
```

Keduanya menjalankan `flutter build web --release --base-href /catatin/` dengan
`app/dart_define.pages.json` — hasilnya identik dengan yang tayang — lalu
menyalin hasilnya ke root. Pilihan lain:

| Build | Windows | Linux / macOS / Git Bash |
| --- | --- | --- |
| Data contoh, tanpa backend | `.\tool\build_web.ps1 -Mock` | `./tool/build_web.sh --mock` |
| Backend REST (hybrid) | `.\tool\build_web.ps1 -ApiBaseUrl <url>` | `./tool/build_web.sh <url>` |

Build REST sengaja tidak memakai berkas Pages, supaya dua sumber konfigurasi
tidak tercampur dalam satu build. Sesudahnya:

```bash
git add -A
git commit -m "build: rilis <deskripsi singkat>"
git push origin main
```

> `tool/sync_build.sh` **menghapus** isi root selain daftar KEEP di dalamnya.
> Kalau kamu menambah berkas baru di root yang bukan hasil build, tambahkan
> namanya ke daftar KEEP di kedua skrip (`.sh` dan `.ps1`) — keduanya harus
> sama persis. `supabase` sudah terdaftar; tanpa itu commit bot menghapus
> folder migrasi.

## Rilis yang mengubah skema database

Setiap perubahan di `supabase/**` dicek workflow `supabase.yml`: semua migrasi
dijalankan dari nol di Postgres lokal runner, di-lint, lalu dites pgTAP
(skema, hak akses, isolasi RLS, dan data contoh staging). Workflow itu **tidak**
menerapkan migrasi ke proyek remote mana pun — rincian dan cara menjalankannya
lokal di [Supabase §9](../arsitektur/supabase.md#9-ci-database).

Urutan untuk migrasi baru:

1. Workflow `Supabase` hijau untuk commit yang membawa migrasinya.
2. Terapkan ke **staging** (`catatin-staging`), lalu uji alur yang terdampak
   dengan `app/dart_define.staging.json`
   ([Supabase §8](../arsitektur/supabase.md#8-staging-dan-data-contoh)).
3. Terapkan ke **produksi** (`catatin`).
4. Baru gabungkan perubahan aplikasi yang membutuhkannya ke `main`.

Menerapkan ke satu proyek — `link` menentukan proyek mana yang dituju, jadi
pastikan ref-nya benar sebelum `push` (staging `herafvadqziftszhxqeq`, produksi
`mhoadvaiarjbbzlltqxy`):

```bash
npx supabase link --project-ref <ref>
npx supabase db push --dry-run
npx supabase db push
```

Migrasi yang diterapkan lewat konektor Supabase (MCP) mendapat versi sesuai
waktu penerapan — samakan nama berkas lokalnya, lihat
[Supabase](../arsitektur/supabase.md#2-menyiapkan-dari-nol).

Kalau urutannya terbalik, situs yang baru tayang menembak tabel atau kolom
yang belum ada. Galatnya tampil sebagai pesan umum di UI; di mode debug pesan
aslinya tercetak di konsol.

## Menguji hasil build secara lokal

`index.html` memakai `<base href="/catatin/">`, jadi **web root harus folder
induk repo**, bukan folder repo itu sendiri. Kalau salah, semua aset 404 dan
halaman blank.

```bash
python -m http.server 8080 --directory ..
```

Lalu buka <http://localhost:8080/catatin/>.

Lewat Claude Code sudah disiapkan di `.claude/launch.json` sebagai
`catatin-web` pada port 8011 → <http://localhost:8011/catatin/>.

Untuk pengembangan sehari-hari lebih enak pakai dev server Flutter, yang tidak
butuh trik base href sama sekali:

```bash
cd app
flutter run -d chrome
```

## Kalau rilis bermasalah

Branch `backup(stable-version)` menyimpan versi stabil yang pernah tayang.
Kembalikan `main` ke sana, situs ikut kembali pada deployment berikutnya:

```bash
git checkout main
git reset --hard "origin/backup(stable-version)"
git push --force-with-lease origin main
```

`--force-with-lease`, bukan `--force`: kalau ada yang push duluan, perintahnya
gagal alih-alih menimpa pekerjaan orang lain.

## Pindah ke domain sendiri

Kalau nanti hosting pindah ke domain utama (mis. `https://catatin.id/`):

1. Ganti `--base-href "/catatin/"` menjadi `"/"` di `tool/build_web.*` dan di
   `.github/workflows/publish-web.yml`.
2. Tambahkan berkas `CNAME` berisi domainnya di root — namanya sudah ada di
   daftar KEEP skrip sinkron, jadi tidak akan terhapus saat build.
3. Perbarui Site URL dan Redirect URLs di pengaturan Auth Supabase
   (lihat [Supabase](../arsitektur/supabase.md#5-pengaturan-auth)). Kalau
   memakai backend REST, perbarui juga `Access-Control-Allow-Origin`-nya
   (lihat [Backend & API](../arsitektur/backend-dan-api.md#5-cors-khusus-web)).

## Menaikkan versi

`version: 1.0.0+1` di `app/pubspec.yaml`. Nilainya ikut ke `version.json` hasil
build, jadi versi yang tayang selalu bisa dicek di
<https://piambak.github.io/catatin/version.json>.
