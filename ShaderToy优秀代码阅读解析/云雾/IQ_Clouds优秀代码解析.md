# IQ_Clouds

作者：IQ，网址：https://www.shadertoy.com/view/XslGRr

标签：procedural，volumetric，lod

![](C:\Users\Cooler\Desktop\JMX\ShaderToy\ShaderToy优秀代码阅读解析\云雾\IQ_Clouds优秀代码解析.assets\IQ-Clouds.gif)

### Render

主函数里面就是常规的坐标变换和相机设置，所以我们直接进入render函数进行分析。

一开始依旧是天空设置，包括：天空的色变和太阳的设置两部分。

```c
// background sky     
float sun = clamp( dot(sundir,rd), 0.0, 1.0 );
vec3 col = vec3(0.6,0.71,0.75) - rd.y*0.2*vec3(1.0,0.5,1.0) + 0.15*0.5;
col += 0.2*vec3(1.0,.6,0.1)*pow( sun, 8.0 );
```

 然后是核心RayMarch函数。

```c
vec4 raymarch( in vec3 ro, in vec3 rd, in vec3 bgcol, in ivec2 px )
{
	vec4 sum = vec4(0.0);
	float t = 0.0;//0.05*texelFetch( iChannel0, px&255, 0 ).x;
    MARCH(40,map5);
    MARCH(40,map4);
    MARCH(30,map3);
    MARCH(30,map2);
    return clamp( sum, 0.0, 1.0 );
}
```

-  对于MARCH宏定义，我们需要传入两个参数，分别是：循环步进次数和FBM函数类型（末尾数字代表细节层次），接下来详细分析宏定义

  ```c
  #define MARCH(STEPS,MAPLOD)
  for(int i=0; i<STEPS; i++)
  {
     vec3 pos = ro + t*rd;
     if( pos.y<-3.0 || pos.y>2.0 || sum.a>0.99 ) break;
     float den = MAPLOD( pos );
     if( den>0.01 )
     {
       float dif = clamp((den - MAPLOD(pos+0.3*sundir))/0.6, 0.0, 1.0 );
       vec3  lin = vec3(0.65,0.7,0.75)*1.4 + vec3(1.0,0.6,0.3)*dif;
       vec4  col = vec4( mix( vec3(1.0,0.95,0.8), vec3(0.25,0.3,0.35), den ), den );
       col.xyz *= lin;
       col.xyz = mix( col.xyz, bgcol, 1.0-exp(-0.003*t*t) );
       col.w *= 0.4;
  
       col.rgb *= col.a;
       sum += col*(1.0-sum.a);
     }
     t += max(0.05,0.02*t);
  }
  ```

  - 首先，Ray March常规流程：pos迭代和循环终止判断，这里的意外是——截至条件是Pos的Y坐标（海拔）。

    ```c
    vec3 pos = ro + t*rd;
    if( pos.y<-3.0 || pos.y>2.0 || sum.a>0.99 ) break;
    ```

  - 获得FBM函数的返回值，如果有效（即大于0），就进行叠加极其相关操作。首先计算得到漫反射系数dif。 这行代码的核心是den的减法，就效果而言，不减去后者会导致云层过亮，而就物理而言：==就该点往太阳方向移动某一个位置进行FBM采样，如果该地点存在云，那么明显会遮挡住太阳光打向这点的光，所以需要减去它，近似到达逻辑的正确==。==这是个简单但巧妙的物理规律的模拟==

    ```c
    float dif = clamp((den - MAPLOD(pos+0.3*sundir))/0.6, 0.0, 1.0 );
    ```

  - 然后是参数Lin的计算，令人尴尬的是，这个参数的物理含义我还不知道，同时他对效果的影响也是微乎其微的，所以这里就不分析了。

    ```
    vec3  lin = vec3(0.65,0.7,0.75)*1.4 + vec3(1.0,0.6,0.3)*dif;
    ```

  - col的设置，使用了FBM返回值Den做了一个Mix，顺便将w分量设置成Den.。主要效果是：云层基色的设置（灰色和白色）。

    ```c
    vec4  col = vec4( mix( vec3(1.0,0.95,0.8), vec3(0.25,0.3,0.35), den ), den );
    ```

  - col和lin进行相乘后，根据当前步进距离的值和背景色进行混合，大致效果是：极远处云层和天空的顺滑过渡。最后w分量乘上一个0.4进行缩放：因为后面col的RGB要和w相乘，所以需要缩放，避免最后场景过亮。

    ```c
    col.xyz = mix( col.xyz, bgcol, 1.0-exp(-0.003*t*t) );
    col.w *= 0.4;
    col.rgb *= col.a;
    ```

  - 最后将Col叠加在sum上，这里的逻辑是：col跟据（1.0-sum）进行缩放。规则也很简单：==肯定最靠近视点这边的云的权重越大==。就效果而言，如果不进行这个缩放，最后的渲染效果会有很严重的伪影——套上了地形图？

    ```
    sum += col*(1.0-sum.a);
    ```

  - 最后更新步长t：这里为了避免步长过大

    ```
    t += max(0.05,0.02*t);
    ```

- 就工具函数map4继续分析，一开始给p加上时间属性，让云层不断变化；然后是非循环的FBM过程，最后的返回值是不一样的，大概等于返回$-0.5+1.75*f$，而结果限制在单位区间内。不行调试了，目测应该是就效果调参的结果。

  ```c
  float map4( in vec3 p )
  {
  	vec3 q = p - vec3(0.0,0.1,1.0)*iTime;
  	float f;
      f  = 0.50000*noise( q ); q = q*2.02;
      f += 0.25000*noise( q ); q = q*2.03;
      f += 0.12500*noise( q ); q = q*2.01;
      f += 0.06250*noise( q );
  	return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
  }
  ```

  





### 工具函数——Noise

```c
float noise( in vec3 x )
{
    vec3 p = floor(x);
    vec3 f = fract(x);
	f = f*f*(3.0-2.0*f);
    
#if 1
	vec2 uv = (p.xy+vec2(37.0,239.0)*p.z) + f.xy;
    vec2 rg = textureLod(iChannel0,(uv+0.5)/256.0,0.0).yx;
#else
    ivec3 q = ivec3(p);
	ivec2 uv = q.xy + ivec2(37,239)*q.z;

	vec2 rg = mix(mix(texelFetch(iChannel0,(uv           )&255,0),
				      texelFetch(iChannel0,(uv+ivec2(1,0))&255,0),f.x),
				  mix(texelFetch(iChannel0,(uv+ivec2(0,1))&255,0),
				      texelFetch(iChannel0,(uv+ivec2(1,1))&255,0),f.x),f.y).yx;
#endif    
	return -1.0+2.0*mix( rg.x, rg.y, f.z );
}
```





### 工具函数——FBM

```c
float map5( in vec3 p )
{
	vec3 q = p - vec3(0.0,0.1,1.0)*iTime;
	float f;
    f  = 0.50000*noise( q ); q = q*2.02;
    f += 0.25000*noise( q ); q = q*2.03;
    f += 0.12500*noise( q ); q = q*2.01;
    f += 0.06250*noise( q ); q = q*2.02;
    f += 0.03125*noise( q );
	return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
}
float map4( in vec3 p )
{
	vec3 q = p - vec3(0.0,0.1,1.0)*iTime;
	float f;
    f  = 0.50000*noise( q ); q = q*2.02;
    f += 0.25000*noise( q ); q = q*2.03;
    f += 0.12500*noise( q ); q = q*2.01;
    f += 0.06250*noise( q );
	return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
}
float map3( in vec3 p )
{
	vec3 q = p - vec3(0.0,0.1,1.0)*iTime;
	float f;
    f  = 0.50000*noise( q ); q = q*2.02;
    f += 0.25000*noise( q ); q = q*2.03;
    f += 0.12500*noise( q );
	return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
}
float map2( in vec3 p )
{
	vec3 q = p - vec3(0.0,0.1,1.0)*iTime;
	float f;
    f  = 0.50000*noise( q ); q = q*2.02;
    f += 0.25000*noise( q );;
	return clamp( 1.5 - p.y - 2.0 + 1.75*f, 0.0, 1.0 );
}
```

