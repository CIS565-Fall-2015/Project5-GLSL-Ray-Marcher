#define maxObj	7
#define maxDist	20.0
#define epsilon	0.00001
#define diffuseCoeff 0.5
#define ambientCoeff 0.3
#define specularCoeff 0.2
#define shadowSample 16
#define shadowScale 8.0
#define minStep 0.0001
#define step 	0.01

#define ADAPTIVE_STEP

//displaying 1.0 - t/maxdist
//#define DEBUG_DISTANCE

//displaying 1.0 - i/maxIter
//#define DEBUG_MARCHITERATION

//#define OVERRELAXATION

#ifdef FIXED_STEP
	#define maxIter 5000
#endif

#ifdef ADAPTIVE_STEP
	#define maxIter 500
#endif


struct Material{
    vec3 clr;
    float specPwr;
};

struct Object{
    Material m;

    // 0 - sphere, 1 - plane, 2 - box, 3 - roundedBox, 4 - Torus, 5 - Cylinder, 6 - Wheel
    int type;

    mat4 invT;
    float det;

    //these are properties needed for calculating SD
    float r;
    float R;
    vec3 v;
};

struct Intersection{
    Material m;
    float sd;
};

Object obj[maxObj];


//determinant from https://github.com/dsheets/gloc/blob/master/stdlib/matrix.glsl
float determinant(mat2 m) {
  return m[0][0]*m[1][1] - m[1][0]*m[0][1] ;
  }

float determinant(mat4 m) {
  mat2 a = mat2(m);
  mat2 b = mat2(m[2].xy,m[3].xy);
  mat2 c = mat2(m[0].zw,m[1].zw);
  mat2 d = mat2(m[2].zw,m[3].zw);
  float s = determinant(a);
  return s*determinant(d-(1.0/s)*c*mat2(a[1][1],-a[0][1],-a[1][0],a[0][0])*b);
}

void calcInvTAndDet(out mat4 invT, out float det, in vec3 translate, in vec3 scale){
    mat4 s = mat4(1.0);
    mat4 t = mat4(1.0);

    //translate
    t[3][0] = translate.x;
    t[3][1] = translate.y;
    t[3][2] = translate.z;

    //scale
    s[0][0] = scale.x;
    s[1][1] = scale.y;
    s[2][2] = scale.z;

    det = determinant(t * s);

    //translate
    t[3][0] = -translate.x;
    t[3][1] = -translate.y;
    t[3][2] = -translate.z;

    //scale
    s[0][0] = 1.0/scale.x;
    s[1][1] = 1.0/scale.y;
    s[2][2] = 1.0/scale.z;

    invT = s * t;
}

void initScene(){
 	//declare material & objects here
    Material rDiffuse;
    rDiffuse.clr = vec3(1.0, 0.0, 0.0);
    rDiffuse.specPwr = 0.0;

    Material gDiffuse;
    gDiffuse.clr = vec3(0.0, 1.0, 0.0);
    gDiffuse.specPwr = 10.0;

    Material shinyOrange;
    shinyOrange.clr = vec3(1.0, 0.64, 0.0);
    shinyOrange.specPwr = 300.0;

    Material wDiffuse;
    wDiffuse.clr = vec3(1.0, 1.0, 1.0);
    wDiffuse.specPwr = 0.0;

    Object plane1;
    plane1.type = 1;
    plane1.m = rDiffuse;
    plane1.v = vec3(0.0, 1.0, 0.0);
    calcInvTAndDet(plane1.invT, plane1.det, vec3(0.0), vec3(1.0));

    Object sphere1;
    sphere1.type = 0;
    sphere1.m = shinyOrange;
    sphere1.r = 0.25;
    calcInvTAndDet(sphere1.invT, sphere1.det, vec3(1.0,0.25,-1.0), vec3(1.0));

    Object box1;
    box1.type = 2;
    box1.m = gDiffuse;
    box1.v = vec3(0.5, 0.25, 0.25);
    calcInvTAndDet(box1.invT, box1.det, vec3(-1.0,0.5,-1.0), vec3(1.0));

    Object box2;
    box2.type = 3;
    box2.m = shinyOrange;
    box2.v = vec3(0.5, 0.25, 0.25);
    box2.r = 0.25;
    calcInvTAndDet(box2.invT, box2.det, vec3(-1.0,0.5,1.0), vec3(0.5));

    Object torus1;
    torus1.type = 4;
    torus1.m = shinyOrange;
    torus1.r = 0.1;
    torus1.R = 0.3;
    calcInvTAndDet(torus1.invT, torus1.det, vec3(1.0,0.3,1.0), vec3(1.0));

    Object cylinder1;
    cylinder1.type = 5;
    cylinder1.m = shinyOrange;
    cylinder1.r = 0.2;
    cylinder1.R = 0.3;
    calcInvTAndDet(cylinder1.invT, cylinder1.det, vec3(0.0,0.5,0.0), vec3(1.0));

    Object wheel1;
    wheel1.type = 6;
    wheel1.m = wDiffuse;
    wheel1.r = 0.1;
    wheel1.R = 0.2;
    calcInvTAndDet(wheel1.invT, wheel1.det, vec3(2.0,0.25,0.0), vec3(1.0));

    obj[0] = plane1;
    obj[1] = sphere1;
    obj[2] = box1;
    obj[3] = box2;
    obj[4] = torus1;
    obj[5] = cylinder1;
    obj[6] = wheel1;
}


vec3 MultiplyMat(mat4 m, vec3 v){
    return vec3(m * vec4(v, 1));
}

/////////////////////////////////////////////////////////////////////////////////////////////

float sphereDist(vec3 p, float r){
	return length(p) - r;
}

float planeDist(vec3 p, vec3 n){
	return dot(p,n);
}

float boxDist(vec3 p, vec3 b){
    vec3 d = abs(p) - b;
    return min(max(d.x,max(d.y,d.z)), 0.0) + length(max(d, 0.0));
}

float roundedBoxDist(vec3 p, vec3 b, float r){
    return length(max(abs(p)-b,0.0))-r;
}

float torusDist(vec3 p, float r, float R) {
    return length(vec2(length(p.xz) - R, p.y)) - r;
}


float cylinderDist(vec3 p, float r, float e) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, e);
    return min(max(d.x,d.y), 0.0) + length(max(d, vec2(0.0, 0.0)));
}

float length8(vec2 v) {
    v *= v; v *= v; v *= v;
    return pow(v.x + v.y, 1.0 / 8.0);
}

float wheelDist(vec3 p, float r, float R) {
    return length8(vec2(length(p.xz) - R, p.y)) - r;
}


/////////////////////////////////////////////////////////////////////////////////////////////

Intersection opUnion(Intersection a, Intersection b){
    if(a.sd < b.sd)
        return a;
  	else
        return b;
}

Intersection findClosestSD(in vec3 p){
    //union to get the result
    Intersection isx;
    isx.sd = maxDist;


    for(int i = 0; i < maxObj; i++){
		Intersection tmp;
        tmp.m = obj[i].m;

        vec3 tP = MultiplyMat(obj[i].invT, p);

        if(obj[i].type == 0)
            tmp.sd = sphereDist(tP, obj[i].r) * obj[i].det;
        else if(obj[i].type == 1)
            tmp.sd = planeDist(tP, obj[i].v) * obj[i].det;
        else if(obj[i].type == 2)
            tmp.sd = boxDist(tP, obj[i].v) * obj[i].det;
        else if(obj[i].type == 3)
            tmp.sd = roundedBoxDist(tP, obj[i].v, obj[i].r) * obj[i].det;
        else if(obj[i].type == 4)
            tmp.sd = torusDist(tP, obj[i].r, obj[i].R) * obj[i].det;
        else if(obj[i].type == 5)
            tmp.sd = cylinderDist(tP, obj[i].r, obj[i].R) * obj[i].det;
        else if(obj[i].type == 6)
            tmp.sd = wheelDist(tP, obj[i].r, obj[i].R) * obj[i].det;

        isx = opUnion(isx, tmp);
    }

    return isx;
}

vec3 getNormal(vec3 pos){
	vec3 evec = vec3( epsilon, 0.0, 0.0 );
	vec3 nor = vec3(
        	findClosestSD(pos+evec.xyy).sd,
	    	findClosestSD(pos+evec.yxy).sd,
	    	findClosestSD(pos+evec.yyx).sd);
    nor -= findClosestSD(pos).sd;
    nor /= epsilon;

	return normalize(nor);
}

//from http://www2.compute.dtu.dk/pubdb/views/edoc_download.php/6392/pdf/imm6392.pdf
float softShadow(vec3 ro, vec3 rd){
    float shadow = 1.0;
    float t = step;
    for(int i = 0; i < shadowSample; i++)
    {
		float d = findClosestSD(ro + rd*t).sd;
        if(d < epsilon) return 0.0;
        shadow = min(shadow, shadowScale*d/t);
        t += clamp(t, 0.0, 0.05);
    }
    return clamp(shadow, 0.0, 1.0);
}

//from http://www2.compute.dtu.dk/pubdb/views/edoc_download.php/6392/pdf/imm6392.pdf
float ambientOcclusion(vec3 p, vec3 n){
    float d = 0.0;
    float occlusion = 0.0;
    float denom = 0.5;

    for(int i = 0; i < 5; i++){
        float k = float(i);
		float d = findClosestSD(p + n*k).sd;
        occlusion += (k*step - d) * denom;
        denom *= 0.5;
    }
	return 1.0 - clamp(occlusion, 0.0, 1.0);
}

vec3 getColor(in vec3 p, in vec3 view, in Material m){
    vec3 lpos = vec3(2.0, 2.0, 2.0);
    vec3 lcol = vec3(1.0, 1.0, 1.0);

    vec3 n = getNormal(p);
    vec3 ldir = normalize(lpos - p);
    vec3 vdir = normalize(view - p);

    //blinn phong
    //diffuse
    float diffuse = clamp(dot(ldir, n), 0.0, 1.0);
    diffuse *= softShadow(p, ldir);
    diffuse *= ambientOcclusion(p, n);

    //specular
    float specular = 0.0;
    if(m.specPwr > 0.0){
        vec3 hdir = normalize(ldir + vdir);
        float specAngle = max(dot(hdir, n), 0.0);
        specular = pow(specAngle, m.specPwr);
    }

    return diffuseCoeff * diffuse * m.clr * lcol +
           specularCoeff * specular * lcol +
           ambientCoeff * m.clr;
}


float getStep(vec3 p){

#ifdef FIXED_STEP
    return step;
#endif

#ifdef ADAPTIVE_STEP
    return max(findClosestSD(p).sd, minStep);
#endif

}

vec3 render(in vec3 ro, in vec3 rd) {
   	float t = 0.0;
    float dt = 0.0;
    vec3 p;
    Intersection isx;

#ifdef OVERRELAXATION
    float k = 1.2;
    float prevdt = k * getStep(ro);
#endif

    initScene();

    for(int i = 0; i < maxIter; i++)
    {
        dt = getStep(p);

#ifdef OVERRELAXATION
        k = dt > prevdt ? k : 1.0;
        prevdt = k * dt;
        t += k * dt;
#endif

#ifndef OVERRELAXATION
        t += dt;
#endif

        if(t > maxDist || dt < epsilon) break;

        p = ro + (rd * t);
        isx = findClosestSD(p);
        if(isx.sd < epsilon){
#ifdef DEBUG_DISTANCE
            	return vec3(1.0 - t/maxDist);
#endif

#ifdef DEBUG_MARCHITERATION
            	return vec3(1.0 - float(i)/float(maxIter));
#endif

            return getColor(p, ro, isx.m);
        }
    }

    #ifdef DEBUG_DISTANCE
    	return vec3(0.0);
    #endif

    #ifdef DEBUG_MARCHITERATION
    	return vec3(0.0);
    #endif

    return vec3(0.8, 0.9, 1.0); // Sky color
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

    //col = pow(col, vec3(0.4545));

    fragColor = vec4(col, 1.0);
}
