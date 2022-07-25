## 1. 技术理解
**RSM**的全称是`reflective shadow maps`，受到**Instant Radiosity**这个离线技术的启发，其思想和**ShadowMap**的思想近似。在正式介绍和了解这个技术之前，我需要确定**RSM**用处何在？我想，《RTR4》中对它的分类很正确——`Dynamic Diffuse Global Illumination`，这是一个处理**动态全局漫反射**的技术：

 - **GI**（全局光照）：用于二次及以上bounce造成的间接光。
 - **Dynamic**（动态）：可以实时更新，可作用于动态物体。
 - **Diffuse**（漫反射）：更加细致的说，这个技术考虑的是间接光照中的漫反射部分。

**RSM**和立即辐射度方法一样，都是在**直接光照亮的区域**，选择采样点作为**发光物**（虚拟点光源`VPL`），来计算**间接光照**。主要分为两个`Pass`：

 1. `Pass 1`：从光源的角度，对整个场景进行一次渲染。这个过程在引擎中可以直接和**ShadowMap的生成**放在一块。不过不同的是，除了存储**深度**之外（这个感觉就是直接使用`ShadowMap`的结果），我们还需要存储**世界空间位置**、**法线**、**辐射通量**。
 2. `Pass 2`：在正常的`lighting pass`中，考虑基于`RSM`的间接光。

### 1.1 推导
在`RSM`中，每个像素都被解释为**一个间接照亮场景的像素光**。通量$\phi_p$定义了其**亮度**。

> 辐射通量$\phi_p$：radiant flux，单位是`W`（瓦特）。描述的是光源的总体能量——每秒的发出的辐射能量。而辐照度`E`的单位是$W/m^2$，辐射强度`I`的单位是$W/sr$。我们在光照积分中比较常见的是：辐射率`L`，单位是$W/(m^2sr)$
> 注意：当光源的面积无限小时，基本可以将辐射强度`I`等同于辐射度`L`。

![在这里插入图片描述](https://img-blog.csdnimg.cn/a210f28fce6e4c3b8d6432704fb85a3a.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)

**忽略可见性**，我们的**光照积分**应该时如下形式：
$$
	L_o(p,w_o)=\int_{\Omega_{pacth}}{L_i(p,w_i)V(p,w_i)f_{r1}(p,w_i,w_o)\cos{\theta_p}dw_i}
	\\
	=\int _{A_{pacth}}L_i(p,w_i)f_{r1}(p,w_i,w_o)\frac{\cos{\theta_p} \cos{\theta_q}}{||q-p||^2} dA
	\\
$$

 参考上图，作者假设光源是**无限小的**，而且$dw=\frac{dA\cos{\theta_q}}{||x^/-x||^2}$，我们可以做出如下推导：法线为`n`的**表面点**`p`因**像素光**`q`而产生的辐照度为：
$$
	dE(p)=L_i(p,w_i)\cos{\theta_p}dw_i
 \\
 \\
 E(p)=\int L_i\cos{\theta_p}dw_i=\int_{A_{patch}}L_i\frac{\cos{\theta_p} \cos{\theta_q}}{||q-p||^2} dA 
 $$
 又因为对于一个`diffuse patch`来说，所有方向的出射光都是相同的——可以有$L_i=f_r \cdot \frac{\Phi}{dA}$（这个公式如何理解？），所以：
$$
E(p)=\frac{\cos{\theta_p} \cos{\theta_q}}{||q-p||^2}\Phi_p
$$

实际上：$\Phi_p=\Phi_{light}\cdot f_{r_q}$。最终推导为：
![在这里插入图片描述](https://img-blog.csdnimg.cn/23446ac14e0746dd99fd88c29d39ab2b.png)


> **争议**：$||x-x_p||$的上标是`4`，还是`2`，有所争议。
> **参考**：
> ![在这里插入图片描述](https://img-blog.csdnimg.cn/a5eda5465863449fbcf1e5804bddf5b4.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)





## 2. Pass 1：Generation
### 2.1 Data
由果推因，最后的计算公式需要世界空间位置、法线、辐射通量，我们就存储它们。但现在，依然存在一个问题，我们存取的通量怎么获得？

如果说，平行光的通量是$\Phi$，那么照明这个像素块之后，**出射辐射率**是：$L_o=f_r\cdot \frac{\Phi}{dA}$。而这个像素块此时的辐射通量是：
$$
	\Phi_p=\int_{Area}\int_{\Omega}(L_o)dAdw_o=\int_{\Omega}(f_r\cdot \Phi)
 dw_i
$$
由于这个`patch`是漫反射的，所以$\Phi$和$f_r$都是常量。而$f_r=\rho/\pi$和$\int(1) dw_i=\pi$，最终：
$$
\Phi_p=\rho\cdot \Phi
$$

### 2.2 实现
所以，最终，我们在第一个Pass中，这样做：

> 代码来自：https://github.com/AngelMonica126/GraphicAlgorithm/blob/master/001_Reflective%20shadow%20map/RSMBuffer_FS.glsl

```cpp
void main()
{
	vec3 TexelColor = texture(u_DiffuseTexture, v2f_TexCoords).rgb;
	//TexelColor = pow(TexelColor, vec3(2.2f));
	vec3 VPLFlux = u_LightColor * TexelColor;
	Flux_ = VPLFlux;
	Normal_ = v2f_Normal;
	Position_ = v2f_FragPosInViewSpace;
}
```
### 3.3 点光源
之前我们考虑的都是**平行光**，如果是**点光源**，我们或许应该在这里考虑一下**光线衰减**和**余弦问题**：
$$
\Phi_p=\rho\cdot \Phi \cdot dot(x_L-x_p,n_p)/(||x_L-x_p||^2)
$$


## 3 Pass 2：Lighting
### 3.1 基础实现
主要流程，读取上一个`pass`存的数据，利用下面的公式，计算间接照明。

```cpp
float3 indirectIllumination = float3(0, 0, 0);
//最远采样半径
float rMax = rsmRMax;

// rsmSampleCount = hight * width（etc. 512*512）
for (uint i = 0; i < rsmSampleCount; ++i)
{
	// 这里就是随机值
	float2 rnd = rsmSamples[i].xy;
	float2 coords = textureSpacePosition.xy + rMax * rnd;
	// 依次读取位置、法线、通量
	float3 vplPositionWS = g_rsmPositionWsMap.Sample(g_clampedSampler, coords.xy).xyz;
	float3 vplNormalWS = g_rsmNormalWsMap.Sample(g_clampedSampler, coords.xy).xyz;
	float3 flux = g_rsmFluxMap.Sample(g_clampedSampler, coords.xy).xyz;
	// 计算当前像素在此RSM像素灯光的影响下，导致的辐照度E
	float3 result = flux
	* ((max(0, dot(vplNormalWS, P – vplPositionWS))
	* max(0, dot(N, vplPositionWS – P)))
	/ pow(length(P – vplPositionWS), 4));
	indirectIllumination += result;
}
indirectIllumination = result / rsmSampleCount;
return saturate(indirectIllumination * rsmIntensity);
```
### 3.2 改进方法
对于一个**典型的阴影图**来说，像素的数量是很大的（$512\times 512$），所以上述`sum`计算是非常昂贵的，在实时情况下不实用。相反，作者必须将总和减少到**有限的光源数量**，例如`400`个。作者使用**重要性驱动的方法**来做到这一点，试图将采样集中到相关像素灯上。

一般来说，可以说`x`和**阴影图中的像素光**$x_p$之间的距离是它们在**世界空间中的距离**的**合理近似值**。如果**相对于光源的深度值**差别很大，世界空间的距离就会大得多，会高估其影响。然而，**重要的间接光源**总是很接近，这些光源在阴影图中也必须是接近的。
所以作者决定按以下方式获得**像素光的样本**：

+ 首先，作者将`x`投影到阴影图$(→(s,t))$中。

+ 然后，作者选择$(s,t)$周围的像素光，**样本密度**随着与$(s,t)$距离的平方而减少。这可以通过选择**相对于$(s,t)$的极坐标样本**轻松实现，也就是说，如果$ξ_1$和$ξ_2$是**均匀分布的随机数**，作者选择位置：
![在这里插入图片描述](https://img-blog.csdnimg.cn/3fe7a0d7493d48979fc1882dca6db690.png)

+ 然后，必须通过用$ξ^2_1$对样本进行加权，来补偿**不同的采样密度**（以及**最后的归一化**）。下图显示了一个**采样模式的例子**。
+ ![在这里插入图片描述](https://img-blog.csdnimg.cn/26aea3522f124598b7e7576a48c536db.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)
实际实现过程中，我们在`CPU`端通过低差异序列，生成随机数$(\xi_1,\xi_2)$。`s`和`t`不用管，就是`GPU`端像素的`UV`坐标，我们只需要计算：$r_{max}\xi_1\sin{(2\pi\xi_2)}$、$r_{max}\xi_1\cos{(2\pi\xi_2)}$、$\xi_1^2$。将这三个数据存储四维向量数组，作为uniform data传入`GPU`：

> 此代码非原创，来自：https://github.com/AngelMonica126/GraphicAlgorithm/blob/master/001_Reflective%20shadow%20map/ShadingWithRSMPass.cpp

```cpp
std::default_random_engine e;
std::uniform_real_distribution<float> u(0, 1);
for (int i = 0; i < m_VPLNum; ++i)
{
	float xi1 = u(e);
	float xi2 = u(e);
	m_VPLsSampleCoordsAndWeights.push_back({ xi1 * sin(2 * ElayGraphics::PI * xi2), xi1 * cos(2 * ElayGraphics::PI * xi2), xi1 * xi1, 0 });
}

genBuffer(GL_UNIFORM_BUFFER, m_VPLsSampleCoordsAndWeights.size() * 4 * sizeof(GL_FLOAT), m_VPLsSampleCoordsAndWeights.data(), GL_STATIC_DRAW, 1);
```
然后，在`GPU`端主要加入的就是这个`权重`：

```cpp
for (int i = 0; i < u_NumSamples; i++)
{
    vec3 offset    = texelFetch(s_Samples, ivec2(i, 0), 0).rgb;
    vec2 tex_coord = light_coord.xy + offset.xy * u_SampleRadius + (((offset.xy * u_SampleRadius) / 2.0) * dither_offset);

    vec3 vpl_pos    = texture(s_RSMWorldPos, tex_coord).rgb;
    vec3 vpl_normal = normalize(texture(s_RSMNormals, tex_coord).rgb);
    vec3 vpl_flux   = texture(s_RSMFlux, tex_coord).rgb;

    vec3 result = light_attenuation(vpl_pos) * vpl_flux * ((max(0.0, dot(vpl_normal, (P - vpl_pos))) * max(0.0, dot(N, (vpl_pos - P)))) / pow(length(P - vpl_pos), 4.0));
	
	// 权重
    result *= offset.z * offset.z;
    indirect += result;
}
```

### 3.3 关于最后的结果是否要乘上albedo
鄙人认为，最后得到的$E_p$，不是当前像素本身产生辐照度（对眼睛生效），而是**其他像素灯**对此像素产生的辐照度，或者推导上可以看看：

$$
	L_o(p,w_o)
	=\int _{A_{pacth}}L_i(p,w_i)f_{r1}(p,w_i,w_o)\frac{\cos{\theta_p} \cos{\theta_q}}{||q-p||^2} dA
	\\
$$

$$
 E(p)=\int L_i\cos{\theta_p}dw_i=\int_{A_{patch}}L_i\frac{\cos{\theta_p} \cos{\theta_q}}{||q-p||^2} dA 
 $$

而$f_r$又和面积没有关系，所以：
$$
L_o(p,w_o)=E(p)*f_{r1}
$$
也就是说，我认为，最终的间接光照结果，应该是：

```cpp
indirect = indirect * albedo / PI;
indirect = indirect / VPL_NUM;
light_result = directLight + indirect;
```

### 4 其他
ToDo


