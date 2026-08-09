#define _POSIX_C_SOURCE 200809L

#include <android/hardware_buffer.h>

#include <jni.h>

#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/system_properties.h>
#include <unistd.h>

#include <vulkan/vulkan.h>
#include <vulkan/vulkan_android.h>

static void
append_line(char *report, size_t capacity, size_t *used, const char *format,
            ...)
{
    if (*used >= capacity) {
        return;
    }
    va_list arguments;
    va_start(arguments, format);
    int written = vsnprintf(report + *used, capacity - *used, format, arguments);
    va_end(arguments);
    if (written > 0) {
        size_t amount = (size_t)written;
        if (amount >= capacity - *used) {
            *used = capacity;
        } else {
            *used += amount;
        }
    }
}

static jstring
report_string(JNIEnv *env, const char *report)
{
    return (*env)->NewStringUTF(env, report);
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
        return 0;
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

static int
choose_memory_type(VkPhysicalDevice physical_device, uint32_t type_bits,
                   uint32_t *memory_type_index)
{
    VkPhysicalDeviceMemoryProperties properties;
    vkGetPhysicalDeviceMemoryProperties(physical_device, &properties);
    for (uint32_t index = 0; index < properties.memoryTypeCount; ++index) {
        if ((type_bits & (1u << index)) != 0) {
            *memory_type_index = index;
            return 1;
        }
    }
    return 0;
}

static uint32_t
probe_property_u32(const char *name, uint32_t fallback, uint32_t maximum)
{
    char value[PROP_VALUE_MAX] = "";
    int length = __system_property_get(name, value);
    if (length <= 0) {
        return fallback;
    }
    char *end = NULL;
    unsigned long parsed = strtoul(value, &end, 0);
    if (end == value || *end != '\0' || parsed == 0 || parsed > maximum) {
        return fallback;
    }
    return (uint32_t)parsed;
}

static uint64_t
probe_property_u64(const char *name, uint64_t fallback)
{
    char value[PROP_VALUE_MAX] = "";
    int length = __system_property_get(name, value);
    if (length <= 0) {
        return fallback;
    }
    char *end = NULL;
    unsigned long long parsed = strtoull(value, &end, 0);
    if (end == value || *end != '\0') {
        return fallback;
    }
    return (uint64_t)parsed;
}

JNIEXPORT jstring JNICALL
Java_com_xjsonderulo_steamandroid_novalab_MainActivity_nativeRunAndroidVulkanHardwareBufferProbe(
    JNIEnv *env, jobject object)
{
    (void)object;
    char report[4096] = "";
    size_t used = 0;
    append_line(report, sizeof(report), &used,
                "android_vulkan_probe_version=1\n");

    AHardwareBuffer *hardware_buffer = NULL;
    VkInstance instance = VK_NULL_HANDLE;
    VkDevice device = VK_NULL_HANDLE;
    VkImage image = VK_NULL_HANDLE;
    VkDeviceMemory memory = VK_NULL_HANDLE;
    VkCommandPool command_pool = VK_NULL_HANDLE;
    VkCommandBuffer command_buffer = VK_NULL_HANDLE;
    VkFence fence = VK_NULL_HANDLE;
    int success = 0;

    const uint32_t buffer_width = probe_property_u32(
        "debug.nova.ahb_layout_width", 64, 4096);
    const uint32_t buffer_height = probe_property_u32(
        "debug.nova.ahb_layout_height", 64, 4096);
    const uint64_t default_usage = AHARDWAREBUFFER_USAGE_CPU_READ_OFTEN |
                                    AHARDWAREBUFFER_USAGE_GPU_SAMPLED_IMAGE |
                                    AHARDWAREBUFFER_USAGE_GPU_FRAMEBUFFER;
    const uint64_t buffer_usage = probe_property_u64(
        "debug.nova.ahb_layout_usage", default_usage);
    AHardwareBuffer_Desc buffer_description = {
        .width = buffer_width,
        .height = buffer_height,
        .layers = 1,
        .format = AHARDWAREBUFFER_FORMAT_R8G8B8A8_UNORM,
        .usage = buffer_usage,
    };
    int status = AHardwareBuffer_isSupported(&buffer_description);
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.profile=%ux%u format=0x%x usage=0x%llx\n",
                buffer_width, buffer_height, buffer_description.format,
                (unsigned long long)buffer_usage);
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.supported=%d\n", status);
    if (!status) {
        goto done;
    }
    status = AHardwareBuffer_allocate(&buffer_description, &hardware_buffer);
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.allocate_status=%d\n", status);
    if (status != 0 || hardware_buffer == NULL) {
        goto done;
    }
    AHardwareBuffer_Desc described = {0};
    AHardwareBuffer_describe(hardware_buffer, &described);
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.describe=%ux%u stride=%u layers=%u format=0x%x usage=0x%llx\n",
                described.width, described.height, described.stride,
                described.layers, described.format,
                (unsigned long long)described.usage);

    VkApplicationInfo application_info = {
        .sType = VK_STRUCTURE_TYPE_APPLICATION_INFO,
        .pApplicationName = "Nova Android Vulkan AHardwareBuffer probe",
        .applicationVersion = 1,
        .pEngineName = "nova-lab",
        .engineVersion = 1,
        .apiVersion = VK_API_VERSION_1_0,
    };
    VkInstanceCreateInfo instance_info = {
        .sType = VK_STRUCTURE_TYPE_INSTANCE_CREATE_INFO,
        .pApplicationInfo = &application_info,
    };
    VkResult result = vkCreateInstance(&instance_info, NULL, &instance);
    append_line(report, sizeof(report), &used,
                "vkCreateInstance_status=%d\n", result);
    if (result != VK_SUCCESS) {
        goto done;
    }

    uint32_t device_count = 0;
    result = vkEnumeratePhysicalDevices(instance, &device_count, NULL);
    append_line(report, sizeof(report), &used,
                "physical_device_count_status=%d count=%u\n", result,
                device_count);
    if (result != VK_SUCCESS || device_count == 0) {
        goto done;
    }
    VkPhysicalDevice physical_device = VK_NULL_HANDLE;
    result = vkEnumeratePhysicalDevices(instance, &device_count, &physical_device);
    if (result != VK_SUCCESS) {
        append_line(report, sizeof(report), &used,
                    "physical_device_status=%d\n", result);
        goto done;
    }
    VkPhysicalDeviceProperties device_properties;
    vkGetPhysicalDeviceProperties(physical_device, &device_properties);
    append_line(report, sizeof(report), &used, "device=%s\n",
                device_properties.deviceName);

    const char *android_external_memory_extension =
        VK_ANDROID_EXTERNAL_MEMORY_ANDROID_HARDWARE_BUFFER_EXTENSION_NAME;
    const char *external_memory_extension =
        VK_KHR_EXTERNAL_MEMORY_EXTENSION_NAME;
    if (!has_device_extension(physical_device, android_external_memory_extension)) {
        append_line(report, sizeof(report), &used, "extension.%s=missing\n",
                    android_external_memory_extension);
        goto done;
    }
    if (!has_device_extension(physical_device, external_memory_extension)) {
        append_line(report, sizeof(report), &used, "extension.%s=missing\n",
                    external_memory_extension);
        goto done;
    }
    append_line(report, sizeof(report), &used, "extension.%s=present\n",
                android_external_memory_extension);
    append_line(report, sizeof(report), &used, "extension.%s=present\n",
                external_memory_extension);

    const char *optional_external_extensions[] = {
        VK_KHR_EXTERNAL_MEMORY_FD_EXTENSION_NAME,
        VK_EXT_EXTERNAL_MEMORY_DMA_BUF_EXTENSION_NAME,
        VK_EXT_IMAGE_DRM_FORMAT_MODIFIER_EXTENSION_NAME,
    };
    for (uint32_t index = 0;
         index < sizeof(optional_external_extensions) /
                     sizeof(optional_external_extensions[0]);
         ++index) {
        int present = has_device_extension(physical_device,
                                           optional_external_extensions[index]);
        append_line(report, sizeof(report), &used, "extension.%s=%s\n",
                    optional_external_extensions[index],
                    present ? "present" : "missing");
    }

    uint32_t queue_family_count = 0;
    vkGetPhysicalDeviceQueueFamilyProperties(physical_device,
                                             &queue_family_count, NULL);
    VkQueueFamilyProperties *queue_families =
        calloc(queue_family_count, sizeof(*queue_families));
    if (queue_families == NULL) {
        goto done;
    }
    vkGetPhysicalDeviceQueueFamilyProperties(physical_device,
                                             &queue_family_count, queue_families);
    uint32_t queue_family = UINT32_MAX;
    for (uint32_t index = 0; index < queue_family_count; ++index) {
        if ((queue_families[index].queueFlags & VK_QUEUE_GRAPHICS_BIT) != 0) {
            queue_family = index;
            break;
        }
    }
    free(queue_families);
    if (queue_family == UINT32_MAX) {
        goto done;
    }

    float priority = 1.0f;
    VkDeviceQueueCreateInfo queue_info = {
        .sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
        .queueFamilyIndex = queue_family,
        .queueCount = 1,
        .pQueuePriorities = &priority,
    };
    const char *device_extensions[5] = {
        VK_ANDROID_EXTERNAL_MEMORY_ANDROID_HARDWARE_BUFFER_EXTENSION_NAME,
        VK_KHR_EXTERNAL_MEMORY_EXTENSION_NAME,
    };
    uint32_t device_extension_count = 2;
    for (uint32_t index = 0;
         index < sizeof(optional_external_extensions) /
                     sizeof(optional_external_extensions[0]);
         ++index) {
        if (has_device_extension(physical_device,
                                 optional_external_extensions[index])) {
            device_extensions[device_extension_count++] =
                optional_external_extensions[index];
        }
    }
    VkDeviceCreateInfo device_info = {
        .sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .queueCreateInfoCount = 1,
        .pQueueCreateInfos = &queue_info,
        .enabledExtensionCount = device_extension_count,
        .ppEnabledExtensionNames = device_extensions,
    };
    result = vkCreateDevice(physical_device, &device_info, NULL, &device);
    append_line(report, sizeof(report), &used, "vkCreateDevice_status=%d\n",
                result);
    if (result != VK_SUCCESS) {
        goto done;
    }

    PFN_vkGetAndroidHardwareBufferPropertiesANDROID get_hardware_buffer_properties =
        (PFN_vkGetAndroidHardwareBufferPropertiesANDROID)vkGetDeviceProcAddr(
            device, "vkGetAndroidHardwareBufferPropertiesANDROID");
    if (get_hardware_buffer_properties == NULL) {
        append_line(report, sizeof(report), &used,
                    "vkGetAndroidHardwareBufferProperties_status=unavailable\n");
        goto done;
    }
    VkAndroidHardwareBufferPropertiesANDROID hardware_buffer_properties = {
        .sType = VK_STRUCTURE_TYPE_ANDROID_HARDWARE_BUFFER_PROPERTIES_ANDROID,
    };
    result = get_hardware_buffer_properties(device, hardware_buffer,
                                             &hardware_buffer_properties);
    append_line(report, sizeof(report), &used,
                "vkGetAndroidHardwareBufferProperties_status=%d allocation_size=%llu memory_type_bits=0x%x\n",
                result,
                (unsigned long long)hardware_buffer_properties.allocationSize,
                hardware_buffer_properties.memoryTypeBits);
    if (result != VK_SUCCESS || hardware_buffer_properties.memoryTypeBits == 0) {
        goto done;
    }

    VkExternalMemoryImageCreateInfo external_image_info = {
        .sType = VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO,
        .handleTypes = VK_EXTERNAL_MEMORY_HANDLE_TYPE_ANDROID_HARDWARE_BUFFER_BIT_ANDROID,
    };
    VkImageCreateInfo image_info = {
        .sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
        .pNext = &external_image_info,
        .imageType = VK_IMAGE_TYPE_2D,
        .format = VK_FORMAT_R8G8B8A8_UNORM,
        .extent = {buffer_width, buffer_height, 1},
        .mipLevels = 1,
        .arrayLayers = 1,
        .samples = VK_SAMPLE_COUNT_1_BIT,
        .tiling = VK_IMAGE_TILING_OPTIMAL,
        .usage = VK_IMAGE_USAGE_TRANSFER_DST_BIT |
                 VK_IMAGE_USAGE_TRANSFER_SRC_BIT |
                 VK_IMAGE_USAGE_SAMPLED_BIT |
                 VK_IMAGE_USAGE_STORAGE_BIT,
        .sharingMode = VK_SHARING_MODE_EXCLUSIVE,
        .initialLayout = VK_IMAGE_LAYOUT_UNDEFINED,
    };
    result = vkCreateImage(device, &image_info, NULL, &image);
    append_line(report, sizeof(report), &used,
                "vkCreateImage_status=%d tiling=%d usage=0x%x\n", result,
                image_info.tiling, image_info.usage);
    if (result != VK_SUCCESS) {
        goto done;
    }

    VkMemoryRequirements image_requirements;
    vkGetImageMemoryRequirements(device, image, &image_requirements);
    uint32_t memory_type_index = 0;
    uint32_t type_bits = hardware_buffer_properties.memoryTypeBits &
                         image_requirements.memoryTypeBits;
    if (!choose_memory_type(physical_device, type_bits, &memory_type_index)) {
        append_line(report, sizeof(report), &used,
                    "memory_type_selection=fail type_bits=0x%x\n", type_bits);
        goto done;
    }
    VkImportAndroidHardwareBufferInfoANDROID import_info = {
        .sType = VK_STRUCTURE_TYPE_IMPORT_ANDROID_HARDWARE_BUFFER_INFO_ANDROID,
        .buffer = hardware_buffer,
    };
    VkMemoryAllocateInfo allocation_info = {
        .sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .pNext = &import_info,
        .allocationSize = hardware_buffer_properties.allocationSize,
        .memoryTypeIndex = memory_type_index,
    };
    result = vkAllocateMemory(device, &allocation_info, NULL, &memory);
    append_line(report, sizeof(report), &used,
                "vkAllocateMemory_import_status=%d memory_type_index=%u\n",
                result, memory_type_index);
    if (result != VK_SUCCESS) {
        goto done;
    }
    result = vkBindImageMemory(device, image, memory, 0);
    append_line(report, sizeof(report), &used, "vkBindImageMemory_status=%d\n",
                result);
    if (result != VK_SUCCESS) {
        goto done;
    }
    if (has_device_extension(
            physical_device, VK_EXT_IMAGE_DRM_FORMAT_MODIFIER_EXTENSION_NAME)) {
        PFN_vkGetImageDrmFormatModifierPropertiesEXT get_modifier_properties =
            (PFN_vkGetImageDrmFormatModifierPropertiesEXT)vkGetDeviceProcAddr(
                device, "vkGetImageDrmFormatModifierPropertiesEXT");
        if (get_modifier_properties != NULL) {
            VkImageDrmFormatModifierPropertiesEXT modifier_properties = {
                .sType = VK_STRUCTURE_TYPE_IMAGE_DRM_FORMAT_MODIFIER_PROPERTIES_EXT,
            };
            result = get_modifier_properties(device, image, &modifier_properties);
            append_line(report, sizeof(report), &used,
                        "android_vulkan_image_modifier_status=%d modifier=0x%llx\n",
                        result,
                        (unsigned long long)modifier_properties.drmFormatModifier);
        } else {
            append_line(report, sizeof(report), &used,
                        "android_vulkan_image_modifier_status=unavailable\n");
        }
    } else {
        append_line(report, sizeof(report), &used,
                    "android_vulkan_image_modifier_status=extension_missing\n");
    }

    VkQueue queue;
    vkGetDeviceQueue(device, queue_family, 0, &queue);
    VkCommandPoolCreateInfo pool_info = {
        .sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
        .queueFamilyIndex = queue_family,
    };
    result = vkCreateCommandPool(device, &pool_info, NULL, &command_pool);
    if (result != VK_SUCCESS) {
        append_line(report, sizeof(report), &used,
                    "vkCreateCommandPool_status=%d\n", result);
        goto done;
    }
    VkCommandBufferAllocateInfo command_info = {
        .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .commandPool = command_pool,
        .level = VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandBufferCount = 1,
    };
    result = vkAllocateCommandBuffers(device, &command_info, &command_buffer);
    if (result != VK_SUCCESS) {
        append_line(report, sizeof(report), &used,
                    "vkAllocateCommandBuffers_status=%d\n", result);
        goto done;
    }
    VkCommandBufferBeginInfo begin_info = {
        .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
        .flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
    };
    result = vkBeginCommandBuffer(command_buffer, &begin_info);
    if (result != VK_SUCCESS) {
        append_line(report, sizeof(report), &used,
                    "vkBeginCommandBuffer_status=%d\n", result);
        goto done;
    }
    VkImageSubresourceRange subresource_range = {
        .aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
        .baseMipLevel = 0,
        .levelCount = 1,
        .baseArrayLayer = 0,
        .layerCount = 1,
    };
    VkImageMemoryBarrier to_transfer = {
        .sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
        .srcAccessMask = 0,
        .dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT,
        .oldLayout = VK_IMAGE_LAYOUT_UNDEFINED,
        .newLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
        .image = image,
        .subresourceRange = subresource_range,
    };
    vkCmdPipelineBarrier(command_buffer, VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
                         VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, NULL, 0, NULL,
                         1, &to_transfer);
    VkClearColorValue clear_color = {{64.0f / 255.0f, 128.0f / 255.0f,
                                      192.0f / 255.0f, 1.0f}};
    vkCmdClearColorImage(command_buffer, image,
                         VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL, &clear_color, 1,
                         &subresource_range);
    VkImageMemoryBarrier to_host = {
        .sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
        .srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT,
        .dstAccessMask = VK_ACCESS_HOST_READ_BIT,
        .oldLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
        .newLayout = VK_IMAGE_LAYOUT_GENERAL,
        .image = image,
        .subresourceRange = subresource_range,
    };
    vkCmdPipelineBarrier(command_buffer, VK_PIPELINE_STAGE_TRANSFER_BIT,
                         VK_PIPELINE_STAGE_HOST_BIT, 0, 0, NULL, 0, NULL, 1,
                         &to_host);
    result = vkEndCommandBuffer(command_buffer);
    if (result != VK_SUCCESS) {
        append_line(report, sizeof(report), &used,
                    "vkEndCommandBuffer_status=%d\n", result);
        goto done;
    }
    VkFenceCreateInfo fence_info = {
        .sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
    };
    result = vkCreateFence(device, &fence_info, NULL, &fence);
    if (result != VK_SUCCESS) {
        append_line(report, sizeof(report), &used,
                    "vkCreateFence_status=%d\n", result);
        goto done;
    }
    VkSubmitInfo submit_info = {
        .sType = VK_STRUCTURE_TYPE_SUBMIT_INFO,
        .commandBufferCount = 1,
        .pCommandBuffers = &command_buffer,
    };
    result = vkQueueSubmit(queue, 1, &submit_info, fence);
    append_line(report, sizeof(report), &used, "vkQueueSubmit_status=%d\n",
                result);
    if (result != VK_SUCCESS) {
        goto done;
    }
    result = vkWaitForFences(device, 1, &fence, VK_TRUE, 5000000000ull);
    append_line(report, sizeof(report), &used, "vkWaitForFences_status=%d\n",
                result);
    if (result != VK_SUCCESS) {
        goto done;
    }

    void *mapped = NULL;
    status = AHardwareBuffer_lock(hardware_buffer,
                                  AHARDWAREBUFFER_USAGE_CPU_READ_OFTEN, -1, NULL,
                                  &mapped);
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.lock_after_vulkan_status=%d\n", status);
    if (status != 0 || mapped == NULL) {
        goto done;
    }
    uint8_t *pixel = (uint8_t *)mapped;
    append_line(report, sizeof(report), &used,
                "vulkan_clear_pixel=%02x%02x%02x%02x\n", pixel[0], pixel[1],
                pixel[2], pixel[3]);
    int pixel_pass = pixel[0] == 0x40 && pixel[1] == 0x80 &&
                     pixel[2] == 0xc0 && pixel[3] == 0xff;
    int32_t read_unlock_fence = -1;
    status = AHardwareBuffer_unlock(hardware_buffer, &read_unlock_fence);
    if (read_unlock_fence >= 0) {
        close(read_unlock_fence);
    }
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.unlock_after_vulkan_status=%d\n", status);
    if (status == 0 && pixel_pass) {
        append_line(report, sizeof(report), &used,
                    "android_vulkan_ahardwarebuffer=pass\n");
        success = 1;
    } else {
        append_line(report, sizeof(report), &used,
                    "android_vulkan_ahardwarebuffer=fail\n");
    }

done:
    if (fence != VK_NULL_HANDLE) {
        vkDestroyFence(device, fence, NULL);
    }
    if (command_buffer != VK_NULL_HANDLE) {
        vkFreeCommandBuffers(device, command_pool, 1, &command_buffer);
    }
    if (command_pool != VK_NULL_HANDLE) {
        vkDestroyCommandPool(device, command_pool, NULL);
    }
    if (memory != VK_NULL_HANDLE) {
        vkFreeMemory(device, memory, NULL);
    }
    if (image != VK_NULL_HANDLE) {
        vkDestroyImage(device, image, NULL);
    }
    if (device != VK_NULL_HANDLE) {
        vkDestroyDevice(device, NULL);
    }
    if (instance != VK_NULL_HANDLE) {
        vkDestroyInstance(instance, NULL);
    }
    if (hardware_buffer != NULL) {
        AHardwareBuffer_release(hardware_buffer);
    }
    if (!success) {
        append_line(report, sizeof(report), &used,
                    "android_vulkan_probe=fail\n");
    }
    return report_string(env, report);
}
