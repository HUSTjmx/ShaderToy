#define PI 3.14

void getLUT0(out vec2 uv,in vec2 p)
{
	float r=sqrt(p.x*p.x+p.y*p.y);
    float a=atan(p.x,p.y);
    uv.x=cos(a+iTime)/r;
    uv.y=sin(a+iTime)/r;
}

void getLUT1(out vec2 uv,in vec2 p)
{
	float r=sqrt(p.x*p.x+p.y*p.y);
    float a=atan(p.x,p.y);
    uv.x=p.x*cos(2.0*r)-p.y*sin(2.0*r);
    uv.y=p.y*cos(2.0*r)+p.x*sin(2.0*r);
}
//螺旋通道
void getLUT2(out vec2 uv,in vec2 p)
{
	float r=sqrt(p.x*p.x+p.y*p.y);
    float a=atan(p.x,p.y);
    uv.x=0.3/(r+0.5*p.x);
    uv.y=3.0*a/PI;
}
void getLUT3(out vec2 uv,in vec2 p)
{
	float r=sqrt(p.x*p.x+p.y*p.y);
    float a=atan(p.x,p.y);
    uv.x=0.02*p.y+0.03*cos(a*2.0)/r;
    uv.y=0.02*p.x+0.03*sin(a*2.0)/r;
}
void getLUT4(out vec2 uv,in vec2 p)
{
    uv.x=p.x/abs(p.y);
    uv.y=p.y/abs(p.x);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 p=-1.0+2.0*fragCoord/iResolution.xy;
    vec2 uv;
    int i=4;
    if(i==0)
    	getLUT0(uv,p);
    else if(i==1)
        getLUT1(uv,p);
    else if(i==2)
        getLUT2(uv,p);
    else if(i==3)
        getLUT3(uv,p);
    else if(i==4)
        getLUT4(uv,p);
    //uv += 10.0*cos( vec2(0.6,0.3) + vec2(0.1,0.13)*iTime );
    uv +=cos(iTime);
    vec3 col=texture(iChannel0,uv).xyz;
    fragColor = vec4(col,1.0);
}