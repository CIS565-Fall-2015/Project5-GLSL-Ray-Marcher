# [CIS565 2015F] A Badly named Awesome Ray Marcher

**GLSL Ray Marching**

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 5**

* SANCHIT GARG
* Tested on: Google Chrome Version 45.0.2454.101 (64-bit) on
* 	Mac OSX 10.10.4, i7 @ 2.4 GHz, GT 650M 1GB (Personal Computer)

### Live on Shadertoy

<img src="renders/terrainMapping.png" height="144" width="256"> <img src="renders/eveything.png" height="144" width="256"> <img src="renders/fractal.png" height="144" width="256"> <img src="renders/pacman.png" height="144" width="256"> 

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

All features must be visible in your final demo for full credit.

**Required Features:**

* Two ray marching methods (comparative analysis required)
  * Naive ray marching (fixed step size) {McGuire 4}
  * Sphere tracing (step size varies based on signed distance field) {McGuire 6}
* 3 different distance estimators {McGuire 7} {iq-prim}
  * With normal computation {McGuire 8}
* One simple lighting computation (e.g. Lambert or Blinn-Phong).
* Union operator {McGuire 11.1}
  * Necessary for rendering multiple objects
* Transformation operator {McGuire 11.5}
* Debug views (preferably easily toggleable, e.g. with `#define`/`#if`)
  * Distance to surface for each pixel
  * Number of ray march iterations used for each pixel

**Extra Features:**

You must do at least 10 points worth of extra features.

* (0.25pt each, up to 1pt) Other basic distance estimators/operations {McGuire 7/11}
* Advanced distance estimators
  * (3pts) Height-mapped terrain rendering {iq-terr}
  * (3pts) Fractal rendering (e.g. Menger sponge or Mandelbulb {McGuire 13.1})
  * **Note** that these require naive ray marching, if there is no definable
    SDF. They may be optimized using bounding spheres (see below).
* Lighting effects
  * (3pts) Soft shadowing using secondary rays {iq-prim} {iq-rwwtt p55}
  * (3pts) Ambient occlusion (see 565 slides for another reference) {iq-prim}
* Optimizations (comparative analysis required!)
  * (3pts) Over-relaxation method of sphere tracing {McGuire 12.1}
  * (2pts) Analytical bounding spheres on objects in the scene {McGuire 12.2/12.3}
  * (1pts) Analytical infinite planes {McGuire 12.3}

This extra feature list is not comprehensive. If you have a particular idea
that you would like to implement, please **contact us first** (preferably on
the mailing list).

## Write-up

For each feature (required or extra), include a screenshot which clearly
shows that feature in action. Briefly describe the feature and mention which
reference(s) you used.

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

## Submit

### Post on Shadertoy

Post your shader on Shadertoy (preferably *public*; *draft* will not work).
For your title, come up with your own demo title and use the format
`[CIS565 2015F] YOUR TITLE HERE` (also add this to the top of your README).

In the Shadertoy description, include the following:

* A link to your GitHub repository with the Shadertoy code.
* **IMPORTANT:** A copy of the *Acknowledgements* section from above.
  * Remember, this is public - strangers will want to know where you got your
    material.

Add a screenshot of your result to `img/thumb.png`
(right click rendering -> Save Image As), and put the link to your
Shadertoy at the top of your README.

### Pull Request

**Even though your code is on Shadertoy, make sure it is also on GitHub!**

1. Open a GitHub pull request so that we can see that you have finished.
   The title should be "Submission: YOUR NAME".
   * **ADDITIONALLY:**
     In the body of the pull request, include a link to your repository.
2. Send an email to the TA (gmail: kainino1+cis565@) with:
   * **Subject**: in the form of `[CIS565] Project N: PENNKEY`.
   * Direct link to your pull request on GitHub.
   * Estimate the amount of time you spent on the project.
   * If there were any outstanding problems, or if you did any extra
     work, *briefly* explain.
   * Feedback on the project itself, if any.
