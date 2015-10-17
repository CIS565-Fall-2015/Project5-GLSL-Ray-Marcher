# [CIS565 2015F] Raymarching Fun

**GLSL Ray Marching**

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 5**

* Tongbo Sui
* Tested on: Google Chrome 46.0.2490.71 on Windows 10, i5-3320M @ 2.60GHz 8GB, NVS 5400M 2GB (Personal)

### Live on Shadertoy

[![](img/thumb.png)](https://www.shadertoy.com/view/4l2SzV)

### Acknowledgements

This Shadertoy uses material from the following external resources:
* Checker board material: https://www.shadertoy.com/view/Xds3zN

Basic scene setup using {iq-prim}

### Features

* Ray marching
  * Naive ray marching {McGuire}
    * *Branch divergence*
  * Sphere tracing {McGuire}
    * *Branch divergence*

###### Naive and sphere tracing
![](img/naive-sphere.png)

* Distance estimators {McGuire}
  * Sphere
  * Box
  * Plane
  * Rounded corner box
  * Torus
  * Cylinder
  * *Branch divergence*

###### Distance estimators
![](img/estimators.png)

* Distance operators {McGuire}
  * Union
  * Transformation
  * Subtraction
  * *Branch divergence*

###### Distance operators
![](img/operators.png)

* Normal computation {McGuire}
  * *Branch divergence*

###### Normal
![](img/normal.png)

* Lambert lighting with effects (sphere tracing only)
  * Soft shadow {iq-shadow}
    * *Branch divergence*
  * Ambient occlusion {ljt-ao}
    * *Branch divergence*

###### Lighting effects

* Over-relaxation for sphere tracing {McGuire}
  * Implementation wise ineffective
    * With over-relaxation: 44.7 FPS
    * Without: 55.7 FPS
  * Iteration-wise effective
  * *Branch divergence*
  * *Possible improvement*: only estimate related surfaces, instead of all objects

###### Per fragment iteration with and without over-relaxation. Brighter means more iterations. Notice reduced iteration count on edges, and also on plane
![](img/relax-norelax.png)

* Debug views
  * Distance to surface for each pixel
  * Number of ray march iterations used for each pixel
  * Surface normal

###### Depth
![](img/depth.png)

### Analysis

* Naive ray marching vs. sphere tracing
  * Sphere: 16ms / 57.7 FPS
  * Naive: 100ms / 10.6 FPS

###### Per fragment iteration. Brighter means more iterations
![](img/iter-naive-sphere.png)

###### Time spent marching vs. shading
![](img/march-time.png)

### References

* {McGuire} Morgan McGuire, Williams College.*Numerical Methods for Ray Tracing Implicitly Defined Surfaces* (2014)
  * http://graphics.cs.williams.edu/courses/cs371/f14/reading/implicit.pdf
* {iq-prim} Iñigo Quílez.*Raymarching Primitives* (2013)
  https://www.shadertoy.com/view/Xds3zN
* {iq-shadow} Iñigo Quílez.
  * http://www.iquilezles.org/www/articles/rmshadows/rmshadows.htm
* {ljt-ao} Lukasz Jaroslaw Tomczak. *GPU Ray Marching of Distance Fields*
  *http://www2.compute.dtu.dk/pubdb/views/edoc_download.php/6392/pdf/imm6392.pdf