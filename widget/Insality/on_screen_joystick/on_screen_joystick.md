# widget.on_screen_control API

> at widget/Insality/on_screen_control/on_screen_control.lua

## Functions

- [init](#init)
- [on_input](#on_input)
- [process_touch](#process_touch)
- [update](#update)

## Fields

- [button_action](#button_action)
- [on_screen_control](#on_screen_control)
- [stick_root](#stick_root)
- [stick_position](#stick_position)
- [on_action](#on_action)
- [on_movement](#on_movement)
- [on_movement_stop](#on_movement_stop)
- [is_multitouch](#is_multitouch)


### init

---
```lua
on_screen_control:init()
```

Initialize the on-screen control widget with joystick and action button


### on_input

---
```lua
on_screen_control:on_input(action_id, action)
```

Handle input events for touch and multitouch

- **Parameters:**
	- `action_id` *(hash)*: Action identifier
	- `action` *(action)*: Action data

- **Returns:**
	- `false` *(boolean)*: Always returns false to allow other handlers


### process_touch

---
```lua
on_screen_control:process_touch(action)
```

Process individual touch action for joystick and button

- **Parameters:**
	- `action` *(action|touch)*: Touch action data


### update

---
```lua
on_screen_control:update(dt)
```

Update function that triggers movement events when joystick is active

- **Parameters:**
	- `dt` *(number)*: Delta time in seconds


## Fields
<a name="button_action"></a>
- **button_action** (_node_): GUI node for the action button

<a name="on_screen_control"></a>
- **on_screen_control** (_node_): GUI node for the joystick root

<a name="stick_root"></a>
- **stick_root** (_node_): GUI node for the joystick stick

<a name="stick_position"></a>
- **stick_position** (_vector3_): Current position of the stick relative to center

<a name="on_action"></a>
- **on_action** (_event_): Event triggered when action button is pressed

<a name="on_movement"></a>
- **on_movement** (_event_): Event triggered continuously while joystick is moved. Parameters: x (number, -1..1), y (number, -1..1), dt (number)

<a name="on_movement_stop"></a>
- **on_movement_stop** (_event_): Event triggered when joystick is released

<a name="is_multitouch"></a>
- **is_multitouch** (_boolean_): Whether multitouch is supported on this device

