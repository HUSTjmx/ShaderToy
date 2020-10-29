# Chapter 9——Physically Based Shading

## 1.  Physics of Light

==光和物质的相互作用形成了PBS的基础==。为了理解这些相互作用，对光的本质有一个基本的理解是有帮助的。在==物理光学==中，光被建模为电磁横波`transverse wave`——一种使电场和磁场垂直于其传播方向的波。这两个场的振荡是耦合的（ coupled）。磁场和电场矢量相互垂直，它们的长度之比是固定的（这个比值等于相速度` phase velocity`，==通常称其为光速c==）

下图是一个最简单的光波——一个完美的Sin曲线。这种波只有一个波长，用$\lambda$表示。单波长的光叫做单色光`monochromatic light`。然而，实际中遇到的大多数光波是多色的，包含许多不同的波长。在另一方面，单色光也是非常简单——它是`linearly polarized`的（偏振的）。这意味着，在空间的一个固定点上，电场和磁场都沿着一条线来回移动。相反，在这本书中，我们关注的是==更普遍的非偏振光==——在非偏振光中，场振荡` the field oscillations`均匀地分布在所有方向（垂直于传播轴的）上。尽管它们很简单，但==理解单色线性偏振波的行为是有用的，因为任何光波都可以分解成这些波的组合==。

<img src="RTR4_C9.assets/image-20201026132200500.png" alt="image-20201026132200500" style="zoom:80%;" />

波长`wavelength`通常多大呢？可以拿蜘蛛丝和头发来对比：

<img src="RTR4_C9.assets/image-20201026133655439.png" alt="image-20201026133655439" style="zoom:67%;" />

光波携带能量，能量流的密度等于电场和磁场的乘积，由于磁场和电场成比例，所以也就是与电场的平方成比例。==我们关注电场==，因为它对物质的影响比磁场强得多。==在渲染中，我们关注的是随时间的变化的平均能量流，这与波振幅的平方成比例==。==这个平均能量流的密度就是辐照度E==。==光波线性结合==——总波是各分量波的和。然而，由于辐照度与振幅的平方成比例，这似乎会导致一个==悖论==。两个相等的波相加，不会导致“1 + 1 = 4”的情况吗？既然辐照度E度量的是能量流，这不会破坏能量守恒吗？这两个问题的答案是：分别是==“有时”和“不”==。

为了说明，举一个简单的例子：n个单色波的加法，除了相位相同之外。每n波的振幅为a。如前所述，每一波的辐照度E~1~与$a^2$成正比，换句话说：$E_1 = ka^2$。见下图，n个单色波相加的三种情况，左边的情况是`constructive interference`，中间是`destructive interference`。这两个都是`coherent addition`（相干叠加）的特殊情况，所以第一个问题的答案是"有时"。

![image-20201026135308585](RTR4_C9.assets/image-20201026135308585.png)

但大多数情况（上图右），波的叠加是不相干的`incoherent`，在这种情况下，组合波的振幅是√n，每个波的辐照度加起来，线性地等于初始辐照度的n倍。但只按照上图左、中，似乎不满足能量守恒，但是上诉是知识空间某个位置的情况，随着位置移动，相位会发生变化，如下图：（这并不违反能量守恒定律，因为通过相长干涉获得的能量和通过相长干涉损失的能量总是可以抵消掉）

![image-20201026140547601](RTR4_C9.assets/image-20201026140547601.png)

光离开光源后，在空间中遨游，直到遇到和其交互的物质。==光-物交互的核心理论是简单的==：振荡的电场对物质中的电荷进行推拉，使它们依次振荡；振荡的电荷发射出新的光波，使入射光波的部分能量定向到新的方向。==这也就是各种渲染理论的基础——散射==`scattering`。

散射的光波与原波的频率相同。通常情况下，当原波包含多个频率的光波时，每个频率的光波都会分别与物质发生作用（也只会对相同频率的出射光产生影响），除了荧光和磷光，我们在本书中不会介绍。

在渲染中，我们关注的是分子的集合。集合体的相互作用与孤立分子的相互作用不一样。从附近的分子散射出来的波通常是相干的，因此表现出干扰，因为它们来源于同一个入射波。The rest of this section is devoted to several important special cases of light scattering from multiple molecules。



### 1.1 Particles

==在理想的气体中，分子通常不会相互影响==，它们的相关位置是完全随机和无关的。在这种情况下，不同分子散射的波之间的相位差是随机的，并且不断变化。因此，它们的能量线性增加，如图9.3的右部。相反，如果分子紧密地挤在比光的波长小得多的团簇中，散射光的波长是同相位的，此时，能量平方增加，如图9.3的左部。

这个解释了为什么云和雾如此强烈地散射光线。它们都是由凝结产生的——空气中的水分子聚集成越来越大的团簇，这大大增加了光的散射。

当讨论光散射时，粒子`particles`用于指孤立的分子和多分子团簇。由于来自多分子聚簇（直径小于波长）的散射是来自孤立分子的散射的放大，它表现出相同的方向变化和波长依赖性。这种类型的散射在大气粒子中称为`Rayleigh scattering`，在固体颗粒中称为`Tyndall scattering`。当粒子越来越大，散射光的波长依赖性越来越低，这种类型的散射称为`Mie scattering`。



### 1.2 Media

另一个重要的情况是==光通过均匀介质传播==，均匀介质包括：晶体，不含杂质、无缝隙的液体和其它固体。在均质介质中，散射波在除原传播方向外的所有方向上都发生破坏性干扰`interfere destructively`。原始波与各个分子散射的波结合后。除了相位速度和（在某些情况下）振幅之外，==最终结果与原始波相同，不表现出任何散射效应==。

旧波和新波的相速度之比，构成了介质的一个光学属性，`index of refraction`（==IOR==、折射率，用n表示）。有些介质具有吸收性，其中的光，随着距离的不断深入，强度逐渐衰减——下降的速率被称为`attenuation index`（用$\kappa$表示）。这两者通常组合起来，$n+i\kappa$，称之为==复折射率==`complex index of refraction`。折射率将分子层面上，光与介质相互作用的细节抽象出来，and enables treating the medium as a continuous volume, which is much simpler。

![image-20201027133006222](RTR4_C9.assets/image-20201027133006222.png)

==非均匀介质通常可以被模拟为：在均匀介质中嵌入散射粒子==。 Such a localized change can be a cluster of a different molecule type, an air gap, a bubble, or density variation。在任何情况下，就像前面讨论的粒子一样散射光，其特性同样依赖于聚簇团的大小，甚至气体也可以用这种方法建模。下图是几个散射`scattering`的例子：

![image-20201027133706422](RTR4_C9.assets/image-20201027133706422.png)

散射和吸收`absorption`都是大小相关的。小场景中，某些介质（水、空气）的视觉效果不明显，但在大场景中就特别重要（如下图所示）

<img src="RTR4_C9.assets/image-20201027155905417.png" alt="image-20201027155905417" style="zoom:67%;" />

介质的亮度是这两种现象的综合结果。特别是白色——高散射和低吸收结合的结果

<img src="RTR4_C9.assets/image-20201027162946726.png" alt="image-20201027162946726" style="zoom:67%;" />



###  1.3 Surface

相比介质内部的缝隙和密度不均匀，物体表面（不同介质的交界处）是一种特殊的、导致散射的“不连续”情况。边界条件要求平行于表面的电场是连续的，换句话说：the projection of the electric field vector to the surface plane must match on either side of the surface。==这有几个含义==：

- 在表面上，散射波的波峰必须与入射波的波峰或波谷对齐。这就限制了散射波只能向两个可能的方向传播，一个继续进入表面（折射光），另一个离开表面（反射光）。
- 散射波必须与入射波具有相同的频率。
- 相速度`phase velocity`和相对折射率(n1 / n2)成比例变化。由于频率是固定的，所以波长也按比例变化为(n1/n2)。

折射光的角度和入射光的角度之间的关系：(==Snell’s law==)
$$
sin(\theta_t)=\frac{n_1}{n_2}sin(\theta_i)
$$
<img src="RTR4_C9.assets/image-20201027162120204.png" alt="image-20201027162120204" style="zoom:67%;" />

==不透明物体也存在光的折射==。比如：对于金属而言，内部包含很多自由电子，它们会吸收折射光，并将光重定向到反射光上，所以，金属同时具有和高吸收性和高反射性。

目前我们讨论的折射内容，都是在IOR上进行突变（发生在小于一个波长的距离上的）。而==一个渐变的IOR== ，不会切割光的传播路径，但是会扭曲它的传播。这个效果通常见于空气密度会因温度而变化的情况，例如：海市蜃楼和热变形（如下图）

![image-20201027163724096](RTR4_C9.assets/image-20201027163724096.png)

如果一个物体的表面没有IOR的变化，那么折射和反射都不发生，它就是不具有` visible surface`（下图书中的小球具备一定的可见性，是由于它对光的吸收性）

<img src="RTR4_C9.assets/image-20201027164408589.png" alt="image-20201027164408589" style="zoom:67%;" />

​	除了表面的IOR区别，==另外一个影响表面的因素==是` geometry`。比波长小得多的表面不规则性` irregularities`对光没有影响，而比波长大得多的不规则性倾斜表面，而不影响其局部平整度；只有波长在1-100范围内的不规则现象，才会通过一种叫做衍射`diffraction`的现象使表面表现出与平面不同的行为。我们将在后面进一步讨论这种现象（C 9.11）

在渲染中，我们通常使用==几何光学==（以上都是物理光学），忽略了波的影响，如干涉和衍射。在几何光学中，光被建模成光线`Ray`，而不是波`wave`。回到本章和上一段提到的情况，也就是所谓的微观几何`microgeometry`，在渲染中，我们是直接处理的，例如BRDF中的几何项G——表面具有随机分布的微观法线，因此，我们沿连续方向扩散反射（和折射）光。扩展的宽度，以及反射和折射细节的模糊程度，==取决于微观几何法向矢量的统计方差==——换句话说，表面的微尺度粗糙度`roughness`。

<img src="RTR4_C9.assets/image-20201027170125123.png" alt="image-20201027170125123" style="zoom: 80%;" />



###  1.4 Subsurface Scattering

正如之前所言，金属反射大部分光，并快速吸收剩下的光；而非金属物体则在这两方面表现各不相同。在这一章中，将集中讨论不透明的物体，在这些物体中，透射光经过多次散射和吸收，直到最后一部分光从表面重新发射回来。

<img src="RTR4_C9.assets/image-20201027170521755.png" alt="image-20201027170521755" style="zoom:67%;" />

距离（出点和入点间的）和阴影尺度（像素的大小，或采样之间的距离）之间的关系很重要。==如果这个entry-exit距离小于后者==，表面下的散射与表面反射结合成一个局部着色模型，在一个点上发出的光只依赖于同一点上的入射光。 The `specular term` = models surface reflection, and the `diffuse term` models = local subsurface scattering；否则，就需要考虑，其它点的散射对某点的影响了——也就是所谓的`global subsurface scattering `。（至于次表面散射是使用局部，还是全局，则取决于物体的材质和观察尺度，更多技术见书 C 14）。

<img src="RTR4_C9.assets/image-20201028152542676.png" alt="image-20201028152542676" style="zoom:67%;" />



## 2. The Camera

渲染的图像系统包含一个由许多离散的小传感器组成的传感器表面。辐照度传感器本身不能产生图像，因为它们平均来自所有入射方向的光线。因此，一个完整的成像系统包括：带有==光圈==`aperture`的防光==外壳==`enclosure`，用来限制光线进入和撞击传感器的方向。放置在光圈处的==透镜==`lens`可使光线聚焦，从而使每个传感器只接收一小部分方向的光线。外壳、光圈和透镜的共同作用，使传感器具有`directionally specific`（特定的方向性）。因此，==相机只对一小部分区域的一部分入射光进行平均处理==。

渲染中模拟的简单图像传感器，叫做==针孔相机==`pinhole camera`。这种相机有着理想化的光圈，近似一个没有尺寸概念的点，而且没有透镜。当然，渲染实际使用还要对其进行修改——设定一个`camera position`来代表针孔相机的位置，如下图中:arrow_down:

<img src="RTR4_C9.assets/image-20201028154755192.png" alt="image-20201028154755192" style="zoom: 50%;" />

尽管针孔相机的建模较为成功，但效果相对人眼，是不够好的，上图下:arrow_up:，加了一个透镜，这样采样了更多的光，且允许增大光圈，但这会对相机的深度造成限制——过近、过远的物体都会被模糊，当然，大部分情况，我们就是需要这种效果，也就是常说的==景深==。



## 3. The BRDF

==根本上，基于物理的渲染是为了计算沿着一组ray到达相机的辐射率==`radiance`，对于每一个Ray，我们需要计算$L_i(c,-v)$，其中，c是相机的位置，v是相机指向渲染点的向量。我们在渲染中，对于物体所处环境的介质 ，常见的考虑是对光无影响的纯净空气；当然也可以考虑那种会散射或吸收光的介质`participating media`，这种情况的考虑，见书 P C 14。因此在本章的考虑下，有如下关系：(p是视线和最近物体的交点)
$$
L_i(c,-v)=L_o(p,v)
$$
 首先，我们不考虑透明物体和全局次表面散射，而专注于局部反射现象，包括：==表面反射和局部次表面散射==，且只依赖于入射光方向l，出射视线方向v。这些可以通过`bidirectional reflectance distribution function`（BRDF）进行量化，公式中写为$f(l,v)$。

早期的实现中，由于物体的表面通常被设定成参数一致的，所以BRDF是常数，但是真实世界中，则很少有这种物体。技术上，基于空间位置的BRDF变体，称为`spatially varying BRDF` (==SVBRDF==) or spatial BRDF (SBRDF)，However, this case is so prevalent in practice that the shorter term BRDF is often used and implicitly assumed to depend on surface location。

出射和入射方向通常都是双自由度的：相对表面方线的仰角`elevation `，方位角` azimuth`。==一般情况下，BRDF包含四个标量变量==。各向同性BRDFs`Isotropic BRDFs`是其中一个重要的特例，其特点是：入射方向和射出方向绕表面法线旋转时，这种BRDFs保持不变，保持它们之间的相对角度相同。因此，这种BRDF只有三个变量，因为光线和相机之间只有一个角度$\phi$需要。（不需要$\phi_i或\phi_o$）

> What this means is that if a uniform isotropic material is placed on a turntable and rotated, it will appear the same for all rotation angles, given a fixed light and camera.

<img src="RTR4_C9.assets/image-20201028162306666.png" alt="image-20201028162306666" style="zoom:67%;" />

因为我们忽略荧光和磷光，可以假设出射光和入射光的波长是一致的。反射光量可以根据波长的不同而变化，这==可以用两种方式来建模==：波长被当作BRDF的一个额外输入变量，或者BRDF返回一个频谱分布的值。第一种方法常见于离线渲染，而第二种则是实时渲染。此时，可以有反射方程：
$$
L_o(p,v)=\int_{I\in \Omega}{f(l,v)L_i(p,l)(n\cdot l)dl}
$$
我们可以将进行采样的半L_o(\theta_o)球参数化，用球坐标表示上诉公式：
$$
L_o(\theta_o,\phi_o)=\int_{\phi_i=0}^{2\pi}{\int_{\theta_i=0}^{\pi/2}{f(\theta_i,\phi_i,\theta_o,\phi_o)L(\theta_i,\phi_i)cos\theta_isin\theta_id\theta_id\phi_i}}
$$
也可以使用更加不同的参数化，使用$\mu_i=cos\theta_i,\mu_o=cos\theta_o$

<img src="RTR4_C9.assets/image-20201028164141296.png" alt="image-20201028164141296" style="zoom:80%;" />

跟Phong模型一样，我们需要考虑，视点在表面以下的情况，即$n\cdot v<0$（主要由法线引起）。简单的clamp会导致`artifacts`，寒霜引擎的解决思路是加上一个小值（0.00001），来避免除零错误。另一个解决思路是`soft clamp`。==物理定律对任何BRDF都有两个限制==：

- `Helmholtz reciprocity`：即使输入和输出角度切换，函数值也是相同的——$f(l,v)=f(v,l)$。在实践中，用于渲染的BRDFs通常会违反这个限制，但不会出现明显的`artifacts`，除了特别需要互易性`reciprocity`的离线渲染算法，如双向路径跟踪`bidirectional path tracing`。
- `energy`：第二个限制是能量守恒，出射光的能量不能大于入射光，无需像离线渲染（如：路径追踪）那么精确，==对于实时渲染，精确的能量守恒是不必要的，但是近似的能量守恒是重要的==。用BRDF渲染的表面明显违反了能源节约，会太亮，导致看起来不现实。

`directional-hemispherical reflectance`==R(l)是一个和BRDF有关的函数，用来测量BRDF的节能程度==。本质上，它测量的是，从指定方向来的入射光，在表面法线的半圆上朝各个方向反射的光量。定义如下：
$$
R(l)=\int_{v\in \Omega}f(l,n)(n\cdot v)dv
$$
`hemispherical-directional reflflectance`，类似但在某种意义上相反的功能，其定义R(v)如下：
$$
R(v)=\int_{l\in \Omega}f(l,n)(n\cdot l)dl
$$
If the BRDF is reciprocal，这两者是相等的。在这两种反射率可互换使用的情况下，==方向反照率==`Directional albedo `可作为这两种反射率的总称。==BRDF节能的要求是，对于l的所有可能值，R(l)不大于1==。

朗伯模型`Lambertian shading model`是最简单的BRDF（常数），常用来计算` local subsurface scattering`，这时，可以计算得到：
$$
R(l)=\pi f(l,v)
$$
郎伯BRDF的恒定反射率值通常称为`diffuse color`$c_{diff}$或者`albedo`$\rho$。本节为了体现和次表面散射的相关性，将其称为`subsurface albedo`$\rho_{ss}$。所以：
$$
f(l,v)=\frac{\rho_{ss}}{\pi}
$$
==在半球上对cos求积分得到$\pi$，这解释了分母==。这些因素经常出现在BRDFs中。理解BRDF的一种方法是：在保持输入方向不变的情况下可视化它，如下图（几个模型的可视化结果，==经典==）。

<img src="RTR4_C9.assets/image-20201028185215407.png" alt="image-20201028185215407" style="zoom:67%;" />



## 4. Illumination

全局关照算法`Global illumination`（==GI==）通过模拟光在整个场景的传播和反射来计算$L_i(l)$。这些算法使用渲染方程，其中反射方程是一种特例。GI将在后面介绍，这里主要讨论`local illumination`。在局部光照中，$L_i(l)$直接给出，而不需要计算。同时，这里只考虑` punctual lights`，不考虑区域光

考虑光源` directional light`(区域光的面积无限小)，其光线为l~c~，颜色为正对着光源的白色郎伯平面的反射辐射率。那么可以得到如下公式：
$$
L_o(v)=\pi f(l_c,v)c_{light}(n\cdot l_c)^+
$$
对于`Punctual lights`，唯一的区别是：不能考虑无限远的情况，c~light~随着距离平方的倒数下降。
$$
L_o(v)=\pi\sum_{i=1}^n{f(l_{c_i},v)c_{light_i}(n\cdot l_{c_i})^+}
$$
结合之前的公式，$\pi$可以消掉，这样就从渲染方程中删去了除法操作。然而，必须注意的是，在论文向实际商业使用的过渡中，一般情况下，BRDF在使用前需要与$\pi$相乘。



## 5. Fresnel Reflectance

==光与平面（两种物质之间的）的相互作用遵循菲涅尔方程==`Fresnel equations`。根据几何光学的假设，菲涅耳方程需要一个平面界面，且不考虑会影响光的` irregularities`。

<img src="RTR4_C9.assets/image-20201028192857577.png" alt="image-20201028192857577" style="zoom:67%;" />

:arrow_up:反射光的量（作为入射光的一部分）由==菲涅耳反射率==`Fresnel reflflectance`F描述，它取决于入射角$\theta_i$。==菲涅耳方程描述了F对$\theta_i$、n~1~和n~2~的依赖关系==。我们将描述它们的重要特征，而不是给出复杂的方程。



### 5.1  External Reflection

`External reflection`，从折射率较低的物质，传播到折射率ROI较大的物质。`internal reflection`则相反。对于给定的物质，菲涅耳方程可以解释为：一个只与入射光角度有关的反射函数F。原则上，==F的值在可见光谱上是连续变化的==。出于渲染目的，它的值被视为RGB向量。函数F具有以下特征：

- 当$\theta_i=0^o$时，F~0~被认为是该物质的特殊高光颜色，这种情况被称为`normal incidence`。
- 随着$\theta_i$变大， the light strikes the surface at increasingly glancing angles，$F(\theta_i)$也变大。当$\theta_i=90^o$时， reaching a value of 1 for all frequencies。

如下图:arrow_down:。这是几个物质（玻璃、铜和铝）的菲涅尔可视化。可以看出是高度非线性化的——前期几乎没有变化，直到75^o^左右，突增到1。

<img src="RTR4_C9.assets/image-20201029134225862.png" alt="image-20201029134225862" style="zoom:67%;" />

==容易想到，反射最强烈的部分在物体边缘，而从摄像机的角度来说，这个部分则占据了相对较少的像素==。此外，我们可以看到，上诉曲线图:arrow_up:使用的是Sin值作为横坐标（讲真，没看出来），而不是直接的角度。而下图:arrow_down:解释了为什么：

<img src="RTR4_C9.assets/image-20201029135717331.png" alt="image-20201029135717331" style="zoom:67%;" />

渲染程序中，在掠射角附近，反射率增加的现象叫做`Fresnel effect`。而在渲染中，直接使用菲涅尔方程是困难的（方面有很多，比如：它要求我们对可见光谱进行采样，获得折射率）。==Schlick给出了菲涅耳反射系数的近似==：（这个函数明显是：在F~0~和white间进行插值，简单但精确）
$$
F(n,l)=F_0+(1-F_0)(1-(n\cdot l)^+)^5
$$
下图:arrow_down:是近似的拟合效果，一共测了六个物质。 Gulbrandsen提出的方法在金属上表现效果极佳；Lagarde对各个近似技术做了个总结；对Schlick方法最简单的扩展，就是允许5以上的次幂。

<img src="RTR4_C9.assets/image-20201029161727652.png" alt="image-20201029161727652" style="zoom:67%;" />

F~0~可以通过折射率来进行计算，在考虑环境介质是空气的情况（物体的IOR为n），则可通过下述公式进行计算:arrow_down:
$$
F_0=(\frac{n-1}{n+1})^2
$$
==更一般的菲涅尔近似方程如下==：
$$
F(n,l)\approx F_0+(F_{90}-F_0)(1-(n\cdot l)^+)^{\frac{1}{p}}
$$
分析可知，这个公式具有更多的可控性，比如菲尼尔效应颜色的控制（F~90~）和“sharpness” of the transition（1/p的次幂）。



### 5.2 Typical Fresnel Reflectance Values

介质主要分为三类：电介质（绝缘体）、金属（导体）、半导体（性质介于前两者之间）。

##### Fresnel Reflectance Values for Dielectrics

==电介质的F~0~通常比较低，一般不大于0.06（未知材料，默认取0.04）==。其光学性质在可见光谱上很少有大的变化，resulting in colorless reflectance values。下表:arrow_down:给出了常见电介质的F~0~，其值是标量而不是RGB——因为这些材料的RGB通道没有显著差异。

<img src="RTR4_C9.assets/image-20201029165404675.png" alt="image-20201029165404675" style="zoom:67%;" />



##### Fresnel Reflectance Values for Metals

金属则拥有较高的F~0~，一般不小于0.5。其光学性质在可见光谱上，一般会有大的变化，resulting in colored reflectance values。下表:arrow_down:给出了常见金属的F~0~。

<img src="RTR4_C9.assets/image-20201029170326097.png" alt="image-20201029170326097" style="zoom:67%;" />

金属会立即吸收任何透射光，因此它们不会表现出次表面散射或透明的效果。金属的所有可见颜色都来自F~0~。



##### Fresnel Reflectance Values for Semiconductors

==出于实际目的，F~0~应该避免取0.2到0.45之间，除非要建模一个不现实的材料。==

<img src="RTR4_C9.assets/image-20201029170810419.png" alt="image-20201029170810419" style="zoom:67%;" />



##### Parameterizing Fresnel Values

这里进行的参数化，要考虑两个方面，一个是这里的高光颜色F~0~，一个是之前提到的漫反射颜色$\rho_{ss}$。具体的参数化：设定一个`surfce color`& c~surf~ 和 金属度`metallic`& m，然后：

+ 如果m=1，c~surf~=F~0~，$\rho_{ss}$=black
+ 如果m=0，c~surf~=$\rho_{ss}$，F~0~=black

==这种参数化技术的缺点==在于：特殊材料无法体现（拥有彩色F~0~的电介质）；电介质和金属的交界处可能会出现`artifacts`。

==另外一种参数化技术==（书上也没说叫啥），主要依据的事实是：除了特殊的抗反射材料，几乎所有材料的F~0~都不低于0.02。The trick is used to suppress specular highlights in surface areas that represent cavities or voids。具体：不是使用单独的`specular occlusion texture`，而是设置低于0.02的F~0~，来"关闭 "菲涅尔效应。这项技术已经应用在虚幻和寒霜上。



###  5.3 Internal Reflection

以上讨论的都是渲染中常用的`External Reflection`，但`Internal Reflection`有时也很重要。这种情况，具体来说是：当光线在透明物体内部传播时，就会“从内部”接触到物体表面，从而发生内部反射。

![image-20201029174902360](RTR4_C9.assets/image-20201029174902360.png)

由于折射角始终大于反射角，所有就会产生一个临界值$\theta_c$——大于它之后，所有光都被反射，折射为0。（$\theta _i=\theta_c\rightarrow sin\theta_t=1\rightarrow\theta_i>\theta_c,sin\theta_t>1,error $）此时的现象被称为==全反射==`total internal reflection`。

而对于内部反射的菲涅尔方程，根据其对称性，应该和外部反射的情况类似，更具体的说，是外部方程的压缩——==在$\theta_c$，而不是90^o^上达到最大值==，如下图:arrow_down:。换一个角度考虑，内部反射的平均反射率更高（毕竟更早到达极大值），这解释了：为什么在水下看到的气泡具有高度反光的银色外观。

<img src="RTR4_C9.assets/image-20201029180058224.png" alt="image-20201029180058224" style="zoom:67%;" />

内部反射通常发生在电解质中，毕竟金属和半导体具有极高的吸收特性。其临界角可以如此计算：

<img src="RTR4_C9.assets/image-20201029180501446.png" alt="image-20201029180501446" style="zoom:67%;" />



## 6. Microgeometry（微观几何）

我们仍停留在几何光学领域——假设这些不规则性要么小于光的波长（因此对光的行为没有影响），要么要大得多。

> 两个微观尺度：
>
> + 基于光波的大小。物体表面的不规则变化相对光波的尺寸，主要考虑的是光的干扰和衍射，区分的是物理光学和几何光学
> + 基于像素的大小。散射入口和出口的距离，主要考虑的是全局次表面散射。
> + 微平面理论。基于像素，考虑小于一个像素的物体表面的不规则性——法线和自遮挡。