#!/usr/bin/env bash
# Image processing utilities for asset store packing
# This file is sourced by pack_all_stores.sh

# Check if a command exists
command_exists() {
  command -v "$1" >/dev/null 2>&1
}


# Extract image filename from URL
extract_image_name_from_url() {
  local url="$1"
  local img_name
  img_name="$(basename "$url" | sed 's/[?#].*$//')"
  if [[ -z "$img_name" || "$img_name" == "/" ]]; then
    img_name="image.jpg"
  fi
  echo "$img_name"
}


# Download image from URL to destination path
download_image_from_url() {
  local url="$1"
  local dest_path="$2"

  if command_exists curl; then
    curl -sSL -o "$dest_path" "$url" && return 0
  elif command_exists wget; then
    wget -q -O "$dest_path" "$url" && return 0
  fi

  return 1
}


# Get image width in pixels; echo to stdout, 0 if unknown
get_image_width() {
  local image_path="$1"
  if [[ ! -f "$image_path" ]]; then
    echo 0
    return
  fi
  if command_exists magick; then
    magick identify -format '%w' "$image_path" 2>/dev/null || echo 0
    return
  fi
  if command_exists convert; then
    identify -format '%w' "$image_path" 2>/dev/null || echo 0
    return
  fi
  if command_exists sips; then
    sips -g pixelWidth "$image_path" 2>/dev/null | awk '/pixelWidth/{print $2}' || echo 0
    return
  fi
  echo 0
}


# Detect if image is PNG format
is_png_image() {
  local image_path="$1"
  if [[ "$image_path" =~ \.(png|PNG)$ ]]; then
    return 0
  fi
  if command_exists file; then
    file "$image_path" 2>/dev/null | grep -qi "PNG" && return 0
  fi
  return 1
}


# Optimize JPEG image file size using additional tools
optimize_jpeg_image() {
  local image_path="$1"

  if command_exists jpegoptim; then
    jpegoptim --max=75 --strip-all --quiet "$image_path" 2>/dev/null || true
  fi
}


# Resize and compress image to target width (maintains aspect ratio, converts all to JPEG)
resize_image() {
  local input_path="$1"
  local output_path="$2"
  local target_width="${3:-146}"

  if [[ ! -f "$input_path" ]]; then
    return 1
  fi

  local quality=65

  if command_exists magick; then
    if magick "$input_path" \
      -resize "${target_width}x" \
      -quality "$quality" \
      -strip \
      -interlace Plane \
      -sampling-factor 4:2:0 \
      -colorspace sRGB \
      "JPEG:$output_path" 2>/dev/null; then
      if [[ -f "$output_path" ]]; then
        optimize_jpeg_image "$output_path"
        return 0
      fi
    fi
  elif command_exists convert; then
    if convert "$input_path" \
      -resize "${target_width}x" \
      -quality "$quality" \
      -strip \
      -interlace Plane \
      -sampling-factor 4:2:0 \
      -colorspace sRGB \
      "JPEG:$output_path" 2>/dev/null; then
      if [[ -f "$output_path" ]]; then
        optimize_jpeg_image "$output_path"
        return 0
      fi
    fi
  elif command_exists sips; then
    local temp_jpeg="${output_path%.*}.jpg"
    if sips -s format jpeg -s formatOptions "$quality" -Z "$target_width" "$input_path" --out "$temp_jpeg" >/dev/null 2>&1; then
      if [[ -f "$temp_jpeg" ]]; then
        mv "$temp_jpeg" "$output_path" 2>/dev/null || cp "$temp_jpeg" "$output_path"
        optimize_jpeg_image "$output_path"
        return 0
      fi
    fi
  fi

  return 1
}


# Build image URL for distribution
build_image_url() {
  local author="$1"
  local id="$2"
  local img_name="$3"
  echo "${BASE_URL:+$BASE_URL/}images/$author/$id/$img_name"
}


# Clean up temporary file if it exists
cleanup_temp_file() {
  local temp_path="$1"
  [[ -n "$temp_path" && -f "$temp_path" ]] && rm -f "$temp_path"
}


# Process URL image: download and prepare for resizing
process_url_image() {
  local url="$1"
  local image_dir="$2"
  local img_name
  local temp_path

  img_name="$(extract_image_name_from_url "$url")"
  temp_path="$image_dir/.temp_$img_name"

  if ! download_image_from_url "$url" "$temp_path"; then
    echo "$url"
    return 1
  fi

  echo "$temp_path|$img_name"
  return 0
}


# Process local image file: validate and prepare for resizing
process_local_image() {
  local image_rel="$1"
  local asset_dir="$2"
  local source_path
  local img_name

  source_path="$asset_dir/$image_rel"
  if [[ ! -f "$source_path" ]]; then
    return 1
  fi

  img_name="$(basename "$image_rel")"
  echo "$source_path|$img_name"
  return 0
}


# Copy image to dist directory and return URL (empty string if no image)
# Local images are copied as-is (no resize on CI). URL images are downloaded and resized when possible.
copy_image() {
  local image_rel="$1"
  local asset_dir="$2"
  local author="$3"
  local id="$4"

  if [[ -z "$image_rel" || "$image_rel" == "null" ]]; then
    echo ""
    return
  fi

  local image_dir="$DIST_DIR/images/$author/$id"
  ensure_dir "$image_dir"

  if [[ "$image_rel" =~ ^https?:// ]]; then
    local result
    result="$(process_url_image "$image_rel" "$image_dir")"
    if [[ $? -ne 0 ]]; then
      echo "$result"
      return
    fi
    local source_path="${result%%|*}"
    local img_name="${result##*|}"
    local img_name_jpg="${img_name%.*}.jpg"
    local output_path="$image_dir/$img_name_jpg"
    if [[ ! "$output_path" =~ \.(jpg|jpeg|JPG|JPEG)$ ]]; then
      output_path="${output_path%.*}.jpg"
      img_name_jpg="$(basename "$output_path")"
    fi
    if resize_image "$source_path" "$output_path" 146; then
      cleanup_temp_file "$source_path"
      build_image_url "$author" "$id" "$img_name_jpg"
    else
      cleanup_temp_file "$source_path"
      echo "$image_rel"
    fi
    return
  fi

  local result
  result="$(process_local_image "$image_rel" "$asset_dir")"
  if [[ $? -ne 0 ]]; then
    echo ""
    return
  fi
  local source_path="${result%%|*}"
  local img_name="${result##*|}"
  cp -f "$source_path" "$image_dir/$img_name"
  build_image_url "$author" "$id" "$img_name"
}
