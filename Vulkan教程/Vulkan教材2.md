# Vulkan教程2

[toc]

### 1. Vertex input description

#### Vertex shader

```c
#version 450
#extension GL_ARB_separate_shader_objects : enable

layout(location = 0) in vec2 inPosition;
layout(location = 1) in vec3 inColor;

layout(location = 0) out vec3 fragColor;

void main() {
    gl_Position = vec4(inPosition, 0.0, 1.0);
    fragColor = inColor;
}
```

inPosition和inColor变量是顶点属性。确保重新编译顶点着色器!	Just like `fragColor`, the `layout(location = x)` annotations assign indices to the inputs that we can later use to reference them. It is important to know that some types, like `dvec3` 64 bit vectors, use multiple *slots*. That means that the index after it must be at least 2 higher：

```
layout(location = 0) in dvec3 inPosition;
layout(location = 2) in vec3 inColor;
```

You can find more info about the layout qualifier in the [OpenGL wiki](https://www.khronos.org/opengl/wiki/Layout_Qualifier_(GLSL)).



#### Vertex data

我们将顶点数据从着色器移动到程序中的数组中。首先==包含GLM库==，它为我们提供了与线性代数相关的类型，如向量和矩阵。我们将使用这些类型来指定位置和颜色向量。==创建一个名为Vertex的新结构==，带有两个属性，我们将在顶点着色器中使用它们：

```c
struct Vertex {
    glm::vec2 pos;
    glm::vec3 color;
};

const std::vector<Vertex> vertices = {
    {{0.0f, -0.5f}, {1.0f, 0.0f, 0.0f}},
    {{0.5f, 0.5f}, {0.0f, 1.0f, 0.0f}},
    {{-0.5f, 0.5f}, {0.0f, 0.0f, 1.0f}}
};
```



#### Binding descriptions

下一步是：一旦顶点数据被上传到GPU内存，告诉Vulkan如何传递数据格式到顶点着色器。==需要两种类型的结构来传递这些信息==。第一个结构是`VkVertexInputBindingDescription`，我们将添加一个成员函数到顶点结构，以==填充正确的数据==。

```c
struct Vertex {
    glm::vec2 pos;
    glm::vec3 color;

    static VkVertexInputBindingDescription getBindingDescription() {
        VkVertexInputBindingDescription bindingDescription{};

        return bindingDescription;
    }
};
```

顶点绑定（vertex binding）描述了从各个顶点从内存中加载数据的速率。它指定数据项之间的字节数，以及是在每个顶点之后还是在每个实例之后移动到下一个数据项

```c
VkVertexInputBindingDescription bindingDescription{};
bindingDescription.binding = 0;
bindingDescription.stride = sizeof(Vertex);
bindingDescription.inputRate = VK_VERTEX_INPUT_RATE_VERTEX;
```

所有顶点的数据都被打包在一个数组中，所以我们只会有一个绑定。`binding`参数指定绑定数组中的绑定索引。`stride`参数指定从一个条目到下一个条目的字节数，`inputRate`参数可以有以下值：

- `VK_VERTEX_INPUT_RATE_VERTEX`: Move to the next data entry after ==each vertex==
- `VK_VERTEX_INPUT_RATE_INSTANCE`: Move to the next data entry after ==each instance==

我们不打算使用实例渲染，所以我们将坚持每个顶点数据。



#### Attribute descriptions

第二个结构是 `VkVertexInputAttributeDescription`（描述如何处理顶点输入）。我们将为Vertex添加另一个辅助函数来填充这些结构。

```c
#include <array>

...

static std::array<VkVertexInputAttributeDescription, 2> getAttributeDescriptions() {
    std::array<VkVertexInputAttributeDescription, 2> attributeDescriptions{};

    return attributeDescriptions;
}
```

正如函数原型所示，将会有两个这样的结构。属性描述结构（attribute description struct）描述如何从==源自binding description的顶点数据块中==提取顶点属性。我们有两个属性，位置和颜色，所以我们需要两个属性描述结构。

```c
attributeDescriptions[0].binding = 0;
attributeDescriptions[0].location = 0;
attributeDescriptions[0].format = VK_FORMAT_R32G32_SFLOAT;
attributeDescriptions[0].offset = offsetof(Vertex, pos);
```

`binding`参数告诉Vulkan：顶点数据来自哪个绑定。`location`参数引用顶点着色器中输入的位置指令。 The input in the vertex shader with location 0 is the position, which has two 32-bit float components。`format`参数描述属性的数据类型。令人困惑的是，这些格式使用 与颜色格式相同的 枚举来指定。The following shader types and formats are commonly used together：

- `float`: `VK_FORMAT_R32_SFLOAT`
- `vec2`: `VK_FORMAT_R32G32_SFLOAT`
- `vec3`: `VK_FORMAT_R32G32B32_SFLOAT`
- `vec4`: `VK_FORMAT_R32G32B32A32_SFLOAT`

如你所见，应该使用格式，让==颜色通道数量==与==着色器数据类型中的组件数量==相匹配。允许使用比着色器中组件数量更多的通道，但它们将被默默丢弃。颜色类型(SFLOAT、UINT、SINT)和位宽也应与着色器输入的类型相匹配。请看下面的例子：

- `ivec2`: `VK_FORMAT_R32G32_SINT`, a 2-component vector of 32-bit signed integers
- `uvec4`: `VK_FORMAT_R32G32B32A32_UINT`, a 4-component vector of 32-bit unsigned integers
- `double`: `VK_FORMAT_R64_SFLOAT`, a double-precision (64-bit) float

`format`参数隐式定义：属性数据的字节大小，`offset`参数指定：每个顶点数据开始读取的字节偏移量（pos是0，而color则是sizeof(pos)），使用宏自动计算。

```c
attributeDescriptions[1].binding = 0;
attributeDescriptions[1].location = 1;
attributeDescriptions[1].format = VK_FORMAT_R32G32B32_SFLOAT;
attributeDescriptions[1].offset = offsetof(Vertex, color);
```



#### Pipeline vertex input

通过引用`createGraphicsPipeline`中的结构来设置图形管道，来接受这种格式的顶点数据。找到`vertexInputInfo`结构体并修改它以引用两个描述：

```c
auto bindingDescription = Vertex::getBindingDescription();
auto attributeDescriptions = Vertex::getAttributeDescriptions();

vertexInputInfo.vertexBindingDescriptionCount = 1;
vertexInputInfo.vertexAttributeDescriptionCount = static_cast<uint32_t>(attributeDescriptions.size());
vertexInputInfo.pVertexBindingDescriptions = &bindingDescription;
vertexInputInfo.pVertexAttributeDescriptions = attributeDescriptions.data();
```

管道现在已经准备好接受此格式的顶点数据，并将其传递到顶点着色器。如果下运行程序，将看到它会报错：没有绑定到绑定的顶点缓冲区。==下一步是：创建一个顶点缓冲区并移动顶点数据到它，以便GPU能够访问它。==





### 2. Vertex buffer creation

==Vulkan中的缓冲区：用于存储GPU可以读取的任意数据==。当然可以用来存储顶点数据，但也可以用于其他用途，我们将在以后的章节中探索。与我们目前所处理的Vulkan对象不同，缓冲区不会自动为自己分配内存。前几章的工作已经表明，Vulkan API将几乎所有事情都置于程序猿的控制之中，而内存管理就是其中之一。



#### Buffer creation

创建一个新的函数`createVertexBuffer`，并在`createCommandBuffers`之前调用它。

```c
void initVulkan() {
    createInstance();
    setupDebugMessenger();
    createSurface();
    pickPhysicalDevice();
    createLogicalDevice();
    createSwapChain();
    createImageViews();
    createRenderPass();
    createGraphicsPipeline();
    createFramebuffers();
    createCommandPool();
    createVertexBuffer();
    createCommandBuffers();
    createSyncObjects();
}

...

void createVertexBuffer() {

}
```

创建缓冲区需要填充`VkBufferCreateInfo`结构。

```c
VkBufferCreateInfo bufferInfo{};
bufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
bufferInfo.size = sizeof(vertices[0]) * vertices.size();
```

结构的第一个字段是`size`，它以字节为单位指定缓冲区的大小。

```c
bufferInfo.usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT;
```

第二个字段是`usage`，它指示将使用缓冲区中的数据用于什么目的。我们的用例将是一个顶点缓冲区，但将在以后的章节中看到其他类型的使用。

```c
bufferInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;
```

就像交换链中的`Image`一样，缓冲区也可以由特定队列族`queue family`拥有，或者在多个队列族之间共享。缓冲区将只在图形队列中使用，因此我们可以坚持独占访问（exclusive access）。

`flags`参数用于配置==稀疏缓冲区内存==（sparse buffer memory），目前与此无关。我们将保留它的默认值为0。我们现在可以使用`vkCreateBuffer`创建缓冲区。定义一个类成员来保存缓冲区句柄，将其称为`vertexBuffer`。

```c
VkBuffer vertexBuffer;

...

void createVertexBuffer() {
    VkBufferCreateInfo bufferInfo{};
    bufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    bufferInfo.size = sizeof(vertices[0]) * vertices.size();
    bufferInfo.usage = VK_BUFFER_USAGE_VERTEX_BUFFER_BIT;
    bufferInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;

    if (vkCreateBuffer(device, &bufferInfo, nullptr, &vertexBuffer) != VK_SUCCESS) {
        throw std::runtime_error("failed to create vertex buffer!");
    }
}
```

在程序结束之前，缓冲区应该可以用于rendering commands，并且它不依赖交换链，所以我们将在原始的cleanup函数中清理它

```
void cleanup() {
    cleanupSwapChain();

    vkDestroyBuffer(device, vertexBuffer, nullptr);

    ...
}
```

#### Memory requirements

缓冲区已经创建，但实际上还没有为它分配任何内存。为缓冲区分配内存的第一步是：使用`vkGetBufferMemoryRequirements`函数查询其内存需求。

```c
VkMemoryRequirements memRequirements;
vkGetBufferMemoryRequirements(device, vertexBuffer, &memRequirements);
```

`VkMemoryRequirements`结构体有三个字段:

- `size`: 所需求的内存（单位：bit）, may differ from `bufferInfo.size`。
- `alignment`: 从已分配内存区域开始的字节偏移量，depends on `bufferInfo.usage` and `bufferInfo.flags`.
- `memoryTypeBits`: 适合缓冲区的内存类型的位域`bit field`。

==图形卡可以提供不同类型的内存来进行分配==。每种类型的内存，在允许的操作和性能特征方面都有所不同。我们需要结合缓冲区的需求和我们自己的应用程序需求，以找到要使用的正确内存类型。为此，我们创建一个新的函数`findMemoryType`。

```c
uint32_t findMemoryType(uint32_t typeFilter, VkMemoryPropertyFlags properties) {

}
```

首先，我们需要使用`vkGetPhysicalDeviceMemoryProperties`来查询关于可用内存类型的信息：

```c
VkPhysicalDeviceMemoryProperties memProperties;
vkGetPhysicalDeviceMemoryProperties(physicalDevice, &memProperties);
```

`VkPhysicalDeviceMemoryProperties`结构有两个数组：`memoryTypes`和`memoryHeaps`。`memoryHeaps`是不同的内存资源，如专用的VRAM和当VRAM耗尽时，RAM中的交换空间`swap space`。现在我们只关心内存的类型，而不是它来自的堆，但这可能会影响性能。首先找到一种适合缓冲区本身的内存类型：

```c
for (uint32_t i = 0; i < memProperties.memoryTypeCount; i++) {
    if (typeFilter & (1 << i)) {
        return i;
    }
}

throw std::runtime_error("failed to find suitable memory type!");
```

`typeFilter`参数将用于指定适合的内存类型的位字段。这意味着可以通过简单地遍历它们，并检查相应的位是否被设置为1来找到合适的内存类型的索引。

然而，我们不仅仅对适合顶点缓冲区的内存类型感兴趣。我们还需要能够将顶点数据写入内存。`memoryTypes`数组由`VkMemoryType`结构体组成，这==些结构体指定堆和每种类型内存的属性==。这些属性定义了内存的特殊特性，比如能够对其进行映射，以便从CPU写入内存。这个属性用`VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT`表示，但是我们还需要使用`VK_MEMORY_PROPERTY_HOST_COHERENT_BIT`。We'll see why when we map the memory。

我们现在可以修改循环来检查这个属性的支持程度：

```c
for (uint32_t i = 0; i < memProperties.memoryTypeCount; i++) {
    if ((typeFilter & (1 << i)) && (memProperties.memoryTypes[i].propertyFlags & properties) == properties) {
        return i;
    }
}
```

我们可能有不止一个理想的属性，所以我们应该检查结果等于期望的属性位字段。



#### Memory allocation

现在我们有了一种方法来确定正确的内存类型，因此我们可以通过填充`VkMemoryAllocateInfo`结构来实际分配内存，

```c
VkMemoryAllocateInfo allocInfo{};
allocInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
allocInfo.allocationSize = memRequirements.size;
allocInfo.memoryTypeIndex = findMemoryType(memRequirements.memoryTypeBits, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
```

内存分配现在就像指定大小和类型一样简单，这两者都来自于顶点缓冲区的内存需求和所需的属性。创建一个类成员来存储内存的句柄，并用`vkAllocateMemory`分配它。

```c
VkBuffer vertexBuffer;
VkDeviceMemory vertexBufferMemory;

...

if (vkAllocateMemory(device, &allocInfo, nullptr, &vertexBufferMemory) != VK_SUCCESS) {
    throw std::runtime_error("failed to allocate vertex buffer memory!");
}
```

如果内存分配成功，那么我们现在可以使用vkBindBufferMemory将此内存与缓冲区关联：

```c
vkBindBufferMemory(device, vertexBuffer, vertexBufferMemory, 0);
```

前三个参数是显然的，第四个参数是内存区域内的偏移量。因为这个内存是专门这个顶点缓冲区分配的，所以偏移量就是0。如果偏移量是非零的，那么它必须被`memrequirementes .alignment`整除。

当然，就像c++中的动态内存分配一样，内存应该在某个时候被释放。绑定到缓冲区对象的内存可能会在缓冲区不再使用时被释放，所以让我们在缓冲区被销毁后释放它

```c
void cleanup() {
    cleanupSwapChain();

    vkDestroyBuffer(device, vertexBuffer, nullptr);
    vkFreeMemory(device, vertexBufferMemory, nullptr);
```



#### Filling the vertex buffer

==是时候将顶点数据复制到缓冲区了==。这是通过使用`vkMapMemory`将缓冲区内存映射到CPU可访问内存来实现的。

```c
void* data;
vkMapMemory(device, vertexBufferMemory, 0, bufferInfo.size, 0, &data);
```

这个函数允许我们访问由偏移量和大小定义的指定内存资源区域。这里的偏移量和大小是0和`bufferInfo.zise`。也可以指定特殊值`VK_WHOLE_SIZE`来映射所有内存。倒数第二个参数可用于指定标志`flag`，但当前API中还没有可用的标志。必须将其设置为0。最后一个参数指定指向映射内存的指针。

```c
void* data;
vkMapMemory(device, vertexBufferMemory, 0, bufferInfo.size, 0, &data);
    memcpy(data, vertices.data(), (size_t) bufferInfo.size);
vkUnmapMemory(device, vertexBufferMemory);
```

现在可以简单地将顶点数据`memcpy`到映射的内存中，然后使用`vkUnmapMemory`取消映射。不幸的是，驱动程序可能不会立即将数据复制到缓冲区内存中，for example because of caching。也有可能对缓冲区的写操作在映射的内存中还不可见。有两种方法来处理这个问题：

- Use a memory heap that is host coherent, indicated with `VK_MEMORY_PROPERTY_HOST_COHERENT_BIT`
- Call [`vkFlushMappedMemoryRanges`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkFlushMappedMemoryRanges.html) after writing to the mapped memory, and call [`vkInvalidateMappedMemoryRanges`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkInvalidateMappedMemoryRanges.html) before reading from the mapped memory

我们选择了第一种方法，它确保映射的内存总是与分配的内存的内容匹配。请记住，这可能导致比显式刷新性能稍差的性能，但我们将在下一章中看到为什么这无关紧要。

刷新内存范围或使用一致的内存堆意味着驱动程序将意识到：我们在写缓冲区，但这并不意味着它们在GPU上是可见的。数据到GPU的传输是一个在后台发生的操作，规范只是告诉我们，它保证在下一次调用`vkQueueSubmit`时是完整的。



#### Binding the vertex buffer

现在剩下的就是在渲染操作期间绑定顶点缓冲区。我们会扩展`createCommandBuffers`函数来做这个。

```c
vkCmdBindPipeline(commandBuffers[i], VK_PIPELINE_BIND_POINT_GRAPHICS, graphicsPipeline);

VkBuffer vertexBuffers[] = {vertexBuffer};
VkDeviceSize offsets[] = {0};
vkCmdBindVertexBuffers(commandBuffers[i], 0, 1, vertexBuffers, offsets);

vkCmdDraw(commandBuffers[i], static_cast<uint32_t>(vertices.size()), 1, 0, 0);
```

`vkCmdBindVertexBuffers`将顶点缓冲区绑定到bindings，就像我们在前一章中设置的那样。除了命令缓冲区之外，前两个参数指定了偏移量和绑定数，我们将为其指定顶点缓冲区。最后两个参数指定要绑定的顶点缓冲区数组和开始读取顶点数据的字节偏移量。还应该更改`vkCmdDraw`的调用，以传递缓冲区中顶点的数量，而不是硬编码的数字3。



### 3. Staging buffer

我们现在的顶点缓冲区可以正常工作，但从CPU访问它的内存类型，可能不是显卡本身读取的最优化内存类型。最理想的内存具有`VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT`标志，通常在专用显卡上，CPU无法访问。在本章中，我们要创建两个顶点缓冲区。一个暂存缓冲区`staging buffer`，在CPU可访问的内存中，用于将顶点数组的数据上传到GPU上，最后一个顶点缓冲区在设备本地内存中。==然后我们将使用缓冲区复制命令将数据从暂存缓冲区移动到实际的顶点缓冲区。==

#### Transfer queue

缓冲区复制命令需要一个支持传输操作的队列族，使用`VK_QUEUE_TRANSFER_BIT`表示。好消息是，任何具有`VK_QUEUE_GRAPHICS_BIT`或`VK_QUEUE_COMPUTE_BIT`的队列族已经隐式地支持``VK_QUEUE_TRANSFER_BIT``。在这些情况下，不需要在`queueFlags`中显式地列出它的实现。

如果您喜欢挑战，那么您仍然可以尝试使用专门用于传输操作的不同队列族。它将要求您对您的程序进行以下修改：

- Modify `QueueFamilyIndices` and `findQueueFamilies` to explicitly look for a queue family with the `VK_QUEUE_TRANSFER_BIT` bit, but not the `VK_QUEUE_GRAPHICS_BIT`.
- Modify `createLogicalDevice` to request a handle to the transfer queue
- Create a second command pool for command buffers that are submitted on the transfer queue family
- Change the `sharingMode` of resources to be `VK_SHARING_MODE_CONCURRENT` and specify both the graphics and transfer queue families
- Submit any transfer commands like [`vkCmdCopyBuffer`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/vkCmdCopyBuffer.html) (which we'll be using in this chapter) to the transfer queue instead of the graphics queue



#### Abstracting buffer creation

因为我们将在本章中创建多个缓冲区，所以将缓冲区创建移到辅助函数中是一个好主意。创建一个新的函数`createBuffer`，并将createVertexBuffer中的代码(除了映射)移动到它

```c
void createBuffer(VkDeviceSize size, VkBufferUsageFlags usage, VkMemoryPropertyFlags properties, VkBuffer& buffer, VkDeviceMemory& bufferMemory) {
    VkBufferCreateInfo bufferInfo{};
    bufferInfo.sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO;
    bufferInfo.size = size;
    bufferInfo.usage = usage;
    bufferInfo.sharingMode = VK_SHARING_MODE_EXCLUSIVE;

    if (vkCreateBuffer(device, &bufferInfo, nullptr, &buffer) != VK_SUCCESS) {
        throw std::runtime_error("failed to create buffer!");
    }

    VkMemoryRequirements memRequirements;
    vkGetBufferMemoryRequirements(device, buffer, &memRequirements);

    VkMemoryAllocateInfo allocInfo{};
    allocInfo.sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO;
    allocInfo.allocationSize = memRequirements.size;
    allocInfo.memoryTypeIndex = findMemoryType(memRequirements.memoryTypeBits, properties);

    if (vkAllocateMemory(device, &allocInfo, nullptr, &bufferMemory) != VK_SUCCESS) {
        throw std::runtime_error("failed to allocate buffer memory!");
    }

    vkBindBufferMemory(device, buffer, bufferMemory, 0);
}
```

请确保为缓冲区大小、内存属性和使用情况添加参数，以便我们可以使用此函数创建许多不同类型的缓冲区。最后两个参数是要写入句柄的输出变量。您现在可以从createVertexBuffer中删除缓冲区创建和内存分配代码，而只调用`createBuffer`

```c
void createVertexBuffer() {
    VkDeviceSize bufferSize = sizeof(vertices[0]) * vertices.size();
    createBuffer(bufferSize, VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, vertexBuffer, vertexBufferMemory);

    void* data;
    vkMapMemory(device, vertexBufferMemory, 0, bufferSize, 0, &data);
        memcpy(data, vertices.data(), (size_t) bufferSize);
    vkUnmapMemory(device, vertexBufferMemory);
}
```



#### Using a staging buffer

我们们现在要改变createVertexBuffer，只使用一个主机可见缓冲区作为临时缓冲区，使用一个设备本地缓冲区作为实际的顶点缓冲区。

```c
void createVertexBuffer() {
    VkDeviceSize bufferSize = sizeof(vertices[0]) * vertices.size();

    VkBuffer stagingBuffer;
    VkDeviceMemory stagingBufferMemory;
    createBuffer(bufferSize, VK_BUFFER_USAGE_TRANSFER_SRC_BIT, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, stagingBuffer, stagingBufferMemory);

    void* data;
    vkMapMemory(device, stagingBufferMemory, 0, bufferSize, 0, &data);
        memcpy(data, vertices.data(), (size_t) bufferSize);
    vkUnmapMemory(device, stagingBufferMemory);

    createBuffer(bufferSize, VK_BUFFER_USAGE_TRANSFER_DST_BIT | VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, vertexBuffer, vertexBufferMemory);
}
```

我们现在使用一个带有`stagingBufferMemory`的`stagingBuffer`来映射和复制顶点数据。在本章中，我们将使用两个新的缓冲区使用标志：

- `VK_BUFFER_USAGE_TRANSFER_SRC_BIT`: Buffer can be used as ==source== in a memory transfer operation.
- `VK_BUFFER_USAGE_TRANSFER_DST_BIT`: Buffer can be used as ==destination== in a memory transfer operation.

`vertexBuffer`现在是从本地设备的内存类型分配的，这意味着我们不能使用`vkMapMemory`。但是，我们可以将数据从`stagingBuffer`复制到`vertexBuffer`。我们必须指定stagingBuffer的传输源标志和vertexBuffer的传输目的地标志，以及顶点缓冲区的使用标志来表示我们打算这样做。我们现在要写一个函数来将内容从一个缓冲区复制到另一个缓冲区，叫做`copyBuffer`。

```C
void copyBuffer(VkBuffer srcBuffer, VkBuffer dstBuffer, VkDeviceSize size) {

}
```

内存传输操作是使用命令缓冲区执行的，就像绘制命令一样。因此，必须首先分配一个临时命令缓冲区。您可能希望为这类短暂寿命的缓冲区创建一个单独的命令池，因为该实现可能能够应用内存分配优化。这种情况下，在命令池生成过程中使用`VK_COMMAND_POOL_CREATE_TRANSIENT_BIT`标志。:arrow_down:

```c
void copyBuffer(VkBuffer srcBuffer, VkBuffer dstBuffer, VkDeviceSize size) {
    VkCommandBufferAllocateInfo allocInfo{};
    allocInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO;
    allocInfo.level = VK_COMMAND_BUFFER_LEVEL_PRIMARY;
    allocInfo.commandPool = commandPool;
    allocInfo.commandBufferCount = 1;

    VkCommandBuffer commandBuffer;
    vkAllocateCommandBuffers(device, &allocInfo, &commandBuffer);
}
```

并立即开始记录命令缓冲区:arrow_down:

```c
VkCommandBufferBeginInfo beginInfo{};
beginInfo.sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO;
beginInfo.flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT;

vkBeginCommandBuffer(commandBuffer, &beginInfo);
```

我们将只使用一次命令缓冲区，并等待函数返回，直到复制操作完成。使用`VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT`来告诉驱动程序我们的意图是一种很好的做法。:arrow_up:

```
VkBufferCopy copyRegion{};
copyRegion.srcOffset = 0; // Optional
copyRegion.dstOffset = 0; // Optional
copyRegion.size = size;
vkCmdCopyBuffer(commandBuffer, srcBuffer, dstBuffer, 1, &copyRegion);
```

使用`vkCmdCopyBuffer`命令传输缓冲区的内容。它接受源缓冲区和目标缓冲区作为参数，以及要复制的区域数组。这些区域是在VkBufferCopy结构中定义的，由源缓冲区偏移量、目标缓冲区偏移量和大小组成。与`vkMapMemory`命令不同，不能在这里指定`VK_WHOLE_SIZE`。:arrow_up:

```c
vkEndCommandBuffer(commandBuffer);
```

这个命令缓冲区只包含复制命令，因此我们可以在那之后立即停止记录:arrow_up:。现在执行命令缓冲区来完成传输:arrow_down:

```c
VkSubmitInfo submitInfo{};
submitInfo.sType = VK_STRUCTURE_TYPE_SUBMIT_INFO;
submitInfo.commandBufferCount = 1;
submitInfo.pCommandBuffers = &commandBuffer;

vkQueueSubmit(graphicsQueue, 1, &submitInfo, VK_NULL_HANDLE);
vkQueueWaitIdle(graphicsQueue);
```

==与draw命令不同，这次我们不需要等待事件==。我们只想立即在缓冲区上执行传输，有两种可能的方法来等待此传输完成。我们可以使用fence并使用`vkwaitforfence`，或者使用`vkQueueWaitIdle`简单地等待传输队列变为空闲。fence允许您同时调度多个传输并等待所有传输完成，而不是一次执行一个。这可能有更多优化的机会。:arrow_up:

```c
vkFreeCommandBuffers(device, commandPool, 1, &commandBuffer);
```

我们现在可以从`createVertexBuffer`函数调用`copyBuffer`来将顶点数据移动到设备本地缓冲区：:arrow_down:

```c
createBuffer(bufferSize, VK_BUFFER_USAGE_TRANSFER_DST_BIT | VK_BUFFER_USAGE_VERTEX_BUFFER_BIT, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, vertexBuffer, vertexBufferMemory);

copyBuffer(stagingBuffer, vertexBuffer, bufferSize);
```

将数据从暂存缓冲区复制到设备缓冲区后，我们应该清理它。:arrow_down:

```c
copyBuffer(stagingBuffer, vertexBuffer, bufferSize);

vkDestroyBuffer(device, stagingBuffer, nullptr);
vkFreeMemory(device, stagingBufferMemory, nullptr);
```

运行您的程序来验证您是否再次看到了熟悉的三角形。改进现在可能还不明显，但是它的顶点数据现在正在从高性能内存中加载。当我们要渲染更复杂的几何图形时，这一点很重要。

#### Conclusion

应该注意的是，在真实的应用程序中，==不应该为每个单独的缓冲区实际调用vkAllocateMemory==。同时分配的最大内存数量受到`maxMemoryAllocationCount`物理设备限制的限制，即使在像NVIDIA GTX 1080这样的高端硬件上，也可能低至4096。==同时为大量对象分配内存的正确方法是==：创建一个自定义分配器，通过使用我们在许多函数中看到的偏移量参数，在许多不同的对象之间分割一次，进行分配。

可以自己实现这样的分配器，==也可以使用GPUOpen倡议提供的VulkanMemoryAllocator库==。然而，对于本教程来说，可以对每个资源使用单独的分配，因为我们目前还没有接近这些限制。





### 4. Index buffer

画一个矩形需要两个三角形，这意味着我们的顶点缓冲区需要有6个顶点。问题是两个顶点的数据是重复的，从而导致50%的冗余。在更复杂的网格中，它只会变得更糟，==顶点在平均3个三角形中被重用。此问题的解决方案是使用索引缓冲区==。

==索引缓冲区本质上是一个指向顶点缓冲区的指针数组==。它允许您重新排序顶点数据，并重用多个顶点的现有数据。



#### Index buffer creation

在本章中，我们将修改顶点数据，并添加索引数据来绘制一个像图中那样的矩形。修改顶点数据以表示四个角：

```c
const std::vector<Vertex> vertices = {
    {{-0.5f, -0.5f}, {1.0f, 0.0f, 0.0f}},
    {{0.5f, -0.5f}, {0.0f, 1.0f, 0.0f}},
    {{0.5f, 0.5f}, {0.0f, 0.0f, 1.0f}},
    {{-0.5f, 0.5f}, {1.0f, 1.0f, 1.0f}}
};
```

我们将添加一个新的数组索引，来表示索引缓冲区的内容。它应该匹配插图中的索引，以绘制右上三角形和左下三角形。

```c
const std::vector<uint16_t> indices = {
    0, 1, 2, 2, 3, 0
};
```

根据顶点数量，可以对索引缓冲区使用`uint16_t`或`uint32_t`。我们可以坚持使用`uint16_t`，因为我们使用的顶点少于65535个。

就像顶点数据，索引需要被上传到一个`VkBuffer`，让GPU能够访问它们。定义两个新的类成员来保存索引缓冲区的资源

```c
VkBuffer vertexBuffer;
VkDeviceMemory vertexBufferMemory;
VkBuffer indexBuffer;
VkDeviceMemory indexBufferMemory;
```

我们现在要添加的`createIndexBuffer`函数几乎与`createVertexBuffer`相同

```c
void initVulkan() {
    ...
    createVertexBuffer();
    createIndexBuffer();
    ...
}

void createIndexBuffer() {
    VkDeviceSize bufferSize = sizeof(indices[0]) * indices.size();

    VkBuffer stagingBuffer;
    VkDeviceMemory stagingBufferMemory;
    createBuffer(bufferSize, VK_BUFFER_USAGE_TRANSFER_SRC_BIT, VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT, stagingBuffer, stagingBufferMemory);

    void* data;
    vkMapMemory(device, stagingBufferMemory, 0, bufferSize, 0, &data);
    memcpy(data, indices.data(), (size_t) bufferSize);
    vkUnmapMemory(device, stagingBufferMemory);

    createBuffer(bufferSize, VK_BUFFER_USAGE_TRANSFER_DST_BIT | VK_BUFFER_USAGE_INDEX_BUFFER_BIT, VK_MEMORY_PROPERTY_DEVICE_LOCAL_BIT, indexBuffer, indexBufferMemory);

    copyBuffer(stagingBuffer, indexBuffer, bufferSize);

    vkDestroyBuffer(device, stagingBuffer, nullptr);
    vkFreeMemory(device, stagingBufferMemory, nullptr);
}
```

:arrow_up:==只有两个明显的区别==。缓冲区的大小`bufferSize`现在等于索引的数量乘以索引类型的大小；`indexBuffer`的参数`usage`应该是`VK_BUFFER_USAGE_INDEX_BUFFER_BIT`，而不是`VK_BUFFER_USAGE_VERTEX_BUFFER_BIT`。除此之外，过程是完全一样的。我们创建一个staging buffer 来复制索引的内容，然后将其复制到` final device local index buffer`。

索引缓冲区应该在程序结束时清理，就像顶点缓冲区一样:arrow_down:：

```c
void cleanup() {
    cleanupSwapChain();

    vkDestroyBuffer(device, indexBuffer, nullptr);
    vkFreeMemory(device, indexBufferMemory, nullptr);

    vkDestroyBuffer(device, vertexBuffer, nullptr);
    vkFreeMemory(device, vertexBufferMemory, nullptr);

    ...
}
```



#### Using an index buffer

使用索引缓冲区进行绘图，涉及到对`createCommandBuffers`的两个更改。我们首先需要绑定索引缓冲区，就像我们绑定顶点缓冲区一样。不同之处在于只能有一个索引缓冲区。不幸的是，不可能对每个顶点属性使用不同的索引，所以即使只有一个属性不同，我们仍然需要完全复制顶点数据。

```c
vkCmdBindVertexBuffers(commandBuffers[i], 0, 1, vertexBuffers, offsets);
vkCmdBindIndexBuffer(commandBuffers[i], indexBuffer, 0, VK_INDEX_TYPE_UINT16);
```

索引缓冲区通过`vkCmdBindIndexBuffer`绑定，vkCmdBindIndexBuffer有索引缓冲区、字节偏移量和作为参数的索引数据类型。如前所述，可能的类型是`VK_INDEX_TYPE_UINT16`和`VK_INDEX_TYPE_UINT32`:arrow_up:

==仅仅绑定索引缓冲区还不能改变任何东西，我们还需要改变绘图命令来告诉Vulkan使用索引缓冲区==。删除`vkCmdDraw`并将其替换为`vkCmdDrawIndexed`:arrow_down:

```c
vkCmdDrawIndexed(commandBuffers[i], static_cast<uint32_t>(indices.size()), 1, 0, 0, 0);
```

对这个函数的调用非常类似于`vkCmdDraw`。从第二个参数开始，==前两个参数==指定索引的数量和实例的数量。我们没有使用实例化，所以只指定一个实例。索引的数量表示将被传递到顶点缓冲区的顶点的数量；==下一个参数==指定：到索引缓冲区的偏移量，使用值1将导致图形卡从第二个索引处开始读取；==倒数第二个参数==指定：要添加到索引缓冲区中的索引的偏移量；==最后一个参数==指定了实例化的偏移量

前一章已经提到，应该从一个内存分配中分配多个资源(如缓冲区)，但实际上应该更进一步。驱动程序开发人员建议将多个缓冲区（比如顶点缓冲区和索引缓冲区）存储到一个`VkBuffer`中，并在`vkCmdBindVertexBuffers`命令中使用偏移量。这样做的好处是，在这种情况下，您的数据对缓存更友好，因为它们之间的距离更近。如果在相同的渲染操作中没有使用相同的内存块，甚至可以为多个资源，重用相同的内存块