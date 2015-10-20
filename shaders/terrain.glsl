// Reference : https://www.shadertoy.com/view/Xds3zN

#define MAX_DIS 70.0
#define MAX_STEPS 100
#define EPSILON 0.001
#define SCENE_Y 10.0

//Comment SHADOW_SCALE to remove shadow
//#define SHADOW_SCALE 30.0

//----------------------Color Modes----------------------
//Uncomment the coloring mode you want to view and comment the rest

#define DEPTH_COLOR
//#define STEP_COUNT_COLOR
//#define NORMAL_COLOR
//#define LAMBERT_COLOR
#define HEIGHT_COLOR

//-------------------------------------------------------



//------------------Ray Casting Modes--------------------
#define NAIVE_RAY_CAST
//#define SPHERICAL_RAY_CAST
//-------------------------------------------------------



//-------------------------------------------------------
//					Distance Estimators
//-------------------------------------------------------


//Function to create the actual scene
vec2 disEstimator(vec3 pt, float maxHeight)
{
    vec4 color = (SCENE_Y+10.0) * texture2D( iChannel0, pt.xz / 1024.0 );
    float h = (pt.y - (color.x + color.y + color.z)/3.0) + SCENE_Y;
	return vec2(h, max(h, maxHeight));
}


//-------------------------------------------------------
//				Color calculation functions
//-------------------------------------------------------

//Function to calculate the normal
vec3 getNormal( in vec3 pos )
{
	vec3 eps = vec3( 0.001, 0.0, 0.0 );
	vec3 nor = vec3(
	    disEstimator(pos+eps.xyy, 0.0).x - disEstimator(pos-eps.xyy, 0.0).x,
	    disEstimator(pos+eps.yxy, 0.0).x - disEstimator(pos-eps.yxy, 0.0).x,
	    disEstimator(pos+eps.yyx, 0.0).x - disEstimator(pos-eps.yyx, 0.0).x);
	return normalize(nor);
}

#ifdef SHADOW_SCALE
//Function to calculate the soft shadow
float getSoftShadow(vec3 pt, vec3 lightPos)
{
    float t = 2.0;
    float minT = 2.0;
    
    vec3 rd = normalize(lightPos - pt);
    vec3 ro = pt;
    float maxT = (lightPos.x - ro.x) / rd.x;
	float shadow = 1.0;
    
	for(int i=0; i<MAX_STEPS; ++i )
    {
		pt = ro + t * rd;

        float dt = disEstimator(pt);
        
        if(dt < EPSILON)
        {
			return 0.0;
        }

        t += dt;
        shadow = min(shadow, SHADOW_SCALE * (dt / t));		
        
        if(t > maxT)
        {
          	return shadow;
        }
    }
    
    return clamp(shadow, 0.0, 1.0);
}
#endif

//Function to calculate lambert color
vec3 getLambertColor(vec3 pt, vec3 ro)
{
 	vec3 lightPos = vec3(5.0,5.0,0.0);
    vec3 lightCol = vec3(1.0);
    vec3 lightVector = normalize(lightPos - pt);
    
    vec3 normal = getNormal(pt);
    
    #ifdef SHADOW_SCALE
		float shadow = getSoftShadow(pt, lightPos);
		return clamp(dot(normal, lightVector), 0.0, 1.0) * lightCol * (shadow) + 0.01;
    #else
	    return clamp(dot(normal, lightVector), 0.0, 1.0) * lightCol + 0.01;
    #endif
}

//Function to calculate color based on number of steps
vec3 getStepCountColor(vec2 steps)
{
    float t = (steps.y - steps.x) / steps.y;
	vec2 c = vec2(t, 0.0);
    return vec3(1.0-t, t, 0);
}

vec3 getHeightColor(vec3 pt, float maxHeight)
{
    vec4 color = 0.6 * texture2D( iChannel1, pt.xz/1024.0 );
	float h = (pt.y - (color.x + color.y + color.z)/3.0) + SCENE_Y;
   
    if(h < 0.0)
    {
        h = abs(clamp(h, -0.5, 0.0)) / 0.5;
        return (vec3(0.15, 0.34, 0.9) * (1.0-h) + h * color.xyz);
    }
    
    return ( h/maxHeight * color.xyz * texture2D( iChannel2, pt.xz/1.0 ).xyz);
}

//Function to calculate colors
vec3 colorCalculation(vec3 pt, vec2 dis, vec3 ro, vec2 steps, float maxHeight)
{
    vec3 color = vec3(1.0);
    #ifdef DEPTH_COLOR
		color *= (abs((dis.y - dis.x) / dis.y));
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
    
    #ifdef HEIGHT_COLOR
        color *= getHeightColor(pt, maxHeight);
	#endif
    
	return color;
}

//-------------------------------------------------------
//				Ray Cast Functions
//-------------------------------------------------------

vec3 naiveRayCast(in vec3 ro, in vec3 rd)
{
    float maxHeight = 0.0;
    vec3 pt = ro;
    float i = 0.0;
    int maxSteps = 500;
	for(float t = 0.00; t < MAX_DIS; t+=0.01)
	{
        ++i;
        pt = ro + rd * t;
        
        vec2 dis = disEstimator(pt, maxHeight);
        maxHeight = dis.y;
            
     	if(dis.x < EPSILON)
        {
            return colorCalculation(pt, vec2(t, MAX_DIS), ro, vec2(i, maxSteps), maxHeight);
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