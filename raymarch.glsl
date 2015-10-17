#define QUARTER_PI 0.7853981634
#define NAIVE_MARCHING 0
#define RENDER_NORMAL 0
#define RENDER_DISTANCE 0
#define RENDER_ITER 0

float dSphere(vec3 X, vec3 C, float r){
    return length(X-C)-r;
}

float dPlane(vec3 X, vec3 C, vec3 n){
    return dot(X-C, n);
}

float dBox(vec3 X, vec3 C, vec3 b){
    vec3 d = abs(X-C)-b;
    float maxComp = max(max(d.x, d.y), d.z);
    return min(maxComp, 0.0)+length(max(d, vec3(0.0)));
}

vec2 oUnion(vec2 r1, vec2 r2){
    return r1.x < r2.x ? r1 : r2;
}

mat3 transpose(mat3 mx){
    mat3 t_mx = mat3(
        mx[0].x, mx[1].x, mx[2].x,
        mx[0].y, mx[1].y, mx[2].y,
        mx[0].z, mx[1].z, mx[2].z
    );
    return t_mx;
}

mat4 inverseTransform(vec3 translate, vec3 scale, mat3 rotate){
    mat4 inv_tranH = mat4(1.0);
    inv_tranH[3] = vec4(-translate, 1.0);
    
    mat3 inv_rot = transpose(rotate);
    mat4 inv_rotH = mat4(1.0);
    inv_rotH[0] = vec4(inv_rot[0], 0.0);
    inv_rotH[1] = vec4(inv_rot[1], 0.0);
    inv_rotH[2] = vec4(inv_rot[2], 0.0);
    
    mat4 inv_scalH = mat4(1.0);
    inv_scalH[0].x = 1.0/scale.x;
    inv_scalH[1].y = 1.0/scale.y;
    inv_scalH[2].z = 1.0/scale.z;
    
    return inv_scalH*inv_rotH*inv_tranH;
}

// Distance estimator wrapper
vec2 g(float t, in vec3 ro, in vec3 rd){
    // Union
    float sphereDist = dSphere(ro+rd*t, vec3(0.0, 0.25, 0.0), 0.25);
    float planeDist = dPlane(ro+rd*t, vec3(0.0, 0.0, 0.0), vec3(0.0, 1.0, 0.0));
    
    vec2 res = oUnion(vec2(sphereDist, 1.0), vec2(planeDist, 2.0));
    
    float boxDist = dBox(ro+rd*t, vec3(-1.0, 0.2, 0.0), vec3(0.1, 0.1, 0.1));
    
    res = oUnion(vec2(boxDist, 3.0), res);
    
    vec3 scale = vec3(1.0, 2.0, 1.0);
    vec3 translate = vec3(1.0,0.3,0.0);
    mat3 rotate = mat3(cos(QUARTER_PI), 0, -sin(QUARTER_PI), 0, 1, 0, sin(QUARTER_PI), 0, cos(QUARTER_PI));
    
    mat4 M = inverseTransform(translate, scale, rotate);
    vec4 tX = M*vec4((ro+rd*t), 1.0);
    vec3 X = vec3(tX.x/tX.w, tX.y/tX.w, tX.z/tX.w);
    
    float boxDist2 = dBox(X, vec3(0.0, 0.0, 0.0), vec3(0.1, 0.1, 0.1));
    
    res = oUnion(vec2(boxDist2, 3.0), res);
    
    return res;
}

vec3 findNormal(float t, vec3 ro, vec3 rd){
    vec3 eps = vec3(0.0001, 0.0, 0.0);
    vec3 norm = vec3(
        g(t, ro+eps.xyy, rd).x-g(t, ro-eps.xyy, rd).x,
        g(t, ro+eps.yxy, rd).x-g(t, ro-eps.yxy, rd).x,
        g(t, ro+eps.yyx, rd).x-g(t, ro-eps.yyx, rd).x
    );
    return normalize(norm);
}

mat3 naiveMarch(in vec3 ro, in vec3 rd){
    float maxDist = 21.0;
    float dt = 0.01;
    float t = 1.0;
    float m = -1.0;
    float eps = 0.000001;
    for (int i = 0; i < 2000; i++){
        vec2 res = g(t, ro, rd);
        if (res.x < eps){
            return mat3(res, i, findNormal(t, ro, rd), t, vec2(0.0));
        }
        t+= dt;
    }
    return mat3(t, m, 199, vec3(0.0), vec3(0.0));
}

mat3 sphereMarch(in vec3 ro, in vec3 rd){
    float t = 1.0;
    float m = -1.0;
    float eps = 0.000001;
    for (int i = 0; i < 2000; i++){
        vec2 res = g(t, ro, rd);
        if (res.x < eps){
            return mat3(res, i, findNormal(t, ro, rd), t, vec2(0.0));
        }
        t+= res.x;
    }
    return mat3(t, m, 199, vec3(0.0), vec3(0.0));
}

float softShadow(vec3 ro, vec3 rd){
    float t = 0.1;
    float eps = 0.00001;
    vec2 res;
    float distAway = 1.0;
    float scatterConstraint = 6.0;
    for (int i = 0; i < 22; i++){
        res = g(t, ro, rd);
        distAway = min(distAway, scatterConstraint*res.x/(res.x+t));
        if (res.x < eps) break;
        t+= clamp(res.x, 0.01, 0.05);
    }
    return 0.2+clamp(distAway, 0.0, 0.8);
}

vec3 shade(mat3 res, vec3 ro, vec3 rd){
    vec3 lightPos = vec3(6.0,6.0,6.0);
#if NAIVE_MARCHING
    vec3 lightCol = vec3(1.0, 0.72, 0.482);
#else
    vec3 lightCol = vec3(0.91, 0.91, 1.0);
#endif
#if RENDER_NORMAL
    return res[1];
#elif RENDER_DISTANCE
    return vec3(res[2].x/21.0);
#elif RENDER_ITER
    return vec3(res[0].z/199.0);
#else
    // Color render
    vec3 m;
    if (res[0].y == 1.0){
        m = vec3(0.8,0.8,0.8);
    }
    if (res[0].y == 2.0){
        m = vec3(1.0) - vec3(0.3)*mod(floor(length(ro+rd*res[2].x)), 3.0);
    }
    if (res[0].y == 3.0){
        m = vec3(1.0,1.0,0.0);
    }
    // Lambert
    vec3 L = normalize(lightPos - (ro+rd*res[2].x));
    vec3 diffuse = dot(L, res[1])*lightCol*m;
    
    // Soft shadow
    float shadow = softShadow(ro+rd*res[2].x, L);
    
    return diffuse*shadow;
#endif
}

vec3 render(in vec3 ro, in vec3 rd) {
    // Sky
    vec3 col = vec3(0.8,0.8,1.0)*(rd.y+1.0);
    
    // Ray marching
    vec3 lightCol;
#if NAIVE_MARCHING
    mat3 res = naiveMarch(ro, rd);
#else
    mat3 res = sphereMarch(ro, rd);
#endif
    
    if (res[0].y > 0.0) col = shade(res, ro, rd);
    
    return clamp(col, 0.0, 1.0);
}

mat3 setCamera(in vec3 ro, in vec3 ta, float cr) {
    // Starter code from iq's Raymarching Primitives
    // https://www.shadertoy.com/view/Xds3zN

    vec3 cw = normalize(ta - ro);
    vec3 cp = vec3(sin(cr), cos(cr), 0.0);
    vec3 cu = normalize(cross(cw, cp));
    vec3 cv = normalize(cross(cu, cw));
    return mat3(cu, cv, cw);
}

void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Starter code from iq's Raymarching Primitives
    // https://www.shadertoy.com/view/Xds3zN

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
