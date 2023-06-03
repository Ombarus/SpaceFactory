shader_type spatial;

uniform sampler2D Diffuse;
uniform float Metallic = 0.5;
uniform float Roughness = 0.5;
uniform float Specular = 0.5;
uniform float WireBrightness = 1.0;
uniform vec3 WireColor : source_color = vec3(1.0, 1.0, 1.0);

void fragment() {
	vec3 col = texture(Diffuse, UV).rgb;
	col = col * WireColor;
	col = pow(col, vec3(WireBrightness));
	ALBEDO = col;
	METALLIC = Metallic;
	SPECULAR = Specular;
	ROUGHNESS = Roughness;
}
