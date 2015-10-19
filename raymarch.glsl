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

// for generating a pseudorandom color given a point.
// from http://stackoverflow.com/questions/4200224/random-noise-functions-for-glsl
float pseudoRand(vec2 xz) {
    return fract(sin(dot(xz.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

float sinSin(vec2 xz) {
    return sin(xz[0]) * sin(xz[1]);
}

/*primitive distance estimators***********************************************/
// each takes in transformations and outputs the distance from the point to the
// primitive in world space.

// unit sphere has radius of 1
float sphere(in vec3 point, in vec3 translation, in vec3 rotation, in vec3 scale) {
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
    mat3 rotationMat = eulerZYXRotationMatrix(rotation);
    up = rotationMat * up;
    return dot(point - translation, up);
}

float cube(in vec3 point, in vec3 translation, in vec3 rotation, in vec3 scale) {
     // transform the point into local coordinates
    vec3 localPoint = point;
    localPoint -= translation; // untranslate
    localPoint = eulerZYXRotationMatrix(-1.0 * rotation) * localPoint; // unrotate
    // no unscale: we can use the scale to determine the sidelengths of the box

    vec3 firstQuadrantCorner = vec3(scale.x * 0.5, scale.y * 0.5, scale.z * 0.5);
    vec3 d = abs(localPoint) - firstQuadrantCorner;
    return min(max(max(d.x, d.y), d.z), 0.0) + length(max(d, vec3(0.0, 0.0, 0.0)));
}

float heightFunction(in vec3 point, in vec3 translation, in vec3 rotation, in vec3 scale) {
    // transform the point into local coordinates
    vec3 localPoint = point;
    localPoint -= translation; // untranslate
    localPoint = eulerZYXRotationMatrix(-1.0 * rotation) * localPoint; // unrotate
    localPoint.x /= scale.x; // unscale
    localPoint.y /= scale.y;
    localPoint.z /= scale.z;

    // compute a height value
    vec3 nearPt = localPoint;
    nearPt.y = sinSin(localPoint.xz);
    
    // get distance vector
    vec3 localDist = localPoint - nearPt;

    // scale back
    localDist.x *= scale.x;
    localDist.y *= scale.y;
    localDist.z *= scale.z;
    return length(localDist) * localDist.y / abs(localDist.y);
}

// computes the distance from point to the axis aligned cube defined by min and max.
// helper for menger sponge.
float distInCube(in vec3 point, in vec3 minCorner, in vec3 maxCorner) {
    vec3 center = (maxCorner + minCorner) / 2.0;
    vec3 Q1 = maxCorner - center;
    vec3 d = abs(point - center) - Q1;
    return min(max(max(d.x, d.y), d.z), 0.0) + length(max(d, vec3(0.0, 0.0, 0.0)));
}

// menger sponge cube of dimensions in scale of iteration depth at most 4
float fractalMenger(in vec3 point, in vec3 translation, in vec3 rotation, in vec3 scale) {
    // transform the point into local coordinates
    vec3 localPoint = point;
    localPoint -= translation; // untranslate
    localPoint = eulerZYXRotationMatrix(-1.0 * rotation) * localPoint; // unrotate

    vec3 maxCorner = vec3(scale.x * 0.5, scale.y * 0.5, scale.z * 0.5);
    vec3 minCorner = -maxCorner;

    // at each iteration, compute if the point is in any of the 20 subcubes
    // update maxCorner and minCorner.
    // if at any point it is not in a subcube, the point is not "inside" the sponge, so break.
    float currDist = 1000.0;
    for (int i = 0; i < 4; i++) {
        vec3 dimensions = (maxCorner - minCorner) / 3.0;
        vec3 currCorner = minCorner;
        // bottom 8
        /***********
        *  1 2 3  -> +x
        *  8   4  | +z
        *  7 6 5  V
        ***********/
        // 1
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

        // 2
        currCorner.x += dimensions.x;
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

        // 3
        currCorner.x += dimensions.x;
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

        // 4
        currCorner.z += dimensions.z;
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

        // 5
        currCorner.z += dimensions.z;
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

        // 6
        currCorner.x -= dimensions.x;
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

        // 7
        currCorner.x -= dimensions.x;
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

        // 8
        currCorner.z -= dimensions.z;
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

        // middle 4
        /***********
        *  1 x 2  -> +x
        *  x   x  | +z
        *  4 x 3  V
        ***********/
        currCorner.y += dimensions.y;

        // 1
        currCorner.z -= dimensions.z;
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

        // 2
        currCorner.x += dimensions.x + dimensions.x;
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

        // 3
        currCorner.z += dimensions.z + dimensions.z;
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

        // 4
        currCorner.x -= dimensions.x + dimensions.x;
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

        // top 8
        /***********
        *  1 2 3  -> +x
        *  8   4  | +z
        *  7 6 5  V
        ***********/
        currCorner.y += dimensions.y;

        // 1
        currCorner.z -= dimensions.z + dimensions.z;
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

        // 2
        currCorner.x += dimensions.x;
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

        // 3
        currCorner.x += dimensions.x;
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

        // 4
        currCorner.z += dimensions.z;
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

        // 5
        currCorner.z += dimensions.z;
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

        // 6
        currCorner.x -= dimensions.x;
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

        // 7
        currCorner.x -= dimensions.x;
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

        // 8
        currCorner.z -= dimensions.z;
        currDist = min(distInCube(localPoint, currCorner, currCorner + dimensions), currDist);

    }
    return currDist;
}

/*Operations******************************************************************/

// for getting the union of two objects. the one with the smaller distance.
vec4 unionColorDistance(vec4 d1, vec4 d2) {
    float minDistance = d2[3];
    vec3 color = d2.rgb;
    if (d1[3] < d2[3]) {
        color = d1.rgb;
        minDistance = d1[3];
    }
    return vec4(color, minDistance);
}

/*Code************************************************************************/

// returns the conservative distance to the nearest scene object.
// declare all scene objects in here.
// returns (r, g, b, distance)
vec4 sceneGraphDistanceFunction(in vec3 point)
{
    vec4 returnMe = vec4(0.0, 0.0, 0.0, 22.0);

    vec4 sphere0 = vec4(1.0, 0.0, 0.0, -1.0);
    sphere0[3] = sphere(point, vec3(0.0, 0.6, 0.0), vec3(0.0, 0.0, 0.0), vec3(0.5, 0.5, 0.5));
    returnMe = unionColorDistance(returnMe, sphere0);

    vec4 sphere1 = vec4(0.0, 1.0, 0.0, -1.0);
    sphere1[3] = sphere(point, vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), vec3(1.0, 0.1, 1.0));
    returnMe = unionColorDistance(returnMe, sphere1);

    vec4 sphere2 = vec4(1.0, 0.0, 1.0, -1.0);
    sphere2[3] = sphere(point, vec3(1.6, 0.6, 0.0), vec3(0.0, 0.0, 0.0), vec3(0.5, 0.5, 0.5));
    returnMe = unionColorDistance(returnMe, sphere2);

    vec4 cube0 = vec4(0.0, 1.0, 1.0, -1.0);
    cube0[3] = cube(point, vec3(0.8, 1.0, 0.0), vec3(0.0, 0.0, 0.0), vec3(1.0, 0.2, 2.0));
    returnMe = unionColorDistance(returnMe, cube0);

    vec4 plane0 = vec4(0.0, 0.0, 1.0, -1.0);
    plane0[3] = plane(point, vec3(0.0, 4.0, 0.0), vec3(3.14159, 0.0, 0.0));
    returnMe = unionColorDistance(returnMe, plane0);

    vec4 heightMap0 = vec4(0.6, 0.6, 0.6, -1.0);
    heightMap0[3] = heightFunction(point, vec3(0.0, -1.0, 0.0), vec3(0.0, 0.0, 0.0), vec3(1.0, 0.2, 2.0));
    returnMe = unionColorDistance(returnMe, heightMap0);

    vec4 oneThird = vec4(1.0, 1.0, 0.0, -1.0);
    //vec3 corner = vec3(0.5, 0.5, 0.5);
    //vec3 dimm = vec3(0.33333, 0.33333, 0.33333);
    //oneThird[3] = distInCube(point, corner, corner + dimm);

    //vec4 one = vec4(1.0, 1.0, 0.0, -1.0);
    //one[3] = distInCube(point, vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0));

    //returnMe = unionColorDistance(one, oneThird);

    returnMe = vec4(1.0, 1.0, 0.0, -1.0);
    returnMe[3] = fractalMenger(point, vec3(0.0, 0.0, 0.0), vec3(0.0, 0.0, 0.0), vec3(1.0, 1.0, 1.0));

    return returnMe;
}

vec3 computeNormal(in vec3 point) {
    // McGuire 8: you can totally use the gradient of the scenegraph distance function.
    vec3 epsilon = vec3(0.001, 0.0, 0.0);
    vec3 returnMe;
    returnMe.x = sceneGraphDistanceFunction(point + epsilon.xyz).a - sceneGraphDistanceFunction(point - epsilon.xyz).a;
    returnMe.y = sceneGraphDistanceFunction(point + epsilon.yxz).a - sceneGraphDistanceFunction(point - epsilon.yxz).a;
    returnMe.z = sceneGraphDistanceFunction(point + epsilon.yzx).a - sceneGraphDistanceFunction(point - epsilon.yzx).a;
    return normalize(returnMe);
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
        vec4 colorAndDistance = sceneGraphDistanceFunction(rayPosition + rayDirection * t);
        distance = colorAndDistance[3];
        t += stepSize;
        if (distance < epsilon) {
            color = colorAndDistance.rgb;
            break;
        }
    }
    return vec4(color, t);
}

// returns a t along the ray that hits the first intersection
// uses spherical stepping [McGuire 6]
vec4 castRaySphere(in vec3 rayPosition, in vec3 rayDirection)
{
    float tmin = 0.0;
    float epsilon = 0.002;
    float maxDistance = 20.0;

    float t = tmin;
    float distance;
    vec3 color = vec3(-1.0, -1.0, -1.0);
    for (int i = 0; i < 2000; i++) {
        vec4 colorAndDistance = sceneGraphDistanceFunction(rayPosition + rayDirection * t);
        distance = colorAndDistance[3];

        if (distance < epsilon) {
            color = colorAndDistance.rgb;
            break;
        }
        if (t > maxDistance) {
            break;
        }
        t += distance;
    }
    return vec4(color, t);}

vec3 lambertShade(in vec3 norm, in vec3 position, in vec3 color, in vec3 sunPosition, in vec3 sunColor) {
    vec3 shade = dot(normalize(sunPosition - position), norm) * color * sunColor;
    if (shade.x <= 0.0 && shade.y <= 0.0 && shade.z <= 0.0) {
        shade = color * sunColor * 0.02; // ambient term
    }
    return shade;
}

// takes in ray origin, ray direction, and sun position
vec3 render(in vec3 ro, in vec3 rd, in vec3 sunPosition, in vec3 sunColor) {
    vec4 materialDistance = castRayNaive(ro, rd);//castRaySphere(ro, rd);
    //vec4 materialDistance = castRaySphere(ro, rd);
    vec3 position = ro + rd * materialDistance.a;
    vec3 norm = computeNormal(position);
    if (materialDistance.r < 0.0 && materialDistance.g < 0.0 && materialDistance.b < 0.0) {
        return vec3(0.9, 1.0, 0.9);
    }
    return lambertShade(norm, position, materialDistance.rgb, sunPosition, sunColor);
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
            2.0 * mo.y,
            0.5 + 3.5 * sin(0.1 * time + 6.0 * mo.x)); // camera position
    vec3 ta = vec3(0.0, 0.0, 0.0); // camera aim

    // camera-to-world transformation
    mat3 ca = setCamera(ro, ta, 0.0);

    // ray direction
    vec3 rd = ca * normalize(vec3(p.xy, 2.0));

    // render
    vec3 col = render(ro, rd, vec3(0.0, 10.0, 0.0), vec3(1.0, 1.0, 1.0));

    col = pow(col, vec3(0.4545));

    fragColor = vec4(col, 1.0);
}
