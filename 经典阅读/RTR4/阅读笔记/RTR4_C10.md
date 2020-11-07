# Chapter 10——Local Illumination

承接上文，我们无需对一个频率没有界限的渲染函数进行采样，可以进行预先积分`pre-integrate`；为了形成更真实的光照模型，我们需要在表面入射方向的半球上对BRDF求积分。而在实时领域内，我们倾向于对其求一个闭合解`closed-form solutions`或拟合解。

本章致力于探索这样的解决方案。通常，为了找到便宜的解决方案，我们需要对光的发射` light emitter`，BRDF进行近似。



## Area Light Sources

光源主要由两种。第一种，` infinitesimal light sources`（punctual and directional），它的亮度由颜色c~light~表示（正对着光源的，白色的朗伯表面，对光源的反射光），它对v方向输出光的亮度的贡献为：$L_o(v)=\pi f(l_c,v)c_{light}(n\cdot l_c)$。第二种，区域光，其亮度由`radiance`$L_l$表示，它对v方向输出光的亮度的贡献为：对$f(l,v)L_l(n\cdot l)^+$进行w的积分。

<img src="RTR4_C10.assets/image-20201106161758116.png" alt="image-20201106161758116" style="zoom:67%;" />

<img src="RTR4_C10.assets/image-20201106162124280.png" alt="image-20201106162124280" style="zoom:67%;" />

在实时领域中，经常在小光源（或punctual）上应用高粗糙度来模拟区域光，然而这是有问题的——它将材质属性与特定的照明设置结合起来了（高度耦合）。

对于兰伯表面这样的特殊情况，使用点光源（替代区域光）是精确的。对于这样的表面，出射辐射率与辐照度成正比：
$$
L_o(v)=\frac{\rho _{ss}}{\pi}E \quad (10.2)
$$
<img src="RTR4_C10.assets/image-20201106164325276.png" alt="image-20201106164325276" style="zoom:80%;" />

`vector irradiance`向量辐照度的概念是有用的，来了解辐照度E` irradiance`如何表现区域光的存在。矢量辐照度是由G神提出的，称为光矢量`light vector`，并由A神进一步推广。==利用矢量辐照度，可以将任意大小和形状的区域光，准确地转换为点光源或方向光源==

Imagine a distribution of radiance L~i~ coming into a point p in space。对于每一个以入射光l为中心的，无限小的立体角dl， a vector is constructed that is aligned with l and has a length equal to the (scalar) radiance incoming from that direction times dl。最后，所有向量相加得到==矢量辐照度E==：
$$
e(p)=\int_{l\in \Theta}{L_i(p,l)ldl}\quad (10.4)
$$
