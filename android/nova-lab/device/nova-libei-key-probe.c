#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <linux/input-event-codes.h>
#include <poll.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#include <libei.h>

static uint64_t monotonic_milliseconds(void)
{
    struct timespec now;
    if (clock_gettime(CLOCK_MONOTONIC, &now) != 0) {
        return 0;
    }
    return (uint64_t)now.tv_sec * 1000u + (uint64_t)now.tv_nsec / 1000000u;
}

static void marker(const char *name)
{
    printf("%s\n", name);
    fflush(stdout);
}

static void marker_value(const char *name, unsigned long value)
{
    printf("%s=%lu\n", name, value);
    fflush(stdout);
}

int main(int argc, char **argv)
{
    const char *socket_path = argc > 1 ? argv[1] : getenv("LIBEI_SOCKET");
    unsigned long keycode = KEY_ENTER;
    unsigned long timeout_ms = 15000;
    char *end = NULL;

    if (socket_path == NULL || *socket_path == '\0') {
        fprintf(stderr, "libei_error=missing_socket\n");
        return 2;
    }
    if (argc > 2) {
        errno = 0;
        keycode = strtoul(argv[2], &end, 10);
        if (errno != 0 || end == argv[2] || *end != '\0' || keycode > UINT32_MAX) {
            fprintf(stderr, "libei_error=invalid_keycode\n");
            return 2;
        }
    }
    if (argc > 3) {
        errno = 0;
        timeout_ms = strtoul(argv[3], &end, 10);
        if (errno != 0 || end == argv[3] || *end != '\0' || timeout_ms == 0) {
            fprintf(stderr, "libei_error=invalid_timeout\n");
            return 2;
        }
    }

    printf("libei_socket=%s\n", socket_path);
    marker_value("libei_keycode", keycode);
    fflush(stdout);

    struct ei *context = ei_new_sender(NULL);
    if (context == NULL) {
        fprintf(stderr, "libei_error=create_sender\n");
        return 1;
    }
    if (ei_setup_backend_socket(context, socket_path) != 0) {
        fprintf(stderr, "libei_error=connect errno=%d\n", errno);
        ei_unref(context);
        return 1;
    }

    int fd = ei_get_fd(context);
    if (fd < 0) {
        fprintf(stderr, "libei_error=invalid_fd\n");
        ei_unref(context);
        return 1;
    }

    struct ei_device *keyboard = NULL;
    struct ei_ping *pending_ping = NULL;
    uint32_t sequence = 0;
    int key_sent = 0;
    int roundtrip_complete = 0;
    uint64_t deadline = monotonic_milliseconds() + timeout_ms;

    while (!roundtrip_complete) {
        uint64_t now = monotonic_milliseconds();
        if (now >= deadline) {
            fprintf(stderr, "libei_error=timeout key_sent=%d\n", key_sent);
            break;
        }
        int wait_ms = (int)(deadline - now);
        if (wait_ms > 500) {
            wait_ms = 500;
        }

        struct pollfd poll_fd = {.fd = fd, .events = POLLIN};
        int poll_status = poll(&poll_fd, 1, wait_ms);
        if (poll_status < 0) {
            if (errno == EINTR) {
                continue;
            }
            fprintf(stderr, "libei_error=poll errno=%d\n", errno);
            break;
        }
        if (poll_status == 0) {
            continue;
        }
        if ((poll_fd.revents & (POLLERR | POLLHUP | POLLNVAL)) != 0) {
            fprintf(stderr, "libei_error=socket_events revents=0x%x\n", poll_fd.revents);
            break;
        }

        ei_dispatch(context);
        struct ei_event *event = NULL;
        while ((event = ei_get_event(context)) != NULL) {
            enum ei_event_type type = ei_event_get_type(event);
            switch (type) {
            case EI_EVENT_CONNECT:
                marker("libei_connect=pass");
                break;
            case EI_EVENT_SEAT_ADDED: {
                struct ei_seat *seat = ei_event_get_seat(event);
                if (seat != NULL && ei_seat_has_capability(seat, EI_DEVICE_CAP_KEYBOARD)) {
                    ei_seat_bind_capabilities(seat, EI_DEVICE_CAP_KEYBOARD, NULL);
                    marker("libei_keyboard_seat=pass");
                }
                break;
            }
            case EI_EVENT_DEVICE_ADDED: {
                struct ei_device *device = ei_event_get_device(event);
                if (device != NULL &&
                    ei_device_has_capability(device, EI_DEVICE_CAP_KEYBOARD) &&
                    keyboard == NULL) {
                    keyboard = ei_device_ref(device);
                    marker("libei_keyboard_device=pass");
                }
                break;
            }
            case EI_EVENT_DEVICE_RESUMED: {
                struct ei_device *device = ei_event_get_device(event);
                if (!key_sent && device != NULL &&
                    ei_device_has_capability(device, EI_DEVICE_CAP_KEYBOARD)) {
                    if (keyboard == NULL) {
                        keyboard = ei_device_ref(device);
                    }
                    ei_device_start_emulating(device, ++sequence);
                    marker("libei_device_resumed=pass");
                    ei_device_keyboard_key(device, (uint32_t)keycode, true);
                    ei_device_keyboard_key(device, (uint32_t)keycode, false);
                    ei_device_frame(device, ei_now(context));
                    key_sent = 1;
                    marker("libei_key_sent=pass");
                    pending_ping = ei_new_ping(context);
                    if (pending_ping == NULL) {
                        fprintf(stderr, "libei_error=create_ping\n");
                    } else {
                        ei_ping(pending_ping);
                    }
                }
                break;
            }
            case EI_EVENT_PONG:
                if (pending_ping == NULL || ei_event_pong_get_ping(event) == pending_ping) {
                    roundtrip_complete = 1;
                    marker("libei_roundtrip=pass");
                }
                break;
            case EI_EVENT_DISCONNECT:
                fprintf(stderr, "libei_error=server_disconnect\n");
                roundtrip_complete = 1;
                break;
            default:
                break;
            }
            ei_event_unref(event);
        }
    }

    if (pending_ping != NULL) {
        ei_ping_unref(pending_ping);
    }
    if (keyboard != NULL) {
        if (key_sent) {
            ei_device_stop_emulating(keyboard);
        }
        ei_device_close(keyboard);
        ei_device_unref(keyboard);
    }
    ei_unref(context);

    if (!key_sent || !roundtrip_complete) {
        return 1;
    }
    marker("libei_probe=pass");
    return 0;
}
