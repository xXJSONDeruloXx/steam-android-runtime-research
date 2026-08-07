#define _POSIX_C_SOURCE 200809L

#include <android/hardware_buffer.h>

#include <jni.h>

#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/socket.h>
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
Java_com_xjsonderulo_steamandroid_novalab_MainActivity_nativeRunHardwareBufferProbe(
    JNIEnv *env, jobject object)
{
    (void)object;
    char report[4096] = "";
    size_t used = 0;
    append_line(report, sizeof(report), &used, "native_probe_version=1\n");

    const uint64_t usage = AHARDWAREBUFFER_USAGE_CPU_READ_OFTEN |
                           AHARDWAREBUFFER_USAGE_CPU_WRITE_OFTEN |
                           AHARDWAREBUFFER_USAGE_GPU_SAMPLED_IMAGE |
                           AHARDWAREBUFFER_USAGE_COMPOSER_OVERLAY;
    AHardwareBuffer_Desc description = {
        .width = 64,
        .height = 64,
        .layers = 1,
        .format = AHARDWAREBUFFER_FORMAT_R8G8B8A8_UNORM,
        .usage = usage,
    };
    int supported = AHardwareBuffer_isSupported(&description);
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.supported=%d usage=0x%llx\n", supported,
                (unsigned long long)usage);
    if (!supported) {
        append_line(report, sizeof(report), &used,
                    "ahardwarebuffer_probe=unsupported\n");
        return report_string(env, report);
    }

    AHardwareBuffer *buffer = NULL;
    int status = AHardwareBuffer_allocate(&description, &buffer);
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.allocate_status=%d\n", status);
    if (status != 0 || buffer == NULL) {
        return report_string(env, report);
    }

    AHardwareBuffer_Desc actual_description;
    AHardwareBuffer_describe(buffer, &actual_description);
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.desc=%ux%u layers=%u format=%u usage=0x%llx\n",
                actual_description.width, actual_description.height,
                actual_description.layers, actual_description.format,
                (unsigned long long)actual_description.usage);

    void *address = NULL;
    const uint32_t write_value = 0x4e4f5641u;
    status = AHardwareBuffer_lock(buffer, AHARDWAREBUFFER_USAGE_CPU_WRITE_OFTEN,
                                   -1, NULL, &address);
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.lock_write_status=%d\n", status);
    if (status != 0 || address == NULL) {
        AHardwareBuffer_release(buffer);
        return report_string(env, report);
    }
    memcpy(address, &write_value, sizeof(write_value));
    int32_t unlock_fence = -1;
    status = AHardwareBuffer_unlock(buffer, &unlock_fence);
    if (unlock_fence >= 0) {
        close(unlock_fence);
    }
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.unlock_write_status=%d\n", status);
    if (status != 0) {
        AHardwareBuffer_release(buffer);
        return report_string(env, report);
    }

    int sockets[2] = {-1, -1};
    status = socketpair(AF_UNIX, SOCK_STREAM, 0, sockets);
    append_line(report, sizeof(report), &used, "socketpair_status=%d\n", status);
    if (status != 0) {
        AHardwareBuffer_release(buffer);
        return report_string(env, report);
    }

    status = AHardwareBuffer_sendHandleToUnixSocket(buffer, sockets[0]);
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.send_handle_status=%d\n", status);
    if (status != 0) {
        close(sockets[0]);
        close(sockets[1]);
        AHardwareBuffer_release(buffer);
        return report_string(env, report);
    }

    AHardwareBuffer *received = NULL;
    status = AHardwareBuffer_recvHandleFromUnixSocket(sockets[1], &received);
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.recv_handle_status=%d\n", status);
    close(sockets[0]);
    close(sockets[1]);
    if (status != 0 || received == NULL) {
        AHardwareBuffer_release(buffer);
        return report_string(env, report);
    }

    void *received_address = NULL;
    status = AHardwareBuffer_lock(received, AHARDWAREBUFFER_USAGE_CPU_READ_OFTEN,
                                   -1, NULL, &received_address);
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.lock_read_status=%d\n", status);
    uint32_t received_value = 0;
    if (status == 0 && received_address != NULL) {
        memcpy(&received_value, received_address, sizeof(received_value));
        int32_t read_unlock_fence = -1;
        status = AHardwareBuffer_unlock(received, &read_unlock_fence);
        if (read_unlock_fence >= 0) {
            close(read_unlock_fence);
        }
    }
    append_line(report, sizeof(report), &used,
                "ahardwarebuffer.received_value=0x%08x\n", received_value);
    if (status == 0 && received_value == write_value) {
        append_line(report, sizeof(report), &used,
                    "ahardwarebuffer_handle_roundtrip=pass\n");
    } else {
        append_line(report, sizeof(report), &used,
                    "ahardwarebuffer_handle_roundtrip=fail\n");
    }

    AHardwareBuffer_release(received);
    AHardwareBuffer_release(buffer);
    return report_string(env, report);
}
