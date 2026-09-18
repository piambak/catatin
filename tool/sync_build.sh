#!/usr/bin/env bash
#
# Menyalin app/build/web/ ke root repo — yang disajikan GitHub Pages.
#
# Pages repo ini bersumber dari branch `main` folder `/ (root)` dan setting itu
# butuh akses admin untuk diubah, jadi output build memang harus tinggal di root.
#
# T-29: versi lama menghapus SEMUA isi root yang tidak ada di daftar KEEP, dan
# karena `dotglob` aktif, dotfile ikut — `.env`, `.vscode`, `.idea`, folder
# coretan. Di runner CI itu tidak terasa (mesin sekali pakai); di mesin
# pengembang itu menghapus pekerjaan.
#
# Sekarang skrip hanya menghapus berkas yang IA SENDIRI salin pada jalan
# sebelumnya, dicatat di manifes tool/.last_build_files. KEEP tetap ada sebagai
# lapisan kedua: apa pun yang terdaftar di sana tidak pernah dihapus, walau
# tercantum di manifes.
#
# Pemakaian:
#   bash tool/sync_build.sh            # dry-run: hanya melaporkan rencananya
#   bash tool/sync_build.sh --yes      # jalankan sungguhan
#   CI=true bash tool/sync_build.sh    # di GitHub Actions, --yes tersirat

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="$ROOT/app/build/web"
MANIFEST="$ROOT/tool/.last_build_files"

# ── Mode ─────────────────────────────────────────────────────────────────────
APPLY=0
[ "${CI:-}" = "true" ] && APPLY=1
for arg in "$@"; do
  case "$arg" in
    --yes|-y) APPLY=1 ;;
    --dry-run) APPLY=0 ;;
    *) echo "✗ Argumen tidak dikenal: $arg" >&2; exit 2 ;;
  esac
done

# Berkas & folder root yang BUKAN hasil build — tidak pernah dihapus.
KEEP=(
  .git
  .github
  .claude
  .codex
  .ok
  .gitignore
  .gitattributes
  .mcp.json
  .nojekyll
  .okignore
  app
  supabase
  tool
  wiki
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
  local name="${1%%/*}" # bandingkan hanya segmen pertama path
  for keep in "${KEEP[@]}"; do
    [ "$name" = "$keep" ] && return 0
  done
  return 1
}

# ── Apa yang akan disalin ────────────────────────────────────────────────────
mapfile -t NEW_FILES < <(cd "$BUILD" && find . -type f -printf '%P\n' | sort)

# ── Apa yang boleh dihapus: hanya jejak build sebelumnya ─────────────────────
STALE=()
if [ -f "$MANIFEST" ]; then
  while IFS= read -r rel; do
    [ -n "$rel" ] || continue
    is_kept "$rel" && continue
    [ -e "$ROOT/$rel" ] || continue
    # masih dihasilkan build baru → bukan sisa
    printf '%s\n' "${NEW_FILES[@]}" | grep -qxF "$rel" && continue
    STALE+=("$rel")
  done < "$MANIFEST"
else
  echo "! Manifes $MANIFEST belum ada (klon baru atau pemakaian pertama)."
  echo "  Pembersihan dilewati; skrip hanya menyalin dan menulis manifes."
fi

# ── Laporan ──────────────────────────────────────────────────────────────────
echo "→ Akan menyalin ${#NEW_FILES[@]} berkas dari $BUILD"
if [ "${#STALE[@]}" -gt 0 ]; then
  echo "→ Akan menghapus ${#STALE[@]} sisa build sebelumnya:"
  printf '    %s\n' "${STALE[@]}"
else
  echo "→ Tidak ada sisa build sebelumnya yang perlu dihapus."
fi

if [ "$APPLY" -ne 1 ]; then
  echo
  echo "• Ini dry-run. Jalankan ulang dengan --yes untuk benar-benar mengubah root."
  exit 0
fi

# ── Jalankan ─────────────────────────────────────────────────────────────────
for rel in ${STALE+"${STALE[@]}"}; do
  rm -f "$ROOT/$rel"
done
# Buang direktori kosong yang ditinggalkan, tanpa menyentuh KEEP.
find "$ROOT" -mindepth 1 -maxdepth 3 -type d -empty \
  -not -path "$ROOT/.git/*" -not -path "$ROOT/app/*" \
  -not -path "$ROOT/wiki/*" -not -path "$ROOT/supabase/*" \
  -delete 2>/dev/null || true

echo "→ Menyalin $BUILD → $ROOT"
cp -R "$BUILD"/. "$ROOT"/

printf '%s\n' "${NEW_FILES[@]}" > "$MANIFEST"
echo "✓ Output web tersinkron; manifes diperbarui ($MANIFEST)."
echo "  Periksa dengan 'git status'."
