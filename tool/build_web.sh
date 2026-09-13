#!/usr/bin/env bash
#
# Build web rilis + sinkron ke root repo.
#
#   ./tool/build_web.sh                                  # sama dengan situs publik
#   ./tool/build_web.sh --mock                           # data contoh, tanpa backend
#   ./tool/build_web.sh https://api.contoh.id/api/v1     # backend REST (hybrid)
#
# Tanpa argumen, build memakai app/dart_define.pages.json — berkas yang sama
# dengan workflow Publikasi web, jadi hasilnya identik dengan yang tayang.
#
# Base href WAJIB "/catatin/" karena situs tayang di
# https://piambak.github.io/catatin/ — tanpa itu semua aset 404.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARG="${1:-}"

cd "$ROOT/app"

echo "→ flutter pub get"
flutter pub get

DEFINES=()
case "$ARG" in
  "")
    DEFINES+=(--dart-define-from-file=dart_define.pages.json)
    echo "→ build sama dengan situs publik (dart_define.pages.json)"
    ;;
  --mock)
    echo "→ build mode mock (tanpa backend)"
    ;;
  *)
    # Sengaja tanpa dart_define.pages.json: --dart-define menimpa nilai dari
    # berkas, jadi mencampur keduanya diam-diam menghasilkan build campuran.
    DEFINES+=(--dart-define=API_BASE_URL="$ARG" --dart-define=DATA_SOURCE=hybrid)
    echo "→ build tersambung backend REST: $ARG"
    ;;
esac

echo "→ flutter build web --release --base-href /catatin/"
flutter build web --release --base-href "/catatin/" "${DEFINES[@]}"

"$ROOT/tool/sync_build.sh"
