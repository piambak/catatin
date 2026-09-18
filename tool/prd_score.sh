#!/usr/bin/env bash
#
# Mengukur kriteria terukur PRD redesain UI (wiki/desain/prd-redesain-ui.md §7)
# terhadap app/lib, lalu mencetaknya sebagai tabel.
#
# Kenapa ada: audit 12 Sep menemukan DUA kriteria yang justru MUNDUR sejak PRD
# ditulis — `BoxShadow` 3 → 6 dan `accounting_screen.dart` 1.731 → 1.827 baris.
# Tidak ada yang menyadarinya karena tidak ada yang mengukur. Skrip ini membuat
# angkanya muncul di setiap PR, sehingga kemunduran ketahuan saat terjadi,
# bukan pada audit berikutnya.
#
# Pemakaian:
#   bash tool/prd_score.sh              # tabel teks, selalu keluar 0
#   bash tool/prd_score.sh --markdown   # tabel Markdown (untuk ringkasan CI)
#   bash tool/prd_score.sh --strict     # keluar 1 kalau ada kriteria GAGAL
#
# `--strict` sengaja BELUM dinyalakan di CI. Dinyalakan Minggu 3, setelah
# accounting_screen.dart dipecah (issue #52) — lihat wiki/proyek/rencana-frontend.md.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LIB="$ROOT/app/lib"
MARKDOWN=0
STRICT=0

for arg in "$@"; do
  case "$arg" in
    --markdown|-m) MARKDOWN=1 ;;
    --strict|-s)   STRICT=1 ;;
    *) echo "✗ Argumen tidak dikenal: $arg" >&2; exit 2 ;;
  esac
done

[ -d "$LIB" ] || { echo "✗ $LIB tidak ada. Jalankan dari repo catatin." >&2; exit 1; }

# grep yang tidak pernah menggagalkan skrip saat nol hasil.
count() { grep -rnE "$1" "$LIB" --include=*.dart 2>/dev/null | grep -vE "${2:-$^}" | wc -l | tr -d ' '; }
countf() { grep -rlE "$1" "$LIB" --include=*.dart 2>/dev/null | wc -l | tr -d ' '; }

NAMA=(); NILAI=(); TARGET=(); STATUS=(); CATATAN=()
GAGAL=0

# nama | nilai | operator | ambang | catatan
ukur() {
  local nama="$1" nilai="$2" op="$3" ambang="$4" catatan="${5:-}"
  local ok=1
  case "$op" in
    le) [ "$nilai" -le "$ambang" ] || ok=0 ;;
    lt) [ "$nilai" -lt "$ambang" ] || ok=0 ;;
    eq) [ "$nilai" -eq "$ambang" ] || ok=0 ;;
  esac
  NAMA+=("$nama"); NILAI+=("$nilai")
  case "$op" in
    le) TARGET+=("<= $ambang") ;;
    lt) TARGET+=("< $ambang") ;;
    eq) TARGET+=("$ambang") ;;
  esac
  if [ "$ok" -eq 1 ]; then STATUS+=("OK"); else STATUS+=("GAGAL"); GAGAL=$((GAGAL+1)); fi
  CATATAN+=("$catatan")
}

# ── R-2: nol bayangan ────────────────────────────────────────────────────────
ukur "BoxShadow (R-2)" "$(count 'BoxShadow')" eq 0 "dua pemakaian sah di ds_widgets.dart per catatan desain"

# ── R-5: modal seperlunya ────────────────────────────────────────────────────
ukur "showDialog (R-5)" "$(count 'showDialog')" le 4 "sisanya harus konfirmasi destruktif"

# ── R-4: breakpoint hanya dari Bp ────────────────────────────────────────────
ukur "Breakpoint literal (R-4)" \
  "$(count '(maxWidth|minWidth|\bwidth)\s*[:>=<]+\s*(500|680)\b' 'core/theme/breakpoints.dart')" \
  eq 0 "hanya yang dipakai sebagai lebar tata letak"

# ── R-3: satu sistem tipografi & warna ───────────────────────────────────────
ukur "fontFamily monospace (R-3)" "$(count "fontFamily: 'monospace'")" eq 0 "harus lewat Typo.mono"

TOKEN_LAMA=$(grep -cE '^\s+static (const|Color get) ' "$LIB/core/theme/app_theme.dart" 2>/dev/null || echo 0)
TOKEN_BARU=$(sed -n '/^class DS {/,/^}/p' "$LIB/core/theme/design_tokens.dart" 2>/dev/null | grep -cE 'static (const|Color get) ' || echo 0)
ukur "Token warna (R-3)" "$((TOKEN_LAMA + TOKEN_BARU))" le 16 "AppColors=$TOKEN_LAMA + DS=$TOKEN_BARU; AppColors dihapus di issue #53"

# ── R-7: berkas & kelas yang bisa dibaca ─────────────────────────────────────
ukur "Kelas widget privat (R-7)" \
  "$(count '^class _[A-Za-z0-9_]+ extends (StatelessWidget|StatefulWidget)')" lt 40 \
  "dipecah di issue #52"

BARIS_AKUN=$(wc -l < "$LIB/screens/accounting/accounting_screen.dart" 2>/dev/null || echo 0)
ukur "Baris accounting_screen.dart (R-7)" "$BARIS_AKUN" lt 400 "dipecah di issue #52"

# ── R-8: satu sumber logika kalender ─────────────────────────────────────────
ukur "Berkas berlogika kalender (R-8)" "$(countf 'weekday')" le 1 "disatukan di issue #66"

# ── Sisa deprecated ──────────────────────────────────────────────────────────
ukur "withOpacity" "$(count 'withOpacity')" eq 0 "sudah selesai (T-6)"

# ── R-4: orientasi dibuka untuk web ──────────────────────────────────────────
if grep -q 'kIsWeb' "$LIB/main.dart" 2>/dev/null; then ORIENTASI=0; else ORIENTASI=1; fi
ukur "Orientasi dikunci di web (R-4)" "$ORIENTASI" eq 0 "1 = masih dikunci; dibuka di issue #67 (D-16)"

# ── Cetak ────────────────────────────────────────────────────────────────────
if [ "$MARKDOWN" -eq 1 ]; then
  echo "| Kriteria | Nilai | Target | Status | Catatan |"
  echo "| --- | ---: | ---: | --- | --- |"
  for i in "${!NAMA[@]}"; do
    ikon="✅"; [ "${STATUS[$i]}" = "GAGAL" ] && ikon="❌"
    echo "| ${NAMA[$i]} | ${NILAI[$i]} | ${TARGET[$i]} | $ikon ${STATUS[$i]} | ${CATATAN[$i]} |"
  done
  echo
  echo "**${GAGAL} dari ${#NAMA[@]} kriteria masih gagal.**"
  [ "$STRICT" -eq 0 ] && echo "> Non-blocking. \`--strict\` dinyalakan mulai Minggu 3 (issue #57)."
else
  printf '\n%-36s %8s %8s  %-6s %s\n' "KRITERIA" "NILAI" "TARGET" "STATUS" "CATATAN"
  printf '%s\n' "$(printf '─%.0s' {1..110})"
  for i in "${!NAMA[@]}"; do
    printf '%-36s %8s %8s  %-6s %s\n' \
      "${NAMA[$i]}" "${NILAI[$i]}" "${TARGET[$i]}" "${STATUS[$i]}" "${CATATAN[$i]}"
  done
  printf '%s\n' "$(printf '─%.0s' {1..110})"
  echo "${GAGAL} dari ${#NAMA[@]} kriteria masih gagal."
  [ "$STRICT" -eq 0 ] && echo "(non-blocking; --strict dinyalakan Minggu 3 — issue #57)"
fi

[ "$STRICT" -eq 1 ] && [ "$GAGAL" -gt 0 ] && exit 1
exit 0
