作者：iq，网址：https://www.shadertoy.com/view/MdX3Rr

标签：[procedural](https://www.shadertoy.com/results?query=tag%3Dprocedural), [3d](https://www.shadertoy.com/results?query=tag%3D3d), [raymarching](https://www.shadertoy.com/results?query=tag%3Draymarching), [distancefield](https://www.shadertoy.com/results?query=tag%3Ddistancefield), [terrain](https://www.shadertoy.com/results?query=tag%3Dterrain), [motionblur](https://www.shadertoy.com/results?query=tag%3Dmotionblur)

总共两个部分：Image，Buffer A



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

+ 对于<u>camPath</u>，明显是计算相机的x，z位置，这里的问题的常量SC和1100为什么这么大，暂且不知。推测原因是采样扩大，坐标范围极大，毕竟我们这里显示的是无边的地形。此外，SC是全局变量，是有很多意义的，但调节的效果无法归纳其作用，而1100这个常量根据调整的结果，可以理解为相机的移动速度。

+ 然后根据terrainL计算此时相机xz位置对应的地形高度。（这里的算法就不做介绍了，个人估计是额外的地形生成算法），然后往上面做一个偏移，求出观察位置的Y（高度）以及视线向量的Y

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

然后进入抗锯齿的循环之中，将屏幕坐标p重映射回裁剪空间，然后使用fl和得到的相机矩阵，计算射线在世界空间的值。因此fl可以理解为裁剪平面的位置。

```c#
vec3 rd = cam * normalize(vec3(s,fl));
```

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
          vec3 pos = ro + t*rd;
  		float h = pos.y - terrainM( pos.xz );
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

  如果返回结果小于tmax，则开始渲染地面，首先简单的计算击中点的法线

  ```c#
  vec3 calcNormal( in vec3 pos, float t )
  {
      vec2  eps = vec2( 0.001*t, 0.0 );
      return normalize( vec3( terrainH(pos.xz-eps.xy) - terrainH(pos.xz+eps.xy),
                              2.0*eps.x,
                              terrainH(pos.xz-eps.yx) - terrainH(pos.xz+eps.yx) ) );
  }
  ```

  然后，计算岩石的颜色，这里的核心代码是第一行和第二行，后续都是一些优化和增加随机性，但是确实看不太懂

  ```c#
  float r = texture( iChannel0, (7.0/SC)*pos.xz/256.0 ).x;
  col = (r*0.25+0.75)*0.9*mix( vec3(0.08,0.05,0.03), vec3(0.10,0.09,0.08), texture(iChannel0,0.00007*vec2(pos.x,pos.y*48.0)/SC).x );
  col = mix( col, 0.20*vec3(0.45,.30,0.15)*(0.50+0.50*r),smoothstep(0.70,0.9,nor.y) );
  col = mix( col, 0.15*vec3(0.30,.30,0.10)*(0.25+0.75*r),smoothstep(0.95,1.0,nor.y) );
  col *= 0.1+1.8*sqrt(fbm(pos.xz*0.04)*fbm(pos.xz*0.005));
  ```

  雪的计算

  ```c#
  float h = smoothstep(55.0,80.0,pos.y/SC + 25.0*fbm(0.01*pos.xz/SC) );
  float e = smoothstep(1.0-0.5*h,1.0-0.1*h,nor.y);
  float o = 0.3 + 0.7*smoothstep(0.0,0.1,nor.x+h*h);
  float s = h*e*o;
  col = mix( col, 0.29*vec3(0.62,0.65,0.7), smoothstep( 0.1, 0.9, s ) );
  ```

  暂且告一段落，目前只是水平不够，很多还是看不懂，还是刷完博客再来继续突进吧。

  2020.04.28

