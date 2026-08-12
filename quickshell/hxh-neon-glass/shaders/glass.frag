#version 440

// Glass pill for the neon-glass sidebar.
//
// This draws a translucent overlay — it deliberately does NOT sample or
// repaint the wallpaper. An earlier version did, loading snek-1.jpg as a
// texture and refracting it, and that was wrong twice over:
//
//   1. Qt's JPEG decode does not match what swaybg puts on screen. Measured at
//      (2,1100): source pixel 90,132,84 but actual screen 62,133,80. The pill
//      was painting its own subtly-wrong copy of the wallpaper, which left it
//      visibly lighter than its surroundings no matter how far the tint came
//      down — the mismatch was independent of the veil.
//   2. The refraction it enabled was a measured no-op anyway. This wallpaper
//      is a near-flat gradient behind the bar, and displacing a uniform colour
//      returns that uniform colour.
//
// Emitting alpha instead means the compositor composites the real wallpaper
// underneath, so the colour matches by construction, and Hyprland's layer blur
// rule handles frosting whenever the backdrop does have detail.
//
// What is left is light the glass adds by itself: a Fresnel rim, a Lambert lit
// edge, a faint shaded opposite edge, and frost grain. All of it reads on any
// backdrop, flat or busy.
//
// The rim runs as a gradient between two colours along the same 45 degree axis
// Hyprland uses for its active window border, so the pills and the window frames
// read as one system rather than two unrelated treatments. Against the near
// black neon wallpapers a white rim just looked grey.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4  qt_Matrix;      // 0
    float qt_Opacity;     // 64
    float radius;         // 68  corner radius, px
    float bevel;          // 72  width of the rounded edge, px
    float fresnel;        // 76  rim glow strength
    vec4  tint;           // 80  frost veil: rgb + density
    vec4  edge;           // 96  highlight hue (alpha unused, see below)
    vec2  pillSize;       // 112 px
    float spec;           // 120 lit-edge strength
    float grain;          // 124 frost micro-texture amount
    vec4  edge2;          // 128 far end of the rim gradient
};

// Cheap value hash, used for the frost grain.
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float sdRoundBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 p  = (uv - 0.5) * pillSize;
    vec2 b  = pillSize * 0.5;

    float d = sdRoundBox(p, b, radius);

    // Outward normal in 2D, from finite differences on the SDF. Stable in the
    // corners, unlike screen-space derivatives.
    const float e = 1.0;
    vec2 n2 = normalize(vec2(
        sdRoundBox(p + vec2(e, 0.0), b, radius) - sdRoundBox(p - vec2(e, 0.0), b, radius),
        sdRoundBox(p + vec2(0.0, e), b, radius) - sdRoundBox(p - vec2(0.0, e), b, radius)
    ) + vec2(1e-6));

    float din = -d;                                 // px inward from the rim
    float t   = clamp(1.0 - din / bevel, 0.0, 1.0); // broad bevel ramp

    // Crisp rim line, peaked ~1.2px *inside* the edge rather than at d = 0:
    // the antialiased mask is already down to 0.5 there, so a highlight centred
    // on the rim washes straight out.
    float band = exp(-pow((din - 1.2) / 1.1, 2.0));

    // Light direction in the plane of the screen. Blinn-Phong is the wrong
    // model here: with the viewer head-on the half-vector points mostly at +z,
    // so its specular peaks on the flat centre and vanishes at the rim — the
    // opposite of what a bevel does.
    const vec2 L2 = normalize(vec2(-0.5, -1.0));   // upper-left

    float lambert = dot(n2, L2);
    float soft    = pow(t, 3.0);

    // Rim colour, interpolated along the 45 degree diagonal. Matches the angle
    // of general.col.active_border in hyprland.lua. On a tall narrow pill this
    // is mostly a vertical sweep, which is what the window borders look like too.
    vec3 rim = mix(edge.rgb, edge2.rgb, clamp((uv.x + uv.y) * 0.5, 0.0, 1.0));

    // A real edge catches light all the way round, not just where the lamp is.
    float fres = (band * 0.60 + soft * 0.25) * fresnel;

    // The lit edge, facing the light.
    float lit = (band + soft * 0.40) * pow(max(lambert, 0.0), 1.5) * spec;

    // The opposite edge falls into shadow. Kept faint on purpose — a strong
    // asymmetry here is what reads as a chunky skeuomorphic bevel.
    float shade = pow(t, 2.0) * max(-lambert, 0.0) * 0.10;

    // Barely-there sheen across the face. Anything stronger turns the pill into
    // a glossy Aqua button.
    float sheen = (1.0 - uv.y) * 0.02;

    // Qt hands colours to shaders premultiplied, so tint.rgb arrives already
    // scaled by tint.a. Invisible for a black tint — black stays black — but it
    // would silently turn a white frost into grey. Undo it before use.
    vec3 tintRgb = tint.a > 0.001 ? tint.rgb / tint.a : tint.rgb;

    // Frost veil, with grain jittering its density. Real etched glass scatters
    // through micro-texture, and unlike blur, noise still reads on a perfectly
    // flat backdrop.
    float veil = clamp(tint.a + (hash(floor(gl_FragCoord.xy)) - 0.5) * grain, 0.0, 1.0);

    // Added light along the bevel. edge.a is deliberately unused: with colours
    // arriving premultiplied, edge.rgb * edge.a squares the alpha and quietly
    // halves the effect twice over. Strength comes from the float uniforms.
    float hi = fres + lit + sheen;

    // Premultiplied composite. `shade` contributes alpha with no colour, which
    // is exactly a black overlay — the darkening on the unlit edge.
    vec3  c = tintRgb * veil + rim * hi;
    float a = clamp(veil + hi + shade, 0.0, 1.0);

    c = min(c, vec3(a));   // keep the premultiplied invariant c <= a

    float mask = 1.0 - smoothstep(-0.75, 0.75, d);
    fragColor = vec4(c, a) * mask * qt_Opacity;
}
