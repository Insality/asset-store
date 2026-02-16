# Lua Modules Asset Store

Find **Lua modules** (core libraries) here and install them with one click into your project. Assets are downloaded as files into a folder you choose. Each asset is placed in a subfolder named after the asset (e.g. `b64`, `dkjson`).

## How to Open

`Project` → `[Asset Store] Assets` in the menu, then select **Lua Modules**.

## Installation Folder

You can set the **Installation Folder** in the store (default: `/libs`). The asset is installed as:

`<Installation Folder>/<asset_id>/`

Example: with folder `/libs`, the asset `Insality/bundle_loader` is installed to `/libs/bundle_loader/`.

## Updates and the .version File

Each installed asset has a `<asset_id>.version` file in its folder. The store uses it to detect the installed version and offer updates. When you update an asset, the **entire asset folder is replaced**; any local changes in that folder will be lost. Keep your project under version control (e.g. GitHub).

---

## How to Add an Asset (Publish for Others)

Publishing uses the same manifest format as all folder-type stores. See **[Publishing Folder-Type Assets](folder_assets_publishing.md)** for the full JSON structure, required and optional fields, and examples.

**For this store**, add your asset under:

`core/<Author>/<AssetID>/`

Example: `core/Insality/bundle_loader/` with `bundle_loader.json` and your Lua files in that folder.
