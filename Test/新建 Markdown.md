```c
#define T iTime
#define PI 3.14159265359
#define FAR 20.0
#define EPS 0.004
#define SR .2
#define CT T/16.0
#define H 1.0

#define PLAYER 1.
#define FLOOR 2.

#define PA vec3(.5,.5,.5)
#define PB vec3(.5,.5,.5)
#define PC vec3(1.,1.,1.)
#define PD vec3(.0,.33,.67)

const vec3 RBb=vec3(1.,1.,1.);
const float RBr=0.3;

//struct from shau :https://www.shadertoy.com/view/MsVcRy
struct Scene{
    float t;
    float id;
    vec3 n;
};

vec2 csqr(vec2 a)
{
    return vec2(a.x*a.x-a.y*a.y,2.0*a.x*a.y);
}
    
mat2 rot(float x) {return mat2(cos(x), sin(x), -sin(x), cos(x));}

//简单的调色板 IQ
vec3 pal(in float t,in vec3 a,in vec3 b,in vec3 c,in vec3 d)
{
    return a+b*cos(2.*PI*(c*t+d));
}
vec3 glowColour()
{
    return pal(T*0.1,PA,PB,PC,PD);
}

//哈希表  Dave_Hoskins
vec3 hash(vec3 p3)
{
	p3 = fract(p3 * vec3(.1031, .1030, .0973));
    p3 += dot(p3, p3.yxz+33.33);
    return fract((p3.xxy + p3.yxx)*p3.zyx);

}

//噪声函数 IQ
float noise( in vec3 x )
{
    // grid
    vec3 p = floor(x);
    vec3 w = fract(x);
    
    // quintic interpolant
    vec3 u = w*w*w*(w*(w*6.0-15.0)+10.0);

    
    // gradients
    vec3 ga = hash( p+vec3(0.0,0.0,0.0) );
    vec3 gb = hash( p+vec3(1.0,0.0,0.0) );
    vec3 gc = hash( p+vec3(0.0,1.0,0.0) );
    vec3 gd = hash( p+vec3(1.0,1.0,0.0) );
    vec3 ge = hash( p+vec3(0.0,0.0,1.0) );
    vec3 gf = hash( p+vec3(1.0,0.0,1.0) );
    vec3 gg = hash( p+vec3(0.0,1.0,1.0) );
    vec3 gh = hash( p+vec3(1.0,1.0,1.0) );
    
    // projections
    float va = dot( ga, w-vec3(0.0,0.0,0.0) );
    float vb = dot( gb, w-vec3(1.0,0.0,0.0) );
    float vc = dot( gc, w-vec3(0.0,1.0,0.0) );
    float vd = dot( gd, w-vec3(1.0,1.0,0.0) );
    float ve = dot( ge, w-vec3(0.0,0.0,1.0) );
    float vf = dot( gf, w-vec3(1.0,0.0,1.0) );
    float vg = dot( gg, w-vec3(0.0,1.0,1.0) );
    float vh = dot( gh, w-vec3(1.0,1.0,1.0) );
	
    // interpolation
    return va + 
           u.x*(vb-va) + 
           u.y*(vc-va) + 
           u.z*(ve-va) + 
           u.x*u.y*(va-vb-vc+vd) + 
           u.y*u.z*(va-vc-ve+vg) + 
           u.z*u.x*(va-vb-ve+vf) + 
           u.x*u.y*u.z*(-va+vb+vc-vd+ve-vf-vg+vh);
}
//fbm函数 IQ
float fbm(in vec3 x,in float h)
{
    float G=exp2(-h);
    float f=1.0;
    float a=1.0;
    float t=0.0;
    for(int i=0;i<8;i++)
    {
        t+=a*noise(f*x);
        f*=2.;
        a*=G;
    }
    return t;
}

//髓质分形
float fractal(vec3 rp)
{
    float res =0.0;
    float x=0.8+sin(T*0.2)*0.3;
    vec3 c=rp;
    for(int i=0;i<12;i++)
    {
        rp=x*abs(rp)/dot(rp,rp)-x;
        rp.yz=csqr(rp.yz);
        rp=rp.zxy;
        res+=exp(-99.0*abs(dot(rp,c)));
    }
    return res;
}

vec3 fractalMarch(vec3 ro,vec3 rd,float maxt)
{
    vec3 pc=vec3(0.0);
    float t=0.0;
    float ns=0.;
    for(int i=0;i<64;i++)
    {
        vec3 rp=ro+t*rd;
        float lt=length(rp)-SR;
        ns=fractal(rp);
        if(lt<EPS||t>maxt)break;
        t+=0.02*exp(-2.0*ns);
        pc = 0.99 * (pc + 0.08 * glowColour() * ns) / (1.0 + lt * lt * 1.);
        pc += 0.1 * glowColour() / (1.0 + lt * lt);  
        
    }
    return pc;
}


float sdRoundBox( vec3 p, vec3 b, float r )
{
  vec3 q = abs(p) - b;
  return length(max(q,0.0)) + min(max(q.x,max(q.y,q.z)),0.0) - r;
}

 
float map(in vec3 pos)
{
    return sdRoundBox(pos,RBb,RBr);
}

float castRay(in vec3 ro,in vec3 rd)
{
    float tmin=1.0;
    float tmax=FAR;
    float t=tmin;
    for(int i=0;i<64;i++)
    {
        float precis=0.0005*t;
        float res=map(ro+t*rd);
        if(res<precis||t>tmax)break;
        t+=res;
    }
    if(t>tmax)t=-1.;
    return t;
}

vec3 calNormal(in vec3 pos)
{
    vec2 e=vec2(1.,-1.)*0.5773*0.0005;
    return normalize(e.xyy*map(pos+e.xyy)+
                     e.yyx*map(pos+e.yyx)+
                     e.yxy*map(pos+e.yxy)+
                     e.xxx*map(pos+e.xxx));
}

Scene iScene(vec3 ro,vec3 rd)
{
    float mint=FAR;
    float id=.0;
    float t=castRay(ro,rd);
    if(t>-.5)
    {
        return Scene(t,PLAYER,calNormal(ro+rd*t));
    }
    return Scene(t
                 ,id,vec3(0.,0.,0.));
}

vec3 clouds(vec3 rd)
{
    vec2 uv=rd.xz/(rd.y+0.6);
    float nz=fbm(vec3(uv.yx*1.4+vec2(CT,0.0),CT),H)*1.8;
    return clamp(pow(vec3(nz),vec3(2.0))*rd.y,0.0,1.0);
}

vec3 drawScene(vec3 ro,vec3 rd,Scene scene)
{
    vec3 light1 = normalize( vec3(-0.8,0.4,-0.3) );
    float sundot = clamp(dot(rd,light1),0.0,1.0);
    vec3 rp=ro+rd*scene.t;
    vec3 ld=normalize(light1-rp);
    
    //天空
    vec3 pc=vec3(0.3,0.5,0.85)-rd.y*rd.y*0.5;
    pc=mix(pc,0.85*vec3(0.7,0.7,0.8),pow(1.0-max(rd.y,0.0),4.0));
    //太阳光晕
    pc+=0.25*vec3(1.0,0.7,0.4)*pow(sundot,5.0);
    pc+=0.25*vec3(1.0,0.8,0.6)*pow(sundot,64.0);
    //云
    pc+=clouds(rd);
    //地平线
   // pc=mix( pc, 0.68*vec3(0.4,0.65,1.0), pow( 1.0-max(rd.y,0.0), 16.0 ) );
    if(scene.t>-0.5)
    {
         pc=fractalMarch(rp,rd,2.);
    }
 
    if(scene.id==PLAYER)
    {
        pc+=vec3(.3);
       
    }
    
    return pc;
}

mat3 setCam(vec3 ro,vec3 ta)
{
    vec3 w=normalize(ta-ro);
    vec3 p=vec3(.0,1.,.0);
    vec3 u=normalize(cross(w,p));
    vec3 v=normalize(cross(u,w));
    return mat3(u,v,w);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p=(fragCoord*2.-iResolution.xy)/iResolution.y;
    vec3 ro=vec3(0.,0.,-4.);
    vec3 ta=vec3(0.,0.,0.);
    ro.xz *= rot(T * 0.4);
    ro.yz *=rot(T*0.1);
    mat3 cam=setCam(ro,ta);
    vec3 rd=cam*normalize(vec3(p.xy,2.));
    
    Scene scene=iScene(ro,rd);
    vec3 pc=drawScene(ro,rd,scene);
    
    fragColor = vec4(pc,1.0);
} 
```

