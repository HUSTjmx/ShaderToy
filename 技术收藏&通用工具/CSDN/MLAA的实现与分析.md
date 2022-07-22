	前言：本文主要参考《Morphological Antialiasing》和《Practical Morphological Antialiasing》
## 1. 介绍
`MSAA`有不可忽视的缺点。首先，会导致**处理时间的增加**。此外，在大部分平台上（旧的），使用**多个渲染目标**（`MRT`）时，不能激活多重采样。即使在可以同时激活`MRT`和`MSAA`的平台上（即`DirectX 10`以上），`MSAA`的实现也不简单。`MSAA`的另一个缺点是==不能平滑非几何边缘==，比如使用**Alpha Test**所产生的边缘——在**渲染植被**时经常使用。因此，如果使用`MSAA`，只有在使用`alpha to coverage `的情况下，植被才能**抗锯齿化**。

`MLAA`基于识别图像中的某些**模式**（`patterns`）。根据原论文，`MLAA`算法主要分为以下三个步骤：
 - 在给定的图像中找到**像素之间的不连续点**。
 - 识别**预定义的模式**。
 - 在这些`patterns`的附近混合颜色

而根据原论文，模式主要分为三个：`L`、`Z`、`U`。如下图：
![《Morphological Antialiasing》图](https://img-blog.csdnimg.cn/16ec4bcd0b97410c9010eb64913d7e76.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16#pic_center)
更加直观的解释，可以参考《**Practical Morphological Antialiasing**》，它的算法解释如下：
 1. 首先，**使用深度值进行边缘检测**（另外，亮度也可以用来检测边缘；也可以参考`FXAA`中的优化亮度检测的方案）。
 2. 然后，对于**属于一个边缘的每个像素**，我们计算从它到该边缘所属的**两端像素的距离**。这些距离定义了该像素**相对于线的位置**。根据下列公式进行**混合操作**：
	![在这里插入图片描述](https://img-blog.csdnimg.cn/db3e1fa5dba0425d9816f53a4156d9f8.png#pic_center)
	![在这里插入图片描述](https://img-blog.csdnimg.cn/2f7d7220ad0446628bd74b250539f0ec.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_17,color_FFFFFF,t_70,g_se,x_16)
  3. 

该算法分三个`pass`实施：

- 在第一个`pass`中，进行**边缘检测**，产生一个**包含边缘的纹理**（见图左中）。
- 在第二个`pass`中，得到与平滑的边缘相邻的**每个像素的相应混合权重**（即值`a`）（见图右中）。要做到这一点，我们首先要检测**通过像素的北面和西面边界的每条线的图案类型**，然后计算**每个像素到`crossing edges`的距离**；然后用这些来查询**预先计算的区域纹理**。
- 第三个也是最后一个`pass`：利用前一个过程中**获得的混合权重纹理**，将每个像素与其四邻进行混合。
![在这里插入图片描述](https://img-blog.csdnimg.cn/0bca1e3a9fef4d66a7e96773e996fb10.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)
## 2. Pass1 : 边缘检测
### 2.1 基本实现
如果我们有**深度信息**，就使用**深度信息**进行**边缘检测**（单独处理一张图像，可能没有深度信息，那么就使用**亮度值**）。具体流程：对于每一个像素，获取它四周（上下左右）领域的深度，和其本身的深度相减得到差值；然后将差值进行**阈值化**，得到`0`或`1`，存入`RGBA`中（依次是：左、上、右、下）。

> 观看下面代码的一个疑惑：不是边缘的区域会`discard`，意义何在？个人猜测：不是边缘，就干脆别写了，反正都是`vec4(0)`——这样就节省了**write texture的开销**。

```cpp
// 以下代码来自《Practical Morphological Antialiasing》
float4 EdgeDetectionPS(float4 position: SV_POSITION, 
                       float2 texcoord: TEXCOORD0) : SV_TARGET 
{ 
    
    float D = depthTex.SampleLevel(PointSampler, texcoord, 0);
    float Dleft = depthTex.SampleLevel(PointSampler, texcoord, 0, -int2(1, 0));
    float Dtop = depthTex.SampleLevel(PointSampler, texcoord, 0, -int2(0, 1));
    float Dright = depthTex.SampleLevel(PointSampler, texcoord, 0, int2(1, 0));
    float Dbottom = depthTex.SampleLevel(PointSampler, texcoord, 0, int2(0, 1));
    
    float4 delta = abs(D.xxxx - float4(Dleft, Dtop, Dright, Dbottom));
    float4 edges = step(threshold.xxxx, delta);
    
    if (dot(edges, 1.0) == 0.0) 
    { 
        discard;
    }
    
    return edges;
}
```
通过这个`Pass`，我们可以得到如下的结果：

![在这里插入图片描述](https://img-blog.csdnimg.cn/53c0c9239e3846eb98dd545367d46e75.png)

### 2.2 深度检测的扩展
使用**基于深度的边缘检测**时，在两个不同角度的平面相遇的地方可能会出现一个问题：**由于样本具有相同的深度，边缘将不会被检测到**。一个常见的解决方案是**增加法线的信息**。


### 2.3 亮度检测
使用**亮度信息**来检测**图像的不连续性**。亮度值是由**CIE XYZ（色彩空间）标准**得出的：
![在这里插入图片描述](https://img-blog.csdnimg.cn/f9e05a9bf1954808af29756a6666a1ad.png)
而如果我们是在开发游戏，那么一个**常见的优化方案**是不考虑`B`通道（因为在游戏的画面中，锯齿的来源大概率和`B`无关）：

```cpp
float FxaaLuma(float3 rgb) 
{
	return rgb.y * (0.587/0.299) + rgb.x;
}
```
如果是使用亮度检测，一个合理的阈值是`0.1`。当相对于亮度检测，深度价测的鲁棒性更强，开销更小。但**亮度检测**允许对**阴影和镜面高光**进行抗锯齿。


通过结合**亮度、深度和法线**，可以获得**质量方面的最佳结果**，但代价是**执行时间较长**。


## 3. Pass2 : 计算混合权重
为了计算**混合权重**，我们首先利用前一阶段获得的**边缘纹理**，搜索**边缘所属的线条两端的距离**。一旦知道了这些距离，我们就可以用它们来获取**线条两端的交叉边缘**。这些交叉边表明我们**正在处理的模式类型**。**到线的两端的距离**和**图案的类型**被用来访问**预先计算的纹理**。而这个预计算纹理中存取的就是**对应的权重值**。

![在这里插入图片描述](https://img-blog.csdnimg.cn/1e02dd1b51b24520b02a7a4490275e3e.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_19,color_FFFFFF,t_70,g_se,x_16)
这里就是大佬实现的巧妙之处了，利用**两个相邻的像素共享相同的边界**这个现实，在相邻的像素之间共享计算结果。

先抛开**复杂的计算流程**，我们只专注于**最终的输出结果**。以上图为例子：`[1, 1]`处最后`Pass`的存储结果分别是`R`（用于当前像素`[1, 1]`的北部混合权重）、`G`（`[1,2]`的南部混合权重）、`B`（用于当前像素`[1, 1]`的西部混合权重）、`A`（`[0,1]`的东部混合权重）。这里我们就可以看出**共享结果**这个巧妙技术。

> PS：下面的什么**北边**、**西边**，都是类似**北部的边**这样的简称！

如果仔细阅读下述代码，第一个疑惑点必然是：**为什么，我们只考虑北边和西边？**。看看上图，这个边是`[1,1]`的北边，但它也同时也是`[1,2]`的南边！我们上个段落已经解释了**结果各通道的意义**，在结合这里的话，我们可以总结以下结论：**我们每次寻边，都可以得到两个收获，一个是当前像素的权重，一个是相对像素的权重；而每一个像素都是需要四个权重，来混合周边；以`[1,1]`为例子，虽然我们只寻边两次，获得了它相对北部、西部的权重，但实际上，它的南部的权重已经存在了`[1,0]`的`g`通道中，它的东部权重已经存储到（或者即将计算得到）了`[2,1]`的`A`通道中。**

本人的语文水平实在有限，讲的不清楚，但希望**未来的我**和**读者**可以理解上诉的核心思想。讲了这么多，上代码：

```cpp
float4 BlendingWeightCalculationPS(float4 position: SV_POSITION,
								   float2 texcoord: TEXCOORD0): SV_TARGET 
{
    
    float4 weights = 0.0;
    
    // 当前像素是否存在北部的边、西部的边
    float2 e = edgesTex.SampleLevel(PointSampler, texcoord, 0).rg;
    
    [branch] 
    if(e.g)
    { 
        // 寻找北部的边，获取了边的两个端点的位置
        float2 d = float2(SearchXLeft(texcoord), 
                          SearchXRight(texcoord));
        
        // Instead of sampling between edges , we sample at -0.25, 
        // to be able to discern what value each edgel has. 
        // mad(m, a, d) : x = m * a + d
        float4 coords = mad(float4(d.x, -0.25, d.y + 1.0, -0.25), 
                            PIXEL_SIZE.xyxy, texcoord.xyxy);
        
        float e1 = edgesTex.SampleLevel(LinearSampler, coords.xy, 0).r;
        float e2 = edgesTex.SampleLevel(LinearSampler, coords.zw, 0).r;
        
        weights.rg = Area(abs(d), e1, e2);
    }
    
    [branch] 
    if (e.r) 
    { 
        // 寻找西部的边，获取了边的两个端点的位置 
        float2 d = float2(SearchYUp(texcoord), SearchYDown(texcoord));
   
        float4 coords = mad(float4(-0.25, d.x, -0.25, d.y + 1.0), 
                            PIXEL_SIZE.xyxy, texcoord.xyxy);
        
        float e1 = edgesTex.SampleLevel(LinearSampler, coords.xy, 0).g;
        float e2 = edgesTex.SampleLevel(LinearSampler, coords.zw, 0).g;
        weights.ba = Area(abs(d), e1, e2);
    }
    
    return weights;
}
```

顺序阅读代码，我们就遇到了第一个子函数`SearchXLeft`，也是我们第一个需要考虑的问题——**怎么寻找边的端点？**

### 3.1 寻找边的端点（距离）
![在这里插入图片描述](https://img-blog.csdnimg.cn/4593a9dd078e46508ccab2873cc3489e.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)
**搜索到线两端的距离**是通过**一个迭代算法**进行的，在每个迭代中检查**是否已经到达了线的末端**。

为了加速这一搜索，大佬利用了边缘纹理（第一个`Pass`得到结果）中**存储的信息是二进制**的这一事实——并使用**双线性滤波**从像素间的位置进行查询，***一次获取两个像素***（见上图，这个思路可太强了）。解释一下：我们采样的不是`0.0`中心处，而是`0.0`和`-1.0`的边界处，这样就可以利用硬件过滤，得到两个像素的信息。查询的结果就具有了判断性，可以是：
 - ` 0.0`，这意味着两个像素**都不包含边缘**
 - `1.0`，这意味着两个像素中**都存在边缘**
 - `0.5`，当两个像素中**只有一个包含边缘**。如果返回值低于`1`，我们就**停止搜索**。

这样处理除了可以**快速判断边缘与否**，还可以**加速**，因为我们每次获得的是两个像素的信息，例如：在`-1.0`和`-2.0`的边界处采样结果是`1`，那么我们就可以不用管`-2.0`，下次直接采样`-3.0`和`-4.0`的边界处——**我们跳过了两个像素进行采样**！

下面给出**水平边缘**的寻边代码：

```cpp
float SearchXLeft(float2 texcoord) 
{ 
    texcoord -= float2 (1.5, 0.0) * PIXEL_SIZE; 
    float e = 0.0; 
    
    // We offset by 0.5 to sample between edges , thus fetching 
    // two in a row. 
    int i;
    for (i = 0; i < maxSearchSteps; i++) 
    { 
        e = edgesTex.SampleLevel(LinearSampler, texcoord, 0).g; 
        // We compare with 0.9 to prevent bilinear access precision 
        // problems. [flatten] 
        if (e < 0.9) break; 
        texcoord -= float2 (2.0, 0.0) * PIXEL_SIZE;
    } 
    
    // When we exit the loop without finding the end , we return 
    // -2 * maxSearchSteps. 
    return min(-2.0 * i - 2.0 * e, -2.0 * maxSearchSteps);
}

float SearchXRight(float2 texcoord) {
    texcoord += float2(1.5, 0.0) * PIXEL_SIZE;
    float e = 0.0;
    for (int i = 0; i < maxSearchSteps; i++) {
        e = edgesTex.SampleLevel(LinearSampler, texcoord, 0).g;
        [flatten] if (e < 0.9) break;
        texcoord += float2(2.0, 0.0) * PIXEL_SIZE;
    }
    return min(2.0 * i + 2.0 * e, 2.0 * maxSearchSteps);
}
```
代码中需要解释的地方：

 - 为什么函数一开头要`+/- 1.5`个`PIXEL_SIZE`？我们既然可以进入这个函数，就说明当前像素是存在对应边的（`g`通道为`1`）。那么我们就不需要考虑当前像素，我们应该考虑**左一和左二的边缘性**（这里是举个例子），因此我们应该往左偏移`1.5`个单位，来符合采样条件。
 - 循环过程比较简单，就不赘述了。
 - 返回值的逻辑。首先，我们限定了**边的最大搜索步数**，用`min`来进行钳制。其次，则是$-2.0*i-2.0*e$，`2.0`是由于我们是跳两个像素采样一次，`e`则是进行修正——因为我们是小于`1`就截止搜素，此时就会有两种情况，要么两个像素都不是边，要么临近的那个是，我们要区分这两种情况。


> ![在这里插入图片描述](https://img-blog.csdnimg.cn/1650271f19404b34abb303a25eeb3c56.png)
代码补充理解，举个例子，目前我们传入的像素坐标是上图的`1.0`处（最右边，下面那个），然后我们首先要向左偏移`1.5`个像素距离，这样我们采样的位置就位于`0.0`和`-1.0`中间处，所以会进行双线性插值（实际上这个特殊位置只会受到左右两边像素的影响），这里采样值是`1.0`，我们就知道这两个像素都是边，所以我们在循环中，每次跳两个像素。而一旦采样值低于`1`，则说明这次验证的两个像素中，左边那个不是边，这个时候就停止迭代，返回这个边的左端点距离此像素的距离。

### 3.2 获得Crossing edges
计算出到**线的两端的距离**后，我们还需要知道端点处的`pattern`。这里就和原论文的方法不一样，做出了改进，我们只需要面对如下**四个模式**，而无须考虑**模式的分割**。
![在这里插入图片描述](https://img-blog.csdnimg.cn/f881776a26744481912a5cd19bde3a84.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_20,color_FFFFFF,t_70,g_se,x_16)
最原始的方法，就是查询**端点外第一个像素的边缘情况**以及**它所相对的那个像素的边缘情况**。值得注意的是，以**北部的边**（上图）为例，我们肯定不是再次查询`g`通道（毕竟，查找端点的截止条件就是：`g`通道为`0`），而是查询`r`通道，获得此像素的**垂直边缘情况**。

一个更有效的方法是**使用双线性过滤**（原理是一致的），以类似于**距离搜索**的方式，**一次性获取两条边**。然而，在这种情况下，我们必须能够区分**每个边的实际值**，所以我们用`0.25`的偏移量进行查询，使我们能够在只有一条边的情况下区分哪条边等于`1.0`。具体来说：当前像素会占据`3/4`的权重，而对应像素占据`1/4`权重，这样就可以得到`0.25`和`0.75`两个情况。

这里的代码，其实已经给出了，就在**权重函数的主体**内：

```cpp
// Edge at north. 
float2 d = float2(SearchXLeft(texcoord), 
                  SearchXRight(texcoord));

// Instead of sampling between edges , we sample at -0.25, 
// to be able to discern what value each edgel has. 
// mad(m, a, d) : x = m * a + d
float4 coords = mad(float4(d.x, -0.25, d.y + 1.0, -0.25), 
                    PIXEL_SIZE.xyxy, texcoord.xyxy);

// e1是左端点模式，e2是右端点模式
float e1 = edgesTex.SampleLevel(LinearSampler, coords.xy, 0).r;
float e2 = edgesTex.SampleLevel(LinearSampler, coords.zw, 0).r;
```

### 3.3 预计算区域纹理
有了**距离和边缘模式信息**，我们就可以了计算**当前像素所对应的面积**（也就是混合权重）。
![在这里插入图片描述](https://img-blog.csdnimg.cn/4a5e4ea2b09a48f59e722b5e8dbadd8d.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_13,color_FFFFFF,t_70,g_se,x_16)

由于**直接计算**是一个昂贵的操作，大佬选择在**一个四维表**中进行预计算，并将其存储在**二维纹理**中（见上图）。这个纹理被分为大小为$9×9$的子纹理，**每个子纹理对应于一个模式类型**（依次是`0.0`，`0.25` ，`0.5`——不存在，所以有个黑色的十字架，`0.75`，`1.0`）。在每个子纹理内，$(u，v)$坐标对应于**到线的两端的距离**，`8`是可达到的最大距离。如果需要一个**更高的最大距离**，可以**提高分辨率**。

**实时代码**进行**纹理的读取**暂且不谈，我们看看这张图是怎么生成的：

```python
## 来自GPU PRO2的源码
from pprint import *
from numpy import *
from PIL import Image

# 生成的图是 32x32 
SIZE = 32
A = {}

# 个人理解，第一个循环，i的意思是线段总长。第二个循环，j的意思是线段左半部分的长度
for i in range(0, 64):
    left = 0.5
    t = []
    for j in range(i):
        x = i / 2.0
        
        # right的值是 0.5-->-0.5
        right = 0.5 * (x - j - 1) / x
        
        # if sign(left) == sign(right) or abs(left) != abs(right)
        # 	 a = abs((left + right) / 2)
        # else
        # 	 a = 0.5 * abs(left / 2)	
        # 感知上，把a的值划分为曲线的话，是由最大值0.5，到一个极低值，然后再次升到0.5。应该是个V字。
        # 之所以要有这个判断，主要是为了防止 a=0，尽管逻辑上，每个循环都只会走一次else分支
        a = abs((left + right) / 2) if sign(left) == sign(right) or abs(left) != abs(right) else 0.5 * abs(left / 2)
        
        # 存入数组
        t += [a]
        
        # 用right更新left
        left = right
        
    A[i] = t

# 初始化数组  32x32 
T = zeros((SIZE,SIZE))

for left in range(SIZE):
    for right in range(SIZE):
    	# 只要理解上两个循环的意思，就可以理解数组A，也就不难理解这里的逻辑了
        x = left + right + 1
        T[left][right] = A[x][left]

pprint(T)

# 保存数据到图片中
image = Image.new("L", (SIZE, SIZE))
for y in range(SIZE):
    for x in range(SIZE):
    	# 转换成RGB值
        val = int(255.0 * T[x][y])
        image.putpixel((x, y), val)
image.save("areas2d.tif")

```

```python
## 来自GPU PRO2的源码
from pprint import *
from PIL import Image

SIZE = 9
def arrange(v1, v2):
    return v1, v2, 0

## 上一步生成的2D area图
areas = Image.open("areas2d.tif")

# 初始化输出 45x45
image = Image.new("RGB", (SIZE * 5, SIZE * 5))

# 外两层循环，选择不同的左右端点模式的组合
for e2 in range(5):
    for e1 in range(5):
    	# 以下循环确定好了左右端点的模式。
        for left in range(SIZE):
            for right in range(SIZE):  
              	
              	# 左，右端点的长度
                p = left, right
                # 读取对应的权重值 a
                a = areas.getpixel(p)
                # 计算需要存取的像素位置
                p = p[0] + e1 * SIZE, p[1] + e2 * SIZE
                
                # 根据模式的不同，修改权重a
                # 0.5的情况实际是不可能发生的
                if (e1 == 2) or (e2 == 2):
                    image.putpixel(p, arrange(0,0))
                # 左端点距离大于右端点的情况
                elif left > right:
                    if e2 == 0:
                        image.putpixel(p, arrange(0,0))
                    elif e2 == 1:
                        image.putpixel(p, arrange(0,a))
                    elif e2 == 3:
                        image.putpixel(p, arrange(a,0))
                    else:
                        image.putpixel(p, arrange(a,a))
                # 左端点距离小于右端点的情况
                elif left < right:
                    if e1 == 0:
                        image.putpixel(p, arrange(0,0))
                    elif e1 == 1:
                        image.putpixel(p, arrange(0,a))
                    elif e1 == 3:
                        image.putpixel(p, arrange(a,0))
                    else:
                        image.putpixel(p, arrange(a,a))
                # 左端点距离等于右端点的情况
                else:
                    if (e1+e2) == 0:
                        image.putpixel(p, arrange(0,0))
                    elif (e1+e2) == 1:
                        image.putpixel(p, arrange(0,a))
                    elif (e1+e2) == 2:
                        image.putpixel(p, arrange(0,2*a))
                    elif (e1+e2) == 3:
                        image.putpixel(p, arrange(a,0))
                    elif (e1+e2) == 4:
                        image.putpixel(p, arrange(a,a))
                    elif (e1+e2) == 5:
                        image.putpixel(p, arrange(a,2*a))
                    elif (e1+e2) == 6:
                        image.putpixel(p, arrange(2*a,0))
                    elif (e1+e2) == 7:
                        image.putpixel(p, arrange(2*a,a))
                    else:
                        image.putpixel(p, arrange(2*a,2*a))
                        
image.save("areas4d.tif")

```

耐着性子对代码逻辑进行了分析（这里只是进行总结，详细分析还是见代码中的注释）：

 - 对于`areamap2d.py`：主要是生成左端距离`e1`和右端距离`e2`所对应的权重值`a`——$a_{left,right}= Area_{2D}[left][right]$。如果固定线段总长度，例如`16`，分割点从最左端（$left=0,right=16$）到最右端（$left=16,right=0$），`a`的值从最大值`0.5`，降低到最小值`1/128`，然后再次回升到`0.5`——一个对称的`V`字！。注意：这里没有考虑**端点模式**！
 - 对于`areamap4d.py`：外两层循环，选择不同的左右端点模式的组合，内两层循环确定左端点距离`e1`，右端点距离`e2`。依靠`e1`、`e2`读取第一步的结果，获得初始权重`a`。最后根据`e1`和`e2`的大小关系、模式，来存入不同的值。（这里就不进行分析了，但估计就是简单的逻辑）


实时读取`area`纹理的代码就很简单了，主要就是坐标的变换，获得正确的`UV`：

```cpp
#define NUM_DISTANCES 9 
#define AREA_SIZE (NUM_DISTANCES * 5)

float2 Area(float2 distance, float e1, float e2) 
{ 
    // * By dividing by AREA_SIZE - 1.0 below we are
    // implicitely offsetting to always fall inside a pixel. 
    // * Rounding prevents bilinear access precision problems.
    // round(x) : 最接近x的整数
    float2 pixcoord = NUM_DISTANCES * round(4.0 * float2(e1 , e2)) + distance;
    float2 texcoord = pixcoord / (AREA_SIZE - 1.0); 
    return areaTex.SampleLevel(PointSampler, texcoord, 0).rg;
}
```

到此为止，第二个`Pass`分析完毕！

> ![在这里插入图片描述](https://img-blog.csdnimg.cn/1e02dd1b51b24520b02a7a4490275e3e.png?x-oss-process=image/watermark,type_d3F5LXplbmhlaQ,shadow_50,text_Q1NETiBASk1YSU40MjI=,size_19,color_FFFFFF,t_70,g_se,x_16)
>复习下：以上图为例子：`[1, 1]`处最后`Pass`的存储结果分别是`R`（用于当前像素`[1, 1]`的北部混合权重）、`G`（`[1,2]`的南部混合权重）、`B`（用于当前像素`[1, 1]`的西部混合权重）、`A`（`[0,1]`的东部混合权重）。这里我们就可以看出**共享结果**这个巧妙技术。

## 4. Pass3 : 混合
在这最后一个`pass`中，**每个像素的最终颜色**是根据**权重纹理中存储的面积值**，通过将实际颜色与它的四个邻居混合而获得的。主要访问**混合权重纹理的三个位置**：

 - 当前像素，它给我们提供了北部和西部的混合权重
 - 南部的像素
 - 东部的像素

再一次利用**硬件能力**，使用**四个双线性滤波访问**来混合**当前像素和它的四个邻居**。

```cpp
float4 NeighborhoodBlendingPS( float4 position: SV_POSITION, 
                              float2 texcoord: TEXCOORD0 ): SV_TARGET 
{
    float4 topLeft = blendTex.SampleLevel(PointSampler, texcoord, 0);
    float right = blendTex.SampleLevel(PointSampler, texcoord, 0, int2(0, 1)).g;
    float bottom = blendTex.SampleLevel(PointSampler, texcoord, 0, int2(1, 0)).a;
    // 左、右，上，下四个权重值
    float4 a = float4(topLeft.r, right, topLeft.b, bottom); 
    float sum = dot(a, 1.0);
    
    [branch] 
    // 需要混合，才进入此分支
    if (sum > 0.0) 
    { 
    	// 单位像素size * a ：又是巧妙的利用硬件线性插值，采样当前像素和对应邻域像素，并按权重插值
        float4 o = a * PIXEL_SIZE.yyxx; 
        float4 color = 0.0; 
		
		// 左邻域
        color = mad(colorTex.SampleLevel(LinearSampler, 
                                         texcoord + float2(0.0, -o.r), 0), a.r, color);
        // 右邻域                     
        color = mad(colorTex.SampleLevel(LinearSampler,
                                         texcoord + float2(0.0, o.g), 0), a.g, color);
        // 上邻域                      
        color = mad(colorTex.SampleLevel(LinearSampler, 
                                         texcoord + float2(-o.b, 0.0), 0), a.b, color);
        
        // 下邻域       
        color = mad(colorTex.SampleLevel(LinearSampler, 
                                         texcoord + float2( o.a, 0.0), 0), a.a, color);
        // 平均                     
        return color / sum;
                            
    } 
    else
    { 
        return colorTex.SampleLevel(LinearSampler, texcoord, 0);                         
    }
}
```

 最后一个`pass`相对第二个`pass`，逻辑简单的不是一点半点，这里的注释已经很清楚了。

## 5. 总结（暂时）
《Practical Morphological Antialiasing》实在是太强了，太多技巧令人拍案叫绝，特别是对硬件线性插值的灵活运用，让人印象深刻。本文本意是结合此论文和`MLAA`的原论文，希望对技术进行一个详细的分析，但做着做着，就只依靠《Practical Morphological Antialiasing》（相对于`intel`的论文，这个理解难度容易太多了）。

 - 本文主要就是整理`MLAA`的整个流程，补充很多原论文难以直接理解部分的描述，以及一些内容的实现方式。
 - 本质上就是翻译和总结，但一些地方的理解也确实是我个人的愚见，就厚颜无耻的标注`原创`了。
 - 后续利用`Opengl`或者`shaderToy`把这个实操出来。


## 6. 照葫芦画瓢 
ToDO

## 7. 参考文献
[1] Alexander Reshetov. Morphological Antialiasing. Proceedings of the HPG 2009: Conference on High-Performance Graphics 2009.
[2] Jorge Jimenez, Belen Masia. Practical Morphological Anti-Aliasing.
[3] GPU 360 Rendering.
[4] GPU Pro 2.
[5] Real Time Rendering 4th.
