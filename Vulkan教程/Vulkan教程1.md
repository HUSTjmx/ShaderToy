# Vulkan教程1





## 开发环境

首先，假设我们使用系统是Win10，采用Visual Studio进行开发

==Vulkan SDK==

开发Vulkan最重要的组件是SDK，类似于OpenGL的GLEW，[下载网址](https://vulkan.lunarg.com/)，下载好之后直接点击EXE。安装完成后要做的第一件事是验证图形卡和驱动程序是否正确支持Vulkan。转到安装SDK的`Bin`目录，打开目录并运行`vkcube.exe`演示，正确结果如下：

![](https://jmx-paper.oss-cn-beijing.aliyuncs.com/Vulkan/Picture/cube_demo.png)

> 目录中还有另一个程序对开发有用。`glslangValidator.exe`和`glslc.exe`程序将被用于编译从人类可读着色[GLSL](https://en.wikipedia.org/wiki/OpenGL_Shading_Language)到字节码。

==GLFW和GLM==

这两个库在OpenGL的学习中已经用到，这里我也懒得写了，直接给一个我已经配好的[文件夹]()

然后老生常谈，放在自定义的路径下的话，去项目属性里面设置依赖库啥的，唯一需要注意的是，这里的环境是64位的。

> [原教程地址](https://vulkan-tutorial.com/Development_environment)



## 画一个三角形

### 开始

#### 基本代码

我们将从如下代码开始

```c++
#include <vulkan/vulkan.h>

#include <iostream>
#include <stdexcept>
#include <cstdlib>

class HelloTriangleApplication {
public:
    void run() {
        initVulkan();
        mainLoop();
        cleanup();
    }

private:
    void initVulkan() {

    }

    void mainLoop() {

    }

    void cleanup() {

    }
};

int main() {
    HelloTriangleApplication app;

    try {
        app.run();
    } catch (const std::exception& e) {
        std::cerr << e.what() << std::endl;
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
```

我们首先包含LunarG SDK中的Vulkan.h，提供我们编程所需的函数，结构和枚举。`stdexcept`和`iostream`头用于报告和传播错误（eporting and propagating errors）。`cstdlib` 提供了`EXIT_SUCCESS`和`EXIT_FAILURE`宏。

程序本身被包装到一个类中，在该类中，我们将Vulkan对象存储为私有类成员，并添加函数来初始化每个对象。一切准备就绪后，我们进入主循环以开始渲染帧。我们将填写`mainLoop` 函数以包含一个循环，该循环将反复执行直到窗口关闭。窗口关闭并返回后，在`cleanup`函数中释放已使用的资源。

添加一个`initWindow`函数，并设置在其他调用之前用。我们将使用该函数初始化并创建一个窗口。写法和OpenGL一样，

```c++
const uint32_t WIDTH = 800;
const uint32_t HEIGHT = 600;
void initWindow() {
    glfwInit();
	//initWindow中的第一个调用应该是glfwInit()，它初始化了GLFW库。因为GLFW最初设计用来创建OpenGL上下文，所以我们需要告诉它不要在后续调用中创建OpenGL上下文
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    //因为处理调整大小的窗口需要特别小心，我们稍后将对此进行研究，所以禁用它
    glfwWindowHint(GLFW_RESIZABLE, GLFW_FALSE);
	//前三个参数指定窗口的宽度，高度和标题。第四个参数允许您有选择地指定一个监视器以打开		窗口，最后一个参数仅与OpenGL有关。
    window = glfwCreateWindow(WIDTH, HEIGHT, "Vulkan", nullptr, nullptr);
}
```

为了保持应用程序运行直到发生错误或关闭窗口，我们需要向`mainLoop`函数添加一个事件循环，如下所示：

```c++
void mainLoop() {
    while (!glfwWindowShouldClose(window)) {
        glfwPollEvents();
    }
}
```

窗口关闭后，我们需要通过销毁资源并终止GLFW本身来清理资源。这将是我们的第一个`cleanup`代码：

```c++
void cleanup() {
    glfwDestroyWindow(window);

    glfwTerminate();
}
```



#### 实例

第一件事是通过创建实例来初始化Vulkan库（应用程序和Vulkan库之间的连接），创建该实例涉及为驱动程序指定有关应用程序的一些详细信息。

首先添加一个`createInstance`函数并在该`initVulkan`函数中调用它 。另外，添加一个数据成员以持有该实例的句柄：

```c++
VkInstance instance;
```

现在，要创建实例==，我们首先必须在结构中填充一些有关我们应用程序的信息，以优化我们的应用程序==。该结构称为[`VkApplicationInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkApplicationInfo.html)：

```c#
void createInstance() {
    VkApplicationInfo appInfo{};
    appInfo.sType = VK_STRUCTURE_TYPE_APPLICATION_INFO;
    appInfo.pApplicationName = "Hello Triangle";
    appInfo.applicationVersion = VK_MAKE_VERSION(1, 0, 0);
    appInfo.pEngineName = "No Engine";
    appInfo.engineVersion = VK_MAKE_VERSION(1, 0, 0);
    appInfo.apiVersion = VK_API_VERSION_1_0;
}
```

如前所述，Vulkan中的许多结构要求在sType成员中显式地指定类型。这也是许多具有pNext成员的结构中的一个，pNext成员可以在将来指向扩展信息。我们在这里使用值初始化将其保留为nullptr。

Vulkan中有很多信息是通过结构体传递的，而不是通过函数参数传递的，==我们必须再填充一个结构体，以便为创建实例提供足够的信息==。下一个结构不是可选的，它告诉Vulkan驱动程序我们想要使用哪一个全局扩展和验证层。全局性意味着它们适用于整个程序，而不是特定的设备。

```c#
VkInstanceCreateInfo createInfo{};
createInfo.sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO;
createInfo.pApplicationInfo = &appInfo;
```

==接下来的两个属性指定所需的全局扩展==。正如在概述章节中提到的，Vulkan是一个平台无关的API，这意味着您需要一个扩展来与窗口系统进行接口。GLFW有一个方便的内置函数，它返回它需要的扩展名，我们可以将这些扩展名传递给结构体

```c++
uint32_t glfwExtensionCount = 0;
const char** glfwExtensions;

glfwExtensions = glfwGetRequiredInstanceExtensions(&glfwExtensionCount);

createInfo.enabledExtensionCount = glfwExtensionCount;
createInfo.ppEnabledExtensionNames = glfwExtensions;
```

结构的最后两个成员决定要启用的全局验证层。我们将在下一章更深入地讨论这些，所以现在先把这些空着。

```c++
createInfo.enabledLayerCount = 0;
VkResult result = vkCreateInstance(&createInfo, nullptr, &instance);
```

Vulkan中对象创建函数参数的一般模式如下

- Pointer to struct with creation info
- Pointer to custom allocator callbacks, always `nullptr` in this tutorial
- Pointer to the variable that stores the handle to the new object

```c++
if (vkCreateInstance(&createInfo, nullptr, &instance) != VK_SUCCESS) {
    throw std::runtime_error("failed to create instance!");
}
```

如果您查看vkCreateInstance文档，那么您将看到其中一个可能的错误是VK_ERROR_EXTENSION_NOT_PRESENT。我们可以简单地指定我们需要的扩展，并在错误返回时终止。这对于像窗口系统接口这样的基本扩展是有意义的，但是如果我们想要检查可选功能呢

要在创建实例之前检索受支持的扩展列表，可以使用vkEnumerateInstanceExtensionProperties函数。它使用一个指向存储扩展数量的变量的指针和一个VkExtensionProperties数组来存储扩展的详细信息。它还带有一个可选的first参数，该参数允许我们通过特定的验证层过滤扩展，我们现在将忽略这个验证层

要分配一个数组来保存扩展细节，我们首先需要知道有多少个扩展细节。您可以通过将后一个参数保留为空来请求扩展的数量

```c++
uint32_t extensionCount = 0;
vkEnumerateInstanceExtensionProperties(nullptr, &extensionCount, nullptr);
```

现在分配一个数组来保存扩展细节

```c++
std::vector<VkExtensionProperties> extensions(extensionCount);
vkEnumerateInstanceExtensionProperties(nullptr, &extensionCount, extensions.data());
```

可以使用vkDestroyInstance函数销毁VkInstance

```c++
 vkDestroyInstance(instance, nullptr);
```



#### 验证层

Vulkan API的设计理念是将驱动程序开销最小化，表现之一就是默认情况下API中的错误检查非常有限。即使是将枚举设置为不正确的值或将空指针传递这样简单的错误，通常也不会显式地处理，只会导致崩溃或未定义的行为。因为Vulkan要求你对你正在做的每件事都非常明确，所以很容易犯很多小错误，比如使用新的GPU功能，却忘记在逻辑设备创建时请求它。

但是，这并不意味着这些检查不能添加到API中。Vulkan为此引入了一个优雅的系统，称为验证层。验证层是可选的组件，它们连接到Vulkan函数调用以应用其他操作。验证层中常见的操作有

- 根据规范检查参数值以检测误用
- 跟踪对象的创建和破坏以查找资源泄漏
- 通过跟踪发出调用的线程来检查线程安全性
- 将每个调用及其参数记录到标准输出
- 跟踪Vulkan以进行分析和回放

下面是一个在诊断验证层中实现函数的示例

```c++
VkResult vkCreateInstance(
    const VkInstanceCreateInfo* pCreateInfo,
    const VkAllocationCallbacks* pAllocator,
    VkInstance* instance) {

    if (pCreateInfo == nullptr || instance == nullptr) {
        log("Null pointer passed to required parameter!");
        return VK_ERROR_INITIALIZATION_FAILED;
    }

    return real_vkCreateInstance(pCreateInfo, pAllocator, instance);
}
```

这些验证层可以自由堆叠，以包含您感兴趣的所有调试功能。您可以简单地为调试构建启用验证层，并在发布构建中完全禁用它们，这是两全其用

Vulkan没有提供任何内置的验证层，但是LunarG Vulkan SDK提供了一组很好的检查常见错误的层。它们也是完全开源的。使用验证层是避免应用程序意外依赖于未定义的行为而破坏不同驱动程序的最佳方法。只有在系统上安装了验证层之后才能使用它们。例如，LunarG验证层只在安装了Vulkan SDK的pc上可用。

以前在Vulkan中有两种不同类型的验证层：特定于实例的验证层和特定于设备的验证层。这个想法是，实例层只会检查与全局Vulkan对象(比如实例)相关的调用，而特定于设备的层只会检查与特定GPU相关的调用。特定于设备的层现在已经被弃用，这意味着实例验证层适用于所有Vulkan调用。规范文档仍然建议在设备级别启用验证层，以保证兼容性，这是某些实现所要求的。

##### ==使用验证层==

在本节中，我们将了解如何启用Vulkan SDK提供的标准诊断层。与扩展一样，需要通过指定验证层的名称来启用它们。所有有用的标准验证都被打包到SDK中包含的一个层中，这个层是`VK_LAYER_KHRONOS_validation`。

让我们首先向程序中添加两个配置变量，以指定要启用的层以及是否启用它们。我选择将该值基于程序是否在调试模式下编译。NDEBUG宏是c++标准的一部分，表示“不调试”。

```c++
const std::vector<const char*> validationLayers = {
    "VK_LAYER_KHRONOS_validation"
};

#ifdef NDEBUG
    const bool enableValidationLayers = false;
#else
    const bool enableValidationLayers = true;
#endif
```

我们将添加一个新函数checkValidationLayerSupport，它检查所有请求的层是否可用。首先使用vkEnumerateInstanceLayerProperties函数列出所有可用的层。它的用法与实例创建一章中讨论的vkEnumerateInstanceExtensionProperties相同。

```c++
bool checkValidationLayerSupport() {
    uint32_t layerCount;
    vkEnumerateInstanceLayerProperties(&layerCount, nullptr);

    std::vector<VkLayerProperties> availableLayers(layerCount);
    vkEnumerateInstanceLayerProperties(&layerCount, availableLayers.data());

    for (const char* layerName : validationLayers) {
        bool layerFound = false;

        for (const auto& layerProperties : availableLayers) {
            if (strcmp(layerName, layerProperties.layerName) == 0) {
                layerFound = true;
                break;
            }
        }

        if (!layerFound) {
            return false;
        }
	}
	return true;
}
```

最后，修改VkInstanceCreateInfo结构实例化，以包含验证层名称(如果启用了这些名称)

```c++
if (enableValidationLayers) {
    createInfo.enabledLayerCount = static_cast<uint32_t>(validationLayers.size());
    createInfo.ppEnabledLayerNames = validationLayers.data();
} else {
    createInfo.enabledLayerCount = 0;
}
```

##### ==信息回调==

默认情况下，验证层将把调试消息打印到标准输出，但是我们也可以通过在程序中提供显式回调来自己处理它们。这还将允许您决定希望看到哪种类型的消息，因为并非所有消息都是必要的(致命的)错误。如果你现在不想这样做，那么你可以跳到本章的最后一节。

要在程序中设置一个回调来处理消息和相关细节，我们必须使用VK_EXT_DEBUG_UTILS_EXTENSION_NAME 设置一个带有回调的调试信使。

我们将首先创建一个getRequiredExtensions函数，该函数将根据是否启用验证层返回所需的扩展列表

```c++
std::vector<const char*> getRequiredExtensions() {
    uint32_t glfwExtensionCount = 0;
    const char** glfwExtensions;
    glfwExtensions = glfwGetRequiredInstanceExtensions(&glfwExtensionCount);

    std::vector<const char*> extensions(glfwExtensions, glfwExtensions + glfwExtensionCount);

    if (enableValidationLayers) {
        extensions.push_back(VK_EXT_DEBUG_UTILS_EXTENSION_NAME);
    }

    return extensions;
}
```

总是需要GLFW指定的扩展，但是有条件地添加了debug messenger扩展。注意，我在这里使用了VK_EXT_DEBUG_UTILS_EXTENSION_NAME宏。使用这个宏可以避免输入错误。然后使用这个函数代替之前的GLFW扩展获取函数。

现在，让我们看看调试回调函数的外观。添加一个新的名为静态成员函数`debugCallback`，内部有`PFN_vkDebugUtilsMessengerCallbackEXT` 原型。`VKAPI_ATTR`和`VKAPI_CALL`确保函数具有供Vulkan调用的正确签名。

```c++
static VKAPI_ATTR VkBool32 VKAPI_CALL debugCallback(
    VkDebugUtilsMessageSeverityFlagBitsEXT messageSeverity,
    VkDebugUtilsMessageTypeFlagsEXT messageType,
    const VkDebugUtilsMessengerCallbackDataEXT* pCallbackData,
    void* pUserData) {

    std::cerr << "validation layer: " << pCallbackData->pMessage << std::endl;

    return VK_FALSE;
}
```

第一个参数指定消息的严重性，参考值如下：

- `K_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT`: 诊断消息
- `VK_DEBUG_UTILS_MESSAGE_SEVERITY_INFO_BIT_EXT`: 信息性消息，例如资源的创建
- `VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT`: 有关行为的消息不一定是错误，很可能是应用程序中的错误
- `VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT`: 有关无效行为并可能导致崩溃的消息

可以使用比较操作来检查消息是否与某些级别的严重性相当或更差

```c++
if (messageSeverity >= VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT) {
    // Message is important enough to show
}
```

messageType参数可以有以下值:

- `VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT`: 发生了一些与规范或性能无关的事件
- `VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT`: 发生了违反规范或指示可能的错误的事情
- `VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT`: Potential non-optimal use of Vulkan

pCallbackData参数引用一个VkDebugUtilsMessengerCallbackDataEXT结构体，该结构体包含消息本身的细节，最重要的成员是:

- `pMessage`: The debug message as a null-terminated string
- `pObjects`: Array of Vulkan object handles related to the message
- `objectCount`: Number of objects in array

最后，pUserData参数包含一个在设置回调期间指定的指针，允许您将自己的数据传递给它。回调返回一个布尔值，该布尔值指示是否应终止触发验证层消息的Vulkan调用。如果回调返回true，则该调用将因`VK_ERROR_VALIDATION_FAILED_EXT`错误而中止。通常这仅用于测试验证层本身，因此您应始终返回`VK_FALSE`。

现在剩下的就是告诉Vulkan回调函数了。也许有些令人惊讶，甚至Vulkan中的debug回调也使用需要显式创建和销毁的句柄进行管理。这样的回调是*调试Messenger的*一部分，您可以根据需要拥有任意数量的回调。在以下位置为此句柄添加一个类成员：

```c++
VkDebugUtilsMessengerEXT debugMessenger;
```

现在添加一个函数`setupDebugMessenger`：

```c++
void initVulkan() {
    createInstance();
    setupDebugMessenger();
}

void setupDebugMessenger() {
    if (!enableValidationLayers) return;

}
```

我们需要在结构中填充关于messenger及其回调的详细信息

```c#
VkDebugUtilsMessengerCreateInfoEXT createInfo{};
createInfo.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
createInfo.messageSeverity = VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
createInfo.messageType = VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;
createInfo.pfnUserCallback = debugCallback;
createInfo.pUserData = nullptr; // Optional
```

messageSeverity字段允许您指定希望调用回调的所有严重程度类型；类似地，messageType字段允许您筛选通知回调的消息类型。pfnUserCallback字段指定指向回调函数的指针。您可以选择传递指向pUserData字段的指针，该字段将通过pUserData参数传递给回调函数。例如，您可以使用它来传递一个指向HelloTriangleApplication类的指针。

这个结构应该传递给vkCreateDebugUtilsMessengerEXT函数，以创建VkDebugUtilsMessengerEXT对象。不幸的是，因为这个函数是一个扩展函数，所以它不会自动加载。我们必须使用vkGetInstanceProcAddr自己查找它的地址。我们将创建我们自己的代理函数在后台处理这个。我在HelloTriangleApplication类定义的正上方添加了它。

```c++
VkResult CreateDebugUtilsMessengerEXT(VkInstance instance, const VkDebugUtilsMessengerCreateInfoEXT* pCreateInfo, const VkAllocationCallbacks* pAllocator, VkDebugUtilsMessengerEXT* pDebugMessenger) {
    auto func = (PFN_vkCreateDebugUtilsMessengerEXT) vkGetInstanceProcAddr(instance, "vkCreateDebugUtilsMessengerEXT");
    if (func != nullptr) {
        return func(instance, pCreateInfo, pAllocator, pDebugMessenger);
    } else {
        return VK_ERROR_EXTENSION_NOT_PRESENT;
    }
}
```

如果函数无法加载，vkGetInstanceProcAddr函数将返回nullptr。现在，如果扩展对象可用，我们可以调用这个函数来创建它：

```c++
if (CreateDebugUtilsMessengerEXT(instance, &createInfo, nullptr, &debugMessenger) != VK_SUCCESS) {
    throw std::runtime_error("failed to set up debug messenger!");
}
```

该`VkDebugUtilsMessengerEXT`物体还需要与呼叫进行清理 `vkDestroyDebugUtilsMessengerEXT`。与`vkCreateDebugUtilsMessengerEXT` 该功能类似，需要显式加载。

```C#
void DestroyDebugUtilsMessengerEXT(VkInstance instance, VkDebugUtilsMessengerEXT debugMessenger, const VkAllocationCallbacks* pAllocator) {
    auto func = (PFN_vkDestroyDebugUtilsMessengerEXT) vkGetInstanceProcAddr(instance, "vkDestroyDebugUtilsMessengerEXT");
    if (func != nullptr) {
        func(instance, debugMessenger, pAllocator);
    }
}
```

> 这里可能会有一个安装问题，就是会报错“VK_LAYER_KHRONOS_validation not Found”，这里我也遇到了，解决方法如下：
>
> \0. Open home menu, **search for "vulkan configurator" or run "vkconfig.exe"** in where you installed vulkan. then you can see which layers are detected and their corresponding vulkan versions.
>
> \1. **Update your graphics card driver**,
> in my case, its Nvidia Driver for Vulkan and intel graphics card driver;
> in Nvidia Driver installation process, select "clean install";
>
> \2. **Uninstall Vulkan SDK** the usual way.
>
> \3. **Run "regedit.exe"**, goto *HKEY_LOCAL_MACHINE\SOFTWARE\Khronos\Vulkan\ExplicitLayers* and there delete any of the validation layer items (i.e. those which would have SDK path), if there are any. Do the same for *HKLM\SOFTWARE\WOW6432Node\Khronos\Vulkan\ExplicitLayers*.
>
> \4. Install Vulkan of latest version.
>
> \5. After these operations, vulkan layer settings should be ready to go.

关于验证层，太多参数，我也没有细看，目前，是直接照搬，没有理解。





#### 物理设备和队列

在通过VkInstance初始化Vulkan库之后，我们需要在系统中寻找并选择支持我们需要的特性的图形卡。事实上，我们可以选择任意数量的显卡并同时使用它们，但是在本教程中，我们将坚持使用第一个符合我们需要的显卡。

我们将添加一个函数`pickPhysicalDevice`并在该`initVulkan`函数中添加对其的调用 。

我们最终选择的显卡将存储在VkPhysicalDevice句柄中，该句柄作为一个新类成员添加。当VkInstance被销毁时，这个对象将被隐式销毁，因此我们不需要在cleanup函数中执行任何新操作。

```c++
uint32_t deviceCount = 0;
vkEnumeratePhysicalDevices(instance, &deviceCount, nullptr);
if (deviceCount == 0) {
    throw std::runtime_error("failed to find GPUs with Vulkan support!");
}
std::vector<VkPhysicalDevice> devices(deviceCount);
vkEnumeratePhysicalDevices(instance, &deviceCount, devices.data());
```

现在我们需要评估它们中的每一个，并检查它们是否适合我们想要执行的操作，因为并非所有显卡都是相同的。为此，我们将引入一个新函数

```c++
bool isDeviceSuitable(VkPhysicalDevice device) {
    return true;
}
```

下一节将介绍我们将在isDeviceSuitable函数中检查的第一个需求。当我们在后面的章节中开始使用更多的Vulkan特性时，我们也将扩展这个功能，包括更多的检查。