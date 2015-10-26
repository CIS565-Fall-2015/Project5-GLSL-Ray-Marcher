#define maxObj	10
#define step 	0.1
#define maxDist	1e10
#define maxIter 50
#define epsilon	0.001

#define FIXED_STEP

struct Material{
    vec3 clr;
};

struct Object{
    Material m;
    float sd;
};

/////////////////////////////////////////////////////////////////////////////////////////////

float sphereDist(vec3 p, vec3 c, float r){
	return length(p-c) - r;
}

float planeDist(vec3 p, vec3 c, vec3 n){
	return dot((p-c),n);
}

Object opUnion(Object a, Object b){
    if(a.sd < b.sd)
        return a;
  	else
        return b;
}

Object intersects(in vec3 p){

    Material rDiffuse;
    rDiffuse.clr = vec3(1.0, 0.0, 0.0);

    Object plane1;
    plane1.m = rDiffuse;
    plane1.sd = planeDist(p, vec3(0.0), vec3(0.0, 1.0, 0.0));


    Object obj;
    obj.sd = -1.0;

    obj = opUnion(obj, plane1);

    return obj;
}

//from inigo quilez's code
vec3 calcNormal(in vec3 pos)
{
	vec3 eps = vec3( 0.001, 0.0, 0.0 );
	vec3 nor = vec3(
	    intersects(pos+eps.xyy).sd - intersects(pos-eps.xyy).sd,
	    intersects(pos+eps.yxy).sd - intersects(pos-eps.yxy).sd,
	    intersects(pos+eps.yyx).sd - intersects(pos-eps.yyx).sd );
	return normalize(nor);
}


vec3 getLambertClr(in vec3 p, in Material m){
    vec3 lpos = vec3(2.0, 2.0, 2.0);
    vec3 lcol = vec3(1.0, 1.0, 1.0);

    vec3 n = calcNormal(p);
    vec3 ldir = lpos - p;
    return clamp(dot(ldir, n), 0.0, 1.0) * m.clr * lcol;
}


float getStep(){
    return step;
}

vec3 render(in vec3 ro, in vec3 rd) {
   	float t = 0.0;
    vec3 p;
    Object obj;

    for(int i = 0; i < maxIter; i++)
    {
        t += getStep();
        if(t > maxDist) break;

        p = ro + (rd * t);
        obj = intersects(p);
        if(obj.sd > 0.0 && obj.sd < epsilon){
            return getLambertClr(p, obj.m);
        }
    }

    return vec3(0,0,0);
}

/////////////////////////////////////////////////////////////////////////////////////////////

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
