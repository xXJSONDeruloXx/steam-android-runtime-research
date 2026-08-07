#define _POSIX_C_SOURCE 200809L

#include <android/hardware_buffer.h>
#include <android/native_window_jni.h>
#include <android/rect.h>

#include <jni.h>

#include <poll.h>
#include <pthread.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/un.h>
#include <sys/uio.h>
#include <time.h>
#include <unistd.h>

/* surface_control.h exposes its ARect parameters as C++ references even when
 * included from C. Declare the API's C ABI here so the NDK C build can use the
 * API-29 surface transaction path without compiling this file as C++. */
typedef struct ASurfaceControl ASurfaceControl;
typedef struct ASurfaceTransaction ASurfaceTransaction;
typedef struct ASurfaceTransactionStats ASurfaceTransactionStats;
typedef void (*ASurfaceTransaction_OnComplete)(
    void *context, ASurfaceTransactionStats *stats);

extern ASurfaceControl *ASurfaceControl_createFromWindow(
    ANativeWindow *window, const char *debug_name);
extern void ASurfaceControl_release(ASurfaceControl *surface_control);
extern ASurfaceTransaction *ASurfaceTransaction_create(void);
extern void ASurfaceTransaction_delete(ASurfaceTransaction *transaction);
extern void ASurfaceTransaction_setBuffer(ASurfaceTransaction *transaction,
                                          ASurfaceControl *surface_control,
                                          AHardwareBuffer *buffer,
                                          int acquire_fence_fd);
extern void ASurfaceTransaction_setGeometry(ASurfaceTransaction *transaction,
                                            ASurfaceControl *surface_control,
                                            const ARect *source,
                                            const ARect *destination,
                                            int32_t transform);
extern void ASurfaceTransaction_setOnComplete(
    ASurfaceTransaction *transaction, void *context,
    ASurfaceTransaction_OnComplete callback);
extern void ASurfaceTransaction_apply(ASurfaceTransaction *transaction);
extern int ASurfaceTransactionStats_getPresentFenceFd(
    ASurfaceTransactionStats *stats);
extern int ASurfaceTransactionStats_getPreviousReleaseFenceFd(
    ASurfaceTransactionStats *stats, ASurfaceControl *surface_control);
extern int64_t ASurfaceTransactionStats_getLatchTime(
    ASurfaceTransactionStats *stats);

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

struct surface_completion {
    pthread_mutex_t mutex;
    pthread_cond_t condition;
    ASurfaceControl *surface_control;
    int complete;
    int abandoned;
    int release_surface_control_on_abandon;
    int present_fence_fd;
    int previous_release_fence_fd;
    int64_t latch_time;
};

static void
surface_transaction_complete(void *context, ASurfaceTransactionStats *stats)
{
    struct surface_completion *completion = context;
    int present_fence = -1;
    int previous_release_fence = -1;
    int64_t latch_time = -1;
    if (stats != NULL) {
        present_fence = ASurfaceTransactionStats_getPresentFenceFd(stats);
        previous_release_fence =
            ASurfaceTransactionStats_getPreviousReleaseFenceFd(
                stats, completion->surface_control);
        latch_time = ASurfaceTransactionStats_getLatchTime(stats);
    }

    pthread_mutex_lock(&completion->mutex);
    if (completion->abandoned) {
        if (present_fence >= 0) {
            close(present_fence);
        }
        if (previous_release_fence >= 0) {
            close(previous_release_fence);
        }
        ASurfaceControl *surface_control = completion->surface_control;
        int release_surface_control =
            completion->release_surface_control_on_abandon;
        pthread_mutex_unlock(&completion->mutex);
        if (release_surface_control) {
            ASurfaceControl_release(surface_control);
        }
        pthread_cond_destroy(&completion->condition);
        pthread_mutex_destroy(&completion->mutex);
        free(completion);
        return;
    }
    completion->present_fence_fd = present_fence;
    completion->previous_release_fence_fd = previous_release_fence;
    completion->latch_time = latch_time;
    completion->complete = 1;
    pthread_cond_signal(&completion->condition);
    pthread_mutex_unlock(&completion->mutex);
}

static int
present_surface_buffer(JNIEnv *env, jobject surface_object,
                        AHardwareBuffer *buffer, int acquire_fence_fd,
                        char *report, size_t capacity, size_t *used)
{
    if (surface_object == NULL) {
        if (acquire_fence_fd >= 0) {
            close(acquire_fence_fd);
        }
        append_line(report, capacity, used, "surface_control=missing_surface\n");
        return 0;
    }
    ANativeWindow *window = ANativeWindow_fromSurface(env, surface_object);
    append_line(report, capacity, used, "native_window=%s\n",
                window != NULL ? "created" : "missing");
    if (window == NULL) {
        if (acquire_fence_fd >= 0) {
            close(acquire_fence_fd);
        }
        return 0;
    }
    ASurfaceControl *surface_control = ASurfaceControl_createFromWindow(
        window, "Nova Linux image bridge");
    ANativeWindow_release(window);
    append_line(report, capacity, used, "surface_control=%s\n",
                surface_control != NULL ? "created" : "missing");
    if (surface_control == NULL) {
        if (acquire_fence_fd >= 0) {
            close(acquire_fence_fd);
        }
        return 0;
    }

    struct surface_completion *completion = calloc(1, sizeof(*completion));
    if (completion == NULL) {
        if (acquire_fence_fd >= 0) {
            close(acquire_fence_fd);
        }
        ASurfaceControl_release(surface_control);
        append_line(report, capacity, used,
                    "surface_transaction=allocation_failed\n");
        return 0;
    }
    pthread_mutex_init(&completion->mutex, NULL);
    pthread_cond_init(&completion->condition, NULL);
    completion->surface_control = surface_control;
    completion->release_surface_control_on_abandon = 1;

    ASurfaceTransaction *transaction = ASurfaceTransaction_create();
    if (transaction == NULL) {
        if (acquire_fence_fd >= 0) {
            close(acquire_fence_fd);
        }
        append_line(report, capacity, used,
                    "surface_transaction=creation_failed\n");
        pthread_cond_destroy(&completion->condition);
        pthread_mutex_destroy(&completion->mutex);
        free(completion);
        ASurfaceControl_release(surface_control);
        return 0;
    }
    ASurfaceTransaction_setBuffer(transaction, surface_control, buffer,
                                  acquire_fence_fd);
    append_line(report, capacity, used, "surface_acquire_fence=passed\n");
    ARect source = {0, 0, 64, 64};
    ARect destination = {0, 0, 960, 540};
    ASurfaceTransaction_setGeometry(transaction, surface_control, &source,
                                    &destination, 0);
    ASurfaceTransaction_setOnComplete(transaction, completion,
                                      surface_transaction_complete);
    ASurfaceTransaction_apply(transaction);
    ASurfaceTransaction_delete(transaction);
    append_line(report, capacity, used, "surface_transaction_apply=pass\n");

    struct timespec deadline;
    clock_gettime(CLOCK_REALTIME, &deadline);
    deadline.tv_sec += 2;
    pthread_mutex_lock(&completion->mutex);
    while (!completion->complete) {
        int wait_status = pthread_cond_timedwait(
            &completion->condition, &completion->mutex, &deadline);
        if (wait_status != 0) {
            break;
        }
    }
    if (!completion->complete) {
        completion->abandoned = 1;
        pthread_mutex_unlock(&completion->mutex);
        append_line(report, capacity, used,
                    "surface_transaction_complete=timeout\n");
        return 0;
    }
    int present_fence_fd = completion->present_fence_fd;
    int previous_release_fence_fd = completion->previous_release_fence_fd;
    int64_t latch_time = completion->latch_time;
    pthread_mutex_unlock(&completion->mutex);
    append_line(report, capacity, used,
                "surface_transaction_complete=pass latch_time=%lld present_fence=%d previous_release_fence=%d\n",
                (long long)latch_time, present_fence_fd >= 0,
                previous_release_fence_fd >= 0);
    if (present_fence_fd >= 0) {
        close(present_fence_fd);
    }
    if (previous_release_fence_fd >= 0) {
        close(previous_release_fence_fd);
    }
    pthread_cond_destroy(&completion->condition);
    pthread_mutex_destroy(&completion->mutex);
    free(completion);
    ASurfaceControl_release(surface_control);
    return 1;
}

static int
present_surface_frame(ASurfaceControl *surface_control, AHardwareBuffer *buffer,
                       int acquire_fence_fd, int *previous_release_fence_fd,
                       char *report, size_t capacity, size_t *used)
{
    *previous_release_fence_fd = -1;
    if (surface_control == NULL) {
        if (acquire_fence_fd >= 0) {
            close(acquire_fence_fd);
        }
        append_line(report, capacity, used,
                    "surface_frame=missing_surface_control\n");
        return 0;
    }

    struct surface_completion *completion = calloc(1, sizeof(*completion));
    if (completion == NULL) {
        if (acquire_fence_fd >= 0) {
            close(acquire_fence_fd);
        }
        append_line(report, capacity, used,
                    "surface_frame=completion_allocation_failed\n");
        return 0;
    }
    pthread_mutex_init(&completion->mutex, NULL);
    pthread_cond_init(&completion->condition, NULL);
    completion->surface_control = surface_control;

    ASurfaceTransaction *transaction = ASurfaceTransaction_create();
    if (transaction == NULL) {
        if (acquire_fence_fd >= 0) {
            close(acquire_fence_fd);
        }
        append_line(report, capacity, used,
                    "surface_frame=transaction_creation_failed\n");
        pthread_cond_destroy(&completion->condition);
        pthread_mutex_destroy(&completion->mutex);
        free(completion);
        return 0;
    }
    ASurfaceTransaction_setBuffer(transaction, surface_control, buffer,
                                  acquire_fence_fd);
    append_line(report, capacity, used,
                "surface_frame_acquire_fence=passed\n");
    ARect source = {0, 0, 64, 64};
    ARect destination = {0, 0, 960, 540};
    ASurfaceTransaction_setGeometry(transaction, surface_control, &source,
                                    &destination, 0);
    ASurfaceTransaction_setOnComplete(transaction, completion,
                                      surface_transaction_complete);
    ASurfaceTransaction_apply(transaction);
    ASurfaceTransaction_delete(transaction);

    struct timespec deadline;
    clock_gettime(CLOCK_REALTIME, &deadline);
    deadline.tv_sec += 2;
    pthread_mutex_lock(&completion->mutex);
    while (!completion->complete) {
        int wait_status = pthread_cond_timedwait(
            &completion->condition, &completion->mutex, &deadline);
        if (wait_status != 0) {
            break;
        }
    }
    if (!completion->complete) {
        completion->abandoned = 1;
        pthread_mutex_unlock(&completion->mutex);
        append_line(report, capacity, used,
                    "surface_frame_complete=timeout\n");
        return 0;
    }
    int present_fence_fd = completion->present_fence_fd;
    *previous_release_fence_fd = completion->previous_release_fence_fd;
    int64_t latch_time = completion->latch_time;
    pthread_mutex_unlock(&completion->mutex);
    append_line(report, capacity, used,
                "surface_frame_complete=pass latch_time=%lld present_fence=%d previous_release_fence=%d\n",
                (long long)latch_time, present_fence_fd >= 0,
                *previous_release_fence_fd >= 0);
    if (present_fence_fd >= 0) {
        close(present_fence_fd);
    }
    pthread_cond_destroy(&completion->condition);
    pthread_mutex_destroy(&completion->mutex);
    free(completion);
    return 1;
}

static int
create_bridge_server(const char *socket_path)
{
    if (strlen(socket_path) >= sizeof(((struct sockaddr_un *)0)->sun_path)) {
        return -1;
    }
    struct sockaddr_un address = {
        .sun_family = AF_UNIX,
    };
    strcpy(address.sun_path, socket_path);
    unlink(socket_path);
    int server = socket(AF_UNIX, SOCK_STREAM, 0);
    if (server < 0 || bind(server, (struct sockaddr *)&address,
                           sizeof(address)) != 0 || listen(server, 1) != 0) {
        if (server >= 0) {
            close(server);
        }
        unlink(socket_path);
        return -1;
    }
    return server;
}

static ssize_t
receive_bridge_acknowledgement(int client, char *acknowledgement,
                               size_t capacity, int *acquire_fence_fd)
{
    *acquire_fence_fd = -1;
    char control[CMSG_SPACE(sizeof(int) * 4)] = {0};
    struct iovec vector = {
        .iov_base = acknowledgement,
        .iov_len = capacity - 1,
    };
    struct msghdr message = {
        .msg_iov = &vector,
        .msg_iovlen = 1,
        .msg_control = control,
        .msg_controllen = sizeof(control),
    };
    ssize_t bytes = recvmsg(client, &message, 0);
    if (bytes > 0) {
        acknowledgement[bytes < (ssize_t)capacity ? bytes : capacity - 1] =
            '\0';
    } else {
        acknowledgement[0] = '\0';
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
            if (*acquire_fence_fd < 0) {
                *acquire_fence_fd = descriptors[index];
            } else {
                close(descriptors[index]);
            }
        }
    }
    return bytes;
}

static int
send_release_fence(int client, int buffer_index, int release_fence_fd)
{
    char release_message[64];
    int message_length = snprintf(release_message, sizeof(release_message),
                                  "release_buffer=%d\n", buffer_index);
    struct iovec vector = {
        .iov_base = release_message,
        .iov_len = (size_t)message_length,
    };
    char control[CMSG_SPACE(sizeof(int))] = {0};
    struct msghdr message = {
        .msg_iov = &vector,
        .msg_iovlen = 1,
    };
    if (release_fence_fd >= 0) {
        message.msg_control = control;
        message.msg_controllen = sizeof(control);
        struct cmsghdr *header = CMSG_FIRSTHDR(&message);
        header->cmsg_level = SOL_SOCKET;
        header->cmsg_type = SCM_RIGHTS;
        header->cmsg_len = CMSG_LEN(sizeof(int));
        memcpy(CMSG_DATA(header), &release_fence_fd, sizeof(release_fence_fd));
    }
    ssize_t sent = sendmsg(client, &message, MSG_NOSIGNAL);
    if (release_fence_fd >= 0) {
        close(release_fence_fd);
    }
    return sent == message_length ? 0 : -1;
}

static int
initialize_loop_buffer(AHardwareBuffer *buffer, uint32_t marker)
{
    void *mapped = NULL;
    int status = AHardwareBuffer_lock(buffer,
                                       AHARDWAREBUFFER_USAGE_CPU_WRITE_OFTEN,
                                       -1, NULL, &mapped);
    if (status != 0 || mapped == NULL) {
        return -1;
    }
    memcpy(mapped, &marker, sizeof(marker));
    int32_t unlock_fence = -1;
    status = AHardwareBuffer_unlock(buffer, &unlock_fence);
    if (unlock_fence >= 0) {
        close(unlock_fence);
    }
    return status == 0 ? 0 : -1;
}

JNIEXPORT jstring JNICALL
Java_com_xjsonderulo_steamandroid_novalab_MainActivity_nativeRunDmaBufBridge(
    JNIEnv *env, jobject object, jstring socket_path_string,
    jobject surface_object)
{
    (void)object;
    char report[4096] = "";
    size_t used = 0;
    append_line(report, sizeof(report), &used, "ahb_bridge_version=1\n");

    if (socket_path_string == NULL) {
        append_line(report, sizeof(report), &used, "ahb_bridge=missing_socket\n");
        return report_string(env, report);
    }
    const char *socket_path =
        (*env)->GetStringUTFChars(env, socket_path_string, NULL);
    if (socket_path == NULL) {
        append_line(report, sizeof(report), &used, "ahb_bridge=invalid_socket\n");
        return report_string(env, report);
    }

    AHardwareBuffer *buffer = NULL;
    int server = -1;
    int client = -1;
    int success = 0;
    const uint32_t marker = 0x4e4f5641u;
    const uint64_t usage = AHARDWAREBUFFER_USAGE_CPU_READ_OFTEN |
                           AHARDWAREBUFFER_USAGE_CPU_WRITE_OFTEN |
                           AHARDWAREBUFFER_USAGE_GPU_SAMPLED_IMAGE |
                           AHARDWAREBUFFER_USAGE_GPU_FRAMEBUFFER |
                           AHARDWAREBUFFER_USAGE_COMPOSER_OVERLAY;
    AHardwareBuffer_Desc description = {
        .width = 64,
        .height = 64,
        .layers = 1,
        .format = AHARDWAREBUFFER_FORMAT_R8G8B8A8_UNORM,
        .usage = usage,
    };
    int status = AHardwareBuffer_isSupported(&description);
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.supported=%d usage=0x%llx\n", status,
                (unsigned long long)usage);
    if (!status) {
        goto done;
    }
    status = AHardwareBuffer_allocate(&description, &buffer);
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.allocate_status=%d\n", status);
    if (status != 0 || buffer == NULL) {
        goto done;
    }
    void *mapped = NULL;
    status = AHardwareBuffer_lock(buffer, AHARDWAREBUFFER_USAGE_CPU_WRITE_OFTEN,
                                  -1, NULL, &mapped);
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.lock_status=%d\n", status);
    if (status != 0 || mapped == NULL) {
        goto done;
    }
    memcpy(mapped, &marker, sizeof(marker));
    int32_t unlock_fence = -1;
    status = AHardwareBuffer_unlock(buffer, &unlock_fence);
    if (unlock_fence >= 0) {
        close(unlock_fence);
    }
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.unlock_status=%d marker=0x%08x\n", status,
                marker);
    if (status != 0) {
        goto done;
    }

    if (strlen(socket_path) >= sizeof(((struct sockaddr_un *)0)->sun_path)) {
        append_line(report, sizeof(report), &used, "ahb_bridge=socket_path_too_long\n");
        goto done;
    }
    struct sockaddr_un address = {
        .sun_family = AF_UNIX,
    };
    strcpy(address.sun_path, socket_path);
    unlink(socket_path);
    server = socket(AF_UNIX, SOCK_STREAM, 0);
    append_line(report, sizeof(report), &used, "socket_status=%d\n", server >= 0 ? 0 : -1);
    if (server < 0 || bind(server, (struct sockaddr *)&address, sizeof(address)) != 0) {
        append_line(report, sizeof(report), &used, "socket_bind_status=%d\n", server < 0 ? -1 : -2);
        goto done;
    }
    if (listen(server, 1) != 0) {
        append_line(report, sizeof(report), &used, "socket_listen_status=-1\n");
        goto done;
    }
    struct timeval timeout = {
        .tv_sec = 10,
        .tv_usec = 0,
    };
    setsockopt(server, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
    append_line(report, sizeof(report), &used, "socket_listen=pass\n");

    client = accept(server, NULL, NULL);
    append_line(report, sizeof(report), &used, "socket_accept_status=%d\n",
                client >= 0 ? 0 : -1);
    if (client < 0) {
        goto done;
    }
    status = AHardwareBuffer_sendHandleToUnixSocket(buffer, client);
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.send_handle_status=%d\n", status);
    if (status != 0) {
        goto done;
    }
    setsockopt(client, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
    char acknowledgement[128] = {0};
    char acknowledgement_control[CMSG_SPACE(sizeof(int))] = {0};
    struct iovec acknowledgement_vector = {
        .iov_base = acknowledgement,
        .iov_len = sizeof(acknowledgement) - 1,
    };
    struct msghdr acknowledgement_message = {
        .msg_iov = &acknowledgement_vector,
        .msg_iovlen = 1,
        .msg_control = acknowledgement_control,
        .msg_controllen = sizeof(acknowledgement_control),
    };
    ssize_t acknowledgement_bytes =
        recvmsg(client, &acknowledgement_message, 0);
    if (acknowledgement_bytes > 0) {
        acknowledgement[acknowledgement_bytes] = '\0';
    }
    int acquire_fence_fd = -1;
    for (struct cmsghdr *header = CMSG_FIRSTHDR(&acknowledgement_message);
         header != NULL; header = CMSG_NXTHDR(&acknowledgement_message, header)) {
        if (header->cmsg_level != SOL_SOCKET ||
            header->cmsg_type != SCM_RIGHTS) {
            continue;
        }
        size_t byte_count = header->cmsg_len - CMSG_LEN(0);
        size_t descriptor_count = byte_count / sizeof(int);
        int *descriptors = (int *)CMSG_DATA(header);
        for (size_t index = 0; index < descriptor_count; ++index) {
            if (acquire_fence_fd < 0) {
                acquire_fence_fd = descriptors[index];
            } else {
                close(descriptors[index]);
            }
        }
    }
    append_line(report, sizeof(report), &used,
                "bridge_ack_bytes=%zd ack=%s", acknowledgement_bytes,
                acknowledgement_bytes > 0 ? acknowledgement : "");
    int linux_import_pass = acknowledgement_bytes > 0 &&
                            strstr(acknowledgement, "linux_import=pass") != NULL;
    int linux_gpu_pass = acknowledgement_bytes > 0 &&
                         strstr(acknowledgement, "linux_gpu_write=pass") != NULL;
    int linux_image_pass = acknowledgement_bytes > 0 &&
                           strstr(acknowledgement, "linux_image_write=pass") != NULL;
    int linux_acquire_fence_pass = acknowledgement_bytes > 0 &&
                                   strstr(acknowledgement,
                                          "linux_acquire_fence=pass") != NULL;
    int linux_async_fence_pass = acknowledgement_bytes > 0 &&
                                 strstr(acknowledgement,
                                        "linux_async_fence=pass") != NULL;
    append_line(report, sizeof(report), &used,
                "linux_acquire_fence_fd=%s\n",
                acquire_fence_fd >= 0 ? "received" : "missing");
    if (linux_import_pass && linux_gpu_pass && linux_image_pass &&
        linux_acquire_fence_pass && acquire_fence_fd >= 0) {
        int image_write_pass = 0;
        if (linux_async_fence_pass) {
            struct pollfd fence_poll = {
                .fd = acquire_fence_fd,
                .events = POLLIN,
            };
            int poll_status = poll(&fence_poll, 1, 0);
            if (poll_status < 0 || (fence_poll.revents & POLLNVAL) != 0) {
                append_line(report, sizeof(report), &used,
                            "linux_acquire_fence_initial=error\n");
            } else if (poll_status == 0) {
                append_line(report, sizeof(report), &used,
                            "linux_acquire_fence_initial=unsignaled\n");
                image_write_pass = 1;
            } else {
                append_line(report, sizeof(report), &used,
                            "linux_acquire_fence_initial=signaled\n");
                image_write_pass = 1;
            }
            append_line(report, sizeof(report), &used,
                        "ahardwarebuffer.pixel_after_linux=deferred\n");
        } else {
            void *after_linux = NULL;
            status = AHardwareBuffer_lock(buffer,
                                          AHARDWAREBUFFER_USAGE_CPU_READ_OFTEN,
                                          -1, NULL, &after_linux);
            append_line(report, sizeof(report), &used,
                        "ahardwarebuffer.lock_after_linux_status=%d\n", status);
            uint8_t after_linux_pixel[4] = {0};
            if (status == 0 && after_linux != NULL) {
                memcpy(after_linux_pixel, after_linux, sizeof(after_linux_pixel));
                int32_t read_unlock_fence = -1;
                status = AHardwareBuffer_unlock(buffer, &read_unlock_fence);
                if (read_unlock_fence >= 0) {
                    close(read_unlock_fence);
                }
            }
            append_line(report, sizeof(report), &used,
                        "ahardwarebuffer.pixel_after_linux=%02x%02x%02x%02x\n",
                        after_linux_pixel[0], after_linux_pixel[1],
                        after_linux_pixel[2], after_linux_pixel[3]);
            image_write_pass = status == 0 && after_linux_pixel[0] == 0x40 &&
                               after_linux_pixel[1] == 0x80 &&
                               after_linux_pixel[2] == 0xc0 &&
                               after_linux_pixel[3] == 0xff;
        }
        if (image_write_pass) {
            append_line(report, sizeof(report), &used,
                        linux_async_fence_pass
                            ? "ahb_linux_image_write=deferred_pass\n"
                            : "ahb_linux_image_write=pass\n");
            append_line(report, sizeof(report), &used,
                        "ahb_linux_bridge=pass\n");
            if (present_surface_buffer(env, surface_object, buffer,
                                        acquire_fence_fd, report,
                                        sizeof(report), &used)) {
                acquire_fence_fd = -1;
                append_line(report, sizeof(report), &used,
                            "ahb_surface=pass\n");
                success = 1;
            } else {
                append_line(report, sizeof(report), &used,
                            "ahb_surface=fail\n");
            }
        } else {
            append_line(report, sizeof(report), &used,
                        "ahb_linux_image_write=fail\n");
            append_line(report, sizeof(report), &used,
                        "ahb_linux_bridge=fail\n");
        }
    } else if (linux_import_pass && linux_gpu_pass) {
        if (acquire_fence_fd >= 0) {
            close(acquire_fence_fd);
            acquire_fence_fd = -1;
        }
        append_line(report, sizeof(report), &used,
                    "ahb_linux_image_write=missing\n");
        append_line(report, sizeof(report), &used, "ahb_linux_bridge=fail\n");
    } else {
        if (acquire_fence_fd >= 0) {
            close(acquire_fence_fd);
            acquire_fence_fd = -1;
        }
        append_line(report, sizeof(report), &used, "ahb_linux_bridge=fail\n");
    }

done:
    if (client >= 0) {
        close(client);
    }
    if (server >= 0) {
        close(server);
    }
    if (acquire_fence_fd >= 0) {
        close(acquire_fence_fd);
    }
    unlink(socket_path);
    if (buffer != NULL) {
        AHardwareBuffer_release(buffer);
    }
    (*env)->ReleaseStringUTFChars(env, socket_path_string, socket_path);
    append_line(report, sizeof(report), &used, "ahb_bridge=%s\n",
                success ? "pass" : "fail");
    return report_string(env, report);
}

JNIEXPORT jstring JNICALL
Java_com_xjsonderulo_steamandroid_novalab_MainActivity_nativeRunDmaBufDoubleBufferBridge(
    JNIEnv *env, jobject object, jstring socket_path_string,
    jobject surface_object, jint frame_count_argument)
{
    (void)object;
    char report[65536] = "";
    size_t used = 0;
    append_line(report, sizeof(report), &used, "ahb_double_buffer_version=1\n");
    if (socket_path_string == NULL) {
        append_line(report, sizeof(report), &used,
                    "ahb_double_buffer=missing_socket\n");
        return report_string(env, report);
    }
    const char *socket_path =
        (*env)->GetStringUTFChars(env, socket_path_string, NULL);
    if (socket_path == NULL) {
        append_line(report, sizeof(report), &used,
                    "ahb_double_buffer=invalid_socket\n");
        return report_string(env, report);
    }

    AHardwareBuffer *buffers[2] = {NULL, NULL};
    int servers[2] = {-1, -1};
    int clients[2] = {-1, -1};
    char socket_paths[2][sizeof(((struct sockaddr_un *)0)->sun_path)] = {{0}};
    ASurfaceControl *surface_control = NULL;
    int success = 0;
    int frame_count = 0;
    int release_fence_count = 0;
    const uint64_t usage = AHARDWAREBUFFER_USAGE_CPU_READ_OFTEN |
                           AHARDWAREBUFFER_USAGE_CPU_WRITE_OFTEN |
                           AHARDWAREBUFFER_USAGE_GPU_SAMPLED_IMAGE |
                           AHARDWAREBUFFER_USAGE_GPU_FRAMEBUFFER |
                           AHARDWAREBUFFER_USAGE_COMPOSER_OVERLAY;
    AHardwareBuffer_Desc description = {
        .width = 64,
        .height = 64,
        .layers = 1,
        .format = AHARDWAREBUFFER_FORMAT_R8G8B8A8_UNORM,
        .usage = usage,
    };
    int status = AHardwareBuffer_isSupported(&description);
    append_line(report, sizeof(report), &used,
                "ahb_double_buffer_supported=%d usage=0x%llx\n", status,
                (unsigned long long)usage);
    if (!status) {
        goto double_buffer_done;
    }
    for (int index = 0; index < 2; ++index) {
        status = AHardwareBuffer_allocate(&description, &buffers[index]);
        append_line(report, sizeof(report), &used,
                    "ahb_double_buffer_allocate_%d_status=%d\n", index,
                    status);
        if (status != 0 || buffers[index] == NULL ||
            initialize_loop_buffer(buffers[index], 0x4e4f5641u + index) != 0) {
            append_line(report, sizeof(report), &used,
                        "ahb_double_buffer_initialize_%d=fail\n", index);
            goto double_buffer_done;
        }
        append_line(report, sizeof(report), &used,
                    "ahb_double_buffer_initialize_%d=pass marker=0x%08x\n",
                    index, 0x4e4f5641u + index);
        int path_length = snprintf(socket_paths[index],
                                   sizeof(socket_paths[index]), "%s.%d",
                                   socket_path, index);
        if (path_length < 0 || (size_t)path_length >= sizeof(socket_paths[index])) {
            append_line(report, sizeof(report), &used,
                        "ahb_double_buffer_socket_path=too_long\n");
            goto double_buffer_done;
        }
        servers[index] = create_bridge_server(socket_paths[index]);
        append_line(report, sizeof(report), &used,
                    "ahb_double_buffer_server_%d=%s\n", index,
                    servers[index] >= 0 ? "listening" : "failed");
        if (servers[index] < 0) {
            goto double_buffer_done;
        }
    }

    for (int index = 0; index < 2; ++index) {
        clients[index] = accept(servers[index], NULL, NULL);
        append_line(report, sizeof(report), &used,
                    "ahb_double_buffer_accept_%d=%s\n", index,
                    clients[index] >= 0 ? "pass" : "fail");
        if (clients[index] < 0) {
            goto double_buffer_done;
        }
        struct timeval timeout = {
            .tv_sec = 15,
            .tv_usec = 0,
        };
        setsockopt(clients[index], SOL_SOCKET, SO_RCVTIMEO, &timeout,
                   sizeof(timeout));
        status = AHardwareBuffer_sendHandleToUnixSocket(buffers[index],
                                                        clients[index]);
        append_line(report, sizeof(report), &used,
                    "ahb_double_buffer_send_handle_%d=%s\n", index,
                    status == 0 ? "pass" : "fail");
        if (status != 0) {
            goto double_buffer_done;
        }
        close(servers[index]);
        servers[index] = -1;
        unlink(socket_paths[index]);
    }

    if (surface_object == NULL) {
        append_line(report, sizeof(report), &used,
                    "ahb_double_buffer_surface=missing\n");
        goto double_buffer_done;
    }
    ANativeWindow *window = ANativeWindow_fromSurface(env, surface_object);
    append_line(report, sizeof(report), &used,
                "ahb_double_buffer_native_window=%s\n",
                window != NULL ? "created" : "missing");
    if (window == NULL) {
        goto double_buffer_done;
    }
    surface_control = ASurfaceControl_createFromWindow(
        window, "Nova double-buffer Linux image loop");
    ANativeWindow_release(window);
    append_line(report, sizeof(report), &used,
                "ahb_double_buffer_surface_control=%s\n",
                surface_control != NULL ? "created" : "missing");
    if (surface_control == NULL) {
        goto double_buffer_done;
    }

    /* Holo sends two frames before waiting for the first release fence. The
     * alternating order then allows each side to overlap one GPU write with
     * the other buffer's SurfaceControl presentation. */
    const int total_frames =
        frame_count_argument > 0 && frame_count_argument <= 600
            ? frame_count_argument
            : 5;
    append_line(report, sizeof(report), &used,
                "ahb_double_buffer_target_frames=%d\n", total_frames);
    for (int frame = 0; frame < total_frames; ++frame) {
        int index = frame & 1;
        char acknowledgement[256] = {0};
        int acquire_fence_fd = -1;
        ssize_t acknowledgement_bytes = receive_bridge_acknowledgement(
            clients[index], acknowledgement, sizeof(acknowledgement),
            &acquire_fence_fd);
        append_line(report, sizeof(report), &used,
                    "ahb_double_buffer_frame=%d buffer=%d ack_bytes=%zd ack=%s",
                    frame, index, acknowledgement_bytes,
                    acknowledgement_bytes > 0 ? acknowledgement : "");
        int acknowledgement_pass =
            acknowledgement_bytes > 0 && acquire_fence_fd >= 0 &&
            strstr(acknowledgement, "linux_import=pass") != NULL &&
            strstr(acknowledgement, "linux_gpu_write=pass") != NULL &&
            strstr(acknowledgement, "linux_image_write=pass") != NULL &&
            strstr(acknowledgement, "linux_acquire_fence=pass") != NULL &&
            strstr(acknowledgement, "linux_loop=pass") != NULL;
        append_line(report, sizeof(report), &used,
                    "ahb_double_buffer_ack_%d=%s fence_fd=%s\n", frame,
                    acknowledgement_pass ? "pass" : "fail",
                    acquire_fence_fd >= 0 ? "received" : "missing");
        if (!acknowledgement_pass) {
            if (acquire_fence_fd >= 0) {
                close(acquire_fence_fd);
            }
            goto double_buffer_done;
        }

        int previous_release_fence_fd = -1;
        int frame_pass = present_surface_frame(
            surface_control, buffers[index], acquire_fence_fd,
            &previous_release_fence_fd, report, sizeof(report), &used);
        acquire_fence_fd = -1;
        if (!frame_pass) {
            if (previous_release_fence_fd >= 0) {
                close(previous_release_fence_fd);
            }
            goto double_buffer_done;
        }
        frame_count += 1;
        append_line(report, sizeof(report), &used,
                    "ahb_double_buffer_present_%d=pass\n", frame);
        if (frame > 0 && previous_release_fence_fd < 0) {
            append_line(report, sizeof(report), &used,
                        "ahb_double_buffer_release_%d=missing\n", frame);
            goto double_buffer_done;
        }
        if (previous_release_fence_fd >= 0) {
            int previous_index = index ^ 1;
            int release_status = send_release_fence(
                clients[previous_index], previous_index,
                previous_release_fence_fd);
            previous_release_fence_fd = -1;
            append_line(report, sizeof(report), &used,
                        "ahb_double_buffer_release_%d=%s buffer=%d\n", frame,
                        release_status == 0 ? "sent" : "failed",
                        previous_index);
            if (release_status != 0) {
                goto double_buffer_done;
            }
            release_fence_count += 1;
        } else {
            append_line(report, sizeof(report), &used,
                        "ahb_double_buffer_release_%d=none\n", frame);
        }
    }
    success = frame_count == total_frames && release_fence_count == total_frames - 1;

double_buffer_done:
    if (surface_control != NULL) {
        ASurfaceControl_release(surface_control);
    }
    for (int index = 0; index < 2; ++index) {
        if (clients[index] >= 0) {
            close(clients[index]);
        }
        if (servers[index] >= 0) {
            close(servers[index]);
        }
        if (socket_paths[index][0] != '\0') {
            unlink(socket_paths[index]);
        }
        if (buffers[index] != NULL) {
            AHardwareBuffer_release(buffers[index]);
        }
    }
    (*env)->ReleaseStringUTFChars(env, socket_path_string, socket_path);
    append_line(report, sizeof(report), &used,
                "ahb_double_buffer_frames=%d releases=%d\n", frame_count,
                release_fence_count);
    append_line(report, sizeof(report), &used, "ahb_double_buffer=%s\n",
                success ? "pass" : "fail");
    return report_string(env, report);
}
