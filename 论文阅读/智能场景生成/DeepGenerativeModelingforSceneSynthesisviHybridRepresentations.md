![](C:\Users\ZoroD\Desktop\IQ--master\论文阅读\智能场景生成\DeepGenerativeModelingforSceneSynthesisviHybridRepresentations.assets\1.PNG)

# Deep Generative Modeling for Scene Synthesis via Hybrid Representations （混合表示）

==我们的目标是使用前馈神经网络训练一个生成模型，该网络将先验分布（例如，正态分布）映射到室内场景中主要物体的分布==。我们在基准数据集上展示了我们的场景表示和网络训练方法的有效性。我们还展示了这个生成模型在场景插值和场景完成中的应用。

> We demonstrate the effectiveness of our scene representation and the network training method on benchmark datasets. We also show the applications of this generative model in scene interpolation and scene completion



## 1.  Introduction

​	在计算机图形学中，自动生成场景是一个长期存在的问题。传统的实现方法是聚焦于递归，从一个根物体开始，不断往场景中插入新物体（考虑空间约束），而最近流行使用神经网络model the recurrent synthesis procedure 。但这不是最好的解决方法，因为它们无法在低功耗的情况下对于新插入的物体进行适应，此外，这些方法并没有明确地建立一个映射，例如从潜参数空间（ latent parameter space ）到三维场景空间的映射，这使得它们不适合场景插值和场景外推等应用。

==这个神经网络的输入：根据先验分布对潜参数空间进行随机采样(对场景的低维编码)；输出：物体组合形成的3D场景==

​	挑战：包括对3D场景进行参数化，以编码3D场景的连续和离散变化；开发合适的神经网络和训练程序以捕捉多个对象之间的几何相关性；以及从无组织的3D场景中进行训练，这些场景并不明显具有一致的方向和标度。应对挑战的三个关键：==representations of 3D scenes==, network design and training（==2.本文的主要贡献==）, and joint learning of scene generators and poses of the scenes used for training the generator（==3.如何从无组织的场景集合中训练生成器==）

​	==将3D场景参数化成一个矩阵==，其中一列代表这个物体出现与否。如果出现，则指定其几何属性（==其他元素指定其位置、方向、大小和几何属性==）。基于这种矩阵编码，引入稀疏密集生成网络（a sparse dense generative network）来生成三维场景。这种网络设计有效地解决了全连接网络中存在的过拟合问题，同时保持了网络的表达能力。

<img src="C:\Users\ZoroD\Desktop\IQ--master\论文阅读\智能场景生成\DeepGenerativeModelingforSceneSynthesisviHybridRepresentations.assets\2.PNG" style="zoom:50%;" />

​	为了进一步提高生成的3D生成器的质量，==我们通过结合两个损失项来训练网络==：第一个是标准的基于矩阵的VAE-GAN  loss（基于对象排列）；第二个损失项将生成的场景投影到一个图像域中，并使用具有卷积层的鉴别器来捕获相邻物体之间的几何关系（基于图像）。

​	目前：使用SUNCG数据集将方法应用到客厅和卧室的生成中。客厅和卧室类别分别包含6401和8054个场景。对于每个类别，我们分别使用6,000和7,000个场景进行训练，剩下的场景作为测试。生成一个场景大约30ms。

> Our approach trains 3D scene generators in 1,001 minutes and1,198 minutes, respectively, using a desktop with 3.2GHZ CPU,64GB main memory, and a GTX 1080 GPU.  



## RELATED WORKS

​	建模具有显著几何、拓扑可变性的复杂对象是非常困难的。由于这个原因，许多物体场景的参数化模型(例如，家具形状和场景)不存在。从数据中学习参数模型是最近计算机视觉的一个研究热点：之前的研究对象都是人体和人脸，参数化模型知识简单的对数据库里的数据进行线性插值，明显不适用于室内场景这种场景。

​	现有的建立参数化三维模型的方法大多集中在三维形状上，而不是由多个物体组成的三维场景。而拓展它们到三维场景也是不容易的，比如：三维物体的生成要求方向的一致性，而三维场景需要方向的一定随机性。此外，场景的优化和模型的优化存在一定的互斥。

> Assembly-based geometric synthesis  （具体详见论文第三页，感觉没什么用就快速扫过去了）

​	从训练数据中学到的先验知识也可以用于三维场景的矫正。[Yu et al. 2011]提出了一个优化框架，将粗糙的对象排列转化为显著改进的对象排列。我们基于图像的鉴别器loss在概念上与这种方法相似，但是我们自动地从数据中学习这个loss。



## OVERVIEW

#### Problem Statement

​	==在这篇文章中，将一个场景表现为一组以有语义意义的方式排列在空间中的刚性物体，并且没有相互渗透==。我们假设每个对象属于预定义的一组对象类中的一个，并且每个类中的对象可以由形状描述符参数化（然后使用该描述符从形状数据库检索对象的3D几何图形）。

​	我们进一步假设物体停留在地面上并且正确垂直于地面，这样每个物体在场景中的位置可以通过xy平面(俯视图)调整方向、位置以及缩放来指定。（当然，数据库的数据不需要都这么严格，这个网络具有足够的健壮性）



#### Approach Overview

​	矩阵表示下，典型的策略是利用全连通层来设计生成网络。然而，这容易导致过拟合。我们提出了两个关键的创新。第一种方法是使用稀疏密集网络对三维场景进行编码，极大地提高了泛化性能。第二是将生成的三维场景投影到一个图像域，即垂直方向的地平面上，使用==具有卷积层的鉴别器（discriminator with convolution layers  ）==来捕获输入对象之间的细粒度空间相关性

​	最后，为了处理无组织的场景集合，我们为训练集中的每个场景引入了一个位姿变量，并执行交替最小化来优化场景位姿和3D场景生成器及相关变量(如鉴别器)。每个组件的设计和动机：

+ Object arrangement scene representation：虽然每个矩阵完全指定了一个3D场景，但这种表示不是唯一的。为了处理这种编码的非唯一性(即，打乱相同类别的列导致相同场景)，我们引入了潜在的排列变量，可以有效地排除这种排列变异性。
+ Scene generator ：我们将场景产生器设计为一个前馈网络，在场景的矩阵表示上有稀疏交叉层和全连通层。
+ Image-based module ：We leverage a CNN-based discriminator loss。我们将基于cnn的image-based discriminator loss加在场景俯视图上，然后将其反向传播到场景生成器，迫使它更准确地学习局部相关模式。
+ Joint scene alignment.（联合场景校准）：从无组织的场景集合中训练网络是困难的。每个场景都不可能完全按照规则来，此外，尽管对象可以按类分组，但同一个类中的对象没有规范的顺序。作者发现，首先aligning the input scenes  可以显著提高3D场景生成器的效果
+ Network training  ：我们通过优化一个目标函数来学习生成器，该函数结合了一个自动编码器loss和之前的两个loss。变量包括生成网络、两个鉴别器、每个场景的姿态(pose)以及每个三维场景中物体的顺序。为了便于优化，为场景引入了一个潜在变量，它描述了场景的底层配置（loss都在这个变量中）。



## APPROACH

#### Scene Representation

​	首先，假设有$n_c=30$个物体类别，每个类别取出$m_k=4$个物体，那么明显矩阵的维数等于物体的总数。我们假设每个类中的对象都可以用d维形状描述符唯一地标识，所有类都使用d常数，矩阵的列向量$v^o$描述了一个物体，除了存在，位置，方向，大小之外，从$v_9^0$到$v_{d+8}^o$是物体形状的描述符（使用的别人预训练好的网络的倒数第二层的输出）

​	==这种直观的3D场景编码的一个技术挑战是==，它不受M~k~列的排列的影响（同一类物体的顺序）。此外，每个物体的位置和方向依赖于每个场景的全局姿态。根据这个观察，我们在矩阵编码M上引入了两个算子。第一个==算子（operator）==将排列表k应用于每个类：(S独立地对每个类的对象应用排列)：个人感觉作用是给每个类的物体加上有序性

![](C:\Users\ZoroD\Desktop\IQ--master\论文阅读\智能场景生成\DeepGenerativeModelingforSceneSynthesisviHybridRepresentations.assets\公式1.PNG)

​	第二个算子给予每个物体一定的平移和旋转。我们通过为每个场景i引入一个潜伏矩阵编码$\overline{M_i}$∈R(d+9)×no来==因子化（factor out）==对象的排列组合和每个输入场景的全局姿态，下面描述的反编码器和discriminator  loss将施加在$\overline{M_i}$上，我们通过最小化下面的损失项来执行Mi和$\overline{M_i}$的一致性。

![](C:\Users\ZoroD\Desktop\IQ--master\论文阅读\智能场景生成\DeepGenerativeModelingforSceneSynthesisviHybridRepresentations.assets\公式2.PNG)



#### 3D Object Arrangement Module

​	作者网络的心脏是如下两个网络：

![](C:\Users\ZoroD\Desktop\IQ--master\论文阅读\智能场景生成\DeepGenerativeModelingforSceneSynthesisviHybridRepresentations.assets\公式3.PNG)

​	由于我们对3D场景的矩阵编码本质上是一种矢量化的表示(与基于图像的表示相反，行向量与列向量)，对于生成器（generator）网络和编码器（encode）网络，使用FC是很自然的。但是我们观察到，FC直连FC几乎不起作用，且容易对训练数据进行过拟合，从而导致生成的场景质量较差。如下图（FC，卷积层，SC，SC+Image-Based）

![](C:\Users\ZoroD\Desktop\IQ--master\论文阅读\智能场景生成\DeepGenerativeModelingforSceneSynthesisviHybridRepresentations.assets\show1.PNG)

此外，我们使用卷积层代替fc类型的层。但实验表明，这种方法不能学习成对的对象关系(参见上图第二列）。为了解决这个过拟合的问题，==使用稀疏连接的层==。每一层的每个节点连接到上一层的h个节点，在作者的实现中，设置h = 4，并将连接随机化，即每个节点独立连接上一层的一个节点，其连接概率为h/L，其中L为上一层节点的数量。如下图（编码器Net），网络在稀疏连接的层和完全连接的层之间交错。仍然保留一些完全连接的层，以使网络具有足够的表达能力来进行网络拟合。

![](C:\Users\ZoroD\Desktop\IQ--master\论文阅读\智能场景生成\DeepGenerativeModelingforSceneSynthesisviHybridRepresentations.assets\network1.PNG)

​	为什么使用稀疏层作为Decode Net，有两个原因：第一：3D场景中的模式通常涉及到小组对象，例如椅子和桌子，或者床头柜和床，因此期望对象类之间的稀疏关系；第二，避免过拟合。

遵循深度卷积生成对抗网络(DCGAN) ，作者将Decode循环的架构设置为与Encode循环的架构相反。使用VAE-GAN对编码器和解码器网络进行训练：

![](C:\Users\ZoroD\Desktop\IQ--master\论文阅读\智能场景生成\DeepGenerativeModelingforSceneSynthesisviHybridRepresentations.assets\公式4.PNG)

the latent distribution p是标准正态分布， and the discriminator Dϕ 和编码器网络有着相同的结构。



#### Image-based Module

​	正如在概述中所讨论的，我们介绍了基于图像的鉴别器，以更好地捕捉基于几何细节的物体的局部排列，例如在生成的场景中桌椅之间的空间关系和床头柜与床之间的空间关系。如之前图第三列所示，在==没有此模块的情况下，场景生成器出现了各种本地兼容性问题(例如，对象相互交叉）。==

​	鉴于CNN能够很好的捕捉邻近物体之间的局部交互模式，我们俯视场景来进行场景降维，然后在其上使用==CNN（卷积神经网络）==，

