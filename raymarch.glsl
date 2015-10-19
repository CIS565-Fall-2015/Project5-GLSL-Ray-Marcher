/********************************** Constants *********************************/
const vec3 light = vec3(2.0, 5.0, -1.0);
const vec3 color = vec3(0.85, 0.85, 0.85);
const vec3 ambient = vec3(0.05, 0.05, 0.05);
const vec3 background = vec3(0.2, 0.5, 0.5);
const vec3 ground = vec3(0.2, 0.8, 0.8);

const vec3 scene2cam = vec3(.35, 2.5, -2);
//const vec3 scene2cam = vec3(2.5, 2.2, -.8);
const float EPSILON = 0.01;
const float TMIN = 0.01;

// Debug flags
#define OVERRELAX   0
#define SPHERETRACE 1
#define NAIVE       0

#define DISTANCE 0
#define NORMAL   0
#define ITERS    0

#define SHADOW   0

#define FIXEDCAM 1

#define SCENE1 0
#define SCENE2 1

/*************************** Signed distance functions ***********************
 * McGuire: http://graphics.cs.williams.edu/courses/cs371/f14/reading/implicit.pdf
 * iq: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
 */

float sdSphere(vec3 p, float r) {
    return length(p) - r;
}

float sdTorus(vec3 p, float minorRadius, float majorRadius) {
    return length(vec2(length(p.xz) - minorRadius, p.y)) - majorRadius;
}

float sdPlane(vec3 p, vec3 n) {
    return dot(p, n);
}

float sdBox(vec3 p, vec3 b) {
    vec3 d = abs(p) - b;
    float dmax = max(max(d.x, d.y), d.z);
    return min(dmax, 0.0) + length(max(d, vec3(0, 0, 0)));
}

float sdRoundedBox(vec3 p, vec3 b, float r) {
    return length(max(abs(p) - b, vec3(0, 0, 0))) - r;
}

float sdCapsule(vec3 p, vec3 a, vec3 b, float r) {
    vec3 pa = p - a;
    vec3 ba = b - a;
    float h = clamp(dot(pa,ba)/dot(ba,ba), 0.0, 1.0);
    return length(pa - ba*h) - r;
}

float sdCylinder(vec3 p, float r, float e) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, e);
    float dmax = max(d.x, d.y);
    return min(dmax, 0.0) + length(max(d, vec2(0, 0)));
}

float sdTriPrism(vec3 p, vec2 h) {
    vec3 q = abs(p);
    return  max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
}

float length8(vec2 p) {
    p = p*p; p = p*p; p = p*p;
    return pow(p.x + p.y, 1.0/8.0);
}

float sdTorus88(vec3 p, vec2 t) {
    vec2 q = vec2(length8(p.xz)-t.x,p.y);
    return length8(q)-t.y;
}

/***************************** Geometry Combinators ***************************
 * McGuire 11: http://graphics.cs.williams.edu/courses/cs371/f14/reading/implicit.pdf
 */

// set union of two geometry
float setunion(float d1, float d2) {
    return min(d1, d2);
}

// intersection of two geometry
float intersect(float d1, float d2) {
    return max(d1, d2);
}

// set subtraction of d2 from d1
float subtract(float d1, float d2) {
    return max(d1, -d2);
}

// transformation OF P by applying the inverse transform
vec3 tr(vec3 p, vec3 translate) {
    return p - translate;
}

/********************************** Raymarch **********************************
 * McGuire: http://graphics.cs.williams.edu/courses/cs371/f14/reading/implicit.pdf
 */

float nearestIntersection(in vec3 p) {
#if SCENE1
    float t = sdSphere(p, 0.5);
    //t = setunion(t, sdPlane     (tr(p, vec3(-2.0)), vec3(.0, 1.0, .0))             );
    t = setunion(t, sdTorus     (tr(p, vec3(-1.3,.8,-1.3)), .4, .15)               );
    t = setunion(t, sdTorus88   (tr(p, vec3(.0,.0,-1.5)), vec2(.35,.2))            );
    t = setunion(t, sdCapsule   (tr(p, vec3(.6, .0, .6)), vec3(1.0), vec3(.5), .2) );
    t = setunion(t, sdRoundedBox(tr(p, vec3(-1.0, 1.0, .0)), vec3(.2), .1)         );
    t = setunion(t, sdCylinder  (tr(p, vec3(1.2,.0,.0)), .5, .2)                   );
    t = setunion(t, sdTriPrism  (tr(p, vec3(.0,.0,1.5)), vec2(.4, .4))             );
#endif
#if SCENE2
    float t = sdCylinder(tr(p, vec3(-.1, .25, 0)), 1.5, .25);
    //t = setunion(t, sdPlane     (tr(p, vec3(-2.0)), vec3(.0, 1.0, .0))   );
    t = subtract(t, sdTriPrism  (tr(p, vec3(-.1,1,0)), vec2(1., 1.))     );

    t = setunion(t, sdSphere    (tr(p, vec3(1,1,0)), .2)                 );
    t = setunion(t, sdTorus     (tr(p, vec3(.4, 1,0)), .15, .1)          );
    t = setunion(t, sdTorus88   (tr(p, vec3(-.2,  1,0)), vec2(.16, .06)) );
    t = setunion(t, sdRoundedBox(tr(p, vec3(-.75,1,0)), vec3(.08), .06)  );
    t = setunion(t, sdBox       (tr(p, vec3(-1.15, 1,0)), vec3(.12))     );
#endif
    return t;
}

// Naive iteration
vec2 raymarch_naive(in vec3 ro, in vec3 rd) {
    const float tmax = 30.0;
    const float tstep = 0.01;
    int iters = 0;
    for (float t = 0.1; t < tmax; t += tstep) {
        iters++;
        vec3 p = ro + rd * t;
        float intersection = nearestIntersection(p);
        if (intersection > 0.0 && intersection < TMIN) {
            return vec2(t, iters);
        }
    }
    return vec2(-1.0);
}

// Sphere tracing
vec2 raymarch_sphere(in vec3 ro, in vec3 rd) {
    const float tmax = 30.0;
    float t = 0.0;
    for (int i = 0; i < 100; i++) {
        vec3 p = ro + rd * t;
        float intersection = nearestIntersection(p);
        if (intersection > 0.0 && intersection < TMIN) {
            return vec2(t, i);
        } else if (intersection > 0.0) {
            t += intersection;
        }
        if (t > tmax) {
            break;
        }
    }
    return vec2(-1.0);
}

// Overrelaxation tracing
// http://erleuchtet.org/~cupe/permanent/enhanced_sphere_tracing.pdf
vec2 raymarch_overrelax(in vec3 ro, in vec3 rd) {
    int iters = 0;
    const float tmax = 30.0;
    float t = 0.1;
    float dt = 0.0;
    float extrastep = 0.0;
    float K = 1.0;

    for (int i = 0; i < 50; i++) {
        iters++;
        vec3 p = ro + rd * t;
        float intersection = nearestIntersection(p);
        if (intersection > 0.0 && intersection < TMIN) {
            // Successful intersection
            return vec2(t, iters);
        } else if (intersection > 0.0) {
            // Valid intersection
            // Take K * intersection distance step forward
            // Unless that is too large; then step backwards
            float nstep = K * intersection;
            if (intersection < dt) {
                t -= (dt + extrastep);
                break;
            } else {
                dt = intersection;
                extrastep = (K-1.) * intersection;
                t += nstep;
            }
        } else {
            // Negative distance
            t -= (K * dt);
            break;
        }
    }

    for (int i = 0; i < 50; i++) {
        //iters++;
        vec3 p = ro + rd * t;
        float intersection = nearestIntersection(p);
        if (intersection > 0.0 && intersection < TMIN) {
            return vec2(t, iters);
        } else if (intersection > 0.0) {
            t += intersection;
        }
        if (t > tmax) {
            return vec2(-1,-1);
        }
    }
    return vec2(-1,-1);
}

vec2 raymarch(in vec3 ro, in vec3 rd) {
    #if OVERRELAX
   	    return raymarch_overrelax(ro, rd);
    #endif
    #if SPHERETRACE
        return raymarch_sphere(ro, rd);
    #endif
    #if NAIVE
        return raymarch_naive(ro, rd);
    #endif
}

vec3 normalAt(in vec3 p) {
    vec2 epsilon = vec2(0.0001, 0.0);
    float d = nearestIntersection(p);
    float dx = nearestIntersection(p + epsilon.xyy);
    float dy = nearestIntersection(p + epsilon.yxy);
    float dz = nearestIntersection(p + epsilon.yyx);
    vec3 v = vec3(d) - vec3(dx, dy, dz);
    return normalize(v / epsilon.xxx);
}

vec3 lambert(in vec3 p, in vec3 n, in vec3 c) {
    vec3 lightdir = normalize(p - light);
    return dot(n, lightdir) * c;
}

// http://www.iquilezles.org/www/articles/rmshadows/rmshadows.htm
float shadowMarch(in vec3 ro, in vec3 rd) {
    const float tmax = 10.0;
    const float k = 8.0;

    float shadow = 1.0;
    float t = 0.0;

    for (int i = 0; i < 100; i++) {
        vec3 p = ro + rd * t;
        float intersection = nearestIntersection(p);
        if (intersection > 0.0 && intersection < TMIN) {
            return 0.0;
        } else if (intersection > 0.0) {
            t += intersection;
            shadow = min(shadow, k*intersection/t);
        }
        if (t > tmax) {
            break;
        }
    }
    return shadow;
}

vec3 shadow(in vec3 p, in vec3 color) {
    vec3 lightdir = normalize(light - p);
    float lightdist = distance(p, light);

    float shadow = shadowMarch(p, lightdir);
    return clamp(shadow * color, 0.0, 1.0) + ambient;
}

// http://www.iquilezles.org/www/articles/terrainmarching/terrainmarching.htm
float heightf(vec2 xz) {
    return -2.0 - (sin(xz.y*2.0)/5.0) - (sin(xz.x)/4.0);
}

float heightff(float x, float z) {
    return heightf(vec2(x, z));
}

vec3 heightn(vec3 p) {
    float eps = 0.001;
    vec3 n = vec3(heightff(p.x-eps,p.z) - heightff(p.x+eps,p.z),
                         2.0*eps,
                         heightff(p.x,p.z-eps) - heightff(p.x,p.z+eps) );
    return normalize(n);
}

vec2 heightmarch(in vec3 ro, in vec3 rd) {
    const float tmax = 30.0;
    const float tstep = 0.01;
    int iters = 0;
    for (float t = 0.1; t < tmax; t += tstep) {
        iters++;
        vec3 rayp = ro + rd * t;
        float height = heightf(rayp.xz);
        
        if (rayp.y < height) {
            return vec2(t, iters);
        }
    }
    return vec2(-1);
}

vec3 render(in vec3 ro, in vec3 rd) {
    vec2 ray = raymarch(ro, rd);
    float d = ray.x;
    vec3 p = ro + rd*d;
    
    vec3 basecolor = color;    
    
    if (d < 0.0) {
        ray = heightmarch(ro, rd);
        d = ray.x;
        if (ray.y < 0.0) {
            return background;
        }
        
        vec3 rayp = ro + rd * d;
        float y = heightf(p.xz);
        p = vec3(rayp.x, y, rayp.z);
        basecolor = background;
        vec3 n = heightn(p);
        vec3 c = lambert(p, n, ground);
        #if SHADOW
            c = shadow(p, c);
            c = clamp(c, 0.0, 1.0);
        #endif
        return c;
    }
    
    float iters = ray.y;
    
    #if ITERS
    return vec3(iters/20.);
        #endif

    #if DISTANCE
        return p;
    #endif

    vec3 n = normalAt(p);

    #if NORMAL
        return n;
    #endif

    #if SCENE2
    if (p.y > -1.9 && p.y < .6) {
        basecolor = color;
    } else if (p.y > -1.9) {
        vec3 absp = abs(p);
        basecolor = absp;
    }
    #endif

    vec3 c = lambert(p, n, basecolor);

    #if SHADOW
        c = shadow(p - 3.0*rd*EPSILON, c);
        c = clamp(c, 0.0, 1.0);
    #endif

    return c;
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
    #if FIXEDCAM
        #if SCENE1
            ro = vec3(2.2, 3.5, -2);
        #endif
        #if SCENE2
            ro = scene2cam;
        #endif
    #endif

    vec3 ta = vec3(-0.5, -0.4, 0.5);
    ta = vec3(0);

    // camera-to-world transformation
    mat3 ca = setCamera(ro, ta, 0.0);

    // ray direction
    vec3 rd = ca * normalize(vec3(p.xy, 2.0));

    // render
    vec3 col = render(ro, rd);

    col = pow(col, vec3(0.4545));

    fragColor = vec4(col, 1.0);
}
