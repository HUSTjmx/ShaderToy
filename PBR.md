## PBR

#### 1 数学知识

1. 立体角：立体角描述了从原点向一个球面区域张成的视野大小，可以看成是弧度的三维扩展。我们知道弧度是度量二维角度的量，等于角度在单位圆上对应的弧长，单位圆的周长是2π，所以整个圆对应的弧度也是2π 。立体角则是度量三维角度的量，用符号Ω表示，单位为立体弧度（也叫球面度，Steradian，简写为sr），等于立体角在单位球上对应的区域的面积（实际上也就是在任意半径的球上的面积除以半径的平方$$ω= s/r^2 $$），单位球的表面积是$$4\pi r^2$$，所以整个球面的立体角也是4π 。

   ![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/paperPicture/PBR/%E7%AB%8B%E4%BD%93%E8%A7%92.PNG)
   $$
   dA=(rd\theta)(rsin\theta d\varphi)=r^2sin\theta d\theta d\varphi \\
   dw=\frac{dA}{r^2}=sin\theta d\theta d\varphi
   $$



#### 2 辐射度量学知识

​	![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/paperPicture/PBR/%E8%BE%90%E5%B0%84%E5%BA%A6%E9%87%8F.jpg)

1. 辐射能Q：“总击中”，实际公式中无意义，单位：焦耳$$J$$

2. 辐射通量$$\Phi$$：“每秒击中”，单位：瓦特$$\quad w=j/s$$

3. 辐照度E：“每秒每单位面积的击中”，理解为辐射通量的密度， 单位：$$w/m^2$$

   - 从这个角度出发，我们在图像生成方面的目标是估计图像中每个点的辐照度(或者每像素的总辐射通量)

   - $$E=\frac{\Phi * cos\theta}{A}\quad,\frac{E_2}{E_1}=\frac{r_1^2}{r_2^2}$$

     <img src="https://jmx-paper.oss-cn-beijing.aliyuncs.com/paperPicture/PBR/%E6%8D%95%E8%8E%B7.PNG" style="zoom:67%;" />

4. 辐射度（radiance）L：辐射度是辐照度的立体角度密度。

   - 辐射度是沿着由原点p和方向 ![[公式]](https://www.zhihu.com/equation?tex=w) 定义的射线的能量

     
     $$
     L(P,w)=lim_{\Delta \rightarrow 0}\frac{dE_w(p)}{dw}
     $$



#### 3 前置理论

[基于物理的渲染（PBR）白皮书——毛星云]: https://zhuanlan.zhihu.com/p/56967462

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/paperPicture/PBR/%E8%BE%B9%E7%95%8C%E4%BA%A4%E4%BA%92.jpg)

1. 微平面理论：微平面理论是将物体表面建模成做无数微观尺度上有随机朝向的理想镜面反射的小平面（microfacet）的理论。在实际的PBR 工作流中，**这种物体表面的不规则性用粗糙度贴图或者高光度贴图来表示。**

   <img src="https://jmx-paper.oss-cn-beijing.aliyuncs.com/paperPicture/PBR/%E5%BE%AE%E5%B9%B3%E9%9D%A2.PNG" style="zoom:80%;" />

2. **次表面散射**：光线不止再物体的表面发生散射，而是会先折射到物体内部，然后再物体内部发生若干次散射，直到从物体表面的某一点射出。所以对于次表面散射性质的材质来说，光线出射的位置和入射的位置是不一样的，而且每一点的亮度取决于物体表面所有其他位置的亮度，物体的形状，厚度等

   [次表面散射]: https://zhuanlan.zhihu.com/p/21247702?refer=graphics

   ![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/paperPicture/PBR/%E6%AC%A1%E8%A1%A8%E9%9D%A2%E6%95%A3%E5%B0%84.PNG)

3. **菲涅尔反射**：光线以不同角度入射会有不同的反射率。相同的入射角度，不同的物质也会有不同的反射率。万物皆有菲涅尔反射。F0是即 0 度角入射的菲涅尔反射值。大多数非金属的F0范围是0.02—0.04，大多数金属的F0范围是0.7~1.0。**任意角度的菲涅尔反射率可由F0和入射角度计算得出**。需要注意的是，**我们在宏观层面看到的菲涅尔效应实际上是微观层面微平面菲涅尔效应的平均值。**也就是说，影响菲涅尔效应的关键参数在于每个微平面的法向量和入射光线的角度，而不是宏观平面的法向量和入射光线的角度。即：

   - 当从接近平行于表面的视线方向进行观察，所有光滑表面都会变得100%的反射性。
   - 对于粗糙表面来说，在接近平行方向的高光反射也会增强，但不够达到100%的强度。

   <img src="https://jmx-paper.oss-cn-beijing.aliyuncs.com/paperPicture/PBR/%E8%8F%B2%E6%B6%85%E5%B0%94.jpg" style="zoom:50%;" />

4. 线性空间：光照计算必须在线性空间完成，shader 中输入的gamma空间的贴图比如漫反射贴图需要被转成线性空间，在具体操作时需要根据不同引擎和渲染器的不同做不同的操作。而描述物体表面属性的贴图如粗糙度，高光贴图，金属贴图等必须保证是线性空间。

5. **色调映射（Tone Mapping）**。也称色调复制（tone reproduction），是将宽范围的照明级别拟合到屏幕有限色域内的过程。因为基于HDR渲染出来的亮度值会超过显示器能够显示最大亮度，所以需要使用色调映射，将光照结果从HDR转换为显示器能够正常显示的LDR

6. 能量守恒：射光线的能量永远不能超过入射光线的能量。随着粗糙度的上升镜面反射区域的面积会增加，作为平衡，镜面反射区域的平均亮度则会下降。
   $$
   \int_{\xi^2}f_r(p,w_i \rightarrow w_o)cos\theta dw_i<=1
   $$

7. **物质的光学特性（Substance Optical Properties）。**现实世界中有不同类型的物质可分为三大类：绝缘体（Insulators），半导体（semi-conductors）和导体（conductors）。在渲染和游戏领域，我们一般只对其中的两个感兴趣：导体（金属）和绝缘体（电解质，非金属）。其中非金属具有单色/灰色镜面反射颜色。而金属具有彩色的镜面反射颜色。即非金属的F0是一个float。而金属的F0是一个float3

   ![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/paperPicture/PBR/%E6%9D%90%E8%B4%A8.jpg)


#### 4  渲染方程

$$
L_o(p,w_o=L_e(p,w_o)+\int_{\xi^2}{f_r(p,w_i \rightarrow w_o)L_i(p,w_i)cos\theta dw_i}
$$

1. ![[公式]](https://www.zhihu.com/equation?tex=L_%7Bo%7D) 是p点的出射光亮度。
2. ![[公式]](https://www.zhihu.com/equation?tex=L_%7Be%7D) 是p点发出的光亮度。
3. ![[公式]](https://www.zhihu.com/equation?tex=f_%7Br%7D) 是p点入射方向到出射方向光的反射比例，即BxDF，一般为BRDF。
4. ![[公式]](https://www.zhihu.com/equation?tex=L_%7Bi%7D) 是p点入射光亮度。
5. ![[公式]](https://www.zhihu.com/equation?tex=+%28%7B%7Bw_%7Bi%7D%7D%7D%5Ccdot++%7Bn%7D%29) 是入射角带来的入射光衰减
6. ![[公式]](https://www.zhihu.com/equation?tex=%7B%5Cdisplaystyle+%5Cint+_%7B%5COmega+%7D...d%7B+%7Bw_i%7D%7D%7D) 是入射方向半球的积分（可以理解为无穷小的累加和）



#### 5 Disney Diffuse

1. Lambert漫反射模型在边缘上通常太暗，而通过尝试添加菲涅尔因子以使其在物理上更合理，但会导致其更暗。所以，根据对Merl 100材质库的观察，Disney开发了一种用于漫反射的新的经验模型，以在光滑表面的漫反射菲涅尔阴影和粗糙表面之间进行平滑过渡。思路方面，Disney使用了Schlick Fresnel近似，并修改掠射逆反射（grazing retroreflection response）以达到其特定值由粗糙度值确定，而不是简单为0。

   Disney Diffuse漫反射模型的公式为：
   $$
   f_d=\frac{baseColor}{\pi}(1+(F_{D90}-1)(1-cos\theta_l)^5)(1+(F_{D90}-1)(1-cos\theta_v)^5)
   \\
   F_{D90}=0.5+2roghness*cos^2\theta_d
   $$
   其中，$$\theta_d$$为半矢量h和视线矢量v之间的夹角。

   

#### 6 高光BRDF（Cook-Torrance模型）

$$
f(l,v)=diffuse+\frac{F(l,h)G(l,h)D(h)}{4cos\theta_icos\theta_o}=f_d+\frac{F(l,h)G(l,h)D(h)}{4(n*l)(n*v)}
$$

入射光方向![[公式]](https://www.zhihu.com/equation?tex=%5Comega+_i)，观察方向![[公式]](https://www.zhihu.com/equation?tex=%5Comega+_o)，对反射到![[公式]](https://www.zhihu.com/equation?tex=%5Comega+_o)方向的反射光有贡献的微表面法线为半角向量![[公式]](https://www.zhihu.com/equation?tex=%5Comega+_h)，则这束光的微分通量
$$
d\Phi_h=L_i(w_i)dw_idA^\bot(w_h)=L_i(w_i)dw_icos\theta_hdA(w_h)
\\
\begin{aligned}
*其中dA(w_h)是法线为半角向量w_h的微分微表面面积，dA^\bot(w_h)为dA(w_h)在入射光线方向的投影，\theta_h为入射光
\\
线和微表面法线的夹角，且定义dA(w_h)=D(w_h)dw_hdA，D(w_h)定义为dA中朝向w_h的比例，d_w稍后讨论。
\end{aligned}
$$

$$
d\Phi_h=L_i(w_i)dw_icos\theta_hD(w_h）dw_hdA\\
$$

然后，设定微表面反射光线遵循菲涅尔定理，则反射通量以及反射辐射率为:
$$
d\Phi_o=F_r(w_o)d\Phi_h
\\
-----------------------------
\\
dL_o(w_o)=\frac{d\Phi_o}{dw_ocos\theta_odA}=\frac{F_r(w_o)L_i(w_i)dw_icos\theta_hD(w_h)dw_hdA}{dw_ocos\theta_odA}
$$
由BRDF的定义可知
$$
f_r(w_i,w_o)=\frac{dL_o(w_o)}{dE_i(w_i)}=\frac{dL_o(w_o)}{L_i(w_i)cos\theta_idw_i}
=\frac{F_r(w_o)cos\theta_hD(w_h)dw_h}{cos\theta_ocos\theta_idw_o}
$$
回头看反射方程![[公式]](https://www.zhihu.com/equation?tex=L_o%28v%29+%3D+%5Cint_%7B%5COmega+%7D%5E%7B%7D+f%28l%2C+v%29+%5Cotimes+L_i%28l%29+cos+%5Ctheta_i+d%5Comega_i)是对![[公式]](https://www.zhihu.com/equation?tex=d+%5Comega_i)积分，而上式分母包含![[公式]](https://www.zhihu.com/equation?tex=d+%5Comega_o)，需要想办法把![[公式]](https://www.zhihu.com/equation?tex=d+%5Comega_o)消掉，我估计这也是为什么Torrance-Sparrow在![[公式]](https://www.zhihu.com/equation?tex=dA%28%5Comega_h%29+%3D+D%28%5Comega_h%29+d+%5Comega_h+dA)中塞一个![[公式]](https://www.zhihu.com/equation?tex=d+%5Comega_h)，：可以通过找到![[公式]](https://www.zhihu.com/equation?tex=%5Cfrac%7Bd+%5Comega_h%7D%7Bd+%5Comega_o%7D+)的关系，把![[公式]](https://www.zhihu.com/equation?tex=d+%5Comega_o)消掉。塞入![[公式]](https://www.zhihu.com/equation?tex=d+%5Comega_h)并不会影响方程的合理性，因为![[公式]](https://www.zhihu.com/equation?tex=D%28%5Comega_h%29)是可以调整的，现在![[公式]](https://www.zhihu.com/equation?tex=D%28%5Comega_h%29)是一个有单位的量，单位为![[公式]](https://www.zhihu.com/equation?tex=1%2Fsr)。

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/paperPicture/PBR/BRDF.PNG)

如上图，入射光线照射到一个微表面上，与微表面的单位上半球相交于点![[公式]](https://www.zhihu.com/equation?tex=I)，与微表面相交于点![[公式]](https://www.zhihu.com/equation?tex=O)，反射光线与单位上半球相交于点![[公式]](https://www.zhihu.com/equation?tex=R)，反射光束立体角![[公式]](https://www.zhihu.com/equation?tex=d+%5Comega_o)（图中是![[公式]](https://www.zhihu.com/equation?tex=d+%5Comega_r)）等于光束与单位上半球相交区域面积![[公式]](https://www.zhihu.com/equation?tex=dA_r)，法线立体角![[公式]](https://www.zhihu.com/equation?tex=d+%5Comega_h)（图中是![[公式]](https://www.zhihu.com/equation?tex=d+%5Comega%5E%5Cprime)）等于法线立体角与单位上半球相交区域面积![[公式]](https://www.zhihu.com/equation?tex=dA%5E%5Cprime)，因此求![[公式]](https://www.zhihu.com/equation?tex=%5Cfrac%7Bd+%5Comega_h%7D%7Bd+%5Comega_o%7D+)等价于求![[公式]](https://www.zhihu.com/equation?tex=%5Cfrac%7BdA%5E%5Cprime%7D%7BdA_r%7D)。

连线![[公式]](https://www.zhihu.com/equation?tex=IR)与法线![[公式]](https://www.zhihu.com/equation?tex=n%5E%5Cprime+)相交于点![[公式]](https://www.zhihu.com/equation?tex=P)，则![[公式]](https://www.zhihu.com/equation?tex=IR+%3D+2IP)，由于![[公式]](https://www.zhihu.com/equation?tex=dA_r)与![[公式]](https://www.zhihu.com/equation?tex=dA%5E%7B%5Cprime+%5Cprime+%5Cprime%7D)半径的比值等于![[公式]](https://www.zhihu.com/equation?tex=%5Cfrac%7BIR%7D%7BIP%7D)，而面积为![[公式]](https://www.zhihu.com/equation?tex=%5Cpi+r%5E2)，与半径的平方成正比，所以![[公式]](https://www.zhihu.com/equation?tex=dA_r+%3D+4+dA%5E%7B%5Cprime+%5Cprime+%5Cprime%7D)

连线![[公式]](https://www.zhihu.com/equation?tex=OQ)长度为1，![[公式]](https://www.zhihu.com/equation?tex=OP)长度为![[公式]](https://www.zhihu.com/equation?tex=cos+%5Ctheta_i+%5E+%5Cprime)，所以![[公式]](https://www.zhihu.com/equation?tex=%5Cfrac%7BdA%5E%7B%5Cprime+%5Cprime%7D%7D%7BdA%5E%7B%5Cprime+%5Cprime+%5Cprime%7D%7D+%3D+%5Cfrac%7B1%7D%7Bcos+%5E+2+%5Ctheta_i+%5E+%5Cprime%7D)

而![[公式]](https://www.zhihu.com/equation?tex=dA%5E%7B%5Cprime+%5Cprime%7D+%3D+%5Cfrac%7BdA%5E%7B%5Cprime%7D%7D%7Bcos+%5Ctheta_i%5E%7B%5Cprime%7D%7D)

由以上几式可得![[公式]](https://www.zhihu.com/equation?tex=%5Cfrac%7BdA%5E%5Cprime%7D%7BdA_r%7D+%3D+%5Cfrac%7B1%7D%7B4+cos+%5Ctheta_i+%5E+%5Cprime%7D)

需要注意的是，上图中的![[公式]](https://www.zhihu.com/equation?tex=%5Ctheta_i+%5E+%5Cprime)实际上是微表面的半角![[公式]](https://www.zhihu.com/equation?tex=%5Ctheta_h)，所以![[公式]](https://www.zhihu.com/equation?tex=%5Cfrac%7Bd+%5Comega_h%7D%7Bd+%5Comega_o%7D+%3D+%5Cfrac%7B1%7D%7B4+cos+%5Ctheta_h%7D)

因此![[公式]](https://www.zhihu.com/equation?tex=f_r%28%5Comega_i%2C+%5Comega_o%29+%3D+%5Cfrac%7BF_r%28%5Comega_o%29+D%28%5Comega_h%29%7D%7B4+cos+%5Ctheta_o+cos+%5Ctheta_i%7D)

前面讲到过并非所有朝向为![[公式]](https://www.zhihu.com/equation?tex=%5Comega_h)的微表面都能接受到光照（Shadowing），也并非所有反射光照都能到达观察者（Masking），考虑几何衰减因子G的影响，则

![[公式]](https://www.zhihu.com/equation?tex=f_r%28%5Comega_i%2C+%5Comega_o%29+%3D+%5Cfrac%7BF_r%28%5Comega_o%29+D%28%5Comega_h%29+G%28%5Comega_i%2C+%5Comega_o%29%7D%7B4+cos+%5Ctheta_o+cos+%5Ctheta_i%7D)

​	

[基于物理着色：BRDF]: https://zhuanlan.zhihu.com/p/21376124



#### 7 D-F-G

1. **法线分布项 Normal Distribution Function，NDF（核心）**
   
   [法线分布函数相关总结]: https://zhuanlan.zhihu.com/p/69380665	"各项异性的公式可见此"
   
   - 在基于物理的渲染工作流中，通过将粗糙度贴图（Roughness Map）与微平面归一化的法线分布函数结合使用，将需渲染的几何体的建模尺度细化到了微观尺度（Microscale）的亚像素层面，对材质的微观表现更加定量，所以能够带来更加接近真实的渲染质量和更全面的材质外观质感把控
     
   - **若以函数输入和输出的角度来看NDF，则其输入为微表面粗糙度（微表面法线集中程度）和宏观法线与视线的中间矢量（微表面法线方向），输出为此方向上的微表面法线强度。**
     
   - **形状不变性（shape-invariant）**是一个合格的法线分布函数需要具备的重要性质。具有形状不变性（shape-invariant）的法线分布函数，**可以用于推导该函数的归一化的各向异性版本，并且可以很方便地推导出对应的遮蔽阴影项G**。对于形状不变的NDF，缩放粗糙度参数相当于通过倒数拉伸微观几何,如下图所示
     
     <img src="https://jmx-paper.oss-cn-beijing.aliyuncs.com/paperPicture/PBR/%E5%BD%A2%E7%8A%B6%E4%B8%8D%E5%8F%98%E5%BD%A2.PNG" style="zoom:67%;" />
     
   - 在流行的模型中，GGX拥有最长的尾部。而GGX其实与Blinn (1977)推崇的Trowbridge-Reitz（TR）（1975）分布等同。然而，对于许多材质而言，即便是GGX分布，仍然没有足够长的尾部。Trowbridge-Reitz（TR）的公式为：
$$
     D_{TR}=\frac{\alpha^2}{\pi((n\cdot h)^2(\alpha^2-1)+1)^2}=c/(\alpha^2cos^2\theta_h+sin^2\theta_h)^2
     \\
     其中,n是宏观平面法线，h是半角向量,c为缩放系数，\alpha为粗糙度
$$

Disney将Trowbridge-Reitz进行了N次幂的推广，并将其取名为Generalized-Trowbridge-Reitz，GTR：

$$
D_{GTR}=c/(\alpha^2cos^2\theta_h+sin^2\theta_h)^\gamma

   \\γ=1时，GTR即Berry分布\\
     γ=2时，GTR即Trowbridge-Reitz分布
$$

   - GTR、Phong分布不具备形状不变性（shape-invariant）,**GGX、Beckmann分布具备形状不变性（shape-invariant）**
   
   - Disney Principled BRDF中使用了两个固定的镜面反射波瓣（specular lobe），且都使用GTR模型，可以总结如下：
   
     - **主波瓣（primary lobe）**
       - 使用γ= 2的GTR（即GGX分布）	
       - 代表基础底层材质（Base Material）的反射
       - 可为各项异性（anisotropic） 或各项同性（isotropic）的金属或非金属
     - **次级波瓣（secondary lobe）**
       - 使用γ= 1的GTR（即Berry分布）
       - 代表基础材质上的清漆层（ClearCoat Layer）的反射
       - 一般为各项同性（isotropic）的非金属材质，即清漆层（ClearCoat Layer）
   
   - 若一个各向同性（isotropic）的NDF具备形状不变性（shape-invariant），则其可以用以下形式写出：
$$
     D(m)=\frac{1}{\alpha^2(n\cdot m)^4}g(\frac{\sqrt{1-(n\cdot m)^2}}{\alpha(n \cdot m)})
$$
 其中g（）代表一个表示了NDF形状的一维函数。而通过此形式，可得到各向异性的（anisotropic）版本：
$$
 D(m)=\frac{1}{\alpha_x\alpha_y(n\cdot m)^4}g(\frac{\sqrt{\frac{(t\cdot m)^2}{\alpha_x^2}+\frac{(b\cdot m)^2}{\alpha_y^2}}}{\alpha(n \cdot m)})
$$

 - 其中，参数**αx**和**αy**分别表示沿切线（tangent）方向**t**和副法线（binormal）方向**b**的粗糙度。若**αx = αy**，则上式缩减回各向同性形式。

   - 需要注意的是，一般的shader写法，会将切线方向**t**写作X，副法线（binormal）**b**方向写作Y
     
   - 各项异性代码举例
   
     ```c#
     float D_GTR2_aniso(float dotHX, float dotHY, float dotNH, float ax, float ay)
     {
     	float deno = dotHX * dotHX / (ax * ax) + dotHY * dotHY / (ay * ay) + dotNH * dotNH;
         return 1.0 / (PI * ax * ay * deno * deno);
     }
     
     ```
   
     

2. **菲涅尔项 Fresnel**

   - F0：0度角入射时的菲涅尔反射率。而折射（refracted）到表面中的光量则为为1-F0，通用的折射率与F0关系如下，也可以直接查表：
     $$
     F_0=(\frac{n1-n2}{n1+n2}),其中n1（物体）和n2（通常是空气，1）是两种物质的折射率
     $$

   - Schlick Fresnel近似已经足够精确，且比完整的菲涅尔方程简单得多; 而由于其他因素，Schlick Fresnel 近似引入的误差明显小于其他因素产生的误差。Schlick Fresnel 近似公式如下：

   $$
   F_{Schlick}=F_0+(1-F_0)(1-cos\theta_d)^5
   $$

   ​		其中，$$\theta_d$$为半矢量h和视线矢量v之间的夹角。一般建议实现一个自定义的Pow5工具函数替换pow(xx, 		5.0)的调用，以省去pow函数带来的稍昂贵的性能开销。

   - Disney在SIGGRAPH 2015上对此项进行了修订，提出在介质间相对IOR（折射率）接近1时，Schlick近似误差较大，这时可以直接用精确的菲涅尔方程：

   ​		![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/paperPicture/PBR/Fresnel.PNG)

   - 公式理解：$$\theta_d$$是间接表明光线的入射角度，当$$\theta_d$$接近90度时，入射光也接近物体表面切线，此时，不管是金属还是电解质，反射率都很高，Schlick公式很简单，指数5个人认为是经验的结果(结果较为接近准确的菲涅尔方程）

3. **几何项G**：Smith-GGX**（辅助核心：，但最复杂）**

   [几何函数相关总结]: https://zhuanlan.zhihu.com/p/81708753

   - 在基于物理的渲染技术中，通常除了近掠射角或非常粗糙的表面，几何函数对BRDF的形状影响相对较小，但几何函数（Geometry Function）是保证Microfacet BRDF**理论上能量守恒，逻辑上自洽的重要一环**。其描述了微平面自阴影的属性，表示具有半矢量法线的微平面（microfacet）中，同时被入射方向和反射方向可见（没有被遮挡的）的比例，即未被遮挡的m = h微表面的百分比。
   - **几何函数的解析形式的确认依赖于法线分布函数**；**法线分布函数需要结合几何函数，得到有效的法线分布强度**

   - 几何项（Specular G）方面，对于主镜面波瓣（primary specular lobe），Disney参考了 Walter的近似方法，使用Smith GGX导出的G项，并将粗糙度参数进行重映射以减少光泽表面的极端增益，即将α 从[0, 1]重映射到[0.5, 1]，α的值为$$(0.5 + roughness/2)^2$$。从而使几何项的粗糙度变化更加平滑，更便于美术人员的使用。以下为Smith GGX的几何项的表达式：
     $$
     G(l,v,h)=G_{GGX}(l)G_{GGX}(v)
     \\
     G_{GGX}(v)=\frac{2(n \cdot v)}{(n\cdot v)+\sqrt{\alpha^2+(1-\alpha^2)(n \cdot v)^2}}
     \\
     \alpha=(0.5+roughness/2)^2
     $$

   - 另外，对于对清漆层进行处理的次级波瓣（secondary lobe），Disney没有使用Smith G推导，而是直接使用固定粗糙度为0.25的GGX的 G项，便可以得到合理且很好的视觉效果。



#### 其他

1. 锯齿（Aliasing）是实时渲染和图形学中经常会面对的问题。而PBR由于使用了标准化的法线分布函数（normalized NDF），以及无处不在的反射现象，加上实时渲染中较少的采样率，让其高光的锯齿问题更加明显。这导致了基于物理的渲染中，高光锯齿是实践中经常会遇到的问题。

2. 关于高光锯齿，业界的解决方案分为两大流派：屏幕空间抗锯齿（Anti-Aliasing）和预过滤（Pre-Filtering）

   

   