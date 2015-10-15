// Some Codes are Created by inigo quilez - iq/2013
// License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License.
// More info here: http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm

int itrNum = 0;

float sdSphere(vec3 p, float s)
{
	return length(p) - s;
}


vec4 map(in vec3 pos)
{
	return vec4(vec3(50, 0, 0), sdSphere(pos, 0.5));
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
		if (res.w<precis)
		{
			m = calcNormal(ro + rd*t);//res.xyz;
            itrNum = i;
			break;
		}
		else if (t>tmax)
		{
			m = vec3(0.8, 0.9, 1.0);
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

	float precis = 0.002;
	float t = tmin;
	vec3 m = vec3(-1, -1, -1);
	for (int i = 0; i<50; i++)
	{
		vec4 res = map(ro + rd*t);
        if (res.w<precis || t>tmax)
        {
            itrNum = i;
            break;
        }
		t += res.w;
		m = res.xyz;
        m = calcNormal(ro + rd*t);
	}

	if (t>tmax) t = -1.0;
	return vec4(m, t);
}

vec3 render(in vec3 ro, in vec3 rd) {
	// TODO
	vec3 col = vec3(0.8, 0.9, 1.0);
	vec4 res = castRay_ST(ro, rd);
	float t = res.w;
	vec3 m = res.xyz;
	if (t>-0.5)  // Ray intersects a surface
	{
		// material        
		//col = m;
        col = 0.45 + 0.3*sin(vec3(0.05, 0.08, 0.10)*(float(itrNum) - 6.0));
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

	col = pow(col, vec3(0.4545));

	fragColor = vec4(col, 1.0);
}
