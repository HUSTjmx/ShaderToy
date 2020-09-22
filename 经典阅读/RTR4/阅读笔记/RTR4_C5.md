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

Directional light没什么值得注意的。Point light的距离衰减的物理解释有点意思，如下图：

<img src="https://jmx-paper.oss-cn-beijing.aliyuncs.com/BookReading/RealTimeRending3/Chapter5/2.PNG" style="zoom:50%;" />

由此给出了inverse-square light attenuation
$$
C_{light})(r)=C_{light_0}(\frac{r_0}{r})^2
$$
当然，这个公式有很多问题，第一个问题发生在离光源很近的地方（分母近似为0），解决方法很多，例如：分母加上一个常数项（虚幻的1cm）,或者分母设置成max，给光源加上一个物理半径。

第二个问题，不是表现而是性能，产生于离光源很远的地方（原公式，不管离光源多远，远，光强都不会变为0）。