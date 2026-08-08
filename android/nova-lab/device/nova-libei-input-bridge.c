#define _DEFAULT_SOURCE
#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <libei.h>
#include <poll.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <time.h>
#include <unistd.h>

#define NOVA_EI_REGION_SIZE 2147483647.0

struct active_touch {
    struct ei_touch *touch;
    int pointer_id;
};

static uint64_t monotonic_milliseconds(void)
{
    struct timespec now;
    if (clock_gettime(CLOCK_MONOTONIC, &now) != 0) {
        return 0;
    }
    return (uint64_t)now.tv_sec * 1000u +
           (uint64_t)now.tv_nsec / 1000000u;
}

static void marker(const char *name)
{
    printf("%s\n", name);
    fflush(stdout);
}

static int parse_timeout(const char *text, uint64_t *timeout_ms)
{
    char *end = NULL;
    unsigned long long value;

    errno = 0;
    value = strtoull(text, &end, 10);
    if (errno != 0 || end == text || *end != '\0' || value == 0) {
        return -1;
    }
    *timeout_ms = (uint64_t)value;
    return 0;
}

static int connect_unix_socket(const char *path)
{
    struct sockaddr_un address;
    const int abstract = path[0] == '@';
    const char *name = abstract ? path + 1 : path;
    size_t length = strlen(name);
    int fd;

    if (length >= sizeof(address.sun_path) - (abstract ? 1u : 0u)) {
        errno = ENAMETOOLONG;
        return -1;
    }
    fd = socket(AF_UNIX, SOCK_STREAM | SOCK_CLOEXEC, 0);
    if (fd < 0) {
        return -1;
    }
    memset(&address, 0, sizeof(address));
    address.sun_family = AF_UNIX;
    if (abstract) {
        memcpy(address.sun_path + 1, name, length);
    } else {
        memcpy(address.sun_path, name, length + 1);
    }
    socklen_t address_length = abstract
        ? (socklen_t)(offsetof(struct sockaddr_un, sun_path) + 1u + length)
        : (socklen_t)sizeof(address);
    if (connect(fd, (struct sockaddr *)&address, address_length) != 0) {
        close(fd);
        return -1;
    }
    return fd;
}

static int connect_unix_socket_retry(const char *path, uint64_t deadline)
{
    while (monotonic_milliseconds() < deadline) {
        int fd = connect_unix_socket(path);
        if (fd >= 0) {
            return fd;
        }
        if (errno != ENOENT && errno != ECONNREFUSED && errno != EAGAIN) {
            break;
        }
        usleep(100000);
    }
    return -1;
}

static int send_touch(struct ei *context, struct ei_device *device,
                      struct active_touch *active, int action, int pointer_id,
                      double normalized_x, double normalized_y,
                      int *down_sent, int *up_sent)
{
    if (device == NULL) {
        return 0;
    }
    double x = normalized_x * NOVA_EI_REGION_SIZE;
    double y = normalized_y * NOVA_EI_REGION_SIZE;
    if (x < 0.0) {
        x = 0.0;
    }
    if (y < 0.0) {
        y = 0.0;
    }
    if (x > NOVA_EI_REGION_SIZE) {
        x = NOVA_EI_REGION_SIZE;
    }
    if (y > NOVA_EI_REGION_SIZE) {
        y = NOVA_EI_REGION_SIZE;
    }

    if (action == 0) {
        if (active->touch != NULL) {
            ei_touch_cancel(active->touch);
            ei_touch_unref(active->touch);
            active->touch = NULL;
        }
        active->touch = ei_device_touch_new(device);
        if (active->touch == NULL) {
            fprintf(stderr, "libei_error=touch_new\n");
            return -1;
        }
        active->pointer_id = pointer_id;
        ei_touch_down(active->touch, x, y);
        *down_sent = 1;
        printf("libei_touch_down_sent=pass pointer=%d x=%.5f y=%.5f\n",
               pointer_id, normalized_x, normalized_y);
    } else if (action == 1) {
        if (active->touch == NULL || active->pointer_id != pointer_id) {
            return 0;
        }
        ei_touch_motion(active->touch, x, y);
        printf("libei_touch_motion_sent=pass pointer=%d x=%.5f y=%.5f\n",
               pointer_id, normalized_x, normalized_y);
    } else if (action == 2 || action == 3) {
        if (active->touch == NULL || active->pointer_id != pointer_id) {
            return 0;
        }
        if (action == 3) {
            ei_touch_cancel(active->touch);
        } else {
            ei_touch_up(active->touch);
        }
        ei_touch_unref(active->touch);
        active->touch = NULL;
        *up_sent = 1;
        printf("libei_touch_%s_sent=pass pointer=%d\n",
               action == 3 ? "cancel" : "up", pointer_id);
    } else {
        return 0;
    }
    ei_device_frame(device, ei_now(context));
    fflush(stdout);
    return 0;
}

static int consume_app_input(struct ei *context, struct ei_device *device,
                             struct active_touch *active, int app_fd,
                             char *buffer, size_t *used, size_t capacity,
                             int *down_sent, int *up_sent)
{
    char incoming[512];
    ssize_t count = read(app_fd, incoming, sizeof(incoming));
    if (count == 0) {
        return 1;
    }
    if (count < 0) {
        if (errno == EINTR || errno == EAGAIN || errno == EWOULDBLOCK) {
            return 0;
        }
        return -1;
    }
    if ((size_t)count >= capacity - *used) {
        fprintf(stderr, "libei_error=touch_input_buffer_overflow\n");
        return -1;
    }
    memcpy(buffer + *used, incoming, (size_t)count);
    *used += (size_t)count;
    buffer[*used] = '\0';

    char *line = buffer;
    char *newline;
    while ((newline = strchr(line, '\n')) != NULL) {
        int action;
        int pointer_id;
        double x;
        double y;
        *newline = '\0';
        if (sscanf(line, "T %d %d %lf %lf", &action, &pointer_id, &x, &y) == 4) {
            printf("android_touch_event_received action=%d pointer=%d x=%.5f y=%.5f\n",
                   action, pointer_id, x, y);
            if (send_touch(context, device, active, action, pointer_id, x, y,
                           down_sent, up_sent) != 0) {
                return -1;
            }
        }
        line = newline + 1;
        *used -= (size_t)(line - buffer);
    }
    if (line != buffer) {
        memmove(buffer, line, *used);
        buffer[*used] = '\0';
    }
    fflush(stdout);
    return 0;
}

int main(int argc, char **argv)
{
    const char *eis_socket = argc > 1 ? argv[1] : getenv("LIBEI_SOCKET");
    const char *app_socket = argc > 2 ? argv[2] : getenv("NOVA_TOUCH_SOCKET");
    uint64_t timeout_ms = 60000;
    char *end = NULL;

    if (eis_socket == NULL || *eis_socket == '\0' ||
        app_socket == NULL || *app_socket == '\0') {
        fprintf(stderr, "libei_error=missing_socket\n");
        return 2;
    }
    if (argc > 3) {
        if (parse_timeout(argv[3], &timeout_ms) != 0) {
            fprintf(stderr, "libei_error=invalid_timeout\n");
            return 2;
        }
    }
    (void)end;
    printf("libei_socket=%s\n", eis_socket);
    printf("android_touch_socket=%s\n", app_socket);
    fflush(stdout);

    struct ei *context = ei_new_sender(NULL);
    if (context == NULL) {
        fprintf(stderr, "libei_error=create_sender\n");
        return 1;
    }
    uint64_t deadline = monotonic_milliseconds() + timeout_ms;
    if (ei_setup_backend_socket(context, eis_socket) != 0) {
        fprintf(stderr, "libei_error=connect errno=%d\n", errno);
        ei_unref(context);
        return 1;
    }
    int eis_fd = ei_get_fd(context);
    if (eis_fd < 0) {
        fprintf(stderr, "libei_error=invalid_eis_fd\n");
        ei_unref(context);
        return 1;
    }
    int app_fd = connect_unix_socket_retry(app_socket, deadline);
    if (app_fd < 0) {
        fprintf(stderr, "libei_error=connect_touch_socket errno=%d\n", errno);
        ei_unref(context);
        return 1;
    }
    marker("android_touch_socket_connected=pass");

    struct ei_device *device = NULL;
    struct ei_ping *pending_ping = NULL;
    struct active_touch active = {0};
    uint32_t sequence = 0;
    int down_sent = 0;
    int up_sent = 0;
    int roundtrip_complete = 0;
    int status = 1;
    char input_buffer[4096] = {0};
    size_t input_used = 0;

    while (monotonic_milliseconds() < deadline && !roundtrip_complete) {
        struct pollfd fds[2] = {
            {.fd = eis_fd, .events = POLLIN},
            {.fd = app_fd, .events = POLLIN},
        };
        uint64_t remaining = deadline - monotonic_milliseconds();
        int wait_ms = remaining > 500 ? 500 : (int)remaining;
        int poll_status = poll(fds, 2, wait_ms);
        if (poll_status < 0) {
            if (errno == EINTR) {
                continue;
            }
            fprintf(stderr, "libei_error=poll errno=%d\n", errno);
            break;
        }
        if ((fds[0].revents & (POLLIN | POLLERR | POLLHUP)) != 0) {
            ei_dispatch(context);
            struct ei_event *event;
            while ((event = ei_get_event(context)) != NULL) {
                enum ei_event_type type = ei_event_get_type(event);
                if (type == EI_EVENT_CONNECT) {
                    marker("libei_connect=pass");
                } else if (type == EI_EVENT_SEAT_ADDED) {
                    struct ei_seat *seat = ei_event_get_seat(event);
                    if (seat != NULL &&
                        ei_seat_has_capability(seat, EI_DEVICE_CAP_TOUCH)) {
                        ei_seat_bind_capabilities(seat, EI_DEVICE_CAP_TOUCH, NULL);
                        marker("libei_touch_seat=pass");
                    }
                } else if (type == EI_EVENT_DEVICE_ADDED) {
                    struct ei_device *candidate = ei_event_get_device(event);
                    if (candidate != NULL && device == NULL &&
                        ei_device_has_capability(candidate, EI_DEVICE_CAP_TOUCH)) {
                        device = ei_device_ref(candidate);
                        marker("libei_touch_device=pass");
                    }
                } else if (type == EI_EVENT_DEVICE_RESUMED) {
                    struct ei_device *resumed = ei_event_get_device(event);
                    if (resumed != NULL &&
                        ei_device_has_capability(resumed, EI_DEVICE_CAP_TOUCH) &&
                        device == NULL) {
                        device = ei_device_ref(resumed);
                    }
                    if (resumed != NULL && device == resumed) {
                        ei_device_start_emulating(resumed, ++sequence);
                        marker("libei_touch_device_resumed=pass");
                    }
                } else if (type == EI_EVENT_PONG) {
                    if (pending_ping == NULL ||
                        ei_event_pong_get_ping(event) == pending_ping) {
                        roundtrip_complete = 1;
                        marker("libei_touch_roundtrip=pass");
                    }
                } else if (type == EI_EVENT_DISCONNECT) {
                    fprintf(stderr, "libei_error=server_disconnect\n");
                    roundtrip_complete = 1;
                }
                ei_event_unref(event);
            }
        }
        if ((fds[1].revents & (POLLIN | POLLHUP | POLLERR)) != 0) {
            int consume_status = consume_app_input(
                context, device, &active, app_fd, input_buffer, &input_used,
                sizeof(input_buffer), &down_sent, &up_sent);
            if (consume_status < 0) {
                break;
            }
            if (consume_status > 0 && up_sent) {
                break;
            }
            if (up_sent && pending_ping == NULL) {
                pending_ping = ei_new_ping(context);
                if (pending_ping != NULL) {
                    ei_ping(pending_ping);
                }
            }
        }
    }

    if (active.touch != NULL) {
        ei_touch_cancel(active.touch);
        ei_touch_unref(active.touch);
    }
    if (pending_ping != NULL) {
        ei_ping_unref(pending_ping);
    }
    if (device != NULL) {
        if (down_sent) {
            ei_device_stop_emulating(device);
        }
        ei_device_close(device);
        ei_device_unref(device);
    }
    close(app_fd);
    ei_unref(context);

    if (down_sent && up_sent) {
        marker("android_touch_forwarded=pass");
        if (roundtrip_complete) {
            marker("libei_touch_probe=pass");
            status = 0;
        }
    }
    return status;
}
