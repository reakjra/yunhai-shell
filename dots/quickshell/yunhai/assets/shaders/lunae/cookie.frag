#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float rot;
    float lobes;
    float scallop;
    float hasArt;
    vec2 size;
    vec4 color;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 p = (qt_TexCoord0 - 0.5) * size;
    float pr = length(p);
    float pa = atan(p.y, p.x);
    float R = min(size.x, size.y) * 0.5;
    float rEdge = R * (1.0 - scallop + scallop * cos(lobes * (pa + rot)));
    float a = clamp(0.5 - (pr - rEdge), 0.0, 1.0);
    vec4 base = hasArt > 0.5 ? texture(source, qt_TexCoord0) : color;
    fragColor = base * a * qt_Opacity;
}
