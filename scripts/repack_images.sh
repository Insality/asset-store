#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/image_utils.sh"

ASSETS_ROOT="$ROOT"
CONTENT_FOLDER=""
DRY_RUN=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --assets-root)
      ASSETS_ROOT="$2"
      shift 2
      ;;
    --content)
      CONTENT_FOLDER="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    *)
      echo "Usage: $0 [--assets-root DIR] [--content FOLDER] [--dry-run]" >&2
      exit 1
      ;;
  esac
done

if [[ "$ASSETS_ROOT" != /* ]]; then
  ASSETS_ROOT="$ROOT/$ASSETS_ROOT"
fi

STORES_JSON="${ROOT}/stores.json"
if [[ ! -f "$STORES_JSON" ]]; then
  echo "Missing $STORES_JSON" >&2
  exit 1
fi

if [[ -n "$CONTENT_FOLDER" ]]; then
  content_folders=("$CONTENT_FOLDER")
else
  content_folders=()
  while IFS= read -r c; do
    [[ -n "$c" ]] && content_folders+=("$c")
  done < <(jq -r '.stores[] | .content // empty' "$STORES_JSON")
fi

TARGET_WIDTH=146

update_manifest_image() {
  local manifest="$1"
  local new_value="$2"
  sed -E 's|("image"[[:space:]]*:[[:space:]]*")[^"]*|\1'"$new_value"'|' "$manifest" > "${manifest}.tmp" && mv "${manifest}.tmp" "$manifest"
}

for content in "${content_folders[@]}"; do
  src_dir="$ASSETS_ROOT/$content"
  if [[ ! -d "$src_dir" ]]; then
    continue
  fi

  shopt -s nullglob
  for manifest in "$src_dir"/*/*.json "$src_dir"/*/*/*.json; do
    [[ -f "$manifest" ]] || continue
    asset_dir="$(dirname "$manifest")"
    asset_folder="$(basename "$asset_dir")"
    name_no_ext="$(basename "$manifest" .json)"
    if [[ "$asset_folder" != "$name_no_ext" ]]; then
      continue
    fi

    image_rel="$(jq -r '.image // empty' "$manifest")"
    if [[ -z "$image_rel" || "$image_rel" == "null" ]]; then
      continue
    fi

    if [[ "$image_rel" =~ ^https?:// ]]; then
      img_name="$(extract_image_name_from_url "$image_rel")"
      output_name="${img_name%.*}.jpg"
      output_path="$asset_dir/$output_name"
      if [[ "$DRY_RUN" == true ]]; then
        echo "[dry-run] Would download $image_rel -> $asset_dir, resize to $output_name"
        continue
      fi
      downloaded="$asset_dir/.repack_$img_name"
      if ! download_image_from_url "$image_rel" "$downloaded"; then
        echo "  ⚠ Failed to download: $image_rel" >&2
        continue
      fi
      width="$(get_image_width "$downloaded")"
      if [[ -n "$width" && "$width" -gt 0 && "$width" -le "$TARGET_WIDTH" ]]; then
        mv -f "$downloaded" "$asset_dir/$img_name"
        update_manifest_image "$manifest" "$img_name"
      elif resize_image "$downloaded" "$output_path" "$TARGET_WIDTH"; then
        rm -f "$downloaded"
        update_manifest_image "$manifest" "$output_name"
      else
        rm -f "$downloaded"
        echo "  ⚠ Resize failed for $manifest" >&2
      fi
    else
      source_path="$asset_dir/$image_rel"
      if [[ ! -f "$source_path" ]]; then
        echo "  ⚠ Missing image: $source_path" >&2
        continue
      fi
      width="$(get_image_width "$source_path")"
      if [[ -n "$width" && "$width" -gt 0 && "$width" -le "$TARGET_WIDTH" ]]; then
        continue
      fi
      output_name="${image_rel%.*}.jpg"
      output_path="$asset_dir/$output_name"
      if [[ "$DRY_RUN" == true ]]; then
        echo "[dry-run] Would resize $source_path -> $output_path, update manifest"
        continue
      fi
      if resize_image "$source_path" "$output_path" "$TARGET_WIDTH"; then
        if [[ "$(basename "$source_path")" != "$(basename "$output_path")" ]]; then
          rm -f "$source_path"
        fi
        update_manifest_image "$manifest" "$output_name"
      else
        echo "  ⚠ Resize failed for $manifest" >&2
      fi
    fi
  done
done
