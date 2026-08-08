#define _GNU_SOURCE
#define _POSIX_C_SOURCE 200809L

#include <errno.h>
#include <dlfcn.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

typedef uint32_t SDL_JoystickID;
typedef uint16_t SDL_JoystickValue;
typedef struct SDL_Joystick SDL_Joystick;
typedef struct SDL_Gamepad SDL_Gamepad;

typedef int (*sdl_init_fn)(uint32_t flags);
typedef void (*sdl_quit_fn)(void);
typedef const char *(*sdl_error_fn)(void);
typedef SDL_JoystickID *(*sdl_get_joysticks_fn)(int *count);
typedef const char *(*sdl_get_joystick_string_fn)(SDL_JoystickID instance_id);
typedef SDL_JoystickValue (*sdl_get_joystick_value_fn)(SDL_JoystickID instance_id);
typedef SDL_Joystick *(*sdl_open_joystick_fn)(SDL_JoystickID instance_id);
typedef void (*sdl_close_joystick_fn)(SDL_Joystick *joystick);
typedef void (*sdl_free_fn)(void *memory);
typedef int (*sdl_poll_event_fn)(void *event);
typedef SDL_JoystickID *(*sdl_get_gamepads_fn)(int *count);
typedef int (*sdl_is_gamepad_fn)(SDL_JoystickID instance_id);
typedef const char *(*sdl_get_gamepad_string_fn)(SDL_JoystickID instance_id);
typedef SDL_JoystickValue (*sdl_get_gamepad_value_fn)(SDL_JoystickID instance_id);
typedef int (*sdl_get_gamepad_type_fn)(SDL_JoystickID instance_id);
typedef char *(*sdl_get_gamepad_mapping_fn)(SDL_JoystickID instance_id);
typedef SDL_Gamepad *(*sdl_open_gamepad_fn)(SDL_JoystickID instance_id);
typedef SDL_JoystickID (*sdl_get_gamepad_id_fn)(SDL_Gamepad *gamepad);
typedef void (*sdl_close_gamepad_fn)(SDL_Gamepad *gamepad);

#define SDL_INIT_JOYSTICK 0x00000200u
#define SDL_INIT_GAMEPAD 0x00002000u

static uint64_t monotonic_milliseconds(void)
{
    struct timespec timestamp;
    clock_gettime(CLOCK_MONOTONIC, &timestamp);
    return (uint64_t)timestamp.tv_sec * 1000u +
           (uint64_t)timestamp.tv_nsec / 1000000u;
}

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
    const char *expected_path = NULL;
    const int event_mode = argc > 3 && strcmp(argv[3], "event") == 0;
    const int gamepad_event_mode = argc > 3 && strcmp(argv[3], "gamepad-event") == 0;
    const int gamepad_mode = (argc > 3 && strcmp(argv[3], "gamepad") == 0) ||
        gamepad_event_mode;
    unsigned int event_timeout_ms = 10000;
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
    sdl_poll_event_fn sdl_poll_event = NULL;
    sdl_get_gamepads_fn sdl_get_gamepads = NULL;
    sdl_is_gamepad_fn sdl_is_gamepad = NULL;
    sdl_get_gamepad_string_fn sdl_get_gamepad_name = NULL;
    sdl_get_gamepad_string_fn sdl_get_gamepad_path = NULL;
    sdl_get_gamepad_value_fn sdl_get_gamepad_vendor = NULL;
    sdl_get_gamepad_value_fn sdl_get_gamepad_product = NULL;
    sdl_get_gamepad_type_fn sdl_get_gamepad_type = NULL;
    sdl_get_gamepad_mapping_fn sdl_get_gamepad_mapping = NULL;
    sdl_open_gamepad_fn sdl_open_gamepad = NULL;
    sdl_get_gamepad_id_fn sdl_get_gamepad_id = NULL;
    sdl_close_gamepad_fn sdl_close_gamepad = NULL;
    SDL_JoystickID *ids;
    SDL_Joystick *virtual_joystick = NULL;
    SDL_JoystickID virtual_id = 0;
    int count = 0;
    int found = 0;
    int event_received = 0;
    int status = 1;

    for (int argument = 3; argument < argc; argument++) {
        if (strncmp(argv[argument], "/dev/input/", 11) == 0) {
            expected_path = argv[argument];
        }
    }

    if ((event_mode || gamepad_event_mode) && argc > 4) {
        char *end = NULL;
        unsigned long value;
        errno = 0;
        value = strtoul(argv[4], &end, 10);
        if (errno != 0 || end == argv[4] || *end != '\0' || value == 0 ||
            value > 600000u) {
            fprintf(stderr, "sdl3_error=invalid_event_timeout\n");
            return 2;
        }
        event_timeout_ms = (unsigned int)value;
    }

    printf("sdl3_probe_begin\n");
    printf("sdl3_library=%s\n", library);
    if (expected_path != NULL) {
        printf("sdl3_target_path=%s\n", expected_path);
    }
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
    if (event_mode || gamepad_event_mode) {
        sdl_poll_event = (sdl_poll_event_fn)load_symbol(handle, "SDL_PollEvent");
    }
    if (gamepad_mode) {
        sdl_get_gamepads = (sdl_get_gamepads_fn)load_symbol(handle, "SDL_GetGamepads");
        sdl_is_gamepad = (sdl_is_gamepad_fn)load_symbol(handle, "SDL_IsGamepad");
        sdl_get_gamepad_name = (sdl_get_gamepad_string_fn)
            load_symbol(handle, "SDL_GetGamepadNameForID");
        sdl_get_gamepad_path = (sdl_get_gamepad_string_fn)
            load_symbol(handle, "SDL_GetGamepadPathForID");
        sdl_get_gamepad_vendor = (sdl_get_gamepad_value_fn)
            load_symbol(handle, "SDL_GetGamepadVendorForID");
        sdl_get_gamepad_product = (sdl_get_gamepad_value_fn)
            load_symbol(handle, "SDL_GetGamepadProductForID");
        sdl_get_gamepad_type = (sdl_get_gamepad_type_fn)
            load_symbol(handle, "SDL_GetGamepadTypeForID");
        sdl_get_gamepad_mapping = (sdl_get_gamepad_mapping_fn)
            load_symbol(handle, "SDL_GetGamepadMappingForID");
        sdl_open_gamepad = (sdl_open_gamepad_fn)load_symbol(handle, "SDL_OpenGamepad");
        sdl_get_gamepad_id = (sdl_get_gamepad_id_fn)load_symbol(handle, "SDL_GetGamepadID");
        sdl_close_gamepad = (sdl_close_gamepad_fn)load_symbol(handle, "SDL_CloseGamepad");
    }
    if (sdl_init == NULL || sdl_quit == NULL || sdl_get_error == NULL ||
        sdl_get_joysticks == NULL || sdl_get_joystick_name == NULL ||
        sdl_get_joystick_path == NULL || sdl_get_joystick_vendor == NULL ||
        sdl_get_joystick_product == NULL || sdl_open_joystick == NULL ||
        sdl_close_joystick == NULL || sdl_free == NULL ||
        ((event_mode || gamepad_event_mode) && sdl_poll_event == NULL) ||
        (gamepad_mode && (sdl_get_gamepads == NULL || sdl_is_gamepad == NULL ||
                          sdl_get_gamepad_name == NULL || sdl_get_gamepad_path == NULL ||
                          sdl_get_gamepad_vendor == NULL || sdl_get_gamepad_product == NULL ||
                          sdl_get_gamepad_type == NULL || sdl_get_gamepad_mapping == NULL ||
                          sdl_open_gamepad == NULL ||
                          sdl_get_gamepad_id == NULL || sdl_close_gamepad == NULL))) {
        goto cleanup;
    }

    if (sdl_init(gamepad_mode ? SDL_INIT_GAMEPAD : SDL_INIT_JOYSTICK) == 0) {
        fprintf(stderr, "sdl3_error=init:%s\n", sdl_get_error());
        goto cleanup;
    }
    printf("sdl3_init=pass\n");

    if (gamepad_mode) {
        SDL_JoystickID *joystick_ids;
        SDL_JoystickID *gamepad_ids;
        SDL_Gamepad *virtual_gamepad = NULL;
        SDL_JoystickID virtual_gamepad_id = 0;
        int joystick_count = 0;
        int gamepad_count = 0;

        joystick_ids = sdl_get_joysticks(&joystick_count);
        if (joystick_ids == NULL) {
            fprintf(stderr, "sdl3_error=get_joysticks:%s\n", sdl_get_error());
            sdl_quit();
            goto cleanup;
        }
        printf("sdl3_joystick_count=%d\n", joystick_count);
        for (int index = 0; index < joystick_count; index++) {
            SDL_JoystickID id = joystick_ids[index];
            const char *name = sdl_get_joystick_name(id);

            printf("sdl3_joystick_gamepad_mapping id=%u name=%s is_gamepad=%d\n",
                   id,
                   name != NULL ? name : "missing",
                   sdl_is_gamepad(id));
        }
        sdl_free(joystick_ids);

        gamepad_ids = sdl_get_gamepads(&gamepad_count);
        if (gamepad_ids == NULL) {
            fprintf(stderr, "sdl3_error=get_gamepads:%s\n", sdl_get_error());
            sdl_quit();
            goto cleanup;
        }
        printf("sdl3_gamepad_count=%d\n", gamepad_count);
        for (int index = 0; index < gamepad_count; index++) {
            SDL_JoystickID id = gamepad_ids[index];
            const char *name = sdl_get_gamepad_name(id);
            const char *path = sdl_get_gamepad_path(id);
            char *mapping = sdl_get_gamepad_mapping(id);

            printf("sdl3_gamepad id=%u name=%s path=%s vendor=0x%04x product=0x%04x type=%d\n",
                   id,
                   name != NULL ? name : "missing",
                   path != NULL ? path : "missing",
                   sdl_get_gamepad_vendor(id),
                   sdl_get_gamepad_product(id),
                   sdl_get_gamepad_type(id));
            printf("sdl3_gamepad_mapping id=%u value=%s\n",
                   id, mapping != NULL ? mapping : "missing");
            if (mapping != NULL) {
                sdl_free(mapping);
            }
            if ((expected_path != NULL && path != NULL &&
                 strcmp(path, expected_path) == 0) ||
                (expected_path == NULL && name != NULL &&
                 strcmp(name, expected_name) == 0)) {
                virtual_gamepad_id = id;
                virtual_gamepad = sdl_open_gamepad(id);
                if (virtual_gamepad != NULL) {
                    printf("sdl3_virtual_gamepad_open=pass\n");
                    printf("sdl3_virtual_gamepad_id=%u\n",
                           sdl_get_gamepad_id(virtual_gamepad));
                } else {
                    fprintf(stderr, "sdl3_error=open_virtual_gamepad:%s\n",
                            sdl_get_error());
                }
            }
        }
        sdl_free(gamepad_ids);
        if (gamepad_event_mode && virtual_gamepad == NULL) {
            fprintf(stderr, "sdl3_error=virtual_gamepad_not_found_for_event\n");
            sdl_quit();
            goto cleanup;
        }
        if (gamepad_event_mode) {
            uint64_t event_storage[16];
            uint64_t deadline;
            int button_down = 0;
            int button_up = 0;

            /* Remove discovery events queued while the virtual gamepad opened. */
            while (sdl_poll_event(event_storage) != 0) {
            }
            printf("sdl3_gamepad_event_ready=pass\n");
            fflush(stdout);
            deadline = monotonic_milliseconds() + event_timeout_ms;
            while (monotonic_milliseconds() < deadline && (!button_down || !button_up)) {
                while (sdl_poll_event(event_storage) != 0) {
                    uint32_t type;
                    SDL_JoystickID which;
                    uint8_t button;

                    memcpy(&type, event_storage, sizeof(type));
                    memcpy(&which, (unsigned char *)event_storage + 16, sizeof(which));
                    memcpy(&button, (unsigned char *)event_storage + 20, sizeof(button));
                    if (type >= 0x650u && type <= 0x65bu && which == virtual_gamepad_id) {
                        printf("sdl3_gamepad_event_observed type=0x%03x which=%u byte20=%u byte21=%u\n",
                               type, which, ((unsigned char *)event_storage)[20],
                               ((unsigned char *)event_storage)[21]);
                    }
                    if (type != 0x651u && type != 0x652u) {
                        continue;
                    }
                    if (which != virtual_gamepad_id || button != 12u) {
                        printf("sdl3_gamepad_event_ignored type=0x%03x which=%u button=%u\n",
                               type, which, button);
                        continue;
                    }
                    if (type == 0x651u) {
                        button_down = 1;
                        printf("sdl3_gamepad_button_event=pass type=0x%03x which=%u button=%u state=down\n",
                               type, which, button);
                    } else {
                        button_up = 1;
                        printf("sdl3_gamepad_button_event=pass type=0x%03x which=%u button=%u state=up\n",
                               type, which, button);
                    }
                }
                if (!button_down || !button_up) {
                    usleep(1000);
                }
            }
            if (!button_down || !button_up) {
                fprintf(stderr, "sdl3_error=gamepad_button_event_timeout\n");
                goto cleanup;
            }
        }
        if (virtual_gamepad != NULL) {
            sdl_close_gamepad(virtual_gamepad);
            printf("sdl3_virtual_gamepad=pass id=%u\n", virtual_gamepad_id);
        } else {
            printf("sdl3_virtual_gamepad=missing\n");
        }
        sdl_quit();
        printf("sdl3_gamepad_probe=pass\n");
        if (gamepad_event_mode) {
            printf("sdl3_gamepad_event_probe=pass\n");
        }
        printf("sdl3_probe=pass\n");
        fflush(stdout);
        status = 0;
        goto cleanup;
    }

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
            if ((expected_path != NULL && path != NULL &&
                 strcmp(path, expected_path) == 0) ||
                (expected_path == NULL && name != NULL &&
                 strcmp(name, expected_name) == 0)) {
            found = 1;
            virtual_id = id;
            virtual_joystick = sdl_open_joystick(id);
            if (virtual_joystick != NULL) {
                printf("sdl3_virtual_open=pass\n");
                printf("sdl3_virtual_id=%u\n", virtual_id);
            } else {
                fprintf(stderr, "sdl3_error=open_virtual:%s\n", sdl_get_error());
            }
        }
    }
    sdl_free(ids);

    if (event_mode) {
        uint64_t event_storage[16];
        uint64_t deadline;

        /* Remove discovery events queued while the virtual joystick opened. */
        while (sdl_poll_event(event_storage) != 0) {
        }
        printf("sdl3_event_ready=pass\n");
        fflush(stdout);
        deadline = monotonic_milliseconds() + event_timeout_ms;
        while (monotonic_milliseconds() < deadline && !event_received) {
            while (sdl_poll_event(event_storage) != 0) {
                uint32_t type;
                SDL_JoystickID which;
                memcpy(&type, event_storage, sizeof(type));
                memcpy(&which, (unsigned char *)event_storage + 16, sizeof(which));
                if (type >= 0x605u && type <= 0x60fu) {
                    if (which != virtual_id) {
                        printf("sdl3_joystick_event_ignored type=0x%03x which=%u\n",
                               type, which);
                        continue;
                    }
                    printf("sdl3_joystick_event=pass type=0x%03x which=%u\n",
                           type, which);
                    event_received = 1;
                    break;
                }
            }
            if (!event_received) {
                usleep(1000);
            }
        }
        if (!event_received) {
            fprintf(stderr, "sdl3_error=joystick_event_timeout\n");
            goto cleanup;
        }
    }

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
    if (event_mode) {
        printf("sdl3_event_probe=pass\n");
    }
    printf("sdl3_probe=pass\n");
    fflush(stdout);
    status = 0;

cleanup:
    dlclose(handle);
    return status;
}
