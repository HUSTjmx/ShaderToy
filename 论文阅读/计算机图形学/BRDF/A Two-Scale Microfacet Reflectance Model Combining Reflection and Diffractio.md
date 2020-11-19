# A Two-Scale Microfacet Reflectance Model Combining Reflection and Diffraction

基于微面模型的方法大多数情况下，可以很好的匹配现实材质，但是有时候通过微面模型预测的结果，却与现实测量值大相径庭。本文对其进行了折射扩展，提出了一种双尺度反射模型，在较大尺度下（大于波长）使用`Cook-Torrance`模型，而在较低尺度下（约等于波长），则负责产生衍射效果。

![image-20201119155248277](A Two-Scale Microfacet Reflectance Model Combining Reflection and Diffractio.assets/image-20201119155248277.png)



## 1. INTRODUCTION

最常用的微表面模型是`Cook-Torrance`模型，它假设每一个微表面都是一个完美的反射平面，其尺寸远大于光的波长——so that the surface response is defined by optical geometry。而衍射效应则由光程长度的变化引起。这两个技术都不错，但是有时候预测的结果，却和实际相矛盾。首先，`Cook-Torrance`模型对于高光峰值波瓣能够进行很好的拟合，但有些材质，其波瓣会随着入射光的波长变化（波瓣宽度的变化）。另外一方面，衍射模型可以很好的拟合，但是需要从模型中去除对波长的依赖性，才能得到更好的拟合。因此结合两个模型，可以得到更好的拟合，但这也与物理模型相矛盾，因为单一微观几何结构不可能有两个正态分布

本文主要基于如下假设：1，在所有尺度上，都存在表面集合信息。本文则主要考虑两个尺度：`microgeometry`和`nano-geometry`。物质响应上则是：`Cook-Torrance`和`Cook-Torrance-Diffractio`，后者是`Cook-Torrance`和衍射的卷积。这个模型可以解释一些以前无法解释的现象，比如：在掠射角度下的波长依赖性。





## 2. PREVIOUS WORK

### 2.1 Microfacet Model

标准的分布模型（NDF，微平面核心），包括：Gaussian、rational fraction、Shifted-Gamma和exponential of a power function。H神认为一个好的法线分布应该是形状不变的，以适应线性变换。在微面模型中，Shadow、Masking是能量守恒的关键。H神也提出了一个多尺度模型BRDF，也是不同的尺度，但考虑的都只是反射效应。



### 2.2 Diffraction Models

衍射效应主要由表面高度的变化引起，几种模型表达了高度分布与反射率特性之间的关系：`Rayleigh-Rice vector perturbation theory`是为光滑表面和广角散射设计的；`Harvey-Shack`模型通过表面传递函数`surface transfer function`来拟合衍射；进一步扩展，得到`Krywonos`模型。在本文中，我们使用了改进的`Harvey-Shack`模型，用单个项代替积分来模拟衍射效应。



### 2.3 Comparison with Measured Reflectances

这两种模型的参数不同，对入射面的反射叶的预测也不同。结果表明，被测材料的反射波瓣形状符合衍射理论的预测，简化后的衍射模型与被测材料的反射波瓣形状拟合较好。

N神发现，哪怕模型拟合的再好，在掠射角处计算得到的结果仍与实际值有差别，而且对于高光材质，单个波瓣进行拟合是不够的，而多个波瓣在提高质量的同时，其拟合过程也变得不稳定。

B神在2016年提出的方法，将Shadow项G~1~从Smith中分离了出来。

==而对于本文最为重要的是==：H神通过进行经验方法的研究，认为反射一般由两个部分组成：广角散射导致的衍射（diffraction for wide-angle scattering），靠近镜面方向的微面反射。



## 3. BACKGROUND

对于每一个微面，其反射率是一个`Dirac delta function`，乘上一个菲涅尔项：

![image-20201119175640958](A Two-Scale Microfacet Reflectance Model Combining Reflection and Diffractio.assets/image-20201119175640958.png)

其中，F取决于材质的IOR，而折射率依赖光的波长$\lambda$。对于电解质，折射率$\eta$是一个实数，与材料内部的光速有关。对于导体（金属），$\eta$是一个虚数。所有微面之和，得到的`Cook-Torrance`模型如下：

![image-20201119180613994](A Two-Scale Microfacet Reflectance Model Combining Reflection and Diffractio.assets/image-20201119180613994.png)

在F、D、G中，唯一依赖波长的是菲涅尔项，对于非偏振光，F定义为：

![image-20201119181020576](A Two-Scale Microfacet Reflectance Model Combining Reflection and Diffractio.assets/image-20201119181020576.png)