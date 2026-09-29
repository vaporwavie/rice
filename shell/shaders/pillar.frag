#version 440
// Replays the landing's pillar: rows condense in Bayer-plus-grain order at the hero pace,
// land hot and cool to rest, then the baked ivy surfaces pixel by pixel as the plant ages.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float t;
    float age;
    float rest;
    float rows;
    float reach;
    float steps;
    vec4 ink;
};
layout(binding = 1) uniform sampler2D source;

const float W = 132.0;
const float DELAY = 0.15;
const float STAGGER = 0.12;
const float DURATION = 1.0;
const float HOT = 0.62;
const float SPARK = 0.07;
const float TICK = 14.0;
const float GRAIN = 0.4;
const float COOL = 1.4;
const float TIME_UNIT = 32.0;
const float IVY[6] = float[6](0.0, 1.6, 0.0, 1.4, 2.0, 2.7);

float curve(float a, float b, float s) {
    float u = 1.0 - s;
    return 3.0 * u * u * s * a + 3.0 * u * s * s * b + s * s * s;
}

// cubic-bezier(0.16, 1, 0.3, 1), the hero easing.
float ease(float x) {
    float lo = 0.0;
    float hi = 1.0;
    for (int i = 0; i < 16; i++) {
        float mid = 0.5 * (lo + hi);
        if (curve(0.16, 0.3, mid) < x) lo = mid; else hi = mid;
    }
    return curve(1.0, 1.0, 0.5 * (lo + hi));
}

float hash(int x, int y, int s) {
    uint h = (uint(x + 1) * 374761393u) ^ (uint(y + 1) * 668265263u) ^ (uint(s + 1) * 2246822519u);
    h = (h ^ (h >> 13)) * 1274126177u;
    return float(h ^ (h >> 16)) / 4294967296.0;
}

float quad(int x, int y) { return float(2 * (x ^ y) + y); }

float bayer(int x, int y) {
    float v = 16.0 * quad(x & 1, y & 1) + 4.0 * quad((x >> 1) & 1, (y >> 1) & 1) + quad((x >> 2) & 1, (y >> 2) & 1);
    return (v + 0.5) / 64.0;
}

int byte(float v) { return int(v * 255.0 + 0.5); }

void main() {
    ivec2 p = ivec2(floor(qt_TexCoord0 * vec2(W, rows)));
    vec4 t0 = texelFetch(source, ivec2(p.x * 3, p.y), 0);
    vec4 t1 = texelFetch(source, ivec2(p.x * 3 + 1, p.y), 0);
    vec4 t2 = texelFetch(source, ivec2(p.x * 3 + 2, p.y), 0);
    int kinds = byte(t0.r);
    int flags = byte(t0.g);
    float bornA = float(byte(t1.r) * 256 + byte(t1.g)) / TIME_UNIT;
    float bornB = float(byte(t2.r) * 256 + byte(t2.g)) / TIME_UNIT;
    int kA = kinds & 7;
    int kB = kinds >> 3;

    float onset = DELAY + STAGGER * (1.0 + (steps - 1.0) * (1.0 - exp(-float(p.y) / reach)));
    float a = 0.0;
    if (t >= onset) {
        bool settled = t - onset >= DURATION;
        float d = settled ? 1.0 : ease((t - onset) / DURATION);
        int k = 0;
        float born = 0.0;
        if (kA > 0 && bornA <= age) { k = kA; born = bornA; }
        if (kB > 0 && bornB <= age) { k = kB; born = bornB; }
        float base = k > 0 ? rest * IVY[k] : ((flags & 1) != 0 ? rest : 0.0);
        if (base > 0.0) {
            float th = (1.0 - GRAIN) * bayer(p.x, p.y) + GRAIN * hash(p.x, p.y, 0);
            if (th <= d) {
                float heat = settled ? 0.0 : (1.0 - d) / (1.0 - th);
                if (k > 0) {
                    float fresh = max(0.0, 1.0 - (age - born) / COOL);
                    heat = max(heat, fresh * fresh);
                }
                a = base + (HOT - base) * heat;
            }
        } else if (k == 0 && (flags & 2) != 0 && !settled) {
            if (hash(p.x, p.y, int(floor(t * TICK))) < SPARK * sin(3.14159265 * d)) a = HOT * 0.5;
        }
    }
    fragColor = vec4(ink.rgb * a, a) * qt_Opacity;
}
