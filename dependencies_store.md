# Dependencies Asset Store

Find all available Defold dependencies here and install them with one click into your project. After installation, the dependency URL is automatically added to your `game.project` file with all required dependencies. After any changes, the library will be automatically fetched.

## How to Open

`Project` -> `[Asset Store] Dependencies` in the menu.

You will see the list of your current dependencies and here you can update them if an new version is available.

To see the all list of dependencies, select "All" in the filter dropdown, instead of "Installed".


## How to Submit

The depenencies is auto-synced with the [Defold Asset Portal](https://defold.com/assets/). If you want to submit a new dependency, please submit it to the [Defold Asset Portal](https://defold.com/assets/) and it will be automatically synced to this repository.

## How to add API button to your dependency

To add API button to your dependency, you need to add the `api` field to your dependency JSON file inside this repository.

```json
"api": "https://github.com/your-username/your-repo?tab=readme-ov-file#api",
```

The `api` field should point to the API documentation of your dependency.

## Minimum Defold version

A dependency version can require a newer Defold than the one you run. Such versions are shown in the version dropdown as `4.7.7 — needs Defold 1.13.1` and cannot be selected, since the editor refuses to fetch them anyway. `Install` picks the newest version your editor supports, and `Update` stays disabled once you are on it.

This comes from the `min_versions` field, filled automatically by the asset-portal sync from the `min_defold_version` of a release:

```json
"min_versions": {
	"4.7.0": "1.13.1",
	"4.7.7": "1.13.1"
}
```

A release declares it with a Defold badge in its GitHub release notes, e.g. `https://img.shields.io/badge/Defold-1.13.1-blue`. Versions without an entry are treated as usable by any editor version.

## Example of dependency file

```json
{
	"author": "Insality",
	"id": "defold-saver",
	"title": "Defold Saver",
	"description": "Defold Save File Manager",
	"tags": [
		"system",
		"util",
		"tools"
	],
	"stars": 42,
	"content": [
		"https://github.com/Insality/defold-saver/archive/refs/tags/1.zip",
		"https://github.com/Insality/defold-saver/archive/refs/tags/2.zip",
		"https://github.com/Insality/defold-saver/archive/refs/tags/3.zip",
		"https://github.com/Insality/defold-saver/archive/refs/tags/4.zip",
		"https://github.com/Insality/defold-saver/archive/refs/tags/5.zip"
	],
	"example_code": "https://github.com/Insality/defold-saver",
	"api": "https://github.com/Insality/defold-saver/blob/main/api/saver_api.md",
	"author_url": "https://github.com/Insality",
	"image": "defold-saver-thumb.png"
}
```
