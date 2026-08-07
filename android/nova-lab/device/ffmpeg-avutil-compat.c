#define _GNU_SOURCE

// Steam's ARM64 libvideo.so was linked against the older tracked allocator
// entry points from libavutil. Holo's current FFmpeg package removed those
// names while retaining the underlying allocators. Export the two legacy
// symbols under the ABI version Steam requests and forward them at runtime.

#include <dlfcn.h>
#include <stddef.h>

typedef void *(*allocator_function)(size_t);

typedef void *(*reallocator_function)(void *, size_t);
typedef void (*deallocator_function)(void *);

static void *forward_allocator(const char *name, size_t size) {
    allocator_function allocator = (allocator_function)dlsym(RTLD_NEXT, name);
    return allocator ? allocator(size) : NULL;
}

void *av_malloc_tracked(size_t size) {
    return forward_allocator("av_malloc", size);
}

void *av_mallocz_tracked(size_t size) {
    return forward_allocator("av_mallocz", size);
}

// Steam's libvideo registers its own tracking callbacks before using the
// av_* allocation API. Holo's FFmpeg keeps the allocator implementation
// internal to libavutil, so retaining the host allocator is the safest
// compatibility behavior for this exploratory process. The callback ABI is
// deliberately represented here only to consume the three call registers;
// the callbacks themselves are not invoked by this shim.
void av_register_malloc(allocator_function malloc_fn,
                        reallocator_function realloc_fn,
                        deallocator_function free_fn) {
    (void)malloc_fn;
    (void)realloc_fn;
    (void)free_fn;
}
