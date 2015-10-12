GLSL Ray Marching
=================

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 5**

* (TODO) YOUR NAME HERE
* Tested on: (TODO) Google Chrome 222.2 on
  Windows 22, i7-2222 @ 2.22GHz 22GB, GTX 222 222MB (Moore 2222 Lab)

### Live on Shadertoy (TODO)

[![](img/thumb.png)](https://www.shadertoy.com/view/TODO)

### Acknowledgements

This Shadertoy uses material from the following resources:

* TODO

### (TODO: Your README)


Instructions (delete me)
========================

This is due at midnight on the evening of **INSTRUCTOR TODO**.

**Summary:** In this project, you'll see yet another way in which GPU
parallelism can be used to render scenes. You'll write a program in the popular
online shader demo editor [Shadertoy](http://www.shadertoy.com/). Your goal
will be to make one or more interesting demos showing off different features.

Ray marching is an iterative ray casting method in which objects are
represented as implicit surfaces defined by signed distance fields (SDFs). This
method is widely used in the Shadertoy community to render complex scenes which
are defined in the fragment shader code of every pixel.

**Important Notes:**
* Even though you will be coding in Shadertoy, it is important as always to
  save versions of your code so that you do not lose progress! Commit often!
* A significant portion of this project will be in performance analysis - don't
  save it for later.

**Provided Code:**
The provided code in `raymarch.glsl` is straight from iq's Raymarching
Primitives; see {iq-prim}. It just sets up a nice starter camera.

### Features

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

**INSTRUCTOR TODO: review point values**

* (0.25pt each up to 1pts) Other basic distance estimators/operations {McGuire 7/11}
* Advanced distance estimators
  * (3pts) Terrain rendering (using naive ray marching) {iq-terr}
  * (3pts) Fractal rendering (e.g. Menger sponge, Mandelbulb {McGuire 13.1})
* Lighting effects
  * (3pts) Soft shadowing using secondary rays {iq-prim} {iq-rwwtt p55}
  * (3pts) Ambient occlusion (see 565 slides for another reference) {iq-prim}
* Optimizations (comparative analysis required!)
  * (3pts) Over-relaxation method of sphere tracing {McGuire 12.1}
  * (2pts) Analytical bounding spheres on objects in the scene {McGuire 12.2/12.3}
  * (1pts) Analytical infinite planes {McGuire 12.3}

### Analysis

* Provide an analysis comparing naive ray marching with sphere tracing
  * In addition to FPS, implement a debug view which shows the "most expensive"
    fragments by number of iterations required for each pixel. Compare these.
* Compare time spent ray marching vs. time spent shading/lighting
  * This can be done by taking measurements with different parts of your code
    enabled (e.g. raymarching, raymarching+shadow, raymarching+shadow+AO).
  * Plot this analysis using pie charts or a 100% stacked bar chart.
* For each feature, estimate whether branch divergence plays a role in its
  performance characteristics, and point out the branch in question.
  (Like in CUDA, if threads diverge within a warp, performance takes a hit.)
* For each optimization feature, compare performance with and without the
  optimization. Describe and demo the types of scenes which benefit from the
  optimization.

**Tips:**

* To avoid computing frame times given FPS, you can use the
  [stats.js bookmarklet](https://github.com/mrdoob/stats.js/#bookmarklet)
  to measure frame times in ms.

### Resources

You **must** acknowledge any resources you use, including, but not limited to,
the links below. **Do not copy non-trivial code verbatim.** Instead, use the
references to understand the methods.

For any code/material in the 565
[slides](http://cis565-fall-2015.github.io/lectures/12-Ray-Marching.pptx),
please reference the source found at the bottom of the slide.

* {McGuire}
  Morgan McGuire, Williams College.
  *Numerical Methods for Ray Tracing Implicitly Defined Surfaces* (2014).
  [PDF](http://graphics.cs.williams.edu/courses/cs371/f14/reading/implicit.pdf)
  * You may credit and use code from this reference.
* {iq-prim}
  Iñigo Quílez.
  *Raymarching Primitives* (2013).
  [Shadertoy](https://www.shadertoy.com/view/Xds3zN)
* {iq-terr}
  Iñigo Quílez.
  *Terrain Raymarching* (2007).
  [Article](http://www.iquilezles.org/www/articles/terrainmarching/terrainmarching.htm)
  * You may credit and use code from this reference.
* {iq-rwwtt}
  Iñigo Quílez.
  *Rendering Worlds with Two Triangles with raytracing on the GPU* (2008).
  [Slides](http://www.iquilezles.org/www/material/nvscene2008/rwwtt.pdf)
* {Ashima}
  Ashima Arts, Ian McEwan, Stefan Gustavson.
  *webgl-noise*.
  [GitHub](https://github.com/ashima/webgl-noise)
  * You may use this code under the MIT-expat license.


## Submit

### Post on Shadertoy

Post your shader on Shadertoy (preferably *public*, but you cannot use
*draft*). In the Shadertoy description, include the following:

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
