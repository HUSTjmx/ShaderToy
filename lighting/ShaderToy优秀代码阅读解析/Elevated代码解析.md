# Elevated代码解析

作者：iq，网址：https://www.shadertoy.com/view/MdX3Rr

标签：[procedural](https://www.shadertoy.com/results?query=tag%3Dprocedural), [3d](https://www.shadertoy.com/results?query=tag%3D3d), [raymarching](https://www.shadertoy.com/results?query=tag%3Draymarching), [distancefield](https://www.shadertoy.com/results?query=tag%3Ddistancefield), [terrain](https://www.shadertoy.com/results?query=tag%3Dterrain), [motionblur](https://www.shadertoy.com/results?query=tag%3Dmotionblur)

总共两个部分：Image，Buffer A

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/ShaderToy%E4%BC%98%E7%A7%80%E4%BB%A3%E7%A0%81%E8%A7%A3%E6%9E%90/Elevated%E4%BB%A3%E7%A0%81%E8%A7%A3%E6%9E%90.gif)



## Image

```c#
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord/iResolution.xy;
    vec4 data = texture( iChannel0, uv );

    vec3 col = vec3(0.0);
    if( data.w < 0.0 )
    {
        col = data.xyz;
    }
    else
    {
        // decompress velocity vector
        float ss = mod(data.w,256.0)/255.0;
        float st = floor(data.w/256.0)/255.0;

        // motion blur (linear blur across velocity vectors
        vec2 dir = (-1.0 + 2.0*vec2( ss, st ))*0.25;
        col = vec3(0.0);
        for( int i=0; i<32; i++ )
        {
            float h = float(i)/31.0;
            vec2 pos = uv + dir*h;
            col += texture( iChannel0, pos ).xyz;
        }
        col /= 32.0;
    }
    
    // vignetting	
	col *= 0.5 + 0.5*pow( 16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y), 0.1 );

    col = clamp(col,0.0,1.0);
    col = col*0.6 + 0.4*col*col*(3.0-2.0*col) + vec3(0.0,0.0,0.04);
    

    
    fragColor = vec4( col, 1.0 );
}
```

+ 读取BufferA的计算结果，据此来说，xyz分量存储的是最终计算结果（color），w存的是速度向量。

  ```c#
   vec4 data = texture( iChannel0, uv );
  ```

+ 如果速度小于0，则说明场景静止，直接取xyz分量，否则进行==运动模糊（motion blur）==

+ 进行运动模糊时，首先进行对速度矢量进行解压缩。

  ```C#
  float ss = mod(data.w,256.0)/255.0;
  float st = floor(data.w/256.0)/255.0;
  ```

  第一个是用w分量对256求模，然后除以255，第二个是用w分量除以246，取整后除以255，为什么这样解码，估计答案在Buffer A里面。

+ 利用解码得到的ss，st计算速度向量，区间重映射为[-0.25,0.25]，这里为什么是0.25？我在测试中改为[-1,1]后，运动模糊效果过于眼中，场景明显有条纹以及晕眩感，这里可能是调节的结果

  ```c#
  vec2 dir = (-1.0 + 2.0*vec2( ss, st ))*0.25;
  ```

+ 接下来是简单的运动模糊，累加32次后平均

  ```c#
  for( int i=0; i<32; i++ )
  {
       float h = float(i)/31.0;
       vec2 pos = uv + dir*h;
       col += texture( iChannel0, pos ).xyz;
  }
       col /= 32.0;
  ```

+ 然后是Vignetting效果（渐晕；光晕，光损失；暗角）

  ```c#
  col *= 0.5 + 0.5*pow( 16.0*uv.x*uv.y*(1.0-uv.x)*(1.0-uv.y), 0.1 );
  ```

  这个效果是这样的

  ![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/lighting/vignetting-example.jpg)

+ 这行代码的呈现结果是：场景由黄，变白亮，有点像黄昏和白天的区别。

  ```c#
  col = col*0.5 + 0.5*col*col*(3.0-2.0*col) + vec3(0.0,0.0,0.04);
  ```

总体来说，Image是对Buffer A的结果进行运动模糊，以及色彩调节等处理，比较简单，我们可以参考的是 ==简单的运动模糊== 和 ==vignetting 效果==。



## Buffer A

这里的代码是主要功能的实现，有几百行，就不在开头贴出来了，我们从主函数开始分析。

一开始，对运行时间进行处理，用作之后的相机移动，这里还用了鼠标输入，用作加速移动（可以理解为瞬移）

```c#
float time = iTime*0.1 - 0.1 + 0.3 + 4.0*iMouse.x/iResolution.x;
```

### 照相机的处理

然后我们进入了moveCamera函数，参数为：时间，观看位置，观看方向，cr和fl不知道是什么，然后其中使用的全局变量 SC 为 250.0 

```c#
void moveCamera( float time, out vec3 oRo, out vec3 oTa, out float oCr, out float oFl )
{
	vec3 ro = camPath( time );
	vec3 ta = camPath( time + 3.0 );
	ro.y = terrainL( ro.xz ) + 22.0*SC;
	ta.y = ro.y - 20.0*SC;
	float cr = 0.2*cos(0.1*time);
    oRo = ro;
    oTa = ta;
    oCr = cr;
    oFl = 3.0;
}
vec3 camPath( float time )
{
	return SC*1100.0*vec3( cos(0.0+0.23*time), 0.0, cos(1.5+0.21*time) );
}
```

+ 对于<u>camPath</u>，明显是计算相机的x，z位置，这里的问题的常量SC和1100为什么这么大，暂且不知。推测原因是采样扩大，坐标范围极大，毕竟我们这里显示的是无边的地形。此外，SC是全局变量，是有很多意义的，但调节的效果无法归纳其作用，暂时可以理解为某个值的单位变量，而1100这个常量根据调整的结果，可以理解为相机的移动速度。

+ 然后根据terrainL计算此时相机xz位置对应的地形高度。（这里的算法就不做介绍了，个人估计是额外的地形生成算法），然后往上面做一个偏移，求出观察位置的Y（高度）以及视线向量的Y。有三个函数，本质是相同的，后缀L，M，H分别对应地形生成的精度等级。

  ```c#
  float terrainL( in vec2 x )
  {
  	vec2  p = x*0.003/SC;
      float a = 0.0;
      float b = 1.0;
  	vec2  d = vec2(0.0);
      for( int i=0; i<3; i++ )
      {
          vec3 n = noised(p);
          d += n.yz;
          a += b*n.x/(1.0+dot(d,d));
  		b *= 0.5;
          p = m2*p*2.0;
      }
  
  	return SC*120.0*a;
  }
  ```

回到主函数，得到了几个相机采数之后，就是设置相机，获得反V矩阵。比较简单和常见，就是通过叉乘进行计算求值。然后cr的作用就出现了。

```c#
mat3 setCamera( in vec3 ro, in vec3 ta, in float cr )
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
    return mat3( cu, cv, cw );
}
```

然后进入抗锯齿的循环之中，将屏幕坐标p重映射回裁剪空间，然后使用fl和得到的相机矩阵，计算射线在世界空间的值。因此==fl可以理解为裁剪平面的位置==。

```c#
vec3 rd = cam * normalize(vec3(s,fl));
```

### 天空，雪和山地的处理

在之后，进入渲染的总函数Render中

```c#
 vec4 res = render( ro, rd );
 t = min( t, res.w );
```

+ 这一部分是进行加速，缩小[tmin,tmax]的区间范围

  ```c#
  float maxh = 300.0*SC;
  float tp = (maxh-ro.y)/rd.y;
  if( tp>0.0 )
  {
      if( ro.y>maxh ) tmin = max( tmin, tp );
      else     tmax = min( tmax, tp );
  }
  ```

+ 然后分析interesct函数，这里也是进行了常规的相交测试，或者说距离场测试，返回射线移动的距离。关于terrainM函数，和之前一样暂不讨论。

  ```c#
  float interesct( in vec3 ro, in vec3 rd, in float tmin, in float tmax )
  {
      float t = tmin;
  	for( int i=0; i<300; i++ )
  	{
          //RayMarching
          vec3 pos = ro + t*rd;
          //计算高度插值
  		float h = pos.y - terrainM( pos.xz );
          //0.0015*t起到一个优化加速的效果
  		if( abs(h)<(0.0015*t) || t>tmax ) break;
  		t += 0.4*h;
  	}
  
	return t;
  }
  ```
  
    如果返回结果大于tmax，这说明没有击中地形，我们要==渲染天空，这里的天空渲染实在巧妙，可以借鉴==
  
```c#
  // sky	根据Y的坐标模拟天空渐变的蓝色	，第二行和海平面处理近似，但变化没有那么急剧，效果相对于给蓝天套了一层由下至上逐渐稀释的白雾
  col = vec3(0.3,0.5,0.85) - rd.y*rd.y*0.5;
  col = mix( col, 0.85*vec3(0.7,0.75,0.85), pow( 1.0-max(rd.y,0.0), 4.0 ) );
  // sun 增光来达到模拟太阳光晕的效果，有点像经典高光的计算
  col += 0.25*vec3(1.0,0.7,0.4)*pow( sundot,5.0 );
  col += 0.25*vec3(1.0,0.8,0.6)*pow( sundot,64.0 );
  col += 0.2*vec3(1.0,0.8,0.6)*pow( sundot,512.0 );
  // clouds 不太懂的云模拟
  vec2 sc = ro.xz + rd.xz*(SC*1000.0-ro.y)/rd.y;
  col = mix( col, vec3(1.0,0.95,1.0), 0.5*smoothstep(0.5,0.8,fbm(0.0005*sc/SC)) );
  // horizon 逻辑简单但适用的地平线模拟，在海平面0处附近生效
col = mix( col, 0.68*vec3(0.4,0.65,1.0), pow( 1.0-max(rd.y,0.0), 16.0 ) );
  t = -1.0;
```

  其中，fbm代表分数布朗运动

  ```c#
  float fbm( vec2 p )
  {
      float f = 0.0;
      f += 0.5000*texture( iChannel0, p/256.0 ).x; p = m2*p*2.02;
      f += 0.2500*texture( iChannel0, p/256.0 ).x; p = m2*p*2.03;
      f += 0.1250*texture( iChannel0, p/256.0 ).x; p = m2*p*2.01;
      f += 0.0625*texture( iChannel0, p/256.0 ).x;
    return f/0.9375;
  }
  ```

  如果返回结果小于tmax，则开始渲染地面，首先简单的计算击中点的法线，这是地形计算法线的版本，具体法线计算的各种情况可见IQ6

  ```c#
  vec3 calcNormal( in vec3 pos, float t )
  {
      vec2  eps = vec2( 0.001*t, 0.0 );
      return normalize( vec3( terrainH(pos.xz-eps.xy) - terrainH(pos.xz+eps.xy),
                              2.0*eps.x,
                            terrainH(pos.xz-eps.yx) - terrainH(pos.xz+eps.yx) ) );
  }
  ```

  然后，计算岩石的颜色，这里的核心代码是第一行和第二行，后续都是一些优化和增加随机性，但是确实看不太懂，最后一行是添加细节的颜色变化。

  ```c#
  float r = texture( iChannel0, (7.0/SC)*pos.xz/256.0 ).x;
  col = (r*0.25+0.75)*0.9*mix( vec3(0.08,0.05,0.03), vec3(0.10,0.09,0.08), texture(iChannel0,0.00007*vec2(pos.x,pos.y*48.0)/SC).x );
  //在效果上体现为：增加后，颜色由泛白变得正常
col = mix( col, 0.20*vec3(0.45,.30,0.15)*(0.50+0.50*r),smoothstep(0.70,0.9,nor.y) );
  //无明显效果
col = mix( col, 0.15*vec3(0.30,.30,0.10)*(0.25+0.75*r),smoothstep(0.95,1.0,nor.y) );
  //相当于细节贴图
  col *= 0.1+1.8*sqrt(fbm(pos.xz*0.04)*fbm(pos.xz*0.005));
  ```

  雪的计算。首先，==对于参数h==，我们知道的是他跟地形的高度有关，除以单位值SC得到高度的无符号数值，然后加上一个分数布朗的相关随机值，关于参数内部除以SC，这个是无所谓的，对于效果没有影响，窃以为是统一格式，毕竟前面除了。总结来说，这个参数决定了海拔越高，越容易被雪覆盖的真实场景特性。==对于参数e==，则是和地形的法向量相关，当然还会有高度的影响：这里的规则是，海拔越高，出现雪所要求的地形法向量范围越大——海拔高的情况，除非是峭壁，不然都有很大概率被雪覆盖，而在海拔低的地区，则很难出现雪，除非法向量无限接近（0,1,0）的平地，而这里，据我观察，会有一个问题，那就是会导致零星雪（海拔低但完全平行的点会出现雪，但是因为地形是随机生成的，它的周围的点大概率不会平行，那么就不会被雪覆盖。这样就会很奇怪）。==对于参数o==，就公式而言，和法向量的x分量和海拔高度有关（正相关），就效果而言，有无，雪的分布基本无变化。但是仔细分析会有这样的想法：场景中，太阳的x坐标是-0.8，那么nor.x是负值的情况下，则说明该点所在坡是正对着太阳的，那么很明显，这种雪的覆盖率应该会降低，在通过海拔进行修正（只要海拔够高，管你有没有对着太阳，当然，峭壁除外）。==最后==，这三个参数进行相乘，决定该点是否被雪覆盖。

  ```c#
float h = smoothstep(55.0,80.0,pos.y/SC + 25.0*fbm(0.01*pos.xz/SC) );
float e = smoothstep(1.0-0.5*h,1.0-0.1*h,nor.y);
float o = 0.3 + 0.7*smoothstep(0.0,0.1,nor.x+h*h);
float s = h*e*o;
col = mix( col, 0.29*vec3(0.62,0.65,0.7), smoothstep( 0.1, 0.9, s ) );
  ```


### 光照计算

```c#
//环境光：越水平，环境光的强度越强
float amb = clamp(0.5+0.5*nor.y,0.0,1.0);
//漫反射
float dif = clamp( dot( light1, nor ), 0.0, 1.0 );
//
float bac = clamp( 0.2 + 0.8*dot( normalize( vec3(-light1.x, 0.0, light1.z ) ), nor ), 0.0, 1.0 );
//阴影参数计算
float sh = 1.0; 
if( dif>=0.0001 ) sh = softShadow(pos+light1*SC*0.05,light1);
```

首先，计算环境光，这里简单的进行了模拟：越水平，环境光越强。然后计算漫反射，比较简单。然后对参数bac，待定，暂时不知道其含义。之后，计算阴影，具体函数如下：明显是RayMarching中比较常见的柔和阴影计算，没有什么意料之外的操作。（这一点，在IQ博客系列阅读中有过分析和介绍）

```c
float softShadow(in vec3 ro, in vec3 rd )
{
    float res = 1.0;
    float t = 0.001;
	for( int i=0; i<80; i++ )
	{
	    vec3  p = ro + t*rd;
        float h = p.y - terrainM( p.xz );
		res = min( res, 16.0*h/t );
		t += h;
		if( res<0.001 ||p.y>(SC*200.0) ) break;
	}
	return clamp( res, 0.0, 1.0 );
}
```

在之后，是光强lin的具体计算，依次计算了实际具体的环境光，漫反射（当然，阴影参数应该在这里使用到），还有bac，最后和col相乘。这里比较意外的是，在阴影参数的使用上，对RGB三个通道进行了不同的变化——R通道的衰减速度是要慢于G，B通道，虽然这个处理对于整个场景的表现没有明显影响，但还是要注意。此外，关于bac，其有无同样对于场景表现无影响。

```c
vec3 lin  = vec3(0.0);
lin += dif*vec3(8.00,5.00,3.00)*1.3*vec3( sh, sh*sh*0.5+0.5*sh, sh*sh*0.8+0.2*sh );
lin += amb*vec3(0.40,0.60,1.00)*1.2;
lin += bac*vec3(0.40,0.50,0.60);
col *= lin;
```

下面两行公式的意义不知。在效果上，增删与否对于表现无明显影响。参数s的再次使用，应该是让雪和山地的光照计算产生一定的差异，毕竟是不同的物质，雪的光吸收应该弱于山地，所以雪覆盖的地方，是1，而山地则是0.7。

```c
col += (0.7+0.3*s)*(0.04+0.96*pow(clamp(1.0+dot(hal,rd),0.0,1.0),5.0))*
               vec3(7.0,5.0,3.0)*dif*sh*
               pow( clamp(dot(nor,hal), 0.0, 1.0),16.0);
        
col += s*0.65*pow(fre,4.0)*vec3(0.3,0.5,0.6)*smoothstep(0.0,0.6,ref.y);
```

雾的计算。比较简单，比较常规的雾的幂计算方法。注释的地方是让雾的颜色和太阳位置挂钩。

```c#
float fo = 1.0-exp(-pow(0.001*t/SC,1.5) );
vec3 fco = 0.65*vec3(0.4,0.65,1.0);// + 0.1*vec3(1.0,0.8,0.5)*pow( sundot, 4.0 );
col = mix( col, fco, fo );
```

最后，映射回伽马空间，返回最终Color和射线步进的距离。

```c
// sun scatter
col += 0.3*vec3(1.0,0.7,0.3)*pow( sundot, 8.0 );

// gamma
col = sqrt(col);
    
return vec4( col, t );
```

### 运动模糊的处理

```c#
// old camera position
float oldTime = time - 0.1 * 1.0/24.0; // 1/24 of a second blur
vec3 oldRo, oldTa; float oldCr, oldFl;
moveCamera( oldTime, oldRo, oldTa, oldCr, oldFl );
mat3 oldCam = setCamera( oldRo, oldTa, oldCr );

// world space
#if AA>1
	vec3 rd = cam * normalize(vec3(p,fl));
#endif
vec3 wpos = ro + rd*t;
// camera space
vec3 cpos = vec3( dot( wpos - oldRo, oldCam[0] ),
                  dot( wpos - oldRo, oldCam[1] ),
                  dot( wpos - oldRo, oldCam[2] ) );
// ndc space
vec2 npos = oldFl * cpos.xy / cpos.z;
// screen space
vec2 spos = 0.5 + 0.5*npos*vec2(iResolution.y/iResolution.x,1.0);


// compress velocity vector in a single float
vec2 uv = fragCoord/iResolution.xy;
spos = clamp( 0.5 + 0.5*(spos - uv)/0.25, 0.0, 1.0 );
vel = floor(spos.x*255.0) + floor(spos.y*255.0)*256.0;
```

首先，时间time减去1/24，然后依据之前说明的相机相关函数，得到坐标系变化矩阵。

```c#
// old camera position
float oldTime = time - 0.1 * 1.0/24.0; // 1/24 of a second blur
vec3 oldRo, oldTa; float oldCr, oldFl;
moveCamera( oldTime, oldRo, oldTa, oldCr, oldFl );
mat3 oldCam = setCamera( oldRo, oldTa, oldCr );
```

然后，依靠t得到当前点的世界坐标wpos，在依据常规流程计算出该点在旧时间的屏幕空间坐标

```c#
// camera space
vec3 cpos = vec3( dot( wpos - oldRo, oldCam[0] ),
                  dot( wpos - oldRo, oldCam[1] ),
                  dot( wpos - oldRo, oldCam[2] ) );
// ndc space
vec2 npos = oldFl * cpos.xy / cpos.z;
// screen space
vec2 spos = 0.5 + 0.5*npos*vec2(iResolution.y/iResolution.x,1.0);
```

最后，压缩速度

```c#
// compress velocity vector in a single float
vec2 uv = fragCoord/iResolution.xy;
spos = clamp( 0.5 + 0.5*(spos - uv)/0.25, 0.0, 1.0 );
vel = floor(spos.x*255.0) + floor(spos.y*255.0)*256.0;
```

