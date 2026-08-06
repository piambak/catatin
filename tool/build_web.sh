#!/usr/bin/env bash
#
# Build web rilis + sinkron ke root repo.
#
#   ./tool/build_web.sh                       # mode mock (demo publik)
#   ./tool/build_web.sh https://api.contoh.id/api/v1   # tersambung backend
#
# Base href WAJIB "/catatin/" karena situs tayang di
# https://piambak.github.io/catatin/ — tanpa itu semua aset 404.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
API_BASE_URL="${1:-}"

cd "$ROOT/app"

echo "→ flutter pub get"
flutter pub get

DEFINES=()
if [ -n "$API_BASE_URL" ]; then
  DEFINES+=(--dart-define=API_BASE_URL="$API_BASE_URL" --dart-define=DATA_SOURCE=hybrid)
  echo "→ build tersambung backend: $API_BASE_URL"
else
  echo "→ build mode mock (tanpa backend)"
fi

echo "→ flutter build web --release --base-href /catatin/"
flutter build web --release --base-href "/catatin/" "${DEFINES[@]}"

"$ROOT/tool/sync_build.sh"
