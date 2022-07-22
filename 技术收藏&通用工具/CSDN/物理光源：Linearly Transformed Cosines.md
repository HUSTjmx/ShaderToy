![在这里插入图片描述](https://img-blog.csdnimg.cn/a8adf95bda0f4960a21625319bdf8b23.png)
## 1. 介绍
:one:首先，确认`LTC`技术的目标：解决**多边形面光源**的光照积分问题，特别是==高光部分的求解==。**多边形面光源的积分**和我们之前考虑的问题都不一样：

 - 常见光源（点光源、`SpotLight`等）：简单，积分域就是一个点。
 - 环境贴图：复杂一点，积分域是**半球域**——一般来说，我们都是使用`IBL`技术类，进行简化。

我们考虑更加物理的光源：多边形光源。这个时候，积分域 $S$ 就很复杂了，求解更加复杂：
$$
	I=\int_S(L(w_l)\cdot f(p,w_i,w_o)\cdot \cos(\theta_p))dw_i
$$

> 注意：我们考虑的是**多边形光源**，这意味着这个光源的所有顶点都是在一个平面上，不能有凹凸！

最朴素的思想就是：使用蒙特卡罗方法。但这个思路在性能上是无法接受的。

:two:作者就发现了一种**线性变换球面分布**（`Linearly Transformed Spherical Distributions` ）的思想。这种思想就是对于**任意一个球面分布函数**，一定可以通过**一个线性变换矩阵**将其变化到**另外一个球面分布函数**。这个时候希望来了，由于$cos^+(\theta_i)$是一个球面分布函数（余弦分布函数），$f(p,w_i,w_o)$ 也是一个球面分布函数。

那么具体这个算法到底是什么呢？

> $cos^+$是**clamp余弦**


:three:根据论文，我们拿来进行简化计算的球面分布函数，实际上是 $cos^+(\theta_i) \cdot \frac{1}{\pi}$。而原来的复杂的球面分布函数，实际上是 $f(p,w_i,w_o)\cdot \cos{\theta_i}$

## 2. 算法分析
### 2.1 思路
:one:根据第一节，我们有两个认识：

 1. 在多边形光源上进行**实时光照积分**是困难的。($S$ 是多边形积分域)
 $$
 I=\int_S(L(w_l)\cdot f(p,w_i,w_o)\cdot \cos(\theta_p))dw_i
 $$
 2.  根据`LTCS`思想（数学思想，所以我不懂，只是给出结论）：存在一个==变换矩阵== $M$，可以把**简单的球面分布函数** $cos^+(\theta_i)\cdot \frac{1}{\pi}$，变换成**复杂的球面分布函数** $f(p,w_i,w_o)\cdot \cos{\theta_i}$。
 $$
 f(p,w_i,w_o)\cdot \cos{\theta_i}\approx M* \frac{cos^+(\theta_i)}{\pi}
 $$
注意：这里的`*`不是普通的矩阵乘法，**这里的线性变换是指把我们的入射向量乘以矩阵M**。
> 矩阵$M$ : 三阶矩阵。根据论文，它主要包括如下的性质：
> ![在这里插入图片描述](https://img-blog.csdnimg.cn/65e95a1b251b453e9ecfd00df938aadd.png)


:two:但是，还是看不出来有什么用，所以我们需要知道`LTCS`的另外一个性质：
$$
\int_SD(w)dw=\int_{S_t}D_t(w_t)dw_t
$$
所以，我们会有：
$$
\int_S f(p,w_i,w_o)\cdot \cos{\theta_i} dw_i=\int_{S_t}\frac{cos^+(\theta_i)}{\pi} dw_t
$$
而积分域：$S=M*S_t$。积分域进行变换，实际上就是对这个多边形域的每个顶点，应用这个矩阵$M$。





:three:对 $cos$ 进行积分是很简单的，哪怕积分域 $S_t$ 比原积分域 $S$ 复杂很多，也不会有太大影响——实际上，积分域 $S_t$ 也不会比 $S$ 复杂，毕竟，我们并没有增加删除顶点，而只是对顶点的位置进行变换（不考虑裁剪：$S$ 是五边形，$S_t$ 也会是五边形）。而且似乎对 $cos$ 进行积分有近似方法，这个后续进行分析。

:four:所以我们的==最终的目标==就是：放弃在多边形积分域$S$中，使用复杂的 $D(w)=f(p,w_i,w_o)\cdot \cos{\theta_i}$进行光照积分，而是使用简单的 $D_t(w_t)=\frac{cos^+(\theta_i)}{\pi}$进行积分计算。
$$
I=\int_{S_t}(L(w_t)\cdot D_t(w_t))dw_t
$$

但目前还是有**两个问题**需要解决：

 1. 我们需要确定积分域 $S_t$，所以我们需要知道 $M^{-1}$。
 2. 光照积分中可不只有**球面分布函数** $D_t(w_t)$，还有入射光 $L(w_t)$！

我们依次来解决！

### 2.2 预计算矩阵M
![在这里插入图片描述](https://img-blog.csdnimg.cn/f1065572ff5f4cc0a51b091a2db86aa2.png)

:one:根据原论文，我们可以知道，变换前后的球面分布函数有如下关系：
$$
D(w)=D_t(w_t)\frac{\delta w_t}{\delta w}=D_o(\frac{M^{-1}w}{||M^{-1}w||})\frac{|M^{-1}|}{||M^{-1}w||^3}
$$
其中，$D(w)=f(p,w,w_o)\cdot \cos{\theta_i}$，$D_o(w_t)=\frac{\cos{\theta_t}}{\pi}$，$w_t=M*w$。$M$ 就是我们需要的**转换矩阵**。根据原论文，这个矩阵 $M$ 实际上有如下固定形式：
![在这里插入图片描述](https://img-blog.csdnimg.cn/0184c33b317c4a26afb012d05fe8ac77.png)
:two:所以，我们的问题从求得一个矩阵，变成了求得$(a,b,c,d)$的值，那么，怎么求呢？

和`IBL`方法类似，我们在`BRDF`中不考虑菲涅尔项，而且假设**入射方向等于法线方向**，那么 $f(p,w_i,w_o)\cdot \cos{\theta_i}$ 项就只依赖于==视线方向==和==粗糙度==。那么我们就可以计算得到一个张类似于`BRDF LUT`的二维纹理，其横纵坐标是**视线法线夹角**和**粗糙度**。

:three:咦？我们似乎还是不会求$M$？根据[大佬的博客](https://zhuanlan.zhihu.com/p/360040187)：对于任意一个$f(p,w_i,w_o)\cdot \cos{\theta_i}$ 一定找的到一个**M变换矩阵**把他变换到**余弦分布**，因此其实只需要遍历所有的矩阵M总能找到一个误差足够小的矩阵 $M$，不过**穷举法**不可能，我们采用一种==单纯形法==用于寻找 $M$。单纯形法的具体过程有点类似梯度下降的思路，我们随机初始化一个矩阵 $M$，然后经过计算，我们会得到一个“梯度”也就是我们该往哪个方向去修正我们的矩阵 $M$，循环往复，直到 $M$ 的误差在接受范围内。

具体过程来说：

 1. 对于`LUT`的每个坐标，也就是一对具体的**视线法线夹角**和**粗糙度**，我们可以随意取一个入射方向$w$，求得$N_0=f(p,w,w_o) \cdot \cos{\theta_i}$。
 2. 初始化一个矩阵 $M$，代入公式 $D_o(\frac{M^{-1}w}{||M^{-1}w||})\frac{|M^{-1}|}{||M^{-1}w||^3}$求值，得到$N_1$。
 3. 求$|N_0-N_1|$的`L3`范数，作为误差 $e$ 。
 4.  不断更新 $M$ ，知道误差 $e$ 足够小（==怎么更新，暂未研究==）。

:four:我们进行预计算，最终得到一张横纵坐标是**视线法线夹角**和**粗糙度**，存储了转换矩阵的逆 $M^{-1}$的`LUT`。

>[M矩阵预计算code](https://github.com/AngelMonica126/GraphicAlgorithm/tree/master/FitLTCMatrix)

### 2.3 恒定多边形光源
![在这里插入图片描述](https://img-blog.csdnimg.cn/62a160bcdb45402c8b90f4bc45d036f8.png)


:one:最简单的情况就是：多边形光源的辐照度是恒定的，那么这个时候，入射光$L$就可以直接提出来。
$$
I=L\cdot\int_{S_t}\frac{1}{||s-p||^2} \cdot \frac{\cos{\theta_t}}{\pi} dw_t
$$
其中，$s$ 是渲染点，$p$是多边形光源上的点（变化后的，位于$S_t$上）。而且，根据Daniel的方法，上诉积分具有解析解：
$$
\int_{S_t}\frac{1}{||s-p||^2} \cdot \frac{\cos{\theta_t}}{\pi} dw_t=\frac{1}{2\pi}\sum_{j=1}^{e}{n_p\cdot\frac{\Gamma_j}{||\Gamma_j||}}\Upsilon_j=I_D
\\
--------------------\\
\Gamma_j=Y_j \times Y_{j+1}
$$
其中，$e$ 是多边形光源的边数，$n_p$ 为渲染点 $p$ 法线，$Y_j$ 是着色点到多边形顶点的向量（这些顶点都是经过变换的，位于 $S_t$），$\Upsilon_j$为向量之间的夹角（$Y_j$ 和 $Y_{j+1}$之间的夹角 ）。

>$\frac{1}{||s-p||^2}$来自于==光线衰减==。

:two:所以，我们最终只需进行如下计算即可：
$$
L(p,w_o)=L\cdot I_D
$$

### 2.4 纹理光源
![在这里插入图片描述](https://img-blog.csdnimg.cn/57375fa6cd07400c9abb29bbc0858413.png)
:one:**纹理多边形光源**的辐照度明显是**不均匀的**，所以我们不能直接将入射光提取出来，但我们可以利用下面这个常用技巧：
$$
I=\int_S{(L(w_l)D(w_l))}dw_l\approx I_D\cdot I_L
\\
-------\\
I_D=\int_SD(w_l)dw_l
\\
-------\\
I_L=\frac{\int_S{(L(w_l)D(w_l))}dw_l}{\int_SD(w_l)dw_l}
$$
我们把积分拆成两部分，第一部分$I_D$很简单，就是我们所需的完美形式，可以直接使用**Daniel的方法**求得解析解：
$$
\int_{S_t}\frac{1}{||s-p||^2} \cdot \frac{\cos{\theta_t}}{\pi} dw_t=\frac{1}{2\pi}\sum_{j=1}^{e}{n_p\cdot\frac{\Gamma_j}{||\Gamma_j||}}\Upsilon_j=I_D
\\
--------------------\\
\Gamma_j=Y_j \times Y_{j+1}
$$
:two:第二部分 $I_L$ 怎么办呢？作者的方法是，可以看做**纹理进行滤波后的值**。在预过滤的步骤中，作者使用==高斯滤波器==，采取**不同的过滤核半径**进行过滤，对应**不同的LOD**。

> 根据论文，这个过滤还有个**需要注意的地方**：预过滤纹理的值必须定义在纹理空间的每个地方，甚至在纹理之外——作者在纹理周围引入一个边缘，在这个区域，增加了滤镜的半径，使其与纹理相交。
> ![在这里插入图片描述](https://img-blog.csdnimg.cn/2323ddf963b742aca45ea99230aad076.png)

:three:对于 $I_L$ ，我们还有最后一个需要解决的问题，那就是用来读取这个纹理的`UV`和`LOD Level`。

 - `LOD Level`，论文里面是通过一个**一维函数**——纹理平面的平方距离$r^2$与多边形的面积$a$之比：$\frac{r^2}{a}$。此外，最终结果需要进行混合，例如，我们得到的`LOD Level`是`3.4`，那么我们需要读取`Level 3`和`Level 4`的纹理值，然后进行混合（权重各自是`0.6`和`0.4`）。
 - `UV`。我们在使用**Daniel的方法**进行求解的时候，会得到==一个指向面光源的向量==，这个向量所指面光源上的点是**对光照贡献最大的点**，记作`Q`点。我们需要做到就是得到这个`Q`点，并算出它在这个纹理平面上对应的`UV`坐标。
 
:four:以下**读取纹理贴图的源码**来自[Monica大佬的Github](https://github.com/AngelMonica126/GraphicAlgorithm/blob/master/010_RealTimePolygonalLightShadingWithLinearlyTransformedCosines/Ground_FS.glsl)：

```cpp
// vPolygonalLightVertexPos: 多边形光源的顶点
// vLooupVector：Daniel方法进行求解得到的向量
vec3 fecthFilteredLightTexture(vec3 vPolygonalLightVertexPos[4], vec3 vLooupVector)
{
	vec3 V1 = vPolygonalLightVertexPos[1] - vPolygonalLightVertexPos[0];
	vec3 V2 = vPolygonalLightVertexPos[3] - vPolygonalLightVertexPos[0];
	vec3 PlaneOrtho = cross(V1, V2);
	float PlaneAreaSquared = dot(PlaneOrtho, PlaneOrtho);
	
	SRay Ray;
	Ray.m_Origin = vec3(0);
	Ray.m_Dir = vLooupVector;
	vec4 Plane = vec4(PlaneOrtho, -dot(PlaneOrtho, vPolygonalLightVertexPos[0]));
	float Distance2Plane;
	rayPlaneIntersect(Ray, Plane, Distance2Plane);
	
	vec3 P = Distance2Plane * Ray.m_Dir - vPolygonalLightVertexPos[0];

	float Dot_V1_V2 = dot(V1, V2);
	float Inv_Dot_V1_V1 = 1.0 / dot(V1, V1);
	vec3  V2_ = V2 - V1 * Dot_V1_V2 * Inv_Dot_V1_V1;
	vec2  UV;
	UV.y = dot(V2_, P) / dot(V2_, V2_);
	UV.x = dot(V1, P) * Inv_Dot_V1_V1 - Dot_V1_V2 * Inv_Dot_V1_V1 * UV.y;
	UV = vec2(1 - UV.y, 1 - UV.x);
	
	float Distance = abs(Distance2Plane) / pow(PlaneAreaSquared, 0.25);
	
	float Lod = log(2048.0 * Distance) / log(3.0);

	float LodA = floor(Lod);
	float LodB = ceil(Lod);
	float t = Lod - LodA;
	vec3 ColorA = texture(u_FilteredLightTexture, vec3(UV, LodA)).rgb;
	vec3 ColorB = texture(u_FilteredLightTexture, vec3(UV, LodB)).rgb;
	return mix(ColorA, ColorB, t);
}

```
:five:最终，我们得到了此时的结果：
$$
I=I_L\cdot I_D
$$

### 2.5 考虑菲涅尔项

> 不知道对不对

:one:之前在计算过程中一直忽略了**菲涅耳项**，因此我们还需要计算**菲涅耳项**用于对上面计算的光照结果进行矫正。这里的思路也是类似`IBL`的方法，所以我们还需要使用第二张`LUT`，也就是大名鼎鼎的`BRDF LUT`：
![在这里插入图片描述](https://img-blog.csdnimg.cn/ec44ae2ef98d415e9030cd86a4511a39.png)
然后，实时运行时，直接使用：

```cpp
// F 就是 F0, 或者说 Specular Color
vec2 envBRDF  = texture(brdfLUT, vec2(max(dot(N, V), 0.0), roughness)).rg;
vec3 specular = prefilteredColor * (F * envBRDF.x + envBRDF.y);
```
:two:所以说，最终结果是：
$$
I_{Spec}=(F_0*LUT.x+LUT.y)\cdot I_D \cdot I_L
$$

### 2.6 关于漫反射项
:one:以上一切都是关于计算高光的，和漫反射无关。

:two:而实际上，漫反射的计算要简单的多，因为它没有`lob`，是均匀的，所以实际上它根本**不需要考虑变换矩阵** $M$，在代码上，则是如下：

```cpp
vec3 LTC_Evaluate(vec3 N, vec3 V, vec3 P, mat3 Minv, vec3 points[4], bool twoSided);
...
vec3 spec = LTC_Evaluate(N, V, pos, Minv, points, twoSided);
spec *= texture2D(ltc_mag, uv).w;
// 矩阵M是单位矩阵，不需要任何转换
vec3 diff = LTC_Evaluate(N, V, pos, mat3(1), points, twoSided); 
col  = lcol*(scol*spec + dcol*diff);
col /= 2.0*pi;
```

## 3. 参考
[1][Monica的小甜甜的博客](https://www.zhihu.com/people/VeerZeng/posts)
[2][官方源码](https://blog.selfshadow.com/sandbox/ltc.html)
[3][Real-Time Polygonal-Light Shading with Linearly Transformed Cosines]
