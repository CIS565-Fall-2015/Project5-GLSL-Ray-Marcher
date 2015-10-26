# GLSL Ray Marching

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 5**

* Ratchpak (Dome) Pongmongkol
* Tested on: **Google Chrome 46.0.2490.71 (64-bit)** on
  OSX El Capitan, 2.4 GHz Intel Core i7, 16 GB 1600 MHz DDR3, NVIDIA GeForce GT 650M 1024 MB (rMBP 15" 2013)

### Live on Shadertoy

<a href="https://www.shadertoy.com/view/MtSXRt"><img src=img/src.png width=50%/></a>

### Acknowledgements

This Shadertoy uses material from the following resources:

* http://www.iquilezles.org/www/material/nvscene2008/rwwtt.pdf
* http://www2.compute.dtu.dk/pubdb/views/edoc_download.php/6392/pdf/imm6392.pdf
* https://github.com/dsheets/gloc/blob/master/stdlib/matrix.glsl

### Features
- Soft Shadow
- Ambient Occlusion
- Naive ray marching (fixed step size) & Sphere tracing (step size varies based on signed distance field) 
  - Over-relaxation method of sphere tracing
- 7 distance estimators.
- Blinn phong lighting 
- Union Operator
- Transformation Operator
- Debug Views

## Performance Analysis
