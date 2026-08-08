#define _DEFAULT_SOURCE
#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <fcntl.h>
#include <linux/input.h>
#include <linux/uinput.h>
#include <poll.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <unistd.h>

#define NOVA_GAMEPAD_NAME "Nova Virtual Xbox Controller"
#define NOVA_MAX_EVENT_NODES 64

static int bit_is_set(const unsigned long *bits, unsigned int bit)
{
    const unsigned int word_bits = sizeof(unsigned long) * 8u;
    return (bits[bit / word_bits] >> (bit % word_bits)) & 1u;
}

static int emit_event(int fd, unsigned short type, unsigned short code, int value)
{
    struct input_event event;
    memset(&event, 0, sizeof(event));
    gettimeofday(&event.time, NULL);
    event.type = type;
    event.code = code;
    event.value = value;
    return write(fd, &event, sizeof(event)) == (ssize_t)sizeof(event) ? 0 : -1;
}

static int emit_key(int fd, unsigned short code, int value)
{
    if (emit_event(fd, EV_KEY, code, value) != 0 ||
        emit_event(fd, EV_SYN, SYN_REPORT, 0) != 0) {
        return -1;
    }
    return 0;
}

static int parse_timeout(const char *text, unsigned int *timeout_ms)
{
    char *end = NULL;
    unsigned long value;

    errno = 0;
    value = strtoul(text, &end, 10);
    if (errno != 0 || end == text || *end != '\0' || value == 0 || value > 3600000u) {
        return -1;
    }
    *timeout_ms = (unsigned int)value;
    return 0;
}

static int configure_from_source(int uinput_fd, int source_fd)
{
    unsigned long key_bits[KEY_MAX / (sizeof(unsigned long) * 8u) + 1u];
    unsigned long abs_bits[ABS_MAX / (sizeof(unsigned long) * 8u) + 1u];

    memset(key_bits, 0, sizeof(key_bits));
    memset(abs_bits, 0, sizeof(abs_bits));
    if (ioctl(source_fd, EVIOCGBIT(EV_KEY, sizeof(key_bits)), key_bits) < 0 ||
        ioctl(source_fd, EVIOCGBIT(EV_ABS, sizeof(abs_bits)), abs_bits) < 0) {
        return -1;
    }

    if (ioctl(uinput_fd, UI_SET_EVBIT, EV_SYN) != 0 ||
        ioctl(uinput_fd, UI_SET_EVBIT, EV_KEY) != 0 ||
        ioctl(uinput_fd, UI_SET_EVBIT, EV_ABS) != 0) {
        return -1;
    }

    for (unsigned int code = 0; code <= KEY_MAX; code++) {
        if (bit_is_set(key_bits, code) && ioctl(uinput_fd, UI_SET_KEYBIT, code) != 0) {
            return -1;
        }
    }
    const unsigned short common_gamepad_keys[] = {
        BTN_MISC, BTN_GAMEPAD, BTN_SOUTH, BTN_EAST, BTN_NORTH, BTN_WEST,
        BTN_TL, BTN_TR, BTN_TL2, BTN_TR2, BTN_SELECT, BTN_START, BTN_MODE,
        BTN_THUMBL, BTN_THUMBR, BTN_DPAD_UP, BTN_DPAD_DOWN,
        BTN_DPAD_LEFT, BTN_DPAD_RIGHT,
    };
    for (size_t index = 0;
         index < sizeof(common_gamepad_keys) / sizeof(common_gamepad_keys[0]);
         index++) {
        if (ioctl(uinput_fd, UI_SET_KEYBIT, common_gamepad_keys[index]) != 0) {
            return -1;
        }
    }
    for (unsigned int code = 0; code <= ABS_MAX; code++) {
        if (!bit_is_set(abs_bits, code)) {
            continue;
        }
        if (ioctl(uinput_fd, UI_SET_ABSBIT, code) != 0) {
            return -1;
        }
    }

    /* The physical controller already exposes the correct Xbox-style ranges. */
    struct uinput_user_dev device;
    memset(&device, 0, sizeof(device));
    snprintf(device.name, UINPUT_MAX_NAME_SIZE, "%s", NOVA_GAMEPAD_NAME);
    device.id.bustype = BUS_USB;
    device.id.vendor = 0x045e;
    device.id.product = 0x028e;
    device.id.version = 1;
    for (unsigned int code = 0; code <= ABS_MAX; code++) {
        if (!bit_is_set(abs_bits, code)) {
            continue;
        }
        struct input_absinfo info;
        memset(&info, 0, sizeof(info));
        if (ioctl(source_fd, EVIOCGABS(code), &info) != 0) {
            return -1;
        }
        device.absmin[code] = info.minimum;
        device.absmax[code] = info.maximum;
        device.absfuzz[code] = info.fuzz;
        device.absflat[code] = info.flat;
        device.absmax[code] = info.maximum;
    }
    return write(uinput_fd, &device, sizeof(device)) == (ssize_t)sizeof(device) ? 0 : -1;
}

static int find_virtual_event(char *path, size_t path_size)
{
    for (unsigned int index = 0; index < NOVA_MAX_EVENT_NODES; index++) {
        char candidate[64];
        char name[UINPUT_MAX_NAME_SIZE];
        int fd;

        snprintf(candidate, sizeof(candidate), "/dev/input/event%u", index);
        fd = open(candidate, O_RDONLY | O_NONBLOCK);
        if (fd < 0) {
            continue;
        }
        memset(name, 0, sizeof(name));
        if (ioctl(fd, EVIOCGNAME(sizeof(name)), name) >= 0 &&
            strcmp(name, NOVA_GAMEPAD_NAME) == 0) {
            snprintf(path, path_size, "%s", candidate);
            close(fd);
            return 0;
        }
        close(fd);
    }
    return -1;
}

static void drain_virtual(int fd, unsigned short expected_code,
                          int *saw_down, int *saw_up)
{
    struct input_event event;
    ssize_t count;

    while ((count = read(fd, &event, sizeof(event))) == (ssize_t)sizeof(event)) {
        if (event.type == EV_KEY && event.code == expected_code) {
            if (event.value == 1) {
                *saw_down = 1;
            } else if (event.value == 0) {
                *saw_up = 1;
            }
        }
    }
}

static int wait_for_key_echo(int virtual_fd, unsigned short code, unsigned int timeout_ms)
{
    struct pollfd poll_fd = {.fd = virtual_fd, .events = POLLIN};
    int saw_down = 0;
    int saw_up = 0;
    unsigned int elapsed = 0;

    while (elapsed < timeout_ms && (!saw_down || !saw_up)) {
        int wait_ms = (int)(timeout_ms - elapsed);
        if (wait_ms > 100) {
            wait_ms = 100;
        }
        int status = poll(&poll_fd, 1, wait_ms);
        if (status < 0 && errno == EINTR) {
            continue;
        }
        if (status < 0) {
            return -1;
        }
        if (status > 0 && (poll_fd.revents & POLLIN) != 0) {
            drain_virtual(virtual_fd, code, &saw_down, &saw_up);
        }
        elapsed += (unsigned int)wait_ms;
    }
    return saw_down && saw_up ? 0 : -1;
}

static int forward_source_event(int uinput_fd, const struct input_event *event)
{
    switch (event->type) {
    case EV_KEY:
    case EV_ABS:
    case EV_SYN:
        return write(uinput_fd, event, sizeof(*event)) == (ssize_t)sizeof(*event) ? 0 : -1;
    default:
        return 0;
    }
}

int main(int argc, char **argv)
{
    const char *source_path = argc > 1 ? argv[1] : "/dev/input/event7";
    const char *mode = argc > 3 ? argv[3] : "self-test";
    unsigned int timeout_ms = 5000;
    char source_name[256];
    char virtual_path[64];
    int source_fd = -1;
    int uinput_fd = -1;
    int virtual_fd = -1;
    int status = 1;

    if (argc > 2 && parse_timeout(argv[2], &timeout_ms) != 0) {
        fprintf(stderr, "uinput_error=invalid_timeout\n");
        return 2;
    }
    if (strcmp(source_path, "none") != 0) {
        source_fd = open(source_path, O_RDONLY | O_NONBLOCK);
        if (source_fd < 0) {
            fprintf(stderr, "uinput_error=open_source errno=%d\n", errno);
            return 1;
        }
        memset(source_name, 0, sizeof(source_name));
        if (ioctl(source_fd, EVIOCGNAME(sizeof(source_name)), source_name) < 0) {
            fprintf(stderr, "uinput_error=source_name errno=%d\n", errno);
            goto cleanup;
        }
        printf("uinput_source=%s\n", source_path);
        printf("uinput_source_name=%s\n", source_name);
    } else {
        snprintf(source_name, sizeof(source_name), "synthetic");
        printf("uinput_source=none\n");
        printf("uinput_source_name=%s\n", source_name);
    }
    fflush(stdout);

    uinput_fd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
    if (uinput_fd < 0) {
        fprintf(stderr, "uinput_error=open_uinput errno=%d\n", errno);
        goto cleanup;
    }
    if (source_fd < 0 || configure_from_source(uinput_fd, source_fd) != 0) {
        fprintf(stderr, "uinput_error=configure_device errno=%d\n", errno);
        goto cleanup;
    }
    if (ioctl(uinput_fd, UI_DEV_CREATE) != 0) {
        fprintf(stderr, "uinput_error=create_device errno=%d\n", errno);
        goto cleanup;
    }
    printf("uinput_open=pass\n");
    fflush(stdout);
    usleep(150000);

    if (find_virtual_event(virtual_path, sizeof(virtual_path)) != 0) {
        fprintf(stderr, "uinput_error=find_virtual_event errno=%d\n", errno);
        goto cleanup;
    }
    virtual_fd = open(virtual_path, O_RDONLY | O_NONBLOCK);
    if (virtual_fd < 0) {
        fprintf(stderr, "uinput_error=open_virtual_event errno=%d\n", errno);
        goto cleanup;
    }
    if (chmod(virtual_path, 0666) == 0) {
        printf("uinput_device_permissions=pass\n");
    }
    printf("uinput_device=%s\n", virtual_path);
    printf("uinput_device_ready=pass\n");
    fflush(stdout);

    if (strcmp(mode, "self-test") == 0 || strcmp(mode, "send-east") == 0) {
        unsigned short code = BTN_EAST;
        if (emit_key(uinput_fd, code, 1) != 0) {
            fprintf(stderr, "uinput_error=send_key_down errno=%d\n", errno);
            goto cleanup;
        }
        usleep(50000);
        if (emit_key(uinput_fd, code, 0) != 0) {
            fprintf(stderr, "uinput_error=send_key_up errno=%d\n", errno);
            goto cleanup;
        }
        if (wait_for_key_echo(virtual_fd, code, 1000) != 0) {
            fprintf(stderr, "uinput_error=key_echo_timeout\n");
            goto cleanup;
        }
        if (strcmp(mode, "send-east") == 0) {
            printf("uinput_action=btn_east\n");
        } else {
            printf("uinput_self_test=pass\n");
        }
        fflush(stdout);
    } else if (strcmp(mode, "none") != 0 && strcmp(mode, "relay") != 0) {
        fprintf(stderr, "uinput_error=unknown_mode\n");
        goto cleanup;
    }

    printf("uinput_relay=begin\n");
    fflush(stdout);
    struct pollfd fds[2];
    unsigned int elapsed = 0;
    int forwarded = 0;
    while (elapsed < timeout_ms) {
        int count = 0;
        if (source_fd >= 0) {
            fds[count++] = (struct pollfd){.fd = source_fd, .events = POLLIN};
        }
        fds[count++] = (struct pollfd){.fd = virtual_fd, .events = POLLIN};
        int wait_ms = (int)(timeout_ms - elapsed);
        if (wait_ms > 100) {
            wait_ms = 100;
        }
        int poll_status = poll(fds, (nfds_t)count, wait_ms);
        if (poll_status < 0 && errno == EINTR) {
            continue;
        }
        if (poll_status < 0) {
            fprintf(stderr, "uinput_error=poll errno=%d\n", errno);
            goto cleanup;
        }
        int position = 0;
        if (source_fd >= 0) {
            if ((fds[position].revents & POLLIN) != 0) {
                struct input_event event;
                ssize_t bytes;
                while ((bytes = read(source_fd, &event, sizeof(event))) == (ssize_t)sizeof(event)) {
                    if (forward_source_event(uinput_fd, &event) != 0) {
                        fprintf(stderr, "uinput_error=forward errno=%d\n", errno);
                        goto cleanup;
                    }
                    if (event.type == EV_KEY || event.type == EV_ABS) {
                        forwarded = 1;
                    }
                }
            }
            position++;
        }
        if ((fds[position].revents & POLLIN) != 0) {
            int ignored_down = 0;
            int ignored_up = 0;
            drain_virtual(virtual_fd, BTN_SOUTH, &ignored_down, &ignored_up);
        }
        elapsed += (unsigned int)wait_ms;
    }
    if (forwarded) {
        printf("uinput_event_forwarded=pass\n");
    } else {
        printf("uinput_event_forwarded=none\n");
    }
    printf("uinput_relay=end\n");
    printf("uinput_probe=pass\n");
    fflush(stdout);
    status = 0;

cleanup:
    if (virtual_fd >= 0) {
        close(virtual_fd);
    }
    if (uinput_fd >= 0) {
        ioctl(uinput_fd, UI_DEV_DESTROY);
        close(uinput_fd);
    }
    if (source_fd >= 0) {
        close(source_fd);
    }
    return status;
}
