#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 size;
    vec2 origin;
    float progress;
    float feather;
    float maxRadius;
    int style;
};

layout(binding = 1) uniform sampler2D fromSource;
layout(binding = 2) uniform sampler2D toSource;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float valueNoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float circleMask() {
    float d = distance(qt_TexCoord0 * size, origin);
    float r = progress * (maxRadius + feather);
    return 1.0 - smoothstep(r - feather, r, d);
}

float wipeMask() {
    float band = max(feather / size.x, 0.001);
    float pos = origin.x < size.x * 0.5 ? qt_TexCoord0.x : 1.0 - qt_TexCoord0.x;
    return clamp((progress * (1.0 + band) - pos) / band, 0.0, 1.0);
}

float dissolveMask() {
    float band = 0.3;
    float n = valueNoise(qt_TexCoord0 * vec2(6.0 * size.x / size.y, 6.0));
    return clamp((progress * (1.0 + band) - n) / band, 0.0, 1.0);
}

void main() {
    float reveal = progress;
    if (style == 1)
        reveal = circleMask();
    else if (style == 2)
        reveal = wipeMask();
    else if (style == 3)
        reveal = dissolveMask();

    vec4 col = mix(texture(fromSource, qt_TexCoord0), texture(toSource, qt_TexCoord0), clamp(reveal, 0.0, 1.0));
    fragColor = col * qt_Opacity;
}
