# widget.external_image API

> at /widget/Insality/external_image/external_image.lua

Widget to load and display an image from external sources (resource path, absolute path or URL)

## Functions

- [load_from_resource_path](#load_from_resource_path)
- [load_from_absolute_path](#load_from_absolute_path)
- [load_from_url](#load_from_url)
## Fields

- [root](#root)



### load_from_resource_path

---
```lua
external_image:load_from_resource_path(resource_path)
```

- **Parameters:**
	- `resource_path` *(string)*: Resource path to the image, e.g. "/resources/images/example.png"

### load_from_absolute_path

---
```lua
external_image:load_from_absolute_path(absolute_path)
```

- **Parameters:**
	- `absolute_path` *(string)*: Absolute path to the image, e.g. "/Users/username/Documents/example.png"

- **Returns:**
	- `` *(nil)*:

### load_from_url

---
```lua
external_image:load_from_url(url, [callback])
```

- **Parameters:**
	- `url` *(string)*: URL to the image, e.g. "https://example.com/image.png"
	- `[callback]` *(function?)*: Callback function to call when the image is loaded, optional


## Fields
<a name="root"></a>
- **root** (_node_)

