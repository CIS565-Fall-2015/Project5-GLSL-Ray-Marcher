float dSphere(vec3 X, vec3 C, float r){
    return length(X-C)-r;
}

float dPlane(vec3 X){
    return X.y;
}

float dBox(vec3 X, vec3 C, float b){
    vec3 d = abs(X-C)-b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float dTorus(vec3 X, vec3 C, float R, float r)
{
    return length(vec2(length(X.xz - C.xz) - r, X.y - C.y)) - R;
}

vec2 opUnion(vec2 r1, vec2 r2){
    return r1.x < r2.x ? r1 : r2;
}


vec2 allDist(in vec3 X){
    vec2 res;
    float sphereDist = dSphere(X, vec3(-1.0, 0.25, 0.0), 0.25);
    float planeDist = dPlane(X);
    res = opUnion(vec2(sphereDist, 1.0), vec2(planeDist, 2.0));
    float boxDist = dBox(X, vec3(1.0, 0.25, 1.0), 0.25);
    res = opUnion(res, vec2(boxDist, 3.0));
    float torusDist = dTorus(X, vec3(-1.5, 0.5, -1.5), 0.15, 0.5);
    res = opUnion(res, vec2(torusDist, 4.0));
    return res;
}

vec2 naiveMarch( in vec3 ro, in vec3 rd ){
    float tmin = 1.0;
    float tmax = 20.0;
    float tstep = 0.01;
    
    float precis = 0.001;
    float t = tmin;
    float m = -1.0;
    for( int i=0; i<1000; i++ )
    {
        vec2 res = allDist( ro+rd*t );
        if( res.x<precis) break;
        m = res.y;
        t += tstep;   
    }  
    
    if( t>tmax ) m=-1.0;
    return vec2( t, m );
}
vec2 sphereMarch( in vec3 ro, in vec3 rd )
{
    float tmin = 1.0;
    float tmax = 20.0;
    
    float precis = 0.001;
    float t = tmin;
    float m = -1.0;
    for( int i=0; i<50; i++ )
    {
        vec2 res = allDist( ro+rd*t );
        if( res.x<precis || t>tmax ) break;
        m = res.y;
        t += res.x;
    }

    if( t>tmax ) m=-1.0;
    return vec2( t, m );
}

vec3 getNormal( in vec3 X )
{
    vec3 eps = vec3( 0.001, 0.0, 0.0 );
    vec3 n = vec3(
        allDist(X+eps.xyy).x - allDist(X-eps.xyy).x,
        allDist(X+eps.yxy).x - allDist(X-eps.yxy).x,
        allDist(X+eps.yyx).x - allDist(X-eps.yyx).x );
    return normalize(n);
}

float shadow(vec3 ro, vec3 rd){
    float t = 0.001;
    float eps = 0.0001;
    vec2 res;
    float dist = 1.0;
    float maxDist = 1.0;
    float C = 8.0;
    for (int i = 0; i < 30; i++){
        res = allDist(ro+rd*t);
        if (res.x < eps){
            return 0.0;
        }
        if (res.x > maxDist)
            break;
        dist = min(dist, C*res.x/t);
        t+= res.x;
    }
    return clamp(dist, 0.0, 1.0);
}


vec3 shade(vec3 ro, vec3 rd, vec2 res){
    vec3 color;
    if(res.y == 1.0){
        color = vec3(0.8,0.2,0.2);
    } else if( res.y == 2.0){
        color = vec3(0.3, 0.8, 0.3);
    } else if( res.y == 3.0){
        color = vec3(0.5, 0.5, 0.9);
    } else if( res.y == 4.0){
        color = vec3(0.9, 0.9, 0.3);
    } 
    
    //for lighting
    vec3 light = normalize( vec3(-0.6, 0.7, -0.5) );
    vec3 norm = getNormal(ro+rd*res.x);
    float diffuse = clamp( dot( norm, light ), 0.0, 1.0 );
    
    float shadow = shadow(ro+rd*res.x, light);
    
    //return color*diffuse;
    return color*diffuse*shadow;
    //return clamp( dot( rd, (ro+rd*res.x) )*vec3(0.1), 0.0, 1.0 );
    //return norm;
}

vec3 render(in vec3 ro, in vec3 rd) {
    vec3 color = vec3(0.8, 0.9, 1.0);
    vec2 res = sphereMarch(ro, rd);
    //vec2 res = naiveMarch(ro, rd);
    if(res.y > 0.0){
        color = shade(ro, rd, res);
    }
    return vec3( clamp(color,0.0,1.0) );
    //return rd;  // camera ray direction debug view
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