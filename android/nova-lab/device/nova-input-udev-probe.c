#define _GNU_SOURCE
#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <fcntl.h>
#include <linux/input.h>
#include <libudev.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/wait.h>
#include <unistd.h>

#define NOVA_MAX_EVENT_NODES 64
#define NOVA_STEAM_UID 501

static int read_input_name(const char *path, char *name, size_t name_size)
{
    int fd = open(path, O_RDONLY | O_NONBLOCK);
    if (fd < 0) {
        return -1;
    }
    memset(name, 0, name_size);
    int status = ioctl(fd, EVIOCGNAME((int)name_size), name);
    close(fd);
    return status < 0 ? -1 : 0;
}

static int find_input_name(const char *expected, char *path, size_t path_size)
{
    char candidate[64];
    char name[256];

    for (unsigned int index = 0; index < NOVA_MAX_EVENT_NODES; index++) {
        snprintf(candidate, sizeof(candidate), "/dev/input/event%u", index);
        if (read_input_name(candidate, name, sizeof(name)) == 0 &&
            strcmp(name, expected) == 0) {
            snprintf(path, path_size, "%s", candidate);
            return 0;
        }
    }
    return -1;
}

static int open_as_steam(const char *path)
{
    pid_t child = fork();
    if (child < 0) {
        return -1;
    }
    if (child == 0) {
        int fd;
        if (setgid(NOVA_STEAM_UID) != 0 || setuid(NOVA_STEAM_UID) != 0) {
            _exit(110);
        }
        fd = open(path, O_RDONLY | O_NONBLOCK);
        if (fd < 0) {
            _exit(errno == EACCES ? 13 : 111);
        }
        close(fd);
        _exit(0);
    }

    int child_status = 0;
    if (waitpid(child, &child_status, 0) != child || !WIFEXITED(child_status)) {
        return -1;
    }
    return WEXITSTATUS(child_status) == 0 ? 0 : -1;
}

int main(int argc, char **argv)
{
    const char *expected_name = argc > 1 ? argv[1] : "Nova Virtual Xbox Controller";
    const char *target_path = argc > 2 ? argv[2] : NULL;
    struct udev *udev = NULL;
    struct udev_enumerate *enumerate = NULL;
    struct udev_list_entry *entry;
    struct udev_list_entry *first_entry;
    char discovered_path[64] = {0};
    char ioctl_name[256] = {0};
    unsigned int event_devices = 0;
    int discovered = 0;
    int status = 1;

    printf("udev_probe_begin\n");
    fflush(stdout);
    udev = udev_new();
    if (udev == NULL) {
        fprintf(stderr, "udev_error=context\n");
        return 1;
    }
    printf("udev_context=pass\n");

    enumerate = udev_enumerate_new(udev);
    if (enumerate == NULL ||
        udev_enumerate_add_match_subsystem(enumerate, "input") != 0 ||
        udev_enumerate_scan_devices(enumerate) != 0) {
        fprintf(stderr, "udev_error=enumerate\n");
        goto cleanup;
    }

    first_entry = udev_enumerate_get_list_entry(enumerate);
    udev_list_entry_foreach(entry, first_entry) {
        const char *syspath = udev_list_entry_get_name(entry);
        struct udev_device *device;
        const char *sysname;
        const char *devnode;
        const char *name;
        const char *id_input_joystick;
        const char *id_input_gamepad;
        const char *id_vendor;
        const char *id_model;
        const char *sys_vendor;
        const char *sys_product;
        struct udev_device *parent;

        if (syspath == NULL) {
            continue;
        }
        device = udev_device_new_from_syspath(udev, syspath);
        if (device == NULL) {
            continue;
        }
        sysname = udev_device_get_sysname(device);
        if (sysname != NULL && strncmp(sysname, "event", 5) == 0) {
            event_devices++;
        }
        devnode = udev_device_get_devnode(device);
        parent = udev_device_get_parent(device);
        name = parent == NULL ? NULL : udev_device_get_sysattr_value(parent, "name");
        if (sysname != NULL && name != NULL && strcmp(name, expected_name) == 0) {
            id_input_joystick = udev_device_get_property_value(device, "ID_INPUT_JOYSTICK");
            id_input_gamepad = udev_device_get_property_value(device, "ID_INPUT_GAMEPAD");
            id_vendor = udev_device_get_property_value(device, "ID_VENDOR_ID");
            id_model = udev_device_get_property_value(device, "ID_MODEL_ID");
            sys_vendor = parent == NULL ? NULL : udev_device_get_sysattr_value(parent, "id/vendor");
            sys_product = parent == NULL ? NULL : udev_device_get_sysattr_value(parent, "id/product");
            snprintf(discovered_path, sizeof(discovered_path), "/dev/input/%s", sysname);
            discovered = 1;
            printf("udev_virtual_sysfs=pass\n");
            printf("udev_virtual_sysname=%s\n", sysname);
            printf("udev_virtual_devnode=%s\n", devnode != NULL ? devnode : "missing");
            printf("udev_virtual_name=%s\n", name);
            printf("udev_virtual_id_input_joystick=%s\n",
                   id_input_joystick != NULL ? id_input_joystick : "missing");
            printf("udev_virtual_id_input_gamepad=%s\n",
                   id_input_gamepad != NULL ? id_input_gamepad : "missing");
            printf("udev_virtual_id_vendor_id=%s\n",
                   id_vendor != NULL ? id_vendor : "missing");
            printf("udev_virtual_id_model_id=%s\n",
                   id_model != NULL ? id_model : "missing");
            printf("udev_virtual_sysfs_vendor=%s\n",
                   sys_vendor != NULL ? sys_vendor : "missing");
            printf("udev_virtual_sysfs_product=%s\n",
                   sys_product != NULL ? sys_product : "missing");
            printf("udev_virtual_properties=%s\n",
                   id_input_joystick != NULL || id_input_gamepad != NULL ||
                           id_vendor != NULL || id_model != NULL ? "present" : "missing");
        }
        udev_device_unref(device);
    }
    printf("udev_input_event_devices=%u\n", event_devices);

    if (!discovered && find_input_name(expected_name, discovered_path,
                                       sizeof(discovered_path)) == 0) {
        printf("udev_virtual_sysfs=not-found\n");
        printf("udev_virtual_devnode=%s\n", discovered_path);
        fprintf(stderr, "udev_error=sysfs_device_name_not_discoverable\n");
        goto cleanup;
    }
    if (!discovered && discovered_path[0] == '\0') {
        fprintf(stderr, "udev_error=virtual_device_not_discoverable\n");
        goto cleanup;
    }
    printf("udev_virtual_discoverable=pass\n");

    if (target_path == NULL || *target_path == '\0') {
        target_path = discovered_path;
    }
    if (read_input_name(target_path, ioctl_name, sizeof(ioctl_name)) != 0) {
        fprintf(stderr, "udev_error=ioctl_name errno=%d\n", errno);
        goto cleanup;
    }
    printf("input_ioctl_path=%s\n", target_path);
    printf("input_ioctl_name=%s\n", ioctl_name);
    if (strcmp(ioctl_name, expected_name) != 0) {
        fprintf(stderr, "udev_error=unexpected_input_name\n");
        goto cleanup;
    }
    printf("input_ioctl_name=pass\n");

    printf("input_nonroot_uid=%d\n", NOVA_STEAM_UID);
    if (open_as_steam(target_path) != 0) {
        fprintf(stderr, "udev_error=nonroot_open errno=%d\n", errno);
        goto cleanup;
    }
    printf("input_nonroot_open=pass\n");
    printf("udev_probe=pass\n");
    fflush(stdout);
    status = 0;

cleanup:
    if (enumerate != NULL) {
        udev_enumerate_unref(enumerate);
    }
    if (udev != NULL) {
        udev_unref(udev);
    }
    return status;
}
