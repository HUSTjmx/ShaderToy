# useful little functions

​	在编写着色器时或在任何过程创建过程中（纹理，建模，着色，动画...），您通常会发现自己以不同的方式修改信号，以使其表现出您想要的方式。通常使用==smoothstep==阈值化一些值，或使用==pow==整形信号，使用==clamp==进行裁剪，使用==fmod==进行重复，使用==mix==进行混合，使用==exp==进行衰减，等等 。这些功能很方便，因为在大多数系统中默认情况下，您可以使用它们作为硬件指令或语言中的函数调用。但是，有些经常使用的操作以您仍然经常使用的任何语言都不存在。您是否发现自己要减去==smoothstep==来隔离某个范围或创建环？还是执行一些平滑的裁切操作以避免被大数除法？



### Almost Identity(I)

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/useful%20little%20functions/AlmostIdentity%28I%29.png)

​	想象一下，除非它为零或非常接近它，否则您不希望更改它的值，在这种情况下，您想用一个小的常数替换该值。那么，与其做一个引入不连续的条件分支，不如将你的值与你的阈值平滑地融合在一起。==让m是阈值（m以上的东西保持不变），n是当你的输入为零时，将采取的值==。那么，下面的函数就可以进行软剪裁（以立方体的方式）。

```c#
float almostIdentity( float x, float m, float n )
{
    if( x>m ) return x;
    const float a = 2.0*n - m;
    const float b = 2.0*m - 3.0*n;
    const float t = x/m;
    return (a*t + b)*t*t + n;
}
```





### Almost Unit Identity

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/useful%20little%20functions/AlmostUnitIdentity.png)

​	这是另一种近乎相同的函数，但此函数将单位间隔映射到其自身。但是它的特殊之处在于，不仅重新映射0到0和1到1，而且在原点处具有0导数，在1处具有1的导数，因此非常适合将事物从静止转变为运动，就像它们一直在运动一样。It's equivalent to the Almost Identity above with n=0 and m=1, basically. And since it's a cubic just like smoothstep() and therefore very fast to evaluate：

```c#
float almostIdentity( float x )
{
    return x*x*(2.0-x);
}
```





### Almost Identity (II)

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/useful%20little%20functions/gfx10.png)

​	也可以用作smooth-abs（）的另一种实现近距离标识的方法是通过有偏平方的平方根。根据硬件的不同，这种方法可能比上面的方法慢一些。尽管它的导数为零，但它的二阶导数不为零，这在某些情况下可能会引起问题

```c#
float almostIdentity( float x, float n )
{
    return sqrt(x*x+n);
}
```





### Exponential Impulse

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/useful%20little%20functions/ExponentialImpulse.png)

​	==非常适用于触发行为或制作音乐或动画的包络（envelopes），也适用于任何快速增长然后缓慢衰减的东西==。用k来控制函数的拉伸。Btw，它的最大值，也就是1，正好发生在x = 1/k的时候：

```c#
float expImpulse( float x, float k )
{
    const float h = k*x;
    return h*exp(1.0-h);
}
```





### Sustained Impulse

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/useful%20little%20functions/SustainedImpulse.png)

​	与前者类似，但它允许独立控制宽度（通过参数 "k"）和释放（参数 "f"）。同时，它确保了脉冲释放值为1.0而不是0。

```c#
float expSustainedImpulse( float x, float f, float k )
{
    float s = max(x-f,0.0)
    return min( x*x/(f*f), 1+(2.0/f)*s*exp(-k*s));
}
```





### Polynomial Impulse

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/useful%20little%20functions/PolynomialImpulse.png)

​	另一个不使用指数函数的冲动函数可以通过使用多项式来设计。用k来控制函数的落差。例如，可以使用二次函数，在x = sqrt(1/k)时达到峰值。

```c#
float quaImpulse( float k, float x )
{
    return 2.0*sqrt(k)*x/(1.0+k*x*x);
}
```

你可以很容易地将其归纳为其他幂，以得到不同的fall off形状，其中n是多项式的度数。

```c#
float polyImpulse( float k, float n, float x )
{
    return (n/(n-1.0))*pow((n-1.0)*k,1.0/n) * x/(1.0+k*pow(x,n));
}
```

These generalized impulses peak at $$x=[k(n-1)]^{-1/n}$$





### Cubic Pulse

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/useful%20little%20functions/CubicPulse.png)

当然，你发现自己经常做smoothstep(c-w,c,c,x)-smoothstep(c,c+w,x)，可能是因为你在试图隔离一个信号中的一些特征。那么，这个cubicPulse()将成为你的新朋友。你也可以用它==作为一个廉价的高斯函数的替代品==。

```c#
float cubicPulse( float c, float w, float x )
{
    x = fabs(x - c);
    if( x>w ) return 0.0;
    x /= w;
    return 1.0 - x*x*(3.0-2.0*x);
}
```





### Exponential Step

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/useful%20little%20functions/ExponentialStep.png)

​	自然衰减是一个线性衰减量的指数：黄色曲线，exp(-x)。一个高斯，是一个二次衰减量的指数：浅绿色曲线，$$exp(-x^2)$$。可以泛化，不断增大幂数，得到越来越锐利的S形曲线，直到得到一个阶梯为止

```c#
float expStep( float x, float k, float n )
{
    return exp( -k*pow(x,n) );
}
```





### Gain

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/useful%20little%20functions/Gain1.png)

> k<1 on the left, k>1 on the right

​	通过扩展边和压缩中心，将单位区间重新映射成单位区间，并保持1/2映射为1/2，这可以用Gain函数来完成。这是RSL教程中常用的函数，k=1是 identity curve，k<1产生经典的Gain，k>1产生 "s "形曲线。对于k=a和k=1/a，这些曲线是对称的。

```c#
float gain(float x, float k) 
{
    const float a = 0.5*pow(2.0*((x<0.5)?x:1.0-x), k);
    return (x<0.5)?a:1.0-a;
}
```





### Parabola

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/useful%20little%20functions/Parabola.png)

​	一个很好的选择是将[0,1]区间重映射为[0,1]，但是边界被映射为0，中心被映射为1，也就是说，抛物线(0)=抛物线(1)=0，抛物线(1/2)=1。

```c#
float parabola( float x, float k )
{
    return pow( 4.0*x*(1.0-x), k );
}
```





### Power curve

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/useful%20little%20functions/Powercurve.png)

​	这是对上面的Parabola()的泛化。但在这个泛化中，你可以控制曲线两边的形状，这在==创建树叶、眼睛和其他有趣的形状时非常方便==。

```c#
float pcurve( float x, float a, float b )
{
    const float k = pow(a+b,a+b) / (pow(a,a)*pow(b,b));
    return k * pow( x, a ) * pow( 1.0-x, b );
}
```





### Sinc curve

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/useful%20little%20functions/Sinccurve.png)

如果一个相位偏移的Sinc曲线从零开始到零结束，==对于某些弹跳行为，那么它就会很有用==。给出k个不同的整数值来调整弹跳量。它在1.0时达到峰值，但取负值，这可能使它在某些应用中无法使用。

```c#
float sinc( float x, float k )
{
    const float a = PI*((k*x-1.0);
    return sin(a)/a;
}
```

