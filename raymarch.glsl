// Mostly from/based off of IQ's code at: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

//#define DEBUG_ITER

vec3 camPos = vec3(3.0,3.0,3.0);

float sdCylinder( vec3 p, vec3 c )
{
  return length(p.xz-c.xy)-c.z;
}

float sdCone( vec3 p, vec2 c )
{
    // c must be normalized
    float q = length(p.xy);
    return dot(c,vec2(q,p.z));
}

float sdTorus( vec3 p, vec2 t )
{
  vec2 q = vec2(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

float sdPlane( vec3 p )
{
    return p.y;
}

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float sdEllipsoid( in vec3 p, in vec3 r )
{
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

float sdBox( vec3 p, vec3 b )
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) +
         length(max(d,0.0));
}

//----------------------------------------------------------------------

// Code from: http://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
mat4 rotation(vec3 axis, float angle)
{
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}

mat4 transpose(mat4 m){
    mat4 mt;
    for(int i = 0; i < 4; i++){
        for (int j = 0; j < 4; j++){
        	mt[i][j] = m[j][i];
        }
    }
    return mt;
}

vec3 opTx(vec3 pos, vec3 axis, float angle, vec3 translation){
    vec3 pos2;
    mat4 rot = rotation(axis, angle);
    pos2 = (transpose(rot)*vec4(pos,1.0)).xyz;
    pos2 -= translation;
    return pos2;
}

vec2 opU( vec2 d1, vec2 d2 )
{
    return (d1.x<d2.x) ? d1 : d2;
}

//----------------------------------------------------------------------

vec2 map( in vec3 pos )
{
    
    vec2 res = opU(
                	vec2( sdPlane(pos), 1.0 ),
	            	vec2( sdSphere(pos-vec3( 0.0,0.25, 0.0), 0.25 ), 46.9)
               );
    vec3 posEllipsoid = opTx(pos, vec3(0.0,0.0,1.0), 0.2, vec3(1.0,1.0,0.0));
    
    res = opU(res, vec2(sdEllipsoid(posEllipsoid, vec3(0.2,0.4,0.2)),40.0));
    
    //res = opU(res, vec2(sdTorus(pos - vec3(1.5,0.5,0.0),vec2(0.4,0.2)),36.0));
    //res = opU(res, vec2(sdCylinder(pos - vec3(-1.0,0.0,0.0), vec3(0.01,1.0,0.2)), 26.0));
    //res = opU(res, vec2(sdEllipsoid(pos - vec3(2.0,0.2,0.1), vec3(0.1,0.8,0.4)),16.0));
    return res;
}

vec3 naiveCastRay(in vec3 ro, in vec3 rd){
    float tmax = 20.0;
    float tmin = 1.0;
    float dt = 0.002;
    const int max_iter = 4000;
    
    float t = tmin;
    float m = -1.0;
    
    vec2 res = map(ro + rd*t);
	int iter;
    for (int i=0; i<max_iter; i++){
        res = map(ro + rd*t);
        if (t > tmax || res.x < 0.0) break;
        t += dt;
        m = res.y;
		iter = i;
    }

    if (res.x > 0.0){
        m = -1.0;
    }
    return vec3(t,m,iter);
}

vec3 castRay( in vec3 ro, in vec3 rd )
{
    float tmin = 1.0;
    float tmax = 20.0;
    
    float precis = 0.002;
    float t = tmin;
    float m = -1.0;
    int iter;
    for(int i=0; i<50; i++ )
    {
        vec2 res = map( ro+rd*t );
        if( res.x<precis || t>tmax ) break;
        t += res.x;
        m = res.y;
        iter = i;
    }

    if( t>tmax ) m=-1.0;
    return vec3( t, m, iter );
}

vec3 calcNormal( in vec3 pos )
{
    vec3 eps = vec3( 0.001, 0.0, 0.0 );
    vec3 nor = vec3(
        map(pos+eps.xyy).x - map(pos-eps.xyy).x,
        map(pos+eps.yxy).x - map(pos-eps.yxy).x,
        map(pos+eps.yyx).x - map(pos-eps.yyx).x );
    return normalize(nor);
}

float calcAO( in vec3 pos, in vec3 nor )
{
    float occ = 0.0;
    float sca = 1.0;
    for( int i=0; i<5; i++ )
    {
        float hr = 0.01 + 0.12*float(i)/4.0;
        vec3 aopos =  nor * hr + pos;
        float dd = map( aopos ).x;
        occ += -(dd-hr)*sca;
        sca *= 0.95;
    }
    return clamp( 1.0 - 3.0*occ, 0.0, 1.0 );    
}

vec3 render( in vec3 ro, in vec3 rd )
{ 
    vec3 col = vec3(0.8, 0.9, 1.0); // Sky color
    vec3 res = castRay(ro,rd);
    float t = res.x;
    float m = res.y;
    if( m>-0.5 )  // Ray intersects a surface
    {
        vec3 pos = ro + t*rd;
        vec3 nor = calcNormal( pos );
        vec3 ref = reflect( rd, nor );
        
        // material        
        col = 0.45 + 0.3*sin( vec3(0.05,0.08,0.10)*(m-1.0) );
        
        if( m<1.5 )
        {
            float f = mod( floor(5.0*pos.z) + floor(5.0*pos.x), 2.0);
            col = 0.4 + 0.1*f*vec3(1.0);
        }

        // lighitng        
        float occ = calcAO( pos, nor );
        vec3  lig = normalize( vec3(-0.6, 0.7, -0.5) );
        float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        float bac = clamp( dot( nor, normalize(vec3(-lig.x,0.0,-lig.z))), 0.0, 1.0 )*clamp( 1.0-pos.y,0.0,1.0);
        float dom = smoothstep( -0.1, 0.1, ref.y );
        float fre = pow( clamp(1.0+dot(nor,rd),0.0,1.0), 2.0 );
        float spe = pow(clamp( dot( ref, lig ), 0.0, 1.0 ),16.0);

        vec3 brdf = vec3(0.0);
        brdf += 1.20*dif*vec3(1.00,0.90,0.60);
        brdf += 1.20*spe*vec3(1.00,0.90,0.60)*dif;
        brdf += 0.30*amb*vec3(0.50,0.70,1.00)*occ;
        brdf += 0.40*dom*vec3(0.50,0.70,1.00)*occ;
        brdf += 0.30*bac*vec3(0.25,0.25,0.25)*occ;
        brdf += 0.40*fre*vec3(1.00,1.00,1.00)*occ;
        brdf += 0.02;
        col = col*brdf;

        col = mix( col, vec3(0.8,0.9,1.0), 1.0-exp( -0.0005*t*t ) );
    }

    return vec3( clamp(col,0.0,1.0) );
}

mat3 setCamera( in vec3 ro, in vec3 ta, float cr )
{
    vec3 cw = normalize(ta-ro);
    vec3 cp = vec3(sin(cr), cos(cr),0.0);
    vec3 cu = normalize( cross(cw,cp) );
    vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 q = fragCoord.xy/iResolution.xy;
    vec2 p = -1.0+2.0*q;
    p.x *= iResolution.x/iResolution.y;
    vec2 mo = iMouse.xy/iResolution.xy;
		 
    float time = 15.0 + iGlobalTime;

    // camera	
    vec3 ro = vec3( -0.5+3.5*cos(0.1*time + 6.0*mo.x), 1.0 + 2.0*mo.y, 0.5 + 3.5*sin(0.1*time + 6.0*mo.x) );
    //camPos += vec3(mo.x,mo.y,0.0);
    //vec3 ro = vec3(3.0+mo.x, 3.0+mo.y, 3.0);
    //vec3 ro = camPos;
    vec3 ta = vec3( -0.5, -0.4, 0.5 );
	
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );
    
    // ray direction
    vec3 rd = ca * normalize( vec3(p.xy,2.0) );

    // render
    #ifdef DEBUG_DIST
    vec3 col = vec3(1.0);
    vec3 t = naiveCastRay( ro, rd );
    col = col * (t.x/20.0);
    #endif
    
    #ifdef DEBUG_ITER
    vec3 col = vec3(1.0);
    vec3 t = naiveCastRay( ro, rd );
    col = col * (t.z/4000.0);
    #endif
    
    #ifndef DEBUG_DIST
    #ifndef DEBUG_ITER
    vec3 col = render(ro, rd);
    #endif
    #endif


    //col = pow( col, vec3(0.4545) ); // Gamma correct

    fragColor=vec4( col, 1.0 );
}
