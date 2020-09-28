## IQ大神博客阅读心得5

| 标题                                                         | 简介                                         |
| ------------------------------------------------------------ | -------------------------------------------- |
| [SSAO](#SSAO)                                                | 简单的屏幕空间环境光遮蔽                     |
| [**Better Fog**](#Better-Fog)                                | **关于雾的计算的诸多效果**                   |
| [Penumbra Shadows In Raymarched SDFS](#Penumbra-Shadows-In-Raymarched-SDFS) | 距离场中软阴影的计算技巧                     |
| [Simple Pathtracing](#Simple-Pathtracing)                    | 简单的路径追踪                               |
| [Multiresolution Ambient occlusion](#Multiresolution-Ambient-occlusion) | 在传统的SSAO（中频）的基础上加上高频和低频AO |
| [Outdoors Lighting](#Outdoors Lighting)                      | 室外大场景的渲染技巧与思路                   |
| [Box Occlusion](#Box-Occlusion)                              | 正方体遮蔽                                   |
| [Terrain Raymarching](#Terrain-Raymarching)                  | 地形的射线步进                               |
| [Volumetric Sort](#Volumetric-Sort)                          | 体积排序（没看懂）                           |
| [Smooth Minimum](#Smooth-Minimum)                            | 平滑最小值，用于RayMarching                  |

------



#### SSAO

```c#
uniform vec4 fk3f[32];
uniform vec4 fres;
uniform sampler2D tex0;
uniform sampler2D tex1;

void main(void)
{
    //采样第一次获得的深度图，获得该像素的Z
    vec4 zbu = texture2D( tex0, gl_Color.xy );
    
    //求得该像素点在视点空间的位置
    vec3 ep = zbu.x*gl_TexCoord[0].xyz/gl_TexCoord[0].z;
    
    //采样随机随机法线贴图，获得一个随机干扰量
    vec4 pl = texture2D( tex1, gl_Color.xy*fres.xy );
    //区间重定向
    pl = pl*2.0 - vec4(1.0);

    float bl = 0.0;
    for( int i=0; i<32; i++ )
    {
        //根据随机干扰量和随机值做反射
        vec3 se = ep + rad*reflect(fk3f[i].xyz,pl.xyz);
        //归一化、但是后面那个乘值不太懂，是因为长宽比是4:3吗
        vec2 ss = (se.xy/se.z)*vec2(.75,1.0);
        //区间重定位
        vec2 sn = ss*.5 + vec2(.5);
        //采样
        vec4 sz = texture2D(tex0,sn);
        //根据采样值计算距离，并进行Step限制
        float zd = 50.0*max( se.z-sz.x, 0.0 );
        //计算AO贡献值
        bl += 1.0/(1.0+zd*zd);
   }
   gl_FragColor = vec4(bl/32.0);
}
```





#### Better Fog

雾是计算机图形学中非常流行的元素，因此非常流行，因此实际上我们总是在教科书或教程中对其进行了介绍。但是，这些教科书，教程甚至API只能进行简单的基于距离的颜色融合。

传统上，雾是作为视觉元素引入的，它在图像中给出距离提示。的确，雾很快就能帮助我们了解物体的距离，从而了解物体的尺度以及世界本身。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/fog1.jpg)

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/fog2.jpg)

```c#
vec3 applyFog( in vec3  rgb,       // original color of the pixel
               in float distance ) // camera to point distance
{
    float fogAmount = 1.0 - exp( -distance*b );
    vec3  fogColor  = vec3(0.5,0.6,0.7);
    return mix( rgb, fogColor, fogAmount );
}

```

但是，我们应该注意，雾还可以提供更多信息。例如，雾的颜色可以告诉我们有关太阳强度的信息。甚至，如果我们使雾的颜色不是恒定的而是取决于方向的，我们可以为图像引入额外的逼真度。例如，当视图矢量与太阳方向对齐时，我们可以将典型的蓝色雾色更改为淡黄色。这给出了非常自然的光散射效果。有人会说这样的效果不应该称为雾而是散射，我同意，但是到最后，人们只需要稍微修改一下雾方程即可完成效果。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/fog3.jpg)

```c#
vec3 applyFog( in vec3  rgb,      // original color of the pixel
               in float distance, // camera to point distance
               in vec3  rayDir,   // camera to point vector
               in vec3  sunDir )  // sun light direction
{
    float fogAmount = 1.0 - exp( -distance*b );
    float sunAmount = max( dot( rayDir, sunDir ), 0.0 );
    vec3  fogColor  = mix( vec3(0.5,0.6,0.7), // bluish
                           vec3(1.0,0.9,0.7), // yellowish
                           pow(sunAmount,8.0) );
    return mix( rgb, fogColor, fogAmount );
}
```

效果可以更复杂。例如，太阳向量和视点向量之间的点积指数（当然，它控制方向颜色梯度的影响）也可以随距离而变化。如果设置正确，则可以伪造发光/泛光和其他光散射效果，而无需进行任何多遍处理或渲染纹理，而只需对雾化方程进行简单更改即可。颜色也会随高度或您可能想到的任何其他参数而改变。

该技术的另一种变化是将通常的mix（）命令分为两部分：

```c#
finalColor = pixelColor *（1.0-exp（-distance * b））+ fogColor * exp（-distance * b）;
```

现在，根据经典的CG大气散射论文，第一个术语可以解释为由于散射或“消光”引起的光的聚集，而第二个术语可以解释为“散射”。我们注意到，这种表示雾的方式更为有效，因为现在我们可以为消光和散射选择独立的参数***b***。此外，我们不能有一个或两个，而是最多可以有六个不同的系数-消色的rgb通道三个，散乱的rgb彩色版本三个。

```c#
vec3 extColor = vec3( exp(-distance*be.x), exp(-distance*be.y) exp(-distance*be.z) );
vec3 insColor = vec3( exp(-distance*bi.x), exp(-distance*bi.y) exp(-distance*bi.z) );
finalColor = pixelColor*(1.0-extColor) + fogColor*insColor;
```

这种做雾的方式，结合太阳方向着色和其他技巧，可以为您提供功能强大且简单的雾化系统，同时又非常紧凑，快速。它也非常直观，您无需处理Mie和Rayleight光谱常数之类的物理参数，数学和常数。**简单而可控就是胜利**。

***非恒定密度***

原始和简单的雾化公式具有两个参数：颜色和密度（我在上面的着色器代码中将其称为***b***）。同样，我们将其修改为具有非恒定的颜色，我们也可以对其进行修改以使其不具有恒定的密度。

一般来书，海拔越高，大气层密度越小，我们可以用指数对密度变化建模。指数函数的优势是公式的解是解析的。
$$
d(y)=a\cdot b^{-by}
$$
参数 **b**当然控制该密度的下降。现在，当我们的光线穿过摄影机到点的大气时，它穿过大气层时会积累不透明性。明显我们需要对此进行积分。我们射线的定义为：
$$
r(t)=o_y+t\cdot k_y
$$
我们有雾的总量为
$$
D=\int_0^t{d(y(t))}\cdot dt
$$
从而
$$
D=\int_0^t{d(o_y+t\cdot k_y)}\cdot dt=a\cdot e^{-b\cdot o_y}\frac{1-e^{-b\cdot k_y\cdot t}}{b\cdot k_y}
$$
所以我们的非恒定雾效着色器为

```c#
vec3 applyFog( in vec3  rgb,      // original color of the pixel
               in float distance, // camera to point distance
               in vec3  rayOri,   // camera position
               in vec3  rayDir )  // camera to point vector
{
    float fogAmount = c * exp(-rayOri.y*b) * (1.0-exp( -distance*rayDir.y*b ))/rayDir.y;
    vec3  fogColor  = vec3(0.5,0.6,0.7);
    return mix( rgb, fogColor, fogAmount );
}
```

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/fog4.jpg)

结合下一节的软阴影，我们的测试例子如下

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/Shadow%2Bfog.gif)







#### Penumbra Shadows In Raymarched SDFS

[距离场](http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm) 的众多优势之一，是他们自然地提供了全球信息。这意味着在为点着色时，只需查询Distanve函数即可轻松浏览周围的几何图形。与经典的光栅化器（基于REYES或基于scaline）不同，在传统光栅化器中，必须以某种方式烘焙全局数据，作为后续消费（在阴影图，深度图，点云...中）或在必须查找全局信息的raytracer中进行预处理。通过光线投射对几何图形进行采样，可以在远距离场中着色时使用该信息，这些信息几乎是免费的（当然，“免费”中有很多引号）。这意味着许多更现实的阴影和照明技术很容易在距离场上实现。当使用光线发射器对距离场进行采样/渲染时，更是如此。

我们假设这个map()函数包含您要呈现的所有对象，并且允许所有对象在所有其他对象中投射阴影。然后，在一个阴影点计算阴影信息的简单方法，是沿着光矢量射线行进，从光到阴影点的距离是多少，直到找到一个交点。你可以这样做一些代码：

```c#
float shadow( in vec3 ro, in vec3 rd, float mint, float maxt )
{
    for( float t=mint; t<maxt; )
    {
        float h = map(ro + rd*t);
        if( h<0.001 )
            return 0.0;
        t += h;
    }
    return 1.0;
}
```

这段代码工作得非常漂亮，并产生了漂亮而准确的锐利阴影

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/Shadow1.png)

现在，我们只能添加一行代码，并使它看起来更好！诀窍是想想当阴影射线没有击中任何物体，而恰好击中任何物体时会发生什么。然后，也许您想指出的是您在半影之下的阴影。可能，最接近您的目标是击中某个物体，而您想使其变暗。另外，距离您的阴影点最近的一次发生的颜色也更深。好吧，碰巧当我们对阴影射线进行射线编影时，这两个距离对我们都可用！当然他在上面的代码中第一个是**h**，第二个是**t**。因此，我们可以简单地为行进过程中的每个步骤计算一个半影因子，并采用所有半影中最暗的一个。在2019年，一些Shadertoy用户注意到，还可以将阴影计算偏移和偏移一半，以获取内部半影。最终代码如下所示：

```c#
float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float w )
{
    float s = 1.0;
    for( float t=mint; t<maxt; )
    {
        float h = map(ro + rd*t);
        s = min( s, 0.5+0.5*h/(w*t) );
        if( s<0.0 ) break;
        t += h;
    }
    s = max(s,0.0);
    return s*s*(3.0-2.0*s); // smoothstep
}
```

参数**w**是光源的大小，并控制阴影的强度。为使该算法稳定，我们应该沿射线精细地寻找半影。但是，由于我们在前进，因此我们很可能错过沿射线产生最暗半影的点。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/gfx14.png)

设y为当前点(绿色)到射线上最近点的距离(黄色)，d为当前点到估计最近距离的距离(上图中黄线长度的一半)。然后，计算这两个量的代码非常简单:

```c#
float y = r2*r2/(2.0*r1);
float d = sqrt(r2*r2-y*y);
```

其中r1和r2是红色和绿色球体的半径，换句话说，就是SDFs在之前和当前raymarch点处的求值。从这两个量，我们可以通过做以下事情来改进我们的半影估计:

```c#
float softshadow( in vec3 ro, in vec3 rd, float mint, float maxt, float k )
{
    float res = 1.0;
    float ph = 1e20;
    for( float t=mint; t<maxt; )
    {
        float h = map(ro + rd*t);
        if( h<0.001 )
            return 0.0;
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y)
        res = min( res, k*d/max(0.0,t-y) );
        ph = h;
        t += h;
    }
    return res;
}
```

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/Shadow2.PNG)

[代码](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E4%BB%A3%E7%A0%81/lighting/Shadow.shader)





#### Simple Pathtracing

编写全局照明渲染器需要一个小时。从头开始。编写*高效且通用的*全局照明渲染器需要十年。当以狂热爱好者而不是专业人士的身份进行计算机图形处理时，可以从实现中删除“高效”和“一般”方面。这意味着您确实可以在一小时内编写完整的全局照明渲染器。同样，鉴于当今硬件的强大功能，即使您不进行任何巧妙的优化或算法，全局照明系统也可以在几秒钟甚至实时的时间内进行渲染。

首先，我们需要

```c#
vec2  worldIntersect( in vec3 ro, in vec3 rd, in float maxlen );
float worldShadow(    in vec3 ro, in vec3 rd, in float maxlen );
```

worldIntersect函数以距离和对象ID的形式返回；worldShadow返回任何交集的存在（或者，如果没有交集，则返回1.0，如果有交集，则返回0.0）。这些功能的实现取决于应用程序的上下文。

```c#
vec3 worldGetNormal( in vec3 po, in float objectID );
vec3 worldGetColor( in vec3 po, in vec3 no, in float objectID );
vec3 worldGetBackground( in vec3 rd );
```

前两个函数返回3D场景中给定曲面点处的法线和表面颜色，第三个函数返回背景/天空色。

```c#
void worldMoveObjects（in float ctime）; 
mat4x3 worldMoveCamera（in float ctime）;
```

这两个功能可在场景中移动对象并在给定的动画时间内定位摄像机。

```c#
vec3 worldApplyLighting( in vec3 pos, in vec3 nor );
```

此函数计算3D场景表面上给定点和法线的直接照明。

*经典的直接光照模型*

```c#
vec3 calcPixelColor( in vec2 pixel, in vec2 resolution, in float frameTime )
{
    // screen coords
    vec2 p = (-resolution + 2.0*pixel) / resolution.y;

    // move objects
    worldMoveObjects( frameTime );

    // get camera position, and right/up/front axis
    vec3 (ro, uu, vv, ww) = worldMoveCamera( frameTime );

    // create ray
    vec3 rd = normalize( p.x*uu + p.y*vv + 2.5*ww );

    // calc pixel color
    vec3 col = rendererCalculateColor( ro, rd );

    // apply gamma correction
    col = pow( col, 0.45 );

    return col;
}
```

```c#
vec3 rendererCalculateColor( vec3 ro, vec3 rd )
{
    // intersect scene
    vec2 tres = worldIntersect( ro, rd, 1000.0 );

    // if nothing found, return background color
    if( tres.y < 0.0 )
       return worldGetBackground( rd );

    // get position and normal at the intersection point
    vec3 pos = ro + rd * tres.x;
    vec3 nor = worldGetNormal( pos, tres.y );

    // get color for the surface
    vec3 scol = worldGetColor( pos, nor, tres.y );

    // compute direct lighting
    vec3 dcol = worldApplyLighting( pos, nor );

    // surface * lighting
    vec3 tcol = scol * dcol;

    return tcol;
}
```

实际上，这是常规的直接照明渲染器。

==蒙特卡洛路径追踪器==





#### Multiresolution Ambient occlusion

总的来说，在业余爱好者中最流行的技术是SSAO，因为它根本不需要繁琐的烘焙工具开发，而只需一个带有几行代码的简单像素着色器。在我看来，它也是最容易滥用且可能应用错误的效果（紧随其后的是Blooming）

除了光晕和性能外，限制SSAO可用性的主要问题是该技术产生可解释为遮挡的结果的距离范围。实际上，由于缺乏第二和第三深度层来进行采样，因此高邻采样内核不仅昂贵，而且实际上不能很好地表示遮挡。同时，如果内核太小，则遮挡的错觉也消失了，剩下的只是一个丑陋的边缘增强器，这给了它所有可怕的卡通阴影效果。因此，似乎传统的SSAO仅是解决中频遮挡的最佳选择，而大/小尺寸遮挡（低频/高频）还需要其他解决方案。

在本文中，我们将看到一种解决一种特定类型场景的三种遮挡的方法

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/SSAO1.PNG)

==**Medium frequency ambient occlusion**==

```c#
uniform vec3       unKernel[16];
uniform sampler2D  unTexZ;
uniform sampler2D  unTexN;
uniform sampler2D  unTexR;

float ssao( in vec2 pixel )
{
    vec2  uv  = pixel*0.5 + 0.5;
    float z   = texture2D( unTexZ, uv ).x;      // read eye linear z
    vec3  nor = texture2D( unTexN, uv ).xyz;    // read normal
    vec3  ref = texture2D( unTexD, uv ).xyz;    // read dithering vector

    // accumulate occlusion
    float bl = 0.0;
    for( int i=0; i<16; i++ )
    {
        vec3  of = orientate( reflect( unKernel[i], ref ), nor );
        float sz = texture2D( unTexZ, uv+0.03*of.xy).x;
        float zd = (sz-z)*0.2;
        bl += clamp(zd*10.0,0.1,1.0)*(1.0-clamp((zd-1.0)/5.0,0.0,1.0));
    }

    return 1.0 - 1.0*bl/16.0;
}
```

使用的是已知的最旧的SSAO（具有通常的基于反射的抖动）以及基于法线的样本方向（这将更好地利用样本，并将法线贴图的细节引入到遮挡信号中）。如果其输入点与法线的乘积为负，则*orientate（）*函数将其翻转。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/B-SSAO.jpg)

**==High frequency ambient occlusion==**

High frequency occlusion, in this scene I'm dealing with and in many others, can be regarded as the occlusion an object casts on itself. That means that the occlusion signal can probably come from the model itself, either in form of backed information or with a procedural description.（高频遮挡可以看做物体投射到自己身上，这意味着遮挡可能来自物体自身）

在自然的情况下，对遮挡的过程描述很有意义。种植草，灌木，树干，树枝或冠层的相同程序方法也可以负责产生与程序生成的几何形状相匹配的遮挡信号。换句话说，由于代码/过程生成了几何图形，因此它知道该几何图形（例如它在哪里，它有多大），因此它可以产生合理的遮挡信息。

例如，当为树冠生成叶子时，树冠内部的叶子可能比外面的叶子更暗（这是一种非常简单的方法，但它显示了这一概念）。在程序上生长草的代码可以使着色器叶片变暗或变亮，这取决于它们相对于它们所属的丛的相对位置。程序树的树干在分支数量较高的区域可能会变暗，等等。

当然，我们的想法是不要烘焙我们可以通过程序完成的所有遮挡。有时候，过于聪明，程序化地生成或烘烤尽可能多的遮挡是很诱人的，但是我们不想这样做，因为这样做的目的是使遮挡实时且尽可能自动地作为照明解决方案的一部分。因此，我们只想生成/烘焙中频实时环境光遮挡（在我们的情况下为SSAO）无法捕获的光遮挡。

中加高频SSAO结果如下

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/B%2BHSSAO.jpg)

**==Low frequency ambient occlusion==**

这是来自对象太远而无法被SSAO捕获的遮挡。One could bake the information in low resolution lightmaps, but instead, game/demo specific tricks can be used which are cheaper, don't require tools or an export pipeline, and can be realtime.（可以烘焙低分辨率的光照贴图信息，此外，游戏中的特定技巧更加便宜，不需要额外的工具或管道，而且实时）

我们有一个户外场景，因此我们基本上希望看到的是树木和大石块在它们周围和下方的遮挡。轻松获得类似效果的一种方法是渲染具有垂直方向的阴影图，以捕获所有树木和岩石，然后进行超级模糊/ lp过滤的查找。这种工作会使树木下面的区域变暗，并使附近的物体有些暗黑。

可能还可以另外渲染三个模糊的阴影贴图，分别旋转120度方位角和45度高度，并更好地近似于低频环境光遮挡。但是请记住，完美的环境光遮挡无论如何也无法获得良好的图像，它本身仍然是一个缺陷，与适当的光线传播相去甚远。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/F-SSAO.jpg)

[原文](http://www.iquilezles.org/www/articles/multiresaocc/multiresaocc.htm)





#### Outdoors Lighting

这些情况下，有时可以通过巧妙地使用灯光来获得令人信服的图像，尤其是在大景观的户外照明中，间接照明的贡献适度且可预测。

本文介绍了在对景观进行此类小型计算机图形实验时使用的照明设备。它基本上由3或4个定向光，一个阴影，一些（伪造或屏幕空间）环境光遮挡和一个雾层组成。如果平衡得当，这几个元素往往表现良好，甚至看起来像是逼真的照片。

==The color space==

在开始进行任何照明和着色工作之前，最主要的事情是确保您在线性的颜色/照明空间中工作。这意味着您将像往常一样进行亮度，阴影和颜色数学运算，但是您确实也应用了伽玛曲线

```c#
color = pow( color, vec3(1.0/2.2) );
```

==Materials==

在不深入了解物理上正确的镜面反射BRDF或其他任何细节的情况下，仅将焦点放在漫反射组件上，请确保漫反射颜色为0.2左右，并且除了非常特殊的情况以外，没有其他颜色更亮。

如果您在没有gamma或任何其他内容的原始框架中工作，则可能会想将材料值和颜色视为它们将在屏幕中显示的最终颜色的代表。这种输出驱动的方法比任何方法都会给您带来更多的麻烦，因为材料的颜色/强度/值仅代表它们反射的光量。因此，将材质/纹理/颜色保持在0.2的范围内，如果需要在屏幕上使对象更亮，那么您想要做的就是使灯光更强烈，不是材料。

==First light==

根据照片是在阳光下还是在阴影下，通过调整关键光或填充光，可能更容易找到你想要的效果。如果你已经实现了自动曝光（automatic exposure）/色调映射，那么这并不重要，只要这些值之间的关系是正确的。在我的例子中，我在这个小渲染实验中没有使用色调映射，而且我通常发现在阴影下的图像更漂亮。

这里的第一个灯，例子中是太阳

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/gfx03.jpg)

关于阴影，有一个很棒的技巧，可以很好地发挥作用，并有助于创建美丽的日落或日出场景——就是将阴影的半影着色并过度饱和为某种红色或橙色。您可以通过将半影标量信号增强为一种颜色：

```c#
//计算柔和阴影 
float shadow = doGreatSoftShadow（pos，sunDir）;
//为半影着色 
vec3 cshadow = pow（vec3（shadow），vec3（1.0，1.2，1.5））;
```

另一个非常重要的技巧是避免对关键灯使用（环境）遮挡。

==Second light==

我们必须考虑的第二个光源是天空本身。当然，它的颜色将是蓝色的，与关键灯相比不是很亮。值为0.2可以正常工作。

从理论上讲，我们应该在半球的阴影点发射几条射线，并与它们一起收集visible_times_skycolor。但是，由于这可能非常昂贵，因此在许多情况下，对我来说，一个很好的折衷办法是用垂直方向垂直落在设备上的单个定向光替换天穹。如果需要创建夕阳的天空照明，则可以根据入射角为光着色。

==Third light==

The last light of our rig is used to implement indirect lighitng, without doing global illumination. Since the main soure of indirect light is the bounce of the sun light into the scene itself being reflected back in the oposite direction it was coming from (in overall), we can simply put a third and last directional light coming from aproximately the oposite direction of the sun. This light we will make it horizontal, so we are basically making copying the two horizontal coordinates of the sun direction and negating them, and leaving the vertical dimension to zero.

```c#
// compute materials
vec3 material = doFantasticMaterialColor( pos, nor );

// lighting terms
float occ = doGorgeousOcclusion( pos, nor );
float sha = doGreatSoftShadow( pos, sunDir );
float sun = clamp( dot( nor, sunDir ), 0.0, 1.0 );
float sky = clamp( 0.5 + 0.5*nor.y, 0.0 1.0 );
float ind = clamp( dot( nor, normalize(sunDir*vec3(-1.0,0.0,-1.0)) ), 0.0, 1.0 );

// compute lighting
vec3 lin  = sun*vec3(1.64,1.27,0.99)*pow(vec3(sha),vec3(1.0,1.2,1.5));
        lin += sky*vec3(0.16,0.20,0.28)*occ;
        lin += ind*vec3(0.40,0.28,0.20)*occ;

// multiply lighting and materials
vec3 color = material * lin;

// apply fog
color = doWonderfullFog( color, pos );

// gamma correction
color = pow( color, vec3(1.0/2.2) );

// display
displayColor = color;
```





#### Box Occlusion

由于该盒子是由6个四边形组成的，因此我们需要确定哪些阴影对着阴影点，并计算它们的遮挡。由于盒子是一个凸物体，并且没有任何面的投影重叠，因此我们可以分别计算每个面的遮挡作用，然后将它们全部加起来即可。

这里四边形遮挡的最终表达式如下
$$
occ=\frac{1}{2\pi}\cdot \sum_{t=0}^{3}(n\cdot(v_i\times v_{i+1}))\cdot acos(v_i\cdot v_{i+1})
$$
此处的顶点当然是相对于遮挡点的，必须对其进行归一化：
$$
v_i=\frac{p_i}{|p_i|}
$$
对于一个完全在阴影下的一个点的地平线上的盒子，我们所要做的就是计算每个面上面的公式。当然，由于我们是通过边进行集成的，所以我们可以跨共享边的面重用大部分工作。因此，如果实现是无分支的，那么上面的公式只需计算12次。然后，根据箱子正面的6个面中哪一个面对着阴影点，我们可以根据需要添加贡献:

```c#
float boxOcclusion( in vec3 pos, in vec3 nor, in vec3 box[8] ) 
{
    // 8 points    
    vec3 v[0] = normalize( box[0] );
    vec3 v[1] = normalize( box[1] );
    vec3 v[2] = normalize( box[2] );
    vec3 v[3] = normalize( box[3] );
    vec3 v[4] = normalize( box[4] );
    vec3 v[5] = normalize( box[5] );
    vec3 v[6] = normalize( box[6] );
    vec3 v[7] = normalize( box[7] );
    
    // 12 edges    
    float k02 = dot( n, normalize( cross(v[2],v[0])) ) * acos( dot(v[0],v[2]) );
    float k23 = dot( n, normalize( cross(v[3],v[2])) ) * acos( dot(v[2],v[3]) );
    float k31 = dot( n, normalize( cross(v[1],v[3])) ) * acos( dot(v[3],v[1]) );
    float k10 = dot( n, normalize( cross(v[0],v[1])) ) * acos( dot(v[1],v[0]) );
    float k45 = dot( n, normalize( cross(v[5],v[4])) ) * acos( dot(v[4],v[5]) );
    float k57 = dot( n, normalize( cross(v[7],v[5])) ) * acos( dot(v[5],v[7]) );
    float k76 = dot( n, normalize( cross(v[6],v[7])) ) * acos( dot(v[7],v[6]) );
    float k37 = dot( n, normalize( cross(v[7],v[3])) ) * acos( dot(v[3],v[7]) );
    float k64 = dot( n, normalize( cross(v[4],v[6])) ) * acos( dot(v[6],v[4]) );
    float k51 = dot( n, normalize( cross(v[1],v[5])) ) * acos( dot(v[5],v[1]) );
    float k04 = dot( n, normalize( cross(v[4],v[0])) ) * acos( dot(v[0],v[4]) );
    float k62 = dot( n, normalize( cross(v[2],v[6])) ) * acos( dot(v[6],v[2]) );
    
    // 6 faces
    float occ = 0.0;
    occ += ( k02 + k23 + k31 + k10) * step( 0.0,  v0.z );
    occ += ( k45 + k57 + k76 + k64) * step( 0.0, -v4.z );
    occ += ( k51 - k31 + k37 - k57) * step( 0.0, -v5.x );
    occ += ( k04 - k64 + k62 - k02) * step( 0.0,  v0.x );
    occ += (-k76 - k37 - k23 - k62) * step( 0.0, -v6.y );
    occ += (-k10 - k51 - k45 - k04) * step( 0.0,  v0.y );
        
    return occ / 6.283185;
}
```

==With clipping==

执行此操作的较慢方法是将框拆分为12个三角形，并考虑剪裁，为每个三角形计算遮挡。参见此处的示例：[https](https://www.shadertoy.com/view/4sSXDV) : [//www.shadertoy.com/view/4sSXDV](https://www.shadertoy.com/view/4sSXDV)。一个更聪明的选择是首先修剪12个边缘并生成一组新的边缘和面，然后对其进行遮挡。无论如何，这是一个计算可能被修剪的三角形的解析遮挡的示例：

<details>    
<summary>代码</summary>    
<pre><code>  
float triOcclusionWithClipping( in vec3 pos, in vec3 nor, in vec3 v0, in vec3 v1, in vec3 v2, in vec4 plane )
{
    if( dot( v0-pos, cross(v1-v0,v2-v0) ) < 0.0 ) return 0.0;  // back facing
    float s0 = dot( vec4(v0,1.0), plane );
    float s1 = dot( vec4(v1,1.0), plane );
    float s2 = dot( vec4(v2,1.0), plane );
    //
    float sn = sign(s0) + sign(s1) + sign(s2);
 	//
    vec3 c0 = clip( v0, v1, plane );
    vec3 c1 = clip( v1, v2, plane );
    vec3 c2 = clip( v2, v0, plane );
    // 3 (all) vertices above horizon
    if( sn>2.0 )  
    {
        return ftriOcclusion(  pos, nor, v0, v1, v2 );
    }
    // 2 vertices above horizon
    else if( sn>0.0 ) 
    {
        vec3 pa, pb, pc, pd;
              if( s0<0.0 )  { pa = c0; pb = v1; pc = v2; pd = c2; }
        else  if( s1<0.0 )  { pa = c1; pb = v2; pc = v0; pd = c0; }
        else/*if( s2<0.0 )*/{ pa = c2; pb = v0; pc = v1; pd = c1; }
        return fquadOcclusion( pos, nor, pa, pb, pc, pd );
    }
    // 1 vertex above horizon
    else if( sn>-2.0 ) 
    {
        vec3 pa, pb, pc;
              if( s0>0.0 )   { pa = c2; pb = v0; pc = c0; }
        else  if( s1>0.0 )   { pa = c0; pb = v1; pc = c1; }
        else/*if( s2>0.0 )*/ { pa = c1; pb = v2; pc = c2; }
        return ftriOcclusion(  pos, nor, pa, pb, pc );
    }
    // zero (no) vertices above horizon
    //
    return 0.0;
}
</code></pre>
</details>

<details>    
<summary>依赖函数</summary>    
<pre><code>  
// fully visible front facing Triangle occlusion
float ftriOcclusion( in vec3 pos, in vec3 nor, in vec3 v0, in vec3 v1, in vec3 v2 )
{
    vec3 a = normalize( v0 - pos );
    vec3 b = normalize( v1 - pos );
    vec3 c = normalize( v2 - pos );
	//
    return (dot( nor, normalize( cross(a,b)) ) * acos( dot(a,b) ) +
            dot( nor, normalize( cross(b,c)) ) * acos( dot(b,c) ) +
            dot( nor, normalize( cross(c,a)) ) * acos( dot(c,a) ) ) / 6.283185;
}
// fully visible front acing Quad occlusion
float fquadOcclusion( in vec3 pos, in vec3 nor, in vec3 v0, in vec3 v1, in vec3 v2, in vec3 v3 )
{
    vec3 a = normalize( v0 - pos );
    vec3 b = normalize( v1 - pos );
    vec3 c = normalize( v2 - pos );
    vec3 d = normalize( v3 - pos );
    //
    return (dot( nor, normalize( cross(a,b)) ) * acos( dot(a,b) ) +
            dot( nor, normalize( cross(b,c)) ) * acos( dot(b,c) ) +
            dot( nor, normalize( cross(c,d)) ) * acos( dot(c,d) ) +
            dot( nor, normalize( cross(d,a)) ) * acos( dot(d,a) ) ) / 6.283185;
}




#### Terrain Raymarching

基本思想是具有一个高度函数**y = f（x，z）**，该函数为平面**（x，z）**中的每个2d点定义该点处地形的高度。

一旦有了**f（x，z）**这样的函数，目标就是使用光线跟踪设置来渲染图像并做其他效果（如阴影或反射）。这意味着对于给定的光线，该光线在空间中具有某个起点（例如摄影机位置）和方向（例如视图方向），我们要计算光线与地形**f**的交点。最简单的方法是缓慢地沿射线方向缓慢前进，然后在每个步进点确定我们是否高于地形水平。下图显示了该过程。我们从靠近相机的光线中的某个点（图像中最左边的蓝色点）开始。我们在当前**x**和**z**处评估地形函数**f**坐标以获取地形的高度**h**：**h = f（x，z）**。现在，我们将蓝色采样点**y**的高度与**h进行比较**，我们意识到**y> h**或换句话说，蓝色点位于山的上方。因此，我们进入射线中的下一个蓝点，然后重复该过程。也许在某个点上，采样点之一将落在地形以下，例如图像中的黄色点。发生这种情况时，**y** ，我们知道射线穿过了地形表面。我们可以在此处停下来，将当前的黄色点标记为相交点（即使我们知道它比真实的相交点稍远），也可以将最后一个蓝色的点标记为相交点（比真实的相交点稍近）或最后一个蓝点和黄点的平均值。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/gfx02.png)

```c#
bool castRay( const vec3 & ro, const vec3 & rd, float & resT )
{
    const float dt = 0.01f;
    const float mint = 0.001f;
    const float maxt = 10.0f;
    for( float t = mint; t < maxt; t += dt )
    {
        const vec3 p = ro + rd*t;
        if( p.y < f( p.x, p.z ) )
        {
            resT = t - 0.5f*dt;
            return true;
        }
    }
    return false;
}
```

**mint**, **maxt**  **dt** 应该适应每一个场景。第一个是到近切平面的距离，你可以把它设为0。第二步是光线允许通过的最大距离，即可见距离。第三步是步长，步长直接影响渲染速度和图像质量。当然，它越大，速度越快，但是地形采样质量越低。

代码非常简单。当然，可以进行许多优化和改进。例如，通过对蓝点和黄点之间的地形高度进行线性近似并计算射线与理想地形之间的解析交点，可以更准确地完成交点的精度。

另一个优化是注意到，随着移动的潜在交点越来越远(t变得越大)，错误变得越不重要，因为随着距离摄像机越来越远，屏幕空间中的几何细节变得越来越小。事实上，细节随距离呈反线性衰减，所以我们可以使我们的误差或精度与距离呈线性变化。

==*支持地形的线性插值和自适应误差*==

```c#
bool castRay( const vec3 & ro, const vec3 & rd, float & resT )
{
    float dt = 0.01f;
    const float mint = 0.001f;
    const float maxt = 10.0f;
    float lh = 0.0f;
    float ly = 0.0f;
    for( float t = mint; t < maxt; t += dt )
    {
        const vec3  p = ro + rd*t;
        const float h = f( p.xz );
        if( p.y < h )
        {
            // interpolate the intersection distance
            resT = t - dt + dt*(lh-ly)/(p.y-ly-h+lh);
            return true;
        }
        // allow the error to be proportinal to the distance
        dt = 0.01f*t;
        lh = h;
        ly = p.y;
    }
    return false;
}
```

因此，构建图像的完整算法很简单。对于屏幕上的每个像素，构造一束光线，该光线从相机位置开始穿过像素位置，就好像屏幕就在查看器正前方一样，然后投射该光线。一旦找到相交点，就必须收集地形的颜色，加阴影并返回颜色。这就是*terrainColor（）*函数必须执行的操作。如果没有与地形的交叉点，则必须为天空计算正确的颜色。因此，主要代码如下所示：

```c#
void renderImage( vec3 *image )
{
    for( int j=0; j < yres; j++ )
    for( int i=0; i < xres; i++ )
    {
        Ray ray = generateRayForPixel( i, j );

        float t;

        if( castRay( ray.origin, ray.direction, t ) )
        {
            image[xres*j+i] = terrainColor( ray, t );
        }
        else
        {
            image[xres*j+i] = skyColor();
        }
    }
}
```

通常terrainColor()首先需要计算交点p，然后计算正常表面n，做一些基于正常照明/阴影s，是这样的:

```c#
vec3 terrainColor( const Ray & ray, float t )
{
    const vec3 p = ray.origin + ray.direction * t;
    const vec3 n = getNormal( p );
    const vec3 s = getShading( p, n );
    const vec3 m = getMaterial( p, n );
    return applyFog( m * s, t );
}
vec3 getNormal( const vec3 & p )
{
    return normalize( vec3( f(p.x-eps,p.z) - f(p.x+eps,p.z),
                            2.0f*eps,
                            f(p.x,p.z-eps) - f(p.x,p.z+eps) ) );
}
```

getShading（）函数可能需要根据模拟太阳的强大黄色偏光和模拟天顶的暗淡蓝色区域光（某种环境光遮挡）来计算一些漫射光。在地形上做阴影很有趣，因为可以进行许多优化。一种这样的技巧是通过计算阴影射线进入地形的深度来免费计算软阴影。通过smoothstep（）设置这一数量，就可以控制山脉的半影。

要获取表面材料，通常是山的海拔高度和坡度以及点**p**被考虑在内。例如，在高海拔地区，您可以返回白色，而在低海拔地区，则可以返回棕色或灰色。可以使用一些*smoothstep（）*函数再次控制过渡。只需记住将所有参数随机化（使用佩林噪声），这样过渡就不会恒定，因此看起来更自然。考虑到地形的坡度也是一个好主意，因为雪和草通常只停留在平坦的表面上。因此，如果法线非常水平（即**ny**小），则最好将其与一些灰色或棕色混合，以去除雪或草。这使纹理自然适合地形，并且图像变得更丰富。





#### Volumetric Sort

假设您有一组要进行Alpha混合的对象。假设这些对象的位置是恒定的。并假设所有对象都沿着2d或3d网格放置。然后，您可以非常容易地以几乎为零的性能成本对这些对象进行排序，并且本文将向您说明如何进行。

==In 2D==

我们首先考虑2D问题。假设您有一个像下面这样的对象网格。现在，假设您正在从图中橙色箭头指示的角度查看此对象网格。现在，尝试同意以下事实：在这种情况下，您可以从**a**，**b** -...线到**p**，**q** -... 线开始逐行绘制对象。

以一种非常相似的方式，如绿色箭头所示：...，**p**，**k**，**f**，**a**，...，**q**，**l**， **g**，**b**，...![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/grid1.jpg)

所以这很简单。我们可以仅基于视图向量来确定顺序。如果使用“ + x”，“-x”，“ + y”和“ -y”代替“从左至右”和“从上至下”，我们可以很容易地看到存在8种不同的可能顺序：{ +x+y, +x-y, -x+y, +x-y, +y+x, +y-x, -y+x, -y-x } (basically we have 4 options for the first axis (+x, -x, +y, -y) and the there is only 2 remaining for the second (+x, -x or +y, -y, depending on the first option).

如您所见，一个顺序和另一个顺序之间的过渡是在半象限上完成的。该图显示了分为8个部分的2D正方形分割，显示了相同顺序有效的区域（您可以看到橙色和绿色区域，与我们在上图中用作示例的箭头相对应）。现在的诀窍很明显：预先计算8个索引数组，并保存内存中，每个可能的顺序一个。对于每个渲染过程，采用视图方向并计算最合适的顺序，然后使用它进行渲染。因此，我们基本上跳过了任何排序时间，也跳过了CPU和GPU之间的总线通信。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/gfx_01.jpg)

==In 3D==

在3D中，情况是完全一样的，我们只有一个轴。所不同的是，现在可能的顺序数量更大。对于第一个轴的顺序，我们有6个选项（-x，+ x，-y，+ y，-z，+ z），对于第二个轴，我们有4个选项（假设我们选择了-x，我们仍然有-y，+ y，-z，+ z）和2作为最后一个轴（假设我们选择了+ z，我们仍然有-y和+ y）。因此，总共有48种可能性！根据应用程序的不同，这可能会占用大量视频内存。当然，有一些简单的技巧可以提供帮助。例如，我们将48个副本保留在内存中，然后仅上传所需的副本。假设帧到帧的一致性，这种情况应该很少发生。我们甚至可以有一个与渲染并行运行的小线程，只计算索引数组，而不是预先计算并将其存储在系统内存中。

另一个技巧是使用顶层网格对对象的单元格进行排序，然后对单元格中的对象进行随机排序。如果物体在一片草地上，则可以很好地工作。甚至，如果我们已经拥有八叉树数据结构来对数据集执行平截头剔除和遮挡查询，则可以使用此技术对八叉树节点进行排序，然后在可见节点中进行标准CPU排序，甚至可以预先计算索引数组节点。

现在，视图矢量可以属于多维数据集表面中的48个可能的部分，如下图所示。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/gfx_00.jpg)

为了完成本文，需要一些代码来说明如何从3D视图向量中获取索引（从0到47）。可能有更简单的方法（紧凑阅读）。

```c#
int calcOrder( const vec3 & dir )
{
    int signs;

    const int   sx = dir.x<0.0f;
    const int   sy = dir.y<0.0f;
    const int   sz = dir.z<0.0f;
    const float ax = fabsf( dir.x );
    const float ay = fabsf( dir.y );
    const float az = fabsf( dir.z );

    if( ax>ay && ax>az )
    {
        if( ay>az ) signs = 0 + ((sx<<2)|(sy<<1)|sz);
        else        signs = 8 + ((sx<<2)|(sz<<1)|sy);
    }
    else if( ay>az )
    {
        if( ax>az ) signs = 16 + ((sy<<2)|(sx<<1)|sz);
        else        signs = 24 + ((sy<<2)|(sz<<1)|sx);
    }
    else
    {
        if( ax>ay ) signs = 32 + ((sz<<2)|(sx<<1)|sy);
        else        signs = 40 + ((sz<<2)|(sy<<1)|sx);
    }

    return signs;
}
```







#### Smooth Minimum

隐式过程建模的基本构建块之一（例如，当基于[基本图元](http://www.iquilezles.org/www/articles/distfunctions/distfunctions.htm)构建用于光线行进的距离场时）是联合运算符

```c#
float opU( float d1, float d2 )
{
    return min( d1, d2 );
}
```

该算子效果很好，但存在一个问题，即所得形状的导数不连续。换句话说，将两个光滑对象统一在一起的结果表面不再是光滑表面。从外观角度来看，这通常很不方便，例如在尝试对有机形状进行建模时。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/spider.PNG)

==Several implementations==

当然，平滑混合形状的方法是摆脱min（）函数的不连续性。但是我们希望当两个原语之一远于另一个原语时，smooth-min函数的行为就像min（）一样。我们只想在两个值变得相似的区域应用平滑度。

```c#
// exponential smooth min (k = 32);
float smin( float a, float b, float k )
{
    float res = exp2( -k*a ) + exp2( -k*b );
    return -log2( res )/k;
}
// polynomial smooth min (k = 0.1);
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}
// power smooth min (k = 8);
float smin( float a, float b, float k )
{
    a = pow( a, k ); b = pow( b, k );
    return pow( (a*b)/(a+b), 1.0/k );
}
```

这三种功能产生的平滑结果具有不同的质量。这三个参数接受控制平滑度的半径/距离的参数*k*。从这三个中，多项式可能是最快的，也是最容易控制的，因为*k*直接映射到混合频带的大小/距离。与其他两个不同，它可能遭受二阶不连续性（导数）的困扰，但对于大多数应用程序而言，在视觉上足够令人满意。

基于指数和幂的平滑最小函数都可以推广到两个以上的距离，因此它们可能更适合于计算到超过2的大点集的最小距离，例如当您想要计算[平滑的voronoi模式](http://www.iquilezles.org/www/articles/smoothvoronoi/smoothvoronoi.htm)或插值点云。在基于功率的最小平滑函数的情况下，表达式*a \* b /（a + b）的*推广公式与计算N个并联电阻的全局电阻时的公式相同：1 /（1 / a + 1 / b + 1 / c + ...）。例如，对于三个距离，您将得到a * b * c /（b * c + c + a + a * b）。

除了接受一个可变数量的点之外，与多项式smin()相比，指数smin()的另一个优点是，当使用两个参数同时多次调用时，无论操作的顺序如何，指数smin()都会产生相同的结果。然而，多项式smin()不是顺序无关的。更明确地说，smin(a, smin(b,c))对于指数smin()等于smin(b,smin(a,c))，但对于多项式却不是。That means that the exponential smin() allows one to process long lists of distances in any arbitrary order and slowly compute the smin, while the polynomial is ordering dependent.

以等效但更有效的形式重写了多项式smin（）

```c#
// polynomial smooth min (k = 0.1);
float smin( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*k*(1.0/4.0);
}
```

正如Shadertoy用户TinyTexel所指出的，可以推广到比二次多项式提供的(C1)更高的连续性级别。移到三次曲线上可以得到C2的连续性，而且不会比二次曲线贵很多:

```c#
// polynomial smooth min (k = 0.1);
float sminCubic( float a, float b, float k )
{
    float h = max( k-abs(a-b), 0.0 )/k;
    return min( a, b ) - h*h*h*k*(1.0/6.0);
}
```

==Sumary==

最有用的最小平滑函数的性质:

Quadratic:

- smin(a,b,k) = min(a,b) - h²/(4k)
  h = max( k-abs(a-b), 0 )
- Continity: C1
- Order Independent: No
- Generalized: No

Cubic:

- smin(a,b,k) = min(a,b) - h³/(6k²)
  h = max( k-abs(a-b), 0)
- Continity: C2
- Order Independent: No
- Generalized: No

Exponential:

- smin(a,b,k) = -ln( e-k⋅a + e-k⋅b )/k
- Continity: C-inf
- Order Independent: Yes
- Generalized: Yes