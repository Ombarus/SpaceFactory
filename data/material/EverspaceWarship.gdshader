shader_type spatial;

uniform sampler2D c_ao;
uniform sampler2D r_mt_e;
uniform sampler2D normal;

void fragment() {
	ALBEDO.rgb = textureLod(c_ao, UV, 1.0).rgb;
	AO = textureLod(c_ao, UV, 1.0).a;
	ROUGHNESS = textureLod(r_mt_e, UV, 1.0).r;
	METALLIC = textureLod(r_mt_e, UV, 1.0).g;
	EMISSION = textureLod(c_ao, UV, 1.0).rgb * textureLod(r_mt_e, UV, 1.0).b;
	NORMAL = textureLod(normal, UV, 1.0).rgb;
}