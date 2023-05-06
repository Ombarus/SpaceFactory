shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

uniform float strength = 200.0;

uniform float outer_slope = -10.0;
uniform float inner_slope = 80.0;
uniform float intersection_dist = 0.2;
uniform float intersection_mult = 4.0;

uniform vec4 color_multiplier = vec4(1.0, 1.0, 1.0, 1.0);

// Nekoto
//vec2 rotateUV(vec2 uv, float rotation, vec2 mid)
//{
//    float cosAngle = cos(rotation);
//    float sinAngle = sin(rotation);
//    return vec2(
//        cosAngle * (uv.x - mid.x) + sinAngle * (uv.y - mid.y) + mid.x,
//        cosAngle * (uv.y - mid.y) - sinAngle * (uv.x - mid.x) + mid.y
//    );
//}
//
//void fragment() {
//	vec2 uv = UV;
//	vec2 sprite_pos_uv = uv * 0.5 + 0.5;
//	float rotation = length(sprite_pos_uv)*strength;
//	vec2 rotated_uv = rotateUV(SCREEN_UV, rotation, sprite_pos_uv);
//
//	vec4 final_color = textureLod(SCREEN_TEXTURE, rotated_uv, 0.0);
//	COLOR = final_color;
//	//COLOR = vec4(abs(center_tex_screen_uv.x), abs(center_tex_screen_uv.y), 0.0, 1.0);
//}



vec2 tex_center_in_screen_uv(vec2 tex_uv, vec2 screen_uv, vec2 texture_pixel_size, vec2 screen_pixel_size) {
	vec2 dist_tex = tex_uv - vec2(0.5, 0.5);
	vec2 dist_pixel = dist_tex / texture_pixel_size;
	vec2 dist_screen = dist_pixel * screen_pixel_size;
	// Not sure why I need this but it works !
	//dist_screen.y *= -1.0;
	return dist_screen;
}

void fragment() {
	vec2 uv = UV;
	vec2 screen_uv = SCREEN_UV;
	vec2 tex_size = TEXTURE_PIXEL_SIZE;
	vec2 screen_size = SCREEN_PIXEL_SIZE;
	vec2 center_tex_screen_uv = tex_center_in_screen_uv(uv, screen_uv, tex_size, screen_size);
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	//COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	//COLOR.rg = center_tex_screen_uv;
	
	vec2 rel = (uv - vec2(0.5, 0.5));
	float angle = length(rel)*strength;
	// not required but help for visualization to keep it within 0 and 2pi when debugging
	angle = fract(angle / (2.0*3.14159265)) * (2.0*3.14159265);
	
	mat2 rot = mat2(vec2(cos(angle),-sin(angle)),vec2(sin(angle),cos(angle)));
	//vec2 coord = screen_uv - center_tex_screen_uv;
    rel = vec2(center_tex_screen_uv.x * aspect, center_tex_screen_uv.y) * rot;
	
	
	
    vec2 final_uv = clamp(vec2((rel.x/aspect) + center_tex_screen_uv.x, rel.y + center_tex_screen_uv.y),vec2(0,0),vec2(1,1));
	
	vec4 final_color = textureLod(SCREEN_TEXTURE, final_uv, 0.0);
	COLOR = final_color;
	//COLOR = vec4(abs(center_tex_screen_uv.x), abs(center_tex_screen_uv.y), 0.0, 1.0);
}


// WORKS PERFECT SWIRL
/*
void fragment() {
	// Get the sprite's center in screen UVs
	vec2 uv = UV;
	vec2 screen_uv = SCREEN_UV;
	vec2 tex_size = TEXTURE_PIXEL_SIZE;
	vec2 screen_size = SCREEN_PIXEL_SIZE;
	vec2 center_tex_screen_uv = tex_center_in_screen_uv(uv, screen_uv, tex_size, screen_size);
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	
	// Calculate the spiral based on the distance from center
	vec2 rel = (uv - vec2(0.5, 0.5));
	float angle = length(rel)*strength;
	// not required but help for visualization to keep it within 0 and 2pi when debugging
	angle = fract(angle / (2.0*3.14159265)) * (2.0*3.14159265);
	
	// Rotation matrix
	mat2 rot = mat2(vec2(cos(angle),-sin(angle)),vec2(sin(angle),cos(angle)));
	vec2 coord = screen_uv - center_tex_screen_uv;
    rel = vec2(coord.x * aspect, coord.y) * rot;
    vec2 final_uv = clamp(vec2((rel.x/aspect) + center_tex_screen_uv.x, rel.y + center_tex_screen_uv.y),vec2(0,0),vec2(1,1));
	
	vec4 final_color = textureLod(SCREEN_TEXTURE, final_uv, 0.0);
	
	// Do the same thing with a custom texture for added "punch"
	float dist_center = length(uv - vec2(0.5, 0.5));
	
	vec2 tex_uv = UV;
	tex_uv = (tex_uv - vec2(0.5, 0.5)) * rot;
	tex_uv = clamp(tex_uv + vec2(0.5, 0.5), vec2(0,0), vec2(1,1));
	vec4 tex_color = textureLod(TEXTURE, tex_uv, 0.0) * 2.0;
	//final_color = mix(tex_color, final_color, dist_center*4.0);
	
	// black middle hole	
	float mult = 1.0;
	float b1 = intersection_mult - (outer_slope * intersection_dist);
	float b2 = intersection_mult - (inner_slope * intersection_dist);
	
	if (dist_center >= intersection_dist) {
		mult = outer_slope * dist_center + b1;
		mult = clamp(mult, 1.0, intersection_mult);
		final_color *= mult;
	}
	else {
		mult = inner_slope * dist_center + b2;
		mult = clamp(mult, 0.0, intersection_mult);
		final_color *= mult;
	}
	
	final_color *= color_multiplier;
	
	final_color.a = 1.0;
	
	// Blend at the corner
	vec4 normal_color = textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);
	float mixer = smoothstep(0.3, 0.5, dist_center);
	//float mixer = clamp(dist_center*2.0, 0.0, 1.0);
	final_color = mix(final_color, normal_color, mixer);
	
	COLOR.rgba = final_color;
}
*/


// WORKS PERFECT SWIRL
/*
void fragment() {
	vec2 uv = UV;
	vec2 screen_uv = SCREEN_UV;
	vec2 tex_size = TEXTURE_PIXEL_SIZE;
	vec2 screen_size = SCREEN_PIXEL_SIZE;
	//vec2 center_tex_screen_uv = vec2(0.5,0.5);
	vec2 center_tex_screen_uv = tex_center_in_screen_uv(uv, screen_uv, tex_size, screen_size);
	float aspect = SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	
	vec2 rel = (uv - vec2(0.5, 0.5));
	float angle = length(rel)*strength;
	// not required but help for visualization to keep it within 0 and 2pi when debugging
	angle = fract(angle / (2.0*3.14159265)) * (2.0*3.14159265);
	
	mat2 rot = mat2(vec2(cos(angle),-sin(angle)),vec2(sin(angle),cos(angle)));
	vec2 coord = screen_uv - center_tex_screen_uv;
    rel = vec2(coord.x * aspect, coord.y) * rot;
    vec2 final_uv = clamp(vec2((rel.x/aspect) + center_tex_screen_uv.x, rel.y + center_tex_screen_uv.y),vec2(0,0),vec2(1,1));
	
	vec4 final_color = textureLod(SCREEN_TEXTURE, final_uv, 0.0);
	float dist_center = length(uv - vec2(0.5, 0.5));
	if (dist_center < 0.1) {
		final_color = vec4(0.0, 0.0, 0.0, 1.0);
	}
	
	//COLOR.rgba = mix(vec4(r, 0.0, 0.0, 1.0), textureLod(SCREEN_TEXTURE, final_uv, 0.0), 0.5);
	//COLOR.rgba = vec4(r, 0.0, 0.0, 1.0);
	COLOR.rgba = final_color;
}
*/