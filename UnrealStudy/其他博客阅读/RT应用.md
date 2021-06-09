# 1. 使用渲染目标绘画

## 绘制方法

为了确定在哪里绘制渲染目标，你需要从摄像机向前画一条线。如果线条击中画布，你可以在**UV空间**中得到击中位置。例如，如果画布是完美的UV映射，在中心的点击将返回值(0.5,0.5)。如果它击中右下角，你将得到一个值(1,1)。然后你可以使用一些**简单的数学**计算**绘制位置**。

在本教程中，您将在蓝图中动态创建**渲染目标**。这意味着你需要设置一个纹理作为参数，这样你就可以传递渲染目标。为此，创建一个`TextureSampleParameter2D`并命名为`RenderTarget`。然后，将它连接到BaseColor。

## 创建RT

更好的方法是使用蓝图创建**渲染目标**。这样做的好处是您只需根据需要创建渲染目标，它们不会使项目文件膨胀。

首先，您需要创建渲染目标并将其存储为变量以供以后使用。转到*Blueprints*文件夹并打开*BP_Canvas*。找到*Event BeginPlay*并添加

![image-20210609094842782](RT应用.assets\image-20210609094842782.png)

### 显示RT

目前，**画布网格**正在使用其默认材质。要显示渲染目标，您需要创建*M_Canvas*的动态实例，并提供渲染目标。然后，您需要将**动态材质实例**应用于画布网格：

![image-20210609095407345](RT应用.assets\image-20210609095407345.png)

## 创建笔刷材质

创建一个名为*M_Brush*的材质，然后打开它。首先，将***混合模式***设置为***半透明***。这将允许使用具有透明度的纹理。

就像画布材质一样，还将在蓝图中设置画笔的纹理。创建一个*TextureSampleParameter2D*并将其命名为*BrushTexture*。

![image-20210609100112407](RT应用.assets\image-20210609100112407.png)

接下来要做的是创建**画笔材质的动态实例**，以便您可以更改画笔纹理。打开*BP_Canvas*：

![image-20210609100457508](RT应用.assets\image-20210609100457508.png)

## 将画笔绘制到渲染目标

创建一个新函数并将其命名为==*DrawBrush*==。首先，需要使用纹理、画笔大小和绘制位置的参数。创建以下输入：

- *BrushTexture：*将类型设置为*Texture 2D*
- *BrushSize：*将类型设置为float
- *DrawLocation：*将类型设置为*Vector 2D*

计算绘制位置是一个两步过程。首先，您需要缩放*DrawLocation*以适应渲染目标的分辨率。为此，*请将 DrawLocation*与*Size*相乘。

默认情况下，引擎将使用左上角作为原点绘制材质。这将导致画笔纹理不会以您要绘制的位置为中心。要解决此问题，您需要将*BrushSize*除以*2*，然后减去上一步的结果。

最后，您需要告诉引擎您要停止绘制渲染目标。添加一个*End Draw Canvas 到 Render Target*节点并像这样连接它

![image-20210609102013023](RT应用.assets\image-20210609102013023.png)

## 来自相机的线路追踪

在画布上绘画之前，您需要指定画笔纹理和大小。转到*Blueprints*文件夹并打开*BP_Player*。然后，将*BrushTexture*变量设置为*T_Brush_01*并将*BrushSize 设置*为*500*。这会将画笔设置为大小为*500×500*像素的猴子图像。接下来，您需要进行线路跟踪。找到*InputAxis Paint*并创建以下设置：

![image-20210609102844669](RT应用.assets\image-20210609102844669.png)

现在需要检查射线是否碰到画布。

![image-20210609103632592](RT应用.assets\image-20210609103632592.png)

在*Find Collision UV*节点工作之前，您需要更改两个设置。首先，转到*LineTraceByChannel*节点并启用*Trace Complex*。

![image-20210609103717643](RT应用.assets\image-20210609103717643.png)

其次，转到*Edit\Project Settings*，然后转到*Engine\Physics*。启用*Support UV From Hit Results*，然后重新启动您的项目。

![image-20210609103812340](RT应用.assets\image-20210609103812340.png)

![虚幻引擎渲染目标](RT应用.assets\unreal-engine-render-targets-04.gif)

## 更改画笔大小

打开*BP_Player*并找到*InputAxis ChangeBrushSize*节点。此轴映射设置为使用*鼠标滚轮*。要更改画笔大小，您需要做的就是根据*Axis Value*更改*BrushSize*的*值*。为此，请创建以下设置：

![image-20210609105957347](RT应用.assets\image-20210609105957347.png)

## 更改画笔纹理

首先，需要一个数组来保存玩家可以使用的纹理。打开*BP_Player*，然后创建一个*数组*变量。将类型设置为*Texture 2D*并将其命名为*Textures*。

![image-20210609110524861](RT应用.assets\image-20210609110524861.png)

接下来，您需要一个变量来保存数组中的当前索引。创建一个*整数*变量并将其命名为*CurrentTextureIndex*。

接下来，您需要一种循环浏览纹理的方法。在本教程中，我设置了一个名为*NextTexture*的动作映射设置为*right-click*。每当玩家按下此按钮时，它应该更改为下一个纹理。为此，请找到*InputAction NextTexture*节点并创建以下设置：

![image-20210609111026355](RT应用.assets\image-20210609111026355.png)





# 2. 创建雪迹

## 雪迹实施

**创建轨迹**所需的第一件事是*渲染目标*。渲染目标将是一个**灰度蒙版**，其中**白色表示有轨迹**，黑色表示没有轨迹。然后，您可以将**渲染目标**投影到地面上，并使用它来**混合纹理**和**置换顶点**。

![虚幻引擎雪](RT应用.assets\unreal-engine-snow-projection.gif)

你需要的第二件事是**如何只屏蔽掉受雪影响的物体**。你可以通过首先将物体渲染为**自定义深度**来做到这一点。然后，你可以使用带有后处理材质的场景捕捉来屏蔽任何渲染为自定义深度的对象。然后，你可以将遮罩输出到渲染目标。

**场景捕捉**的重要部分是你放置它的位置。下面是一个从**自顶向下视图**捕获的渲染目标的例子。在这里，第三人称角色和盒子被掩盖了。

![unreal engine snow](RT应用.assets\unreal-engine-snow-01.jpg)

乍一看，**自上而下的捕捉**看起来是个好办法。形状似乎是精确到网格的，所以应该没有问题，对吗？并非如此。自上而下捕捉的问题是，它不能捕捉最宽点以下的东西。这里有一个例子。

![unreal engine snow](RT应用.assets\unreal-engine-snow-02.gif)

![unreal engine snow](RT应用.assets\unreal-engine-snow-02.jpg)

这个问题的延伸是**很难确定一个物体是否接触到地面**。

![unreal engine snow](RT应用.assets\unreal-engine-snow-03.gif)

### 自顶向上方法

![unreal engine snow](RT应用.assets\unreal-engine-snow-04.gif)

为了确定物体是否接触到地面，可以使用**后期处理材质**来进行深度检查。这将检查物体的深度是否**高于地面深度**和**低于指定的偏移量**。如果这两个条件都是真的，你就可以屏蔽掉这个像素。

![unreal engine snow](RT应用.assets\unreal-engine-snow-03.jpg)

![unreal engine snow](RT应用.assets\unreal-engine-snow-05.gif)

## 创建深度检查材质

为了进行==深度检查==，你需要使用两个**深度缓冲区**。一个用于地面，另一个用于受雪影响的物体。由于**场景捕捉**只能看到地面，所以场景深度将输出地面的深度。要获得物体的深度，你只需将它们渲染到**自定义深度**。

首先，你需要计算每个像素到地面的距离。打开`Materials\PP DepthCheck`，然后创建以下内容

![image-20210609114747731](RT应用.assets\image-20210609114747731.png)

现在，如果像素在地面的`25`个单位内，它就会显示在遮蔽中。遮罩的强度取决于像素离地面有多近。点击应用，然后回到主编辑器。

接下来，你需要创建场景捕捉。

## 创建场景捕捉

首先，你需要一个渲染目标，以便将场景捕捉写入其中。导航到RenderTargets文件夹，创建一个名为`RT_Capture`的新渲染目标。

现在让我们来创建场景捕捉。在本教程中，你将把**场景捕捉**添加到蓝图中，因为你以后需要对它进行一些脚本编写。打开Blueprints/BP_Capture，然后添加一个`Scene Capture Component 2D`。将其命名为SceneCapture。

![image-20210609120137966](RT应用.assets\image-20210609120137966.png)

首先，你需要设置捕捉的旋转，使它向上看向地面。转到细节面板，设置旋转为(0,90,90)。接下来是**投影类型**。由于遮罩`mask`是**场景的二维表示**，你需要消除**任何透视变形**。要做到这一点，将`Projection\Projection`类型设置为`Orthographic`。

![image-20210609121147827](RT应用.assets\image-20210609121147827.png)

接下来，你需要告诉**场景捕捉**要写到哪个**渲染目标**上。要做到这一点，将`Scene Capture/Texture Target`设置为`RT1`（自己建的）。

![image-20210609121356497](RT应用.assets\image-20210609121356497.png)

最后，**你需要使用深度检查材质**。将`PP_DepthCheck`添加到`Rendering Features/Post Process Materials`中。为了让**后期处理**发挥作用，你还需要把`Scene Capture\Capture Source`改为RGB中的`Final Color（LDR）`。

![image-20210609121600995](RT应用.assets\image-20210609121600995.png)

![image-20210609121651104](RT应用.assets\image-20210609121651104.png)

## 设置捕捉区域大小

由于最好使用**低分辨率的渲染目标**，你需要确保有效地利用其空间。这意味着要决定一个像素覆盖多少区域。例如，如果**捕捉区域**和**渲染目标**的分辨率相同，你就会得到一个1:1的比例。每个像素将覆盖一个1×1的区域（以世界为单位）。

对于雪道来说，1:1的比例是不需要的，因为你不太可能需要那么多的细节。我建议使用更高的比率，因为它们将允许你在使用低分辨率的同时增加捕捉区域的大小。注意不要把比例提高得太多，否则你会开始失去细节。在本教程中，你将使用`8:1`的比例，这意味着每个像素的大小为8×8世界单位。

你可以通过改变Scene Capture/Ortho Width属性来调整捕捉区域的大小。例如，如果你想捕捉一个1024×1024的区域，你可以把它设置为1024。由于你使用的是8:1的比例，所以将其设置为`2048`（**默认的渲染目标分辨率为256×256**）。

![image-20210609122640403](RT应用.assets\image-20210609122640403.png)

这意味着场景捕捉将捕捉一个`2048×2048`的区域。这大约是20×20米。

地面材质也需要访问**捕获的大小**，以便正确地投影**渲染目标**。做到这一点的一个简单方法是将**捕捉的尺寸**存储到一个**材料参数集合**中。这是一个变量的集合，任何材质都可以访问。

### 存储区域大小

创建一个**材料参数集**，它被列在材料和纹理下。把它重命名为`MPC_Capture`，然后打开它。

接下来，创建一个新的标量参数并命名为`CaptureSize`。

![image-20210609131826225](RT应用.assets\image-20210609131826225.png)

回到BP_Capture，确保将`set`设置为MPC_Capture，参数名称为`CaptureSize`。

![image-20210609132117072](RT应用.assets\image-20210609132117072.png)

## 变形地形

打开`M_Landscape `，然后转到细节面板。然后，设置以下属性

- 将`LandscapeTwo Sided`设置为启用。由于场景捕捉将从底部看，它将只看到地面的背面。默认情况下，引擎不会渲染背面。这意味着它不会将地面的深度存储到深度缓冲区。要解决这个问题，你需要告诉引擎渲染**网格的两面**。
- `D3D11 Tessellation`设置为`Flat Tessellation`（也可以使用PN三角形）。这有效地提高了网格的分辨率，使你在**置换顶点**时可以得到更精细的细节。

![unreal engine snow](RT应用.assets\unreal-engine-snow-13.jpg)

一旦你启用了镶嵌，**世界位移**和**镶嵌乘数**将被启用。

![image-20210609133142004](RT应用.assets\image-20210609133142004.png)

Tessellation Multipler控制`tessellation`的数量。在本教程中，不连接它，这意味着它将使用默认值1。

世界位移（World Displacement）接收一个矢量值，描述顶点的移动方向和移动量。为了计算这个`pin`的值，你首先需要把**渲染目标**投射到地面上。

## 投射渲染目标

为了投射渲染目标，你需要计算它的**UV坐标**。为此，创建以下设置（在地形材质中）

![image-20210609134053301](C:\Users\xueyaojiang\Desktop\JMX\ShaderToy\UnrealStudy\其他博客阅读\RT应用.assets\image-20210609134053301.png)

1. 首先，你需要得到当前顶点的XY位置。**由于你是从底部捕捉的，X坐标被翻转了**:star:，所以你需要把它翻转回来（如果你是从顶部捕捉的，你就不需要这样做

2. 这一部分实际上会做两件事。首先，它将使渲染目标居中，使其在世界空间中位于（0, 0）。然后，它将从**世界空间**转换到**UV空间**。

确保将Texture Sample的纹理设置为RT Capture：

![image-20210609135943390](RT应用.assets\image-20210609135943390.png)

注意这里的位置节点是如下的**材质函数**，逻辑也很简单

![image-20210609135852935](RT应用.assets\image-20210609135852935.png)

这将把渲染目标投射到地面上。然而，捕获区域之外的任何顶点都将采样渲染目标的边缘。这是一个问题，因为**渲染目标**只用于捕获区域内的顶点。为了解决这个问题，你需要屏蔽任何落在0到1范围之外的UV。`MF MaskUV0-1`函数是为此而构建的函数。如果提供的UV在0到1范围之外，它将返回0；如果在范围内，它将返回1。将结果与渲染目标相乘将执行屏蔽。

## 使用RT

让我们从混合颜色开始：

![image-20210609140247621](RT应用.assets\image-20210609140247621.png)

现在，当有一个踪迹，地面的颜色将是棕色。如果没有踪迹，它将是白色的。下一步是替换顶点。为此：

![image-20210609141121134](RT应用.assets\image-20210609141121134.png)

然后回到主编辑器。在关卡中创建一个`BP_Capture`的实例，并将其位置设置为`(0, 0, -2000)`，使其位于地面之下。按下Play，用W、A、S和D走动，开始对雪进行变形。

![image-20210609141603473](RT应用.assets\image-20210609141603473.png)

## 创造持久的痕迹

那么肯定是乒乓缓冲。

![unreal engine snow](RT应用.assets\unreal-engine-snow-persistent.gif)

创建一个名为RT Persistent的渲染目标。接下来，您需要一个将**捕获**复制到**持久缓冲区**的材料。打开`Materials\M_DrawToPersistent`，然后添加一个Texture Sample节点。将其纹理设置为RT Capture并像这样连接它

![image-20210609161321195](RT应用.assets\image-20210609161321195.png)

现在你需要使用这个**绘制材料**。点击应用，然后打开`BP_Capture`。首先，让我们创建一个材料的动态实例（以后你将需要传入数值）：

![img](RT应用.assets\unreal-engine-snow-20.jpg)

接下来，打开`DrawToPersistent`函数并添加：

![image-20210609161939350](RT应用.assets\image-20210609161939350.png)

接下来，您需要确保每一帧都绘制到持久缓冲区，因为捕获每一帧都会发生。为此，将DrawToPersistent添加到事件Tick中。

![image-20210609162023498](C:\Users\xueyaojiang\Desktop\JMX\ShaderToy\UnrealStudy\其他博客阅读\RT应用.assets\image-20210609162023498.png)

修改深度测试材质：

![image-20210609162712571](C:\Users\xueyaojiang\Desktop\JMX\ShaderToy\UnrealStudy\其他博客阅读\RT应用.assets\image-20210609162712571.png)

结果看起来很棒，但目前的设置只适用于地图的一个区域。如果你走出捕获区域，踪迹将停止出现。



## 移动捕获

你可能认为你所要做的就是将**捕获的XY位置**设置为**玩家的XY位置**。但是如果你这样做，渲染目标就会开始模糊。这是因为你正在以比一个像素小的步骤移动渲染目标。当这种情况发生时，一个像素的新位置最终将在像素之间。这将导致将多个像素插值到单个像素。这是它的样子

![unreal engine snow](RT应用.assets\unreal-engine-snow-10.gif)

要解决这个问题，您需要以**离散的`step`**移动**捕获**。首先，让我们创建一个参数来保持捕获的位置。**地面材质**将需要这个来进行**投影数学运算**。打开MPC_Capture并添加一个名为`CaptureLocation`的矢量参数。

接下来，你需要更新地面材质来使用**新的参数**：

![image-20210609165302321](RT应用.assets\image-20210609165302321.png)

现在**渲染目标**将始终投影在捕获的位置。点击应用，然后关闭材质。接下来是以离散`step`移动捕获。

要计算` pixel’s world size`，可以使用以下等式：

```c++
(1 / RenderTargetResolution) * CaptureSize
```

要计算新的位置，请在每个位置组件（在本例中为X和Y位置）上使用下面的公式：

```c#
(floor(Position / PixelWorldSize) + 0.5) * PixelWorldSize
```

现在让我们在捕获蓝图中使用它们。为了节省时间，我为第二个等式创建了一个`SnapToPixelWorldSize`宏。打开`BP Capture`，然后打开`moveccapture`函数。然后，创建以下设置

![image-20210609165619224](RT应用.assets\image-20210609165619224.png)

![image-20210609170315040](RT应用.assets\image-20210609170315040.png)

然后：

![image-20210609170704213](RT应用.assets\image-20210609170704213.png)

这将使用计算出的偏移量**移动捕获**。然后，它将存储**捕获的新位置**到MPC，以便地面材料可以使用它。最后，你需要在每一帧执行位置更新。关闭函数，然后在事件Tick中DrawToPersistent之前添加MoveCapture。

==移动捕获只是解决方案的一半==。您还需要在捕获移动时**移动持久缓冲区**。否则，捕获和持久缓冲区将不同步并产生奇怪的结果。

![unreal engine snow](RT应用.assets\unreal-engine-snow-11.gif)

## 移动持久缓存区

要移动**持久化缓冲区**，你需要传入你计算的**移动偏移量**。打开`M_DrawToPersistent`，添加

![image-20210609171346597](RT应用.assets\image-20210609171346597.png)

这将使用**提供的偏移量**移动**持久性缓冲区**。就像在地面材质中一样，你也需要**翻转X坐标**并进行遮蔽。点击应用，然后关闭该材质。

接下来，你需要传入移动偏移。打开`BP_Capture`，然后打开`DrawToPersistent`函数。之后，添加：

![image-20210609171845412](RT应用.assets\image-20210609171845412.png)

![unreal engine snow](RT应用.assets\unreal-engine-snow-12.gif)

