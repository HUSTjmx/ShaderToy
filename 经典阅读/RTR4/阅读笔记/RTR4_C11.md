# Chapter 11——Global Illumination

[toc]



![image-20201121164916012](RTR4_C11.assets/image-20201121164916012.png)



## 1. The Rendering Equation

反射率方程是Kajiya在1986年提出的<u>全渲染方程</u>` full rendering equation`的一种受限特例。有很多不同的形式，我们使用这个版本：

![image-20201121165148887](RTR4_C11.assets/image-20201121165148887.png)

其中，$L_e$是自发光，然后用以下进行替代：

![image-20201121165815289](RTR4_C11.assets/image-20201121165815289.png)

这一项意味着：从$l$方向射入p的辐射强度，等于从相反法向$-l$射入其它位置的辐射强度。在这种情况下，“其他点”是由光线投射函数$r(p, l)$定义的，这个函数返回从$p$朝$l$方向，进行光线投射所击中的第一个表面点的位置，见下图：

![image-20201121170300774](RTR4_C11.assets/image-20201121170300774.png)

这个公式中唯一的新成员就是$L_o(r(p,l),-l)$，它显示指出到达一个点的入射光来自另外一个点的出射光。因此，这项是递归项。光线照亮一个场景，而光子在每次碰撞中反弹，并以各种方式被吸收、反射和折射。==渲染方程的重要之处在于，它将所有可能的路径汇总在一个看起来简单的方程中==。

<img src="RTR4_C11.assets/image-20201121185551197.png" alt="image-20201121185551197" style="zoom:67%;" />

Transparency，reflections, and shadows是全局光照算法，因为它们需要使用来自其它物体的信息。而一个思考渲染照明的好方法就是思考光子传播的路径，如上图:arrow_up:，H神提出了一个基本思路：光子`photon`从光(L)到眼睛(E)的过程中，每一次相互作用都可以标记为漫反射(D)或镜面(S)——当然也可以加入新的种类，如`glossy`，光滑但却不是镜面效果。

算法可以用正则表达式进行简要总结，显示它们模拟的交互类型。下表是基本符号的总结：:arrow_down:

![image-20201121190628225](RTR4_C11.assets/image-20201121190628225.png)

尽管H神的符号读起来很直观，但反方向理解表达式往往更容易（从右到左）。渲染方程本身可以用一个简单的表达式来概括：$L(D|S)*E$。而在实时渲染中使用全局光照时，最常用的两个策略是==简化和预计算==。

本章将举例说明如何使用这些策略来实现实时的各种全局照明效果。

下图是昂贵的路径追踪效果：

![image-20201121192728578](RTR4_C11.assets/image-20201121192728578.png)



## 2. General Global Illumination

在本章中，我们提出算法，旨在解决全渲染方程。它和我们在第九章讨论的反射方程的区别是：反射方程忽略了辐射度的**来历**，而是 simply given。`full`则明确给出：渲染点的辐射率`radiance`由其它点反射或射出而来。

路径追踪等方法对于实时而言是昂贵的，所以讨论干嘛？第一个理由是，对于很多静态场景，这种算法可以作为预处理，在实时运行时，直接读取使用。第二个理由是，全局光照算法建立在严格的理论之上，都是基于渲染方程推理得到的，而在设计实时算法时也可以使用类似的方法。（而且随着硬件的方法，很多离线方法也可以应用于实时了）

两个解决渲染方程的常见方法是：<span style="color:green;font-size:1.3rem">有限元法和蒙特卡洛方法</span>。<u>辐射度方法</u>` Radiosity`基于第一个方法；光线追踪及各种变体使用第二种。两者中，光线追踪要流行得多。这主要是因为==它可以在同一个框架内有效地处理一般的光传输==——包括体积散射`volumetric scattering`等效果。

> 同样经典的离线算法书籍：
>
> [400] Dutr´e, Philip, Kavita Bala, and Philippe Bekaert, ==Advanced Global Illumination==, Second
>
> Edition, A K Peters, Ltd., 2006. Cited on p. 269, 442, 512, 684
>
> 以及PBR第三版



### 2.1 Radiosity

Radiosity是第一种用于模拟漫反射表面之间Bounce的计算机图形技术。在经典的形式中，Radiosity可以计算区域光的相互反射和软阴影。其基本想法是：<span style="color:green;font-size:1.3rem">Light bounces around an environment. </span>——你打开一盏灯，照明度很快达到平衡。在这种稳定的状态下，每个表面都可以看作是一个光源。

==基本的辐射算法假设==：所有的间接光都来自于漫反射表面。这个算法在大镜面的环境下失效，但对大部分场景是一个合理的拟合。使用之前说过的标记法，此算法的光传输过程是$LD*E$。

>  [275] Cohen, Michael F., and John R. Wallace, ==Radiosity and Realistic Image Synthesis==, Academic Press Professional, 1993. Cited on p. 442, 483
>
> [1642]  Sillion, Fran¸cois, and Claude Puech, ==Radiosity and Global Illumination==, Morgan Kaufmann, 1994. Cited on p. 442, 483

辐射度法假设每个表面由一些<span style="color:green;font-size:1.3rem">Patches</span>组成。对于每一个较小的区域，它计算一个单一的平均辐射值，所以这些Patches必须足够小才能捕捉到光线的所有细节。此外，它们不需要一一匹配底层的<span style="color:green;font-size:1.3rem">surface triangles</span>，甚至不需要在大小上统一。

从渲染方程开始，我们可以推导Patch i 等于：:arrow_down:
$$
B_i=B_i^e+\rho_{ss}\sum_jF_{ij}B_j
$$
其中，$B_i$是patch i的辐射度，$B_i^e$是<u>辐射出射度</u>` radiant exitance`（自发辐射，类似`emit`），$\rho_{ss}$是 ==subsurface albedo==。只有光源的发射`Emission`是非零的。$F_{ij}$是Patches $i$和$j$间的形状因子`form factor`，它的定义如下：

![image-20201121202209458](RTR4_C11.assets/image-20201121202209458.png)

其中，$A_i$是patch i的区域面积，$V(i,j)$是点i和点j间的可见性函数——中间没有遮挡就是1，否则就是0；角度$\theta_i,\theta_j$是两个patch的法线间的夹角（如下图:arrow_down:），$d_{ij}$是两点间的距离。

![image-20201121202634906](RTR4_C11.assets/image-20201121202634906.png)

形状因子是一个纯粹的几何项，是离开Patch i的均匀漫反射辐射的部分。两块Patch的面积、距离、朝向，以及中间的任意表面都会影响形状因子。==而辐射度方法的重要部分就是：准确地确定场景中成对patch之间的形状因子。==

由于性能等诸多限制，传统的辐射度方法很少使用，但是其预计算形状因子的思想在现代实时全局光照系统很流行，后续会详细介绍。



### 2.2 Ray Tracing

<span style="color:green;font-size:1.3rem">Ray Casting</span>是指从某一位置发射一条射线，来确定特定方向上的物体。而对于<span style="color:green;font-size:1.3rem">Ray Tracing</span>最基本的形式，Ray从相机通过<u>像素网格</u>`pixel grid`进入场景，后面的过程可太经典了，这里就不赘述了。

传统的射线追踪只提供了简单受限的效果集：Sharp反射和折射，以及硬阴影。但是，同样的基本原理可以用于解决完整的渲染方程。Kajiya**[846]**意识到，==射出射线并评估其携带的光量的机制==，可以用来计算方程11.2中的积分。该方程是递归的，这意味着对于每一条光线，我们需要在不同的位置再次评估积分。

幸运的是，处理这个问题的数学基础已经存在——<span style="color:green;font-size:1.3rem">Monte Carlo methods</span>。当光线反弹`Bounce`穿过场景时，就建立了一条路径`path`。沿着每条路径的光，提供了被积函数的一个评估，这个过程称为路径跟踪<span style="color:green;font-size:1.3rem">path tracing</span>。

![image-20201121205653436](RTR4_C11.assets/image-20201121205653436.png)

跟踪路径`Tracing paths`是一个非常强大的概念，它可用于渲染光滑或漫反射材料。使用这个技术，==我们可以生成软阴影，渲染透明物体以及焦散效果==。扩展路径追踪，进行体积采样，还可以处理雾和次表面散射效应。

此技术的唯一缺点是计算过于昂贵。这是因为我们从来不计算积分的实际值，而只计算它的估计值。而采样点过少，则会出现太多噪点，如上图左:arrow_up:。许多方法已经被提出，来提高效果，但不需要增加额外的路径，其中一个流行的技术是<span style="color:green;font-size:1.3rem">重要性抽样</span>，其基本思想是：通过在大部分光线来源的方向射出更多的光线，可以大大减少方差。

一些相关Paper和书籍：

-  a great introduction to modern off-line ray tracing-based techniques。**[1413]**
- 我们将在本章的最后讨论交互速率下的射线和路径跟踪。



## 3. Ambient Occlusion

本章将开始讨论简单但令人信服的实时技术，并逐步过渡到复杂技术。一个基本的全局光照效果就是<span style="color:green;font-size:1.3rem">ambient occlusion，AO</span>。首次是由Industrial Light & Magic公司提出 **[974]**。当光线缺乏方向性变化，无法凸显物体细节时，这种方法可以廉价提供形状信息。



### 3.1 Ambient Occlusion Theory

AO的理论背景可以直接从反射方程得到。为了简化，我们首先只考虑`Lambertian surfaces`。从这种表面发出的辐射度L~o~与表面辐照度E成正比，辐照度是入射辐射度L~i~的余弦加权积分。一般来说，它取决于表面位置p和表面法线n。同样，为了简单起见，我们假设入射辐射是常数，对于所有入射光强方向l，L~i~(l) = L~A~。计算辐照度的公式如下：

![image-20201121214202593](RTR4_C11.assets/image-20201121214202593.png)

上诉公式导致了一个` flat appearance`，且没有考虑可见性。首先进行简单的扩展，只要被阻挡，就设置入射辐射率为0，而不考虑该阻挡表面反射的光，然后，我们得到了由Cook和Torrance首先提出的方程：

![image-20201121215056660](RTR4_C11.assets/image-20201121215056660.png)

![image-20201121215143009](RTR4_C11.assets/image-20201121215143009.png)

==可见度函数的归一化、余弦加权积分称为环境遮挡==：

![image-20201121215322626](RTR4_C11.assets/image-20201121215322626.png)

这个值代表的是半球可见性的余弦加权百分比——0代表被完全遮挡，1代表完全无遮挡。对凸物体进行遮挡计算是无意义的，但对于有孔洞的物体，则是有意义的。一旦定义了k~A~，遮挡存在时的环境辐照度方程为：

![image-20201121220831553](RTR4_C11.assets/image-20201121220831553.png)

比较图11.8:arrow_down:中的表面位置p~0~和p~1~。==表面朝向也有影响==，因为能见度函数要加权余弦因子。

![image-20201121221121917](RTR4_C11.assets/image-20201121221121917.png)