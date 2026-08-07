#define _POSIX_C_SOURCE 200809L

#include <android/hardware_buffer.h>

#include <jni.h>

#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/time.h>
#include <sys/un.h>
#include <unistd.h>

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

JNIEXPORT jstring JNICALL
Java_com_xjsonderulo_steamandroid_novalab_MainActivity_nativeRunDmaBufBridge(
    JNIEnv *env, jobject object, jstring socket_path_string)
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
                           AHARDWAREBUFFER_USAGE_GPU_FRAMEBUFFER;
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
    ssize_t acknowledgement_bytes =
        read(client, acknowledgement, sizeof(acknowledgement) - 1);
    if (acknowledgement_bytes > 0) {
        acknowledgement[acknowledgement_bytes] = '\0';
    }
    append_line(report, sizeof(report), &used,
                "bridge_ack_bytes=%zd ack=%s", acknowledgement_bytes,
                acknowledgement_bytes > 0 ? acknowledgement : "");
    int linux_import_pass = acknowledgement_bytes > 0 &&
                            strstr(acknowledgement, "linux_import=pass") != NULL;
    int linux_gpu_pass = acknowledgement_bytes > 0 &&
                         strstr(acknowledgement, "linux_gpu_write=pass") != NULL;
    if (linux_import_pass && linux_gpu_pass) {
        void *after_linux = NULL;
        status = AHardwareBuffer_lock(buffer, AHARDWAREBUFFER_USAGE_CPU_READ_OFTEN,
                                      -1, NULL, &after_linux);
        append_line(report, sizeof(report), &used,
                    "ahardwarebuffer.lock_after_linux_status=%d\n", status);
        uint32_t after_linux_value = 0;
        if (status == 0 && after_linux != NULL) {
            memcpy(&after_linux_value, after_linux, sizeof(after_linux_value));
            int32_t read_unlock_fence = -1;
            status = AHardwareBuffer_unlock(buffer, &read_unlock_fence);
            if (read_unlock_fence >= 0) {
                close(read_unlock_fence);
            }
        }
        append_line(report, sizeof(report), &used,
                    "ahardwarebuffer.value_after_linux=0x%08x\n",
                    after_linux_value);
        if (status == 0 && after_linux_value == 0xb16b00b5u) {
            append_line(report, sizeof(report), &used,
                        "ahb_linux_gpu_write=pass\n");
            append_line(report, sizeof(report), &used,
                        "ahb_linux_bridge=pass\n");
            success = 1;
        } else {
            append_line(report, sizeof(report), &used,
                        "ahb_linux_gpu_write=fail\n");
            append_line(report, sizeof(report), &used,
                        "ahb_linux_bridge=fail\n");
        }
    } else {
        append_line(report, sizeof(report), &used, "ahb_linux_bridge=fail\n");
    }

done:
    if (client >= 0) {
        close(client);
    }
    if (server >= 0) {
        close(server);
    }
    unlink(socket_path);
    if (buffer != NULL) {
        AHardwareBuffer_release(buffer);
    }
    (*env)->ReleaseStringUTFChars(env, socket_path_string, socket_path);
    if (!success) {
        append_line(report, sizeof(report), &used, "ahb_bridge=fail\n");
    }
    return report_string(env, report);
}
