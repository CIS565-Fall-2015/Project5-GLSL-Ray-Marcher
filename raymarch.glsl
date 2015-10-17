// Reference : https://www.shadertoy.com/view/Xds3zN

#define MAX_DIS 5.2
#define MAX_STEPS 50

//--------Color Modes----------
//#define DEPTH_COLOR
//#define STEP_COUNT_COLOR
//#define NORMAL_COLOR
#define LAMBERT_COLOR


//--------Ray Casting Modes
#define NAIVE_RAY_CAST
//#define SPHERICAL_RAY_CAST

//-------------------------------------------------------
//					Distance Estimators
//-------------------------------------------------------

float sdSphere( vec3 p, float s )
{
    return length(p)-s;
}

float sdTorus( vec3 p, vec2 t )
{
  return length( vec2(length(p.xz)-t.x,p.y) )-t.y;
}

float sdEllipsoid( in vec3 p, in vec3 r )
{
    return (length( p/r ) - 1.0) * min(min(r.x,r.y),r.z);
}

//Function to create the actual scene
float disEstimator(vec3 pt)
{
    float dis = min(sdTorus(pt-vec3(0.0), vec2(1.0, 0.1)), 
               sdSphere(pt-vec3(0.0), 0.5));
//	dis = min(sdTorus(pt-vec3(0.0), vec2(1.0, 0.1)), 
  //             sdSphere(pt-vec3(0.0), 0.5));
    
    return dis;
}

//-------------------------------------------------------
//				Color calculation functions
//-------------------------------------------------------

vec3 getNormal( in vec3 pos )
{
	vec3 eps = vec3( 0.001, 0.0, 0.0 );
	vec3 nor = vec3(
	    disEstimator(pos+eps.xyy) - disEstimator(pos-eps.xyy),
	    disEstimator(pos+eps.yxy) - disEstimator(pos-eps.yxy),
	    disEstimator(pos+eps.yyx) - disEstimator(pos-eps.yyx));
	return normalize(nor);
}

vec3 getLambertColor(vec3 pt, vec3 ro)
{
 	vec3 lightPos = vec3(5.0,5.0,0.0);
    vec3 lightCol = vec3(1.0);
    vec3 lightVector = normalize(lightPos - pt);
    
    vec3 normal = getNormal(pt);

	return clamp(dot(normal, lightVector), 0.0, 1.0) * lightCol + 0.01;
}

vec3 getStepCountColor(vec2 steps)
{
    float t = (steps.y - steps.x) / steps.y;
	vec2 c = vec2(t, 0.0);
    return vec3(1.0-t, t, 0);
}

vec3 colorCalculation(vec3 pt, vec2 dis, vec3 ro, vec2 steps)
{
    #ifdef DEPTH_COLOR
		return vec3(abs((dis.y - dis.x) / dis.y));
    #endif
    
    #ifdef STEP_COUNT_COLOR
		return getStepCountColor(steps);
	#endif
    
    #ifdef NORMAL_COLOR
        return abs(getNormal(pt));
	#endif
    
    #ifdef LAMBERT_COLOR
        return getLambertColor(pt, ro);
	#endif
    
	return vec3(0.0);
}

//-------------------------------------------------------
//				Ray Cast Functions
//-------------------------------------------------------

vec3 naiveRayCast(in vec3 ro, in vec3 rd)
{
    vec3 pt = ro;
    float i = 0.0;
    int maxSteps = 500;
	for(float t = 0.00; t < MAX_DIS; t+=0.01)
	{
        ++i;
        pt = ro + rd * t;
        
        float dis = disEstimator(pt);
        
     	if(dis < 0.0)
        {
            return colorCalculation(pt, vec2(t, MAX_DIS), ro, vec2(i, maxSteps));
        }
	}
    
    return vec3(0.0);
}

vec3 sphericalRayCast(in vec3 ro, in vec3 rd)
{
    vec3 pt = ro;
    float epsilon = 0.01;
    
    float dt = disEstimator(pt);
	float t = 0.0;
    
    for(float i = 1.0; i<50.0; i++)
	{
        pt = ro + t * rd;
        
        dt = disEstimator(pt);
        
     	if(dt < epsilon)
        {   
            return colorCalculation(pt, vec2(t, MAX_DIS), ro, vec2(i, 50));
        }
        
		t += dt;
        
        if(t > MAX_DIS)
  	    {
         	return vec3(0.0);
        }
	}
    
    return vec3(0.0);
}


//-------------------------------------------------------

vec3 render(in vec3 ro, in vec3 rd)
{
    #ifdef NAIVE_RAY_CAST
	    return naiveRayCast(ro, rd);
    #else 
        return sphericalRayCast(ro, rd);
    #endif
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