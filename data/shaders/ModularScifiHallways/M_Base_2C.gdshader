shader_type spatial;

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

//uniform float r_detail_u = 3.4f;
//uniform float r_detail_v = 3.4f;
uniform float r_detail_u = 2.0f;
uniform float r_detail_v = 2.0f;

uniform float roughness_green = 0.1f;
uniform float roughness_other = 0.2f;
uniform float roughness_red = 0.65f;

uniform float spec_green = 0.5f;
uniform float spec_other = 0.5f;
uniform float spec_red = 0.55f;

uniform sampler2D trim_diffuse;

void fragment() {
	ALBEDO = texture(diffuse, UV).rgb;
	vec3 mask_rgb = texture(mask, UV).rgb;
	//ALBEDO = texture(trim_diffuse, UV2).rgb;
	
	float metallic = mix(metallic_other, mettalic_red, mask_rgb.r);
	metallic = mix(metallic, metallic_green, mask_rgb.g);
	METALLIC = metallic;
	
	float spec = mix(spec_other, spec_red, mask_rgb.r);
	spec = mix(spec, spec_green, mask_rgb.g);
	SPECULAR = spec;
	
	vec2 detail_uv = vec2(r_detail_u, r_detail_v);
	detail_uv *= UV;
	float rough = mix(roughness_other, roughness_red, mask_rgb.r);
	rough = mix(rough, roughness_green, mask_rgb.g);
	float scratches_col = texture(scratches, detail_uv).r;
	rough = clamp(rough * scratches_col, 0.0f, 1.0f);
	ROUGHNESS = rough;

	vec3 base_normal = texture(normal, UV).rgb;
	vec2 norm_detail_uv = vec2(norm_detail_u, norm_detail_v);
	norm_detail_uv *= UV;
	vec3 detail_normal = texture(brushed, norm_detail_uv).rgb;
	detail_normal *= vec3(1.0f, 1.0f, 0.0f);
	base_normal = mix(base_normal, detail_normal, 0.5);
	//base_normal = detail_normal;
	NORMAL_MAP = base_normal;
}
