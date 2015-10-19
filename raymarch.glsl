/*************************** Signed distance functions ***********************
 * McGuire: http://graphics.cs.williams.edu/courses/cs371/f14/reading/implicit.pdf
 * iq: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
 */

float sdSphere(vec3 p, vec3 center, float r) {
    return length(p - center) - r;
}

float sdTorus(vec3 p, vec3 center, float minorRadius, float majorRadius) {
    return length(vec2(length(p.xz - center.xz) - minorRadius, p.y - center.y)) - majorRadius;
}

float sdPlane(vec3 p, vec3 center, vec3 n) {
    return dot(p - center, n);
}

float sdBox(vec3 p, vec3 center, vec3 b) {
    vec3 d = abs(p - center) - b;
    float dmax = max(max(d.x, d.y), d.z);
    return min(dmax, 0.0) + length(max(d, vec3(0, 0, 0)));
}

float sdRoundedBox(vec3 p, vec3 center, vec3 b, float r) {
    return length(max(abs(p - center) - b, vec3(0, 0, 0))) - r;
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a, ba = b - a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

/********************************** Raymarch **********************************
 * McGuire: http://graphics.cs.williams.edu/courses/cs371/f14/reading/implicit.pdf
 */


bool intersection(in vec3 p) {
    if (sdSphere(p, vec3(0.0), 0.5) < .1) {
        return true;
    } else if (sdTorus(p, vec3(0.0, -1.25, 0.0), .5, .15) < .1) {
        return true;
    } else if (sdCapsule(p, vec3(1.0), vec3(.5), 0.2) < .1) {
       return true;
    } else {
        return false;
    }
}

float raymarch(in vec3 ro, in vec3 rd) {
    // Reference:
    const float dt = 0.01;
    const float tmax = 10.0;
    for (float t = 0.0; t < tmax; t += dt) {
        vec3 p = ro + rd * t;
        if (intersection(p)) {
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

/************************************ Setup ***********************************
  * Directly from iq's Raymarching Primitives
  * https://www.shadertoy.com/view/Xds3zN
  */
mat3 setCamera(in vec3 ro, in vec3 ta, float cr) {
    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = normalize(cross(cu, cw));
    return mat3(cu, cv, cw);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
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
