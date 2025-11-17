# Druid Widget Store

Find all available widgets here and install them with one click into your project. After installation, the widget is copied locally, so you can freely modify it to fit your needs!

If you've made improvements to an existing widget, feel free to send updates via Pull Request. The community will appreciate it!

## How to Open

`Project` -> `[Druid] Widget Store` in the menu. Make sure the Druid library is installed and fetched.

## Adding Your Widget

### File Structure

Create a folder for your widget:

```
widget/
└── {YourName}/
    └── {widget_id}/
        ├── {widget_id}.json      # Widget manifest (required)
        ├── {widget_id}.lua        # Widget script
        ├── {widget_id}.gui        # GUI file (if needed)
        ├── {widget_id}.md         # Documentation (recommended)
        ├── {widget_id}.png        # Preview image (recommended)
        └── example/               # Example (optional)
            ├── example_{widget_id}.collection
            ├── example_{widget_id}.gui
            └── example_{widget_id}.gui_script
```

**Important**: The folder name must match the `id` in the JSON file.

### Widget Manifest

Create a `{widget_id}.json` file:

#### Required Fields

- `author` — your name (usually GitHub username)
- `version` — version number (start with 1)
- `id` — unique identifier (usually matches folder name)

#### Recommended Fields

- `title` — widget name
- `description` — brief description
- `content` — list of files to include:
  ```json
  "content": [
    "widget_id.lua",
    "widget_id.gui"
  ]
  ```
- `api` — path to documentation (e.g., `"widget_id.md"`)
- `image` — path to image (e.g., `"widget_id.png"`)
- `tags` — tags for search (e.g., `["debug", "ui"]`)
- `author_url` — link to your profile

#### Optional Fields

- `depends` — dependencies on other widgets:
  ```json
  "depends": ["Insality:mini_graph@1"]
  ```
- `example` — path to example (e.g., `"/widget/Author/widget_id/example/example_widget.collectionc"`)
- `example_url` — external link to example (takes priority over `example`)

### Example Manifest

```json
{
  "author": "YourAuthorName",
  "id": "my_awesome_widget",
  "version": 1,
  "title": "My Awesome Widget",
  "description": "A widget that does something cool",
  "image": "my_awesome_widget.png",
  "api": "my_awesome_widget.md",
  "author_url": "https://github.com/YourAuthorName",
  "tags": ["ui", "custom"],
  "content": [
    "my_awesome_widget.lua",
    "my_awesome_widget.gui"
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
   git checkout -b add-my-widget
   ```
4. Add widget files to `widget/{YourName}/{widget_id}/`
5. Commit:
   ```bash
   git add widget/YourAuthorName/my_awesome_widget/
   git commit -m "Add my_awesome_widget widget"
   ```
6. Push:
   ```bash
   git push origin add-my-widget
   ```
7. Create a Pull Request on GitHub

After submitting, the automated system will check your widget, maintainers will review the code, and if everything looks good — your widget will automatically appear in the store!

### Tips

- Test your widget before submitting
- Make example collection and set with `example` field in the manifest. This collection will be built and added as an example to the widget.
- Write clear documentation with examples
- Use meaningful tags
- Check out other widgets for code style reference
- Start with version 1

## Updating a Widget

To update an existing widget:
1. Increment the `version` in the manifest
2. Make your changes
3. Create a new PR

All previous versions are preserved automatically.
