# widget.tiling_node API

> at /widget/Insality/tiling_node/tiling_node.lua

This widget allow to use "repeat" shader over a node size in GUI.
To use this, you should add a `druid.script` file nearby the GUI component with this widget

## Functions

- [on_node_property_changed](#on_node_property_changed)
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
- [PROP_SIZE_X](#PROP_SIZE_X)
- [PROP_SIZE_Y](#PROP_SIZE_Y)
- [PROP_SCALE_X](#PROP_SCALE_X)
- [PROP_SCALE_Y](#PROP_SCALE_Y)
- [margin](#margin)
- [timer_no_init](#timer_no_init)
- [is_inited](#is_inited)



### on_node_property_changed

---
```lua
tiling_node:on_node_property_changed(node, property)
```

Call this if you want to update the tiling animation when the node size or scale changes

- **Parameters:**
	- `node` *(node)*:
	- `property` *(string)*:

### start_animation

---
```lua
tiling_node:start_animation(repeat_x, repeat_y)
```

 Start our repeat shader work

- **Parameters:**
	- `repeat_x` *(number)*: X factor
	- `repeat_y` *(number)*: Y factor

### set_repeat

---
```lua
tiling_node:set_repeat([repeat_x], [repeat_y])
```

Update repeat factor values

- **Parameters:**
	- `[repeat_x]` *(number?)*: X factor
	- `[repeat_y]` *(number?)*: Y factor

- **Returns:**
	- `` *(widget.tiling_node)*:

### set_offset

---
```lua
tiling_node:set_offset([offset_perc_x], [offset_perc_y])
```

Set the distance offset between the tiles
Can used for the moving effect

- **Parameters:**
	- `[offset_perc_x]` *(number?)*: X offset
	- `[offset_perc_y]` *(number?)*: Y offset

- **Returns:**
	- `` *(widget.tiling_node)*:

### set_margin

---
```lua
tiling_node:set_margin([margin_x], [margin_y])
```

Set the distance between the tiles

- **Parameters:**
	- `[margin_x]` *(number?)*: X margin in percentage from 0 to 1
	- `[margin_y]` *(number?)*: Y margin in percentage from 0 to 1

- **Returns:**
	- `` *(widget.tiling_node)*:

### set_scale

---
```lua
tiling_node:set_scale(scale)
```

Set the scale of the node

- **Parameters:**
	- `scale` *(number)*: Scale factor

- **Returns:**
	- `` *(widget.tiling_node)*:


## Fields
<a name="animation"></a>
- **animation** (_table_)

<a name="node"></a>
- **node** (_node_)

<a name="params"></a>
- **params** (_vector4_)

<a name="time"></a>
- **time** (_number_)

<a name="PROP_SIZE_X"></a>
- **PROP_SIZE_X** (_unknown_)

<a name="PROP_SIZE_Y"></a>
- **PROP_SIZE_Y** (_unknown_)

<a name="PROP_SCALE_X"></a>
- **PROP_SCALE_X** (_unknown_)

<a name="PROP_SCALE_Y"></a>
- **PROP_SCALE_Y** (_unknown_)

<a name="margin"></a>
- **margin** (_integer_)

<a name="timer_no_init"></a>
- **timer_no_init** (_unknown_)

<a name="is_inited"></a>
- **is_inited** (_boolean_)

