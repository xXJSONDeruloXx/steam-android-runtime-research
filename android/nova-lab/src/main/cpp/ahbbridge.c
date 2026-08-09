#define _POSIX_C_SOURCE 200809L

#include <android/hardware_buffer.h>
#include <android/log.h>
#include <android/native_window_jni.h>
#include <android/rect.h>

#include <jni.h>

#include <errno.h>
#include <poll.h>
#include <pthread.h>
#include <stddef.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/stat.h>
#include <sys/ioctl.h>
#include <sys/syscall.h>
#include <sys/system_properties.h>
#include <sys/time.h>
#include <sys/types.h>
#include <sys/un.h>
#include <sys/uio.h>
#include <time.h>
#include <unistd.h>

#define AHB_FRAME_MARKER_X 16
#define AHB_FRAME_MARKER_Y 96
#define AHB_FRAME_MARKER_CELL 8
#define AHB_FRAME_MARKER_COLUMNS 12
#define AHB_FRAME_MARKER_ROWS 4
#define AHB_FRAME_MARKER_BITS \
    (AHB_FRAME_MARKER_COLUMNS * AHB_FRAME_MARKER_ROWS)
#define AHB_FRAME_MARKER_MAGIC 0x4e56u

static int
ahb_trace_enabled(void)
{
    static int enabled = -1;
    if (enabled < 0) {
        char value[PROP_VALUE_MAX] = {0};
        int length = __system_property_get("debug.nova.ahb_trace", value);
        enabled = length > 0 && value[0] == '1' ? 1 : 0;
    }
    return enabled;
}

static int
ahb_frame_identity_enabled(void)
{
    static int enabled = -1;
    if (enabled < 0) {
        char value[PROP_VALUE_MAX] = {0};
        int length = __system_property_get("debug.nova.ahb_frame_identity",
                                           value);
        enabled = length > 0 && value[0] == '1' ? 1 : 0;
    }
    return enabled;
}

static int
ahb_frame_marker_enabled(void)
{
    static int enabled = -1;
    if (enabled < 0) {
        char value[PROP_VALUE_MAX] = {0};
        int length = __system_property_get("debug.nova.ahb_frame_marker",
                                           value);
        enabled = length > 0 && value[0] == '1' ? 1 : 0;
    }
    return enabled;
}

static int
ahb_content_probe_enabled(void)
{
    static int enabled = -1;
    if (enabled < 0) {
        char value[PROP_VALUE_MAX] = {0};
        int length = __system_property_get("debug.nova.ahb_content_probe",
                                           value);
        enabled = length > 0 && value[0] == '1' ? 1 : 0;
    }
    return enabled;
}

struct ahb_content_probe_result {
    uint32_t description_width;
    uint32_t description_height;
    uint32_t description_stride;
    uint32_t description_layers;
    uint32_t description_format;
    uint64_t description_usage;
    uint64_t pixel_count;
    uint64_t raw_checksum;
    uint32_t red_min;
    uint32_t red_max;
    uint32_t green_min;
    uint32_t green_max;
    uint32_t blue_min;
    uint32_t blue_max;
    uint32_t alpha_min;
    uint32_t alpha_max;
    uint64_t red_sum;
    uint64_t green_sum;
    uint64_t blue_sum;
    uint64_t alpha_sum;
    uint32_t luma_min;
    uint32_t luma_max;
    uint64_t luma_sum;
};

static unsigned long long
ahb_monotonic_ns(void)
{
    struct timespec timestamp = {0};
    if (clock_gettime(CLOCK_MONOTONIC, &timestamp) != 0) {
        return 0;
    }
    return (unsigned long long)timestamp.tv_sec * 1000000000ULL +
           (unsigned long long)timestamp.tv_nsec;
}

static long
ahb_thread_id(void)
{
    return (long)syscall(SYS_gettid);
}

static void
ahb_trace(int frame, int buffer, const char *phase, ssize_t bytes, int fence_fd,
          int status)
{
    if (!ahb_trace_enabled()) {
        return;
    }
    __android_log_print(ANDROID_LOG_INFO, "NovaLab",
                        "ahb_double_buffer_trace monotonic_ns=%llu pid=%d tid=%ld frame=%d buffer=%d phase=%s bytes=%zd fence=%d status=%d",
                        ahb_monotonic_ns(), getpid(), ahb_thread_id(), frame,
                        buffer, phase, bytes, fence_fd >= 0, status);
}

static int
ahb_socket_trace_enabled(void)
{
    static int enabled = -1;
    if (enabled < 0) {
        char value[PROP_VALUE_MAX] = {0};
        int length = __system_property_get("debug.nova.ahb_socket_trace",
                                           value);
        enabled = length > 0 && value[0] == '1' ? 1 : 0;
    }
    return enabled;
}

static int
ahb_socket_ack_poll_timeout_ms(void)
{
    char value[PROP_VALUE_MAX] = {0};
    int length = __system_property_get("debug.nova.ahb_ack_poll_timeout_ms",
                                       value);
    if (length <= 0) {
        return 0;
    }

    char *end = NULL;
    errno = 0;
    long parsed = strtol(value, &end, 10);
    if (errno == ERANGE || end == value || *end != '\0' || parsed < 0 ||
        parsed > 600000) {
        return 0;
    }
    return (int)parsed;
}

static unsigned long long
ahb_socket_inode(int fd)
{
    struct stat information;
    return fd >= 0 && fstat(fd, &information) == 0
               ? (unsigned long long)information.st_ino
               : 0;
}

static int
ahb_socket_type(int fd)
{
    int type = -1;
    socklen_t length = sizeof(type);
    if (fd >= 0 && getsockopt(fd, SOL_SOCKET, SO_TYPE, &type, &length) == 0) {
        return type;
    }
    return -1;
}

static int ahb_socket_connection_fds[3] = {-1, -1, -1};
static unsigned int ahb_socket_connection_generations[3] = {0, 0, 0};

static pthread_mutex_t ahb_bridge_cancel_mutex = PTHREAD_MUTEX_INITIALIZER;
static int ahb_bridge_cancel_read_fd = -1;
static int ahb_bridge_cancel_write_fd = -1;

static int
ahb_bridge_register_cancel_pipe(int read_fd, int write_fd)
{
    int status = 0;
    pthread_mutex_lock(&ahb_bridge_cancel_mutex);
    if (ahb_bridge_cancel_read_fd >= 0 || ahb_bridge_cancel_write_fd >= 0) {
        status = -1;
    } else {
        ahb_bridge_cancel_read_fd = read_fd;
        ahb_bridge_cancel_write_fd = write_fd;
    }
    pthread_mutex_unlock(&ahb_bridge_cancel_mutex);
    return status;
}

static void
ahb_bridge_unregister_cancel_pipe(int read_fd, int write_fd)
{
    pthread_mutex_lock(&ahb_bridge_cancel_mutex);
    if (ahb_bridge_cancel_read_fd == read_fd &&
        ahb_bridge_cancel_write_fd == write_fd) {
        ahb_bridge_cancel_read_fd = -1;
        ahb_bridge_cancel_write_fd = -1;
    }
    pthread_mutex_unlock(&ahb_bridge_cancel_mutex);
}

static void
ahb_bridge_request_cancel(void)
{
    pthread_mutex_lock(&ahb_bridge_cancel_mutex);
    int cancel_fd = ahb_bridge_cancel_write_fd;
    pthread_mutex_unlock(&ahb_bridge_cancel_mutex);
    if (cancel_fd < 0) {
        __android_log_print(ANDROID_LOG_INFO, "NovaLab",
                            "ahb_double_buffer_cancel_request=absent");
        return;
    }

    char marker = 'x';
    errno = 0;
    ssize_t written;
    do {
        written = write(cancel_fd, &marker, sizeof(marker));
    } while (written < 0 && errno == EINTR);
    __android_log_print(
        ANDROID_LOG_INFO, "NovaLab",
        "ahb_double_buffer_cancel_request=%s errno=%d",
        written == (ssize_t)sizeof(marker) || (written < 0 && errno == EPIPE)
            ? "pass"
            : "fail",
        written < 0 ? errno : 0);
}

static void
ahb_socket_register_connection(int buffer, int fd)
{
    if (buffer < 0 || buffer >= 3 || fd < 0) {
        return;
    }
    ahb_socket_connection_fds[buffer] = fd;
    ahb_socket_connection_generations[buffer] += 1;
    if (ahb_socket_connection_generations[buffer] == 0) {
        ahb_socket_connection_generations[buffer] = 1;
    }
}

static unsigned int
ahb_socket_connection_generation(int buffer, int fd)
{
    if (buffer < 0 || buffer >= 3 || fd < 0 ||
        ahb_socket_connection_fds[buffer] != fd) {
        return 0;
    }
    return ahb_socket_connection_generations[buffer];
}

static unsigned long long
ahb_socket_cookie(int fd)
{
#ifdef SO_COOKIE
    uint64_t cookie = 0;
    socklen_t length = sizeof(cookie);
    if (fd >= 0 && getsockopt(fd, SOL_SOCKET, SO_COOKIE, &cookie, &length) ==
                        0) {
        return (unsigned long long)cookie;
    }
#else
    (void)fd;
#endif
    return 0;
}

static void
ahb_socket_peer_credentials(int fd, int *pid, int *uid, int *gid)
{
    *pid = -1;
    *uid = -1;
    *gid = -1;
#ifdef SO_PEERCRED
    struct {
        pid_t pid;
        uid_t uid;
        gid_t gid;
    } credentials = {0};
    socklen_t length = sizeof(credentials);
    if (fd >= 0 && getsockopt(fd, SOL_SOCKET, SO_PEERCRED, &credentials,
                              &length) == 0) {
        *pid = (int)credentials.pid;
        *uid = (int)credentials.uid;
        *gid = (int)credentials.gid;
    }
#else
    (void)fd;
#endif
}

static void
ahb_socket_name(int fd, int peer, char *name, size_t capacity)
{
    if (capacity == 0) {
        return;
    }
    name[0] = '\0';
    struct sockaddr_un address = {0};
    socklen_t length = sizeof(address);
    int status = peer
                     ? getpeername(fd, (struct sockaddr *)&address, &length)
                     : getsockname(fd, (struct sockaddr *)&address, &length);
    if (status != 0 || length <= offsetof(struct sockaddr_un, sun_path)) {
        snprintf(name, capacity, "<unnamed>");
        return;
    }
    size_t path_length =
        length - offsetof(struct sockaddr_un, sun_path);
    if (path_length > sizeof(address.sun_path)) {
        path_length = sizeof(address.sun_path);
    }
    if (address.sun_path[0] == '\0') {
        name[0] = '@';
        if (capacity == 1) {
            return;
        }
        size_t copy_length = path_length > 1 ? path_length - 1 : 0;
        if (copy_length > capacity - 2) {
            copy_length = capacity - 2;
        }
        memcpy(name + 1, address.sun_path + 1, copy_length);
        name[copy_length + 1] = '\0';
        return;
    }
    size_t copy_length = strnlen(address.sun_path, path_length);
    if (copy_length > capacity - 1) {
        copy_length = capacity - 1;
    }
    memcpy(name, address.sun_path, copy_length);
    name[copy_length] = '\0';
}

static struct cmsghdr *
ahb_socket_next_cmsg(const struct msghdr *message, struct cmsghdr *header,
                     int *malformed)
{
    if (malformed != NULL) {
        *malformed = 0;
    }
    if (message == NULL || header == NULL || message->msg_control == NULL) {
        if (malformed != NULL) {
            *malformed = 1;
        }
        return NULL;
    }

    uintptr_t control_start = (uintptr_t)message->msg_control;
    if (message->msg_controllen > UINTPTR_MAX - control_start) {
        if (malformed != NULL) {
            *malformed = 1;
        }
        return NULL;
    }
    uintptr_t control_end = control_start + message->msg_controllen;
    uintptr_t header_address = (uintptr_t)header;
    if (header_address < control_start || header_address > control_end ||
        control_end - header_address < CMSG_LEN(0)) {
        if (malformed != NULL) {
            *malformed = 1;
        }
        return NULL;
    }

    size_t remaining = (size_t)(control_end - header_address);
    if (header->cmsg_len == 0) {
        /* Some Android kernels leave zeroed control-buffer padding visible. */
        return NULL;
    }
    if (header->cmsg_len < CMSG_LEN(0) || header->cmsg_len > remaining) {
        if (malformed != NULL) {
            *malformed = 1;
        }
        return NULL;
    }

    size_t aligned_length = CMSG_ALIGN(header->cmsg_len);
    if (aligned_length < header->cmsg_len || aligned_length > remaining) {
        if (malformed != NULL) {
            *malformed = 1;
        }
        return NULL;
    }
    if (aligned_length == remaining ||
        remaining - aligned_length < CMSG_LEN(0)) {
        return NULL;
    }
    return (struct cmsghdr *)(header_address + aligned_length);
}

static void
ahb_socket_cmsg_summary(const struct msghdr *message, char *summary,
                        size_t capacity)
{
    if (capacity == 0) {
        return;
    }
    summary[0] = '\0';
    if (message == NULL) {
        snprintf(summary, capacity, "none");
        return;
    }
    size_t used = 0;
    int header_index = 0;
    for (struct cmsghdr *header = CMSG_FIRSTHDR(message); header != NULL;) {
        if (header->cmsg_len == 0) {
            break;
        }
        size_t bytes = 0;
        int valid = header->cmsg_len >= CMSG_LEN(0) &&
                    header->cmsg_len <= message->msg_controllen;
        if (valid) {
            bytes = header->cmsg_len - CMSG_LEN(0);
        }
        int written = snprintf(
            summary + used, capacity - used, "%s%d:%d:%zu:%s",
            header_index == 0 ? "" : ";", header->cmsg_level,
            header->cmsg_type, header->cmsg_len,
            valid ? (bytes % sizeof(int) == 0 ? "aligned" : "unaligned")
                  : "invalid");
        if (written < 0 || (size_t)written >= capacity - used) {
            used = capacity - 1;
            break;
        }
        used += (size_t)written;
        header_index += 1;
        int malformed = 0;
        struct cmsghdr *next =
            ahb_socket_next_cmsg(message, header, &malformed);
        if (malformed) {
            break;
        }
        header = next;
    }
    if (header_index == 0) {
        snprintf(summary, capacity, "none");
    }
}

static int
ahb_socket_rights_count(const struct msghdr *message)
{
    int count = 0;
    if (message == NULL) {
        return 0;
    }
    for (struct cmsghdr *header = CMSG_FIRSTHDR(message); header != NULL;) {
        if (header->cmsg_len == 0) {
            break;
        }
        if (header->cmsg_level == SOL_SOCKET &&
            header->cmsg_type == SCM_RIGHTS &&
            header->cmsg_len >= CMSG_LEN(0) &&
            header->cmsg_len <= message->msg_controllen) {
            count += (int)((header->cmsg_len - CMSG_LEN(0)) / sizeof(int));
        }
        int malformed = 0;
        struct cmsghdr *next =
            ahb_socket_next_cmsg(message, header, &malformed);
        if (malformed) {
            break;
        }
        header = next;
    }
    return count;
}

static void
ahb_socket_trace(const char *operation, int frame, int buffer, int fd,
                 ssize_t result, int error_number,
                 const struct msghdr *message, int fence_fd,
                 const char *payload)
{
    if (!ahb_socket_trace_enabled()) {
        return;
    }
    char local_name[sizeof(((struct sockaddr_un *)0)->sun_path) + 1] = {0};
    char peer_name[sizeof(((struct sockaddr_un *)0)->sun_path) + 1] = {0};
    char cmsg_summary[128] = {0};
    int peer_pid = -1;
    int peer_uid = -1;
    int peer_gid = -1;
    ahb_socket_name(fd, 0, local_name, sizeof(local_name));
    ahb_socket_name(fd, 1, peer_name, sizeof(peer_name));
    ahb_socket_peer_credentials(fd, &peer_pid, &peer_uid, &peer_gid);
    ahb_socket_cmsg_summary(message, cmsg_summary, sizeof(cmsg_summary));
    __android_log_print(
        ANDROID_LOG_INFO, "NovaLab",
        "ahb_socket_trace monotonic_ns=%llu pid=%d tid=%ld op=%s frame=%d buffer=%d fd=%d inode=%llu type=%d generation=%u cookie=%llu peer_pid=%d peer_uid=%d peer_gid=%d local=%s peer=%s result=%zd errno=%d msg_flags=0x%x msg_controllen=%zu cmsgs=%s rights=%d fence_fd=%d payload=%s",
        ahb_monotonic_ns(), getpid(), ahb_thread_id(), operation, frame,
        buffer, fd, ahb_socket_inode(fd),
        ahb_socket_type(fd), ahb_socket_connection_generation(buffer, fd),
        ahb_socket_cookie(fd), peer_pid, peer_uid, peer_gid, local_name,
        peer_name, result, error_number,
        message != NULL ? message->msg_flags : 0,
        message != NULL ? message->msg_controllen : 0, cmsg_summary,
        ahb_socket_rights_count(message), fence_fd,
        payload != NULL ? payload : "");
}

static void
ahb_socket_poll_trace(const char *operation, int frame, int buffer, int fd,
                      int result, short revents, int error_number)
{
    if (!ahb_socket_trace_enabled()) {
        return;
    }
    __android_log_print(
        ANDROID_LOG_INFO, "NovaLab",
        "ahb_socket_poll monotonic_ns=%llu pid=%d tid=%ld op=%s frame=%d buffer=%d fd=%d inode=%llu type=%d generation=%u cookie=%llu result=%d revents=0x%x errno=%d",
        ahb_monotonic_ns(), getpid(), ahb_thread_id(), operation, frame,
        buffer, fd, ahb_socket_inode(fd),
        ahb_socket_type(fd), ahb_socket_connection_generation(buffer, fd),
        ahb_socket_cookie(fd), result, (unsigned int)revents, error_number);
}

static void
ahb_socket_set_receive_timeout(int frame, int buffer, int fd,
                               const struct timeval *requested)
{
    int ack_poll_timeout_ms = ahb_socket_ack_poll_timeout_ms();
    errno = 0;
    int set_status = setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, requested,
                                sizeof(*requested));
    int set_error = set_status < 0 ? errno : 0;

    struct timeval effective = {0};
    socklen_t effective_length = sizeof(effective);
    errno = 0;
    int get_status = getsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &effective,
                                &effective_length);
    int get_error = get_status < 0 ? errno : 0;

    if (!ahb_socket_trace_enabled()) {
        return;
    }
    __android_log_print(
        ANDROID_LOG_INFO, "NovaLab",
        "ahb_socket_timeout frame=%d buffer=%d fd=%d inode=%llu type=%d generation=%u cookie=%llu requested_sec=%lld requested_usec=%lld set_result=%d set_errno=%d get_result=%d get_errno=%d effective_sec=%lld effective_usec=%lld effective_len=%u ack_poll_timeout_ms=%d",
        frame, buffer, fd, ahb_socket_inode(fd), ahb_socket_type(fd),
        ahb_socket_connection_generation(buffer, fd), ahb_socket_cookie(fd),
        (long long)requested->tv_sec, (long long)requested->tv_usec,
        set_status, set_error, get_status, get_error,
        (long long)effective.tv_sec, (long long)effective.tv_usec,
        (unsigned int)effective_length, ack_poll_timeout_ms);
}

static void
ahb_socket_wait_probe(int frame, int buffer, int fd)
{
    if (!ahb_socket_trace_enabled()) {
        return;
    }
    struct pollfd socket_poll = {
        .fd = fd,
        .events = POLLIN | POLLERR | POLLHUP | POLLNVAL,
    };
    errno = 0;
    int poll_status;
    do {
        poll_status = poll(&socket_poll, 1, 0);
    } while (poll_status < 0 && errno == EINTR);
    int error_number = poll_status < 0 ? errno : 0;
    ahb_socket_poll_trace("ack_wait_probe", frame, buffer, fd, poll_status,
                          socket_poll.revents, error_number);
}

static void
ahb_socket_timeout_queue_payload(int fd, char *payload, size_t capacity)
{
    if (capacity == 0) {
        return;
    }
    int queued_bytes = -1;
    int queue_errno = 0;
    errno = 0;
    if (ioctl(fd, FIONREAD, &queued_bytes) != 0) {
        queue_errno = errno;
    }
    snprintf(payload, capacity,
             "recv_timeout_queue_bytes=%d queue_errno=%d", queued_bytes,
             queue_errno);
}

static int
wait_for_socket_or_cancel(int socket_fd, int cancel_fd, int frame, int buffer)
{
    struct pollfd descriptors[2] = {
        {
            .fd = socket_fd,
            .events = POLLIN | POLLERR | POLLHUP | POLLNVAL,
        },
        {
            .fd = cancel_fd,
            .events = POLLIN | POLLERR | POLLHUP | POLLNVAL,
        },
    };
    nfds_t descriptor_count = cancel_fd >= 0 ? 2 : 1;
    int poll_status;
    do {
        errno = 0;
        poll_status = poll(descriptors, descriptor_count, -1);
    } while (poll_status < 0 && errno == EINTR);
    if (poll_status < 0) {
        return -1;
    }
    if (cancel_fd >= 0 && descriptors[1].revents != 0) {
        __android_log_print(
            ANDROID_LOG_INFO, "NovaLab",
            "ahb_double_buffer_cancelled phase=accept frame=%d buffer=%d",
            frame, buffer);
        return -2;
    }
    if (descriptors[0].revents == 0) {
        return -1;
    }
    return 0;
}

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
extern void ASurfaceTransaction_setEnableBackPressure(
    ASurfaceTransaction *transaction, ASurfaceControl *surface_control,
    int enable_back_pressure);
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
    ASurfaceTransaction_setEnableBackPressure(transaction, surface_control, 0);
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
                       int acquire_fence_fd, int buffer_width, int buffer_height,
                       int destination_width, int destination_height,
                       int *previous_release_fence_fd,
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
    ASurfaceTransaction_setEnableBackPressure(transaction, surface_control, 0);
    append_line(report, capacity, used,
                "surface_frame_acquire_fence=passed\n");
    ARect source = {0, 0, buffer_width, buffer_height};
    ARect destination = {0, 0, destination_width, destination_height};
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
parse_ack_u64(const char *acknowledgement, const char *field_name,
              uint64_t *value)
{
    if (acknowledgement == NULL || field_name == NULL || value == NULL) {
        return -1;
    }
    const char *field = strstr(acknowledgement, field_name);
    if (field == NULL ||
        (field != acknowledgement && field[-1] != ' ' && field[-1] != '\n')) {
        return -1;
    }
    field += strlen(field_name);
    if (*field != '=') {
        return -1;
    }
    char *end = NULL;
    errno = 0;
    unsigned long long parsed = strtoull(field + 1, &end, 10);
    if (errno != 0 || end == field + 1 ||
        (*end != '\0' && *end != ' ' && *end != '\n')) {
        return -1;
    }
    *value = (uint64_t)parsed;
    return 0;
}

static int
write_frame_marker(uint8_t *pixels, size_t stride_bytes, int width, int height,
                   int frame, uint64_t checksum)
{
    const int marker_width = AHB_FRAME_MARKER_COLUMNS * AHB_FRAME_MARKER_CELL;
    const int marker_height = AHB_FRAME_MARKER_ROWS * AHB_FRAME_MARKER_CELL;
    if (pixels == NULL || width < AHB_FRAME_MARKER_X + marker_width ||
        height < AHB_FRAME_MARKER_Y + marker_height || frame < 0 ||
        frame > 0xffff) {
        return -1;
    }

    const uint64_t payload = ((uint64_t)AHB_FRAME_MARKER_MAGIC << 32) |
                             ((uint64_t)(uint32_t)frame << 16) |
                             (checksum & 0xffffu);
    for (int bit = 0; bit < AHB_FRAME_MARKER_BITS; ++bit) {
        const int column = bit % AHB_FRAME_MARKER_COLUMNS;
        const int row = bit / AHB_FRAME_MARKER_COLUMNS;
        const uint8_t value =
            ((payload >> (AHB_FRAME_MARKER_BITS - 1 - bit)) & 1u) != 0
                ? 0xff
                : 0x00;
        for (int y = 0; y < AHB_FRAME_MARKER_CELL; ++y) {
            uint8_t *line = pixels +
                            (size_t)(AHB_FRAME_MARKER_Y +
                                     row * AHB_FRAME_MARKER_CELL + y) *
                                stride_bytes;
            for (int x = 0; x < AHB_FRAME_MARKER_CELL; ++x) {
                uint8_t *pixel = line +
                                 (size_t)(AHB_FRAME_MARKER_X +
                                          column * AHB_FRAME_MARKER_CELL + x) *
                                     4u;
                pixel[0] = value;
                pixel[1] = value;
                pixel[2] = value;
                pixel[3] = 0xff;
            }
        }
    }
    return 0;
}

static int
checksum_ahardware_buffer(AHardwareBuffer *buffer, int width, int height,
                          int acquire_fence_fd, int marker_enabled, int frame,
                          int content_probe_enabled,
                          struct ahb_content_probe_result *content_probe,
                          uint64_t *checksum, int *marker_status)
{
    if (buffer == NULL || checksum == NULL || width <= 0 || height <= 0 ||
        acquire_fence_fd < 0 ||
        (content_probe_enabled && content_probe == NULL)) {
        return -1;
    }
    if (content_probe != NULL) {
        memset(content_probe, 0, sizeof(*content_probe));
    }
    if (marker_status != NULL) {
        *marker_status = marker_enabled ? -1 : 0;
    }

    struct pollfd fence_poll = {
        .fd = acquire_fence_fd,
        .events = POLLIN,
    };
    int poll_status;
    do {
        poll_status = poll(&fence_poll, 1, 5000);
    } while (poll_status < 0 && errno == EINTR);
    if (poll_status <= 0 || (fence_poll.revents & POLLNVAL) != 0 ||
        (fence_poll.revents & (POLLIN | POLLERR | POLLHUP)) == 0) {
        return -1;
    }

    AHardwareBuffer_Desc description = {0};
    AHardwareBuffer_describe(buffer, &description);
    if (content_probe != NULL) {
        content_probe->description_width = description.width;
        content_probe->description_height = description.height;
        content_probe->description_stride = description.stride;
        content_probe->description_layers = description.layers;
        content_probe->description_format = description.format;
        content_probe->description_usage = description.usage;
        content_probe->red_min = 255;
        content_probe->green_min = 255;
        content_probe->blue_min = 255;
        content_probe->alpha_min = 255;
        content_probe->luma_min = 255;
    }
    if (description.format != AHARDWAREBUFFER_FORMAT_R8G8B8A8_UNORM ||
        description.width < (uint32_t)width ||
        description.height < (uint32_t)height ||
        description.stride < (uint32_t)width) {
        return -1;
    }

    void *mapped = NULL;
    int status = AHardwareBuffer_lock(buffer,
                                      AHARDWAREBUFFER_USAGE_CPU_READ_OFTEN |
                                          AHARDWAREBUFFER_USAGE_CPU_WRITE_OFTEN,
                                      -1, NULL, &mapped);
    if (status != 0 || mapped == NULL) {
        return -1;
    }

    const size_t stride_bytes = (size_t)description.stride * 4u;
    uint64_t hash = 1469598103934665603ULL;
    const uint8_t *pixels = (const uint8_t *)mapped;
    for (int row = 0; row < height; ++row) {
        const uint8_t *line = pixels + (size_t)row * stride_bytes;
        for (int column = 0; column < width; ++column) {
            const uint8_t *pixel = line + (size_t)column * 4u;
            for (int channel = 0; channel < 4; ++channel) {
                hash ^= pixel[channel];
                hash *= 1099511628211ULL;
            }
            if (content_probe != NULL) {
                const uint32_t red = pixel[0];
                const uint32_t green = pixel[1];
                const uint32_t blue = pixel[2];
                const uint32_t alpha = pixel[3];
                const uint32_t luma =
                    (77u * red + 150u * green + 29u * blue + 128u) >> 8;
                content_probe->red_min =
                    red < content_probe->red_min ? red : content_probe->red_min;
                content_probe->red_max =
                    red > content_probe->red_max ? red : content_probe->red_max;
                content_probe->green_min = green < content_probe->green_min
                                                ? green
                                                : content_probe->green_min;
                content_probe->green_max = green > content_probe->green_max
                                                ? green
                                                : content_probe->green_max;
                content_probe->blue_min =
                    blue < content_probe->blue_min ? blue : content_probe->blue_min;
                content_probe->blue_max =
                    blue > content_probe->blue_max ? blue : content_probe->blue_max;
                content_probe->alpha_min = alpha < content_probe->alpha_min
                                                ? alpha
                                                : content_probe->alpha_min;
                content_probe->alpha_max = alpha > content_probe->alpha_max
                                                ? alpha
                                                : content_probe->alpha_max;
                content_probe->red_sum += red;
                content_probe->green_sum += green;
                content_probe->blue_sum += blue;
                content_probe->alpha_sum += alpha;
                content_probe->luma_min =
                    luma < content_probe->luma_min ? luma : content_probe->luma_min;
                content_probe->luma_max =
                    luma > content_probe->luma_max ? luma : content_probe->luma_max;
                content_probe->luma_sum += luma;
            }
        }
    }
    if (content_probe != NULL) {
        content_probe->pixel_count = (uint64_t)width * (uint64_t)height;
        content_probe->raw_checksum = hash;
    }

    if (marker_enabled) {
        if (marker_status == NULL) {
            status = -1;
        } else {
            *marker_status = write_frame_marker(
                (uint8_t *)mapped, stride_bytes, width, height, frame, hash);
            if (*marker_status != 0) {
                status = -1;
            }
        }
    }

    int32_t unlock_fence = -1;
    status = AHardwareBuffer_unlock(buffer, &unlock_fence);
    if (unlock_fence >= 0) {
        close(unlock_fence);
    }
    if (status != 0) {
        return -1;
    }
    *checksum = hash;
    return 0;
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

static int
accept_bridge_client(int server, int cancel_fd, int frame, int buffer)
{
    int wait_status = wait_for_socket_or_cancel(server, cancel_fd, frame, buffer);
    if (wait_status != 0) {
        return wait_status == -2 ? -2 : -1;
    }
    errno = 0;
    int client = accept(server, NULL, NULL);
    return client >= 0 ? client : -1;
}

static ssize_t
receive_bridge_acknowledgement(int client, char *acknowledgement,
                               size_t capacity, int *acquire_fence_fd,
                               int frame, int buffer, int cancel_fd,
                               int continuous)
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
    ahb_socket_trace("ack_wait_begin", frame, buffer, client, 0, 0, NULL, -1,
                     "blocking_recvmsg=begin");
    ahb_socket_wait_probe(frame, buffer, client);

    int ack_poll_timeout_ms = ahb_socket_ack_poll_timeout_ms();
    int wait_timeout_ms = ack_poll_timeout_ms;
    if (wait_timeout_ms == 0) {
        wait_timeout_ms = continuous ? -1 : 15000;
    }
    if (cancel_fd >= 0 || wait_timeout_ms != 0) {
        struct pollfd timed_poll[2] = {
            {
                .fd = client,
                .events = POLLIN | POLLERR | POLLHUP | POLLNVAL,
            },
            {
                .fd = cancel_fd,
                .events = POLLIN | POLLERR | POLLHUP | POLLNVAL,
            },
        };
        nfds_t descriptor_count = cancel_fd >= 0 ? 2 : 1;
        errno = 0;
        int poll_status;
        do {
            poll_status = poll(timed_poll, descriptor_count, wait_timeout_ms);
        } while (poll_status < 0 && errno == EINTR);
        int poll_error = poll_status < 0 ? errno : 0;
        ahb_socket_poll_trace("ack_wait_timed", frame, buffer, client,
                              poll_status, timed_poll[0].revents, poll_error);

        if (cancel_fd >= 0 && timed_poll[1].revents != 0) {
            __android_log_print(
                ANDROID_LOG_INFO, "NovaLab",
                "ahb_double_buffer_cancelled phase=ack_wait frame=%d buffer=%d",
                frame, buffer);
            return -2;
        }

        if (poll_status <= 0) {
            char queue_payload[96] = {0};
            ahb_socket_timeout_queue_payload(client, queue_payload,
                                             sizeof(queue_payload));
            char timeout_payload[256] = {0};
            snprintf(timeout_payload, sizeof(timeout_payload),
                     "%s poll_timeout_ms=%d poll_result=%d poll_revents=0x%x poll_errno=%d",
                     queue_payload, wait_timeout_ms, poll_status,
                     (unsigned int)timed_poll[0].revents, poll_error);
            ahb_socket_trace(
                poll_status == 0 ? "ack_wait_timeout" : "ack_wait_poll_error",
                frame, buffer, client, poll_status, poll_error, NULL, -1,
                timeout_payload);
            return -1;
        }
    }

    errno = 0;
    ssize_t bytes = recvmsg(client, &message, MSG_CMSG_CLOEXEC);
    int error_number = bytes < 0 ? errno : 0;
    int protocol_error = bytes >= 0 &&
                         (message.msg_flags & (MSG_CTRUNC | MSG_TRUNC)) != 0;
    if (bytes > 0) {
        acknowledgement[bytes < (ssize_t)capacity ? bytes : capacity - 1] =
            '\0';
    } else {
        acknowledgement[0] = '\0';
    }
    for (struct cmsghdr *header = CMSG_FIRSTHDR(&message); header != NULL;) {
        if (header->cmsg_len == 0) {
            break;
        }
        if (header->cmsg_len < CMSG_LEN(0) ||
            header->cmsg_len > message.msg_controllen) {
            protocol_error = 1;
            break;
        }
        if (header->cmsg_level == SOL_SOCKET &&
            header->cmsg_type == SCM_RIGHTS) {
            size_t byte_count = header->cmsg_len - CMSG_LEN(0);
            if (byte_count % sizeof(int) != 0) {
                protocol_error = 1;
                break;
            }
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
        int malformed = 0;
        struct cmsghdr *next =
            ahb_socket_next_cmsg(&message, header, &malformed);
        if (malformed) {
            protocol_error = 1;
            break;
        }
        header = next;
    }
    char wait_end_payload[96] = {0};
    const char *wait_end_message = acknowledgement;
    if (bytes < 0) {
        ahb_socket_timeout_queue_payload(client, wait_end_payload,
                                          sizeof(wait_end_payload));
        wait_end_message = wait_end_payload;
    }
    ahb_socket_trace("ack_wait_end", frame, buffer, client, bytes,
                     error_number, &message, *acquire_fence_fd,
                     wait_end_message);
    if (protocol_error) {
        if (*acquire_fence_fd >= 0) {
            close(*acquire_fence_fd);
            *acquire_fence_fd = -1;
        }
        ahb_socket_trace("ack_protocol_error", frame, buffer, client, bytes,
                         0, &message, -1, "ancillary_or_message_truncated");
        return -1;
    }
    ahb_socket_trace("ack_recv", frame, buffer, client, bytes, error_number,
                     &message, *acquire_fence_fd, acknowledgement);
    return bytes;
}

static int
send_release_fence(int client, int frame, int buffer_index, int release_fence_fd)
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
    errno = 0;
    ssize_t sent = sendmsg(client, &message, MSG_NOSIGNAL);
    int error_number = sent < 0 ? errno : 0;
    ahb_socket_trace("release_send", frame, buffer_index, client, sent,
                     error_number, &message, release_fence_fd,
                     release_message);
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
    ahb_socket_set_receive_timeout(-1, -1, client, &timeout);
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
        recvmsg(client, &acknowledgement_message, MSG_CMSG_CLOEXEC);
    if (acknowledgement_bytes > 0) {
        acknowledgement[acknowledgement_bytes] = '\0';
    }
    int acquire_fence_fd = -1;
    int acknowledgement_protocol_error =
        acknowledgement_bytes >= 0 &&
        (acknowledgement_message.msg_flags & (MSG_CTRUNC | MSG_TRUNC)) != 0;
    for (struct cmsghdr *header = CMSG_FIRSTHDR(&acknowledgement_message);
         header != NULL;) {
        if (header->cmsg_len == 0) {
            break;
        }
        if (header->cmsg_len < CMSG_LEN(0) ||
            header->cmsg_len > acknowledgement_message.msg_controllen) {
            acknowledgement_protocol_error = 1;
            break;
        }
        if (header->cmsg_level == SOL_SOCKET &&
            header->cmsg_type == SCM_RIGHTS) {
            size_t byte_count = header->cmsg_len - CMSG_LEN(0);
            if (byte_count % sizeof(int) != 0) {
                acknowledgement_protocol_error = 1;
                break;
            }
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
        int malformed = 0;
        struct cmsghdr *next = ahb_socket_next_cmsg(
            &acknowledgement_message, header, &malformed);
        if (malformed) {
            acknowledgement_protocol_error = 1;
            break;
        }
        header = next;
    }
    append_line(report, sizeof(report), &used,
                "bridge_ack_bytes=%zd control_protocol=%s ack=%s", acknowledgement_bytes,
                acknowledgement_protocol_error ? "fail" : "pass",
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
    jobject surface_object, jint frame_count_argument,
    jint frame_width_argument, jint frame_height_argument,
    jboolean force_gpu_composition)
{
    (void)object;
    /*
     * The bounded acceptance profile may run past the historical frame-149
     * boundary.  A 64 KiB report truncated a successful 240-frame producer
     * run before its final frames/releases/pass summary, making the harness
     * reject valid transport evidence.  Keep the report bounded, but large
     * enough for the maximum 600-frame diagnostic profile.
     */
    char report[262144] = "";
    size_t used = 0;
    append_line(report, sizeof(report), &used, "ahb_double_buffer_version=2\n");
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

    AHardwareBuffer *buffers[3] = {NULL, NULL, NULL};
    int servers[3] = {-1, -1, -1};
    int clients[3] = {-1, -1, -1};
    char socket_paths[3][sizeof(((struct sockaddr_un *)0)->sun_path)] = {{0}};
    ASurfaceControl *surface_control = NULL;
    int cancel_pipe[2] = {-1, -1};
    int cancel_registered = 0;
    int cancelled = 0;
    int success = 0;
    int frame_count = 0;
    int release_fence_count = 0;
    const int continuous = frame_count_argument < 0;
    const int frame_identity = ahb_frame_identity_enabled();
    const int frame_marker = ahb_frame_marker_enabled();
    const int content_probe = ahb_content_probe_enabled();
    const int buffer_width =
        frame_width_argument > 0 && frame_width_argument <= 4096
            ? frame_width_argument
            : 64;
    const int buffer_height =
        frame_height_argument > 0 && frame_height_argument <= 4096
            ? frame_height_argument
            : 64;
    const uint64_t usage = AHARDWAREBUFFER_USAGE_CPU_READ_OFTEN |
                           AHARDWAREBUFFER_USAGE_CPU_WRITE_OFTEN |
                           AHARDWAREBUFFER_USAGE_GPU_SAMPLED_IMAGE |
                           AHARDWAREBUFFER_USAGE_GPU_FRAMEBUFFER |
                           (force_gpu_composition
                                ? 0
                                : AHARDWAREBUFFER_USAGE_COMPOSER_OVERLAY);
    AHardwareBuffer_Desc description = {
        .width = (uint32_t)buffer_width,
        .height = (uint32_t)buffer_height,
        .layers = 1,
        .format = AHARDWAREBUFFER_FORMAT_R8G8B8A8_UNORM,
        .usage = usage,
    };
    int status = 0;
    if (pipe(cancel_pipe) != 0) {
        append_line(report, sizeof(report), &used,
                    "ahb_double_buffer_cancel_pipe=failed errno=%d\n", errno);
        goto double_buffer_done;
    }
    if (ahb_bridge_register_cancel_pipe(cancel_pipe[0], cancel_pipe[1]) != 0) {
        append_line(report, sizeof(report), &used,
                    "ahb_double_buffer_cancel_pipe=already_active\n");
        goto double_buffer_done;
    }
    cancel_registered = 1;
    append_line(report, sizeof(report), &used,
                "ahb_double_buffer_cancel_pipe=ready\n");
    status = AHardwareBuffer_isSupported(&description);
    append_line(report, sizeof(report), &used,
                "ahb_double_buffer_supported=%d usage=0x%llx\n", status,
                (unsigned long long)usage);
    append_line(report, sizeof(report), &used,
                "ahb_double_buffer_composer_overlay=%s\n",
                force_gpu_composition ? "disabled" : "enabled");
    if (!status) {
        goto double_buffer_done;
    }
    for (int index = 0; index < 3; ++index) {
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
        int server_error = servers[index] < 0 ? errno : 0;
        ahb_socket_trace("listen", -1, index, servers[index],
                         servers[index] >= 0 ? 0 : -1,
                         server_error, NULL, -1, socket_paths[index]);
        append_line(report, sizeof(report), &used,
                    "ahb_double_buffer_server_%d=%s\n", index,
                    servers[index] >= 0 ? "listening" : "failed");
        if (servers[index] < 0) {
            goto double_buffer_done;
        }
    }

    for (int index = 0; index < 3; ++index) {
        clients[index] = accept_bridge_client(servers[index], cancel_pipe[0], -1,
                                              index);
        if (clients[index] == -2) {
            cancelled = 1;
            append_line(report, sizeof(report), &used,
                        "ahb_double_buffer_cancelled=pass phase=accept\n");
            goto double_buffer_done;
        }
        int accept_error = clients[index] < 0 ? errno : 0;
        ahb_socket_register_connection(index, clients[index]);
        ahb_socket_trace("accept", -1, index, clients[index],
                         clients[index] >= 0 ? 0 : -1, accept_error, NULL,
                         -1, NULL);
        append_line(report, sizeof(report), &used,
                    "ahb_double_buffer_accept_%d=%s\n", index,
                    clients[index] >= 0 ? "pass" : "fail");
        if (clients[index] < 0) {
            goto double_buffer_done;
        }
        struct timeval timeout = {
            /* A live session must remain blocked while Gamescope has a
             * quiet scene.  Positive bounded runs retain a fail-fast
             * timeout so a dead host cannot leave the acceptance test
             * hanging indefinitely. */
            .tv_sec = continuous ? 0 : 15,
            .tv_usec = 0,
        };
        ahb_socket_set_receive_timeout(-1, index, clients[index], &timeout);
        status = AHardwareBuffer_sendHandleToUnixSocket(buffers[index],
                                                        clients[index]);
        ahb_socket_trace("handle_send", -1, index, clients[index], status,
                         status == 0 ? 0 : errno, NULL, -1, NULL);
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
    const int destination_width = ANativeWindow_getWidth(window);
    const int destination_height = ANativeWindow_getHeight(window);
    append_line(report, sizeof(report), &used,
                "ahb_double_buffer_destination=%dx%d\n",
                destination_width, destination_height);
    surface_control = ASurfaceControl_createFromWindow(
        window, "Nova double-buffer Linux image loop");
    ANativeWindow_release(window);
    append_line(report, sizeof(report), &used,
                "ahb_double_buffer_surface_control=%s\n",
                surface_control != NULL ? "created" : "missing");
    if (surface_control == NULL) {
        goto double_buffer_done;
    }

    /* Holo sends three frames before waiting for the first release fence. The
     * extra slot absorbs a panel/compositor release-latency spike without
     * reusing a buffer that SurfaceFlinger still owns. */
    /* A negative frame count is the manual-session sentinel. Keep the
     * bounded positive mode strict for automated smoke tests, while allowing
     * the live Android presentation and input bridges to remain available for
     * real device interaction until the host session is stopped. */
    const int total_frames =
        continuous
            ? 0
            : (frame_count_argument > 0 && frame_count_argument <= 600
                   ? frame_count_argument
                   : 5);
    if (continuous) {
        append_line(report, sizeof(report), &used,
                    "ahb_double_buffer_target_frames=continuous\n");
    } else {
        append_line(report, sizeof(report), &used,
                    "ahb_double_buffer_target_frames=%d\n", total_frames);
    }
    append_line(report, sizeof(report), &used,
                "ahb_double_buffer_size=%dx%d\n", buffer_width,
                buffer_height);
    append_line(report, sizeof(report), &used,
                "ahb_double_buffer_ack_wait_mode=%s\n",
                continuous ? "continuous_blocking" : "bounded_15s");
    append_line(report, sizeof(report), &used,
                "ahb_double_buffer_frame_identity=%s\n",
                frame_identity ? "enabled" : "disabled");
    append_line(report, sizeof(report), &used,
                "ahb_double_buffer_frame_marker=%s x=%d y=%d cell=%d columns=%d rows=%d\n",
                frame_marker ? "enabled" : "disabled", AHB_FRAME_MARKER_X,
                AHB_FRAME_MARKER_Y, AHB_FRAME_MARKER_CELL,
                AHB_FRAME_MARKER_COLUMNS, AHB_FRAME_MARKER_ROWS);
    append_line(report, sizeof(report), &used,
                "ahb_double_buffer_content_probe=%s sample_policy=first3_every30_final\n",
                content_probe ? "enabled" : "disabled");
    for (int frame = 0; continuous || frame < total_frames; ++frame) {
        int index = frame % 3;
        char acknowledgement[256] = {0};
        int acquire_fence_fd = -1;
        ahb_trace(frame, index, "wait_ack", -1, -1, 0);
        if (frame < 4 || (frame % 30) == 0) {
            __android_log_print(ANDROID_LOG_INFO, "NovaLab",
                                "ahb_double_buffer_wait_ack frame=%d buffer=%d",
                                frame, index);
        }
        ssize_t acknowledgement_bytes = receive_bridge_acknowledgement(
            clients[index], acknowledgement, sizeof(acknowledgement),
            &acquire_fence_fd, frame, index, cancel_pipe[0], continuous);
        if (acknowledgement_bytes == -2) {
            cancelled = 1;
            append_line(report, sizeof(report), &used,
                        "ahb_double_buffer_cancelled=pass phase=ack_wait\n");
            goto double_buffer_done;
        }
        if (frame < 4 || (frame % 30) == 0 || acknowledgement_bytes <= 0) {
            __android_log_print(
                ANDROID_LOG_INFO, "NovaLab",
                "ahb_double_buffer_ack_result frame=%d buffer=%d bytes=%zd fence=%d",
                frame, index, acknowledgement_bytes, acquire_fence_fd >= 0);
        }
        ahb_trace(frame, index, "ack_received", acknowledgement_bytes,
                  acquire_fence_fd, acknowledgement_bytes > 0 ? 0 : -1);
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

        if (frame_identity || frame_marker || content_probe) {
            uint64_t producer_frame = 0;
            uint64_t focus_commit = 0;
            uint64_t override_commit = 0;
            int metadata_pass =
                parse_ack_u64(acknowledgement, "nova_output_frame",
                              &producer_frame) == 0 &&
                parse_ack_u64(acknowledgement, "nova_focus_commit",
                              &focus_commit) == 0 &&
                parse_ack_u64(acknowledgement, "nova_override_commit",
                              &override_commit) == 0 &&
                producer_frame == (uint64_t)frame;
            uint64_t checksum = 0;
            int marker_status = frame_marker ? -1 : 0;
            const int content_probe_capture =
                content_probe &&
                (frame < 3 || (frame % 30) == 0 ||
                 (!continuous && frame == total_frames - 1));
            struct ahb_content_probe_result content = {0};
            int checksum_status = metadata_pass
                                       ? checksum_ahardware_buffer(
                                             buffers[index], buffer_width,
                                             buffer_height, acquire_fence_fd,
                                             frame_marker, frame,
                                             content_probe_capture,
                                             content_probe_capture ? &content : NULL,
                                             &checksum, &marker_status)
                                       : -1;
            int identity_pass = metadata_pass && checksum_status == 0;
            if (content_probe && content_probe_capture) {
                if (checksum_status == 0) {
                    const uint64_t pixel_count = content.pixel_count;
                    append_line(
                        report, sizeof(report), &used,
                        "ahb_double_buffer_frame_content_%d=pass producer_frame=%llu desc=%ux%u stride=%u layers=%u format=0x%08x usage=0x%llx pixels=%llu raw_fnv1a64=%016llx rgba_min=%u,%u,%u,%u rgba_max=%u,%u,%u,%u rgba_avg_milli=%llu,%llu,%llu,%llu luma_min=%u luma_max=%u luma_avg_milli=%llu\n",
                        frame, (unsigned long long)producer_frame,
                        content.description_width, content.description_height,
                        content.description_stride, content.description_layers,
                        content.description_format,
                        (unsigned long long)content.description_usage,
                        (unsigned long long)pixel_count,
                        (unsigned long long)content.raw_checksum,
                        content.red_min, content.green_min, content.blue_min,
                        content.alpha_min, content.red_max, content.green_max,
                        content.blue_max, content.alpha_max,
                        (unsigned long long)(content.red_sum * 1000u /
                                             pixel_count),
                        (unsigned long long)(content.green_sum * 1000u /
                                             pixel_count),
                        (unsigned long long)(content.blue_sum * 1000u /
                                             pixel_count),
                        (unsigned long long)(content.alpha_sum * 1000u /
                                             pixel_count),
                        content.luma_min, content.luma_max,
                        (unsigned long long)(content.luma_sum * 1000u /
                                             pixel_count));
                } else {
                    append_line(report, sizeof(report), &used,
                                "ahb_double_buffer_frame_content_%d=fail checksum_status=%d\n",
                                frame, checksum_status);
                }
            }
            if (frame_identity) {
                append_line(
                    report, sizeof(report), &used,
                    "ahb_double_buffer_frame_identity_%d=%s producer_frame=%llu focus_commit=%llu override_commit=%llu checksum_fnv1a64=%016llx checksum_status=%d\n",
                    frame, identity_pass ? "pass" : "fail",
                    (unsigned long long)producer_frame,
                    (unsigned long long)focus_commit,
                    (unsigned long long)override_commit,
                    (unsigned long long)checksum, checksum_status);
            }
            if (frame_marker) {
                append_line(
                    report, sizeof(report), &used,
                    "ahb_double_buffer_frame_marker_%d=%s producer_frame=%llu checksum_low16=%04llx marker_status=%d checksum_status=%d\n",
                    frame,
                    identity_pass && marker_status == 0 ? "pass" : "fail",
                    (unsigned long long)producer_frame,
                    (unsigned long long)(checksum & 0xffffu), marker_status,
                    checksum_status);
            }
            if (!identity_pass || (frame_marker && marker_status != 0)) {
                if (acquire_fence_fd >= 0) {
                    close(acquire_fence_fd);
                }
                goto double_buffer_done;
            }
        }

        if (frame == 0 || (frame % 30) == 0) {
            __android_log_print(ANDROID_LOG_INFO, "NovaLab",
                                "ahb_double_buffer_frame_in_flight=%d", frame);
        }

        int previous_release_fence_fd = -1;
        int frame_pass = present_surface_frame(
            surface_control, buffers[index], acquire_fence_fd, buffer_width,
            buffer_height, destination_width, destination_height,
            &previous_release_fence_fd, report, sizeof(report), &used);
        acquire_fence_fd = -1;
        if (frame < 4 || (frame % 30) == 0) {
            __android_log_print(
                ANDROID_LOG_INFO, "NovaLab",
                "ahb_double_buffer_present_result frame=%d pass=%d previous_release=%d",
                frame, frame_pass, previous_release_fence_fd >= 0);
        }
        ahb_trace(frame, index, "surface_present", -1,
                  previous_release_fence_fd, frame_pass ? 0 : -1);
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
            int previous_index = (index + 2) % 3;
            int release_status = send_release_fence(
                clients[previous_index], frame, previous_index,
                previous_release_fence_fd);
            previous_release_fence_fd = -1;
            if (frame < 4 || (frame % 30) == 0 || release_status != 0) {
                __android_log_print(
                    ANDROID_LOG_INFO, "NovaLab",
                    "ahb_double_buffer_release_result frame=%d buffer=%d status=%d",
                    frame, previous_index, release_status);
            }
            ahb_trace(frame, previous_index, "release_sent", -1, -1,
                      release_status);
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
    success = !continuous && frame_count == total_frames &&
              release_fence_count == total_frames - 1;

double_buffer_done:
    if (cancel_registered) {
        ahb_bridge_unregister_cancel_pipe(cancel_pipe[0], cancel_pipe[1]);
    }
    if (cancel_pipe[0] >= 0) {
        close(cancel_pipe[0]);
    }
    if (cancel_pipe[1] >= 0) {
        close(cancel_pipe[1]);
    }
    if (surface_control != NULL) {
        ASurfaceControl_release(surface_control);
    }
    for (int index = 0; index < 3; ++index) {
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
    if (cancelled) {
        append_line(report, sizeof(report), &used,
                    "ahb_double_buffer_cancelled=pass\n");
    }
    append_line(report, sizeof(report), &used, "ahb_double_buffer=%s\n",
                success ? "pass" : "fail");
    return report_string(env, report);
}

JNIEXPORT void JNICALL
Java_com_xjsonderulo_steamandroid_novalab_MainActivity_nativeStopDmaBufDoubleBufferBridge(
    JNIEnv *env, jobject object)
{
    (void)env;
    (void)object;
    ahb_bridge_request_cancel();
}
