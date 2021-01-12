## 项目设置

1. 新建空项目（包含新手包），导入课程资源文件。

2. 由于我们第一目标是手柄，所以设置输入，添加轴映射（反方向的实现，直接通过将缩放设置为-1）：

   <img src="TwinStickShooter1.assets/image-20210111121331425.png" alt="image-20210111121331425" style="zoom:80%;" />

3. 为**方向控制**设置`盲区`，默认值0.25对于右摇杆，会导致非常明显的不协调感，因此我们修改为0.05（不要设置为0，会导致==漂移==）

   ![image-20210111121741408](TwinStickShooter1.assets/image-20210111121741408.png)



## 关卡设计

1. 新建一个空`map`

2. 构建初始场景

3. 一个UE技巧，选择一个细节面板的几何分栏，可以根据多个因素选择场景中类似的一大群物体：

   | 1                                                            | 2                                                            |
   | ------------------------------------------------------------ | ------------------------------------------------------------ |
   | ![image-20210111123157319](TwinStickShooter1.assets/image-20210111123157319.png) | ![image-20210111123206774](TwinStickShooter1.assets/image-20210111123206774.png) |

4. 添加光源：定向光和`Sky Light`。其中天空光的`Source Type`选择为立方体贴图。

5. 添加后处理体积，修改曝光：

   <img src="TwinStickShooter1.assets/image-20210111124552089.png" alt="image-20210111124552089" style="zoom:80%;" />

   

   

   ## 框架综述

   | Name              | Info                                                         |
   | ----------------- | ------------------------------------------------------------ |
   | Actor             | 继承自Object；场景中任何放置的物体都是Actor；                |
   | Pawn              | 派生自Actor；场景中可以被控制的任何对象；可以是场景中的人物，也可以是交通工具，或者是鱼 |
   | Character         | 继承自Pawn类；专门表示双足类对象；具有专门的插槽，可以选择网格模型；自带胶囊体碰撞体；具有==特殊的人物移动组件== |
   | Component         | Actor的一部分，实现特定功能；                                |
   | Controller        | 有两种，如下；就是一种**控制机制**，用于控制==Pawn==         |
   | Player Controller | 经常用于实现游戏中的所有输入功能                             |
   | AI  Controller    | 通常是简单的逻辑组合                                         |
   | GameMode          | 告诉引擎玩家应该使用哪个角色；Rules；独立于其他类；          |



## 角色基类

1. 新建一个继承`Character`的类：

   <img src="TwinStickShooter1.assets/image-20210111131048693.png" alt="image-20210111131048693" style="zoom:67%;" />

2. 编写代码，需要注意的是：

   ```c++
   UFUNCTION(BlueprintCallable, Category = "BaseCharacter")
   		virtual void CalculateHealth(float delta);
   ```

   `UFUNCTION`宏中的`BlueprintCallable`让此函数可以蓝图中成为一个节点被访问:star:。

   辅助函数：

   ```c++
   #if WITH_EDITOR
   	virtual void PostEditChangeProperty(FPropertyChangedEvent& PropertyChangedEvent) override;
   #endif
   ```

   `WITH_EDITOR`让函数只在编辑器中被调用。

3. 详细代码见课程配套资源



## 构建主角

1. 基于上一节的C++类，新建一个蓝图类：

   <img src="TwinStickShooter1.assets/image-20210111133638974.png" alt="image-20210111133638974" style="zoom:50%;" />

2. 为这个蓝图类，选择网格体，并进行调整：

   | 1                                                            | 2                                                            |
   | ------------------------------------------------------------ | ------------------------------------------------------------ |
   | ![image-20210111134146661](TwinStickShooter1.assets/image-20210111134146661.png) | <img src="TwinStickShooter1.assets/image-20210111134140429.png" alt="image-20210111134140429" style="zoom:50%;" /> |

3. 新增一个`弹簧臂`组件，其作用是确保摄像机与附加目标之间保持**固定距离**，或者确保其子对象和他保持固定距离。我们还需要设置其**细节面板**如下，确保相机不会随着人物的旋转而旋转。

   ![image-20210111134552209](TwinStickShooter1.assets/image-20210111134552209.png)

   `弹簧臂`其作用有点像**自拍杆**

4. 新增一个`相机`组件，作为`弹簧臂`的子物体，并进行如下设置：

   ![image-20210111135222066](TwinStickShooter1.assets/image-20210111135222066.png)

5. 在场景中，新增一个玩家出生点。

6. 在蓝图文件夹下，新增一个继承游戏模式的蓝图类，修改其默认`Pawn`：

   <img src="TwinStickShooter1.assets/image-20210111135758892.png" alt="image-20210111135758892" style="zoom:67%;" />

7. 并在项目设置中，进行修改：

   <img src="TwinStickShooter1.assets/image-20210111140047699.png" alt="image-20210111140047699" style="zoom:80%;" />



## 移动设置

1. 设置如下蓝图，来实现移动。

   ![image-20210111142554233](TwinStickShooter1.assets/image-20210111142554233.png)

2. 对于旋转，我们需要建立一个**阈值**，大于阈值的输入才会引发旋转：

   ![image-20210111142820422](TwinStickShooter1.assets/image-20210111142820422.png)

3. 对于摇杆，可能会有问题，会出现`Y`轴反向，可以通过如下设置解决：

   ![image-20210111143044957](TwinStickShooter1.assets/image-20210111143044957.png)



## 敌人设置

1. 新建一个Enemy Character蓝图类，和之前的类似，唯一的不同是要在`Construction Script`内增加修改身体颜色的蓝图逻辑：

   ![image-20210111145852240](TwinStickShooter1.assets/image-20210111145852240.png)

<img src="TwinStickShooter1.assets/image-20210111145906731.png" alt="image-20210111145906731" style="zoom:67%;" />

2. 新建一个继承`AI Controller`类的蓝图`EnemyAI`

3. 为这个类添加如下`事件图表`，让AI自动跟踪玩家。

   ![image-20210111150631322](TwinStickShooter1.assets/image-20210111150631322.png)

4. 上诉事件怎么触发呢，我们可以定义一个==计时器==，每秒触发一次：

   ![image-20210111150939471](TwinStickShooter1.assets/image-20210111150939471.png)

5. 回到之前的敌人蓝图，进行AI控制器的修改：

   ![image-20210111151126664](TwinStickShooter1.assets/image-20210111151126664.png)

6. 但现在敌人依然没有动静，因为缺少`导航网格包围体`。在体积中就有此导航，我们使用时，需要注意，此**导航体积**需要和地面**相交**。

![image-20210111151514100](TwinStickShooter1.assets/image-20210111151514100.png)



## 武器和激光系统

1. 新建一个继承`Actor`的蓝图类`Projectile`，其组件面板如下图，其实还有添加一个组件：`ProjectileMovement`（子弹移动）

   | 1                                                            | 2                                                            |
   | ------------------------------------------------------------ | ------------------------------------------------------------ |
   | ![image-20210111185724094](TwinStickShooter1.assets/image-20210111185724094.png) | ![image-20210111185737494](TwinStickShooter1.assets/image-20210111185737494.png) |

2. 新建一个简单的发光材质，然后应用到上诉的子弹上：

   | 蓝图                                                         | 效果                                                         |
   | ------------------------------------------------------------ | ------------------------------------------------------------ |
   | ![image-20210111190531582](TwinStickShooter1.assets/image-20210111190531582.png) | ![image-20210111190544353](TwinStickShooter1.assets/image-20210111190544353.png) |

3. 新建一个继承`Actor`的蓝图类`weapon`，需要用带之前教程没有使用的组件：`Arrow`（发射）：（下图错了，没有MoveMent）

   | 1                                                            | 2                                                            |
   | ------------------------------------------------------------ | ------------------------------------------------------------ |
   | ![image-20210111191225011](TwinStickShooter1.assets/image-20210111191225011.png) | ![image-20210111191234974](TwinStickShooter1.assets/image-20210111191234974.png) |

4. `ProjectileMovement`（子弹移动）的一些简单修改：

   ![image-20210111191427928](TwinStickShooter1.assets/image-20210111191427928.png)



## 武器发射逻辑

1. 首先在武器上，实现`Fire`逻辑：

   ![image-20210111192635619](TwinStickShooter1.assets/image-20210111192635619.png)

2. 实现扣动扳机的逻辑：扣动扳机后：持续射出子弹（一秒七发）。需要使用`执行一次`节点：

   ![image-20210111193340513](TwinStickShooter1.assets/image-20210111193340513.png)

3. 实现断开扳机逻辑：

   > 自定义事件和函数差不多，每一个函数都只有一个计数器。

   <img src="TwinStickShooter1.assets/image-20210111193715529.png" alt="image-20210111193715529" style="zoom:67%;" />

4. 为主角添加一个临时组件，放在武器应该在的位置。

5. 添加初始`给主角附加武器`逻辑：

   ![image-20210111194914010](TwinStickShooter1.assets/image-20210111194914010.png)

6. 开枪逻辑：

   ![image-20210111195522457](TwinStickShooter1.assets/image-20210111195522457.png)