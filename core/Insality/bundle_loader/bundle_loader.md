# File Loader Module

Promise-based file loader for Defold that works cross-platform with special HTML5 support.

## Features

- **Cross-platform**: Works on HTML5, iOS, Android, Desktop
- **Promise-based API**: Clean async/await-style code using promises
- **HTTP Caching**: Automatic file caching on HTML5 to reduce bandwidth
- **JSON Support**: Built-in JSON parsing with error handling
- **Simple API**: Easy to use with intuitive functions

## API Reference

### `file_loader.load(path, options)`

Load a file from bundle resources or any project file (in development mode).

**Parameters:**
- `path` (string): Full path from project root (e.g., `"/bundle/common/data.txt"`)
- `options` (table, optional):
  - `ignore_cache` (boolean): Force reload, ignoring cache (default: `false`)
  - `raw_path` (boolean): Skip all path transformations (default: `false`)

**Returns:** Promise that resolves with file content as string

**Path Behavior:**
- **Bundle resources** (e.g., `/bundle/common/file.json`): Works everywhere
- **Non-bundle files** (e.g., `/assets/locales/en.json`): Works in development only, fails in production
- **Raw path** (`raw_path = true`): No transformations, use path as-is

**Examples:**
```lua
local bundle_loader = require("core.bundle_loader.bundle_loader")

-- Load bundle resource
bundle_loader.load("/bundle/common/data.txt"):next(function(content)
    print("File content:", content)
end):catch(function(err)
    print("Error loading file:", err)
end)

-- Load arbitrary project file (development only)
bundle_loader.load("/assets/locales/en.json"):next(function(content)
    print("Locale data:", content)  -- Works in dev, fails in production
end)

-- Load with raw path (no transformations)
bundle_loader.load("/debug/config.json", { raw_path = true })
```

### `bundle_loader.load_json(path, options)`

Load and parse a JSON file from bundle resources.

**Parameters:**
- `path` (string): Full path from project root (e.g., `"/bundle/common/config.json"`)
- `options` (table, optional):
  - `ignore_cache` (boolean): Force reload, ignoring cache (default: `false`)

**Returns:** Promise that resolves with parsed JSON as Lua table

**Example:**
```lua
bundle_loader.load_json("/bundle/common/example.json"):next(function(data)
    print("Message:", data.message)
    print("Version:", data.version)
    for i, item in ipairs(data.data.items) do
        print("Item " .. i .. ":", item)
    end
end):catch(function(err)
    print("Error loading JSON:", err)
end)
```

### `bundle_loader.get_cached(path)`

Get cached file content if available (HTML5 only).

**Parameters:**
- `path` (string): Full path from project root (e.g., `"/bundle/common/data.txt"`)

**Returns:** File content string or `nil` if not cached

**Example:**
```lua
local cached = bundle_loader.get_cached("/bundle/common/data.txt")
if cached then
    print("Found in cache:", cached)
else
    print("Not in cache")
end
```


### `bundle_loader.clear_cache()`

Clear all cached files (HTML5 only). Note: Limited functionality due to Defold constraints.

**Example:**
```lua
bundle_loader.clear_cache()
```

## When to Use Each Approach

### Bundle Resources (`/bundle/common/file.json`)
**Use for:** Files that should be available in production builds
- Game data files
- Configuration files
- Localization files for production
- Any asset needed at runtime

**Works:**  everywhere (development & production, all platforms)

### Non-Bundle Project Files (`/assets/locales/en.json`)
**Use for:** Development/testing files not needed in production
- Debug configurations
- Test data
- Development-only assets

**Works:** Development only (fails gracefully in production)

### Raw Path (`{ raw_path = true }`)
**Use for:** Editor-only files with no path transformations
- Custom editor configurations
- Tools and utilities
- Files outside normal project structure

**Works:** Development only, no automatic path transformations

## Bundle Folder Structure

Files should be placed in the `/bundle` directory with platform-specific subdirectories:

```
bundle/
├── common/          # Files for all platforms
│   ├── example.json
│   └── data.txt
├── html5/           # HTML5-specific files
├── ios/             # iOS-specific files
├── android/         # Android-specific files
└── osx/             # macOS-specific files
```

The bundle directory must be configured in `game.project`. You can use any name you want:
```
[project]
bundle_resources = /bundle
# or
bundle_resources = /resources
# or
bundle_resources = /data
```

**Important:**
- Use full paths from project root, matching your `bundle_resources` path: `/bundle/common/example.json`
- The loader reads `bundle_resources` from `game.project` automatically (defaults to `/bundle` if not set)
- **Bundle resources:** Work everywhere (development & production)
- **Non-bundle files:** Work only in development mode (e.g., `/assets/locales/en.json`)
- **Raw path option:** Skip all transformations for editor-only files (`raw_path = true`)
- During bundling, Defold flattens the structure automatically:
  - Native: `/bundle/common/file.json` → `/common/file.json`
  - HTML5: `/bundle/common/file.json` → `file.json` (both bundle and platform folder stripped)
- No need to add to `custom_resources` - the loader detects development mode automatically

## How It Works

### Native Platforms (iOS, Android, Desktop)

**Development Mode** (running from Defold editor):
- Detects project directory using `io.popen("pwd")`
- Validates by checking for `game.project` file
- Loads from: `<project_dir><path>`
  - Example: `/bundle/common/data.json` → `<project>/bundle/common/data.json`

**Production Mode** (bundled application):
- Strips `/bundle` prefix and loads from application path
- Automatically falls back to this if development detection fails
  - Example: `/bundle/common/data.json` → `<app_path>/common/data.json`

**File Access:**
- Uses `io.open()` with binary read mode
- No caching needed (direct file system access)

### HTML5
- Files are loaded via `http.request()` from the server
- First checks cache using `io.open()`
- If not cached, downloads from server
  - **Bundle resources:** Strips both bundle prefix AND platform folder
    - Example: `/bundle/common/data.json` → `<app_url>/data.json`
  - **Raw path:** Uses path as-is (with leading slash stripped)
    - Example: `/debug/config.json` → `<app_url>/debug/config.json`
- Saves to cache automatically using the `path` option in `http.request()`
- Cache path: `sys.get_save_file(project_title, sanitized_path)`
- Proper slash handling ensures URLs like `<app_url>/file.json` (no double slashes)

## Complete Example

```lua
local bundle_loader = require("core.bundle_loader.file_loader")

function init(self)
    -- Load bundle resource (works everywhere)
    file_loader.load_json("/bundle/common/example.json")
        :next(function(data)
            print("Successfully loaded JSON:")
            print("Message:", data.message)
            print("Version:", data.version)
            print("Enabled:", data.data.enabled)

            -- Load a text file from bundle
            return file_loader.load("/bundle/common/readme.txt")
        end)
        :next(function(text_content)
            print("Text file content:", text_content)

            -- Load non-bundle file (development only)
            return file_loader.load("/assets/locales/en.json")
        end)
        :next(function(locale_data)
            print("Locale data loaded (development only)")

            -- Load editor-only file with raw path
            return file_loader.load("/debug/config.json", { raw_path = true })
        end)
        :catch(function(err)
            print("Error occurred:", err)
        end)
end
```

## Error Handling

All errors are returned as rejected promises with descriptive messages:

- File not found
- HTTP errors (non-200/304 status)
- Invalid JSON parsing
- File read failures

Always use `:catch()` to handle potential errors gracefully.

