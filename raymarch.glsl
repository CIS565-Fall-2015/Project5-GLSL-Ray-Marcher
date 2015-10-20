#define EPSILON 0.001
#define MAX_STEPS 500
#define MAX_DISTANCE 100.0
#define DISPLACEMENT_FACTOR 5.0
#define SHADOW_SCALE 30.0

// Defined propertitres
#define NAIVE
#define LAMBERT_COLOR
#define SOFT_SHADOW
//#define STEP_COUNT_COLOR
//#define DISTANCE_COLOR

// Distance estimates for different objects
float sphereDistance(vec3 vector, float radius) {
	return length(vector) - radius;
}

float planeDistance(vec3 point, float y) {
	return point.y - y;
}

float boxDistance(vec3 point, vec3 bvec) {
	vec3 distance = abs(point) - bvec;
    return min(max(distance.x, max(distance.y, distance.z)), 0.0) + length(max(distance, 0.0));
}

float roundedBoxDistance(vec3 point) {
	return length(max(abs(point) - 1.0, 0.0)) - 0.1;
}

float torusDistance(vec3 point, float minorRadius, float majorRadius) {
	return length(vec2(length(point.xz) - minorRadius, point.y)) - majorRadius;
}

// Distance operations
float unionDistance(float distance1, float distance2) {
	return min(distance1, distance2);
}

float intersectionDistance(float distance1, float distance2) {
	return max(distance1, distance2);
}

float subtractionDistance(float distance1, float distance2) {
	return max(distance1, -distance2);
}

float displacementDistance(vec3 point) {
	return sin(DISPLACEMENT_FACTOR * point.x) * sin(DISPLACEMENT_FACTOR * point.y)
        * sin(DISPLACEMENT_FACTOR * point.z);
}

float blendDistance(float a, float b, float blendRadius) {
	float c = 1.0 * (0.5 + (b - a) * (0.5 / blendRadius));
    return (c * a + (1.0 - c) * b) - blendRadius * c * (1.0 - c);
}

float crossDistance(vec3 point, float size) {
	float v = 1.5;
    float a = boxDistance(point.xyz, vec3(size, v, v));
    float b = boxDistance(point.yzx, vec3(v, size, v));
    float c = boxDistance(point.zxy, vec3(v, v, size));
    return min(a, min(b, c));
}

// Mandelbulb fractal rendering
// https://www.shadertoy.com/view/XsXXWS
float mandelbulbDistance(vec3 point) {
	float scale = 1.0; // scale the surface brightness by this value
    float power = 8.0;
    float derivative = 1.0;
    float internalBoundingRadius = 0.72;
    vec3 temp_point = point;

    // Use a bouncing sphere to speedup the distant ray marching
    float externalBoundingRadius = 1.2;
	float r = length(point) - externalBoundingRadius;
	if (r > 1.0) {
    	return r;
    }

    // Darker the deeper we go
	for (int i = 0; i < 10; i++) {
		scale *= 0.725;
		float r = length(temp_point);

		if (r > 2.0) {
			// The point escaped, remap the scale for more brightness and return
			scale = min((scale + 0.075) * 4.1, 0.0);
			return min(length(point) - internalBoundingRadius, 0.5 * log(r) * r / derivative);
		} else {
			// Convert to polar coordinates and then rotate by the power
			float theta = acos(temp_point.z / r) * power;
			float phi   = atan(temp_point.y, temp_point.x) * power;
			float sinTheta = sin(theta);

			derivative = pow(r, power - 1.0) * power * derivative + 1.0;

			// Convert back to Cartesian coordinates and offset by original point
			temp_point = vec3(sinTheta * cos(phi), sinTheta * sin(phi), cos(theta)) * pow(r, power) + point;
		}
	}

	return EPSILON;
}

float mengerSponge(vec3 point) {
	float distance = boxDistance(point, vec3(1.0));
    float s = 0.5;

    for(int i = 0; i < 3; i++) {
    	vec3 a = mod(point * s, 2.0) - 1.0;
        s *= 5.0;
        vec3 b = 5.0 - 5.0 * abs(a); // double check
        float c = crossDistance(b, 1000.0) / s;
        distance = max(distance, -c);
    }

    return distance;
}

// Height-mapped terrain rendering
// http://www.iquilezles.org/www/articles/terrainmarching/terrainmarching.htm
float terrainDistance(vec3 point, float height, float length) {
	return point.y - height * sin(length * point.x) * cos(point.z);
}

vec3 transform(vec3 point, vec3 t, vec3 rot_axis, float angle, vec3 s) {
    // translation
	mat4 translation = mat4(
        1.0, 0.0, 0.0, 0.0,
        0.0, 1.0, 0.0, 0.0,
        0.0, 0.0, 1.0, 0.0,
        -t.x, -t.y, -t.z, 1.0);

    //rotation matrix
    rot_axis = normalize(rot_axis);
    float sin = sin(radians(-angle));
    float cos = cos(radians(-angle));

   mat4 rotation = mat4(
       (1.0 - cos) * rot_axis.x * rot_axis.x + cos, (1.0 - cos) * rot_axis.x * rot_axis.y - rot_axis.z * sin, (1.0 - cos) * rot_axis.z * rot_axis.x + rot_axis.y * sin, 0.0,
       (1.0 - cos) * rot_axis.x * rot_axis.y + rot_axis.z * sin, (1.0 - cos) * rot_axis.y * rot_axis.y + cos, (1.0 - cos) * rot_axis.y * rot_axis.z - rot_axis.x * sin, 0.0,
       (1.0 - cos) * rot_axis.z * rot_axis.x - rot_axis.y * sin, (1.0 - cos) * rot_axis.y * rot_axis.z + rot_axis.x * sin, (1.0 - cos) * rot_axis.z * rot_axis.z + cos, 0.0,
       0.0, 0.0, 0.0, 1.0);

    //scale matrix
    mat4 scale = mat4(
        1.0 / s.x, 0.0, 0.0, 0.0,
        0.0, 1.0 / s.y, 0.0, 0.0,
        0.0, 0.0, 1.0 / s.s, 0.0,
        0.0, 0.0, 0.0, 1.0);

    vec4 new_point = point.xyzz;
    new_point.w = 1.0;
    new_point = scale * rotation * translation * new_point;
    return new_point.xyz;
}

// Scene creation
float map(vec3 point) {
    float distance = 0.0;

    // add a sphere
    vec3 temp_point = transform(point, vec3(-1.5, 0.0, 0.0), vec3(1.0), 0.0, vec3(1.5));
    float sphere = sphereDistance(temp_point - vec3(1.0, 0.0, 0.0), 0.5);

    // add a plane
    float plane = planeDistance(point, -2.0);

    // Combine them
    distance = unionDistance(sphere, plane);

    // add a torus
    temp_point = transform(point, vec3(2.0, -0.5, 0.0), vec3(1.0), 0.0, vec3(0.3));
    float torus = torusDistance(temp_point, 2.0, 1.0);
    distance = unionDistance(distance, torus);

    temp_point = transform(point, vec3(-2.0, 0.5, 0.0), vec3(0.0, 1.0, 0.0), 45.0, vec3(0.5));
    float roundedBox = roundedBoxDistance(temp_point);
    distance = unionDistance(distance, roundedBox);

    //temp_point = transform(point, vec3(0.0, 0.0, 0.0), vec3(1.0), 0.0, vec3(0.5));
    //float sponge = mengerSponge(temp_point);
    //distance = unionDistance(distance, sponge);

    //temp_point = transform(point, vec3(0.0, 0.0, 0.0), vec3(1.0), 0.0, vec3(0.5));
    //float mandelbulb = mandelbulbDistance(temp_point);
    //distance = unionDistance(distance, mandelbulb);

    return distance;



	//float distance = sphereDistance(point - vec3(1.0, 0.0, 0.0), 0.5);

    //distance += displacementDistance(point);
    //distance = unionDistance(distance, min(distance, planeDistance(transform(point, vec3(0.0, 1.0, 0.0), vec3(0.0), 0.0, vec3(0.0)), -2.0)));
    //transform(point, vec3(2.0, 0.0, 0.0), vec3(0.0), 0.0, vec3(0.0))

    //distance = unionDistance(distance, );
    //torusDistance(vec3 point, float minorRadius, float majorRadius

    //distance = terrainDistance(point, 0.5, 2.5);

    //distance = distanceToSurface(point);

    //distance += roundedBoxDistance(point);
    //return distance;
}

float calculateSoftShadow(vec3 point, vec3 lightPosition) {
	float t = 2.0;
    float minT = 2.0;
    vec3 ro = point;
    vec3 rd = normalize(lightPosition - point);
    float maxT = (lightPosition.x - ro.x) / rd.x;
    float shadowColor = 1.0;

    for(int i = 0; i < MAX_STEPS; i++) {
    	//point = ro + t * rd;
        point = ro + rd * t;

        float distance = map(point);

        if(distance < EPSILON) {
        	return 0.0;
        }

        t += distance;
        shadowColor = min(shadowColor, SHADOW_SCALE * (distance / t));

        if(t > maxT) {
        	return clamp(shadowColor, 0.0, 1.0);
        }
    }

    return clamp(shadowColor, 0.0, 1.0);
}

vec3 calculateNormal(in vec3 point) {
	vec3 epsilon = vec3(EPSILON, 0.0, 0.0);
    vec3 normal = vec3(
        map(point + epsilon.xyy) - map(point - epsilon.xyy),
        map(point + epsilon.yxy) - map(point - epsilon.yxy),
        map(point + epsilon.yyx) - map(point - epsilon.yyx));
    return normalize(normal);
}

// Lambert Color
vec3 calculateLambertColor(vec3 point, vec3 ro) {
	vec3 lightPosition = vec3(6.0, 5.0, 0.0);
    vec3 lightColor = vec3(0.8);
    vec3 lightVector = normalize(lightPosition - point);

    // calculate the normal
    vec3 normal = calculateNormal(point);

    // also require naive right?
    #ifdef SOFT_SHADOW
    	float shadowColor = calculateSoftShadow(point, lightPosition);
    	return clamp(dot(normal, lightVector), 0.0, 1.0) * lightColor * (shadowColor) + 0.05;
    #else
    	return clamp(dot(normal, lightVector), 0.0, 1.0) * lightColor + 0.01;
	#endif
}

// Step count color
vec3 calculateStepCountColor(vec2 steps) {
	float t = (steps.y - steps.x) / steps.y;
    return vec3(1.0 - t, t, 0.0);
}

// Calls the different types of color calculations
vec3 calculateColor(vec3 point, vec2 distance, vec3 ro, vec2 steps) {
    #ifdef LAMBERT_COLOR
		return calculateLambertColor(point, ro);
    #endif

    // Debug colors
    #ifdef DISTANCE_COLOR
    	return vec3(abs((distance.y - distance.x) / distance.y));
    #endif

    #ifdef STEP_COUNT_COLOR
    	return calculateStepCountColor(steps);
    #endif

    return vec3(0.0);
}

// McGuire {4}
// http://graphics.cs.williams.edu/courses/cs371/f14/reading/implicit.pdf
vec3 naiveRayMarch(in vec3 ro, in vec3 rd) {
	vec3 point; //The point on the ray

    float i = 0.0;
    for(float t = 0.0; t < MAX_DISTANCE; t += 0.01) {
        i++;
    	point = ro + rd * t;

        // distance estimator goes here
        float distance = map(point);

        if(distance < EPSILON) {
        	// if valid distance return color calculation
            return calculateColor(point, vec2(t, MAX_DISTANCE), ro, vec2(i, MAX_STEPS));
        }
    }

    return vec3(0.0);
}

vec3 sphericalRayMarch(in vec3 ro, in vec3 rd) {
    float minStep = 0.01;
    float t = 0.0;

    for(int i = 0; i < MAX_STEPS; i++) {
    	vec3 point = ro + rd * t;
        float distance = map(point);

        if(distance <= EPSILON) {
        	return calculateColor(point, vec2(t, MAX_DISTANCE), ro, vec2(float(i), MAX_STEPS));
        }

        if(distance > 0.0) {
        	t += max(distance, minStep);
        }

        if(t >= MAX_DISTANCE) {
        	break;
        }
    }

    return vec3(0.0);
}

vec3 render(in vec3 ro, in vec3 rd) {
    #ifdef NAIVE
    	return naiveRayMarch(ro, rd);
    #else
    	return sphericalRayMarch(ro, rd);
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
