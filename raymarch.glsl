// Some Codes are Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// More info here: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

#define Debug_Normal 0
#define Debug_SurfDist 0
#define Debug_iterNum 0
#define NaiveMarch 0
#define SoftShadow 1
#define showMS 1
#define HeightMap 0		//height: iChannel0
#define AO_Test 0
#define withAO 0

const int Iter_Naive = 2000;
const int Iter_ST =80000;
const int leve_MergeSponge = 4;
float pre_naive = 0.01;
float pre_ST = 5.0e-4;//0.0000006;
    
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

float sdPlane_height(vec3 p,float s,float repeat)
{
	return p.y - s*length(texture2D( iChannel0, repeat*p.xz, 0.0 ).xyz);
}
/*
float sdBox(vec3 p,vec3 s)
{
    vec3 d = abs(p)-s;
    return length(max(d,vec3(0.0)));
}*/

float sdBox(vec3 p,vec3 s,float r)
{
    vec3 d = abs(p)-s;
    return length(max(d,vec3(0.0)))-r;
}

float sdCylinder(vec3 p,float h, float r)
{
    return max( length(vec2(p.x,p.z))-r,max(abs(p.y)-h,0.0)); 
}

float sdCylinderRing(vec3 p,float h, float ro,float ri)
{
    float r = length(vec2(p.x,p.z));
    float dxz = r-ro;
    dxz = max(dxz, ri-r);
    
    return max( dxz,max(abs(p.y)-h,0.0)); 
}

float sdSphere(vec3 p, float r)
{
	return length(p) - r;
}

float sdPlane(vec3 p)
{
	return p.y;
}

vec4 MergeSponge(float boundDist,vec3 pos)
{  
    float s = 1.0;
    vec3 col = vec3(1.0,0.1,0.2);
    for(int m=0;m<leve_MergeSponge;m++)
    {
        //vec3 a = abs(mod((pos)*s, 2.0)-1.0)-0.5;
        //vec3 a = abs(mod((pos)*s, 2.0))-vec3(0.5);
        vec3 a = abs(mod(pos*s,2.0)-1.0)-(1.0/3.0)*2.0;
        float dx = min(a.x,a.y);
        float dy = min(a.y,a.z);
        float dz = min(a.z,a.x);
        
        s*=3.0;
        
        float c = max(dx,max(dy,dz))/s;

        if(c>boundDist)
        {
            col.r*=0.5;
            col.g*=2.4;
            col.b*=2.6;
            boundDist = c;
        }	        
    }
    return vec4(clamp(col,0.01,1.0),boundDist);
}

vec4 opU(vec4 d1, vec4 d2)
{
	return (d1.w<d2.w) ? d1 : d2;
}


vec4 map(in vec3 pos)
{

#if HeightMap
    vec4 plane = vec4(vec3(0.6,0.6,0.6),sdPlane_height(pos,0.2,0.1));
#else
    vec4 plane = vec4(vec3(float(floor(mod(pos.x*2.0,2.0))==floor(mod(pos.z*2.0,2.0)))*0.4+0.5), sdPlane(pos));
#endif
    
#if AO_Test
    vec4 rCube1 = vec4(vec3(0.95,0.95,0.9), sdBox(TransP(pos,vec3(0.0,0.05,0.0),vec3(0),vec3(2.0)),vec3(0.5,0.1,0.5),0.05));
    vec4 rCube2 = vec4(vec3(0.95,0.95,0.9), sdBox(TransP(pos,vec3(0.0,0.35,0.0),vec3(0),vec3(2.0)),vec3(0.25,0.1,0.25),0.05));
    vec4 sphere1 = vec4(vec3(0.95,0.95,0.9), sdSphere(TransP(pos,vec3(0.0,0.9,0.0),vec3(0),vec3(2.0)),0.15));
  
    vec4 res = opU(rCube1,rCube2);
    res = opU(res,sphere1);
    res = opU(res,plane);
        
#else
    vec3 Ts = vec3(0,0.2,-1.2);
    vec3 Rs = vec3(0.0,0.4,0.0);
    vec3 Ss = vec3(1,1,1);
    vec4 sphere = vec4(vec3(1.0,1.0 ,0.55), Ss.x*Ss.y*Ss.z*sdSphere(TransP(pos,Ts,Rs,Ss), 0.3));
    vec4 cylinder = vec4(vec3(1.5,0.9,0.8),sdCylinder(TransP(pos,vec3(-1.2,0.2,0),vec3(-0.3,0.0,0.3),vec3(1)),0.2,0.2));
    vec4 cylRing = vec4(vec3(0.98,0.5,0.75),sdCylinderRing(TransP(pos,vec3(1.0,0.4,-0.8),vec3(1.5,0.0,0.4),vec3(1)),0.1,0.3,0.25));
    vec4 roundCube = vec4(vec3(0.7,0.5,1),sdBox(TransP(pos,vec3(1.0,0.4,-0.8),vec3(1.2,0.72,1.0),vec3(1)),vec3(0.03,0.33,0.03),0.06));
    vec4 cube = vec4(vec3(0.3,0.75,1),sdBox(TransP(pos,vec3(-0.6,0.19,-0.6),Rs,vec3(1)),vec3(0.2,0.2,0.2),0.0));

//MS.rgb*=5.0;
    
   vec4 res = opU(sphere,plane);
	res = opU(res,cube);
    res = opU(res,cylinder);
    res = opU(res,cylRing);
    res = opU(res,roundCube);
    
#endif

#if showMS
    float sc = 0.6;
    float sc3 = sc*sc*sc;
    vec3 lclP = TransP(pos,vec3(0.0,1.0,0.0),vec3(0.3,0.2,0.0),vec3(sc));
    vec4 bound = vec4(vec3(0.5,0.6,1),sc3*sdBox(lclP,vec3(1.0,1.0,1.0),0.05));
    //vec4 bound = vec4(vec3(0.5,0.6,1),sdSphere(TransP(pos,vec3(0.0,0.0,0),vec3(0),vec3(1)),2.0));
    vec4 MS = MergeSponge(bound.w,lclP);
    res = opU(res,MS);
   // res = opU(res,cone);
#endif
    return res;
}

vec3 calcNormal(vec3 pos )
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

	float t = tmin;
	vec3 m = vec3(-1, -1, -1);
	for (int i = 0; i<Iter_Naive; i++)
	{
		vec4 res = map(ro + rd*t);
        dist = length(rd*t);
        m = res.xyz;
		if (res.w<pre_naive)
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
        
		t += pre_naive;
	}

	if (t>tmax) t = -1.0;
	return vec4(m, t);
}

vec4 castRay_ST(in vec3 ro, in vec3 rd)
{
	float tmin = 1.0;
	float tmax = 20.0;

	float t = tmin;
	vec3 m = vec3(0.7, 0.4, 0.1);
	for (int i = 0; i<Iter_ST; i++)
	{
		vec4 res = map(ro + rd*t);
        dist = length(rd*t);
        
        if (res.w<pre_ST)
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

float Shadow( vec3 ro, vec3 rd )
{

    float res = 1.0; 
    float t = 0.02;
    rd = normalize(rd);
#if SoftShadow	//soft shadow
    //rd = rd-ro;
    bool ifBreak = false;
    for( int i=0; i<40; i++ )
    {
		float dist = map( ro + rd*t ).w;
        res = min( res, 8.0*dist/t );
        if(dist<0.0001||t>10.0)
        {
            ifBreak = true;
            itrNum += i;
            break;
        }      
        //t+=
        t += clamp(dist,0.0,0.05);
    }
    if(!ifBreak) itrNum+=40;
#else   //sharp shadow   
    vec3 d = rd;//+vec3(0.0,0.0,0.0)-ro;
    for( int i=0; i<40; i++ )
    {
        float dist = map(ro+d*t).w;
        res = dist;
        
        t+=dist;//clamp( dist, 0.0002, 0.005 );
        if(dist<0.002||t>10.0) break;
    }
#endif
    return clamp( res, 0.2, 1.0 );

}

float calcAO(vec3 p,vec3 nor)
{
    float ao = 0.0;
    float scale = 1.0;
    for(int i=0;i<5;i++)
    {
        float dirScale = 0.01+0.03*float(i);
        vec3 stepP = p+nor*dirScale;
        float dist = map(stepP).w;
        ao += -(dist-dirScale)*scale;
        scale*=0.75;
    }
#if withAO
    return clamp(1.0-5.5*ao,0.0,1.0);
#endif
    return 1.0;
}

vec3 render(in vec3 ro, in vec3 rd) {
	// TODO
    vec3 col = vec3(0.8, 0.9, 1.0);
    float itrTotal = 1.0;
    
#if NaiveMarch
    itrTotal = float(Iter_Naive)/3.0;
    vec4 res = castRay_Naive(ro,rd);
#elif HeightMap
    itrTotal = float(Iter_Naive)/3.0;
    vec4 res = castRay_Naive(ro,rd);
#else
    itrTotal = float(Iter_Naive)/3.0;
    vec4 res = castRay_ST(ro, rd);
#endif
    ///*
	float t = res.w;    
    vec3 nor = calcNormal(ro + rd*t);
	vec3 m = res.xyz;
	if (t>-0.5)  // Ray intersects a surface
	{ 
		col = m;
        vec3  light = normalize( vec3(-0.6, 0.7, -0.5) );
        float shadow = Shadow(ro+t*rd,light);
        float diffuse = clamp( dot( nor, light ), 0.0, 1.0 );
        float ambient = clamp(dot(nor,normalize(-rd)),0.0,1.0)*calcAO(ro+t*rd,nor);
        diffuse*=shadow;
        vec3 brdf =  (0.2*ambient + 0.9*diffuse)*vec3(1.0,1,1);
        col = col*brdf;
#if Debug_Normal
        col = nor;
#elif Debug_SurfDist
        col = vec3(1.0-dist/8.0);
#elif Debug_iterNum
        //col = vec3(1.0-float(itrNum)/40.0);
        col = vec3(1.2-float(itrNum)*2.0/float(itrTotal),abs(0.2-float(itrNum)*1.1/float(itrTotal)),1.0);
#endif
        
    }//*/
    
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
	//vec3 col = vec3 (0.0,0.0,0.0);
    vec3 col = render(ro, rd);

	//col = pow(col, vec3(0.4545));

	fragColor = vec4(col, 1.0);
}
