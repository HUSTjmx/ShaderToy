# Combustible Clouds

作者：Shane，网址：https://www.shadertoy.com/view/MscXRH

标签：noise，cloud，volumetric

![](C:\Users\ZoroD\Desktop\IQ--master\ShaderToy优秀代码阅读解析\Combustible Clouds代码解析.assets\Combustible Clouds.png)

![](C:\Users\ZoroD\Desktop\IQ--master\ShaderToy优秀代码阅读解析\Combustible Clouds代码解析.assets\CombustibleClouds.gif)



#### 基础设置

​	一开始是ro，rd的设置，这里和常规的不一样。

```c
vec3 rd = normalize(vec3(fragCoord - iResolution.xy*.5, iResolution.y*.75)); 
// Ray origin. Moving along the Z-axis.
vec3 ro = vec3(0, 0, iTime*4.);
```

​	然后是廉价的相机旋转（看着没有cos变量，其实是被隐藏了）。

```c
vec2 a = sin(vec2(1.5707963, 0) + iTime*0.1875); 
mat2 rM = mat2(a, -a.y, a.x);

rd.xy = rd.xy*rM; // Apparently, "rd.xy *= rM" doesn't work on some setups. Crazy.
a = sin(vec2(1.5707963, 0) + cos(iTime*0.1875*.7)*.7);
rM = mat2(a, -a.y, a.x); 
rd.xz = rd.xz*rM;
```

​	接下来一大片注释：射线实际上是在不连续的噪声片中行进，所以在某些角度，你可以看到分离。随机化可以在一定程度上掩盖这一点。

```c
// Randomizing the direction.
rd = (rd + (hash33(rd.zyx)*0.004-0.002)); 
// Randomizing the length also. 
rd *= (1. + fract(sin(dot(vec3(7, 157, 113), rd.zyx))*43758.5453)*0.04-0.02);  
rd = rd*.5 + normalize(rd)*.5;    
// Some more randomization, to be used for color based jittering inside the loop.
vec3 rnd = hash33(rd + 311.);
```

​	然后是一些值的声明。（感谢作者的注释，不用自己去琢磨了）

```c
// Local density, total density, and weighting factor.
//局部密度，整体密度，权重
float lDe = 0., td = 0., w = 0.;

// Closest surface distance, and total ray distance travelled.
//最近的表面距离，和总的射线移动距离
float d = 1., t = dot(rnd, vec3(.08));

// Distance threshold. Higher numbers give thicker clouds, but fill up the screen too much.
//距离阈值。数字越高，云层越厚，但填满屏幕的时间越长。
const float h = .5;

// Initializing the scene color to black, and declaring the surface position vector.
//初始化场景颜色为黑色，并声明表面位置向量。
vec3 col = vec3(0), sp;
```

​	之后是粒子表面法线，的计算：这里作者的推理很简单——因为视线打在粒子的前面，所以法线就简单设置成单位方向射线的反向射线，在添加一些随机性。（至于为什么是yzx，应该是去除对称性，起码是表面直观的对称性）。

```c
 vec3 sn = normalize(hash33(rd.yxz)*.03-rd);
```



#### RayMarching循环

​	首先截至条件的设置，翻译成汉语就是：当整体密度大于1，射线移动距离大于80，距离表面最近值低于某个小值时，退出循环。

```c
 if((td>1.) || d<.001*t || t>80.)break;
```

​	然后是核心过程Map。直观感觉就是根据射线步进的位置，获取两层正弦波，然后和一个随机值进行加权和，将结果传递给d[^1]。

```c
float map(vec3 p) {
    return trigNoise3D(p*.5);
    // 三层噪声，用于对比
    //p += iTime;
    //return n3D(p*.75)*.57 + n3D(p*1.875)*.28 + n3D(p*4.6875)*.15;
}
// 由三层旋转、突变的三角函数组成的低质量噪声
float trigNoise3D(in vec3 p){
    float res = 0., sum = 0.;
    //IQ的texture lookup noise
    float n = n3D(p*8. + iTime*2.);
    //两层正弦波
    vec3 t = sin(p.yzx*3.14159265 + cos(p.zxy*3.14159265+1.57/2.))*0.5 + 0.5;
    p = p*1.5 + (t - 1.5); //  + iTime*0.1
    res += (dot(t, vec3(0.333)));
    t = sin(p.yzx*3.14159265 + cos(p.zxy*3.14159265+1.57/2.))*0.5 + 0.5;
    res += (dot(t, vec3(0.333)))*0.7071;    
	return ((res/1.7071))*0.85 + n*0.15;
}
...
d=map(sp);
...
```

​	然后计算lDe[^2]和w[^4]，局部密度lDe的计算的原理是简单易见的，而权重w暂且不知。

```c
lDe = (h - d) * step(d, h); //局部密度=（阈值-最近距离）when h>d
w = (1. - td) * lDe;        //权重=(1.-整体密度)*局部密度
```

​	使用权重来积累密度[^3]

```c
 td += w*w*8. + 1./60.; //w*w*5. + 1./50.;
 //td += w*.4 + 1./45.; // Looks cleaner, but a little washed out.
```

​	点光源的一些常规计算，包括光矢量，衰减系数。然后是简单的漫反射系数和高光系数的计算。

```c
//获得单位方向光矢量
vec3 ld = lp-sp; 
float lDist = max(length(ld), 0.001); 
ld/=lDist;
//计算光的衰减系数，漫反射系数和高光系数
float atten = 1./(1. + lDist*0.1 + lDist*lDist*.03);
float diff = max(dot(sn, ld ), 0.);
float spec = pow(max(dot( reflect(-ld, sn), -rd ), 0.), 4.);
```

​	颜色的累计计算，第一行是简单的对常规项继续累加，但第二项的粗化（确实效果明显），但为什么是这个式子，不知道。

```c
//累积颜色。请注意，在这种情况下，我只添加了一个标量值，但你可以添加颜色组合。
col += w*(1.+ diff*.5 + spec*.5)*atten;
//基于颜色的抖动。对打在相机镜头上的灰云进行粗化处理。原理不太懂
col += (fract(rnd*289. + t*41.) - .5)*.02;;
```

​	循环的最后，是最重要的部分，也就是射线步进（执行最小步长）。可以直接加上d*0.5（系数越小，云的体积越大），这里使用max是提升效率的考量。

```c
t +=  max(d*.5, .02);
```



#### 天空以及最终色彩处理

```c
// Adding a bit of a firey tinge to the cloud value.
col = mix(pow(vec3(1.3, 1, 1)*col, vec3(1, 2, 10)), col, dot(cos(rd*6. +sin(rd.yzx*6.)), vec3(.333))*.2+.8);

// Using the light position to produce a blueish sky and sun. Pretty standard.
vec3 sky = vec3(.6, .8, 1.)*min((1.5+rd.y*.5)/2., 1.); 	
sky = mix(vec3(1, 1, .9), vec3(.31, .42, .53), rd.y*0.5 + 0.5);

float sun = clamp(dot(normalize(lp-ro), rd), 0.0, 1.0);

// Combining the clouds, sky and sun to produce the final color.
sky += vec3(1, .3, .05)*pow(sun, 5.)*.25; 
sky += vec3(1, .4, .05)*pow(sun, 16.)*.35; 	
col = mix(col, sky, smoothstep(0., 25., t));
col += vec3(1, .6, .05)*pow(sun, 16.)*.25; 	

// Done.
fragColor = vec4(sqrt(min(col, 1.)), 1.0);
```

​	太阳和天空的计算，这里也是不错的（比较在Elevsted中的），唯一不懂得是第一行代码，作者的原话如下。效果是出奇的好，什么时候我也能这🐏信手拈来。

> Adding a bit of a firey tinge to the cloud value.
>
> 为云增添了一点火热的色彩？

```c
col = mix(pow(vec3(1.3, 1, 1)*col, vec3(1, 2, 10)), col, dot(cos(rd*6. +sin(rd.yzx*6.)), vec3(.333))*.2+.8);
```



#### 哈希函数

```c
// Hash function. This particular one probably doesn't disperse things quite 
// as nicely as some of the others around, but it's compact, and seems to work.
//
vec3 hash33(vec3 p){ 
    float n = sin(dot(p, vec3(7, 157, 113)));    
    return fract(vec3(2097152, 262144, 32768)*n); 
}

```

#### 纹理噪声查找函数

```c
// IQ's texture lookup noise... in obfuscated form. There's less writing, so
// that makes it faster. That's how optimization works, right? :) Seriously,
// though, refer to IQ's original for the proper function.
// 
// By the way, you could replace this with the non-textured version, and the
// shader should run at almost the same efficiency.
float n3D( in vec3 p ){
    
    vec3 i = floor(p); p -= i; p *= p*(3. - 2.*p);
	p.xy = texture(iChannel0, (p.xy + i.xy + vec2(37, 17)*i.z + .5)/256., -100.).yx;
	return mix(p.x, p.y, p.z);
}
```

```c
// Textureless 3D Value Noise:
//
// This is a rewrite of IQ's original. It's self contained, which makes it much
// easier to copy and paste. I've also tried my best to minimize the amount of 
// operations to lessen the work the GPU has to do, but I think there's room for
// improvement. I have no idea whether it's faster or not. It could be slower,
// for all I know, but it doesn't really matter, because in its current state, 
// it's still no match for IQ's texture-based, smooth 3D value noise.
//
// By the way, a few people have managed to reduce the original down to this state, 
// but I haven't come across any who have taken it further. If you know of any, I'd
// love to hear about it.
//
// I've tried to come up with some clever way to improve the randomization line
// (h = mix(fract...), but so far, nothing's come to mind.
float n3D(vec3 p){
    
    // Just some random figures, analogous to stride. You can change this, if you want.
	const vec3 s = vec3(7, 157, 113);
	
	vec3 ip = floor(p); // Unique unit cell ID.
    
    // Setting up the stride vector for randomization and interpolation, kind of. 
    // All kinds of shortcuts are taken here. Refer to IQ's original formula.
    vec4 h = vec4(0., s.yz, s.y + s.z) + dot(ip, s);
    
	p -= ip; // Cell's fractional component.
	
    // A bit of cubic smoothing, to give the noise that rounded look.
    p = p*p*(3. - 2.*p);
    
    // Smoother version of the above. Weirdly, the extra calculations can sometimes
    // create a surface that's easier to hone in on, and can actually speed things up.
    // Having said that, I'm sticking with the simpler version above.
	//p = p*p*p*(p*(p * 6. - 15.) + 10.);
    
    // Even smoother, but this would have to be slower, surely?
	//vec3 p3 = p*p*p; p = ( 7. + ( p3 - 7. ) * p ) * p3;	
	
    // Cosinusoidal smoothing. OK, but I prefer other methods.
    //p = .5 - .5*cos(p*3.14159);
    
    // Standard 3D noise stuff. Retrieving 8 random scalar values for each cube corner,
    // then interpolating along X. There are countless ways to randomize, but this is
    // the way most are familar with: fract(sin(x)*largeNumber).
    h = mix(fract(sin(h)*43758.5453), fract(sin(h + s.x)*43758.5453), p.x);
	
    // Interpolating along Y.
    h.xy = mix(h.xz, h.yw, p.y);
    
    // Interpolating along Z, and returning the 3D noise value.
    return mix(h.x, h.y, p.z); // Range: [0, 1].
	
}
```



#### 符号意义

[^1]:最近的表面距离d
[^2]:局部密度lDe
[^3]:整体密度td
[^4]:权重w
[^5]:射线移动距离t
[^6]:距离阈值h