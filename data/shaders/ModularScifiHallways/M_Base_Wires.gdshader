shader_type spatial;

uniform sampler2D Diffuse;
uniform float Metallic = 0.5;
uniform float Roughness = 0.5;
uniform float Specular = 0.5;
uniform float Brightness = 1.0;
uniform vec3 WireColor : source_color = vec3(1.0, 1.0, 1.0);

void fragment() {
	vec3 tex_col = texture(Diffuse, UV).rgb;
	tex_col *= WireColor;
	tex_col = pow(tex_col, vec3(Brightness));
	ALBEDO = tex_col;
	
	METALLIC = Metallic;
	SPECULAR = Specular;
	ROUGHNESS = Roughness;
}
