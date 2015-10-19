// Acknowledgements:
// Mostly from/based off of IQ's code at: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm
// https://www.shadertoy.com/view/Xds3zN

//#define DEBUG_ITER
//#define DEBUG_DIST
//#define HEIGHT_MAP

vec3 camPos = vec3(3.0,3.0,3.0);

float lengthn(vec2 x, float n){
	return pow(pow(x.x,n)+pow(x.y,n), 1.0/n);
}

float sdCylinder( vec3 p, vec3 c )
{
  return length(p.xz-c.xy)-c.z;
}

float sdCone( vec3 p, vec2 c )
{
    // c must be normalized
    c = normalize(c);
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

float sdTorus88( vec3 p, vec2 t )
{
  vec2 q = vec2(lengthn(p.xz,8.0)-t.x,p.y);
  return lengthn(q,8.0)-t.y;
}

//----------------------------------------------------------------------

// rotation code from: http://www.neilmendoza.com/glsl-rotation-about-an-arbitrary-axis/
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
    vec3 posBox = opTx(pos, vec3(0.0,1.0,0.0), 0.3, vec3(1.0,1.0,-1.0));
    //vec3 posCone = opTx(pos, vec3(0.0,0.0,0.0), 0.0, vec3(-1.0,0.7,2.0));
    
    res = opU(res, vec2(sdEllipsoid(posEllipsoid, vec3(0.2,0.4,0.2)),40.0));
    
    res = opU(res, vec2(sdTorus(pos - vec3(-1.5,0.5,0.0),vec2(0.4,0.2)), 36.0));
    res = opU(res, vec2(sdCylinder(pos - vec3(-1.0,0.0,0.0), vec3(0.01,1.0,0.2)), 26.0));
    res = opU(res, vec2(sdBox(posBox, vec3(0.2,0.2,0.2)), 10.0));
    res = opU(res, vec2(sdTorus88(pos, vec2(0.5,0.1)), 10.0));
    return res;
}

vec4 naiveCastRayHeightMap(in vec3 ro, in vec3 rd, in sampler2D iChannel){
    float tmax = 20.0;
    float tmin = 1.0;
    float dt = 0.002;
    const int max_iter = 4000;
    
    float t = tmin;
    float m = -1.0;
    
    //vec3 pos = ro + rd*t;
    vec3 pos;
    vec4 color;
    float h;
    
	int iter;
    for (int i=0; i<max_iter; i++){
        pos = ro + rd*t;
        color = texture2D(iChannel, (pos.xz + 0.7) / 6.0);
        h = 0.2989*color.r + 0.5870*color.g + 0.1140*color.b;
        h = h*0.2;

        //h = 1.0/h;
        //h = color.x
        
        if (h >= pos.y){
            m = color.x;
        	break;
        }
        t += dt;
		iter = i;
    }

    return vec4(iter,color.xyz);
}

vec3 naiveCastRay(in vec3 ro, in vec3 rd){
    float tmax = 20.0;
    float tmin = 1.0;
    float dt = 0.005;
    const int max_iter = 2000;
    
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

vec3 castRayOverRelaxation( in vec3 ro, in vec3 rd )
{
    float k = 1.4;
    float tmin = 1.0;
    float tmax = 20.0;
    
    float precis = 0.002;
    float t = tmin;
    float m = -1.0;
    int iter;
    for(int i=0; i<50; i++ )
    {
        vec2 hx = map(ro + rd*t);
        vec2 dt = k*hx;
        vec2 hy = map(ro+rd*(t+dt.x));
        
        dt = float((hy.x >= dt.x))*dt + float((1.0-float(hy.x >= dt.x)))*hx;
        
        //if(!(hy.x >= dt.x)){
        //    dt = hx;
        //}
        
        if( dt.x<precis || t>tmax ) break;
        
        t += dt.x;
        m = dt.y;
        iter = i;
    }

    if( t>tmax ) m=-1.0;
    return vec3( t, m, iter );
}

vec3 castRay( in vec3 ro, in vec3 rd )
{
    float tmin = 1.0;
    float tmax = 20.0;
    
    float precis = 0.0001;
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

float calcAmbOcc(in vec3 pos, in vec3 nor)
{
    // Heavily based on IQ's implementation
    // Takes in the surface position and normal, tries several small steps
    // along the surface normal and finds the amount occluded
    float occ = 0.0;
    float offset_amount = 1.0/100.0;
    float dec = 1.0;
    for (int i = 0; i<10; i++)
    {
        vec3 occ_pos = pos + nor*float(i)*offset_amount;
        float dist = map(occ_pos).x;
        occ += (dist-float(i)*offset_amount)*dec;
        dec *= 0.9;
    }
    return clamp(1.0+4.0*occ,0.0,1.0);
}

float softshadow( in vec3 ro, in vec3 rd )
{
    float tmin = 0.01;
    float tmax = 2.0;
	float res = 1.0;
    float t = tmin;
    for( int i=0; i<10; i++ )
    {
		float h = map( ro + rd*t ).x;
        res = min( res, h/t );
        t += clamp( h, 0.02, 0.20 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );

}

vec3 render( in vec3 ro, in vec3 rd )
{ 
    vec3 col = vec3(0.8, 0.9, 1.0); // Sky color
    //vec3 res = castRayOverRelaxation(ro,rd);
    vec3 res = castRay(ro,rd);
    //vec3 res = naiveCastRay(ro, rd);
    float t = res.x;
    float m = res.y;
    if( m>-0.5 )  // Ray intersects a surface
    {
        vec3 pos = ro + t*rd; // surface position
        vec3 nor = calcNormal( pos ); // surface normal
        vec3 light = normalize( vec3(0.6, 0.7, 0.5) ); // direction of the light
        
        // Material handling from IQ's reference
        // material        
		col = 0.45 + 0.3*sin( vec3(0.05,0.08,0.10)*(m-1.0) );

        // Diffuse shading + ambient occlusion + soft shadows  
        float diffuse = clamp( dot( nor, light ), 0.0, 1.0 );
        float occ = calcAmbOcc( pos, nor );

		float amb = clamp( nor.y, 0.0, 1.0 );
        
        diffuse *= softshadow( pos, light );

		vec3 brdf = vec3(0.0);
        brdf += diffuse;
        brdf += amb*occ;
		brdf += 0.3;
		col = col*brdf;
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
    //vec3 ro = vec3( -0.5+3.5*cos(0.1*time + 6.0*mo.x), 1.0 + 2.0*mo.y, 0.5 + 3.5*sin(0.1*time + 6.0*mo.x) );
    vec3 ro = vec3( -0.5+3.5*cos( 6.0*mo.x), 1.0 + 2.0*mo.y, 0.5 + 3.5*sin(6.0*mo.x) );
    //ro += vec3(0.0,4.0,0.0);
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
    //vec3 t = castRayOverRelaxation( ro, rd );
    vec3 t = castRay( ro, rd );
    //vec3 t = naiveCastRay( ro, rd);
    //col = col * (t.z/50.0);
    //col = col * (t.z/4000.0);
    col = col * (t.z/350.0);
    #endif
    
    #ifdef HEIGHT_MAP
    vec3 col = vec3(1.0);
    vec4 t = naiveCastRayHeightMap(ro,rd,iChannel0);
    if (t.x < 3999.0){
    	col = t.yzw;
    }
    #endif
    
    #ifndef HEIGHT_MAP
    #ifndef DEBUG_DIST
    #ifndef DEBUG_ITER
    vec3 col = render(ro, rd);
    #endif
    #endif
    #endif


    //col = pow( col, vec3(0.4545) ); // Gamma correct

    fragColor=vec4( col, 1.0 );
}
