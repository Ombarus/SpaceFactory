shader_type spatial;
render_mode cull_disabled;

uniform sampler2D diffuse;
uniform sampler2D mask;
uniform sampler2D normal;

uniform sampler2D scratches;
uniform sampler2D brushed;

uniform float metallic_green = 0.7f;
uniform float metallic_other = 0.75f;
uniform float mettalic_red = 0.0f;

uniform float norm_detail_u = 18.0f;
uniform float norm_detail_v = 18.0f;

uniform float r_detail_u = 2.0f;
uniform float r_detail_v = 2.0f;

uniform float roughness_green = 0.1f;
uniform float roughness_other = 0.2f;
uniform float roughness_red = 0.65f;

uniform float spec_green = 0.5f;
uniform float spec_other = 0.5f;
uniform float spec_red = 0.55f;

uniform sampler2D emissive;
uniform float light_intensity = 0.0;

uniform vec3 RColor : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 GColor : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 OtherColor : source_color = vec3(1.0, 1.0, 1.0);
uniform float DiffuseDesaturation = 0.0f;
uniform float RoughnessBlendContrast = 0.0;

vec3 desat(vec3 col, float desat_value)
{
	return mix(col.rgb, vec3(dot(col.rgb, vec3(0.299, 0.587, 0.114))), desat_value);
}

vec3 cheap_contrast_rgb(float input_contrast, vec3 input_color)
{
	vec3 s = vec3(0.0 - input_contrast);
	vec3 a = vec3(input_contrast + 1.0);
	vec3 res = clamp(mix(s, a, input_color), vec3(0), vec3(1));
	return res;
}

void fragment() {
	// DIFFUSE
	ALBEDO = vec3(0.0, 0.0, 0.0);
	vec3 diff_base = texture(diffuse, UV).rgb;
	vec3 mask_col = texture(mask, UV).rgb;
	diff_base = desat(diff_base, DiffuseDesaturation);
	vec3 rcol = diff_base * RColor;
	rcol = mix(diff_base, rcol, mask_col.r);
	vec3 gcol = diff_base * GColor;
	gcol = mix(rcol, gcol, mask_col.g);
	vec3 othercol = diff_base * OtherColor;
	othercol = mix(othercol, gcol, mask_col.r + mask_col.g);
	ALBEDO = othercol;
	
	//METALLIC
	float metal = mix(metallic_other, mettalic_red, mask_col.r);
	metal = mix(metal, metallic_green, mask_col.g);
	METALLIC = metal;
	//METALLIC = 1.0;
	
	//ROUGHNESS
	float rough = mix(roughness_other, roughness_red, mask_col.r);
	rough = mix(rough, roughness_green, mask_col.g);
	vec2 rough_uv = vec2(r_detail_u, r_detail_v) * UV;
	vec3 scratch_col = texture(scratches, rough_uv).rgb;
	scratch_col = cheap_contrast_rgb(RoughnessBlendContrast, scratch_col);
	ROUGHNESS = rough * scratch_col.r;
	//ROUGHNESS = 0.0;
	
	//DETAIL + NORMAL
	vec2 det_uv = vec2(norm_detail_u, norm_detail_v) * UV;
	vec3 brush_col = texture(brushed, det_uv).rgb;
	vec3 norm_col = texture(normal, UV).rgb;
	brush_col = brush_col * vec3(1.0, 1.0, 0.0);
	NORMAL_MAP = (brush_col + norm_col) / 2.0;
	
	//SPECULAR
	float spec = mix(spec_other, spec_red, mask_col.r);
	spec = mix(spec, spec_green, mask_col.g);
	SPECULAR = spec;
	
	//LIGHT
	EMISSION = texture(emissive, UV).rgb * light_intensity;
}
