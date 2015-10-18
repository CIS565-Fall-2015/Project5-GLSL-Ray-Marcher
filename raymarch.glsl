
//MACRO-------------------------------------

//Scene
#define MENGER 0
#define TERRAIN 0

//Debug Render Type
#define DEBUG_DISTANCE_TO_SURFACE 0
#define DEBUG_NUM_RAY_MARCH_ITERATIONS 0



//Ray March Mode
#define NAIVE_TRACE_INTERPOLATE 0
#define NAIVE_TRACE 0
//#define SPHERE_OVER_RELAXATION 1



//Trace Parameter
#define MAX_ITERATIONS_NAIVE 2000
#define DT 0.01
#define RATIO_T 0.005

#define MAX_ITERATIONS_SPHERE 50


#define MAX_ITERATION_TIMES_DIVIDER 40


//Optimize

#define K_OVERRELAX (1.2)
#define BOUNDING_SPHERE 1


//------------------------------------------



#if DEBUG_NUM_RAY_MARCH_ITERATIONS
	int num_ray_march_interations=0;
	//int num_reverse=0;
#endif

//Distance Functions

float sdPlane( vec3 p )
{
	return p.y;
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

float sdEllipsoid( in vec3 p, in vec3 r )
{
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

float udRoundBox( vec3 p, vec3 b, float r )
{
  return length(max(abs(p)-b,0.0))-r;
}

float sdTorus( vec3 p, vec2 t )
{
  return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}

float sdHexPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
#if 0
    return max(q.z-h.y,max((q.x*0.866025+q.y*0.5),q.y)-h.x);
#else
    float d1 = q.z-h.y;
    float d2 = max((q.x*0.866025+q.y*0.5),q.y)-h.x;
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
#endif
}

float sdCapsule( vec3 p, vec3 a, vec3 b, float r )
{
	vec3 pa = p-a, ba = b-a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h ) - r;
}

float sdTriPrism( vec3 p, vec2 h )
{
    vec3 q = abs(p);
#if 0
    return max(q.z-h.y,max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5);
#else
    float d1 = q.z-h.y;
    float d2 = max(q.x*0.866025+p.y*0.5,-p.y)-h.x*0.5;
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
#endif
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

float sdConeSection( in vec3 p, in float h, in float r1, in float r2 )
{
    float d1 = -p.y - h;
    float q = p.y - h;
    float si = 0.5*(r1-r2)/h;
    float d2 = max( sqrt( dot(p.xz,p.xz)*(1.0-si*si)) + q*si - r2, q );
    return length(max(vec2(d1,d2),0.0)) + min(max(d1,d2), 0.);
}
float length2( vec2 p )
{
	return sqrt( p.x*p.x + p.y*p.y );
}

float length6( vec2 p )
{
	p = p*p*p; p = p*p;
	return pow( p.x + p.y, 1.0/6.0 );
}

float length8( vec2 p )
{
	p = p*p; p = p*p; p = p*p;
	return pow( p.x + p.y, 1.0/8.0 );
}

float sdTorus82( vec3 p, vec2 t )
{
  vec2 q = vec2(length2(p.xz)-t.x,p.y);
  return length8(q)-t.y;
}

float sdTorus88( vec3 p, vec2 t )
{
  vec2 q = vec2(length8(p.xz)-t.x,p.y);
  return length8(q)-t.y;
}

float sdCylinder6( vec3 p, vec2 h )
{
  return max( length6(p.xz)-h.x, abs(p.y)-h.y );
}




float maxcomp(in vec2 p ) { return max(p.x,p.y);}
float sdCross( in vec3 p )
{
  float da = maxcomp(abs(p.xy));
  float db = maxcomp(abs(p.yz));
  float dc = maxcomp(abs(p.zx));
  return min(da,min(db,dc))-1.0;
}

float sdMengerSponge(vec3 p)
{

	//bounding Sphere
#if BOUNDING_SPHERE
	float tSquared = dot(p,p) - 3.0;
	if(tSquared > 0.0)
	{
		return sqrt(tSquared);
	}
#endif

	float d = sdBox(p,vec3(1.0));

	float s = 1.0;
	for( int m=0; m<3; m++ )
	{
		vec3 a = mod( p*s, 2.0 )-1.0;
		s *= 3.0;
		vec3 r = 1.0 - 3.0*abs(a);
		float c = sdCross(r)/s;
		d = max(d,c);
	}
    
    
   return d;
}



//----------------------------------------------------------------------

float opS( float d1, float d2 )
{
    return max(-d2,d1);
}

vec2 opU( vec2 d1, vec2 d2 )
{
	return (d1.x<d2.x) ? d1 : d2;
}

//Repetition
vec3 opRep( vec3 p, vec3 c )
{
    return mod(p,c)-0.5*c;
}

vec3 opTwist( vec3 p )
{
    float  c = cos(10.0*p.y+10.0);
    float  s = sin(10.0*p.y+10.0);
    mat2   m = mat2(c,-s,s,c);
    return vec3(m*p.xz,p.y);
}


vec3 opTranslate(vec3 p, vec3 trans)
{
	return p - trans;
}

vec3 opRotate(vec3 p, vec3 axis, float angle)
{
	axis = normalize(axis);
    float s = sin(radians(-angle));
    float c = cos(radians(-angle));
    float oc = 1.0 - c;
	mat3 R = mat3(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c);
	
	
	return R*p;
}

vec3 opScale(vec3 p, vec3 scale)
{
	return p/scale;
}

vec3 opTransform(vec3 p, vec3 trans, vec3 axis,float angle, vec3 scale)
{
	//transform T*R*S
	//inv order S*R*T

	mat4 T = mat4(1.0,0.0,0.0,0.0
					,0.0,1.0,0.0,0.0
					,0.0,0.0,1.0,0.0
					,-trans.x,-trans.y,-trans.z,1.0);
	
	axis = normalize(axis);
    float s = sin(radians(-angle));
    float c = cos(radians(-angle));
    float oc = 1.0 - c;
	mat4 R = mat4(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s, 0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,0.0,
				0.0,0.0,0.0,1.0);

	
	mat4 S = mat4(1.0/scale.x,0.0,0.0,0.0,
					0.0,1.0/scale.y,0.0,0.0,
					0.0,0.0,1.0/scale.z,0.0,
					0.0,0.0,0.0,1.0);

	vec4 hp = p.xyzz;
	hp.w = 1.0;
	hp = S*R*T*hp;

	return hp.xyz;
}


float opIntersect(float d1, float d2)
{
	return max(d1,d2);
}

//vec3 opScale(vec3 



vec3 float2Color(float v,float vmin,float vmax)
{
	float t = 2.0 * (v-vmin)/(vmax-vmin);
	
	return vec3( 1.0 - min(1.0,max(0.0,t))
				, t>1.0 ? max(0.0,2.0-t) : t
				, min(1.0,max(0.0,t-1.0)) );

}


float opBump(float r,vec3 p, float h)
{
	return  r+h*sin(50.0*p.x)*sin(50.0*p.y)*sin(50.0*p.z);
}

//----------------------------------------------------------------------

float terrain(vec3 pos)
{
	float h = sin(pos.x)*sin(pos.z);
	return pos.y-h;
}

vec2 map( in vec3 pos )
{
    //vec2 res = opU( vec2( sdPlane(     pos), 1.0 ),
	 //           vec2( sdSphere(    pos-vec3( 0.0,0.25, 0.0), 0.25 ), 46.9 ) );
    
	//terrain
	//vec2 res= vec2(terrain(pos),1.0);
#if MENGER==0

#if TERRAIN
	vec2 res= vec2(terrain(pos),1.0);
#else
	vec2 res = vec2( sdPlane(pos), 1.0 );
#endif
	res = opU( res, vec2( sdSphere( opTranslate(pos,vec3(0.0,0.25,0.0)),0.25) , 58.0) );
	res = opU( res, vec2( sdSphere( opTransform(pos,vec3(0.0,0.85,0.0),vec3(1.0,1.0,1.0),45.0,vec3(2.0,1.0,1.0)  ) ,0.25) , 58.0) );
    
	res = opU( res, vec2( sdBox(     opTransform(pos,vec3(1.0,0.75,0.0),vec3(1.0,1.0,1.0),45.0,vec3(1.0,1.0,1.0)  ), vec3(0.25) ), 3.0 ) );
    res = opU( res, vec2( udRoundBox(  opTransform(pos,vec3(1.0,0.25,1.0),vec3(0.0,1.0,0.0),60.0,vec3(1.0,1.0,1.0)), vec3(0.15), 0.1 ), 41.0 ) );


	//simple bump
	res = opU( res, vec2( opBump(sdSphere(pos-vec3(-2.0,0.25,-1.0), 0.2 ),pos,0.01) , 
                                       65.0 ) );


	res = opU( res, vec2( opS(
		             udRoundBox(  pos-vec3(-2.0,0.2, 1.0), vec3(0.15),0.05),
	                 sdSphere(    pos-vec3(-2.0,0.2, 1.0), 0.25)), 13.0 ) );
#endif

#if MENGER
	//fractal
	vec2 res = vec2( sdPlane(pos-vec3(0.0,-1.0,0.0)), 1.0 );
	res = opU( res, vec2( sdMengerSponge(opTransform(pos,vec3(0.0,0.2,0.0),vec3(0.0,1.0,0.0),0.0,vec3(1.0,1.0,1.0)) ),46.0 ) );
#endif

    return res;
}


//const overRelaxK = 1.5;


vec2 castRay( in vec3 ro, in vec3 rd )
{

//interpolate and dynamic delta
#if NAIVE_TRACE_INTERPOLATE


	float tmin = 1.0;
    float tmax = DT * float(MAX_ITERATIONS_NAIVE);
	float dt = DT;

	float t = tmin;
	vec2 res = map(ro+rd*t);

    float lh = 0.0;
    float ly = 0.0;
	//while loop is not allowed in shader toy
	for( int i=0; i<MAX_ITERATIONS_NAIVE; i++ )
    {
#if DEBUG_NUM_RAY_MARCH_ITERATIONS
		num_ray_march_interations = num_ray_march_interations + 1;
#endif
        vec3 p = ro+rd*t;
        res = map(p);
		if(t >= tmax)
        {
            break;
        }
            
        if(res.x <= 0.0)
        {
            t = t - dt + dt *(lh-ly)/(p.y-ly-(p.y-res.x)+lh);
            break;
        }

		t = t + dt;
        
		
        
        //changing dt and interpolate
        dt = RATIO_T*t;
        lh = p.y - res.x;
        ly = p.y;

	}
	if( t>tmax ) res.y=-1.0;
	return vec2(t,res.y);

	//naive way
#elif NAIVE_TRACE


	float tmin = 1.0;
    float tmax = 20.0;
	float dt = 0.01;

	float t = tmin;
	vec2 res = map(ro+rd*t);

	//while loop is not allowed in shader toy
	for( int i=0; i<MAX_ITERATIONS_NAIVE; i++ )
    {
#if DEBUG_NUM_RAY_MARCH_ITERATIONS
		num_ray_march_interations = num_ray_march_interations + 1;
#endif
		if(t >= tmax || res.x <= 0.0) break;

		t = t + dt;
		res = map(ro+rd*t);
		
	}

    if( t>tmax ) res.y=-1.0;
	return vec2(t,res.y);
#else
	//Sphere Trace

    float tmin = 1.0;
    float tmax = 20.0;
    
    float precis = 0.002;
    float t = tmin;
    float m = -1.0;

	float this_dt = 0.0;
    float K = K_OVERRELAX;
    float last_r=0.0;
    for( int i=0; i<MAX_ITERATIONS_SPHERE; i++ )
    {
#if DEBUG_NUM_RAY_MARCH_ITERATIONS
		num_ray_march_interations = num_ray_march_interations + 1;
#endif
        vec2 res = map( ro+rd*t );
		if(K>1.01 && last_r + abs(res.x) < this_dt)
		{
			//fail
#if DEBUG_NUM_RAY_MARCH_ITERATIONS
            //num_reverse += 1;
			num_ray_march_interations = num_ray_march_interations + 1;
#endif

			t += (1.0-K) * this_dt;
			res = map( ro + rd * t);
            K=1.0;
		}
		
		if( res.x<precis || t>tmax ) break;
		
        last_r = abs(res.x);
		this_dt = K * last_r;
        t += this_dt;
        m = res.y;

    }
    if( t>tmax ) m=-1.0;
    return vec2( t, m );
#endif
}


float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
    float res = 1.0;
    float t = mint;
    for( int i=0; i<16; i++ )
    {
        float h = map( ro + rd*t ).x;
        res = min( res, 8.0*h/t );
        t += clamp( h, 0.02, 0.10 );
        if( h<0.001 || t>tmax ) break;
    }
    return clamp( res, 0.0, 1.0 );

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

#if DEBUG_DISTANCE_TO_SURFACE
	vec2 res = castRay(ro,rd);
	float tmp = res.x/20.0;
	vec3 col = vec3(tmp);
	return clamp(col,0.0,1.0);
	
#elif DEBUG_NUM_RAY_MARCH_ITERATIONS
	vec2 res = castRay(ro,rd);
	//vec3 col = vec3(float(num_ray_march_interations)/float(MAX_ITERATION_TIMES_DIVIDER),0.0,0.0);
	//return clamp(col,0.0,1.0);
	return float2Color(float(num_ray_march_interations),0.0,float(MAX_ITERATION_TIMES_DIVIDER));
    //return float2Color(float(num_reverse),0.0,10.0);
#else 
    vec3 col = vec3(0.8, 0.9, 1.0); // Sky color
    vec2 res = castRay(ro,rd);
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
        
        dif *= softshadow( pos, lig, 0.02, 2.5 );
        dom *= softshadow( pos, ref, 0.02, 2.5 );

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
#endif
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
    vec3 ta = vec3( -0.5, -0.4, 0.5 );
	
    // camera-to-world transformation
    mat3 ca = setCamera( ro, ta, 0.0 );
    
    // ray direction
    vec3 rd = ca * normalize( vec3(p.xy,2.0) );

    // render	
    vec3 col = render( ro, rd );

    col = pow( col, vec3(0.4545) ); // Gamma correct

    fragColor=vec4( col, 1.0 );
}
