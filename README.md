# [CIS565 2015F] Ray Marcher

**GLSL Ray Marching**

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 5**

* Megan Moore
* Tested on: **Google Chrome** on
  MacBook Pro 2.6 GHz Intel Core i5 @ 8 GB 1600 MHz DDR3, Intel Iris 1536 MB 

### Live on Shadertoy 

[![](img/bridge2.png)](https://www.shadertoy.com/view/Mt2XRV#)

[![](img/debug_image_orig.png)](https://www.shadertoy.com/view/MlSSRK)

### Acknowledgements

This Shadertoy uses material from the following resources:
Morgan McGuire, Williams College.
*Numerical Methods for Ray Tracing Implicitly Defined Surfaces* (2014).
[PDF](http://graphics.cs.williams.edu/courses/cs371/f14/reading/implicit.pdf)

Iñigo Quílez.
*Terrain Raymarching* (2007).
[Article](http://www.iquilezles.org/www/articles/terrainmarching/terrainmarching.htm)

Iñigo Quílez.
*Terrain Raymarching* (2007).
[Article](http://www.iquilezles.org/www/articles/terrainmarching/terrainmarching.htm)
  
http://www.iquilezles.org/www/articles/menger/menger.htm - mendel sponge
https://en.wikipedia.org/wiki/Blinn%E2%80%93Phong_shading_model - blinn-phong lighting
http://graphics.cs.williams.edu/courses/cs371/f14/reading/implicit.pdf - ray marching/sphere tracing
http://www2.compute.dtu.dk/pubdb/views/edoc_download.php/6392/pdf/imm6392.pdf - ambient occlusion/soft shadows
https://www.shadertoy.com/view/4t2SRz - smoke color
https://www.shadertoy.com/view/MdXGW2 - water



<img src="img/train_gif.gif" height="192" width="341.333333333">

###Final Image with debug views

<img src="img/final_scene_gif.gif" height="192" width="341.333333333"> <img src="img/debug_image_steps.png" height="192" width="341.333333333"> <img src="img/debug_image_norm.png" height="192" width="341.333333333"> <img src="img/debug_image.png" height="192" width="341.333333333">


**Summary:** In this project, you'll see yet another way in which GPU
parallelism and compute-efficiency can be used to render scenes.
I wrote a program in the popular online shader editor
[Shadertoy](http://www.shadertoy.com/).

Ray marching is an iterative ray casting method in which objects are
represented as implicit surfaces defined by signed distance functions (SDFs). This
method is widely used in the Shadertoy community to render complex scenes which
are defined in the fragment shader code executed for each pixel.

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


* (0.25pt each, up to 1pt) Other basic distance estimators/operations {McGuire 7/11}
* Advanced distance estimators
  * (3pts) Height-mapped terrain rendering {iq-terr}
  ![](img/height_map1.png)
  * Fractal rendering (e.g. Menger sponge or Mandelbulb {McGuire 13.1})
  ![](img/menger_sponge.png)
  
* Lighting effects
  * (3pts) Soft shadowing using secondary rays {iq-prim} {iq-rwwtt p55}
  ![](img/soft_shadow.png)
  * (3pts) Ambient occlusion (see 565 slides for another reference) {iq-prim}
  
<img src="img/before_amb_occ.png" height="192" width="227.5"> <img src="img/amb_occ_debug.png" height="192" width="227.5"> <img src="img/ambient_occlusion.png" height="192" width="227.5">

This extra feature list is not comprehensive. If you have a particular idea
that you would like to implement, please **contact us first** (preferably on
the mailing list).



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
