float g(float t, in vec3 ro, in vec3 rd){
    return length(ro+rd*t-vec3(0.0, 0.25, 0.0))-0.25;
}    

vec2 naiveMarch(in vec3 ro, in vec3 rd){
    float maxDist = 21.0;
    float dt = 0.1;
    float t = 1.0;
    float m = -1.0;
    float eps = 0.000001;
    for (int i = 0; i < 200; i++){
        if (g(t, ro, rd) < eps){
            m = 1.0;
            break;
        }
        t+= dt;
    }
    return vec2(t, m);
}

vec3 render(in vec3 ro, in vec3 rd) {
    // Sky
    vec3 col = vec3(0.8,0.8,1.0)*(rd.y+1.0);
    
    // Ray marching
#if 1
    vec2 res = naiveMarch(ro, rd);
#else
    vec2 res = sphereMarch(ro, rd);
#endif
    
    if (res.y > 0.0){
        col = vec3(1.0, 0.0, 0.0);
    }    
    
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
