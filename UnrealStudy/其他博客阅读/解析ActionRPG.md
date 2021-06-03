# 解析ActionRPG前言

参考课程：https://www.jianshu.com/p/941c299e2e5a



# 1. Gameplay Ability System[GAS] （ ActionRPG/Abilities）

![image-20210517140541472](解析ActionRPG.assets\image-20210517140541472.png)

## 1. RPGAbilitySystemComponent.h/cpp & AbilitySystemComponent

`AbilitySystemComponent`是一个庞大的类，我们看看官方描述：

> UAbilitySystemComponent ：一个组件，可以轻松地与AbilitySystem的3个方面对接。
>
>  * GameplayAbilities。
>      * 提供一种方法来赋予/分配可以使用的能力（例如，由玩家或AI使用）。
>
>      * 提供对实例能力的管理（必须有东西来保管它们）。
>
>      * 提供复制功能：能力状态`Ability state `必须始终在`UGameplayAbility`本身上进行复制，但`UAbilitySystemComponent`提供了RPC复制功能。
>
>  * GameplayEffects。
>      * 提供了一个`FActiveGameplayEffectsContainer`，用于保存激活的`GameplayEffects`。
> 
>     * 提供将**游戏效果**应用于目标或自身的方法。
> 
>     * 提供用于查询`FActiveGameplayEffectsContainer`中的信息（持续时间、大小等）的封装器。
> 
>     * 提供清除/删除游戏效果的方法。
> 
> * GameplayAttributes
>      * 提供分配和初始化**属性集**的方法
>      * 提供获取**属性集**的方法
> 

`AbilitySystemComponent`提供了丰富的“method”来与`Ability`、`Effect`、`Attribute`交互，随着我们深入GAS，会接触到。

### URPGGameAbilitySystemComponent.h

在本例子中，扩展了三个方法，具体见下。

```c++
// Copyright 1998-2019 Epic Games, Inc. All Rights Reserved.

#pragma once

#include "ActionRPG.h"
#include "AbilitySystemComponent.h"
#include "Abilities/RPGAbilityTypes.h"
#include "RPGAbilitySystemComponent.generated.h"

class URPGGameplayAbility;

/**
 * Subclass of ability system component with game-specific data
 * Most games will need to make a game-specific subclass to provide utility functions
 */
UCLASS()
class ACTIONRPG_API URPGAbilitySystemComponent : public UAbilitySystemComponent
{
    GENERATED_BODY()

public:
    // Constructors and overrides
    URPGAbilitySystemComponent();

    /** Returns a list of currently active ability instances that match the tags */
       /**   返回匹配tag的所有激活的ability实例**/
    void GetActiveAbilitiesWithTags(const FGameplayTagContainer& GameplayTagContainer, TArray<URPGGameplayAbility*>& ActiveAbilities);

    /** Returns the default level used for ability activations, derived from the character */
      /** 获得当前释放技能的默认等级，从人物角色上获得(这个游戏设定，应该是人物等级==技能等级) */
    int32 GetDefaultAbilityLevel() const;

    /** Version of function in AbilitySystemGlobals that returns correct type */
       /** 使用 AbilitySystemGlobals 类的方法，返回特定actor实例上的abilitysystemcomponent实例 */
    static URPGAbilitySystemComponent* GetAbilitySystemComponentFromActor(const AActor* Actor, bool LookForComponent = false);

};
```

### URPGGameAbilitySystemComponent.cpp

```c++
// Copyright 1998-2019 Epic Games, Inc. All Rights Reserved.

#include "Abilities/RPGAbilitySystemComponent.h"
#include "RPGCharacterBase.h"
#include "Abilities/RPGGameplayAbility.h"
#include "AbilitySystemGlobals.h"

URPGAbilitySystemComponent::URPGAbilitySystemComponent() {}

void URPGAbilitySystemComponent::GetActiveAbilitiesWithTags(const FGameplayTagContainer& GameplayTagContainer, TArray<URPGGameplayAbility*>& ActiveAbilities)
{
      /** FGameplayAbilitySpec是对gameplay ability的包装，还包含了ability运行时必要的信息 */
    TArray<FGameplayAbilitySpec*> AbilitiesToActivate;

          /** UAbilitySystemComponent的方法，获得所有可激活的ability specification*/
    GetActivatableGameplayAbilitySpecsByAllMatchingTags(GameplayTagContainer, AbilitiesToActivate, false);

    // Iterate the list of all ability specs
    for (FGameplayAbilitySpec* Spec : AbilitiesToActivate)
    {
        // Iterate all instances on this ability spec
        TArray<UGameplayAbility*> AbilityInstances = Spec->GetAbilityInstances();

        for (UGameplayAbility* ActiveAbility : AbilityInstances)
        {
            ActiveAbilities.Add(Cast<URPGGameplayAbility>(ActiveAbility));
        }
    }
}

int32 URPGAbilitySystemComponent::GetDefaultAbilityLevel() const
{
    ARPGCharacterBase* OwningCharacter = Cast<ARPGCharacterBase>(OwnerActor);

    if (OwningCharacter)
    {
          /** 获得人物等级 */
        return OwningCharacter->GetCharacterLevel();
    }
    return 1;
}

URPGAbilitySystemComponent* URPGAbilitySystemComponent::GetAbilitySystemComponentFromActor(const AActor* Actor, bool LookForComponent)
{
      /** 使用UAbilitySystemGlobals的方法，对结果进行cast */
    return Cast<URPGAbilitySystemComponent>(UAbilitySystemGlobals::GetAbilitySystemComponentFromActor(Actor, LookForComponent));
}

```

- `FGameplayAbilitySpec`是对`gameplay ability`的包装，还包含了`ability`运行时必要的信息

现在，我们回顾一下。发现**三个新添加的get方法**都是跟`actor`有关：

- `GetActiveAbilitiesWithTags`： 获得`actor（owner）`所有与`tag`匹配的**ability实例**
- `GetDefaultAbilityLevel`：获得`character（owner）`的等级
- `GetAbilitySystemComponentFromActor`： 获得**任意Actor实例**挂载的`AbilitySystemComponent实例`。



## 2. RPGGameplayAbility.h/cpp & GameplayAbility

### Gameplay Ability

看看`Gameplay Ability`的官方描述：

> UGameplayAbility：定义了可以激活或触发的**自定义游戏逻辑**。`AbilitySystem`为`GameplayAbilities`提供的主要功能是：
>
>  *  可以使用的功能（CanUse functionality）
>      * 冷却时间
>      * 成本（法力、体力等）。
>      * 等等
>  *  支持复制
>      * 能力激活的**客户端/服务器通信**
>      * 能力激活的**客户端预测**
>  *  支持Instancing
>      * 能力可以是非实例化的（仅本地）。
>      * 为每个所有者提供实例（Instanced per owner）
>      * 每次执行都会实例化（默认）。
>  *  支持扩展
>      *  输入绑定
>      *  赋予能力（可以使用）给`Actor`
>  *  关于复制支持的说明。
>      *  非实例能力（Non instanced abilities）的复制支持有限。
>          * 不能有状态（很明显），所以没有复制的属性。
>          * 对能力类的RPC也是不可能的。
>  *  为了支持状态或事件的复制，==一个能力必须被实例化==。这可以通过`InstancingPolicy`属性来实现。
>

整体上的概括就是：**Abilities define custom gameplay logic that can be activated or triggere。**Abilities定义可激活或触发的**自定义游戏玩法逻辑**。所以才有“Everything can be a gameplay ability”的说法。同样注意，这里说**Ability是逻辑**，也就是这个类主要是**实现各种行为**，比如：技能释放、撤销、目标选择等等。可以通过`tag`来影响Ability的运作逻辑，通过`effect`来影响actor的属性（`attributes`）。

`UGameplayAbility`类中重要的函数有：

| 函数名                | 作用                                                         |
| --------------------- | ------------------------------------------------------------ |
| CanActivateAbility()  | 用于查看能力是否可被激活。可由`UI`等调用。                   |
| TryActivateAbility()  | 试图激活该能力。调用`CanActivateAbility()`。输入事件可以直接调用它。 |
| CallActivateAbility() | Protected, non virtual function。做一些模板性的 **"预激活 "工作**，然后调用`ActivateAbility()` |
| ActivateAbility()     | `ability`到底做啥。这也是派生类需要覆盖的内容。              |
| CommitAbility()       | 占用资源/冷却时间等。`ActivateAbility()`必须调用它。         |
| CancelAbility()       | 中断能力（从外部来源）                                       |
| EndAbility()          | 能力已经结束。这是由`ability`本身调用的，以结束自身。        |

还有大量的行为（函数），头文件中对他们做了解释：

- Accessors ： 一系列的访问函数
- CanActivateAbility ：判断能否释放技能
- CancelAbility ： 撤销技能
- CommitAbility :  确认技能释放
- Input： 用户输入相关
- Animation ： 动画
- Ability Levels and source object: 技能等级和技能来源
- Interaction with ability system component：与Ability System Component的信息传递
- EndAbility：结束技能
- Ability Tasks： 异步任务
- Apply/Remove gameplay effects：应用或移除gameplay effects

我们的自定义逻辑，主要是`ActivateAbility()`中完成，该方法可支持蓝图实现。定义一个能力的主函数。

> 官方解释：子类将希望覆盖这个函数；这个函数图应该调用CommitAbility；这个函数图应该调用EndAbility。延迟/同步动作是可以的。注意，Commit和EndAbility的调用要求是针对K2_ActivateAbility的。在C++中，对K2_ActivateAbility()的调用可以在没有调用CommitAbility或EndAbility的情况下返回。但是，我们希望这种情况。只会在延迟/同步动作待定时发生。当K2_ActivateAbility逻辑上完成时，我们将期望Commit/End被调用。

在谈`RPGGameplayAbility.h`之前，我们需要先看`RPGAbilityTypes.h`。

### RPGAbilityType.h/cpp

头文件：

```c++
// Copyright 1998-2019 Epic Games, Inc. All Rights Reserved.

#pragma once

// ----------------------------------------------------------------------------------------------------------------
// This header is for Ability-specific structures and enums that are shared across a project
// Every game will probably need a file like this to handle their extensions to the system
// This file is a good place for subclasses of FGameplayEffectContext and FGameplayAbilityTargetData
// ----------------------------------------------------------------------------------------------------------------

#include "ActionRPG.h"
#include "GameplayEffectTypes.h"
#include "Abilities/GameplayAbilityTargetTypes.h"
#include "RPGAbilityTypes.generated.h"

class URPGAbilitySystemComponent;
class UGameplayEffect;
class URPGTargetType;


/**
 * Struct defining a list of gameplay effects, a tag, and targeting info
 * These containers are defined statically in blueprints or assets and then turn into Specs at runtime
 */
USTRUCT(BlueprintType)
struct FRPGGameplayEffectContainer
{
    GENERATED_BODY()

public:
    FRPGGameplayEffectContainer() {}

    /** Sets the way that targeting happens */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = GameplayEffectContainer)
    TSubclassOf<URPGTargetType> TargetType;

    /** List of gameplay effects to apply to the targets */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = GameplayEffectContainer)
    TArray<TSubclassOf<UGameplayEffect>> TargetGameplayEffectClasses;
};

/** A "processed" version of RPGGameplayEffectContainer that can be passed around and eventually applied */
USTRUCT(BlueprintType)
struct FRPGGameplayEffectContainerSpec
{
    GENERATED_BODY()

public:
    FRPGGameplayEffectContainerSpec() {}

    /** Computed target data */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = GameplayEffectContainer)
    FGameplayAbilityTargetDataHandle TargetData;

    /** List of gameplay effects to apply to the targets */
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = GameplayEffectContainer)
    TArray<FGameplayEffectSpecHandle> TargetGameplayEffectSpecs;

    /** Returns true if this has any valid effect specs */
    bool HasValidEffects() const;

    /** Returns true if this has any valid targets */
    bool HasValidTargets() const;

    /** Adds new targets to target data */
    void AddTargets(const TArray<FHitResult>& HitResults, const TArray<AActor*>& TargetActors);
};

```

这个文件中定义了两个结构体，用来辅助`ability`。官方推荐玩家继承`FGameplayEffectContext`和`FGameplayAbilityTargetData`来实现自己的ability复杂逻辑。这些结构体围绕的通常是这两个点：**Effect **和 **Target**，即**技能携带的效果**和**技能释放目标**。

注意上面代码注解中的"processed version"。这很切合数据流的思维。`FRPGGameplayEffectContainer`的数据作为输入，经过某个系统的一系列行为处理之后，输出`FRPGGameplayEffectContainerSpec`供下一阶段使用。在Unreal Engine中可能所有带"Spec"后缀的都是类似这种情况（注：没有证明的猜测）。

### RPGGameplayAbility.h/cpp

```c++
// Copyright 1998-2019 Epic Games, Inc. All Rights Reserved.

#pragma once

#include "ActionRPG.h"
#include "GameplayAbility.h"
#include "GameplayTagContainer.h"
#include "Abilities/RPGAbilityTypes.h"
#include "RPGGameplayAbility.generated.h"

/**
 * Subclass of ability blueprint type with game-specific data
 * This class uses GameplayEffectContainers to allow easier execution of gameplay effects based on a triggering tag
 * Most games will need to implement a subclass to support their game-specific code
 */
UCLASS()
class ACTIONRPG_API URPGGameplayAbility : public UGameplayAbility
{
    GENERATED_BODY()

public:
    // Constructor and overrides
    URPGGameplayAbility();

    /** Map of gameplay tags to gameplay effect containers */
    UPROPERTY(EditDefaultsOnly, BlueprintReadOnly, Category = GameplayEffects)
    TMap<FGameplayTag, FRPGGameplayEffectContainer> EffectContainerMap;

    /** Make gameplay effect container spec to be applied later, using the passed in container */
    UFUNCTION(BlueprintCallable, Category = Ability, meta=(AutoCreateRefTerm = "EventData"))
    virtual FRPGGameplayEffectContainerSpec MakeEffectContainerSpecFromContainer(const FRPGGameplayEffectContainer& Container, const FGameplayEventData& EventData, int32 OverrideGameplayLevel = -1);

    /** Search for and make a gameplay effect container spec to be applied later, from the EffectContainerMap */
    //从EffectContainerMap中搜索并制作一个`gameplay effect container spec`，以便以后应用。
    UFUNCTION(BlueprintCallable, Category = Ability, meta = (AutoCreateRefTerm = "EventData"))
    virtual FRPGGameplayEffectContainerSpec MakeEffectContainerSpec(FGameplayTag ContainerTag, const FGameplayEventData& EventData, int32 OverrideGameplayLevel = -1);

    /** Applies a gameplay effect container spec that was previously created */
    UFUNCTION(BlueprintCallable, Category = Ability)
    virtual TArray<FActiveGameplayEffectHandle> ApplyEffectContainerSpec(const FRPGGameplayEffectContainerSpec& ContainerSpec);

    /** Applies a gameplay effect container, by creating and then applying the spec */
    UFUNCTION(BlueprintCallable, Category = Ability, meta = (AutoCreateRefTerm = "EventData"))
    virtual TArray<FActiveGameplayEffectHandle> ApplyEffectContainer(FGameplayTag ContainerTag, const FGameplayEventData& EventData, int32 OverrideGameplayLevel = -1);
};
```

官方建议，大多游戏通常要拓展`UGameplayAbility`。因为不同游戏的Ability可能需要额外的不同的数据。 ActionRPG中添加了：

```xml
 TMap<FGameplayTag, FRPGGameplayEffectContainer> EffectContainerMap;
```

可以方便在蓝图中设定`GameplayTag`、`TargetType`（TargetType是项目自定义的，继承自UObject）和`GameplayEffect`。

添加的行为主要是：

```c++
/** 将Container的数据处理成ContainerSpec，只有当数据变为ContainSpec时，才做好了释放的准备。
会调用到  UGameplayAbility::MakeOutgoingGameplayEffectSpec(...)*/
virtual FRPGGameplayEffectContainerSpec MakeEffectContainerSpecFromContainer
(const FRPGGameplayEffectContainer& Container, const FGameplayEventData& EventData, int32 OverrideGameplayLevel = -1);

/** 应用之前的Spec数据中 GameplaySpecHandle对应的GameplayEffect。
会调用到 UGameplayAbility::K2_ApplyGameplayEffectSpecToTarget(...)
K2 可能代表着：kismet 2代，也就是蓝图系统。1代源自虚幻3 */
virtual TArray<FActiveGameplayEffectHandle> ApplyEffectContainerSpec(const FRPGGameplayEffectContainerSpec& ContainerSpec);
```

我们会发现在`GameplayAbility`中会大量的和`GameplayEffect`打交道，毕竟最终作用于`Gameplay Attributes`的是`GameplayEffect`。



## 3. RPGAttributeSet.h/cpp & AttributeSet

### Attibute Set

定义了你的游戏的所有`Gameplay Attributes`的集合。
 * 游戏应该对其进行子类化，并添加`FGameplayAttributeData`属性以表示健康、伤害等属性。
 * 属性集作为子对象被添加到角色中，然后在`AbilitySystemComponent`中注册。
 * 通常希望每个项目有几个属性集，相互继承。
 * **你可以做一个基本的健康集，然后有一个玩家集，继承它并增加更多属性。**

`Attribute Set`中定义的属性就是RPG游戏中的人物属性，如血量、魔法值。数据类型为`FGameplayAttributeData` （对`float`的封装）。之前写过一篇关于AttributeSet的文章，已经讲的和详细了，这里就不复述了。 [GAS - Gameplay Attributes](https://www.jianshu.com/p/fb75f0ebae42)

### RPGAttributeSet.cpp

首先，因为`AttributeSet`是支持`Replication`的，不要漏了`GetLifetimeReplicatedProps`。

```c++
void URPGAttributeSet::GetLifetimeReplicatedProps(TArray<FLifetimeProperty>& OutLifetimeProps) const
```

RPGAction添加了函数 `AdjustAttributeForMaxChange` , 其作用是，当属性最大值发生改变时，按比例改变当前值。

```c++
void URPGAttributeSet::AdjustAttributeForMaxChange(FGameplayAttributeData& AffectedAttribute, const FGameplayAttributeData& MaxAttribute, float NewMaxValue, const FGameplayAttribute& AffectedAttributeProperty)
{
//获得UAbilitySystemComponent实例
    UAbilitySystemComponent* AbilityComp = GetOwningAbilitySystemComponent();、
//Getter方法获取的都是current value而不是base value
    const float CurrentMaxValue = MaxAttribute.GetCurrentValue();
    if (!FMath::IsNearlyEqual(CurrentMaxValue, NewMaxValue) && AbilityComp)
    {
        // Change current value to maintain the current Val / Max percent
        const float CurrentValue = AffectedAttribute.GetCurrentValue();
        float NewDelta = (CurrentMaxValue > 0.f) ? (CurrentValue * NewMaxValue / CurrentMaxValue) - CurrentValue : NewMaxValue;
                //      通过UAbilitySystemComponent实例
        AbilityComp->ApplyModToAttributeUnsafe(AffectedAttributeProperty, EGameplayModOp::Additive, NewDelta);
    }
}
```

我们要注意到**对属性值的修改**是通过调用`GameplayAbilityComponent`的`ApplyModToAttributeUnsafe`方法实现的。接下来是两个利用GASt提供的回调函数的例子。

- `PreAttributeChange` ： 任意属性发生变化前都会调用，**通常用于强加规则给数值**。

  ```c++
  void URPGAttributeSet::PreAttributeChange(const FGameplayAttribute& Attribute, float& NewValue)
  {
      // This is called whenever attributes change, so for max health/mana we want to scale the current totals to match
      Super::PreAttributeChange(Attribute, NewValue);
  
  //如果将要改变的属性是最大血量
      if (Attribute == GetMaxHealthAttribute())
      {
          AdjustAttributeForMaxChange(Health, MaxHealth, NewValue, GetHealthAttribute());
      }
  //如果将要改变的属性是最大魔法值
      else if (Attribute == GetMaxManaAttribute())
      {
          AdjustAttributeForMaxChange(Mana, MaxMana, NewValue, GetManaAttribute());
      }
  }
  ```

- `PostGameplayEffectExecute`： 任意影响`Attribute`的`GameplayEffect`执行之后都会调用，**通常用于clamp数值，触发游戏中的事件**。

  ```c++
  void URPGAttributeSet::PostGameplayEffectExecute(const FGameplayEffectModCallbackData& Data)
  {
      Super::PostGameplayEffectExecute(Data);
  
  // Context !!! 还记得讲GameplayAbility时提到的RPGAbilityType么？
  // 我们可以通过引擎提供的FGameplayEffectContextHandle得到许多关联的信息
      FGameplayEffectContextHandle Context = Data.EffectSpec.GetContext();
      UAbilitySystemComponent* Source = Context.GetOriginalInstigatorAbilitySystemComponent();
      const FGameplayTagContainer& SourceTags = *Data.EffectSpec.CapturedSourceTags.GetAggregatedTags();
  
      // Compute the delta between old and new, if it is available
      float DeltaValue = 0;
      if (Data.EvaluatedData.ModifierOp == EGameplayModOp::Type::Additive)
      {
          // If this was additive, store the raw delta value to be passed along later
          DeltaValue = Data.EvaluatedData.Magnitude;
      }
  
      // Get the Target actor, which should be our owner
      AActor* TargetActor = nullptr;
      AController* TargetController = nullptr;
      ARPGCharacterBase* TargetCharacter = nullptr;
      if (Data.Target.AbilityActorInfo.IsValid() && Data.Target.AbilityActorInfo->AvatarActor.IsValid())
      {
          TargetActor = Data.Target.AbilityActorInfo->AvatarActor.Get();
          TargetController = Data.Target.AbilityActorInfo->PlayerController.Get();
          TargetCharacter = Cast<ARPGCharacterBase>(TargetActor);
      }
  
      if (Data.EvaluatedData.Attribute == GetDamageAttribute())
      {
          // Get the Source actor
          AActor* SourceActor = nullptr;
          AController* SourceController = nullptr;
          ARPGCharacterBase* SourceCharacter = nullptr;
          if (Source && Source->AbilityActorInfo.IsValid() && Source->AbilityActorInfo->AvatarActor.IsValid())
          {
              SourceActor = Source->AbilityActorInfo->AvatarActor.Get();
              SourceController = Source->AbilityActorInfo->PlayerController.Get();
              if (SourceController == nullptr && SourceActor != nullptr)
              {
                  if (APawn* Pawn = Cast<APawn>(SourceActor))
                  {
                      SourceController = Pawn->GetController();
                  }
              }
  
              // Use the controller to find the source pawn
              if (SourceController)
              {
                  SourceCharacter = Cast<ARPGCharacterBase>(SourceController->GetPawn());
              }
              else
              {
                  SourceCharacter = Cast<ARPGCharacterBase>(SourceActor);
              }
  
              // Set the causer actor based on context if it's set
              if (Context.GetEffectCauser())
              {
                  SourceActor = Context.GetEffectCauser();
              }
          }
  
          // Try to extract a hit result
          FHitResult HitResult;
          if (Context.GetHitResult())
          {
              HitResult = *Context.GetHitResult();
          }
  
          // Store a local copy of the amount of damage done and clear the damage attribute
          const float LocalDamageDone = GetDamage();
          SetDamage(0.f);
  
          if (LocalDamageDone > 0)
          {
              // Apply the health change and then clamp it
              const float OldHealth = GetHealth();
              SetHealth(FMath::Clamp(OldHealth - LocalDamageDone, 0.0f, GetMaxHealth()));
  
              if (TargetCharacter)
              {
                  // This is proper damage
                  TargetCharacter->HandleDamage(LocalDamageDone, HitResult, SourceTags, SourceCharacter, SourceActor);
  
                  // Call for all health changes
                  TargetCharacter->HandleHealthChanged(-LocalDamageDone, SourceTags);
              }
          }
      }
      else if (Data.EvaluatedData.Attribute == GetHealthAttribute())
      {
          // Handle other health changes such as from healing or direct modifiers
          // First clamp it
          SetHealth(FMath::Clamp(GetHealth(), 0.0f, GetMaxHealth()));
  
          if (TargetCharacter)
          {
              // Call for all health changes
              TargetCharacter->HandleHealthChanged(DeltaValue, SourceTags);
          }
      }
      else if (Data.EvaluatedData.Attribute == GetManaAttribute())
      {
          // Clamp mana
          SetMana(FMath::Clamp(GetMana(), 0.0f, GetMaxMana()));
  
          if (TargetCharacter)
          {
              // Call for all mana changes
              TargetCharacter->HandleManaChanged(DeltaValue, SourceTags);
          }
      }
      else if (Data.EvaluatedData.Attribute == GetMoveSpeedAttribute())
      {
          if (TargetCharacter)
          {
              // Call for all movespeed changes
              TargetCharacter->HandleMoveSpeedChanged(DeltaValue, SourceTags);
          }
      }
  }
  ```

  我们需要注意对`FGameplayEffectContextHandle`的使用。如果引擎默认提供的信息不足，我们可以考虑拓展`FGameplayEffectContextHandle`类。这里所有的Set函数也都是通过`AbilitySystemComponent`调用方法改变数值的。随着`AttributeSet`中的属性增多，回调函数中的判断也会变得更加复杂。



## 4. RPGTargetType.h/cpp & Targeting

技能系统中很重要的一环就是目标的选取，比如LOL中的各色技能。

![img](https:////upload-images.jianshu.io/upload_images/14591462-307004416b1fad5e.png?imageMogr2/auto-orient/strip|imageView2/2/w/358/format/webp)

在[GameplayAbilities and You](https://links.jianshu.com/go?to=https%3A%2F%2Fwiki.unrealengine.com%2FGameplayAbilities_and_You) 中，将Targeting放在了Advanced话题中。我主要参考这篇文章来讲GAS中的Targeting。 文中以`Wait Target Data`这个`AbilityTask`为例。这个task在GAS中有**举足轻重**的地位，原因如：

- 提供系统用以可视化技能目标选择
- 提供玩家发送信息到服务器的框架(Client  to  Server)

![img](https:////upload-images.jianshu.io/upload_images/14591462-d9b2878dec90eed5.png?imageMogr2/auto-orient/strip|imageView2/2/w/940/format/webp)`Wait Target Data`通常放在`Commit Ability`之前，玩家在确认释放技能前可以看到技能指示器（参考LOL）。

![img](C:\Users\xueyaojiang\Desktop\JMX_Update\解析ActionRPG.assets\14591462-39b30fd68cbeffef.png)

Class必须是`GameplayAbilityTargetActor`的子类。共有4种Confirmation type，后两种是Custom，默认提供的是**Instant**和**User Confirmed**。**User Confirmed**相较于**Instant**来说，需要额外调用`UAbilitySystemComponent::TargetConfirm()`或将comfirm绑定在输入上，取消也是类似的，需要调用`UAbilitySystemComponent::TargetCancel()`，或将cancel绑定在输入上。最后记得不要忘记调用`EndAbility`。

需要注意，task右侧的引脚在客户端和服务端都有效，Valid Data Delegate都会调用。后端关于它的实现采取一种比较有趣的方式： task会生成actor（GameplayAbilityTargetActor）实例，而这些实例不是replicated。（应该是客户端和服务端都生成actor）实际上，服务端通过`AbilitySystemComponent`将数据发送给客户端。这种方案导致`targeting actor`的设置有些奇特。（暂时我还没get到）

### Target Actor

> ==TargetActors==的产生是为了**协助能力的定位**。它们由`ability tasks`生成，并创建/确定从一个任务传递到另一个任务的**外发目标定位数据**。
>
>  * 警告：这些行为体在每个能力激活时产生一次，在其默认形式下，效率不高。
>  * 对于大多数游戏，你需要对这个角色进行子类化和大量的修改，或者你想在一个特定的游戏角色或蓝图中实现类似的功能，以避免角色的生成成本。
>  * 这个类没有经过内部游戏的测试，但它是一个有用的类，可以用来了解目标复制是如何发生的。

我们通过继承`AGameplayAbilityTargetActor`创建**自定义的TargetActor**。其中，有两个主要的函数需要我们重写：

- `virtual void StartTargeting(UGameplayAbility* Ability) override`
  - 在这里，你可以访问**Ability实例**，因此你可以使用Ability类里的数据。比如：假如你有一个造墙的技能，那么在目标选择时，需要从**Ability实例**中得到墙的mesh数据，这样`TargetActor`才能正确显示墙体指示器。**Ability实例**中还包含释放该技能的Character引用，因此TargetActor还能访问到Character的信息（人物的tag和attribute可能影响targeting）。
- `virtual void ConfirmTargetingAndContinue() override`

这里有些较难理解的地方，但是我们化繁为简，这个函数最核心的功能是调用`TargetDataReadyDelegate`，同时传递携带包含我们`target data`的负载。因此，如果我们想传递两个`transforms`，分别包含技能施放者位置和目标物体位置，那么代码如下：

```c++
// 继承自FGameplayAbilityTargetData
FGameplayAbilityTargetData_LocationInfo *ReturnData = new FGameplayAbilityTargetData_LocationInfo();

// Source Transform
ReturnData->SourceLocation.LocationType = EGameplayAbilityTargetingLocationType::LiteralTransform;
ReturnData->SourceLocation.LiteralTransform = FTransform(SourceLocation);
// Destination Transform
ReturnData->TargetLocation.LocationType = EGameplayAbilityTargetingLocationType::LiteralTransform;
ReturnData->TargetLocation.LiteralTransform = FTransform((TargetLocation - SourceLocation).ToOrientationQuat(), TargetLocation);

// Handle !! 这就是我们为什么new了却不要delete的原因，里面用了智能指针
FGameplayAbilityTargetDataHandle Handle(ReturnData);
// Fire delegate with data handle !!!
TargetDataReadyDelegate.Broadcast(Handle);
```

关键的数据结构是`FGameplayAbilityTargetData`（你的`TargetingSystem`运行后最终的结果数据），引擎里已经提供了一系列的子类用于不同的需求：

- FGameplayAbilityTargetData_LocationInfo ：包含最多两个位置信息数据
- FGameplayAbilityTargetData_ActorArray ： 包含一个Actor数组
- FGameplayAbilityTargetData_SingleTargetHit ： 包含一个碰撞结果（HitResult）

***特别注意： 这个方法是将数据从Client端发往Server端。虽然Server端也有一个版本的数值，但它并不准确。因为是从Client端发往Server端，所以数据有被用户篡改的风险，记得要添加验证。\***

接下来我们自定义一个`FGameplayAbilityTargetData`类，它包含两个`location`，一个`float`，一个`int`。这个数据类依旧是用于造墙技能，只是这次，我们用鼠标按下的时间（float）来决定墙的高度。代码如下：

```c++
USTRUCT(BlueprintType)
struct FGameplayAbilityCastingTargetingLocationInfo: public FGameplayAbilityTargetData
{
    GENERATED_USTRUCT_BODY()

        /**
          如果没记错，属性需要标记UPROPERTY()，才能被序列化
        */

    /** Amount of time the ability has been charged */
    UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Targeting)
    float ChargeTime;

    /** The ID of the Ability that is performing targeting */
    UPROPERTY()
    uint32 UniqueID;

    /** Generic location data for source */
    UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Targeting)
    FGameplayAbilityTargetingLocationInfo SourceLocation;

    /** Generic location data for target */
    UPROPERTY(BlueprintReadWrite, EditAnywhere, Category = Targeting)
    FGameplayAbilityTargetingLocationInfo TargetLocation;

    // -------------------------------------

    virtual bool HasOrigin() const override
    {
        return true;
    }

    virtual FTransform GetOrigin() const override
    {
        return SourceLocation.GetTargetingTransform();
    }

    // -------------------------------------

    virtual bool HasEndPoint() const override
    {
        return true;
    }

    virtual FVector GetEndPoint() const override
    {
        return TargetLocation.GetTargetingTransform().GetLocation();
    }

    virtual FTransform GetEndPointTransform() const override
    {
        return TargetLocation.GetTargetingTransform();
    }

    // -------------------------------------

    virtual UScriptStruct* GetScriptStruct() const override
    {
        return FGameplayAbilityCastingTargetingLocationInfo::StaticStruct();
    }

    virtual FString ToString() const override
    {
        return TEXT("FGameplayAbilityCastingTargetingLocationInfo");
    }

    bool NetSerialize(FArchive& Ar, class UPackageMap* Map, bool& bOutSuccess);
};

/**  这一部分具体的运作机制不明，但必须要有 */
template<>
struct TStructOpsTypeTraits<FGameplayAbilityCastingTargetingLocationInfo> : public TStructOpsTypeTraitsBase2<FGameplayAbilityCastingTargetingLocationInfo>
{
    enum
    {
        WithNetSerializer = true    // For now this is REQUIRED for FGameplayAbilityTargetDataHandle net serialization to work
    };
};
```

NetSerialize的实现：

```c++
bool FGameplayAbilityCastingTargetingLocationInfo::NetSerialize(FArchive& Ar, class UPackageMap* Map, bool& bOutSuccess)
{
    SourceLocation.NetSerialize(Ar, Map, bOutSuccess);
    TargetLocation.NetSerialize(Ar, Map, bOutSuccess);

    Ar << ChargeTime;
    Ar << UniqueID;

    bOutSuccess = true;
    return true;
}
```

最后，正如官方头文件所述，`TargetActor`默认是**每执行一次Ability都会创建**，然后销毁。为了提高性能，要考虑重用`TargetActor`。当然，你甚至可以不使用TargetActor，`ActionRPG`中就是这样。对于造墙这种技能，墙体指示器可能要跟随玩家的移动，所以你需要保存在`StartTarget`中获得Character的指针或引用，然后在TargetActor的Tick函数中获取Character的位置信息来更新墙体指示器的位置。

### RPGTargetType.h/cpp

我们终于可以回到`ActionRPG`项目上来了。很不幸的是，前面说了一大段的知识点。这个项目并没有用到，而是另辟蹊径。

> 用来确定**能力的目标**的类
>  * 它是用来运行目标逻辑的蓝图。
>  * 这不是GameplayAbilityTargetActor的子类，因为这个类从未被实例化到世界中。
>  * 这可以作为特定游戏的目标定位蓝图的基础。
>  * 如果你的目标设定比较复杂，你可能需要将其实例化到世界中一次或作为一个池状的角色。

头文件：

```c++
// Copyright 1998-2019 Epic Games, Inc. All Rights Reserved.

#pragma once

#include "ActionRPG.h"
#include "Abilities/GameplayAbilityTypes.h"
#include "Abilities/RPGAbilityTypes.h"
#include "RPGTargetType.generated.h"

class ARPGCharacterBase;
class AActor;
struct FGameplayEventData;

/**
 * Class that is used to determine targeting for abilities
 * It is meant to be blueprinted to run target logic
 * This does not subclass GameplayAbilityTargetActor because this class is never instanced into the world
 * This can be used as a basis for a game-specific targeting blueprint
 * If your targeting is more complicated you may need to instance into the world once or as a pooled actor
 */
UCLASS(Blueprintable, meta = (ShowWorldContextPin))
class ACTIONRPG_API URPGTargetType : public UObject
{
    GENERATED_BODY()

public:
    // Constructor and overrides
    URPGTargetType() {}

    /** Called to determine targets to apply gameplay effects to */
    UFUNCTION(BlueprintNativeEvent)
    void GetTargets(ARPGCharacterBase* TargetingCharacter, AActor* TargetingActor, FGameplayEventData EventData, TArray<FHitResult>& OutHitResults, TArray<AActor*>& OutActors) const;
};

/** Trivial target type that uses the owner */
UCLASS(NotBlueprintable)
class ACTIONRPG_API URPGTargetType_UseOwner : public URPGTargetType
{
    GENERATED_BODY()

public:
    // Constructor and overrides
    URPGTargetType_UseOwner() {}

    /** Uses the passed in event data */
    virtual void GetTargets_Implementation(ARPGCharacterBase* TargetingCharacter, AActor* TargetingActor, FGameplayEventData EventData, TArray<FHitResult>& OutHitResults, TArray<AActor*>& OutActors) const override;
};

/** Trivial target type that pulls the target out of the event data */
UCLASS(NotBlueprintable)
class ACTIONRPG_API URPGTargetType_UseEventData : public URPGTargetType
{
    GENERATED_BODY()

public:
    // Constructor and overrides
    URPGTargetType_UseEventData() {}

    /** Uses the passed in event data */
    virtual void GetTargets_Implementation(ARPGCharacterBase* TargetingCharacter, AActor* TargetingActor, FGameplayEventData EventData, TArray<FHitResult>& OutHitResults, TArray<AActor*>& OutActors) const override;
};

```

不同于`TargetActor`，这里定义的`TargetType`（继承自UObject）不会被也不能实例化到World中（Actor才能被放置到World中）。



## 5. RPGAbilityTask_PlayMontageAndWaitForEvent & AbilityTask

### AbilityTask

官方头文件注释：

> ```c++
> /**
>  *  AbilityTasks are small, self contained operations that can be performed while executing an ability.
>  *  They are latent/asynchronous is nature. They will generally follow the pattern of 'start something and wait until it is finished or interrupted'
>  *  
>  *  We have code in K2Node_LatentAbilityCall to make using these in blueprints streamlined. The best way to become familiar with AbilityTasks is to 
>  *  look at existing tasks like UAbilityTask_WaitOverlap (very simple) and UAbilityTask_WaitTargetData (much more complex).
>  *  
>  *  These are the basic requirements for using an ability task:
>  *  
>  *  1) Define dynamic multicast, BlueprintAssignable delegates in your AbilityTask. These are the OUTPUTs of your task. When these delegates fire,
>  *  execution resumes in the calling blueprints.
>  *  
>  *  2) Your inputs are defined by a static factory function which will instantiate an instance of your task. The parameters of this function define
>  *  the INPUTs into your task. All the factory function should do is instantiate your task and possibly set starting parameters. It should NOT invoke
>  *  any of the callback delegates!
>  *  
>  *  3) Implement a Activate() function (defined here in base class). This function should actually start/execute your task logic. It is safe to invoke
>  *  callback delegates here.
>  *  
>  *  
>  *  This is all you need for basic AbilityTasks. 
>  *  
>  *  
>  *  CheckList:
>  *      -Override ::OnDestroy() and unregister any callbacks that the task registered. Call Super::EndTask too!
>  *      -Implemented an Activate function which truly 'starts' the task. Do not 'start' the task in your static factory function!
>  *  
>  *  
>  *  --------------------------------------
>  *  
>  *  We have additional support for AbilityTasks that want to spawn actors. Though this could be accomplished in an Activate() function, it would not be
>  *  possible to pass in dynamic "ExposeOnSpawn" actor properties. This is a powerful feature of blueprints, in order to support this, you need to implement 
>  *  a different step 3:
>  *  
>  *  Instead of an Activate() function, you should implement a BeginSpawningActor() and FinishSpawningActor() function.
>  *  
>  *  BeginSpawningActor() must take in a TSubclassOf<YourActorClassToSpawn> parameters named 'Class'. It must also have a out reference parameters of type 
>  *  YourActorClassToSpawn*& named SpawnedActor. This function is allowed to decide whether it wants to spawn the actor or not (useful if wishing to
>  *  predicate actor spawning on network authority).
>  *  
>  *  BeginSpawningActor() can instantiate an actor with SpawnActorDefferred. This is important, otherwise the UCS will run before spawn parameters are set.
>  *  BeginSpawningActor() should also set the SpawnedActor parameter to the actor it spawned.
>  *  
>  *  [Next, the generated byte code will set the expose on spawn parameters to whatever the user has set]
>  *  
>  *  If you spawned something, FinishSpawningActor() will be called and pass in the same actor that was just spawned. You MUST call ExecuteConstruction + PostActorConstruction
>  *  on this actor!
>  *  
>  *  This is a lot of steps but in general, AbilityTask_SpawnActor() gives a clear, minimal example.
>  *  
>  *  
>  */
> ```

上面文字的大意：

**AbilityTask是小而完备的行为，通常在Ability执行过程中运行。**异步是其固有特征。实现的功能一般按照***“开始做些事，直到结束或被中断”\***的模式。 官方推荐了学习两个已有的AbilityTask：

- UAbilityTask_WaitOverlap (very simple)
- UAbilityTask_WaitTargetData ( much more complex)

为了使用AbilityTask，你必须满足**三个基本要求**：

1. 在AbilityTask中定义dynamic multicast ， BlueprintAssignable类型的delegate，这些委托就是task的输出。当这些委托触发时，我们会回到调用AbilityTask的蓝图中（通常是`Ability`）。
2. 你需要定义一个static的工厂函数来实例化`AbilityTask`。该工厂函数的输入参数表，就是你对ability task的输入。在这个函数中，你应该创建你的**task实例**并设置你的成员变量初值。不应该在此调用任何委托。
3. 实现`Activate()`函数。从这个函数开始你的task。你可以在这里安全地触发委托。

你还有一个**check list**要检查：

- Override `:: OnDestroy()` 来注销你之前在task注册的callback。记得在合适的地方调用EndTask来结束任务。
- Implemented an Activate function which truly 'starts' the task. Do not 'start' the task in your static factory function!

还有一部分是说在task中spawn actor，这里就不说明了。引擎提供了`AbilityTask_SpawnActor()`供参考。

### RPGAbilityTask_PlayMontageAndWaitForEvent.h/cpp

```c++
// Copyright 1998-2019 Epic Games, Inc. All Rights Reserved.

#pragma once

#include "ActionRPG.h"
#include "Abilities/Tasks/AbilityTask.h"
#include "RPGAbilityTask_PlayMontageAndWaitForEvent.generated.h"

class URPGAbilitySystemComponent;

/** Delegate type used, EventTag and Payload may be empty if it came from the montage callbacks */
/**  我们先声明要使用的Delegate类型，还记得要求1)么？ Dynamic multicast !!!
 你可以声明各种不同参数表的delegate*/
DECLARE_DYNAMIC_MULTICAST_DELEGATE_TwoParams(FRPGPlayMontageAndWaitForEventDelegate, FGameplayTag, EventTag, FGameplayEventData, EventData);

/**
 * This task combines PlayMontageAndWait and WaitForEvent into one task, so you can wait for multiple types of activations such as from a melee combo
 * Much of this code is copied from one of those two ability tasks
 * This is a good task to look at as an example when creating game-specific tasks
 * It is expected that each game will have a set of game-specific tasks to do what they want
 */
UCLASS()
class ACTIONRPG_API URPGAbilityTask_PlayMontageAndWaitForEvent : public UAbilityTask
{
    GENERATED_BODY()

public:
    // Constructor and overrides
    URPGAbilityTask_PlayMontageAndWaitForEvent(const FObjectInitializer& ObjectInitializer);

// 要求3)，重写Activate()
    virtual void Activate() override;

    virtual void ExternalCancel() override;
    virtual FString GetDebugString() const override;

//Check List ， 重写OnDestroy来注销callback
    virtual void OnDestroy(bool AbilityEnded) override;

// 要求1) BlueprintAssignable的delegate提供蓝图支持
// -------------------------------------------------------------------------
    /** The montage completely finished playing */
    UPROPERTY(BlueprintAssignable)
    FRPGPlayMontageAndWaitForEventDelegate OnCompleted;

    /** The montage started blending out */
    UPROPERTY(BlueprintAssignable)
    FRPGPlayMontageAndWaitForEventDelegate OnBlendOut;

    /** The montage was interrupted */
    UPROPERTY(BlueprintAssignable)
    FRPGPlayMontageAndWaitForEventDelegate OnInterrupted;

    /** The ability task was explicitly cancelled by another ability */
    UPROPERTY(BlueprintAssignable)
    FRPGPlayMontageAndWaitForEventDelegate OnCancelled;

    /** One of the triggering gameplay events happened */
    UPROPERTY(BlueprintAssignable)
    FRPGPlayMontageAndWaitForEventDelegate EventReceived;
// -------------------------------------------------------------------------

    /**
     * Play a montage and wait for it end. If a gameplay event happens that matches EventTags (or EventTags is empty), the EventReceived delegate will fire with a tag and event data.
     * If StopWhenAbilityEnds is true, this montage will be aborted if the ability ends normally. It is always stopped when the ability is explicitly cancelled.
     * On normal execution, OnBlendOut is called when the montage is blending out, and OnCompleted when it is completely done playing
     * OnInterrupted is called if another montage overwrites this, and OnCancelled is called if the ability or task is cancelled
     *
     * @param TaskInstanceName Set to override the name of this task, for later querying
     * @param MontageToPlay The montage to play on the character
     * @param EventTags Any gameplay events matching this tag will activate the EventReceived callback. If empty, all events will trigger callback
     * @param Rate Change to play the montage faster or slower
     * @param bStopWhenAbilityEnds If true, this montage will be aborted if the ability ends normally. It is always stopped when the ability is explicitly cancelled
     * @param AnimRootMotionTranslationScale Change to modify size of root motion or set to 0 to block it entirely
   要求1) 静态工厂函数 ， 前两个参数必须是UGameplayAbility* , FName
     */
    UFUNCTION(BlueprintCallable, Category="Ability|Tasks", meta = (HidePin = "OwningAbility", DefaultToSelf = "OwningAbility", BlueprintInternalUseOnly = "TRUE"))
    static URPGAbilityTask_PlayMontageAndWaitForEvent* PlayMontageAndWaitForEvent(
        UGameplayAbility* OwningAbility,
        FName TaskInstanceName,
        UAnimMontage* MontageToPlay,
        FGameplayTagContainer EventTags,
        float Rate = 1.f,
        FName StartSection = NAME_None,
        bool bStopWhenAbilityEnds = true,
        float AnimRootMotionTranslationScale = 1.f);

private:
    /** Montage that is playing */
    UPROPERTY()
    UAnimMontage* MontageToPlay;

    /** List of tags to match against gameplay events */
    UPROPERTY()
    FGameplayTagContainer EventTags;

    /** Playback rate */
    UPROPERTY()
    float Rate;

    /** Section to start montage from */
    UPROPERTY()
    FName StartSection;

    /** Modifies how root motion movement to apply */
    UPROPERTY()
    float AnimRootMotionTranslationScale;

    /** Rather montage should be aborted if ability ends */
    UPROPERTY()
    bool bStopWhenAbilityEnds;

    /** Checks if the ability is playing a montage and stops that montage, returns true if a montage was stopped, false if not. */
    bool StopPlayingMontage();

    /** Returns our ability system component */
    URPGAbilitySystemComponent* GetTargetASC();

    void OnMontageBlendingOut(UAnimMontage* Montage, bool bInterrupted);
    void OnAbilityCancelled();
    void OnMontageEnded(UAnimMontage* Montage, bool bInterrupted);
    void OnGameplayEvent(FGameplayTag EventTag, const FGameplayEventData* Payload);

// 用于绑定到montage的委托
    FOnMontageBlendingOutStarted BlendingOutDelegate;
    FOnMontageEnded MontageEndedDelegate;

// Delegate Handle用来清理对外部注册的delegate
    FDelegateHandle CancelledHandle;
    FDelegateHandle EventHandle;
};

```

源文件我们主要看这些函数：

- OnMontageEnded ： 触发OnCompleted蓝图输出引脚
- PlayMontageAndWaitForEvent：静态工厂函数
- Activate：执行task
- OnDestroy: 清理注册到外部的delegate

```c++
void URPGAbilityTask_PlayMontageAndWaitForEvent::OnGameplayEvent(FGameplayTag EventTag, const FGameplayEventData* Payload)
{
// 在broad cast 委托之前，都要调用 ShouldBroadcastAbilityTaskDelegates检测Ability是否有效
    if (ShouldBroadcastAbilityTaskDelegates())
    {
        FGameplayEventData TempData = *Payload;
        TempData.EventTag = EventTag;
         
// Fire delegate
        EventReceived.Broadcast(EventTag, TempData);
    }
}
```

静态工厂函数：

```c++
URPGAbilityTask_PlayMontageAndWaitForEvent* URPGAbilityTask_PlayMontageAndWaitForEvent::PlayMontageAndWaitForEvent(UGameplayAbility* OwningAbility,
    FName TaskInstanceName, UAnimMontage* MontageToPlay, FGameplayTagContainer EventTags, float Rate, FName StartSection, bool bStopWhenAbilityEnds, float AnimRootMotionTranslationScale)
{
// 在开发阶段使用，控制montage的播放速度
    UAbilitySystemGlobals::NonShipping_ApplyGlobalAbilityScaler_Rate(Rate);

//使用NewAbilityTask来创建ability task实例
    URPGAbilityTask_PlayMontageAndWaitForEvent* MyObj = NewAbilityTask<URPGAbilityTask_PlayMontageAndWaitForEvent>(OwningAbility, TaskInstanceName);

//设置成员变量初始值
    MyObj->MontageToPlay = MontageToPlay;
    MyObj->EventTags = EventTags;
    MyObj->Rate = Rate;
    MyObj->StartSection = StartSection;
    MyObj->AnimRootMotionTranslationScale = AnimRootMotionTranslationScale;
    MyObj->bStopWhenAbilityEnds = bStopWhenAbilityEnds;

    return MyObj;
}
```

任务本体Activate()，在这里绑定各种delegate：

```c++
void URPGAbilityTask_PlayMontageAndWaitForEvent::Activate()
{
    if (Ability == nullptr)
    {
        return;
    }

    bool bPlayedMontage = false;
// GetTargetASC的功能只是Cast
    URPGAbilitySystemComponent* RPGAbilitySystemComponent = GetTargetASC();

    if (RPGAbilitySystemComponent)
    {
        const FGameplayAbilityActorInfo* ActorInfo = Ability->GetCurrentActorInfo();
//获得actor上的skeletal mesh comp的动画实例
        UAnimInstance* AnimInstance = ActorInfo->GetAnimInstance();
        if (AnimInstance != nullptr)
        {
            // Bind to event callback
            EventHandle = RPGAbilitySystemComponent->AddGameplayEventTagContainerDelegate(EventTags, FGameplayEventTagMulticastDelegate::FDelegate::CreateUObject(this, &URPGAbilityTask_PlayMontageAndWaitForEvent::OnGameplayEvent));

// Play montage
            if (RPGAbilitySystemComponent->PlayMontage(Ability, Ability->GetCurrentActivationInfo(), MontageToPlay, Rate, StartSection) > 0.f)
            {
                // Playing a montage could potentially fire off a callback into game code which could kill this ability! Early out if we are  pending kill.
                if (ShouldBroadcastAbilityTaskDelegates() == false)
                {
                    return;
                }

                CancelledHandle = Ability->OnGameplayAbilityCancelled.AddUObject(this, &URPGAbilityTask_PlayMontageAndWaitForEvent::OnAbilityCancelled);

// Set  montage delegates
//----------------------------------------------------------------------------------------------------------
                BlendingOutDelegate.BindUObject(this, &URPGAbilityTask_PlayMontageAndWaitForEvent::OnMontageBlendingOut);
                AnimInstance->Montage_SetBlendingOutDelegate(BlendingOutDelegate, MontageToPlay);

                MontageEndedDelegate.BindUObject(this, &URPGAbilityTask_PlayMontageAndWaitForEvent::OnMontageEnded);
                AnimInstance->Montage_SetEndDelegate(MontageEndedDelegate, MontageToPlay);
//--------------------------------------------------------------------------------------------------------------

//是否应用动画影响角色的位置
                ACharacter* Character = Cast<ACharacter>(GetAvatarActor());
                if (Character && (Character->Role == ROLE_Authority ||
                                  (Character->Role == ROLE_AutonomousProxy && Ability->GetNetExecutionPolicy() == EGameplayAbilityNetExecutionPolicy::LocalPredicted)))
                {
                    Character->SetAnimRootMotionTranslationScale(AnimRootMotionTranslationScale);
                }

                bPlayedMontage = true;
            }
        }
        else
        {
            ABILITY_LOG(Warning, TEXT("URPGAbilityTask_PlayMontageAndWaitForEvent call to PlayMontage failed!"));
        }
    }
    else
    {
        ABILITY_LOG(Warning, TEXT("URPGAbilityTask_PlayMontageAndWaitForEvent called on invalid AbilitySystemComponent"));
    }
//动画播放失败
    if (!bPlayedMontage)
    {
        ABILITY_LOG(Warning, TEXT("URPGAbilityTask_PlayMontageAndWaitForEvent called in Ability %s failed to play montage %s; Task Instance Name %s."), *Ability->GetName(), *GetNameSafe(MontageToPlay),*InstanceName.ToString());
        if (ShouldBroadcastAbilityTaskDelegates())
        {
            OnCancelled.Broadcast(FGameplayTag(), FGameplayEventData());
        }
    }
/** Called when the ability task is waiting on ACharacter type of state (movement state, etc). IF the remote player ends the ability prematurely, and a task with this set is still running, the ability is killed. */
// 我们需要明确等待什么东西：
// Task is waiting for the game to do something 
//  WaitingOnGame = 0x01,

    // Waiting for the user to do something 
//  WaitingOnUser = 0x02,

    // Waiting on Avatar (Character/Pawn/Actor) to do something (usually something physical in the world, like land, move, etc) 
//  WaitingOnAvatar = 0x04
*/
    SetWaitingOnAvatar();
}
```

