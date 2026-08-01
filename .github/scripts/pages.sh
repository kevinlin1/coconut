#!/usr/bin/env bash
# Assembles the directory GitHub Pages serves, from a completed build.
#
# The website goes at the root of the site rather than under a subdirectory, so
# every relative link the bundle emits — the navigation, the "download this page
# as a PDF" link beside each title, the cross-page links in the schedule —
# resolves exactly as it does in a local build. The single-document reader is
# copied in beside it under its own name instead of into a subdirectory of its
# own, because a directory with no index.html serves a 404.
#
# Usage: .github/scripts/pages.sh [build directory] [output directory]
#        (defaults: build, build/pages)

set -euo pipefail
shopt -s nullglob

cd "$(dirname "$0")/../.."

build="${1:-build}"
out="${2:-$build/pages}"

site="$build/site"
reader="$build/reader"

for dir in "$site" "$reader"; do
  if [ ! -d "$dir" ]; then
    echo "error: $dir does not exist. Run .github/scripts/build.sh first." >&2
    exit 1
  fi
done

# Pages serves index.html for the site root; without one, the published course
# site opens on a 404 no matter how many pages the bundle emitted.
if [ ! -f "$site/index.html" ]; then
  echo "error: $site has no index.html, so the published site would have no landing page." >&2
  echo "  One page in the bundle needs \`path: \"index\"\`." >&2
  exit 1
fi

rm -rf "$out"
mkdir -p "$out"
cp -R "$site/." "$out/"

# The reader lands among the per-page PDFs, so a route named `course-reader`
# would otherwise be overwritten by it without a word.
for file in "$reader"/*; do
  name="$(basename "$file")"
  if [ -e "$out/$name" ]; then
    echo "error: the reader file $name collides with a page of the same name in $site." >&2
    echo "  Rename that page, or rename the reader output in .github/scripts/build.sh." >&2
    exit 1
  fi
  cp "$file" "$out/$name"
done

echo "Assembled the GitHub Pages root in $out ($(find "$out" -type f | wc -l) files)"
