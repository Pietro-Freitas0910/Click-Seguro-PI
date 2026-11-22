shader_type canvas_item;
// Efeito de "tela de monitor": linhas finas, reflexo de vidro e bordas mais escuras.
// Fica só dentro da área da tela do computador desenhado no fundo.

uniform float line_spacing = 3.0;
uniform float line_alpha : hint_range(0.0, 1.0) = 0.10;
uniform float glare_strength : hint_range(0.0, 1.0) = 0.07;
uniform float edge_shadow : hint_range(0.0, 1.0) = 0.45;
uniform float sweep_speed = 0.08;

void fragment() {
	float scan = step(mod(FRAGCOORD.y, line_spacing), 1.0) * line_alpha;

	// Reflexo diagonal suave no canto de cima.
	float glare = smoothstep(0.55, 0.0, UV.x * 0.6 + UV.y) * glare_strength;

	// Faixa de luz descendo devagar.
	float sweep = smoothstep(0.01, 0.0, abs(UV.y - fract(TIME * sweep_speed))) * 0.05;

	// Bordas internas mais escuras, como a curvatura de um monitor.
	vec2 d = abs(UV - 0.5) * 2.0;
	float edge = pow(max(d.x, d.y), 6.0) * edge_shadow;

	float light = glare + sweep;
	float dark = clamp(scan + edge, 0.0, 1.0);
	float alpha = clamp(light + dark, 0.0, 1.0);
	vec3 rgb = vec3(0.75, 0.9, 1.0) * (light / max(alpha, 0.0001));
	COLOR = vec4(rgb, alpha);
}
