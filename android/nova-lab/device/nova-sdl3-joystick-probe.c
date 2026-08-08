#define _GNU_SOURCE
#define _POSIX_C_SOURCE 200809L

#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef uint32_t SDL_JoystickID;
typedef uint16_t SDL_JoystickValue;
typedef struct SDL_Joystick SDL_Joystick;

typedef int (*sdl_init_fn)(uint32_t flags);
typedef void (*sdl_quit_fn)(void);
typedef const char *(*sdl_error_fn)(void);
typedef SDL_JoystickID *(*sdl_get_joysticks_fn)(int *count);
typedef const char *(*sdl_get_joystick_string_fn)(SDL_JoystickID instance_id);
typedef SDL_JoystickValue (*sdl_get_joystick_value_fn)(SDL_JoystickID instance_id);
typedef SDL_Joystick *(*sdl_open_joystick_fn)(SDL_JoystickID instance_id);
typedef void (*sdl_close_joystick_fn)(SDL_Joystick *joystick);
typedef void (*sdl_free_fn)(void *memory);

#define SDL_INIT_JOYSTICK 0x00000200u

static void *load_symbol(void *handle, const char *name)
{
    void *symbol = dlsym(handle, name);
    if (symbol == NULL) {
        fprintf(stderr, "sdl3_error=missing_symbol:%s\n", name);
    }
    return symbol;
}

int main(int argc, char **argv)
{
    const char *library = argc > 1 ? argv[1] :
        "/opt/nova-steam/home/.local/share/Steam/steamrtarm64/libSDL3.so.0";
    const char *expected_name = argc > 2 ? argv[2] : "Nova Virtual Xbox Controller";
    void *handle;
    sdl_init_fn sdl_init;
    sdl_quit_fn sdl_quit;
    sdl_error_fn sdl_get_error;
    sdl_get_joysticks_fn sdl_get_joysticks;
    sdl_get_joystick_string_fn sdl_get_joystick_name;
    sdl_get_joystick_string_fn sdl_get_joystick_path;
    sdl_get_joystick_value_fn sdl_get_joystick_vendor;
    sdl_get_joystick_value_fn sdl_get_joystick_product;
    sdl_open_joystick_fn sdl_open_joystick;
    sdl_close_joystick_fn sdl_close_joystick;
    sdl_free_fn sdl_free;
    SDL_JoystickID *ids;
    SDL_Joystick *virtual_joystick = NULL;
    int count = 0;
    int found = 0;
    int status = 1;

    printf("sdl3_probe_begin\n");
    printf("sdl3_library=%s\n", library);
    fflush(stdout);
    handle = dlopen(library, RTLD_NOW | RTLD_LOCAL);
    if (handle == NULL) {
        fprintf(stderr, "sdl3_error=dlopen:%s\n", dlerror());
        return 1;
    }
    printf("sdl3_dlopen=pass\n");

    sdl_init = (sdl_init_fn)load_symbol(handle, "SDL_Init");
    sdl_quit = (sdl_quit_fn)load_symbol(handle, "SDL_Quit");
    sdl_get_error = (sdl_error_fn)load_symbol(handle, "SDL_GetError");
    sdl_get_joysticks = (sdl_get_joysticks_fn)load_symbol(handle, "SDL_GetJoysticks");
    sdl_get_joystick_name = (sdl_get_joystick_string_fn)
        load_symbol(handle, "SDL_GetJoystickNameForID");
    sdl_get_joystick_path = (sdl_get_joystick_string_fn)
        load_symbol(handle, "SDL_GetJoystickPathForID");
    sdl_get_joystick_vendor = (sdl_get_joystick_value_fn)
        load_symbol(handle, "SDL_GetJoystickVendorForID");
    sdl_get_joystick_product = (sdl_get_joystick_value_fn)
        load_symbol(handle, "SDL_GetJoystickProductForID");
    sdl_open_joystick = (sdl_open_joystick_fn)load_symbol(handle, "SDL_OpenJoystick");
    sdl_close_joystick = (sdl_close_joystick_fn)load_symbol(handle, "SDL_CloseJoystick");
    sdl_free = (sdl_free_fn)load_symbol(handle, "SDL_free");
    if (sdl_init == NULL || sdl_quit == NULL || sdl_get_error == NULL ||
        sdl_get_joysticks == NULL || sdl_get_joystick_name == NULL ||
        sdl_get_joystick_path == NULL || sdl_get_joystick_vendor == NULL ||
        sdl_get_joystick_product == NULL || sdl_open_joystick == NULL ||
        sdl_close_joystick == NULL || sdl_free == NULL) {
        goto cleanup;
    }

    if (sdl_init(SDL_INIT_JOYSTICK) == 0) {
        fprintf(stderr, "sdl3_error=init:%s\n", sdl_get_error());
        goto cleanup;
    }
    printf("sdl3_init=pass\n");
    ids = sdl_get_joysticks(&count);
    if (ids == NULL) {
        fprintf(stderr, "sdl3_error=get_joysticks:%s\n", sdl_get_error());
        sdl_quit();
        goto cleanup;
    }
    printf("sdl3_joystick_count=%d\n", count);
    for (int index = 0; index < count; index++) {
        SDL_JoystickID id = ids[index];
        const char *name = sdl_get_joystick_name(id);
        const char *path = sdl_get_joystick_path(id);
        SDL_JoystickValue vendor = sdl_get_joystick_vendor(id);
        SDL_JoystickValue product = sdl_get_joystick_product(id);

        printf("sdl3_joystick id=%u name=%s path=%s vendor=0x%04x product=0x%04x\n",
               id,
               name != NULL ? name : "missing",
               path != NULL ? path : "missing",
               vendor,
               product);
        if (name != NULL && strcmp(name, expected_name) == 0) {
            found = 1;
            virtual_joystick = sdl_open_joystick(id);
            if (virtual_joystick != NULL) {
                printf("sdl3_virtual_open=pass\n");
            } else {
                fprintf(stderr, "sdl3_error=open_virtual:%s\n", sdl_get_error());
            }
        }
    }
    sdl_free(ids);
    if (virtual_joystick != NULL) {
        sdl_close_joystick(virtual_joystick);
    }
    if (!found) {
        fprintf(stderr, "sdl3_error=virtual_joystick_not_found\n");
        sdl_quit();
        goto cleanup;
    }
    if (virtual_joystick == NULL) {
        sdl_quit();
        goto cleanup;
    }
    sdl_quit();
    printf("sdl3_virtual_joystick=pass\n");
    printf("sdl3_probe=pass\n");
    fflush(stdout);
    status = 0;

cleanup:
    dlclose(handle);
    return status;
}
