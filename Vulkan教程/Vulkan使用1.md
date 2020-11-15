# Vulkan使用1



## Uniform的添加

- 首先，应该在c++文件中添加一个Uniform变量，例如：

    ```c
    struct PointLightOfUniformBufferObject {
        glm::vec3 Position;
        glm::vec3 Color;
    };
    ```

- 然后，为它新建一个UniformBuffer变量：

    ```c
    LightUniBuffer = new UniformBuffer(swapChain, sizeof(PointLightOfUniformBufferObject));
    LightUniBuffer->createUniformBuffers(swapChain);
    ```

- 在`createDescriptorSetLayout`中为它添加一个新的布局，并且别忘了修改bindings数组。

    ```c
    VkDescriptorSetLayoutBinding LightLayoutBinding{};
    LightLayoutBinding.binding = 1;
    LightLayoutBinding.descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
    LightLayoutBinding.descriptorCount = 1;
    LightLayoutBinding.stageFlags = VK_SHADER_STAGE_FRAGMENT_BIT;
    LightLayoutBinding.pImmutableSamplers = nullptr; // Optional
    ```

- 更新`DescriptorPool`，修改`createDescriptorPool`：

    ```c
    std::array<VkDescriptorPoolSize, 3> poolSizes{};
    poolSizes[0].type = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
    poolSizes[0].descriptorCount = static_cast<uint32_t>(swapChain->swapChainImages.size());
    poolSizes[1].type = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
    poolSizes[1].descriptorCount = static_cast<uint32_t>(swapChain->swapChainImages.size());
    poolSizes[2].type = VK_DESCRIPTOR_TYPE_COMBINED_IMAGE_SAMPLER;
    poolSizes[2].descriptorCount = static_cast<uint32_t>(swapChain->swapChainImages.size());
    ```

- 在`UpdateDescriptorSets`中为其添加描述符信息:

    ```c
    bufferInfo.range = sizeof(CameraOfUniformBufferObject);
    
    VkDescriptorBufferInfo LightInfo{};
    LightInfo.buffer = lightBuffer->selfs[i];
    LightInfo.offset = 0;
    LightInfo.range = sizeof(PointLightOfUniformBufferObject);
    
    VkDescriptorImageInfo imageInfo{};
    ```

- 在其后更新`descriptorWrites`:

    ```c
    descriptorWrites[1].sType = VK_STRUCTURE_TYPE_WRITE_DESCRIPTOR_SET;
    descriptorWrites[1].dstSet = self[i];
    descriptorWrites[1].dstBinding = 1;
    descriptorWrites[1].dstArrayElement = 0;
    descriptorWrites[1].descriptorType = VK_DESCRIPTOR_TYPE_UNIFORM_BUFFER;
    descriptorWrites[1].descriptorCount = 1;
    descriptorWrites[1].pBufferInfo = &LightInfo;
    ```

总之，要不还是把Uniform都写在一个结构体算了，但是，我觉得对于纹理，还是不能写死。



## 绘制多个物体

首先，我们需要新建一个VertexBuffer对象

```c
verterBuffer = new VertexBuffer(swapChain,vertices1);
verterBuffer->createSelf(commandBuffer->commandPool);

verterBuffer2 = new VertexBuffer(swapChain,vertices2,indices2);
verterBuffer2->createSelf(commandBuffer->commandPool);
verterBuffer2->createIndexBuffer(commandBuffer->commandPool);
```

然后，调整commandBuffer的`excuteCommandBuffer`函数：

```c
VkBuffer vertexBuffers[] = { vertexBuffer2->self };
VkDeviceSize offsets[] = { 0 };
vkCmdBindVertexBuffers(commandBuffers[i], 0, 1, vertexBuffers, offsets);
vkCmdBindIndexBuffer(commandBuffers[i], vertexBuffer2->indexBuffer, 0, VK_INDEX_TYPE_UINT16);
vkCmdBindDescriptorSets(commandBuffers[i], VK_PIPELINE_BIND_POINT_GRAPHICS, graphicsPipeline->pipelineLayout, 0, 1, &descriptorSets[i], 0, nullptr);
vkCmdDrawIndexed(commandBuffers[i], static_cast<uint32_t>(vertexBuffer2->indices.size()), 1, 0, 0, 0);

VkBuffer vertexBuffers2[] = { vertexBuffer1->self };
VkDeviceSize offsets2[] = { 0 };
vkCmdBindVertexBuffers(commandBuffers[i], 0, 1, vertexBuffers2, offsets2);
vkCmdBindDescriptorSets(commandBuffers[i], VK_PIPELINE_BIND_POINT_GRAPHICS, graphicsPipeline->pipelineLayout, 0, 1, &descriptorSets[i], 0, nullptr);
vkCmdDraw(commandBuffers[i], static_cast<uint32_t>(vertexBuffer1->vertices.size()), 1, 0, 0);
```



