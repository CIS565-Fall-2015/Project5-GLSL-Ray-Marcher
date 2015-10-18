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
// primitive in world space.

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
    if (length(localPoint) < 1.0) return -1.0 * length(localDist);
    return length(localDist);
}

// unit plane is at 0, 0, 0 and has y up normal
float plane(in vec3 point, in vec3 translation, in vec3 rotation) {
    // plane is easier to deal with since there's no scale. yay!
    vec3 up = vec3(0.0, 1.0, 0.0);
    up = rotation * up;
    return dot(point - translation, up);
}

/*Boolean operations**********************************************************/

// for getting the union of two objects. the one with the smaller distance.
vec4 unionDistance(vec4 d1, vec4 d2) {
    float minDistance;
    vec3 color = vec3(0.0, 0.0, 0.0);
    if (d1[3] < d2[3]) {
        color = d1.rgb;
        minDistance = d1[3];
    } else {
        color = d2.rgb;
        minDistance = d2[3];
    }
    return vec4(color, minDistance);
}


/*Code************************************************************************/

// returns the conservative distance to the nearest scene object.
// declare all scene objects in here.
// returns (r, g, b, distance)
vec4 sceneGraphCheck(in vec3 point)
{
    vec4 returnMe = vec4(0.0, 0.0, 0.0, 22.0);

    vec4 sphere0 = vec4(1.0, 0.0, 0.0, -1.0);
    sphere0[3] = sphere(point, vec3(0.0, 0.6, 0.0), vec3(0.5, 0.5, 0.5), vec3(0.0, 0.0, 0.0));
    returnMe = unionDistance(returnMe, sphere0);

    vec4 sphere1 = vec4(0.0, 1.0, 0.0, -1.0);
    sphere1[3] = sphere(point, vec3(0.0, 0.0, 0.0), vec3(1.0, 0.1, 1.0), vec3(0.0, 0.0, 0.0));
    returnMe = unionDistance(returnMe, sphere1);

    vec4 sphere2 = vec4(1.0, 0.0, 1.0, -1.0);
    sphere2[3] = sphere(point, vec3(0.6, 0.6, 0.0), vec3(0.5, 0.5, 0.5), vec3(0.0, 0.0, 0.0));
    returnMe = unionDistance(returnMe, sphere2);

    vec4 plane0 = vec4(0.0, 0.0, 1.0, -1.0);
    plane0[3] = plane(point, vec3(0.0, -1.0, 0.0), vec3(0.0, 0.0, 0.0));
    //returnMe = unionDistance(returnMe, plane0);

    return returnMe;
}

// returns a t along the ray that hits the first intersection.
// uses naive stepping [McGuire 4]
// returns (r, g, b, distance), but if distance was maxed out, color is all -1
vec4 castRayNaive(in vec3 rayPosition, in vec3 rayDirection)
{
    float tmin = 1.0;
    float stepSize = 0.01; // 2000 * 0.01 + 1.0 gives us a max distance of 1.0
    float epsilon = 0.002;

    float t = tmin;
    float distance = 1000.0;
    vec3 color = vec3(-1.0, -1.0, -1.0);
    for (int i = 0; i < 2000; i++) {
        vec4 colorAndDistance = sceneGraphCheck(rayPosition + rayDirection * t);
        distance = colorAndDistance[3];
        t += stepSize;
        if (distance < epsilon) {
            color = colorAndDistance.rgb;
        }
    }
    return vec4(color, t);
}

// returns a t along the ray that hits the first intersection
// uses spherical stepping [McGuire 6]
float castRaySphere(in vec3 rayPosition, in vec3 rayDirection)
{
    return -1.0;
}

vec3 render(in vec3 ro, in vec3 rd) {
    vec4 materialDistance = castRayNaive(ro, rd);
    return materialDistance.rgb * (materialDistance.a / 22.0); 
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
