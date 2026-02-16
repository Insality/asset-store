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

Publishing uses the same manifest format as all folder-type stores. See **[Publishing Folder-Type Assets](folder_assets_publishing.md)** for the full JSON structure, required and optional fields, and examples.

**For this store**, add your asset under:

`widget/<Author>/<WidgetID>/`

Example: `widget/Insality/rich_input/` with `rich_input.json` and your `.gui` / `.lua` (and any other) files in that folder. Widgets can declare **dependencies** on other widgets via the `depends` field; those are installed automatically when a user installs your widget.
