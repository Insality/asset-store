# Dependencies Asset Store

Find all available library dependencies here and install them with one click into your project. After installation, the dependency URL is automatically added to your `game.project` file, and you can fetch it using Defold's built-in library system.

## How to Open

`Project` -> `[Asset Store] Dependencies` in the menu.

## Adding Your Dependency

### File Structure

Create a folder for your dependency:

```
dependencies/
└── {YourName}/
    └── {dependency_id}/
        └── {dependency_id}.json    # Dependency manifest (required)
```

**Important**: The folder name must match the `id` in the JSON file.

### Dependency Manifest

Create a `{dependency_id}.json` file:

#### Required Fields

- `author` — your name (usually GitHub username)
- `id` — unique identifier (usually matches folder name)
- `version` — version string (e.g., `"1.1.6"` or `"14"`)
- `content` — array of GitHub release URLs:
  ```json
  "content": [
    "https://github.com/YourAuthorName/your-repo/archive/refs/tags/1.0.0.zip",
    "https://github.com/YourAuthorName/your-repo/archive/refs/tags/1.1.0.zip",
    "https://github.com/YourAuthorName/your-repo/archive/refs/tags/1.1.6.zip"
  ]
  ```

#### Recommended Fields

- `title` — dependency name
- `description` — brief description
- `tags` — tags for search (e.g., `["UI", "framework", "utility"]`)
- `author_url` — link to your profile
- `depends` — array of dependency IDs in format `"Author:id"`:
  ```json
  "depends": ["Insality:defold-event"]
  ```

#### Optional Fields

- None currently

**Note**: Multiple URLs in the `content` array enable automatic update detection. The asset store will show an "Update" button if a newer version is available in the list.

### Example Manifest

```json
{
  "author": "Insality",
  "id": "defold-event",
  "version": "14",
  "depends": [],
  "title": "Defold Event",
  "description": "Event system for Defold game engine",
  "author_url": "https://github.com/Insality",
  "tags": ["event", "system", "messaging"],
  "content": [
    "https://github.com/Insality/defold-event/archive/refs/tags/12.zip",
    "https://github.com/Insality/defold-event/archive/refs/tags/13.zip",
    "https://github.com/Insality/defold-event/archive/refs/tags/14.zip"
  ]
}
```

### How to Submit

1. Fork the repository on GitHub
2. Clone your fork:
   ```bash
   git clone https://github.com/YourUsername/asset_store.git
   cd asset_store
   ```
3. Create a branch:
   ```bash
   git checkout -b add-my-dependency
   ```
4. Add dependency manifest to `dependencies/{YourName}/{dependency_id}/`
5. Commit:
   ```bash
   git add dependencies/YourAuthorName/my_dependency/
   git commit -m "Add my_dependency dependency"
   ```
6. Push:
   ```bash
   git push origin add-my-dependency
   ```
7. Create a Pull Request on GitHub

After submitting, the automated system will check your dependency, maintainers will review it, and if everything looks good — your dependency will automatically appear in the store!

### Tips

- Test your dependency before submitting
- Use semantic versioning for your releases (e.g., `1.0.0`, `1.1.6`, `2.0.0`)
- Include all available versions in the `content` array to enable update detection
- Use meaningful tags for better discoverability
- Check out existing dependencies in `/dependencies/Insality/` for reference
- Dependencies are added to `game.project` automatically — users don't need to manually edit the file
- If your dependency requires other dependencies, list them in the `depends` field using format `"Author:id"` (e.g., `"Insality:defold-event"`)

## Updating a Dependency

To update an existing dependency:

1. Add the new version URL to the `content` array in the manifest
2. Update the `version` field to match the latest version
3. Create a new PR

The asset store will automatically detect when a newer version is available and show an "Update" button to users who have an older version installed.

All previous versions are preserved automatically in the `content` array.

