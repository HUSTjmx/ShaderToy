# Vulkan教程2



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

