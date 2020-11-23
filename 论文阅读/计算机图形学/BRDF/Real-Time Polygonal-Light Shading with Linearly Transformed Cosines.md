# Real-Time Polygonal-Light Shading with Linearly Transformed Cosines

论文首页：https://eheitzresearch.wordpress.com/415-2/

论文地址：https://drive.google.com/file/d/0BzvWIdpUpRx_d09ndGVjNVJzZjA/view

实时代码地址：https://blog.selfshadow.com/sandbox/ltc.html



![image-20201123164859537](Real-Time Polygonal-Light Shading with Linearly Transformed Cosines.assets/image-20201123164859537.png)

本文证明了：将一个3×3矩阵表示的线性变换，应用于球面分布的方向向量，得到了另一个球面分布，并推导了该球面分布的闭合表达式。有了这个想法，我们可以使用任何球面分布作为基本形状，以创建一个新的球面分布族，其具有参数化的粗糙度，椭圆各向异性和偏度`skewness`

如果原始分布具有解析表达式、归一化、` integration over spherical polygons`，重要性抽样，==那么这些特性都会被线性变换后的分布所继承==。

通过设置原始分布为`clamped cosine`，得到了一个分布族，称之为线性变换余弦（==LTCs==），它为基于物理的BRDF提供了一个很好的近似，并且可以在任意球面多边形上进行积分（可解析的）。

最终效果:arrow_up:



## 1. Introduction

在本文中，作者主要对来自多边形灯光的渲染感兴趣，这意味着在球形多边形上计算BRDF的积分。尽管多边形灯光在理论上是最简单的灯光模型之一，但由于两个主要原因，它们在实时渲染中具有挑战性。

- 在球面多边形上，对参数化的球面分布进行积分，一般来说是很困难的，即使是最简单的分布。
- 