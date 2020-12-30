# Analytic Normals 3D代码解析

作者：iq，网址：https://www.shadertoy.com/view/XttSz2

标签：[3d](https://www.shadertoy.com/results?query=tag%3D3d), [noise](https://www.shadertoy.com/results?query=tag%3Dnoise), [normals](https://www.shadertoy.com/results?query=tag%3Dnormals), [analytical](https://www.shadertoy.com/results?query=tag%3Danalytical), [numerical](https://www.shadertoy.com/results?query=tag%3Dnumerical)

总共一个部分：Image

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/ShaderToy%E4%BC%98%E7%A7%80%E4%BB%A3%E7%A0%81%E8%A7%A3%E6%9E%90/Analytic%20Normals%203D%E4%BB%A3%E7%A0%81%E8%A7%A3%E6%9E%90.gif)



### 照相机设置

这个比较常见，就是简单的照相机旋转和矩阵获取

```c#
// camera anim
float an = 0.1*iTime;
vec3 ro = 3.0*vec3( cos(an), 0.8, sin(an) );
vec3 ta = vec3( 0.0 );
// camera matrix	
vec3  cw = normalize( ta-ro );
vec3  cu = normalize( cross(cw,vec3(0.0,1.0,0.0)) );
vec3  cv = normalize( cross(cu,cw) );
vec3  rd = normalize( p.x*cu + p.y*cv + 1.7*cw );
```

### 相交测试函数

之后是进行相交测试

```c#
vec4 interesect( in vec3 ro, in vec3 rd )
{
	vec4 res = vec4(-1.0);

    // 正方形相交测试   
    vec2 dis = iBox( ro, rd, vec3(1.5) ) ;
    if( dis.y<0.0 ) return res;

    // raymarch
    float tmax = dis.y;
    float t = dis.x;
	for( int i=0; i<128; i++ )
	{
        vec3 pos = ro + t*rd;
		vec4 hnor = map( pos );
        res = vec4(t,hnor.yzw);
        
		if( hnor.x<0.001 ) break;
		t += hnor.x;
        if( t>tmax ) break;
	}

	if( t>tmax ) res = vec4(-1.0);
	return res;
}
```

首先是判断[射线与正方形是否相交](#*工具iBox函数)，如果相交，返回两个交点。具体关于相交测试函数，可以参考IQ的博客。然后在两个交点产生的[tmin,tmax]的范围内进行RayMarching， 核心是Map函数，如下所示：

```c#
vec4 map( in vec3 p )
{
	vec4 d1 = fbmd( p );
    d1.x -= 0.37;
	d1.x *= 0.7;
    d1.yzw = normalize(d1.yzw);
    // clip to box
    vec4 d2 = sdBox( p, vec3(1.5) );
    return (d1.x>d2.x) ? d1 : d2;
}
```

具体分析：对于d1，是通过[分数布朗函数](#*工具FBMD函数)获得随机点（其中，x分量是t，yzw是法线）,这里和之前了解到的FBM函数的区别在于，得到了随机点的法向量。当然我们也可以直接使用常规的calNormal函数。对于结果，进行了区间重映射。为什么需要这个重映射呢（一次加减法，一次乘法）？其核心是加减法，乘法是无所谓的（效果上也是这样表现的），试想，如果我们不减去一个值，那么FBM的返回值始终是大于0的，那么无论怎么往前推进（在FMB上，表现是在曲面上移动），都不会结束，在效果表现上，如果删去这行，则所有射线都会投到无限远处，而不断增大减去的值，几何体越接近完整的正方形。

然后在判断离正方形的距离，两个结果相比较，返回较大值的结果和法向量。回到interesect函数，之后是常规的射线步进操作。最后返回主函数。

### 渲染过程

==首先计算AO==。使用球面斐波那契采样（实际是半球）得到均匀的采样，采样32次，每次进行map，累加返回结果的步进距离，然后除以32，这里有个问题——在进行Clamp的时候，分别乘以3，5。这里的分析：因为我们对于采样点的判断是它离几何体的距离，而不是灯光方向的深度图，所以，哪怕对于正方体表面的点，对其进行采样，它们的返回值依然不会很大，所以需要乘上倍数。

<img src="https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/ShaderToy%E4%BC%98%E7%A7%80%E4%BB%A3%E7%A0%81%E8%A7%A3%E6%9E%90/%E6%97%A0%E6%A0%87%E9%A2%98.png" style="zoom:50%;" />

```c
float calcAO( in vec3 pos, in vec3 nor )
{
	float ao = 0.0;
    for( int i=0; i<32; i++ )
    {
        //球面斐波那契均匀采样
        vec3 ap = forwardSF( float(i), 32.0 );
        //随机值
        float h = hash(float(i));
        //反法线方向半球倒转方向
		ap *= sign( dot(ap,nor) ) * h*0.25;
        ao += clamp( map( pos + nor*0.001 + ap ).x*3.0, 0.0, 1.0 );
    }
	ao /= 32.0;
	
    return clamp( ao*5.0, 0.0, 1.0 );
}
```

==然后计算Fre，Fro。==

```c#
float fre = clamp( 1.0+dot(rd,nor), 0.0, 1.0 );
float fro = clamp( dot(nor,-rd), 0.0, 1.0 );
```

其中，Fre是菲尼尔效应的近似，大致如图：在图中，越平坦，紫色段越短，那么1减去紫色段的值越大，那么菲涅尔效应越强。Fro则相反，或者说接近一般的计算。

<img src="https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/ShaderToy%E4%BC%98%E7%A7%80%E4%BB%A3%E7%A0%81%E8%A7%A3%E6%9E%90/Untitled.png" style="zoom:50%;" />

==然后正式计算颜色==

```c
col = mix( vec3(0.05,0.2,0.3), vec3(1.0,0.95,0.85), 0.5+0.5*nor.y );
//col = 0.5+0.5*nor;
col += 10.0*pow(fro,12.0)*(0.04+0.96*pow(fre,5.0));
col *= pow(vec3(occ),vec3(1.0,1.1,1.1) );
```

第一行：计算基本的颜色，因人而异，这里是将颜色和法线的Y分量挂钩（正相关）。第二行，使用计算好的fre，fro。具体含义不知，以后有机会搞明白。第三行，加入AO。

最后，转为伽马空间后，结束。

### *工具iBox函数

```c#
vec2 iBox( in vec3 ro, in vec3 rd, in vec3 rad ) 
{
    vec3 m = 1.0/rd;
    vec3 n = m*ro;
    vec3 k = abs(m)*rad;
    vec3 t1 = -n - k;
    vec3 t2 = -n + k;
	float tN = max( max( t1.x, t1.y ), t1.z );
	float tF = min( min( t2.x, t2.y ), t2.z );
	if( tN > tF || tF < 0.0) return vec2(-1.0);
	return vec2( tN, tF );
}
```



### *工具FBMD函数

```c#
vec4 fbmd( in vec3 x )
{
    const float scale  = 1.5;

    float a = 0.0;
    float b = 0.5;
	float f = 1.0;
    vec3  d = vec3(0.0);
    for( int i=0; i<8; i++ )
    {
        vec4 n = noised(f*x*scale);
        a += b*n.x;           // accumulate values		
        d += b*n.yzw*f*scale; // accumulate derivatives
        b *= 0.5;             // amplitude decrease
        f *= 1.8;             // frequency increase
    }
	return vec4( a, d );
}
```



### *工具SdBox函数

```c#
vec4 sdBox( vec3 p, vec3 b ) // distance and normal
{
    vec3 d = abs(p) - b;
    float x = min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
    vec3  n = step(d.yzx,d.xyz)*step(d.zxy,d.xyz)*sign(p);
    return vec4( x, n );
}
```



### *工具ValueNoise及其梯度

```c#
float hash( float n ) { return fract(sin(n)*753.5453123); }
vec4 noised( in vec3 x )
{
    vec3 p = floor(x);
    vec3 w = fract(x);
	vec3 u = w*w*(3.0-2.0*w);
    vec3 du = 6.0*w*(1.0-w);
    
    float n = p.x + p.y*157.0 + 113.0*p.z;
    
    float a = hash(n+  0.0);
    float b = hash(n+  1.0);
    float c = hash(n+157.0);
    float d = hash(n+158.0);
    float e = hash(n+113.0);
	float f = hash(n+114.0);
    float g = hash(n+270.0);
    float h = hash(n+271.0);
	
    float k0 =   a;
    float k1 =   b - a;
    float k2 =   c - a;
    float k3 =   e - a;
    float k4 =   a - b - c + d;
    float k5 =   a - c - e + g;
    float k6 =   a - b - e + f;
    float k7 = - a + b + c - d + e - f - g + h;

    return vec4( k0 + k1*u.x + k2*u.y + k3*u.z + k4*u.x*u.y + k5*u.y*u.z + k6*u.z*u.x + k7*u.x*u.y*u.z, 
                 du * (vec3(k1,k2,k3) + u.yzx*vec3(k4,k5,k6) + u.zxy*vec3(k6,k4,k5) + k7*u.yzx*u.zxy ));
}
```



### *工具ForwardSF函数