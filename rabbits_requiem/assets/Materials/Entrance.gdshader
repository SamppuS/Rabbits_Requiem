shader_type spatial;

uniform sampler2D albedo_texture;
uniform sampler2D alpha_texture;

void fragment() {
    vec4 albedo = texture(albedo_texture, UV);
    float alpha = texture(alpha_texture, UV).r; // Use red channel for alpha
    ALBEDO = albedo.rgb;
    ALPHA = alpha;
}