# Editor Scripts Asset Store

Find all available editor scripts here and install them with one click into your project. After installation, the editor script is copied locally, so you can freely modify it to fit your needs!

If you've made improvements to an existing editor script, feel free to send updates via Pull Request. The community will appreciate it!

## How to Open

`Project` -> `[Asset Store] Editor Scripts` in the menu.

## Adding Your Editor Script

### File Structure

Create a folder for your editor script:

```
editor_scripts/
└── {YourName}/
    └── {script_id}/
        ├── {script_id}.json          # Editor script manifest (required)
        ├── {script_id}.editor_script # Editor script file
        ├── {script_id}.md            # Documentation (optional)
        └── {script_id}.png           # Preview image (optional)
```

**Important**: The folder name must match the `id` in the JSON file.

### Editor Script Manifest

Create a `{script_id}.json` file:

#### Required Fields

- `author` — your name (usually GitHub username)
- `id` — unique identifier (usually matches folder name)
- `version` — version number (start with 1)

#### Recommended Fields

- `title` — editor script name
- `description` — brief description
- `content` — list of files to include:
  ```json
  "content": [
    "script_id.editor_script"
  ]
  ```
- `api` — path to documentation (e.g., `"script_id.md"`)
- `image` — path to image (e.g., `"script_id.png"`)
- `tags` — tags for search (e.g., `["utility", "debug"]`)
- `author_url` — link to your profile

#### Optional Fields

- `depends` — dependencies on other editor scripts:
  ```json
  "depends": ["Insality:other_script@1"]
  ```

### Example Manifest

```json
{
  "author": "YourAuthorName",
  "id": "my_awesome_script",
  "version": 1,
  "title": "My Awesome Editor Script",
  "description": "An editor script that does something cool",
  "image": "my_awesome_script.png",
  "api": "my_awesome_script.md",
  "author_url": "https://github.com/YourAuthorName",
  "tags": ["utility", "custom"],
  "content": [
    "my_awesome_script.editor_script"
  ],
  "depends": []
}
```

### How to Submit

1. Fork the repository on GitHub
2. Clone your fork:
   ```bash
   git clone https://github.com/YourUsername/core.git
   cd core
   ```
3. Create a branch:
   ```bash
   git checkout -b add-my-editor-script
   ```
4. Add editor script files to `editor_scripts/{YourName}/{script_id}/`
5. Commit:
   ```bash
   git add editor_scripts/YourAuthorName/my_awesome_script/
   git commit -m "Add my_awesome_script editor script"
   ```
6. Push:
   ```bash
   git push origin add-my-editor-script
   ```
7. Create a Pull Request on GitHub

After submitting, the automated system will check your editor script, maintainers will review the code, and if everything looks good — your editor script will automatically appear in the store!

### Tips

- Test your editor script before submitting
- Write clear documentation with examples
- Use meaningful tags
- Check out other editor scripts for code style reference
- Start with version 1

## Updating an Editor Script

To update an existing editor script:
1. Increment the `version` in the manifest
2. Make your changes
3. Create a new PR

All previous versions are preserved automatically.

