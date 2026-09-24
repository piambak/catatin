#!/usr/bin/env bash
#
# Mencari berkas Dart yatim di app/lib: berkas yang tidak terjangkau dari
# lib/main.dart lewat rantai import/export/part.
#
# Kenapa "tidak terjangkau", bukan sekadar "tidak diimpor": berkas yang hanya
# diimpor oleh berkas yatim lain juga mati. Audit 12 Sep menghitung 3.684 baris
# seperti ini; daftar audit bukan bukti — keluaran skrip inilah buktinya
# (issue #32, T-32).
#
# Berkas yang tidak terjangkau dari main.dart tapi masih diimpor tes ditandai
# terpisah: menghapusnya ikut mematahkan tes, jadi putuskan satu per satu.
#
# Lapisan data yang sudah dibangun Backend tapi UI-nya belum ada (mis. fasad
# transaksi berulang sebelum layar Minggu 3) memang belum terjangkau. Daftarkan
# di tool/find_orphans.allow — satu path per baris, WAJIB dengan alasan dan
# issue yang akan menyambungkannya — supaya bedanya jelas: "belum disambung,
# ada rencananya" lawan "mati, tidak ada yang ingat".
#
# Pemakaian:
#   bash tool/find_orphans.sh            # daftar berkas yatim, selalu keluar 0
#   bash tool/find_orphans.sh --strict   # keluar 1 kalau ada yang yatim
#
# Batasannya: hanya membaca direktif import/export/part yang ditulis satu baris
# (gaya seluruh repo ini) dan import bersyarat `if (dart.library.x)`.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP="$ROOT/app"
LIB="$APP/lib"
PKG="catatin"
STRICT=0

for arg in "$@"; do
  case "$arg" in
    --strict|-s) STRICT=1 ;;
    *) echo "✗ Argumen tidak dikenal: $arg" >&2; exit 2 ;;
  esac
done

[ -f "$APP/pubspec.yaml" ] || { echo "✗ $APP/pubspec.yaml tidak ada. Jalankan dari repo catatin." >&2; exit 1; }
[ -f "$LIB/main.dart" ] || { echo "✗ $LIB/main.dart tidak ada." >&2; exit 1; }

# Semua target direktif di satu berkas, sudah jadi path absolut.
targets() {
  local file="$1" dir
  dir="$(dirname "$file")"
  grep -oE "^[[:space:]]*(import|export|part)[[:space:]]+'[^']+'|if[[:space:]]*\([^)]*\)[[:space:]]*'[^']+'" "$file" 2>/dev/null \
    | grep -oE "'[^']+'" | tr -d "'" \
    | while read -r uri; do
        case "$uri" in
          dart:*) ;;
          package:"$PKG"/*) realpath -m "$LIB/${uri#package:"$PKG"/}" ;;
          package:*) ;;
          *) realpath -m "$dir/$uri" ;;
        esac
      done
}

# Penelusuran lebar dari main.dart.
declare -A SAMPAI=()
ANTRE=("$(realpath -m "$LIB/main.dart")")
SAMPAI["${ANTRE[0]}"]=1
while [ "${#ANTRE[@]}" -gt 0 ]; do
  f="${ANTRE[0]}"; ANTRE=("${ANTRE[@]:1}")
  [ -f "$f" ] || continue
  while read -r t; do
    [ -n "$t" ] || continue
    if [ -z "${SAMPAI[$t]:-}" ]; then
      SAMPAI["$t"]=1
      ANTRE+=("$t")
    fi
  done < <(targets "$f")
done

# Berkas yang sengaja belum disambung (lihat kepala berkas).
declare -A IZIN=()
ALLOW="$ROOT/tool/find_orphans.allow"
if [ -f "$ALLOW" ]; then
  while IFS= read -r baris; do
    p="${baris%%#*}"; p="${p//[[:space:]]/}"
    [ -n "$p" ] || continue
    IZIN["$(realpath -m "$ROOT/$p")"]="${baris#*#}"
  done < "$ALLOW"
fi

# Berkas lib yang diimpor tes (langsung).
declare -A DITES=()
if [ -d "$APP/test" ]; then
  while read -r tf; do
    while read -r t; do [ -n "$t" ] && DITES["$t"]=1; done < <(targets "$tf")
  done < <(find "$APP/test" -name '*.dart' | sort)
fi

YATIM=0; BARIS=0; DIPAKAI_TES=0; DIIZINKAN=()
while read -r f; do
  f="$(realpath -m "$f")"
  [ -n "${SAMPAI[$f]:-}" ] && continue
  rel="${f#"$ROOT"/}"
  if [ -n "${IZIN[$f]+ada}" ]; then
    DIIZINKAN+=("$rel —${IZIN[$f]}")
    continue
  fi
  n="$(wc -l < "$f" | tr -d ' ')"
  if [ -n "${DITES[$f]:-}" ]; then
    printf '  %5s  %s  (masih diimpor tes)\n' "$n" "$rel"
    DIPAKAI_TES=$((DIPAKAI_TES+1))
  else
    printf '  %5s  %s\n' "$n" "$rel"
  fi
  YATIM=$((YATIM+1)); BARIS=$((BARIS+n))
done < <(find "$LIB" -name '*.dart' ! -name '*.g.dart' ! -name '*.freezed.dart' | sort)

if [ "${#DIIZINKAN[@]}" -gt 0 ]; then
  echo "Belum disambung, sudah dijadwalkan (tool/find_orphans.allow):"
  for x in "${DIIZINKAN[@]}"; do echo "         $x"; done
fi

# Entri izin yang ternyata sudah terjangkau — atau berkasnya sudah tidak ada —
# harus dicabut, supaya daftar izin tidak diam-diam jadi tempat sembunyi.
for f in "${!IZIN[@]}"; do
  if [ ! -f "$f" ] || [ -n "${SAMPAI[$f]:-}" ]; then
    echo "→ Cabut dari tool/find_orphans.allow (sudah terjangkau atau tidak ada): ${f#"$ROOT"/}"
  fi
done

if [ "$YATIM" -eq 0 ]; then
  echo "✓ Nol berkas yatim — semua berkas di app/lib terjangkau dari main.dart."
else
  echo "→ $YATIM berkas yatim, $BARIS baris ($DIPAKAI_TES di antaranya masih diimpor tes)."
fi

[ "$STRICT" -eq 1 ] && [ "$YATIM" -gt 0 ] && exit 1
exit 0
