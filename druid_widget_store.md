# Druid Widget Asset Store

Find Druid widgets here and install them with one click into your project. Assets are downloaded as files into a folder you choose—unlike the Dependencies store, nothing is added to `game.project`. Each asset is always placed in a subfolder named after the asset (e.g. `mini_graph`, `rich_input`).

## How to Open

`Project` → `[Asset Store] Assets` in the menu, then select **Druid Widgets** (requires [Druid](https://github.com/Insality/druid) in the project).

## Installation Folder

You can set the **Installation Folder** in the store (e.g. `/widget`). The asset is installed as:

`<Installation Folder>/<asset_id>/`

Example: with folder `/widget`, the widget `Insality/rich_input` is installed to `/widget/rich_input/` with its files (`.gui`, `.lua`, etc.) inside.

## Updates and the .version File

Each installed asset has a `<asset_id>.version` file in its folder. The store uses it to detect the installed version and offer updates. When you update an asset, the **entire asset folder is replaced**. Any local changes inside that folder will be lost. Keep your project under version control (e.g. GitHub) so you can recover work if you overwrite something by accident.

## Druid Widgets in Short

[Druid Widgets](https://github.com/Insality/druid/blob/master/wiki/widgets.md) are reusable UI components. You create them with:

```lua
druid:new_widget(widget_module, template_name, nodes)
```

- **widget_module** – the widget Lua module (e.g. from `require`).
- **template_name** – the GUI template id (the same as the widget name in your GUI scene).
- **nodes** – optional; pass `nil` to use the template from the scene, or e.g. `"root"` when cloning for multiple instances.

In the Defold GUI scene you add a GUI file that contains the widget template. You can customize looks and properties, but keep the **node structure and node IDs** the same, because the widget code finds nodes by ID. Widgets can declare **dependencies** on other widgets; those are downloaded automatically when you install a widget from this store.

---

## How to Add an Asset (Publish for Others)

To publish a widget in this store:

1. **Add a folder** in this repository:
   `widget/<Author>/<WidgetID>/`
   Example: `widget/Insality/rich_input/`.

2. **Put your asset files** in that folder (e.g. `rich_input.gui`, `rich_input.lua`).

3. **Add a JSON manifest** in the same folder, named `<WidgetID>.json` (e.g. `rich_input.json`), and fill in the fields below.

4. Optionally add an **example** (collection + script) and **API documentation**; see the JSON fields and “Examples” section.

### JSON Manifest Structure

**Required:**

| Field         | Type     | Description |
|---------------|----------|-------------|
| `author`      | string   | Author name (e.g. `"Insality"`). |
| `id`          | string   | Widget id; must match the folder name (e.g. `"rich_input"`). |
| `version`     | number   | Version number (integer). |
| `title`       | string   | Display name. |
| `description` | string   | Short description. |
| `content`     | string[] | List of file names to pack (e.g. `["rich_input.gui", "rich_input.lua"]`). Only these files are shipped; include all files the widget needs. |

**Optional:**

| Field          | Type     | Description |
|----------------|----------|-------------|
| `api`          | string   | Path to API doc (relative to asset folder, e.g. `"rich_input.md"`) or full URL. Linked as “API” in the store. |
| `example`      | string   | Path to the example **collection** used to build the live example (e.g. `/widget/Author/id/example/example_id.collection`). If set, the example is built automatically. |
| `example_code` | string   | Path to the example **GUI script** (relative to asset folder or absolute from repo root). Used for “View code” / example code link. |
| `example_url`  | string   | If you build the example yourself, set the full URL here; otherwise leave unset and use `example` so it is built automatically. |
| `image`        | string   | Thumbnail filename (e.g. `"rich_input.jpg"`) in the asset folder. |
| `tags`         | string[] | Tags for filtering (e.g. `["GUI", "debug"]`). |
| `depends`      | string[] | Other widgets this one needs. Format: `"Author:widget_id@version"` (e.g. `["Insality:mini_graph@1"]`). They are installed automatically when this widget is installed. |
| `author_url`   | string   | Link to author (e.g. `"https://github.com/Insality"`). |
| `unlisted`     | boolean  | If `true`, hide from the default listing. The asset can still be found when the user searches for its exact ID. |
| `requires`     | string[] | Folder paths that must exist in the project for this asset to be shown (e.g. `["/decore", "/token"]`). The asset is visible only when **all** listed folders exist. Use this for widgets that only make sense when a given system or library is present. |

Paths in `api`, `example`, and `example_code` can be relative to the asset folder or absolute from the repo root. For `example`, use the path that points to the `.collection` file so the build can run the example. Examples are built automatically when you provide correct `example` (and optionally `example_code`) links; you do not need to host the example yourself.

### Example manifest

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

With a dependency:

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
