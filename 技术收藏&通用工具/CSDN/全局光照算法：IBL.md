## 1. 介绍

**基于图像的光照**（`Image based lighting`, IBL）是一类光照技术的集合。其光源不是**可分解的直接光源**，而是将**周围环境**整体视为一个大光源。现代渲染引擎中使用的IBL有四种常见类型:

 - **远程光探头**，用于捕捉"无限远"处的光照信息，可以忽略视差。远程探头通常包括天空， 远处的景观特征或建筑物等。它们可以由渲染引擎捕捉, 也可以**高动态范围图像的形式**从相机获得.
 - **局部光探头**，用于从特定角度捕捉世界的某个区域。捕捉会投影到**立方体或球体**上, 具体取决于周围的几何体。局部探头比远程探头更精确，**在为材质添加局部反射时特别有用**.
 - **平面反射**，用于通过渲染**镜像场景**来捕捉反射。**此技术只适用于平面**，如建筑地板，道路和水。
 - **屏幕空间反射**，基于在深度缓冲区使用光线行进方法渲染的场景，来捕捉反射。SSR效果很好，但可能非常昂贵。


`IBL` 通常使用（取自现实世界或从3D场景生成的）**环境立方体贴图** (`Cubemap`) ，我们可以将**立方体贴图的每个像素**视为光源，在渲染方程中直接使用它。这种方式可以有效地捕捉**环境的全局光照**，使物体更好地融入环境。

> **全景图**也有其它形式的记录方法，例如` Spherical Map`（我们常见的 `HDRI Map `多用 `Spherical Map` 表示），其对于**地平线的分辨率要高于正上方的天空**，比较适合**室外这种天空啥都没有的环境**。
> ![在这里插入图片描述](https://img-blog.csdnimg.cn/6e66999ca2af4719801f93dcc04e3064.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)

理论上，物体的每一个细分的表面都应该对应着自己**独有的一个半球体光照环境**，而不是整个物体共享一个 `Cubemap`，但是这样的话对于每个细分表面都算` Cubemap`，**性能开销**还不如**光线追踪**——所以使用此技术的**一个前提**是：**周围的物体足够远**。


### 1.1 积分方程的分解
先快速回顾一下**基于Cook-Torrance BRDF的反射积分方程**：
$$
	L_o(p,w_o)=\int_{\Omega}{k_d\frac{c}{\pi}+k_s\frac{DFG}{4(w_0\cdot n)(w_i\cdot n)}L_i(p,w_i)n\cdot w_i}dw_i
$$

> 以上公式应该都是很熟了，每个符号就无需解释了

**来自周围环境的入射光**都可能具有**一些辐射度**，使得解决积分变得不那么简单。这为解决积分提出了两个要求：

 - 给定任何方向向量 $w_i$ ，我们需要一些方法来获取这个方向上**场景的辐射度**。
 - 求解积分需要**快速且实时**

但实际上，**第一点和第二点似乎是冲突的**——因为如果真的在渲染时，考虑**每个方向的辐射度**，那就很难做到**快速实时**。为了以**更有效的方式**解决积分，我们需要对其大部分结果进行**预计算**。仔细研究反射方程，我们发现` BRDF` 的漫反射 $k_d$ 和镜面 $k_s$ 项是**相互独立的**——可以将积分分成两部分：
$$
	L_o(p,w_o)=\int_{\Omega}{k_d\frac{c}{\pi}L_i(p,w_i)n\cdot w_i}dw_i+\int_{\Omega}{k_s\frac{DFG}{4(w_0\cdot n)(w_i\cdot n)}L_i(p,w_i)n\cdot w_i}dw_i
$$

这样，就可以分开研究**漫反射**和**镜面反射**。


## 2. Diffuse IBL 
仔细观察**漫反射积分**，我们发现**漫反射兰伯特项**是一个**常数项**，不依赖于**任何积分变量**。基于此，我们可以将**常数项**移出**漫反射积分**：
$$
L_o(p,w_o)=k_d\frac{c}{\pi}\int_{\Omega}{L_i(p,w_i)n\cdot w_i}dw_i
$$

> 因为有上面的“**周围物体足够远**”的假设，这里`p`也和**积分变量**没什么关系了。但如果是**室内场景**，可以通过在场景中放置**多个反射探针**，来解决此问题——每个反射探针单独预计算其**周围环境的辐照度图**。这样，位置 `p` 处的辐照度（以及辐射度）是：最近的几个反射探针之间的辐照度插值。

这时候积分只和入射方向有关 了，而` Cubemap `本身就可以记录整个球面的入射角度，所以 `Cubemap `在这里很好的派上了用场。**为了避免运行时做“积分”，我们可以在运行前预处理这张` Cubemap`**。
![在这里插入图片描述](https://img-blog.csdnimg.cn/c464c3bd985048eaad18d95b99c41ad0.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_15,color_FFFFFF,t_70,g_se,x_16)


这个**预计算的立方体贴图**，在每个采样方向 $w_o$ 上存储其**积分结果**，可以理解为：场景中所有能够击中**面向 $w_o$ 的表面**的间接漫反射光的预计算总和。这样的立方体贴图被称为**辐照度图** `Irradiance Map`。

>  `Irradiance Map`：使用**表面法线**`n`作为**索引**，存储的是**辐照度值** `irradiance `，要求的分辨率极低。可以使用**预过滤的高光环境贴图的最低等级Mip**来存储。
>  `Irradiance Map`直接和光照挂钩，所以这张图存的时候一定要存**线性空间**，并且支持分量大于`1`的像素值。` .hdr` 或者 `.exr` 格式的图像（radiance HDR）就可以做到这点。


### 2.1 立方体贴图的卷积
如果只是使用上诉的`cubeMap`，那我们为了得到尽量正确的积分结果，还是要对半球的各个方向进行采样。为了避免这一点，我们需要对`cubemap`进行预过滤，让我们可以在实时运行时，通过一次采样，得到所需的辐照度。

既然**半球的朝向**决定了我们**捕捉辐照度的位置**，我们可以预先计算每个可能的半球朝向的辐照度，这些半球朝向涵盖了所有可能的出射方向 $w_o$。
![在这里插入图片描述](https://img-blog.csdnimg.cn/f0fee67baa2543d085a106cf2446b8c4.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)

真的对每一个可能方向去采样，理论上根本做不完，也没什么必要，所以这里肯定是用**一种离散积分的方法**，比如最简单的**黎曼积分**。为了避免对**难处理的立体角**求积分，我们使用**球坐标** $\theta$ 和 $\phi$ 来代替**立体角** $w$——这时候**积分方程**就变成了：

$$
L_o(p,ϕ_o,θ_o)=k_d\frac{c}{π}∫^{2π}_{ϕ=0}∫^{\frac{1}{2}π}_{θ=0}L_i(p,ϕ_i,θ_i)cos(θ)sin(θ)dϕdθ
$$

> 当我们离散地对**两个球坐标轴**进行采样时，每个采样近似代表了**半球上的一小块区域**，如上图所示。注意，由于球的一般性质，当**采样区域朝向中心顶部会聚时**，天顶角 θ 变高，**半球的离散采样区域变小**。为了平衡较小的区域贡献度，我们使用 sinθ 来权衡区域贡献度，这就是多出来的 sin 的作用。

将上诉公式转换为**黎曼和形式的离散版本**：
![在这里插入图片描述](https://img-blog.csdnimg.cn/3ff8a26cf16c4960854bf634b3be32de.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)

> 一般情况下，连续形式可按照如下方法，转换成离散形式：
> ![在这里插入图片描述](https://img-blog.csdnimg.cn/c0d6e1a31a1041888e95a0f4dc984715.png#pic_center)

所以，参考**离散版本**，实际代码如下（这里存取的是辐照度`E`，注意！）：

```cpp
vec3 irradiance = vec3(0.0);  
vec3 up    = vec3(0.0, 1.0, 0.0); 
vec3 right = normalize(cross(up, normal)); 
up         = normalize(cross(normal, right));
float sampleDelta = 0.025; 
float nrSamples = 0.0; 
for (float phi = 0.0; phi < 2.0 * PI; phi += sampleDelta) 
{    
	for(float theta = 0.0; theta < 0.5 * PI; theta += sampleDelta)    
	{        
		// spherical to cartesian (in tangent space)        
		vec3 tangentSample = vec3(sin(theta) * cos(phi),  sin(theta) * sin(phi), cos(theta));        
		// tangent space to world space (for cubemap to use)        
		vec3 sampleVec = tangentSample.x * right + tangentSample.y * up + tangentSample.z * N; 
	    irradiance += texture(environmentMap, sampleVec).rgb * cos(theta) * sin(theta);        
	    nrSamples++;    
    } 
} 
irradiance = PI * irradiance * (1.0 / float(nrSamples));
```

这段程序可以在运行**图形应用程序**之前就执行，然后存在硬盘上，程序执行直接读；也可以动态生成，然后存在显存上（和` Mipmap` 的生成差不多）。 
### 2.2 应用

实际使用很简单：

```cpp
vec3 kS = fresnelSchlickRoughness(max(dot(N, V), 0.0), F0, roughness); 
vec3 kD = 1.0 - kS;
vec3 irradiance = texture(irradianceMap, N).rgb;
vec3 diffuse    = irradiance * albedo;
// 间接光照的漫反射部分
vec3 ambient    = (kD * diffuse) * ao; 
```
为什么上诉代码中，是乘以`albedo`，而不是$albedo/\pi$，原因见上诉：**离散版本的推导**。

### 2.3 关于菲涅尔项
由于环境光来自**半球内围绕法线 `N` 的所有方向**，因此没有一个确定的半向量，来计算**菲涅耳效应**。

为了模拟**菲涅耳效应**，我们用**法线和视线之间的夹角**计算菲涅耳系数。然而，之前我们是以**受粗糙度影响的微表面半向量**作为菲涅耳公式的输入，但**我们目前没有考虑任何粗糙度，表面的反射率总是会相对较高**。间接光和直射光遵循相同的属性，因此我们期望**较粗糙的表面在边缘反射较弱**。由于我们没有考虑表面的粗糙度，**间接菲涅耳反射在粗糙非金属表面上看起来有点过强**。

可以通过在 Sébastien Lagarde 提出的 **Fresnel-Schlick 方程**中加入**粗糙度项**来缓解这个问题：

```cpp
vec3 fresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness)
{
    return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(1.0 - cosTheta, 5.0);
}   
```
 
 此时的结果如下：
 

> 自己也写过，照着learnOpenGL这个教程，但是找不到了，就直接照搬吧。

![在这里插入图片描述](https://img-blog.csdnimg.cn/419f97afec1c46da80e906f895694a33.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)

### 2.4 后续研究

考虑到运行时性能和效果，还可以做几点增强：

 - 用 `Irradiance Map `算出 `SH`，提升性能。全局可以使用一个` SH` 模拟**天光照明**（例如` UE4 `中的 `SkyLight`），也可以组建成网格，实现**动态物体的 GI**（`Unity `中的 `Light Probe Group`，`UE` 中的 `ILC`）。[An Efficient Representation for Irradiance Environment Maps ](https://www.csie.ntu.edu.tw/~cyy/courses/rendering/06fall/lectures/handouts/lec13_SH.pdf)
 - 使用 `Hammersley` 随机采样（球面上的均匀采样）实现 `Importance Sampling`，**提升离线资产处理的性能**。[Hammersley Points on the Hemisphere](http://holger.dammertz.org/stuff/notes_HammersleyOnHemisphere.html)

 ### 2.5 Irradiance Environment Maps
 #### Irradiance Map 和 Light Map
 当初第一次看RTR4时，看到十一章的第五节——`Diffuse Global Illumination`时，就特别疑惑，搞不清楚`light map`和后文诸如**H基技术**的区别。特别是**关于法线的描述**。
 
 这里给出一个不知道对不对的理解：
 

 - `light map` : 对于每一个物体的表面，以**较低的分辨率**预计算它的每个像素的光照情况，然后存储在纹理中。这个时候如果把墙旋转一个角度，那么如下所示的两张图都失效了。所以，`light map`更多用于
 	![在这里插入图片描述](https://img-blog.csdnimg.cn/af747f9579864239a41c68466758e6e2.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)

 - `Irradiance Map`：则是只预计算周围环境的光照情况。

 
#### SH基础
==球谐函数==在球域$S$上定义了一个**正交基**。使用如下参数化：:arrow_down:
$$
s=(x,y,z)=(\sin{\theta}\cos(\phi),\sin{\theta}\cos{\phi},\cos{\phi})
$$
基函数定义为：:arrow_down:
$$
Y_l^m(\theta,\phi)=K_l^me^{im\phi}P_l^{|m|}(\cos{\theta}),l\in N，-l\leq m\leq l
$$
![在这里插入图片描述](https://img-blog.csdnimg.cn/c0a7675a3b8e425eb68ffe7969e3633a.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)

其中，$P_l^m$是相关的**勒让德多项式**，$K_l^m$是**归一化常数**：:arrow_down:
$$
K_l^m=\sqrt{\frac{(2l+1)}{4\pi}\frac{(l-|m|)!}{(l+|m|)!}}
$$
上述定义形成了一个<u>复基</u>`complex basis`，实值基是由简单的变换给出的：:arrow_down:

![在这里插入图片描述](https://img-blog.csdnimg.cn/f931922dc61d4f1dbe322cf329a64945.png)
![在这里插入图片描述](https://img-blog.csdnimg.cn/dacecb3504494e05a3a9cf33361f9b49.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)

**$l$的低值**（称为<u>频带指数</u>`band index`）表示**球上的低频基函数**，频带$l$的基函数在$x,y,z$上化为$l$阶多项式。可以用**简单的递推公式**进行计算。因为**SH基**是正交的，所以**定义在S上的标量函数**$f$可以通过如下积分:arrow_down:，**投影**`Projection`得到系数：:arrow_down:
$$
f_l^m=\int{f(s)y_l^m(s)\mathrm{d}s}
$$
这些系数提供了n阶**重建**`Reconstruction`函数：:arrow_down:
$$
\overline{f}(s)=\sum_{l=0}^{n-1}\sum_{m=-l}^{l}{f_l^my_l^m(s)}
$$
**Properties**： SH投影的一个重要性质是它的旋转不变性，例如：给定$g(s)=f(Q(s))$，$Q$是S上的一个任意的旋转函数，则：:arrow_down:（这类似于一维傅里叶变换的位移不变性）
$$
\overline{g}(s)=\overline{f}(Q(s))
$$
这个不变性意味着，当在一组旋转的样本处采样f时，SH投影不会产生任何锯齿。

**SH基的正交性**提供了一个**有用的性质**，即给定任意两个球上的函数$a$和$b$，它们的投影满足：:star:

![在这里插入图片描述](https://img-blog.csdnimg.cn/0f6d27b4935a4335a465ab18ed3e5ab9.png)


换句话说，==对带限函数的乘积进行积分，可将其简化为投影系数的点积和==。

#### 使用SH进行投影
如果我们使用`3`个频带的`SH`系数，也就是说，我们只需要计算得到`9`个$L_{lm}$，而不是对每个像素进行积分。这些系数的计算方法如下：
$$
	L_{lm}=\int_{\theta=0}^{\pi}\int_{\phi=0}^{2\pi}L(\theta,\phi)Y_{lm}(\theta,\phi)sin\theta d\theta d\phi
$$

它的离散形式如下：
$$
	L_{lm}=\frac{\pi}{N1}\cdot \frac{2\pi}{N2}\sum_{pixels(\theta,\phi)}{envmap[pixel] \cdot Y_{lm}(\theta,\phi)}
$$
实际上，更加精确的公式，应该是实际考虑每个`cubemap`上的像素**所代表的矩形区域**投影到单位球面的面积：
$$
	L_{lm}=\sum_{pixels(\theta,\phi)}{envmap[pixel] \cdot Y_{lm}(\theta,\phi)\Delta{w_i}}
$$

最终我们得到`9`个SH系数（`27`个float）。

> 这里可以简单讲下为什么我们只需要**这么点数据（27个float）**就可以记录**光照情况**：最大的原因就是我们的假设——**光照环境无限远**，每个着色点 $P_i$ 对于光照贴图来说，都是一样的，这个时候，$L(p,\theta,\phi)$ 就变成了 $L(\theta,\phi)$，所以我们只需要在这个`cube map`（或者探针）的中心 $P_0$，算一次投影结果，就可以推广到**其他着色点**。








 

#### 重建
我们重建的光照度量是辐照度`E`，而对于`E`和`L`的SH系数有如下关系：
$$
	E_{lm}=A_lL_{lm}
$$
公式中的$A_{l}$的定义如下：
![在这里插入图片描述](https://img-blog.csdnimg.cn/faacaa1345394cf9aeb73bd903c93cb5.png)

> 这个 $A_l$ 的物理意义是什么？考虑**diffuse项**的计算，光照积分里面是 $L\cdot cos$，我们上面计算的只是 $L$，而没有**余弦项**。所以 $A_l$ 应该是这个**余弦项的SH系数** （根据**SH基的正交性**可以推断出）。目前还有一个问题是，我们是要投影 $\int (n\cdot w) dw$，而这个积分哪怕基于**环境光无限远的假设**，除了$(\theta,\phi)$，我们还要考虑 $n$，这意味着我们需要$width * height * {NUM_{SH}}$个系数（其实就是三张纹理），这根本不节省带宽。考虑**球谐函数的旋转不变性**（**法线的各不相同，本质就是旋转**），我们可以对其进行简化，最终得到 $A_l$。具体推导可以见[论文复现：A Non-Photorealistic Lighting Model For Automatic Technical Illustration](https://zhuanlan.zhihu.com/p/357295394)

所以**重建公式**变成了：
$$
E(\theta,\phi)=\sum_{l,m}{A_l}L_{lm}Y_{lm}(\theta,\phi)
$$
对于实际渲染，我们可以使用下列公式来计算`E`：
![在这里插入图片描述](https://img-blog.csdnimg.cn/449c2c7cd7d34013aa29639e807b7a3a.png)
![在这里插入图片描述](https://img-blog.csdnimg.cn/b95447a034184bf48e11e127dba8e041.png)

由于我们只考虑$l\leq2$，辐照度就是一个（归一化）**表面法线坐标的二次多项式**。因此，对于$n^t=(x,y,z,1)$，我们可以有：
$$
E(n)=n^tMn
$$
M是一个**对称的4x4矩阵**。下面的方程对渲染特别有用，因为我们只需要**一个矩阵-向量乘法**和**一个点乘法**来计算`E`：
![在这里插入图片描述](https://img-blog.csdnimg.cn/00f4a4269786429e95ad88275fa1047b.png)
#### 总结
我们在`Diffuse IBL`的假设以及思想上，结合**球谐函数**，将**环境贴图的低频光照信息**投影到`SH基`上，这样就可以极大节省带宽，因为我们不需要存储一张**预过滤图**了，而是存储**几十个vector**就行了（以$l=2$为例，我们只需要存储9个`SH vector`系数即可）

实时运行过程中，只需要以**法线**为索引，就可以快速重建辐照度`E`，下面是**UE4的源码**：
```cpp
// filament根据预缩放的SH重建辐照度的GLSL代码
vec3 irradianceSH(vec3 n) {
    // uniform vec3 sphericalHarmonics[9]
    // 我们只使用前两个波段以获得更好的性能
    return
    //另外, 由于使用 Kml 进行了预缩放, SH系数可视为颜色, 
    //特别地sphericalHarmonics[0]直接就是平均辐照度.
          sphericalHarmonics[0]
        + sphericalHarmonics[1] * (n.y)
        + sphericalHarmonics[2] * (n.z)
        + sphericalHarmonics[3] * (n.x)
        + sphericalHarmonics[4] * (n.y * n.x)
        + sphericalHarmonics[5] * (n.y * n.z)
        + sphericalHarmonics[6] * (3.0 * n.z * n.z - 1.0)
        + sphericalHarmonics[7] * (n.z * n.x)
        + sphericalHarmonics[8] * (n.x * n.x - n.y * n.y);
}
```

![在这里插入图片描述](https://img-blog.csdnimg.cn/1e06dd878e7949e38637ff277dbceff1.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)


 ## 3. Specular IBL 
 将重点关注**反射方程的镜面部分**：
 $$
 	L_o(p,w_o)=\int_{\Omega}{k_s\frac{DFG}{4(w_0\cdot n)(w_i\cdot n)}L_i(p,w_i)n\cdot w_i}dw_i
 $$
 很明显，镜面部分要复杂的多，不仅受**入射光方向**影响，还受**视角**影响。如果试图解算**所有入射光方向**加**所有可能的视角方向**的积分，二者组合数会极其庞大，**实时计算太昂贵**。
 
进行预计算？但是这里的积分依赖于$w_i$和$w_o$，我们无法用**两个方向向量**采样**预计算的立方体图**。`Epic Games `提出了一个解决方案，他们预计算**镜面部分的卷积**，为实时计算作了一些妥协，这种方案被称为**分割求和近似法**（`split sum approximation`）——将**预计算**分成**两个单独的部分**求解，再将两部分组合起来，得到预计算结果。**分割求和近似法**将**镜面反射积分**拆成两个独立的积分：
$$
L_o(p_,w_o)=\int_{\Omega}{L_i(p,w_i)dw_i}*\int_{\Omega}f_r(p,w_i,w_o)n\cdot w_idw_i
$$


### 3.1 第一部分：光照部分
$$
L_o(p_,w_o)=\int_{\Omega_{f_r}}{L_i(p,w_i)dw_i}
$$

卷积的第一部分被称为**预滤波环境贴图**，它类似于辐照度图，是预先计算的**环境卷积贴图**，但这次考虑了**粗糙度**。这部分看起来和上面 `Diffuse IBL `非常接近，唯一不一样的是：它的**积分域**从整个半球，变为了`BRDF `的覆盖范围，也就是` Specular Lobe / BRDF Lobe`。于是**积分域**就和 Lobe “撑起来的**胖瘦程度**”有关了。而`Lobe `和` BRDF `项的 `Roughness `有直接关系——越粗糙，高光越分散（极端情况就是`diffuse`了）。` Roughness` 是变量，因此需要得到一系列不同` Roughness` 所对应的` Cubemap`。
![在这里插入图片描述](https://img-blog.csdnimg.cn/080e3b0487734989981a01953621b50c.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)
 

> `diffuse IBL`中对粗糙度的考虑是**菲涅尔项**，但在求解积分的时候，并没有考虑，和这里是不同的。

这里轮到` Mipmapping `来救场了：用不同的 `mipmaps `离散的表示不同的 `Roughness`，借助着 `Trilinear Filtering` **三线性纹理过滤**，来插值得到真正 `Roughness `所对应的光照强度。在实时渲染中，可以预处理**原始环境贴图**，得到的` Mipmap` 过的环境贴图被称为`Pre-filtered Environment Map`（**预处理环境贴图**），如下图所示（来自 `LearnOpenGL`）：
![在这里插入图片描述](https://img-blog.csdnimg.cn/f943ce69af0849bbb6dd3c2636495b45.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)
虽然积分中没有$w_o$（视线向量）的身影，但采样的**球面积分域**和出射角有关，我们还没有考虑——一个`lobe`除了**胖瘦程度**，还有**朝向**！但正如之前所说，我们已经和`Diffuse IBL`一样有了法线`N`作为索引，来采样这个**预滤波环境贴图**，不能在考虑第二个向量了，因此` Epic Games `假设**视角方向**`V`——也就是**镜面反射方向**`R`——总是等于**输出采样方向**`N`，以作进一步近似。翻译成代码如下：

```cpp
vec3 N = normalize(w_o);
vec3 R = N;
vec3 V = R;
```

> 显然，这种近似会导致：在视线几乎垂直于法线的**掠射方向**上，会无法获得很好的掠射镜面反射

### 3.2 光照部分的实现
一些基础技术，这里直接给出实现，具体原理请百度。
#### 低差异序列：Hammersley 序列

```cpp
float RadicalInverse_VdC(uint bits) 
{
    bits = (bits << 16u) | (bits >> 16u);
    bits = ((bits & 0x55555555u) << 1u) | ((bits & 0xAAAAAAAAu) >> 1u);
    bits = ((bits & 0x33333333u) << 2u) | ((bits & 0xCCCCCCCCu) >> 2u);
    bits = ((bits & 0x0F0F0F0Fu) << 4u) | ((bits & 0xF0F0F0F0u) >> 4u);
    bits = ((bits & 0x00FF00FFu) << 8u) | ((bits & 0xFF00FF00u) >> 8u);
    return float(bits) * 2.3283064365386963e-10; // / 0x100000000
}
// ----------------------------------------------------------------------------
vec2 Hammersley(uint i, uint N)
{
    return vec2(float(i)/float(N), RadicalInverse_VdC(i));
}  
```
#### GGX重要性采样
有别于**均匀或纯随机**地（比如**蒙特卡洛**）在积分半球 Ω 产生**采样向量**，我们的采样会根据**粗糙度**，偏向**微表面的半向量的宏观反射方向**。采样过程将与我们之前看到的过程相似：

 1. 开始一个大循环，生成一个**随机（低差异）序列值**，用该序列值在**切线空间**中生成**样本向量**，
 2. 将**样本向量**变换到**世界空间**，并对**场景的辐射度**采样。

```cpp
const uint SAMPLE_COUNT = 4096u;
for(uint i = 0u; i < SAMPLE_COUNT; ++i)
{
    vec2 Xi = Hammersley(i, SAMPLE_COUNT);   
}
```

此外，要构建**采样向量**，我们需要一些方法**定向和偏移采样向量**，以使其朝向**特定粗糙度的镜面波瓣方向**。我们可以如理论教程中所述使用 `NDF`，并将` GGX NDF `结合到 Epic Games 所述的**球形采样向量的处理**中：

```cpp
vec3 ImportanceSampleGGX(vec2 Xi, vec3 N, float roughness)
{
    float a = roughness*roughness;

    float phi = 2.0 * PI * Xi.x;
    float cosTheta = sqrt((1.0 - Xi.y) / (1.0 + (a*a - 1.0) * Xi.y));
    float sinTheta = sqrt(1.0 - cosTheta*cosTheta);

    // from spherical coordinates to cartesian coordinates
    vec3 H;
    H.x = cos(phi) * sinTheta;
    H.y = sin(phi) * sinTheta;
    H.z = cosTheta;

    // from tangent-space vector to world-space sample vector
    vec3 up        = abs(N.z) < 0.999 ? vec3(0.0, 0.0, 1.0) : vec3(1.0, 0.0, 0.0);
    vec3 tangent   = normalize(cross(up, N));
    vec3 bitangent = cross(N, tangent);

    vec3 sampleVec = tangent * H.x + bitangent * H.y + N * H.z;
    return normalize(sampleVec);
}
```

#### 着色器

```cpp
#version 330 core
out vec4 FragColor;
in vec3 localPos;

uniform samplerCube environmentMap;
uniform float roughness;

const float PI = 3.14159265359;

float RadicalInverse_VdC(uint bits);
vec2 Hammersley(uint i, uint N);
vec3 ImportanceSampleGGX(vec2 Xi, vec3 N, float roughness);

void main()
{       
    vec3 N = normalize(localPos);    
    vec3 R = N;
    vec3 V = R;

    const uint SAMPLE_COUNT = 1024u;
    float totalWeight = 0.0;   
    vec3 prefilteredColor = vec3(0.0);     
    for(uint i = 0u; i < SAMPLE_COUNT; ++i)
    {
        vec2 Xi = Hammersley(i, SAMPLE_COUNT);
        vec3 H  = ImportanceSampleGGX(Xi, N, roughness);
        vec3 L  = normalize(2.0 * dot(V, H) * H - V);

        float NdotL = max(dot(N, L), 0.0);
        if(NdotL > 0.0)
        {
            prefilteredColor += texture(environmentMap, L).rgb * NdotL;
            totalWeight      += NdotL;
        }
    }
    prefilteredColor = prefilteredColor / totalWeight;

    FragColor = vec4(prefilteredColor, 1.0);
}  

```

> 当然，也可以使用`Diffuse IBL`中均匀采样的方法，但这样的效率太低。


### 3.3 第二部分：BRDF 部分 
#### 推导
$$
L_o(p_,w_o)=\int_{\Omega}f_r(p,w_i,w_o)n\cdot w_idw_i
$$
这个方程要求我们在$n\cdot ω_o$ 、**表面粗糙度**、**菲涅尔系数** $F_0$ 上计算**BRDF方程的卷积**。这等同于在**纯白的环境光**或者**辐射度恒定为1.0**的设置下，对**镜面BRDF**求积分。对`3`个变量做卷积有点复杂，不过我们可以把$F_0$移出**镜面BRDF方程**：
![在这里插入图片描述](https://img-blog.csdnimg.cn/dfc11a2161b64e4899c0b022cd4763a7.png)
`F `为**菲涅耳方程**。将**菲涅耳分母**移到 `BRDF` 下面可以得到如下等式：
![在这里插入图片描述](https://img-blog.csdnimg.cn/4369c2f296b743a1a704d58148e40a95.png)
用 `Fresnel-Schlick `**近似公式**替换**右边的`F`** 可以得到：
![在这里插入图片描述](https://img-blog.csdnimg.cn/80053e14770043058962048acbf0f21c.png)
让我们用$\alpha = (1-w_o\cdot h)^5$，以便更轻松地求解$F_0$：
![在这里插入图片描述](https://img-blog.csdnimg.cn/978d56c35c9747c4b4aad9dd4e963c5e.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_16,color_FFFFFF,t_70,g_se,x_16)
然后我们将**菲涅耳函数**` F`分拆到两个积分里：
![在这里插入图片描述](https://img-blog.csdnimg.cn/141876395f294f438f347dfd3e53426f.png)
接下来，我们将$\alpha$替换回其**原始形式**，从而得到**最终分割求和的BRDF方程**：
![在这里插入图片描述](https://img-blog.csdnimg.cn/3731e7ca5d6947daa70f1bc3505a5044.png)
**公式中的两个积分**分别表示$F_0$的**比例和偏差** 。注意，这里的$f_r$中不计算`F`项。积分式子里面留下来了**夹角（$n$ 和 $w_o$）和粗糙度**。我们将**卷积后的结果**存储在**2D查找纹理**（Look Up Texture, `LUT`）中，这张纹理被称为 **BRDF 积分贴图**。

#### 着色器
**BRDF卷积着色器**在**2D 平面**上执行计算，直接使用其**2D纹理坐标**作为**卷积输入**（`NdotV` 和 `roughness`）。代码与**预滤波器的卷积代码**大体相似，不同之处在于，它现在根据 `BRDF `的几何函数和 `Fresnel-Schlick `近似来处理采样向量：

```cpp
vec2 IntegrateBRDF(float NdotV, float roughness)
{
    vec3 V;
    V.x = sqrt(1.0 - NdotV*NdotV);
    V.y = 0.0;
    V.z = NdotV;

    float A = 0.0;
    float B = 0.0;

    vec3 N = vec3(0.0, 0.0, 1.0);

    const uint SAMPLE_COUNT = 1024u;
    for(uint i = 0u; i < SAMPLE_COUNT; ++i)
    {
        vec2 Xi = Hammersley(i, SAMPLE_COUNT);
        vec3 H  = ImportanceSampleGGX(Xi, N, roughness);
        vec3 L  = normalize(2.0 * dot(V, H) * H - V);

        float NdotL = max(L.z, 0.0);
        float NdotH = max(H.z, 0.0);
        float VdotH = max(dot(V, H), 0.0);

        if(NdotL > 0.0)
        {
            float G = GeometrySmith(N, V, L, roughness);
            // 我们就是基于NDF进行重要性采样的
            // 所以这里除了F，实际上也不需要计算D项。
            // 所以fr只剩下了分母，和几何项G。
            float G_Vis = (G * VdotH) / (NdotH * NdotV);
            float Fc = pow(1.0 - VdotH, 5.0);

            A += (1.0 - Fc) * G_Vis;
            B += Fc * G_Vis;
        }
    }
    A /= float(SAMPLE_COUNT);
    B /= float(SAMPLE_COUNT);
    return vec2(A, B);
}
// ----------------------------------------------------------------------------
void main() 
{
    vec2 integratedBRDF = IntegrateBRDF(TexCoords.x, TexCoords.y);
    FragColor = integratedBRDF;
}
```


如你所见，**BRDF卷积部分**是从数学到代码的直接转换。我们将角度$\theta$和粗糙度作为输入，以**重要性采样**产生**采样向量**，在整个几何体上结合**BRDF的菲涅耳项**对向量进行处理，然后输出每个样本上$F_0$的**系数和偏差**，最后**取平均值**。


#### 关于几何项
与`IBL` 一起使用时，**BRDF的几何项**略有不同，因为` k `变量的含义稍有不同：
![在这里插入图片描述](https://img-blog.csdnimg.cn/6049ee100734457b8beb2f1e14ace040.png)

由于**BRDF卷积**是镜面IBL积分的一部分，因此我们要在 `Schlick-GGX`几何函数中使用$k_{IBL}$：

```cpp
float GeometrySchlickGGX(float NdotV, float roughness)
{
    float a = roughness;
    float k = (a * a) / 2.0;

    float nom   = NdotV;
    float denom = NdotV * (1.0 - k) + k;

    return nom / denom;
}
// ----------------------------------------------------------------------------
float GeometrySmith(vec3 N, vec3 V, vec3 L, float roughness)
{
    float NdotV = max(dot(N, V), 0.0);
    float NdotL = max(dot(N, L), 0.0);
    float ggx2 = GeometrySchlickGGX(NdotV, roughness);
    float ggx1 = GeometrySchlickGGX(NdotL, roughness);

    return ggx1 * ggx2;
}  
```

> 请注意，虽然 k 还是从 a 计算出来的，但这里的 a 不是 roughness 的平方——如同最初对 a 的其他解释那样——在这里我们假装平方过了。我不确定这样处理是否与 Epic Games 或迪士尼原始论文不一致，但是直接将 roughness 赋给 a 得到的 BRDF 积分贴图与 Epic Games 的版本完全一致。

#### 结果
![在这里插入图片描述](https://img-blog.csdnimg.cn/917db68c7cfd4505b0d8dde595eb1966.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_13,color_FFFFFF,t_70,g_se,x_16#pic_center)


### 3.4 实时运行阶段
也是公式到代码的直接复刻：

```cpp
vec3 F = FresnelSchlickRoughness(max(dot(N, V), 0.0), F0, roughness);

vec3 kS = F;
vec3 kD = 1.0 - kS;
kD *= 1.0 - metallic;     

vec3 irradiance = texture(irradianceMap, N).rgb;
vec3 diffuse    = irradiance * albedo;

const float MAX_REFLECTION_LOD = 4.0;
vec3 prefilteredColor = textureLod(prefilterMap, R,  roughness * MAX_REFLECTION_LOD).rgb;   
vec2 envBRDF  = texture(brdfLUT, vec2(max(dot(N, V), 0.0), roughness)).rg;
vec3 specular = prefilteredColor * (F * envBRDF.x + envBRDF.y);

vec3 ambient = (kD * diffuse + specular) * ao; 
```
请注意，`specular `没有乘以$k_s$，因为已经乘过了**菲涅耳系数**。 现在，在一系列粗糙度和金属度各异的球上运行此代码：
![在这里插入图片描述](https://img-blog.csdnimg.cn/b7323d92d074423c8c6354d1e11fe776.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)

## 参考
[1] [LearnOpenGLCN](https://learnopengl-cn.github.io/07%20PBR/03%20IBL/02%20Specular%20IBL/#brdf)
[2] Real Time Rendering 4th.
[3] [Filament白皮书](https://jerkwin.github.io/filamentcn/Filament.md.html#%E5%85%B3%E4%BA%8E)
[4] 学姐的笔记
[5] [Games202](http://games-cn.org/games202/)


