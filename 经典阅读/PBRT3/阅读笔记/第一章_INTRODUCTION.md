# INTRODUCTION

## 1. LITERATE PROGRAMMING

本书和==RTR4==不同，会使用`literate programming metalanguage`来描述详细的算法，大概形式如下：

![image-20210301130153141](第一章_INTRODUCTION.assets/image-20210301130153141.png)





## 2. PHOTOREALISTIC RENDERING AND THE RAY-TRACING ALGORITHM

老生常谈，不做赘述。



## 3. pbrt: SYSTEM OVERVIEW

![image-20210301140100883](第一章_INTRODUCTION.assets/image-20210301140100883.png)

==pbrt==在概念上可以分为两个**执行阶段**。首先，它解析用户提供的场景描述文件。**场景描述**是一个文本文件，它指定了构成场景的几何形状，材质属性，照亮它们的灯光，虚拟摄像机在场景中的位置，以及整个系统中使用的所有单个算法的参数。输入文件中的每条语句都直接映射到附录B中的一个例程；这些例程组成了描述场景的**程序接口**。

一旦场景被指定，**第二阶段**的执行开始，==主渲染==循环执行。这个阶段通常是**pbrt**花费大部分运行时间的阶段，本书的大部分内容描述了在这个阶段执行的**代码**。

在==程序的角度==上：

- pbrt的main()函数可以在main/pbrt.cpp文件中找到。这个函数非常简单;它首先循环argv中提供的命令行参数，在Options结构中初始化值，并存储参数中提供的文件名。

    > `<Process command-line arguments>`是直接的，没有在书中进行解释

- ==options==结构然后被传递给`pbrtInit()`函数，该函数执行**系统范围**的初始化。``main()``函数然后解析给定的**场景描述**，从而创建一个场景和一个积分器。在所有渲染完成后，``pbrtCleanup()``在系统退出之前，进行最后的清理。

- ==\<Main Program\>==

    ```c++
    <Main program> ≡
        int main(int argc, char *argv[]) {
            Options options;
            std::vector<std::string> filenames;
            <Process command-line arguments> 
            pbrtInit(options);
            <Process scene description>
            pbrtCleanup();
            return 0;
        }
    ```

- \<Process scene description\>

    ```c++
    <Process scene description> ≡ 
        if (filenames.size() == 0) {
        	<Parse scene from standard input>
        } 
    	else {
       		<Parse scene from input files>
        }
    ```

- \<Parse scene from input file>

    ```c++
    <Parse scene from input files> ≡ 21
    	for (const std::string &f : filenames)
    		if (!ParseFile(f))
    			Error("Couldn’t open scene file \"%s\"", f.c_str());
    
    ```

- 当场景文件被解析时，对象被创建来代表场景中的灯光和几何原语。这些都存储在**场景对象**中，它是由`RenderOptions::MakeScene()`创建的

    ![image-20210301143926226](第一章_INTRODUCTION.assets/image-20210301143926226.png)

- 场景使用来自c++标准库的[`shared_ptr`](https://blog.csdn.net/shaosunrise/article/details/85228823)实例向量存储所有的灯光

    ![image-20210301144518331](第一章_INTRODUCTION.assets/image-20210301144518331.png)

- 场景中的每个几何对象都由一个==基元==表示，该基元组合了两个对象：一个指定其几何形状的**形状**，以及一个描述其外观的**材质**

    ![image-20210301144711089](第一章_INTRODUCTION.assets/image-20210301144711089.png)

- 构造函数在`worldBound`成员变量中，缓存场景几何的==边界框==。

    ![image-20210301144828680](第一章_INTRODUCTION.assets/image-20210301144828680.png)

- 在渲染开始之前，对光源做一些**额外的初始化**是很有用的。场景构造函数调用Preprocess()``方法：

    ![image-20210301145312008](第一章_INTRODUCTION.assets/image-20210301145312008.png)

- ==Scene类==提供了两个与**射线-基元**交汇有关的方法。它的`Intersect()`方法在场景中追踪给定的射线，并返回一个布尔值，指示该射线是否与任何基元相交。如果是，它就会填写所提供的`SurfaceInteraction`结构，其中包含沿射线最近的交点的信息。

    ![image-20210301145830408](第一章_INTRODUCTION.assets/image-20210301145830408.png)

- 另外一个方法是`Scene::IntersectP()`，它只返回是否相交，不会处理其它额外信息，所以很适合阴影：

    ![image-20210301150032867](第一章_INTRODUCTION.assets/image-20210301150032867.png)

- 

