# Playing Marble代码解析

作者：Guil，网址：https://www.shadertoy.com/view/MtX3Ws

标签：3D，分形，volumetric

![](PlayM.gif)

### Image

一开始，常规的坐标变换，处理鼠标点击事件，然后照相机设置，然后进行IQ的球体相交测试

```
vec2 tmm = iSphere( ro, rd, vec4(0.,0.,0.,2.) );
```

然后是核心的rayMarch函数，这里是进行髓质计算，关于这一部分，在RM-F中有详细介绍，这里就不说了

```c
float map(in vec3 p) {
	
	float res = 0.;
	
    vec3 c = p;
	for (int i = 0; i < 10; ++i) {
        p =.7*abs(p)/dot(p,p) -.7;
        p.yz= csqr(p.yz);
        p=p.zxy;
        res += exp(-19. * abs(dot(p,c)));
        
	}
	return res/2.;
}
vec3 raymarch( in vec3 ro, vec3 rd, vec2 tminmax )
{
    float t = tminmax.x;
    float dt = .02;
    //float dt = .2 - .195*cos(iTime*.05);//animated
    vec3 col= vec3(0.);
    float c = 0.;
    for( int i=0; i<64; i++ )
	{
        t+=dt*exp(-2.*c);
        if(t>tminmax.y)break;
        vec3 pos = ro+t*rd;
        
        c = map(ro+t*rd);               
        
        col = .99*col+ .08*vec3(c*c, c, c*c*c);//green	
        //col = .99*col+ .08*vec3(c*c*c, c*c, c);//blue
    }    
    return col;
}
```

回到主函数，对于球的渲染计算如下：

```c
 vec3 nor=(ro+tmm.x*rd)/2.;
 nor = reflect(rd, nor);        
 float fre = pow(.5+ clamp(dot(nor,rd),0.0,1.0), 3. )*1.3;
 col += texture(iChannel0, nor).rgb * fre;
```

