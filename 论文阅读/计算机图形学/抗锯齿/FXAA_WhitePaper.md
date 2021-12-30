# FXAA

[toc]



## 实现

### 1. 算法前瞻

![image-20211230141547701](https://s2.loli.net/2021/12/30/VA7h4rpGKPZIigu.png)

==算法流程==参考上图，可以分为以下几步：

1. 输入一张非线性`RGB`图（例如：`sRGB`），并从采样得到的颜色值中得到==亮度==`luminance `。
2. 通过亮度，检查当前像素的**局部对比度**（` local contrast`），来舍弃**非边缘像素**。检测到的边缘为**红色**，向**黄色**渐变表示检测到的**亚像素锯齿的程度**。（drawn using `FXAA_DEBUG_PASSTHROUGH `shader define）。
3. 通过**局部对比度检测**的像素被分类为**金色的水平**，和**蓝色的垂直**。（`FXAA_DEBUG_HORZVERT)`）
4. 根据当前像素的方向，选出和此方向垂直的（成$90^o$），且对比度最高的==像素对==，图中标记为`蓝/绿`。（`FXAA_DEBUG_PAIR`）
5. 沿边缘的负方向和正方向（红/蓝）搜索**边缘的末端**。检查**沿边缘的高对比度像素对的平均亮度**是否有明显变化。（`FXAA_DEBUG_NEGPOS`）
6. 给出**边缘的两端**，**边缘上的像素位置**进行一个**垂直于边缘$90^o$的子像素移动**，以减少锯齿，`红/蓝`为`-/+水平移动`，`金/天蓝`为`-/+垂直移动`。（`FXAA_DEBUG_OFFSET`）
7. 考虑这个**子像素偏移量**，对输入的纹理进行==重新采样==。
8. 最后，根据检测到的**子像素锯齿的程度**，加入一个**低通滤波器**。 



### 2. 亮度转换（过程`1`）

直接使用`R`和`G`通道进行`mad`操作——经验上，`B`通道锯齿很少出现在游戏中：

```c++
float FxaaLuma(float3 rgb) 
{
	return rgb.y * (0.587/0.299) + rgb.x;
}
```



### 3. 局部对比度检查（过程`2`）

**局部对比度检查**使用**东西南北**四个邻域像素。如果局部最大和最小对比度之差小于**阈值**（==正比于最大局部对比度==），则直接退出（不是边缘像素）。这个阈值应该进行`clamp`，避免太小，而错误的处理**黑色区域**。

```c++
float3 rgbN  = FxaaTextureOffset(tex, pos.xy, FxaaInt2( 0,-1)).xyz; 
float3 rgbW  = FxaaTextureOffset(tex, pos.xy, FxaaInt2(-1, 0)).xyz; 
float3 rgbM  = FxaaTextureOffset(tex, pos.xy, FxaaInt2( 0, 0)).xyz; 
float3 rgbE  = FxaaTextureOffset(tex, pos.xy, FxaaInt2( 1, 0)).xyz; 
float3 rgbS  = FxaaTextureOffset(tex, pos.xy, FxaaInt2( 0, 1)).xyz; 
float lumaN  = FxaaLuma(rgbN); 
float lumaW  = FxaaLuma(rgbW); 
float lumaM  = FxaaLuma(rgbM); 
float lumaE  = FxaaLuma(rgbE); 
float lumaS  = FxaaLuma(rgbS); 
float rangeMin = min(lumaM, min(min(lumaN, lumaW), min(lumaS, lumaE))); 
float rangeMax = max(lumaM, max(max(lumaN, lumaW), max(lumaS, lumaE))); 
float range = rangeMax - rangeMin; 
if(range <  max(FXAA_EDGE_THRESHOLD_MIN, rangeMax * XAA_EDGE_THRESHOLD)) 
{ 
    return FxaaFilterReturn(rgbM); 
}
```

> 由此产生的、由艺术家控制的参数：
>
> - `FXAA_EDGE_THRESHOLD`：对比度检测阈值，参考值——`1/3`（too little），`1/4`（low quality），`1/8`（high quality），`1/16`（overkill）
> - `FXAA_EDGE_THRESHOLD_MIN `：最小阈值，参考值——`1/32`（visible limit），`1/16`（high quality），`1/12`（upper limit，start of visible unfiltered edges）



### 4. 亚像素锯齿测试（过程`2`）

首先，**像素对比度`lumaL`**的计算方法是：通过一个**低通滤波器**得到平均值，然后减去中间亮度，意义上就是**绝对差异**。==像素对比度与局部对比度的比率==被用来检测**子像素锯齿**。这个比率在**单像素点存在**的情况下接近`1.0`，而当更多的像素贡献于一个边缘时，开始下降趋于`0.0`。这个比率后续会拿来（最后一步）作为**低通滤波器的强度**。

```c++
float lumaL = (lumaN + lumaW + lumaE + lumaS) * 0.25; 
float rangeL = abs(lumaL - lumaM); 
float blendL = max(0.0, (rangeL / range) - FXAA_SUBPIX_TRIM) * FXAA_SUBPIX_TRIM_SCALE;  
blendL = min(FXAA_SUBPIX_CAP, blendL);
```

在算法的最后，**用于过滤==子像素锯齿==的低通滤波器**是一个完整的**`3x3`的`BOX`滤波器**。

```c++
// 已经采样好的，就直接进行黎曼和
float3 rgbL = rgbN + rgbW + rgbM + rgbE + rgbS; 
// ... 
// 经历了诸多过程，再来采样四个角落，凑出完整的3x3领域
float3 rgbNW = FxaaTextureOffset(tex, pos.xy, FxaaInt2(-1,-1)).xyz; 
float3 rgbNE = FxaaTextureOffset(tex, pos.xy, FxaaInt2( 1,-1)).xyz; 
float3 rgbSW = FxaaTextureOffset(tex, pos.xy, FxaaInt2(-1, 1)).xyz; 
float3 rgbSE = FxaaTextureOffset(tex, pos.xy, FxaaInt2( 1, 1)).xyz; 
rgbL += (rgbNW + rgbNE + rgbSW + rgbSE); 
rgbL *= FxaaToFloat3(1.0/9.0); 
```

> 由此产生的、由艺术家控制的参数：（除了**关闭**或**完全开启**特性外，这些参数==不会影响性能==。默认情况下，**亚像素锯齿的去除程度是有限的**。这使得**细微的特征**得以保留，但**对比度足够低**，这样它们就不会分散眼睛的注意力。**完全开启会使图像模糊**。）
>
> - `FXAA_SUBPIX`：亚像素过滤的开关，参考值——`0`（关闭）、`1`（开启）、`2`（完全开启，忽略`FXAA_SUBPIX_TRI`和`CAP`）
> - ` FXAA_SUBPIX_TRIM`：控制亚像素锯齿的移除，参考值——`1/2`（low removal），`1/3`（medium removal），`1/4`（default removal），`1/8`（high removal），`0`（complete removal）
> - `FXAA_SUBPIX_CAP `：确保**精细的细节**不被完全删除。这部分`覆盖了FXAA_SUBPIX_TRIM`。参考值——`3/4`（default amount of filtering），`7/8`（high amount of filtering），`1`（ no capping of filtering）



### 5. 水平/垂直边缘检测（过程`3`）

像`Sobel`这样的**边缘检测滤波器**在通过像素中心的**单像素线**上效果很差。`FXAA`取**局部3x3邻域**的**行和列的高通值的加权平均幅度**，作为**局部边缘程度**的指示：

```c++
float edgeVert =  
    abs((0.25 * lumaNW) + (-0.5 * lumaN) + (0.25 * lumaNE)) + 
    abs((0.50 * lumaW ) + (-1.0 * lumaM) + (0.50 * lumaE )) + 
    abs((0.25 * lumaSW) + (-0.5 * lumaS) + (0.25 * lumaSE)); 
float edgeHorz =  
    abs((0.25 * lumaNW) + (-0.5 * lumaW) + (0.25 * lumaSW)) + 
    abs((0.50 * lumaN ) + (-1.0 * lumaM) + (0.50 * lumaS )) + 
    abs((0.25 * lumaNE) + (-0.5 * lumaE) + (0.25 * lumaSE)); 
bool horzSpan = edgeHorz >= edgeVert;
```

> 那个话看似复杂，实际上很简单，这个还是得看示意图：
>
> Todo，灵魂画师用平板画。



### 6. 边缘末端检测（过程`5`）

给定**局部边缘方向**，`FXAA`将选出和此方向垂直的（成$90^o$），且**对比度最高的==像素对==**。算法沿着正方向和负方向进行搜索，直到达到**搜索极限**，或者沿着边缘移动的`pair`的**平均亮度变化**足以表示边缘结束。

在水平或垂直方向上平行搜索**负方向和正方向**（==单个循环==）。这样做是为了避免在着色器中的分支。

==搜索加速的原理==（预设`0`、`1`和`2`）：使用**各向异性过滤**作为**盒式过滤器**来检查不止一个像素对。

```c++
for(uint i = 0; i < FXAA_SEARCH_STEPS; i++) { 
    #if FXAA_SEARCH_ACCELERATION == 1 
        if(!doneN) lumaEndN = FxaaLuma(FxaaTexture(tex, posN.xy).xyz); 
        if(!doneP) lumaEndP = FxaaLuma(FxaaTexture(tex, posP.xy).xyz); 
    #else 
        if(!doneN) lumaEndN = FxaaLuma(FxaaTextureGrad(tex, posN.xy, offNP).xyz); 
        if(!doneP) lumaEndP = FxaaLuma(FxaaTextureGrad(tex, posP.xy, offNP).xyz); 
    #endif 
    doneN = doneN || (abs(lumaEndN - lumaN) >= gradientN); /*负方向*/
    doneP = doneP || (abs(lumaEndP - lumaN) >= gradientN); /*正方向*/
    if(doneN && doneP) break; 
    if(!doneN) posN -= offNP; 
    if(!doneP) posP += offNP; 
} 
```

> 由此产生的、由艺术家控制的参数：（==这些定义对性能有最大的影响==。注意，使用**搜索加速**可能会在边缘过滤中引起**一些抖动**。）
>
> - `FXAA_SEARCH_STEPS`：控制搜索步数的最大值。乘以`FXAA_SEARCH_ACCELERATION`的**过滤半径**。
> - `FXAA_SEARCH_ACCELERATION`：各向异性过滤加速搜索的程度，参考值——`1`（无加速）、`2`（跳过`2`个像素）、`3`（跳过`3`个）、`4`。
> - `FXAA_SEARCH_THRESHOLD`：控制什么时候停止搜索，参考值——`1/4`（似乎是最佳选择）。此外，个人觉得，==代码中的`gradientN`就和这个参数有关==。



### 7. 关于后续的过程`4`，`5`，`6`

首先，这三个过程其实主要是为了==一个目的==，那就是获得**当前像素的偏移量**。这个偏移量又和**边缘的末端**有什么关系呢？

在我看来，首先这个边缘越长，说明这个边越`水平/垂直`，因为我们采样就是按照标准方向来的，所以哪怕这个边实际上很长，但是如果它很斜的话，那么我们的循环也走不长。所以，我们可以得出第一个结论：两个端点距离越长，则偏移量越小。

但仅仅这样想，会有一个问题，那就是这个边真的很短，而且有真的很标准（完全垂直或水平），那么，我们此时就不能按照上诉想法，给它分配一个**较大的偏移量**。这个时候，就引出了第二个评判标准，那就是，这个像素如果离某一个端点很近，那么哪怕这个边不长，也应该给它分配一个**小的偏移量**。

最后，给出每一步的意义：

- 过程`4`：仅仅是为了获得最大对比度对，来作为第五步的截止条件。
- 过程`5`：搜索得到两个端点。
- 过程`6`：利用两个端点和上诉分析得到的两个规则，给当前像素一个偏移量。
- 过程`7`和`8`：使用偏移量，重新确定当前像素的采样中心，然后根据亚像素锯齿程度来决定`box`过滤核的大小，进行最后的过滤。



### 8. 技术总结

就我个人感觉，`FXAA`的核心就是两个：

- 重新确定采样核心位置。
- 确定过滤核的半径。