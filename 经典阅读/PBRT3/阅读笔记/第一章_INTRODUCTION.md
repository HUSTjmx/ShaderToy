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

#### SCENE REPRESENTATION

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

#### INTEGRATOR INTERFACE AND SamplerIntegrator

- 呈现场景的图像是由==实现Integrator接口的类==的实例处理的。Integrator是一个抽象基类，它定义了所有积分器必须提供的`Render()`方法。在本节中，我们将定义一个积分器——**采样积分器**。

    ![image-20210303212449308](第一章_INTRODUCTION.assets/image-20210303212449308.png)

- 积分器必须提供的方法是`Render()`；它传递一个对场景的引用，用来计算场景的图像，或者更普遍地说，一组**场景照明**的测量值。==这个接口故意保持非常通用，以允许广泛的实现==，例如，可以实现一个积分器，只在场景中分布的**稀疏位置集**进行测量，而不是生成常规的2D图像。

![image-20210303214234207](第一章_INTRODUCTION.assets/image-20210303214234207.png)

在本章中，我们将重点介绍`Integrator`的子类`SamplerIntegrator`，以及实现了`SamplerIntegrator接口`的`whitteintegrator`。采样器积分器的名称来源于：它的**呈现过程**是由采样器的**样本流**驱动的；每一个**采样**识别图像上的一个点，在这个点上，**积分器**应该计算**到达的光**，以形成**图像**。

![image-20210303214510893](第一章_INTRODUCTION.assets/image-20210303214510893.png)

`SamplerIntegrator`存储一个指向**采样器**的指针。采样器的作用是微妙的，但是它的实现可以从本质上影响系统**生成的图像**的质量。首先，采样器负责在**图像平面**上选择**光线跟踪**的点。其次，它负责提供**积分器**用来估计**光传输积分值**的样本位置。例如，一些积分器需要在光源上选择随机点来计算区域灯的照明。生成这些样本的**良好分布**是渲染过程的一个重要部分，可以显著地影响整体效率。

![image-20210303214816893](第一章_INTRODUCTION.assets/image-20210303214816893.png)

==相机对象==控制观看和镜头参数，如位置、方向、焦点和视场。`Camera类`中的`Film成员变量`处理图像存储，负责将最终图像写入文件，并可能在计算图像时将其显示在屏幕上。

![image-20210303214945890](第一章_INTRODUCTION.assets/image-20210303214945890.png)

`SamplerIntegrator构造函数`将指向这些对象的指针存储在`成员变量`中。`SamplerIntegrator`是在`RenderOptions::MakeIntegrator()`方法中创建的，该方法由`pbrtWorldEnd()`调用，当从输入文件解析**场景描述**并准备呈现场景时，**输入文件解析器**将调用该方法。

![image-20210303215126510](第一章_INTRODUCTION.assets/image-20210303215126510.png)

`SamplerIntegrator`可以选择实现`Preprocess()`方法。它在场景被**完全初始化后**调用，并给积分器提供了一个机会，来进行与场景相关的计算，比如分配额外的数据结构，这些数据结构依赖于场景中的灯的数量，或者预先计算场景中**辐射度分布**的粗略表示。不需要做这些事情的实现可以不执行这个方法。

![image-20210303215407396](第一章_INTRODUCTION.assets/image-20210303215407396.png)

#### THE MAIN RENDERING LOOP

在场景和积分器被分配和初始化之后，将调用`Integrator:: Render()`方法，启动==pbrt==执行的第二阶段：==主渲染循环==。在每一个图像平面上的一系列位置，该方法使用相机和采样器，来生成一个`ray`到场景中，然后使用`Li()`来确定**沿射线**到达图像平面上的==光量==。这个值传递给`Film`。图1.17总结了该方法中使用的主要类以及它们之间的数据流。

![image-20210303215910505](第一章_INTRODUCTION.assets/image-20210303215910505.png)

![image-20210303215952254](第一章_INTRODUCTION.assets/image-20210303215952254.png)

为了在具有多个**处理核心**的系统上并行地进行渲染，图像被分解成**像素的小块**。每个`tiles`都可以独立和并行地处理。`ParallelFor()`函数，将在a .6节中详细描述，它实现了一个==parallel for循环==，其中多个迭代可以并行运行。c++ lambda表达式提供循环体。这里，ParallelFor()的一个变体在2D域上循环，用于迭代图像块。