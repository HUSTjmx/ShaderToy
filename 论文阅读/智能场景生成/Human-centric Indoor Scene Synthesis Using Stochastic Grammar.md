# Human-centric Indoor Scene Synthesis Using Stochastic Grammar

### Abstract

本文提出了一种以人为中心的方法来生成三维场景。使用属性化的空间`And-Or Graph`来表示室内场景。==S-AOG==是一种概率文法模型`probabilistic grammar model`，其中终端节点是对象实体，包括房间、家具和受支持的对象。我们通过数据库学习分布` distributions`，然后使用马尔可夫链来生成新的场景（采样新的布局）。实验表明，基于以下三个标准，该方法可以稳健地对各种真实的房间布局进行采样：

+ 视觉逼真的方法与最先进的房间布置方法的比较
+  accuracy of the affordance maps with respect to ground-truth
+ 受试者评估下，房间的功能性和自然性。



## 1. Introduction

传统的2D/3D图像数据采集和`ground-truth`标注方法存在明显的局限性：

+ 获取高质量的`ground truths`是困难的
+ 有些信息无法正确的标注出来，比如：2D图像中3D物体的大小
+ 手工标注，工作庞大且乏味，还容易出错

因此，为了给模型提供高质量的数据，我们需要一个这样的方法。在本文中，我们提出了一种算法，以自动生成一个大规模的3D室内场景数据集，我们可以从这个数据集中，渲染出包含表面法线、深度和分割信息的、像素级的真实2D图像。本算法适用于，但不仅限于以下任务:

+ 各种计算机视觉任务的学习和推理
+ 为3D建模和游戏生成3D内容
+ 三维重建和机器人映射问题`robot mappings problems`
+ 机器人技术中低级和高级任务规划问题的基准测试

智能生成场景的四个挑战：

+ 在一组功能部件中，如一套餐具，其数量可能有所不同。（数量不确定）
+ 即使我们只考虑成对关系，对象-对象关系也已经是二次方。（关系多）
+ 更糟糕的是，大多数对象-对象关系都没有明显的意义。例如，即使钢笔和显示器都放在桌子上，也没有必要对它们之间的关系进行建模。（关系无意义）
+ 由于之前的困难，产生了过多的约束。许多约束包含循环，使得最终的布局很难抽样和优化。（抽样困难，难以优化）

为了解决这些挑战，我们提出了一种以人为中心的室内场景生成方法。它整合了人的活动` human activities`和功能性的*分组/支持*关系`functional grouping/supporting relations`。==这种方法不仅捕捉了人的语境，而且简化了场景结构==。具体地说，我们使用图像和场景的概率语法模型——S-AOG，包括垂直的层次结构和水平的上下文关系` contextual relations`。

上下文关系`contextual relations`对 分组和支持 进行编码，由`object affordances`建模。对于每一个对象，我们都会学习其`object affordances`的分布，即对象与人的关系，这样就可以根据该对象对人进行采样。除了静态的`object affordances`，我们还考虑了场景中人的动态活动，通过规划从一件家具到另一件家具的轨迹来约束布局（constraining the layout by planning trajectories from one piece of furniture to another.）

本文有三大贡献：

+ 将对象建模，负担能力和活动规划`activity planning`组合起来，来生成室内场景。
+ 提供了一个通用的学习和采样框架，用于室内场景建模。
+ 通过大量的对比实验证明了这种结构化联合采样的有效性。



###  1.1 Related Works

**3D content generation** is one of the largest communities in the game industry and we refer readers to a ==recent survey [13] and book== 。大部分三维场景重建算法通过使用给定的一组对象约束，来生成新的房间布局。具体的各种相关技术，见论文。

**Synthetic data**：合成数据已经吸引了越来越多的兴趣，来增强训练数据，甚至直接作为训练数据。

**Stochastic grammar model**：随机语法模型已经被用于==解析==室内和室外场景的图像，和涉及人类的图像的==层次结构==。在本文中，我们没有使用随机语法来进行解析，而是转发`forward`语法模型中的样本来生成大量不同的室内场景。



## 2. Representation of Indoor Scenes

我们使用参数化的S-AOG来表示场景。属性化的S-AOG是在终端节点上具有属性的概率语法模型，它包含：

+ ==一个概率性的上下文无关文法（PCFG）==
+ 马尔可夫随机场==(MRF)==上定义的上下文关系`contextual relations`，例如：节点之间的水平连接。

PCFG通过一组终端节点和非终端节点来表示：从场景(顶层)到对象(底层)的层次分解；而上下文关系通过水平链接对空间关系和功能关系进行编码。S-AOG结构如图所示：

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201102203201179.png" alt="image-20201102203201179" style="zoom:80%;" />

形式上，S-AOG被定义为一个5元组：$G=<S,V,R,P,E> $。我们使用符号S$\rightarrow$场景语法的根节点，V$\rightarrow$顶点集，R$\rightarrow$产生的规则`the production rules`，P$\rightarrow$定义在S-AOG上的概率模型，和E$\rightarrow$上下文关系，用来表示同一层节点的水平连接。

==顶点集V==可以分解为非终端节点和终端节点的有限集：$V = V_{NT}∪V_T$：

+ $V_{NT}=V^{And}\bigcup V^{Or}\bigcup V^{set}$。非终端节点由三部分组成。1，And-Nodes，其中，每个节点表示将一个较大的实体（如卧室）分解为较小的组件（如墙壁、家具和支撑对象）。2，Or-Nodes，其中每个节点分枝可选择性的分解（例如，一个室内场景可以是卧室或客厅），使算法能够重新配置一个场景。3，Set Nodes，一组Or节点作为子分支，由一个And节点分组，每个子分支可以包括不同数量的对象。
+ $V_T=V_T^a\bigcup V_T^r$。终端节点由两个子节点组成：常规节点和地址节点。1，常规节点表示场景中的带有属性的空间实体（例如：一把椅子），在本文中，属性包括：a.内部属性A~int~，物体大小(w,l,h)；b.外部属性A~ext~，物体位置(x,y,z)和朝向(x-y平面)$\theta$，以及采样到的人的位置A~h~。2，为了避免图过于稠密，增加了地址节点，编码那些只在特定上下文`context`出现的交互作用`interactions`。它是一个指向常规终端节点的指针，取集合$V_T^r∪\{nil\}$中的值，表示支持或分组关系，如图2所示。

==Contextual Relations== E：节点之间的上下文关系由S-AOG中的水平链接表示，形成终端节点上的MRF。为了对上下文关系进行编码，我们为不同的派系`clique`定义了不同类型的潜在函数。$E=E_f\bigcup E_o\bigcup E_g\bigcup E_r$，上下文关系分为四个子集：1，家具间的关系E~f~。2，支持物体与被支持物体间的关系E~o~。3，功能对之间的关系E~g~（例如：一个桌子和一把椅子）4，房间和家具间的关系E~R~ 。据此，终端层中形成的派系`clique`也可分为四个子集：$C=C_f\bigcup C_o\bigcup C_g\bigcup C_r$。Instead of directly capturing the object-object relations, we compute the potentials using affordances as a bridge to characterize the object-human-object relations（我们不直接捕捉物体间关系，而是以负担能力`affordancer`为桥梁来计算势能`potentials`，以表征物-人-物的关系。）

==层次解析树pt（hierarchical parse tree）通过为Or节点选择一个子节点以及为Set节点确定每个子节点的状态来实现SAOG的实例化==。一个解析图`pg`由一个解析树`pt`和解析树上的一些上下文关系E组成：pg=（pt，E~pt~）。图3展示了一个简单的解析图和终端层形成的四种类型的小团体的例子。

![image-20201103230507510](Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201103230507510.png)



## 3. Probabilistic Formulation of S-AOG

场景配置由一个解析图`pg`表示，包括场景中的对象和相关属性。$\theta$参数化的S-AOG产生的pg的先验概率被表述为吉布斯分布`Gibbs distribution`。

![image-20201103231047903](Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201103231047903.png)

其中，$\varepsilon(pg|\Theta)$是解析图的能量函，$\varepsilon(pt|\Theta)$是解析树的能量函数 ，$\varepsilon(E_{pt}|\Theta)$是上下文关系的能量函数。

$\varepsilon(pt|\Theta)$可进一步分解为不同类型的非终端节点的能量函数，以及规则终端节点和地址终端节点的内部属性的能量函数:arrow_down:。其中，Or节点的子节点和Set节点的子分支，这两者的选择遵循不同的多项分布。由于And节点展开明确，所以没有能量项。终端节点的内部属性遵循<u>核密度估计</u>`kernel density estimation`学习到的无参化概率分布`non-parametric probability distribution`

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201104213629004.png" alt="image-20201104213629004" style="zoom: 80%;" />

$\varepsilon(E_{pt}|\Theta)$结合了终端层形成的四种派系`cliques`的势能`potentials`，来整合常规终端节点的人属性`human attributes `和外部属性:

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201104215056399.png" alt="image-20201104215056399" style="zoom: 80%;" />

### Human Centric Potential Functions

- Potential function $\phi_f(c)$定义了家具间的关系，$c={f_i}\in C_f$包含了所有家具节点

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201104215522251.png" alt="image-20201104215522251" style="zoom:80%;" />

​		其中，$\lambda_f$是权重向量，<.,.>表示一个向量，成本函数$l_{col}(f_i,f_j)$代表两个家具的重叠面积，用来作为碰撞的惩罚。成本函数$l_{ent}(c)=-H(\Gamma)=\sum_{i}p(\gamma_i)\log p(\gamma_i)$，通过采样人体轨迹，可以更好地利用房间空间，$\Gamma$是房间中计划好的轨迹集合$H(\Gamma)$是熵` entropy`。通过使用<u>双向快速探索随机树</u>` bi-directional rapidly-exploring random tree`，来规划任意一个家具的中心到另一个家具的轨迹$\gamma_i$，我们可以获得<u>轨迹概率图</u>`trajectory probability map`——构成了				热度图`heatmap`。

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201104221301627.png" alt="image-20201104221301627" style="zoom:80%;" />

- Potential function $\phi_o(c)$定义了支持物体与被支持物体间的关系，每一个集合元素$c=\{f,a,0\}\in C_o$包含了：受支持的物体终端节点o，地址节点a ，以及它指向的家具终端节点f：

    <img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201104221928524.png" alt="image-20201104221928524" style="zoom:80%;" />

    其中，成本函数$l_{hum}$定义了`human usability cost`——一个好的人类位置应该允许一个代理去访问或使用家具和它支持的物体。$l_{hum}(f,o)=\max_ip(h_i^o|f)$，其中h~i~^o^是根据被支持对象的位置、方向和`affordance map`进行的第一次采样。

    成本函数$l_{add}(a)$是指地址节点v ，视作某一个遵循多项式分布的常规终端节点的负对数概率。

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201104223714864.png" alt="image-20201104223714864" style="zoom:67%;" />

- Potential function $\phi_g(c)$定义了家具之间的功能分组关系，任意一个元素$c=\{f_i,a,f_j\}\in C_g$，包括了：核心功能家具的终端节点f~i~，指向关联家具的地址节点a，以及关联节点。其计算方式类似上一个。

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201104224221732.png" alt="image-20201104224221732" style="zoom:80%;" />



### Other Potential Functions

- Potential function $\phi_r(c)$定义房间和家具间的关系，任意一个元素$c=\{f,r\}\in C_r$，包含了一个家具节点和一个房间节点

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201104224908601.png" alt="image-20201104224908601" style="zoom:80%;" />

​		其中，$l_{dis}(f,r)=-log(p(d|\Theta))$是距离成本函数。d的分布属于$\ln N(\mu,\sigma^2)$，是家具离最近的墙的距离modeled by a log normal distribution。$l_{ori}(f,r)=-\log p(\theta|\Theta)$是朝向成本函数，其中$\theta$是模型和最近的墙之间的朝向，==modeled by a von Mises distribution.==

![image-20201104225755381](Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201104225755381.png)



## 4. Learning S-AOG

我们使用SUNCG数据集作为训练数据。它包含了超过45K不同的场景和手工创建的逼真的房间和家具布局。我们收集房间类型、房间大小、家具出现情况、家具大小、家具和墙壁之间的朝向和相对距离、家具的可视性、分组出现情况和支持关系的统计数据。概率模型P的参数$\Theta$可以通过最大似然估计（MLE），以着监督的方式学习。

### Weights of Loss Functions

回想一下，在终端层中形成的派系的概率分布为：

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201105155709925.png" alt="image-20201105155709925" style="zoom: 80%;" />

其中，$\lambda$是权重向量，$l(E_{pt})$是四个不同的`potential functions`给出的损失向量。为了学习权值向量，标准MLE最大化<u>平均对数似然值</u>`the average log-likelihood`：

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201105160215087.png" alt="image-20201105160215087" style="zoom:80%;" />

This is usually maximized by following the gradient：

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201105160258511.png" alt="image-20201105160258511" style="zoom:80%;" />

其中，最终结果的右项是当前模型的一组生成示例。通常，在梯度上升的每一次迭代中，对一个均衡分布的马尔科夫链进行采样，在计算上是不可行的。因此，我们不需要等待马尔科夫链收敛，而是按照两个发散的差值梯度进行<u>对比发散</u>`contrastive divergence`（CD）学习

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201105161715754.png" alt="image-20201105161715754" style="zoom:80%;" />

其中，$$KL(p_0||p_{\infty})$$是数据分布p~0~与模型分布$p_{\infty}$之间的==Kullback-Leibler发散==，$p_{n^-}$是由数据分布开始的，并运行一小步n的马尔科夫链得到的分布。在本文中，我们设n=1。理论和经验证据都表明，在保持偏差非常小的情况下，这种方法是有效的。对比发散的梯度可计算如下：

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201105163016909.png" alt="image-20201105163016909" style="zoom:80%;" />

而经验表明，第三项可以忽略，因为它很小，很少反对其他两项的结果。最后，通过从马尔可夫链中生成少量的实例N~，然后通过梯度下降计算，来学习权重向量：

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201105163400537.png" alt="image-20201105163400537" style="zoom:80%;" />  						

### Branching Probabilities、Grouping Relations

or节点、set节点和地址终端节点的分支概率$\rho_i$的MLE就是每个备选选择的频率：

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201105163913054.png" alt="image-20201105163913054" style="zoom:80%;" />

分组关系是手工定义的(例如，床头柜与床相关联，椅子与桌子相关联)。以多项式分布的形式学习发生概率，并自动从SUNCG中提取支持关系。

### Room Size and Object Sizes、Affordances

房间大小和对象大小在所有家具和支持对象之间的分布被学习为非参数分布。首先从SUNCG数据集中的三维模型中提取尺寸信息，然后利用核密度估计`kernel density estimation`拟合非参数分布。家具和物体到最近的墙壁的距离和相对方向，分别被计算并装进一个正态对数`log normal`和一个冯米塞斯分布` von Mises distributions`的混合物中。

我们通过计算可能的人体位置的热图来学习所有家具和支持对象的`Affordance map`。这些位置包括带注释的人，我们假设椅子、沙发和床的中心是人们经常光顾的位置。通过累积相对位置，我们得到了合理的非参数分布`Affordance map`：

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201105164702803.png" alt="image-20201105164702803" style="zoom:67%;" />



## 5. Synthesizing Scene Configurations

从S-AOG定义的先验概率$p(pg|\Theta)$，对解析图pg进行采样，来配置生成场景。解析树的结构和对象的内部属性(大小)可以很容易地从封闭形式的分布或非参数分布中采样。但是，对象的外部属性(位置和方向)受多个<u>势函数</u>` potential functions`的约束，过于复杂，无法直接采样。在此，我们利用马尔可夫链蒙特卡洛（MCMC）采样器来绘制分布中的典型状态。每次抽样的过程可以分为两个主要步骤：

+ 直接对pt的结构和内部属性进行采样。(i)，对or节点的子节点进行采样；(ii)，确定set节点的每个子分支的状态；(iii)，对于每个常规终端节点，从已知分布中抽取大小和人员位置的样本。
+ 使用MCMC方案，通过建议（==by making proposal moves==.），对地址节点和外部属性Aex的值进行采样。在马尔科夫链收敛后，选择一个采样。

我们设计了两种简单的马尔科夫链`dynamics`，其中随机使用概率q~i~（i=1，2）来进行`make proposal moves`：

+ Dynamics q~1~：物体的移动。选择一个常规终端节点，然后根据当前的位置采样一个新的位置：$x\rightarrow x+\delta x$，$\delta x$服从二元正态分布。
+ Dynamics q~2~：物体的旋转。选择一个常规终端节点，然后根据当前的朝向采样一个新的朝向：$\theta\rightarrow \theta+\delta \theta$，$\delta \theta$服从二元正态分布。

采用`Metropolis-Hastings`算法，对提出的新解析图$p_g^`$按以下的接受概率接受：

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201105171746527.png" alt="image-20201105171746527" style="zoom:80%;" />

> where the proposal probability rate is canceled since the proposal moves are symmetric in probability. A simulated
>
> annealing scheme is adopted to obtain samples with high probability as shown in Figure 6

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201105171853639.png" alt="image-20201105171853639" style="zoom:80%;" />



## 6. Experiments

根据不同的标准设计了三个实验：

+ 与人工构建的场景在视觉上的相似性；
+ 合成场景的启示地图`affordance map`的准确性；
+ 合成场景的功能性和自然性。

第一个实验将我们的方法与最先进的房间布置方法进行了比较；第二个实验测量了合成功能；第三个是`ablation study`。总体而言，实验表明，我们的算法能够稳健地生成大量展现自然和功能性的真实场景。

### Layout Classification

为了定量评估视觉上的真实度，我们在合成场景和SUNCG场景的俯视分割图上训练了一个分类器。具体地说，我们训练ResNet-152来分类俯视分割图(合成vs SUNCG):arrow_down:。使用分割图的原因是：我们想要评估房间布局而不考虑渲染因素，比如物体材质。我们用两种方法进行比较：1，Yu等人提出的一种最先进的家具布置优化方法；2，通过在布局中添加小的高斯噪声，对SUNCG场景进行轻微的扰动。提出的房间布置算法取一个预先固定的输入房间，对房间进行重新整理。

每种方法和SUNCG随机选取1500个场景：800个用于训练，200个用于验证，500个用于测试。如表1所示，分类器成功区分Yu方法和SUNCG，其准确率为87.49%。我们的方法获得了较好的（76.18%）的性能，表现出更高的真实性和更大的多样性。

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201105172623296.png" alt="image-20201105172623296" style="zoom:80%;" />

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201105172653005.png" alt="image-20201105172653005" style="zoom:80%;" />

Yu等人与我们方法的定性比较如下图所示。上面：以前的方法只重新安排一个给定的输入场景与一个固定的房间大小和一组预定义的对象。下面：我们的方法对各种场景进行采样。

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201105173723725.png" alt="image-20201105173723725" style="zoom:80%;" />

### Affordance Maps Comparison

我们对表2中总结的10个不同场景类别的500个房间进行了采样。对于每一种类型的房间，我们计算生成样本中对象的功能可见图`affordance maps `，并计算从合成样本中、SUNCG数据集中计算出的`affordance maps` 之间的总变化距离和<u>海灵格距离</u>`Hellinger distances`。如果距离接近于 0，则这两个分布是相似的，大多数使用本方法的采样场景与 SUNCG 中手动创建的场景显示出相似的` affordance distributions`。

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201105174511312.png" alt="image-20201105174511312" style="zoom:80%;" />



### Functionality and naturalness

有三种方法可供比较：

+ 根据家具出现的统计数字直接采样房间，不增加上下文的关系.
+ 在我们的模型中去掉人的约束，只建立对象关系模型
+ Yu等人的算法

用三种方法向4名受试者展示了抽样的布局。受试者事先被告知房间类别，并被指示在不知道产生这些布局的方法的情况下对给定的场景布局进行评级。对于10个房间类别，使用我们的方法和[44]随机抽取24个样本，使用面向对象建模方法和随机生成方法抽取8个样本。受试者根据两项标准对布局进行评估：

+ 房间的功能，例如“卧室”能否满足人们日常生活的需要;
+ 布局的自然和现实性。

问卷的回答范围：1 - 5，5表示完美的功能或完美的自然和现实

<img src="Human-centric Indoor Scene Synthesis Using Stochastic Grammar.assets/image-20201105175141851.png" alt="image-20201105175141851" style="zoom:67%;" />

### Complexity of synthesis

由于采用MCMC采样，时间复杂度难以度量。根据经验，采样一个室内布局大约需要20-40分钟（MCMC 20000次迭代)，在普通PC上渲染640×480图像大约需要12-20分钟。渲染速度取决于与光照、环境和场景大小等相关的设置。







