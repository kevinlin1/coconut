#!/usr/bin/env bash
# Builds all three shapes of the example site from template/main.typ.
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

typst compile template/main.typ \
  --package-path dist \
  --features bundle,html \
  --format html \
  "$out/reader/course-reader.html"

echo "Built the website into $out/site and the course reader into $out/reader"
