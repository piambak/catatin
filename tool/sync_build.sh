#!/usr/bin/env bash
#
# Menyalin app/build/web/ ke root repo — yang disajikan GitHub Pages.
#
# Pages repo ini bersumber dari branch `main` folder `/ (root)` dan setting itu
# butuh akses admin untuk diubah, jadi output build memang harus tinggal di root.
#
# Skrip menghapus isi root SELAIN daftar KEEP di bawah. Kalau kamu menambah
# berkas/folder baru di root yang bukan hasil build, tambahkan namanya ke KEEP —
# kalau tidak, ia akan terhapus pada build berikutnya.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/app/build/web"

# Berkas & folder root yang BUKAN hasil build.
KEEP=(
  .git
  .github
  .claude
  .gitignore
  .gitattributes
  .nojekyll
  app
  docs
  tool
  README.md
  CONTRIBUTING.md
  LICENSE
  CNAME
)

# ── Pemeriksaan keamanan ─────────────────────────────────────────────────────
[ -f "$ROOT/app/pubspec.yaml" ] || {
  echo "✗ $ROOT tidak terlihat seperti root repo catatin. Batal." >&2
  exit 1
}
[ -d "$BUILD" ] || {
  echo "✗ $BUILD tidak ada. Jalankan 'flutter build web' dulu." >&2
  exit 1
}
[ -f "$BUILD/index.html" ] || {
  echo "✗ Hasil build tidak punya index.html. Batal." >&2
  exit 1
}

is_kept() {
  local name="$1"
  for keep in "${KEEP[@]}"; do
    [ "$name" = "$keep" ] && return 0
  done
  return 1
}

echo "→ Membersihkan output lama di root…"
shopt -s dotglob nullglob
for path in "$ROOT"/*; do
  name="$(basename "$path")"
  if ! is_kept "$name"; then
    rm -rf "$path"
  fi
done
shopt -u dotglob nullglob

echo "→ Menyalin $BUILD → $ROOT"
cp -R "$BUILD"/. "$ROOT"/

echo "✓ Output web tersinkron. Periksa dengan 'git status'."
