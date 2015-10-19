# [CIS565 2015F] Shadertoy: Morph

**GLSL Ray Marching**

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 5**

Terry Sun; Google Chrome 45.0, Arch Linux, Intel i5-4670, GTX 750

### Live on Shadertoy

[![](img/thumb.png)](https://www.shadertoy.com/view/XISSRc)

### Acknowledgements

This Shadertoy uses *code* from the following resources:

* Morgan McGuire's
  *Numerical Methods for Ray Tracing Implicitly Defined Surfaces*.
  [PDF](http://graphics.cs.williams.edu/courses/cs371/f14/reading/implicit.pdf)
* Iñigo Quílez's [Modeling with distance functions]
  (http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm) --
  [Shadertoy] (https://www.shadertoy.com/view/Xds3zN)
* Iñigo Quílez's [Terrain Raymarching]
  (http://www.iquilezles.org/www/articles/terrainmarching/terrainmarching.htm)
* "Enhanced Sphere Tracing." Keinert, Schafer, Korndorf, Ganse, Stamminger.
  [PDF](http://erleuchtet.org/~cupe/permanent/enhanced_sphere_tracing.pdf)

### Features

#### Geometries

Rererence: iq "Raymarching Primitives", McQuire "Implicitly Defined Surfaces"

![](img/geometries.png)

#### Soft Shadows

Reference: iq "Modeling with distance functions"

![](img/debug_softshadow_noise.png)

#### Height Mapped Terrain

Reference: iq "Terrain Raymarching"

![](img/height.png)

#### Sphere Overrelaxation

Reference: McQuire "Implicitly Defined Surfaces", Keinert "Enhanced Sphere Tracing"

The number of ray march iterations displayed as grayscale, with darker areas
indicating fewer iterations before the surface is considered intersected.

![](img/iters_spheretracing.png)

![](img/iters_overrelax.png)

### Debug images

Positions

![](img/debug_distance.png)

Normals

![](img/debug_normals.png)

### Bloopers

Overrelaxation without stepping backwards:

![](img/bloop_overrelax_gloopy.png)

Naive ray marching with a step size of 0.1 (too small), got wireframes:

![](img/bloop_wireframe.png)
