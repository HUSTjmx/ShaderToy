## 虚幻4渲染编程（Shader篇）

### 1. 虚幻自身的延迟渲染管线

**<img src="YivanLee博客阅读.assets/v2-f9c233f06579279d759ee7f76d1d87d3_720w.jpg" alt="img" style="zoom:200%;" />**

那么当我们把一个模型托到场景里，这个模型被渲染出来的整个流程到底是什么样的呢？这个流程其实是非常庞大的。下面我就来一个一个拆分。

（1）第一步：资源准备阶段。这个阶段包括顶点缓冲区的准备，索引缓冲区的准备。这一步由场景代理管理完成。当然从磁盘里读取模型资源这些就涉及到StaticMesh这些了。想了解这一步可以去看我以前的博客，或者直接去看UPrimitiveComponent，UMeshComponent，UStaticMeshComponent，UCableComponent，UCustomMeshComponent。当你把这些源码全部研究一遍后，这个阶段算是了解了。这个阶段我不打算再描述了，因为已经有了很多现成的代码了。

（2）第二步就是shader资源的准备了，这个又是一个非常大的话题了。可以去看我以前关于给改材质编辑器和加shadingmode的文章便可以有个大概的了解。这一步我还会进一步阐述。

（3）第三步就是绘制了。

我们先不看Render函数那些复杂的调用，我们把精力先集中到shader层面来。一张画面是怎么开始绘制的呢？

![img](YivanLee博客阅读.assets/v2-c1e60fc31db469462deaf519452720aa_720w.jpg)

#### InitView

主要是计算可见性，进行剔除。

![img](YivanLee博客阅读.assets/v2-fa3aa8b0d64ec933f51e6d53cf8c1962_720w.jpg)

#### Early Z-Pre Pass

Early Z由硬件实现，我们的渲染管线只需要按照硬件要求渲染就可以使用earlyz优化了，具体步骤如下：

（1）首先UE4会把场景中所有的Opaque和Mask的材质做一遍Pre-Pass，只写深度不写颜色，这样可以做到快速写入，先渲染Opaque再渲染Mask的物体，渲染Mask的时候开启Clip。

（2）做完Pre-pass之后，这个时候把深度测试改为Equal，关闭写深度渲染Opaque物体。然后再渲染Mask物体，同样是关闭深度写，深度测试改为Equal，但是这个时候是不开启clip的，因为pre-pass已经把深度写入，这个时候只需要把Equal的像素写入就可以了。

首先渲染prepass的第一步肯定是渲染资源的准备啦。primitive资源会在InitView的时候准备好。

然后会再BeginRenderingPrePass函数中设置各种绘制管线的绑定，包括关闭颜色写入，绑定Render target

![img](YivanLee博客阅读.assets/v2-b7bc93523a89f8a71fdcbaff1c5f7741_720w.jpg)

然后再调用draw之前会把各种UniformBuffer和渲染状态设置好

![img](YivanLee博客阅读.assets/v2-2335f9e9be8296914c75dcc0143dc20e_720w.jpg)

![img](YivanLee博客阅读.assets/v2-222b71e8428210b332c7af6630f59734_720w.png)

然后调用draw

![img](YivanLee博客阅读.assets/v2-2bf33be4490056844784e7f7ca614789_720w.png)

最后完成Pre Pass的绘制

![img](YivanLee博客阅读.assets/v2-f46c8f5ca6bfebefeeb5309fd4da63ba_720w.jpg)

#### ShadowDepthPass

根据不同的灯光类型会绘制不同种类的shadowmap。总的来说绘制shadowmap的时候不会使用遮挡剔除。

Unreal渲染shadowmap目前我就找到个视锥剔除

![img](YivanLee博客阅读.assets/v2-76d5a2f790384aa5c172157eda0fb760_720w.png)

![img](YivanLee博客阅读.assets/v2-4b239cf4bbdce108af1929b27542fa8e_720w.jpg)

shadowdepthpass可能是在basepass之前，也可以是之后，具体看EarlyZ的方式

![img](YivanLee博客阅读.assets/v2-c1d630e5e5349a8133c907a4d845c0d7_720w.png)

![img](YivanLee博客阅读.assets/v2-7be01e95ea13f36f1a1e979637691570_720w.jpg)

我们的灯光种类繁多大致可以分为两类，一类使用2Dshadowmap的，一类使用Cubemapshadowmap的

![img](YivanLee博客阅读.assets/v2-322e5c8413568369be9fa332612372c0_720w.jpg)

上图的1部分就是渲染2DshadowMap，2部分渲染的就是Cubemapshadowmap，这一步只是渲染出shadowmap供后面的Lightingpass使用。

#### BasePass

![img](YivanLee博客阅读.assets/v2-975568166609af0c7721fbaca1464828_720w.png)

BasePass使用了==MRT技术==一次性渲染出GBuffer。

![img](https://pic4.zhimg.com/80/v2-f7018c22976e094d9a2faf24a82467bb_720w.png)

再上一次**GBuffer**的数据分布

![img](https://pic1.zhimg.com/80/v2-7122e9e374b7824897153f0d30716304_720w.jpg)

BasePass把GBuffer渲染出来之后就可以供后面的LightingPass使用了。我们的材质编辑器再Surface模式下也是在生成MaterialShader为BasePass服务

![img](https://pic4.zhimg.com/80/v2-08e5687122396117ca2ec8c91364cb1f_720w.jpg)

这部分可以去看看我的材质编辑器篇有详细介绍。

也是通过一系列设置绑定渲染状态资源等，最后调用==dispatchdraw==

![img](YivanLee博客阅读.assets/v2-7b3ca3b430be474df968dbefa78b3a31_720w.jpg)

![img](YivanLee博客阅读.assets/v2-7cfc98b15cddeae69f7ce2c082ff1554_720w.jpg)

可以注意到，MRT0是SceneColor而不是BaseColor

![img](YivanLee博客阅读.assets/v2-5d21e50dd500c5a2767beee0e1d46af1_720w.jpg)

Scene在BasePass中做了简单的漫反射计算

![img](YivanLee博客阅读.assets/v2-387c26c1874b87fcc347f1ae4e8a59db_720w.png)

这一步用到了，这个测试场景我是烘焙过的，我把烘焙数据去掉，SceneColor其实是这样的：

![img](YivanLee博客阅读.assets/v2-8eaeaf082a3a834c4c171ed747c5d12f_720w.jpg)

啥也没有黑的

BasePass会在这个阶段把预烘焙的IndirectLiting计算到SceneColor这张RT上供后面的pass使用

![img](https://pic4.zhimg.com/80/v2-e1057d96b87a69bd1b0348192e7d3743_720w.png)

#### CustomDepthPass

CustomDepth没啥特别的，就是把需要绘制CustomDepth的物体的深度再绘制一遍到CustomDepthBuffer上。

#### PreLightingPass

虚幻封装了一套方便画PostPass的机制，后面的绘制SSAO，Lighting，SSR，Bloom等各种pass都是用的这套Context的机制。

![img](YivanLee博客阅读.assets/v2-dd100189736dd2fbc0bf7fcd04c602c7_720w.jpg)

![img](YivanLee博客阅读.assets/v2-27ce6dcd474432309e921ff6a4c5dd3a_720w.jpg)

==PreLighting这步主要是在用前面的GBuffer，算decals和SSAO为后面的Lighting做准备。==

![img](YivanLee博客阅读.assets/v2-3e9ecfb1b2b3b30bedbf036a96e95424_720w.png)

SSAO使用的是FPostProcessBasePassAOPS这个C++shader类。

![img](YivanLee博客阅读.assets/v2-71ec0c87347da589f9fdd1a996245211_720w.jpg)

对应的USF是PostProcessAmbientOcclusion

![img](YivanLee博客阅读.assets/v2-3bb3b9be4b24b7e6f72a81ac4374a49a_720w.jpg)

并且使用Computeshader来加速计算

#### DirectLightPass

![img](YivanLee博客阅读.assets/v2-9c628b0deac61c8f85fdf9e737bbee36_720w.jpg)

LightPass也非常复杂，整个pass的代码有几千行，shader代码也有几千行非常恐怖的系统。我们先找到入口函数：

![img](YivanLee博客阅读.assets/v2-ae2cf511c90d31bdc8f1fd5b51e775e5_720w.png)

##### （1）方向光

根据不同的情况，使用不同的渲染策略

渲染不同情况下的灯光大体分类如下。还会根据不同的渲染方式分类。

![img](https://pic4.zhimg.com/80/v2-a1333d04a291ebbcb02b00e3aee9e20f_720w.jpg)

比如一般的方向光：

![img](https://pic1.zhimg.com/80/v2-e81159b5659a27db7d517ed13c75add0_720w.png)

![img](https://pic4.zhimg.com/80/v2-d92700e7edb10534ee05525828eb2953_720w.png)

![img](https://pic4.zhimg.com/80/v2-ea5721ab9ef2dd6b2142de91fc8d25fb_720w.jpg)

在渲染方向光的时候因为不需要考虑分块，所以直接把每盏灯挨个画出来就可以了

![img](https://pic4.zhimg.com/80/v2-24d0336562057e6775d29cc3c816ce87_720w.png)

下面我只放了一盏方向光

![img](https://pic1.zhimg.com/80/v2-61121b057c63138f11f098d20e221154_720w.jpg)

下面我放三盏方向光：

![img](https://pic2.zhimg.com/80/v2-1611d5f40ce987c51300b20a8a5bc5dd_720w.jpg)

##### （2）TileDeferredLighting

如果灯光不渲染阴影，并且灯光没用IES，并且灯光数目达到80盏以上（4.22）并且启用了TileDeferred管线，那么虚幻4就会使用TileDeferredLight来计算光照，虚幻实现TileDeferrdLight使用的是一个Computeshader

![img](https://pic4.zhimg.com/80/v2-921f7b112ed427ba1c620d175427af67_720w.jpg)

![img](https://pic4.zhimg.com/80/v2-d48819345cfedd485228613f01978203_720w.jpg)

![img](https://pic2.zhimg.com/80/v2-b6c3467da49e57487a68713c3b426481_720w.png)

有很多灯光使用的潜规则。

#### ScreenSpaceReflectionPass

![img](https://pic3.zhimg.com/80/v2-70188de95d3495fb079b443ae6c7dcf2_720w.jpg)

![img](https://pic3.zhimg.com/80/v2-09ba59cff82192d6da7a5a162719a6f6_720w.png)

#### TranslucencyPass

![img](YivanLee博客阅读.assets/v2-d1f1d40bdd60db0e92b278cfa9728eae_720w.jpg)

![img](YivanLee博客阅读.assets/v2-94b0640d438e3161dbeaec70cf3f1582_720w.jpg)

透明物体会放在最后渲染，但是在==后期==的前面。需要看是否在DOF(景深)后合并。

对于这个上图的那个场景来说，透明物体渲染的buffer是长下面这样的：

![img](YivanLee博客阅读.assets/v2-6c05f557dc872163ce7f9b1f554222af_720w.jpg)

最后在后期中组合

![img](YivanLee博客阅读.assets/v2-7aceba7b907363239ee4127cae52b7dd_720w.jpg)

如果没有启用==r.ParallelTranslucency==透明物体只能挨个渲染。

![img](https://pic4.zhimg.com/80/v2-f171cd98a584a4d84d496fdbf8b23ec7_720w.jpg)

![img](https://pic4.zhimg.com/80/v2-bd2be1695a6910da54f2365ffaaf5b2b_720w.jpg)

![img](https://pic4.zhimg.com/80/v2-0186407aafeca4d0bb4b0c89367d2d7b_720w.jpg)

如果启用了就可以走上面的并行渲染分支。

透明物体的渲染在实时渲染中一直比较迷，会有各种问题。比如排序等等。在默认情况下是走AllowTranslucentDOF的。AllowTranslucentDOF是什么意思呢，代码的注释里有解释。

![img](https://pic1.zhimg.com/80/v2-2b17bd6e094be3f7032fc8b5a34a8d80_720w.jpg)

Translucent物体的渲染有几种模式：

![img](https://pic1.zhimg.com/80/v2-6b669646aa731d2e62198ecdd6f72c88_720w.jpg)

这里的代码我们在BasePassPixelShader.usf里能找到

![img](https://pic2.zhimg.com/80/v2-45338166686e8f83ea1ad2afe022a049_720w.jpg)

对于非透明物体来说basepass是渲染GBuffer的，但是对于透明物体来说，BasePass是渲染基础的+Lighting的，会在这里一次性渲染完，如果我们想改透明物体的shading方式，就需要用在这里改了。

 参考文章：

【1】[fengliancanxue：深入剖析GPU Early Z优化](https://zhuanlan.zhihu.com/p/53092784)

【2】[Visibility and Occlusion Culling](https://link.zhihu.com/?target=https%3A//docs.unrealengine.com/en-us/Engine/Rendering/VisibilityCulling)

### 2. 不用虚幻4Shader管线使用自己的shader

