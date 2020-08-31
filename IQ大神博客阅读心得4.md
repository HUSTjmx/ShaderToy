## `IQ大神博客阅读心得4

*<u>蒋孟贤，2020.05，Useful Maths</u>*

| [Thinking with Quaternions](#Thinking-with-Quaternions)      | 四元树的基本知识和一些思考                               |
| ------------------------------------------------------------ | -------------------------------------------------------- |
| [Sphere Ambient Occlusion](#Sphere-Ambient-Occlusion)        | 球的环境光遮蔽，一个好的思路，产生的简单却有效的实验结果 |
| [Working with Ellipses](#Working-with-Ellipses)              | 椭圆包围盒以及椭圆相交测试算法                           |
| [Sphere Visibility](#Sphere-Visibility)                      | 球体的可见性                                             |
| [Patched Sphere](#Patched-Sphere)                            | 球的UV坐标的合理计算                                     |
| [Fourier Series](#Fourier-Series)                            | 傅里叶曲线拟合                                           |
| [**Normal and Areas of N-sided Polygons**](#Normal-and-Areas-of-N-sided-Polygons) | **计算多边形的法向量和面积的巧妙思路和方法**             |
| [Distance to An Ellipse](#Distance-to-An-Ellipse)            | 计算点到椭圆的距离                                       |
| [A Sin/Cos Trick](#A-Sin/Cos-Trick)                          | 简单的三角函数讨论                                       |
| [**Inverse Bilinear Interpolation**](#Inverse Bilinear Interpolation) | **UV坐标的获取，线性插值的反过程**                       |
| [Area of A Triangle](#Area-of-A-Triangle)                    | 三角形面积的其他快速求解                                 |
| [**Distance Estimation**](#Distance Estimation)              | **平面函数的距离的一般求解**                             |
| [Sphere Projection](#Sphere-Projection)                      | LOD的简单方法                                            |
| [Distance to Triangle](#Distance to Triangle)                | 3D空间中计算点到物体·的距离，但核心是我对实例的分析      |
| [Sphere Density](#Sphere-Density)                            | 球体光的简单实现                                         |
| **[Disk and Cylinder Bounding Box](#Disk-and-Cylinder-Bounding-Box)** | 圆盘、圆柱、圆台的包围盒计算的一般方法                   |
| [Inverse Smoothstep](#Inverse-Smoothstep)                    | 求立体SM的反函数                                         |
| [Bezier Bounding Box](#Bezier-Bounding-Box)                  | 二次以及三次贝塞尔曲线包围盒的求法                       |
|                                                              |                                                          |



#### Thinking with Quaternions

对于四元数，咱们都知道在计算机图形学中一般是用来进行旋转的。一个四元数有一个实部和三个虚部，如果将虚部打包，则可以看作一个实部和一个三维向量。
$$
q=\{w,x,y,z\}=\{w,v\}=w+x\cdot i+y\cdot j+z\cdot k
$$
如果要绕方向为a的轴旋转w角，对于四元数有如下：
$$
q=\{cos(w/2),a\cdot sin(w/2) \}
$$
IQ在这里指出，对于四元数的指数有如下规则：
$$
q^t=\{cos(w/2),a\cdot sin(w/2)\}^t=\{cos(w\cdot t/2),a\cdot sin(w\cdot t/2)\}
$$
自乘四元数t与将角度乘以t是一样的(即使这种解释对于t的非整数值有点棘手)。。我们知道将两个旋转连接起来可以通过将两个相应的四元数相乘来实现。因此，我们需要记住的只是下表的前两行

|       | Angular Space | Quaternion Space  |
| ----- | ------------- | ----------------- |
| Add   | a+b           | q~a~*q~b~         |
| Scale | a*t           | q~a~^t^           |
| Mad   | a+b*t         | q~a~q~b~^t^       |
| Lerp  | a*t+b(1-t)    | q~a~^t^*q~b~^1-t^ |

现在，我们可以轻松地将任何我们想要执行的angular操作转换成正确的四元数操作。只要用乘法/除法来代替加法/减法，用幂/根来代替乘法/除法，就做完了。这个角和四元数运算之间的关系很像线性运算和对数运算之间的关系(比如拉普拉斯变换)……实际上，这是有原因的，因为四元数是复数的一般化，而这样的标准化四元数是纯粹的复指数(pure complex exponentials)的一般化，因此对数关系变得明显。实际上，如果我们有以下的标准化四元数，使旋转轴为a={1,0,0}，我们有
$$
q_{w,(1,0,0)}=cos(w/2)+i\cdot sin(w/2)=e^{i\cdot w/2}
$$

------





#### Sphere Ambient Occlusion

这篇文章是关于分析计算一个球体到任意表面上一点的遮挡。AO的定义比较简单，可以理解为irradiance的相反量，这里，IQ使用的是Block version。这里的问题是找到**一个半径为r的球体的阻塞因子**，这个球和表面点的距离为d。现在我们不需要法向量和球的位置之间的夹角，因为这与阻塞因子无关。
$$
ir(r,d)=1-bl(r,d)
$$
现在，**阻碍因子是球体投射到半球的面积除以半球的面积**。如果球体的投影(阴影)覆盖了整个半球，那么两个区域相等，因此阻塞因子为1。(这里也很好理解，比如说：一个点离这个表面点很近，那么这个点对应球的投影面积就很接近半球的面积，那么此时bl越接近1，那么Ir就接近0，这个方向的光的贡献就很低。这也符合咱们的尝试，反之，若是大部分点都离这个表面点很远，那么这么推算下来，这个点的AO应该不大)
$$
bl(r,d)=\frac{A_{pr}(r,d)}{A_{hs}}=\frac{A_{pr}(r,d)}{2\pi}
$$
假设半球的半径为1，则半球的面积为pi的两倍。 使用单位半径是一件很不错的事情，因为我们可以交换面积和立体角的概念（球体上物体投影的面积就是其立体角乘以球体半径的平方）。 立体角以球面度表示（即使它是无单位量度）。 该图显示了问题的设置。 蓝色球体通过黄色圆锥体向粉红色半球投射阴影。 我们必须计算球体（由圆锥和半球的交点绘制的小圆圈）的立体角w。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/gfx_02_p.jpg)

物体的立体角按下式计算。积分遍历投影“阴影”的物体（在我们的例子中是球体）的所有表面。这个公式背后的思想并不复杂：我们需要取每一个表面元素（微分）dA（注意，它是一个具有表面方向的矢量，并且对面积的微分度量进行模运算），然后将它与位置矢量作点积。这样，指向我们的点的部分，表面会比那些垂直的部分遮挡更多，这很有意义。这些表面元素的贡献除以距离r的平方来计算球体的投影面积，自然，离物体越远的点有着越小的投影面积。
$$
w=\int_{S}\frac{d\hat{A}\cdot \hat{n}}{r^2}
$$
我们认识到，由球面投射出的阴影与由球面与圆锥相交形成的圆盘投射出的阴影是相同的。基本上，我们可以改变积分在那个磁盘上运行，这将使我们的计算更容易。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/gfx_01_p.jpg)
$$
R=\frac{r}{d}\sqrt{d^2-r^2}\\
D=\frac{1}{d}(d^2-r^2)
$$
对于圆，显然我们应该采取极坐标。所以,表面的积分将是由一个二重积分,一个沿径向轴从圆的中心到边境,和另一个是沿圆的周长。φ角，λ距离中心的磁盘。然后，重新定义r为三角形的斜边。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/gfx_04_p.png)
$$
\begin{align}
d\hat{A}\cdot \hat{n}&=|dA|cos\beta\\
cos\beta&=\frac{D}{r}\\
|dA|&=\lambda\cdot d\varphi\cdot d\lambda
\end{align}
$$
然后，结果是：
$$
w=\int_{0}^{2\pi}\int_0^R{\frac{D\lambda\cdot d\lambda\cdot d\varphi}{(D^2+\lambda^2)^{3/2}}}=2\pi D\int^R_0\frac{\lambda\cdot d\lambda}{(D^2+\lambda^2)^{3/2}}=2\pi D[\frac{-1}{\sqrt{D^2+\lambda^2}}]^R_0=2\pi(1-\frac{1}{\sqrt{1+(R/D)^2}})
$$
将r，d带入替代R，D
$$
bl(r,d)=1-\sqrt{1-(r/d)^2}
$$
然而，这个结果在物理上是不正确的，因为我们知道从侧面来的光对我们的影响比直接从上面来的光要小。所以，下一步就是解决这个问题。我们需要把余弦项包含到积分里。这将产生这样的效果，如果圆盘是在点的正上方，它将挡住更多的光，即使投射的面积与它在其他任何地方的投影面积相同。现在我们需要知道圆盘相对于曲面法向量的位置。我们必须注意正确地积分磁盘表面。首先注意，我称当前积分点和向上方向之间的夹角为。这是lambert cos项的角度。然后，通过重复利用我们在之前的分析中得到的，我们得到:
$$
w=\int_{0}^{2\pi}\int_0^R{\frac{D\lambda\cdot d\lambda\cdot d\varphi\cdot cos\alpha}{(D^2+\lambda^2)^{3/2}}}
$$
![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/gfx_05_p.png)
$$
cos\alpha=\frac{D\cdot cos\alpha_s-sin\alpha_s\cdot cos\varphi}{\sqrt{D^2+\lambda^2}}
$$
重新计算有如下结果（具体推算参见博客）
$$
bl(r,d)=cos\alpha_s(r/d)^2
$$
在ShaderToy内写的一个[小测试](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E4%BB%A3%E7%A0%81/Math/SphAO.shader)

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/%E7%90%83AO.PNG)

------





#### Working with Ellipses

平面椭圆对计算机图形学非常有用。例如，当你用平面切割一个圆柱体时，它们就会出现。它们也出现在使用喷溅算法( splatting algorithm)绘制点云时，或者在光线跟踪点云时。它们还可以帮助实时环境遮挡和间接照明计算（where occluders can be approximated by a pointcloud.）。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/gfx_00.png)

任何在椭圆边界上的点可以表示如下：
$$
p(w)=c+u\cdot cos(w)+v\cdot sin(w)
$$
椭圆的边界框必须与这个边界相切。这个切点将是边界方程的最大和最小的x、y和z坐标。我们需要找到方程的最大值/最小值。我们知道我们可以通过求出导数为0的点来得到它们。所以,
$$
p^`(w)=-u\cdot \sin(w)+v\cdot \cos(w)
$$
三个坐标都必须等于0，首先，定义$$\lambda=cos(w)$$，然后解决x坐标
$$
-\sqrt{1-\lambda^2}\cdot u_x+\lambda\cdot v_x=0
$$
得到
$$
cosw=\frac{u_x}{\sqrt{u_x^2+v_x^2}}\space\space\space\space
 sinw=\frac{v_x}{\sqrt{u_x^2+v_x^2}}
$$
所以
$$
p_x=c_x\pm \sqrt{u_x^2+v_x^2}
$$
最终，边界盒可以计算如下：

$$
bbox=c_x\pm\sqrt{u_x^2+v_x^2},c_x\pm\sqrt{u_x^2+v_x^2},c_y\pm\sqrt{u_y^2+v_y^2},c_z\pm\sqrt{u_z^2+v_z^2}
$$
GLSL类型代码比较简单

```c#
bound3 EllipseAABB( in vec3 c, in vec3 u, in vec3 v )
{
    vec3 e = sqrt( u*u + v*v );
    return bound3( c-e, c+e );
}
```

和椭圆边界相似，椭圆内部的点可以定义为
$$
p(\lambda,\gamma)=c+u\cdot \lambda+v\cdot \gamma\space\space\space\space and
\space\space\space\space
\lambda^2+\gamma^2\leq1
$$
我们假设射线的定义为$$p(t)=r_o+t\cdot r_d$$，且交点毫无疑问需要保证，两者相等，于是有：

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/gfx_12.png)

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/1.PNG)

代码内，可以表示为：

```c#
float iEllipse( in vec3 ro, in vec3 rd,           // ray: origin, direction
                in vec3 c, in vec3 u, in vec3 v ) // disk: center, 1st axis, 2nd axis
{
    vec3 q = ro - c;
    vec3 r = vec3(
        dot( cross(u,v), q ),
        dot( cross(q,u), rd ),
        dot( cross(v,q), rd ) ) / 
        dot( cross(v,u), rd );
    return (dot(r.yz,r.yz)<1.0) ? r.x : -1.0;
}
```

测试例子[如下](https://www.shadertoy.com/view/Xtjczw)

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/2.PNG)

------





#### Sphere Visibility

我们从以下构造开始（如左图所示）。令**c**为摄影机位置（我们假设它不在两个球体的任何一个内）。中心位置为**o**，半径为**R**的大球体是遮挡物（我们的星球）。位置为**o'**且半径为**R'**的小球体是我们要测试其遮挡的对象的边界球体。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/gfx00.png)

关键观察结果是，只要*γ>α+β*，小球体将是可见的或部分可见的。当然，这没有考虑到小球体位于相机和行星之间的情况，但是稍后我们将分别处理。使用角度工作总是一个坏主意，不仅涉及昂贵的逆三角函数，而且由于2π处的角度值换行等原因，它们也容易出错。只使用向量（向量永不说谎！）更可取。因此，我们通过在两侧都取余弦来转换先前的条件（余弦总是矢量的点积！）：
$$
cos(\gamma)<cos(\alpha+\beta)=cos(\alpha)\cdot cos(\beta)-sin(\alpha)\cdot sin(\beta)
$$
![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/for03.png)
$$
D=|o-c|\space\space\space\space D^`=|o^`-c|
$$
让我们设置$$k=cos(\gamma)$$，因此有
$$
kDD^`-RR^`<\sqrt{(R^2-D^2)(R^{`2}-D^{`2})}
$$
让我们假设
$$
k_1=\frac{R}{D}\space\space\space k2=\frac{R^`}{D^`}
$$
我们可以通过$$k>k_1k_2$$来测试左部的符号，最终的判断为：
$$
k_1^2+k^2_2<1-k^2+2k\cdot k_1\cdot k_2
$$
代码形式大致如下：

```c#
//下面的式子相当于将最终式左右两边各乘了一个DD`
int sphereVisibility( in vec3 ca, in float ra, in vec3 cb, float rb, in vec3 c )
{
    //D1*D1
    float aa = dot(ca-c,ca-c);
    //D2*D2
    float bb = dot(cb-c,cb-c);
    //D1*D2*cosa[k]
    float ab = dot(ca-c,cb-c);
    //ab*ab+D2*r1*r1+D1*r2*r2-D1*D2
    float s = ab*ab + ra*ra*bb + rb*rb*aa - aa*bb;
    //2*ab*r1*r2
    float t = 2.0*ab*ra*rb;

    //完全不遮蔽
    if( s + t < 0.0 ) return 1;
    //部分遮蔽
    else if( s - t < 0.0 ) return 2;
    //完全遮蔽
    return 3;
}
```

[测试例子](https://www.shadertoy.com/view/XdS3Rt)

------



#### Patched Sphere

每个人都知道如何生成一个多边形球…但并不是每个人都知道如何制作好的多边形球体。由于极坐标是球体的自然参数化，因此常借助于极坐标来构造球体和纹理映射坐标。问题是参数化在极点有奇点，并且映射对极点周围的环境有很强的收缩性(高阶导数)，这使得它对纹理映射毫无用处(纹理在那里被拉伸了很多)。它还导致薄三角形出现在极点(除非使用两个参数的非均匀采样)，这可以在右侧的图像中看到。极坐标参数化有更多的缺点;例如，它涉及到三角函数，这意味着如果一个人想要计算到曲面的切线(例如法向映射)，就必须使用更多的三角函数，这些函数通常太昂贵，不能在实时着色器中滥用。

所以，当球体的自然参数化是极坐标化的时候，我们可能会想要使用一些其他的东西，而不是用一种物质主义的明显的思维方式。在这里，我们将使用分段代数参数化（有利于快速着色器的执行），这将减少参数空间失真（有利于纹理）。最重要的是，几乎所有编写过cube map纹理抓取程序的人都对它很熟悉。

例如，由于立方体的每个面都有一个简单的矩形参数化（0,1）x（0,1），我们也会自动得到球体的一个简单的参数化域。本文的其余部分是关于这种参数化的，以及如何解析地提取相应的切线空间基向量，以一种精确而廉价的方式，甚至在必要时按像素提取。

我们从立方体的一个面开始（实际上，所有的文章都将处理六个面中的一个，其他面遵循相同的步骤）。例如+z面（我假设是OpenGL坐标系，也就是你在学校学到的：x=右，y=上，z=朝你）。设面域的两个参数为s和t，取值区间为[0,1]。我们希望我们的立方体以原点为中心，取值范围为[-1,1]，因此我们的表面点p表示为:
$$
p(s,t)=(1-2s,1-2t,1)
$$

接下来，我们对立方体表面上的这个点进行归一化，得到球面上的一个点q：
$$
q(s,t)=\frac{p(s,t)}{|p(s,t)|}=\frac{1}{k}=(1-2s,1-2t,1)
\\
where\space\space\space k^2=3+4(s^2-s+t^2-t)\\
q(s,t)=\frac{1}{k}(x,y,1) \space\space with \space\space x=1-2s\space\space y=1-2t \space\space k^2=x^2+y^2+1
$$
现在我们知道了球面的实际情况，是时候计算它的切线空间了。实际上，我们将计算一个切线空间基，使得它的基向量遵循纹理坐标参数化，这就是你需要做的法向/凹凸映射。基本上，表面的切向量将与球面的方向导数对齐。当然，我们也可以测量关于x和y的变化，所以让我们使用它们，因为它们更容易处理。对x的导数得到tanu，对y的导数得到第二个tanv（有时称为副法线），注意，这两个向量不一定是互相正交的，尽管它们是线性无关的，它们会定义一个球面的切平面，当然也会正交于曲面的法向量n。我们开始做数学题，对x和y求导得到u和v:
$$
\begin{align}
u&=\partial q/\partial x=\frac{1}{k\sqrt{k}}(1+y^2,-xy,-x)
\\
v&=\partial q/\partial y=\frac{1}{k\sqrt{k}}(-xy,1+x^2,-y)
\end{align}
$$
如果只对切基向量的方向感兴趣，那么就可以跳过公因数到三个分量。通过替换变量，表达式变得更容易编码（将前面的K去掉）





#### Fourier Series

你可能还记得代数课上的一个想法:取一个向量（或函数或信号）f，和一组轴（或“坐标系”或“基”），把f写成这些轴的线性组合
$$
f=\sum_{n}a_n\varphi_n
$$
a~n~可以称为向量f的坐标值。我们可以选择任何坐标系统（勒让德多项式或简单泰勒级数,等等）。但是,我们保证轴是互相正交的。同时，我们的坐标系,它的轴随着n的增加，显示越来越多的细节。实际上是一个非常受欢迎的坐标系统，满足这些需求：三角函数（即sin和cos系列，这里写作为更紧凑的复指数）
$$
\varphi_n(x)=e^{jnx}
$$
这些是傅里叶级数（就像它们的许多表亲一样——DFT, DCT，球面谐波，拉普拉斯，等等）。每个轴相互垂直，可以通过点生成任意两个轴来手动检查

计算a~m~如下：
$$
(\overline{\varphi}_m\cdot f)=\sum_{n}a_n\delta_{n,m}=a_m
$$
[链接](https://www.shadertoy.com/view/4lGSDw)

------





#### Normal and Areas of N sided Polygons

在寻求大小优化时，始终建议应用一些基本代数并扩展表达式，然后尝试以不同的方式再次分解它们，以查看是否可以用较少的代码来表示相同的结果（通常以准确性为代价） ）。计算多边形法线和面积就是其中一种情况（例如，对于网格）。

对于三角形ABC而言，正如我们之前阅读博客所意识到的，三角形面积等于法线模的一半
$$
\begin{align}
normal(A,B,C)&=(B-A)\times(C-A)=A\times B+B\times C+C\times A\\
area(A,B,C)&=|normal(A,B,C)|/2
\end{align}
$$
也就是三角形每点的叉乘的和。我们可以通过按顺序和循环遍历所有顶点来求值，然后对下面的顶点做叉乘。这不仅是计算三角形法线的另一种有趣的方法，而且它还涉及到对具有更多边的多边形的某种泛化

让我们定义一个四边形ABCD。我们将计算它的表面积和法线，作为组成它的两个三角形的area和法线的和。只要两个三角形是共面并且定义了一个实的四边形，这对于表面积和法线来说都是可行的。如果它们不这样做，两个法线的加法将只是四轴飞行器的平均法线。无论如何，我们有:
$$
\begin{align}
normal(A,B,C,D)&=normal(A,B,D)+normal(B,C,D)\\
&=A\times B+B\times D+D\times A+B\times C+C\times D+D\times B\\
&=A\times B+B\times C+C \times D+D\times A
\end{align}
$$
它也是一个循环的按字母顺序排序的多边形每边叉乘的和。好了!
$$
area(A,B,C,D)=|normal(A,B,C,D)|/2
$$
有趣的是，四边形的法向/面积也可以表示为对角线的交叉：(A-C)x(B-D)

事实上，这对于n边的多边形是成立的。你可以通过画一个五边形，然后一个六边形，并概括这个概念来很容易地证明这一点。**结果是，对于n个顶点vi, i={0,1,2，…n-1}形成多边形：**
$$
normal(v_0,v_1,...,v_{n-1})=\sum v_i\times v_{i+1}
$$

------





#### Distance to An Ellipse

通常情况下，椭圆通常比圆难不了多少，而且人们可以分析和容易地计算它们的许多属性，比如它们的[边界框和交点](#Working-with-Ellipses)。然而，有些属性的计算要比预期的复杂一些。其中一个属性是点到椭圆的距离，在2D中!

平面上一个点$$z=(x,y)$$，和一个参数化的椭圆e（中点在原点，在x，y轴上的参数为a，b）：$$e(w)=\{a\cdot\cos{w},b\cdot \sin{w}\}$$，那么从z到椭圆的距离为：
$$
s^2(w)=|e(w)-z|^2
$$
拓展开为：
$$
\begin{align}
s^2(w)&=|e(w)|^2+|z|^2-2<e(w),z>\\
&=a^2\cdot cos^2w+b^2\cdot sin^2w+x^2+y^2-2ax\cdot cosw-2by\cdot sinw
\end{align}
$$
最近的点是：
$$
\frac{ds^2(w)}{dw}=0
\\....\\
(b^2-a^2)\cdot sinw\cdot cosw+ax\cdot sinw-by\cdot cosw=0
\\
if \space\space \lambda=cos(w)\\
\sqrt{1-\lambda^2}((b^2-a^2)\lambda+ax)=by\lambda
$$
左右两边平方，展开为四次方程，其系数如下：
$$
\begin{align}
k_4&=(b^2-a^2)^2\\
k_3&=2ax(b^2-a^2)\\
k_2&=(a^2x^2+b^2y^2)-(b^2-a^2)^2\\
k_1&=-2ax(b^2-a^2)\\
k_0&=-a^2x^2

\end{align}
$$
或者通过将方程除以领先系数k~4~（椭圆不是圆，k~4~不为零），然后令$$m=x\frac{a}{b^2-a^2}\space\space\space n=y\frac{b}{b^2-a^2}$$，
$$
\begin{align}
k_4&=1\\
k_3&=2m\\
k_2&=m^2+n^2-1\\
k_1&=-2m\\
k_0&=-m^2
\end{align}
$$
在此基础上，用标准方法对四次方程进行解析求解。由于系数中的对称性，我们得到了一些很好的简化。例如，解析三次方程失去了它的线性项，然后降为
$$
z^3-3Qz+2R=0\\
with\\
Q=(\frac{m^2+n^2-1}{3})^2\space\space\space R=2m^2n^2+(\frac{m^2+n^2-1}{3})^3
$$

```c#
float sdEllipse( in vec2 z, in vec2 ab )
{
    vec3 p = abs( z ); if( p.x > p.y ){ p=p.yx; ab=ab.yx; }
	
    float l = ab.y*ab.y - ab.x*ab.x;
    float m = ab.x*p.x/l; float m2 = m*m;
    float n = ab.y*p.y/l; float n2 = n*n;
    float c = (m2 + n2 - 1.0)/3.0; float c3 = c*c*c;
    float q = c3 + m2*n2*2.0;
    float d = c3 + m2*n2;
    float g = m + m*n2;

    float co;

    if( d<0.0 )
    {
        float p = acos(q/c3)/3.0;
        float s = cos(p);
        float t = sin(p)*sqrt(3.0);
        float rx = sqrt( -c*(s + t + 2.0) + m2 );
        float ry = sqrt( -c*(s - t + 2.0) + m2 );
        co = ( ry + sign(l)*rx + abs(g)/(rx*ry) - m)/2.0;
    }
    else
    {
        float h = 2.0*m*n*sqrt( d );
        float s = sign(q+h)*pow( abs(q+h), 1.0/3.0 );
        float u = sign(q-h)*pow( abs(q-h), 1.0/3.0 );
        float rx = -s - u - c*4.0 + 2.0*m2;
        float ry = (s - u)*sqrt(3.0);
        float rm = sqrt( rx*rx + ry*ry );
        float p = ry/sqrt(rm-rx);
        co = (p + 2.0*g/rm - m)/2.0;
    }

    float si = sqrt( 1.0 - co*co );
 
    vec2 closestPoint = vec2( ab.x*co, ab.y*si );
	
    return length(closestPoint - p ) * sign(p.y-closestPoint.y);
}
```

[测试应用](https://www.shadertoy.com/view/4sS3zz)

------



#### A Sin/Cos Trick

$$
sin(\alpha+\beta)=sin\alpha\cdot cos\beta+cos\alpha\cdot sin\beta\\
cos(\alpha+\beta)=cos\alpha cos\beta-sin\alpha\cdot sin\beta
$$

当你在一张纸上画出一个三角形的旋转时，这个公式自然就出现了。事实上，当我需要把这个公式写下来的时候，我就是这么做的。在本教程进行到一半时，这种解释就会很明显了。但是现在，为了让事情变得有趣，并延迟发现的时刻，让我们首先思考一下为什么我们会关心这个公式。

我们开始以增量的方式写循环：给定一个循环的迭代n，它的当前阶段是t，下一个迭代n+1将计算sin(t+f)和cos (t+f)，换句话说，我们已经计算了sin(t)和cos(t)，现在我们需要计算sin(t+f)和cos(t+f)

<details>
    <summary>代码</summary>
    <pre><code>
        const float f = 2.0f*PI/(float)num;
		const float t = 0.0f;
		for( int n=0; n < num; n++ )
		{
    		const float s = sinf(t);
    		const float c = cosf(t);
   			 ...
    		t += f;
		}
    </code></pre>
</details>

对于本文来说，计算t的确切方式并不重要，它的取值范围也不重要（在上面的例子中是0到2）。我们唯一关心的是有一个循环反复调用sin和cos，其参数以常数步递增（在本例中为2·PI/num）。本文讨论如何优化这段代码，以提高速度，使相同的计算可以在完全不使用sin或cos函数的情况下执行（在内部循环中），甚至不使用更快的sincos()函数。

因为f是常数，所以用a和b代替cos(f)和sin(f)，此时代码如下：

<details>
    <summary>代码</summary>
    <pre><code>
        const float f = 2.0f*PI/(float)num;
        const float a = cosf(f);
        const float b = sinf(f);
        float s = 0.0f;
        float c = 1.0f;
        for(int n=0;n < num;n++)
        {
            const float ns = b*c + a*s;
            const float nc = a*c - b*s;
            c = nc;
            s = ns;
        }
    </code></pre>
</details>

到目前为止，我们一直在盲目地玩弄数学等式，而没有真正看到我们在做什么。让我们首先重写内部循环这样：
$$
s_{n+1}=s_n\cdot a+c_n\cdot b\\
c_{n+1}=c_n\cdot a-s_n\cdot b
$$
们有些人可能已经注意到这只是二维旋转的公式。如果你还不认识它，也许它的形式可能会有帮助：
$$
\left[\matrix{
s_{n+1}\\
c_{n+1}
}\right]
= 
\left[\matrix{
  a & b\\
  -b & a\\
}\right]\cdot
\left[\matrix{s_n\\c_n}\right]
$$
实际上，sin(t)和cos(t)可以组成长度为1的向量（并在屏幕上作为一个点绘制）。我们称它为x：
$$
x=(sin\beta,cos\beta)
$$
那么，上面这个表达式的向量形式是这样的：
$$
x_{n+1}=R\cdot x_n
$$

------



#### Inverse Bilinear Interpolation

你可能已经不止一次地在四边形中做过双线性插值了。假设你有一个随机的、任意维数的四边形ABCD。四边形内任意点X坐标，通过一组坐标（u，v）计算出P，Q点，再通过P，Q进行线性插值。这样的好处是可以通过相同的规则得到x处的任意数据。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/gfx00IBI.png)
$$
P=A+(B-A)\cdot u\\
Q=D+(C-D)\cdot u\\
X=P+(Q-P)\cdot v
$$
因此：

$$
X(u,v)=A+(B-A)\cdot u+(D-A)\cdot v+(A-B+C-D)\cdot u\cdot v
$$
我们想要知道提取出双线性参数u和v是什么?简单的答案是我们只要解这个方程然后分离出参数u和v。上面的方程实际上是适用于所有的坐标系统，这意味着顶点D实际上是二维或者3三维的向量。所以方程组是可解的。为了让事情变得更简单，我们引入一些中间变量，比如：
$$
\begin{align}
E&=B-A\\
F&=D-A\\
G&=A-B+C-D\\
H&=X-A=E\cdot u+F\cdot V+G\cdot u\cdot v
\end{align}
$$
现在，我们选择任意两个坐标进行计算。可能最好的选择是使用二维平面，我们的四边形在直角投影下有更大的表面积。假设我们选择轴i和j
$$
u=(Hi-Fi\cdot v)/(Ei+Gi\cdot v)
$$
回带进方程有：
$$
Hj\cdot Ei+Hj\cdot Gi\cdot v=Ej\cdot Hi-Ej\cdot Fi\cdot v+Fj\cdot Ei\cdot v+Fj\cdot Gi\cdot v^2+Gj\cdot Hi\cdot v-Gj\cdot Fi\cdot v^2
$$
这是一个二次方程，其系数为
$$
\begin{align}
k2&=Gi* Fj-Gj*Fi\\
k1&=Ei*Fj-Ej*Fi+Hi*Gj-Hj*Gi\\
k0&=Hi*Ej-Hj*Ei
\end{align}
$$
常解为
$$
v=\frac{-k1\pm\sqrt{k1^2-4\cdot k0\cdot k2}}{2\cdot k2}
$$
如果X在四边形内，$$k1^2-4k0k2$$则通常是正的。一旦我们有了v，就可以使用第一个变量隔离步骤中使用的表达式来计算u。

```c#
float sdSegment( in vec2 p, in vec2 a, in vec2 b )
{
	vec2 pa = p - a;
	vec2 ba = b - a;
	float h = clamp( dot(pa,ba)/dot(ba,ba), 0.0, 1.0 );
	return length( pa - ba*h );
}
vec2 IBI(in vec2 P,in vec2 A,in vec2 B,in vec2 C,in vec2 D)
{
    vec2 E=B-A;
    vec2 F=D-A;
    vec2 G=A-B+C-D;
    vec2 H=P-A;
    
    float k2=G.x*F.y-G.y*F.x;
    float k1=E.x*F.y-E.y*F.x+H.x*G.y-H.y*G.x;
    float k0=H.x*E.y-H.y*E.x;
    
    float beta=k1*k1-4.*k0*k2;
    if(beta<0.)return vec2(-1.);
    beta=sqrt(beta);
    
    float v=(-1.*k1+beta)/(2.*k2);
    if(v<0.||v>1.)v=(-1.*k1-beta)/(2.*k2);
    if(v<0.||v>1.)return vec2(-1.);
    
    float u=(H.x-F.x*v)/(E.x+G.x*v);
    if(u>1.||u<0.)return vec2(-1.);
    return vec2(u,v);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 p=(2.*fragCoord-iResolution.xy)/iResolution.y;
    
    //四个点
    vec2 a = cos( 1.11*iTime + vec2(0.1,4.0) );
    vec2 b = cos( 1.13*iTime + vec2(1.0,3.0) );
    vec2 c = cos( 1.17*iTime + vec2(2.0,2.0) );
    vec2 d = cos( 1.15*iTime + vec2(3.0,1.0) );

    vec2 uv=IBI(p,a,b,c,d);
    vec3 col=vec3(0.4,0.4,0.4)+vec3(.2,.2,.2)*length(p);
    
    if(uv.x>-.5)
    {
        col=texture(iChannel0,uv).xyz;
    }
    
    
    float h=1./iResolution.y;
    col=mix(col,vec3(.1,.1,.9),1.-smoothstep(h,3.*h,sdSegment(p,a,b)));
    col=mix(col,vec3(.1,.1,.9),1.-smoothstep(h,3.*h,sdSegment(p,b,c)));
    col=mix(col,vec3(.1,.1,.9),1.-smoothstep(h,3.*h,sdSegment(p,c,d)));
    col=mix(col,vec3(.1,.1,.9),1.-smoothstep(h,3.*h,sdSegment(p,d,a)));
    
    fragColor=vec4(col,1.);
    
}
```

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/GIF%202020-04-23%2016-06-54.gif)





#### Area of A Triangle

除了之前一直反复提及的双边叉乘的模的一半以为，还有Heron公式，它根据边长给出面积：
$$
S^2=s\cdot(s-a)\cdot(s-b)\cdot(s-c)
$$
其中，s是三角形的周长的一半
$$
S^2=(a+b+c)\cdot(-a+b+c)\cdot(a-b+c)\cdot(a+b-c)/16
$$

$$
S^2=(2a^2b^2+2b^2c^2+2c^2a^2-a^4-b^4-c^4)
$$

这里的讨论思路是，直接看Heron公式，由于a，b，c是边长，需要昂贵的开根号操作，作者这里发现了一个显而易见但难以注意到的问题，就是将这个式子展开后，只有偶次项，那么我们就不需要进行开根号操作了。

------



#### Distance Estimation

通常，需要计算到隐式标量字段f(x)定义的等值面之间的距离。这发生在太多的情况下，例如在julia集合或任何常规距离场、光栅化函数或呈现2d分形中，仅举几例。在本文中将解释计算等值面距离的常用方法，以及如何避免在呈现过程性图形时经常出现的一个恼人问题—the compression and shrinking of your pattern.

假设你用了一个随机的隐函数，假设我们用这个函数来画一个形状（定义为f = 0等值面）。让我们以一个简单的公式为例：
$$
f(r,a)=r-1+\sin{(3a+2r^2)}/2
$$
和之前UV坐标重映射一样，$$r=\sqrt{x^2+y^2},a=atan(y,x)$$，也就是说f最终是x和y笛卡尔坐标的函数。这个公式产生了一个简单的3叶扇子形状。

<details>
    <summary>简单的测试代码</summary>
    <pre><code>
        float f(float r,float a)
        {
            return r-1.+sin(3.*a+2.*r*r)/2.;
        }
        float color(float r,float a,in vec2 p)
        {
            float col=0.4+0.2*length(p);
            float w=abs(f(r,a));
            float h=1./iResolution.y;
            col=mix(0.1,col,smoothstep(h,10.*h,w*w));
            return col;
        }
        void mainImage( out vec4 fragColor, in vec2 fragCoord )
        {
            vec2 p=(fragCoord*2.-iResolution.xy)/iResolution.y*2.;
            float r=length(p);
            float a=atan(p.y,p.x);
            vec3 col=vec3(color(r,a,p));
            fragColor = vec4(col,1.0);
        }
    </code></pre>
</details>

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/GIF%202020-04-23%2017-12-48.gif)

也许你会对常数厚度轮廓图像更感兴趣，可能是基于更均匀的标量场。事实上，如果你能计算到f的0等值线的距离（现在您可能已经看到了它与基于距离的raymarching的关系，并且尝试寻找与零等值面的交点）。也许，你会对能够计算出像下边这样的图像感兴趣。让我们看看如何实现这一点!

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/gfx03X.jpg)

计算在空间的给定点x处（黄点）到*f = 0*形状的距离。到等值线的距离是到红点的距离，这是等值线中最接近黄点的点。让我们称最近的红点为*x + e*，这样*e*是从黄点到红点的矢量。我们在这里追求的是*| e |*，即*e*的长度，即从*x*到等值线/等值面的距离。在此设置中，由于*x + e*在0等值线中，我们显然有
$$
f(x+\varepsilon)=0
$$
假设我们很接近它的形状，也就是说，|e|很小。然后在泰勒分解中展开f(x+e)：
$$
f(x+\varepsilon)=f(x)+\nabla{f(x)}\cdot\varepsilon+O(|e|^2)
$$
如果我们足够接近，那么我们就可以用f的线性近似来证明：
$$
0=|f(x+\varepsilon)|\approx|f(x)+\nabla{f(x)}\cdot\varepsilon|\\
0\geq|f(x)|-|\nabla f(x)\cdot\varepsilon|\geq|f(x)|-|\nabla f(x)|\cdot|\varepsilon|\\
|\varepsilon|\geq\frac{|f(x)|}{|\nabla f(x)|}
$$
 这就给出了f从x到0等值面的估计距离的上界。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/gfx05S.jpg)

我们只需要f(x)的梯度。对于上面例子中的函数，我们有以下代码:

```c#
vec2 grad( vec2 x )												 
{
    float r = length(x);
    float a = atan(x.y,x.x);
    vec2 da = vec2(x.y,-x.x)/(r*r);
    return (x/r) + (1.5*da+2.0*x)*cos(3.0*a+2.0*r*r);
}
```

然而，在大多数情况下，我们不会得到函数f的解析梯度向量，所以我们不得不使用常规的中心差分法进行数值逼近

```c#
vec2 grad( in vec2 x )
{
    vec2 h = vec2( 0.01, 0.0 );
    return vec2( f(x+h.xy) - f(x-h.xy),
                 f(x+h.yx) - f(x-h.yx) )/(2.0*h.x);
}
```

这种方法在计算一维函数的距离时很有优势。实际上，f的梯度垂直于它的tan /导数，所以它简化为(1,f')使得距离估计更加简单.
$$
de(x,y)=\frac{|f(x)-y|}{\sqrt{1+(\frac{df(x)}{dx})^2}}
$$
[测试用例](https://www.shadertoy.com/view/MdfGWn)

<details>
    <summary>代码随笔</summary>
    <pre><code>
        vec2 grad1( vec2 x )												 
        {
            float r = length(x);
            float a = atan(x.y,x.x);
            vec2 da = vec2(x.y,-x.x)/(r*r);
            return (x/r) + (1.5*da+2.0*x)*cos(3.0*a+2.0*r*r);
        }
        float f(float r,float a)
        {
            return r-1.+sin(3.*a+2.*r*r)/2.;
        }
        float color(float r,float a,in vec2 p)
        {
            float col=0.4+0.2*length(p);
            float w=abs(f(r,a));
            vec2 g=grad1(p);
            w=w/length(g);
            float h=1./iResolution.y;
            col=mix(0.1,col,smoothstep(h,10.*h,w));
            return col;
        }
        void mainImage( out vec4 fragColor, in vec2 fragCoord )
        {
            vec2 p=(fragCoord*2.-iResolution.xy)/iResolution.y*2.;
            float r=length(p);
            float a=atan(p.y,p.x);
            vec3 col=vec3(color(r,a,p));
            fragColor = vec4(col,1.0);
        }
    </code></pre>
</details>

------



#### Sphere Projection

在计算机图形学中，你经常想知道一个物体在屏幕上看起来有多大，可能是用像素来测量的。或者至少您希望拥有像素覆盖率的上限，因为这允许您为该对象执行详细级别(LOD)。例如，如果一个字符或一棵树只是屏幕上的几个像素，那么您可能希望用更少的细节来呈现它们。

获取像素覆盖上限的一个简单方法是将对象嵌入一个边界框或球体中，对球体或球体进行栅格化并计算像素的数量。但该技术仍然只能在某些情况下应用。例如，如果一个镶嵌着色器或一个几何着色器能够基于像素覆盖动态地镶嵌或杀死几何图形。

一个(边界)球体的像素覆盖恰好有解析表达式，可以用不超过一个平方根来求解，非常紧凑。。本文就是关于这种解析式快速边界球屏幕覆盖计算的。

在不损失通用性的情况下，我们将在摄像机空间中工作（原点在摄像机位置，z轴指向视图方向）。以位置o为中心的球面上的所有点x和半径r被描述为：
$$
|x-o|^2-r^2=0
$$
通过针孔摄像机的光线中的所有点经过视图平面中的一个点(x, y)得到描述
$$
x=t\cdot d\space\space\space\space d=\frac{(x,y,f_1)}{\sqrt{x^2+y^2+f_1^2}}
$$
其中f~1~是焦距，我们已经确定了射线的归一化使得|d|=1。如果射线与球面相交，则视图平面上的一个点被球面的投影覆盖。这可以通过用x代替上面球面方程中的射线来计算，从而得到经典的t的二次方程：
$$
t^2+2bt+c=0\\
b=-o\cdot d\\
c=|o|^2-r^2
$$
如果要想方程有实数解，毫无疑问，保证$$\Delta=b^2-c$$不小于0，拓展开为：
$$
（o_xx+o_yy+o_zf_1）^2-(|o|^2-r^2)(x^2+y^2+f_1^2)\geq0
$$
系数合并为：
$$
ax^2+by^2+cxy+dx+ey+f\geq0
$$
​                                              ![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/for07.png)     

这就是椭圆的隐式定义，因为
$$
c^2-4ab=-(r^2-|o|^2)(r^2-o_z^2)
$$

这个量总是小于0，只要球面不包含原点/摄像机，只要球面原点和视点的Z分量至少被球面半径隔开。所以这个不等式标记了平面上的所有点（如果你想的话，也可以是屏幕上的像素点），这些点将得到球面的投影(将被光栅化)。现在我们必须找到一种方法来计算这些像素!

幸运的是，如果我们知道椭圆的几何性质，就可以很容易地计算出它们的面积。计算椭圆中心的方法有很多种，例如，可以使隐式的导数等于0：
$$
\frac{df}{dx}=2ax+cy+d=0 \space\space\space\space \frac{df}{dy}=2by+cx+e=0
$$
推出：
$$
ce=\frac{(2bd-ce,2ae-cd)}{c^2-4ab}\\
ce=o_{xy}\frac{o_zf_1}{o_z^2-r^2}
$$
非常紧凑。一旦得到了中心，就可以通过改变变量把整个隐函数转换成原点。然后，需要执行一个旋转。椭圆的轴将分别与(x,y)和(-y,x)方向对齐(或(d,e)和(-e,d)方向对齐。可以通过除以来标准化这些向量来获得：
$$
\sqrt{d^2+e^2}=2f_1o_z|o_{xy}|
$$
一旦完成了旋转，一旦椭圆的轴与坐标系统对齐，即椭圆符合标准形式，就可以像往常一样计算轴的长度和面积。

```c#
float projectSphere( in vec4 sph,  // sphere in world space
                     in mat4 cam,  // camera matrix (world to camera)
                     in float fl ) // projection (focal length)
{
    // transform to camera space
    vec3  o = (cam*vec4(sph.xyz,1.0)).xyz;

    float r2 = sph.w*sph.w;
    float z2 = o.z*o.z;
    float l2 = dot(o,o);
	return -3.14159*fl*fl*r2*sqrt(abs((l2-r2)/(r2-z2)))/(r2-z2);
}

```

[IQ例子](https://www.shadertoy.com/view/XdBGzd)

------





#### Distance to Triangle

在3D中计算到三角形的距离并不困难，但是我经常看到太复杂的代码，有太多的平方根和分支。这是我的实现，我喜欢并在Shader Toy的raymarching实验中使用了它。

主要是分为两种情况：1.点的投影在三角形内，则距离就是点到平面的距离。2.点的投影在三角形外，则距离就是点到边的最短距离。

```C#
float dot2( in vec3 v ) { return dot(v,v); }

float udTriangle( in vec3 v1, in vec3 v2, in vec3 v3, in vec3 p )
{
    // prepare data    
    vec3 v21 = v2 - v1; vec3 p1 = p - v1;
    vec3 v32 = v3 - v2; vec3 p2 = p - v2;
    vec3 v13 = v1 - v3; vec3 p3 = p - v3;
    vec3 nor = cross( v21, v13 );

    return sqrt( // inside/outside test    
                 (sign(dot(cross(v21,nor),p1)) + 
                  sign(dot(cross(v32,nor),p2)) + 
                  sign(dot(cross(v13,nor),p3))<2.0) 
                  ?
                  // 3 edges    
                  min( min( 
                  dot2(v21*clamp(dot(v21,p1)/dot2(v21),0.0,1.0)-p1), 
                  dot2(v32*clamp(dot(v32,p2)/dot2(v32),0.0,1.0)-p2) ), 
                  dot2(v13*clamp(dot(v13,p3)/dot2(v13),0.0,1.0)-p3) )
                  :
                  // 1 face    
                  dot(nor,p1)*dot(nor,p1)/dot2(nor) );
}
```

[IQ用例](https://www.shadertoy.com/view/4sXXRN)

这里对于源代码进行解析，Map函数不需要解析

+ intersect函数：这里为什么需要循环50次呢，你尝试把循环次数设置为1，会发现图像变成纯色基本上，为什么呢？对于大多数点来说，他们不在三角形上，那么第一次循环，他们会获得距离h(离三角形某个边的距离)，这个时候，这些点对应的射线才打到半空中，既没有命中地面，也没有飞到无限远处，这个时候就结束循环，他们也成为了三角形内部点，所以，我们发现将次数改成10次就有了好的效果，但是三角形边缘很不稳定，这也是很容易想到原因的——次数太少，而离三角形很近的逃离点的速度是小于其他逃离点，这个时候他们尚未飞远，所以可能误认为是三角形点。

  - <details>
        <summary>代码</summary>
        <pre><code>
        float intersect( in vec3 ro, in vec3 rd )
    	{
            const float maxd = 100.0;
            float h = 1.0;
            float t = 0.0;
            for( int i=0; i<100; i++ )
            {
                if( h<0.001 || t>maxd ) break;
                h = map( ro+rd*t );
                t += h;
            }
            if( t>maxd ) t=-1.0;
            return t;
    	}
        </code></pre>
    </details>

+ CalNormal：调用六次Map，简单差分计算法线

  + <details>
        <summary>代码</summary>
        <pre><code>
        vec3 calcNormal( in vec3 pos )
        {
            vec3 eps = vec3(0.002,0.0,0.0);
            return normalize( vec3(
                   map(pos+eps.xyy) - map(pos-eps.xyy),
                   map(pos+eps.yxy) - map(pos-eps.yxy),
                   map(pos+eps.yyx) - map(pos-eps.yyx) ) );
        }
        </code></pre>
    </details>

+ calcSoftshadow：往灯的方向调用Map的简单思路。（h是位移增量，t是总位移）这里的核心问题是res的求解，clamp函数的使用，容易理解，而且在t的迭代过程中，限制了最小值为0.01，这加快了收敛速度，回到res，对于h/t，阴影点会越来越小，乘以k也无所谓，依然很小，但是对于逃离的点来说，他们的h/t会在某个中间位置取到最小值，但这个最小值小于1是肯定的，所以我们需要乘上一个k保证它大于1，而两者中的过渡区域，随着k的减小出现阴影的原因也明了了——他们的最小值随着越接近三角形，越小，这个时候小的k是无法保证h/t的值大于1的（话说这短短几行代码，特别是k的作用，看了我好久，哎），所以会出现的软阴影，而且k越小，软阴影越大越淡。

  + <details>
        <summary>代码</summary>
        <pre><code>
        float calcSoftshadow( in vec3 ro, in vec3 rd, float k )
        {
            float res = 1.0;
            float t = 0.0;
            float h = 1.0;
            for( int i=0; i<=100; i++ )
            {
                h = map(ro + rd*t);
                res = min( res, k*h/t);
                t += clamp( h, 0.01, 1.0 );
                if( h<0.0001 ) break;
            }
            return clamp(res,0.0,1.0);
        }
        </code></pre>
    </details>

+ calcOcclusion：环境光遮蔽的实现很简单，就是简单的往法线法向，随距离增加采样5个点，依据采样点到采样物体的距离hr和采样点到投射阴影物体距离dd，进行比较，将相减结果加到中间变量中。

  + <details>
        <summary>代码</summary>
        <pre><code>
        float calcOcclusion( in vec3 pos, in vec3 nor )
        {
            float occ = 0.0;
            float sca = 1.0;
            for( int i=0; i<5; i++ )
            {
                float hr = 0.02 + 0.025*float(i*i);
                vec3 aopos =  nor * hr + pos;
                float dd = map( aopos );
                occ += -(dd-hr)*sca;
                sca *= 0.95;
            }
            return 1.0 - clamp( occ, 0.0, 1.0 );
        }
        </code></pre>
    </details>

------



#### Sphere Density

有时，您需要在CG图像的某些区域中选择性地进行一些像素颜色处理。通常，这可以在二维上或更一般地通过照明来完成。确实，虽然效果工作室在进行实景动作和逼真的渲染时将照明视为实现真实感和可信度的一种方式，但动画工作室却将照明视为在屏幕上绘画色彩的一种方式，从而使他们实现自己的艺术视野。Point-lights, rods, and volumes become brushes really。但是，许多基于光的着色技术缺乏厚度或没有参与介质的感觉-它们仅影响表面，而不会影响它们之间的空间。在本文中，我们将看到如何开发一种体积工具，您可以使用该工具来实现这种着色技术，或实现简单的传统雾化，但是要在空间中进行局部化。

我们的想法是，我们要在空间中的某个位置放置一个球体，并沿着体积内的视线累积一些参与的介质密度。然后使用该累积量来驱动某种视觉效果（例如像雾一样简单，或者像图像失真，色彩渐变，纹理化或某种程序效果一样复杂。但这一切都始于在片段或空间中累积媒体的密度。在这篇文章中，我们将看到如何解析实现这一点在没有raymarching的情况下，而只用几个数学运算。

第一步是检测当前像素是否与球形体积重叠，如果不重叠则提前跳过。我们可以通过一个简单的射线球相交测试来做到这一点。如果发生相交，则我们有兴趣知道射线与球体的入口和出口点，以便稍后可以沿球体内的射线段积分雾量。这个过程非常简单，我们在下面的段落中仅作参考说明

对于空间内的一个点x，和一个以sc为中心，sr为半径的球：
$$
|x-sc|=r
$$
以及一个射线定义为
$$
x=ro+t*rd
$$
带入前式，并拓展有：
$$
t^2+t\cdot2<rd,ro-sc>+|ro-sc|^2-r^2=0
$$
对于二次方程而言，求解是小学知识$$t=-b\pm\sqrt{b^2-c}$$

一旦我们用**t**设置了入口点和出口点，我们就准备好对雾进行积分了。在此之前，我们只需要考虑球体完全位于摄影机后面（**t2 <0.0**）或完全隐藏在depth buffer之后（**t1** > **buffer**）的情况。然后，我们必须裁剪该片段，以便仅从摄像机位置向前进行积分，而不会超出深度缓冲区所指示的深度，可以执行以下操作：
$$
\begin{align}
T_1&=max(-b-h,0)\\
T_2&=min(-b+h,depthbuffer)
\end{align}
$$
我们现在可以沿着这段积分雾了。我们可以从多种雾密度函数中选择。我们选择了一个在球体中心密度最大(1.0)的地方达到峰值，然后二次衰减，直到球体表面达到零。
$$
D(x)=1-\frac{|x-sc|^2}{r^2}
$$
这个函数很容易分析积：
$$
F=\int_{T_1}^{T_2}D(t)dt=\frac{-1}{r^2}[ct+bt^2+\frac{t^3}{3}]^{T_2}_{T_1}
$$
现在可以方便地对积累的雾进行归一化，使它在极端情况下取值1，即射线从它的中心一直从它的表面到背面。在这个几何构型中我们有c=0和b=-r：
$$
F_{max}=\{c=0,b=-r\}=4/3r
$$
最后的公式为：
$$
NF=F/F_{max}=\frac{-3}{4r^3}[ct+bt^2+\frac{t^3}{3}]^{T_2}_{T_1}
$$
As a curiosity, note than when the sphere does not overlap with the camera or the scene, then
$$
NF_{full}=\{T_2-T_1=2h\}=(\frac{h}{r})^3
$$
这些结果几乎可以用代码实现。在此之前，值得注意的是，可以通过将整个问题重铸到单位球体（以原点为中心，半径为1）来获得一些浮点精度，在这种情况下，最终实现为：

[爱是一道光，绿的人发慌](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E4%BB%A3%E7%A0%81/Math/SphereDensity.shader)

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/GIF%202020-04-24%2017-02-52.gif)







####  Disk and Cylinder Bounding Box

计算不同几何图元的轴对齐包围盒（AABB）对于碰撞检测和渲染算法很有用。尤其是，磁盘是用于splatting and global illumination lighting algorithms，来表示远处的几何图形和点云渲染的通用图元。因此，能够计算出任意定向的磁盘的最紧密的轴向对齐边界框非常重要，特别是如果可以快速且分析地完成它而不必遍历磁盘的外围时。幸运的是，存在这样一种紧密形式的表达式。

椭圆由其中心，半径和两个正交切线轴定义，[则可以精确地计算3D空间中任意定向的椭圆的边界框](#Working-with-Ellipses)，
$$
bbox=c_x\pm\sqrt{u_x^2+v_x^2},c_y\pm\sqrt{u_y^2+v_y^2},c_z\pm\sqrt{u_z^2+v_z^2}
$$
磁盘通常由单个方向矢量（或法向）定义，而不是由两个（不同大小）的轴定义。解决此问题的一种方法是坚持我们的磁盘法线，然后通过将法线与一些非平行向量互积来计算两个正交法线向量。但是，尽管这很好用，但似乎浪费了计算，并且在数学上不佳（因此不令人满意），因为似乎没有必要使用任意向量来执行确定性计算。

为此，我的解决方案是首先注意将法向量与规范**i**，**j**或**k**交叉轴产生不同的一对轴和不同的数学表达式，但由于磁盘是唯一的，因此它们中的三个应落在相同的数字边界框结果上。这意味着将三个计算实际开发为三个不同的表达式并将它们组合为一个表达式仍然是有效的解决方案，但应通过仅选择三个轴之一来消除您所获得的所有不对称性。

让我们看看。对于给定的磁盘方向或法线**n** =（**x**，**y**，**z**），构造与**n**相交的基向量**u**和**v**具有三个规范轴（1,0,0），（0,1,0）和（0,0,1）的结果如下：
$$
u_i=(1,0,0)\times(x,y,z)\space\space\space v_i=u_i\times(x,y,z)\\
u_j=(0,1,0)\times(x,y,z)\space\space\space v_j=u_j\times(x,y,z)\\
u_k=(0,0,1)\times(x,y,z)\space\space\space v_k=u_k\times(x,y,z)
$$
考虑到|n|=1，将得到以下结果：

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/BBOX1.PNG)

具体推导可以见博客，最终结果为
$$
bbox(c,r,n)=c\pm r\cdot \sqrt{1-n^2}
$$

```c#
struct bound3
{
    vec3 mMin;
    vec3 mMax;
};

// bounding box for a disk defined by cen(ter), nor(mal), rad(ius)
bound3 DiskAABB( in vec3 cen, in vec3 nor, float rad )
{
    vec3 e = rad*sqrt( 1.0 - nor*nor );
    return bound3( cen-e, cen+e );
}
```

拓展，圆柱的包围盒

<details>
    <summary>代码</summary>
    <pre><code>
    bound3 CylinderAABB( in vec3 pa, in vec3 pb, in float ra )
    {
        vec3 a = pb - pa;
        vec3 e = ra*sqrt( 1.0 - a*a/dot(a,a) );
        return bound3( min( pa - e, pb - e ),
                       max( pa + e, pb + e ) );
    }
    </code></pre>
</details>

圆锥体的包围盒计算

<details>
    <summary>代码</summary>
    <pre><code>
    bound3 ConeAABB( in vec3 pa, in vec3 pb, in float ra, in float rb )
    {
        vec3 a = pb - pa;
        vec3 e = sqrt( 1.0 - a*a/dot(a,a) );
        return bound3( min( pa - e*ra, pb - e*rb ),
                       max( pa + e*ra, pb + e*rb ) );
    }
    </code></pre>
</details>

[IQ例子](https://www.shadertoy.com/view/MtcXRf)





#### Inverse Smoothstep

The cubic smoothstep() is simply, after remapping and clamping
$$
y(x)=x^2(3-2x)
$$
求反函数，需要求解三次方程

$$
x(y)=2x^3-3x^2+y
$$
[推导](http://www.iquilezles.org/www/articles/ismoothstep/ismoothstep.htm)，结果如下：
$$
\begin{align}
\phi&=asin(1-2*y)\\
x&=0.5-sin(\phi/3)
\end{align}
$$

```c#
float inverse_smoothstep( float y )
{
    return 0.5 - sin(asin(1.0-2.0*y)/3.0);
}
```

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/Math/InSm.PNG)

<details>
    <summary>代码</summary>
    <pre><code>
    float Smoothstep(float x)
    {
        return x*x*(3.-2.*x);
    }
    float InverseSmoothstep(float y)
    {
        return .5-sin(asin(1.-2.*y)/3.);
    }
    void mainImage( out vec4 fragColor, in vec2 fragCoord )
    {
        vec2 p=fragCoord/iResolution.y;
        p.x=p.x-.4;
        vec3 col=vec3(0.2)+vec3(0.02*mod(floor(5.*p.x)+floor(5.*p.y),2.));
        vec3 c1=vec3(0.7,0.7,0.);
        float w1=Smoothstep(p.x);
        float step=1./iResolution.y;
        col=mix(c1,col,smoothstep(1.*step,2.*step,abs(p.y-w1)));
        vec3 c2=vec3(0.0,0.7,0.7);
        float w2=InverseSmoothstep(p.x);
        col=mix(c2,col,smoothstep(1.*step,2.*step,abs(p.y-w2)));
        col=mix(vec3(0.6),col,smoothstep(1.*step,2.*step,abs(p.y-p.x)));
        col=mix(vec3(0,0,0),col,smoothstep(0.,0.,p.x));
        col=mix(vec3(0,0,0),col,smoothstep(0.,0.0,(1.-p.x)));
        fragColor=vec4(col,1.0);
    }
    </code></pre>
</details>



#### Bezier Bounding Box

贝塞尔曲线是计算机图形的有用图元。从头发到字体，它们几乎无处不在。快速使他们的边界盒计算机对于保持它们在空间上的组织以便快速查询或评估很重要。尽管对bbox的简单近似是微不足道的（例如计算其控制点的边界框），但在本文中，我们通过分析得出了确切的边界框。

对于2次贝塞尔曲线，我们有
$$
p(t)=(1-t)^2p_0+2(1-t)t\cdot p_1+t^2\cdot p_2
$$
为了求解包围盒，我们有它的导数为0，可以获得：
$$
t=\frac{p_0-p_1}{p_0-2p_1+p_2}
$$

```c#
vec4 bboxBezier(in vec2 p0, in vec2 p1, in vec2 p2 )
{
    vec2 mi = min(p0,p2);
    vec2 ma = max(p0,p2);

    if( p1.x<mi.x || p1.x>ma.x || p1.y<mi.y || p1.y>ma.y )
    {
        vec2 t = clamp((p0-p1)/(p0-2.0*p1+p2),0.0,1.0);
        vec2 s = 1.0 - t;
        vec2 q = s*s*p0 + 2.0*s*t*p1 + t*t*p2;
        mi = min(mi,q);
        ma = max(ma,q);
    }
    
    return vec4( mi, ma );
}

```

对于三次贝塞尔曲线，过程和上面相同
$$
\begin{align}
t&=\frac{-b\pm \sqrt{b^2-ac}}{a}\\
a&=-p_0+3p_1-3p_2+p_3
\\
b&=p_0-2p_1+p_2\\
c&=-p_0+p_1
\end{align}
$$

<details>
    <summary>代码</summary>
    <pre><code>
   vec4 bboxBezier(in vec2 p0, in vec2 p1, in vec2 p2, in vec3 p3 )
    {
        vec2 mi = min(p0,p3);
        vec2 ma = max(p0,p3);
        vec2 c = -1.0*p0 + 1.0*p1;
        vec2 b =  1.0*p0 - 2.0*p1 + 1.0*p2;
        vec2 a = -1.0*p0 + 3.0*p1 - 3.0*p2 + 1.0*p3;
        vec2 h = b*b - a*c;
        if( h.x > 0.0 )
        {
            h.x = sqrt(h.x);
            float t = (-b.x - h.x)/a.x;
            if( t>0.0 && t<1.0 )
            {
                float s = 1.0-t;
                float q = s*s*s*p0.x + 3.0*s*s*t*p1.x + 3.0*s*t*t*p2.x + t*t*t*p3.x;
                mi.x = min(mi.x,q);
                ma.x = max(ma.x,q);
            }
            t = (-b.x + h.x)/a.x;
            if( t>0.0 && t<1.0 )
            {
                float s = 1.0-t;
                float q = s*s*s*p0.x + 3.0*s*s*t*p1.x + 3.0*s*t*t*p2.x + t*t*t*p3.x;
                mi.x = min(mi.x,q);
                ma.x = max(ma.x,q);
            }
        }
        if( h.y>0.0 )
        {
            h.y = sqrt(h.y);
            float t = (-b.y - h.y)/a.y;
            if( t>0.0 && t<1.0 )
            {
                float s = 1.0-t;
                float q = s*s*s*p0.y + 3.0*s*s*t*p1.y + 3.0*s*t*t*p2.y + t*t*t*p3.y;
                mi.y = min(mi.y,q);
                ma.y = max(ma.y,q);
            }
            t = (-b.y + h.y)/a.y;
            if( t>0.0 && t<1.0 )
            {
                float s = 1.0-t;
                float q = s*s*s*p0.y + 3.0*s*s*t*p1.y + 3.0*s*t*t*p2.y + t*t*t*p3.y;
                mi.y = min(mi.y,q);
                ma.y = max(ma.y,q);
            }
        }
        return vec4( mi, ma );
    }
    </code></pre>
</details>