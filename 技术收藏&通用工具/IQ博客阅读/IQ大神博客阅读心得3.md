## IQ大神博客阅读心得3

*蒋孟贤，2020.04，*

| [Bitmap Orbit Traps](#Bitmap-Orbit-Traps)                    | 在轨道陷阱的基础上读取纹理                    |
| ------------------------------------------------------------ | --------------------------------------------- |
| [Distance Rendering For Fractals](#Distance-Rendering-For-Fractals) | 使用格林函数G计算从当前像素到该集的边界的距离 |
|                                                              |                                               |
|                                                              |                                               |
|                                                              |                                               |
|                                                              |                                               |
|                                                              |                                               |
|                                                              |                                               |
|                                                              |                                               |
|                                                              |                                               |

#### Bitmap Orbit Traps

在前面基础的Mandelbrot集的基础上，通过Z的值，经过简单特异性的处理，将其作为UV坐标对图像进行采样，对于代码而言，核心是**if(color.w>0.1)break;**

个人分析：我们读取的图片BG的透明度是0，只有中部的猫的透明度大于0.1（应该是1），那么我们生产的图像的BG区域，也就是逃离陷阱的点，它的Z值大于1，那么在采样时，取的点是边角点，那个位置的w为0，那么此时就常规退出。那么为什么这个代码是核心呢？个人理解是在Z的迭代赋值中，没有逃离，但是正确采样到了猫，这个时候不需要继续迭代了，也不需要判断会不会逃离了，直接退出。感觉自己也解释不清，直接分析点的情况：

1. 未采样到猫，直接逃离：BG，原本也应该是BG
2. 不逃离，但未采样到猫：BG，原本应该是图像
3. 不逃离，采样到猫：猫，原本也应该是图像
4. 逃离之前采样到猫：猫，原本应该是BG（这个类型就是关键代码保留下的点）

```c#
vec4 getColor(vec2 p)
{
    p=clamp(p,0.0,1.0);
    p.x=p.x*40.0/256.0;
    p=clamp(p,0.0,1.0);
    float fr=floor(mod(20.0*iTime,6.0));
    p.x+=fr*40.0/256.0;
    return texture(iChannel0,p);
}
...
if(color.w>0.1)break;
z=vec2(z.x*z.x-z.y*z.y,2.*z.x*z.y)+c;
color=getColor(z);
```

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/fractals%20rendering%20algorithms/GOT%20bitmap.gif)



#### Distance Rendering For Fractals

呈现诸如Julia或Mandelbrot多项式集之类的分形的一种好方法是使用从当前像素到该集的边界的距离。这避免了渲染分形的常见混叠问题，在分形中，细节太小而无法通过图像采样看到。无需在本文中进行详细介绍（有关数学部分），可以通过其格林函数G来计算到Mandelbrot集的距离，该函数是一个连续函数。因此，根据在连续函数中逼近等值面的通常方法，我们可以估算到分形面的距离为：
$$
\begin{align}
d&=\frac{G(c)}{|G^`(c)|}
\\
G(c)&=\lim_{n\rightarrow \infty}\frac{1}{2^n}log|Z_n|
\\
|G^`(c)|&=\lim_{n\rightarrow \infty}\frac{1}{2^n}\frac{|z^`_n|}{|z_n|}\\
d&=\lim_{n\rightarrow \infty}\frac{|z_n|\cdot log|z_n|}{|z^`_n|}
\end{align}
$$
基本上，这意味着比在我们的常规迭代循环中，我们需要像往常一样同时跟踪Zn及其导数Z'n。如果我们正在渲染Mandelbrot集，则推导规则为：
$$
Z^`_{N+1}=2Z_nZ^`_N+1\\
Z^`_0=0
$$
渲染Julia集，则推导规则如下：
$$
Z^`_{N+1}=2Z_NZ^`_{N+1}+1\\
Z^`_0=1
$$

```
#define MAXNUM 128
#define COLORING d/1.1, d*d/0.8, d*d*d/0.9
float Distance(vec2 p1,vec2 p2)
{
    float a=sqrt(dot(p1,p1));
    float b=sqrt(dot(p2,p2));
    return a*log(a)/b;
}
float Mandelbrot(vec2 p)
{
    vec2 z=vec2(.0,.0);
    vec2 dz=vec2(.0,.0);
    vec2 c=p;
    int i=0;
    for(;i<MAXNUM;i++)
    {
        // Z' -> 2·Z·Z' + 1
        dz = 2.0*vec2(z.x*dz.x-z.y*dz.y, z.x*dz.y + z.y*dz.x) + vec2(1.0,1.0);
        z=vec2(z.x*z.x-z.y*z.y,2.*z.x*z.y)+c;
        if(dot(z,z)>4.)
        {
            return Distance(z,dz);
        }
    }
    return .0;
    
}
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 p = fragCoord;
    
     p = vec2(-.745,.186) + 3.*(p/iResolution.x-.5)*pow(.01,1.+cos(.2*iTime)); 
    
    float d=Mandelbrot(p);
  // do some soft coloring based on distance
	d = clamp( pow(8.*d,0.1), 0.0, 1.0 );
    
    vec3 col = vec3(COLORING);
    
    fragColor = vec4( col, 1.0 );
}
```

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/fractals%20rendering%20algorithms/DistanceGOT.gif)