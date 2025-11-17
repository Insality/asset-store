#!/usr/bin/env bash
# Local testing script for pack_all_stores.sh
# Usage: bash scripts/test_local.sh

set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🧪 Local Test Mode"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Clean up previous test artifacts
if [[ -d "$ROOT/dist" ]]; then
  echo "🗑️  Cleaning up previous dist/ directory..."
  rm -rf "$ROOT/dist"
fi

# Set up test environment variables
export ASSETS_ROOT="$ROOT"
export DIST_DIR="$ROOT/dist"
export BASE_URL="https://example.github.io/test-repo"  # Test URL

echo "Running pack_all_stores.sh with:"
echo "   ASSETS_ROOT=$ASSETS_ROOT"
echo "   DIST_DIR=$DIST_DIR"
echo "   BASE_URL=$BASE_URL"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run the packing script
bash "$ROOT/scripts/pack_all_stores.sh"

# Show results
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 Test Results"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [[ ! -d "$DIST_DIR" ]]; then
  echo "❌ ERROR: dist/ directory was not created!"
  exit 1
fi

echo "📂 Directory structure:"
find "$DIST_DIR" -type f -o -type d | sort
echo ""

echo "📊 File sizes:"
find "$DIST_DIR" -type f -exec ls -lh {} \; | awk '{print $5 "\t" $9}'
echo ""

echo "📄 Generated JSON indices:"
for json in "$DIST_DIR"/*.json; do
  if [[ -f "$json" ]]; then
    echo ""
    echo "───────────────────────────────────────────────────────"
    echo "File: $(basename "$json")"
    echo "───────────────────────────────────────────────────────"
    cat "$json" | jq '.'
  fi
done

echo ""
echo "✅ Local test complete!"
echo ""
echo "To clean up: rm -rf $DIST_DIR"

