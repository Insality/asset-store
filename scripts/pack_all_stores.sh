#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_STORES_JSON="$ROOT/stores.json"

# GitHub repository info (can be overridden by environment variables)
GITHUB_OWNER="${GITHUB_OWNER:-Insality}"
GITHUB_REPO="${GITHUB_REPO:-asset-store}"
GITHUB_BRANCH="${GITHUB_BRANCH:-main}"

# Convert ASSETS_ROOT to absolute path if relative
if [[ -n "${ASSETS_ROOT:-}" ]]; then
  if [[ "$ASSETS_ROOT" != /* ]]; then
    ASSETS_ROOT="$ROOT/$ASSETS_ROOT"
  fi
else
  ASSETS_ROOT="$ROOT"
fi

# Convert DIST_DIR to absolute path if relative
if [[ -n "${DIST_DIR:-}" ]]; then
  if [[ "$DIST_DIR" != /* ]]; then
    DIST_DIR="$ROOT/$DIST_DIR"
  fi
else
  DIST_DIR="$ROOT/dist"
fi

# Create dist directory
mkdir -p "$DIST_DIR"

BASE_URL="${BASE_URL:-}"  # set by CI to Pages URL

require() { command -v "$1" >/dev/null 2>&1 || { echo "Missing '$1'"; exit 1; }; }
require jq
require zip
require zipinfo
# Check for sha256 command (either sha256sum or shasum)
if ! command -v sha256sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1; then
  echo "Missing sha256 command (need either 'sha256sum' or 'shasum')"
  exit 1
fi

# Helper functions
ensure_dir() {
  local path="$1"
  [[ ! -d "$path" ]] && mkdir -p "$path" || true
}

get_file_size() {
  local path="$1"
  if stat -c%s "$path" >/dev/null 2>&1; then
    stat -c%s "$path"  # Linux
  else
    stat -f%z "$path"  # macOS/BSD
  fi
}

get_sha256() {
  local path="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$path" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$path" | awk '{print $1}'
  else
    echo "ERROR: No sha256 command found" >&2
    exit 1
  fi
}

get_download_stats() {
  echo '{"total":0,"week":0,"month":0}'
}

encode_base64() {
  local path="$1"
  if base64 --version 2>&1 | grep -q GNU; then
    base64 -w 0 "$path"  # Linux
  else
    base64 -i "$path"     # macOS
  fi
}

# Generate GitHub URL from file path (handles absolute URLs, absolute paths, and relative paths)
generate_github_url() {
  local file_path="$1"
  local asset_dir="$2"

  if [[ -z "$file_path" || "$file_path" == "null" ]]; then
    echo ""
    return
  fi

  # Already an absolute URL
  if [[ "$file_path" =~ ^https?:// ]]; then
    echo "$file_path"
    return
  fi

  # Absolute path from repository root
  if [[ "$file_path" =~ ^/ ]]; then
    local full_path="$ASSETS_ROOT$file_path"
    if [[ -f "$full_path" ]]; then
      local relative_path="${file_path#/}"
      echo "https://github.com/$GITHUB_OWNER/$GITHUB_REPO/blob/$GITHUB_BRANCH/$relative_path"
      return
    fi
  fi

  # Relative path from asset directory
  local normalized_path="$file_path"
  [[ "$normalized_path" =~ ^\./ ]] && normalized_path="${normalized_path#./}"

  if [[ -f "$asset_dir/$normalized_path" ]]; then
    local relative_path="${asset_dir#$ASSETS_ROOT/}/$normalized_path"
    echo "https://github.com/$GITHUB_OWNER/$GITHUB_REPO/blob/$GITHUB_BRANCH/$relative_path"
    return
  fi

  echo ""
}

# Copy manifest to dist directory and return URL
copy_manifest() {
  local manifest="$1"
  local content_folder="$2"
  local author="$3"
  local id="$4"

  local manifest_dist_dir="$DIST_DIR/manifests/$content_folder/$author"
  ensure_dir "$manifest_dist_dir"
  cp -f "$manifest" "$manifest_dist_dir/${id}.json"
  echo "${BASE_URL:+$BASE_URL/}manifests/$content_folder/$author/${id}.json"
}

# Copy image to dist directory and return URL (empty string if no image)
copy_image() {
  local image_rel="$1"
  local asset_dir="$2"
  local author="$3"
  local id="$4"

  if [[ -z "$image_rel" || "$image_rel" == "null" ]]; then
    echo ""
    return
  fi

  # If image_rel is a URL (starts with http:// or https://), return it as is
  if [[ "$image_rel" =~ ^https?:// ]]; then
    echo "$image_rel"
    return
  fi

  # Otherwise, it's a local file path - check if it exists and copy it
  if [[ ! -f "$asset_dir/$image_rel" ]]; then
    echo ""
    return
  fi

  local image_dir="$DIST_DIR/images/$author/$id"
  ensure_dir "$image_dir"
  cp -f "$asset_dir/$image_rel" "$image_dir/"
  local img_name
  img_name="$(basename "$image_rel")"
  echo "${BASE_URL:+$BASE_URL/}images/$author/$id/$img_name"
}


# Create asset ZIP file
create_asset_zip() {
  local zip_path="$1"
  local asset_dir="$2"
  local content_items=("${@:3}")

  ensure_dir "$(dirname "$zip_path")"

  if [[ ! -f "$zip_path" ]]; then
    ( cd "$asset_dir" && zip -q -r "$zip_path" "${content_items[@]}" )
  fi

  if [[ ! -f "$zip_path" ]]; then
    echo "  ❌ ERROR: Failed to create ZIP at $zip_path" >&2
    exit 1
  fi
}

# Create base64 JSON version of ZIP
create_json_zip() {
  local zip_path="$1"
  local zip_name="$2"
  local content_folder="$3"

  local json_zip_name="${zip_name}.json"
  local json_zip_path="$DIST_DIR/$content_folder/$json_zip_name"
  local size
  size="$(get_file_size "$zip_path")"
  local base64_data
  base64_data="$(encode_base64 "$zip_path")"
  local zip_content
  zip_content="$(zipinfo -1 "$zip_path" | jq -R -s -c 'split("\n") | map(select(length > 0 and (. | endswith("/") | not)))')"

  jq -n \
    --arg data "$base64_data" \
    --arg filename "$zip_name" \
    --arg size "$size" \
    --argjson content "$zip_content" \
    '{"data": $data, "filename": $filename, "size": ($size|tonumber), "content": $content}' \
    > "$json_zip_path"

  echo "${BASE_URL:+$BASE_URL/}$content_folder/$json_zip_name"
}

# Build item JSON for folder store
build_folder_item_json() {
  local id="$1" version="$2" title="$3" author="$4" description="$5"
  local api_url="$6" author_url="$7" example_url="$8" example_code_url="$9"
  local image_url="${10}" zip_url="${11}" json_zip_url="${12}" sha256="${13}"
  local manifest_url="${14}" size="${15}" depends="${16}" tags="${17}" unlisted="${18}"
  local stats="${19}"

  jq -n \
    --arg id "$id" --arg version "$version" --arg title "$title" \
    --arg author "$author" --arg description "$description" \
    --arg api "$api_url" --arg author_url "$author_url" --arg example_url "$example_url" \
    --arg example_code "$example_code_url" --arg image "$image_url" \
    --arg zip_url "$zip_url" --arg json_zip_url "$json_zip_url" --arg sha256 "$sha256" \
    --arg manifest_url "$manifest_url" --arg size "$size" \
    --argjson depends "$depends" --argjson tags "$tags" --argjson unlisted "$unlisted" \
    --argjson stats "$stats" \
    '{
      id: $id,
      version: $version,
      title: $title,
      author: (if $author == "" then null else $author end),
      description: (if $description == "" then null else $description end),
      api: (if $api == "" then null else $api end),
      author_url: (if $author_url == "" then null else $author_url end),
      image: (if $image == "" then null else $image end),
      example_url: (if $example_url == "" then null else $example_url end),
      example_code: (if $example_code == "" then null else $example_code end),
      manifest_url: $manifest_url,
      zip_url: $zip_url,
      json_zip_url: $json_zip_url,
      sha256: $sha256,
      size: ($size | tonumber),
      depends: $depends,
      tags: $tags,
      unlisted: $unlisted,
      popularity: $stats
    }'
}

# Build item JSON for dependency store
build_dependency_item_json() {
  local id="$1" version="$2" title="$3" author="$4" description="$5"
  local api_url="$6" author_url="$7" image_url="$8" manifest_url="$9"
  local depends="${10}" tags="${11}" content="${12}" unlisted="${13}"
  local stats="${14}" example_code="${15}" example_url="${16}" stars="${17}"

  jq -n \
    --arg id "$id" --arg version "$version" --arg title "$title" \
    --arg author "$author" --arg description "$description" \
    --arg api "$api_url" --arg author_url "$author_url" \
    --arg image "$image_url" --arg manifest_url "$manifest_url" \
    --arg example_code "$example_code" --arg example_url "$example_url" \
    --argjson depends "$depends" --argjson tags "$tags" --argjson content "$content" \
    --argjson unlisted "$unlisted" --argjson stats "$stats" \
    --arg stars "$stars" \
    '{
      id: $id,
      version: (if $version == "null" or $version == "" then null else $version end),
      title: $title,
      author: (if $author == "" then null else $author end),
      description: (if $description == "" then null else $description end),
      api: (if $api == "" then null else $api end),
      author_url: (if $author_url == "" then null else $author_url end),
      image: (if $image == "" then null else $image end),
      manifest_url: $manifest_url,
      example_code: (if $example_code == "" then null else $example_code end),
      example_url: (if $example_url == "" then null else $example_url end),
      depends: $depends,
      tags: $tags,
      content: $content,
      unlisted: $unlisted,
      popularity: $stats,
      stars: (if $stars == "null" or $stars == "" then null else ($stars | tonumber) end)
    }'
}

# Build example HTML if needed
build_example_if_needed() {
  local example_path="$1"
  local author="$2"
  local id="$3"
  local version="$4"
  local asset_dir="$5"
  local title="$6"
  local description="$7"
  local api_url="$8"
  local author_url="$9"
  local example_code_url="${10}"

  if [[ -z "$example_path" || "$example_path" == "null" ]]; then
    echo ""
    return
  fi

  local collection_proxy_path="$ROOT/example/example_proxy.collectionproxy"
  if [[ ! -f "$collection_proxy_path" ]]; then
    echo "  ❌ ERROR: Missing $collection_proxy_path" >&2
    echo ""
    return
  fi

  local example_dir_name="${author}:${id}@${version}"
  local example_output_dir="$DIST_DIR/examples/$example_dir_name"
  local example_url="${BASE_URL:+$BASE_URL/}examples/$example_dir_name/index.html"

  # Check if example directory already exists with required files (restored from GitHub Pages)
  # Do this BEFORE modifying the proxy file to avoid leaving it in wrong state
  if [[ -d "$example_output_dir" && -f "$example_output_dir/index.html" && -f "$example_output_dir/dmloader.js" ]]; then
    echo "$example_url"
    return
  fi

  local collection_path_for_proxy="$example_path"

  local tmp_proxy_backup
  tmp_proxy_backup="$(mktemp)"
  cp "$collection_proxy_path" "$tmp_proxy_backup"

  # Cleanup function: restore proxy file and remove INI file
  trap 'cp "$tmp_proxy_backup" "$collection_proxy_path" 2>/dev/null || true; rm -f "$tmp_proxy_backup" "$ROOT/build.ini"; trap - RETURN' RETURN

  printf 'collection: "%s"\n' "$collection_path_for_proxy" > "$collection_proxy_path"

  ensure_dir "$example_output_dir"

  # Remove existing INI file if it exists, then create new one
  local ini_file="build.ini"
  rm -f "$ROOT/$ini_file"

  {
    echo "[example]"
    echo "author = ${author:-}"
    echo "id = ${id:-}"
    echo "version = ${version:-}"
    if [[ -n "$example_code_url" && "$example_code_url" != "null" && "$example_code_url" != "" ]]; then
      echo "example_code_url = ${example_code_url}"
    fi
    if [[ -n "$title" && "$title" != "null" && "$title" != "" ]]; then
      echo "title = ${title}"
    fi
    if [[ -n "$description" && "$description" != "null" && "$description" != "" ]]; then
      echo "description = ${description}"
    fi
    if [[ -n "$api_url" && "$api_url" != "null" && "$api_url" != "" ]]; then
      echo "api_url = ${api_url}"
    fi
    if [[ -n "$author_url" && "$author_url" != "null" && "$author_url" != "" ]]; then
      echo "author_url = ${author_url}"
    fi
  } > "$ROOT/$ini_file"

  # Build using deployer
  local deployer_url="https://raw.githubusercontent.com/Insality/defold-deployer/refs/heads/update/deployer.sh"
  if (cd "$ROOT" && curl -s "${deployer_url}" | bash -s hbr --settings "$ini_file") >&2; then
    # Find the most recently created index.html
    local found_html=""
    found_html="$(find "$ROOT/dist/bundle" -name "index.html" -type f -path "*/_html/*" 2>/dev/null | head -1)"
    [[ -z "$found_html" ]] && found_html="$(find "$ROOT/dist/bundle" -name "index.html" -type f 2>/dev/null | head -1)"

    if [[ -n "$found_html" && -f "$found_html" ]]; then
      local src_dir; src_dir="$(dirname "$found_html")"
      ensure_dir "$example_output_dir"
      cp -r "$src_dir"/* "$example_output_dir/" 2>/dev/null || true

      if [[ -f "$example_output_dir/index.html" && -f "$example_output_dir/dmloader.js" ]]; then
        echo "$example_url"
      else
        echo ""
      fi
    else
      echo ""
    fi
  else
    echo ""
  fi

  # Cleanup handled by trap (proxy file restored, temp files removed)
}

pack_folder_store() {
  local store_name="$1" store_index="$2" content_folder="$3"
  local asset_type="item"

  local src_dir="$ASSETS_ROOT/$content_folder"
  local out_index="$DIST_DIR/$store_index"

  echo "📦 Store: $store_name"

  local tmp_index
  tmp_index="$(mktemp)"
  jq -n '{items:[]}' > "$tmp_index"

  if [[ ! -d "$src_dir" ]]; then
    echo "⚠️  Directory '$src_dir' does not exist, writing empty index"
    cp "$tmp_index" "$out_index"
    return
  fi

  shopt -s nullglob
  local all_manifests=()
  for manifest in "$src_dir"/*/*.json "$src_dir"/*/*/*.json; do
    all_manifests+=("$manifest")
  done

  for manifest in "${all_manifests[@]}"; do
    local asset_dir
    asset_dir="$(dirname "$manifest")"
    local asset_folder
    asset_folder="$(basename "$asset_dir")"
    local name_no_ext
    name_no_ext="$(basename "$manifest" .json)"

    if [[ "$asset_folder" != "$name_no_ext" ]]; then
      echo "  ⚠️  SKIP: $asset_folder != $name_no_ext"
      continue
    fi

    # Read manifest fields
    local id version title author description api author_url image_rel
    local depends tags example example_code example_url unlisted
    id="$(jq -r '.id // "'$asset_folder'"' "$manifest")"
    version="$(jq -r '.version' "$manifest")"
    title="$(jq -r '.title // "'$id'"' "$manifest")"
    author="$(jq -r '.author // empty' "$manifest")"
    description="$(jq -r '.description // empty' "$manifest")"
    api="$(jq -r '.api // empty' "$manifest")"
    author_url="$(jq -r '.author_url // empty' "$manifest")"
    example="$(jq -r '.example // empty' "$manifest")"
    example_code="$(jq -r '.example_code // empty' "$manifest")"
    example_url="$(jq -r '.example_url // empty' "$manifest")"
    image_rel="$(jq -r '.image // empty' "$manifest")"
    depends="$(jq -c '.depends // []' "$manifest")"
    tags="$(jq -c '.tags // []' "$manifest")"
    unlisted="$(jq -c '.unlisted // false' "$manifest")"

    if [[ -z "$version" || "$version" == "null" ]]; then
      echo "  ❌ ERROR: $author:$id@$version has no version" >&2
      exit 1
    fi

    if [[ -z "$author" || "$author" == "null" ]]; then
      echo "  ❌ ERROR: $author:$id@$version has no author" >&2
      exit 1
    fi

    # Read content array
    local content_items=()
    if jq -e '.content' "$manifest" > /dev/null; then
      while IFS= read -r line; do
        content_items+=("$line")
      done < <(jq -r '.content[]' "$manifest")
    else
      while IFS= read -r line; do
        content_items+=("$line")
      done < <(cd "$asset_dir" && find . -maxdepth 1 -type f ! -name '*.json' ! -name '.*' -exec basename {} \;)
    fi

    if [[ ${#content_items[@]} -eq 0 ]]; then
      echo "  ❌ ERROR: $author:$id@$version has no content to pack" >&2
      exit 1
    fi

    # Create ZIP
    local zip_name="${author}:${id}@${version}.zip"
    local zip_path="$DIST_DIR/$content_folder/$zip_name"
    create_asset_zip "$zip_path" "$asset_dir" "${content_items[@]}"

    # Generate URLs
    local sha256 size zip_url json_zip_url manifest_url image_url api_url example_code_url
    sha256="$(get_sha256 "$zip_path")"
    size="$(get_file_size "$zip_path")"
    zip_url="${BASE_URL:+$BASE_URL/}$content_folder/$zip_name"
    json_zip_url="$(create_json_zip "$zip_path" "$zip_name" "$content_folder")"
    manifest_url="$(copy_manifest "$manifest" "$content_folder" "$author" "$id")"
    image_url="$(copy_image "$image_rel" "$asset_dir" "$author" "$id")"
    api_url="$(generate_github_url "$api" "$asset_dir")"
    example_code_url="$(generate_github_url "$example_code" "$asset_dir")"

    # Build example if needed
    if [[ -z "$example_url" || "$example_url" == "null" ]]; then
      if [[ -n "$example" && "$example" != "null" ]]; then
        local built_example_url
        built_example_url="$(build_example_if_needed "$example" "$author" "$id" "$version" "$asset_dir" "$title" "$description" "$api_url" "$author_url" "$example_code_url")"
        [[ -n "$built_example_url" ]] && example_url="$built_example_url"
      fi
    fi

    # Get download statistics
    local asset_id="${asset_type}:${author}:${id}"
    local download_stats
    download_stats="$(get_download_stats "$asset_id")"

    # Build item JSON
    local item
    item="$(build_folder_item_json \
      "$id" "$version" "$title" "$author" "$description" \
      "$api_url" "$author_url" "$example_url" "$example_code_url" \
      "$image_url" "$zip_url" "$json_zip_url" "$sha256" \
      "$manifest_url" "$size" "$depends" "$tags" "$unlisted" \
      "$download_stats")"

    # Add item to index
    jq --argjson item "$item" '.items += [$item]' "$tmp_index" > "${tmp_index}.tmp" && mv "${tmp_index}.tmp" "$tmp_index"

    # Output
    echo "  ✅ $author:$id@$version"
    echo "     zip: $zip_url"
    echo "     json: $json_zip_url"
    echo "     manifest: $manifest_url"
    [[ -n "$image_url" ]] && echo "     image: $image_url"
    [[ -n "$api_url" ]] && echo "     api: $api_url"
    [[ -n "$example_url" ]] && echo "     example: $example_url"
    [[ -n "$example_code_url" ]] && echo "     example_code: $example_code_url"
  done

  cp "$tmp_index" "$out_index"
  local item_count
  item_count=$(jq -r ".items | length" "$out_index")
  echo "  📊 Total: $item_count items"
}

copy_or_stub_defold_deps() {
  local store_name="$1" store_index="$2"
  local out_index="$DIST_DIR/$store_index"
  if [[ -f "$ROOT/store/$store_index" ]]; then
    cp "$ROOT/store/$store_index" "$out_index"
  else
    jq -n '{schema_version:1,"items":[]}' > "$out_index"
  fi
  echo "📦 Store: $store_name"
}

pack_dependency_store() {
  local store_name="$1" store_index="$2" content_folder="$3"
  local asset_type="dependency"

  local src_dir="$ASSETS_ROOT/$content_folder"
  local out_index="$DIST_DIR/$store_index"

  echo "📦 Store: $store_name"

  local tmp_index
  tmp_index="$(mktemp)"
  jq -n '{items:[]}' > "$tmp_index"

  if [[ ! -d "$src_dir" ]]; then
    echo "⚠️  Directory '$src_dir' does not exist, writing empty index"
    cp "$tmp_index" "$out_index"
    return
  fi

  shopt -s nullglob
  local all_manifests=()
  for manifest in "$src_dir"/*/*.json "$src_dir"/*/*/*.json; do
    all_manifests+=("$manifest")
  done

  for manifest in "${all_manifests[@]}"; do
    local asset_dir
    asset_dir="$(dirname "$manifest")"
    local asset_folder
    asset_folder="$(basename "$asset_dir")"
    local name_no_ext
    name_no_ext="$(basename "$manifest" .json)"

    if [[ "$asset_folder" != "$name_no_ext" ]]; then
      echo "  ⚠️  SKIP: $asset_folder != $name_no_ext"
      continue
    fi

    # Read manifest fields
    local id version title author description api author_url image_rel
    local depends tags content unlisted example_code example_url stars
    id="$(jq -r '.id // "'$asset_folder'"' "$manifest")"
    version="$(jq -r '.version // null' "$manifest")"
    title="$(jq -r '.title // "'$id'"' "$manifest")"
    author="$(jq -r '.author // empty' "$manifest")"
    description="$(jq -r '.description // empty' "$manifest")"
    api="$(jq -r '.api // empty' "$manifest")"
    author_url="$(jq -r '.author_url // empty' "$manifest")"
    image_rel="$(jq -r '.image // empty' "$manifest")"
    depends="$(jq -c '.depends // []' "$manifest")"
    tags="$(jq -c '.tags // []' "$manifest")"
    content="$(jq -c '.content // []' "$manifest")"
    unlisted="$(jq -c '.unlisted // false' "$manifest")"
    example_code="$(jq -r '.example_code // empty' "$manifest")"
    example_url="$(jq -r '.example_url // empty' "$manifest")"
    stars="$(jq -r '.stars // null' "$manifest")"

    if [[ -z "$author" || "$author" == "null" ]]; then
      local display_id="${id}"
      [[ -n "$version" && "$version" != "null" ]] && display_id="${display_id}@${version}"
      echo "  ❌ ERROR: $display_id has no author" >&2
      exit 1
    fi

    if [[ -z "$content" || "$content" == "null" || "$content" == "[]" ]]; then
      local display_id="${author}:${id}"
      [[ -n "$version" && "$version" != "null" ]] && display_id="${display_id}@${version}"
      echo "  ❌ ERROR: $display_id has no content array" >&2
      exit 1
    fi

    # Generate URLs
    local manifest_url image_url api_url
    manifest_url="$(copy_manifest "$manifest" "$content_folder" "$author" "$id")"
    image_url="$(copy_image "$image_rel" "$asset_dir" "$author" "$id")"
    api_url="$(generate_github_url "$api" "$asset_dir")"

    # Get download statistics
    local asset_id="${asset_type}:${author}:${id}"
    local download_stats
    download_stats="$(get_download_stats "$asset_id")"

    # Generate example_code URL if needed
    local example_code_url
    example_code_url="$(generate_github_url "$example_code" "$asset_dir")"
    if [[ -z "$example_code_url" && -n "$example_code" && "$example_code" != "null" && "$example_code" != "" ]]; then
      # If example_code is a direct URL, use it as is
      example_code_url="$example_code"
    fi

    # Build item JSON
    local item
    item="$(build_dependency_item_json \
      "$id" "$version" "$title" "$author" "$description" \
      "$api_url" "$author_url" "$image_url" "$manifest_url" \
      "$depends" "$tags" "$content" "$unlisted" \
      "$download_stats" "$example_code_url" "$example_url" "$stars")"

    # Add item to index
    jq --argjson item "$item" '.items += [$item]' "$tmp_index" > "${tmp_index}.tmp" && mv "${tmp_index}.tmp" "$tmp_index"

    # Output
    local display_name="${author}:${id}"
    [[ -n "$version" && "$version" != "null" ]] && display_name="${display_name}@${version}"
    echo "  ✅ $display_name"
    echo "     manifest: $manifest_url"
    [[ -n "$image_url" ]] && echo "     image: $image_url"
    [[ -n "$api_url" ]] && echo "     api: $api_url"
    [[ -n "$example_code_url" ]] && echo "     example_code: $example_code_url"
    [[ -n "$example_url" ]] && echo "     example_url: $example_url"
  done

  cp "$tmp_index" "$out_index"
  local item_count
  item_count=$(jq -r ".items | length" "$out_index")
  echo "  📊 Total: $item_count items"
}

# ---------- main ----------
echo "╔════════════════════════════════════════════════════════╗"
echo "║         Defold Asset Store Builder                    ║"
echo "╚════════════════════════════════════════════════════════╝"
echo ""

if [[ ! -f "$SRC_STORES_JSON" ]]; then
  echo "❌ ERROR: Missing $SRC_STORES_JSON" >&2
  exit 1
fi


# Build per-store indices
store_objs=()
while IFS= read -r line; do
  store_objs+=("$line")
done < <(jq -c '.stores[]' "$SRC_STORES_JSON")

for s in "${store_objs[@]}"; do
  name="$(jq -r '.name' <<<"$s")"
  type="$(jq -r '.type' <<<"$s")"
  index="$(jq -r '.index' <<<"$s")"
  content="$(jq -r '.content // empty' <<<"$s")"

  case "$type" in
    folder)
      if [[ -z "$content" ]]; then
        echo "❌ ERROR: Store '$name' missing 'content'" >&2
        exit 1
      fi
      pack_folder_store "$name" "$index" "$content"
      ;;
    dependency|dependencies)
      if [[ -z "$content" ]]; then
        echo "❌ ERROR: Store '$name' missing 'content'" >&2
        exit 1
      fi
      pack_dependency_store "$name" "$index" "$content"
      ;;
    defold-dependencies)
      copy_or_stub_defold_deps "$name" "$index"
      ;;
    *)
      echo "❌ ERROR: Unknown store type: $type (store '$name')" >&2
      exit 1
      ;;
  esac
done

echo ""
echo "📝 Writing root stores.json..."

# Write *published* root stores.json with absolute index URLs
updated_at="$(date -u +%FT%TZ)"
jq --arg base "$BASE_URL" --arg updated_at "$updated_at" '
  { updated_at: $updated_at,
    stores: [ .stores[]
      | .index = ( ($base // "") + "/" + .index )
    ]
  }
' "$SRC_STORES_JSON" > "$DIST_DIR/stores.json"

# Helper function to format file size
format_size() {
  local size="$1"
  if command -v numfmt >/dev/null 2>&1; then
    numfmt --to=iec-i --suffix=B "$size" 2>/dev/null || echo "${size} bytes"
  else
    # Fallback: simple formatting
    if [[ $size -gt 1048576 ]]; then
      echo "$(( size / 1048576 ))MB"
    elif [[ $size -gt 1024 ]]; then
      echo "$(( size / 1024 ))KB"
    else
      echo "${size} bytes"
    fi
  fi
}

# Create examples.zip archive for faster restoration
if [[ -d "$DIST_DIR/examples" && -n "$(find "$DIST_DIR/examples" -mindepth 1 -maxdepth 1 2>/dev/null)" ]]; then
  echo ""
  echo "📦 Creating examples.zip archive..."
  examples_zip="$DIST_DIR/examples.zip"
  (cd "$DIST_DIR" && zip -q -r "examples.zip" "examples/")
  if [[ -f "$examples_zip" ]]; then
    zip_size="$(get_file_size "$examples_zip")"
    echo "✅ Created examples.zip ($(format_size "$zip_size"))"
    echo "   URL: ${BASE_URL:+$BASE_URL/}examples.zip"
  else
    echo "⚠️  Warning: Failed to create examples.zip"
  fi
fi


echo ""
echo "✅ Build complete: $DIST_DIR/stores.json"
if [[ -n "$BASE_URL" ]]; then
  echo "🌐 Published at: $BASE_URL/stores.json"
fi
