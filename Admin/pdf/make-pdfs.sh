#!/bin/bash
# Regenerate PDFs for Admin/*.md reports with a shared style.
# Usage: Admin/pdf/make-pdfs.sh
set -euo pipefail

cd "$(dirname "$0")/.."   # -> Admin/
DATE="$(date '+%-d %B %Y')"
PANDOC=/usr/local/bin/pandoc   # the .cabal/bin/pandoc on this machine is a stale i386 binary

for f in *.md; do
  [ "$f" = "README.md" ] && continue
  title="$(sed -n '1s/^# //p' "$f")"
  out="pdf/${f%.md}.pdf"
  echo "==> $f -> $out"
  # Drop the leading H1 (pandoc renders it via the title block instead)
  # Palatino has no -> glyph; swap it for a LaTeX math arrow xelatex can render.
  tail -n +2 "$f" | sed 's/→/$\\rightarrow$/g' | "$PANDOC" \
    --from=markdown \
    --pdf-engine=xelatex \
    --include-in-header=pdf/header.tex \
    --toc --toc-depth=2 \
    --metadata title="$title" \
    --metadata date="$DATE" \
    -V mainfont="Palatino" \
    -V monofont="Menlo" \
    -V fontsize=11pt \
    -V geometry:margin=1in \
    -V linkcolor=NavyBlue \
    -o "$out"
done
