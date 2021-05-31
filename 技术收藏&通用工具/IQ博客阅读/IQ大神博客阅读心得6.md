# IQ大神博客阅读心得6

| 名称                                                         | 简介                                                         |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| [Filtering Procedural Textures](#Filtering-Procedural-Textures) | 过程纹理的过滤采样的一般方法；除噪                           |
| [Directional Derivative](#Directional-Derivative)            | ==方向导数的分析==，由此得到的云等场景中光照的加速计算思路   |
| [Sphere Soft Shadow](#Sphere-Soft-Shadow)                    | ==球体的软阴影==的简单实现                                   |
| [Normals For An SDF](#Normals-For-An-SDF)                    | 在RayMarching中对于距离场函数构建的模型进行==法线计算==的方法 |
| [Texturing and Raymarching](#Texturing-and-Raymarching)      | 在射线步进中的LOD，MinMap问题。没怎么看懂                    |
| [Texture Repetition](#Texture-Repetition)                    | 防止纹理平铺重复的三个技巧                                   |
| [Ellipsoid](#Ellipsoid)                                      | 椭球体的距离场函数的几个方法                                 |
| [SDF Bounding Volumes](#SDF-Bounding-Volumes)                | 复杂角色的距离场的近似技术（简单速览）                       |
| [Interior SDFs](#Interior-SDFs)                              | 正确内部场的计算思路                                         |
|                                                              |                                                              |





## Filtering Procedural Textures

程序纹理/着色是计算机图形学中的强大工具。它对存储的要求很低，而且不具有拼贴性，并且其自然的适应几何形状的能力使它对许多应用程序都非常有吸引力。但是，与基于位图（bitmap）的纹理方法不同，位图通过mipmap过滤可以轻松避免混叠，而程序模式很难抗锯齿，这在某些情况下会破坏设计的重点。

本文介绍了一种实现过程模式的过滤/抗锯齿的简单方法，该方法不需要手动进行细节钳位，也不需要将图案支持到位图纹理中，这基本上是一种蛮力方法。当然，以前已经使用过这种方法，但是它似乎并不流行。但是，我发现它在实践中表现良好，并且在如今复杂的照明模型中，这种过滤方法似乎很有用。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/PS.PNG)

==The Filtering==

显而易见的解决方案是超采样。唯一需要注意的就是正确地执行它，即自适应——不要过度采样，不要欠采样。幸运的是，这个问题是计算机图形学中的一个老问题，很久以前就为我们解决了：过滤器足迹（*filter footprints*）。这是GPU在着色器中访问纹理像素时，用来选择纹理的正确Mipmap级别的技术。最后，对于给定的图像像素，我们需要知道它覆盖了纹理或图案的多少面积。

当使用位图纹理时，该问题可以表述为“我们的纹理中确实有多少纹理像素落在此像素之下”。实际上必须取所有这些纹理像素并将其平均为一种颜色，因为像素只能存储一种颜色。所谓的mipmap中以不同的纹理像素数预先计算的（平均或积分），

对于没有经过缓存/位图烘焙过程的过程模式，由于我们没有预先计算的纹理像素，因此无法执行这种预先集成/预先计算。因此，我们必须委托集成，直到图案/阴影生成时间（即渲染时间）为止。至于过滤器宽度的计算，在位图文本和过程模式之间不会改变。

因此，让我们先关注过滤，然后再关注过滤器占用空间。假设我们确实有一个名为*sampleTexture（）*的过程模式/纹理，如下所示：

```c#
vec3 sampleTexture( in vec3 uvw );
```

```c#
// sample a procedural pattern with filtering
vec3 sampleTextureWithFilter( in vec3 uvw, in vec3 uvwX, in vec3 uvwY, in float detail )
{
    int sx = 1 + iclamp( int( detail*length(uvwX-uvw) ), 0, MaxSamples-1 );
    int sy = 1 + iclamp( int( detail*length(uvwY-uvw) ), 0, MaxSamples-1 );

    vec3 no = vec3( 0.0f );

    for( int j=0; j < sy; j++ )
    for( int i=0; i < sx; i++ )
    {
        vec2 st = vec2( float(i), float(j) )/vec2(float(sx),float(sy));
        no += sampleTexture( uvw + st.x * (ddx_uvw-uvw) + st.y*(ddy_uvw-uvw) );
    }

    return no / float(sx*sy);
}
```

在调用此函数之前，我们首先对于当前坐标fragCoord在X，Y轴进行偏移

```c#
calcRayForPixel( fragCoord.xy + vec2(1.0,0.0), ddx_ro, ddx_rd );
calcRayForPixel( fragCoord.xy + vec2(0.0,1.0), ddy_ro, ddy_rd );
```

然后在相交测试之后，我们依据上述结果进行射线微分的计算（与切平面相交来计算），关于这个计算，我的理解是，如图，除法的结果就是红色除以绿色，依据这个倍数延长射线，与切线平面相交。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/render%20techniques/%E6%89%8B%E7%BB%98.png)

```c#
vec3 ddx_pos = ddx_ro - ddx_rd*dot(ddx_ro-pos,nor)/dot(ddx_rd,nor);
vec3 ddy_pos = ddy_ro - ddy_rd*dot(ddy_ro-pos,nor)/dot(ddy_rd,nor);
```

然后计算纹理采样足迹

```c#
vec3 texCoords( in vec3 p )
{
	return 64.0*p;
}
vec3     uvw = texCoords(     pos );
vec3 ddx_uvw = texCoords( ddx_pos );
vec3 ddy_uvw = texCoords( ddy_pos );
```

最后调用之前的那个函数。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/render%20techniques/filter.PNG)

[测试案例](https://www.shadertoy.com/view/MdjGR1)







## Directional Derivative

> [梯度与方向导数](https://www.cnblogs.com/key1994/p/11503840.html)
>
> - 方向导数的本质是一个数值，简单来说其定义为：一个函数沿指定方向的变化率。
> - 梯度与方向导数是有本质区别的，梯度其实是一个向量，其定义为：一个函数对于其自变量分别求偏导数，这些偏导数所组成的向量就是函数的梯度。
> - 梯度垂直于等高线，同时指向高度更高的等高线

对于方向导数
$$
\nabla_vf(x)=\nabla{f(x)}\cdot \frac{v}{|v|}
$$
其中，x是空间内正在渲染的点，f是体积场（volumetric field），然后f(x)将是渲染点的密度（density），$$\nabla f(x)$$是点的梯度（或者说 normal）。如果v是光的方向，那么方程的右边将是常规的兰伯特照明$$N\cdot L$$，而左边可以理解为沿LightView的方向导数，那么，我们可以得到一个优化思路——计算光照时，我们可以直接计算左边的式子，而无需使用Normal，下面是作者的解释

基本上，可以直接在感兴趣的方向上测量变化（导数），而不是在所有可能的方向上提取通用导数。换句话说，我们不需抽取4或6个样本来提取通用导数或梯度，然后将其指向光的方向进行照明，而只需在当前点采样不超过2次的场即可，在与光的方向相距一小段距离的点处（并除以该距离）

```c#
// function : R3->R1 is the volumetric density function
// eps is the diferential unit, based on the current LOD
vec3 calcNormal( in vec3 x, in float eps )
{
    vec2 e = vec2( eps, 0.0 );
    return normalize( vec3( function(x+e.xyy) - function(x-e.xyy),
                            function(x+e.yxy) - function(x-e.yxy),
                            function(x+e.yyx) - function(x-e.yyx) ) );
}

void render( void )
{
    // ...
    float den = function( pos );
    vec3  nor = calcNormal( pos, eps );
    float dif = clamp( dot(nor,light), 0.0, 1.0 );
    // ...
}
```

加速为

```c#
// function : R3->R1 is the volumetric density function
// eps is the diferential unit, based on the current LOD
void render( void )
{
    // ...
    float den = function( pos );
    //下面计算了方向导数
    float dif = clamp( (function(pos+eps*light)-den)/eps, 0.0, 1.0 );
    // ...
}
```

当然，缺点是这仅对少量光源有好处。通常，将需要2个用于云的光源（太阳和天顶）。如果有3个或更多的光源，那么基于渐变的传统照明会更加高效。





## Sphere Soft Shadow

对于给定的阴影点，空间球体和定向光源（不是区域光），请查看从相关点**ro**沿光方向**rd**传播的光线是否撞击或错过了球体，以及是否错过了多少。光线越接近球体，阴影（半影）越暗。但是，有一个观察：最接近的点与接收点**ro**的距离越远，阴影的强度就越小。换句话说，在这个简化模型中，阴影的暗度取决于两个参数：d和t（如下图），则柔和阴影将与它们的比率**d / t**成正比。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/render%20techniques/gfx01.jpg)

```c#
float sphSoftShadow( in vec3 ro, in vec3 rd, in vec4 sph, in float k )
	{
		vec3 oc = ro - sph.xyz;
		float b = dot( oc, rd );
		float c = dot( oc, oc ) - sph.w*sph.w;
		float h = b*b - c;
		
		float d = -sph.w + sqrt( max(0.0,sph.w*sph.w-h));
		float t = -b     - sqrt( max(0.0,h) );
		return (t<0.0) ? 1.0 : smoothstep( 0.0, 1.0, k*d/t );
	}
```

参数**k**控制阴影半影的清晰度。较高的值使其更清晰。这里的smoothstep（）函数只是为了平滑然后在光和影之间过渡。

上面的代码更快的一种方法是删除平方根。我创建了替代近似值，在该近似值以下会生成物理上不正确的阴影，但仍然合理，因为阴影的清晰度取决于生成阴影的对象与接收阴影的对象之间的距离

```c#
float sphSoftShadow( in vec3 ro, in vec3 rd, in vec4 sph, in float k )
	{
		vec3 oc = ro - sph.xyz;
		float b = dot( oc, rd );
		float c = dot( oc, oc ) - sph.w*sph.w;
		float h = b*b - c;
		
		return (b>0.0) ? step(-0.0001,c) : smoothstep( 0.0, 1.0, h*k/b );
	}

```







## Normals For An SDF

> 选中一行：Home定位到行首，然后Shift+End选中一行

==**SDF是一个有符号距离函数**==，在计算机图形学中，通常使用它来快速进行[raymarch几何和场景](https://www.iquilezles.org/www/articles/normalsSDF/raymarchingdf)。在此类场景上进行照明或碰撞检测时，必须访问几何图形的表面法线。从SDF f(p)中出现的曲面，其中p是空间中的一个点，由特定的等值面给出，通常f(p) = 0等值面。计算等值面的法向量n可以通过位于表面点的SDF的梯度得到。
$$
n=normalize(\nabla f(p))
$$
请记住，标量场的梯度始终垂直于标量场描述的等值线或等值面，并且由于曲面的法线需要垂直，因此法线必须与该梯度对齐。

有多种计算这种梯度的方法。有些是数字的，有些是分析的，都具有不同的优势和劣势。本文是关于对它们进行数值计算，它需要最少的代码编写，但可能不是最快或最准确的。尽管如此，它的简单性还是它成为在实时光线采样演示和游戏中计算法线的最受欢迎的方法。

==Classic technique-forward and central differences==

最简单的梯度定义如下：
$$
\nabla f(p)=\{\frac{df(p)}{dx},\frac{df(p)}{dy},\frac{df(p)}{dz}\}
$$
从导数的定义所知道的，那些偏导数可以用很小的差异来计算
$$
\frac{df(p)}{dx}\approx\frac{f(p+\{h,0,0\})-f(p)}{h}
$$
h尽可能小，以上是正向微分，而Backwards and central differences 如下：
$$
\begin{align}
\frac{df(p)}{dx}&\approx\frac{f(p)-f(p-\{h,0,0\})}{h}\\
\frac{df(p)}{dx}&\approx\frac{f(p+\{h,0,0\}-f(p-\{h,0,0\})}{2h}\\
\end{align}
$$
因此，使用中心差，法线采用以下形式：

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/render%20techniques/for04.png)

```c#
{
    const float eps = 0.0001; // or some other value
    const vec2 h = vec2(eps,0);
    return normalize( vec3(f(p+h.xyy) - f(p-h.xyy),
                           f(p+h.yxy) - f(p-h.yxy),
                           f(p+h.yyx) - f(p-h.yyx) ) );
}
```

六次**f(p)**变得过于昂贵，则可以使用前向差异代替：
$$
n=normalize(\{f(p+\{h,0,0\})-f(p),f(p+\{0,h,0\})-f(p),f(p+\{0,0,h\})-f(p)\})
$$
==Tetrahedron technique==

有一个很好的替代方法，它也基于中心差异来直接渐变定义技术，这意味着法线上的光照将跟随曲面而没有任何偏移，它仅使用四个评估而不是六个评估，使其与正向效率相同差异，代码上大致如下：

```c#
vec3 calcNormal( in vec3 & p ) // for function f(p)
{
    const float h = 0.0001; // replace by an appropriate value
    const vec2 k = vec2(1,-1);
    return normalize( k.xyy*f( p + k.xyy*h ) + 
                      k.yyx*f( p + k.yyx*h ) + 
                      k.yxy*f( p + k.yxy*h ) + 
                      k.xxx*f( p + k.xxx*h ) );
}
```

具体推导理由如下：

四个采样点排列在一个四面体中，顶点为**k0** = {1，-1，-1}，**k1** = {-1，-1，1}，**k2** = {-1，1 ，-1}和**k3** = {1，1，1}。Evaluating the sum：
$$
m=\sum_{i}k_if(p+hk_i)
$$
在这四个顶点上产生一些很好的抵消
$$
m=\sum_{i}k_i(f(p+hk_i)-f(x))
$$
很明显这是四个方向导数，那么可以写为：
$$
m=\sum_i{k_i\nabla_{k_i}f(p)}=\sum_ik_i(k_i\cdot\nabla f(p))
$$
我们可以一次只看一个分量。对于x，我们得到
$$
m_x=\sum_i{k_{ix}\nabla_{k_i}f(p)}=\nabla f(p)\cdot \sum_i{k_{ix}k_i}=\nabla f(p)\cdot \{4,0,0\}
$$
同理推导Y和Z，则有
$$
m=4\nabla f(p)
$$
归一化后得到零等值面处的法线。

在Shadertoy社区中变得相当普遍，因为它不仅可以防止崩溃，还可以减少很多编译时间。这是克莱门特·巴蒂克（ClémentBaticle）（又名克莱姆斯）做出的绝招的变体：

```c#
vec3 calcNormal( in vec3 & p ) // for function f(p)
{
    const float h = 0.0001;      // replace by an appropriate value
    #define ZERO (min(iFrame,0)) // non-constant zero
    vec3 n = vec3(0.0);
    for( int i=ZERO; i<4; i++ )
    {
        vec3 e = 0.5773*(2.0*vec3((((i+3)>>1)&1),((i>>1)&1),(i&1))-1.0);
        n += e*map(pos+e*h).x;
    }
    return normalize(n);
}
```

==Central differences for Terrains==

在渲染光线照射的地形时，我们通常使用**g（x，z）**形式的高度图，该高度图通过**y** = **g（x，z）**对其进行定义。可以将其重写为**f（x，y，z）** = **y** - **g（x，z）** = 0，这意味着不是距离场，它是标量场。这样，我们得到

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/render%20techniques/for12.png)

法向量可以简单计算如下：

```c#
vec3 getNormal( const vec2 & p ) // for terrain g(p)
{
    const float eps = 0.0001; // or some other value
    const vec2 h = vec2(eps,0);
    return normalize( vec3( g(p-h.xy) - g(p+h.xy),
                            2.0*h.x,
                            g(p-h.yx) - g(p+h.yx) ) );
}
```

请注意，因为我们使用的是中心差，并且采样点之间的距离为**2h**，所以除以**2h**意味着需要将y分量（即**1**）乘以**2h**，在[有关地形行进的文章中](https://www.iquilezles.org/www/articles/terrainmarching/terrainmarching.htm)也可以找到的代码

到目前为止，我们尚未对**h**的值进行任何关注。从理论上讲，它必须尽可能小，以使梯度的成分正确地近似于空间导数。当然，值太小会引入数值误差，因此在实践中，**h的**大小是有限制的。

但是，在选择值时，还有一个重要的考虑因素——几何细节和抗锯齿。确实，当我们在某个空间点上取得中心差异时，我们应该考虑距相机有多远。这个想法是，我们想知道当在采样点附近投影到屏幕时，几何细节有多小？或者，与该区域的几何细节相比，像素占用的空间有多大。我们需要这些信息，以便我们可以在光线细分的几何图形中进行LOD——我们不需要为距离很远并且由于透视投影而变得太小的物体计算SDF。这不仅是性能优化，而且更重要的是图像质量问题。

现在，在这种情况下，需要确保用于采样梯度的**h**也大约等于像素覆盖区的大小。这将与从采样点到相机的距离成比例，通常在光线追踪器和光线发射器中称为**t**。







## Texturing and Raymarching

[Raymarching距离场](https://www.iquilezles.org/www/articles/raymarchingdf/raymarchingdf.htm)正在成为一种流行的技术，以一种廉价的方式来呈现过程图形。从分形到地形再到任意复杂的形状和对象，只需几行代码就可以轻松渲染出有趣的图像。但是，就像任何基于像素跟踪的技术（光线跟踪，路径跟踪等）一样，该技术也存在一些缺点。其中之一是在进行需要偏导数的曲面操作时得到的artifacts。例如，使用硬件纹理映射器以一种native的方式创建纹理对象，它使用dFdx()和dFdy()来提取屏幕空间中的texel足迹，这会在对象的边缘产生伪影，从而破坏UV的连续性。但是，让我们仅在SDF raymarcher中进行纹理化。

在最简单的实现方式中，通过光线marching绘制距离场包括以下步骤：构造穿过给定像素的光线，实际Raymarching以找到交点，在交点处进行法线计算，the shading/surfacing，照明和色彩校正。我们在本文中讨论的工作发生在表面处理/纹理化步骤中。

问题是，与多边形栅格化不同的是，在上述经典的raymarching设置中，当我们请求经过mipmap过滤的纹理样本时，不再保证GPU中的纹理单元从同一局部表面查找。众所周知，当前的GPU会以2x2像素为一组进行着色（并因此进行纹理化）。这保证了每个纹理查找将具有邻居来执行纹理坐标差。通过这些差异，GPU知道许多纹理像素将落入当前像素，因此可以推断出哪个mip级别最适合对纹理进行采样而不会发生混叠（即每个像素有两个以上的纹理像素）。

当然，在我们考虑的光线行进设置下，这种像素微分方法不起作用，因为破坏了表面局部性的整个假设。例如，一个像素可以属于一棵树，而相邻像素可以属于该树的不同分支，甚至可以属于一个完全不同的对象，例如岩石。多边形栅格化永远不会发生这种情况，因为一次只能对一个对象进行栅格化，并且在需要时（当多边形太小或我们对其边缘进行着色时），多边形阴影会扩展为在x和y方向上分别覆盖1个额外的像素。但是在我们的raymarcher中，不能保证像素的局部性，在所有情况下像素差异都不再测量纹理坐标的导数，因此纹理过滤在表面（深度）不连续处被破坏。通常会发生的情况是，在这些不连续处，导数被高估了（因为纹理坐标的差异很大），而texels从纹理的最小的mip层中带出，产生了一个不同颜色的可见边缘，如下图所示。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/render%20techniques/gfx00.gif)

解决方法很简单：如果硬件无法计算正确的梯度，让我们自己去实现它，在IQ大多数传统的raymarcher中，当我们构建像素射线时，我们可以同时计算进过该像素邻居的射线（右侧，上侧或下侧），当前射线和这两条额外射线之间的差异称为射线微分，and basically they encode the footprint of your pixel in world space (it's size and orientation)，然后，当我们进行射线步进，穿越整个场景时，这个微分和投射距离成正比，变得越来越大，所以，只要我们保持这条线的微分，我们就能估算出在世界空间交点上被渲染的像素的轨迹，然后估算出这个像素轨迹角落的纹理坐标。这将告诉我们需要考虑多少个texel来进行适当的过滤。

让我们假设我们有以下经典的raymarcher，我已经简化为设置一个给定像素的光线，raymarching, surfacing和lighting：

```c#
void raymarch( out vec4 color, in vec2 pixel )
{
    // setup
    vec3 ro = calcRayOrigin();
    vec3 rd = calcRayDirection( pixel );
	
    // raymarch: return distance and object id
    float (t,oid) = raymarch( ro, rd );
	
    // prepare for surfacing
    vec3 pos = ro + t*rd;
    vec3 nor = calcNormal( pos, t );

    // surfacing
    vec2 uv = textureMapping( pos, oid );
    vec3 sur = texture( sampler, uv );
	
    // lighting
    vec3 lig = calcLighting( pos, nor, t );
	
    // point color
    return calcSurfaceColor( sur, lig, t );
}

```

如前所述，问题是t和oid(相交对象的id)在许多像素处都是不连续的(即使在同一对象内)。因此，之后的计算也是不连续的(pos, nor和纹理坐标uv)。

提出的解决方案是在已知法线的情况下，在交点处用一个与之相切的平面来近似物体oid的表面。然后，我们可以让这两条射线通过相邻的像素点并与这个切平面进行解析相交。这是非常便宜的(与我们刚刚执行的昂贵的raymarch相比是免费的)。交点的差异将给我们的像素世界的空间足迹:

```c#
void raymarch( out vec4 color, in vec2 pixel )
{
    // setup
    vec3 ro  = calcRayOrigin();
    vec3 rd  = calcRayDirection( pixel );
    vec3 rdx = calcRayDirection( pixel + vec2(1,0) );
    vec3 rdy = calcRayDirection( pixel + vec2(0,1) );
	
    // raymarch: return distance and object id
    float (t,oid) = raymarch( ro, rd );
	
    // prepare for surfacing
    vec3 pos = ro + t*rd;
    vec3 nor = calcNormal( pos, t );
    vec3 (dposdx, dposdy) = calcDpDxy( ro, rd, rdx, rdy, t, nor );	

    // surfacing
    vec2 (uv,duvdx,duvdy) = textureMapping( pos, dposdx, dposdy, oid );
    vec3 sur = textureGrad( sampler, uv, dudvx, dudvy );
	
    // lighting
    vec3 lig = calcLighting( pos, nor, t );
	
    // point color
    return calcSurfaceColor( sur, lig, t );
}
```

算法并没有太大的变化。首先我们计算相邻的射线(水平和垂直偏移1像素)。在完成了经典的raymarch(我们只做了一次，就像之前一样)之后，我们计算了考虑的射线与场景的局部平面近似的相邻射线的交点的差异。我们在calcDpDxy()中实现了这一点。经过一点简化，这个函数简化为:

```c#
// compute screen space derivatives of positions analytically without dPdx()
void calcDpDxy( in vec3 ro, in vec3 rd, in vec3 rdx, in vec3 rdy, in float t, in vec3 nor, 
                out vec3 dpdx, out vec3 dpdy )
{
    dpdx = t*(rdx*dot(rd,nor)/dot(rdx,nor) - rd);
    dpdy = t*(rdy*dot(rd,nor)/dot(rdy,nor) - rd);
}
```

值得注意的是，通过不返回绝对相交位置，而只返回微分，我们可以避免浮点精度问题。一旦我们在世界空间中有了这些微分，我们就需要通过 *世界空间*  到 *纹理坐标* 变换来传播它们。这可以用链式法则来做。对于平面纹理映射投影来说，这就像一个简单的线性变换一样简单(后面会详细介绍)。最后，我们使用textureGrad()，以从纹理中获取过滤后的texel。这个函数获得显式的纹理坐标导数(“gradient”)，并使用它们来选择适当的mip级别，而不是通过自动的像素微分。

[原网址](https://www.iquilezles.org/www/articles/filteringrm/filteringrm.htm)





## Texture Repetition

大表面纹理映射最典型的问题之一是纹理的可见重复。虽然像GL ARB纹理镜像重复可以通过使重复周期增加一倍来帮助缓解问题，但是硬件本身不能解决问题。然而，如果我们愿意为每个样本支付多个纹理获取的成本，那么就有很好的方法来防止纹理重复。我将展示三种不同的技巧。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/render%20techniques/TR1.PNG)

==Technique 1==

防止纹理的视觉重复的一种方法是为重复的每个图块分配随机偏移和方向。 我们可以通过确定我们在哪个图块中，为图块创建一系列四个伪随机值，然后使用这些值来偏移和重新定向纹理来做到这一点。 重新定向可以像在x或y或两者中进行镜像一样简单。 这在整个表面上产生了非重复图案。

刚刚描述的技术带有一些需要解决的警告：首先，该模式将显示跨图块边界的接缝，因为不同偏移的纹理图块在图块边界处不匹配。 其次，由于最终纹理获取坐标本身引入了不连续性，因此导数将在图块边界处发生巨大的跳跃，而mipmapping将破裂，从而产生线条伪像。

解决这两个问题的一个解决方案是在四个纹理块上用上面提到的偏移和方向采样纹理，并在足够靠近当前纹理块的边界时将它们混合(例如在可能的U和V方向上)。虽然这将在平铺的某些区域引入一些模糊，但在大多数情况下是可以接受的，如本文开头的图像所示。

当然，为了实现这一点，我们必须使用自定义纹理梯度，它必须来自原始的重复UV映射。

```c#
vec4 textureNoTile( sampler2D samp, in vec2 uv )
{
    ivec2 iuv = ivec2( floor( uv ) );
     vec2 fuv = fract( uv );

    // generate per-tile transform
    vec4 ofa = hash4( iuv + ivec2(0,0) );
    vec4 ofb = hash4( iuv + ivec2(1,0) );
    vec4 ofc = hash4( iuv + ivec2(0,1) );
    vec4 ofd = hash4( iuv + ivec2(1,1) );
    
    vec2 ddx = dFdx( uv );
    vec2 ddy = dFdy( uv );

    // transform per-tile uvs
    ofa.zw = sign( ofa.zw-0.5 );
    ofb.zw = sign( ofb.zw-0.5 );
    ofc.zw = sign( ofc.zw-0.5 );
    ofd.zw = sign( ofd.zw-0.5 );
    
    // uv's, and derivatives (for correct mipmapping)
    vec2 uva = uv*ofa.zw + ofa.xy, ddxa = ddx*ofa.zw, ddya = ddy*ofa.zw;
    vec2 uvb = uv*ofb.zw + ofb.xy, ddxb = ddx*ofb.zw, ddyb = ddy*ofb.zw;
    vec2 uvc = uv*ofc.zw + ofc.xy, ddxc = ddx*ofc.zw, ddyc = ddy*ofc.zw;
    vec2 uvd = uv*ofd.zw + ofd.xy, ddxd = ddx*ofd.zw, ddyd = ddy*ofd.zw;
        
    // fetch and blend
    vec2 b = smoothstep( 0.25,0.75, fuv );
    
    return mix( mix( textureGrad( samp, uva, ddxa, ddya ), 
                     textureGrad( samp, uvb, ddxb, ddyb ), b.x ), 
                mix( textureGrad( samp, uvc, ddxc, ddyc ),
                     textureGrad( samp, uvd, ddxd, ddyd ), b.x), b.y );
}
```

[用例](https://www.shadertoy.com/view/lt2GDd)

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/render%20techniques/TR11.gif)

==Technique 2==

另一种使外观看起来更加有机的方法（只是在其中创造了一个字）是用随机缩放，偏移和旋转的原始纹理副本轰炸整个表面，然后将它们混合在一起，并且取决于混合权重因子到每个副本中心的距离。例如，这可以用[光滑的voronoi](https://www.iquilezles.org/www/articles/smoothvoronoi/smoothvoronoi.htm)模式完成。对于voronoi模式中的每个特征点，按比例混合与高斯衰落成比例的权重效果很好。只需记住将最终颜色重新归一化为每个特征点的总贡献，否则纹理亮度范围将丢失。

```c#
vec4 textureNoTile( sampler2D samp, in vec2 uv )
{
    vec2 p = floor( uv );
    vec2 f = fract( uv );
	
    // derivatives (for correct mipmapping)
    vec2 ddx = dFdx( uv );
    vec2 ddy = dFdy( uv );
    
    // voronoi contribution
    vec4 va = vec4( 0.0 );
    float wt = 0.0;
    for( int j=-1; j<=1; j++ )
    for( int i=-1; i<=1; i++ )
    {
        vec2 g = vec2( float(i), float(j) );
        vec4 o = hash4( p + g );
        vec2 r = g - f + o.xy;
        float d = dot(r,r);
        float w = exp(-5.0*d );
        vec4 c = textureGrad( samp, uv + o.zw, ddx, ddy );
        va += w*c;
        wt += w;
    }
	
    // normalization
    return va/wt;
}
```

当然，缺点是算法对纹理采样9次。但另一方面，它确实有助于高质量的图像或场景

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/render%20techniques/TR3.gif)

[==Technique3==](https://www.shadertoy.com/view/Xtl3zf)

还有一个非常便宜的方法也可以通过不同的概念来实现。通过简单地对纹理查找应用恒定的偏移量，便得到了这种切片模式的多个虚拟版本，例如8。通过允许对这8个虚拟版本进行旋转，对称和缩放，可以使该技术更强大，但是对于我们而言，在大多数情况下，偏移量就足够了。现在，通过首先选择0到7之间的一个数字，在贴图域的每个点上评估最终的非重复模式，我们可以将其称为*index*，然后从这些版本中选择一个以基于其采样纹理像素。通过为区域内的索引选择相同的值，我们可以创建使用相同虚拟图案的平面补丁。当然接缝是可见的，因此为了改善这一点，我们实际上使索引成为浮点值而不是整数。这样，索引可以在平面上缓慢平稳地变化。然后，我们可以使用它在两个最接近的虚拟模式之间进行内插，而不仅仅是选择一个。这种低频索引变化模式可以是程序噪声，也可以是来自“查找表”或纹理的随机值，这使得过滤更容易，因此可以得到完全可过滤的结果模式

```c#
vec4 textureNoTile( sampler2D samp, in vec2 uv )
{
    // sample variation pattern    
    float k = texture( iChannel1, 0.005*x ).x; // cheap (cache friendly) lookup    
    
    // compute index    
    float index = k*8.0;
    float i = floor( index );
    float f = fract( index );

    // offsets for the different virtual patterns    
    vec2 offa = sin(vec2(3.0,7.0)*(i+0.0)); // can replace with any other hash    
    vec2 offb = sin(vec2(3.0,7.0)*(i+1.0)); // can replace with any other hash    

    // compute derivatives for mip-mapping    
    vec2 dx = dFdx(x), dy = dFdy(x);
    
    // sample the two closest virtual patterns    
    vec3 cola = textureGrad( iChannel0, x + offa, dx, dy ).xxx;
    vec3 colb = textureGrad( iChannel0, x + offb, dx, dy ).xxx;

    float sum( vec3 v ) { return v.x+v.y+v.z; }

    // interpolate between the two virtual patterns    
    return mix( cola, colb, smoothstep(0.2,0.8,f-0.1*sum(cola-colb)) );

}
```





## Ellipsoid

椭圆体是用SDF建模时最有用的基元之一。然而，与球体、圆锥、圆锥、方块不同，椭圆体没有分析距离函数。这意味着原则上不能用椭圆来建模，我们需要用数值方法来实现它们的距离函数。当然，那是相当慢的（二分法需要10到20次左右的迭代才能得到好的结果）。因此，我们需要使用近似距离函数来实现。幸运的是，we can  find bound functions that at least have a zero iso-surface in the shape on an exact ellipsoid.。这意味着，这样的约束函数将产生精确椭圆的渲染，但在查询时将报告非欧几里得的距离。这意味着 raymarcher 在找到它们的时候会比较困难，需要更多的步骤，直到找到一个交点。这也意味着对于椭圆的遮蔽和阴影将根据我们使用的约束函数而出现错误。这篇文章是关于两个这样的绑定函数的文章。

事实上，当椭圆体在一条轴上对称时，可以计算出椭圆的确切距离。在这种情况下，形状凸轮可以作为一个二维椭圆，在三维中沿一个垂直轴旋转。由于椭圆确实有确切的立方体形式的解，而且由于创建旋转的形状是琐碎的，而且不会增加多项式的度数，所以旋转椭圆的椭圆确实有封闭的形式。本文中所有比较两种约束技术的图像都使用了对称椭圆。

==First Approach==

将距离限定到一个椭球的最简单的方法是将空间拉伸，使椭球成为一个球体，计算该空间到一个单位球体的距离，然后用最大的比例因子将距离缩回到原始空间。代码是

```c#
float sdbEllipsoidV1( in vec3 p, in vec3 r )
{
    float k1 = length(p/r);
    return (k1-1.0)*min(min(r.x,r.y),r.z);
}
```

==Second Approach==

改进前一个边界的一个简单方法是除以它的梯度的长度。在纸上做了一些数学运算和漂亮的重新排列之后，就得到了这个：

```c#
float sdbEllipsoidV2( in vec3 p, in vec3 r )
{
    float k1 = length(p/r);
    float k2 = length(p/(r*r));
    return k1*(k1-1.0)/k2;
}
```

==Third Approach==

另一个可能在你脑海中浮现的想法是将第一种技术稍微改变一下，看看是否能改善距离估计：将空间拉伸，将椭圆变形为单位球，在单位球中找到最近的点，将该点转换回源空间，然后计算出那里的距离。这个技术实际上很好用，因为它确实能产生一个更好的距离估计。然而，它在低估和高估之间波动，即使是用回溯射线行进器，它的效果也不是很好，我不会在这篇文章中进一步讨论，尽管它可以用于二维绘图。

```c#
float sdaEllipsoidV3( in vec3 p, in vec3 r )
{
    float k1 = length(p/r);
    return length(p)*(1.0-1.0/k1);
}
```

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/render%20techniques/Ellie1.PNG)

第一种技术相比，第二种技术最重要的优点并不是更有效的raymarching。主要的好处是，它产生了更接近地面真实的距离估计，特别是，它使它更欧几里得。这意味着，当与生成精确欧氏距离的其他原语结合使用时，第二种技术生成的值与其他原语生成的值配合得很好。这意味着我们可以为整个SDF和keep调整阴影柔软度参数、遮挡阈值和许多其他全局值

[测试例子](https://www.shadertoy.com/view/tdS3DG)







## SDF Bounding Volumes

当对SDF进行射线渲染时，或将常规的GL/DX/VK光栅化与阴影、遮挡或碰撞的SDF结合在一起时，往往会发现SDF的评估成本太高。对于完全由程序化基元组成的SDF，或者是对具有大量三角形的3D网格进行评估时，情况就更加严重。

在我的Shadertoy实验中，很多时候，我接受了这个限制，并据此设计我的场景和世界，这意味着我经常会创建简单的形状，而不是我喜欢的复杂形状。然而，在复杂的SDF对象周围使用简单的Bounding Volumes也不是一个坏主意，以避免在不需要的时候评估整个SDF。这可以降低整个SDF评估的复杂性，并且在大多数平台上都能很好地运行（特别是那些分支不是太贵的平台）。

这篇文章介绍了我过去用过的几个简单的技术，效果很好，还有一些涉及加速结构的更高级的快速实验，也许可以启发你构建更复杂的结构。

==Basic Bounding Volumes==

因此，让我们以一个复杂的对象（例如，一个角色）为例，它可以定义如下：

```c#
float sdCharacter( in vec3 pos, in float minDist )
{
    float d1 = sdHead( pos ); // expensive SDF
    float d2 = sdBody( pos ); // expensive SDF
    float d3 = sdLegs( pos ); // expensive SDF
    float d4 = sdArms( pos ); // expensive SDF
	
    float dT = min(min(d1,d2),min(d3,d4));
	
    if( dT<minDist ) minDist = dT;
	
    return minDist;
}
```

现在我们要做一个最简单的事情：定义一个完全约束角色的球体，在评估任何角色部分之前，先检查到这个球体的距离。如果在评估字符之前，当前离全局SDF最近的距离minDist已经小于到边界球体的距离，那么根本不需要评估角色的任何SDF部分，

```c#
// early skip
float dB = sdSphere( pos, boundingSphereRadious );
if( dB>minDist ) return minDist;
```

[超级牛逼的IQ着色器](https://www.shadertoy.com/view/3lsSzf)

==Recursive Bounding Volumes==

就像计算机图形学中的许多东西一样，一个问题可以被分割成更小的问题，这样就可以扩展到更大的数据集。在这种情况下，我们除了在 sdCharacter()中添加边界卷外，还可以在 sdHead()、sdBody()和所有其他子部分中添加边界卷。

当然，评估 bounding volumes 确实会增加一些性能成本（如果它所绑定的 SDF 最终需要被评估）。因此，我们必须平衡做边界卷评估的成本和它所要优化的SDF的原始成本。

==Bounding Volumes Hierarchies==

递归边界体积的一种极端情况是，SDF的复杂性非常高，以至于无论如何，都需要一个非常深的递归边界体积系统。可以使用多种易于理解的边界卷层次结构算法，既可以使用stack（）实现自动递归，也可以使用从根重启的方法，而无需使用堆栈，也可以不使用堆栈，也可以使用跳过指针或父级来实现堆栈指针。这些可能不在本文的讨论范围之内，但是它们并不难实现，并且可以使某些其他复杂的SDF以全帧速率和全屏运行，例如（微小的）三角形网格。

```c#
float sdMesh( in vec3 pos, in float minDist )
{
    stack_reset();
    int currentNode = 0;
    for( ;; )
    {
        Node n = data.node[ currentNode ];
        
        // if we hit bounding volume, go down the tree
        if( sdBox( pos, n.bbox ) < minDist )
        {
            // intersect triangles in this node
            if( n.numTriangles>0 )
            {
                minDist = sdTriangles( pos, n.trianglesOffset, n.numTriangles, minDist );
            }
			
            // traverse children, closest one first
            int closest = (pos[n.splitAxis] < center(n.bbox)[n.splitAxis]) ? 0 : 1;
            stack_push( Data(n.childOffset+1-closest) );
            stack_push( Data(n.childOffset+  closest) );
        }

        // get next node, if any
        if( stack_is_empty() ) break;
        currentNode = stack_pop();
    }

    return minDist;
}
```







## Interior SDFs

在使用SDF建模时，有两种方法可以实现复杂形状的建模：一种是将较简单的形状与联合、减法和相交操作相结合，通常用min()和max()函数来实现。另一种是对所需形状的SDF从头设计一个新的公式。第二种方案涉及到一些数学上的推导，但需要注意的是，有时可能无法得到这样的封闭式公式。正因为如此，人们倾向于使用非常小的基本基元集，并根据需要将它们组合起来。

但是，两个SDF的min()和max()并不总是能得到一个有效的SDF，因为这样的结果实际上并不是距离场，而只是对结果面的实际距离的下限。这就影响了SDF的性能和算法的质量（就像在raymarcher的情况下），甚至会完全破坏它，使其停止运行（就像在碰撞检测的情况下）。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/render%20techniques/ISDF1.PNG)

现在，虽然众所周知，基于max()的运算符(减法和相交)会破坏结果形状的SDF(它们产生界线，而不是到处都是正确的距离)，但基于min()的运算符(联合)通常被假设为产生正确的SDF。但这有时是一个不正确的假设。特别是在结果形状的内部，在SDF取负值的情况下，它的作用并不像预期的那样。我说的不是真正的SDF的小偏离或精度问题，而是完全破损的SDF。然而，人们可能会认为SDF的内部往往是不需要的，除了可能是地表下的散射或体积效应外，SDF的内部是不需要的。但事实也并非如此。那么，我们来看看这个问题的解决方法。

==Idea 1==

首先能做的事情当然是无视这个问题。这是完全没有问题的，只要你知道这个决定所带来的影响和限制。

==Idea 2==

然而，有时我们不想忽略我们的SDF的内部。这可能是，正如前言中提到的，因为我们已经意识到，给定的SDF的内部确实与我们建模的对象很接近。例如上面的L形房间的例子，由两个盒子和一个圆组成的L形房间，用两个盒子和一个圆确实很容易建模。至少它的墙面或进出界面是这样的。但是由于我们今天分析的SDF问题，房间的内部就被打破了。

我们可以做的一件事，可能在某些情况下是可行的，那就是把问题反过来想一想，在形状周围的负空间。在这个房间的情况下，这意味着我们的SDF模型是房间的外部（黄色区域），而不是内部（蓝色区域）。如果我们从内向外思考，我们可以看到，我们可以通过使用五个盒子和一个弧形/月形来对房间进行建模。

那么==我们可以通过改变SDF的符号，将室内和室外的定义颠倒过来，得到一个完美的房间内部的SDF==。当然，现在房间的外部有了错误的SDF，但假设我们的游戏或电影场景发生在房间内部，我们就完全没有问题了（除了在计算一些表面法线的计算中，同样如此）。

==Idea 3==

当然，因为我们原则上可以生成正确的内部和外部的SDF，我们也可以准确地辨别内部和外部的体块，我们可以根据需要选择合适的准确的SDF。这是以双倍的建模成本(艺术家时间)和存储为代价的。

==Idea 4==

在2D中，我们可以做一件事——将对象的边界建模为一系列的线段、圆弧和二次贝塞尔线段，所有这些线段都具有精确的SDFs。如果形状是一个闭环，确定内部和外部区域是非常简单的(每段的叉乘就足够了)。因此，我们可以生产任意封闭形状与正确的SDF内外的形状。

==Idea 5==

最后一个想法就是我在文章开头的介绍中暗示的——不要只使用基本的（通常是凸的）SDF基元，而是可以开始使用更复杂的（通常是凹的）但精确的SDF基元。你可以在我的[2D SDF](https://www.iquilezles.org/www/articles/distfunctions2d/distfunctions2d.htm)和[3D SDF](https://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm)上找到许多这样的SDF。我一直在推导和收集它们的原因正是这个。