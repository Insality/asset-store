# widget.properties_panel API

> at widget/insality/properties_panel/properties_panel.lua

## Functions

- [properties_constructors](#properties_constructors)
- [init](#init)
- [on_remove](#on_remove)
- [toggle_auto_refresh](#toggle_auto_refresh)
- [on_drag_widget](#on_drag_widget)
- [clear_created_properties](#clear_created_properties)
- [next_scene](#next_scene)
- [previous_scene](#previous_scene)
- [clear](#clear)
- [on_size_changed](#on_size_changed)
- [update](#update)
- [add_checkbox](#add_checkbox)
- [add_slider](#add_slider)
- [add_button](#add_button)
- [add_input](#add_input)
- [add_text](#add_text)
- [add_left_right_selector](#add_left_right_selector)
- [add_vector3](#add_vector3)
- [add_inner_widget](#add_inner_widget)
- [add_widget](#add_widget)
- [remove](#remove)
- [set_dirty](#set_dirty)
- [set_hidden](#set_hidden)
- [is_hidden](#is_hidden)
- [load_previous_page](#load_previous_page)
- [set_properties_per_page](#set_properties_per_page)
- [set_page](#set_page)
- [set_header](#set_header)
- [render_lua_table](#render_lua_table)

## Fields

- [root](#root)
- [scroll](#scroll)
- [layout](#layout)
- [container](#container)
- [container_content](#container_content)
- [container_scroll_view](#container_scroll_view)
- [contaienr_scroll_content](#contaienr_scroll_content)
- [button_hidden](#button_hidden)
- [text_header](#text_header)
- [paginator](#paginator)
- [properties](#properties)
- [scale_root](#scale_root)
- [content](#content)
- [default_size](#default_size)
- [header_size](#header_size)
- [scenes](#scenes)
- [current_page](#current_page)
- [properties_per_page](#properties_per_page)
- [button_back](#button_back)
- [button_refresh](#button_refresh)
- [is_dirty](#is_dirty)



### properties_constructors

---
```lua
properties_panel:properties_constructors()
```

List of properties functions to create a new widget. Used to not spawn non-visible widgets but keep the reference

### init

---
```lua
properties_panel:init()
```

### on_remove

---
```lua
properties_panel:on_remove()
```

### toggle_auto_refresh

---
```lua
properties_panel:toggle_auto_refresh()
```

### on_drag_widget

---
```lua
properties_panel:on_drag_widget([dx], [dy])
```

- **Parameters:**
	- `[dx]` *(any)*:
	- `[dy]` *(any)*:

### clear_created_properties

---
```lua
properties_panel:clear_created_properties()
```

### next_scene

---
```lua
properties_panel:next_scene()
```

### previous_scene

---
```lua
properties_panel:previous_scene()
```

### clear

---
```lua
properties_panel:clear()
```

### on_size_changed

---
```lua
properties_panel:on_size_changed([new_size])
```

- **Parameters:**
	- `[new_size]` *(any)*:

### update

---
```lua
properties_panel:update([dt])
```

- **Parameters:**
	- `[dt]` *(any)*:

### add_checkbox

---
```lua
properties_panel:add_checkbox([on_create])
```

- **Parameters:**
	- `[on_create]` *(fun(checkbox: widget.property_checkbox)|nil)*:

- **Returns:**
	- `` *(widget.properties_panel)*:

### add_slider

---
```lua
properties_panel:add_slider([on_create])
```

- **Parameters:**
	- `[on_create]` *(fun(slider: widget.property_slider)|nil)*:

- **Returns:**
	- `` *(widget.properties_panel)*:

### add_button

---
```lua
properties_panel:add_button([on_create])
```

- **Parameters:**
	- `[on_create]` *(fun(button: widget.property_button)|nil)*:

- **Returns:**
	- `` *(widget.properties_panel)*:

### add_input

---
```lua
properties_panel:add_input([on_create])
```

- **Parameters:**
	- `[on_create]` *(fun(input: widget.property_input)|nil)*:

- **Returns:**
	- `` *(widget.properties_panel)*:

### add_text

---
```lua
properties_panel:add_text([on_create])
```

- **Parameters:**
	- `[on_create]` *(fun(text: widget.property_text)|nil)*:

- **Returns:**
	- `` *(widget.properties_panel)*:

### add_left_right_selector

---
```lua
properties_panel:add_left_right_selector([on_create])
```

- **Parameters:**
	- `[on_create]` *(fun(selector: widget.property_left_right_selector)|nil)*:

- **Returns:**
	- `` *(widget.properties_panel)*:

### add_vector3

---
```lua
properties_panel:add_vector3([on_create])
```

- **Parameters:**
	- `[on_create]` *(fun(vector3: widget.property_vector3)|nil)*:

- **Returns:**
	- `` *(widget.properties_panel)*:

### add_inner_widget

---
```lua
properties_panel:add_inner_widget(widget_class, [template], [nodes], [on_create])
```

- **Parameters:**
	- `widget_class` *(<T:druid.widget>)*:
	- `[template]` *(string|nil)*:
	- `[nodes]` *(string|node|table<hash, node>|nil)*:
	- `[on_create]` *(fun(widget: <T:druid.widget>)|nil)*:

- **Returns:**
	- `` *(widget.properties_panel)*:

### add_widget

---
```lua
properties_panel:add_widget(create_widget_callback)
```

- **Parameters:**
	- `create_widget_callback` *(fun():druid.widget)*:

- **Returns:**
	- `` *(widget.properties_panel)*:

### remove

---
```lua
properties_panel:remove([widget])
```

- **Parameters:**
	- `[widget]` *(any)*:

### set_dirty

---
```lua
properties_panel:set_dirty()
```

Force to refresh properties next update

### set_hidden

---
```lua
properties_panel:set_hidden([is_hidden])
```

- **Parameters:**
	- `[is_hidden]` *(any)*:

### is_hidden

---
```lua
properties_panel:is_hidden()
```

- **Returns:**
	- `` *(unknown)*:

### load_previous_page

---
```lua
properties_panel:load_previous_page()
```

### set_properties_per_page

---
```lua
properties_panel:set_properties_per_page(properties_per_page)
```

- **Parameters:**
	- `properties_per_page` *(number)*:

### set_page

---
```lua
properties_panel:set_page(page)
```

Set a page of current scene

- **Parameters:**
	- `page` *(number)*:

### set_header

---
```lua
properties_panel:set_header(header)
```

Set a text at left top corner of the properties panel

- **Parameters:**
	- `header` *(string)*:

### render_lua_table

---
```lua
properties_panel:render_lua_table(data)
```

- **Parameters:**
	- `data` *(table)*:


## Fields
<a name="root"></a>
- **root** (_node_)

<a name="scroll"></a>
- **scroll** (_druid.scroll_)

<a name="layout"></a>
- **layout** (_druid.layout_)

<a name="container"></a>
- **container** (_druid.container_)

<a name="container_content"></a>
- **container_content** (_druid.container_)

<a name="container_scroll_view"></a>
- **container_scroll_view** (_druid.container_)

<a name="contaienr_scroll_content"></a>
- **contaienr_scroll_content** (_druid.container_)

<a name="button_hidden"></a>
- **button_hidden** (_druid.button_)

<a name="text_header"></a>
- **text_header** (_druid.text_)

<a name="paginator"></a>
- **paginator** (_widget.property_left_right_selector_)

<a name="properties"></a>
- **properties** (_druid.widget[]_): List of created properties

<a name="scale_root"></a>
- **scale_root** (_unknown_)

<a name="content"></a>
- **content** (_unknown_)

<a name="default_size"></a>
- **default_size** (_unknown_)

<a name="header_size"></a>
- **header_size** (_unknown_)

<a name="scenes"></a>
- **scenes** (_table_):  To have ability to go back to previous scene, collections of all properties to rebuild

<a name="current_page"></a>
- **current_page** (_integer_)

<a name="properties_per_page"></a>
- **properties_per_page** (_integer_)

<a name="button_back"></a>
- **button_back** (_unknown_)

<a name="button_refresh"></a>
- **button_refresh** (_unknown_)

<a name="is_dirty"></a>
- **is_dirty** (_boolean_)

