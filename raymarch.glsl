/* Signed distance functions */

float sdSphere(vec3 p, float r) {
    return length(p)-r;
}

float sdTorus(vec3 p, vec3 center, float minorRadius, float majorRadius) {
	return length(vec2(length(p.xz - center.xz) - minorRadius, p.y - center.y)) - majorRadius;
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

/* Raymarch */

float raymarch(in vec3 ro, in vec3 rd) {
    // Reference:
    // http://graphics.cs.williams.edu/courses/cs371/f14/reading/implicit.pdf
    const float dt = 0.01;
    const float tmax = 10.0;
    for (float t = 0.0; t < tmax; t += dt) {
        vec3 p = ro + rd * t;
        if (sdSphere(p, 0.5) < .1) {
            return t;
        } else if (sdTorus(p, vec3(0.0, -1.25, 0.0), .5, .15) < .1) {
            return t;
        }
    }
    return -1.0;
}

vec3 render(in vec3 ro, in vec3 rd) {
    float d = raymarch(ro, rd);
    if (d > 0.0) {
        vec3 p = ro + rd*d;
        return vec3(p);
    } else {
        return vec3(0.7, 0.7, 0.7);
    }
}

mat3 setCamera(in vec3 ro, in vec3 ta, float cr) {
    // Directly from iq's Raymarching Primitives:
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = normalize(cross(cu, cw));
    return mat3(cu, cv, cw);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Directly from iq's Raymarching Primitives:
    vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= iResolution.x / iResolution.y;
    vec2 mo = iMouse.xy / iResolution.xy;

    float time = 15.0 + iGlobalTime;

    // camera
    vec3 ro = vec3(
            -0.5 + 3.5 * cos(0.1 * time + 6.0 * mo.x),
            1.0 + 2.0 * mo.y,
            0.5 + 3.5 * sin(0.1 * time + 6.0 * mo.x));
    vec3 ta = vec3(-0.5, -0.4, 0.5);

    // camera-to-world transformation
    mat3 ca = setCamera(ro, ta, 0.0);

    // ray direction
    vec3 rd = ca * normalize(vec3(p.xy, 2.0));

    // render
    vec3 col = render(ro, rd);

    col = pow(col, vec3(0.4545));

    fragColor = vec4(col, 1.0);
}
