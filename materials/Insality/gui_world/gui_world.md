# GUI in World Camera Space

This material and example show how to render GUI in world coordinates so it can follow game objects and appear on the same layer as your sprites.

Based on [How to GUI in Defold — GUI in World Coordinates](https://forum.defold.com/t/how-to-gui-in-defold/73256#p-165285-gui-in-world-coordinates-48).

**Main idea:** The only difference from normal GUI is that these materials use the **`tile`** render tag, so they are drawn in the same pass as your usual sprites (same layer, same camera). No render script changes needed if you already draw `tile`. If you need more control (e.g. draw order or a separate pass), add a new tag and set it in the gui world materials (edit the material files and your render script).

## Overview

1. **Custom material on GUI** — Use the provided world-space material (or a copy with your own tag).
2. **Disable GUI adjust reference** — So layout is in world units, not screen-adjusted.
3. **Font with same-tag material** — If the GUI has text, use a font that uses the world GUI font material (same tag as your GUI material).
4. **Transform input before Druid** — Convert screen coordinates to world (or your GUI space) in the GUI script’s `on_input` before passing the action to Druid.
5. **Control transform from game logic** — Update position/scale of the world GUI from the game object (e.g. in `late_update`) so it follows the GO or camera.

---

## 1. Add custom material to GUI

- In the GUI scene, set **Material** to the world-space material (e.g. `/materials/Insality/gui_world/gui_world.material`).
- For nodes that must render in world space, assign the same material in the **materials** block and set each node’s **material** to that name.

The materials in this asset use the **`tile`** tag, so they render together with your sprites. For a custom pass or order, add a new tag (e.g. `world_gui`) in the material files and add a predicate for it in your render script.

---

## 2. Set GUI adjust mode to Disabled

In the GUI file, set:

```
adjust_reference: ADJUST_REFERENCE_DISABLED
```

So the GUI is not scaled or shifted to screen size; coordinates stay in your world (or design) units.

---

## 3. Create a font with custom material (if you use text)

If the world GUI contains text:

- Use a font that references the world GUI font material (e.g. `gui_world_font_df.material`), which uses the same tag as the GUI material.
- In the GUI scene, add that font in **fonts** and use it for the text nodes.

Example font file:

```
font: "/druid/fonts/Roboto-Bold.ttf"
material: "/materials/Insality/gui_world/gui_world_font_df.material"
```

---

## 4. Adjust input coordinates before sending to Druid

Touch/click positions are in screen space. World GUI is in world space, so convert before passing to Druid.

In the **GUI script** that owns the world GUI (and Druid), in `on_input`:

1. Read `action.screen_x`, `action.screen_y`.
2. Convert them to world (or your GUI space) using your camera API (e.g. `camera.screen_xy_to_world`, or `rendercam.screen_to_world_2d`).
3. Optionally account for GUI stretch (window size vs. `gui.get_width()` / `gui.get_height()`) so the coordinates match the space in which you position the GUI.
4. Overwrite `action.x` and `action.y` with the converted values.
5. Return `self.druid:on_input(action_id, action)`.

Example pattern (exact conversion depends on your camera and stretch):

```lua
function on_input(self, action_id, action)
	if action.screen_x then
		local window_x, window_y = window.get_size()
		local stretch_x = window_x / gui.get_width()
		local stretch_y = window_y / gui.get_height()
		local world_position = camera.screen_xy_to_world(action.screen_x, action.screen_y)
		action.x = world_position.x / stretch_x
		action.y = world_position.y / stretch_y
	end
	return self.druid:on_input(action_id, action)
end
```

---

## 5. Control GUI transform via dedicated methods

World GUI position and scale are not adjusted by the engine; your game logic must set them.

- From the **game object** that owns (or follows) the world GUI:
  - In `late_update` (or after the GO/camera has moved), get the desired world position and scale (e.g. `go.get_world_position(gui_id)` / `go.get_world_scale(gui_id)`).
  - Call a dedicated widget API, e.g. `widget:set_position(position)` and `widget:set_scale(scale)`.
- In the **Druid widget** (or GUI component), implement:
  - `set_position(position)` → `gui.set_position(self.root, position)`
  - `set_scale(scale)` → `gui.set_scale(self.root, scale)`

So the GO (or camera) drives the transform; the widget only applies it to the GUI root.

---

## More control: custom tag

By default the materials use the **`tile`** tag, so they render with your sprites and no render script change is needed.

If you need a separate pass, draw order, or stencil: add a new tag (e.g. `world_gui`) in both `gui_world.material` and `gui_world_font_df.material`, then in your render script create a predicate for that tag and draw it where you need (e.g. after tiles, with stencil on/off).

---

## Summary checklist

- [ ] GUI scene uses the world-space material (tag `tile`, or your custom tag).
- [ ] `adjust_reference: ADJUST_REFERENCE_DISABLED` in the GUI file.
- [ ] Text uses a font with the world GUI font material (same tag).
- [ ] `on_input` converts screen coordinates to world (or GUI space) before `druid:on_input()`.
- [ ] Position and scale are set from game logic via `set_position` / `set_scale` on the widget.
