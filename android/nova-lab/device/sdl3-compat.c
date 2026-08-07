#define _GNU_SOURCE

// Steam's current ARM64 steamui.so requests SDL 3.6's non-blocking joystick
// lock entry point. SteamRT 3c and Holo's SDL 3.2 package expose the older
// blocking lock pair, so provide the narrow ABI bridge needed to load the UI.

#include <dlfcn.h>
#include <stdbool.h>

typedef void (*sdl_lock_joysticks_function)(void);

bool SDL_TryLockJoysticks(void) {
    sdl_lock_joysticks_function lock_joysticks =
        (sdl_lock_joysticks_function)dlsym(RTLD_NEXT, "SDL_LockJoysticks");
    if (!lock_joysticks) {
        return false;
    }

    // SDL 3.2 has no public try-lock primitive. Taking the existing lock is
    // conservative for this startup adapter and reports success once held.
    lock_joysticks();
    return true;
}
