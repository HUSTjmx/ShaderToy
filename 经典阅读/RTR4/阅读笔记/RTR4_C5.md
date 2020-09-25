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