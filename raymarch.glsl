// Some Codes are Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// More info here: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

int itrNum = 0;
float dist = 0.0;

vec3 TransP(vec3 pos, vec3 T, vec3 R, vec3 S)
{
    float c1 = cos(R.x);
    float c2 = cos(R.y);
    float c3 = cos(R.z);
    float s1 = sin(R.x);
    float s2 = sin(R.y);
    float s3 = sin(R.z);
    mat4 RotMat = mat4(	c2*c3,	c1*s3+c3*s1*s2,	s1*s3-c1*c3*s2,	0,
                      	-c2*s3,	c1*c3-s1*s2*s3,	c3*s1+c1*s2*s3,	0,
                      	s2,		-c2*s1,			c1*c2,			0,
                      	0,		0,				0,				1);
    mat4 inv_R = mat4(	c2*c3,	-c2*s3,	s2,	0,
                     	c1*s3+c3*s1*s2,	c1*c3-s1*s2*s3,-c2*s1,0,
                     	s1*s3-c1*c3*s2,c3*s1+c1*s2*s3,c1*c2,0,	
                     	0,0,0,1);
    mat4 inv_T = mat4(1,0,0,0,
                      0,1,0,0,
                      0,0,1,0,
                      -T.x,-T.y,-T.z,1);
    mat4 inv_S = mat4(1.0/S.x,0,0,0,
                      0,1.0/S.y,0,0,
                      0,0,1.0/S.z,0,
                      0,0,0,1);
    
    mat4 inv_M = inv_S*inv_R*inv_T;
    
    vec4 localPos = inv_M*vec4(pos,1.0);
    
    return localPos.xyz;
}

float sdBox(vec3 x,vec3 b)
{
    vec3 d = abs(x)-b;
    return min(max(d.z,max(d.x,d.y)),0.0)+length(max(d,vec3(0.0))); 
}

float sdSphere(vec3 p, float s)
{
	return length(p) - s;
}

float sdPlane(vec3 p)
{
	return p.y;
}

vec4 opU(vec4 d1, vec4 d2)
{
	return (d1.w<d2.w) ? d1 : d2;
}


vec4 map(in vec3 pos)
{
    vec3 Ts = vec3(0,0.5,0);
    vec3 Rs = vec3(0,0.0,0.0);
    vec3 Ss = vec3(1,1,1);
    vec4 sphere = vec4(vec3(0.8, 0, 0), Ss.x*Ss.y*Ss.z*sdSphere(TransP(pos,Ts,Rs,Ss), 0.5));
    vec4 plane = vec4(vec3(1, 1, 0.5), sdPlane(pos));
    vec4 cube = vec4(vec3(0.2,0.2,1),sdBox(TransP(pos,vec3(0.5,1,0),vec3(0),vec3(1)),vec3(0.1,0.2,0.1)));
    vec4 res = opU(sphere,plane);
	res = opU(res,cube);
    return res;
}

vec3 calcNormal( in vec3 pos )
{
    vec3 eps = vec3( 0.001, 0.0, 0.0 );
    vec3 nor = vec3(
        map(pos+eps.xyy).w - map(pos-eps.xyy).w,
        map(pos+eps.yxy).w - map(pos-eps.yxy).w,
        map(pos+eps.yyx).w - map(pos-eps.yyx).w );
    return normalize(nor);
}

vec4 castRay_Naive(in vec3 ro, in vec3 rd)
{
	float tmin = 1.0;
	float tmax = 20.0;

	float precis = 0.02;
	float t = tmin;
	vec3 m = vec3(-1, -1, -1);
	for (int i = 0; i<1000; i++)
	{
		vec4 res = map(ro + rd*t);
        dist = length(rd*t);
        
		if (res.w<precis)
		{
			//m = calcNormal(ro + rd*t);//res.xyz;
            itrNum = i;
			break;
		}
		else if (t>tmax)
		{
			m = vec3(0.8, 0.9, 1.0);
            dist = 1000.0;
            itrNum = i;
			break;
		}
		else m = vec3(0.5, 0.5, 1.0);
        
		t += precis;
	}

	if (t>tmax) t = -1.0;
	return vec4(m, t);
}

vec4 castRay_ST(in vec3 ro, in vec3 rd)
{
	float tmin = 1.0;
	float tmax = 20.0;

	float precis = 0.001;
	float t = tmin;
	vec3 m = vec3(0.7, 0.4, 0.1);
	for (int i = 0; i<100; i++)
	{
		vec4 res = map(ro + rd*t);
        dist = length(rd*t);
        
        if (res.w<precis)
        {
            itrNum = i;
            m = res.xyz;
            break;
        }
        else if(t>tmax)
        {
            m = vec3(0.8, 0.9, 1.0);
            dist = 1000.0;
            break;
        }
        else m = vec3(0.5, 0.5, 1.0);
		t += res.w;
		
        //m = calcNormal(ro + rd*t);
	}

	if (t>tmax) t = -1.0;
	return vec4(m, t);
}

vec3 render(in vec3 ro, in vec3 rd) {
	// TODO

    vec4 res = castRay_ST(ro, rd);
    //vec4 res = castRay_Naive(ro,rd);
	float t = res.w;
    vec3 col = vec3(0.8, 0.9, 1.0);
    vec3 nor = calcNormal(ro + rd*t);
	vec3 m = res.xyz;
	if (t>-0.5)  // Ray intersects a surface
	{
		// material        
		col = m;
        //col = mix( col, vec3(0.8,0.9,1.0), 1.0-exp( -0.0005*t*t ) );
        //col = nor;
        //col = 0.45 + 0.3*sin(vec3(0.05, 0.08, 0.10)*(float(itrNum) - 6.0)); 
        vec3  lig = normalize( vec3(-0.6, 0.7, -0.5) );
        //float amb = clamp( 0.5+0.5*nor.y, 0.0, 1.0 );
        float dif = clamp( dot( nor, lig ), 0.0, 1.0 );
        vec3 brdf = vec3(0.0);
        brdf += 1.20*dif*vec3(1.0,1,1);
        col = col*brdf;
        //col = vec3(1.0-dist/10.0);
    }
    

	return vec3(clamp(col, 0.0, 1.0));
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

	//col = pow(col, vec3(0.4545));

	fragColor = vec4(col, 1.0);
}
