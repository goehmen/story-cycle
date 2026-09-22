#!/usr/bin/env bash
#
# build-workflow-doc.sh
#
# Convert a workflow markdown doc to Google-Docs-friendly HTML using pandoc
# with project-standard formatting helpers (table CSS + horizontal-rule
# stripper). Output lands alongside the input with the same basename and a
# .html extension.
#
# Usage:
#   ./scripts/build-workflow-doc.sh <path-to-md-file>
#
# Example:
#   ./scripts/build-workflow-doc.sh docs/story-cycle-guide-v6.5.md
#   # → docs/story-cycle-guide-v6.5.html
#
# Post-build steps for Google Docs:
#   1. Upload the .html file to Google Drive
#   2. Right-click → Open with → Google Docs
#   3. Place cursor at top → Insert → Table of contents → "With blue links"
#   (Pandoc's --toc is intentionally omitted — its anchor links break on GD
#    import; the native GD TOC works correctly.)

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <path-to-md-file>" >&2
  exit 1
fi

INPUT="$1"

if [[ ! -f "$INPUT" ]]; then
  echo "Error: input file not found: $INPUT" >&2
  exit 1
fi

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HEADER="$REPO_ROOT/docs/_pandoc/header.html"
LUA_FILTER="$REPO_ROOT/docs/_pandoc/remove-hr.lua"
OUTPUT="${INPUT%.md}.html"

if [[ ! -f "$HEADER" ]]; then
  echo "Error: header file not found: $HEADER" >&2
  exit 1
fi

if [[ ! -f "$LUA_FILTER" ]]; then
  echo "Error: lua filter not found: $LUA_FILTER" >&2
  exit 1
fi

pandoc "$INPUT" \
  --standalone \
  --include-in-header="$HEADER" \
  --lua-filter="$LUA_FILTER" \
  -o "$OUTPUT"

echo "Built: $OUTPUT"
echo ""
echo "Next steps:"
echo "  1. Upload $OUTPUT to Google Drive"
echo "  2. Right-click → Open with → Google Docs"
echo "  3. Insert → Table of contents → 'With blue links'"
