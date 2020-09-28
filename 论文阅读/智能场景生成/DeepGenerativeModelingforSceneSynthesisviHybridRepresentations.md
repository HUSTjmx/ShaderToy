# Deep Generative Modeling for Scene Synthesis via Hybrid Representations （混合表示）

==我们的目标是使用前馈神经网络训练一个生成模型，该网络将先验分布（例如，正态分布）映射到室内场景中主要物体的分布==。我们在基准数据集上展示了我们的场景表示和网络训练方法的有效性。我们还展示了这个生成模型在场景插值和场景完成中的应用。

> We demonstrate the effectiveness of our scene representation and the network training method on benchmark datasets. We also show the applications of this generative model in scene interpolation and scene completion



## 1.  Introduction

在计算机图形学中，自动生成场景是一个长期存在的问题。传统的实现方法是聚焦于递归，从一个根物体开始，不断往场景中插入新物体（考虑空间约束），而最近流行使用神经网络model the recurrent synthesis procedure 。但这不是最好的解决方法，因为它们无法在低功耗的情况下对于新插入的物体进行适应，此外，这些方法并没有明确地建立一个映射，例如从潜参数空间（ latent parameter space ）到三维场景空间的映射，这使得它们不适合场景插值和场景外推等应用。

这个神经网络的输入：根据先验分布对潜参数空间进行随机采样；输出：物体组合形成的3D场景