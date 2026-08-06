# Rilis & Deploy

## Ringkas

| | |
| --- | --- |
| **Live** | <https://piambak.github.io/catatin/> |
| **Sumber Pages** | branch `main`, folder `/ (root)` |
| **Base href** | `/catatin/` |
| **Pemicu** | push ke `main` yang menyentuh `app/**` |
| **Cadangan** | branch `backup(stable-version)` |

## Alur otomatis

```
push ke main (app/**)
        │
        ▼
.github/workflows/publish-web.yml
        │  flutter pub get
        │  flutter build web --release --base-href /catatin/
        │  bash tool/sync_build.sh      ← salin build/web → root
        ▼
commit "build: publikasi web dari <sha> [skip ci]" ke main
        │
        ▼
GitHub Pages men-deploy root main (1–2 menit)
```

Commit dari bot hanya menyentuh berkas di root, sedangkan workflow disaring
`paths: app/**`, jadi tidak ada loop build.

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

Keduanya menjalankan `flutter build web --release --base-href /catatin/` lalu
menyalin hasilnya ke root. Sesudahnya:

```bash
git add -A
git commit -m "build: rilis <deskripsi singkat>"
git push origin main
```

> `tool/sync_build.sh` **menghapus** isi root selain daftar KEEP di dalamnya.
> Kalau kamu menambah berkas baru di root yang bukan hasil build, tambahkan
> namanya ke daftar KEEP di kedua skrip (`.sh` dan `.ps1`).

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
3. Perbarui daftar `Access-Control-Allow-Origin` di backend
   (lihat [BACKEND.md](BACKEND.md#5-cors-khusus-web)).

## Menaikkan versi

`version: 1.0.0+1` di `app/pubspec.yaml`. Nilainya ikut ke `version.json` hasil
build, jadi versi yang tayang selalu bisa dicek di
<https://piambak.github.io/catatin/version.json>.
