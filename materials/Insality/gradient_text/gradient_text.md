# Gradient Text Material

Distance-field font material that paints a **vertical gradient on each glyph**. It uses the font cache cell layout from the [Fonts manual](https://defold.com/manuals/font/#font-cache): `texture_size_recip.w` is the cache cell height ratio, so the gradient stays aligned to the glyph instead of the atlas UV.

The shadow channel is reused for the second gradient color, so font drop shadows are not rendered. Outline still works as a solid color.

The font must be **Output Format** `TYPE_DISTANCE_FIELD`. After installing from the store (default folder `/materials`), the material path is `/materials/gradient_text/gradient_text.material`.

## Setup (GUI)

Add the material to the GUI scene and assign it on the text node. The font can keep the default DF material.

1. In the GUI, add **Materials** → `gradient_text` → `gradient_text.material`.
2. On the text node, set **Material** to `gradient_text`.

```
materials {
  name: "gradient_text"
  material: "/materials/Insality/gradient_text/gradient_text.material"
}
```

On the text node: `material: "gradient_text"`.

## Setup (font or Label)

You can also set **Material** on the `.font` itself. That applies the gradient to every use of that font. Both approaches work.

For **Label** components, copy the material and change the tag from `gui` to `tile`.

```
font: "/builtins/fonts/vera_mo_bd.ttf"
material: "/materials/Insality/gradient_text/gradient_text.material"
output_format: TYPE_DISTANCE_FIELD
```

## Colors

| Property | Role |
|----------|------|
| **Color** | Top of the glyph |
| **Shadow** | Bottom of the glyph |
| **Shadow alpha** | Gradient softness. `1` = full-height blend. Lower values sharpen the split around the middle. `0` is treated as a full smooth gradient. |
| **Outline** | Solid outline (optional) |

Swap Color and Shadow if you want the opposite direction.

Lua:

```lua
gui.set_color(node, vmath.vector4(1.0, 0.92, 0.4, 1.0))
gui.set_shadow(node, vmath.vector4(0.85, 0.2, 0.05, 1.0))
```

In the editor, set the same values on the text node: **Color**, **Shadow**, and **Shadow Alpha**.
