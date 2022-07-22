## 1. 介绍
物体在不同光照下的表现不同，`PRT`（Precomputed Radiance Transfer）是一 个计算物体在不同光照下表现的方法。光线在一个环境中，会经历**反射**，**折射**， **散射**，甚至还会在物体的内部进行**散射**。为了模拟具有真实感的渲染结果，传统的 `Path Tracing` 方法需要考虑来自各个方向的光线、所有可能的传播形式，并且**收敛速度极慢**。`PRT `使用一种**预计算方法**，该方法在离线渲染的 **Path Tracing 工具链**中预计算 `lighting `以及 `light transport`， 并将它们用**球谐函数**拟合后储存，这样就将时间开销转移到了离线中。最后通过使用这些预计算好的数据，我们可以轻松达到实时渲染**严苛的时间要求**，同时渲染结果可以呈现出**全局光照**的效果。 

**预计算部分**是` PRT` 算法的核心，也是其局限性的根源。因为在预计算 `light transfer` 时包含了 `visibility` 以及` cos `项，这代表着实时渲染使用的这些**几何信息**已经完全固定了下来。所以 `PRT `方法存在的**限制**包括： 
 - 不能计算随机动态场景的**全局光照**
 - 场景中物体**不可变动**。



> 以上实际上来自Games202作业2，下面给出**我自己的技术理解**

个人觉得，`Light Map`、`Irradiance Map`、`Precomputed Radiance Transfer`应该是一脉相承的，都是使用**预计算**，来解决**渲染质量和性能的权衡问题**：

 1. `Light Map`。此技术实际上只是把常数项（$f_d$）提取出来，然后没有采用`split sum`，而是基于**实际的对象**，没有做任何近似，直接使用**路径追踪**等复杂离线方法来计算。此技术不仅绑定了光源（静态）、还绑定了对象（静态）。一般引擎中的**烘焙过程**就是使用了此技术。此技术的限制极大，物体和光源必须都是**静态的**，一旦变换其一，就需要**重新烘焙**，来计算`Light Map`。实际渲染过程中，由于引擎都是以**低分辨率**计算`Light Map`，然后将多个物体、多个表面的`Light Map`存在一张纹理上，所以需要使用特定的`LightUV`来读取`Light Map`，然后再乘上$f_d$（或`albedo`）。
        $$
        	L_{pre}=\int {L\cdot V\cdot dot(n\cdot l)} dw 
        $$
        ![在这里插入图片描述](https://img-blog.csdnimg.cn/ab3b8aa9a8eb4a1f832d4fd5f2826dd5.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)

 
 2. `Irradiance Map`。此技术详情见[我的另外一篇博客](https://blog.csdn.net/JMXIN422/article/details/123180206?spm=1001.2014.3001.5501)。这里简单讲下：为了避免`Light Map`过于严苛的限制，让**运动物体**可以收益于**预计算**。`Irradiance Map`提出了一个**重大假设**：那就是环境光源**无限远**，物体上的每一个点，相对于环境光，都是一致的，并且忽略掉**自反射和自阴影**。这样的话，我们就只绑定了光源，物体在此光源的影响范围内，可以任意的**旋转和移动**。在预计算公式上，其实也和`Light Map`没有区别（去掉了`V`），只是考虑原理不一样了。实际渲染过程中，以法线作为索引，来读取这张**环境贴图**，然后乘上 $f_d$ 即可。
       $$
        	L_{pre}=\int {L\cdot dot(n\cdot l)} dw 
        $$
 3. `Efficient Irradiance Map`。此技术详情见[我的另外一篇博客](https://blog.csdn.net/JMXIN422/article/details/123180206?spm=1001.2014.3001.5501)。个人目前对于`RTR4`以及原论文中的关于此技术起源的解释，还是不能理解。所以这里给出我的解释： `Irradiance Map`低频的特性（相当于**低通滤波器**），意味着它的**入射光照分布**可以用**光滑曲线**去近似，而依然可以取得**不错的渲染结果**。那么直接给出答案吧（以下都以**三阶SH**举例数字）：我们可以将光照分布投影到少数几个（27个`float`）SH系数上，实际使用时**重建**，这样可以极大压缩内存需求。而这个时候，为了投影到SH上，我们需要使用把**原本的积分方程**拆成两部分：光照部分`L`和余弦部分`cos`，分别对其进行**SH投影**。这里产生了一个问题：法线`n`和$L(w)$不同，它独立于`w`，相当于第二个参数，我们需要对每个可能的方向（总共 $width* height$ 个方向）做**SH投影**，那么就会产生 $27 * width* height$个SH系数，这相当于**好几张纹理**了，这根本不省内存！幸运的是，受益于**SH旋转不变**的特性，可以简化为基于法线的缩放系数 $A_l$，来可以克服这个问题，最终的渲染过程也正如我们的期待：计算得到最终的法线$N(\theta,\phi)$后，根据**法线的球坐标**，得到各个球谐基$Y_{l.m}(\theta,\phi)$的值，然后代入**重建公式**：
 $$
 E(\theta,\phi)=\sum_{l,m}{A_l}L_{lm}Y_{lm}(\theta,\phi)
 $$
 4. `Precomputed Radiance Transfer`。`PRT`又是另外一个技术路线了，它不关注$\int (L) dw$部分（可以直接按照`Efficient Irradiance Map`进行SH投影），而是重新捡起了 $V$项，并且还考虑了**自反射**，也就是说，我们在这关注的是$\int(V\cdot cos)dw$部分，这部分也被称为**传输项**。这里只是起个头，具体的还是看后文。
![在这里插入图片描述](https://img-blog.csdnimg.cn/b5dd1184b9c844f3af0b638de704f1e8.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)



## 2. Diffuse Transfer
正如前文所说，`PRT`技术的核心在于怎么求解**转移方程**，来解释物体如何对自身**投射阴影**和**散射光线**。而对于`Diffuse`物体来说，应用`PRT`技术是简单的。

对于光照 $L_p(s)$（整个半球域的光照），我们直接进行**SH投影**，得到 $n^2$ 个**SH参数** $(L_p)_i$ 。然后对应的，我们对**传输项**进行SH投影，也得到 $n^2$ 个SH参数 $(M_p)_i$ 。

> 正如下文所示，随着考虑的要素变多，**传输项**变得复杂


**SH基的正交性**提供了一个有用的性质：即给定任意两个球上的函数 $a$ 和 $b$ ，它们的投影满足 $\int{a(s)b(s)ds} = \sum_{i=1}^{n^2}{a_ib_i}$。换句话说，对**带限函数的乘积**进行**积分**，可将其简化为**投影系数的点积和**。所以：
$$
L_o=\frac{\rho}{\pi}\int{(L_{p}(s)\cdot M_{p}(s))}ds=\frac{\rho}{\pi}\sum_{i=1}^{n^2}(M_p)_i(L_p)_i
$$

> **怎么求SH参数**？这里简单提个醒：
> $$
> f_l^m=\int{f(s)y_l^m(s)ds}=\sum_{i=1}^{i=n}f(s_i)y_l^m(s_i)\Delta s_i
> $$

知道`high level`的想法后，现在留下的问题就是：**传输项是什么**？通过考虑**阴影、自反射**等因素，我们会有如下三个可选的传输项。
![在这里插入图片描述](https://img-blog.csdnimg.cn/8e495740ad8d468880d9a8756110ba4c.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)


### 2.1 unshadowed diffuse transfer
这是最简单的传输方程，我们不要考虑**阴影**和**自反射**。我们假设 $p$ 处的法线为 $N_p$，那么**传输项**实际就是**钳制的余弦项**：
$$
M_{N_p}(s)=\max{(N_p \cdot s, 0)}
$$
下面是作业中的代码：

```cpp
for (int i = 0; i < mesh->getVertexCount(); i++)
{
    const Point3f &v = mesh->getVertexPositions().col(i);
    const Normal3f &n = mesh->getVertexNormals().col(i);
    auto shFunc = [&](double phi, double theta) -> double {
        Eigen::Array3d d = sh::ToVector(phi, theta);
        const auto wi = Vector3f(d.x(), d.y(), d.z());
        double cos_ = wi.dot(n);
        //double cos_ = 0.0;
                       
        return max(cos_, 0);
        
    };
    // SHOrder : 使用的SH阶数
    // shFunc : 要投影的函数，这里是转移函数
    // m_SampleCount : 采样点数
    auto shCoeff = sh::ProjectFunction(SHOrder, shFunc, m_SampleCount);
    for (int j = 0; j < shCoeff->size(); j++)
    {
        m_TransportSHCoeffs.col(i).coeffRef(j) = (*shCoeff)[j];
    }
}
```

### 2.2 shadowed diffuse transfer
这里我们就要考虑阴影了，其实就是在余弦项的基础上加上**可见性** $V$。也就是说，传输项变成了：
$$
M_{N_p+Shadow}(s)=\max{(N_p \cdot s, 0)} *V_p(s)
$$
**可见项怎么计算**？实际上，一个很简单的思路就是：在当前渲染点的**法线半球**，进行采样得到**方向 $s$** 的同时，沿着这个方向 $s$，进行击中判定。如果击中了，则 $V=0$；否则 $V=1$。

下面是作业中的代码：

```cpp
for (int i = 0; i < mesh->getVertexCount(); i++)
{
    const Point3f &v = mesh->getVertexPositions().col(i);
    const Normal3f &n = mesh->getVertexNormals().col(i);
    auto shFunc = [&](double phi, double theta) -> double {
        Eigen::Array3d d = sh::ToVector(phi, theta);
        const auto wi = Vector3f(d.x(), d.y(), d.z());
        double cos_ = wi.dot(n);
        //double cos_ = 0.0;
                       
        Ray3f r(v, wi);
        return max(cos_, 0) * (1.0 - scene->rayIntersect(r));
        
    };
    // SHOrder : 使用的SH阶数
    // shFunc : 要投影的函数，这里是转移函数
    // m_SampleCount : 采样点数
    auto shCoeff = sh::ProjectFunction(SHOrder, shFunc, m_SampleCount);
    for (int j = 0; j < shCoeff->size(); j++)
    {
        m_TransportSHCoeffs.col(i).coeffRef(j) = (*shCoeff)[j];
    }
}
```

### 2.3 interreflected diffuse transfer
这里进一步考虑了**自反射**，在考虑**传输项**之前，我们还需要重写**光照方程**：
$$
L_o=\frac{\rho_p}{\pi}\int{(L_{p}(s)\cdot M_{N_p+Shadow}(s))}ds
\\
L_o^1=L_o+\frac{\rho_p}{\pi}\int{\overline{L_p^0}(s)M_{N_p}(1-V_p(s))ds}
\\
L_o^2=L_o^1+\frac{\rho_p}{\pi}\int{\overline{L_p^1}(s)M_{N_p}(1-V_p(s))ds}
\\
\cdots
$$
实际上，上诉过程就是物体本身**多次互`bounce`的过程**，我们迭代计算多少次，就相当于`bounce`越多。其中，$\overline{L}_p(s)$是来自物体 $O$ 自身的、方向 $s$ 的辐射度（`radiance`）。**困难在于**，除非入射光来自**无限远的光源**，否则我们实际上不知道 $\overline{L}_p(s)$。

但真的困难吗？$L_o$可以直接计算（虽然这里说是直接，但请注意，我们通篇都是讲的`GI`，算的是**间接光照**），而自反射导致的**迭代依赖积分**似乎很复杂？我们如果把这个过程拆成多个`Pass`，迭代计算自反射不就成了，反正我们不需要过多考虑性能——这些都是离线计算的。==但我们必须注意到一个问题==：不管是**公式上直接看**，还是**理论理解**，我们在计算传输方程的时候，都需要考虑 **BRDF**了（对于`diffuse`，也就是 $\frac{\rho}{\pi}$）！

> 其实之前的计算也可以考虑 $\frac{\rho}{\pi}$，反正是个常数。但考虑自反射，情况就发生了变化，因为我们的**转移函数**需要考虑**来自物体其他点的辐射度**了！此时，==考虑 $\frac{\rho}{\pi}$ 是必不可少的==！
> 
$$
M_{N_p}(s)=\frac{\rho_p}{\pi}\max{(N_p \cdot s, 0)}
\\
\\ -------------------
\\
M_{N_p+Shadow}(s)=\frac{\rho_p}{\pi}\max{(N_p \cdot s, 0)} *V_p(s)
$$
以上就是自反射情况下，对之前两个传输方程的修正。那么，让我们正式开始描述把！

 - `Pass 1`。按照`shadowed diffuse transfer`描述的那样，计算得到模型上**每一个点的传输参数**——$(M_p)_i^0$ 。
 - `Pass 2`。也是和`Pass 1`一样，遍历模型的每一个顶点。以 $p$ 点为例，在其**法线半球域**，进行采样。对于采样得到的方向 $s_d$，我们只考虑和物体本身相交的，也就是说，**传输方程参数**的计算如下：
 $$
 (M_p)^1_i = \sum_{s_d}(1-V_p(s_d))\cdot (M_q)_i^0\cdot M_{N_p}(s_d)
 $$
 其中，$(M_p)^1_i$ 的下标代表**球谐参数的索引**（第几个SH参数），其上标代表**迭代次数**。$q$ 代表物体上和 $s_d$相交的点。上述方程比较好理解：$1-V_p(s_d)$ 是由于我们只考虑**和物体相交的方向**；$(M_q)_i^0$则是需要考虑 $q$ 点本身的光线传输情况。
 

> $(M_q)_i^0$ 实际上并不是 $q$ 的传输参数，或者说，$q$ 点身可能并不是模型的一个顶点，而是相交的三角形图元上的一个点。所以$(M_q)_i^0$ 实际上是这个相交图元的**三个顶点的传输参数的插值**。`Games202`里面是说的是**重心坐标插值**。

 
 - `Pass 3`，就是迭代，直接贴公式了：
 $$
 (M_p)^2_i = \sum_{s_d}\frac{\rho_p}{\pi}\cdot (1-V_p(s_d))\cdot (M_q)_i^1\cdot M_{N_p}(s_d)
 $$
 - 可能继续的`Pass4`、`Pass 5`。只要你不嫌麻烦。
 - `Pass final`，组合直接传输和多次传输（再说一遍：我们通篇都是讲的`GI`，算的是**间接光照**）：
 $$
 	(M_p)_i=(M_p)_i^0+(M_p)_i^1+(M_p)_i^2+\cdots+(M_p)_i^n
 $$

这里就暂时不贴代码了，嘛哈哈哈，当时太菜了，写错了。

### 2.4 实时计算
这个就很简单了，以三阶SH投影为例：

 - `light`。对于光照的投影（例如：来自环境贴图），我们得到 $9_R+9_G+9_B=27$ 个SH参数，然后实际上可以以`uniform mat3`传入**顶点着色器**。由于是`27`个参数，我们应该传入 $Mat_R,Mat_G,Mat_B$ 三个`mat3`矩阵。
 - `Transform`。对于转移函数的投影，则是有 $Number_{顶点数} * 9$ 个SH参数。所以我们应该把这个**转移SH参数**，设置成顶点数据结构体的成员，类似于顶点法线、顶点位置等。只不过，这个成员是`mat3`类型。


### 2.5 旋转光源
如果我们想要**旋转光源**，那就破坏了**预计算系方法**的静态光源要求，除非我们重新预计算**旋转后光源的分布情况**。但更好的方法还是在**SH系数**上花功夫。本节介绍这个方法，它主要利用了球谐函数的**两个性质**：

 - 球谐函数具有**旋转不变性**，通俗的讲就是：假设有一个旋转 $R$，对原函数 $f(x)$ 的旋转 $R(f(x))$ 与直接旋转$f(x)$ 的自变量是一样的，即 $R_1(f(x))=f(R_2(x))$。


 
 - 对每层` band `上的` SH coefficient`，可以分别在上面进行旋转，并且这个旋转是**线性变化的**。 也就是说，SH系数可以看成是向量，并且可以拆分。

:star: 我们对环境贴图（举个例）进行**SH投影**，得到`9`个SH系数，可以把这个看出一个$vec9$向量，旋转环境贴图实际上就是旋转这个`vec9`向量：
$$
Light\_SH\_vec9=[L_{0,0},\cdots,L_{2,2}]=[\sum{L_{n_p}\cdot Y_{0,0}(n_p)\cdot \Delta{Area}},\cdots,\sum{L_{n_p}\cdot Y_{2,2}(n_p)\cdot \Delta{Area}}]
\\-----------------------
\\
R(Light\_SH\_vec9)=R( [L_{0,0},\cdots,L_{2,2}])=R(\sum{L_{n_p}\cdot \Delta{Area}}\cdot [Y_{0,0}(n_p),\cdots, Y_{2,2}(n_p)])
\\
=\sum{L_{R^-(n_p)}\cdot \Delta{Area}} \cdot R([Y_{0,0}(n_p),\cdots, Y_{2,2}(n_p)])
$$
通过如上公式推导，我们可以知道：$R(Light\_SH\_vec9)$的求解可以看作 $R([Y_{0,0}(n_p),\cdots, Y_{2,2}(n_p)])$的求解（至于$R^+(L_{n_p})=L_{R^-(n_p)}$，就是换个**采样的反射度值**，是一个未知且无关的变换）。而$R(\cdot)$实际上就是一个$mat9$矩阵（拿来旋转 $vec9$ 啊！）。此外，$[Y_{0,0}(n_p),\cdots, Y_{2,2}(n_p)]$ 实际上就是法线$n_p$的SH投影，或者说 $P(n_p)=[Y_{0,0}(n_p),\cdots, Y_{2,2}(n_p)]$。最终，我们需要考虑的就是$R(P(n_p))$的求解!
$$
R_1(P(n_p))=P(R_2(n_p))
$$

:one:首先，以**三阶SH**为例，来确定符号。根据上面的分析，**投影函数**$P(n_i)$ 是一个**类球谐函数**（**多个球谐函数组成的向量**，从下面的代码也可以看出来），返回SH系数向量，返回类型暂定为 $vec9$。它的伪代码大致如下：

```cpp
/*float getSH(int l, int m)
{
	float sh;
	for(int i = 0; i < width; ++i)
	{
		for(int j = 0; j < height; ++j)
		{
			vec3 n =GetNormal(i, j)
			sh += envMap(i, j) * Y(l, m, n) * getArea(i, j);
		}
	}
	return sh;
}*/

vec9 P(vec3 n)
{	
	vec9 sh;
	for(int l = 0; l < 3; ++l)
	{
		for(int m = -l; m <= l; ++m )
		{
			sh[getID(l, m)] = Y(l, m, n);
		}
	} 
}
```
所以 $P(n_i)$具备旋转不变性，所以有如下关系：
$$
M_{mat9} \cdot P(n_i) = P(R(n_i))
$$
我们知道$P(n_i)$ 以及 $P(R(n_i))$的值（后者就是对法线进行旋转），似乎不好求解得到$M_{mat9}$。但如果我们采样`9`个法线，并把他们组合成矩阵 $A=[P(n_0),P(n_1),\cdots,P(n_9)]$，根据数字知识，此时满足：
$$
M_{mat9} \cdot A = [P(R(n_0)),P(R(n_1)),\cdots, P(R(n_9))]
$$
这个时候就好办了，`A`是矩阵，我们就可以利用**矩阵的逆**，来进行操作了：
$$
M_{mat9}= [P(R(n_0)),P(R(n_1)),\cdots, P(R(n_9))]\cdot A^{-1}
$$

:two:接下来可以讨论具体算法的实现了：

 1. 首先，选取9个法线 $[n_0,n_1,\cdots,n_9]$，对其中的法线$n_i$，在球谐上投影，得到$P(n_i)$。9`个 $vec9$ 向量$P(n_i)$构成了我们需要的矩阵 $A$，并求出 $A^{−1}$。
 2.  其次，给定旋转$R$，对所有 $n_i$ 依次做旋转 $R(n_i)$、SH投影取系数$P(R(n_i))$。 此时我们应该得到`9`个 $vec9$ 向量 $P(R(n_i))$，这些向量构成了我们需要的矩阵$S$。
 3. 接着，求出所需的矩阵 $M = SA^{−1}$，用 $M$ 乘以`Light SH coefficient vector `就可以得到**旋转后的SH系数**了。

:three:`Games202`里面给出了优化思路：`mat9`太大了，且计算耗时，而且0阶那个系数根本不需要考虑旋转。在此基础上，我们可以把剩余的`8`个系数，按照所属阶拆成两部分：1阶的`vec3`，2阶的`vec5`。具体流程和上面的类似，可以看看如下截图：

![在这里插入图片描述](https://img-blog.csdnimg.cn/b6ae28b49bbd4014879e4da2450d79d1.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)

:four:不管实现方法如何，我们最终可以发现，这个用来旋转**光源SH Vector**的函数（一个，或多个矩阵），实际上是独立于环境光的。也就是说，我们完全可以预计算**几个常用的旋转角度**，通过上诉方法求出**旋转矩阵**，然后实际运行的时候就可以直接用了。其次，这个旋转算法不是是适用于这个`PRT`，它依赖的仅仅是球谐函数的特性，所以其他使用SH基进行压缩的`GI`算法，也可以使用这个方法来旋转光源。





## 3. Specular Transfer

对于`Specular`物体来说，应用`PRT`技术则有点复杂。我目前也没有完全弄明白，这里先给出我们需要提前知道的设定：

 - **BRDF方程**不依赖法线，而依赖于**反射向量**$R$：$f_r=G(s,R,r)=BRDF(s,R,roughness)$。
 - BRDF不是各向异性的，所以它的`lob`是以$R$为轴，圆对称的。

### 3.1 shadowed specular transfer
我们首先给出渲染方程：
$$
L_{GS}(L_p,R,r)=\int{L_p(s)G(s,R,r)V_p(s)ds}
$$
如果依然按照之前的思路，会遇到困难：$G$不仅是**入射光方向**$s$的函数，不能被简化成**SH系数向量**。

作者的思路是：

 1. 首先，去除$R$的影响，让：$G_r^*(z)=G(s,(0,0,1),r)$
 2. 然后，将**积分**看作是：$G_r^*$和光照进行卷积，然后投影到SH基上，最后代入实际的$R$，来获得$L_{GS}(L_p,R,r)$。
 3. 重建公式：$L_{GS}=\sum{\alpha_l^0 \cdot G_l^0 \cdot L^m_l \cdot Y_l^m(R)}$

> **SH Convolution**一个**圆对称核函数** $h(z)$，与函数 $f$ 的卷积表示为：$h*f$。==卷积的投影满足==：
> $$
> (h*f)^m_l=\sqrt{\frac{4\pi}{2l+1}}h^0_lf^m_l=a^0_l \cdot h^0_l \cdot f^m_l
> $$



:one:综上所诉，我们首先可以把 $G(s,(0,0,1),r)$ 投影到SH基上。方法如下：
$$
G_l^m=\int{G(s,(0,0,1),r)y_l^m(s)\mathrm{d}s}
$$

:two:




ToDo



