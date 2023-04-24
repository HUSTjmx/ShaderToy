[toc]





# SD参数指南

## 1. CFG Scale

全称是**Classifier Free Guidance scale**，用于控制模型应该在多大程度上遵守我们的提示。

| Value |                                                          |
| ----- | -------------------------------------------------------- |
| 1     | Mostly ignore your prompt.                               |
| 3     | Be more creative.                                        |
| 7     | A good balance between following the prompt and freedom. |
| 16    | Adhere more to prompt                                    |
| 30    | Strictly follow the prompt.                              |

> 一般建议使用`7`
>
> <img src="SD基础.assets/cfg.png" alt="Stable Diffusion CFG scale parameters" style="zoom:50%;" />



## 2. 采样次数 Sampling steps

**质量**随着**采样次数**的增加而提高。通常使用**欧拉采样器**，20次就足以获得**高质量、清晰的图像**。虽然采样更多，图像仍然会发生微妙的变化——内容会变得不同，但不一定是更高的质量。

> 一般建议采样20次。如果怀疑质量较低，可以调整到更高的采用次数。
>
> <img src="SD基础.assets/steps.png" alt="Stable Diffusion sampling step size." style="zoom:50%;" />



## 3. 采样方法 Sampling methods

哪个方法产生的图片质量最好，使用哪一个方法，没有定式。但在时间上，不同的采用方法的复杂度是相对固定的：

<img src="SD基础.assets/image-16.png" alt="img" style="zoom:67%;" />

> 一般建议：20 steps with ==Euler==.



## 4. Seed

都是学计算机的，不用解释了。

> 设置为`-1`来进行探索，生成不同的图像。
>
> 设置为其他值，则固定结果，进行微调。



## 5. Other

| 参数          |                    |
| ------------- | ------------------ |
| Image size    | 图像大小           |
| Batch size    | 每次生成的图像数量 |
| Restore faces | 修复脸部           |



------



# CheckPoints模型

> 有很多漏洞，或者说很不学术，只是为了让我这种小白，可以有个浅显的理解和认知

==模型==`Models`，有时称为**检查点**（`checkpoint files`），是预训练的SD权重，用于生成一般或特定类型的图像。

一个模型能生成什么样的图像取决于**用来训练它们的数据**。如果训练数据中没有猫，模型将无法生成猫的图像。同样，如果只用猫的图像训练一个模型，它只会生成猫。



## 1. Fine-tuned models:star:

**微调**`Fine-tuning`是机器学习中的一种常见技术——它需要一个**在广泛数据集上训练的模型**，并在狭窄的数据集上进行训练。==经过微调的模型==将倾向于生成与我们的数据集相似的图像，同时保持**原始模型的多功能性**。

有三种方法来生成`fine-tuning methods`：

- Additional training：通过用我们**感兴趣的额外数据集**训练一个**基本模型**来实现的。例如，可以使用**额外的老爷车数据集**来训练`Stable Diffusion v1.5`，从而使**汽车的美学**偏向于老爷车。
- DeamBooth：最初由谷歌开发，是一种将**自定义主题**注入到`text-to-image models`的技术。这个技术可以只使用3-5个自定义主题的图像。用Dreambooth训练的模型需要**一个特殊的关键字**来调节模型。
- 文本反转`textual inversion`（也就是`embedding`）：其目标与`Dreambooth`类似，仅通过几个示例图像将**自定义主题**注入模型，并为新对象专门创建一个新关键字。在保持模型其余部分不变的同时，只对**文本嵌入网络**（` text embedding network`）进行微调。



## 2. 模型v1

有成千上万个微调过的SD模型，这个数字每天都在增加。以下是可用于一般用途的模型列表。

- [Stable diffusion v1.4](https://huggingface.co/CompVis/stable-diffusion-v-1-4-original/resolve/main/sd-v1-4.ckpt)：由Stability AI于2022年8月发布的v1.4模型被认为是第一个公开可用的稳定扩散模型。大多数情况下，使用它就足够了

- [Stable diffusion v1.5](https://huggingface.co/runwayml/stable-diffusion-v1-5/resolve/main/v1-5-pruned-emaonly.ckpt)：与`v1.4`相比，它产生的结果略有不同，但不清楚它们是否更好。与`v1.4`一样，可以将`v1.5`视为通用模型

- [F222](https://huggingface.co/acheong08/f222/blob/main/f222.ckpt)：`F222`最初是为生成裸体而训练的，有助于生成美丽的女性。有趣的是，它也很擅长制作美观的衣服。它很容易产生裸体（所以请在正面提示词中加入 `NFSW` 哦）。

- [Anything V3](https://huggingface.co/Linaqruf/anything-v3.0/resolve/main/anything-v3-fp16-pruned.safetensors)：一个特殊用途的模型，经过训练可以生成**高质量的动画风格图像**。一个缺点是（或许不是？），它产生的女性身材不成比例，可以用`F222`对它进行微调。

- [Open Journey](https://huggingface.co/prompthero/openjourney/resolve/main/mdjrny-v4.ckpt)：它具有不同的审美，是一个很好的通用模型。触发提示词：`mdjrny-v4 style`

- [DreamShaper](https://civitai.com/api/download/models/5636?type=Pruned%20Model&format=SafeTensor)：`Dreamshaper`模型是微调的**肖像插图风格**，画风处于现实和CG之间。

  <img src="SD基础.assets/image-11.png" alt="img" style="zoom:50%;" />

- [ChilloutMix](https://civitai.com/models/6424/chilloutmix)：`ChilloutMix`是一个特殊的模型，用于生成**照片质量的亚洲女性**。它就像亚洲版的`F222`。与`embedding` `ulzzang-6500-v1`一起使用，生成像k-pop一样的女孩。像`F222`一样，它有时也会生成裸体。

  <img src="SD基础.assets/Untitled.png" alt="img" style="zoom:25%;" />

- [Waifu-diffusion](https://huggingface.co/hakurei/waifu-diffusion)：日式动画风

  <img src="SD基础.assets/image-42.png" alt="img" style="zoom:25%;" />

- [Robo Diffusion](https://huggingface.co/nousr/robo-diffusion)：一个有趣的机器人风格的模型

  <img src="SD基础.assets/image-22.png" alt="img" style="zoom:25%;" />

- [Mo-di-diffusion](https://huggingface.co/nitrosocke/mo-di-diffusion)：皮克斯迪士尼风格。Use keywords: `modern disney style`

  <img src="SD基础.assets/image-23.png" alt="img" style="zoom:25%;" />

- [wlop model](https://huggingface.co/SirVeggie/wlop/resolve/main/wlop-any.ckpt)：鬼刀插画风格，有配套的[embedding](https://huggingface.co/datasets/Nerfgun3/wlop_style/resolve/main/wlop_style.pt)

  <img src="SD基础.assets/00567-964685456-wlop_style-_0.6-m_wlop_1.4-woman-wearing-dress-perfect-face-beautiful-detailed-eyes-long-hair-birds.png" alt="img" style="zoom:25%;" />

- [Inkpunk Diffusion](https://huggingface.co/Envvi/Inkpunk-Diffusion)：`Inkpunk Diffusion`是一个`dreambooth`训练的模型，具有非常独特的插图风格。Use keyword: `nvinkpunk`

  <img src="SD基础.assets/image-24.png" alt="img" style="zoom: 25%;" />



## 3. 模型v2

`Stability AI`发布了一系列新的模型v2。到目前为止，已经发布了2.0和2.1模型。v2模型的主要变化是：

- 除了512*512像素外，还提供更高分辨率的768\*768像素版本。
- 不能搞黄色了



## 4. 如何使用模型

将下载好的模型文件放在下列文件夹下：*stable-diffusion-webui/models/Stable-diffusion/*。



## 5. 混合两个模型:star:

![img](SD基础.assets/image-47.png)

如果要合并两个模型，请在**模型合并**页签，在**模型A**和**模型B**中选择需要合并的两个模型。通过调整倍率（`M`）来调整两个模型的相对权重。在按下`Run`后，新的合并模型将产生。

### 5.1 合并实例

以下是使用**倍率0.5**，来合并`F222`和`Anything V3`的示例图像：

<img src="SD基础.assets/image-20230422132948845-1682141390267-28.png" alt="image-20230422132948845" style="zoom: 50%;" />



## 6. 训练自己的CheckPoints

> [Todo](https://stable-diffusion-art.com/dreambooth/)



## 7. 其他模型类型

有四种主要类型的文件可以称为**模型**。为了防止混淆，我们需要理解各自的区别：

- **Checkpoint models**：这些是==真正的稳定扩散模型==。它们包含生成图像所需的所有内容，不需要额外的文件。它们很大，通常为2~7GB。（这就是本节我们所介绍的）
- **[Textual inversions](https://stable-diffusion-art.com/embedding/)** (**embeddings**) ：它们是定义**新关键字**，来生成**新对象或样式**的小文件。它们很小，通常为10~100 KB。必须将它们与检查点模型一起使用。
- **LoRA models**：它们是检查点模型的**小补丁文件**，用于**修改样式**。它们通常为10~200mb。必须将它们与检查点模型一起使用。
- **[Hypernetworks](https://stable-diffusion-art.com/hypernetwork/)**：它们是添加到**检查点模型**中的**附加网络模块**。它们通常是5~300 MB。必须与检查点模型一起使用它们。



------



# 提示Prompts:star:

> Stable Diffusion内部存在一个名为`token`的对象，但注意，我们的提示词`word`和这个`token`并不一定是一一对应的关系，例如：SD不理解dreambeach这个提示词，会将其分为两个`token`，分别代表`dream`和`beach`

## 1. 提示的构成

关于提示的重要性，我想是不言而喻的。首先，我们需要了解一个好的提示，应该如何构建。有一些经过验证的技术可以生成**高质量的特定图像**。

### 1.1 主题内容Subject

> ==***The subject is what you want to see in the image***==

`Subject`是我们要生成图像的==主要内容==，我们是要绘制美少女，还是要绘制一个可爱的猫，她们在什么地方，又在做什么表情。

> 一个示例`Subject`：*Emma Watson as a powerful mysterious sorceress, casting lightning magic, detailed clothing*。
>
> <img src="SD基础.assets/04808-1220894852-Emma-Watson-as-a-powerful-mysterious-sorceress-casting-lightning-magic-detailed-clothing.png" alt="img" style="zoom:50%;" />

我们在书写`Subject`时，有一些简单的建议：

- 在描述`Subject`时要详细而具体。
- 使用括号`()`来增加其强度，或使用`[]`来减少其强度。
- 使用**名人的名字**来构建我们的`Subject`，可以得到**高质量结果**，但会**失去自由度**



### 1.2 绘画类别Medium

`Medium`定义了我们作品的类别，在视觉效果上，会呈现不同的艺术风格。常见的`Medium`有：

- **Portrait**：将图像集中在**面部/头像**上

- **Digital painting**：数字艺术
- **photograph**：照片风格
- **oil painting**：油画
- **Concept art**：插图风格，2D
- **Ultra realistic illustration**：**非常逼真的绘画，很适合用来画人**
- **Underwater portrait**：在画人的时候使用，模拟人在水中的表现，例如：头发会飘浮起来
- **Underwater steampunk**： *underwater with wash color*
- etc.

> 添加`Medium`：*Emma Watson as a powerful mysterious sorceress, casting lightning magic, detailed clothing, **digital painting***
>
> <img src="SD基础.assets/04810-340969114-Emma-Watson-as-a-powerful-mysterious-sorceress-casting-lightning-magic-detailed-clothing-digital-painting.png" alt="img" style="zoom:50%;" />



### 1.3 绘制风格Style

`Style`可以进一步完善**美术风格**。推荐的`Style`提示词有：

- **hyperrealistic**： 增加细节和分辨率 :star:
- **pop-art**： Pop艺术风格
- **Modernist**：色彩鲜艳，对比度高
- **art nouveau**：添加装饰和细节，建筑风格
- **full body**：全身像
- etc.

> 我们可以尝试混合`style`

> 加上hyperrealistic, fantasy, surrealist, full body：*Emma Watson as a powerful mysterious sorceress, casting lightning magic, detailed clothing, digital painting, **hyperrealistic, fantasy, Surrealist, full body***
>
> <img src="SD基础.assets/04821-3088755250-Emma-Watson-as-a-powerful-mysterious-sorceress-casting-lightning-magic-detailed-clothing-digital-painting-hyperrealistic-fa.png" alt="img" style="zoom:50%;" />





### 1.4 作者Artist

在提示词中提到艺术家会产生强烈的效果。我们研究他们的作品，根据我们的需要，做出明智的选择。下面给出一些有名的作者：

- **John Collier**： 9世纪肖像画家——似乎能给画面添加`elegancy`（优雅？）
- **Stanley Artgerm Lau**：强烈的**现实主义现代绘画**
- **Frida Kahlo**：继承了`Collier`的肖像风格，绘制风格更加独特——有时会导致**相框**`picture frame`
- **John Singer Sargent**：适合与**女子肖像**搭配使用，可以产生**19世纪的精致服装**，有些**印象派色彩**
- **Alphonse Mucha**：独特风格的2D肖像画
- etc.

关于`Artist`和`Medium`、`Style`，我们应该使用风格配套的，这样才能产生好的图像——`photograph`这种`Medium`就不应该和**梵高**配合在一起使用。

> 艺术家的名字是一个非常强大的风格修改器——明智地使用。

> *Emma Watson as a powerful mysterious sorceress, casting lightning magic, detailed clothing, digital painting, hyperrealistic, fantasy, Surrealist, full body, **by Stanley Artgerm Lau and Alphonse Mucha***
>
> <img src="SD基础.assets/04827-1484067991-Emma-Watson-as-a-powerful-mysterious-sorceress-casting-lightning-magic-detailed-clothing-digital-painting-hyperrealistic-fa.png" alt="img" style="zoom:50%;" />





### 1.5 网站Website

使用一个**图像网站**作为提示词，也会产生强大的效果——特别是那些拥有自己风格的网站，像`Artstation`和`Deviant Art`这样的小众图形网站。下面给出一些有名的网站：

- **pixiv**：日本动漫风格
- **pixabay**： Commercial stock photo style
- **artstation**：现代插画，幻想
- **Deviant Art**
- etc.

> *Emma Watson as a powerful mysterious sorceress, casting lightning magic, detailed clothing, digital painting, hyperrealistic, fantasy, Surrealist, full body, by Stanley Artgerm Lau and Alphonse Mucha, **artstation***
>
> <img src="https://i0.wp.com/stable-diffusion-art.com/wp-content/uploads/2023/02/04843-344447326-Emma-Watson-as-a-powerful-mysterious-sorceress-casting-lightning-magic-detailed-clothing-digital-painting-hyperrealistic-fa.png?resize=512%2C704&ssl=1" alt="img" style="zoom:50%;" />
>
> 这不是一个很大的变化，但图像看起来确实像在`Artstation`上看到的那样。



### 1.6 Resolution

不能简单理解为分辨率，这里直接给出大佬给的提示词：

- **unreal engine**：非常逼真和详细的3D画面
- **sharp focus**：增加分辨率
- **8k**：提高分辨率
- **vray**：3D rendering best for objects, landscape and building.

> *Emma Watson as a powerful mysterious sorceress, casting lightning magic, detailed clothing, digital painting, hyperrealistic, fantasy, Surrealist, full body, by Stanley Artgerm Lau and Alphonse Mucha, artstation, **highly detailed, sharp focus***
>
> <img src="SD基础.assets/04847-1108153948-Emma-Watson-as-a-powerful-mysterious-sorceress-casting-lightning-magic-detailed-clothing-digital-painting-hyperrealistic-fa.png" alt="img" style="zoom:50%;" />
>
> 也许不是很大的影响，因为之前的图像已经非常清晰和详细了，但补充一下也无妨。



### 1.7 Additional details

| keyword            | Note                                                         |
| ------------------ | ------------------------------------------------------------ |
| **dramatic**       | 增加面部的情感表现力。整体上大幅增加照片的潜力/可变性`variability` |
| **silk**           | 在衣服上添加丝绸                                             |
| **expansive**      | 背景更开阔，`subject`更小                                    |
| **low angle shot** | 从低角度拍摄                                                 |
| **god rays**       | 破云而出的阳光                                               |
| **psychedelic**    | 失真的鲜艳色彩                                               |

`Additional details`是为了修改图像而添加的**甜味剂**`sweeteners`。

> *Emma Watson as a powerful mysterious sorceress, casting lightning magic, detailed clothing, digital painting, hyperrealistic, fantasy, Surrealist, full body, by Stanley Artgerm Lau and Alphonse Mucha, artstation, highly detailed, sharp focus, **sci-fi, stunningly beautiful, dystopian***
>
> <img src="SD基础.assets/04864-2405740094-Emma-Watson-as-a-powerful-mysterious-sorceress-casting-lightning-magic-detailed-clothing-digital-painting-hyperrealistic-fa.png" alt="img" style="zoom:50%;" />



### 1.8 色彩Color

可以通过添加**颜色关键字**来控制**图像的整体颜色**——指定的颜色可以显示为色调或对象的主体颜色。

- **iridescent gold**：金色
- **silver**：银色
- **vintage**：年代感

> *Emma Watson as a powerful mysterious sorceress, casting lightning magic, detailed clothing, digital painting, hyperrealistic, fantasy, Surrealist, full body, by Stanley Artgerm Lau and Alphonse Mucha, artstation, highly detailed, sharp focus, sci-fi, stunningly beautiful, dystopian, **iridescent gold***
>
> <img src="SD基础.assets/04889-2937046758-Emma-Watson-as-a-powerful-mysterious-sorceress-casting-lightning-magic-detailed-clothing-digital-painting-hyperrealistic-fa.png" alt="img" style="zoom: 50%;" />



### 1.9 光影Lighting

`Lighting`可以对图像的外观产生巨大的影响。让我们在提示词中添加电影般的灯光和黑暗。

> *Emma Watson as a powerful mysterious sorceress, casting lightning magic, detailed clothing, digital painting, hyperrealistic, fantasy, Surrealist, full body, by Stanley Artgerm Lau and Alphonse Mucha, artstation, highly detailed, sharp focus, sci-fi, stunningly beautiful, dystopian, iridescent gold, **cinematic lighting, dark***
>
> <img src="SD基础.assets/04912-3838184885-Emma-Watson-as-a-powerful-mysterious-sorceress-casting-lightning-magic-detailed-clothing-digital-painting-hyperrealistic-fa.png" alt="img" style="zoom: 50%;" />



## 2. 负面提示词 Negative prompt

使用**负面提示**是引导图像生成的另一个好方法，但不是放进想要的东西，而是放进不想要的东西。它们可以是物体，也可以是样式和不需要的属性——例如，`ugly`，`deformed`。

负面提示词一般是通用的，例如：*ugly, tiling, poorly drawn hands, poorly drawn feet, poorly drawn face, out of frame, extra limbs, disfigured, deformed, body out of frame, bad anatomy, watermark, signature, cut off, low contrast, underexposed, overexposed, bad art, beginner, amateur, distorted face, blurry, draft, grainy*

> <img src="SD基础.assets/04965-4275528308-Emma-Watson-as-a-powerful-mysterious-sorceress-casting-lightning-magic-detailed-clothing-digital-painting-hyperrealistic-fa.png" alt="img" style="zoom:50%;" />



### 2.1 如何使用负面提示词:star:

:one:第一个明显的用法是删除不想在图像中看到的内容。具体例子见[How to use negative prompts?](https://stable-diffusion-art.com/how-to-use-negative-prompts/)。

:two:用**负面提示**做**细微的改变** ——不需要删除任何东西，只需要对`subjects`做一些细微的改变。

有时候使用负面提示词也无法完全满足我们的要求，甚至随着强度提示，图像会发生剧烈变化，如下所示：当ear的强度指定为`1.9`时，整个图像的构成都发生了变化，这显然不是我们想要的。

<img src="SD基础.assets/image-20230421180711174.png" alt="image-20230421180711174" style="zoom:67%;" />

我们怎么能避免图像变化呢？一个小窍门是使用==提示词迭代技术==：首先使用**无意义的单词**作为**否定提示**，然后在后面的采样步骤切换到(ear:1.9)，例如：*[the: (ear:1.9): 0.5]*。

> 这背后的原因是**扩散过程**在开始阶段是最重要的。后面的步骤只是对细节进行更精细的调整，比如**毛发覆盖耳朵**。
>
> <img src="SD基础.assets/image-13.png" alt="img" style="zoom:67%;" />

:three:用**负面提示词**来改变风格。在**正面提示词**中添加太多，可能会**混淆扩散器**，导致描述的泛化——本来我们使用提示词就是为了约束AI的想象，但提示词过多会导致**约束混乱**。



### 2.2 通用的负面提示词

- ugly, disfigured, deformed （丑陋，毁容，畸形）
- underexposed, overexposed（曝光不足、曝光过度）
- low contrast（低对比度）
- 一个流行的通用负面提示词：*ugly, tiling, poorly drawn hands, poorly drawn feet, poorly drawn face, out of frame, extra limbs, disfigured, deformed, body out of frame, blurry, bad anatomy, blurred, watermark, grainy, signature, cut off, draft* （丑陋，平纹，画得不好的手，画得不好的脚，画得不好的脸，画框外，多余的四肢，毁容，变形，身体画框外，模糊，糟糕的解剖结构，模糊，水印，颗粒状，符号，剪切，草稿）
- `blurry, blurred, grainy, draft` 这些会改变图像风格的负面提示词要谨慎使用
- 因此，==一个更好的通用负面提示词==是：*ugly, tiling, poorly drawn hands, poorly drawn feet, poorly drawn face, out of frame, extra limbs, disfigured, deformed, body out of frame, bad anatomy, watermark, signature, cut off, low contrast, underexposed, overexposed, bad art, beginner, amateur, distorted face*



## 3. 构建高质量的提示词

### 3.1 迭代构建

我们可以把**提示词的构建**看作一个**迭代的过程**：

1. 从一个只有`subject`、`medium`和`style`的简单提示开始
2. 每次至少生成4张图片，看看能得到什么
3. 效果没达标，则添加最多2个提示词，生成4张图片，看看能得到什么
4. 效果没达标，继续3，否则结束。



### 3.2 使用负面提示词

我们可以使用一个通用的负面提示。这些提示词可以是你想避免的物体或身体部位。例如，**手的绘制**存在明显Bug时，我们可以在**负面提示词**中加入`Hand`。

> **负面提示词**在很多时候是**不可缺少的**，可以从这个[例子](https://stable-diffusion-art.com/how-negative-prompt-work/)中看出。





## 4. 提示词技术 Prompting techniques

### 4.1 提示词权重

我们可以通过语法（提示词：因子）来调整**提示词的权重**。因子是一个值，小于1表示不太重要，大于1表示比较重要。

> **dog**, autumn in paris, ornate, beautiful, atmosphere, vibe, mist, smoke, fire, chimney, rain, wet, pristine, puddles, melting, dripping, snow, creek, lush, ice, bridge, forest, roses, flowers, by stanley artgerm lau, greg rutkowski, thomas kindkade, alphonse mucha, loish, norman rockwell.
>
> ![image-20230421150141633](SD基础.assets/image-20230421150141633.png)



### 4.2 () and []

调整提示词强度的一个等效方法是使用`()`和`[]`。(keyword)将提示词的强度增加1.1倍，与(keyword:1.1)相同。[keyword] 将强度降低0.9倍，与(keyword:0.9)相同。我们也可以嵌套使用，其效果是乘法。

> (keyword): 1.1
>
> ((keyword)): 1.21
>
> (((keyword))): 1.33



### 4.3 混合和迁移

==提示词混合==可以用来混合两个描述同一对象的提示词要素，例如：*white|yellow flower*，会生成黄色和白色混合的花。

==提示词迁移==则是连续生成具有多个不同特征的对象，不断迁移，例如：[white|red|bule] flower，会先生成白花，再生成红花，再生成蓝花。



### 4.4 提示词迭代

你可以混合两个关键词，其语法是：

> [keyword1 : keyword2: factor]

例如，我们使用：*Oil painting portrait of [Joe Biden: Donald Trump: 0.5]*，进行30次采样，前15次是：*Oil painting portrait of Joe Biden*；后15次是：*Oil painting portrait of Donald Trump*。

<img src="SD基础.assets/image-20230421151417655.png" alt="image-20230421151417655" style="zoom:67%;" />

我们注意到**特朗普**身穿白色西装，这更像是**拜登**的打扮。这是一个完美的例子，说明了提示词混合的==一个非常重要的规则==： 第一个提示词决定了**全局的构成**——早期的扩散步骤设定了整体构图；后期的步骤（第二个提示词）则完善了细节。



## 5. 关联效应

### 5.1 属性关联

有些属性是==强相关的==——当你指定了一个，你就会得到另一个。假设我们想生成**蓝眼睛的女人**的照片：*a young female with **blue eyes**, highlights in hair, sitting outside restaurant, wearing a white outfit, side light*。

<img src="SD基础.assets/image-20230421153747105.png" alt="image-20230421153747105" style="zoom:67%;" />

如果我们改成**棕色眼睛**呢？

<img src="SD基础.assets/image-20230421153822542-1682062704451-36.png" alt="image-20230421153822542" style="zoom:67%;" />

在提示的任何地方，都没有指明**种族**。但是因为有蓝眼睛的人主要是欧洲人，所以生成了白种人。棕色眼睛在不同种族中更常见，所以你会看到一个更多样化的种族样本。

> 刻板印象和偏见是人工智能模型的一个大话题



## 5.2 名人姓名的关联

每个提示词都有一些无意的联想。对于名人的名字来说，这一点尤其明显。一些演员在拍照时喜欢摆出某些姿势或穿上某些衣服，因此在训练数据中也是如此——如果Taylor（在训练数据中）总是翘着二郎腿，模型也会认为翘二郎腿的就是Taylor。

<img src="SD基础.assets/image-20230421154140660-1682062902414-38.png" alt="image-20230421154140660" style="zoom: 67%;" />

==姿势和装着==是全局性的构成。如果你想要她的脸，但不想要她的姿势，你可以在以后的取样步骤中使用关键词混合来把她换进来，例如：[Trump:Taylor swift:0.1]



### 5.3 艺术家的关联

19世纪捷克画家Alphonse Mucha在**肖像生成**中是一个很受欢迎的提示词，因为这个名字有助于产生有趣的点缀，而且他的风格与**数字插图**融合得非常好，但它也经常在背景中留下标志性的**圆形或圆顶形图案**。

<img src="SD基础.assets/image-20230421154517612-1682063119991-40.png" alt="image-20230421154517612" style="zoom:67%;" />



## 6.  Embedding are keywords

嵌入物`Embeddings`，是**文本反转**的结果，是提示词的组合。

`Style-Empire`是常用的一个嵌入物，因为它能为**人像图像**添加暗色调，并创造有趣的照明效果。由于它是在有夜间街景的图片上训练的，我们可以使用它增加一些黑色，也许还有建筑物和街道。



## X. Nenly的提示词笔记

- 提示词类别

  - 内容型提示词![img](https://api2.mubu.com/v3/document_image/b2b31116-f792-4be6-a1a8-4260b45c459f-3233270.jpg)

  - 标准化提示词![img](https://api2.mubu.com/v3/document_image/e1fd8e34-8e35-42ce-b11a-962526ba1168-3233270.jpg)

- 提示词语法

  - 权重（优先级）增减![img](https://api2.mubu.com/v3/document_image/beb5ad55-8b10-4595-aead-4ea66e89eac8-3233270.jpg)

- 书写提示词的模版

  - 通用模版<img src="SD基础.assets/49fd065e-b6c6-44a2-bdb6-2536a58a10bf-3233270.jpg" alt="img" style="zoom:200%;" />

- 借助工具

  - 利用提示词工具，以“选取”的方式完成提示词撰写

    - 一个工具箱：http://www.atoolbox.net/Tool.php?Id=1101

    - AI词语加速器：https://ai.dawnmark.cn/

  - 不要被已有的词条限制了思维

- 抄作业

  - 参考一些模型网站的例图与提示词记录网站的成品

    - OpenArt：https://openart.ai/

    - ArtHubAi：https://arthub.ai/

  - 按照需要参考内容/标准化提示词




# 采样器Samplers

> 详见[如何选取采样器](https://stable-diffusion-art.com/samplers/)
>
> 如果想要深入了解，阅读 [“How does Stable Diffusion work?”](https://stable-diffusion-art.com/how-stable-diffusion-work/) 

## 1. 什么是采样器

为了生成图像，`Stable Diffusion`首先在潜在空间中生成一个完全随机的图像，然后 **noise predictor** 估计图像的噪声，从图像中减去预测的噪声，这个过程要重复十几次。最后，你会得到一个干净的形象。

![denoising steps](SD基础.assets/image-84.png)

这个去噪过程被称为采样` sampling`，因为`Stable Diffusion`在每一步都会产生一个新的样本图像。用于采样的方法称为**采样器**或**采样方法**。

> 下面是一个实际的采样过程，采样器逐渐产生越来越清晰的图像：
>
> <img src="SD基础.assets/cat_euler_15-1682314579463-5.gif" alt="stable diffusion euler" style="zoom:50%;" />



## 2. 采样器前瞻

目前有19个采样器可供我们选择，我们依次进行讲解。

### 2.1 老式的ODE求解器

一些采样器是一百多年前发明的，它们是**常微分方程**(ODE)的` old-school solvers`：

- **Euler**：最简单的求解器
- **Heun**：一个**更精确**但更慢的欧拉版本
- **LMS** (Linear multi-step method)：和欧拉一样的速度，但**更准确**



### 2.2 Ancestral samplers

名字中带有`a`的采样器都是：`ancestral samplers`——Euler a、DPM2 a、DPM++ 2S a、DPM++ 2S a Karras

**Ancestral采样器**在每个采样步骤向图像中**添加噪声**。使用**Ancestral采样器**的缺点是==图像不会收敛==。

| **Euler a**                                                  | **Euler**                                                    |
| ------------------------------------------------------------ | ------------------------------------------------------------ |
| ![img](https://i0.wp.com/stable-diffusion-art.com/wp-content/uploads/2023/03/euler-a-2-40.gif?resize=512%2C512&ssl=1) | ![img](https://i0.wp.com/stable-diffusion-art.com/wp-content/uploads/2023/03/euler-2-40.gif?resize=512%2C512&ssl=1) |

用**Euler a**生成的图像在高采样步长时不收敛。相反，来自**Euler**的图像收敛得很好。

> 所以，我感觉还是少用**Ancestral采样器**，哪怕是为了复现结果



### 2.3 Karras noise schedule

标签为Karras的采样器使用 [Karras article](https://arxiv.org/abs/2206.00364)中推荐的**噪声时间表**（`noise schedule`）。==这种采样器可以提高图像的质量==。

<img src="SD基础.assets/image-102.png" alt="img" style="zoom:67%;" />



### 2.4 DDIM and PLMS

**DDIM**（去噪扩散隐式模型，Denoising Diffusion Implicit Model）和**PLMS**（伪线性多步骤方法，Pseudo Linear Multi-Step method）是原始的[Stable Diffusion v1](https://github.com/CompVis/stable-diffusion)附带的采样器。**DDIM**是最早为扩散模型设计的采样器之一，**PLMS**是**DDIM**的更新和更快的替代品。



### 2.5 DPM and DPM++

**DPM**（扩散概率模型求解器，Diffusion probabilistic model solver）和**DPM++**是针对2022年发布的扩散模型设计的新采样器。它们代表了一组具有类似架构的求解器。

**DPM**和**DPM2**相似，但**DPM2**是二阶的，==更准确但更慢==。**DPM++**是对**DPM**的改进。

**DPM adaptive**自适应调整步长，它可能很慢，因为它不能保证在采样步骤数内完成。



### 2.6 UniPC

[UniPC](https://unipc.ivg-research.xyz/)是2023年发布的新采样器。受**ODE求解器**中的预测校正方法的启发，该方法可以==在5-10步内实现高质量的图像生成==。



### 2.7 k-diffusion

它只是指Katherine Crowson的 [k-diffusion](https://github.com/crowsonkb/k-diffusion) GitHub库和**与之相关的采样器**。该库实现了Karras 2022文章中研究的采样器。

> 基本上，AUTOMATIC1111中除了DDIM, PLMS和UniPC之外的所有采样器都是从 [k-diffusion](https://github.com/crowsonkb/k-diffusion) 中来的。



## 3. 如何选取采样器

### 3.1 图像融合Image Convergence

> 实验过程和分析见[如何选取采样器](https://stable-diffusion-art.com/samplers/)

![img](SD基础.assets/image-113.png)



### X. 使用建议

1. 如果想使用一些快速、融合、新颖、质量不错的东西，那么很好的选择是：
   - **DPM++ 2M Karras**：20~30 steps
   - **UniPC**：20~30 steps
2. 如果想要**高质量的图像**，而不关心收敛，好的选择是：
   - **DPM++ SDE Karras**：8~12 steps
   - **DDIM**：10~15 steps
3. 如果喜欢稳定的、可复制的图像，请避免使用任何ancestral  samplers
4. 如果喜欢简单的东西，**Euler**和**Heun**是不错的选择
   - 使用**Heun**时，可以减少迭代次数，以节省时间







# InPainting技术

`Inpainting`是一种用来**修补图像小缺陷**的方法。

## 1. 基本的InPainting

> 将使用一个实例来进行说明

首先，我们使用提示词：*[emma watson: amber heard: 0.5], (long hair:0.5), headLeaf, wearing stola, vast roman palace, large window, medieval renaissance palace, ((large room)), 4k, arstation, intricate, elegant, highly detailed*，来生成一个初始图像。

<img src="SD基础.assets/01644-3083470266-emma-watson_-amber-heard_-0.5-long-hair_0.5-headLeaf-wearing-stola-vast-roman-palace-large-window-medieval-renaissan.png" alt="img" style="zoom:50%;" />

这是一个很好的图像，但我想解决以下问题：

- 脸看起来不自然
- 右臂不见了

### 1.1 使用inpainting模型

对于`Inpainting`模型，我们可以有两种采纳方案：

- 一个专门用于`Inpainting`的 [Stable Diffusion model](https://huggingface.co/runwayml/stable-diffusion-inpainting)
- 使用生成图像的checkpoint模型（即使用这个模型生成图像，也用它来作为`Inpainting`模型）

> 对于`Inpainting`模型，我们吧把它放在：stable-diffusion-webui/models/Stable-diffusion



### 1.2 创建inpaint蒙版

在`AUTOMATIC1111 GUI`中，选择**`img2img`选项卡**，并选择**`Inpaint`子选项卡**。将图像上传到画布上：

<img src="SD基础.assets/image-6.png" alt="inpainting canvas" style="zoom:67%;" />

我们将同时在**右臂和脸**上进行`Inpainting`。使用**画笔工具**创建一个蒙版`mask`——这是我们想要`SD`来重新生成图像的区域。

<img src="SD基础.assets/image-7.png" alt="img" style="zoom: 67%;" />



### 1.3 InPainting设置:star:

- **提示词**：可以重用**原来的提示**来修复缺陷——这就像在一个特定区域生成多个图像一样。
- **图像大小**：需要将图像大小调整为与原始图像相同
- **面部修复**：如果正在绘制人脸，我们可以打开**面部修复**。（注意这个选项可能会产生不自然的外观。它还可能生成与模型风格不一致的内容。）
- **遮罩内容**`Mask Content`：如果我们希望**重绘结果**以原始内容的颜色和形状为指导，请选择`original`
  - 在大多数情况下，将使用`Original`和改变**重绘幅度**`denoising strength`，来达到不同的效果。
  - 如果想再生一些**与原始内容完全不同的东西**，可以使用==潜变量噪声==或==潜变量值零==，例如切除肢体或隐藏一只手。
- **重绘幅度**`denoising strength`：重绘幅度控制着结果与原始图像相比会有多大的变化。当你把它设为`0`时，什么都不会改变；将其设置为`1`时，将获得一个不相关的`inpainting`。`0.75`是一个建议值。
- **批次数量**`Batch size`：确保一次生成几个图像，以便可以选择最好的图像。将种子设置为-1，这样每个图像都是不同的。
- **重绘区域**：重绘大面积区域时选择**全图**，重绘小面积区域时选择**仅蒙版**

<img src="SD基础.assets/image-20230422121933182-1682137176615-7.png" alt="image-20230422121933182" style="zoom:67%;" />



### 1.4 迭代

重复上诉过程，直到结果满足我们的要求。

<img src="SD基础.assets/tmp77hnb1kr.png" alt="img" style="zoom: 67%;" />





## 2. 添加新的对象

我们想给图像添加一些新的东西。让我们尝试在图片中添加**一个扇子**。首先，将图像上传到画布上，并在**胸部和右臂**周围创建一个遮罩。在**原始提示的开头**添加**手持风扇的提示**。提示词为：*(holding a hand fan: 1.2), [emma watson: amber heard: 0.5], (long hair:0.5), headLeaf, wearing stola, vast roman palace, large window, medieval renaissance palace, ((large room)), 4k, arstation, intricate, elegant, highly detailed*。

向**原始提示**添加**新对象的提示**可以确保样式的一致性。我们可以调整提示字权重（`1.2`以上），使扇子显示。将遮罩内容设置为==潜变量噪声==。调整**重绘幅度**和`CFG`比例，以微调所绘制的图像。经过反复实验，结果如下：

<img src="SD基础.assets/image-13-1682137626551-9.png" alt="img" style="zoom: 67%;" />



## 3. 探索Inpainting参数

**遮罩内容**控制**遮罩区域的初始化方式**：

- 填充：用高度模糊的原始图像进行全局重绘。
- 原图：Unmodified。
- 潜变量噪声：用`fill`方法初始化遮罩区域，并在`latent space`中加入随机噪声。
- 潜变量数值零：：用`fill`方法初始化遮罩区域，不添加噪声。

下面是四个方法各自在采样之前的**初始掩码内容**：

<img src="https://i0.wp.com/stable-diffusion-art.com/wp-content/uploads/2022/11/image-10.png?resize=750%2C708&ssl=1" alt="img" style="zoom:67%;" />



## 4. inpainting技巧

- 一次只重绘一个小区域
- 在90%的情况下，将**遮罩内容**设置为`Original`（原图），并调整**重绘幅度**。
- 也可以试试其他的遮罩内容选项，看看哪个最好。
-  直接使用`PS`也是个不错的选择



## 5. 实战教程

[Inpainting修复多余肢体](https://stable-diffusion-art.com/inpainting-remove-extra-limbs/)

[Inpainting抠图](https://stable-diffusion-art.com/how-to-remove-a-person-with-ai-inpainting/)

[Inpainting换衣]()



------

# LoRA模型

## 1. 什么是LoRA

==LoRA模型==是**小型的稳定扩散模型**，它对**标准checkpoint模型**进行微小的更改。它们通常比检查点模型小`10`到`100`倍。

**LoRA (Low-Rank adaptive)**是一种用于微调**SD模型**的训练技术。但我们已经有了`Dreambooth`和`Embedding`等技术。`LoRA`有什么用？`LoRA`在文件大小和训练能力之间提供了一个很好的权衡：`Dreambooth`功能强大，但会产生较大的模型文件(2~7gb)；Embedding很小(大约100kb)，但功能受限。

与`Embedding`一样，我们不能单独使用LoRA模型，必须与checkpoint模型一起使用。LoRA通过对**附带的模型文件**应用**微小的更改**，来修改样式。



## 2. LoRA库

[Civitai](https://civitai.com/)拥有大量的LoRA模型。hugs Face是LoRA库的另一个来源



## 3. 如何使用LoRA

要使用LoRA模型，请在提示符中输入以下短语：**\<lora:filename:multiplier>**。`filename`是LoRA模型的文件名，不包括扩展名(`.pt`， `.bin`等)；`multiplier`是应用于LoRA模型的**权重**，默认为`1`，将其设置为`0`禁用模型。如何确定文件名是正确的？我们应该单击**模型按钮**，而不是编写这个短语。

<img src="SD基础.assets/image-20230422211316611.png" alt="image-20230422211316611" style="zoom:67%;" />

一些LoRA模型是用`Dreambooth`训练的。我们需要使用**触发器关键字**来使用LoRA模型——可以在模型页面上找到**触发器关键字**。与`Embedding`类似，我们可以同时使用多个LoRA模型，也可以将它们与`Embedding`一起使用。



## 4. 推荐的LoRA

:one:我们使用 [Guo Feng](https://civitai.com/models/10415)这个大模型和[Shukezouma LoRA](https://civitai.com/models/12597/moxin)，可以绘制出中国水墨画主题，触发关键词：**shukezouma**

> **Prompt**：(shukezouma:0.5) ,\<lora:Moxin_Shukezouma:1> , chinese painting, half body, female, perfect symmetric face, detailed chinese dress, mountains, flowers, 1girl, tiger
>
> **Negative Prompt**：disfigured, ugly, bad, immature
>
> <img src="SD基础.assets/image-189.png" alt="img" style="zoom:50%;" />

:two:我们使用[AbyssOrangeMix2 model](https://civitai.com/models/4437/abyssorangemix2-sfw)和[Akemi Takada LoRA](https://civitai.com/models/5737/akemi-takada-1980s-style-lora)。==高田明美==是一位日本漫画插画家。如果你喜欢20世纪80年代和90年代的日本动漫，这是个不错的选择。

> **Prompt**：takada akemi, Tifa lockhart as magician, Final Fantasy VII, 1girl, small breast, beautiful eyes, brown hair, smiling, red eyes, highres, diamond earring, long hair, side parted hair, hair behind ear, upper body, stylish dress, indoors, bar 1980s (style), painting (medium), retro artstyle, watercolor (medium) \<lora:akemiTakada1980sStyle_1:0.6>
>
> **Negative prompt**：(worst quality, low quality:1.4), (painting by bad-artist-anime:0.9), (painting by bad-artist:0.9), watermark, text, error, blurry, jpeg artifacts, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, artist name, bad anatomy
>
> <img src="SD基础.assets/image-195.png" alt="img" style="zoom:50%;" />

:three:使用 [Anything v4.5 model](https://huggingface.co/andite/anything-v4.0/blob/main/anything-v4.5.ckpt)和[Cyberpunk 2077 Tarot card LoRA](https://civitai.com/models/6628/cyberpunk-2077-tarot-card-512x1024)。这种LoRA模型产生具有未来主义赛博朋克风格的机器人和城市。

> **Prompt**：cyberpunk, tarot card, close up, portrait, bionic body, cat, young man, perfect human symmetric face, leather metallic jacket, circuit, city street in background, natural lighting, masterpiece \<lora:cyberpunk2077Tarot_tarotCard512x1024:0.6>
>
> **Negative prompt**：(worst quality, low quality:1.4), (painting by bad-artist-anime:0.9), (painting by bad-artist:0.9), watermark, text, error, blurry, jpeg artifacts, cropped, worst quality, low quality, normal quality, jpeg artifacts, signature, watermark, username, artist name, bad anatomy, big breast
>
> <img src="SD基础.assets/image-1682169935689-5.png" alt="img" style="zoom:50%;" />



## 5. 如何训练自己的LoRA库

- [stable diffusion打造自己专属的LORA模型](https://www.cnblogs.com/wangiqngpei557/p/17301360.html)
- [Stable Diffusion Lora训练定制角色（二次元向）](https://zhuanlan.zhihu.com/p/616500728)



# ControlNet模型

**ControlNet**是一个`stable diffusion model`，==可以复制构图和人体姿势==。经验丰富的SD用户知道生成想要的确切姿势有多难。**ControlNet**解决了这个问题，它功能强大，用途广泛，可以与任何稳定的扩散模型一起使用。



## 1. 什么是ControlNet模型

`ControlNet`是一个==改进的稳定扩散模型==。稳定扩散模型最基本的形式是`text-to-image`——它使用文本提示作为控制图像生成的条件。`ControlNet`又增加了一个条件。以两个ControlNet为例子：**边缘检测**和**人体姿态检测**。



### 1.1 Edge detection

在下面的工作流程中，**ControlNet**需要一个额外的输入图像，并使用**Canny边缘检测器**检测其轮廓——检测到的边缘被保存为**控制图**`control map `，然后作为文本提示之外的额外条件输入**ControlNet模型**。

![Stable Diffusion ControlNet model workflow.](SD基础.assets/openpose-workflow.jpg)

从输入图像中提取特定信息（在这种情况下是边缘）的过程称为**注释**`annotation`（在研究文章中）或**预处理**`preprocessing`（在**ControlNet扩展**中）。



### 1.2 Human pose detection

**边缘检测**并不是图像预处理的唯一方法。 [Openpose](https://github.com/CMU-Perceptual-Computing-Lab/openpose) 是一个快速的**keypoint detection**模型，可以提取人体姿势，如手、腿和头的位置。

下面是使用`OpenPose`的**ControlNet工作流程**。使用`OpenPose`从输入图像中提取关键点，并保存为**包含关键点位置的控制图**，然后将其作为附加条件与文本提示一起馈送给`Stable Diffusion`。

![img](SD基础.assets/image-120.png)

使用**Canny边缘检测**和**Openpose**有什么区别？**Canny边缘检测**提取边缘的`subject`和`background`。它倾向于更忠实地诠释场景——你可以看到跳舞的男人变成了女人，但**轮廓和发型**都很相似。

**OpenPose**只检测**关键点**，因此图像生成更自由，但遵循原始姿态。在上面的例子中，它生成了一个女人跳起来，左脚指向侧面，不同于原始图像和Canny边缘的例子——原因是**OpenPose的关键点检测**没有指定**脚的方向**。



## 2. 可用的ControlNet模型

### 2.1 OpenPose detector

[OpenPose](https://github.com/CMU-Perceptual-Computing-Lab/openpose) 检测人体关键点，如头部、肩膀、手等的位置。它对模仿人体姿势很有效果，但不能模仿服装、发型和背景等其他细节。

![img](SD基础.assets/image-131.png)



### 2.2 Canny edge detector

[Canny edge detector](https://en.wikipedia.org/wiki/Canny_edge_detector)是一个通用的边缘检测器。它提取图像的轮廓，有助于==保留原始图像的组成==。

![img](SD基础.assets/image-123.png)



### 2.3 Straight line detector

**ControlNet**可以与 [M-LSD](https://github.com/navervision/mlsd)（**Mobile Line Segment Detection**）一起使用，这是==一种快速的直线检测器==。它对于提取像室内设计、建筑、街景、相框和纸边这样的直边轮廓很有用。

![img](SD基础.assets/image-124.png)



### 2.4 HED edge detector

[HED (Holistically-Nested Edge Detection)](https://arxiv.org/abs/1504.06375) 是一种边缘检测器，擅长产生像真人一样的轮廓。==HED适用于重新着色和重新设计图像==。

![img](SD基础.assets/image-125.png)



### 2.5 Scribbles

Controlnet还可以把你涂鸦的东西变成图像

![img](SD基础.assets/image-126.png)



### 2.6 Other models

- [Human Pose](https://github.com/lllyasviel/ControlNet#controlnet-with-human-pose) ：Use OpenPose to detect keypoints.
- [Semantic Segmentation](https://github.com/lllyasviel/ControlNet#controlnet-with-semantic-segmentation)：Generate images based on a segmentation map extracted from the input image
- [Depth Map](https://github.com/lllyasviel/ControlNet#controlnet-with-depth) ：与Stable diffusion v2中的[depth-to-image](https://stable-diffusion-art.com/depth-to-image/)一样，ControlNet可以从输入图像中推断出深度图。ControlNet的深度图具有比Stable Diffusion v2更高的分辨率。
- [Normal map](https://github.com/lllyasviel/ControlNet#controlnet-with-normal-map)



## 3. 下载Stable Diffusion ControlNet

要安装**ControlNet扩展**，请转到**扩展选项卡**并选择**可用子选项卡**，按Load from按钮：

![img](https://i0.wp.com/stable-diffusion-art.com/wp-content/uploads/2023/02/image-112.png?resize=750%2C218&ssl=1)

在新出现的列表中，找到扩展名为`sd-web -controlnet`的扩展安装：

![img](SD基础.assets/image-113-1682318024161-25.png)

如果扩展成功安装，将在**txt2img选项卡**中看到一个名为**ControlNet的新可折叠部分**——它应该在Script下拉菜单的正上方。

![img](SD基础.assets/image-115.png)



### 3.1 下载ControlNet Models

ControlNet的作者已经发布了一些预训练的ControlNet模型，可以在[this page](https://huggingface.co/lllyasviel/ControlNet/tree/main/models)找到。web社区拥有半精确版本的ControlNet模型，这些模型具有较小的文件大小。它们下载速度更快，也更容易存储——可以在 [here](https://huggingface.co/webui/ControlNet-modules-safetensors/tree/main)找到它们。

要使用这些模型，请下载模型文件并将它们放在扩展的模型文件夹中。模型文件夹的路径是：*stable-diffusion-webui/extensions/sd-webui-controlnet/models*

> 不需要下载所有模型，如果这是你第一次使用ControlNet，你可以下载[openpose model](https://huggingface.co/lllyasviel/ControlNet/blob/main/models/control_sd15_openpose.pth).。



## 4. 使用ControlNet Models

展开**ControlNet面板**：

<img src="SD基础.assets/image-116.png" alt="img" style="zoom:50%;" />

我将使用下面的图片展示如何使用**ControlNet**。可以[下载图像](https://stable-diffusion-art.com/wp-content/uploads/2023/02/controlNet_demo_image.jpg)以遵循本教程。

![img](SD基础.assets/controlNet_demo_image.jpg)



### 4.1 Text-to-image settings

**ControlNet**将需要与**稳定扩散模型**一起使用，选择[v1-5-pruned-emaonly.ckpt](https://stable-diffusion-art.com/models/#Stable_diffusion_v15)。

在txt2image选项卡中，编写**正面提示词**：*full-body, a young female, highlights in hair, dancing outside a restaurant, brown eyes, wearing jeans*；编写负面提示词：*disfigured, ugly, bad, immature*。

设置图像生成的图像大小：我将使用$$512*776$$为演示图像。注意==，图像大小是在txt2img部分设置的，而不是在ControlNet部分设置的==。

<img src="SD基础.assets/image-128.png" alt="img" style="zoom:67%;" />



### 4.2 ControlNet settings

先将图像上传到画布，选中**启用复选框**：

<img src="SD基础.assets/image-129.png" alt="img" style="zoom:67%;" />

现在按`Generate`开始使用**ControlNet**生成图像。我们会看到按照**输入图像的姿态**生成的图像，最后一个图像是**预处理步骤的结果**。在本例中，它是检测到的关键点。

<img src="SD基础.assets/image-130.png" alt="img" style="zoom:67%;" />

这是使用ControlNet的基础知识！



## 5. ControlNet设置全解

### 5.1 输入控制Input controls

<img src="SD基础.assets/image-143.png" alt="img" style="zoom:67%;" />

**Invert input color**（反转输入颜色）：调换黑色和白色，可以用于上传涂鸦：**ControlNet**期望黑色背景与白色涂鸦。如果我们使用白色背景的外部软件创建涂鸦，则**必须使用此选项**。如果使用ControlNet的界面创建涂鸦，则不需要使用此选项。

**RGB到BGR**：这是为了改变上传图像的**颜色通道的顺序**，或者是上传的法线贴图的坐标顺序。如果上传图像并使用预处理，则不需要勾选此框。

**Low VRAM**：适用于VRAM小于8GB的GPU。这是一个实验性的功能：检查是否GPU内存不足，或者想要增加处理的图像数量。

**Guess Mode**：也称为 **non-prompt mode** （非提示模式）。==图像生成可以完全不受文本提示的引导==。它强制**ControlNet编码器**遵循输入控制映射（如深度，边缘等）。使用此模式时，请使用**更高的步长**，例如`50`。我们一般不使用这个功能。



### 5.2 Preprocessor and model

**Preprocessor**（预处理器）:star:：用于预处理输入图像的预处理器——detecting edges, depth, and normal maps

**Model**：==要使用的ControlNet模型==。如果我们选择了一个预处理器，我们应该选择相应的模型。ControlNet模型与Stable Diffusion model一起使用。



### 5.3 Weight and guidance strength

<img src="SD基础.assets/image-144.png" alt="img" style="zoom:67%;" />

我将用下面的图片来说明**weight**和**guidance strength**的影响。这是一个女孩坐着的形象。

<img src="SD基础.assets/01976-1737435102-full-body-a-young-female-highlights-in-hair-sitting-outside-restaurant-blue-eyes-wearing-a-dress-side-light.png" alt="img" style="zoom:67%;" />

但在提示中，我会要求生成一个站起来的女人：*full body, a young female, highlights in hair, **standing** outside restaurant, blue eyes, wearing a dress, side light*。

:one:**weight** 权重：相对于提示词，应该给予控制图多少重视。它类似于**提示符中的关键字权重**，但用于控制映射。以下图像是使用**ControlNet OpenPose预处理器**和**OpenPose模型**生成的：

<img src="SD基础.assets/image-20230424155007542.png" alt="image-20230424155007542" style="zoom:50%;" />

**Controlnet权重**控制相对于**提示符**，生成图像遵循**控制映射**的程度。权值越低，遵循控制映射的程度就越低。

:two:**Guidance strength** 引导强度：==ControlNet的执行步数==。它类似于 [image-to-image](https://stable-diffusion-art.com/how-stable-diffusion-work/#Image-to-image)的 [denoising strength](https://stable-diffusion-art.com/inpainting_basics/#Denoising_strength)。如果引导强度为`1`，则**ControlNet**应用于$$100\%$$的采样步骤。如果指导强度为`0.7`，并且执行50步，则**ControlNet**应用于前$$70\%$$的采样步骤，即前`35`步。

<img src="SD基础.assets/image-20230424155506596.png" alt="image-20230424155506596" style="zoom: 50%;" />

由于` initial steps`设置了图片的全局组成，因此即使只将`Guidance strength`设置为`0.2`，也可以设置姿势。



### 5.4 Resize model

当输入图像或控制映射的大小与要生成的图像的大小==不同==时，Resize model可以提供什么操作。如果它们具有相同的宽高比，则无需担心这些选项。

<img src="SD基础.assets/image-145.png" alt="img" style="zoom:67%;" />

我将通过设置**text-to-image**生成一个**横向图像**，而**input image/control map** 是一个**纵向图像**，来演示**Resize model**的效果。

**Envelope (Outer Fit)**: 裁剪control map，使其与画布的尺寸相同。因为control map在顶部和底部被裁剪，所以我们的女孩也是如此。

<img src="SD基础.assets/image-20230424160437414-1682323478461-48.png" alt="image-20230424160437414" style="zoom:67%;" />

**Scale to Fit**： 调整control map。用空值扩展控制图，使其与图像画布的大小相同。与原始输入图像相比，边上有更多的空间。

<img src="SD基础.assets/image-20230424160755954-1682323677213-50.png" alt="image-20230424160755954" style="zoom:67%;" />

**Just Resize**： 独立缩放control map的宽度和高度以适应图像画布。这将**改变control map的长宽比**。女孩现在需要向前倾斜，以便她仍然在画布内。你可以用这种模式创造一些有趣的效果。

<img src="SD基础.assets/image-20230424160901379-1682323742835-52.png" alt="image-20230424160901379" style="zoom: 67%;" />



### 5.5 Scribble canvas settings

<img src="SD基础.assets/image-147.png" alt="img" style="zoom: 67%;" />

如果你使用**ControlNet GUI**来创建**草图**`scribbles`，则需要考虑这个设置。当我们上传输入图像并使用预处理器时，==这些设置没有影响==。

**画布宽度和画布高度**是按下**创建空白画布按钮**时创建的空白画布的宽度和高度。



### 5.6 Preview annotation

<img src="SD基础.assets/image-148.png" alt="img" style="zoom:67%;" />

**ControlNet extension**会在每轮图像生成后向你显示一份控制图。但有时你只想看看控制图，并对参数进行实验。

**Preview annotator result**：根据**预处理器的设置**生成控制图。控制图会在输入图像的旁边显示。

<img src="SD基础.assets/image-149.png" alt="img" style="zoom:67%;" />

**Hide annotator result**：Hide the control map.



## 6. 不同Preprocessors的实践

> 见[原文](https://stable-diffusion-art.com/controlnet/)





## 7. ControlNet的实际应用:star:

- **从图像复制姿势**（最明显的功能）

- **重写电影场景**：可以把《纸醉金迷》中的标志性舞蹈场景改编成公园里的一些瑜伽练习。

  | ![img](SD基础.assets/image-171.png) | <img src="SD基础.assets/image-133.png" alt="img" style="zoom:80%;" /> |
  | ----------------------------------- | ------------------------------------------------------------ |

- 许多ControlNet模型在复制人类姿势方面效果很好，但有**不同的优势和劣势**。让我们以**贝多芬的画**为例，用不同的控制网模型对其进行改造。

  > 使用[DreamShaper](https://stable-diffusion-art.com/models/#DreamShaper) ，配合提示词：*elegant snobby rich Aerith Gainsborough looks intently at you in wonder and anticipation. ultra detailed painting at 16K resolution and epic visuals. epically surreally beautiful image. amazing effect, image looks crazily crisp as far as it’s visual fidelity goes, absolutely outstanding. vivid clarity. ultra. iridescent. mind-breaking. mega-beautiful pencil shadowing. beautiful face. Ultra High Definition. process twice.*
  >
  > ![image-20230424162522770](SD基础.assets/image-20230424162522770-1682324724116-64.png)

  - **HED模型最忠实地复制了原始图像**，精确到小的细节。
  - **Canny Edge**、**深度**和**法线图**都做得很好，但变化也比较大。
  - **OpenPose**复制了姿势，但允许DreamShaper模型做其余的工作，包括发型、脸部和服装。
  - **m-LSD**在这里完全失败（在复制姿势方面）。

- 有些姿势太魔幻，比如JoJo立，我们可以直接自己摆弄模型生成，都不用我们去Unity，这里有个[现成的网站](https://webapp.magicposer.com/)

  - 去[MagicPose](https://webapp.magicposer.com/)

  - 摆弄出我们想要的姿势

  - 按下**预览**。对该模型进行截图。你应该得到一个像下面这样的图像。

    ![img](SD基础.assets/pose2.jpg)

  - 作为ControlNet的输入图像

- ==室内设计==

  - 使用**Stable Diffusion ControlNet**的<straight-line detector M-LSD model >。以下是ControlNet的设置：

    <img src="SD基础.assets/image-137.png" alt="img" style="zoom:67%;" />

  - Prompt：*award winning living room*。Model: Stable Diffusion v1.5

    | 原图像                                            | 生成1                                                        | 生成2                                                        |
    | ------------------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
    | ![img](SD基础.assets/living-room-2732939_640.jpg) | ![img](SD基础.assets/00133-475383634-award-winning-living-room.png) | ![img](SD基础.assets/00129-1768390595-award-winning-living-room.png) |

  - 也可以使用**深度模型**，它将强调保留深度信息。



## 8. Stable Diffusion depth model和ControlNet之间的差异

Stability AI发布了一个 [depth-to-image](https://stable-diffusion-art.com/depth-to-image/)模型。它与**ControlNet**有很多相似之处，但也有重要区别。让我们先来谈谈什么是相似的：

- 它们都是**稳定扩散模型**...
- 它们都使用两个条件（预处理的图像和文本提示）。
- 它们都使用**MiDAS**来估计深度图。

不同之处是：

- [depth-to-image](https://stable-diffusion-art.com/depth-to-image/)是**v2模型**。**ControlNet**可以与**任何v1或v2模型**一起使用。这一点很重要，因为v2模型是出了名的难用。ControlNet可以使用任何v1模型的原因：不仅为**v1.5基本模型**打开了深度调节，而且还为社区发布的数千种特殊模型打开了深度调节。
- **ControlNet**的功能更加全面。除了深度之外，它还可以用边缘检测、姿势检测等进行调节。
- **ControlNet**的深度图比[depth-to-image](https://stable-diffusion-art.com/depth-to-image/)的分辨率更高。

## More readings

- [Some images](https://www.reddit.com/r/StableDiffusion/comments/112t4fl/controlnet_experiments_from_magic_poser_input/) generated with Magic Poser and OpenPose.

- Research article: [Adding Conditional Control to Text-to-Image Diffusion Models](https://arxiv.org/abs/2302.05543) (Feb 10, 2023)
- [ControlNet Github page](https://github.com/lllyasviel/ControlNet)





# **Embedding**技术（**textual inversion**）

## 1. 什么是**Embedding**？

`Embedding`是文本反转（`textual inversion`）的结果，==一种在模型中定义**新关键词**而不修改模型的方法==。该方法因其能够以**3~5个样本图像**为模型注入新的样式或对象而受到关注。

**文本反转**的神奇之处不在于添加新样式或对象的能力，其他微调方法也可以做到这一点，甚至更好。关键是它可以在不改变模型的情况下做到这一点。

每个embedding都是基于一款模型生成的，如果我们下载的embedding是基于SD1.5模型训练的，那它只能针对SD1.5模型来生效



## 2. 哪里找到Embedding

[Face站](https://huggingface.co/sd-concepts-library?sort_models=likes#models)

[C站](https://civitai.com/)



## 3. 怎么使用Embeddings

1. 首先，从[概念库](https://huggingface.co/sd-concepts-library)下载一个`.bin`嵌入文件，例如：*learned_embedds.bin*。

2. 接下来，将文件重命名为要使用的关键字——它必须是模型中不存在的东西。*Marc_allante.bin*是个不错的选择。

3. 将其放在GUI工作目录中的embeddings文件夹中：*stable-diffusion-webui/embeddings*

4. 重新启动GUI。在启动终端中，我们应该看到如下消息：*Loaded a total of 1 textual inversion embeddings. Embeddings: marc_allante*

5. 使用文件名作为提示词：*(`marc_allante:1.2)` a dog*

   - 即使少了一个字母，`embeddings`也不会起作用。此外，我们不能在`v2`中使用`v1 embeddings`

   <img src="SD基础.assets/image-44.png" alt="img" style="zoom:50%;" />

垃圾桶和复制按钮之间有一个按钮，看起来像一个小`ipod`。单击它，我们将看到**所有可用的嵌入**。它们都在`text Inversion`选项卡下，单击其中任何一个都会将其插入到提示词中。

<img src="SD基础.assets/image-20230422140605795.png" alt="image-20230422140605795" style="zoom: 50%;" />



## 4. 推荐Embeddings

- [wlop_style](https://huggingface.co/datasets/Nerfgun3/wlop_style/resolve/main/wlop_style.pt)：能够渲染一些不错的鬼刀插图风格，和[wlop_model](https://huggingface.co/SirVeggie/wlop/resolve/main/wlop-any.ckpt)一起使用，效果最好

  <img src="SD基础.assets/00558-964685455-wlop_style-_0.6-m_wlop_1.2-woman-wearing-dress-perfect-face-beautiful-detailed-eyes-long-hair-birds.png" alt="img" style="zoom:50%;" />

- [Kuvshinov](https://huggingface.co/sd-concepts-library/kuvshinov/resolve/main/learned_embeds.bin)：Kuvshinov is a Russian illustration

  <img src="SD基础.assets/00676-3637224931-kuvshinov-a-woman-with-beautiful-detailed-eyes-highlight-hair.png" alt="img" style="zoom: 50%;" />



## 5. embedding，dreambooth，hypernetwork间的区别

稳定扩散模型的微调有三种常用方法：textual inversion (embedding)，[dreambooth](https://stable-diffusion-art.com/dreambooth/) and hypernetwork.

**embedding**：在不改变模型的情况下定义新的关键字，来描述一个新的概念。嵌入向量存储在`.bin`或`.pt`文件中。它的文件大小非常小，通常小于100 kB

**Dreambooth**：通过对整个模型进行微调，注入新的概念。文件大小是典型的`Stable Diffusion`，大约2~4 GB。文件扩展名与其他模型相同，为`.ckpt`

**Hypernetwork**：是附加在稳定扩散模型**去噪单元**上的==附加网络==。其目的是在不更改模型的情况下对模型进行微调。文件大小一般为100 MB左右。



## 6. 怎么训练自己的Embedding

- [【Stable Diffusion】头像训练篇](https://zhuanlan.zhihu.com/p/618040302?utm_id=0)
- [训练Embdedding](https://ivonblog.com/posts/stable-diffusion-webui-manuals/zh-cn/training/embedding/)





# 超网络模型hypernetworks

准备好把**SD技能**提高到一个新的水平了吗？如果是这样，让我们谈谈==超网络模型==。

## 1. 什么是hypernetworks

**hypernetworks**是一种微调技术，最初由`Novel AI`开发，是稳定扩散的早期采用者。它是一个**小的神经网络**，连接到一个**Stable Diffusion model**来修改它的风格。

**hypernetworks**插入到哪里？稳定扩散模型中**最关键的部分**：噪声预测器UNet的交叉注意模块。==LoRA模型类似地修改了稳定扩散模型的这一部分，但方式不同==。

在训练过程中，**Stable Diffusion model**被锁定，但附加的**hypernetworks**允许变化。由于**hypernetworks**较小，训练速度快，所需资源有限，可以在一台普通的电脑上进行。**快速训练**和**小文件**是其主要技术吸引力。



## 2. 和其他模型的区别

:one:**hypernetworks**无法单独运行，它也需要使用checkPoint模型来生成图像。

:two:**LoRA模型**与**hypernetworks**最为相似。它们都很小，只修改**交叉注意模块**。不同之处在于他们如何修改它：**LoRA模型**通过改变交叉注意的权重，来修改交叉注意；**Hypernetwork**通过插入额外的网络来实现。

> 用户通常会发现**LoRA模型**产生更好的结果

:three:**Embeddings**和**hypernetworks**作用于稳定扩散模型的不同部分。:three:**Embeddings**在文本编码器中创建**新的嵌入**。**hypernetworks**将一个小网络插入到**交叉注意模块**。

> 根据大佬的经验，**Embeddings**比**hypernetworks**更强大。



## 3. 怎么使用hypernetworks

将下载好的hypernetworks模型文件放入以下文件夹中：*stable-diffusion-webui/models/hypernetworks*。

要使用hypernetworks，请在提示符中输入以下短语：**\<hypernet:filename:multiplier>**。

为了成功解锁预期的风格，首先将其**与训练时使用的模型**一起使用。但不要止步于此，有些hypernetworks需要==特定的提示==，或者只能处理==特定的主题==，因此请务必查看**模型页面上的提示示例**，以了解哪种提示最有效。

这里有一个专业建议：如果注意到图像看起来有点太饱和了，这可能是我们需要**调整倍率的信号**。一旦确认了超网络正在发挥它的魔力，我们也可以在其他模型上试用它（这不是炼丹，只是配药~~）。



## 4. 推荐的hypernetworks

- [Water Elemental ](https://civitai.com/models/1399/water-elemental)：使用 [Stable Diffusion v1.5](https://stable-diffusion-art.com/models/#Stable_diffusion_v15)。可以把任何东西变成水！在`subejct`前使用短语 *water elemental*（PS：一定要描述背景）。

  - Prompt：water elemental woman walking across a busy street \<hypernet:waterElemental_10:0.7>

    <img src="SD基础.assets/image-90.png" alt="img" style="zoom:50%;" />

  - Prompt：water elemental a boy running on water \<hypernet:waterElemental_10:1>

    ![hypernetwork water elemental](SD基础.assets/image-91.png)

- [InCase Style](https://civitai.com/models/5124/incase-style-hypernetwork)：使用[Anything v3 Model](https://huggingface.co/Linaqruf/anything-v3.0)。它修改了任何v3模型，以产生**更成熟的动画风格**。

  - Prompt：detailed face, a beautiful woman, explorer in forest, white top, short brown pants, hat, sky background, realism, small breast \<hypernet:incaseStyle_incaseAnythingV3:1>

  - Negative prompt：moon, ugly, tiling, poorly drawn hands, poorly drawn feet, poorly drawn face, out of frame, extra limbs, disfigured, deformed, body out of frame, bad anatomy, watermark, signature, cut off, low contrast, underexposed, overexposed, bad art, beginner, amateur, distorted face, blurry, draft, grainy, large breast

    <img src="SD基础.assets/image-85.png" alt="img" style="zoom:50%;" />

- [Gothic RPG Artstyle](https://civitai.com/models/5814/gothic-rpg-artstyle)：使用[Protogen v2.2 Model](https://huggingface.co/darkstorm2150/Protogen_v2.2_Official_Release)。

  - Prompt：drawing male leather jacket cyberpunk 2077 on a city street by WoD1 \<hypernet:gothicRPGArtstyle_v1:1>

    <img src="SD基础.assets/image-96.png" alt="img" style="zoom:50%;" />











# VAE技术

`VAE`是SD1.4或1.5模型的部分更新，使眼睛渲染的更好。VAE代表**变分自动编码器**（`variational autoencoder`）。它是神经网络模型的一部分，对图像进行**编码和解码**，使其与较小的潜在空间相匹配，从而使计算速度更快。

我们不需要安装一个VAE文件来运行Stable Diffusion，我们使用的任何模型，无论是`v1`, `v2`还是自定义，都已经有一个**默认的VAE**。当人们说下载和使用VAE时，他们指的是使用**它的改进版本**。

==改进的VAE==可以更好地从潜在空间对图像进行解码。细节得到了更好的恢复，因此它有助于渲染眼睛和文本。**Stability AI** 发布了两个版本的**微调VAE解码器**，[EMA](https://huggingface.co/stabilityai/sd-vae-ft-ema-original/resolve/main/vae-ft-ema-560000-ema-pruned.ckpt)（Exponential Moving Average）和[MSE](https://huggingface.co/stabilityai/sd-vae-ft-mse-original/resolve/main/vae-ft-mse-840000-ema-pruned.ckpt)（ Mean Square Error ）。

<img src="SD基础.assets/image-12.png" alt="Comparison of 3 VAEs: EMA, MSE and original." style="zoom: 50%;" />

> ==EMA的图像更清晰，而MSE的图像更平滑==
>
> 改进的VAE表现都不差：要么做得更好，要么什么都不做。

将下载的VAE文件放入目录：*stable-diffusion-webui/models/VAE*。要使用VAE，转到**设置选项卡**，并单击左侧的**Stabe Diffusion**部分，找到`SD VAE`部分。在下拉菜单中，选择想要使用的VAE文件。

![img](SD基础.assets/image-11-1682145567216-40.png)





# AI放大器:star:

<img src="SD基础.assets/image.png" alt="img" style="zoom:67%;" />

对于游戏开发者而言，**放大器**是一个节省游戏资源的方法，而`SD`为什么也需要呢？因为`SD`生成的图片的分辨率较低，一般是512*512， 这对于现代电子设备来说是不够的，因此我们需要对生成的图像进行放大，将其分辨率提升到2K，甚至8K。



## 1. 怎么在SD中使用AI放大器

- 转到**附加功能选项卡**，然后选择图像。
- 设置缩放比例因子。默认设置为`4`。
  - 如果源图像是512\*512像素，那么因子`2`产生的结果就是1024*\*1024像素，因子`4`就是2048\*2048像素。
- 选择==R-ESRGAN 4x+==，这是一款适用于大多数图像的AI升级器。
- 开始放大

<img src="SD基础.assets/image-20230422155402462-1682150044351-3.png" alt="image-20230422155402462" style="zoom:50%;" />



## 2. AI upscaler options

- **Latent Diffusion Super Resolution** (LDSR) ：质量上乘，但速度极慢，不推荐！
- **Enhanced Super-Resolution Generative Adversarial Networks** ([ESRGAN](https://github.com/xinntao/ESRGAN)) ：赢得了2018年感知图像恢复和操作挑战赛。它是对SRGAN模型的增强。
-  **Real-ESRGAN 4x** ([R-ESRGAN](https://github.com/xinntao/Real-ESRGAN))：对`ESRGAN`的增强，可以恢复各种真实世界的图像。它模拟了相机镜头和数字压缩产生的不同程度的失真。与ESRGAN相比，它倾向于生成更平滑的图像。==R-ESRGAN在逼真的照片中表现最好==。
- **动画图像**需要专门训练放大器。访问[Upscaler模型数据库](https://upscale.wiki/wiki/Model_Database)下载其他Upscaler。将其放入文件夹中：*stable-diffusion-webui/models/ESRGAN*



# 参考资料	

- [Nenly的B站教程](https://www.bilibili.com/video/BV12X4y1r7QB/?spm_id_from=333.788&vd_source=e2a58daa685fa13d99286660e00518e4)
- [stable-diffusion-art](https://stable-diffusion-art.com/how-to-come-up-with-good-prompts-for-ai-image-generation/)

