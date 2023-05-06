shader_type spatial;
render_mode blend_mix;

uniform vec4 ColorGlass : source_color = vec4(0.0, 0.001202, 0.003303, 0.05);
uniform float Roughness = 0.0;
uniform float Specular = 10.0;
uniform float FresnelFalloff = 10.0;
uniform float Refraction = 1.0;

void fragment() {
	ALBEDO = ColorGlass.rgb;
	ALPHA = ColorGlass.a;
	SPECULAR = Specular;
	ROUGHNESS = Roughness;
}
