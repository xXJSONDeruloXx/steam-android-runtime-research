#define _GNU_SOURCE

#include <errno.h>
#include <fcntl.h>
#include <poll.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

#include <wayland-client.h>

#include "xdg-shell-client-protocol.h"

enum {
    WIDTH = 64,
    HEIGHT = 64,
    BUFFER_COUNT = 2,
    RUN_SECONDS = 5,
};

struct shm_buffer {
    struct wl_buffer *buffer;
    uint32_t *pixels;
    int busy;
};

struct client_state {
    struct wl_display *display;
    struct wl_registry *registry;
    struct wl_compositor *compositor;
    struct wl_shm *shm;
    struct xdg_wm_base *wm_base;
    struct wl_surface *surface;
    struct xdg_surface *xdg_surface;
    struct xdg_toplevel *toplevel;
    struct shm_buffer buffers[BUFFER_COUNT];
    int configured;
    int closed;
    int frame_pending;
    int frame_index;
    unsigned long frame_count;
    int pool_fd;
    size_t pool_size;
    void *pool_data;
};

static uint64_t monotonic_ms(void)
{
    struct timespec ts;
    clock_gettime(CLOCK_MONOTONIC, &ts);
    return (uint64_t)ts.tv_sec * 1000u + (uint64_t)ts.tv_nsec / 1000000u;
}

static void xdg_wm_base_ping(void *data, struct xdg_wm_base *wm_base,
                             uint32_t serial)
{
    (void)data;
    xdg_wm_base_pong(wm_base, serial);
}

static const struct xdg_wm_base_listener wm_base_listener = {
    .ping = xdg_wm_base_ping,
};

static void shm_buffer_release(void *data, struct wl_buffer *buffer)
{
    (void)buffer;
    struct shm_buffer *shm_buffer = data;
    shm_buffer->busy = 0;
}

static const struct wl_buffer_listener buffer_listener = {
    .release = shm_buffer_release,
};

static void frame_done(void *data, struct wl_callback *callback, uint32_t time)
{
    (void)time;
    struct client_state *state = data;
    wl_callback_destroy(callback);
    state->frame_pending = 0;
}

static const struct wl_callback_listener frame_listener = {
    .done = frame_done,
};

static void xdg_surface_configure(void *data, struct xdg_surface *surface,
                                  uint32_t serial)
{
    struct client_state *state = data;
    xdg_surface_ack_configure(surface, serial);
    state->configured = 1;
}

static const struct xdg_surface_listener xdg_surface_listener = {
    .configure = xdg_surface_configure,
};

static void xdg_toplevel_configure(void *data, struct xdg_toplevel *toplevel,
                                   int32_t width, int32_t height,
                                   struct wl_array *states)
{
    (void)data;
    (void)toplevel;
    (void)width;
    (void)height;
    (void)states;
}

static void xdg_toplevel_close(void *data, struct xdg_toplevel *toplevel)
{
    (void)toplevel;
    struct client_state *state = data;
    state->closed = 1;
}

static const struct xdg_toplevel_listener toplevel_listener = {
    .configure = xdg_toplevel_configure,
    .close = xdg_toplevel_close,
};

static void registry_global(void *data, struct wl_registry *registry,
                            uint32_t name, const char *interface,
                            uint32_t version)
{
    struct client_state *state = data;
    if (strcmp(interface, wl_compositor_interface.name) == 0) {
        state->compositor = wl_registry_bind(
            registry, name, &wl_compositor_interface,
            version < 4 ? version : 4);
    } else if (strcmp(interface, wl_shm_interface.name) == 0) {
        state->shm = wl_registry_bind(registry, name, &wl_shm_interface, 1);
    } else if (strcmp(interface, xdg_wm_base_interface.name) == 0) {
        state->wm_base = wl_registry_bind(
            registry, name, &xdg_wm_base_interface,
            version < 2 ? version : 2);
        xdg_wm_base_add_listener(state->wm_base, &wm_base_listener, state);
    }
}

static void registry_global_remove(void *data, struct wl_registry *registry,
                                   uint32_t name)
{
    (void)data;
    (void)registry;
    (void)name;
}

static const struct wl_registry_listener registry_listener = {
    .global = registry_global,
    .global_remove = registry_global_remove,
};

static int create_pool_fd(size_t size)
{
    int fd = memfd_create("nova-wayland-shm", MFD_CLOEXEC);
    if (fd < 0) {
        char name[64];
        snprintf(name, sizeof(name), "/nova-wayland-shm-%ld", (long)getpid());
        fd = shm_open(name, O_CREAT | O_RDWR, 0600);
        if (fd >= 0)
            shm_unlink(name);
    }
    if (fd < 0 || ftruncate(fd, (off_t)size) != 0) {
        if (fd >= 0)
            close(fd);
        return -1;
    }
    return fd;
}

static int create_buffers(struct client_state *state)
{
    const size_t stride = WIDTH * sizeof(uint32_t);
    const size_t buffer_size = stride * HEIGHT;
    state->pool_size = buffer_size * BUFFER_COUNT;
    state->pool_fd = create_pool_fd(state->pool_size);
    if (state->pool_fd < 0)
        return -1;

    state->pool_data = mmap(NULL, state->pool_size, PROT_READ | PROT_WRITE,
                            MAP_SHARED, state->pool_fd, 0);
    if (state->pool_data == MAP_FAILED)
        return -1;

    struct wl_shm_pool *pool = wl_shm_create_pool(
        state->shm, state->pool_fd, (int)state->pool_size);
    if (!pool)
        return -1;

    for (int i = 0; i < BUFFER_COUNT; i++) {
        struct shm_buffer *buffer = &state->buffers[i];
        size_t offset = buffer_size * (size_t)i;
        buffer->pixels = (uint32_t *)((uint8_t *)state->pool_data + offset);
        buffer->buffer = wl_shm_pool_create_buffer(
            pool, (int)offset, WIDTH, HEIGHT, (int)stride,
            WL_SHM_FORMAT_XRGB8888);
        if (!buffer->buffer)
            return -1;
        wl_buffer_add_listener(buffer->buffer, &buffer_listener, buffer);
    }
    wl_shm_pool_destroy(pool);
    return 0;
}

static void paint(struct shm_buffer *buffer, unsigned long frame)
{
    for (int y = 0; y < HEIGHT; y++) {
        for (int x = 0; x < WIDTH; x++) {
            uint32_t red = (uint32_t)((x + frame) & 0xff);
            uint32_t green = (uint32_t)((y * 4 + frame * 3) & 0xff);
            uint32_t blue = (uint32_t)(((x ^ y) * 4 + frame * 5) & 0xff);
            buffer->pixels[y * WIDTH + x] = (red << 16) | (green << 8) | blue;
        }
    }
}

static unsigned long max_frames(void)
{
    const char *value = getenv("NOVA_WAYLAND_SHM_MAX_FRAMES");
    if (!value || !*value)
        return 0;
    char *end = NULL;
    unsigned long result = strtoul(value, &end, 10);
    return end != value && *end == '\0' ? result : 0;
}

static int draw(struct client_state *state)
{
    if (!state->configured || state->frame_pending)
        return 0;

    struct shm_buffer *buffer = NULL;
    for (int i = 0; i < BUFFER_COUNT; i++) {
        int index = (state->frame_index + i) % BUFFER_COUNT;
        if (!state->buffers[index].busy) {
            buffer = &state->buffers[index];
            state->frame_index = (index + 1) % BUFFER_COUNT;
            break;
        }
    }
    if (!buffer)
        return 0;

    paint(buffer, state->frame_count);
    buffer->busy = 1;
    struct wl_callback *callback = wl_surface_frame(state->surface);
    if (!callback)
        return -1;
    wl_callback_add_listener(callback, &frame_listener, state);
    wl_surface_attach(state->surface, buffer->buffer, 0, 0);
    wl_surface_damage_buffer(state->surface, 0, 0, WIDTH, HEIGHT);
    wl_surface_commit(state->surface);
    state->frame_pending = 1;
    state->frame_count++;
    printf("wayland_shm_frame=%lu\n", state->frame_count);
    fflush(stdout);
    return 0;
}

static void destroy_state(struct client_state *state)
{
    for (int i = 0; i < BUFFER_COUNT; i++) {
        if (state->buffers[i].buffer)
            wl_buffer_destroy(state->buffers[i].buffer);
    }
    if (state->pool_data && state->pool_data != MAP_FAILED)
        munmap(state->pool_data, state->pool_size);
    if (state->pool_fd >= 0)
        close(state->pool_fd);
    if (state->toplevel)
        xdg_toplevel_destroy(state->toplevel);
    if (state->xdg_surface)
        xdg_surface_destroy(state->xdg_surface);
    if (state->surface)
        wl_surface_destroy(state->surface);
    if (state->wm_base)
        xdg_wm_base_destroy(state->wm_base);
    if (state->shm)
        wl_shm_destroy(state->shm);
    if (state->compositor)
        wl_compositor_destroy(state->compositor);
    if (state->registry)
        wl_registry_destroy(state->registry);
    if (state->display)
        wl_display_disconnect(state->display);
}

int main(void)
{
    struct client_state state = {
        .pool_fd = -1,
    };
    const char *socket_name = getenv("WAYLAND_DISPLAY");
    if (!socket_name || !*socket_name)
        socket_name = getenv("GAMESCOPE_WAYLAND_DISPLAY");

    state.display = wl_display_connect(socket_name);
    if (!state.display) {
        fprintf(stderr, "wayland_connect=fail socket=%s\n",
                socket_name ? socket_name : "default");
        return 1;
    }
    state.registry = wl_display_get_registry(state.display);
    wl_registry_add_listener(state.registry, &registry_listener, &state);
    if (wl_display_roundtrip(state.display) < 0 || !state.compositor ||
        !state.shm || !state.wm_base) {
        fprintf(stderr, "wayland_globals=fail\n");
        destroy_state(&state);
        return 1;
    }

    state.surface = wl_compositor_create_surface(state.compositor);
    state.xdg_surface = xdg_wm_base_get_xdg_surface(state.wm_base, state.surface);
    state.toplevel = xdg_surface_get_toplevel(state.xdg_surface);
    if (!state.surface || !state.xdg_surface || !state.toplevel) {
        fprintf(stderr, "wayland_surface=fail\n");
        destroy_state(&state);
        return 1;
    }
    xdg_surface_add_listener(state.xdg_surface, &xdg_surface_listener, &state);
    xdg_toplevel_add_listener(state.toplevel, &toplevel_listener, &state);
    xdg_toplevel_set_title(state.toplevel, "Nova Gamescope SHM control");
    wl_surface_commit(state.surface);
    if (wl_display_roundtrip(state.display) < 0 || !state.configured) {
        fprintf(stderr, "wayland_configure=fail\n");
        destroy_state(&state);
        return 1;
    }

    if (create_buffers(&state) != 0 || draw(&state) != 0) {
        fprintf(stderr, "wayland_shm_buffer=fail errno=%d\n", errno);
        destroy_state(&state);
        return 1;
    }
    printf("wayland_connect=pass socket=%s\n",
           socket_name ? socket_name : "default");
    fflush(stdout);

    const unsigned long frame_limit = max_frames();
    uint64_t deadline = monotonic_ms() + RUN_SECONDS * 1000u;
    while (!state.closed && monotonic_ms() < deadline) {
        if (wl_display_dispatch_pending(state.display) < 0)
            break;
        if (frame_limit > 0 && state.frame_count >= frame_limit &&
            !state.frame_pending)
            break;
        if (draw(&state) != 0)
            break;
        if (wl_display_flush(state.display) < 0 && errno != EAGAIN)
            break;

        struct pollfd pollfd = {
            .fd = wl_display_get_fd(state.display),
            .events = POLLIN,
        };
        int timeout = (int)(deadline - monotonic_ms());
        if (timeout < 0)
            timeout = 0;
        if (timeout > 50)
            timeout = 50;
        int result = poll(&pollfd, 1, timeout);
        if (result > 0 && (pollfd.revents & (POLLIN | POLLERR | POLLHUP))) {
            if (wl_display_dispatch(state.display) < 0)
                break;
        }
    }

    printf("wayland_shm_frames=%lu\n", state.frame_count);
    destroy_state(&state);
    return state.frame_count > 0 ? 0 : 1;
}
