# widget.tiling_node API

> at widget/Insality/tiling_node/tiling_node.lua

## Functions

- [init](#init)
- [final](#final)
- [on_get_atlas_path](#on_get_atlas_path)
- [on_node_property_changed](#on_node_property_changed)
- [get_repeat_count_from_node](#get_repeat_count_from_node)
- [init_tiling_animation](#init_tiling_animation)
- [start_animation](#start_animation)
- [set_repeat](#set_repeat)
- [set_offset](#set_offset)
- [set_margin](#set_margin)
- [set_scale](#set_scale)

## Fields

- [animation](#animation)
- [node](#node)
- [params](#params)
- [time](#time)


### init

---
```lua
tiling_node:init(node)
```

Initialize the tiling node component

- **Parameters:**
	- `node` *(node|string)*: GUI node or node id to apply tiling to


### final

---
```lua
tiling_node:final()
```

Clean up resources and cancel timers


### on_get_atlas_path

---
```lua
tiling_node:on_get_atlas_path(atlas_path)
```

Callback when atlas path is retrieved

- **Parameters:**
	- `atlas_path` *(string)*: Path to the atlas texture


### on_node_property_changed

---
```lua
tiling_node:on_node_property_changed(node, property)
```

Handle node property changes (size or scale)

- **Parameters:**
	- `node` *(node)*: The node that changed
	- `property` *(string)*: Name of the property that changed


### get_repeat_count_from_node

---
```lua
tiling_node:get_repeat_count_from_node()
```

Calculate repeat count based on node size and scale

- **Returns:**
	- `repeat_x` *(number)*: Number of times to repeat horizontally
	- `repeat_y` *(number)*: Number of times to repeat vertically


### init_tiling_animation

---
```lua
tiling_node:init_tiling_animation(atlas_path)
```

Initialize animation data from atlas

- **Parameters:**
	- `atlas_path` *(string)*: Path to the atlas texture

- **Returns:**
	- `success` *(boolean)*: Whether initialization was successful


### start_animation

---
```lua
tiling_node:start_animation(repeat_x, repeat_y)
```

Start tiling animation with specified repeat counts

- **Parameters:**
	- `repeat_x` *(number)*: X repeat factor
	- `repeat_y` *(number)*: Y repeat factor


### set_repeat

---
```lua
tiling_node:set_repeat(repeat_x, repeat_y)
```

Update repeat factor values

- **Parameters:**
	- `[repeat_x]` *(number?)*: X factor (optional)
	- `[repeat_y]` *(number?)*: Y factor (optional)


### set_offset

---
```lua
tiling_node:set_offset(offset_perc_x, offset_perc_y)
```

Set offset in percentage

- **Parameters:**
	- `[offset_perc_x]` *(number?)*: X offset (optional)
	- `[offset_perc_y]` *(number?)*: Y offset (optional)

- **Returns:**
	- `self` *(tiling_node)*: Returns self for chaining


### set_margin

---
```lua
tiling_node:set_margin(margin_x, margin_y)
```

Set margin between tiles

- **Parameters:**
	- `[margin_x]` *(number?)*: X margin (optional)
	- `[margin_y]` *(number?)*: Y margin (optional)

- **Returns:**
	- `self` *(tiling_node)*: Returns self for chaining


### set_scale

---
```lua
tiling_node:set_scale(scale)
```

Set scale of the node

- **Parameters:**
	- `scale` *(number)*: Scale value

- **Returns:**
	- `self` *(tiling_node)*: Returns self for chaining


## Fields
<a name="animation"></a>
- **animation** (_table_): Animation data with frames and timing

<a name="node"></a>
- **node** (_node_): The GUI node being tiled

<a name="params"></a>
- **params** (_vector4_): Shader parameters (margin_x, margin_y, offset_x, offset_y)

<a name="time"></a>
- **time** (_number_): Current animation time

