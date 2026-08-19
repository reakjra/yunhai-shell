#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float radius;
    float thickness;
    float sweep;
    float progress;
    float waveAmp;
    float waveFreq;
    float phase;
    vec2 size;
    vec4 fgColor;
    vec4 trackColor;
};

vec2 pointAt(float a, float r) {
    return vec2(r * sin(a), -r * cos(a));
}

float segDist(vec2 p, float a0, float a1, float amp) {
    float a = clamp(atan(p.x, -p.y), a0, a1);
    float t = (a + sweep * 0.5) / sweep;
    float r = radius + amp * sin(waveFreq * t * 6.2831853 + phase);
    return length(p - pointAt(a, r)) - thickness * 0.5;
}

void main() {
    vec2 p = (qt_TexCoord0 - 0.5) * size;
    float half_ = sweep * 0.5;
    float tip = -half_ + progress * sweep;
    float gap = thickness * 1.6 / max(radius, 1.0);

    float cFg = clamp(0.5 - segDist(p, -half_, tip, waveAmp), 0.0, 1.0);
    float cTr = clamp(0.5 - segDist(p, min(tip + gap, half_), half_, 0.0), 0.0, 1.0) * (1.0 - cFg);
    fragColor = (fgColor * cFg + trackColor * cTr) * qt_Opacity;
}
