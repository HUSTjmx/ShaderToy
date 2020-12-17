# Interactive Indirect Illumination Using Voxel Cone Tracing

![image-20201216181947607](Interactive Indirect Illumination Using Voxel Cone Tracing.assets/image-20201216181947607.png)

本文主要基于分层的<span style="color:red;font-size:1.3rem">体素八叉树</span>。通过一个常规的场景网格，加上**近似体素**<span style="color:red;font-size:1.3rem">锥跟踪</span>（此技术允许对能见度和传入的能量进行**快速估算**），本文可以实时**生成和更新**这个体素八叉树。

本文可以在25~70 FPS的表现下，为`Lambertian`材料和`Glossy`材料添加 *2 light bounce*的GI，其性能表现几乎和场景无关、且**不局限于低频照明**。

> 它显示了几乎与场景无关的性能，因为我们尽量避免在我们的计算中涉及实际网格。
>
> 建议主题：Fluent

## 1. Introduction

离线不行；预计算限制太大。

本文方法的==核心==是**预过滤**场景几何的层次八叉树。考虑到效率，这个表示以==动态稀疏八叉树==的形式存储在GPU上。利用一种新的==voxel cone tracing technique==，我们依靠这种**预滤波**，来快速估计**可见性**，并将来自光源的**间接能量**投射到结构中。

八叉树首先基于场景的静态部分进行构建，然后根据移动物体，或场景改变，来进行**更新**。



## 2. Previous Work