shader_type spatial;
render_mode blend_add, cull_disabled;

uniform float BigLinesBrightness = 1.1;
uniform float DesatValue = 0.05;
uniform float SmallLinesBrightness = 10.0;
uniform float SquareBrightness = 1.3;
uniform float SquareFlickerSpeed = 1.0;
uniform float TexU = 0.5;
uniform float TexV = 0.5;
uniform float TypeBrightness = 3.0;
uniform float TypeFlickerSpeed = 0.01;
uniform float UIBrightness = 1.5;

uniform sampler2D Diffuse;
uniform sampler2D UIDetails;
uniform sampler2D TextureSample;

void fragment() {
	ALBEDO = vec3(0.0, 0.0, 0.0);
	// Detail Size
	vec2 detail_size = (TexU * TexV) * UV;
	
	// Detail Lines
	vec3 diffuse_col = texture(Diffuse, UV).rgb;
	//ALBEDO = diffuse_col;
	vec2 panned_uv_1 = detail_size + vec2(0.0, -0.01 * TIME);
	vec2 panned_uv_2 = detail_size + vec2(0.0, 0.01 * TIME);
	vec3 sampl_uv_1 = texture(TextureSample, panned_uv_1).rgb;
	vec3 sampl_uv_2 = texture(TextureSample, panned_uv_2).rgb;
	vec4 sampl_uv = texture(TextureSample, UV);
	vec3 uv_1_lerp =  mix(diffuse_col, diffuse_col * SmallLinesBrightness, sampl_uv_1.r);
	vec3 big_uv1_lerp = uv_1_lerp * BigLinesBrightness;
	vec3 uv2_lerp = mix(uv_1_lerp, big_uv1_lerp, sampl_uv_2.g);
	vec3 detail_lines = mix(uv2_lerp, diffuse_col, sampl_uv.a); /////
	
	// Square Flicker
	float t = TIME * SquareFlickerSpeed * 2.0 * PI;
	float s = sin(t);
	float c = cos(t);
	float sc = (s * 2.0) + abs(c);
	vec3 sqbright = SquareBrightness * diffuse_col;
	vec3 ui_detail = texture(UIDetails, UV).rgb;
	vec3 ui_detail_lerp = mix(detail_lines, sqbright, ui_detail.r);
	vec3 ui_detail_lerp2 = mix(detail_lines, ui_detail_lerp, sc);
	
	// Type Flicker
	float t2 = TIME * TypeFlickerSpeed * 2.0 * PI;
	float s2 = sin(t * 0.01);
	float c2 = cos(t * 0.01);
	float sc2 = (s * 2.0) + abs(c);
	vec3 type_bright = mix(ui_detail_lerp2, TypeBrightness * diffuse_col, ui_detail.g);
	
	vec3 lerp3 = mix(ui_detail_lerp2, type_bright, sc2);
	lerp3 *= UIBrightness;
	
	lerp3 = mix(lerp3.rgb, vec3(dot(lerp3.rgb, vec3(0.299, 0.587, 0.114))), DesatValue);
	
	ALBEDO = lerp3;
	ALPHA = 0.3;
	//ALBEDO.r = fract(panned_uv_2.x);
	//EMISSION = lerp3;
}
