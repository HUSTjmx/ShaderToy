# 物体

## Actor

| 函数名                   | 大概作用            |
| ------------------------ | ------------------- |
| GetActorLocation()       | 获得自身的世界位置  |
| SetActorLocation(NewPos) | 设置自身的世界位置  |
| GetComponentTransform()  | 获取自身的Transform |
|                          |                     |
|                          |                     |



# 组件

## 静态网格

==UStaticMeshComponent* Mesh;==

| 函数名                                                       | 大概作用                                                     |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| SetStaticMesh(MeshAsset.Object);                             | 指定静态网格                                                 |
| AttachToComponent(Root, FAttachmentTransformRules::SnapToTargetIncludingScale); | 作为子组件附加到`root`上，后面一个参数感觉大多数情况不用改变 |
|                                                              |                                                              |

## 场景组件

==USceneComponent* Root;==

| 函数名                                                       | 大概作用                                                     |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| AttachToComponent(Root, FAttachmentTransformRules::SnapToTargetIncludingScale); | 作为子组件附加到`root`上，后面一个参数感觉大多数情况不用改变 |
| SetRelativeTransform(FTransform(FRotator(0, 0, 0), FVector(250, 0, 0), FVector(0.1f))); | 设置场景组件的相对变换（相对于父物体）                       |
|                                                              |                                                              |



# 宏

## UCLASS

==UCLASS( ClassGroup=(Custom), meta=(BlueprintSpawnableComponent) )==

 `blueprintspawnablcomponent` 添加到==类的元值==中，意味着**组件的实例**可以添加到编辑器中的 ==Blueprint 类==中；==类组说明符==`ClassGroup`允许我们指出我们的组件属于类列表中的哪个类别:



# 函数

# 类型

### TSubclassOf 类型

```c++
UPROPERTY(EditAnywhere)
    	TSubclassOf<AActor> ActorToSpawn;c
```

这是一种模板类型，允许我们将指针限制为**基类**或其**子类**。 这也意味着在编辑器中，我们将得到一个**预过滤的类列表**，以便从中选择，防止我们意外地分配一个无效的值。



# 工具函数

| 函数名                                                       | 大概作用                                                     |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| GEngine->AddOnScreenDebugMessage(-1, 10, FColor::Red, TEXT("Actor")); | 在场景屏幕上的指定位置和指定颜色，打印指定字符。             |
| GetWorld()->SpawnActor<AMyCharacter>(AMyCharacter::StaticClass(), SpawnLocation); | 在场景的指定位置上，安置一个指定类型的Actor                  |
| GetWorldTimerManager().SetTimer(Timer, this, &Atest1GameMode::DestroyActorFunction, 10); | 在指定时间（10秒）后，调用相应函数                           |
| SetLifeSpan(5);                                              | 设置对象的生命周期（5秒）                                    |
| CreateDefaultSubobject<UStaticMeshComponent>("BaseMeshComponent"); | 初始化一个指向指定类型的指针，这里是静态网格                 |
| ConstructorHelpers::FObjectFinder<UStaticMesh>                 (TEXT("StaticMesh'/Engine/BasicShapes/Cube.Cube'")); | 帮助我们加载资源；传入一个字符串，该字符串包含我们试图加载的资源的路径 |
| GetOwner();                                                  | 获取自己父物体的指针                                         |
| GetWorld();                                                  | 获取当前世界的指针                                           |

