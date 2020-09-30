# Chapter 5——Shading Basic

本章将讨论那些适用于真实感渲染（photo realistic）和程序化渲染（stylized，非真实渲染？）的着色器Shading的方方面面。

## 1. Shading Models

主要介绍模型着色的基础，其中举了个例子——游戏Fire Watch的渲染风格（a illustrative art style）,如下图

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/BookReading/RealTimeRending3/Chapter5/RTR3_5-1.PNG)

实现公式也较为简单，公式如下：
$$
\begin{align}
C_{shaded}&=s*C_{highlight}+(1-s)(t*C_{warm}+(1-t)C_{cool})\\
C_{cool}&=(0,0,0.55)+0.25*C_{surface}\\
C_{warm}&=(0.3,0.3,0)+0.25C_{surface}\\
C_{highlight}&=(1,1,1)\\
t&=\frac{(n\cdot l)+1}{2}\\
r&=2(n\cdot l)n-l\\
s&=(100(r\cdot  v)-97),\space\in (0,1)
\end{align}
$$
这个例子可以看到：余弦操作是十分常见的，用来描述两个向量法向之间的关系（the degree to which two vectors are aligned with each other）；以及线性插值（mix in shading function）；最后r的计算是最为常见的反射方向的计算。



## 2. Light Sources

对于光源的考虑和使用来说，真实感渲染需要考虑的不仅是直接光源，还需要加入间接光源；而程序化渲染则没有这方面的考量，或者仅仅是利用它来提供一些简单的方向性（directionality）

光源复杂性的下一步的讨论是——物体应该对于光源影响的有无有着不同的外表（A surface shaded with such a model would have one appearance when lit and a different appearance when unaffected by light. ）（这里的光源的影响有无应该指的是——直接光源），书中接下来给出了如下公式：
$$
C_{shaded}=f_{unlit}(n,v)+\sum^{n}_{i=1}{C_{light}f_{lit}(l_i,n,v)}
$$
公式中第一部分，Often, this part of the shading model expresses some form of lighting that does not come directly from explicitly placed light sources，而是来自天空，或者周围物体对于光源的bounce。

接下来的一部分，感觉应该是高光部分和漫反射部分，这里只是简单介绍了f~lit~是常数的情况，然后就光源的类型进行了介绍和分析。

------

Directional light没什么值得注意的。Punctal Light中的Point light的距离衰减的物理解释有点意思，如下图：

<img src="https://jmx-paper.oss-cn-beijing.aliyuncs.com/BookReading/RealTimeRending3/Chapter5/2.PNG" style="zoom:50%;" />

由此给出了inverse-square light attenuation
$$
C_{light})(r)=C_{light_0}(\frac{r_0}{r+\varepsilon})^2
$$
- 当然，这个公式有很多问题，第一个问题发生在离光源很近的地方（分母近似为0），解决方法很多，例如：分母加上一个常数项（虚幻的1cm）,或者分母设置成max，给光源加上一个物理半径。


- 第二个问题，不是表现而是性能，产生于离光源很远的地方（原公式，不管离光源多远，远，光强都不会变为0）。为了使得衰减公式变成0，同时避免突然的shutoff，最好使得函数的导数在相同的位置也变成0，一个虚幻和寒霜都在使用的解决方案如下：

$$
f_{win}(r)=(1-(\frac{r}{r_{max}})^4)^{+2}
$$
​		这个作为乘项和之前的inverse-square相乘即是最终解决方案。他们的曲线如下图：

<img src="https://jmx-paper.oss-cn-beijing.aliyuncs.com/BookReading/RealTimeRending3/Chapter5/3.PNG" style="zoom:50%;" />

- 应用要求将影响到所使用的方法的选择。例如，当距离衰减函数在一个相对较低的空间频率下采样时，导数等于0是特别重要的。f_dist(r)

------

一般的Spotlight的参数定义如下图所示，一般light intensity公式：$c_{light}=c_{light_0}f_{dist}(r)f_{dir}(l)$

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/BookReading/RealTimeRending3/Chapter5/4.PNG)

- Various directional falloff functions are used for spotlights，如下依次是寒霜引擎和？？的实现方法：
  $$
  t=(\frac{cos\theta_{s}-cos\theta_{u}}{cos\theta_{p}-cos\theta_{u}}),\\
  f_{dir_{F}}(l)=t^2\\
  f_{dir_{T}}(l)=t^2(3-2t)
  $$

当然除了上述两种，还有很多其他形式的Punctual Light。对于$f_{dir}$函数来说，除了上述的方案之外，还有很多复杂的方式，IES（Illuminating Engineering Society）为其定义了a standard file format 。

------

还有一些其他类型的灯，有着其他方式计算light direction。例如：古墓丽影中的胶囊灯，将光源视作一个线段而不是点，每次使用离渲染点最近的线段点来计算L。

目前为止讨论的光源都是抽象的，而最近，具有大小和形状的==area Light==在实时渲染中使用的越来越多。区域光技术主要是两个方面：第一个是部分被遮挡的区域光产生的柔和阴影，第二个是整个区域光对于物体表面的作用（对于光滑，mirror-like的物体，这方面的区别是显而易见的）。

未来是区域光的。

> those that simulate the softening of shadow edges that results from the area light being partially occluded  and those that simulate the effect of the area light on surface shading 。



## 3. Implementing Shading Models

这部分主要是对实现公式向编程的方法的关键考量——如何将公式转化为实际可用的Code呢？

 设计一个实现方法，计算应该根据评估频率（frequency of evaluation. ）划分成几部分。首先，判断计算结果在整个Draw Call过程中是否是常数（或者变化十分微小，或者变化的频率很慢），如果是，则应该放在程序（CPU）上计算。

理论上，阴影计算可以在任何一个可编程阶段进行，每个级对应一个不同的评估频率。

- 大家都知道，光照计算主要是在片元着色器中实现，为什么不在顶点着色器呢？这主要是顶点着色器会导致Spec部分的错误（color进行线性插值——错误的高光进行插值不会产生正确的高光）

- 在顶点着色器中，各种几何，变换参数进行归一化的重要性。（否则会如下图所示，插值法线倾向于朝向长度较长的法线，这是明显不对的）

  ![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/BookReading/RealTimeRending3/Chapter5/5.PNG)

------

材质系统最重要的任务之一是将不同的着色器功能划分为单独的元素，并控制它们如何组合。在许多情况下，这种类型的组合是有用的，包括以下情况：

- Composing surface shading with ==geometric processing==, such as rigid transforms,vertex blending, morphing, tessellation, instancing, and clipping. 
- Composing surface shading with ==compositing operations== such as pixel discardand blending. 
- Composing the operations used to compute the shading model parameters with the computation of the shading model itself. 
- Composing the shading model and computation of its parameters with light source evaluation

如果图形API能提供这种类型的着色器代码模块化作为核心功能，那就方便了。遗憾的是，与CPU代码不同，GPU着色器不允许代码片段的编译后链接（post-compilation linking of code fragments. ），The program for each shader stage is compiled as a unit。

早期的渲染系统的shader变体数量相对较少，而且往往每个变体都是手动编写的。这有一些好处。例如，每个变体都可以在充分了解最终着色器的情况下进行优化。然而，随着变体数量的增加，这种方法很快就变得不切实际。当考虑到所有不同的部件和选项，可能的不同着色器变体的数量是巨大的。这就是为什么模块化和可组合性如此重要的原因。

当设计一个处理着色器变体的系统时，首先要解决的问题是，选择是在运行时通过动态分支进行，还是在编译时通过条件预处理进行。如今的GPU对于动态分支（dynamic branch）的处理非常好，但是，这会产生额外的消耗：寄存器计数的增加和占用率的相应降低，从而降低性能。因此，编译时的==Shader Variant==仍然是有价值的。它避免包含永远不会执行的复杂逻辑。

材质系统的设计者思考了如下几种策略去实现这些目标：

+ Subtractive  ：使用编译时预处理器条件（compile-time preprocessor conditionals  ）和动态分支的组合来删除未使用的部分，并在相互排斥的选项之间进行切换。
+ 代码重用：将一些函数写在可分享的文件中，然后其他需要使用的地方使用'#include'
+ Additive  ：个人理解其作用和代表是：shader可视化编辑器。
+ Template-based ：定义了一个接口，不同的实现只要符合该接口，就可以插入其中。一个常见例子是将模型参数的计算和模型本身的计算分开。



## 4. Aliasing and Antialiasing

首先介绍的是 Sampling and Filtering Theory，主要是对==采样、重建、滤波（filtering）==的介绍。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/BookReading/RealTimeRending3/Chapter5/6.PNG)

*Sample*

==采样频率必须是被采样信号最高频率的两倍以上==。这就是通常所说的采样定理（==Nyquist limit==）。相邻采样之间的间隔，信号必须足够平滑。

因为使用point Sample来渲染场景，无论采样频率多高，总有小的物体不会被采样到，所以不可能完全避免走样，但是是可能知道什么时候可以限制采样频率。

> It is possible to compute the frequency of the texture samples compared to the sampling rate of the pixel. If this frequency is lower than the Nyquist limit, then no special action is needed to properly sample the texture. If the frequency is too high, then a variety of algorithms are used  to band-limit the texture 

------



*Reconstruction*

在给定一个受限采样的情况下，我们需要一个合适的filter去重建信号。请注意，滤波器的面积应始终为1，否则重建信号可能会出现增长或收缩，下面是三种常见的filter。Box、Tent、Sinc

<img src="https://jmx-paper.oss-cn-beijing.aliyuncs.com/BookReading/RealTimeRending3/Chapter5/7.PNG" style="zoom: 67%;" />

<img src="https://jmx-paper.oss-cn-beijing.aliyuncs.com/BookReading/RealTimeRending3/Chapter5/8.PNG" style="zoom:67%;" />

<img src="https://jmx-paper.oss-cn-beijing.aliyuncs.com/BookReading/RealTimeRending3/Chapter5/9.PNG" style="zoom:67%;" />

The ideal low-pass filter is the sinc filter :
$$
sinc(x)=\frac{sin(\pi x)}{\pi x}
$$
为什么这个公式是理想的low-pass滤波器呢？采样过程为图像引入了高频部分，而sinc会去除那些频率高于采样频率1/2的部分，具体详见135页。但是其无限的影响区域以及其它问题，导致这个滤波器实际场景用的比较少。目前使用最广泛的几个filter都是对sinc的近似，但是会对他们影响的像素数量进行限制，例如：Gaussian filters

------



*Resampling*

重采样用于放大或缩小一个采样信号。假设初始信号位于单位坐标系上（间隔为一进行采样）。那么在重采样的过程中，采样间隔a>1，则minification（downSampling），否则a<1，导致magnification（upsampling）。

Magnification比较简单：the reconstructed signal has been resampled at double the sample rate。

Minification：the filter width has doubled in order to double the interval between the samples.

<img src="https://jmx-paper.oss-cn-beijing.aliyuncs.com/BookReading/RealTimeRending3/Chapter5/10.PNG" style="zoom:67%;" />

​           

### 4.1 Antialiasing Patterns

这些算法有助于解决图像中颜色剧烈变化处产生的artifacts（采样和过滤的方法不够好）。主要考虑这些因素：quality, ability to capture sharp details or other phenomena, appearance during movement, memory cost, GPU requirements, and speed.

基本思想是：在屏幕上使用取样模式（ sampling pattern ），然后对样本进行加权加和，以产生像素颜色。
$$
p(x,y)=\sum_{i=1}^n{w_ic(i,x,y)}
$$
<img src="https://jmx-paper.oss-cn-beijing.aliyuncs.com/BookReading/RealTimeRending3/Chapter5/11.PNG" style="zoom:67%;" />

每个像素计算一个以上完整样本的抗锯齿算法称为==超采样（或过采样）方法==。

- full-scene antialiasing (==FSAA==，or ==SSAA==)：最为简单，用更高的resolution渲染场景：render an image of 2560 × 2048 offscreen and then average each 2 × 2 pixel area on the screen，for 1280× 1024。还有accumulation buffer的一些内容（详见139）。这是比较早期的抗锯齿方法，比较消耗资源，但简单直接。这种抗锯齿方法先把图像映射到缓存并把它放大，再用超级采样把放大后的图像像素进行采样，一般选取2 个或4 个邻近像素，把这些采样混合起来后，生成的最终像素，令每个像素拥有邻近像素的特征，像素与像素之间的过渡色彩，就变得近似，令图形的边缘色彩过渡趋于平滑。再把最终像素还原回原来大小的图像，并保存到帧缓存也就是显存中，替代原图像存储起来，最后输出到显示器，显示出一帧画面。这样就等于把一幅模糊的大图，通过细腻化后再缩小成清晰的小图。

  > Techniques such as ==supersampling and accumulation buffering== work by generating samples that are fully specified with individually computed shades and depths. The overall gains are relatively low and the cost is high, as each sample has to run through a pixel shader

- Multisampling antialiasing (==MSAA==) ：通过每个像素计算一次surface shader，并在采样之间共享这一结果，从而降低了高计算成本。这是一种特殊的超级采样抗锯齿（SSAA）。MSAA首先来自于OpenGL。具体是MSAA只对Z缓存（Z-Buffer）和模板缓存(Stencil Buffer)中的数据进行超级采样抗锯齿的处理。可以简单理解为只对多边形的边缘进行抗锯齿处理。这样的话，相比SSAA 对画面中所有数据进行处理，MSAA 对资源的消耗需求大大减弱，不过在画质上可能稍有不如SSAA。（基本后面的算法都是在MSAA上做新花样，例如：TXAA，HRAA）、

  [博客详解1](https://zhuanlan.zhihu.com/p/32823370)

  <img src="https://jmx-paper.oss-cn-beijing.aliyuncs.com/BookReading/RealTimeRending3/Chapter5/12.PNG" style="zoom:80%;" />

- Temporal Anti-Aliasing（==TXAA==）：将MSAA、时间滤波以及后期处理相结合，用于呈现更高的视觉保真度。与CG 电影中所采用的技术类似，TXAA 集MSAA 的强大功能与复杂的解析滤镜于一身，可呈现出更加平滑的图像效果。此外，TXAA 还能够对帧之间的整个场景进行抖动采样，以减少闪烁情形，闪烁情形在技术上又称作时间性锯齿。目前，TXAA 有两种模式：TXAA 2X 和TXAA 4X。TXAA 2X 可提供堪比8X MSAA 的视觉保真度，然而所需性能却与2X MSAA 相类似；TXAA 4X 的图像保真度胜过8XMSAA，所需性能仅仅与4X MSAA 相当。

------



***Sampling Patterns***

Effective sampling patterns are a key element in reducing aliasing。45度角，近水平和近垂直边缘的锯齿对人类的干扰最大

- ==RGSS==，旋转栅格超级采样（Rotated Grid Super-Sampling，简称RGSS），是N-rooks的一种形式，如下所示，四个采样点都在不同的列和行上，相对常规的2*2采样，这样更加有利于捕捉近乎水平和垂直的边缘 

  ![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/BookReading/RealTimeRending3/Chapter5/13.PNG)

==亚像素网格形式的采样模式具有一些缺点==，例如：对于像素级的微小物体，进行MSAA之类的采样，会产生严重的伪影，因为这种等级的采样频率根本无法完美Capture它们。一个解决方法是==stochastic sampling==：Having a less ordered sampling pattern can break up these patterns. 。随机化倾向于用噪声代替重复的混叠现象，而人类的视觉系统对这种现象是比较宽容的。总结起来就是：每个像素使用不同德抗锯齿算法，例如2X MSAA，TXAA，2X2 RGSS，Quincunx的随机选取使用。

- ==Quincunx==（HRAA）：英伟达提出的一种实时，采样影响不只一个像素的抗锯齿思想。意思是5个物体的排列方式，其中4个在正方形角上，第五个在正方形中心。四个角的采样值被最对四个像素使用，至于权重，则是中心点为$\frac{1}{2}$，边缘采样点为$\frac{1}{8}$，平均下来，一个像素两次采样。

  ![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/BookReading/RealTimeRending3/Chapter5/14.PNG)

  ==FILPQUAD==：结合HRAA和RGSS，如下图。而且，也可以用在TXAA上，而且发现FLIPQUAD模式是多种测试中最好的。

  <img src="https://jmx-paper.oss-cn-beijing.aliyuncs.com/BookReading/RealTimeRending3/Chapter5/15.PNG" style="zoom: 80%;" />

------



*Morphological* Methods

锯齿多产生于几何、硬阴影、亮光等边界处。2009年，Reshetov提出了一种以此为根据的新算法——MLAA（morphological antialiasing ）。Rsa的研究目标在于找到MS方法的替代品，着重寻找和重建边缘。==MLAA==：“Morphological means  relating to structure or shape.” ，这个技术作为==后处理==（正常渲染，然后对此结果进行处理）来进行。大概流程如下：找到似乎是边界的地方（对周围的像素进行分析，给出边界的可能性，下图中），然后处理他（根据覆盖值处理颜色，下图右）

![](C:\Users\Cooler\Desktop\JMX\ShaderToy\经典阅读\RTR4\阅读笔记\RTR4_C5.assets\16.PNG)

近几年，利用深度、法线等额外的Buffer，发展了很多抗锯齿技术：SRAA（subpixel reconstruction antialiasing ，仅对几何边界进行抗锯齿），GBAA（geometry buffer antialiasing ），DEAA（distance-to-edge antialiasing ）

- ==DLAA==（directionally localized antialiasing ）：基于这样的观察：接近垂直的边缘应该在水平方向上模糊，同样接近水平方向上模糊

  应该在垂直方向上模糊。

Iourcha提出根据MSAA的采样结果来寻找边界，以此得到更好的结果。例如，一种每个像素采样四次的技术只能为一个对象的边缘提供五个层次的混合。估计边缘位置可以有更多的位置，从而提供更好的结果。这些方法统称为 image-based 算法。

==基于图像的算法面对几个挑战==：首先，颜色差异太小会导致边界识别失败；多个物体覆盖的像素进行插值是困难的；颜色剧烈变化的地方也可能导致寻边失败；文本应用会导致质量下降；物体的变角会变得圆润。单个像素的变化会导致边缘重建的方式发生较大的变化，从而在帧与帧之间产生明显的伪影。改善这一问题的一种方法是使用MSAA覆盖掩模来改进边缘确定

其中，最流行的两种算法是：==FXAA（fast approximate antialiasing ）和SMAA（subpixel morphological antialiasing ）==，流行的部分原因其高度的可移植性。这两个算法都使用 color-only input，SMAA还有着acess（控制）MSAA采样的优点。自然，也能结合到TXAA中。



##  5.Transparency, Alpha, andCompositing

从算法的角度去看允许光通过自身的半透明物体，可以分为两种效果：Light-based ，使光衰减或转向（diverted），造成场景的其它物体被lit而渲染不一样的物体；View-based，指那些半透明物体自身被渲染的。本节主要简单介绍

