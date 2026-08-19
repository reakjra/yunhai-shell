#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float k;
    float chromeMode;
    float frameThickness;
    float frameRadius;
    float shadowSoftness;
    vec2 size;
    vec4 fillColor;
    vec4 shadowColor;
    vec4 s0g; vec4 s0r;
    vec4 s1g; vec4 s1r;
    vec4 s2g; vec4 s2r;
    vec4 s3g; vec4 s3r;
    vec4 s4g; vec4 s4r;
    vec4 s5g; vec4 s5r;
    vec4 s6g; vec4 s6r;
    vec4 s7g; vec4 s7r;
    vec4 d01; vec4 d23;
    vec4 d45; vec4 d67;
};

float sdRoundedBox(vec2 p, vec2 c, vec2 b, float r) {
    vec2 q = abs(p - c) - b + vec2(r);
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

float sdRoundedBox4(vec2 p, vec2 c, vec2 b, vec4 rr) {
    vec2 q = p - c;
    vec2 rs = q.x > 0.0 ? rr.xy : rr.wz;
    float rad = q.y > 0.0 ? rs.y : rs.x;
    vec2 qq = abs(q) - b + vec2(rad);
    return length(max(qq, vec2(0.0))) + min(max(qq.x, qq.y), 0.0) - rad;
}

float smin(float a, float b, float kk) {
    return max(kk, min(a, b)) - length(max(vec2(kk) - vec2(a, b), vec2(0.0)));
}

void main() {
    vec2 p = qt_TexCoord0 * size;

    vec4 g[8];
    vec4 r[8];
    g[0] = s0g; r[0] = s0r;
    g[1] = s1g; r[1] = s1r;
    g[2] = s2g; r[2] = s2r;
    g[3] = s3g; r[3] = s3r;
    g[4] = s4g; r[4] = s4r;
    g[5] = s5g; r[5] = s5r;
    g[6] = s6g; r[6] = s6r;
    g[7] = s7g; r[7] = s7r;

    vec2 dv[8];
    dv[0] = d01.xy; dv[1] = d01.zw;
    dv[2] = d23.xy; dv[3] = d23.zw;
    dv[4] = d45.xy; dv[5] = d45.zw;
    dv[6] = d67.xy; dv[7] = d67.zw;

    float d = 1e6;
    for (int i = 0; i < 8; i++) {
        if (g[i].w < 0.5)
            continue;
        vec2 ps = g[i].xy + (p - g[i].xy) / dv[i];
        d = smin(d, sdRoundedBox4(ps, g[i].xy, g[i].zw, r[i]), k);
    }

    float dChrome;
    if (chromeMode > 0.5) {
        vec2 c = size * 0.5;
        dChrome = -sdRoundedBox(p, c, c - vec2(frameThickness), frameRadius);

        float preOff = k * (2.0 - sqrt(2.0)) * 0.5;
        float innerT = frameThickness;
        float innerB = size.y - frameThickness;
        float innerL = frameThickness;
        float innerR = size.x - frameThickness;
        float s = k * 2.0;
        float sinkValue = 0.0;
        for (int i = 0; i < 8; i++) {
            if (g[i].w < 0.5)
                continue;
            vec2 ctr = g[i].xy;
            vec2 sh = g[i].zw;
            float topPen = clamp(innerT - (ctr.y + sh.y) - preOff, 0.0, frameThickness);
            float botPen = clamp((ctr.y - sh.y) - innerB - preOff, 0.0, frameThickness);
            float leftPen = clamp(innerL - (ctr.x + sh.x) - preOff, 0.0, frameThickness);
            float rightPen = clamp((ctr.x - sh.x) - innerR - preOff, 0.0, frameThickness);
            float hLat = max(abs(p.x - ctr.x) - sh.x, 0.0);
            float vLat = max(abs(p.y - ctr.y) - sh.y, 0.0);
            float topZone = 1.0 - smoothstep(innerT, innerT + k, p.y);
            float botZone = smoothstep(innerB - k, innerB, p.y);
            float leftZone = 1.0 - smoothstep(innerL, innerL + k, p.x);
            float rightZone = smoothstep(innerR - k, innerR, p.x);
            float sink = max(
                max(topPen * smoothstep(s, 0.0, hLat) * topZone,
                    botPen * smoothstep(s, 0.0, hLat) * botZone),
                max(leftPen * smoothstep(s, 0.0, vLat) * leftZone,
                    rightPen * smoothstep(s, 0.0, vLat) * rightZone));
            sinkValue = max(sinkValue, sink);
        }
        dChrome += sinkValue;
    } else {
        dChrome = min(min(p.x, p.y), min(size.x - p.x, size.y - p.y)) + 1.0;
    }
    d = smin(d, dChrome, k);

    float cov = clamp(0.5 - d, 0.0, 1.0);
    float dp = max(d, 0.0);
    float sh = 0.5 * exp(-(dp * dp) / (2.0 * shadowSoftness * shadowSoftness)) * (1.0 - cov);
    fragColor = (fillColor * cov + shadowColor * sh) * qt_Opacity;
}
