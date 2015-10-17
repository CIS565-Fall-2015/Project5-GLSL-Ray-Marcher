# [CIS565 2015F] YOUR TITLE HERE

**GLSL Ray Marching**

**University of Pennsylvania, CIS 565: GPU Programming and Architecture, Project 5**

* Ziwei Zong
* Tested on: (TODO) **Google Chrome 222.2** on
  Windows 10, i7-5500 @ 2.40GHz 8GB, GTX 950M (Personal)

Overview
========================


Features
========================


Analysis
========================

#### Naive Ray Marching vs. Sphere Tracing

**Test Scene

![](img/debug_IterNum_TestScene.PNG =50x)

**Iteration Number Debug View**

|Naive Ray Marching					|Sphere Tracing
|:---------------------------------:|:---------------------------------------:
|![](img/debug_IterNum_ST.PNG =50x)	|![](img/debug_IterNum_Naive.PNG =50x)
| !!!!Analysis here ... ...

**Precision and FPS**

* Naive Ray Marching

|Max Iteration Numver|				80000			   |
|--------------------|------|--------|--------|--------|
|		Precision	 |  1e-6|  9.5e-7|  9.0e-7|  6.0e-7|
|		`FPS		 |    60|    12.5|       7|     6.8|

!!!!Analysis here ... ...

* Sphere Tracing

|--------------------|-----|-----|-----|-----|-----|
|		Precision	 |0.02 |0.015| 0.01|0.005|0.001|
|   FPS				 |   60|   52|   38|   20|  4.3|

!!!!Analysis here ... ...

#### XXX

References
========================
