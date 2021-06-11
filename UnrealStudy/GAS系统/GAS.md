![img](GAS.assets\af1ad70fd0073affb0ad5beaa9f42839.png)

# Pt0

![image-20210608100030864](GAS.assets\image-20210608100030864-1623117632842.png)

![image-20210608100241032](GAS.assets\image-20210608100241032.png)

# Pt1

新建项目，安装`game ability`插件，新建一个C++类，继承自`character`。

使用GAS建立一个项目的基本步骤:

1. 在编辑器中启用`GameplayAbilitySystem`插件.
2. 编辑`YourProjectName.Build.cs`, 添加`"GameplayAbilities"`, `"GameplayTags"`, `"GameplayTasks"`到你的`PrivateDependencyModuleNames`.
3. **刷新/重新生成**Visual Studio项目文件.
4. 从4.24开始, 需要强制调用`UAbilitySystemGlobals::InitGlobalData()`来使用[`TargetData`](https://github.com/BillEliot/GASDocumentation_Chinese#concepts-targeting-data), 样例项目在`UEngineSubsystem::Initialize()`中调用该函数. 参阅[`InitGlobalData()`](https://github.com/BillEliot/GASDocumentation_Chinese#concepts-asg-initglobaldata)获取更多信息.

代码：

```c++
// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "AbilitySystemComponent.h"
#include "AbilitySystemInterface.h"
#include "Abilities/GameplayAbility.h"
#include "BaseCharacter.generated.h"

UCLASS()
class GAS_TEST_API ABaseCharacter : public ACharacter, public IAbilitySystemInterface
{
	GENERATED_BODY()

public:
	// Sets default values for this character's properties
	ABaseCharacter();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	// Called to bind functionality to input
	virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "BaseCharacter")
		UAbilitySystemComponent* AbilitySystemComp;

	UFUNCTION(BlueprintCallable, Category = "BaseCharacter")
		void InitializeAbility(TSubclassOf<UGameplayAbility> AbilityToGet, int32 AbilityLevel);

	virtual UAbilitySystemComponent* GetAbilitySystemComponent() const;
};

```

```c++
// Fill out your copyright notice in the Description page of Project Settings.


#include "BaseCharacter.h"

// Sets default values
ABaseCharacter::ABaseCharacter()
{
 	// Set this character to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

	AbilitySystemComp = CreateDefaultSubobject<UAbilitySystemComponent>("AbilitySystemComp");
}

// Called when the game starts or when spawned
void ABaseCharacter::BeginPlay()
{
	Super::BeginPlay();
	
}

// Called every frame
void ABaseCharacter::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

}

// Called to bind functionality to input
void ABaseCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);

}

void ABaseCharacter::InitializeAbility(TSubclassOf<UGameplayAbility> AbilityToGet, int32 AbilityLevel)
{
	if (AbilitySystemComp) {
		if (HasAuthority() && AbilityToGet) {
			//返回能力的句柄，用以激活
			AbilitySystemComp->GiveAbility(FGameplayAbilitySpec(AbilityToGet, AbilityLevel, 0));
		}

		//初始化能力的用户信息，主要是逻辑用户和物理用户
		//逻辑用户：控制这个能力的（逻辑上拥有这个组件的）
		//物理用户：这个能力控制的（物理上我们正在acting on 的角色）
		AbilitySystemComp->InitAbilityActorInfo(this, this);
	}
}

UAbilitySystemComponent* ABaseCharacter::GetAbilitySystemComponent() const
{
	return AbilitySystemComp;
}


```

修改角色的类设置：

![image-20210608165401959](GAS.assets\image-20210608165401959-1623142443261.png)



# Pt2

创建一个C++类，继承`attributeSet`：

![image-20210608165850036](GAS.assets\image-20210608165850036.png)

代码：

```c++
// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "AttributeSet.h"
#include "AbilitySystemComponent.h"
#include "BaseAttributeSet.generated.h"

//以下相当于宏注册，如此声明的函数，会自动具有init，get,set 函数，例如initHealth。
#define ATTRIBUTE_ACCESSORS(ClassName, PropertyName) \
GAMEPLAYATTRIBUTE_PROPERTY_GETTER(ClassName, PropertyName) \
GAMEPLAYATTRIBUTE_VALUE_GETTER(PropertyName) \
GAMEPLAYATTRIBUTE_VALUE_SETTER(PropertyName) \
GAMEPLAYATTRIBUTE_VALUE_INITTER(PropertyName)

/**
 * 
 */
UCLASS()
class GAS_TEST_API UBaseAttributeSet : public UAttributeSet
{
	GENERATED_BODY()

public:

	UBaseAttributeSet();

	//health
	UPROPERTY(EditAnywhere, BlueprintReadWrite ,Category = "BaseAttribute")
	FGameplayAttributeData Health;
	ATTRIBUTE_ACCESSORS(UBaseAttributeSet, Health);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BaseAttribute")
	FGameplayAttributeData MaxHealth;
	ATTRIBUTE_ACCESSORS(UBaseAttributeSet, MaxHealth);

	//Mana
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BaseAttribute")
		FGameplayAttributeData Mana;
	ATTRIBUTE_ACCESSORS(UBaseAttributeSet, Mana);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BaseAttribute")
		FGameplayAttributeData MaxMana;
	ATTRIBUTE_ACCESSORS(UBaseAttributeSet, MaxMana);
	
	//Stamina
	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BaseAttribute")
		FGameplayAttributeData Stamina;
	ATTRIBUTE_ACCESSORS(UBaseAttributeSet, Stamina);

	UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "BaseAttribute")
		FGameplayAttributeData MaxStamina;
	ATTRIBUTE_ACCESSORS(UBaseAttributeSet, MaxStamina);

	/*
	* 在执行GameplayEffect之前被调用，以修改一个属性的基本值。No more changes can be made 。
	* 注意这只是在一个 "执行 "过程中被调用。例如，对一个属性的 "基础值 "进行修改。
	* 它不会在应用游戏效果的过程中被调用，比如一个5秒+10的移动速度BUFF。
	*/
	void PostGameplayEffectExecute(const struct FGameplayEffectModCallbackData& Data)override;
};

```

```c#
// Fill out your copyright notice in the Description page of Project Settings.


#include "BaseAttributeSet.h"
#include "GameplayEffect.h"
#include "GameplayEffectExtension.h"

UBaseAttributeSet::UBaseAttributeSet() {

}

/*
* 在执行GameplayEffect之前被调用，以修改一个属性的基本值。No more changes can be made 。
* 注意这只是在一个 "执行 "过程中被调用。例如，对一个属性的 "基础值 "进行修改。
* 它不会在应用游戏效果的过程中被调用，比如一个5秒+10的移动速度BUFF。
*/
void UBaseAttributeSet::PostGameplayEffectExecute(const FGameplayEffectModCallbackData& Data){
	Super::PostGameplayEffectExecute(Data);

	if (Data.EvaluatedData.Attribute == GetHealthAttribute()) {
		SetHealth(FMath::Clamp(GetHealth(), 0.0f, GetMaxHealth()));
	}

	if (Data.EvaluatedData.Attribute == GetManaAttribute()) {
		SetMana(FMath::Clamp(GetMana(), 0.0f, GetMaxMana()));
	}

	if (Data.EvaluatedData.Attribute == GetStaminaAttribute()) {
		SetStamina(FMath::Clamp(GetStamina(), 0.0f, GetMaxStamina()));
	}
}

```

修改上节新建的`BaseCharacter`：

```c++
// Fill out your copyright notice in the Description page of Project Settings.

#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Character.h"
#include "AbilitySystemComponent.h"
#include "AbilitySystemInterface.h"
#include "Abilities/GameplayAbility.h"
#include "BaseCharacter.generated.h"

class BaseAttributeSet;

UCLASS()
class GAS_TEST_API ABaseCharacter : public ACharacter, public IAbilitySystemInterface
{
	GENERATED_BODY()

public:
	// Sets default values for this character's properties
	ABaseCharacter();

protected:
	// Called when the game starts or when spawned
	virtual void BeginPlay() override;

public:	
	// Called every frame
	virtual void Tick(float DeltaTime) override;

	// Called to bind functionality to input
	virtual void SetupPlayerInputComponent(class UInputComponent* PlayerInputComponent) override;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "BaseCharacter")
		UAbilitySystemComponent* AbilitySystemComp;

	UFUNCTION(BlueprintCallable, Category = "BaseCharacter")
		void InitializeAbility(TSubclassOf<UGameplayAbility> AbilityToGet, int32 AbilityLevel);

	virtual UAbilitySystemComponent* GetAbilitySystemComponent() const;

	UPROPERTY(VisibleAnywhere, BlueprintReadWrite, Category = "BaseCharacter")
		const class UBaseAttributeSet* BaseAttributeSetComp;

	UFUNCTION(BlueprintPure, Category = "BaseCharacter")
		void GetHealthValues(float& Health, float& MaxHealth);

	UFUNCTION(BlueprintPure, Category = "BaseCharacter")
		void GetManaValues(float& Mana, float& MaxMana);

	UFUNCTION(BlueprintPure, Category = "BaseCharacter")
		void GetStaminaValues(float& Stamina, float& MaxStamina);

	void OnHealthChangedNative(const FOnAttributeChangeData& Data);
	void OnManaChangedNative(const FOnAttributeChangeData& Data);
	void OnStaminaChangedNative(const FOnAttributeChangeData& Data);

	//BlueprintImplementableEvent: 在C++可以声明函数（不能定义，蓝图重载），在C++里调用该函数，蓝图重载实现该函数
	UFUNCTION(BlueprintImplementableEvent, Category = "BaseCharacter")
		void OnHealthChanged(float OldValue, float NewValue);
	UFUNCTION(BlueprintImplementableEvent, Category = "BaseCharacter")
		void OnManaChanged(float OldValue, float NewValue);
	UFUNCTION(BlueprintImplementableEvent, Category = "BaseCharacter")
		void OnStaminaChanged(float OldValue, float NewValue);
};

```

```c++
// Fill out your copyright notice in the Description page of Project Settings.


#include "BaseCharacter.h"
#include "BaseAttributeSet.h"

// Sets default values
ABaseCharacter::ABaseCharacter()
{
 	// Set this character to call Tick() every frame.  You can turn this off to improve performance if you don't need it.
	PrimaryActorTick.bCanEverTick = true;

	AbilitySystemComp = CreateDefaultSubobject<UAbilitySystemComponent>("AbilitySystemComp");
}

// Called when the game starts or when spawned
void ABaseCharacter::BeginPlay()
{
	Super::BeginPlay();

	if (AbilitySystemComp) {
		//寻找此AS存在的ability set 。
		BaseAttributeSetComp = AbilitySystemComp->GetSet<UBaseAttributeSet>();

		//GetGameplayAttributeValueChangeDelegate：注册一个委托，当一个属性值改变时触发。
		//AddUObject：增加了一个基于UObject的成员函数委托。InUserObject 要绑定的用户对象。InFunc 类方法函数地址
		AbilitySystemComp->GetGameplayAttributeValueChangeDelegate(BaseAttributeSetComp->GetHealthAttribute()).AddUObject(this, &ABaseCharacter::OnHealthChangedNative);
		AbilitySystemComp->GetGameplayAttributeValueChangeDelegate(BaseAttributeSetComp->GetManaAttribute()).AddUObject(this, &ABaseCharacter::OnManaChangedNative);
		AbilitySystemComp->GetGameplayAttributeValueChangeDelegate(BaseAttributeSetComp->GetStaminaAttribute()).AddUObject(this, &ABaseCharacter::OnStaminaChangedNative);
	}
	
}

// Called every frame
void ABaseCharacter::Tick(float DeltaTime)
{
	Super::Tick(DeltaTime);

}

// Called to bind functionality to input
void ABaseCharacter::SetupPlayerInputComponent(UInputComponent* PlayerInputComponent)
{
	Super::SetupPlayerInputComponent(PlayerInputComponent);

}

void ABaseCharacter::InitializeAbility(TSubclassOf<UGameplayAbility> AbilityToGet, int32 AbilityLevel)
{
	if (AbilitySystemComp) {
		if (HasAuthority() && AbilityToGet) {
			//返回能力的句柄，用以激活
			AbilitySystemComp->GiveAbility(FGameplayAbilitySpec(AbilityToGet, AbilityLevel, 0));
		}

		//初始化能力的用户信息，主要是逻辑用户和物理用户
		//逻辑用户：控制这个能力的（逻辑上拥有这个组件的）
		//物理用户：这个能力控制的（物理上我们正在acting on 的角色）
		AbilitySystemComp->InitAbilityActorInfo(this, this);
	}
}

UAbilitySystemComponent* ABaseCharacter::GetAbilitySystemComponent() const
{
	return AbilitySystemComp;
}

void ABaseCharacter::GetHealthValues(float& Health, float& MaxHealth)
{
	Health = BaseAttributeSetComp->GetHealth();
	MaxHealth = BaseAttributeSetComp->GetMaxHealth();
}

void ABaseCharacter::GetManaValues(float& Mana, float& MaxMana)
{
	Mana = BaseAttributeSetComp->GetMana();
	MaxMana = BaseAttributeSetComp->GetMaxMana();
}

void ABaseCharacter::GetStaminaValues(float& Stamina, float& MaxStamina)
{
	Stamina = BaseAttributeSetComp->GetStamina();
	MaxStamina = BaseAttributeSetComp->GetMaxStamina();
}

//当属性改变时，使用的结构体
void ABaseCharacter::OnHealthChangedNative(const FOnAttributeChangeData& Data)
{
	OnHealthChanged(Data.OldValue, Data.NewValue);
}

void ABaseCharacter::OnManaChangedNative(const FOnAttributeChangeData& Data)
{
	OnManaChanged(Data.OldValue, Data.NewValue);
}

void ABaseCharacter::OnStaminaChangedNative(const FOnAttributeChangeData& Data)
{
	OnStaminaChanged(Data.OldValue, Data.NewValue);
}
```

![image-20210608180403689](GAS.assets\image-20210608180403689.png)



# Pt3

对**默认的人体模型BP1**，将其**类设置**中的父类设置成我们的自定义`character`，然后我下载了两个模型导入，它们是主角和敌人，都继承了这个**默认的人体模型BP1**。

因为继承了我们的角色类，所以会有`Ability System Comp`，在其细节面板`attribute test`模块新加一个`attribute set`：

![image-20210610144858744](GAS.assets\image-20210610144858744-1623307740434.png)

点击`Default Starting Table`，选择**数据表格**，

![image-20210610145015017](GAS.assets\image-20210610145015017.png)

![image-20210610145035399](GAS.assets\image-20210610145035399.png)

对生成的数据表格进行设置：

![image-20210610150102648](GAS.assets\image-20210610150102648.png)

新建一个UMG：

![image-20210610150202840](GAS.assets\image-20210610150202840.png)

![image-20210610151517426](GAS.assets\image-20210610151517426.png)

添加绑定：（重复下述过程）

![image-20210610151548218](GAS.assets\image-20210610151548218.png)

![image-20210610151752809](GAS.assets\image-20210610151752809.png)

打开`Player`的角色蓝图，添加：

![image-20210610152612921](GAS.assets\image-20210610152612921.png)

然后，将此角色设定为`player 0`，为了让**动画**正常，打开它对应的**动画蓝图**，添加修改：

![image-20210610153716079](GAS.assets\image-20210610153716079.png)

![image-20210610153804798](GAS.assets\image-20210610153804798.png)

新建一个`GameAbility`，首先我们应该将动画和模型分离，由`GA`来调用，所以修改角色的蓝图：（这里新建一个蒙太奇变量）

![image-20210610193421258](GAS.assets\image-20210610193421258.png)

主要是为了调用最右的节点，来触发`GA`，转到`GA`，由它控制**蒙太奇动画**：

![image-20210610193559423](GAS.assets\image-20210610193559423.png)

这个`GA`是攻击能力（普A+连招），所以击中敌人时，我们需要触发`GameEffect`：

![image-20210610193750446](GAS.assets\image-20210610193750446.png)

我们需要等待触发事件来通知（在我们攻击的时间内），但我们不能什么都触发，所以我们什么了一个`Tag`：

![image-20210610194007787](GAS.assets\image-20210610194007787.png)

通过最右的节点，或者逻辑思考，我们的能力触发了，肯定会有相应的效果，所以我们需要建立`GameEffect`：（扣敌人的血量，和自己的蓝条）

![image-20210610194155426](GAS.assets\image-20210610194155426.png)

这里告一段落，我们需要触发，所以，给**角色的武器**添加**碰撞体**和**触发函数**：

![image-20210610194324317](GAS.assets\image-20210610194324317.png)

![image-20210610194409875](GAS.assets\image-20210610194409875.png)

逻辑很简单：就是使用特殊的节点通知`GA`的`wait`节点（注意Tag要一致）。

> 按理来说，现在应该没问题了，但我实验的时候没反应，原因是作者的代码写错了？最起码给我们的信息是不全的，他在角色类里面给属性集加了`const`修饰符，这让`set`和`Init`调用不了，最起码我们不能在代码里面用（我不知道数据表初始化行不行），所以我将其改了。
>
> 第二个问题很隐蔽，最大值默认都是0，导致我们设置的时候，必须先设置最大值，再设置当前值才行。或者说，我们应该在属性集初始化的时候，对每个属性执行：设置最大值、设置当前值。

![image-20210610195025289](C:\Users\xueyaojiang\Desktop\JMX\ShaderToy\UnrealStudy\GAS系统\GAS.assets\image-20210610195025289.png)

现在没问题了。

然后我们需要设置能力消耗，这个比较特殊，`GA`自带了，或者说，在UE的逻辑中，任何特殊能力都是有代价的（钢之炼金术师？哈哈），所以我们对于代价效果的`GameEffect`，是这样设置的：

![image-20210610195258855](GAS.assets\image-20210610195258855.png)

然后触发也很简单，只要用了就消耗，我们直接在能力触发之处，就通知：

![image-20210610195346558](GAS.assets\image-20210610195346558.png)

现在我们一个普A，都会消耗一点能量！

那么，现在，我们其实可以发挥想象力了。我们可以设置各种补给包或者陷阱，一旦我们的主角触发了，那些补给或陷阱就会通知`GA`（不是我们之前那个攻击的，可以是这些特殊场景武自己的能力，比如叫做：GA_Touch），它就会对我们的角色附加我们定义的各种效果，例如：灼烧和回血（`GameEffect`仔细看面板，是可以设置延迟效果的哦！）。

> ps：还是不太熟练，以及教程出了错，**半小时的教程**，看了一下午，哎。

