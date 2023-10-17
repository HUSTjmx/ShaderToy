# 形状Shapes

## 1. 基本的`Shape`接口

`PBRT`针对渲染对象提供了两个抽象类

- `Shape类`提供了对原语的**原始几何属性**的访问，比如它的表面区域和包围框，并提供了==射线相交例程==。
- `原语类`封装了关于`Primitive`的其他非几何信息，比如它的**材质属性**。然后渲染器的其余部分只处理抽象的`Primitive`接口。

这一章将集中于几何学的形状类；原语接口是第4章的一个关键主题。

```c++
<<Shape Declarations>>= 
class Shape {
public:
    <<Shape Interface>> 
       Shape(const Transform *ObjectToWorld, const Transform *WorldToObject,
             bool reverseOrientation);
       virtual ~Shape();
       virtual Bounds3f ObjectBound() const = 0;
       virtual Bounds3f WorldBound() const;
       virtual bool Intersect(const Ray &ray, Float *tHit,
           SurfaceInteraction *isect, bool testAlphaTexture = true) const = 0;
       virtual bool IntersectP(const Ray &ray,
               bool testAlphaTexture = true) const {
               Float tHit = ray.tMax;
               SurfaceInteraction isect;
               return Intersect(ray, &tHit, &isect, testAlphaTexture);
       }
       virtual Float Area() const = 0;
       virtual Interaction Sample(const Point2f &u) const = 0;
       virtual Float Pdf(const Interaction &) const {
           	return 1 / Area();
       }
       virtual Interaction Sample(const Interaction &ref,
                                  const Point2f &u) const {
           	return Sample(u);
       }
       virtual Float Pdf(const Interaction &ref, const Vector3f &wi) const;

    <<Shape Public Data>> 
       const Transform *ObjectToWorld, *WorldToObject;
       const bool reverseOrientation;
       const bool transformSwapsHandedness;

};
```

首先，`Shape`存储了`ModelToWorld`变换矩阵及其**逆矩阵**。然后是一个==布尔值==`reverseOrientation`，决定法线方向是否需要翻转。（这个值具体是由输入文件的对应参数决定的）

还存储了`TransformL::SwapsHandedness()`的返回值（转换是否变换了左/右手坐标系），因为每一次射线和表面相交，`SurfaceInteraction`都需要这个参数进行初始化，所以`Shape`类对其进行了存储。



### 包围盒

需要包围盒是为了进行加速。这里有两个不同的`bounding`方法。第一个，`ObjectBound()`返回一个`shape`物体空间的包围盒：

```c++
virtual Bounds3f ObjectBound() const = 0;
```

第二个则返回世界空间下的。

```c++
Bounds3f Shape::WorldBound() const {
    	return (*ObjectToWorld)(ObjectBound());
}
```

### 射线-包围盒相交测试

具体的测试，可以回过头去看计算机图形学的相交测试知识，这里就不多说了：

```c++
template <typename T>
inline bool Bounds3<T>::IntersectP(const Ray &ray, Float *hitt0,
        Float *hitt1) const {
        Float t0 = 0, t1 = ray.tMax;
        for (int i = 0; i < 3; ++i) {
               //Update interval for ith bounding box slab>> 
               Float invRayDir = 1 / ray.d[i];
               Float tNear = (pMin[i] - ray.o[i]) * invRayDir;
               Float tFar  = (pMax[i] - ray.o[i]) * invRayDir;
                //Update parametric interval from slab intersection  values
                if (tNear > tFar) std::swap(tNear, tFar);
                //Update tFar to ensure robust ray–bounds intersection
                t0 = tNear > t0 ? tNear : t0;
                t1 = tFar  < t1 ? tFar  : t1;
                if (t0 > t1) return false;
        }
        if (hitt0) *hitt0 = t0;
        if (hitt1) *hitt1 = t1;
        return true;
}
```

### 相交测试

通过了包围盒测试，则是和形状本身进行相交测试

```c++
virtual bool Intersect(const Ray &ray, Float *tHit,
    SurfaceInteraction *isect, bool testAlphaTexture = true) const = 0;
```

在阅读==相交例程==时，有几件重要的事情需要记住：

- 忽略`tmax`之后的区域
- 如果找到一个交点，它沿光线的参数距离应该存储在传递到交点例程的`tHit指针`中。如果沿射线有多个交叉点，应报告最近的一个。
- 关于交点的信息存储在` SurfaceInteraction`结构中，它完全捕获了一个表面的局部几何属性。
- 进入**相交例程**的光线是在**世界空间**中，所以如果需要交叉测试，**形状**负责将它们转换到**对象空间**。返回的交集信息应该在世界空间中。

一些形状实现支持使用**纹理**切割它们的一些表面；`testAlphaTexture参数`指示那些执行该操作的对象。第二个交集测试方法`Shape::IntersectP()`是一个判断是否发生交集的谓词函数，而不返回关于交集本身的任何细节。Shape类提供了IntersectP()方法的默认实现，该方法调用Shape::Intersect()方法，并忽略了关于Intersect的额外计算信息。

```c++
virtual bool IntersectP(const Ray &ray,	bool testAlphaTexture = true) const {
        Float tHit = ray.tMax;
        SurfaceInteraction isect;
        return Intersect(ray, &tHit, &isect, testAlphaTexture);
}
```

### 表面积

为了正确地使用形状作为区域光源，有必要计算物体空间中形状的表面积。

```c++
virtual Float Area() const = 0;
```



## 2. 球、圆柱、圆盘

圆是最特殊的二次曲线（PBRT支持六种二次曲线）。

```c++
class Sphere : public Shape {
public:
       //Sphere Public Methods
       Sphere(const Transform *ObjectToWorld, const Transform *WorldToObject,
              bool reverseOrientation, Float radius, Float zMin, Float zMax,
              Float phiMax)
           : Shape(ObjectToWorld, WorldToObject, reverseOrientation),
             radius(radius), zMin(Clamp(std::min(zMin, zMax), -radius, radius)),
             zMax(Clamp(std::max(zMin, zMax), -radius, radius)),
             thetaMin(std::acos(Clamp(zMin / radius, -1, 1))),
             thetaMax(std::acos(Clamp(zMax / radius, -1, 1))),
             phiMax(Radians(Clamp(phiMax, 0, 360))) { }
       Bounds3f ObjectBound() const;
       bool Intersect(const Ray &ray, Float *tHit, SurfaceInteraction *isect,
           bool testAlphaTexture) const;
       bool IntersectP(const Ray &ray, bool testAlphaTexture) const;
       Float Area() const;
       Interaction Sample(const Point2f &u) const;
       Interaction Sample(const Interaction &ref, const Point2f &u) const;
       Float Pdf(const Interaction &ref, const Vector3f &wi) const;

private:
      //Sphere Private Data
       const Float radius;
       const Float zMin, zMax;
       const Float thetaMin, thetaMax, phiMax;

};
```

更多细节见[在线网址](http://www.pbr-book.org/3ed-2018/Shapes/Spheres.html)



## 3. 三角网格

Todo。



## 4. 曲面

Todo。



## 5. 曲面细分

Todo。



## 6. 管理舍入误差

Todo.

