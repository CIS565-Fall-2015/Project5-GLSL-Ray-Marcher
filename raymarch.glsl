// Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.

// A list of usefull distance function to simple primitives, and an example on how to 
// do some interesting boolean operations, repetition and displacement.
//
// More info here: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

float sdPlane( vec3 p )
{
    return p.y;
}

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

//----------------------------------------------------------------------

vec2 opU( vec2 d1, vec2 d2 )
{
    return (d1.x<d2.x) ? d1 : d2;
}

//----------------------------------------------------------------------

vec2 map( in vec3 pos )
{
    vec2 res = opU( vec2( sdPlane(     pos), 1.0 ),
	            vec2( sdSphere(    pos-vec3( 0.0,0.25, 0.0), 0.25 ), 46.9 ) );
    return res;
}

vec2 castRay( in vec3 ro, in vec3 rd )
{
    float tmin = 1.0;
    float tmax = 20.0;
    
    float precis = 0.002;
    float t = tmin;
    float m = -1.0;
    for( int i=0; i<50; i++ )
    {
        vec2 res = map( ro+rd*t );
        if( res.x<precis || t>tmax ) break;
        t += res.x;
        m = res.y;
    }

    if( t>tmax ) m=-1.0;
    return vec2( t, m );
}

vec2 castRayNaive(in vec3 ro, in vec3 rd)
{
	float tmin = 1.0;
    float tmax = 20.0;
	float dt = 0.01;

	float t = tmin;
	vec2 res = map(ro+rd*t);

	//while loop is not allowed in shader toy
	for( int i=0; i<2000; i++ )
    {
		if(t >= tmax || res.x <= 0.0) break;

		t = t + dt;
		res = map(ro+rd*t);
	}

    if( t>tmax ) res.y=-1.0;
	return vec2(t,res.y);
}

vec3 render( in vec3 ro, in vec3 rd )
{ 
    vec3 col = vec3(0.8, 0.9, 1.0); // Sky color
    vec2 res = castRay(ro,rd);
    float t = res.x;
    float m = res.y;
    if( m>-0.5 )  // Ray intersects a surface
    {
        vec3 pos = ro + t*rd;
        
        // material        
        col = 0.45 + 0.3*sin( vec3(0.05,0.08,0.10)*(m-1.0) );
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
