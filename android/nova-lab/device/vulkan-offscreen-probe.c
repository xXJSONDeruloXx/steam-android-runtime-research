#define _POSIX_C_SOURCE 200809L

#include <stdint.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <poll.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <sys/uio.h>
#include <time.h>
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

static int
receive_dma_buf_fds(const char *socket_path, int *file_descriptors,
                    size_t max_file_descriptors, int *connection_fd)
{
    if (strlen(socket_path) >= sizeof(((struct sockaddr_un *)0)->sun_path)) {
        fprintf(stderr, "AHB bridge socket path is too long\n");
        return -1;
    }
    struct sockaddr_un address = {
        .sun_family = AF_UNIX,
    };
    strcpy(address.sun_path, socket_path);
    int socket_fd = -1;
    int connect_errno = 0;
    for (int attempt = 0; attempt < 100; ++attempt) {
        socket_fd = socket(AF_UNIX, SOCK_STREAM, 0);
        if (socket_fd >= 0 &&
            connect(socket_fd, (struct sockaddr *)&address, sizeof(address)) == 0) {
            break;
        }
        connect_errno = errno;
        if (socket_fd >= 0) {
            close(socket_fd);
            socket_fd = -1;
        }
        if (connect_errno != ENOENT && connect_errno != ECONNREFUSED) {
            break;
        }
        struct timespec delay = {
            .tv_sec = 0,
            .tv_nsec = 100000000,
        };
        nanosleep(&delay, NULL);
    }
    if (socket_fd < 0) {
        errno = connect_errno;
        perror("connect(AHB bridge)");
        return -1;
    }

    char payload[256];
    char control[CMSG_SPACE(sizeof(int) * 16)] = {0};
    struct iovec vector = {
        .iov_base = payload,
        .iov_len = sizeof(payload),
    };
    struct msghdr message = {
        .msg_iov = &vector,
        .msg_iovlen = 1,
        .msg_control = control,
        .msg_controllen = sizeof(control),
    };
    ssize_t received_bytes = recvmsg(socket_fd, &message, 0);
    if (received_bytes < 0) {
        perror("recvmsg(AHB bridge)");
        close(socket_fd);
        return -1;
    }
    size_t received_count = 0;
    for (struct cmsghdr *header = CMSG_FIRSTHDR(&message); header != NULL;
         header = CMSG_NXTHDR(&message, header)) {
        if (header->cmsg_level != SOL_SOCKET ||
            header->cmsg_type != SCM_RIGHTS) {
            continue;
        }
        size_t byte_count = header->cmsg_len - CMSG_LEN(0);
        size_t descriptor_count = byte_count / sizeof(int);
        int *descriptors = (int *)CMSG_DATA(header);
        for (size_t index = 0; index < descriptor_count; ++index) {
            if (received_count < max_file_descriptors) {
                file_descriptors[received_count++] = descriptors[index];
            } else {
                close(descriptors[index]);
            }
        }
    }
    printf("ahb_bridge_recv_bytes=%zd ahb_bridge_fd_count=%zu\n",
           received_bytes, received_count);
    *connection_fd = socket_fd;
    return (int)received_count;
}

static int
send_acknowledgement(int connection_fd, const char *acknowledgement,
                     int acquire_fence_fd)
{
    struct iovec vector = {
        .iov_base = (void *)acknowledgement,
        .iov_len = strlen(acknowledgement),
    };
    char control[CMSG_SPACE(sizeof(int))] = {0};
    struct msghdr message = {
        .msg_iov = &vector,
        .msg_iovlen = 1,
    };
    if (acquire_fence_fd >= 0) {
        message.msg_control = control;
        message.msg_controllen = sizeof(control);
        struct cmsghdr *header = CMSG_FIRSTHDR(&message);
        header->cmsg_level = SOL_SOCKET;
        header->cmsg_type = SCM_RIGHTS;
        header->cmsg_len = CMSG_LEN(sizeof(int));
        memcpy(CMSG_DATA(header), &acquire_fence_fd, sizeof(acquire_fence_fd));
    }
    ssize_t sent = sendmsg(connection_fd, &message, 0);
    if (acquire_fence_fd >= 0) {
        close(acquire_fence_fd);
    }
    return sent == (ssize_t)strlen(acknowledgement) ? 0 : -1;
}

struct pending_image {
    int active;
    VkImage image;
    VkDeviceMemory memory;
    VkFence fence;
    VkCommandPool command_pool;
    VkCommandBuffer command_buffer;
};

static int
finish_pending_image(VkDevice device, VkQueue queue,
                     struct pending_image *pending)
{
    if (!pending->active) {
        return 0;
    }
    VkResult result = vkQueueWaitIdle(queue);
    printf("ahb_bridge_async_cleanup_status=%d\n", result);
    if (pending->command_buffer != VK_NULL_HANDLE) {
        vkFreeCommandBuffers(device, pending->command_pool, 1,
                              &pending->command_buffer);
    }
    if (pending->command_pool != VK_NULL_HANDLE) {
        vkDestroyCommandPool(device, pending->command_pool, NULL);
    }
    if (pending->fence != VK_NULL_HANDLE) {
        vkDestroyFence(device, pending->fence, NULL);
    }
    if (pending->image != VK_NULL_HANDLE) {
        vkDestroyImage(device, pending->image, NULL);
    }
    if (pending->memory != VK_NULL_HANDLE) {
        vkFreeMemory(device, pending->memory, NULL);
    }
    pending->active = 0;
    return result == VK_SUCCESS ? 0 : 1;
}

static int
render_android_hardware_image(VkPhysicalDevice physical_device, VkDevice device,
                               VkQueue queue, uint32_t queue_family,
                               int dma_buf_fd, int async_fence,
                               int *acquire_fence_fd,
                               struct pending_image *pending)
{
    const VkImageTiling tilings[] = {
        VK_IMAGE_TILING_OPTIMAL,
        VK_IMAGE_TILING_LINEAR,
    };
    const char *tiling_names[] = {
        "optimal",
        "linear",
    };
    int image_pass = 0;
    *acquire_fence_fd = -1;
    pending->active = 0;
    PFN_vkGetFenceFdKHR get_fence_fd =
        (PFN_vkGetFenceFdKHR)vkGetDeviceProcAddr(device, "vkGetFenceFdKHR");

    /* The Android driver does not expose a DRM modifier query; let Android's
     * readback decide which basic layout matches this shared allocation. */
    for (size_t tiling_index = 0;
         tiling_index < sizeof(tilings) / sizeof(tilings[0]); ++tiling_index) {
        image_pass = 0;
        VkExternalMemoryImageCreateInfo external_image_info = {
            .sType = VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO,
            .handleTypes = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT,
        };
        VkImageCreateInfo image_info = {
            .sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
            .pNext = &external_image_info,
            .imageType = VK_IMAGE_TYPE_2D,
            .format = VK_FORMAT_R8G8B8A8_UNORM,
            .extent = {64, 64, 1},
            .mipLevels = 1,
            .arrayLayers = 1,
            .samples = VK_SAMPLE_COUNT_1_BIT,
            .tiling = tilings[tiling_index],
            .usage = VK_IMAGE_USAGE_TRANSFER_DST_BIT |
                     VK_IMAGE_USAGE_SAMPLED_BIT |
                     VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
            .sharingMode = VK_SHARING_MODE_EXCLUSIVE,
            .initialLayout = VK_IMAGE_LAYOUT_UNDEFINED,
        };
        VkImage image = VK_NULL_HANDLE;
        VkResult result = vkCreateImage(device, &image_info, NULL, &image);
        printf("ahb_bridge_vkCreateImage_%s_status=%d\n",
               tiling_names[tiling_index], result);
        if (result != VK_SUCCESS) {
            continue;
        }

        VkMemoryRequirements memory_requirements;
        vkGetImageMemoryRequirements(device, image, &memory_requirements);
        int import_fd = dup(dma_buf_fd);
        printf("ahb_bridge_image_dup_%s_status=%d\n",
               tiling_names[tiling_index], import_fd >= 0 ? 0 : -1);
        if (import_fd < 0) {
            vkDestroyImage(device, image, NULL);
            continue;
        }
        VkImportMemoryFdInfoKHR import_info = {
            .sType = VK_STRUCTURE_TYPE_IMPORT_MEMORY_FD_INFO_KHR,
            .handleType = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT,
            .fd = import_fd,
        };
        VkMemoryAllocateInfo allocation_info = {
            .sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
            .pNext = &import_info,
            .allocationSize = memory_requirements.size,
            .memoryTypeIndex = find_memory_type(
                physical_device, memory_requirements.memoryTypeBits, 0),
        };
        VkDeviceMemory memory = VK_NULL_HANDLE;
        result = vkAllocateMemory(device, &allocation_info, NULL, &memory);
        import_fd = -1;
        printf("ahb_bridge_image_allocate_%s_status=%d\n",
               tiling_names[tiling_index], result);
        if (result != VK_SUCCESS) {
            vkDestroyImage(device, image, NULL);
            continue;
        }
        result = vkBindImageMemory(device, image, memory, 0);
        printf("ahb_bridge_image_bind_%s_status=%d\n",
               tiling_names[tiling_index], result);
        if (result != VK_SUCCESS) {
            vkDestroyImage(device, image, NULL);
            vkFreeMemory(device, memory, NULL);
            continue;
        }

        VkCommandPoolCreateInfo pool_info = {
            .sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
            .flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
            .queueFamilyIndex = queue_family,
        };
        VkCommandPool command_pool = VK_NULL_HANDLE;
        result = vkCreateCommandPool(device, &pool_info, NULL, &command_pool);
        printf("ahb_bridge_image_command_pool_status=%d\n", result);
        VkCommandBuffer command_buffer = VK_NULL_HANDLE;
        int is_final_tiling = tiling_index + 1 == sizeof(tilings) /
                                          sizeof(tilings[0]);
        if (result == VK_SUCCESS) {
            VkCommandBufferAllocateInfo command_info = {
                .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
                .commandPool = command_pool,
                .level = VK_COMMAND_BUFFER_LEVEL_PRIMARY,
                .commandBufferCount = 1,
            };
            result = vkAllocateCommandBuffers(device, &command_info,
                                              &command_buffer);
            printf("ahb_bridge_image_command_buffer_status=%d\n", result);
        }

        if (result == VK_SUCCESS) {
            VkCommandBufferBeginInfo begin_info = {
                .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
                .flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
            };
            result = vkBeginCommandBuffer(command_buffer, &begin_info);
            if (result == VK_SUCCESS) {
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
                    .srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
                    .dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
                    .image = image,
                    .subresourceRange = subresource_range,
                };
                vkCmdPipelineBarrier(command_buffer,
                                     VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
                                     VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, NULL,
                                     0, NULL, 1, &to_transfer);
                VkClearColorValue clear_color = {
                    .float32 = {64.0f / 255.0f, 128.0f / 255.0f,
                                192.0f / 255.0f, 1.0f},
                };
                vkCmdClearColorImage(command_buffer, image,
                                     VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                                     &clear_color, 1, &subresource_range);
                VkImageMemoryBarrier to_general = {
                    .sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
                    .srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT,
                    .dstAccessMask = 0,
                    .oldLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                    .newLayout = VK_IMAGE_LAYOUT_GENERAL,
                    .srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
                    .dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
                    .image = image,
                    .subresourceRange = subresource_range,
                };
                vkCmdPipelineBarrier(command_buffer,
                                     VK_PIPELINE_STAGE_TRANSFER_BIT,
                                     VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0,
                                     0, NULL, 0, NULL, 1, &to_general);
                result = vkEndCommandBuffer(command_buffer);
            }
        }

        VkFence fence = VK_NULL_HANDLE;
        if (result == VK_SUCCESS) {
            VkExportFenceCreateInfo export_fence_info = {
                .sType = VK_STRUCTURE_TYPE_EXPORT_FENCE_CREATE_INFO,
                .handleTypes = VK_EXTERNAL_FENCE_HANDLE_TYPE_SYNC_FD_BIT,
            };
            VkFenceCreateInfo fence_info = {
                .sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
                .pNext = get_fence_fd != NULL ? &export_fence_info : NULL,
            };
            result = vkCreateFence(device, &fence_info, NULL, &fence);
            if (result == VK_SUCCESS) {
                VkSubmitInfo submit_info = {
                    .sType = VK_STRUCTURE_TYPE_SUBMIT_INFO,
                    .commandBufferCount = 1,
                    .pCommandBuffers = &command_buffer,
                };
                result = vkQueueSubmit(queue, 1, &submit_info, fence);
                if (result == VK_SUCCESS && !(async_fence && is_final_tiling)) {
                    result = vkWaitForFences(device, 1, &fence, VK_TRUE,
                                             5000000000ull);
                } else if (result == VK_SUCCESS && async_fence &&
                           is_final_tiling) {
                    printf("ahb_bridge_image_fence_wait=skipped\n");
                }
            }
        }
        printf("ahb_bridge_image_gpu_%s_status=%d\n",
               tiling_names[tiling_index], result);
        image_pass = result == VK_SUCCESS;
        if (image_pass && is_final_tiling) {
            if (get_fence_fd != NULL) {
                VkFenceGetFdInfoKHR fence_fd_info = {
                    .sType = VK_STRUCTURE_TYPE_FENCE_GET_FD_INFO_KHR,
                    .fence = fence,
                    .handleType = VK_EXTERNAL_FENCE_HANDLE_TYPE_SYNC_FD_BIT,
                };
                VkResult fence_result = get_fence_fd(
                    device, &fence_fd_info, acquire_fence_fd);
                printf("ahb_bridge_image_fence_status=%d fd=%d\n",
                       fence_result, *acquire_fence_fd);
                if (fence_result != VK_SUCCESS) {
                    *acquire_fence_fd = -1;
                }
            } else {
                printf("ahb_bridge_image_fence_status=unavailable\n");
            }
        }

        if (async_fence && is_final_tiling && image_pass) {
            pending->active = 1;
            pending->image = image;
            pending->memory = memory;
            pending->fence = fence;
            pending->command_pool = command_pool;
            pending->command_buffer = command_buffer;
        } else {
            if (fence != VK_NULL_HANDLE) {
                vkDestroyFence(device, fence, NULL);
            }
            if (command_buffer != VK_NULL_HANDLE) {
                vkFreeCommandBuffers(device, command_pool, 1, &command_buffer);
            }
            if (command_pool != VK_NULL_HANDLE) {
                vkDestroyCommandPool(device, command_pool, NULL);
            }
            vkFreeMemory(device, memory, NULL);
            vkDestroyImage(device, image, NULL);
        }
        if (image_pass) {
            printf("ahb_bridge_linux_image_submit=pass tiling=%s\n",
                   tiling_names[tiling_index]);
        }
    }
    close(dma_buf_fd);
    if (!image_pass) {
        printf("ahb_bridge_linux_image_submit=fail\n");
    }
    return image_pass;
}

struct loop_image {
    VkImage image;
    VkDeviceMemory memory;
    VkCommandPool command_pool;
    VkCommandBuffer command_buffer;
    VkFence fence;
    VkImageLayout layout;
    int pending;
};

static void
destroy_loop_image(VkDevice device, struct loop_image *loop)
{
    if (loop->command_buffer != VK_NULL_HANDLE) {
        vkFreeCommandBuffers(device, loop->command_pool, 1,
                              &loop->command_buffer);
    }
    if (loop->fence != VK_NULL_HANDLE) {
        vkDestroyFence(device, loop->fence, NULL);
    }
    if (loop->command_pool != VK_NULL_HANDLE) {
        vkDestroyCommandPool(device, loop->command_pool, NULL);
    }
    if (loop->image != VK_NULL_HANDLE) {
        vkDestroyImage(device, loop->image, NULL);
    }
    if (loop->memory != VK_NULL_HANDLE) {
        vkFreeMemory(device, loop->memory, NULL);
    }
    memset(loop, 0, sizeof(*loop));
}

static void
recycle_loop_image(VkDevice device, struct loop_image *loop)
{
    if (!loop->pending) {
        return;
    }
    if (loop->command_buffer != VK_NULL_HANDLE) {
        vkFreeCommandBuffers(device, loop->command_pool, 1,
                              &loop->command_buffer);
        loop->command_buffer = VK_NULL_HANDLE;
    }
    if (loop->fence != VK_NULL_HANDLE) {
        vkDestroyFence(device, loop->fence, NULL);
        loop->fence = VK_NULL_HANDLE;
    }
    loop->pending = 0;
    printf("ahb_double_buffer_recycle=pass\n");
}

static int
initialize_loop_image(VkPhysicalDevice physical_device, VkDevice device,
                      int *file_descriptors, int descriptor_count,
                      int buffer_index, struct loop_image *loop)
{
    if (descriptor_count <= 0) {
        return -1;
    }
    int image_fd = dup(file_descriptors[0]);
    printf("ahb_double_buffer_image_fd_dup_%d_status=%d\n", buffer_index,
           image_fd >= 0 ? 0 : -1);
    if (image_fd < 0) {
        return -1;
    }

    VkExternalMemoryBufferCreateInfo buffer_external_info = {
        .sType = VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_BUFFER_CREATE_INFO,
        .handleTypes = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT,
    };
    VkBufferCreateInfo buffer_info = {
        .sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        .pNext = &buffer_external_info,
        .size = 64 * 64 * 4,
        .usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT |
                 VK_BUFFER_USAGE_TRANSFER_DST_BIT,
        .sharingMode = VK_SHARING_MODE_EXCLUSIVE,
    };
    VkBuffer buffer = VK_NULL_HANDLE;
    VkResult result = vkCreateBuffer(device, &buffer_info, NULL, &buffer);
    printf("ahb_double_buffer_vkCreateBuffer_%d_status=%d\n", buffer_index,
           result);
    if (result != VK_SUCCESS) {
        close(image_fd);
        return -1;
    }
    VkMemoryRequirements buffer_requirements;
    vkGetBufferMemoryRequirements(device, buffer, &buffer_requirements);
    VkImportMemoryFdInfoKHR buffer_import = {
        .sType = VK_STRUCTURE_TYPE_IMPORT_MEMORY_FD_INFO_KHR,
        .handleType = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT,
        .fd = file_descriptors[0],
    };
    VkMemoryAllocateInfo buffer_allocation = {
        .sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .pNext = &buffer_import,
        .allocationSize = buffer_requirements.size,
        .memoryTypeIndex = find_memory_type(
            physical_device, buffer_requirements.memoryTypeBits, 0),
    };
    VkDeviceMemory buffer_memory = VK_NULL_HANDLE;
    result = vkAllocateMemory(device, &buffer_allocation, NULL,
                               &buffer_memory);
    printf("ahb_double_buffer_allocate_marker_%d_status=%d\n", buffer_index,
           result);
    if (result != VK_SUCCESS) {
        close(image_fd);
        vkDestroyBuffer(device, buffer, NULL);
        return -1;
    }
    file_descriptors[0] = -1;
    result = vkBindBufferMemory(device, buffer, buffer_memory, 0);
    if (result == VK_SUCCESS) {
        uint32_t *mapped = NULL;
        result = vkMapMemory(device, buffer_memory, 0, sizeof(*mapped), 0,
                             (void **)&mapped);
        if (result == VK_SUCCESS && mapped != NULL) {
            printf("ahb_double_buffer_marker_%d=0x%08x\n", buffer_index,
                   *mapped);
            result = *mapped == 0x4e4f5641u + (uint32_t)buffer_index
                         ? VK_SUCCESS
                         : VK_ERROR_INITIALIZATION_FAILED;
            vkUnmapMemory(device, buffer_memory);
        } else if (result == VK_SUCCESS) {
            result = VK_ERROR_MEMORY_MAP_FAILED;
        }
    }
    vkFreeMemory(device, buffer_memory, NULL);
    vkDestroyBuffer(device, buffer, NULL);
    printf("ahb_double_buffer_marker_check_%d=%s\n", buffer_index,
           result == VK_SUCCESS ? "pass" : "fail");
    if (result != VK_SUCCESS) {
        close(image_fd);
        return -1;
    }

    VkExternalMemoryImageCreateInfo image_external_info = {
        .sType = VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_IMAGE_CREATE_INFO,
        .handleTypes = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT,
    };
    VkImageCreateInfo image_info = {
        .sType = VK_STRUCTURE_TYPE_IMAGE_CREATE_INFO,
        .pNext = &image_external_info,
        .imageType = VK_IMAGE_TYPE_2D,
        .format = VK_FORMAT_R8G8B8A8_UNORM,
        .extent = {64, 64, 1},
        .mipLevels = 1,
        .arrayLayers = 1,
        .samples = VK_SAMPLE_COUNT_1_BIT,
        .tiling = VK_IMAGE_TILING_LINEAR,
        .usage = VK_IMAGE_USAGE_TRANSFER_DST_BIT |
                 VK_IMAGE_USAGE_SAMPLED_BIT |
                 VK_IMAGE_USAGE_COLOR_ATTACHMENT_BIT,
        .sharingMode = VK_SHARING_MODE_EXCLUSIVE,
        .initialLayout = VK_IMAGE_LAYOUT_UNDEFINED,
    };
    result = vkCreateImage(device, &image_info, NULL, &loop->image);
    printf("ahb_double_buffer_vkCreateImage_%d_status=%d\n", buffer_index,
           result);
    if (result != VK_SUCCESS) {
        close(image_fd);
        return -1;
    }
    VkMemoryRequirements image_requirements;
    vkGetImageMemoryRequirements(device, loop->image, &image_requirements);
    VkImportMemoryFdInfoKHR image_import = {
        .sType = VK_STRUCTURE_TYPE_IMPORT_MEMORY_FD_INFO_KHR,
        .handleType = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT,
        .fd = image_fd,
    };
    VkMemoryAllocateInfo image_allocation = {
        .sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
        .pNext = &image_import,
        .allocationSize = image_requirements.size,
        .memoryTypeIndex = find_memory_type(
            physical_device, image_requirements.memoryTypeBits, 0),
    };
    result = vkAllocateMemory(device, &image_allocation, NULL, &loop->memory);
    printf("ahb_double_buffer_image_allocate_%d_status=%d\n", buffer_index,
           result);
    if (result != VK_SUCCESS) {
        close(image_fd);
        destroy_loop_image(device, loop);
        return -1;
    }
    image_fd = -1;
    result = vkBindImageMemory(device, loop->image, loop->memory, 0);
    printf("ahb_double_buffer_image_bind_%d_status=%d\n", buffer_index,
           result);
    if (result != VK_SUCCESS) {
        destroy_loop_image(device, loop);
        return -1;
    }

    loop->layout = VK_IMAGE_LAYOUT_UNDEFINED;
    return 0;
}

static int
create_loop_image_command_pool(VkDevice device, uint32_t queue_family,
                               struct loop_image *loop)
{
    VkCommandPoolCreateInfo pool_info = {
        .sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
        .flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
        .queueFamilyIndex = queue_family,
    };
    VkResult result = vkCreateCommandPool(device, &pool_info, NULL,
                                          &loop->command_pool);
    return result == VK_SUCCESS ? 0 : -1;
}

static int
submit_loop_image(VkPhysicalDevice physical_device, VkDevice device,
                  VkQueue queue, PFN_vkGetFenceFdKHR get_fence_fd,
                  struct loop_image *loop, int frame, int *acquire_fence_fd)
{
    (void)physical_device;
    *acquire_fence_fd = -1;
    if (loop->pending || loop->command_pool == VK_NULL_HANDLE) {
        return -1;
    }
    VkCommandBufferAllocateInfo command_info = {
        .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
        .commandPool = loop->command_pool,
        .level = VK_COMMAND_BUFFER_LEVEL_PRIMARY,
        .commandBufferCount = 1,
    };
    VkCommandBuffer command_buffer = VK_NULL_HANDLE;
    VkResult result = vkAllocateCommandBuffers(device, &command_info,
                                                &command_buffer);
    if (result == VK_SUCCESS) {
        VkCommandBufferBeginInfo begin_info = {
            .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
            .flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
        };
        result = vkBeginCommandBuffer(command_buffer, &begin_info);
        VkImageSubresourceRange range = {
            .aspectMask = VK_IMAGE_ASPECT_COLOR_BIT,
            .baseMipLevel = 0,
            .levelCount = 1,
            .baseArrayLayer = 0,
            .layerCount = 1,
        };
        if (result == VK_SUCCESS) {
            VkImageMemoryBarrier to_transfer = {
                .sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
                .srcAccessMask = 0,
                .dstAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT,
                .oldLayout = loop->layout,
                .newLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                .srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
                .dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
                .image = loop->image,
                .subresourceRange = range,
            };
            vkCmdPipelineBarrier(command_buffer,
                                 VK_PIPELINE_STAGE_TOP_OF_PIPE_BIT,
                                 VK_PIPELINE_STAGE_TRANSFER_BIT, 0, 0, NULL,
                                 0, NULL, 1, &to_transfer);
            VkClearColorValue clear_color = {
                .float32 = {
                    frame & 1 ? 32.0f / 255.0f : 64.0f / 255.0f,
                    frame & 1 ? 160.0f / 255.0f : 128.0f / 255.0f,
                    frame & 1 ? 224.0f / 255.0f : 192.0f / 255.0f,
                    1.0f,
                },
            };
            vkCmdClearColorImage(command_buffer, loop->image,
                                 VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                                 &clear_color, 1, &range);
            VkImageMemoryBarrier to_general = {
                .sType = VK_STRUCTURE_TYPE_IMAGE_MEMORY_BARRIER,
                .srcAccessMask = VK_ACCESS_TRANSFER_WRITE_BIT,
                .dstAccessMask = 0,
                .oldLayout = VK_IMAGE_LAYOUT_TRANSFER_DST_OPTIMAL,
                .newLayout = VK_IMAGE_LAYOUT_GENERAL,
                .srcQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
                .dstQueueFamilyIndex = VK_QUEUE_FAMILY_IGNORED,
                .image = loop->image,
                .subresourceRange = range,
            };
            vkCmdPipelineBarrier(command_buffer,
                                 VK_PIPELINE_STAGE_TRANSFER_BIT,
                                 VK_PIPELINE_STAGE_BOTTOM_OF_PIPE_BIT, 0,
                                 0, NULL, 0, NULL, 1, &to_general);
            result = vkEndCommandBuffer(command_buffer);
        }
    }
    VkFence fence = VK_NULL_HANDLE;
    if (result == VK_SUCCESS) {
        VkExportFenceCreateInfo export_fence_info = {
            .sType = VK_STRUCTURE_TYPE_EXPORT_FENCE_CREATE_INFO,
            .handleTypes = VK_EXTERNAL_FENCE_HANDLE_TYPE_SYNC_FD_BIT,
        };
        VkFenceCreateInfo fence_info = {
            .sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
            .pNext = get_fence_fd != NULL ? &export_fence_info : NULL,
        };
        result = vkCreateFence(device, &fence_info, NULL, &fence);
        if (result == VK_SUCCESS) {
            VkSubmitInfo submit_info = {
                .sType = VK_STRUCTURE_TYPE_SUBMIT_INFO,
                .commandBufferCount = 1,
                .pCommandBuffers = &command_buffer,
            };
            result = vkQueueSubmit(queue, 1, &submit_info, fence);
        }
    }
    if (result == VK_SUCCESS && get_fence_fd != NULL) {
        VkFenceGetFdInfoKHR fence_fd_info = {
            .sType = VK_STRUCTURE_TYPE_FENCE_GET_FD_INFO_KHR,
            .fence = fence,
            .handleType = VK_EXTERNAL_FENCE_HANDLE_TYPE_SYNC_FD_BIT,
        };
        result = get_fence_fd(device, &fence_fd_info, acquire_fence_fd);
        printf("ahb_double_buffer_frame_fence=%d fd=%d\n", result,
               *acquire_fence_fd);
    }
    if (result != VK_SUCCESS || *acquire_fence_fd < 0) {
        if (*acquire_fence_fd >= 0) {
            close(*acquire_fence_fd);
            *acquire_fence_fd = -1;
        }
        if (fence != VK_NULL_HANDLE) {
            vkWaitForFences(device, 1, &fence, VK_TRUE, 5000000000ull);
            vkDestroyFence(device, fence, NULL);
        }
        if (command_buffer != VK_NULL_HANDLE) {
            vkFreeCommandBuffers(device, loop->command_pool, 1,
                                  &command_buffer);
        }
        return -1;
    }
    loop->command_buffer = command_buffer;
    loop->fence = fence;
    loop->pending = 1;
    loop->layout = VK_IMAGE_LAYOUT_GENERAL;
    printf("ahb_double_buffer_frame_submit=%d\n", frame);
    return 0;
}

static int
receive_release_fence(int connection_fd, int expected_buffer)
{
    char message_text[128] = {0};
    char control[CMSG_SPACE(sizeof(int) * 2)] = {0};
    struct iovec vector = {
        .iov_base = message_text,
        .iov_len = sizeof(message_text) - 1,
    };
    struct msghdr message = {
        .msg_iov = &vector,
        .msg_iovlen = 1,
        .msg_control = control,
        .msg_controllen = sizeof(control),
    };
    ssize_t bytes = recvmsg(connection_fd, &message, 0);
    int release_fence_fd = -1;
    if (bytes > 0) {
        message_text[bytes < (ssize_t)sizeof(message_text)
                         ? bytes
                         : sizeof(message_text) - 1] = '\0';
    }
    for (struct cmsghdr *header = CMSG_FIRSTHDR(&message); header != NULL;
         header = CMSG_NXTHDR(&message, header)) {
        if (header->cmsg_level != SOL_SOCKET ||
            header->cmsg_type != SCM_RIGHTS) {
            continue;
        }
        size_t byte_count = header->cmsg_len - CMSG_LEN(0);
        size_t descriptor_count = byte_count / sizeof(int);
        int *descriptors = (int *)CMSG_DATA(header);
        for (size_t index = 0; index < descriptor_count; ++index) {
            if (release_fence_fd < 0) {
                release_fence_fd = descriptors[index];
            } else {
                close(descriptors[index]);
            }
        }
    }
    char expected_message[32];
    snprintf(expected_message, sizeof(expected_message), "release_buffer=%d",
             expected_buffer);
    int expected = bytes > 0 && release_fence_fd >= 0 &&
                   strstr(message_text, expected_message) != NULL;
    printf("ahb_double_buffer_release_message buffer=%d bytes=%zd fd=%s\n",
           expected_buffer, bytes,
           release_fence_fd >= 0 ? "received" : "missing");
    if (!expected) {
        if (release_fence_fd >= 0) {
            close(release_fence_fd);
        }
        return -1;
    }
    struct pollfd fence_poll = {
        .fd = release_fence_fd,
        .events = POLLIN,
    };
    int poll_status;
    do {
        poll_status = poll(&fence_poll, 1, 5000);
    } while (poll_status < 0 && errno == EINTR);
    close(release_fence_fd);
    printf("ahb_double_buffer_release_wait buffer=%d status=%d\n",
           expected_buffer, poll_status);
    return poll_status > 0 && (fence_poll.revents & POLLNVAL) == 0 ? 0 : -1;
}

static int
send_loop_frame(VkPhysicalDevice physical_device, VkDevice device, VkQueue queue,
                PFN_vkGetFenceFdKHR get_fence_fd, int connection_fd,
                struct loop_image *loop, int frame)
{
    int acquire_fence_fd = -1;
    if (submit_loop_image(physical_device, device, queue, get_fence_fd, loop,
                          frame, &acquire_fence_fd) != 0) {
        return -1;
    }
    const char *acknowledgement =
        "linux_import=pass linux_gpu_write=pass linux_image_write=pass linux_acquire_fence=pass linux_loop=pass\n";
    int status = send_acknowledgement(connection_fd, acknowledgement,
                                       acquire_fence_fd);
    printf("ahb_double_buffer_ack_status=%d frame=%d\n", status, frame);
    return status;
}

static int
probe_android_hardware_buffer_loop(VkPhysicalDevice physical_device,
                                   VkDevice device, VkQueue queue,
                                   uint32_t queue_family,
                                   const char *socket_path)
{
    printf("ahb_double_buffer.begin\n");
    struct loop_image images[2] = {0};
    int connections[2] = {-1, -1};
    int success = 0;
    char socket_paths[2][sizeof(((struct sockaddr_un *)0)->sun_path)] = {{0}};
    PFN_vkGetFenceFdKHR get_fence_fd =
        (PFN_vkGetFenceFdKHR)vkGetDeviceProcAddr(device, "vkGetFenceFdKHR");
    if (get_fence_fd == NULL) {
        printf("ahb_double_buffer_fence_export=missing\n");
        goto done;
    }

    for (int index = 0; index < 2; ++index) {
        int path_length = snprintf(socket_paths[index],
                                   sizeof(socket_paths[index]), "%s.%d",
                                   socket_path, index);
        if (path_length < 0 || (size_t)path_length >= sizeof(socket_paths[index])) {
            printf("ahb_double_buffer_socket_path=too_long\n");
            goto done;
        }
        int file_descriptors[16] = {-1};
        int descriptor_count = receive_dma_buf_fds(
            socket_paths[index], file_descriptors,
            sizeof(file_descriptors) / sizeof(file_descriptors[0]),
            &connections[index]);
        printf("ahb_double_buffer_recv_%d fd_count=%d\n", index,
               descriptor_count);
        if (descriptor_count <= 0 ||
            initialize_loop_image(physical_device, device, file_descriptors,
                                  descriptor_count, index, &images[index]) != 0 ||
            create_loop_image_command_pool(device, queue_family,
                                           &images[index]) != 0) {
            for (int fd_index = 0; fd_index < descriptor_count; ++fd_index) {
                if (file_descriptors[fd_index] >= 0) {
                    close(file_descriptors[fd_index]);
                }
            }
            goto done;
        }
        for (int fd_index = 0; fd_index < descriptor_count; ++fd_index) {
            if (file_descriptors[fd_index] >= 0) {
                close(file_descriptors[fd_index]);
            }
        }
    }

    if (send_loop_frame(physical_device, device, queue, get_fence_fd,
                        connections[0], &images[0], 0) != 0 ||
        send_loop_frame(physical_device, device, queue, get_fence_fd,
                        connections[1], &images[1], 1) != 0) {
        goto done;
    }
    for (int frame = 2; frame < 5; ++frame) {
        int index = frame & 1;
        if (receive_release_fence(connections[index], index) != 0) {
            goto done;
        }
        recycle_loop_image(device, &images[index]);
        if (send_loop_frame(physical_device, device, queue, get_fence_fd,
                            connections[index], &images[index], frame) != 0) {
            goto done;
        }
    }
    /* Frame four replaces buffer one, so its completion carries the final
     * release fence needed to prove both buffers can be recycled. */
    if (receive_release_fence(connections[1], 1) != 0) {
        goto done;
    }
    recycle_loop_image(device, &images[1]);
    if (vkQueueWaitIdle(queue) != VK_SUCCESS) {
        goto done;
    }
    success = 1;

done:
    if (vkQueueWaitIdle(queue) != VK_SUCCESS) {
        success = 0;
    }
    for (int index = 0; index < 2; ++index) {
        if (connections[index] >= 0) {
            close(connections[index]);
        }
        destroy_loop_image(device, &images[index]);
        unlink(socket_paths[index]);
    }
    printf("ahb_double_buffer=%s\n", success ? "pass" : "fail");
    return success ? 0 : 1;
}

static int
probe_android_hardware_buffer(VkPhysicalDevice physical_device, VkDevice device,
                              VkQueue queue, uint32_t queue_family,
                              const char *socket_path, int async_fence)
{
    printf("ahb_bridge.begin\n");
    int file_descriptors[16] = {-1};
    int connection_fd = -1;
    int descriptor_count = receive_dma_buf_fds(
        socket_path, file_descriptors,
        sizeof(file_descriptors) / sizeof(file_descriptors[0]), &connection_fd);
    if (descriptor_count <= 0) {
        fprintf(stderr, "AHB bridge did not receive any DMA-BUF FDs\n");
        if (connection_fd >= 0) {
            close(connection_fd);
        }
        return 1;
    }

    const VkDeviceSize buffer_size = 64 * 64 * 4;
    VkExternalMemoryBufferCreateInfo external_buffer_info = {
        .sType = VK_STRUCTURE_TYPE_EXTERNAL_MEMORY_BUFFER_CREATE_INFO,
        .handleTypes = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT,
    };
    VkBufferCreateInfo buffer_info = {
        .sType = VK_STRUCTURE_TYPE_BUFFER_CREATE_INFO,
        .pNext = &external_buffer_info,
        .size = buffer_size,
        .usage = VK_BUFFER_USAGE_TRANSFER_SRC_BIT | VK_BUFFER_USAGE_TRANSFER_DST_BIT,
        .sharingMode = VK_SHARING_MODE_EXCLUSIVE,
    };
    VkBuffer buffer = VK_NULL_HANDLE;
    VkResult result = vkCreateBuffer(device, &buffer_info, NULL, &buffer);
    printf("ahb_bridge_vkCreateBuffer_status=%d\n", result);
    if (result != VK_SUCCESS) {
        goto fail;
    }

    VkMemoryRequirements memory_requirements;
    vkGetBufferMemoryRequirements(device, buffer, &memory_requirements);
    uint32_t memory_type_index = find_memory_type(
        physical_device, memory_requirements.memoryTypeBits,
        VK_MEMORY_PROPERTY_HOST_VISIBLE_BIT | VK_MEMORY_PROPERTY_HOST_COHERENT_BIT);
    int pass = 0;
    int linux_gpu_pass = 0;
    int android_image_fd = -1;
    for (int index = 0; index < descriptor_count; ++index) {
        int image_candidate_fd = dup(file_descriptors[index]);
        printf("ahb_bridge_image_fd_dup_%d_status=%d\n", index,
               image_candidate_fd >= 0 ? 0 : -1);
        VkImportMemoryFdInfoKHR import_info = {
            .sType = VK_STRUCTURE_TYPE_IMPORT_MEMORY_FD_INFO_KHR,
            .handleType = VK_EXTERNAL_MEMORY_HANDLE_TYPE_DMA_BUF_BIT_EXT,
            .fd = file_descriptors[index],
        };
        VkMemoryAllocateInfo allocation_info = {
            .sType = VK_STRUCTURE_TYPE_MEMORY_ALLOCATE_INFO,
            .pNext = &import_info,
            .allocationSize = memory_requirements.size,
            .memoryTypeIndex = memory_type_index,
        };
        VkDeviceMemory memory = VK_NULL_HANDLE;
        result = vkAllocateMemory(device, &allocation_info, NULL, &memory);
        printf("ahb_bridge_fd_%d_allocate_status=%d\n", index, result);
        if (result == VK_SUCCESS) {
            file_descriptors[index] = -1;
            result = vkBindBufferMemory(device, buffer, memory, 0);
            printf("ahb_bridge_fd_%d_bind_status=%d\n", index, result);
            if (result == VK_SUCCESS) {
                uint32_t *mapped = NULL;
                result = vkMapMemory(device, memory, 0, sizeof(*mapped), 0,
                                     (void **)&mapped);
                printf("ahb_bridge_fd_%d_map_status=%d\n", index, result);
                if (result == VK_SUCCESS && mapped != NULL) {
                    printf("ahb_bridge_fd_%d_value=0x%08x\n", index, *mapped);
                    if (*mapped == 0x4e4f5641u) {
                        pass = 1;
                        android_image_fd = image_candidate_fd;
                        image_candidate_fd = -1;
                        vkUnmapMemory(device, memory);

                        VkCommandPoolCreateInfo bridge_pool_info = {
                            .sType = VK_STRUCTURE_TYPE_COMMAND_POOL_CREATE_INFO,
                            .flags = VK_COMMAND_POOL_CREATE_RESET_COMMAND_BUFFER_BIT,
                            .queueFamilyIndex = queue_family,
                        };
                        VkCommandPool bridge_pool = VK_NULL_HANDLE;
                        VkResult bridge_result = vkCreateCommandPool(
                            device, &bridge_pool_info, NULL, &bridge_pool);
                        printf("ahb_bridge_vkCreateCommandPool_status=%d\n",
                               bridge_result);
                        if (bridge_result == VK_SUCCESS) {
                            VkCommandBufferAllocateInfo bridge_command_info = {
                                .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_ALLOCATE_INFO,
                                .commandPool = bridge_pool,
                                .level = VK_COMMAND_BUFFER_LEVEL_PRIMARY,
                                .commandBufferCount = 1,
                            };
                            VkCommandBuffer bridge_command_buffer =
                                VK_NULL_HANDLE;
                            bridge_result = vkAllocateCommandBuffers(
                                device, &bridge_command_info,
                                &bridge_command_buffer);
                            printf("ahb_bridge_vkAllocateCommandBuffer_status=%d\n",
                                   bridge_result);
                            if (bridge_result == VK_SUCCESS) {
                                VkCommandBufferBeginInfo bridge_begin_info = {
                                    .sType = VK_STRUCTURE_TYPE_COMMAND_BUFFER_BEGIN_INFO,
                                    .flags = VK_COMMAND_BUFFER_USAGE_ONE_TIME_SUBMIT_BIT,
                                };
                                bridge_result = vkBeginCommandBuffer(
                                    bridge_command_buffer, &bridge_begin_info);
                                if (bridge_result == VK_SUCCESS) {
                                    vkCmdFillBuffer(bridge_command_buffer, buffer,
                                                    0, buffer_size, 0xb16b00b5u);
                                    bridge_result = vkEndCommandBuffer(
                                        bridge_command_buffer);
                                }
                                VkFence bridge_fence = VK_NULL_HANDLE;
                                if (bridge_result == VK_SUCCESS) {
                                    VkFenceCreateInfo bridge_fence_info = {
                                        .sType = VK_STRUCTURE_TYPE_FENCE_CREATE_INFO,
                                    };
                                    bridge_result = vkCreateFence(
                                        device, &bridge_fence_info, NULL,
                                        &bridge_fence);
                                    if (bridge_result == VK_SUCCESS) {
                                        VkSubmitInfo bridge_submit_info = {
                                            .sType = VK_STRUCTURE_TYPE_SUBMIT_INFO,
                                            .commandBufferCount = 1,
                                            .pCommandBuffers =
                                                &bridge_command_buffer,
                                        };
                                        bridge_result = vkQueueSubmit(
                                            queue, 1, &bridge_submit_info,
                                            bridge_fence);
                                        if (bridge_result == VK_SUCCESS) {
                                            bridge_result = vkWaitForFences(
                                                device, 1, &bridge_fence, VK_TRUE,
                                                5000000000ull);
                                        }
                                    }
                                }
                                printf("ahb_bridge_linux_gpu_status=%d\n",
                                       bridge_result);
                                if (bridge_result == VK_SUCCESS) {
                                    uint32_t *gpu_mapped = NULL;
                                    bridge_result = vkMapMemory(
                                        device, memory, 0, sizeof(*gpu_mapped), 0,
                                        (void **)&gpu_mapped);
                                    if (bridge_result == VK_SUCCESS &&
                                        gpu_mapped != NULL) {
                                        printf("ahb_bridge_linux_gpu_value=0x%08x\n",
                                               *gpu_mapped);
                                        linux_gpu_pass =
                                            *gpu_mapped == 0xb16b00b5u;
                                        vkUnmapMemory(device, memory);
                                    }
                                }
                                if (bridge_fence != VK_NULL_HANDLE) {
                                    vkDestroyFence(device, bridge_fence, NULL);
                                }
                                vkFreeCommandBuffers(device, bridge_pool, 1,
                                                      &bridge_command_buffer);
                            }
                            vkDestroyCommandPool(device, bridge_pool, NULL);
                        }
                    } else {
                        vkUnmapMemory(device, memory);
                    }
                }
            }
            vkFreeMemory(device, memory, NULL);
        }
        if (image_candidate_fd >= 0) {
            close(image_candidate_fd);
        }
        if (file_descriptors[index] >= 0) {
            close(file_descriptors[index]);
            file_descriptors[index] = -1;
        }
        if (pass && linux_gpu_pass) {
            for (int remaining = index + 1; remaining < descriptor_count;
                 ++remaining) {
                close(file_descriptors[remaining]);
                file_descriptors[remaining] = -1;
            }
            break;
        }
    }
    vkDestroyBuffer(device, buffer, NULL);
    int linux_image_pass = 0;
    int linux_acquire_fence_fd = -1;
    struct pending_image pending = {0};
    if (pass && linux_gpu_pass && android_image_fd >= 0) {
        linux_image_pass = render_android_hardware_image(
            physical_device, device, queue, queue_family, android_image_fd,
            async_fence, &linux_acquire_fence_fd, &pending);
        android_image_fd = -1;
    }
    if (android_image_fd >= 0) {
        close(android_image_fd);
    }
    int bridge_pass = pass && linux_gpu_pass && linux_image_pass &&
                      linux_acquire_fence_fd >= 0;
    {
        const char *acknowledgement =
            bridge_pass
                ? async_fence
                      ? "linux_import=pass linux_gpu_write=pass linux_image_write=pass linux_acquire_fence=pass linux_async_fence=pass\n"
                      : "linux_import=pass linux_gpu_write=pass linux_image_write=pass linux_acquire_fence=pass\n"
                : pass && linux_gpu_pass
                      ? "linux_import=pass linux_gpu_write=pass linux_image_write=fail linux_acquire_fence=fail\n"
                      : "linux_import=fail linux_gpu_write=fail linux_image_write=fail linux_acquire_fence=fail\n";
        int acknowledgement_status = send_acknowledgement(
            connection_fd, acknowledgement, linux_acquire_fence_fd);
        printf("ahb_bridge_ack_status=%d\n", acknowledgement_status);
        linux_acquire_fence_fd = -1;
        if (acknowledgement_status != 0) {
            bridge_pass = 0;
        }
    }
    if (pending.active) {
        int async_cleanup_status = finish_pending_image(device, queue, &pending);
        if (async_cleanup_status != 0) {
            bridge_pass = 0;
        }
    }
    close(connection_fd);
    printf("ahb_bridge=%s\n", bridge_pass ? "pass" : "fail");
    return bridge_pass ? 0 : 1;

fail:
    if (buffer != VK_NULL_HANDLE) {
        vkDestroyBuffer(device, buffer, NULL);
    }
    for (int index = 0; index < descriptor_count; ++index) {
        if (file_descriptors[index] >= 0) {
            close(file_descriptors[index]);
        }
    }
    if (connection_fd >= 0) {
        send_acknowledgement(connection_fd, "linux_import=fail\n", -1);
        close(connection_fd);
    }
    return 1;
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
    const char *external_fence_extensions[] = {
        VK_KHR_EXTERNAL_FENCE_EXTENSION_NAME,
        VK_KHR_EXTERNAL_FENCE_FD_EXTENSION_NAME,
    };
    for (uint32_t index = 0;
         index < sizeof(external_fence_extensions) /
                     sizeof(external_fence_extensions[0]);
         ++index) {
        printf("extension.%s=%s\n", external_fence_extensions[index],
               has_device_extension(physical_device,
                                    external_fence_extensions[index])
                   ? "present"
                   : "missing");
    }
    int external_fence_enabled =
        has_device_extension(physical_device,
                             VK_KHR_EXTERNAL_FENCE_EXTENSION_NAME) &&
        has_device_extension(physical_device,
                             VK_KHR_EXTERNAL_FENCE_FD_EXTENSION_NAME);

    float priority = 1.0f;
    VkDeviceQueueCreateInfo queue_info = {
        .sType = VK_STRUCTURE_TYPE_DEVICE_QUEUE_CREATE_INFO,
        .queueFamilyIndex = queue_family,
        .queueCount = 1,
        .pQueuePriorities = &priority,
    };
    const char *device_extensions[5] = {
        external_memory_extensions[0],
        external_memory_extensions[1],
        external_memory_extensions[2],
    };
    uint32_t device_extension_count =
        sizeof(external_memory_extensions) /
        sizeof(external_memory_extensions[0]);
    if (external_fence_enabled) {
        device_extensions[device_extension_count++] =
            VK_KHR_EXTERNAL_FENCE_EXTENSION_NAME;
        device_extensions[device_extension_count++] =
            VK_KHR_EXTERNAL_FENCE_FD_EXTENSION_NAME;
    }
    VkDeviceCreateInfo device_info = {
        .sType = VK_STRUCTURE_TYPE_DEVICE_CREATE_INFO,
        .queueCreateInfoCount = 1,
        .pQueueCreateInfos = &queue_info,
        .enabledExtensionCount = device_extension_count,
        .ppEnabledExtensionNames = device_extensions,
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

    const char *android_hardware_buffer_socket =
        getenv("NOVA_AHB_HANDLE_SOCKET");
    if (android_hardware_buffer_socket != NULL &&
        android_hardware_buffer_socket[0] != '\0') {
        const char *double_buffer_value = getenv("NOVA_AHB_DOUBLE_BUFFER");
        int double_buffer = double_buffer_value != NULL &&
                            strcmp(double_buffer_value, "1") == 0;
        if (double_buffer) {
            int loop_status = probe_android_hardware_buffer_loop(
                physical_device, device, queue, queue_family,
                android_hardware_buffer_socket);
            printf("ahb_double_buffer_status=%d\n", loop_status);
            if (loop_status != 0) {
                return 1;
            }
            goto vulkan_probe_cleanup;
        }
        const char *async_fence_value = getenv("NOVA_AHB_ASYNC_FENCE");
        int async_fence = async_fence_value != NULL &&
                          strcmp(async_fence_value, "1") == 0;
        int bridge_status = probe_android_hardware_buffer(
            physical_device, device, queue, queue_family,
            android_hardware_buffer_socket, async_fence);
        printf("ahb_bridge_status=%d\n", bridge_status);
        if (bridge_status != 0) {
            return 1;
        }
    }

vulkan_probe_cleanup:
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
