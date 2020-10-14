# Fast 3D Indoor Scene Synthesis with Discrete and Exact Layout Pattern Extraction

我们提出了一个室内场景合成的快速框架，给定一个房间几何形状和与学习的先验的对象列表。现有的数据驱动解决方案通常通过共现分析和统计模型拟合来提取先验，与此不同的是，我们的方法通过测试完全空间随机性(CSR)来度量空间关系的强度，并基于能够准确表示离散布局模式的样本提取复杂先验。在提取先验的基础上，将输入对象划分为不相交的组，从而达到加速和合理的目的



## 1. Introduction

随着各种室内三维场景数据集的出现，技术转向数据驱动的方法。然而，室内三维场景合成在各个方面仍然存在固有的困难。

首先，不可避免地要处理连续或离散参数化的家具布局，这些布局分布在复杂的高维空间中[24]。一些工作（例如[15，32，13，30]）试图将布局简化为独立的小团体或子集，例如[13，32]。然而，==他们的基本度量依赖于 "共现"，这仅仅是计算共存的频率，而不是结合空间知识==。以图2中的一个例子为例，共现频率高并不一定意味着空间关系强。换句话说，单纯基于共现的场景合成可能会产生奇怪的结果。

![image-20201013202245925](Fast 3D Indoor Scene Synthesis with Discrete and Exact Layout Pattern Extraction.assets/image-20201013202245925.png)

其次，由于排列策略数不胜数，很难详尽地列出物体之间所有可能的空间关系[5,6,31,45,22]，也难以在数学上为它们建立统一而精确的模型。为了对多种模式的关系进行建模，一种常见的方法是用模型拟合观察到的布局。然而，"拟合模型 "可能会潜在地引入噪声，并受到噪声的影响，特别是当基础模式不满足与模型的假设时，例如，常用的高斯混合模型（GMM）。图3显示了一个失败的案例。我们认为，当观察到的数据有足够的大小时，正确的情况下，在观察到的数据或样本内进行拟合已经提供了精确的布局策略与变种。

![image-20201013202309895](Fast 3D Indoor Scene Synthesis with Discrete and Exact Layout Pattern Extraction.assets/image-20201013202309895.png)

为了解决上述困难，==本文提出了一种利用完全空间随机性(CSR)测试来衡量物体之间空间关系强度的方法。==对CSR的测试（第4节）描述了一组事件产生w.r.t同质泊松过程`homogeneous Poisson process`的可能性。直观地说，它衡量了一组点中存在的某些模式的可能程度。因此，具有高测量值的对象往往会被分组并安排在一起。未能通过CSR测试的对象会被忽略，即使它们有很高的共存度。

此外，我们提出了一种利用==密度峰聚类==` density peak clustering`来提取不同形状布局策略的离散表示的方法（ we present an approach for extracting discrete representation of various shapes of layout strategies, incorporating density peak clustering ）。最后，我们==提出了一个框架，用于自动合成给定对象的各种排列方式==——输入房间的几何形状，根据提取的前验值将输入对象划分为不相干的组，然后基于`Hausdorff metric`进行优化，以应对离散的前验值` discrete priors`。整个过程可以在几秒钟内完成。



## 2. Related Works

##### 3D Indoor Scene Synthesis

布局策略的表示在三维室内场景合成中扮演着重要的角色。例如：利用诸如左、右、前等语义建立对象之间的空间关系模型。采用高斯混合模型(GMMs)来拟合物体的观测分布；图结构；为对象建模上下文，如对象之间的平均角度和距离，朝向（比如：最近的墙），等等。然而，尽管有各种各样的代表，基本的度量仍然局限于共现、模型拟合甚至是直观的语义，例如，边的概率是通过共存的频率计算的。我们的目标是从现有的场景合成布局示例中学习成对物体排列的一般模式



##### Tests for Complete Spatial Randomness (CSR)

这是个经典的课题。给定一系列分布在平面上的点，CSR测试通常用来回答这些点被随机放置的可能性有多大。从形式上讲，它描述了一组事件产生w.r.t同质泊松过程（平面泊松过程）的可能性有多大。此前，CSR的应用大多局限于生态学[，例如，研究一组观察到的植物是否按照某个模式放置。Rosin可能是第一个将CSR的概念带入计算机视觉中——如何检测图像内部的白色噪声。CSR的典型测试方法包括使用Diggle函数、基于距离的方法等。在本文中，我们按照[2]的方法，通过角度来测试CSR（第4节）。

<img src="Fast 3D Indoor Scene Synthesis with Discrete and Exact Layout Pattern Extraction.assets/image-20201013212252321.png" alt="image-20201013212252321" style="zoom: 67%;" />



## 3. Overview