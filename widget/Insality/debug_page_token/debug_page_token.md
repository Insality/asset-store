# widget.debug_page_token API

> at widget/insality/debug_page_token/debug_page_token.lua

## Functions

- [render_properties_panel](#render_properties_panel)
- [token_count_containers](#token_count_containers)
- [token_count_tokens](#token_count_tokens)
- [render_container_page](#render_container_page)
- [render_token_details_page](#render_token_details_page)


### render_properties_panel

---
```lua
debug_page_token:render_properties_panel(druid, properties_panel)
```

- **Parameters:**
	- `druid` *(druid.instance)*:
	- `properties_panel` *(druid.widget.properties_panel)*:

### token_count_containers

---
```lua
debug_page_token:token_count_containers(containers)
```

Count the number of containers

- **Parameters:**
	- `containers` *(table<string, token.container_data>)*:

- **Returns:**
	- `` *(number)*:

### token_count_tokens

---
```lua
debug_page_token:token_count_tokens(tokens)
```

Count the number of tokens in a container

- **Parameters:**
	- `tokens` *(table<string, number>)*:

- **Returns:**
	- `` *(number)*:

### render_container_page

---
```lua
debug_page_token:render_container_page(token, container_id, properties_panel)
```

Render a specific container page

- **Parameters:**
	- `token` *(token)*:
	- `container_id` *(string)*:
	- `properties_panel` *(druid.widget.properties_panel)*:

### render_token_details_page

---
```lua
debug_page_token:render_token_details_page(container, token_id, properties_panel)
```

Render the details page for a specific token

- **Parameters:**
	- `container` *(token.container)*:
	- `token_id` *(string)*:
	- `properties_panel` *(druid.widget.properties_panel)*:

