# Chapter 14——Volumetric and Translucency Rendering

<span style="color:yellow;font-size:1.3rem">Participating media</span>是光传输的参与者，它们通过*散射或吸收*来影响穿过它们的光。之前我们讨论的大多是密集介质，而*密度较低的介质*是水、雾、蒸汽，甚至是由稀疏分子组成的空气。

根据其组成的不同，介质与穿过它的光以及*与它的粒子反射*的光之间的相互作用会有所不同，这一事件通常被称为光散射**light scattering**。

如9.1节所示，**漫反射表面着色模型**是光在微观层面上散射的结果。

<span style="color:yellow;font-size:1.3rem">Everything is scattering!</span>



## 1. Light Scattering Theory

在本节中，我们将描述参与介质中*光的模拟和渲染*。辐射传输方程 *radiative transfer equation* 在**多重散射路径追踪**中，被许多作者描述**[479,743,818,1413]**。在这里，我们将专注于*单个散射*，下表:arrow_down:给出了散射方程中参与介质的属性。

> :star:值得注意的是，这里很多的属性都是**波长相关的**，这意味着它们都是RGB值。
>
> 所以，回顾之前的波长相关量，我们也会发现这个道理，确实也是。RGB颜色值本质上也是光的波长，而这些值又都是波长相关的，所以自然而然也是可以考虑成RGB量

<img src="RTR4_C14.assets/image-20201213164037613.png" alt="image-20201213164037613" style="zoom:80%;" />





### 1.1 Participating Media Material

==有四种类型的事件，可以影响沿光线通过介质传播的辐射量==，可见上表:arrow_up:，也可见：

- **Absorption**（$\sigma_a$）：光子被介质吸收，然后转换为*热能*或其它形式的能量。
- **Out-scattering**（$\sigma_s$）：光子在介质中碰撞粒子而*散射*。这将根据描述*光反弹方向分布*（ **light bounce directions**）的相位函数p发生。
- **Emission**：当介质达到高温时，会发出光，例如火的黑体辐射。关于自发光的更多细节可见[**479**]
- **In-scattering**（$\sigma_s$）：

