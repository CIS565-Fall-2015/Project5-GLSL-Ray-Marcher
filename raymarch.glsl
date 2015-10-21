// 0 = None, 1 = Position, 2 = Normals, 3 = Steps
#define DEBUG 3
#define SPHERE_TRACE 1

/*****************Distance estimators from iq***************/
//https://www.shadertoy.com/view/Xds3zN

float sdTerrain( vec3 p )
{
    //http://www.iquilezles.org/www/articles/terrainmarching/terrainmarching.htm
    return p.y - 1.0 * sin(p.x) * sin(p.z);
}

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdCylinder( vec3 p, vec2 h )
{
  vec2 d = abs(vec2(length(p.xz),p.y)) - h;
  return min(max(d.x,d.y),0.0) + length(max(d,0.0));
}

float sdCone( in vec3 p, in vec3 c )
{
    vec2 q = vec2( length(p.xz), p.y );
    float d1 = -q.y-c.z;
    float d2 = max( dot(q,c.xy), q.y);
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}

float sdTorus( vec3 p, vec2 t )
{
  return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}

float unionDistance(float d1, float d2) {
    return min(d1, d2);
}

//construct scene
vec2 estimateDistance(in vec3 point) {
    
    float d1 = sdSphere(point + vec3(-0.5, -0.6, 0), 0.15);
    float d2 = sdBox(point, vec3(0.2, 0.2, 0.2));
    float d3 = sdCone(point + vec3(1.2, -0.2, -0.1),
                     vec3 (0.7, 0.3, 0.7));
    float d4 = sdTerrain(point + vec3(0, 0.5, 0));
    float d5 = sdCylinder(point + vec3(-1.0, 0.1, 0.5),
                         vec2(0.2, 0.8));
    
    float nearest = unionDistance(d5, 
                                  unionDistance(unionDistance(d3,d4),
                                  unionDistance(d1,d2)));
    float col = 0.0;
    
    if (nearest == d1) {
        col = 1.0;
    } else if(nearest == d2) {
        col = 2.0;
    } else if(nearest == d3){
        col = 3.0;
    } else if(nearest == d4){
        col = 4.0;
    } else {
        col = 3.0;
    }
    return vec2(nearest, col);
}



vec3 naiveRayMarch(in vec3 ro, in vec3 rd) {
    const float maxDistance = 50.0;
    const float dt = 0.001;
    int steps = 0;
    for (float t = 0.0; t < maxDistance; t += dt) {
     steps++;
     vec3 point = ro + rd * t;
     float intersected = estimateDistance(point).x;
     if(intersected < 0.0) {
        return vec3(t, steps, estimateDistance(point).y);
     }
    }
    return vec3(-1);
}

vec3 sphereTrace(in vec3 ro, in vec3 rd) {
    const float epsilon = 0.00001;
    const float minStep = 0.001;
    const int maxSteps = 500;
    
    float t = 0.0;
    float dt = estimateDistance(ro + rd * t).x;
    int steps = 0;
    float col;
    for (int i = 0; i <= maxSteps; i++ ) {
        steps++;
        dt = estimateDistance(ro + rd * t).x;
        t += max(dt, minStep);
        if (dt < epsilon) {
            col = estimateDistance(ro + rd * t).y;
            break;
        }   
    }
    return vec3(t, steps, col);
}


vec3 calcNormal(in vec3 pos)
{
    float eps = 0.0001;
    vec3 posx = vec3(pos.x + eps, pos.y, pos.z);
    vec3 posy = vec3(pos.x, pos.y + eps, pos.z);
    vec3 posz = vec3(pos.x, pos.y, pos.z + eps);
    vec3 nor = vec3(estimateDistance(pos).x - estimateDistance(posx).x,
                    estimateDistance(pos).x - estimateDistance(posy).x,
                    estimateDistance(pos).x - estimateDistance(posz).x);
    return normalize(nor);
}


/******************LIGHTING***************************/

//lambert
vec3 lambert(in vec3 point, in vec3 normal, in vec3 mat_color) {
    vec3 light_pos = vec3(0.0, -10, -4);
    float diffuse_term = 0.7;
    
    return mat_color * diffuse_term * max(0.0,dot(normal, normalize(light_pos - point)));
}


//soft shadow
float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<16; i++ )
    {
        float h = estimateDistance(ro + rd*t).x;
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );

}

vec3 render(in vec3 ro, in vec3 rd, in vec2 pixel) {
  
    vec3 marched_ray;
    vec3 BG = vec3(0.7);
    
    if (SPHERE_TRACE == 1) {
        marched_ray = sphereTrace(ro, rd);
    } else {
        marched_ray = naiveRayMarch(ro, rd);
    }
    
    vec3 point = ro + rd * marched_ray.x;
 
  
    if (DEBUG == 1) {   
        //debug image with distance to surface
        return point;
    } else if (DEBUG == 2){ 
        //debug image with normals
        return calcNormal(point);        
    } else if (DEBUG == 3) {    
        //debug image with distance to surface
        return vec3(0.0, marched_ray.y/255.0, marched_ray.y/255.0);
    } else {
        //render the image
        if(marched_ray.x > 0.0) {
           if(SPHERE_TRACE == 1 && marched_ray.y >= 50.0){
              return BG;
           } 
            
            vec3 col = vec3(0.7);
            if(marched_ray.z == 1.0) {
                col = vec3(0.1, 0, 0.8);
            } else if (marched_ray.z == 2.0) {
                col = vec3(0, 1, 1);
            } else if (marched_ray.z == 3.0) {
                col = vec3(0.7, 0, 0);
            } else {
                col = vec3(0.5);
            }
            
            return 1.2 * lambert(point, calcNormal(point), col);
         } else {
           return BG;
         }
    }
 
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
    vec3 col = render(ro, rd, fragCoord);

    col = pow(col, vec3(0.3545));

    fragColor = vec4(col, 1.0);
}
