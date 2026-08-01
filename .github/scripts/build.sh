#!/usr/bin/env bash
# Builds every shape of the example site from template/main.typ: the website,
# the course reader in both editions, and the one-page HTML reader.
#
# The template imports @preview/coconut:<version> exactly as a published
# consumer does, so it is compiled against the working tree staged into dist/
# rather than against whatever is on Typst Universe.
#
# Usage: .github/scripts/build.sh [output directory]   (default: build)

set -euo pipefail

cd "$(dirname "$0")/../.."

out="${1:-build}"

node .github/scripts/stage-package.mjs --out dist

rm -rf "$out"
mkdir -p "$out/site" "$out/reader"

# --pdf-standard ua-1 makes Typst enforce PDF/UA on every PDF it emits, which
# is the PDF half of the accessibility check; axe covers the HTML.
typst compile template/main.typ \
  --package-path dist \
  --features bundle,html \
  --format bundle \
  --pdf-standard ua-1 \
  "$out/site"

typst compile template/main.typ \
  --package-path dist \
  --features bundle,html \
  --format pdf \
  --pdf-standard ua-1 \
  "$out/reader/course-reader.pdf"

# The large-print reader. Bundle export writes both editions of every page in
# the one pass above, because it emits as many documents as it likes; a
# single-document build writes exactly one PDF, so the edition is chosen on the
# command line and the reader is compiled a second time.
typst compile template/main.typ \
  --package-path dist \
  --features bundle,html \
  --format pdf \
  --pdf-standard ua-1 \
  --input large-print=true \
  "$out/reader/course-reader-large-print.pdf"

typst compile template/main.typ \
  --package-path dist \
  --features bundle,html \
  --format html \
  "$out/reader/course-reader.html"

echo "Built the website into $out/site and the course reader into $out/reader"
echo "Every PDF in both is emitted twice: standard size, and large print at 18 point"
