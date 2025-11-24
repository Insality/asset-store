# widget.navigation_handler API

> at widget/insality/navigation_handler/navigation_handler.lua

Widget force handling GUI navigation via keyboard/gamepad.

### Setup
Loads the widget module:
`local navigation_handler = require("druid.widgets.navigation_handler.navigation_handler")`

Create the new widget instance:
`self.nav = self.druid:new_widget(navigation_handler)`

Set the first component instance (likely a button) to be selected. This is **required**.
`self.nav:select_component(self.my_button)`


### Example using the `on_select` event
```
local function on_select_btn(self, new, current)
    gui.play_flipbook(new.node, "button_selected")
    gui.play_flipbook(current.node, "button")
end
```
With `self.nav.on_select:subscribe(on_select_btn)`


### Notes
- `on_select` event callback params: (self, component_instance, component_instance).
-   - **self** - Druid self context.
-   - **new** - The component that will be selected next.
-   - **current** - The component that is about to be de-selected.
- Key triggers in `input.binding` should match your setup.
- Used `action_id`'s are:' `key_up`, `key_down`, `key_left` and `key_right`.

## Functions

- [init](#init)
- [select_component](#select_component)
- [set_weight](#set_weight)
- [set_tolerance](#set_tolerance)
- [set_select_trigger](#set_select_trigger)
- [get_select_trigger](#get_select_trigger)
- [set_temporary_select_triggers](#set_temporary_select_triggers)
- [get_selected_component](#get_selected_component)
- [set_deselect_directions](#set_deselect_directions)

## Fields

- [on_select](#on_select)



### init

---
```lua
navigation_handler:init()
```

The constructor for the navigation_handler widget.

### select_component

---
```lua
navigation_handler:select_component(component)
```

Set the given `druid.component` as selected component.

- **Parameters:**
	- `component` *(druid.component)*: Current druid component that starts as selected.

- **Returns:**
	- `self` *(widget.navigation_handler)*:

### set_weight

---
```lua
navigation_handler:set_weight(new_value)
```

Sets a new weight value which affects the next button diagonal finding logic.

- **Parameters:**
	- `new_value` *(number)*:

- **Returns:**
	- `self` *(widget.navigation_handler)*:

### set_tolerance

---
```lua
navigation_handler:set_tolerance(new_value)
```

Sets a new tolerance value. Can be useful when scale or window size changes.

- **Parameters:**
	- `new_value` *(number)*: How far to allow misalignment on the perpendicular axis when finding the next button.

- **Returns:**
	- `self` *(widget.navigation_handler)*: The current navigation handler instance.

### set_select_trigger

---
```lua
navigation_handler:set_select_trigger(key)
```

Set input action_id name to trigger selected component by keyboard/gamepad.

- **Parameters:**
	- `key` *(hash)*: The action_id of the input key. Example: "key_space".

- **Returns:**
	- `self` *(widget.navigation_handler)*: The current navigation handler instance.

### get_select_trigger

---
```lua
navigation_handler:get_select_trigger()
```

Get current the trigger key for currently selected component.

- **Returns:**
	- `_select_trigger` *(hash)*: The action_id of the input key.

### set_temporary_select_triggers

---
```lua
navigation_handler:set_temporary_select_triggers(keys)
```

Set the trigger keys for the selected component. Stays valid until the selected component changes.

- **Parameters:**
	- `keys` *(string|table|hash)*: Supports multiple action_ids if the given value is a table with the action_id hashes or strings.

- **Returns:**
	- `self` *(widget.navigation_handler)*: The current navigation handler instance.

### get_selected_component

---
```lua
navigation_handler:get_selected_component()
```

Get the currently selected component.

- **Returns:**
	- `_selected_component` *(druid.component|nil)*: Selected component, which often is a `druid.button`.

### set_deselect_directions

---
```lua
navigation_handler:set_deselect_directions(dir)
```

Set the de-select direction for the selected button. If this is set
then the next button can only be in that direction.

- **Parameters:**
	- `dir` *(string|table)*: Valid directions: "up", "down", "left", "right". Can take multiple values as a table of strings.

- **Returns:**
	- `self` *(widget.navigation_handler)*: The current navigation handler instance.


## Fields
<a name="on_select"></a>
- **on_select** (_event_): fun(self, component_instance, component_instance) Triggers when a new component is selected. The first component is for the newly selected and the second is for the previous component.

