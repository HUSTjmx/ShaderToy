# Lecture 1

结合神经网络的渲染的两个问题：1、实时性。2、需要手动调整、选择。



# Lecture 2——基础知识回顾

## 基本渲染管线

![image-20210322142300527](Games202学习笔记1.assets/image-20210322142300527.png)

## OpenGL

垂直同步和双重渲染。





# Lecture3——Real-Time Shadows 1

## Shadow Map

主要问题：自遮挡、阴影贴图的分辨率问题。

### 一点数学

![image-20210326142334555](Games202学习笔记1.assets/image-20210326142334555.png)

在实时渲染中，我们不关心不等式，而是关心==约等于==。==一个重要的约等式==：

![image-20210326142526669](Games202学习笔记1.assets/image-20210326142526669.png)

 这个分母的理由：是为了==归一化==。**什么时候这个不等式比较准确**？（两者其一就可）

- 实际积分域比较小
- $g(x)$比较光滑（min，max差别不大）

那么，考虑上节课的公式：

<img src="Games202学习笔记1.assets/image-20210326143130289.png" alt="image-20210326143130289" style="zoom: 67%;" />

对于上诉公式，具体考虑精确条件：（两者其一就可）

- Small support（point / directional lighting）（小的积分域）
- Smooth integrand。（diffuse bsdf / constant randiance area lighting）

所以**SM**对环境光（积分域大）和Gloosy BRDF（不光滑）就不太适用。



## Percentage closer soft shadows

### Percentage Closer Filtering

PCF的设计是为了抗锯齿。

<img src="Games202学习笔记1.assets/image-20210326144501841.png" alt="image-20210326144501841" style="zoom: 67%;" />

对于每一个像素，让它的深度和多个**SM**的`texel`进行比较，获得多个比较结果，然后对结果和进行平均。

![image-20210326144722895](Games202学习笔记1.assets/image-20210326144722895.png)

所以**PCF**平均的是**深度比较**的结果。

![image-20210329122102181](Games202学习笔记1.assets/image-20210329122102181.png)

PCF的问题，RTR4中也说过：其模糊区域是固定的。

### Percentage closer soft shadows

<img src="Games202学习笔记1.assets/image-20210326145853325-1616742183138.png" alt="image-20210326145853325" style="zoom: 67%;" />

![image-20210329122118490](Games202学习笔记1.assets/image-20210329122118490.png)

算法的整个流程：

<img src="Games202学习笔记1.assets/image-20210326150528301.png" alt="image-20210326150528301" style="zoom: 80%;" />

<img src="Games202学习笔记1.assets/image-20210326151014801.png" alt="image-20210326151014801" style="zoom:67%;" />





# Lecture4——Real-Time Shadows 2

对于PCSS，主要的性能限制是第一步和第三步。

## Variance Soft Shadow Mapping

对于PCSS，我们其实就是要知道渲染点在指定范围内的深度排名，那么我们就可以假设这个排名分布是符合**正态分布**的，而对于正态分布，其特征是由均值和方差决定的，所以我们就可以通过这些近似，避免多次访问ShadowMap求和做均值。

核心思路：

- 快速计算获得区域内深度的均值和方差。
- 对于均值：硬件的`MipMap`，Summed Area Tables
- 方差：$Var(X)=E(X^2)-E^2(X)$，所以我们需要一张深度平方的`ShadowMap`。
- 所以问题变成了：我们求正态曲线下，小于x的面积。

![image-20210329124658779](Games202学习笔记1.assets/image-20210329124658779.png)

- 正态分布的CDF没有解析解，只有数值解，如果觉得计算麻烦（打表更麻烦），可以使用如下不等式进行近似。

    <img src="Games202学习笔记1.assets/image-20210329125150535.png" alt="image-20210329125150535" style="zoom:80%;" />

回到第一步

<img src="Games202学习笔记1.assets/image-20210329130706840.png" alt="image-20210329130706840" style="zoom:80%;" />



## MIPMAP and Summed-Area Variance Shadow Maps

都是为了解决==范围查询==的问题。 

<img src="Games202学习笔记1.assets/image-20210329132548617.png" alt="image-20210329132548617" style="zoom:80%;" />



## Moment Shadow mapping

VSSM因为有很多近似，所以问题也不少

<img src="Games202学习笔记1.assets/image-20210329133715650.png" alt="image-20210329133715650" style="zoom:80%;" />

为了解决这些问题，可以使用更高阶的矩`moment`，

![image-20210329133915593](Games202学习笔记1.assets/image-20210329133915593.png)

![image-20210329134257560](Games202学习笔记1.assets/image-20210329134257560.png)



# Lecture 5 Real-time Environment Mapping

## Distance field soft shadow

有向距离场（SDF）的应用：

- Ray Marching

- 软阴影：寻找最小安全角（没有被遮挡的最大角）

    <img src="Games202学习笔记1.assets/image-20210331132434705.png" alt="image-20210331132434705"  />

![image-20210331132540780](Games202学习笔记1.assets/image-20210331132540780.png)

k越大，`penumbra`过渡带越小，阴影越硬。

<img src="Games202学习笔记1.assets/image-20210331132949215.png" alt="image-20210331132949215"  />

![image-20210331133543178](Games202学习笔记1.assets/image-20210331133543178.png)

## Environment Lighting

难点在于蒙特卡洛这种采样方法，很难用于实时，我们需要根据其特性进行近似，回顾之前的拆分方程：

![image-20210331135226889](Games202学习笔记1.assets/image-20210331135226889.png)

- 实际积分域比较小
- $g(x)$比较光滑（min，max差别不大）

所以我们可以对光照方程进行安全拆分：（不考虑可见性）

![image-20210331135843200](Games202学习笔记1.assets/image-20210331135843200.png)

把光给拆了出来，所以我们第一步其实就是==prefiltering==：

![image-20210331141137754](Games202学习笔记1.assets/image-20210331141137754.png)

![image-20210331141619843](Games202学习笔记1.assets/image-20210331141619843.png)

大致意思：本来关于Glossy的高光项，是需要查询左图蓝色波瓣区域的环境光，但是我们提前在那块蓝色区域投影的区域进行滤波，那么实际允许时，只需要访问一次，就可以近似访问了蓝色区域。

然后是BRDF项：

![image-20210331143816302](Games202学习笔记1.assets/image-20210331143816302.png)

![image-20210331144342928](Games202学习笔记1.assets/image-20210331144342928.png)

具体选什么参数呢，我们主要考虑决定颜色的**菲涅尔项**和决定分布的**法线分布项**。

![image-20210331144937296](Games202学习笔记1.assets/image-20210331144937296.png)

现在参数只剩下上诉三个，但还是有点多，

![image-20210331150740386](Games202学习笔记1.assets/image-20210331150740386.png)

![image-20210331145405136](Games202学习笔记1.assets/image-20210331145405136.png)

![image-20210331153803580](Games202学习笔记1.assets/image-20210331153803580.png)





# Lecture 6 Real-time Environment Mapping

## Shadow From Environment Lighting

实时渲染下，环境光的阴影计算是困难的。可以按照如下不同的角度考虑：

+ 环境光相当于很多光源。SM的消耗是巨大的。
+ 作为采样问题：可见项V是复杂的。

一个工业界的解决方案：在环境光最亮的部位，生成一个或多个最具代表性的光源。相关研究：`Imperfect shadow map`、`Light cuts`、实时光追、`PRT`。



## Background knowledge

傅里叶展开。

<img src="Games202学习笔记1.assets/image-20210405124051298.png" alt="image-20210405124051298" style="zoom: 50%;" />

<img src="Games202学习笔记1.assets/image-20210405124126479.png" alt="image-20210405124126479" style="zoom:50%;" />

==Filtering = Getting rid of certain frequency contents==。

![image-20210405124643767](Games202学习笔记1.assets/image-20210405124643767.png)

积分的频率是相乘项的最低频率。（这解释了为什么**高频灯**照在`diffuse`物体上，依然不会有高光）



## Spherical Harmonics

首先球谐函数是定义在球面上的一系列二维基函数$B_i(w)$。可以看做一维傅里叶函数的扩展。（下图的颜色是值而不是频率，越蓝白越大，越黄越小（负值））

<img src="Games202学习笔记1.assets/image-20210405125353496.png" alt="image-20210405125353496" style="zoom:80%;" />

投影：对于任意一个函数$f(w)$，可以简单获得其==球谐基的系数==：
$$
c_i=\int_{\Omega}f(w)B_i(w)dw
$$
重建：使用系数和基函数恢复原函数。（一般使用前四阶）



`Diffuse BRDF`表现的就像一个低通滤波器，为什么这么说，之前我们讲过——两者**点乘积分**的结果的频率，取决于两者的最低频率，那么无论光源包含多少高频信息，我们的最终结果依然会受限于低频的`Diffuse BRDF `，这不就是低通滤波器吗？而实际上，对于`Diffuse BRDF`，其投影到SH上，如下图所示，只有前三阶需要进行考虑。最终，我们可以提出问题：既然高频的光源信息无用，那么我们还需要保留所有光源信息吗？

<img src="Games202学习笔记1.assets/image-20210405133655229.png" alt="image-20210405133655229" style="zoom:67%;" />

所以说，==我们也只需要用前三阶的SH来描述光源==，而这个实际误差不会超过`3%`。



## Precomputed Radiance Transfer

PRT的基本想法：（假设场景中，只有光照条件会变）

<img src="Games202学习笔记1.assets/image-20210405135140065.png" alt="image-20210405135140065" style="zoom:50%;" />

> 在图形学中，大部分情况下，积分和求和的顺序可以任意交换。



<img src="Games202学习笔记1.assets/image-20210405140001566.png" alt="image-20210405140001566" style="zoom:80%;" />

缺点是什么呢？静态场景这个固有限制不用考虑，但我们需要考虑光源的变换。换个预计算的光源自然没什么问题，但现有光源进行旋转呢？难道我们也要对其进行预计算吗？

旋转光源，而光源投影到ＳＨ上，那么我们实际就是旋转所有**使用的球谐基**。而所有**旋转后的球谐基**，都可以通过同阶的球谐基**线性组合**得到。

![image-20210405141208504](Games202学习笔记1.assets/image-20210405141208504.png)

![image-20210405141248523](Games202学习笔记1.assets/image-20210405141248523.png)





# Lecture 7  Real-time Global Illumination (in 3D)

## Precomputed Radiance Transfer

![image-20210418150552012](Games202学习笔记1.assets/image-20210418150552012.png)

![image-20210419113210818](Games202学习笔记1.assets/image-20210419113210818.png)



## More basis functions

![image-20210419115803222](Games202学习笔记1.assets/image-20210419115803222.png)

![image-20210419120123771](Games202学习笔记1.assets/image-20210419120123771.png)



## GI——RSM

在RTR中，我们处理GI，实际就是处理Bounce一次的间接光。

![image-20210419123111948](Games202学习笔记1.assets/image-20210419123111948.png)

![image-20210419123720584](Games202学习笔记1.assets/image-20210419123720584.png)

![image-20210419124510879](Games202学习笔记1.assets/image-20210419124510879.png)

> 按照我的想法，来分析分析上诉公式，首先$f_r=\rho/\pi$和$L_i=f_r \frac{\Phi}{dA}$是物理定义（对于diffuse的平面）。第一个问题，为什么结果是`E`而不是`L`，我来思考的话，对于diffuse像素而言，每一个方向的光（也就是$L_o$），都是一致的，而$dE=L_0\cdot dw$，所以$E=L_0*4\pi$。
>
> 而回到$L_o$这个积分，

![image-20210419125612947](Games202学习笔记1.assets/image-20210419125612947.png)



# Lecture 8  Real-time Global Illumination (Screen Space)

## Light Propagation Volume (LPV)

high level。

![image-20210430120848514](Games202学习笔记1.assets/image-20210430120848514.png)

<img src="Games202学习笔记1.assets/image-20210430120932406.png" alt="image-20210430120932406" style="zoom:150%;" />

![image-20210430121259571](Games202学习笔记1.assets/image-20210430121259571.png)

![image-20210430121614415](Games202学习笔记1.assets/image-20210430121614415.png)

![image-20210430121808684](Games202学习笔记1.assets/image-20210430121808684.png)

![image-20210430121847566](Games202学习笔记1.assets/image-20210430121847566.png)

## Voxel Global Illumination (VXGI)

![image-20210430122946417](Games202学习笔记1.assets/image-20210430122946417.png)

![image-20210430123055966](Games202学习笔记1.assets/image-20210430123055966.png)

![image-20210430124309680](Games202学习笔记1.assets/image-20210430124309680.png)

## SSAO

![image-20210430130001900](Games202学习笔记1.assets/image-20210430130001900.png)



![image-20210430130550284](Games202学习笔记1.assets/image-20210430130550284.png)

![image-20210430130832230](Games202学习笔记1.assets/image-20210430130832230.png)

> AO就是一个平均的可见性。

![image-20210430131434758](Games202学习笔记1.assets/image-20210430131434758.png)

![image-20210430131618742](Games202学习笔记1.assets/image-20210430131618742.png)

![image-20210430132107775](Games202学习笔记1.assets/image-20210430132107775.png)

![image-20210430132255577](Games202学习笔记1.assets/image-20210430132255577.png)

![image-20210430133013058](Games202学习笔记1.assets/image-20210430133013058.png)

![image-20210430133237861](Games202学习笔记1.assets/image-20210430133237861.png)

![image-20210430133800391](Games202学习笔记1.assets/image-20210430133800391.png)



# Lecture 9  Real-time Global Illumination (Screen Space Cont)

## SSDO

![image-20210506105210603](Games202学习笔记1.assets/image-20210506105210603.png)

![image-20210506105240012](Games202学习笔记1.assets/image-20210506105240012.png)

![image-20210506105736817](Games202学习笔记1.assets/image-20210506105736817.png)

![image-20210506110258529](Games202学习笔记1.assets/image-20210506110258529.png)



## SSR

![image-20210506110958946](Games202学习笔记1.assets/image-20210506110958946.png)

![image-20210506111735700](Games202学习笔记1.assets/image-20210506111735700.png)

![image-20210506112058849](Games202学习笔记1.assets/image-20210506112058849.png)

更好的方法：

![image-20210506112241591](Games202学习笔记1.assets/image-20210506112241591.png)

![image-20210506112412197](Games202学习笔记1.assets/image-20210506112412197.png)

![image-20210506113242382](Games202学习笔记1.assets/image-20210506113242382.png)

![image-20210506114526971](Games202学习笔记1.assets/image-20210506114526971.png)

![image-20210506115808466](Games202学习笔记1.assets/image-20210506115808466.png)



# Lecture 10 RealTime Physiaclly Based Material



# Lecture 11 RealTime Physiaclly Based Material 2

## Linearly Transformed Cosines

![image-20210531111222178](Games202学习笔记1.assets\image-20210531111222178-1622430743253.png)

![image-20210531111421628](Games202学习笔记1.assets\image-20210531111421628.png)

![image-20210531111901296](Games202学习笔记1.assets\image-20210531111901296.png)



## Disney Principled BRDF

![image-20210531113132078](Games202学习笔记1.assets\image-20210531113132078.png)

设计原则：

![image-20210531113412414](Games202学习笔记1.assets\image-20210531113412414.png)

![image-20210531113934506](Games202学习笔记1.assets\image-20210531113934506.png)



## NPR

![image-20210531121716380](Games202学习笔记1.assets\image-20210531121716380.png)

![image-20210531141554606](Games202学习笔记1.assets\image-20210531141554606.png)

![image-20210531141934863](Games202学习笔记1.assets\image-20210531141934863.png)

![image-20210531142230022](Games202学习笔记1.assets\image-20210531142230022.png)

![image-20210531142929844](Games202学习笔记1.assets\image-20210531142929844.png)

![image-20210531143413949](Games202学习笔记1.assets\image-20210531143413949.png)

![image-20210531143519981](Games202学习笔记1.assets\image-20210531143519981.png)



# Lecture 12 Real-Time Ray Tracing

![image-20210531151205969](Games202学习笔记1.assets\image-20210531151205969.png)

![image-20210531151330118](Games202学习笔记1.assets\image-20210531151330118.png)

![image-20210531151718718](Games202学习笔记1.assets\image-20210531151718718.png)

为什么会有这么强的效果？

![image-20210531154144803](Games202学习笔记1.assets\image-20210531154144803.png)

 

![image-20210531154745912](Games202学习笔记1.assets\image-20210531154745912.png)

![image-20210531154952360](Games202学习笔记1.assets\image-20210531154952360.png)

