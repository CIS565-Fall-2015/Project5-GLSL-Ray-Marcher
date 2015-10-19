# [CIS565 2015F] A Badly named Awesome Ray Marcher

**GLSL Ray Marching**

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 5**

* SANCHIT GARG
* Tested on: Google Chrome Version 45.0.2454.101 (64-bit) on
* 	Mac OSX 10.10.4, i7 @ 2.4 GHz, GT 650M 1GB (Personal Computer)

### Live on Shadertoy

<a href = "https://www.shadertoy.com/view/ll2SzK"> <img src="renders/terrainMapping.png" height="192" width="341.333333333"></a>  <a href = "https://www.shadertoy.com/view/Mt2SzK"><img src="renders/everything.png" height="192" width="341.333333333"></a>   <a href = "https://www.shadertoy.com/view/4tSSz3"><img src="renders/fractal.png" height="192" width="341.333333333"></a>   <a href = "https://www.shadertoy.com/view/4lBSz3"><img src="renders/pacman.png" height="192" width="341.333333333"></a> 

### Acknowledgements

* {McGuire}
  Morgan McGuire, Williams College.
  *Numerical Methods for Ray Tracing Implicitly Defined Surfaces* (2014).
  [PDF](http://graphics.cs.williams.edu/courses/cs371/f14/reading/implicit.pdf)
* {iq-prim}
  Iñigo Quílez.
  *Raymarching Primitives* (2013).
  [Shadertoy](https://www.shadertoy.com/view/Xds3zN)
* {iq-terr}
  Iñigo Quílez.
  *Terrain Raymarching* (2007).
  [Article](http://www.iquilezles.org/www/articles/terrainmarching/terrainmarching.htm)
* {iq-rwwtt}
  Iñigo Quílez.
  *Rendering Worlds with Two Triangles with raytracing on the GPU* (2008).
  [Slides](http://www.iquilezles.org/www/material/nvscene2008/rwwtt.pdf)
* {Ashima}
  Ashima Arts, Ian McEwan, Stefan Gustavson.
  *webgl-noise*.
  [GitHub](https://github.com/ashima/webgl-noise)

  

### What is a Ray Marcher

Ray marching is an image based volume rendering technique. With ray marching, you can compute 2D images from 3D volumetric data. For the data, I used implicit surface definitions using signes distance functions as explained in [PDF](http://graphics.cs.williams.edu/courses/cs371/f14/reading/implicit.pdf).


### Features



### Analysis

* Provide an analysis comparing naive ray marching with sphere tracing
  * In addition to FPS, implement a debug view which shows the "most expensive"
    fragments by number of iterations required for each pixel. Compare these.
* Compare time spent ray marching vs. time spent shading/lighting
  * This can be done by taking measurements with different parts of your code
    enabled (e.g. raymarching, raymarching+shadow, raymarching+shadow+AO).
  * Plot this analysis using pie charts or a 100% stacked bar chart.
* For each feature (required or extra), estimate whether branch divergence
  plays a role in its performance characteristics, and, if so, point out the
  branch in question.
  (Like in CUDA, if threads diverge within a warp, performance takes a hit.)
* For each optimization feature, compare performance with and without the
  optimization. Describe and demo the types of scenes which benefit from the
  optimization.

**Tips:**

* To avoid computing frame times given FPS, you can use the
  [stats.js bookmarklet](https://github.com/mrdoob/stats.js/#bookmarklet)
  to measure frame times in ms.


