# [CIS565 2015F] YOUR TITLE HERE

**GLSL Ray Marching**

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 5**

siqi Huang Tested on: Windows 7, Inter(R) Core(TM) i7-4870 HQ CPU@ 2.5GHz; GeForce GT 750M(GK107) (Personal Computer)

Representative Images:

![](img/AO1.png)
![](img/terrain1.png)
![](img/fractal1.png)

PART I: Different Ray Marching Methods

Sphere:

The sphere method is pretty simple, compute the distance from the ray to the center of the sphere. Normal is easy to get too.

Cube:

The cube is a little difficult than the sphere. You have to decide which direction goes to the boundary first, which means which is the biggest among xyz in absolute value. Then the normal has only 6 values.

Cylinder:

The cylinder is the combination of cube and sphere. in y direction, compute like cube, in xz direction compute like sphere.

PART II: Naive Ray Marching vs Smart Ray Marching

In naive ray marching, the move step is fixed. So the time used in linear to the iteration number.
In smart ray marching, the move step is dynamic, based on the distance to the nearest object. So the time is constant.
However, the smart time cannot do feature like height map and fractal which is talked below, naive can do both.
The performance analysis is in the last part.

