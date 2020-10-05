# ccVulkan教程1





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

### 1. 开始

#### 1.1  基本代码

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



####  1.2 实例

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

------



#### 1.3  验证层

==Vulkan API的设计理念是将驱动程序开销最小化，表现之一就是默认情况下API中的错误检查非常有限==。即使是枚举设置不正确或空指针传递这样简单的错误，通常也不会显式地处理，只会导致崩溃或未定义的行为。因为Vulkan要求你对你正在做的每件事都非常明确，所以很容易犯很多小错误，比如使用新的GPU功能，却忘记在逻辑设备创建时请求它。

==但是，这并不意味着这些检查不能添加到API中。Vulkan为此引入了一个优雅的系统，称为验证层==。验证层是可选的组件，它们连接到Vulkan函数调用以应用其他操作（Vulkan function calls to apply additional operations.）。验证层中常见的操作有

- 根据规范==检查参数值==，避免误用
- 跟踪对象的创建和破坏以查找==资源泄漏==
- 通过跟踪发出调用的线程来==检查线程安全性==
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

==这些验证层可以自由堆叠，以包含您感兴趣的所有调试功能==。您可以简单地为调试构建启用验证层，并在发布构建中完全禁用它们，这是两全其用

==Vulkan没有提供任何内置的验证层，但是LunarG Vulkan SDK提供了一组很好的检查常见错误的层==。它们也是完全开源的。使用验证层是避免应用程序意外依赖于未定义的行为而破坏不同驱动程序的最佳方法。只有在系统上安装了验证层之后才能使用它们。例如，LunarG验证层只在安装了Vulkan SDK的pc上可用。

以前在Vulkan中有两种不同类型的验证层：特定于实例的验证层和特定于设备的验证层。这个想法是，实例层只会检查与全局Vulkan对象(比如实例)相关的调用，而特定于设备的层只会检查与特定GPU相关的调用。特定于设备的层现在已经被弃用，这意味着==实例验证层适用于所有Vulkan调用==。规范文档仍然建议在设备级别启用验证层，以保证兼容性，这是某些实现所要求的。

##### ==使用验证层==

在本节中，我们将了解如何启用Vulkan SDK提供的标准诊断层。与扩展一样，需要通过指定验证层的名称来启用它们。==所有有用的标准验证都被打包到SDK中包含的一个层中，这个层是==`VK_LAYER_KHRONOS_validation`。

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

我们将首先创建一个getRequiredExtensions函数，该==函数将返回所需的扩展列表（基于验证层是否启用）==

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

==GLFW指定的扩展是固定需要的，但是有条件地添加了debug messenger扩展==。注意，在这里使用了VK_EXT_DEBUG_UTILS_EXTENSION_NAME宏。使用这个宏可以避免输入错误。然后使用这个函数代替之前的GLFW扩展获取函数。

==现在，让我们看看调试回调函数的外观==。添加一个新的名为静态成员函数`debugCallback`，参数有`PFN_vkDebugUtilsMessengerCallbackEXT` 。`VKAPI_ATTR`和`VKAPI_CALL`确保函数具有供Vulkan调用的正确签名。

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

==第一个参数指定消息的严重性==，参考值如下：

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

==messageType参数可以有以下值==:

- `VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT`: 发生了一些与规范或性能无关的事件
- `VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT`: 发生了违反规范或指示可能的错误的事情
- `VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT`: Potential non-optimal use of Vulkan（潜在的非最佳使用vulkan）

==pCallbackData参数==引用一个VkDebugUtilsMessengerCallbackDataEXT结构体，该结构体包含消息本身的细节，最重要的成员是:

- `pMessage`: The debug message as a null-terminated string，调试消息
- `pObjects`: Array of Vulkan object handles related to the message，与消息相关的Vulkan对象句柄数组
- `objectCount`: Number of objects in array，

最后，pUserData参数包含一个在设置回调期间指定的指针，允许您将自己的数据传递给它。回调返回一个布尔值，该布尔值指示是否应终止触发验证层消息的Vulkan调用。如果回调返回true，则该调用将因`VK_ERROR_VALIDATION_FAILED_EXT`错误而中止。==通常这仅用于测试验证层本身，因此您应始终返回VK_FALSE==。

==现在剩下的就是告诉Vulkan关于回调函数的信息==。可能有些令人惊讶的是，即使是Vulkan中的调试回调也是使用一个需要显式地创建和销毁的句柄来管理的。这样的回调是调试信使的一部分，您可以使用任意数量的回调。将此句柄的类成员添加到instance的正下方：

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
void populateDebugMessengerCreateInfo(VkDebugUtilsMessengerCreateInfoEXT& createInfo) {
        createInfo = {};
        createInfo.sType = VK_STRUCTURE_TYPE_DEBUG_UTILS_MESSENGER_CREATE_INFO_EXT;
        createInfo.messageSeverity = VK_DEBUG_UTILS_MESSAGE_SEVERITY_VERBOSE_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
        createInfo.messageType = VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT | VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;
        createInfo.pfnUserCallback = debugCallback;
}
```

messageSeverity字段允许您指定希望调用回调的所有严重程度类型；类似地，messageType字段允许您筛选通知回调的消息类型。pfnUserCallback字段指定指向回调函数的指针。您可以选择传递指向pUserData字段的指针，该字段将通过pUserData参数传递给回调函数。例如，您可以使用它来传递一个指向HelloTriangleApplication类的指针。

==这个结构应该传递给vkCreateDebugUtilsMessengerEXT函数，以创建VkDebugUtilsMessengerEXT对象==。不幸的是，因为这个函数是一个扩展函数，所以它不会自动加载。我们必须使用vkGetInstanceProcAddr自己查找它的地址。我们将创建我们自己的代理函数在后台处理这个。我在HelloTriangleApplication类定义的正上方添加了它。

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

------



####  1.4 物理设备和队列

在通过VkInstance初始化Vulkan库之后，我们需要在系统中寻找并选择支持我们需要的特性的图形卡。事实上，我们可以选择任意数量的显卡并同时使用它们，但是在本教程中，我们将坚持使用第一个符合我们需要的显卡。

我们将添加一个函数`pickPhysicalDevice`并在该`initVulkan`函数中添加对其的调用 。

我们最终选择的显卡将存储在VkPhysicalDevice句柄中，该句柄作为一个新类成员添加。==当VkInstance被销毁时，这个对象将被隐式销毁，因此我们不需要在cleanup函数中执行任何新操作==。

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

下一节将介绍我们将在isDeviceSuitable函数中检查的第一个需求。当我们在后面的章节中开始使用更多的Vulkan特性时，我们也将扩展这个功能。



##### 基本的设备适用性检查

要评估设备的适用性，我们可以从查询==基本的设备属性==开始，如名称，类型和支持的Vulkan版本，可以使用vkGetPhysicalDeviceProperties查询。

```c
VkPhysicalDeviceProperties deviceProperties;
vkGetPhysicalDeviceProperties(device, &deviceProperties);
```

支持==可选功能，如纹理压缩，64位浮动和多viewport渲染==(对VR有用)，可以使用vkGetPhysicalDeviceFeatures查询：

```c
VkPhysicalDeviceFeatures deviceFeatures;
vkGetPhysicalDeviceFeatures(device, &deviceFeatures);
```

作为一个例子，让我们假设我们的应用程序只对支持几何着色器的专用图形卡可用。那么isDeviceSuitable函数就像这样：

```c
bool isDeviceSuitable(VkPhysicalDevice device) {
    VkPhysicalDeviceProperties deviceProperties;
    VkPhysicalDeviceFeatures deviceFeatures;
    vkGetPhysicalDeviceProperties(device, &deviceProperties);
    vkGetPhysicalDeviceFeatures(device, &deviceFeatures);

    return deviceProperties.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU &&
           deviceFeatures.geometryShader;
}
```

你也可以给每个设备打个分数，然后选出最高的那个，而不是只检查一个设备是否合适，然后选择第一个。这样一来，你就可以通过给专用显卡更高的分数来选择它，但如果集成显卡是唯一可用的，那么就退回到集成显卡。您可以实现如下内容：

```c
#include <map>

...

void pickPhysicalDevice() {
    ...

    // Use an ordered map to automatically sort candidates by increasing score
    std::multimap<int, VkPhysicalDevice> candidates;

    for (const auto& device : devices) {
        int score = rateDeviceSuitability(device);
        candidates.insert(std::make_pair(score, device));
    }

    // Check if the best candidate is suitable at all
    if (candidates.rbegin()->first > 0) {
        physicalDevice = candidates.rbegin()->second;
    } else {
        throw std::runtime_error("failed to find a suitable GPU!");
    }
}

int rateDeviceSuitability(VkPhysicalDevice device) {
    ...

    int score = 0;

    // Discrete GPUs have a significant performance advantage
    if (deviceProperties.deviceType == VK_PHYSICAL_DEVICE_TYPE_DISCRETE_GPU) {
        score += 1000;
    }

    // Maximum possible size of textures affects graphics quality
    score += deviceProperties.limits.maxImageDimension2D;

    // Application can't function without geometry shaders
    if (!deviceFeatures.geometryShader) {
        return 0;
    }

    return score;
}
```

在本教程中，您不需要实现所有这些，但这是为了让您了解如何设计设备选择过程。



##### Queue Families

在此之前，我们已经简单提到过，==在Vulkan中几乎所有的操作，从绘制到上传纹理，都需要将命令提交到队列中==。==不同类型的队列起源于不同的队列系列（Queue Familes），每个队列系列只允许命令的一个子集。例如，可能有一个队列系列只允许处理计算命令，或者一个队列系列只允许内存传输相关命令==。



我们需要检查设备支持哪些队列家族，以及其中哪个队列家族支持我们想要使用的命令。为此，我们将添加一个新函数findQueueFamilies，用于查找我们需要的所有队列族。

但是如果队列families不可用呢？我们可以在findQueueFamilies中抛出一个异常，但是这个函数并不是决定设备是否适合的正确位置。例如，我们可能更喜欢具有专用传输队列家族的设备，但并不需要它。因此，我们需要某种方式来指示是否找到了特定的队列族。

实际上不可能使用一个magic value来表示队列族的不存在，因为uint32 t的任何值在理论上都可以是一个有效的队列族索引，包括0。幸运的是，c++ 17引入了一种数据结构来区分值存在与否：

```c
#include <optional>

...

std::optional<uint32_t> graphicsFamily;

std::cout << std::boolalpha << graphicsFamily.has_value() << std::endl; // false

graphicsFamily = 0;

std::cout << std::boolalpha << graphicsFamily.has_value() << std::endl; // true
```

==std::optional是一个包装器，它不包含任何值，直到你给它赋值==。==在任何时候，您都可以通过调用它的has_value()成员函数来查询它是否包含值==。这意味着我们可以把逻辑改为：

```c
#include <optional>

...

struct QueueFamilyIndices {
    std::optional<uint32_t> graphicsFamily;
};

QueueFamilyIndices findQueueFamilies(VkPhysicalDevice device) {
    QueueFamilyIndices indices;
    // Assign index to queue families that could be found
    return indices;
}
```

接下来正式实现`findQueueFamilies`:

```c
uint32_t queueFamilyCount = 0;
vkGetPhysicalDeviceQueueFamilyProperties(device, &queueFamilyCount, nullptr);

std::vector<VkQueueFamilyProperties> queueFamilies(queueFamilyCount);
vkGetPhysicalDeviceQueueFamilyProperties(device, &queueFamilyCount, queueFamilies.data());
```

VkQueueFamilyProperties结构体包含关于队列家族的一些细节，包括受支持的操作类型和基于该家族可以创建的队列数量。我们需要找到至少一个支持`VK_QUEUE_GRAPHICS_BIT`的队列族。

```c
int i = 0;
for (const auto& queueFamily : queueFamilies) {
    if (queueFamily.queueFlags & VK_QUEUE_GRAPHICS_BIT) {
        indices.graphicsFamily = i;
    }

    i++;
}
```

现在我们有了这个奇特的队列族查找函数，我们可以在isDeviceSuitable函数中使用它，以确保设备能够处理我们想要使用的命令:

```
bool isDeviceSuitable(VkPhysicalDevice device) {
    QueueFamilyIndices indices = findQueueFamilies(device);

    return indices.graphicsFamily.has_value();
}
```

为了方便起见，我们还将向结构本身添加一个通用检查：

```c
struct QueueFamilyIndices {
    std::optional<uint32_t> graphicsFamily;

    bool isComplete() {
        return graphicsFamily.has_value();
    }
};

...

bool isDeviceSuitable(VkPhysicalDevice device) {
    QueueFamilyIndices indices = findQueueFamilies(device);

    return indices.isComplete();
}
```

很好，这就是我们现在所需要的找到正确的物理设备!==下一步是创建一个与之接口的逻辑设备==。

------



####  1.5 逻辑设备和队列

在选择要使用的物理设备之后，我们需要设置一个逻辑设备与之接口。逻辑设备创建过程类似于实例创建过程，并描述了我们想要使用的特性。在查询了哪些队列家族可用之后，我们还需要指定要创建哪些队列。如果您有不同的需求，甚至可以从同一物理设备创建多个逻辑设备。

基础代码添加

```
VkDevice device;
...
void createLogicalDevice() {

}
```



##### Specifying the queues to be created

​	创建逻辑设备需要再次在struct中指定一堆细节，其中第一个是VkDeviceQueueCreateInfo。这个结构描述了一个队列族所需的队列数量。现在我们只对具有图形功能的队列感兴趣。

```c
QueueFamilyIndices indices = findQueueFamilies(physicalDevice);

VkDeviceQueueCreateInfo queueCreateInfo{};
queueCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
queueCreateInfo.queueFamilyIndex = indices.graphicsFamily.value();
queueCreateInfo.queueCount = 1;
```

​	当前可用的驱动程序只允许为每个队列家族创建少量的队列，实际上不需要多个队列。这是因为您可以在多个线程上创建所有的Command Buffer，然后通过一个低开销的调用在主线程上一次性提交它们

​	Vulkan允许您使用0.0到1.0之间的浮点数为队列分配优先级，以影响命令缓冲区执行的调度。即使只有一个队列，这也是必需的：

```
float queuePriority = 1.0f;
queueCreateInfo.pQueuePriorities = &queuePriority;
```



##### Specifying used device features

​	接下来要指定的信息是我们将使用的一组设备特性。这些是我们在前一章中查询过的支持vkGetPhysicalDeviceFeatures的特性，比如几何着色器。现在我们不需要任何特殊的东西，所以我们可以简单地定义它，然后把所有东西都置为假。当我们要开始用Vulkan做更多有趣的事情时，我们会回到这个结构。

```
VkPhysicalDeviceFeatures deviceFeatures{};
```



##### Creating the logical device

​	有了前两个结构，我们可以开始==填充主VkDeviceCreateInfo结构==。首先添加指向队列创建信息和设备特性结构体的指针

```
VkDeviceCreateInfo createInfo{};
createInfo.sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO;

createInfo.pQueueCreateInfos = &queueCreateInfo;
createInfo.queueCreateInfoCount = 1;

createInfo.pEnabledFeatures = &deviceFeatures;
```

​	其余的信息与VkInstanceCreateInfo结构类似，需要您指定扩展和验证层。不同的是，这一次这些是特定于设备的。特定于设备的扩展的一个示例是VK KHR swapchain，它允许您将设备中呈现的图像显示到窗口中。系统中可能有一些Vulkan设备缺乏这种能力，例如，因为它们只支持计算操作。我们将在交换链一章中回到这个扩展。

```c
createInfo.enabledExtensionCount = 0;

if (enableValidationLayers) {
    createInfo.enabledLayerCount = static_cast<uint32_t>(validationLayers.size());
    createInfo.ppEnabledLayerNames = validationLayers.data();
} else {
    createInfo.enabledLayerCount = 0;
}
```

​	我们现在不需要任何特定于设备的扩展。

​	好了，现在我们准备通过调用适当命名的``vkCreateDevice``函数==实例化逻辑设备==。

```c
if (vkCreateDevice(physicalDevice, &createInfo, nullptr, &device) != VK_SUCCESS) {
    throw std::runtime_error("failed to create logical device!");
}
```

​	参数是要接口的物理设备、我们刚才指定的队列和使用信息、可选的分配回调指针和一个指向存储逻辑设备句柄的变量的指针。与实例创建函数类似，此调用可以基于启用不存在的扩展或指定不支持的特性的期望用法而返回错误



##### Retrieving queue handles

​	队列是与逻辑设备一起自动创建的，但是我们还没有一个句柄来与它们进行接口。首先添加一个类成员来存储图形队列的句柄

```c
VkQueue graphicsQueue;
```

​	设备被销毁时，设备队列被隐式清除，因此我们不需要在清理中做任何事情。我们可以使用vkGetDeviceQueue函数来检索每个队列族的队列句柄。参数包括逻辑设备、队列家族、队列索引和一个指向用于存储队列句柄的变量的指针。因为我们只从这个系列中创建一个队列，所以我们只使用索引0。

```c
vkGetDeviceQueue(device, indices.graphicsFamily.value(), 0, &graphicsQueue);
```

​	有了逻辑设备和队列句柄，我们现在就可以开始使用显卡来做事情了!在接下来的几章中，我们将设置资源以将结果呈现给窗口系统。

------



###  2 展示(presentation)

​	==由于Vulkan是一个平台无关的API，它不能自己直接与窗口系统交互==。为了在Vulkan和窗口系统之间建立连接，以便将结果显示在屏幕上，我们需要使用WSI(窗口系统集成)扩展。在本章中，我们将讨论第一个扩展，即`VK_KHR_surface`。 It exposes a `VkSurfaceKHR` object that represents an abstract type of surface to present rendered images to. The surface in our program will be backed by the window that we've already opened with GLFW.

`VK_KHR_surface`扩展是一个实例级扩展，我们实际上已经启用了它，因为它包含在由glfwGetRequiredInstanceExtensions返回的列表中。该列表还包括一些其他的WSI扩展，我们将在接下来的几章中使用。

​	==在实例创建之后立即创建窗口表面，因为它实际上会影响物理设备的选择==。我们推迟的原因是窗口表面是渲染目标和表现的大主题的一部分，对于它的解释会使基本设置混乱。还需要注意的是，==如果你只需要在屏幕外渲染，那么在Vulkan中窗口表面是一个完全可选的组件。Vulkan允许你这样做，而不需要像创建一个不可见的窗口(这是OpenGL所必需的)==。



#### 2.1 Window surface

​	首先在调试回调的正下方添加一个surface类成员

```
VkSurfaceKHR surface;
```

​	尽管VkSurfaceKHR对象及其使用与平台无关，但它的创建并不是因为它依赖于窗口系统细节。例如，它需要Windows上的HWND和HMODULE句柄。因此，在扩展中有一个特定于平台的附加项，在Windows中称为VK KHR win32 surface，它也自动包含在来自glfwGetRequiredInstanceExtensions的列表中。

​	因为窗口表面是一个Vulkan对象，它带有一个需要填充的VkWin32SurfaceCreateInfoKHR结构。它有两个重要的参数:hwnd和hinstance。这是窗口和流程的句柄。

```c
VkWin32SurfaceCreateInfoKHR createInfo{};
createInfo.sType = VK_STRUCTURE_TYPE_WIN32_SURFACE_CREATE_INFO_KHR;
createInfo.hwnd = glfwGetWin32Window(window);
createInfo.hinstance = GetModuleHandle(nullptr);
```

然后可以使用vkCreateWin32SurfaceKHR创建surface，其中包括实例的参数、surface创建细节、自定义分配器和存储在其中的surface句柄的变量。从技术上讲，这是一个WSI扩展函数，但它是如此常用，以至于标准的Vulkan加载程序包含了它，所以不像其他扩展，你不需要显式地加载它。

```c
if (vkCreateWin32SurfaceKHR(instance, &createInfo, nullptr, &surface) != VK_SUCCESS) {
    throw std::runtime_error("failed to create window surface!");
}
```

但是根据教程，实际使用中，我们使用的是下面这个GLFW函数

```c
void createSurface() {
    if (glfwCreateWindowSurface(instance, window, nullptr, &surface) != VK_SUCCESS) {
        throw std::runtime_error("failed to create window surface!");
    }
}
```

最后，破坏这个Surface

```c
 vkDestroySurfaceKHR(instance, surface, nullptr);
```

------

##### Querying for presentation support

虽然`Vulkan`实现可能支持窗口系统集成，但这并不意味着系统中的每个设备都支持它。因此，我们需要`isDeviceSuitable`以确保设备能够将图像显示到我们创建的表面上。==由于Presentation是一个特定于队列的特性，因此问题实际上是关于找到一个队列家族来支持我们创建的表面表示==。

实际上，==支持绘制命令的队列族和支持表示的队列族可能没有重叠==。因此，我们必须考虑到，通过修改QueueFamilyIndices结构，可能会有一个不同的表示队列：

```c
struct QueueFamilyIndices {
    std::optional<uint32_t> graphicsFamily;
    std::optional<uint32_t> presentFamily;

    bool isComplete() {
        return graphicsFamily.has_value() && presentFamily.has_value();
    }
};
```

接下来，我们将修改`findQueueFamilies`函数，以查找能够显示到窗口表面的队列族。检查这一点的函数是`vkGetPhysicalDeviceSurfaceSupportKHR`，它将物理设备、队列家族索引和表面作为参数。在`VK_QUEUE_GRAPHICS_BIT`的循环中添加对它的调用：

```c
VkBool32 presentSupport = false;
vkGetPhysicalDeviceSurfaceSupportKHR(device, i, surface, &presentSupport);
if (presentSupport) {
    indices.presentFamily = i;
}
```

请注意，这些很可能最终成为相同的队列族，但在整个程序中，我们将把它们看作是不同的队列，以统一的方式处理。不过，您可以添加逻辑来显式地选择在同一队列中支持绘图和表示的物理设备，以提高性能。

##### Creating the presentation queue

剩下的一件事就是修改逻辑设备创建过程，以创建表示队列并检索`VkQueue句柄`。为句柄添加一个成员变量。接下来，我们需要有多个		`VkDeviceQueueCreateInfo`结构体来创建来自两个家族的队列。An elegant way to do that is to create a set of all unique queue families that are necessary for the required queues：

```c
#include <set>

...

QueueFamilyIndices indices = findQueueFamilies(physicalDevice);

std::vector<VkDeviceQueueCreateInfo> queueCreateInfos;
std::set<uint32_t> uniqueQueueFamilies = {indices.graphicsFamily.value(), indices.presentFamily.value()};

float queuePriority = 1.0f;
for (uint32_t queueFamily : uniqueQueueFamilies) {
    VkDeviceQueueCreateInfo queueCreateInfo{};
    queueCreateInfo.sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO;
    queueCreateInfo.queueFamilyIndex = queueFamily;
    queueCreateInfo.queueCount = 1;
    queueCreateInfo.pQueuePriorities = &queuePriority;
    queueCreateInfos.push_back(queueCreateInfo);
}
```

And modify [`VkDeviceCreateInfo`](https://www.khronos.org/registry/vulkan/specs/1.0/man/html/VkDeviceCreateInfo.html) to point to the vector:

```c
createInfo.queueCreateInfoCount = static_cast<uint32_t>(queueCreateInfos.size());
createInfo.pQueueCreateInfos = queueCreateInfos.data();
```





####  2.2 Swap Chain

Vulkan没有”默认framebuffer“的概念，因此它需要一个基础结构——在屏幕上显示之前，它将拥有我们要呈现的缓冲区。这个基础结构称为==交换链（Swap Chain）==，必须在Vulkan中显式地创建。==交换链本质上是等待显示在屏幕上的图像队列==，我们的应用程序获得一个Image显示后，然后将图片返回到队列中。队列的具体工作方式以及从队列中显示图像的条件取决于交换链的设置方式，但是==交换链的一般目的是同步图像的表示和屏幕的刷新速率。==



#####  Checking for swap chain support

由于各种原因，并不是所有的图形卡都能够将图像直接显示到屏幕上，例如：它们是为服务器设计的，没有任何显示输出。其次，since image presentation is heavily tied into the window system and the surfaces associated with windows，它实际上不是Vulkan核心的一部分。必须在确定可用之后启用`VK_KHR_swapchain`

为此，==我们将首先扩展isDeviceSuitable函数==，检查是否支持该扩展。我们之前已经看到了如何列出VkPhysicalDevice支持的扩展，注意，Vulkan头文件提供了一个很好的宏`VK_KHR_SWAPCHAIN_EXTENSION_NAME`，它被定义为`VK_KHR_swapchain`。==使用这个宏的好处是编译器可以捕捉拼写错误。==首先声明所需设备扩展的列表，类似于要启用的验证层列表

```c
const std::vector<const char*> deviceExtensions = {
    VK_KHR_SWAPCHAIN_EXTENSION_NAME
};
```

接下来，创建一个新的函数`checkDeviceExtensionSupport`，从isDeviceSuitable调用该函数作为附加检查：

```c
bool isDeviceSuitable(VkPhysicalDevice device) {
    QueueFamilyIndices indices = findQueueFamilies(device);

    bool extensionsSupported = checkDeviceExtensionSupport(device);

    return indices.isComplete() && extensionsSupported;
}

bool checkDeviceExtensionSupport(VkPhysicalDevice device) {
    return true;
}
```

修改函数体以枚举扩展并检查所有必需的扩展是否在其中：

```c
bool checkDeviceExtensionSupport(VkPhysicalDevice device) {
    uint32_t extensionCount;
    vkEnumerateDeviceExtensionProperties(device, nullptr, &extensionCount, nullptr);

    std::vector<VkExtensionProperties> availableExtensions(extensionCount);
    vkEnumerateDeviceExtensionProperties(device, nullptr, &extensionCount, availableExtensions.data());

    std::set<std::string> requiredExtensions(deviceExtensions.begin(), deviceExtensions.end());

    for (const auto& extension : availableExtensions) {
        requiredExtensions.erase(extension.extensionName);
    }

    return requiredExtensions.empty();
}
```



##### Enabling device extensions

使用交换链需要首先启用`VK_KHR_swapchain`。启用扩展只需要对逻辑设备创建结构做一点小小的更改

```c
createInfo.enabledExtensionCount = static_cast<uint32_t>(deviceExtensions.size());
createInfo.ppEnabledExtensionNames = deviceExtensions.data();
```



##### Querying details of swap chain support

仅仅检查交换链是否可用是不够的，因为它实际上可能与我们的窗口表面不兼容。创建交换链还涉及到比创建实例和设备多得多的设置，因此在继续操作之前，我们需要查询更多细节。==我们基本上需要检查如下种属性：==

- 基本Surface属性，包括：交换链中image的最大和最小数量，Image的最大/小 高度和宽度
- Surface格式：pixel format、颜色空间、
- 可用的表现模式

与`findQueueFamilies`类似，在查询完这些细节后，我们将使用一个结构体来传递这些细节。上述三种类型的属性以下面的结构和结构列表的形式出现

```c
struct SwapChainSupportDetails {
    VkSurfaceCapabilitiesKHR capabilities;
    std::vector<VkSurfaceFormatKHR> formats;
    std::vector<VkPresentModeKHR> presentModes;
};
```

现在我们将创建一个新的函数`querySwapChainSupport`将填充这个结构：

```c
SwapChainSupportDetails querySwapChainSupport(VkPhysicalDevice device) {
    SwapChainSupportDetails details;

    return details;
}
```

让我们从基本的surface功能开始。这些属性查询起来很简单，并且返回到一个`VkSurfaceCapabilitiesKHR`结构中。

```
vkGetPhysicalDeviceSurfaceCapabilitiesKHR(device, surface, &details.capabilities);
```

在确定所支持的功能时，此函数将指定的VkPhysicalDevice和VkSurfaceKHR窗口表面考虑在内。所有支持查询函数都将这两个参数作为第一个参数，因为它们是交换链的核心组件。下一步是查询所支持的表面格式。因为这是一个struct列表，所以它遵循熟悉的2个函数调用的惯例：

```c
uint32_t formatCount;
vkGetPhysicalDeviceSurfaceFormatsKHR(device, surface, &formatCount, nullptr);

if (formatCount != 0) {
    details.formats.resize(formatCount);
    vkGetPhysicalDeviceSurfaceFormatsKHR(device, surface, &formatCount, details.formats.data());
}
```

最后，查询支持的表示模式的工作方式与`vkGetPhysicalDeviceSurfacePresentModesKHR`完全相同

```c
uint32_t presentModeCount;
vkGetPhysicalDeviceSurfacePresentModesKHR(device, surface, &presentModeCount, nullptr);

if (presentModeCount != 0) {
    details.presentModes.resize(presentModeCount);
    vkGetPhysicalDeviceSurfacePresentModesKHR(device, surface, &presentModeCount, details.presentModes.data());
}
```

所有的细节现在都在结构体中，所以让我们再次扩展isDeviceSuitable，以利用这个函数来验证交换链支持是否足够。==交换链支持对于本教程来说就足够了，前提是我们所拥有的窗口表面至少支持一种图像格式和一种表示模式。==

```c
bool swapChainAdequate = false;
if (extensionsSupported) {
    SwapChainSupportDetails swapChainSupport = querySwapChainSupport(device);
    swapChainAdequate = !swapChainSupport.formats.empty() && !swapChainSupport.presentModes.empty();
}
```

重要的是，我们只在验证扩展可用之后才尝试查询交换链支持。函数的最后一行更改为：

```c
return indices.isComplete() && extensionsSupported && swapChainAdequate;
```



##### Choosing the right settings for the swap chain

现在我们将编写两个函数来为最好的交换链找到正确的设置。有三种类型的设置需要确定：

- Surface format (color depth)
- Presentation mode (conditions for "swapping" images to the screen)
- Swap extent (resolution of images in swap chain)



***Surface format***

```c
VkSurfaceFormatKHR chooseSwapSurfaceFormat(const std::vector<VkSurfaceFormatKHR>& availableFormats) {
    for (const auto& availableFormat : availableFormats) {
        if (availableFormat.format == VK_FORMAT_B8G8R8A8_SRGB && availableFormat.colorSpace == 				                 VK_COLOR_SPACE_SRGB_NONLINEAR_KHR) {
            return availableFormat;
        }
    }
     return availableFormats[0];
}
```

每个`VkSurfaceFormatKHR`条目都包含一个格式和一个色彩空间成员。format成员指定颜色通道和类型。例如，`VK_FORMAT_B8G8R8A8_SRG`意味着以8位无符号整数存储B、G、R和alpha通道，每像素总共32位。colorSpace成员指示是否支持SRGB颜色空间，或者不使用`VK_COLOR_SPACE_SRGB_NONLINEAR_KHR`。对于颜色空间，我们将使用SRGB，因为它产生更准确的感知颜色。它也是图像的标准颜色空间，就像我们后面会用到的纹理一样。



 ***Presentation mode***

presentation mode可以说是交换链中最重要的设置，因为它表示在屏幕上显示图像的实际条件。Vulkan有四种模式可供选择：

- `VK_PRESENT_MODE_IMMEDIATE_KHR`：应用程序提交的图像会立即传输到屏幕上，这可能会导致撕裂（tearing）
- `VK_PRESENT_MODE_FIFO_KHR`：交换链是这样一个队列，当刷新显示时，显示器从队列前端获取图像，并且程序将呈现的图像插入到队列的后部。如果队列已满，则程序必须等待。这与现代游戏中的垂直同步（vertical sync ）非常相似。刷新显示的时刻称为`vertical blank`。
- `VK_PRESENT_MODE_FIFO_RELAXED_KHR`：与上一个基本一样，但是当队列已满时，立即显示而不是等待，所以这也可能导致tearing。
- `VK_PRESENT_MODE_MAILBOX_KHR`：这是第二种模式的另一种变化。当队列已满时，不会阻塞应用程序，只是将已经排队的映像替换为较新的映像。此模式可用于实现三重缓冲，与使用双重缓冲的标准垂直同步相比，三重缓冲允许您避免撕裂，显著减少延迟问题。

只有`VK_PRESENT_MODE_FIFO_KHR`被保证可用，但就效果而言肯定是第四种模式最好，因此我们将再次编写一个函数来寻找可用的最佳模式：

```c
VkPresentModeKHR chooseSwapPresentMode(const std::vector<VkPresentModeKHR>& availablePresentModes) {
    for (const auto& availablePresentMode : availablePresentModes) {
        if (availablePresentMode == VK_PRESENT_MODE_MAILBOX_KHR) {
            return availablePresentMode;
        }
    }
    return VK_PRESENT_MODE_FIFO_KHR;
}
```



***Swap extent***

```c
#include <cstdint> // Necessary for UINT32_MAX
VkExtent2D chooseSwapExtent(const VkSurfaceCapabilitiesKHR& capabilities) {
    if (capabilities.currentExtent.width != UINT32_MAX) {
            return capabilities.currentExtent;
        } else {
            VkExtent2D actualExtent = {WIDTH, HEIGHT};

            actualExtent.width = std::max(capabilities.minImageExtent.width, 			                                                            std::min(capabilities.maxImageExtent.width, actualExtent.width));
            actualExtent.height = std::max(capabilities.minImageExtent.height,                                                              std::min(capabilities.maxImageExtent.height, actualExtent.height));

            return actualExtent;
        }
}
```

> The swap extent is the resolution of the swap chain images and it's almost always exactly equal to the resolution of the window that we're drawing to. The range of the possible resolutions is defined in the `VkSurfaceCapabilitiesKHR` structure. Vulkan tells us to match the resolution of the window by setting the width and height in the `currentExtent` member. However, some window managers do allow us to differ here and this is indicated by setting the width and height in `currentExtent` to a special value: the maximum value of `uint32_t`. In that case we'll pick the resolution that best matches the window within the `minImageExtent` and `maxImageExtent` bounds.



##### Creating the Swap Chain

现在我们有了所有这些辅助函数来帮助我们在运行时做出选择，我们终于有了创建一个工作交换链所需的所有信息。创建一个createSwapChain函数，它从这些调用的结果开始，并确保在逻辑设备创建之后从initVulkan调用它。

```c
void createSwapChain() {
    SwapChainSupportDetails swapChainSupport = querySwapChainSupport(physicalDevice);

    VkSurfaceFormatKHR surfaceFormat = chooseSwapSurfaceFormat(swapChainSupport.formats);
    VkPresentModeKHR presentMode = chooseSwapPresentMode(swapChainSupport.presentModes);
    VkExtent2D extent = chooseSwapExtent(swapChainSupport.capabilities);
}
```

除了这些属性之外，我们还必须决定交换链中应该有多少Image，建议请求至少比最小值多一个：

```c
uint32_t imageCount = swapChainSupport.capabilities.minImageCount + 1;
```

在执行此操作时，我们还应该确保不超过图像的最大数量，其中0是一个特殊值，表示不存在最大值：

```c
if (swapChainSupport.capabilities.maxImageCount > 0 && imageCount > swapChainSupport.capabilities.maxImageCount) {
    imageCount = swapChainSupport.capabilities.maxImageCount;
}
```

老生常谈，建立对应的`CreateInfo`结构体：

```c
VkSwapchainCreateInfoKHR createInfo{};
createInfo.sType = VK_STRUCTURE_TYPE_SWAPCHAIN_CREATE_INFO_KHR;
createInfo.surface = surface;

createInfo.minImageCount = imageCount;
createInfo.imageFormat = surfaceFormat.format;
createInfo.imageColorSpace = surfaceFormat.colorSpace;
createInfo.imageExtent = extent;
createInfo.imageArrayLayers = 1;
createInfo.imageUsage = VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT;
```

`imageArrayLayers`指定每个图像所包含的层的数量。这总是1，除非你正在开发一个立体的3D应用程序。` imageUsage`位字段指定我们将在交换链中使用图像进行的操作类型。在本教程中，我们将直接渲染它们，这意味着它们被用作`color attachment.`。也有可能首先将图像呈现为单独的图像，以执行诸如后处理之类的操作。在这种情况下，您可以使用像`VK_IMAGE_USAGE_TRANSFER_DST_BIT`这样的值，并使用内存操作将渲染的图像传输到交换链图像。

```c
QueueFamilyIndices indices = findQueueFamilies(physicalDevice);
uint32_t queueFamilyIndices[] = {indices.graphicsFamily.value(), indices.presentFamily.value()};

if (indices.graphicsFamily != indices.presentFamily) {
    createInfo.imageSharingMode = VK_SHARING_MODE_CONCURRENT;
    createInfo.queueFamilyIndexCount = 2;
    createInfo.pQueueFamilyIndices = queueFamilyIndices;
} else {
    createInfo.imageSharingMode = VK_SHARING_MODE_EXCLUSIVE;
    createInfo.queueFamilyIndexCount = 0; // Optional
    createInfo.pQueueFamilyIndices = nullptr; // Optional
}
```

接下来，我们需要指定如何处理将跨多个队列族使用的交换链Image。在我们的应用程序中，如果图形队列族与表示队列不同，就会出现这种情况。我们将在交换链中，从图形队列绘制图像，然后将它们提交到演示队列中。有两种方法可以处理从多个队列访问的Iamge：

- `VK_SHARING_MODE_EXCLUSIVE`：一个Image一次由一个队列家族所有，在另一个队列家族中使用它之前，必须显式地转移它的所有权。此选项提供了最佳性能。
- `VK_SHARING_MODE_CONCURRENT`：图像可以跨多个队列族使用，而无需显式的所有权转移。

如果队列族不同，那么在本教程中我们将使用并发模式，以避免进行ownership chapters，因为其中涉及的一些概念将在稍后进行更好的解释。并发模式需要你提前指定队列族所有权之间共享使用`queueFamilyIndexCount`和`pQueueFamilyIndices`。如果图形队列族和表示队列族是相同的(大多数硬件上都是这样)，那么我们应该坚持使用exclusive mode，因为并发模式要求您至少指定两个不同的队列族。

```c
createInfo.preTransform = swapChainSupport.capabilities.currentTransform;
```

如果转换受到支持，我们可以指定对交换链中的图像应用转换，比如90度顺时针旋转或水平翻转。不需要任何转换，只需指定当前转换。

```c
createInfo.compositeAlpha = VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR;
```

`compositeAlpha`字段指定了alpha通道是否应该用于与窗口系统中的其他窗口混合。这个一般不考虑，所以使用`VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR`

```c
createInfo.presentMode = presentMode;
createInfo.clipped = VK_TRUE;
```

如果`clipped`被设置为VK_TRUE，那么这意味着不关心被遮挡像素的颜色。除非真的需要能够读取这些像素并获得可预测的结果，否则启用剪切将获得最佳性能。

```c
createInfo.oldSwapchain = VK_NULL_HANDLE;
```

这就剩下最后一个字段`oldSwapChain`。使用Vulkan时，您的交换链可能会在应用程序运行时失效，例如，因为窗口被调整了大小。在这种情况下，交换链实际上需要从头重新创建，并且必须在这个字段中指定对旧交换链的引用。这是一个复杂的主题，我们将在以后的章节中了解更多。现在，我们假设只创建一个交换链。

最后，老生常谈

```c
VkSwapchainKHR swapChain;
...
if (vkCreateSwapchainKHR(device, &createInfo, nullptr, &swapChain) != VK_SUCCESS) {
    throw std::runtime_error("failed to create swap chain!");
}
...
vkDestroySwapchainKHR(device, swapChain, nullptr);
```



##### Retrieving the swap chain images

交换链现在已经创建，因此剩下的工作就是检索其中VkImages句柄。我们将在后面章节的渲染操作中引用这些。添加一个类成员来存储句柄

```c
std::vector<VkImage> swapChainImages;
VkSwapchainKHR swapChain;
std::vector<VkImage> swapChainImages;
VkFormat swapChainImageFormat;
VkExtent2D swapChainExtent;

...

swapChainImageFormat = surfaceFormat.format;
swapChainExtent = extent;
```

我们现在有了一组可以在窗口上绘制和显示的图像。下一章将开始介绍我们如何设置图像作为渲染目标，然后我们开始研究实际的图形管道和绘图命令





#### 2.3 Image Views

要在渲染管道中使用任何`VkImage`，包括交换链中的那些，我们必须创建一个VkImageView对象。An Image View实际上是一个图像的视图。它描述了如何访问图像以及访问图像的哪一部分，例如，它是否应该被视为没有任何mipmapping级别的2D纹理深度纹理

在本章中，我们将编写一个createImageViews函数，为交换链中的每个图像创建一个基本的图像视图，以便我们以后可以使用它们作为颜色目标。首先添加一个类成员来存储图像视图：

```c
std::vector<VkImageView> swapChainImageViews;

void createImageViews() {

}
```

我们需要做的第一件事是调整列表的大小，以适应我们将创建的所有图像视图：

```c
swapChainImageViews.resize(swapChainImages.size());
```

接下来，设置遍历所有交换链Iamge的循环。创建图像视图的参数在VkImageViewCreateInfo结构中指定

```c
for (size_t i = 0; i < swapChainImages.size(); i++) {
	VkImageViewCreateInfo createInfo{};
    createInfo.sType = VK_STRUCTURE_TYPE_IMAGE_VIEW_CREATE_INFO;
    createInfo.image = swapChainImages[i];
}
```

==viewType和format字段==指定应该如何解释图像数据。viewType参数允许您将图像处理为1D纹理、2D纹理、3D纹理和立方体映射。

```c
createInfo.viewType = VK_IMAGE_VIEW_TYPE_2D;
createInfo.format = swapChainImageFormat;
```

The `components` field allows you to swizzle the color channels around. For example, you can map all of the channels to the red channel for a monochrome texture. You can also map constant values of `0` and `1` to a channel. In our case we'll stick to the default mapping.

```c
createInfo.components.r = VK_COMPONENT_SWIZZLE_IDENTITY;
createInfo.components.g = VK_COMPONENT_SWIZZLE_IDENTITY;
createInfo.components.b = VK_COMPONENT_SWIZZLE_IDENTITY;
createInfo.components.a = VK_COMPONENT_SWIZZLE_IDENTITY;
```

==subresourceRange字段描述了图像的用途以及应该访问图像的哪一部分==。我们的图像将被用作没有任何mipmapping级别或多层的颜色目标。

```c
createInfo.subresourceRange.aspectMask = VK_IMAGE_ASPECT_COLOR_BIT;
createInfo.subresourceRange.baseMipLevel = 0;
createInfo.subresourceRange.levelCount = 1;
createInfo.subresourceRange.baseArrayLayer = 0;
createInfo.subresourceRange.layerCount = 1;
```

如果您正在处理一个立体的3D应用程序，那么您将创建一个具有多层的交换链。然后，您可以通过访问不同的层来为每个图像创建多个图像视图，以表示左右眼睛的视图。

```c
if (vkCreateImageView(device, &createInfo, nullptr, &swapChainImageViews[i]) != VK_SUCCESS) {
    throw std::runtime_error("failed to create image views!");
}
```

与图像不同，图像视图是由我们显式创建的，所以我们需要添加一个类似的循环来在程序结束时再次销毁它们:

```c
for (auto imageView : swapChainImageViews) {
        vkDestroyImageView(device, imageView, nullptr);
    }
```

一个图像视图就足以开始使用一个图像纹理,但还没完全准备好作为渲染目标。这需要另外一个间接步骤，即所谓的framebuffer。但首先我们必须设置图形管道。





### 3. 图形管道基础——Graphics pipeline basics

==The graphics pipeline is the sequence of operations that take the vertices and textures of your meshes all the way to the pixels in the render targets.==。

![](C:\Users\Cooler\Desktop\JMX\ShaderToy\Vulkan教程\Vulkan教程1.assets\1.PNG)

- *input assembler* ：从指定的缓冲区收集原始顶点数据，也可以使用索引缓冲区来重复某些元素，而不必复制顶点数据本身。
- *vertex shader*：运行每个顶点，通常应用转换将顶点位置从模型空间转换到屏幕空间。它还通过管道传递每个顶点的数据。
- *tessellation shaders* ：允许基于某些规则细分几何，以增加网格质量。这通常是用来让像砖墙和楼梯这样的平面看起来不平坦。
- *geometry shader*：在每个原语(三角形、线、点)上运行，可以丢弃它或输出比进来的原语更多的原语。这类似于镶嵌着色器，但更加灵活。然而，它在今天的应用程序中使用不多，因为除了英特尔的集成gpu之外，大多数显卡的性能都不是很好。
- *rasterization* ：将基元分解成片段。这些是它们填充在framebuffer上的像素元素。任何落在屏幕之外的片段都会被丢弃，顶点着色器输出的属性会在这些片段上进行插值，如图所示。通常由于深度测试的原因，在其他基元片段后面的片段在这里也会被丢弃。
- *fragment shader*：对幸存下来的每个片段调用，并确定将片段写入到哪个framebuffer以及使用哪个颜色和深度值。它可以使用来自顶点着色器的插值数据来做到这一点，包括纹理坐标和用于照明的法线等。
-  *color blending*：混合映射到framebuffer中相同像素的不同片段。片段可以基于透明度相互覆盖,增加或混合。

==绿色的阶段称为固定功能阶段==。这些阶段允许您使用参数调整它们的操作，但是它们的工作方式是预定义的。另一方面，橙色的舞台是可编程的，这意味着你可以上传你自己的代码到显卡来应用你想要的操作。

==Vulkan中的图形管道几乎是不可变的==，所以如果你想改变着色器，绑定不同的framebuffer或者改变混合函数，你必须从头重新创建管道。缺点是您必须创建许多管道来表示您想在呈现操作中使用的所有不同的状态组合。然而，由于您将在管道中执行的所有操作都是预先知道的，因此驱动程序可以更好地优化它。

创建一个createGraphicsPipeline函数，该函数在initVulkan中的createImageViews之后调用。我们将在接下来的章节中讨论这个功能。



#### 3.1 Shader modules

