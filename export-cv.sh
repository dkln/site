#!/usr/bin/env bash
# Export cv_pdf_download.html to PDF with headless Chrome.
# Usage: ./export-cv.sh [output.pdf]
# Default output is ~/Downloads, outside the repo: the PDF contains personal details.
set -euo pipefail

dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
src="$dir/cv_pdf_download.html"
out="${1:-$HOME/Downloads/CV.pdf}"
chrome="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"
timeout=45

[[ -x "$chrome" ]] || { echo "Chrome niet gevonden: $chrome (zet CHROME=/pad/naar/chrome)" >&2; exit 1; }
[[ -f "$src" ]] || { echo "Bronbestand niet gevonden: $src" >&2; exit 1; }
[[ -d "$(dirname "$out")" ]] || { echo "Map bestaat niet: $(dirname "$out")" >&2; exit 1; }

tmp="$(mktemp -d)"
pid=""
cleanup() {
  if [[ -n "$pid" ]]; then kill "$pid" 2>/dev/null || true; wait "$pid" 2>/dev/null || true; fi
  rm -rf "$tmp" 2>/dev/null || true
}
trap cleanup EXIT

"$chrome" --headless=new --disable-gpu --no-first-run --user-data-dir="$tmp/profile" \
  --virtual-time-budget=10000 --no-pdf-header-footer \
  --print-to-pdf="$tmp/cv.pdf" "file://${src// /%20}" >"$tmp/log" 2>&1 &
pid=$!

# Chrome may keep running after writing the PDF, so wait for a complete file instead.
for ((i = 0; i < timeout * 2; i++)); do
  if [[ -s "$tmp/cv.pdf" ]] && tail -c 32 "$tmp/cv.pdf" | grep -qa '%%EOF'; then
    mv -f "$tmp/cv.pdf" "$out"
    echo "CV geëxporteerd: $out"
    exit 0
  fi
  if ! kill -0 "$pid" 2>/dev/null && [[ ! -s "$tmp/cv.pdf" ]]; then break; fi
  sleep 0.5
done

echo "Export mislukt. Uitvoer van Chrome:" >&2
cat "$tmp/log" >&2
exit 1
