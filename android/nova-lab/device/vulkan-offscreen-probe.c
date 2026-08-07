#define _POSIX_C_SOURCE 200809L

#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <vulkan/vulkan.h>

static void
check_vk(VkResult result, const char *operation)
{
    if (result != VK_SUCCESS) {
        fprintf(stderr, "%s failed: %d\n", operation, result);
        exit(1);
    }
}

static uint32_t
find_memory_type(VkPhysicalDevice physical_device,
                 uint32_t type_bits,
                 VkMemoryPropertyFlags required)
{
    VkPhysicalDeviceMemoryProperties properties;
    vkGetPhysicalDeviceMemoryProperties(physical_device, &properties);
    for (uint32_t index = 0; index < properties.memoryTypeCount; ++index) {
        if ((type_bits & (1u << index)) != 0 &&
            (properties.memoryTypes[index].propertyFlags & required) == required) {
            return index;
        }
    }
    fprintf(stderr, "no compatible memory type\n");
    exit(1);
}

static int
has_device_extension(VkPhysicalDevice physical_device, const char *name)
{
    uint32_t extension_count = 0;
    if (vkEnumerateDeviceExtensionProperties(
            physical_device, NULL, &extension_count, NULL) != VK_SUCCESS) {
        return 0;
    }

    VkExtensionProperties *extensions =
        calloc(extension_count, sizeof(*extensions));
    if (extensions == NULL) {
        fprintf(stderr, "device extension allocation failed\n");
        exit(1);
    }
    VkResult result = vkEnumerateDeviceExtensionProperties(
        physical_device, NULL, &extension_count, extensions);
    if (result != VK_SUCCESS) {
        free(extensions);
        return 0;
    }

    int found = 0;
    for (uint32_t index = 0; index < extension_count; ++index) {
        if (strcmp(extensions[index].extensionName, name) == 0) {
            found = 1;
            break;
        }
    }
    free(extensions);
    return found;
}

int
main(void)
{
    VkApplicationInfo application_info = {
        .sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .pApplicationName = "Nova KGSL offscreen probe",
        .applicationVersion = 1,
        .pEngineName = "nova-lab",
        .engineVersion = 1,
        .apiVersion = VK_API_VERSION_1_0,
    };
    VkInstanceCreateInfo instance_info = {
        .sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pApplicationInfo = &application_info,
    };
    VkInstance instance;
    check_vk(vkCreateInstance(&instance_info, NULL, &instance), "vkCreateInstance");

    uint32_t device_count = 0;
    check_vk(vkEnumeratePhysicalDevices(instance, &device_count, NULL),
             "vkEnumeratePhysicalDevices(count)");
    if (device_count == 0) {
        fprintf(stderr, "no Vulkan physical devices\n");
        return 1;
    }

    VkPhysicalDevice physical_device;
    check_vk(vkEnumeratePhysicalDevices(instance, &device_count, &physical_device),
             "vkEnumeratePhysicalDevices");

    VkPhysicalDeviceProperties device_properties;
    vkGetPhysicalDeviceProperties(physical_device, &device_properties);
    printf("device=%s\n", device_properties.deviceName);

    uint32_t queue_family_count = 0;
    vkGetPhysicalDeviceQueueFamilyProperties(physical_device, &queue_family_count, NULL);
    VkQueueFamilyProperties *queue_families =
        calloc(queue_family_count, sizeof(*queue_families));
    if (queue_families == NULL) {
        fprintf(stderr, "queue family allocation failed\n");
        return 1;
    }
    vkGetPhysicalDeviceQueueFamilyProperties(
        physical_device, &queue_family_count, queue_families);

    uint32_t queue_family = UINT32_MAX;
    for (uint32_t index = 0; index < queue_family_count; ++index) {
        if ((queue_families[index].queueFlags & VK_QUEUE_GRAPHICS_BIT) != 0) {
            queue_family = index;
            break;
        }
    }
    free(queue_families);
    if (queue_family == UINT32_MAX) {
        fprintf(stderr, "no graphics queue family\n");
        return 1;
    }

    const char *external_memory_extensions[] = {
        VK_KHR_EXTERNAL_MEMORY_EXTENSION_NAME,
        VK_KHR_EXTERNAL_MEMORY_FD_EXTENSION_NAME,
        VK_EXT_EXTERNAL_MEMORY_DMA_BUF_EXTENSION_NAME,
    };
    for (uint32_t index = 0;
         index < sizeof(external_memory_extensions) /
                     sizeof(external_memory_extensions[0]);
         ++index) {
        if (!has_device_extension(physical_device,
                                  external_memory_extensions[index])) {
            printf("extension.%s=missing\n", external_memory_extensions[index]);
            fprintf(stderr, "required external-memory extension is missing\n");
            return 1;
        }
        printf("extension.%s=present\n", external_memory_extensions[index]);
    }

    float priority = 1.0f;
    VkDeviceQueueCreateInfo queue_info = {
        .sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
        .queueFamilyIndex = queue_family,
        .queueCount = 1,
        .pQueuePriorities = &priority,
    };
    VkDeviceCreateInfo device_info = {
        .sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .queueCreateInfoCount = 1,
        .pQueueCreateInfos = &queue_info,
        .enabledExtensionCount = sizeof(external_memory_extensions) /
                                  sizeof(external_memory_extensions[0]),
        .ppEnabledExtensionNames = external_memory_extensions,
    };
    VkDevice device;
    check_vk(vkCreateDevice(physical_device, &device_info, NULL, &device),
             "vkCreateDevice");

    VkQueue queue;
    vkGetDeviceQueue(device, queue_family, 0, &queue);

    VkCommandPoolCreateInfo pool_info = {
        .sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
        .queueFamilyIndex = queue_family,
    };
    VkCommandPool command_pool;
    check_vk(vkCreateCommandPool(device, &pool_info, NULL, &command_pool),
             "vkCreateCommandPool");

    VkCommandBufferAllocateInfo command_info = {
        .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .commandPool = command_pool,
        .level = VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandBufferCount = 1,
    };
    VkCommandBuffer command_buffer;
    check_vk(vkAllocateCommandBuffers(device, &command_info, &command_buffer),
             "vkAllocateCommandBuffers");

    const VkDeviceSize buffer_size = 4096;
    VkExternalMemoryBufferCreateInfo external_buffer_info = {
        .sType = VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_BUFFER_CREATE_INFO,
        .handleTypes = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT,
    };
    VkBufferCreateInfo buffer_info = {
        .sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        .pNext = &external_buffer_info,
        .size = buffer_size,
        .usage = VK_BUFFER_USAGE_TRANSFER_DST_BIT,
        .sharingMode = VK_SHARING_MODE_EXCLUSIVE,
    };
    VkBuffer buffer;
    check_vk(vkCreateBuffer(device, &buffer_info, NULL, &buffer), "vkCreateBuffer");

    VkMemoryRequirements memory_requirements;
    vkGetBufferMemoryRequirements(device, buffer, &memory_requirements);
    VkExportMemoryAllocateInfo export_info = {
        .sType = VK_STRUCTURE_TYPE_EXPORT_MEMORY_ALLOCATE_INFO,
        .handleTypes = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT,
    };
    VkMemoryAllocateInfo allocation_info = {
        .sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .pNext = &export_info,
        .allocationSize = memory_requirements.size,
        .memoryTypeIndex = find_memory_type(
            physical_device,
            memory_requirements.memoryTypeBits,
            VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT),
    };
    VkDeviceMemory memory;
    check_vk(vkAllocateMemory(device, &allocation_info, NULL, &memory),
             "vkAllocateMemory");
    check_vk(vkBindBufferMemory(device, buffer, memory, 0), "vkBindBufferMemory");

    PFN_vkGetMemoryFdKHR get_memory_fd =
        (PFN_vkGetMemoryFdKHR)vkGetDeviceProcAddr(device, "vkGetMemoryFdKHR");
    if (get_memory_fd == NULL) {
        fprintf(stderr, "vkGetMemoryFdKHR is unavailable\n");
        return 1;
    }
    VkMemoryGetFdInfoKHR fd_info = {
        .sType = VK_STRUCTURE_TYPE_MEMORY_GET_FD_INFO_KHR,
        .memory = memory,
        .handleType = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT,
    };
    int dma_buf_fd = -1;
    check_vk(get_memory_fd(device, &fd_info, &dma_buf_fd), "vkGetMemoryFdKHR");
    if (dma_buf_fd < 0) {
        fprintf(stderr, "vkGetMemoryFdKHR returned an invalid fd\n");
        return 1;
    }
    printf("dma_buf_fd=%d\n", dma_buf_fd);
    char fd_path[64];
    char fd_target[256];
    snprintf(fd_path, sizeof(fd_path), "/proc/self/fd/%d", dma_buf_fd);
    ssize_t target_length = readlink(fd_path, fd_target, sizeof(fd_target) - 1);
    if (target_length >= 0) {
        fd_target[target_length] = '\0';
        printf("dma_buf_fd_target=%s\n", fd_target);
    }
    printf("dma_buf_export=pass\n");

    VkCommandBufferBeginInfo begin_info = {
        .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
    };
    check_vk(vkBeginCommandBuffer(command_buffer, &begin_info), "vkBeginCommandBuffer");
    vkCmdFillBuffer(command_buffer, buffer, 0, buffer_size, 0xc0dec0deu);
    check_vk(vkEndCommandBuffer(command_buffer), "vkEndCommandBuffer");

    VkFenceCreateInfo fence_info = {
        .sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
    };
    VkFence fence;
    check_vk(vkCreateFence(device, &fence_info, NULL, &fence), "vkCreateFence");
    VkSubmitInfo submit_info = {
        .sType = VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .commandBufferCount = 1,
        .pCommandBuffers = &command_buffer,
    };
    check_vk(vkQueueSubmit(queue, 1, &submit_info, fence), "vkQueueSubmit");
    check_vk(vkWaitForFences(device, 1, &fence, VK_TRUE, 5000000000ull),
             "vkWaitForFences");

    uint32_t *mapped = NULL;
    check_vk(vkMapMemory(device, memory, 0, sizeof(*mapped), 0, (void **)&mapped),
             "vkMapMemory");
    uint32_t value = *mapped;
    vkUnmapMemory(device, memory);
    printf("fill_value=0x%08x\n", value);
    if (value != 0xc0dec0deu) {
        fprintf(stderr, "unexpected fill value\n");
        return 1;
    }
    printf("offscreen_fill=pass\n");

    VkBuffer imported_buffer;
    check_vk(vkCreateBuffer(device, &buffer_info, NULL, &imported_buffer),
             "vkCreateBuffer(imported)");
    VkMemoryRequirements imported_requirements;
    vkGetBufferMemoryRequirements(device, imported_buffer,
                                  &imported_requirements);
    VkImportMemoryFdInfoKHR import_info = {
        .sType = VK_STRUCTURE_TYPE_IMPORT_MEMORY_FD_INFO_KHR,
        .handleType = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT,
        .fd = dma_buf_fd,
    };
    VkMemoryAllocateInfo import_allocation_info = {
        .sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .pNext = &import_info,
        .allocationSize = imported_requirements.size,
        .memoryTypeIndex = find_memory_type(
            physical_device,
            imported_requirements.memoryTypeBits,
            VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT),
    };
    VkDeviceMemory imported_memory;
    check_vk(vkAllocateMemory(device, &import_allocation_info, NULL,
                              &imported_memory),
             "vkAllocateMemory(imported)");
    dma_buf_fd = -1;
    check_vk(vkBindBufferMemory(device, imported_buffer, imported_memory, 0),
             "vkBindBufferMemory(imported)");

    uint32_t *imported_mapped = NULL;
    check_vk(vkMapMemory(device, imported_memory, 0, sizeof(*imported_mapped),
                         0, (void **)&imported_mapped),
             "vkMapMemory(imported)");
    uint32_t imported_value = *imported_mapped;
    vkUnmapMemory(device, imported_memory);
    printf("imported_fill_value=0x%08x\n", imported_value);
    if (imported_value != 0xc0dec0deu) {
        fprintf(stderr, "imported dma-buf did not retain the fill value\n");
        return 1;
    }
    printf("dma_buf_import=pass\n");

    vkDestroyFence(device, fence, NULL);
    vkFreeMemory(device, imported_memory, NULL);
    vkDestroyBuffer(device, imported_buffer, NULL);
    vkFreeMemory(device, memory, NULL);
    vkDestroyBuffer(device, buffer, NULL);
    vkFreeCommandBuffers(device, command_pool, 1, &command_buffer);
    vkDestroyCommandPool(device, command_pool, NULL);
    vkDestroyDevice(device, NULL);
    vkDestroyInstance(instance, NULL);
    return 0;
}
