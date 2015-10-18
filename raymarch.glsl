/*utils***********************************************************************/
mat3 eulerXYZRotationMatrix(in vec3 rotation) {
    //https://en.wikipedia.org/wiki/Euler_angles#Rotation_matrix
    mat3 eulerXYZ;
    float c1 = cos(rotation.x);
    float c2 = cos(rotation.y);
    float c3 = cos(rotation.z);
    float s1 = sin(rotation.x);
    float s2 = sin(rotation.y);
    float s3 = sin(rotation.z);

    eulerXYZ[0][0] = c2 * c3;
    eulerXYZ[0][1] = s1 * s3 + c1 * c3 * s2;
    eulerXYZ[0][2] = c3 * s1 * s2 - c1 * s3;

    eulerXYZ[1][0] = -s2;
    eulerXYZ[1][1] = c1 * c2;
    eulerXYZ[1][2] = c2 * s1;

    eulerXYZ[2][0] = c2 * c3;
    eulerXYZ[2][1] = c1 * s2 * s3 - c3 * s1;
    eulerXYZ[2][2] = c1 * c3 + s1 * s2 * s3;

    return eulerXYZ;
}

mat3 eulerZYXRotationMatrix(in vec3 rotation) {
    //https://en.wikipedia.org/wiki/Euler_angles#Rotation_matrix
    mat3 eulerZYX;
    float c1 = cos(rotation.x);
    float c2 = cos(rotation.y);
    float c3 = cos(rotation.z);
    float s1 = sin(rotation.x);
    float s2 = sin(rotation.y);
    float s3 = sin(rotation.z);
    
    eulerZYX[0][0] = c1 * c2;
    eulerZYX[0][1] = c2 * s1;
    eulerZYX[0][2] = -s2;

    eulerZYX[1][0] = c1 * s2 * s3 - c3 * s1;
    eulerZYX[1][1] = c1 * c3 + s1 * s2 * s3;
    eulerZYX[1][2] = c2 * s3;

    eulerZYX[2][0] = s1 * s3 + c1 * c3 * s2;
    eulerZYX[2][1] = c3 * s1 * s2 - c1 * s3;
    eulerZYX[2][2] = c2 * c3;
    
    return eulerZYX;
}


/*primitive distance estimators***********************************************/
// each takes in transformations and outputs the distance from the point to the
// ray in world space.

// unit sphere has radius of 1
float sphere(in vec3 point, in vec3 translation, in vec3 scale, in vec3 rotation) {
    // transform the point into local coordinates
    vec3 localPoint = point;
    localPoint -= translation; // untranslate
    localPoint = eulerZYXRotationMatrix(-1.0 * rotation) * localPoint; // unrotate
    localPoint.x /= scale.x; // unscale
    localPoint.y /= scale.y;
    localPoint.z /= scale.z;

    // compute distance from the unit sphere
    vec3 localDist = localPoint - normalize(localPoint);

    // transform into world space
    // the distance is along the vector point - center, so use that in the scaleback?
    localDist.x *= scale.x;
    localDist.y *= scale.y;
    localDist.z *= scale.z;
    return length(localDist);
}



/*****************************************************************************/

// returns the conservative distance to the nearest scene object.
// declare all scene objects in here.
float sceneGraphCheck(in vec3 point)
{
    float sphere1 = sphere(point, vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0), vec3(0.0, 0.0, 0.0));
    return sphere1;
}

// returns a t along the ray that hits the first intersection.
// uses naive stepping [McGuire 4]
vec2 castRayNaive(in vec3 rayPosition, in vec3 rayDirection)
{
    float tmin = 1.0;
    float stepSize = 0.01; // 2000 * 0.01 gives us a max distance of 20
    float epsilon = 0.002;

    float t = tmin;
    float distance = 1000.0;
    float maxedOut = 1.0; // toggle for whether the ray maxed out or not
    vec3 point = rayPosition;
    for (int i = 0; i < 2000; i++) {
        point = rayPosition + rayDirection * t;
        distance = sceneGraphCheck(point);
        t += stepSize;
        if (distance < epsilon) {
            maxedOut = -1.0;
        }
    }
    return vec2(t, maxedOut);
}

// returns a t along the ray that hits the first intersection
// uses spherical stepping [McGuire 6]
float castRaySphere(in vec3 rayPosition, in vec3 rayDirection)
{
    return -1.0;
}

vec3 render(in vec3 ro, in vec3 rd) {
    vec2 distanceMaterial = castRayNaive(ro, rd);
    if (distanceMaterial[1] < 0.0) {
        return vec3(1.0, 1.0, 1.0);
    }
    return vec3(0.0, 0.0, 0.0);  // camera ray direction debug view
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
            0.5 + 3.5 * sin(0.1 * time + 6.0 * mo.x)); // camera position
    vec3 ta = vec3(-0.5, -0.4, 0.5); // camera aim

    // camera-to-world transformation
    mat3 ca = setCamera(ro, ta, 0.0);

    // ray direction
    vec3 rd = ca * normalize(vec3(p.xy, 2.0));

    // render
    vec3 col = render(ro, rd);

    col = pow(col, vec3(0.4545));

    fragColor = vec4(col, 1.0);
}
