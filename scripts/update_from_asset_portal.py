#!/usr/bin/env python3
"""
Sync asset information from Defold's asset-portal repository to local dependency files.

This script downloads the asset-portal repository, parses asset metadata, and updates
existing dependency JSON files with stars, tags, description, and new releases.
"""

import argparse
import json
import os
import shutil
import subprocess
import sys
import tempfile
import urllib.request
import zipfile
from pathlib import Path
from typing import Dict, List, Optional, Set


def download_file(url: str, dest_path: Path) -> None:
    """Download a file from URL to destination path."""
    print(f"Downloading {url}...")

    # Try using curl first (works better with SSL on macOS)
    try:
        result = subprocess.run(
            ['curl', '-L', '-f', '-s', '-S', '--retry', '3', '--max-time', '300', '-o', str(dest_path), url],
            check=True,
            capture_output=True,
            text=True
        )
        if dest_path.exists() and dest_path.stat().st_size > 0:
            print(f"✓ Downloaded to {dest_path}")
            return
    except (subprocess.CalledProcessError, FileNotFoundError) as e:
        # Fallback to urllib if curl is not available
        if isinstance(e, FileNotFoundError):
            print("  (curl not found, trying urllib...)")
        else:
            print(f"  (curl failed: {e}, trying urllib...)")

    # Fallback to urllib with SSL context
    try:
        import ssl
        context = ssl.create_default_context()
        with urllib.request.urlopen(url, context=context) as response:
            with open(dest_path, 'wb') as f:
                shutil.copyfileobj(response, f)
        print(f"✓ Downloaded to {dest_path}")
    except Exception as e:
        print(f"✗ Error downloading {url}: {e}", file=sys.stderr)
        raise


def extract_zip(zip_path: Path, extract_to: Path) -> Path:
    """Extract zip file and return path to extracted directory."""
    print(f"Extracting {zip_path}...")
    try:
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(extract_to)

        # Find the extracted directory (usually asset-portal-master)
        extracted_dirs = [d for d in extract_to.iterdir() if d.is_dir()]
        if not extracted_dirs:
            raise ValueError("No directories found in extracted archive")

        extracted_dir = extracted_dirs[0]
        print(f"✓ Extracted to {extracted_dir}")
        return extracted_dir
    except Exception as e:
        print(f"✗ Error extracting {zip_path}: {e}", file=sys.stderr)
        raise


def load_json_file(file_path: Path) -> Optional[Dict]:
    """Load JSON file and return parsed data, or None if error."""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        print(f"  ⚠ Warning: Could not load {file_path}: {e}", file=sys.stderr)
        return None


def save_json_file(file_path: Path, data: Dict) -> None:
    """Save JSON data to file with proper formatting."""
    try:
        with open(file_path, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent='\t', ensure_ascii=False)
            f.write('\n')
    except Exception as e:
        print(f"  ✗ Error saving {file_path}: {e}", file=sys.stderr)
        raise


def load_config(config_path: Path) -> Dict:
    """Load configuration file."""
    if not config_path.exists():
        # Return default empty config
        return {
            'author_renames': {},
            'asset_renames': {},
            'ignore_repositories': []
        }

    config_data = load_json_file(config_path)
    if not config_data:
        return {
            'author_renames': {},
            'asset_renames': {},
            'ignore_repositories': []
        }

    # Ensure all required keys exist
    config_data.setdefault('author_renames', {})
    config_data.setdefault('asset_renames', {})
    config_data.setdefault('ignore_repositories', [])

    return config_data


def apply_renames(author: str, asset_id: str, config: Dict) -> tuple:
    """
    Apply author and asset renames from config.
    Returns (new_author, new_asset_id).
    """
    # Apply author rename
    new_author = config['author_renames'].get(author, author)

    # Apply asset rename (key format: "author:asset_id")
    asset_key = f"{author}:{asset_id}"
    new_asset_id = config['asset_renames'].get(asset_key, asset_id)

    return (new_author, new_asset_id)


def is_ignored(author: str, asset_id: str, config: Dict) -> bool:
    """Check if repository should be ignored."""
    asset_key = f"{author}:{asset_id}"
    return asset_key in config.get('ignore_repositories', [])


def extract_github_author_url(project_url: str) -> Optional[str]:
    """
    Extract GitHub author URL from project URL.
    Example: https://github.com/Insality/druid -> https://github.com/Insality
    """
    if not project_url or not isinstance(project_url, str):
        return None
    
    # Match GitHub URLs: https://github.com/username/repo
    import re
    match = re.match(r'https?://github\.com/([^/]+)', project_url)
    if match:
        username = match.group(1)
        return f"https://github.com/{username}"
    
    return None


def create_new_asset_file(
    local_path: Path,
    portal_data: Dict,
    author: str,
    asset_id: str,
    assets_dir: Path
) -> bool:
    """
    Create a new asset file from portal data.
    Returns True if file was created, False otherwise.
    """
    # Check if we have library_url or releases
    has_library_url = bool(portal_data.get('library_url'))
    has_releases = bool(portal_data.get('releases') and isinstance(portal_data.get('releases'), list) and len(portal_data.get('releases', [])) > 0)
    
    if not has_library_url and not has_releases:
        return False
    
    # Create directory if needed
    local_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Build new asset data (use renamed author and asset_id)
    new_data = {
        'author': author,
        'id': asset_id,
        'title': portal_data.get('name') or asset_id,
        'description': portal_data.get('description', ''),
        'tags': portal_data.get('tags', []),
        'stars': portal_data.get('stars'),
        'content': []
    }
    
    # Add optional fields
    if portal_data.get('project_url'):
        new_data['example_code'] = portal_data.get('project_url')
    
    # Set author_url: use from portal_data if available, otherwise extract from project_url
    if portal_data.get('author_url'):
        new_data['author_url'] = portal_data.get('author_url')
    elif portal_data.get('project_url'):
        # Try to extract GitHub author URL from project_url
        github_author_url = extract_github_author_url(portal_data.get('project_url'))
        if github_author_url:
            new_data['author_url'] = github_author_url
    
    # Copy thumbnail image if available
    images = portal_data.get('images', {})
    thumb_name = None
    if isinstance(images, dict):
        thumb_name = images.get('thumb')
    elif isinstance(images, str):
        # Some assets might have images as a string
        thumb_name = images
    
    if thumb_name:
        # Images are located in assets/images/ directory
        # assets_dir is the path to assets/ directory, so images are in assets_dir.parent / 'assets' / 'images'
        # But actually, if assets_dir is already assets/, then images are in assets_dir.parent / 'assets' / 'images'
        # Let's check: assets_dir should be {extracted_root}/assets
        # So images should be in {extracted_root}/assets/images/
        images_dir = assets_dir / 'images'
        image_path = images_dir / thumb_name
        
        if image_path.exists() and image_path.is_file():
            dest_image_path = local_path.parent / thumb_name
            try:
                shutil.copy2(image_path, dest_image_path)
                new_data['image'] = thumb_name
            except Exception as e:
                print(f"    ⚠ Warning: Could not copy image {thumb_name}: {e}", file=sys.stderr)
                # Still add the image field even if copy failed
                new_data['image'] = thumb_name
        else:
            # If image file not found, still add the image field (might be added manually later)
            new_data['image'] = thumb_name
            print(f"    ⚠ Warning: Image file not found: {image_path}", file=sys.stderr)
    
    # Set content based on releases or library_url
    if has_releases:
        # Extract zip URLs from releases and sort by date
        releases = portal_data.get('releases', [])
        zip_urls = [r.get('zip') for r in releases if r.get('zip')]
        new_data['content'] = sort_content_by_date(zip_urls, releases)
    elif has_library_url:
        # Use library_url as single content item
        new_data['content'] = [portal_data.get('library_url')]
    
    # Remove None values
    new_data = {k: v for k, v in new_data.items() if v is not None}
    
    # Save file
    save_json_file(local_path, new_data)
    return True


def get_existing_content_urls(local_data: Dict) -> Set[str]:
    """Extract all zip URLs from local content array."""
    content = local_data.get('content', [])
    if isinstance(content, list):
        return set(content)
    return set()


def sort_content_by_date(content: List[str], portal_releases: List[Dict]) -> List[str]:
    """
    Sort content array by published_at date from portal releases.
    URLs without date info are placed at the end.
    """
    # Create mapping from zip URL to published_at date
    url_to_date = {}
    for release in portal_releases:
        zip_url = release.get('zip')
        published_at = release.get('published_at')
        if zip_url and published_at:
            url_to_date[zip_url] = published_at

    def sort_key(url: str) -> tuple:
        if url in url_to_date:
            # Return date string for sorting (ISO format sorts correctly)
            return (0, url_to_date[url])  # 0 means has date
        else:
            # URLs without date go to the end, sorted alphabetically
            return (1, url)

    return sorted(content, key=sort_key)


def merge_releases_into_content(local_data: Dict, portal_releases: List[Dict]) -> tuple:
    """
    Merge releases from asset-portal into local content array.
    Returns tuple: (new_releases_count, was_resorted).
    Content array is sorted by published_at date in ascending order (oldest first).
    """
    existing_urls = get_existing_content_urls(local_data)
    new_count = 0

    # Ensure content array exists
    if 'content' not in local_data:
        local_data['content'] = []

    # Save original order to check if sorting changed it
    original_content = local_data['content'].copy()

    # Process releases
    for release in portal_releases:
        zip_url = release.get('zip')
        if zip_url and zip_url not in existing_urls:
            local_data['content'].append(zip_url)
            existing_urls.add(zip_url)
            new_count += 1

    # Sort content by published_at date in ascending order (oldest first)
    was_resorted = False
    if local_data['content']:
        sorted_content = sort_content_by_date(local_data['content'], portal_releases)
        # Check if order changed
        if sorted_content != original_content:
            was_resorted = True
        local_data['content'] = sorted_content

    return (new_count, was_resorted)


def update_local_asset(local_path: Path, portal_data: Dict) -> Dict[str, int]:
    """
    Update local asset file with data from asset-portal.
    Returns dict with update statistics.
    """
    stats = {
        'updated': False,
        'new_releases': 0,
        'fields_updated': []
    }

    local_data = load_json_file(local_path)
    if not local_data:
        return stats

    # Update stars
    if 'stars' in portal_data:
        old_stars = local_data.get('stars')
        local_data['stars'] = portal_data['stars']
        if old_stars != portal_data['stars']:
            stats['fields_updated'].append('stars')
            stats['updated'] = True

    # Update tags
    if 'tags' in portal_data:
        old_tags = local_data.get('tags', [])
        local_data['tags'] = portal_data['tags']
        if old_tags != portal_data['tags']:
            stats['fields_updated'].append('tags')
            stats['updated'] = True

    # Update description
    if 'description' in portal_data:
        old_desc = local_data.get('description')
        local_data['description'] = portal_data['description']
        if old_desc != portal_data['description']:
            stats['fields_updated'].append('description')
            stats['updated'] = True
    
    # Update author_url only if local file doesn't have it
    # If local file already has author_url, don't overwrite it (preserve manual edits)
    if 'author_url' not in local_data or not local_data.get('author_url'):
        # Try to get author_url from portal_data
        if portal_data.get('author_url'):
            local_data['author_url'] = portal_data['author_url']
            stats['fields_updated'].append('author_url')
            stats['updated'] = True
        elif portal_data.get('project_url'):
            # Try to extract GitHub author URL from project_url
            github_author_url = extract_github_author_url(portal_data.get('project_url'))
            if github_author_url:
                local_data['author_url'] = github_author_url
                stats['fields_updated'].append('author_url')
                stats['updated'] = True

    # Merge releases into content
    if 'releases' in portal_data and isinstance(portal_data['releases'], list):
        new_releases, was_resorted = merge_releases_into_content(local_data, portal_data['releases'])
        if new_releases > 0:
            stats['new_releases'] = new_releases
            stats['updated'] = True
        if was_resorted:
            # Content was resorted, need to save
            stats['updated'] = True
            if 'content (resorted)' not in stats['fields_updated']:
                stats['fields_updated'].append('content (resorted)')

    # Save if updated
    if stats['updated']:
        save_json_file(local_path, local_data)

    return stats


def process_asset(
    asset_name: str,
    assets_dir: Path,
    dependencies_dir: Path,
    missing_assets: List[str],
    config: Dict,
    created_assets: List[str],
    skipped_assets: List[str]
) -> Dict[str, int]:
    """
    Process a single asset from asset-portal.
    Returns dict with processing statistics.
    """
    asset_file = assets_dir / asset_name
    if not asset_file.exists():
        print(f"  ⚠ Asset file not found: {asset_file}")
        return {'processed': False}

    portal_data = load_json_file(asset_file)
    if not portal_data:
        return {'processed': False}

    author = portal_data.get('author')
    asset_id = portal_data.get('id')

    # If id is missing, use asset filename (without .json extension) as id
    if not asset_id or (isinstance(asset_id, str) and asset_id.strip() == ""):
        asset_id = asset_name.replace('.json', '')
        # Update portal_data so it's available for create_new_asset_file
        portal_data['id'] = asset_id

    # Check if author is missing or empty
    if not author or (isinstance(author, str) and author.strip() == ""):
        reason = f"Missing or empty 'author' field"
        skipped_assets.append(f"{asset_name}: {reason}")
        print(f"  ⚠ {reason} in {asset_name}")
        return {'processed': False, 'skipped': True}

    # Check if ignored (before renames, in case config uses original names)
    original_author = author
    original_asset_id = asset_id
    if is_ignored(original_author, original_asset_id, config):
        return {'processed': False, 'ignored': True}

    # Apply renames from config
    author, asset_id = apply_renames(author, asset_id, config)
    
    # Check if ignored (after renames, in case config uses renamed names)
    if is_ignored(author, asset_id, config):
        return {'processed': False, 'ignored': True}

    # Construct local file path: dependencies/{author}/{id}/{id}.json
    local_path = dependencies_dir / author / asset_id / f"{asset_id}.json"

    if not local_path.exists():
        # Try to create new file if we have library_url or releases
        if create_new_asset_file(local_path, portal_data, author, asset_id, assets_dir):
            created_assets.append(f"{author}:{asset_id}")
            # Now update it with portal data (to ensure all fields are synced)
            stats = update_local_asset(local_path, portal_data)
            stats['processed'] = True
            stats['created'] = True
            return stats
        else:
            missing_assets.append(f"{author}:{asset_id}")
            return {'processed': False, 'missing': True}

    # Update local file
    stats = update_local_asset(local_path, portal_data)
    stats['processed'] = True

    return stats


def main():
    parser = argparse.ArgumentParser(
        description='Sync asset information from Defold asset-portal to local dependencies'
    )
    parser.add_argument(
        '--dependencies-dir',
        type=str,
        default='dependencies',
        help='Path to dependencies directory (default: dependencies)'
    )
    parser.add_argument(
        '--asset-portal-url',
        type=str,
        default='https://github.com/defold/asset-portal/archive/refs/heads/master.zip',
        help='URL to asset-portal zip archive'
    )
    parser.add_argument(
        '--config',
        type=str,
        default='scripts/asset_portal_config.json',
        help='Path to configuration file (default: scripts/asset_portal_config.json)'
    )
    args = parser.parse_args()

    # Convert to Path objects
    dependencies_dir = Path(args.dependencies_dir)
    if not dependencies_dir.is_absolute():
        # Make relative to script directory
        script_dir = Path(__file__).parent
        root_dir = script_dir.parent
        dependencies_dir = root_dir / args.dependencies_dir

    if not dependencies_dir.exists():
        print(f"✗ Dependencies directory not found: {dependencies_dir}", file=sys.stderr)
        sys.exit(1)

    # Load configuration
    config_path = Path(args.config)
    if not config_path.is_absolute():
        script_dir = Path(__file__).parent
        root_dir = script_dir.parent
        config_path = root_dir / args.config

    config = load_config(config_path)
    if config_path.exists():
        print(f"✓ Loaded configuration from {config_path}")
    else:
        print(f"⚠ No configuration file found at {config_path}, using defaults")

    # Create temporary directory for download and extraction
    temp_dir = None
    try:
        temp_dir = Path(tempfile.mkdtemp(prefix='asset-portal-sync-'))
        zip_path = temp_dir / 'asset-portal.zip'
        extract_dir = temp_dir / 'extracted'
        extract_dir.mkdir()

        # Download asset-portal
        download_file(args.asset_portal_url, zip_path)

        # Extract
        extracted_root = extract_zip(zip_path, extract_dir)

        # Read header.json
        header_path = extracted_root / 'header.json'
        if not header_path.exists():
            print(f"✗ header.json not found in {extracted_root}", file=sys.stderr)
            sys.exit(1)

        header_data = load_json_file(header_path)
        if not header_data:
            print("✗ Failed to parse header.json", file=sys.stderr)
            sys.exit(1)

        # Get list of assets
        asset_names = list(header_data.keys())
        print(f"\nFound {len(asset_names)} assets in header.json")

        # Process each asset
        assets_dir = extracted_root / 'assets'
        if not assets_dir.exists():
            print(f"✗ assets directory not found in {extracted_root}", file=sys.stderr)
            sys.exit(1)

        missing_assets = []
        created_assets = []
        skipped_assets = []  # Assets skipped due to missing fields
        processed_count = 0
        updated_count = 0
        created_count = 0
        ignored_count = 0
        skipped_count = 0
        total_new_releases = 0

        print(f"\nProcessing assets...")
        for i, asset_name in enumerate(asset_names, 1):
            print(f"[{i}/{len(asset_names)}] Processing {asset_name}...", end=' ')

            stats = process_asset(asset_name, assets_dir, dependencies_dir, missing_assets, config, created_assets, skipped_assets)

            if stats.get('processed'):
                processed_count += 1
                if stats.get('created'):
                    created_count += 1
                    print("✓ (created)")
                elif stats.get('updated'):
                    updated_count += 1
                    fields = stats.get('fields_updated', [])
                    new_releases = stats.get('new_releases', 0)
                    total_new_releases += new_releases

                    msg_parts = []
                    if fields:
                        msg_parts.append(f"updated: {', '.join(fields)}")
                    if new_releases > 0:
                        msg_parts.append(f"added {new_releases} release(s)")
                    print(f"✓ {'; '.join(msg_parts)}")
                else:
                    print("✓ (no changes)")
            elif stats.get('ignored'):
                ignored_count += 1
                print("⊘ (ignored)")
            elif stats.get('skipped'):
                skipped_count += 1
                print("⚠ (skipped)")
            elif stats.get('missing'):
                print("✗ (not found locally)")
            else:
                print("⚠ (skipped)")

        # Print summary
        print(f"\n{'='*60}")
        print(f"Summary:")
        print(f"  Total assets in portal: {len(asset_names)}")
        print(f"  Processed (found locally): {processed_count}")
        print(f"  Created: {created_count}")
        print(f"  Updated: {updated_count}")
        print(f"  New releases added: {total_new_releases}")
        print(f"  Ignored: {ignored_count}")
        print(f"  Skipped (missing fields): {skipped_count}")
        print(f"  Missing (in portal, not local): {len(missing_assets)}")

        if created_assets:
            print(f"\nCreated assets:")
            for asset in sorted(created_assets):
                print(f"  + {asset}")

        if skipped_assets:
            print(f"\nSkipped assets (missing required fields):")
            for asset in sorted(skipped_assets):
                print(f"  - {asset}")

        if missing_assets:
            print(f"\nMissing assets (in portal but not in local repo):")
            for asset in sorted(missing_assets):
                print(f"  - {asset}")

        print(f"{'='*60}\n")

    except KeyboardInterrupt:
        print("\n\nInterrupted by user", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"\n✗ Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        sys.exit(1)
    finally:
        # Clean up temporary directory
        if temp_dir and temp_dir.exists():
            print(f"Cleaning up temporary directory...")
            shutil.rmtree(temp_dir)
            print("✓ Cleanup complete")


if __name__ == '__main__':
    main()

