//http://www.iquilezles.org/www/articles/menger/menger.htm - mendel sponge
//https://en.wikipedia.org/wiki/Blinn%E2%80%93Phong_shading_model - blinn-phong lighting
//http://graphics.cs.williams.edu/courses/cs371/f14/reading/implicit.pdf - ray marching/sphere tracing
//http://www2.compute.dtu.dk/pubdb/views/edoc_download.php/6392/pdf/imm6392.pdf - ambient occlusion/soft shadows
//https://www.shadertoy.com/view/4t2SRz - smoke color
//https://www.shadertoy.com/view/MdXGW2 - water
//https://www.shadertoy.com/view/MdX3zr - smoke movement
//--Distance Functions-------------------------------------------------------------------

float time;
float newPos = 0.0;
const mat2 m2 = mat2(0.8,-0.6,0.6,0.8);

#define BUMPFACTOR 0.1
#define EPSILON 0.1
#define BUMPDISTANCE 60.

float noise(vec3 p) //Thx to Las^Mercury
{
    vec3 i = floor(p);
    vec4 a = dot(i, vec3(1., 57., 21.)) + vec4(0., 57., 21., 78.);
    vec3 f = cos((p-i)*acos(-1.))*(-.5)+.5;
    a = mix(sin(cos(a)*a),sin(cos(1.+a)*(1.+a)), f.x);
    a.xy = mix(a.xz, a.yw, f.y);
    return mix(a.x, a.y, f.z);
}

float sphere(vec3 p, vec4 spr)
{
    return (length(spr.xyz-p) - spr.w);
}

float planeDist( vec3 p )
{
    /*if (p.y < ((sin(p.x) - sin(p.z)) / 4.0)) return (sin(p.x) - sin(p.z)) / 4.0;
     else return 100.0;
     return 100.0;*/
    return p.y;
    
}

float ellipsoidDist( in vec3 p, in vec3 r )
{
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

float cylinderDist( vec3 p, vec2 h )
{
    vec2 d = abs(vec2(length(p.xz),p.y)) - h;
    return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sphereDist(vec3 p, float r) {
    return length(p) - r;
}

float flame(vec3 p)
{
    float d = sphere(p*vec3(6.,-1.0,5.), vec4(.0,-.9,.0,1.0));
    return d + (noise(p+vec3(.0,iGlobalTime*6.0,.0)) + noise(p*6.)*.5)*.25*(p.y) ;
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

float capsoleDist( vec3 p, vec3 a, vec3 b, float r )
{
    vec3 pa = p-a, ba = b-a;
    float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
    return length( pa - ba*h ) - r;
}

float crossDist( in vec3 p )
{
    float da = boxDist(p.xyz,vec3(100000,1.0,1.0));
    float db = boxDist(p.yzx,vec3(1.0,100000,1.0));
    float dc = boxDist(p.zxy,vec3(1.0,1.0,100000));
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
    return capsoleDist(q - vec3(-1.0, -1.0, -2.0), vec3(1.0,-4.0,1.0), vec3(1.0,1.0,1.0), 0.75);
}

/*vec3 transform( vec3 p, mat4 m )
 {
 //vec3 q = invert(m)*p;
 return box(p);
 }*/

float displace( vec3 p )
{
    float d1 = capsoleDist(p, vec3(-6.3,-4.0,-8.1), vec3(2.8,-0.50,-3.), 5.0);
    float d2 = (sin(20.0*p.z)*sin(20.0*p.y)*sin(20.0*p.x)*sin(iGlobalTime)) / (16.0*p.y);
    return d1+d2;
}

float bend( vec3 p )
{
    float c = cos(20.0*p.y);
    float s = sin(20.0*p.y);
    mat2  m = mat2(c,-s,s,c);
    vec2 newp = m*p.xz;
    vec3  q = vec3(newp.x, p.y, newp.y);
    return boxDist(q, vec3(1.0));
}

vec2 myMin(vec2 d1, vec2 d2) {
    
    return (d1.x<d2.x) ? d1 : d2;
}

//--Scenes------------------------------------------------------------------------

vec2 scene(vec3 ro, vec3 rd, float t) {
    vec3 pt = ro + rd*t;
    newPos = (-sin(mod(iGlobalTime/8.0, radians(90.0))))*10.0 + 5.;
    vec2 obj;
    vec4 color1 = texture2D (iChannel0, pt.xz/256.0);
    float avg = (color1.x + color1.y + color1.z) / 3.0;
    avg -= 2.0;
    float tmin = boxDist(pt - vec3(0.0, -2.75, 1.0), vec3(6.0, 3.0, .2));
    obj = myMin(vec2(tmin, 1.0), vec2(roundBoxDist(pt - vec3(0.0 + newPos, 0.475, 1.0), vec3(0.3, 0.15, .125), .05), 2.0));
    obj = myMin(obj, vec2(cylinderDist(pt - vec3(-0.2 + newPos, 0.775, 1.0), vec2(0.05, 0.25)), 2.0));
    obj = myMin(obj, vec2(roundBoxDist(pt - vec3(0.7 + newPos, 0.475, 1.0), vec3(0.3, 0.15, .125), .05), 2.0));
    obj = myMin(obj, vec2(roundBoxDist(pt - vec3(1.4 + newPos, 0.475, 1.0), vec3(0.3, 0.15, .125), .05), 2.0));
    obj = myMin(obj, vec2(flame(pt - vec3(-0.2 + newPos, 0.775, 1.0)), 3.0));
    obj = myMin(obj, vec2(boxDist(pt - vec3(0.0, 0.265, 1.15), vec3(6.0, .01, .01)), 1.0));
    obj = myMin(obj, vec2(boxDist(pt - vec3(0.0, 0.265, 0.85), vec3(6.0, .01, .01)), 1.0));
    obj = vec2(diffFunc(obj.x, repeat(pt - vec3(0.0, -0.85, 2.0), vec3(1.75, 0.0, 0.0))), obj.y); //diffFunc(tmin, repeat(pt, vec3(1.0, 0.0, 1.0)));
    //obj = myMin(obj, vec2(planeDist(pt - vec3(0.0, -2.0, 0.0)), 5.0));
    //obj = myMin(obj, vec2(planeDist(pt - vec3(0.0, -2.0, 0.0)), 4.0));
    return obj;
}

vec2 sceneHeight(vec3 ro, vec3 rd, float t) {
    vec3 pt = ro + rd*t;
    vec4 color1 = texture2D (iChannel0, pt.xz/256.0);
    float avg = (color1.x + color1.y + color1.z) / 3.0;
    
    float tmin = pt.y - (avg+(pt.z/iResolution.y)*64.);
    return vec2(tmin, 4.0);
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

vec3 sphereTrace(vec3 ro, vec3 rd, float t) {
    //float t = 0.0;
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

vec3 getColor(vec3 pt, vec3 norm, float t) {
    vec4 color = texture2D (iChannel2, pt.xz);
    if (pt.y > 10.0) {
        color *= pt.y;
    }
    
    // snow
    /*float h = smoothstep(55.0,80.0,pt.y/SC + 25.0*fbm(0.01*pt.xz/SC) );
     float e = smoothstep(1.0-0.5*h,1.0-0.1*h,norm.y);
     float o = 0.3 + 0.7*smoothstep(0.0,0.1,norm.x+h*h);
     float s = h*e*o;
     col = mix( col, 0.29*vec3(0.62,0.65,0.7), smoothstep( 0.1, 0.9, s ) );*/
    return vec3(color);
    
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

float random(float x) {
    
    return fract(sin(x) * 10000.);
    
}

float noise2(vec2 p) {
    
    return random(p.x + p.y * 10000.);
    
}

vec2 sw(vec2 p) { return vec2(floor(p.x), floor(p.y)); }
vec2 se(vec2 p) { return vec2(ceil(p.x), floor(p.y)); }
vec2 nw(vec2 p) { return vec2(floor(p.x), ceil(p.y)); }
vec2 ne(vec2 p) { return vec2(ceil(p.x), ceil(p.y)); }
float smoothNoise(vec2 p) {
    
    vec2 interp = smoothstep(0., 1., fract(p));
    float s = mix(noise2(sw(p)), noise2(se(p)), interp.x);
    float n = mix(noise2(nw(p)), noise2(ne(p)), interp.x);
    return mix(s, n, interp.y);
    
}


float noise3( const in vec3 x ) {
    vec3 p = floor(x);
    vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    
    vec2 uv = (p.xy+vec2(37.0,17.0)*p.z) + f.xy;
    vec2 rg = texture2D( iChannel0, (uv+ 0.5)/256.0, -100.0 ).yx;
    return mix( rg.x, rg.y, f.z );
}


const mat2 m4 = mat2( 0.60, -0.80, 0.80, 0.60 );

const mat3 m3 = mat3( 0.00,  0.80,  0.60,
                     -0.80,  0.36, -0.48,
                     -0.60, -0.48,  0.64 );

float fbm( in vec3 p ) {
    float f = 0.0;
    f += 0.5000*noise3( p ); p = m3*p*2.02;
    f += 0.2500*noise3( p ); p = m3*p*2.03;
    f += 0.1250*noise3( p ); p = m3*p*2.01;
    f += 0.0625*noise3( p );
    return f/0.9375;
}

float fractalNoise(vec2 p) {
    
    float n = 0.;
    n += smoothNoise(p);
    n += smoothNoise(p * 2.) / 2.;
    n += smoothNoise(p * 4.) / 4.;
    n += smoothNoise(p * 8.) / 8.;
    n += smoothNoise(p * 16.) / 16.;
    n /= 1. + 1./2. + 1./4. + 1./8. + 1./16.;
    return n;
    
}

float waterMap( vec2 pos ) {
    vec2 posm = pos * m4;
    
    return abs( fbm( vec3( 8.*posm, time ))-0.5 )* 0.1;
}

bool intersectPlane(const in vec3 ro, const in vec3 rd, const in float height, inout float dist) {
    if (rd.y==0.0) {
        return false;
    }
    
    float d = -(ro.y - height)/rd.y;
    d = min(100000.0, d);
    if( d > 0. && d < dist ) {
        dist = d;
        return true;
    }
    return false;
}

vec3 lig = normalize(vec3( 0.3,0.25, -0.6));

vec3 bgColor( const in vec3 rd ) {
    float sun = clamp( dot(lig,rd), 0.0, 1.0 );
    vec3 col = vec3(0.5, 0.52, 0.55) - rd.y*0.2*vec3(1.0,0.8,1.0) + 0.15*0.75;
    col += vec3(1.0,.6,0.1)*pow( sun, 8.0 );
    col *= 0.95;
    return col;
}


vec4 render(in vec3 ro, in vec3 rd, float t) {
    // TODO
    int debug = 0;
    bool root = false;
    vec3 col = vec3(.8, .9, 1.0);
    //float t = -1.0;
    vec3 dist;
    if (root) {
        dist = findRoot(ro, rd);
    }
    else {
        dist = sphereTrace(ro, rd, t);
    }
    t = dist.x;
    if (t < 10.0) {
        vec3 pt = ro + rd*t;
        vec3 norm = calcNorm(pt);
        
        //material
        
        vec4 x = texture2D( iChannel1, pt.yz );
        vec4 y = texture2D( iChannel1, pt.zx );
        vec4 z = texture2D( iChannel1, pt.yx );
        vec3 a = abs(norm);
        vec4 diffuse = (x*a.x + y*a.y + z*a.z) / (a.x + a.y + a.z);
        if (dist.z == 1.0 && norm.y >= 0.999) {
            diffuse *= vec4(0.3, 0.0, 0.0, 1.0);
        }
        if (dist.z == 2.0) {
            diffuse = vec4(.2118, 0.2706, 0.3098, 1.0);
        }
        
        //end material
        
        vec3 ref = reflect(rd, norm);
        vec3 light = normalize(vec3(0.0, 2.0, 2.0) - pt);
        float lambert = clamp(dot(light, norm), 0.0, 1.0);
        //float amb = ambientOcc(pt, norm);
        //soft shadows
        //lambert *= softshadow( pt, light, 0.02, 2.5 );
        float dom = smoothstep( -0.1, 0.1, ref.y );
        //dom *= softshadow( pt, ref, 0.02, 2.5 );
        
        float specular = 0.0;
        if (lambert > 0.0) {
            vec3 viewDir = normalize(-pt);
            vec3 halfDir = normalize(light + viewDir);
            float specAngle = clamp(dot(halfDir, norm), 0.0, 1.0);
            specular = pow(specAngle, 4.0);
            
        }
        
        col = vec3(.2) + lambert * vec3(diffuse) + specular * vec3(0.5); //amb*
        
        col = pow(col, vec3(1.0/2.2));
        col *= 1.0 - smoothstep( 20.0, 40.0, t );
        if (dist.z == 3.0) {
            float x = fractalNoise(pt.xz * 6.);
            col = mix(vec3(x), vec3(.75, .85, 1.0), pow(abs(pt.y), .6));
            //return vec4(rd, dist.y*3.0 / 50.0);
        }
        if (dist.z == 4.0) {
            col = getColor(pt, norm, t);
        }
        
        if (debug == 1) {
            col = norm;
        }
        else if (debug == 2) {
            if (root) {
                col = vec3(1.0, 1.0, 1.0)*(dist.y / 1000.0);
            }
            else {
                col = vec3(1.0, 0.0, 0.0)*(dist.y*3.0 / 50.0);
            }
        }
        else if (debug == 3) {
            col = vec3(1.0) * ((5.0 - t) / 5.0);
        }
        
        
    }
    
    
    return vec4(col, 1.0); //rd;  // camera ray direction debug view
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

float intersectSimple( const vec3 ro, const vec3 rd ) {
    float maxd = 10000.0;
    float precis = 0.001;
    float h=precis*2.0;
    float t = 0.0;
    for( int i=0; i<50; i++ ) {
        if( abs(h)<precis || t>maxd ) break;  {
            t += h;
            vec2 newt = scene(ro, rd, t);
            h = newt.x;
        }
    }
    
    return t;
}
void mainImage(out vec4 fragColor, in vec2 fragCoord) {
    // Starter code from iq's Raymarching Primitives
    // https://www.shadertoy.com/view/Xds3zN
    vec2 q = fragCoord.xy / iResolution.xy;
    vec2 p = -1.0 + 2.0 * q;
    p.x *= iResolution.x / iResolution.y;
    vec2 mo = iMouse.xy / iResolution.xy;
    
    time = 15.0 + iGlobalTime;
    
    // camera
    vec3 ro = vec3(
                   -0.5 + 3.5 * cos(0.1  + 6.0 * mo.x),
                   0.0 + 2.0 * mo.y,
                   0.5 + 3.5 * sin(0.1  + 6.0 * mo.x));
    vec3 ta = vec3(-0.5, -0.4, 0.5);
    
    // camera-to-world transformation
    mat3 ca = setCamera(ro, ta, 0.0);
    
    // ray direction
    vec3 rd = ca * normalize(vec3(p.xy, 2.0));
    
    
    float fresnel, refldist = 5000., maxdist = 5000.;
    bool reflected = false;
    vec3 normal, col = bgColor( rd );
    vec3 roo = ro, rdo = rd, bgc = col;
    float distSimple = intersectSimple(ro,rd);
    if( intersectPlane( ro, rd, 0., refldist ) && refldist < distSimple ) {
        ro += (refldist)*rd;
        vec2 coord = ro.xz;
        float bumpfactor = BUMPFACTOR * (1. - smoothstep( 0., BUMPDISTANCE, refldist) );
        
        vec2 dx = vec2( EPSILON, 0. );
        vec2 dz = vec2( 0., EPSILON );
        
        normal = vec3( 0., 1., 0. );
        normal.x = -bumpfactor * (waterMap(coord + dx) - waterMap(coord-dx) ) / (2. * EPSILON);
        normal.z = -bumpfactor * (waterMap(coord + dz) - waterMap(coord-dz) ) / (2. * EPSILON);
        normal = normalize( normal );
        
        float ndotr = dot(normal,rd);
        fresnel = pow(1.0-abs(ndotr),5.);
        
        rd = reflect( rd, normal);
        
        reflected = true;
        bgc = col = bgColor( rd );
    }
    
    // render
    vec4 color = render(roo, rdo, 0.);
    col = vec3(color);
    if(reflected) {
        col = mix( col.xyz, bgc, 1.0-exp(-0.0000005*refldist*refldist) );
        col *= fresnel*0.9;
        vec3 refr = refract( rdo, normal, 1./1.3330 );
        intersectPlane( ro, refr, -2., refldist );
        col += mix( texture2D( iChannel2, (roo+refldist*refr).xz*1.3 ).xyz *
                   vec3(1.,.9,0.6), vec3(1.,.9,0.8)*0.5, clamp( refldist / 3., 0., 1.) ) 
        * (1.-fresnel)*0.125;
        
    }
    col = pow(col, vec3(0.7)); //4545));
    col = col*col*(3.0-2.0*col);
    col = mix( col, vec3(dot(col,vec3(0.33))), -0.5 );
    col *= 0.25 + 0.75*pow( 16.0*q.x*q.y*(1.0-q.x)*(1.0-q.y), 0.1 );
    fragColor = vec4(col, 1.0);
    
    
}