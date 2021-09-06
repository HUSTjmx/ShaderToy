[toc]





# 1. Shaders and Vertex Data

在这篇文章中，我们将看看**着色器**和**顶点工厂**。Unreal使用一些魔法将**着色器的c++表示**绑定到一个**等价的HLSL类**，并使用**顶点工厂**来控制**上传到GPU的数据**。

我们将只关注核心的==Shader/Vertex Factory== 相关类。有很多与之相关的**结构/函数**，它们构成了支撑整个系统的胶水。你不太可能需要改变这些胶水，所以不谈论它们。

## 1.1 Shaders

**所有着色器派生类**的基类是==FShader==。虚幻有==2==个主要的着色器类别，**FGlobalShader**只有一个实例应该存在，而**FMaterialShader**绑定材料。`FShader`与`FShaderResource`配对，后者跟踪GPU上与那个**特定着色器**相关的资源。 如果来自`FShader`的编译输出与已经存在的`FShader`相匹配，一个`FShaderResource`可以在多个`FShader`之间共享。

### FGlobalShader

这个很简单，用途有限（但很有效！）。当一个**着色器类**派生自`FGlobalShader`时，将它们标记为**全局重编译组**的一部分（这似乎意味着它们在引擎打开时不会重新编译！）。全局着色器只存在一个实例，这意味着你不能有每个实例的参数。但是，可以有全局参数。举例来说。FLensDistortionUVGenerationShader FBaseGPUSkinCacheCS（一个用于计算网格蒙皮的计算着色器）。

### FMaterialShader and FMeshMaterialShader

现在，来看看更复杂的：**FMaterialShader**和**FMeshMaterialShader**。这两个类都允许多个实例，每个实例都与它自己的**GPU资源副本**相关。`FMaterialShader`增加了一个`SetParameters`函数，允许**着色器的C++代码**改变**绑定的HLSL参数的值**。参数绑定是通过`FShaderParameter/FShaderResourceParameter`类完成的，并且可以在着色器的构造器中完成，见`FSimpleElementPS`的例子。`SetParameters`函数在用该着色器渲染之前被调用，并传递了相当多的信息：包括材质。

现在我们知道了如何设置 **shader-wide parameters**，我们可以看看`FMeshMaterialShader`。这为我们增加了在绘图每个网格之前，在着色器中设置参数的能力。大量的着色器都源自这个类，**因为它是所有需要材质和顶点工厂参数的着色器的基类**（根据文件上的注释）。这只是添加了一个`SetMesh`函数，在用它绘制每个网格之前被调用，允许你在GPU上修改参数，以适应特定的网格。例如：`TDepthOnlyVS`, `TBasePassVS`, `TBasePassPS`.

### Binding C++ to HLSL

现在我们知道`FShader`是CPU上**着色器的C++表示**，我们需要知道如何将一个给定的`FShader`与它相应的`HLSL`代码联系起来。这就是我们的第一个**C++宏**的用处。`IMPLEMENT_MATERIAL_SHADER_TYPE（TemplatePrefix, ShaderClass, SourceFilename, FunctionName, Frequency）`。在解释每个参数之前，让我们看一下`DepthRendering.cpp`中的一个例子。

```c++
IMPLEMENT_MATERIAL_SHADER_TYPE(,FDepthOnlyPS,TEXT(“/Engine/Private/DepthOnlyPixelShader.usf”),TEXT(“Main”),SF_Pixel);
```

这个宏将C++类`FDepthOnlyPS`与位于`/Engine/Private/DepthOnlyPixelShader.usf`的`HLSL`代码绑定在一起。 具体来说，它与入口点 "Main "和**SF_Pixel的频率**相关。在我们的C++代码（`FDepthOnlyPS`）、它所存在的HLSL文件（`DepthOnlyPixelShader.usf`）以及该HLSL代码中要调用的函数（`Main`）之间有了关联。Unreal使用术语 ==Frequency== 来指定它是哪种类型的着色器——顶点、`Hull`、`Domain`、几何、像素或计算。

这个实现忽略了**第一个参数**。这是因为这个例子并不是一个**模板化的函数**。在某些情况下，宏会对一个模板类进行专业化处理，然后由另一个宏对模板类进行实例化，以创建特定的实现。这方面的一个例子是：为每个可能的照明类型创建一个变体。如果你很好奇，可以看看`BasePassRendering.cpp`顶部的`IMPLEMENT_BASEPASS_LIGHTMAPPED_SHADER_TYPE`宏。但我们会在Base Pass的文章中更深入地介绍它



## 1.2 Review

`FShader`的实现是**着色管道**中的特定阶段，并且可以在使用之前修改其HLSL代码里面的参数。虚幻使用一个宏来将C++代码绑定到HLSL代码上。从头开始实现一个着色器是非常简单的，但是将其集成到现有的**延迟基础渲染管道**中会比较复杂。



## 1.3 Caching and Compilation Environments

在我们继续之前有**两个重要的概念**要介绍。当您修改一个材质时，虚幻会自动为您编译一个着色器的诸多**变体**`permutation`。这是件好事，但是会导致过多的、未使用的着色器。这就引入了`ShouldCache`函数。

![img](https://miro.medium.com/max/1073/1*1wv6wXwxr4y5AdzshjbyvA.png)

只有当`Shader`、`Material`和`Vertex Factory`都同意该特定的`permutation`应该被缓存时，Unreal才会创建一个着色器的特定permutation。如果这些中的任何一个是假的，那么虚幻就会跳过创建一个 `permutation`，这意味着您将永远不会出现这种permutation可以被绑定的情况。例如：当我们不希望缓存**需要SM5支持的着色器**的时候，如为一个**不支持SM5的平台**开发，就没有理由去编译和缓存它。

`ShouldCache`函数是一个**静态函数**，可以在`FShader`、`FMaterial`或`FVertexFactory`类中实现。检查一下现有的使用情况，可以让你了解如何以及何时可以实现它。

第二个重要的概念是：在编译前，改变`HLSL`代码中的**预处理器定义**的能力。`FShader`使用`ModifyCompilationEnvironment`（通过宏实现的静态函数），`FMaterial`使用`SetupMaterialEnvironment`，`FVertexFactory`也使用`ModifyCompilationEnvironment`。这些函数在着色器被编译之前被调用，让你修改HLSL**预处理器的定义**。`FMaterial`广泛地使用这个函数，来设置与着色模型相关的定义，这些定义基于该材质的设置，以优化任何不必要的代码。

### FVertexFactory

现在我们知道了如何在着色器进入GPU之前对其进行修改，然后我们需要知道如何在第一时间将数据传送到`GPU`上。一个**顶点工厂**封装了一个**顶点数据源**，并可以与**顶点着色器**相连接。虚幻使用的是一个顶点工厂，它可以让您只上传您实际需要的数据到**顶点缓冲区**。

为了理解顶点工厂，我们应该了解两个具体的例子。`FLocalVertexFactory`和`FGPUBaseSkinVertexFactory`。`FLocalVertexFactory`在很多地方被使用，因为它提供了一种简单的方法来将**显式顶点属性**从**本地空间**转换到**世界空间**（静态网格使用，以及`cables`和`procedural meshes`）。另一方面，骨骼网格（需要更多的数据）使用`FGPUBaseSkinVertexFactory`。再往下看，我们看看**与这两个顶点工厂相匹配的着色器数据**是如何在其中包含不同数据的。

### FPrimitiveSceneProxy

那么，虚幻如何知道对一个**网格**使用哪个**顶点工厂**呢？通过`FPrimitiveSceneProxy`类：`FPrimitiveSceneProxy`是`UPrimitiveComponent`的渲染线程版本`render thread version`。我们打算让您对`UPrimitiveComponent`和`FPrimitiveSceneProxy`进行子类化，并创建特定的实现。

![image-20210513192853312](UE4渲染管道理解——Matt.assets\image-20210513192853312.png)

退一步讲，虚幻有一个**游戏线程**和一个**渲染线程**，它们不应该接触属于其他线程的数据（除了通过一些**特定的同步宏**）。为了解决这个问题，虚幻为**游戏线程**使用了`UPrimitiveComponent`，它通过覆盖`CreateSceneProxy()`函数来决定创建哪个`FPrimitiveSceneProxy`类。然后，`FPrimitiveSceneProxy`可以查询游戏线程（在适当的时候），以便从**游戏线程**中获取数据到**渲染线程**中，这样它就可以被处理，并放在GPU上。

**这两个类经常成对出现**，这里有两个很好的例子：`UCableComponent/FCableSceneProxy`，以及`UImagePlateFrustrumComponent/ImagePlateFrustrumSceneProxy`。在`FCableSceneProxy`中，渲染线程查看`UCableComponent`中的数据并建立一个新的网格（计算位置、颜色等），然后与先前的`FLocalVertexFactory`关联。`UImagePlateFrustrumComponent`很聪明，因为它根本就没有顶点工厂！它只是使用了`FLocalVertexFactory`的回调。它只是使用**渲染线程的回调**来计算一些数据，然后用这些数据来画线。没有与之相关的**着色器或顶点工厂**，它只是使**用GPU的回调**来调用一些**即时模式风格的渲染函数**。

### Binding C++ to HLSL

到目前为止，我们已经涵盖了**不同类型的顶点数据**，以及**场景中的组件**如何创建和存储这些数据（**通过具有顶点工厂的场景代理**）。现在我们需要知道如何在GPU上使用独特的顶点数据，特别是考虑到`basepass`只有一个顶点函数，**它必须处理所有不同类型的传入数据**。如果你猜到答案是 "==另一个C++宏=="，那你就对了。

```cc
IMPLEMENT_VERTEX_FACTORY_TYPE(FactoryClass, ShaderFilename, bUsedWithmaterials, bSupportsStaticLighting, bSupportsDynamicLighting, bPrecisePrevWorldPos, bSupportsPositionOnly)
```

这个宏让我们把**顶点工厂的C++表示**绑定到一个**特定的HLSL文件**。一个例子是：

```cc
MPLEMENT_VERTEX_FACTORY_TYPE(FLocalVertexFactory,”/Engine/Private/LocalVertexFactory.ush”,true,true,true,true,true);
```

现在你会注意到一些有趣的事情，这里没有指定任何入口点（该文件中也不存在任何入口点）！我认为这实际上是一种很好的工作方式（虽然学习起来很困惑）。虚幻根据**所使用的顶点工厂**改变了**数据结构的内容和函数调用**while all while reusing the same name so common code works。

我们来看看一个例子。`BasePass`顶点着色器接受一个`FVertexFactoryInput`作为输入。这个数据结构被定义在`LocalVertexFactory.ush`中，具有特定的意义。然而，`GpuSkinVertexFactory.ush`也定义了这个结构!：然后，根据哪个头文件被包含，提供给顶点着色器的数据就会改变。这种模式在其他领域也有重复，并将在Shader Architecture文章中更深入地介绍。

```cc
// Entry point for the base pass vertex shader. We can see that it takes a generic FVertexFactoryInput struct and outputs a generic FBasePassVSOutput.
void Main(FVertexFactoryInput Input, out FBasePassVSOutput Output)
{
    // This is where the Vertex Shader would calculate things based on the Input and store them in the Output.
}
// LocalVertexFactory.ush implements the FVertexFactoryInput struct
struct FVertexFactoryInput
{
    float4 Position : ATTRIBUTE0;
    float3 TangentX : ATTRIBUTE1;
    float4 TangentZ : ATTRIBUTE2;
    
    float4 Color : ATTRIBUTE3;
    // etc…
}
// GpuSkinVertexFactory.ush also implements the FVertexFactoryInput struct
struct FVertexFactoryInput
{
    float4 Position : ATTRIBUTE0;
    half3 TangentX : ATTRIBUTE1;
    half4 TangentZ : ATTRIBUTE2;
    uint4 BlendIndices : ATTRIBUTE3;
    uint4 BlendIndicesExtra : ATTRIBUTE14;
    // etc…
}
```

## 1.4 Review

`IMPLEMENT_MATERIAL_SHADER_TYPE`宏定义了你的**着色器的入口点**，但**顶点工厂**决定了被传递到该顶点着色器的数据。着色器使用非特定的变量名（如`FVertexFactoryInput`），这些变量对不同的顶点工厂有不同的含义。`UPrimitiveComponent/FPrimitiveSceneProxy`一起工作，从你的场景中获取数据，并以**特定的数据布局**传送到`GPU`上。

## 1.5 A Footnote About Shader Pipelines

虚幻有一个 "==shader pipeline== "的概念，它在一个管道中一起处理**多个着色器**（顶点、像素），因此它可以查看**输入/输出**并将其优化。它们在引擎中被用于三个地方。`DepthRendering`，`MobileTranslucentRendering`，和`VelocityRendering`。我对它们的理解还不够深刻，所以无法写出大量的内容，但如果你正在处理这三个系统中的任何一个，并且你在阶段之间遇到了语义被优化的问题，那么就可以调查`IMPLEMENT_SHADERPIPELINE_TYPE_*`。



# 2. Drawing Policies

在这篇博文中，我们将介绍如何绘制**策略**、绘制**策略工厂**以及它们如何与我们目前所了解的所有系统交互。我们也快速看看：是什么让虚幻绘制一个网格。

## 2.1 Drawing Policies

虚幻中的**绘制策略**与其说是一个具体的类，不如说是一个概念，因为它们并不都共享同一个**基类**。从概念上讲，**绘制策略**决定了使用哪些**着色器变体**来绘制某些东西，**但是它并不选择绘制什么或何时绘制**。我们将看一下两个绘制策略，一个是用于**深度预处理**的策略，另一个是用于虚幻的`base pass`的策略，后者明显要复杂得多。

![image-20210513200415484](C:\Users\xueyaojiang\Desktop\JMX_Update\UE4渲染管道理解——Matt.assets\image-20210513200415484.png)

### FDepthDrawingPolicy

==深度绘制策略==是一个很好的例子，说明**绘制策略**可以很简单。在它的构造函数中，它要求**材质**为**特定的顶点工厂**找到一个**特定类型的着色器**。

```c++
VertexShader = InMaterial.GetShader<TDepthOnlyVS<false>>(VertexFactory->GetType());
```

`TDepthOnlyVS`是`FMeshMaterialShader`的一个实现，并且使用**适当的宏**来声明自己是一个着色器。虚幻试图编译所有可能的==材质/着色器/顶点工厂==的排列组合，所以它应该能够找到这个。如果您的`ShouldCache`函数设置得不正确，那么引擎会抛出一个断言并你修复它。

然后，它会查看要**绘制的材质**，以确定该材质是否启用了`tessellation`，如果启用了，那么**深度绘制策略**会寻找一个`Hull`和`domain`着色器。

```c
HullShader = InMaterial.GetShader<FDepthOnlyHS>(VertexFactory->GetType());
DomainShader = InMaterial.GetShader<FDepthOnlyDS>(VertexFactory->GetType());
```

==绘制策略==也有能力通过`SetSharedState`和`SetMeshRenderState`函数来设置**着色器的参数**，尽管它们通常只是将这些参数传递给**当前绑定的着色器**。

### FBasePassDrawingPolicy

这里是宏和模板开始棘手的地方。考虑一下**延迟渲染**中的`basepass`。你有很多不同的材质，使用不同的硬件特性（比如`tessellation`），使用不同的顶点工厂，而且你需要针对**光线的变化**。这是一个巨大的排列组合，而虚幻使用了几个宏来实现这一点。如果这不是很有意义的话，不要担心这个问题。这对进行修改并不太重要，只要意识到它的存在就行了。

他们做的第一件事是做了一个`FBasePassDrawingPolicy`模板：

```cc
<typename LightMapPolicyType> class TBasePassDrawingPolicy : public FBasePassDrawingPolicy
```

**构造函数**只是调用另一个模板函数。这又调用了另一个模板函数，但这次是为**每个照明类型**提供了一个特定的枚举。

现在知道了要为哪个**照明策略**获取着色器，他们使用了与**深度绘图策略**相同的`InMaterial.GetShader`函数，但这次他们得到的是一个着色器类，而这个类是模板化的。

```c++
VertexShader = InMaterial.GetShader<TBasePassVS<TUniformLightMapPolicy<Policy>, false> >(VertexFactoryType);
```

欢迎你一路跟着**模板链**走，但是重要的是要知道`Unreal`是如何知道所有可能的实现的。这个问题的答案是几个**嵌套的宏**! 跳到`BasePassRendering.cpp`的顶部，我们将从上到下看一下它们。

第一个宏是`IMPLEMENT_BASEPASS_VERTEXSHADER_TYPE`，它通过创建新的类型定义，为给定的`LightMapPolicyType`和`LightMapPolicyName`注册顶点、`hull`和`domain`材质着色器（使用我们在着色器一节中谈到的`IMPLEMENT_MATERIAL_SHADER_TYPE`宏）。所以现在我们知道，调用`IMPLEMENT_BASEPASS_VERTEXSHADER_TYPE`可以为我们注册顶点着色器。

第二个宏是`IMPLEMENT_BASEPASS_LIGHTMAPPED_SHADER_TYPE`，它接收`LightMapPolicyType`和`LightMapPolicyName`并调用`IMPLEMENT_BASEPASS_VERTEXSHADER_TYPE`和`IMPLEMENT_BASEPASS_PIXELSHADER_TYPE`（我们没有谈到，但工作方式与前者相同）。因此，这个宏可以让我们为任何给定的`LightMap`创建一个==完整的着色器链==（顶点和像素）。最后，Unreal调用了这个宏`16`次，传入了`LightMapPolicyTypes`和`LightMapPolicyNames`的不同组合。

在前面调用`InMaterial.GetShader<...>`函数的过程中，其中一个函数对每个`LightMapPolicyType`都有一个大的**开关语句**来返回正确的类型。所以我们知道虚幻为我们声明了所有的变化，所以`GetShader`能够得到正确的东西！。



## 2.2 Drawing Policy Factory

**绘制策略**会**找出**对给定的材质和顶点工厂使用的**特定着色器**，这使得虚幻可以创建诸如 "获得只有深度的着色器 "或 "获得具有点灯代码的着色器 "的策略。但是，是什么创建了一个绘制策略，它是如何知道要做哪个策略的？它又如何知道要画什么呢？这就是==绘制策略工厂==的作用。它检查**材质**或**顶点工厂**的状态，然后可以创建正确的绘制策略。

### FDepthDrawingPolicyFactory

我们将使用`FDepthDrawingPolicyFactory`作为一个（相对）简单的例子。这里只有三个函数，`AddStaticMesh`、`DrawDynamicMesh`和`DrawStaticMesh`。当`AddStaticMesh`被调用时，`Policy Factory`会查看关于要绘制的材质和`asset`的设置，并确定要创建的**适当的绘制策略**。然后，虚幻将该**绘制策略**放入即将被绘制的`FScene`的一个列表中。

例如，`FDepthDrawingPolicyFactory`会查看材质，看它是否修改了**网格位置**。如果它修改了网格位置，它就会创建一个`FDepthDrawingPolicy`并将其添加到`FScene`的 "==MaskedDepthDrawList== "中。如果材质没有修改网格位置，那么它就会创建一个`FPositionOnlyDepthDrawingPolicy`并将其添加到FScene中的另一个列表中。

![image-20210514101050356](C:\Users\xueyaojiang\Desktop\JMX_Update\UE4渲染管道理解——Matt.assets\image-20210514101050356.png)

`FDepthDrawingPolicyFactory`也有能力绘制一个给定的`mesh batch`，它再次检查设置并创建一个绘制策略。然而，它不是将其添加到一个列表中，而是通过`RHI层`为GPU设置状态，然后调用**另一个绘制策略**来实际绘制网格。



## 2.3 Telling the the Drawing Policy Factory to Draw

最后，我们学习这个问题的根源，看看所有这些部分如何发挥作用。还记得没有**绘制策略**或**绘制策略工厂**的共享基类吗？我们已经达到了这样一个点，即代码只是明确地知道它们，并在不同的时间调用它们。

### FStaticMesh::AddToDrawLists

我们的`FDepthDrawingPolicyFactory`有一个叫`AddStaticMesh`的函数，所以创建它的类与静态网格有关也就不足为奇了。当`AddToDrawLists`被调用时，它检查`asset`和**项目设置**以决定如何处理它。它做的第一件事是调用`FHitProxyDrawingPolicyFactory::AddStaticMesh`，然后是`FShadowDepthDrawingPolicyFactory::AddStaticMesh`，然后是`FDepthDrawingPolicyFactory::AddStaticMesh`，最后是`FBasePassOpaqueDrawingPolicyFactory::AddStaticMesh`和`FVelocityDrawingPolicyFactory::AddStaticMesh`！。

所以当`FStaticMesh`被标记为**添加到绘制列表**时，它会创建**各种各样的绘制策略工厂**（然后由它们创建**绘制策略**，并添加到正确的列表中）。这个函数被调用的具体细节并不可怕（见`FPrimitiveSceneInfo::AddStaticMeshe`，并从那里往上看），但我们知道在`base pass`之前，必须告诉`depth pass`要绘制什么。

进入`FDeferredShadingRenderer`，一个巨大的类，让一切以正确的顺序绘制。`FDeferredShadingRenderer::Render`启动了整个过程，并控制渲染操作的顺序。我们来看看`base pass drawing policy factory`；**Render函数**调用`FDeferredShadingSceneRenderer::RenderBasePass`，后者又调用`FDeferredShadingSceneRenderer::RenderBasePassView`，后者调用`FDeferredShadingSceneRenderer::RenderBasePassDynamicData`，最后循环调用我们的`FBasePassOpaqueDrawingPolicyFactory:: DrawDynamicMesh`，每次传给它一个不同的网格。

### Review

**绘制策略**为给定的材质、顶点工厂和着色器组合找到正确的`shader permutation`。开发者根据策略指定着色器类型，以完成不同的事情。**绘制策略工厂**负责创建**绘制策略**，并将其添加到适当的列表中。最后，通过一长串的继承关系，`FDeferredShadingRenderer::Render`最终在各种列表中循环，并调用其`Draw函数`。



## 2.4 Next Post

我们已经走到了C++方面的尽头！我们已经涵盖了大量的信息，希望能让你很好地了解这些部分是如何连接在一起的。我们学习了场景如何创建可绘制的数据（UPrimitiveComponent），这些数据如何到达**渲染线程**（FPrimitiveSceneProxy），以及**渲染线程**如何将数据以**正确的格式**传送到GPU上（`FVertexFactory`）。然后，我们学习了**绘制策略**如何根据开发者的意图找到正确的着色器，以及**绘图策略工厂**如何抽象出具有多种类型的绘制策略的细节，然后我们快速查看了这些绘制策略工厂的调用方式。

在下一篇文章中，我们将转向`GPU`方面！我们将看看**着色器的架构**，主要集中在==延迟着色渲染器==。



# 3. The Deferred Shading Pipeline

## 3.1  The Deferred Shading Base Pass

在第三部分中，我们完成了对C++方面的研究。我们将更深入地研究**顶点工厂**如何控制输入到普通`base pass`的**顶点着色器代码**，以及如何处理`tessellation `（包括其额外的`Hull`和`Domain`阶段）。在我们了解了这些部分是如何组合在一起的之后，我们将通过**延迟pass**。

![image-20210514103225787](C:\Users\xueyaojiang\Desktop\JMX_Update\UE4渲染管道理解——Matt.assets\image-20210514103225787.png)



## 3.2  A Second Look at Vertex Factories

在第2部分中，我们简单地讨论了**顶点工厂**如何改变**被送入顶点着色器的数据**。虚幻公司最终做出了一个聪明的决定，用学习的复杂性来减少代码的重复性。我们将在例子中使用`LocalVertexFactory.ush`和`BasePassVertexCommon.ush`，并将`GpuSkinVertexFactory.ush`作为比较对象，因为它们都使用**相同的顶点着色器**。

### Changing Input Data

不同类型的网格最终将需要**不同的数据**来完成它们的工作，即：**GPU蒙皮的点阵**比简单的静态网格需要更多的数据。虚幻在CPU方面用`FVertexFactory`来处理这些差异，但是在GPU方面就比较麻烦了。因为**所有的顶点工厂都共享相同的顶点着色器**（至少对于`base pass`来说），它们使用一个通用的输入结构`FVertexFactoryInput`。

因为虚幻公司使用了相同的顶点着色器，但是在每个**顶点工厂**中包含了不同的代码，虚幻公司在每个**顶点工厂**中重新定义了`FVertexFactoryInput`结构。这个结构在`GpuSkinVertexFactory.ush`、`LandscapeVertexFactory.ush`、`LocalVertexFactory.ush`和其他几个文件中都是唯一定义的。显然，包括所有这些文件是行不通的——相反，`BasePassVertexCommon.ush`包括`/Engine/Generated/VertexFactory.ush`。当着色器被编译时，这将被设置为**正确的顶点工厂**，从而使**引擎**知道要使用哪种`FVertexFactoryInput`的实现。我们在第二部分简要地谈到了使用**宏**来声明顶点工厂，你必须提供一个着色器文件——这就是原因。

所以现在我们的**基本通道顶点着色器**的数据输入与我们正在上传的顶点**数据类型相匹配**。下一个问题是，不同的顶点工厂将需要在`VS`和`PS`之间插值不同的数据。同样，`BasePassVertexShader.usf`调用了通用函数 ——`GetVertexFactoryIntermediates`, `VertexFactoryGetWorldPosition`，`GetMaterialVertexParameters`。如果我们在Files中再做一次查找，我们会发现每个==*VertexFactory.ush==都根据自己的需要定义了这些函数。

### Changing Output Data

现在需要看看：如何从**顶点着色器**获得数据到**像素着色器**。不出所料，`BasePassVertexShader.usf`的输出是另一个通用的结构（==FBasePassVSOutput==），它的实现依赖于顶点工厂。不过这里有一个小问题——如果你启用了`Tessellation`，在`Vertex shader`和`Pixel shader`之间有两个阶段（`Hull`和`Domain`阶段），而**这些阶段需要的数据**与**VS到PS的数据**不同。

==UE==使用`#define`来改变`FBasePassVSOutput`的含义，它既可以定义为简单的`FBasePassVSToPS`结构，也可以定义为用于`Tessellation`的`FBasePassVSToDS`（这段代码可以在`BasePassVertexCommon.ush`中找到）。这两个结构的内容几乎相同，只是`domain`着色器版本增加了一些额外的变量。

现在，那些独特的**每顶点工厂插值**又是怎么回事呢？`Unreal`通过创建`FVertexFactoryInterpolantsVSToPS`和`FBasePassInterpolantsVSToPS`作为`FBasePassVSOutput`的成员来解决这个问题。`FVertexFactoryInterpolantsVSToPS`定义在每个`*VertexFactory.ush`文件中，这意味着我们仍然在阶段之间传递正确的数据，即使我们在中间添加一个`Hull/Domain`阶段。`FBasePassInterpolantsVSToPS`没有被重新定义，因为存储在这个结构中的东西并不依赖于**任何特定的顶点工厂所特有的东西**，它持有像`VertexFog`值、`AmbientLightingVector`等。

虚幻的==重定义技术==抽象化了`base pass vertex shader`中的大部分差异，允许使用通用的代码，而不考虑`tessellation`或特定的顶点工厂。

## 3.3 Base Pass Vertex Shader

`BasePassVertexShader.usf`最终是非常简单的。在大多数情况下，顶点着色器只是简单地计算和分配`BasePassInterpolants`和`VertexFactoryInterpolants`，尽管这些值是如何计算的，变得有点复杂——有很多特殊情况，他们选择只在某些预处理器定义下，声明某些插值器，然后只在匹配的定义下分配这些插值。

例如，在顶点着色器的底部，我们可以看到一个定义`#if WRITES_VELOCITY_TO_GBUFFER`，它通过计算上一帧和这一帧的**位置差**来计算每个顶点的速度。一旦计算出来，它就会存储在`BasePassInterpolants`变量中，但是如果你看那边，他们已经把这个**变量的声明**包装在一个匹配的`#if WRITES_VELOCITY_TO_GBUFFER`中。这意味着只有将速度写入`GBuffer`的**着色器变体**才会计算它——这有助于减少阶段间传递的数据量，这意味着更少的带宽，从而导致更快的着色器。

![image-20210514143628050](C:\Users\xueyaojiang\Desktop\JMX_Update\UE4渲染管道理解——Matt.assets\image-20210514143628050.png)



## 3.4 Base Pass Pixel Shader

### Material Graph to HLSL

当我们在虚幻中创建一个材质图时，虚幻将您的节点网络翻译成`HLSL`代码。该代码被编译器插入到HLSL着色器中。如果我们看一下`MaterialTemplate.ush`，它包含了许多没有主体的`structures`（像`FPixelMaterialInputs`）——它们只是有一个`%s`。虚幻将其作为一种字符串格式，并将其替换为材质图的特定代码。                                                                                                                                 

这种文本替换并不仅仅限于`structures`，`MaterialTemplate.ush`还包括几个没有实现的函数。例如，`half3 GetMaterialCustomData0`，`half3 GetMaterialBaseColor`，`half3 GetMaterialNormal`都是不同的函数，它们的内容是根据你的材质`graph`填写的。这使得你可以从像素着色器中调用这些函数，并知道它将执行你在**材质图表**中创建的计算，并将返回结果值。 

![image-20210514151208827](C:\Users\xueyaojiang\Desktop\JMX_Update\UE4渲染管道理解——Matt.assets\image-20210514151208827.png)

### The “Primitive” Variable

在整个代码中，你会发现对一个名为 "==Primitive== "的变量的引用——在着色器文件中搜索它，却没有得到任何声明！这是因为它实际上是通过一些宏在`C++`端声明的。这个宏声明了一个结构，渲染器在GPU上**绘制每个基元之前**会对其进行设置。

它所支持的变量的完整列表可以在`PrimitiveUniformShaderParameters.h`中从**顶部的宏**中找到。默认情况下，它包括像`LocalToWorld`、`WorldToLocal`、`ObjectWorldPositionAndRadius`、`LightingChannelMask`等内容。

### Creating the GBuffer

==延迟着色==使用了 "GBuffer"（Geometry Buffer）的概念，它是一系列的`render targets`，这些目标存储了关于几何体的不同信息，例如世界法线、基色、粗糙度等。当计算光照时，虚幻对这些缓冲区进行采样以确定最终的着色。不过在它到达那里之前，虚幻经过了几个步骤来创建和填充它。

`GBuffer`的确切内容可以不同，**通道的数量**和用途可以根据项目设置而改变。一个常见的例子是一个`5`个纹理的`GBuffer`，从A到E。`GBufferA.rgb` = World Normal，用`PerObjectGBufferData`填充alpha通道。`GBufferB.rgba` = Metallic, Specular, Roughness, ShadingModelID。`GBufferC.rgb`是基础颜色，由`GBufferAO`填充alpha通道。`GBufferD`是专门用于自定义数据的，`GBufferE`是用于**预计算的阴影因子**。

在`BasePassPixelShader.usf`中，`FPixelShaderInOut_MainPS函数`作为像素着色器的==入口点==。由于有大量的**预处理器定义**，这个函数看起来相当复杂，但是它主要是由**模板代码**组成的。虚幻使用了几种不同的方法来计算`GBuffer`的所需数据，这取决于启用了什么**光照模型**和**功能**。除非需要改变其中的一些模板代码，否则**第一个重要的函数**是在中间位置，在那里着色器获得BaseColor、Metallic、Specular、MaterialAO和Roughness的值。它通过调用`MaterialTemplate.ush`中声明的函数来实现，它们的实现由你的`material graph`定义。

![image-20210514152022455](C:\Users\xueyaojiang\Desktop\JMX_Update\UE4渲染管道理解——Matt.assets\image-20210514152022455.png)

现在我们已经对一些数据通道进行了采样，虚幻要为**某些着色模型**修改其中的**一些数据通道**。例如，如果使用的是==次表面散射模型==（Subsurface, Subsurface Profile, Preintegrated Skin, two sided foliage or cloth)，那么虚幻将根据对`GetMaterialSubsurfaceData`的调用计算出一个**次表面颜色**。如果照明模型不是这些之一，它就会使用默认值`0`。

在计算了`Subsurface Color`之后，如果在工程中启用了`DBuffer Decals`，那么`Unreal`允许`DBuffer Decals`修改`GBuffer`的结果。在做了一些数学运算之后，虚幻将DBufferData应用于BaseColor、Metallic、Specular、Roughness、Normal和Subsurface Color通道。

在允许DBuffer Decals修改数据之后，Unreal计算了不透明度（使用`material graph`的结果）并进行了一些**体积光照贴图**的计算。最后，它创建了`FGBufferData`结构，并将所有这些数据打包到其中，每个`FGBufferData`实例代表一个**像素**。



### Setting the GBuffer Shading Model

虚幻的下一件事是让每个**着色模型**按照它认为合适的方式修改`GBuffer`。为了实现这一点，虚幻在`ShadingModelMaterials.ush`里面有一个叫做`SetGBufferForShadingModel`的函数。该函数接收我们的不透明度、基色、金属、镜面、粗糙度和次表面数据，并允许每个**着色模型**以它所希望的方式将数据分配到`GBuffer`结构中。

**大多数着色模型只是简单地分配传入的数据而不做任何修改**，但某些着色模型（比如与`Subsurface`相关的）会使用**自定义数据通道**，将额外的数据编码到`GBuffer`中。这个函数的另一个重要作用是将`ShadingModelID`写到`GBuffer`中。这是一个存储在每个像素上的整数值，可以让==延迟pass==查找每个像素应该使用什么**渲染模型**。

这里需要注意的是，如果你想使用`GBuffer`的`CustomData`通道，你需要修改`BasePassCommon.ush`，它有一个`WRITES_CUSTOMDATA_TO_GBUFFER`的**预处理器定义**。如果你试图使用GBuffer的CustomData部分，而不确保你的**渲染模型**被添加到这里，它将被丢弃，你以后将不会得到任何数值。

### Using the Data

现在我们已经让每个照明模型选择**如何将数据写入FGBufferData结构**中，`BasePassPixelShader`将进行相当多的模板代码和内部管理——计算每个像素的速度、进行次表面颜色的改变、覆盖ForceFullyRough的粗糙度等等。

在这些模板代码之后，虚幻将获得**预先计算的间接照明**和`sky light`数据（`GetPrecomputedIndirectLightingAndSkyLight`）并将其添加到GBuffer的`DiffuseColor`中。有相当多的代码与**半透明的正向着色**、**顶点雾化**和调试有关，我们最终来到了`FGBufferData`结构的末尾。Unreal调用了`EncodeGBuffer`（DeferredShadingCommon.ush），它接收了FGBufferData结构并将其写入了各种`GBuffer纹理(A-E)`中。

这就结束了`Base Pass Pixel Shader`的大部分内容。

### Review

`BasePassPixelShader`负责通过调用`material graph`生成的函数，对各种**PBR数据通道**进行采样。这些数据被打包到`FGBufferData`中，然后被传递给各种函数，这些函数根据不同的**渲染模型**来修改数据。渲染模型由被写入纹理的`ShadingModelID`决定。最后，`FGBufferData`中的数据被编码为多个`render target`，供以后使用。



## 3.5 Deferred Light Pixel Shader

我们接下来要看的是`DeferredLightPixelShaders.usf`，因为这是计算每个光对像素的影响的地方。为了做到这一点，虚幻使用了一个简单的顶点着色器来绘制**与每个灯光的可能影响相匹配的**几何图形，即：对于**点光源**是一个球体，对于聚光灯是一个圆锥体。这就在**像素着色器需要运行的像素**上创建了一个**掩码**，这使得填充较少像素的灯光更便宜。

### Shadowed and Unshadowed Lights

虚幻在多个阶段中绘制照明。首先绘制**不产生阴影的灯光**，然后再绘制**间接照明**。最后，虚幻绘制出所有**投射阴影的灯光**。虚幻对**阴影灯**和**非阴影灯**使用了类似的像素着色器——它们之间的区别来自于对投影灯的**额外预处理步骤**。对于每一个灯光，虚幻都会计算一个`ScreenShadowMaskTexture`，它是场景中的**阴影像素**的一个**屏幕空间表示**。

![image-20210514162009895](C:\Users\xueyaojiang\Desktop\JMX_Update\UE4渲染管道理解——Matt.assets\image-20210514162009895.png)

为了做到这一点，虚幻渲染了看起来与**场景中的每个物体的边界框**相匹配的几何体，以及场景中**物体的几何表示**。它不会重新渲染您的场景中的物体，而是结合**给定像素的深度**对`GBuffer`进行采样，看看它投射的光是否会被挡住。



## 3.6 Base Pass Pixel Shader

现在我们知道了**有阴影的灯光**会创建一个屏幕空间的**阴影纹理**，我们可以回去看看`Base Pass Pixel Shader`是如何工作的。作为提醒，这是为场景中的每个灯光运行的，所以对于任何有多个灯光影响的物体，它将在每个像素上运行多次。像素着色器可以很简单，我们对这个像素着色器**调用的函数**更感兴趣。

```c++
void RadialPixelMain( float4 InScreenPosition, float4 SVPos, out float4 OutColor)
{
    // Intermediate variables have been removed for brevity
    FScreenSpaceData ScreenSpaceData = GetScreenSpaceData(ScreenUV);
    FDeferredLightData LightData = SetupLightDataForStandardDeferred();
    OutColor = GetDynamicLighting(WorldPosition, CameraVector, ScreenSpaceData.GBuffer, ScreenSpaceData.AmbientOcclusion, 	ScreenSpaceData.GBuffer.ShadingModelID, LightData, 	GetPerPixelLightAttenuation(ScreenUV), Dither, Random);
    OutColor *= ComputeLightProfileMultiplier(WorldPosition, DeferredLightUniforms_LightPosition,     DeferredLightUniforms_NormalizedLightDirection);
}
```

这里只有几个函数。`GetScreenSpaceData`从`GBuffer`中检索一个给定像素的信息。`SetupLightDataForStandardDeferred`计算信息，如光线方向、光线颜色、衰减等。最后，它调用`GetDynamicLighting`并传入我们到目前为止计算的所有数据——像素在哪里，GBuffer数据，着色模型ID，以及灯光信息。

### GetDynamicLighting

`GetDynamicLighting`（位于`DeferredLightingCommon.ush`）函数相当长，看起来很复杂，但很多复杂的地方是由于每个灯的各种设置。这个函数计算`SurfaceShadow`和`SubsurfaceShadow`变量，它们被初始化为`1.0`。这一点很重要，因为我们以后要用它来乘以数值，所以现在只需接受一个较高的数值，即**阴影较少**。

如果==阴影==被启用，那么就会调用`GetShadowTerms`。这将使用先前的**光线衰减缓冲区**（称为`ScreenShadowMaskTexture`）来确定**给定像素的阴影项**。有很多不同的地方可以提供阴影数据，（Unreal存储`light function` + 在`z`通道中的每个物体的阴影，在`w`通道中存储每个物体的**次表面散射**，在`x`通道中存储整个场景的**定向光阴影**，在`y`通道中存储整个场景的**定向光次表面散射**，**静态阴影**来自适当的GBuffer通道），`GetShadowTerms`将这些信息写入我们先前的`SurfaceShadow`和`SubsurfaceShadow`变量。

现在我们已经确定了表面和次表面数据的**阴影系数**，我们来计算==光的衰减==。衰减实际上是基于与光的距离的能量衰减，可以通过修改来产生不同的效果，即：卡通渲染通常会从计算中删除衰减，这样你与光源的距离就不重要了。Unreal根据**距离**、**光的半径和衰减**，以及**阴影项**来分别计算`SurfaceAttenuation`和`SubsurfaceAttenuation`。==阴影是与衰减相结合的，这意味着我们将来的计算只考虑衰减强度==。

最后我们计算这个像素的`surface shading`。`surface shading`需要考虑`GBuffer`、表面粗糙度、区域灯高光、光照方向、视图方向和法线。粗糙度是由我们的GBuffer数据决定的。Area Light Specular使用基于物理的渲染（基于light数据和粗糙度）来计算一个新值，并可以修改粗糙度和光线向量。

![image-20210514163811651](C:\Users\xueyaojiang\Desktop\JMX_Update\UE4渲染管道理解——Matt.assets\image-20210514163811651.png)

`surface shading`最后给了我们一个机会来修改每个表面对这些数据的反应。这个函数位于`ShadingModels.ush`中，只是一个大的开关语句，看的是`ShadingModel ID`，这个ID早先被写进了GBuffer中。许多**光照模型**共享一个标准的着色函数，但一些更特殊的着色模型使用自定义实现。`surface shading`并不考虑衰减，所以它**只处理计算没有阴影的表面颜色**。衰减（也就是距离+阴影）要到==光累积器==`Light Accumulator`运行时才会被考虑进去。**光线累加器**将表面光照和衰减考虑在内，并在乘以光线衰减值后，将表面和次表面光照正确地加在一起。

最后，`Dynamic Lighting function`返回光照累积器所累积的总光照。在实践中，这只是表面+次表面照明，但代码因**次表面属性**和调试选项而变得复杂。

### ComputeLightProfileMultiplier

最后，`DeferredLightPixelShader`做的最后一件事是将`GetDynamicLighting`计算的颜色乘以`ComputeLightProfileMultiplier`的值。这个函数允许使用**1D IES灯光配置文件纹理**。如果一个**IES灯光配置文件**没有被用于该灯光，那么结果值不会改变。

### Accumulated Light

因为`BasePassPixelShaders`是为每一个影响到物体的`light`而运行的，所以虚幻会积累这些`light`并将其存储在一个缓冲区中。这个缓冲区甚至在几步之后的`ResolveSceneColor`步骤中才被绘制到屏幕上。在这之前还要计算一些其他的东西，比如半透明的物体（使用**传统的前向渲染技术**来绘制）、屏幕空间的抗锯齿以及**屏幕空间的反射**。



## 3.7 Review

对于每一盏灯，**阴影数据**在**屏幕空间**计算，并结合静态阴影、次表面阴影和方向性阴影。然后为每个光绘制近似的几何图形，并绘制该光对每个像素的影响。表面阴影是根据GBuffer数据和渲染模型计算的，然后乘以光的衰减。光线衰减是光线设置（距离、衰减等）和阴影采样的组合。每个表面阴影的输出被累积在一起，产生最终的光照值。





# 4. Shader Permutations

正如我们以前所介绍的那样，虚幻将编译一个**给定的着色器/材质的多种排列方式**，以处理不同的使用情况。当一个材质被修改时，Unreal将寻找该Shader所使用的**.ush/.usf文件**并重新加载它们。然后Unreal会将`Material Graph`转变成HLSL代码，然后开始构建着色器的每一种`permutation `。

每次我们在虚幻中使用**材质编辑器**时都会发生这个过程。不幸的是，这里面有一个问题。它只重新加载与材质本身有关的着色器。因为虚幻使用的是延迟渲染器，所以有些着色器是**全局的**（例如对`GBuffer`进行采样并计算最终颜色的通道）。这意味着这些着色器实际上不是材质的一部分，所以修改该材质不会导致它们被重新加载。

此外，一旦您改变了这些全局着色器并重新启动，虚幻就会重新编译使用该文件的每一个着色器，所以如果您编辑了一个普通的着色器，您就会看到一个接近完全的重新编译，这对于一个空的项目来说是：将近125个着色器/10000个`permutation `。这对于修改渲染器模块的C++代码也是如此。这对迭代时间来说是很糟糕的，因为你需要重新编译所有的东西，并等待10分钟来查看你的修改是否有效。更糟糕的是，如果你在着色器内的`#if X_Y`部分修改了一些东西，你可能会在遇到**不能编译的permutation**之前部分地通过重新编译（浪费时间）。

## 4.1 Lowering the Overall Number of Permutations

第一个目标是看看可以在引擎中改变哪些设置，或者考虑为**材质**减少需要编译的`permutation `的总数。

第一件事是`Usage settings`。这些设置似乎代表了引擎中**特定的顶点工厂**，如果你在新的VF中使用它，编辑器中`Automatically Set Usage`被选中，它将产生这种`permutation `。**禁用这个功能**可以让你有更多的控制权，并且会让艺术家在分配材质时三思而后行，但可能不会为你赢得太多`permutations`。

在材质的基础上，可以注意的下一件事是质量和**静态开关**的使用。因为` Static switches`是==compile-time==的，它们的每个可能的组合都需要一个新的`permutation `，有太多的静态开关会导致相当多的`permutation `。同样，这个可能不会为你省去太多的`permutation `。

现在我们可以看看可能会减少`permutations`的项目设置 。进入**项目设置 > 渲染**，有几个设置可以调整。根据特定**项目/测试需要**，可能需要保留其中的一些设置。如果你在这里禁用了shader permutation，而你的场景需要它，那么当你试图使用大气雾，并禁用支持大气雾时，你会在视口中得到一个警告，即："PROJECT DOES NOT SUPPORT ATMOSPHERIC FOG"。

![image-20210514173135530](UE4渲染管道理解——Matt.assets\image-20210514173135530.png)

### Lighting

允许静态照明（注意：禁用这个意味着标记为静态的灯光不会对你的材料产生影响。如果禁用此功能，请将它们设置为可移动的，以便进行测试）

### Shader Permutation Reduction

支持`Stationary Skylight`

支持`Low Quality Lightmap Shader Permutations`

支持点光源全场景阴影

支持大气雾

### Mobile Shader Permutation Reduction

支持组合**静态**和**CSM阴影**

支持距离场阴影

支持可移动的定向灯

最大的可移动点光 = 0

在==禁用==所有这些之后，打开`ConsoleVariables.ini`，添加`r.ForceDebugViewModes=2`，这样可以进一步减少`permutation `的数量。这将禁用编辑器中的缓冲区可视化（以显示GBuffer通道），但可能是值得的。

做了所有这些后，作者的着色器从8809减少到了3708，或者说着色器减少了58%。



## 4.2 Speeding up Compilation

你可以在编译环境中添加`CFLAG_StandardOptimization`，以确保**D3D编译器**不花时间优化着色器。为所有着色器设置的最简单方法是：打开`ShaderCompiler.cpp`，向下滚动到`GlobalBeginCompileShader`函数，然后添加：`Input.Environment.CompilerFlags.Add(CFLAG_StandardOptimization);`。如果你想对你的性能进行剖析，就不要这样做，因为优化着色器很重要。注意：这与`r.Shaders.Optimize=0`不同，后者是关于**调试信息**，而不是代码优化。



## 4.3 Recompiling Only Changed Shaders

最后，我们要看一下==重新编译特定的着色器==的技术。虚幻有一个未列出的控制台命令==recompileshaders==，它可以接受几个不同的参数。请注意，这只对`.usf`文件起作用，因为`.ush`文件是只被`.usf`文件包含的头文件。

`recompileshaders`查询`FShaderType`和`FShaderPipelineType`，以返回所有过时的着色器、工厂和着色器管道。如果发现任何过时的东西（由于源文件改变），那么它将被重新编译。**全局着色器可以用这个命令重新编译**。在实践中，我发现由于它最终会重新编译所有受影响的**全局着色器**，修改`ShadingModels.ush`这样的文件最终会导致大量的编译工作，需要`3-5`分钟。

`recompileshaders global `获取`global shader map`，清除它并强制重新编译所有全局着色器。修改`ShadingModels.ush`等文件需要`1-2`分钟。如果知道要修改的着色器是全局的，而不是材质着色器，也许会很有用。

`recompileshaders material <MaterialName>`将重新编译找到的**第一个具有该名称的材质**。不应包括路径信息。这是通过在材质上调用`PreEditChange/PostEditChange`来完成的，所以它很可能与在材质编辑器中点击`Apply`没有区别。

`recompileshaders all`将重新编译所有文件。可以与 "项目设置">"渲染覆盖（本地）">"强制支持所有着色器属性 "结合起来，以确保你的代码在每个`#if`变量下都能编译。

`recompileshaders <path>`将尝试按**着色器类型**或**着色器平台类型**重新编译着色器。这允许我们指定特定的着色器文件路径，例如`recompileshaders /Engine/Private/BasePassPixelShader.usf `。



## 4.4 Common #if Defines

下面是在**延迟着色管道**中发现的一些**常见的预处理器定义**。我根据`C++`代码触发它们的情况，把它们的**预期含义**列了出来。希望这能让你弄清楚延迟管道的哪些部分适用于你的代码，因为你可以对照这个列表检查预处理器定义，看看它在UE4设置方面的转化情况。

- `#if NON_DIRECTIONAL_DIRECT_LIGHTING` 这可以在`DeferredLightingCommon.ush`中找到，但似乎只在`ForwardLightingCommon`中定义。 定义为：

  ```c++
  #define NON_DIRECTIONAL_DIRECT_LIGHTING (TRANSLUCENCY_LIGHTING_VOLUMETRIC_NONDIRECTIONAL || TRANSLUCENCY_LIGHTING_VOLUMETRIC_PERVERTEX_NONDIRECTIONAL)
  ```

- `#if SUPPORT_CONTACT_SHADOWS`提供了对虚幻的**接触阴影特性**的支持。
- `#if REFERENCE_QUALITY`在`eferredLightingCommon.ush`的顶部被定义为`0` ——可能是为了进行电影级的渲染？
- `#if ALLOW_STATIC_LIGHTING` 。如果 `r.AllowStaticLighting `控制台变量设置为 `1`，则为真，这与**项目设置 > 渲染选项**中的**静态照明支持**相匹配。
- `#if USE_DEVELOPMENT_SHADERS`。 如果 `COMPILE_SHADERS_FOR_DEVELOPMENT` 为真（且平台支持），则为真。如果设置了`r.CompileShadersForDevelopment`，则`COMPILE_SHADERS_FOR_DEVELOPMENT`为真。
- `#if TRANSLUCENT_SELF_SHADOWING`被定义为正在用`FSelfShadowedTranslucencyPolicy渲`染的对象。我相信这是为了支持`Lit Translucency`。
- `#if SIMPLE_FORWARD_DIRECTIONAL_LIGHT`和`#if SIMPLE_FORWARD_SHADING`似乎是在光照贴图渲染过程中为`stationary directional lights`设置的。
- `#if FORWARD_SHADING`在`r.ForwardShading`被设置为`1`时被设置。



# 5. Adding a new Shading Model

## 5.1 Adding a new Shading Model

虚幻支持几种常见的、开箱即用的**着色模型**，它们可以满足大多数游戏的需要。虚幻支持通用的`microfacet specular`作为其**默认的照明模型**，但是也有支持高端头发和眼睛效果的照明模型。这些着色模型可能不是最适合我们游戏的，可能希望对它们进行调整或添加全新的模型，特别是对于**高度风格化**的游戏。

![image-20210514194147460](C:\Users\xueyaojiang\Desktop\JMX_Update\UE4渲染管道理解——Matt.assets\image-20210514194147460.png)

**集成一个新的照明模型的代码少得令人吃惊**，但需要一些耐心（因为它需要对引擎和所有着色器进行（几乎）全面的编译）。一旦你决定开始自己进行增量修改，请确保你查看迭代部分，因为这可以帮助你减少开箱后的**10分钟**迭代时间。

> 这篇文章中的大部分代码是基于**FelixK**在其博客系列中的优秀（但有些过时）的信息，再加上各个帖子的评论者的一些修正。强烈建议你也读一下FelixK的博客，因为我已经略过了一些着色器代码的变化，以换取更多关于这个过程和我们为什么要这样做的解释。为了支持新的着色模型，我们需要修改引擎的三个不同区域，材料编辑器、材料本身和现有的着色器代码。我们将一个一个地解决这些变化。

## 5.2 Modifying the Material Editor

我们的第一站是`EngineTypes.h`中的`EMaterialShadingModel`**枚举**。这个枚举决定了在**材质编辑器**中的**渲染模型下拉菜单**中显示的内容。我们将把**新枚举项目**`MSM_StylizedShadow`添加到该枚举中的`MSM_MAX`之前

```c++
// Note: Check UMaterialInstance::Serialize if changed!
UENUM()
enum EMaterialShadingModel
{
    // … Previous entries omitted for brevity
    MSM_Eye UMETA(DisplayName=”Eye”),
    MSM_StylizedShadow UMETA(DisplayName=”Stylized Shadow”),
    MSM_MAX,
};
```

**枚举**似乎是按名称**序列化**的（如果存在的话），但无论如何都值得添加到列表的末尾，因为引擎的任何部分都可能按**整数值**序列化它们。

`Epic`在`EMaterialShadingModel`枚举上面留下了一个评论，警告开发者如果我们改变了这个枚举，要检查`UMaterialInstance::Serialize`函数。如果我们添加一个新的着色模型，里面似乎没有什么需要改变的，所以我们可以忽略它。如果你对该函数的作用感到好奇，看起来他们确实在某一时刻改变了**枚举值的顺序**，所以该函数有一些代码来修复，这取决于正在加载的资产的版本）。

如果编译，**新的渲染模型**将显示在**材料编辑器**内的**渲染模型下拉菜单**中，但它不会做任何事情！FelixK使用`Custom Data 0 pin`，允许艺术家设置**光线衰减的范围大小**。我们需要修改代码，使``Custom Data 0 pin``为**自定义渲染模型**所启用。

打开`Material.cpp`（不要与`Lightmass`项目中相同的文件混淆），寻找`UMaterial::IsPropertyActive`函数。这个函数会被`Material`上每个可能的`pin`调用。如果你试图修改一个材质域（如**贴花**、**后期处理**等），你需要仔细注意这个函数的第一部分，他们会查看每个域，并简单地指定哪些`pin`应该被启用。如果你像我们一样修改渲染模型，那就有点复杂了——there is a switch statement that returns true for each pin if it should be active given other properties。

在我们的例子中，我们想启用`MP_CustomData0`引脚，所以我们向下滚动到`MP_CustomData0`部分，并在其末尾添加`|| ShadingModel == MSM_StylizedShadow`。当您将**渲染模型**改为风格化阴影时，该引脚应被启用。

```c++
switch (InProperty)
{
        // Other cases omitted for brevity
    case MP_CustomData0:
        Active = ShadingModel == MSM_ClearCoat || ShadingModel == MSM_Hair || ShadingModel == MSM_Cloth || ShadingModel == MSM_Eye || ShadingModel == MSM_StylizedShadow;
        break;
}
```

```c++
case MP_CustomData0:
		Active = ShadingModels.HasAnyShadingModel({ MSM_ClearCoat, MSM_Hair, MSM_Cloth, MSM_Eye, MSM_StylizedShadow});
		break;
```

重要的是要明白，这段代码只改变了**材质编辑器**中的用户界面，你仍然需要确保在你的着色器中，使用**提供给这些针脚的**数据。

题外话：`Custom Data 0 pin`和`Custom Data 1 pin`是**单通道浮点属性**，对于**自定义着色模型**来说，可能不够。Javad Kouchakzadeh向我指出，你可以创建全新的针脚`pin`，让你选择如何为它们生成`HLSL`代码。不幸的是，这有点超出了本教程的范围，但可能是未来教程的主题。如果你觉得很冒险，可以查看`MaterialShared.cpp`中的`InitializeAttributeMap()`函数！



## 5.3 Modifying the HLSL Pre-Processor Defines

一旦我们修改了**材质编辑器**，使其能够选择我们新的着色模型，我们就需要确保**着色器**知道它们何时被设置为使用**我们的着色模型**。

打开`MaterialShared.cpp`，寻找有点庞大的`FMaterial::SetupMaterialEnvironment(EShaderPlatform Platform, const FUniformExpressionSet& InUniformExpressionSet, FShaderCompilerEnvironment& OutEnvironment) const`函数。这个函数可以让你查看各种**配置因素**（比如你的材质上的属性），然后通过添加**额外的定义**来修改`OutEnvironment`变量。

在这里的特殊情况下，我们将向下滚动到开启`GetShadingModel()`的部分，并添加我们的`MSM_StylizedShadow`（来自`EngineTypes.h`），并按照现有模式给它一个字符串名称。

```c++
switch(GetShadingModel())
{
    // Other cases omitted for brevity
    case MSM_Eye:
    OutEnvironment.SetDefine(TEXT(“MATERIAL_SHADINGMODEL_EYE”), TEXT(“1”)); break;
    case MSM_StylizedShadow:
    OutEnvironment.SetDefine(TEXT(“MATERIAL_SHADINGMODEL_STYLIZED_SHADOW”), TEXT(“1”)); break;
}
```

这里的处理落伍了，具体可见博客https://blog.csdn.net/qq_40725856/article/details/113402321

