shader_type spatial;

uniform float Brightness = 1.0;
uniform float Desaturation = 0.0;
uniform sampler2D Diffuse;
uniform vec3 LightColor : source_color = vec3(1.0, 1.0, 1.0);
uniform float Metallic = 0.5;
uniform float Roughness = 0.5;

vec3 desat(vec3 col, float desat_value)
{
	return mix(col.rgb, vec3(dot(col.rgb, vec3(0.299, 0.587, 0.114))), desat_value);
}

void fragment() {
	vec3 col = texture(Diffuse, UV).rgb;
	col = desat(col, Desaturation);
	col = col * LightColor;
	ALBEDO = col;
	EMISSION = col * Brightness;
	METALLIC = Metallic;
	ROUGHNESS = Roughness;
}
