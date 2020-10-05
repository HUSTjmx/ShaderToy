# Chapter 6——Texturing

In computer graphics，texturing is a process that takes a surface and modifies its appearance at each location using some image， function,，or other data source.。本章主要讨论纹理对于物体表面的影响，对于程序化纹理介绍较少。



## 1. The Texturing Pipeline

图像纹理中的像素通常称为`texel`，以区别于屏幕上的像素`pixels`。Texturing可以通过广义的纹理管道进行描述。

空间位置是Texturing process的起点，当然这里的空间位置更多指的是模型坐标系。这一点在空间中，进行投影获得一组数字，称为纹理坐标，将用于访问纹理，这个过程叫做`Texture  Mapping`，有时纹理图像本身被称为纹理贴图`texture map  `，虽然这不是严格正确的。

在使用这些新值访问纹理之前，可以使用一个或多个相应的函数来转换纹理坐标到纹理空间。这些纹理空间位置用于从纹理中获取值，例如，它们可能是图像纹理中检索像素的数组索引。管道复杂的原因是，每一步都为用户提供了一个有用的控件，但并非所有步骤都需要在任何时候都被激活

<img src="C:\Users\Cooler\Desktop\JMX\ShaderToy\经典阅读\RTR4\阅读笔记\RTR4_C6.assets\image-20201005155742124.png" alt="image-20201005155742124" style="zoom:67%;" />

<img src="C:\Users\Cooler\Desktop\JMX\ShaderToy\经典阅读\RTR4\阅读笔记\RTR4_C6.assets\image-20201005155814664.png" alt="image-20201005155814664" style="zoom: 67%;" />



###  1.1 The Projector Function

==Texture Process中的第一步就是得到物体表面的位置然后将它投影到UV纹理坐标空间==。转化过程中需要`Projector function`，常用的包括：spherical，cylindrical，planar projections   

<img src="C:\Users\Cooler\Desktop\JMX\ShaderToy\经典阅读\RTR4\阅读笔记\RTR4_C6.assets\image-20201005160638679.png" alt="image-20201005160638679" style="zoom: 67%;" />

==纹理坐标也可以从各种不同的参数中生成==，比如视图方向、表面温度或任何可以想象的东西。投影函数的目标是生成纹理坐标。把它们作为位置的函数来推导只是一种方法。

非交互式渲染器通常将这些投影函数当作渲染过程本身的一部分。一个投影函数可能足以满足整个模型的需要，但通常艺术家必须使用工具来细分模型，并分别应用各种投影函数。

在实时工作中，投影函数通常应用于建模阶段，结果也将存储在模型顶点中。但有时也会在顶点或片元着色器中进行应用，这样做可以提高精度，并有助于启用各种效果，包括动画——一些实时算法，例如`environment mapping  `有自己的专门的投影函数。

由于投影方向上的边缘表面有严重的变形，艺术家通常必须手动将模型分解成近平面的碎片。还有一些工具可以通过展开网格来帮助最小化失真，或者创建一组近乎最优的平面投影，或者其他帮助这个过程的工具。我们的目标是让每个多边形在纹理区域中占有更公平的份额，同时保持尽可能多的网格连通性。==连接性是很重要的，因为采样错误会出现在纹理的不同部分相遇的边缘上==。

> This unwrapping process is one facet of a larger field of study, mesh parameterization  。。。具体见书P173

==纹理坐标空间有时候也可以是三维的==，表现为$(u,v,w)$，w是沿着投影方向的深度；也有表现为$(u,v,r,q)$，q作为齐次坐标中的第四个值，它就像一个电影或幻灯片放映机，随着距离的增加，投影纹理的大小也会增加——例如，在舞台或其他表面上投射一个装饰性的聚光灯图案(称为gobo)就很有用。

纹理坐标空间的另外一个主要类型就是==directional==——空间中的每一个点都被一个输入方向所控制。想象这样一个空间的一种方法是：在一个单位球体上的点，每个点的法线表示用于在那个位置访问纹理的方向。代表：`cube map`

==一维纹理==也是有用的：地形建模中通过海拔访问颜色值（绿到白）；雨点的渲染等。



###  1.2 The Corresponder Function

对应函数（Corresponder Function ）将纹理坐标（texture coordinates  ）转化为纹理空间位置（texture-space locations  ），对应函数的一个示例是：使用API选择用于显示的现有纹理的一部分，在后续操作中只使用此子映像。

另外一种类型的对应函数是==矩阵变换==，包括：移动，旋转，缩放，交错等。奇特的是，==纹理的变换顺序必须和我们实际期待的相反==。

==另一类对应函数控制应用图像的方式==。我们知道，当(u, v)在[0,1]范围内时，图像将出现在曲面上。但是在这个范围之外会发生什么呢？对应函数决定了这种行为。在OpenGL中，这种类型的对应函数称为“Wrapping mode”；在DirectX，它被称为“纹理寻址模式”。这类常见的函数有:

- wrap (DirectX), repeat (OpenGL), or tile ：图像在表面重复;算法上，纹理坐标的整数部分被删除。这个功能对于一个材料的图像重复覆盖一个表面非常有用，并且通常是默认的。

- mirror：也是重复，但是每次重新开始之前，会进行翻转。

- clamp (DirectX) or clamp to edge (OpenGL)  ：图像纹理边缘的重复。

- border (DirectX) or clamp to border (OpenGL)  ：自定义纯色。

  ![image-20201005165322898](C:\Users\Cooler\Desktop\JMX\ShaderToy\经典阅读\RTR4\阅读笔记\RTR4_C6.assets\image-20201005165322898.png)

tile模式形成的图像大部分是无法令人信服的，避免这种周期性问题的一个常见解决方案是将纹理值与另一个非平铺纹理相结合。另外一种是：implement specialized corresponder functions that randomly recombine texture patterns or tiles  。



### 1.3 Texture Values

图像纹理构成了实时工作中纹理使用的绝大部分，但是程序纹理也可以使用。在程序纹理的情况下，从纹理空间位置获得纹理值的过程不涉及内存查找，而是计算一个函数。



## 2. Image Texturing

在本章的其余部分，图像纹理将被简单地称为纹理。此外，当我们在这里引用一个像素的单元格时，我们指的是围绕该像素的屏幕网格单元格。在本节中，我们特别关注==快速采样和过滤纹理图像的方法==。纹理也会有采样问题，但是它们发生在被渲染的三角形内部。

像素着色器通过将纹理坐标值传递给调用(如texture2D)来访问纹理，不同API中的纹理坐标系统有两个主要区别。DirectX中左上角是（0，0），右下角是（1.1）；OpenGL中，左下角是（0，0），右上角是（1，1）。texel有整数坐标，但我们经常希望访问texel之间的位置并在它们之间混合——这就产生了一个问题，即一个像素中心的浮点坐标是什么。之前的DX版本有将（0，0）置为像素中心，而现在统一为（0.5，0.5）。

==dependent texture read== ：这是个值得解释的问题，有两个解释。第一个适配的是移动设备，当通过texture2D或类似方式访问纹理时，当像素着色器计算纹理坐标而不是使用从顶点着色器传入的未经修改的纹理坐标时，依赖纹理读取就会发生。当着色器没有依赖纹理读取时，运行效率更高，因为texel数据可以被预取。这个术语的另一个较早的定义对于早期的桌面gpu尤其重要。在这种情况下，当一个纹理的坐标依赖于前一个纹理的值时，就会发生依赖纹理读取。例如，一个纹理可能会改变阴影法线，这反过来会改变用于访问立方体映射的坐标。现在，这类读取可能会对性能产生影响，具体取决于批量计算的像素数以及其他因素。

在GPU中使用的纹理的分辨率一般是$2^m\times 2^n$，被称作 power-of-two（POT）textures。现代GPU也能处理NPOT。

本章讨论的图像采样和滤波方法应用于从每个纹理读取的值。这里的区别是过滤渲染方程的输入，还是过滤它的输出。本来，对于颜色来说，渲染方程一般是线性的，所以filter的位置无所谓，但是对于其它存储在纹理中的数据，如法线，对于最后输出而言是非线性的关系，标准的纹理过滤会导致锯齿。



### 2.1 Magnification

对于纹理放大==最常见的过滤技术==是`nearest neighbor`（实际上是Box Filter）和`bilinear interpolation`（双线性插值）。还有`cubic convolution  `立方卷积，它使用一个4×4或5×5的texels数组的加权和，得到更高的放大质量。虽然本地硬件对立方卷积，也称为`bicubic interpolation  `，的支持目前还不普遍，但它可以在一个着色程序中执行。

使用==最近邻法==这种放大技术的一个特点是，单个的texels可以变得明显。这种效果被称为==像素化==，因为该方法在放大时取每个像素中心最近的texel值，从而导致块状外观。虽然这种方法的质量有时很差，但它只需要取 1Texel/pixel。（下左图）



<img src="C:\Users\Cooler\Desktop\JMX\ShaderToy\经典阅读\RTR4\阅读笔记\RTR4_C6.assets\image-20201005203836975.png" alt="image-20201005203836975" style="zoom:67%;" />

对于==双线性插值法==：对于每个像素，这种滤波方法找到四个相邻的纹理，并在二维上进行线性插值，从而找到像素的混合值。结果更加模糊了，使用最近邻方法产生的锯齿也消失了。（上中图）