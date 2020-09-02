# RM-F代码解析

作者：shau，网址：https://www.shadertoy.com/view/MsVcRy

标签：3D，带状条纹，Moody Clouds，髓质效果

总共一个部分：Image

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/IQ%E5%A4%A7%E7%A5%9E%E5%8D%9A%E5%AE%A2%E9%98%85%E8%AF%BB/%E5%9B%BE%E7%89%87/ShaderToy%E4%BC%98%E7%A7%80%E4%BB%A3%E7%A0%81%E8%A7%A3%E6%9E%90/RM-F.gif)



### Image

​	首先自定义了一个结构体Scene

```c
struct Scene {
    //射线步进的距离
    float t;
    //物体标号：外球，内球，还是地板
    float id;
    //法线
    vec3 n;
    //近交点位置
    float stn;
    //远交点位置
    float stf;
};
```

​	一开始，常规的坐标变化和相机设置

```c
vec2 uv = (fragCoord.xy - iResolution.xy * 0.5) / iResolution.y;
vec3 ro, rd;
setupCamera(uv, ro, rd);
```

#### DrawScene

然后，转到drawScene函数中（返回填充好的Scene的结构体）,进行场景搭建

```c
Scene drawScene(vec3 ro, vec3 rd) {
    float mint = FAR;
    vec3 minn = vec3(0.0);
    float id = 0.0;

    vec3 fo = vec3(0.0, -1.0, 0.0);
    vec3 fn = vec3(0.0, 1.0, 0.0);
    float ft = planeIntersection(ro, rd, fn, fo);
    if (ft > 0.0 && ft < FAR) {
        mint = ft;
        id = FLOOR;
        minn = fn;
    }    
    
    vec4 si = sphIntersect(ro, rd, sphere);
    if (si.x > 0.0 && si.x < mint) {        
        vec3 rp = ro + rd * si.x;
        mint = si.x;
        id = SPHERE_EXTERIOR;
        minn = sphNormal(rp, sphere);
    } else if (si.y > 0.0 && si.y < mint) {        
        vec3 rp = ro + rd * si.y;
        mint = si.y;
        id = SPHERE_INTERIOR;
        minn = -sphNormal(rp, sphere);
    }
    
    return Scene(mint, id, minn, si.z, si.w);;
}

```

+  首先是进行平面相交测试（来自IQ的工具博客），对于n，仅仅是作为向上向量进行点积求值，而o，则是决定地板的高度。在之后，进行传值。

  ```
  float planeIntersection(vec3 ro, vec3 rd, vec3 n, vec3 o) {
      return dot(o - ro, n) / dot(rd, n);
  }
  ```

+ 然后进行球体相交测试，这里和一般的相交测试不同的是，对于两个交点进行了pattern测试，对于原理，不太懂，但就效果而言，这个函数导致了球上的条带状条纹。在pattern函数内，就代码分析，abs和两个step函数的相乘的有否，不会对最终效果产生明显影响，而核心毫无疑问是$f.xy = f.x > .5 ? rp.yz / rp.x : f.y > .5 ? rp.xz / rp.y : rp.xy / rp.z; $，这里的常数0.5的数值大小对于实际效果无明显影响（所以到底有什么用），但是这个分支的存在导致了多个条纹（容易想得到），而在tex函数中，对于条纹的宽度进行了控制。回到测试函数，如果是条纹部分，则设置相应变量为0。

  ```c
  float tex(vec3 rp) {
      rp.xy *= rot(T);
      if (rp.y > 0.1&& rp.y < 0.2) return 0.0;
      return 1.0;
  }        
  //Cube mapping trick from Fizzer
  float pattern(vec3 rp) {
      vec3 f = abs(rp);
      f = step(f.zxy, f) * step(f.yzx, f); 
      f.xy = f.x > .5 ? rp.yz / rp.x : f.y > .5 ? rp.xz / rp.y : rp.xy / rp.z; 
      return tex(f);
  }
  //See sphere functions IQ
  //http://iquilezles.org/www/articles/spherefunctions/spherefunctions.htm
  //slightly modified for cut patterns
  vec4 sphIntersect(vec3 ro, vec3 rd, vec4 sph) {
      vec3 oc = ro - sph.xyz;
      float b = dot(oc, rd);
      float c = dot(oc, oc) - sph.w * sph.w;
      float h = b * b - c;
      if (h < 0.0) return vec4(0.0); //missed
      h = sqrt(h);
      float tN = -b - h;
      float tNF = tN;
      if (pattern(ro + rd * tNF) == 0.0) tNF = 0.0;
      float tF = -b + h;
      float tFF = tF;
      if (pattern(ro + rd * tFF) == 0.0) tFF = 0.0;
      return vec4(tNF, tFF, tN, tF);
  }
  ```

+ 回到drawScene主函数，这里根据测试结果进行相应赋值，问题在于，根据两个交点的返回结果，将球形测试划分了两个部分，我一开始以为是内球和外球，但实际结果是正面亮纹和背面暗纹的区分。



#### ColourScene

​	然后将scene结构体传入此函数中，也是此shader最重要的部分。

```c#
vec3 colourScene(vec3 ro, vec3 rd, Scene scene) {
    
    vec3 pc = clouds(rd) * glowColour();
    vec3 gc = vec3(0.0);
    vec3 lp = vec3(4.0, 5.0, -2.0);
	//交点的世界坐标
    vec3 rp = ro + rd * scene.t;
    	
    vec3 ld = normalize(lp - rp);
    float lt = length(lp - rp);
    float atten = 1.0 / (1.0 + lt * lt * 0.051);
    
    if (scene.stn > 0.0) {
        gc = fractalMarch(ro + rd * scene.stn, rd, scene.stf - scene.stn);
        pc = gc;
    }

    if (scene.id == FLOOR) {
        
        // calc texture sampling footprint	
        vec3 uvw = texCoords(rp * 0.15);
		vec3 ddx_uvw = dFdx(uvw); 
    	vec3 ddy_uvw = dFdy(uvw);
        float fc = checkersTextureGradTri(uvw, ddx_uvw, ddy_uvw);
        
    	float diff = max(dot(ld, scene.n), 0.05);
        float ao = 1.0 - sphOcclusion(rp, scene.n, sphere);  
        float spec = pow(max(dot(reflect(-ld, scene.n), -rd), 0.0), 32.0);
        float sh = sphSoftShadow(rp, ld, sphere, 2.0);

        pc += glowColour() * fc * diff * atten;
        pc += vec3(1.0) * spec;
        pc *= ao * sh; 
        
        vec3 gld = normalize(-rp);
        if (sphIntersect(rp, gld, sphere).x == 0.0) {
            pc += glowColour() / (1.0 + length(rp) * length(rp));    
        }
    }
    
    if (scene.id == SPHERE_EXTERIOR) {
    	
        float ao = 0.5 + 0.5 * scene.n.y;
        float spec = pow(max(dot(reflect(-ld, scene.n), -rd), 0.0), 32.0);
        float fres = pow(clamp(dot(scene.n, rd) + 1.0, 0.0, 1.0), 2.0);
        
        pc *= 0.4 * (1.0 - fres);
        pc += vec3(1.0) * fres * 0.2;
        pc *= ao;
        pc += vec3(1.0) * spec;
    }

      
    if (scene.id == SPHERE_INTERIOR) {
    	float ao = 0.5 + 0.5 * scene.n.y;
        float ilt = length(rp) - SR;
        pc += glowColour() * ao / (1.0 + ilt * ilt);
    }
    //*/
    
    return pc;
}
```

第一行代码：右乘项是根据时间在自定义的调色板上进行取值，左乘项如下所示，效果是产生Moody Clouds，使用了FBM函数，这里可以作为背景技术在以后的日子中使用。然后，就效果论，参数CT的分母影响云状网格的密度，分母越小，网格越密；此外，使用静态的CT实际上呈现并没有网格的效果，个人猜测，是函数原理上是周期函数，在每个周期的部分区域会呈现网格状效果

```c#
#define CT T / 15.0
//Moody clouds from Patu
//https://www.shadertoy.com/view/4tVXRV
vec3 clouds(vec3 rd) {
    vec2 uv = rd.xz / (rd.y + 0.6);
    float nz = fbm(vec3(uv.yx * 1.4 + vec2(CT, 0.0), CT)) * 1.5;
    //就效果而言,指数4.0配合Clamp,显而易见是控制云雾显示区域的面积,指数越小,云雾区域越大
    return clamp(pow(vec3(nz), vec3(4.0)) * rd.y, 0.0, 1.0);
}
```

![](C:\Users\ZoroD\Desktop\IQ--master\ShaderToy优秀代码阅读解析\MoodyCloud.gif)

然后，对于参数而言，lp是光源的位置，根据光源和交点的距离计算雾化参数atten，然后进行球内分形图案计算：如果击中了球，则转入fractalMarch函数

```c
 if (scene.stn > 0.0) {
        gc = fractalMarch(ro + rd * scene.stn, rd, scene.stf - scene.stn);
        pc = gc;
    }
......
#define SR 0.2
#define EPS 0.005
vec3 fractalMarch(vec3 ro, vec3 rd, float maxt) {
    
    vec3 pc = vec3(0.0);
    float t = 0.0;
    float ns = 0.;
    
    for (int i = 0; i < 64; i++) {
        
        vec3 rp = ro + t * rd;
        float lt = length(rp) - SR;

        ns = fractal(rp); 
        
        if (lt < EPS || t > maxt) break;
        t += 0.02 * exp(-2.0 * ns);

        pc = 0.99 * (pc + 0.08 * glowColour() * ns) / (1.0 + lt * lt * 1.);
        pc += 0.1 * glowColour() / (1.0 + lt * lt);  
    } 
    
    return pc;
}
```

+ 在球内进行射线步进的过程，和一般的过程相似，其中，SR决定了球体内部黑球的大小，然后我们需要分析的是fractal函数，射线推进和pc的取值都和它相关，这是髓质效果的核心。x的取值是为了动画效果，常数值也无所谓；在循环中，第一行（关键）是递归核心操作，计算新的rp值（取正值后归一化，然后利用x进行线性操作）；最后一行是根据rp的值计算res的增量（核心）；中间两行就效果而言，无明显作用。

  ```c
  vec2 csqr(vec2 a) {return vec2(a.x * a.x - a.y * a.y, 2.0 * a.x * a.y);}
  //fractal from GUIL
  //https://www.shadertoy.com/view/MtX3Ws
  float fractal(vec3 rp) {
  	
  	float res = 0.0;
  	float x = 0.8 + sin(T * 0.2) * 0.3;
      
      rp.yz *= rot(T);
      
      vec3 c = rp;
  	
      for (int i = 0; i < 10; ++i) {
          rp = x * abs(rp) / dot(rp, rp) - x;
          rp.yz = csqr(rp.yz);
          rp = rp.zxy;
          res += exp(-99.0 * abs(dot(rp, c)));   
  	}
      
      return res;
  }
  ```

  在进行实验时，如果将rp递归更新的公式中的减法变成加法，会有带状星球的效果。之后，是分情况进行渲染。
  
  第一种是渲染地板。将点的坐标进行缩放之后，获取它的梯度（ddx，ddy），然后进行如下棋盘处理（关于这个技术，在IQ7中有更为详细的介绍）
  
  ```c
  // see https://www.shadertoy.com/view/MtffWs
  vec3 pri(vec3 x) {
      vec3 h = fract(x / 2.0) - 0.5;
      return x * 0.5 + h * (1.0 - 2.0 * abs(h));
  }
  
  float checkersTextureGradTri(vec3 p, vec3 ddx, vec3 ddy) {
      p.z += T;
      vec3 w = max(abs(ddx), abs(ddy)) + 0.01; // filter kernel
      vec3 i = (pri(p + w) - 2.0 * pri(p) + pri(p - w)) / (w * w); // analytical integral (box filter)
      return 0.5 - 0.5 * i.x *  i.y * i.z; // xor pattern
  }
  ```
  
  然后依次计算diff，AO，spec，球的柔和阴影。
  
  ```c
  float diff = max(dot(ld, scene.n), 0.05);
  float ao = 1.0 - sphOcclusion(rp, scene.n, sphere);  
  float spec = pow(max(dot(reflect(-ld, scene.n), -rd), 0.0), 32.0);
  float sh = sphSoftShadow(rp, ld, sphere, 2.0);
  ```
  
  然后计算条纹在地板上产生的光影
  
  ```c
   vec3 gld = normalize(-rp);
   if (sphIntersect(rp, gld, sphere).x == 0.0) {
         pc += glowColour() / (1.0 + length(rp) * length(rp));    
   }
  ```
  
  然后是计算SPHERE_EXTERIOR下的球，这也是球体渲染的主要部分，一开始，简单的AO和常规的Spec项计算，然后是菲涅尔项计算fres（越接近球的中心，此项越小）
  
  ```c
  float ao = 0.5 + 0.5 * scene.n.y;
  float spec = pow(max(dot(reflect(-ld, scene.n), -rd), 0.0), 32.0);
  float fres = pow(clamp(dot(scene.n, rd) + 1.0, 0.0, 1.0), 2.0);
  //此项导致球的外围黑化，中心影响较小，符合电解质的性质
  pc *= 0.4 * (1.0 - fres);
  //此项在球的边缘加了一层白边，更加符合现实
  pc += vec3(1.0) * fres * 0.2;
  pc *= ao;
  pc += vec3(1.0) * spec;
  ```
  
  最后一种情况，无论是代码还是效果都较为简单，就不分析了。

再次回到主函数，进行最后一步，在原有计算结果上加上vMarch函数的返回值。这里的作用是为球的带状条纹增加发光效果。在射线步进的循环中，每次移动的步伐是一致的，但是，不是很懂这个map函数和对应的ns变量的作用，在之后，比较简单，从当前点的位置往球心的位置投射线进行相交测试，若是打在光带上，则进行对应渲染

```c
float map(vec3 rp) {
	return min(length(rp) - sphere.w, rp.y + 1.0);
}

vec3 vMarch(vec3 ro, vec3 rd) {

    vec3 pc = vec3(0.0);
    float t = 0.0;
    
    for (int i = 0; i < 96; i++) {
        
        vec3 rp = ro + rd * t;
        float ns = map(rp);
        //这个不管是作用分析还是实际效果上，都无明显作用
        float fz = pattern(rp);
        
        if ((ns < EPS && fz > 0.0) || t > FAR) break;
        
        vec3 ld = normalize(-rp);
        float lt = length(rp);
        //lt项对效果无影响
        if (sphIntersect(rp, ld, sphere).x == 0.0 || lt < sphere.w) {
            lt -= SR;//不重要
            pc += glowColour() * 0.1 / (1.0 + lt * lt * 12.0);        
        }
        
        t += 0.05;
    }
    
    return pc;
}
```

![](C:\Users\ZoroD\Desktop\IQ--master\ShaderToy优秀代码阅读解析\DFG.PNG)







### 工具类

#### IQ噪声

```c#
//IQs noise
float noise(vec3 rp) {
    vec3 ip = floor(rp);
    rp -= ip; 
    vec3 s = vec3(7, 157, 113);
    vec4 h = vec4(0.0, s.yz, s.y + s.z) + dot(ip, s);
    rp = rp * rp * (3.0 - 2.0 * rp); 
    h = mix(fract(sin(h) * 43758.5), fract(sin(h + s.x) * 43758.5), rp.x);
    h.xy = mix(h.xz, h.yw, rp.y);
    return mix(h.x, h.y, rp.z); 
}
```

#### 常规FBM(H=1,G=0.5)

```c
float fbm(vec3 x) {
    float r = 0.0;
    float w = 1.0;
    float s = 1.0;
    for (int i = 0; i < 5; i++) {
        w *= 0.5;
        s *= 2.0;
        r += w * noise(s * x);
    }
    return r;
}
```

>>>>>>> 98573fd... update in my pc
