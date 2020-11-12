# Chapter 10——Local Illumination

承接上文，我们无需对一个频率没有界限的渲染函数进行采样，可以进行预先积分`pre-integrate`；为了形成更真实的光照模型，我们需要在表面入射方向的半球上对BRDF求积分。而在实时领域内，我们倾向于对其求一个闭合解`closed-form solutions`或拟合解。

本章致力于探索这样的解决方案。通常，为了找到便宜的解决方案，我们需要对光的发射` light emitter`，BRDF进行近似。



## 1. Area Light Sources

光源主要由两种。第一种，` infinitesimal light sources`（punctual and directional），它的亮度由颜色c~light~表示（正对着光源的，白色的朗伯表面，对光源的反射光），它对v方向输出光的亮度的贡献为：$L_o(v)=\pi f(l_c,v)c_{light}(n\cdot l_c)$。第二种，区域光，其亮度由`radiance`$L_l$表示，它对v方向输出光的亮度的贡献为：对$f(l,v)L_l(n\cdot l)^+$进行w的积分。

<img src="RTR4_C10.assets/image-20201106161758116.png" alt="image-20201106161758116" style="zoom:67%;" />

<img src="RTR4_C10.assets/image-20201106162124280.png" alt="image-20201106162124280" style="zoom:67%;" />

==在实时领域中，经常在小光源（或punctual）上应用高粗糙度来模拟区域光，然而这是有问题的——它将材质属性与特定的照明设置结合起来了（高度耦合）==。

对于兰伯表面这样的特殊情况，使用点光源（替代区域光）是精确的。对于这样的表面，出射辐射率与辐照度成正比：
$$
L_o(v)=\frac{\rho _{ss}}{\pi}E \quad (10.2)
$$
<img src="RTR4_C10.assets/image-20201106164325276.png" alt="image-20201106164325276" style="zoom:80%;" />

<span style="color:green;font-size:1.3rem">向量辐照度</span>：`vector irradiance`向量辐照度的概念是有用的，来了解辐照度E` irradiance`如何表现区域光的存在。向量辐照度是由G神提出的，称为光矢量`light vector`，并由A神进一步推广。==利用向量辐照度，可以将任意大小和形状的区域光，准确地转换为点光源或方向光源==

Imagine a distribution of radiance L~i~ coming into a point p in space。对于每一个以入射光l为中心的，无限小的立体角dl， a vector is constructed that is aligned with l and has a length equal to the (scalar) radiance incoming from that direction times dl。最后，所有向量相加得到==矢量辐照度E==：
$$
e(p)=\int_{l\in \Theta}{L_i(p,l)ldl}\quad (10.4)
$$

通过点积，向量辐照度可以用来计算，通过点p的、任意朝向的平面的<span style="color: red">净辐照度</span>`net irradiance`:arrow_down:
$$
E(p,n)-E(p,-n)=n\cdot e(p)\quad (10.5)
$$
其中，n就是平面的法线。净辐照度对于渲染是没有用的。而大多数情况下（p和-n间的夹角大于90^o^），$E(p.-n)=0$，所以：
$$
E(p,n)=n\cdot e(p) \quad (10.6)
$$
彩色光在所有点上通常具有相同的相对光谱分布，这意味着我们可以将L~i~分解为颜色$c^,$和与波长无关的辐射分布$L_i^,$（10.7）

<img src="RTR4_C10.assets/image-20201109095708254.png" alt="image-20201109095708254" style="zoom:67%;" />

我们现在可以==将任意形状和大小的面积光源转换为方向光源，并且没有引入任何误差==。一个简单的例子：对于一个球形光（中心在$p_l$，半径是$r_l$，球上任意一点的辐射率是$L_l$），则可转化如下：（10.8）

<img src="RTR4_C10.assets/image-20201109100031169.png" alt="image-20201109100031169" style="zoom:67%;" />

<span style="color:green;font-size:1.3rem">区域光的近似</span>：对于理想的郎伯平面，可以使用一个不基于物理，但有效的方法来近似区域光（之前的Fig 4）：`wrap lighting`。寒霜的一个实现如下：
$$
E=\pi c_{light}(\frac{(n\cdot l)+k_{wap}}{1+k_{wap}})^+ \quad (10.9)
$$
另一个简单的形式：
$$
E=\pi c_{light}(\frac{1+(n\cdot l)}{2})\quad(10.10)
$$

###  1.1 Glossy Materials

在光滑平面`Glossy surfaces`上，区域光的主要特征是高光，且高光的大小和形状，近似等于区域光（当然，边缘模糊）。（下图：左为修改的Phong模型，右为未修改的）

<img src="RTR4_C10.assets/image-20201109103508625.png" alt="image-20201109103508625" style="zoom:80%;" />

在实时渲染中，大多数区域光的模拟，都是使用对一个`Punctual Light`进行设置，来模拟其效果。

<span style="color:green;font-size:1.3rem">粗糙度重映射</span>：最早的一个近似是虚幻中使用的`Mittring’s roughness modification`。基本思想：

+ 1，首先找到一个锥体，包含大多数入射到表面采样半球的辐照度；
+ 2，然后我们在镜面波瓣的周围，拟合一个类似的圆锥，包含大部分"BRDF":arrow_down:；
+ 3，这样做之后，我们可以通过找到一个具有不同粗糙度的BRDF波瓣，来近似光源和材料BRDF之间的卷积，该波瓣有一个相应的圆锥，其`solid angle `= 光源波瓣角 + 材料波瓣角。

<img src="RTR4_C10.assets/image-20201109104732202.png" alt="image-20201109104732202" style="zoom: 67%;" />

基于这个原理，K神在GGX BRDF和球形区域光的情况下，对粗糙度进行了简单的调整：

<img src="RTR4_C10.assets/image-20201109105442830.png" alt="image-20201109105442830" style="zoom:67%;" />

这种近似的效果相当好，而且便宜，但==不适用于像镜子一样的材料==。这是因为镜面波瓣总是平滑的，不能模拟：区域光源在表面上的强烈反射，引起的高光（因为光滑，所以尾部信息不会丢失，所以这种平面能够反映波瓣的尾部）。而且，大多数微面BRDF模型的高光波瓣，都有一个较长的尾部，这使得==粗糙度重映射==`roughness remapping`的效果较差（毕竟用锥体进行了裁剪，失去了尾部的信息，如下图中:arrow_down:）。

<img src="RTR4_C10.assets/image-20201109110024736.png" alt="image-20201109110024736" style="zoom:67%;" />

<span style="color:green;font-size:1.3rem">most representative point</span>：其基本思想是——使用一个基于渲染点而改变的光矢量`light vector`，来表示区域光。修改光矢量，使其朝向区域光的表面上，产生最大能量贡献的点（上图右:arrow_up:）。这个点在哪呢？

+ P神的想法是产生最小反射角的点（反射光和光表面法线的夹角）；
+ K神进行了优化。以视点向量，计算点P的“反射光”，在这条射线上找到离球形光源最近的点P~cr~，再在球形表面上找到离P~cr~最近的点P~cs~（如下图:arrow_down:）。

<img src="RTR4_C10.assets/image-20201109111950715.png" alt="image-20201109111950715" style="zoom:67%;" />

这种方法已经可以用于各种各样的几何光，所以了解他们的理论背景是很重要的。这种方法的思想类似==蒙特卡洛重要性采样==。而一个更加便利的优化是：视线的反射光，打中光源，才考虑调整光矢量，否则就直接将光源视作点光源。（具体的，特别是基于定积分的`mean value theorem`的讨论，见书 P 385，这几段没怎么看懂）

<img src="RTR4_C10.assets/image-20201112194821769.png" alt="image-20201112194821769" style="zoom:50%;" />

> 关于中值定理这段，我的个人理解是：我们在最近点周围进行重要性采样，结果需要进行积分（一开始，我还以为是只采样一个最近点，还想着，着这样效果会好吗？还是太年轻），这个时候，根据中值定理，只需要对采样区域面积进行积分，然后乘上中值就可以得到区域光下，该点的辐照度。

这个技术的缺陷，和粗糙度重映射导致的过度模糊相反，可能导致高光峰值部分过度"陡峭"。一些改进技术，其中一个有点意思——考虑的是$N\cdot H$值最大的光源表面点。



### 1.2 General Light Shapes

目前讨论的技术，最大的问题是——只考虑灯光是球形的。现实中的光源通常是形状各异的，而且也不是均匀发射的。

而在计算机图形学，特别是实时领域，我们需要权衡：是选择针对特殊情况的精确结果，还是选择一般情况的拟合结果。（==通用性、精确性间的权衡==）

<img src="RTR4_C10.assets/image-20201109205011824.png" alt="image-20201109205011824" style="zoom:67%;" />

对球形光最简单的扩展就是胶囊光`Tube Light`。对于`Lambertian BRDFs`，p神提出了一个封闭形式的积分拟合，这相当于用适当的衰减函数，从线段端点的两个点光源来评估照明：

<img src="RTR4_C10.assets/image-20201109205431453.png" alt="image-20201109205431453" style="zoom:67%;" />

而对于`Phone Specular BRDF`的积分，p神提出了一种基于`most representative point`的方法，基本思路是：在线段灯上取一个点光源，这个光源满足它到对应得向量和反射向量的夹角最小。

> 值得注意得是，在我的理解下，这里的所有反射向量和一般情况的不同，这里应该是view vector的在渲染点的反射向量。

k神进行了改进，以效率换准确率——寻找的点，是离反射向量最近的点，并加入一个缩放因子，来拟合能量守恒。

<span style="color:green;font-size:1.3rem">平面区域灯：</span>相对线性灯和环形灯，一个在现实生活中用途更为广泛的是`planar area lights`，其几何形状可以是长方形、圆形、或者任意。

D神提出了第一个实用的拟合 **[380]**。这个方法也基于代表点，并从`mean value theorem`开始，寻找光照积分的全局最大值，以此作为代表点。对于`Lambertian BRDFs`，其积分是：(图13:arrow_down:)

<img src="RTR4_C10.assets/image-20201112195013341.png" alt="image-20201112195013341" style="zoom:67%;" />

仔细看看公式，不难发现，其实是两个决定因素：1，$(n\cdot l)^+$测试的是光源上点的入射向量和表面点法线的夹角，越小越好，其最佳点记为P~c~；2，$\frac{1}{r^2_l}$测试的是光源上点到表面渲染点的距离，也是越小越好，其最佳点记为P~r~。那么，全局最大点，应该位于这两点的连线上，$p_{max}=t_m\cdot p_c+(1-t_m)\cdot p_r$。D神使用数值积分来为许多不同的配置找到最佳代表点，然后找到一个平均效果最好的t~m~。D神的一些跟进研究，包括对`textured card lights`的适配，见书 P 388。

`polygonal area lights`的拟合：Lambert在理想漫反射平面的封闭拟合；A神的拓展，在高光上进行拟合，非实时；L神在性能上进行优化，满足实时需求。**[967]  [74]**  **[1004]**

<span style="color:green;font-size:1.3rem">LCTs：</span>以上所有的算法，都基于假设对模型进行简化，然后通过对结果积分进行拟合。==H神提出了一种不同的、通用的、精确的思路==——` linearly transformed cosines`（LTCs）。基本思路：首先设计一类球面函数，这类函数既具有很强的表现力(即可以有多种形状)，又可以很容易地集成在任意球面多边形上:arrow_down:。**[711]**

<img src="RTR4_C10.assets/image-20201112202237937.png" alt="image-20201112202237937" style="zoom:80%;" />

LTCs只用了一个3×3矩阵变换的余弦叶，所以它们可以在半球上调整大小、拉伸和旋转，以适应各种形状。简单余弦叶的积分与球面多边形的积分是很成熟的。==H神最关键的观察是：用变换矩阵对积分进行拓展，并不会改变积分的复杂性==。

==我们可以用矩阵的逆，来变换多边形域，并消去积分内的矩阵，返回一个简单的余弦叶作为被积函数。==

<img src="RTR4_C10.assets/image-20201112203049611.png" alt="image-20201112203049611" style="zoom:67%;" />

对于一般的BRDFs和区域光，唯一剩下的工作是：找到方法（近似），将球体上的BRDF函数表达为一个或多个LTCs，这项工作可以离线完成，并在以BRDF参数为索引进行制表：粗糙度、入射角或其他。

LTCs方法比代表点的效果好，但更耗时。



## 2. Environment Lighting

以上区域光讨论的积分，所有方向都是恒定的辐射率，而在实际场景中，场景光（间接光）的辐射率通常不是常数。尽管我们在这里将讨论环境光，但我们并不会引入GI算法。==核心区别是：本节的所有渲染公式没有依赖其他表面的知识，but rather on a small set of light primitives。==

最简单的环境光方法就是`ambient light`。别看只是一个简单的常数，但确实提升了场景的真实性。

`ambient light`的具体视觉效果取决于我们使用的BRDF。对于`Lambertian`表面来说：

<img src="RTR4_C10.assets/image-20201112205711484.png" alt="image-20201112205711484" style="zoom:50%;" />

而对于任意的BRDF，其等式如下：

<img src="RTR4_C10.assets/image-20201112205748213.png" alt="image-20201112205748213" style="zoom: 67%;" />

可以简化成$L_o(v)=L_A\cdot R(v)$，早期的实时渲染程序将$R(v)$视为一个常数，称为`ambient color`，c~amb~。



##  3. Spherical and Hemispherical Functions

为了扩展环境照明，我们需要一种方法来表示从任何方向射入物体的辐射率`radiance`。首先，我们将radiance看作是对方向进行积分的函数，而不是表面位置`surfaceposition`。这样做的前提是：照明环境是无限远的。

<span style="color:green;font-size:1.3rem">Spherical Functions：</span>定义在单位球面上，用S来表示定义域。无论是生成一个值，还是多个值，这些函数的工作方式都不变。

假设在`Lambertian surface`的情况下，球面函数可以通过一个预先计算的radiance函数来计算环境照明，e.g., radiance convolved with a cosine lobe, for each possible surface normal direction。球面函数在全局光照算法中也得到了广泛的应用。

与球函数相关的是用于`hemisphere`函数。我们把这些表示称为球基`spherical bases`，因为它们是定义在球上的函数的向量空间的基。将一个函数转换为一个给定的`representation`称为投影`projection`，从一个给定的表示求函数的值称为重构`reconstruction`。

每种表示都有自己的一组权衡。我们在给定的`basis`上，可能寻找的属性是：

+ 高效的编码(投影)和解码(查找)
+ The ability to represent arbitrary spherical functions with few coefficients and low reconstruction error。
+ 投影的旋转不变性`Rotational invariance`。这个等价性意味着一个近似的函数，例如球谐函数，在旋转时不会改变。
+ Ease（简化） of computing sums and products of encoded functions
+ 球面积分和卷积计算的简化