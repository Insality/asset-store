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

# Read each store index and download ZIPs, images, manifests, and collect example URLs
for store_index in $(jq -r '.stores[].index' /tmp/old_stores.json | sed 's|.*/||'); do
  if ! curl -f -s "$BASE_URL/$store_index" -o "/tmp/$store_index" 2>/dev/null; then
    continue
  fi

  # Download ZIPs (only if they don't exist locally)
  jq -r '.items[]?.zip_url // empty' "/tmp/$store_index" | while IFS= read -r zip_url; do
    if [[ -n "$zip_url" && "$zip_url" == "$BASE_URL/"* ]]; then
      zip_path=$(echo "$zip_url" | sed "s|$BASE_URL/||")
      if [[ ! -f "$DIST_DIR/$zip_path" ]]; then
        mkdir -p "$DIST_DIR/$(dirname "$zip_path")"
        curl -f -s "$zip_url" -o "$DIST_DIR/$zip_path" 2>/dev/null || true
      fi
    fi
  done

  # Download images
  jq -r '.items[]?.image // empty' "/tmp/$store_index" | while IFS= read -r img_url; do
    if [[ -n "$img_url" && "$img_url" == "$BASE_URL/"* ]]; then
      img_path=$(echo "$img_url" | sed "s|$BASE_URL/||")
      mkdir -p "$DIST_DIR/$(dirname "$img_path")"
      curl -f -s "$img_url" -o "$DIST_DIR/$img_path" 2>/dev/null || true
    fi
  done

  # Download manifests
  jq -r '.items[]?.manifest_url // empty' "/tmp/$store_index" | while IFS= read -r manifest_url; do
    if [[ -n "$manifest_url" && "$manifest_url" == "$BASE_URL/"* ]]; then
      manifest_path=$(echo "$manifest_url" | sed "s|$BASE_URL/||")
      mkdir -p "$DIST_DIR/$(dirname "$manifest_path")"
      curl -f -s "$manifest_url" -o "$DIST_DIR/$manifest_path" 2>/dev/null || true
    fi
  done

  # Collect example URLs (restore all versions including old ones)
  jq -r '.items[]?.example_url // empty' "/tmp/$store_index" >> /tmp/all_example_urls.txt 2>/dev/null || true
done

# Restore examples
if [[ -f /tmp/all_example_urls.txt ]]; then
  echo "📦 Restoring examples..."
  sort -u /tmp/all_example_urls.txt | while IFS= read -r example_url; do
    if [[ -z "$example_url" || "$example_url" == "null" || "$example_url" != "$BASE_URL/"* ]]; then
      continue
    fi

    example_path=$(echo "$example_url" | sed "s|$BASE_URL/||" | sed "s|/index.html$||")
    if [[ -z "$example_path" ]]; then
      continue
    fi

    # Skip if already exists
    if [[ -d "$DIST_DIR/$example_path" && -f "$DIST_DIR/$example_path/index.html" && -f "$DIST_DIR/$example_path/dmloader.js" ]]; then
      echo "  ✅ EXM: $example_path (already exists)"
      continue
    fi

    # Check if example exists on GitHub Pages
    if ! curl -f -s "$example_url" -o /dev/null 2>/dev/null; then
      continue
    fi

    # Download all example files
    example_base_url=$(echo "$example_url" | sed "s|/index.html$||")
    mkdir -p "$DIST_DIR/$example_path"

    # Download main files
    downloaded=0
    for file in index.html dmloader.js; do
      if curl -f -s "$example_base_url/$file" -o "$DIST_DIR/$example_path/$file" 2>/dev/null; then
        downloaded=$((downloaded + 1))
      fi
    done

    # Download archive files
    mkdir -p "$DIST_DIR/$example_path/archive"
    for file in game0.public.der game0.dmanifest game0.arci game0.arcd game0.projectc archive_files.json; do
      curl -f -s "$example_base_url/archive/$file" -o "$DIST_DIR/$example_path/archive/$file" 2>/dev/null || true
    done

    if [[ $downloaded -gt 0 ]]; then
      echo "  ✅ EXM: $example_path (restored $downloaded file(s))"
    else
      echo "  ⚠️  EXM: $example_path (exists but files not downloaded)"
    fi
  done
  rm -f /tmp/all_example_urls.txt
fi

echo "✅ Old assets restored"
