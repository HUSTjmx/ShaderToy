# Chapter 6——Texturing

In computer graphics，texturing is a process that takes a surface and modifies its appearance at each location using some image， function,，or other data source.。本章主要讨论纹理对于物体表面的影响，对于程序化纹理介绍较少。



### 1. The Texturing Pipeline

图像纹理中的像素通常称为`texel`，以区别于屏幕上的像素`pixels`。Texturing可以通过广义的纹理管道进行描述。

空间位置是Texturing process的起点，当然这里的空间位置更多指的是模型坐标系。这一点在空间中，进行投影获得一组数字，称为纹理坐标，将用于访问纹理，这个过程叫做`Texture  Mapping`，有时纹理图像本身被称为纹理贴图`texture map  `，虽然这不是严格正确的。

