# Vulkan教程3



## Descriptor layout and buffer

### Introduction

我们现在可以传递任意属性到每个顶点的顶点着色器`vertex shader`，但是全局变量呢？我们将从本章继续到3D图形，这需要一个模型-视图-投影矩阵。我们可以将它作为顶点数据包含进来，但这是对内存的浪费，而且它会要求我们在转换发生变化时更新顶点缓冲区。这种变换可以很容易地改变每一个帧。

在Vulkan中解决这个问题的正确方法是使用<u>资源描述符</u>`resource descriptors`。==描述符是着色器自由访问缓冲区和图像等资源的一种方式==。我们将建立一个包含转换矩阵的缓冲区，并让顶点着色器通过描述符访问它们。描述符的使用包括三个部分：

- 在管道创建期间，指定描述符布局`descriptor layout `。
- 从描述符池分配描述符集`descriptor set`
- 在渲染期间，绑定描述符集

==描述符布局==：指定将由管道访问的资源类型，就像`render pass`指定将被访问的附件类型一样。==描述符集==：指定将绑定到描述符的实际缓冲区或图像资源，就像framebuffer——指定要绑定到渲染pass的附件上的实际图像视图一样。描述符集然后绑定到绘图命令上，就像顶点缓冲区`vertex buffers`和`framebuffer`一样。

描述符有很多种类型，但在本章中我们将使用<u>统一缓冲区对象</u>`uniform buffer objects`(UBO)。我们将在以后的章节中研究其他类型的描述符，但基本过程是相同的。假设我们有一个数据，像这样：

```c
struct UniformBufferObject {
    glm::mat4 model;
    glm::mat4 view;
    glm::mat4 proj;
};
```

然后我们可以复制数据到一个`VkBuffer`，并通过一个uniform缓冲区对象描述符从顶点着色器访问它，像这样:arrow_down:：

```c
layout(binding = 0) uniform UniformBufferObject {
    mat4 model;
    mat4 view;
    mat4 proj;
} ubo;

void main() {
    gl_Position = ubo.proj * ubo.view * ubo.model * vec4(inPosition, 0.0, 1.0);
    fragColor = inColor;
}
```



### Vertex shader

修改顶点着色器，包括常量缓冲对象，就像上面指定的那样。

```c
#version 450
#extension GL_ARB_separate_shader_objects : enable

layout(binding = 0) uniform UniformBufferObject {
    mat4 model;
    mat4 view;
    mat4 proj;
} ubo;

layout(location = 0) in vec2 inPosition;
layout(location = 1) in vec3 inColor;

layout(location = 0) out vec3 fragColor;

void main() {
    gl_Position = ubo.proj * ubo.view * ubo.model * vec4(inPosition, 0.0, 1.0);
    fragColor = inColor;
}
```

注意uniform的顺序，in和out声明并不重要。`binding`指令类似于属性的位置`location`指令。我们将在描述符布局中引用这个绑定。



### Descriptor set layout

下一步是在c++端定义UBO，并在顶点着色器中告诉Vulkan这个描述符。

```c
struct UniformBufferObject {
    glm::mat4 model;
    glm::mat4 view;
    glm::mat4 proj;
};
```

矩阵中的数据与着色器期望的方式是二进制兼容的，所以我们可以稍后memcpy一个`UniformBufferObject`到一个`VkBuffer`。

我们需要提供每个描述符绑定`descriptor binding`的细节，用于创建管道，就像我们必须为每个顶点属性及其位置索引做的那样。我们将设置一个新的函数来定义所有这些信息，叫做`createDescriptorSetLayout`。它应该在创建管道之前就被调用，因为我们会在那里需要它。:arrow_down:

```c
void initVulkan() {
    ...
    createDescriptorSetLayout();
    createGraphicsPipeline();
    ...
}

...

void createDescriptorSetLayout() {

}
```

每个绑定都需要通过`VkDescriptorSetLayoutBinding`结构进行描述：

```c
void createDescriptorSetLayout() {
    VkDescriptorSetLayoutBinding uboLayoutBinding{};
    uboLayoutBinding.binding = 0;
    uboLayoutBinding.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
    uboLayoutBinding.descriptorCount = 1;
}
```

前两个字段指定在着色器中使用的绑定`binding`和描述符的类型（这里是UBO）。着色器变量可以代表一个uniform缓冲对象数组，而`descriptorCount`指定数组中的值的数量。例如，这可以用来为骨骼动画中的每个骨骼指定一个转换。我们的MVP转换在一个uniform缓冲对象中，因此我们使用的descriptorCount为1。:arrow_up:

```c
uboLayoutBinding.stageFlags = VK_SHADER_STAGE_VERTEX_BIT;
```

我们还需要指定在哪个着色器阶段`shader stages`，描述符将被引用。`stageFlags`字段可以是`VkShaderStageFlagBits`值或`VK_SHADER_STAGE_ALL_GRAPHICS`值的组合。在我们的例子中，我们只在顶点着色器中引用描述符。:arrow_up:

```c
uboLayoutBinding.pImmutableSamplers = nullptr; // Optional
```

`pImmutableSamplers`字段只和图像采样相关的描述符有关，我们稍后会看到。将其保留为默认值。

所有的<u>描述符绑定</u>`descriptor binding`被组合到一个`VkDescriptorSetLayou`t对象中。在`pipelineLayout`上面定义一个新的类成员:

```c
VkDescriptorSetLayout descriptorSetLayout;
VkPipelineLayout pipelineLayout;
```

然后我们可以使用`vkCreateDescriptorSetLayout`创建它。这个函数接受一个带有绑定数组的`VkDescriptorSetLayoutCreateInfo`：:arrow_down:

```c
VkDescriptorSetLayoutCreateInfo layoutInfo{};
layoutInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_LAYOUT_CREATE_INFO;
layoutInfo.bindingCount = 1;
layoutInfo.pBindings = &uboLayoutBinding;

if (vkCreateDescriptorSetLayout(device, &layoutInfo, nullptr, &descriptorSetLayout) != VK_SUCCESS) {
    throw std::runtime_error("failed to create descriptor set layout!");
}
```

我们需要在管道创建期间指定`descriptor set layout`，以告诉Vulkan着色器将使用哪些描述符。描述符集布局在管道布局对象中指定。修改`VkPipelineLayoutCreateInfo`以引用布局对象:arrow_down:

```c
VkPipelineLayoutCreateInfo pipelineLayoutInfo{};
pipelineLayoutInfo.sType = VK_STRUCTURE_TYPE_PIPELINE_LAYOUT_CREATE_INFO;
pipelineLayoutInfo.setLayoutCount = 1;
pipelineLayoutInfo.pSetLayouts = &descriptorSetLayout;
```

可能想知道为什么在这里可以指定多个描述符集布局，因为一个描述符已经包含了所有的绑定。我们将在下一章中回到这个问题，在这一章中我们将研究描述符池`descriptor pools`和描述符集`descriptor sets.`

```c
void cleanup() {
    cleanupSwapChain();

    vkDestroyDescriptorSetLayout(device, descriptorSetLayout, nullptr);

    ...
}
```



### Uniform buffer

在下一章中，我们将为着色器指定包含UBO数据的缓冲区，但是我们首先需要创建这个缓冲区。我们会把每一帧的新数据复制到`uniform buffer`，所以用一个<u>暂存缓冲区</u>`staging buffer`没有任何意义。在这种情况下，它只会增加额外的开销，而且可能会降低而不是提高性能

我们应该有多个缓冲区，因为多个帧可能同时在运行——我们不想在更新缓冲区准备下一帧时，前一帧还在读取它！我们可以为每帧或每交换链图像设置一个`uniform buffer`。但是，since we need to refer to the uniform buffer from the command buffer that we have per swap chain image，因此每个交换链映像拥有`uniform buffer`是最有意义的。

为此，添加新的类成员`uniformbuffer`和`uniformBuffersMemory`

```c
VkBuffer indexBuffer;
VkDeviceMemory indexBufferMemory;

std::vector<VkBuffer> uniformBuffers;
std::vector<VkDeviceMemory> uniformBuffersMemory;
```

类似地，在`createIndexBuffer`之后创建一个新的函数`createUniformBuffers`，并分配缓冲区

```c
void initVulkan() {
    ...
    createVertexBuffer();
    createIndexBuffer();
    createUniformBuffers();
    ...
}

...

void createUniformBuffers() {
    VkDeviceSize bufferSize = sizeof(UniformBufferObject);

    uniformBuffers.resize(swapChainImages.size());
    uniformBuffersMemory.resize(swapChainImages.size());

    for (size_t i = 0; i < swapChainImages.size(); i++) {
        createBuffer(bufferSize, VK_BUFFER_USAGE_UNIFORM_BUFFER_BIT, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, uniformBuffers[i], uniformBuffersMemory[i]);
    }
}
```

我们将编写一个单独的函数，它在每一帧都更新uniform缓冲区，因此这里将没有`vkMapMemory`。uniform数据将被用于所有的绘制调用，因此只有当我们停止渲染时，包含它的缓冲区才应该被销毁。由于它还取决于交换链映像的数量，而交换链映像在重新创建后可能会发生变化，因此我们将在cleanupSwapChain中对其进行清理：

```c
void cleanupSwapChain() {
    ...

    for (size_t i = 0; i < swapChainImages.size(); i++) {
        vkDestroyBuffer(device, uniformBuffers[i], nullptr);
        vkFreeMemory(device, uniformBuffersMemory[i], nullptr);
    }
}
```

```c
void recreateSwapChain() {
    ...

    createFramebuffers();
    createUniformBuffers();
    createCommandBuffers();
}
```



### Updating uniform data

创建一个新的函数`updateUniformBuffer`，并在我们知道要获取哪个交换链图像之后，立即从`drawFrame`函数添加对它的调用

```c
void drawFrame() {
    ...

    uint32_t imageIndex;
    VkResult result = vkAcquireNextImageKHR(device, swapChain, UINT64_MAX, imageAvailableSemaphores[currentFrame], VK_NULL_HANDLE, &imageIndex);

    ...

    updateUniformBuffer(imageIndex);

    VkSubmitInfo submitInfo{};
    submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;

    ...
}

...

void updateUniformBuffer(uint32_t currentImage) {

}
```

这个函数将在每一帧中生成一个新的变换，使几何图形旋转。我们需要包含两个新的头文件来实现这个功能：

```c
#define GLM_FORCE_RADIANS
#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

#include <chrono>
```

`glm/gtc/matrix_transform.hpp`公开了可用于模型转换的函数，例如`glm::rotate`、视点转换函数，例如`glm::lookAt`、投影函数，例如`glm::perspective`。`GLM_FORCE_RADIANS`确保像`glm::rotate`这样的函数使用弧度作为参数，避免任何可能的混淆，其定义是必要的。`chrono`标准库头公开了==用于精确计时的函数==。我们将使用它来确保几何图形，无论帧速率如何，每秒旋转90度。:arrow_up:

```c
void updateUniformBuffer(uint32_t currentImage) {
    static auto startTime = std::chrono::high_resolution_clock::now();

    auto currentTime = std::chrono::high_resolution_clock::now();
    float time = std::chrono::duration<float, std::chrono::seconds::period>(currentTime - startTime).count();
}
```

`updateUniformBuffer`函数将开始使用一些逻辑`logic`来计算时间(以秒为单位)，因为渲染已经开始使用浮点精度。

现在，我们将在uniform缓冲区对象中定义模型、视图和投影转换。模型旋转将是一个简单的绕z轴旋转，使用时间变量：

```c
UniformBufferObject ubo{};
ubo.model = glm::rotate(glm::mat4(1.0f), time * glm::radians(90.0f), glm::vec3(0.0f, 0.0f, 1.0f));
```

```c
ubo.view = glm::lookAt(glm::vec3(2.0f, 2.0f, 2.0f), glm::vec3(0.0f, 0.0f, 0.0f), glm::vec3(0.0f, 0.0f, 1.0f));
```

对于视图转换，从上面45度角度观察几何体。`glm::lookAt`功能以眼睛位置、中心位置和上轴为参数。

```c
ubo.proj = glm::perspective(glm::radians(45.0f), swapChainExtent.width / (float) swapChainExtent.height, 0.1f, 10.0f);
```

我选择使用45度<u>垂直视场</u>`vertical field-of-view`的透视投影。其他参数是纵横比，近面和远面。重要的是使用当前交换链区段来计算长宽比，以考虑调整大小后窗口的新宽度和高度。

```c
ubo.proj[1][1] *= -1;
```

==GLM最初是为OpenGL设计的==，其中剪辑坐标` clip coordinates`的Y坐标是倒置的。最简单的补偿方法是翻转投影矩阵中Y轴的比例因子上的符号。如果您不这样做，那么图像将被渲染颠倒。

现在已经定义了所有的转换，因此我们可以将uniform缓冲区对象中的数据复制到当前的uniform缓冲区中。这与我们对顶点缓冲区的处理方式完全相同，除了没有`staging buffer`:

```c
void* data;
vkMapMemory(device, uniformBuffersMemory[currentImage], 0, sizeof(ubo), 0, &data);
    memcpy(data, &ubo, sizeof(ubo));
vkUnmapMemory(device, uniformBuffersMemory[currentImage]);
```

使用UBO的这种方式并不是最有效的方式，来传递频繁变化的值到着色器。A more efficient way to pass a small buffer of data to shaders are *push constants*.。我们可以在以后的章节中讨论这些。

在下一章中，我们将研究描述符集，它将实际地将vkbuffer绑定到uniform缓冲区描述符，以便着色器可以访问这个转换数据。



## Descriptor pool and sets

### Descriptor pool

==描述符集不能直接创建，必须从命令缓冲区之类的池中分配==。毫不奇怪，描述符集的等价，称为描述符池`descriptor pool`。我们将编写一个新函数`createDescriptorPool`来设置它。

```c
void initVulkan() {
    ...
    createUniformBuffers();
    createDescriptorPool();
    ...
}

...

void createDescriptorPool() {

}
```

首先，我们需要使用`VkDescriptorPoolSize`结构描述`descriptor sets `将包含哪些描述符类型以及它们的数量。

```c
VkDescriptorPoolSize poolSize{};
poolSize.type = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
poolSize.descriptorCount = static_cast<uint32_t>(swapChainImages.size());
```

我们将为每一帧分配一个描述符。这个池大小结构由`VkDescriptorPoolCreateInfo`引用：

```c
VkDescriptorPoolCreateInfo poolInfo{};
poolInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_POOL_CREATE_INFO;
poolInfo.poolSizeCount = 1;
poolInfo.pPoolSizes = &poolSize;
```

除了可用的单个描述符的最大数量之外，我们还需要指定：可能分配的描述符集的最大数量:arrow_down:

```c
poolInfo.maxSets = static_cast<uint32_t>(swapChainImages.size());
```

此结构有一个类似于命令池的可选标志，用于确定各个描述符集是否可以释放:`VK_DESCRIPTOR_POOL_CREATE_FREE_DESCRIPTOR_SET_BIT`。我们不会在创建描述符集之后再去修改它，所以我们不需要这个标志。可以将标志保留为默认值0。

```c
VkDescriptorPool descriptorPool;

...

if (vkCreateDescriptorPool(device, &poolInfo, nullptr, &descriptorPool) != VK_SUCCESS) {
    throw std::runtime_error("failed to create descriptor pool!");
}
```

添加一个新的类成员来存储描述符池的句柄，并调用vkCreateDescriptorPool来创建它。在重新创建交换链时，应该销毁描述符池，因为它取决于图像的数量：

```c
void cleanupSwapChain() {
    ...

    for (size_t i = 0; i < swapChainImages.size(); i++) {
        vkDestroyBuffer(device, uniformBuffers[i], nullptr);
        vkFreeMemory(device, uniformBuffersMemory[i], nullptr);
    }

    vkDestroyDescriptorPool(device, descriptorPool, nullptr);
}
```

```c
void recreateSwapChain() {
    ...

    createUniformBuffers();
    createDescriptorPool();
    createCommandBuffers();
}
```



### Descriptor set

我们现在可以分配描述符集本身。为此添加`createDescriptorSets`函数：

```c
void initVulkan() {
    ...
    createDescriptorPool();
    createDescriptorSets();
    ...
}

void recreateSwapChain() {
    ...
    createDescriptorPool();
    createDescriptorSets();
    ...
}

...

void createDescriptorSets() {

}
```

描述符集分配使用`VkDescriptorSetAllocateInfo`结构体进行描述。您需要指定要分配的描述符池、要分配的描述符集的数量以及基于它们的描述符布局。:arrow_down:

```c
std::vector<VkDescriptorSetLayout> layouts(swapChainImages.size(), descriptorSetLayout);
VkDescriptorSetAllocateInfo allocInfo{};
allocInfo.sType = VK_STRUCTURE_TYPE_DESCRIPTOR_SET_ALLOCATE_INFO;
allocInfo.descriptorPool = descriptorPool;
allocInfo.descriptorSetCount = static_cast<uint32_t>(swapChainImages.size());
allocInfo.pSetLayouts = layouts.data();
```

在我们的例子中，我们将为每个<u>交换链映像</u>` swap chain image`创建一个描述符集，所有这些都具有相同的布局。不幸的是，我们需要布局的所有副本，因为下一个函数需要一个匹配集合数量的数组。

添加一个类成员来保存描述符集的句柄，并使用`vkAllocateDescriptorSets`分配它们

```c
VkDescriptorPool descriptorPool;
std::vector<VkDescriptorSet> descriptorSets;

...

descriptorSets.resize(swapChainImages.size());
if (vkAllocateDescriptorSets(device, &allocInfo, descriptorSets.data()) != VK_SUCCESS) {
    throw std::runtime_error("failed to allocate descriptor sets!");
}
```

不需要显式地清理描述符集，因为它们将在销毁描述符池时自动释放。对`vkAllocateDescriptorSets`的调用将分配描述符集，每个描述符集有一个`uniform buffer descriptor.`。

现在已经分配了描述符集，但是仍然需要配置其中的描述符。现在我们将添加一个循环来填充每个描述符

```c
for (size_t i = 0; i < swapChainImages.size(); i++) {

}
```

引用缓冲区的描述符，使用`VkDescriptorBufferInfo`结构体配置。此结构指定缓冲区和==包含描述符数据的区域==。

```c
for (size_t i = 0; i < swapChainImages.size(); i++) {
    VkDescriptorBufferInfo bufferInfo{};
    bufferInfo.buffer = uniformBuffers[i];
    bufferInfo.offset = 0;
    bufferInfo.range = sizeof(UniformBufferObject);
}
```

如果您要覆盖整个缓冲区，就像我们在本例中所做的那样，那么也可以使用`VK_WHOLE_SIZE`作为范围。使用`vkUpdateDescriptorSets`更新描述符的配置，该函数接受`VkWriteDescriptorSet`数组作为参数。

```c
VkWriteDescriptorSet descriptorWrite{};
descriptorWrite.sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
descriptorWrite.dstSet = descriptorSets[i];
descriptorWrite.dstBinding = 0;
descriptorWrite.dstArrayElement = 0;
```

前两个字段指定the descriptor set to update and the binding.。我们给了our uniform buffer binding index为0。请记住，描述符可以是数组，因此我们还需要指定要更新的数组中的第一个索引。我们没有使用数组，所以索引是0。

```c
descriptorWrite.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
descriptorWrite.descriptorCount = 1;
```

我们需要再次指定描述符的类型。可以在一个数组中同时更新多个描述符，从索引`dstArrayElement`开始。`descriptorCount`字段指定需要更新的数组元素数量。

```c
descriptorWrite.pBufferInfo = &bufferInfo;
descriptorWrite.pImageInfo = nullptr; // Optional
descriptorWrite.pTexelBufferView = nullptr; // Optional
```

最后一个字段引用一个具有`descriptorCount`结构体的数组，该结构体实际配置描述符。这取决于描述符的类型，您实际上需要使用这三种描述符中的哪一种。``pBufferInfo`字段用于引用缓冲区数据的描述符，`pImageInfo`用于引用图像数据的描述符，`pTexelBufferView`用于引用缓冲区视图的描述符。我们的描述符是基于缓冲区的，所以我们使用`pBufferInfo`。

```c
vkUpdateDescriptorSets(device, 1, &descriptorWrite, 0, nullptr);
```

使用`vkUpdateDescriptorSets`应用更新。它接受两种数组作为参数：`VkWriteDescriptorSet`数组和`VkCopyDescriptorSet`数组。后者可用于相互复制描述符，正如其名称所暗示的那样



### Using descriptor sets

现在我们需要更新`createCommandBuffers`函数，以便使用`vkCmdBindDescriptorSets`将每个交换链图像的、正确的描述符集实际绑定到着色器中的描述符集。这需要在`vkCmdDrawIndexed`调用之前完成

```c
vkCmdBindDescriptorSets(commandBuffers[i], VK_PIPELINE_BIND_POINT_GRAPHICS, pipelineLayout, 0, 1, &descriptorSets[i], 0, nullptr);
vkCmdDrawIndexed(commandBuffers[i], static_cast<uint32_t>(indices.size()), 1, 0, 0, 0);
```

与顶点和索引缓冲区不同，描述符集不是图形管道所独有的。因此，我们需要指定：是否希望将描述符集绑定到图形或计算管道。下一个参数是描述符所基于的布局。接下来的三个参数指定：第一个描述符集的索引、要绑定的集的数量和要绑定的集的数组。我们一会儿会回到这个问题上。最后两个参数指定一个用于动态描述符的偏移量数组。我们将在以后的章节中讨论这些。

如果现在运行程序，那么什么都不可见。问题是在投影矩阵中做了y翻转，这些顶点现在是按逆时针顺序，而不是顺时针。这将导致剔除。转到createGraphicsPipeline函数并修改：

```c
rasterizer.cullMode = VK_CULL_MODE_BACK_BIT;
rasterizer.frontFace = VK_FRONT_FACE_COUNTER_CLOCKWISE;
```

c