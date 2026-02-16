# Publishing Folder-Type Assets

This page describes how to add and publish assets for the **folder-type** asset stores: Druid Widgets, Editor Scripts, Lua Modules, Particles, and Materials. In these stores, assets are downloaded as files into a folder you choose (nothing is added to `game.project`). Each asset is installed as `<Installation Folder>/<asset_id>/`.

The **manifest format and publishing steps are the same** for all of these stores. The only difference is the **repository folder** where you add your asset (see each store’s doc: [Druid Widgets](druid_widget_store.md), [Editor Scripts](assets_editor_scripts_store.md), [Lua Modules](lua_modules_store.md), [Particles](particles_store.md), [Materials](materials_store.md)).

## Installation and updates (all folder stores)

- You set an **Installation Folder** in the store (e.g. `/widget`, `/editor_scripts`, `/libs`). The asset is installed at `<Installation Folder>/<asset_id>/`.
- Each installed asset has a **`<asset_id>.version`** file. The store uses it to detect the installed version and offer updates. When you **update** an asset, the **entire asset folder is replaced**; any local changes in that folder are lost. Keep your project under version control (e.g. GitHub).

---

## How to Add an Asset (Publish for Others)

1. **Add a folder** in this repository:  
   `<content_folder>/<Author>/<AssetID>/`  
   The **content folder** is defined by the store (e.g. `widget`, `editor_scripts`, `core`, `particles`, `materials`). See the store’s doc for the exact path.

2. **Put your asset files** in that folder.

3. **Add a JSON manifest** in the same folder, named `<AssetID>.json`, and fill in the fields below.

4. Optionally add an **example** (collection + script) and **API documentation**; see the optional fields and “Examples” section.

---

## JSON Manifest Structure

**Required:**

| Field         | Type     | Description |
|---------------|----------|-------------|
| `author`      | string   | Author name (e.g. `"Insality"`). |
| `id`          | string   | Asset id; must match the folder name (e.g. `"rich_input"`). |
| `version`     | number   | Version number (integer). |
| `title`       | string   | Display name. |
| `description` | string   | Short description. |
| `content`     | string[] | List of file names to pack (e.g. `["asset.gui", "asset.lua"]`). Only these files are shipped; include all files the asset needs. |

**Optional:**

| Field          | Type     | Description |
|----------------|----------|-------------|
| `api`          | string   | Path to API doc (relative to asset folder, e.g. `"readme.md"`) or full URL. Linked as “API” in the store. |
| `example`      | string   | Path to the example **collection** used to build the live example (e.g. `/<content_folder>/Author/id/example/example_id.collection`). If set, the example is built automatically. |
| `example_code` | string   | Path to the example **GUI script** (relative to asset folder or absolute from repo root). Used for “View code” / example code link. |
| `example_url`  | string   | If you build the example yourself, set the full URL here; otherwise leave unset and use `example` so it is built automatically. |
| `image`        | string   | Thumbnail filename (e.g. `"asset.jpg"`) in the asset folder. |
| `tags`         | string[] | Tags for filtering (e.g. `["GUI", "debug"]`). |
| `depends`      | string[] | Other assets from the **same store** this one needs. Format: `"Author:asset_id@version"` (e.g. `["Insality:mini_graph@1"]`). They are installed automatically when this asset is installed. (Mainly used in Druid Widgets.) |
| `author_url`   | string   | Link to author (e.g. `"https://github.com/Insality"`). |
| `unlisted`     | boolean  | If `true`, hide from the default listing. The asset can still be found when the user searches for its exact ID. |
| `requires`     | string[] | Folder paths that must exist in the project for this asset to be shown (e.g. `["/decore", "/token"]`). The asset is visible only when **all** listed folders exist. |

Paths in `api`, `example`, and `example_code` can be relative to the asset folder or absolute from the repo root. For `example`, use the path that points to the `.collection` file so the build can run the example. Examples are built automatically when you provide correct `example` (and optionally `example_code`) links; you do not need to host the example yourself.

---

## Example manifests

**Simple (e.g. editor script or Lua module):**

```json
{
  "author": "Insality",
  "id": "set_bootstrap_collection",
  "version": 1,
  "title": "Set Bootstrap Collection",
  "description": "Add [Set as Bootstrap Collection] command in the context menu of *.collection files",
  "content": ["set_bootstrap_collection.editor_script"],
  "author_url": "https://github.com/Insality",
  "tags": ["utility"]
}
```

**With API, example, image, and dependency (e.g. widget):**

```json
{
  "author": "Insality",
  "id": "rich_input",
  "version": 1,
  "title": "Rich Input",
  "description": "A rich text input field",
  "content": ["rich_input.gui", "rich_input.lua"],
  "api": "rich_input.md",
  "example": "/widget/Insality/rich_input/example/example_rich_input.collection",
  "example_code": "/widget/Insality/rich_input/example/example_rich_input.gui_script",
  "author_url": "https://github.com/Insality",
  "image": "rich_input.jpg",
  "tags": ["GUI"]
}
```

With a dependency (same store):

```json
{
  "author": "Insality",
  "id": "fps_panel",
  "version": 1,
  "depends": ["Insality:mini_graph@1"],
  "title": "FPS Panel",
  "description": "Shows current FPS and graph of the last 3 seconds of performance",
  "content": ["fps_panel.gui", "fps_panel.lua"],
  "api": "fps_panel.md",
  "example": "/widget/Insality/fps_panel/example/example_fps_panel.collection",
  "example_code": "/widget/Insality/fps_panel/example/example_fps_panel.gui_script",
  "author_url": "https://github.com/Insality",
  "image": "fps_panel.jpg",
  "tags": ["debug", "system"]
}
```
