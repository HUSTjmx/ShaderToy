# Volumetric Stanford Bunny

原网址：https://www.shadertoy.com/view/MdlyDs

<img src="Volumetric Stanford Bunny.assets/image-20220328120114571.png" alt="image-20220328120114571" style="zoom: 67%;" />

## 1. mainImage分析1

:one:一开始是比较简单的，包括：坐标变换（得到`UV`）、鼠标控制、散射属性的设置（包括：**散射系数**和**吸收系数**）：

```c++
void mainImage( out float4 fragColor, in float2 fragCoord )
{   
    // 坐标变换
	float2 uv = fragCoord.xy / iResolution.xy;
	fragColor = float4(uv,0.5+0.5*sin(iTime),1.0);
    float time = iTime;
    
    // 鼠标控制
	vec2 mouseControl = iMouse.xy / iResolution.xy;
    erosionStrength = iMouse.z>0.0 ? mouseControl.y * 4.0 : erosionStrength;
    
    // 散射属性的设置
#if BASIC_ANIMATED_MEDIA==1
    float r = floor(time);
    scattering = abs(25.0* float3(rand(float3(r,0.0,1.0)),rand(float3(r,0.0,5.0)),rand(float3(r,0.0,9.0))));
    absorption = abs(5.0* float3(rand(float3(r,1.0,2.0)),rand(float3(r,1.0,7.0)),rand(float3(r,1.0,7.0))));
#elif BASIC_ANIMATED_MEDIA==2
    float r = time*0.2;
    scattering = abs(25.0* float3(sin(r*1.1),sin(r*3.3),sin(r*5.5)));
    absorption = abs( 5.0* float3(sin(r*2.2),sin(r*4.4),sin(r*6.6)));
#endif
```

:two:然后是进行**相机的设置**，以及`ray`方向的变换：

```c++
// View diretion in camera space
float3 viewDir = normalize(float3((fragCoord.xy - iResolution.xy*0.5) / iResolution.y, 1.0));
viewDir*= float3(0.9,1.0,1.0);

Lpos = float3(0.85*cos(time*0.55),1.5, 0.85*sin(time*1.0));

// Compute camera properties
float  camDist = 10.0;
float3 camUp = float3(0,1,0);
float3 camPos = float3(camDist*cos(time*0.51),8.0, camDist*sin(time*0.51));
camPos = iMouse.z<=0.0 ? camPos : float3(camDist*cos(mouseControl.x*10.0),8.0, camDist*sin(mouseControl.x*10.0));
float3 camTarget = float3(0,3.0,0);

// And from them evaluted ray direction in world space
float3 forward = normalize(camTarget - camPos);
float3 left = normalize(cross(forward, camUp));
float3 up = cross(left, forward);
float3 worldDir = viewDir.x*left + viewDir.y*up + viewDir.z*forward;
```

:three:然后计算地面（包括斯坦福兔子在地面上投射的阴影），首先计算和地面的交点，以及地面的颜色：

```c++
//// Render the flat ground with lighting and volumetric shadows
float3 color= float3(0.0, 0.0, 0.0);
float3 groundIntersection = camPos + worldDir * abs(camPos.y/worldDir.y);
float2 groundUv = groundIntersection.xz*0.1;
float3 groundTex = texture(iChannel0, groundUv).xyz;
```

然后是计算渲染方程所需的各个参数，包括：阴影项、衰减项、法线：

```c++
float3 worldPosTocubePos(float3 worldPos)
{
    // cube of world space size 4 with bottom face on the ground y=0
    // 世界空间的立方体，大小为4，底面在地面(y=0)上
    return worldPos*0.15 + float3(0.0,-0.5,0.0);
}

// Returns the light distance attenuation
float distanceAttenuation(float distance)
{
    float lightMaxRadius = 3.0;
    float linAtt = clamp((lightMaxRadius-distance)/lightMaxRadius,0.0,1.0);
    linAtt*=linAtt;	// some "fake artistic" attenuation
    return linAtt/(distance*distance);
}

...
// 这个if只是为了加速，因为y大于0的区域本身就属于地面
if(worldDir.y<0.0)
{
    // ground position to cube space for lighting evaluation
    // 这里是将相交点，转换到cubePos，但背后的原理是什么？
    float3 cubeSpacePos= worldPosTocubePos(groundIntersection)+0.5;

    float3 shadow = getShadowTransmittance(cubeSpacePos,2.0,0.05);

    float3 Ldir = Lpos-cubeSpacePos;
    float Ldist = length(Ldir);
    float3 LdirNorm = Ldir / max(0.0001, Ldist);
    float Lattenuation = distanceAttenuation(Ldist);

    float N00 = texture(iChannel0, groundUv + float2( 0.001, 0.001)).g;
    float N01 = texture(iChannel0, groundUv + float2( 0.001,-0.001)).g;
    float N10 = texture(iChannel0, groundUv + float2(-0.001, 0.001)).g;
    float N11 = texture(iChannel0, groundUv + float2(-0.001,-0.001)).g;
    float3 N = cross(normalize(float3(1.0,25.0*(N11-N00),1.0)),normalize(float3(1.0,25.0*(N10-N01),-1.0)));

    color = groundTex * shadow * Lattenuation * L * dot(N,LdirNorm);
}
```

根据对` worldPosTocubePos`中的常数进行修改，感觉`cubePos`就是进行了缩放和平移，作用？感觉是了为了更好的**控制观察区域**：

+ `worldPos`的因子：代码中是`0.15`，这个似乎很像控制`FOV`的大小，有种**放大缩小**的感觉。
+ `vec3`常数：文中是`(0,-0.5,0)`，这个感觉是用来**控制灯光的位置**。因为灯光的位置`LPos`是设置在`cubePos`中的，这虽然是**固定的**，但我们只要改变**变换函数**，那么我们**世界空间转换后的位置**也不同了。变相的，相当于移动了光源。

我们后面用一个单独的小节，来分析`getShadowTransmittance`的函数调用链。这里快速看看此函数之后的代码：衰减项就是通过常见的平分衰减方法得到的，而法线计算也很简单（这里是`shadertoy`的常用技法：法线和颜色是同一张纹理图），最后应用**兰伯特漫反射**，



## 2. getShadowTransmittance分析

:one:这里单独分析`getShadowTransmittance`函数以及其调用链：

```c++
// Get transmittance from a direction and distance onto a point (volume shadows)
float3 getShadowTransmittance(float3 cubePos, float sampledDistance, float stepSizeShadow)
{
    float3 shadow = float3(1.0);
    float3 Ldir = normalize(Lpos-cubePos);
    for(float tshadow=0.0; tshadow<sampledDistance; tshadow+=stepSizeShadow)
    {
        float3 cubeShadowPos = cubePos + tshadow*Ldir;
        float densityShadow = getDensity(cubeShadowPos);
        shadow *= exp(-densityShadow * extinction * stepSizeShadow);
    }
    return shadow;
}
```

逻辑很简单，以当前点`cubePos`为`origin`，以`LPos-cubePos`为`dir`，进行步进。每次步进，都会调用`densityShadow`方法得到当前位置的介质密度，然后利用这个密度，以及消光率，来计算幂函数，最后近似阴影系数。

:two:分析`densityShadow`：

```c++
// Get density for a position
float getDensity(float3 cubePos)
{
    float density = sampleBunny(cubePos);
    if(density==0.0) return 0.0;	// makes things a tad bit faster
#if FBM_NOISE
    float3 noiseUV = cubePos*12.0;
	#if BASIC_ANIMATED_NOISE
    noiseUV += iTime * float3(1.0,0.0,0.0);
	#endif
    density = density * max(0.0, 1.25*erosionStrength*linearRandFBM(noiseUV)*4.0-2.0); // more complex FBM noise
#else
    float3 noiseUV = cubePos*16.0;
	#if BASIC_ANIMATED_NOISE
    noiseUV += iTime * float3(1.0,0.0,0.0);
	#endif
    density = density * max(0.0, 0.5 + 0.5*erosionStrength*linearRand(noiseUV));
#endif
    return density;
}
```

这里逻辑也不复杂，就是使用`sampleBunny`得到**斯坦福兔子的密度**，然后应用噪声：这里又分是否使用动态噪声、应用噪声的类型。

而`sampleBunny`这里则不分析，因为这仅仅是**经验主义**：

```c++
//////////////////////////////////////////////////
// Bunny volume data
//////////////////////////////////////////////////

// Packed 32^3 bunny data as 32x32 uint where each bit represents density per voxel
#define BUNNY_VOLUME_SIZE 32
const uint packedBunny[1024] = uint[1024](0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,917504u,917504u,917504u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,1966080u,12531712u,16742400u,16742400u,16723968u,16711680u,8323072u,4128768u,2031616u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,6144u,2063360u,16776704u,33553920u,33553920u,33553920u,33553920u,33520640u,16711680u,8323072u,8323072u,2031616u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,268435456u,402653184u,134217728u,201326592u,67108864u,0u,0u,7168u,2031104u,16776960u,33554176u,33554176u,33554304u,33554176u,33554176u,33554176u,33553920u,16744448u,8323072u,4128768u,1572864u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,805306368u,939524096u,402653184u,478150656u,260046848u,260046848u,260046848u,125832192u,130055680u,67108608u,33554304u,33554304u,33554304u,33554304u,33554304u,33554304u,33554304u,33554176u,16776704u,8355840u,4128768u,917504u,0u,0u,0u,0u,0u,0u,0u,0u,0u,805306368u,1056964608u,1056964608u,528482304u,528482304u,260046848u,260046848u,260046848u,130039296u,130154240u,67108739u,67108807u,33554375u,33554375u,33554370u,33554368u,33554368u,33554304u,33554304u,16776960u,8330240u,4128768u,393216u,0u,0u,0u,0u,0u,0u,0u,0u,939524096u,1040187392u,1040187392u,520093696u,251658240u,251658240u,260046848u,125829120u,125829120u,130088704u,63045504u,33554375u,33554375u,33554375u,33554407u,33554407u,33554370u,33554370u,33554374u,33554310u,16776966u,4144642u,917504u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,15360u,130816u,262017u,4194247u,33554383u,67108847u,33554415u,33554407u,33554407u,33554375u,33554375u,33554318u,2031502u,32262u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,31744u,130816u,262019u,2097151u,134217727u,134217727u,67108863u,33554415u,33554407u,33554415u,33554383u,2097102u,982926u,32262u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,31744u,130816u,524263u,117964799u,127926271u,134217727u,67108863u,16777215u,4194303u,4194303u,2097151u,1048574u,65422u,16134u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,3u,31751u,130951u,524287u,252182527u,261095423u,261095423u,59768830u,2097150u,1048574u,1048575u,262143u,131070u,65534u,16134u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,7u,31751u,130959u,503840767u,520617982u,529530879u,261095423u,1048575u,1048574u,1048574u,524286u,524287u,131070u,65534u,16134u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,3u,1799u,32527u,134348750u,1040449534u,1057488894u,520617982u,51380223u,1048575u,1048575u,524287u,524287u,524287u,131070u,65534u,15886u,6u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,1536u,3968u,8175u,65535u,1006764030u,1040449534u,1057488894u,50855934u,524286u,524286u,524287u,524287u,524286u,262142u,131070u,65534u,32270u,14u,6u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,3968u,8160u,8191u,805371903u,2080505854u,2114191358u,101187582u,34078718u,524286u,524286u,524286u,524286u,524286u,524286u,262142u,131070u,32766u,8078u,3590u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,8128u,8176u,16383u,2013331455u,2080505854u,235143166u,101187582u,524286u,1048574u,1048574u,1048574u,1048574u,524286u,524286u,262142u,131070u,32766u,16382u,8070u,1024u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,8160u,8184u,1879064574u,2013331455u,470024190u,67371006u,524286u,1048574u,1048574u,1048574u,1048574u,1048574u,1048574u,524286u,524286u,262142u,65534u,16382u,8160u,1024u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,8128u,8184u,805322750u,402718719u,134479870u,524286u,524286u,1048574u,1048574u,1048574u,1048574u,1048574u,1048574u,1048574u,524286u,262142u,65534u,16382u,16368u,1792u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,3968u,8184u,16382u,131071u,262142u,524286u,1048574u,1048574u,1048574u,1048574u,1048574u,1048574u,1048574u,1048574u,524286u,262142u,65534u,16382u,16368u,1792u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,1792u,8184u,16380u,65535u,262143u,524286u,524286u,1048574u,1048574u,1048575u,1048574u,1048574u,1048574u,1048574u,524286u,262142u,65534u,16376u,16368u,1792u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,8176u,16376u,32767u,262143u,524286u,1048574u,1048574u,1048575u,1048575u,1048575u,1048575u,1048574u,1048574u,524286u,262142u,32766u,16376u,8176u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,4032u,8184u,32766u,262142u,524286u,524286u,1048575u,1048574u,1048574u,1048574u,1048574u,1048574u,1048574u,524286u,262142u,32766u,16376u,8176u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,384u,8184u,32766u,131070u,262142u,524286u,1048575u,1048574u,1048574u,1048574u,1048574u,1048574u,524286u,524286u,131070u,32766u,16368u,1920u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,4080u,32764u,65534u,262142u,524286u,524286u,524286u,1048574u,1048574u,524286u,524286u,524286u,262142u,131070u,32764u,8160u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,256u,16376u,32760u,131068u,262140u,262142u,524286u,524286u,524286u,524286u,524286u,262142u,131070u,65532u,16368u,3840u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,3968u,32752u,65528u,131068u,262142u,262142u,262142u,262142u,262142u,262142u,262140u,131064u,32752u,7936u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,8064u,32736u,65528u,131070u,131070u,131070u,131070u,131070u,131070u,65532u,32752u,8160u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,3456u,16376u,32764u,65534u,65534u,65534u,32766u,32764u,16380u,4048u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,48u,2680u,8188u,8188u,8188u,8188u,4092u,120u,16u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,120u,248u,508u,508u,508u,248u,240u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,96u,240u,504u,504u,504u,240u,96u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,224u,224u,224u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u,0u);


float sampleBunny(float3 uvs)
{
    float3 voxelUvs = max(float3(0.0),min(uvs*float3(BUNNY_VOLUME_SIZE), float3(BUNNY_VOLUME_SIZE)-1.0));
    uint3 intCoord = uint3(voxelUvs);
    uint arrayCoord = intCoord.x + intCoord.z*uint(BUNNY_VOLUME_SIZE);
	
    // Very simple clamp to edge. It would be better to do it for each texture sample
    // before the filtering but that would be more expenssive...
    // Also adding small offset to catch cube intersection floating point error
    if(uvs.x<-0.001 || uvs.y<-0.001 || uvs.z<-0.001 ||
      uvs.x>1.001 || uvs.y>1.001 || uvs.z>1.001)
    	return 0.0;
   
    // 1 to use nearest instead
#if VOLUME_FILTERING_NEAREST
    // sample the uint representing a packed volume data of 32 voxel (1 or 0)
    uint bunnyDepthData = packedBunny[arrayCoord];
    float voxel = (bunnyDepthData & (1u<<intCoord.y)) > 0u ? 1.0 : 0.0;
#else
    uint3 intCoord2 = min(intCoord+uint3(1), uint3(BUNNY_VOLUME_SIZE-1));
    
    uint arrayCoord00 = intCoord.x  + intCoord.z *uint(BUNNY_VOLUME_SIZE);
    uint arrayCoord01 = intCoord.x  + intCoord2.z*uint(BUNNY_VOLUME_SIZE);
    uint arrayCoord10 = intCoord2.x + intCoord.z *uint(BUNNY_VOLUME_SIZE);
    uint arrayCoord11 = intCoord2.x + intCoord2.z*uint(BUNNY_VOLUME_SIZE);
    
    uint bunnyDepthData00 = packedBunny[arrayCoord00];
    uint bunnyDepthData01 = packedBunny[arrayCoord01];
    uint bunnyDepthData10 = packedBunny[arrayCoord10];
    uint bunnyDepthData11 = packedBunny[arrayCoord11];
        
    float voxel000 = (bunnyDepthData00 & (1u<<intCoord.y)) > 0u ? 1.0 : 0.0;
    float voxel001 = (bunnyDepthData01 & (1u<<intCoord.y)) > 0u ? 1.0 : 0.0;
    float voxel010 = (bunnyDepthData10 & (1u<<intCoord.y)) > 0u ? 1.0 : 0.0;
    float voxel011 = (bunnyDepthData11 & (1u<<intCoord.y)) > 0u ? 1.0 : 0.0;
    float voxel100 = (bunnyDepthData00 & (1u<<intCoord2.y)) > 0u ? 1.0 : 0.0;
    float voxel101 = (bunnyDepthData01 & (1u<<intCoord2.y)) > 0u ? 1.0 : 0.0;
    float voxel110 = (bunnyDepthData10 & (1u<<intCoord2.y)) > 0u ? 1.0 : 0.0;
    float voxel111 = (bunnyDepthData11 & (1u<<intCoord2.y)) > 0u ? 1.0 : 0.0;
    
    float3 d = voxelUvs - float3(intCoord);
    
    voxel000 = mix(voxel000,voxel100, d.y);
    voxel001 = mix(voxel001,voxel101, d.y);
    voxel010 = mix(voxel010,voxel110, d.y);
    voxel011 = mix(voxel011,voxel111, d.y);
    
    voxel000 = mix(voxel000,voxel010, d.x);
    voxel001 = mix(voxel001,voxel011, d.x);
    
    float voxel = mix(voxel000,voxel001, d.z);
#endif
    
    return voxel;
}

```



## 3. mainImage分析2

:one:回到主函数，计算完地面之后，首先计算和**含有兔子的立方体**的交点：

```c++
float near = 0.0;
float far  = 0.0;
float3 cubeSpacePos= worldPosTocubePos(camPos);
if (cube(cubeSpacePos, worldDir, near, far))
{
    float3 scatteredLuminance = float3(0.0,0.0,0.0);
    float3 transmittance = float3(1.0);

    float stepSize = 0.01;
```

:two:然后就是标准的实现步进过程：

```c++
for(float t=near; t<far; t+=stepSize)
{
    float3 cubePos = cubeSpacePos + t*worldDir + 0.5;
    float density = getDensity(cubePos);

    float stepSizeShadow = 0.1;
    float3 shadow = getShadowTransmittance(cubePos,1.0, 0.1);


    float Ldist = length(Lpos-cubePos);
    float Lattenuation = distanceAttenuation(Ldist);

#if 0
    // Scattered luminance ignores phase function (assumes L has it baked in)
    // This is not energy conservative.
    scatteredLuminance += Lattenuation * shadow * transmittance * density *scattering * stepSize * L;       
    transmittance *= exp(-density * extinction * stepSize);
#else
    // Improved scattering integration. See slide 28 at http://www.frostbite.com/2015/08/physically-based-unified-volumetric-rendering-in-frostbite/
    vec3 S = L * Lattenuation * shadow * density *scattering;
    vec3 sampleExtinction = max(vec3(0.0000000001), density * extinction);
    vec3 Sint = (S - S * exp(-sampleExtinction * stepSize)) / sampleExtinction;
    scatteredLuminance += transmittance * Sint;

    // Evaluate transmittance to view independentely
    transmittance *= exp(-sampleExtinction * stepSize);
#endif
}
```

:three:最后：

```c++
// Apply volumetric on scene
	color = transmittance*color + scatteredLuminance;
}

fragColor = float4(pow(color, float3(1.0/2.2)),1.0); // simple linera to gamma
```



## 工具函数：噪声

```c++
float rand(vec3 co)
{
    return -1.0 + fract(sin(dot(co.xy,vec2(12.9898 + co.z,78.233))) * 43758.5453) * 2.0;
}

float linearRand(vec3 uv)
{
	vec3 iuv = floor(uv);
	vec3 fuv = fract(uv);
	
	float v1 = rand(iuv + vec3(0,0,0));
	float v2 = rand(iuv + vec3(1,0,0));
	float v3 = rand(iuv + vec3(0,1,0));
	float v4 = rand(iuv + vec3(1,1,0));
	
	float d1 = rand(iuv + vec3(0,0,1));
	float d2 = rand(iuv + vec3(1,0,1));
	float d3 = rand(iuv + vec3(0,1,1));
	float d4 = rand(iuv + vec3(1,1,1));
	
	return mix(mix(mix(v1,v2,fuv.x),mix(v3,v4,fuv.x),fuv.y),
		       mix(mix(d1,d2,fuv.x),mix(d3,d4,fuv.x),fuv.y),
			   fuv.z);
}

float linearRandFBM(vec3 uv)
{
	float c = (linearRand(uv * 1.0) * 32.0 +
			   linearRand(uv * 2.0) * 16.0 + 
			   linearRand(uv * 4.0) * 8.0 + 
			   linearRand(uv * 8.0) * 4.0) / 32.0;
	return c * 0.5 + 0.5;
}
```



## 工具函数：INSERT_CUBE

```c++
// From https://www.shadertoy.com/view/4s23DR
bool cube(vec3 org, vec3 dir, out float near, out float far)
{
	// compute intersection of ray with all six bbox planes
	vec3 invR = 1.0/dir;
	vec3 tbot = invR * (-0.5 - org);
	vec3 ttop = invR * (0.5 - org);
	
	// re-order intersections to find smallest and largest on each axis
	vec3 tmin = min (ttop, tbot);
	vec3 tmax = max (ttop, tbot);
	
	// find the largest tmin and the smallest tmax
	vec2 t0 = max(tmin.xx, tmin.yz);
	near = max(t0.x, t0.y);
	t0 = min(tmax.xx, tmax.yz);
	far = min(t0.x, t0.y);

	// check for hit
	return near < far && far > 0.0;
}
```

