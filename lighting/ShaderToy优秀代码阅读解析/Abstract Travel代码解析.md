# Abstract Travel

作者：Shane，网址：https://www.shadertoy.com/view/MlXSWX

Tags：Noise，tunnel，triangle，abstract

简介：利用Shadertoy用户Nimitz的三角噪声思想及其曲率函数来伪造一个抽象，平面阴影，点光源的网状外观。

个人收获：

![](C:\Users\ZoroD\Desktop\IQ--master\ShaderToy优秀代码阅读解析\Abstract Travel代码解析.assets\Abstract Travel.png)

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/ShaderToy%E4%BC%98%E7%A7%80%E4%BB%A3%E7%A0%81%E8%A7%A3%E6%9E%90/Abstract%20Travel/AbCd.gif)

#### Image

​	首先是进行常规的坐标变换，以及相机的起始位置和目标位置的设置，然后在相机前后设置了两个点光源，然后使用这些值的Z值扰动他们的XY平面：这里的扰动函数path使用的是随时间变化的2D正弦波。在效果上的体现也比较容易得到：周期性左右摇摆的路径前行。

```c
// The path is a 2D sinusoid that varies over time, depending upon the frequencies, and amplitudes.
vec2 path(in float z){ float s = sin(z/24.)*cos(z/12.); return vec2(s*12., 0.); }
///code in Image
...
lookAt.xy += path(lookAt.z);
camPos.xy += path(camPos.z);
light_pos.xy += path(light_pos.z);
light_pos2.xy += path(light_pos2.z);
...
```

​	然后计算单位射线方向向量。并且在转弯时在XY平面翻转相机。

```C
float FOV = PI/3.; // FOV - Field of view.
vec3 forward = normalize(lookAt-camPos);
vec3 right = normalize(vec3(forward.z, 0., -forward.x )); 
vec3 up = cross(forward, right);
// rd - Ray direction.
vec3 rd = normalize(forward + FOV*uv.x*right + FOV*uv.y*up);
//偏转相机
rd.xy = rot2( path(lookAt.z).x/32. )*rd.xy;
```

然后是标准的射线步近（Ray Marching）过程：在标准的隧道距离函数中加入了一些扰动。还加入了一个地板。隧道就是一个管子，当你纵向穿越时，管子的中心平滑移动。管子的壁面是由一个非常廉价的3D曲面函数来扰动的。

```c
#define FH 1.0 // Floor height. 设置2.0可以去除地板
float map(vec3 p){

    float sf = surfFunc(p - vec3(0, cos(p.z/3.)*.15, 0));
    // For a square tunnel, use the Chebyshev(?) distance: max(abs(tun.x), abs(tun.y))
    vec2 tun = abs(p.xy - path(p.z))*vec2(0.5, 0.7071);
    float n = 1. - max(tun.x, tun.y) + (0.5 - sf);
    return min(n, p.y + FH);
}
//code in image
...
float t = 0.0, dt;
for(int i=0; i<128; i++){
	dt = map(camPos + rd*t);
	if(dt<0.005 || t>150.){ break; } 
	t += dt*0.75;
}
...
```

+ 第一行代码，调用了SurfFunc函数：用来扰乱（perturb）墙壁——基于三角形函数，以提供一个微妙的锯齿状。虽然不是很花哨，但它在为尖锐的岩面打基础方面出奇的好。==Tri==函数是Shadertoy用户Nimitz在三角噪声演示中使用的三角函数。首先，关于传入参数，是否减去那个Y分量为余弦函数的向量对于实际效果无影响。然后==进入函数：主体是一个点积==，我们就效果和分析而言，右乘项的常量代表着凸显程度，值越大，墙壁的凹凸程度越大，尖锐石块越多；左乘项则是一个嵌套的Tri调用，经过个人实验，这里决定了墙壁三角形的复杂程度，嵌套程度越大，尖锐石块越复杂，至于p的常数乘项，则很明显：随着嵌套程度越高，值越小——细节的程度；至于.yzx则是为了去除对称性，增加洞穴的随机性。下图则显示了tri嵌套程度不同产生的效果。

  ```c
  vec3 tri(in vec3 x){return abs(x-floor(x)-.5);} // Triangle function.
  float surfFunc(in vec3 p){
      
  	return dot(tri(p*0.5 + tri(p*0.25).yzx), vec3(0.666));
  }
  ```

  ![](C:\Users\ZoroD\Desktop\IQ--master\ShaderToy优秀代码阅读解析\Abstract Travel代码解析.assets\ac_tri.png)

+ 然后是计算是计算变量Tun，这一行代码似乎是通用的（在实际的网址代码中，还有注释的圆形，方圆形通道，它们的Tun计算都是一样的）。首先，为什么要在Abs函数里面减去path(z)，这里我的理解是，因为我们之前在诸如RayPos，LightPos等值上做了Path的相加，偏移，那么我们应该在通道的建立上做出相反的偏移，比如说：我们的视点左移，那么我们继续移动时，通道应该往右移动，形成一种转弯的效果，否则会时不时和墙壁碰撞，产生“穿模”错误。然后我们需要乘上一个向量对通道进行XY方向上的缩放，以达到足够好的通道体现效果。

  ```c
  vec2 tun = abs(p.xy - path(p.z))*vec2(0.5, 0.7071);
  ```

+ 然后计算n，分为三部分。Max函数负责产生方形通道（在实际网址中，圆形通道此部分是调用的length），然后使用计算好的SF对墙壁进行扭曲（至于具体数值无所谓，==个人倒是觉得直接加上SF，既能达到好的效果，也易于理解==）。

  ```
  float n = 1. - max(tun.x, tun.y) + (0.5 - sf);
  ```

+ 最后使用min来组合墙壁和地面，FH来控制地板高度。

Map函数分析完毕，回到主函数。射线步近完毕后，计算好交点位置和法线，然后我们进行基于纹理的凹凸映射，这一部分对于法线进行了微调，增加了细节。通过对彩色纹理进行采样，取灰度，计算梯度，对法线进行调整，这里面，没有搞懂的是tex3D 的作用和原理（为什么不直接采样），后面，仔细一想，直接采样，又没有从切线空间转变出来，所以直接采样是不行的，所以这里的tex3D 的作用应该是使得采样合理化

```c
// Tri-Planar混合功能。基于一个老的Nvidia教程
vec3 tex3D( sampler2D tex, in vec3 p, in vec3 n ){
  
    n = max((abs(n) - 0.2)*7., 0.001); // max(abs(n), 0.001), etc.
    n /= (n.x + n.y + n.z );  
	return (texture(tex, p.yz)*n.x + texture(tex, p.zx)*n.y + texture(tex, p.xy)*n.z).xyz;
}
// 灰度
float getGrey(vec3 p){ return p.x*0.299 + p.y*0.587 + p.z*0.114; }
// Texture bump mapping. Four tri-planar lookups, or 12 texture lookups in total.
vec3 doBumpMap( sampler2D tex, in vec3 p, in vec3 nor, float bumpfactor){
   
    const float eps = 0.001;
    float ref = getGrey(tex3D(tex,  p , nor));                 
    vec3 grad = vec3( getGrey(tex3D(tex, vec3(p.x - eps, p.y, p.z), nor)) - ref,
                      getGrey(tex3D(tex, vec3(p.x, p.y - eps, p.z), nor)) - ref,
                      getGrey(tex3D(tex, vec3(p.x, p.y, p.z - eps), nor)) - ref )/eps;
             
    grad -= nor*dot(nor, grad);             
    return normalize( nor + grad*bumpfactor );
	
}
... 
vec3 sp = t * rd+camPos;
vec3 sn = getNormal(sp);
if (sp.y<-(FH-0.005)) sn = doBumpMap(iChannel1, sp*tSize1, sn, 0.025); // Floor.
else sn = doBumpMap(iChannel0, sp*tSize0, sn, 0.025); // Walls.
...
```

然后计算AO。这是在IQ的代码中比较常见的计算方式——往法线方向进行依次采样（离起点越远，加权越小）。

```c
// Based on original by IQ.
float calculateAO(vec3 p, vec3 n){

    const float AO_SAMPLES = 5.0;
    float r = 0.0, w = 1.0, d;
    
    for (float i=1.0; i<AO_SAMPLES+1.1; i++){
        d = i/AO_SAMPLES;
        r += w*(d - map(p + n*d));
        w *= 0.5;
    }
    
    return 1.0-clamp(r,0.0,1.0);
}
```

然后依次计算衰减系数、环境光、漫反射系数、高光系数。这些计算都是常规的，简单的。

```c
float atten = min(1./(distlpsp) + 1./(distlpsp2), 1.);
// Ambient light.
float ambience = 0.25;
// Diffuse lighting.
float diff = max( dot(sn, ld), 0.0);
float diff2 = max( dot(sn, ld2), 0.0);
// Specular lighting.
float spec = pow(max( dot( reflect(-ld, sn), -rd ), 0.0 ), 8.);
float spec2 = pow(max( dot( reflect(-ld2, sn), -rd ), 0.0 ), 8.);
```

然后计算曲率？，根据注释：酷炫的曲线功能，由Shadertoy用户Nimitz提供。它是否与连续拉普拉斯微分算子的离散有限差分近似有关？无论哪种方式，它都能为一个对象的有符号距离函数提供一个标量曲率值，这非常方便。Original Use？：https://www.shadertoy.com/view/Xts3WM。关于这个曲率有什么用，目前不知道，看看后面吧。

```c
float curve(in vec3 p, in float w){

    vec2 e = vec2(-1., 1.)*w;
    
    float t1 = map(p + e.yxx), t2 = map(p + e.xxy);
    float t3 = map(p + e.xyx), t4 = map(p + e.yyy);
    
    return 0.125/(w*w) *(t1 + t2 + t3 + t4 - 4.*map(p));
}
...
// code in image
// Curvature
float crv = clamp(curve(sp, 0.125)*0.5 + 0.5, .0, 1.);
...
```

然后计算菲涅尔项。适合于给表面一点反射光亮。

```c
float fre = pow( clamp(dot(sn, rd) + 1., .0, 1.), 1.);
```

然后按墙壁和地面采样不同的纹理颜色

```c
vec3 texCol;
if (sp.y<-(FH - 0.005)) texCol = tex3D(iChannel1, sp*tSize1, sn); // Floor.
else texCol = tex3D(iChannel0, sp*tSize0, sn); // Walls.
```

> Shadertoy doesn't appear to have anisotropic filtering turned on... although, I could be wrong. Texture-bumped objects don't appear to look as crisp. Anyway, this is just a very lame, and not particularly well though out, way to sparkle up the blurry bits. It's not really that necessary.
> vec3 aniso = (0.5 - hash33(sp))\*fre*0.35;
> texCol = clamp(texCol + aniso, 0., 1.);

然后使缝隙变暗。也就是所谓的廉价的、科学不正确的阴影。

```c
float shading =  crv*0.5 + 0.5; 
```

计算光照

```c
sceneCol = getGrey(texCol)*((diff + diff2)*0.75 + ambience*0.25) + (spec + spec2)*texCol*2. + fre*crv*texCol.zyx*2.;
```

> Other combinations:
> Shiny：
> sceneCol = texCol\*((diff + diff2)\*vec3(1.0, 0.95, 0.9) + ambience + fre\*fre\*texCol) + (spec + spec2);
> Abstract pen and ink：
> float c = getGrey(texCol)\*((diff + diff2)\*1.75 + ambience + fre\*fre) + (spec + spec2)\*0.75;
> sceneCol = vec3(c\*c\*c, c*c, c);

最后，画出墙壁上的线条。把这个注释出来，可以做成花岗岩走廊的效果。

```c
// Shading.
sceneCol *= atten*shading*ao;
// Drawing the lines on the walls. Comment this out and change the first texture to
// granite for a granite corridor effect.
sceneCol *= clamp(1.-abs(curve(sp, 0.0125)), .0, 1.);
```

