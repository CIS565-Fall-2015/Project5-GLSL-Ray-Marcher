//http://www.iquilezles.org/www/articles/menger/menger.htm - mendel sponge
//https://en.wikipedia.org/wiki/Blinn%E2%80%93Phong_shading_model - blinn-phong lighting
//http://graphics.cs.williams.edu/courses/cs371/f14/reading/implicit.pdf - ray marching/sphere tracing
//http://www2.compute.dtu.dk/pubdb/views/edoc_download.php/6392/pdf/imm6392.pdf - ambient occlusion/soft shadows
//--Distance Functions-------------------------------------------------------------------

#define NORMALS 0
#define RAY_STEPS 0
#define DISTANCE 0
#define SPHERE_TRACE 1


float planeDist( vec3 p )
{
    /*if (p.y < ((sin(p.x) - sin(p.z)) / 4.0)) return (sin(p.x) - sin(p.z)) / 4.0;
     else return 100.0;
     return 100.0;*/
    return p.y;
    
}

float sphereDist(vec3 p, float r) {
    return length(p) - r;
}

float boxDist( vec3 p, vec3 b )
{
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float torusDist( vec3 p, vec2 t )
{
    return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}

float roundBoxDist( vec3 p, vec3 b, float r )
{
    return length(max(abs(p)-b,0.0))-r;
}

float crossDist( in vec3 p )
{
    float da = boxDist(p.xyz,vec3(100000,1.0,1.0));
    float db = boxDist(p.yzx,vec3(1.0,100000,1.0));
    float dc = boxDist(p.zxy,vec3(1.0,1.0,100000));
    return min(da,min(db,dc));
}

float crossDist2( in vec3 p )
{
    float da = boxDist(p.xyz,vec3(.7,.3,.3));
    float db = boxDist(p.yzx,vec3(.3,.7,.3));
    float dc = boxDist(p.zxy,vec3(.3,.3,.7));
    return min(da,min(db,dc));
}

//--CSG Functions----------------------------------------------------------------------

float diffFunc(float d1, float d2) {
    return max(d1, -d2);
}

float intersectionFunc(float d1, float d2) {
    return max(d1, d2);
}

float repeat( vec3 p, vec3 c )
{
    vec3 q = mod(p,c)-0.5*c;
    vec4 height = texture2D(iChannel0, p.xz);
    //float avg = clamp((height.x + height.y + height.z + height.w) / 4.0, 0.0, 2.0);
    return roundBoxDist(q - vec3(0.0, 0.0, 0.0), vec3(.35, 0.1, .35), 0.1);
}

float displace( vec3 p )
{
    float d1 = torusDist(p, vec2(.2, .2));
    float d2 = (sin(10.0*p.x)*sin(10.0*p.y)*sin(10.0*p.z)) / (16.0*p.y);
    return d1+d2;
}

vec3 transform(vec3 pt, vec3 translate, vec3 rot, vec3 scale) {
    scale.x = 1.0/scale.x;
    scale.y = 1.0/scale.y;
    scale.z = 1.0/scale.z;
    mat3 invRot = mat3(scale.x*cos(rot.y)*cos(rot.x), sin(rot.y)*sin(rot.z)*cos(rot.x) - cos(rot.z)*sin(rot.x) , sin(rot.y)*sin(rot.x) + cos(rot.z)*sin(rot.y)*cos(rot.x) ,
                       cos(rot.y)*sin(rot.x), (sin(rot.z)*sin(rot.y)*sin(rot.x) + cos(rot.z)*cos(rot.x))*scale.y, sin(rot.x)*sin(rot.y)*cos(rot.z) - cos(rot.x)*sin(rot.z),
                       -sin(rot.y), cos(rot.y)*sin(rot.z), cos(rot.y)*cos(rot.z)*scale.z);
    mat4 trans = mat4(scale.x*cos(rot.y)*cos(rot.x), sin(rot.y)*sin(rot.z)*cos(rot.x) - cos(rot.z)*sin(rot.x) , sin(rot.y)*sin(rot.x) + cos(rot.z)*sin(rot.y)*cos(rot.x) , 0.0,
                      cos(rot.y)*sin(rot.x), (sin(rot.z)*sin(rot.y)*sin(rot.x) + cos(rot.z)*cos(rot.x))*scale.y, sin(rot.x)*sin(rot.y)*cos(rot.z) - cos(rot.x)*sin(rot.z), 0.0,
                      -sin(rot.y), cos(rot.y)*sin(rot.z), cos(rot.y)*cos(rot.z)*scale.z, 0.0,
                      (-invRot*translate).x, (-invRot*translate).y, (-invRot*translate).z, 1.0);
    
    vec4 newPt = vec4(pt, 1.0);
    newPt = trans*newPt;
    return vec3(newPt);
    
}

vec2 myMin(vec2 d1, vec2 d2) {
    
    return (d1.x<d2.x) ? d1 : d2;
}

//--Different Scenes-------------------------------------------------------------------

vec2 scene(vec3 ro, vec3 rd, float t) {
    vec3 pt = ro + rd*t;
    
    float tmin = boxDist(pt - vec3(1.0, 0.0, -1.0), vec3(.3));
    //vec2 obj = vec2(tmin, 0.0);
    float s = 1.0;
    for( int m=0; m<5; m++ )
    {
        vec3 a = mod( pt*s, 2.0 )-1.0;
        s *= 3.0;
        vec3 r = abs(1.0 - 3.0*abs(a));
        
        float da = max(r.x,r.y);
        float db = max(r.y,r.z);
        float dc = max(r.z,r.x);
        float c = (min(da,min(db,dc))-1.0)/s;
        
        tmin = max(tmin,c);
    }
    vec2 obj = vec2(tmin, 0.0);
    obj = myMin(obj, vec2(planeDist(pt - vec3(0.0, -1.0, 1.0)), 1.0));
    obj = myMin(obj, vec2(displace(pt - vec3(-2.5, 0.0, 1.0)), 2.0));
    obj = myMin(obj, vec2(diffFunc(boxDist(pt - vec3(-2.0, .5, -.5), vec3(0.30, 0.50, 0.30)), sphereDist(pt - vec3(-2.0, .5, -.5), 0.4)), 3.0));
    obj = myMin(obj, vec2(torusDist(pt - vec3(0.3, -.2, 2.0), vec2(.3, .1)), 5.0));
    vec3 pos = transform(pt, vec3(0.0), vec3(radians(iGlobalTime*100.), 0.0, 0.0), vec3(1.0));
    obj = myMin(obj, vec2(crossDist2(pos), 6.0));
    
    vec4 color1 = texture2D (iChannel0, pt.xz/256.0);
    float avg = (color1.x + color1.y + color1.z) / 3.0;
    
    //obj = myMin(obj, vec2(pt.y - (avg*2.0), 4.0));
    
    return obj;
    
}

vec2 sceneSoftShadow(vec3 ro, vec3 rd, float t) {
    vec3 pt = ro + rd*t;
    vec2 obj = vec2(planeDist(pt - vec3(0.0, 0.0, 0.0)), 1.0);
    obj = myMin(obj, vec2(torusDist(pt - vec3(0.0, 0.5, 0.0), vec2(.3, .1)), 5.0));
    return obj;
}

float sceneDisplacement(vec3 ro, vec3 rd, float t) {
    vec3 pt = ro + rd*t;
    float tmin = displace(pt);
    
   	return tmin;
}

float sceneNothin(vec3 ro, vec3 rd, float t) {
    vec3 pt = ro + rd*t;
    float tmin = 0.0;
    
    return tmin;
}
float sceneRepeat(vec3 ro, vec3 rd, float t) {
    vec3 pt = ro + rd*t;
    float tmin = repeat(pt, vec3(1.0, 0.0, 1.0));
    
    return tmin;
    
}

float sceneTransform(vec3 ro, vec3 rd, float t) {
    vec3 pt = ro + t*rd;
    
   	vec3 pos = transform(vec3(pt), vec3(1.0, 0.0, 0.0), vec3(radians(iGlobalTime), radians(0.), radians(45.)), vec3(.5, 1.0, 1.0));
    float tmin = boxDist(pos, vec3(0.25));
    
    return tmin;
}

float sceneHeight(vec3 ro, vec3 rd, float t) {
    vec3 pt = ro + rd*t;
    vec4 color1 = texture2D (iChannel0, pt.xz);
    
    float tmin = pt.y - (color1.y);
    return tmin;
}

float sceneLighting(vec3 ro, vec3 rd, float t) {
    vec3 pt = ro + rd*t;
    float tmin = sphereDist(pt - vec3(0.0, -1.0, 0.0), .50);
    tmin = min(tmin, planeDist(pt - vec3(0.0, -.5, 0.0)));
    tmin = min(tmin, boxDist(pt - vec3( 1.0,-.25, 0.0), vec3(0.25)));
   	tmin = min(tmin, torusDist(pt - vec3(-1.0, 0.25, 0.0), vec2(0.20,0.05)));
    tmin = min(tmin, diffFunc(boxDist(pt - vec3(0.0), vec3(0.50, 0.30, 0.30)), sphereDist(pt - vec3(0.0), 0.40)));
    return tmin;
}

//--Ray Marching------------------------------------------------------------------

vec3 calcNorm( in vec3 pos )
{
    vec3 eps = vec3( 0.001, 0.0, 0.0 );
    vec3 nor = vec3(
                    scene(pos+eps.xyy, vec3(0.0), 0.0).x - scene(pos-eps.xyy, vec3(0.0), 0.0).x,
                    scene(pos+eps.yxy, vec3(0.0), 0.0).x - scene(pos-eps.yxy, vec3(0.0), 0.0).x,
                    scene(pos+eps.yyx, vec3(0.0), 0.0).x - scene(pos-eps.yyx, vec3(0.0), 0.0).x );
    return normalize(nor);
}

vec3 findRoot(vec3 ro, vec3 rd) {
    float dist = 100.0;
    float i = 0.0;
    float numObj = 0.0;
    for (float t = 0.0; t < 5.0; t += .005) {
        i++;
        vec2 obj = scene(ro, rd, t);
        if (obj.x < 0.0) {
            dist = t;
            numObj = obj.y;
            break;
        }
    }
    
    return vec3(dist, i, numObj);
    
}

vec3 sphereTrace(vec3 ro, vec3 rd) {
    float t = 0.0;
    float dt;
    vec2 objs;
    float numTraces = 0.0;
    float numObj = 0.0;
    for (int i = 0; i < 50; i++) {
        numTraces++;
        objs = scene(ro, rd, t);
        dt = objs.x;
        numObj = objs.y;
        t = t + dt;
        if (dt < 0.0001) {
            break;
        }
    }
    return vec3(t, numTraces, numObj);
}

float softshadow( in vec3 ro, in vec3 rd, in float tmin, in float tmax )
{
    float shadow = 1.0;
    float t = tmin;
    float d = 0.0;
    for( int i=0; i<16; i++ )
    {
        d = scene(ro, rd, t).x;
        if (d < 0.0001) return 0.0;
        shadow = min( shadow, 8.0*d/t );
        t += d;
        if( d<0.0001 || t > tmax) break;
    }
    return clamp(shadow, 0.0, 1.0);
    
}

float ambientOcc( in vec3 pt, in vec3 norm )
{
    float occ = 0.0;
    float d = 0.0;
    for(float k=1.0; k<10.0; k++ )
    {
        d = scene(pt, norm, .01*k).x;
        occ = (1.0 / pow(2.0, k)) * (k*.01 - d);
    }
    return clamp(1.0 - 3000.0*occ, 0.0, 1.0);
}

vec3 render(in vec3 ro, in vec3 rd) {
    // TODO
    int debug = 1;
    bool root;
    if (SPHERE_TRACE == 1) root = false;
    else root = true;
    vec3 col = vec3(.8, .9, 1.0);
    float t = -1.0;
    vec3 dist;
    if (root) {
        dist = findRoot(ro, rd);
    }
    else {
        dist = sphereTrace(ro, rd);
    }
    t = dist.x;
    if (t < 10.0) {
        vec3 pt = ro + rd*t;
        vec3 norm = calcNorm(pt);
        vec4 diffuse = vec4(1.0);
        //material
        if (dist.z == 0.0) {
            diffuse = vec4(0.0, 0.0, 0.0, 1.0);
        }
        if (dist.z == 1.0) {
            vec4 x = texture2D( iChannel1, pt.yz );
            vec4 y = texture2D( iChannel1, pt.zx );
            vec4 z = texture2D( iChannel1, pt.yx );
            vec3 a = abs(norm);
            diffuse = (x*a.x + y*a.y + z*a.z) / (a.x + a.y + a.z);
            
        }
        if (dist.z == 6.0) {
            vec4 x = texture2D( iChannel2, pt.yz );
            vec4 y = texture2D( iChannel2, pt.zx );
            vec4 z = texture2D( iChannel2, pt.yx );
            vec3 a = abs(norm);
            diffuse = (x*a.x + y*a.y + z*a.z) / (a.x + a.y + a.z);
        }
        //end material
        if (dist.z == 2.0) {
            diffuse = vec4(0.0, 1.0, 0.0, 1.0);
        }
        if (dist.z == 3.0) {
            diffuse = vec4(0.0, 1.0, 1.0, 1.0);
        }
        if (dist.z == 5.0) {
            diffuse = vec4(1.0, 0.0, 0.0, 1.0);
        }
        vec3 ref = reflect(rd, norm);
        vec3 light = normalize(vec3(0.0, 2.0, 2.0) - pt);
        float lambert = clamp(dot(light, norm), 0.0, 1.0);
        float amb = ambientOcc(pt, norm);
        //soft shadows
        lambert *= softshadow( pt, light, 0.02, 2.5 );
        float dom = smoothstep( -0.1, 0.1, ref.y );
        dom *= softshadow( pt, ref, 0.02, 2.5 );
        
        float specular = 0.0;
        if (lambert > 0.0) {
            vec3 viewDir = normalize(-pt);
            vec3 halfDir = normalize(light + viewDir);
            float specAngle = clamp(dot(halfDir, norm), 0.0, 1.0);
            specular = pow(specAngle, 4.0);
            
        }
        
        col = vec3(amb*.2) + lambert * vec3(diffuse) + specular * vec3(0.5);
        
        col = pow(col, vec3(1.0/2.2));
        col *= 1.0 - smoothstep( 20.0, 40.0, t );
        
        
        
        if (NORMALS == 1) {
            col = norm;
        }
        else if (RAY_STEPS == 1) {
            if (root) {
                col = vec3(1.0, 0.0, 0.0)*(dist.y / 1000.0);
            }
            else {
                col = vec3(1.0, 0.0, 0.0)*(dist.y / 50.0);
            }
        }
        else if (DISTANCE == 1) {
            col = vec3(1.0) * ((5.0 - t) / 5.0);
        }
    }
    return col; //rd;  // camera ray direction debug view
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