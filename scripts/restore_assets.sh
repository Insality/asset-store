#!/usr/bin/env bash
set -euo pipefail

# Restore old assets from GitHub Pages to preserve old versions
BASE_URL="${1:-}"
DIST_DIR="${DIST_DIR:-dist}"

if [[ -z "$BASE_URL" ]]; then
  echo "Usage: $0 <BASE_URL>"
  exit 1
fi

mkdir -p "$DIST_DIR"
echo "📥 Downloading existing assets from: $BASE_URL"

# Try to download stores.json to get list of all stores
if ! curl -f -s "$BASE_URL/stores.json" -o /tmp/old_stores.json 2>/dev/null; then
  echo "ℹ️  No existing stores.json found, starting fresh"
  exit 0
fi

echo "✅ Found existing stores.json"

# Restore examples from zip archive (skip when REBUILD_EXAMPLES is set)
examples_zip_url="$BASE_URL/examples.zip"
examples_zip_path="$DIST_DIR/examples.zip"

if [[ -n "${REBUILD_EXAMPLES:-}" && "${REBUILD_EXAMPLES}" != "0" && "${REBUILD_EXAMPLES}" != "false" ]]; then
  echo "🔄 Rebuild examples requested, skipping examples restore"
elif curl -f -s -I "$examples_zip_url" -o /dev/null 2>/dev/null; then
  echo "📦 Downloading examples.zip archive..."
  if curl -f -s -L --retry 2 --max-time 300 "$examples_zip_url" -o "$examples_zip_path" 2>/dev/null; then
    echo "  ✅ Downloaded examples.zip"
    echo "  📂 Extracting examples..."
    if unzip -q -o "$examples_zip_path" -d "$DIST_DIR" 2>/dev/null; then
      example_count=$(find "$DIST_DIR/examples" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
      echo "  ✅ Extracted $example_count example(s)"
      rm -f "$examples_zip_path"
    else
      echo "  ⚠️  Warning: Failed to extract examples.zip"
      rm -f "$examples_zip_path"
    fi
  else
    echo "  ⚠️  Warning: Failed to download examples.zip"
  fi
else
  echo "ℹ️  No examples.zip found, examples will be built from scratch"
fi

echo "✅ Old assets restored"
