# Dependencies Asset Store

Find all available library dependencies here and install them with one click into your project. After installation, the dependency URL is automatically added to your `game.project` file with all required dependencies. After any changes, the library will be automatically fetched.

## How to Open

`Project` -> `[Asset Store] Dependencies` in the menu.

## How to Submit

The depenencies is auto-synced with the [Defold Asset Portal](https://defold.com/assets/). If you want to submit a new dependency, please submit it to the [Defold Asset Portal](https://defold.com/assets/) and it will be automatically synced to this repository.

## How to add API button to your dependency

To add API button to your dependency, you need to add the `api` field to your dependency JSON file inside this repository.

```json
"api": "https://github.com/your-username/your-repo?tab=readme-ov-file#api",
```

The `api` field should point to the API documentation of your dependency.

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
