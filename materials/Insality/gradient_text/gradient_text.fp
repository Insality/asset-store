#version 140

in mediump vec2 var_texcoord0;
in mediump vec4 var_face_color;
in mediump vec4 var_outline_color;
in mediump vec4 var_shadow_color;
in mediump vec4 var_sdf_params;
in mediump vec4 var_layer_mask;
in mediump float var_cell_t;

out vec4 out_fragColor;
uniform mediump sampler2D texture_sampler;

void main()
{
	mediump vec4 df_sample = texture(texture_sampler, var_texcoord0);
	mediump float distance = df_sample.x;
	mediump float sdf_edge = var_sdf_params.x;
	mediump float sdf_outline = var_sdf_params.y;
	mediump float sdf_smoothing = var_sdf_params.z;
	mediump float sdf_is_single_layer = var_layer_mask.a;
	mediump float face_alpha = smoothstep(sdf_edge - sdf_smoothing, sdf_edge + sdf_smoothing, distance);
	mediump float outline_alpha = smoothstep(sdf_outline - sdf_smoothing, sdf_outline + sdf_smoothing, distance);

	// Vertical position inside the font cache cell (0 = bottom, 1 = top).
	mediump float cell_t = fract(var_cell_t);
	// Shadow alpha is softness: 1 = full-height gradient, lower = sharper mid split.
	// Alpha 0 (default) is treated as a full smooth gradient.
	mediump float softness = var_shadow_color.w > 0.001
		? clamp(var_shadow_color.w / max(var_face_color.w, 0.0001), 0.001, 1.0)
		: 1.0;
	mediump float gradient_t = clamp((cell_t - 0.5) / softness + 0.5, 0.0, 1.0);
	// Color at the top of the glyph, shadow color at the bottom.
	mediump vec3 gradient_rgb = mix(var_shadow_color.rgb, var_face_color.rgb, gradient_t);
	mediump vec4 face_color = vec4(gradient_rgb * var_face_color.w, var_face_color.w);

	out_fragColor = face_alpha * face_color * var_layer_mask.x +
		outline_alpha * var_outline_color * var_layer_mask.y * (1.0 - face_alpha * sdf_is_single_layer);
}
