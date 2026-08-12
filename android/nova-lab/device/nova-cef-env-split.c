#define _GNU_SOURCE

// Keep the direct Steam client on its rooted GL profile while allowing its
// steamwebhelper child to choose its own renderer.  Steam launches the
// webhelper from several code paths, so filter the environment at the exec
// boundary instead of modifying the persistent Steam installation.

#include <dlfcn.h>
#include <errno.h>
#include <spawn.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <unistd.h>

extern char **environ;

typedef int (*execve_function)(const char *, char *const[], char *const[]);
typedef int (*execv_function)(const char *, char *const[]);
typedef int (*execvp_function)(const char *, char *const[]);
typedef int (*execvpe_function)(const char *, char *const[], char *const[]);
typedef int (*execveat_function)(int, const char *, char *const[], char *const[], int);
typedef int (*posix_spawn_function)(
    pid_t *, const char *, const posix_spawn_file_actions_t *,
    const posix_spawnattr_t *, char *const[], char *const[]);

static int is_steamwebhelper(const char *path) {
    if (!path || path[0] == '\0') {
        return 0;
    }
    const char *base = strrchr(path, '/');
    base = base ? base + 1 : path;
    return strcmp(base, "steamwebhelper") == 0;
}

static int remove_environment_entry(const char *entry) {
    static const char *const names[] = {
        "MESA_LOADER_DRIVER_OVERRIDE",
        "GALLIUM_DRIVER",
        "LIBGL_ALWAYS_SOFTWARE",
        "LIBGL_ALWAYS_INDIRECT",
        // Steam sets this for webhelper's store path.  On this rooted X11
        // stack it disables Mesa's Zink Vulkan path and falls back to
        // llvmpipe, which makes Chromium's GPU process exit during startup.
        "LIBGL_KOPPER_DISABLE",
    };
    if (!entry) {
        return 0;
    }
    for (size_t index = 0; index < sizeof(names) / sizeof(names[0]); index++) {
        size_t length = strlen(names[index]);
        if (strncmp(entry, names[index], length) == 0 &&
            (entry[length] == '=' || entry[length] == '\0')) {
            return 1;
        }
    }
    return 0;
}

static void trace_split(const char *path, size_t removed, const char *status) {
    const char *trace = getenv("NOVA_CEF_ENV_SPLIT_TRACE");
    if (!trace || trace[0] != '1') {
        return;
    }
    const char *base = strrchr(path ? path : "", '/');
    base = base ? base + 1 : (path ? path : "unset");
    char line[256];
    int length = snprintf(
        line, sizeof(line), "nova_cef_env_split target=%s removed=%zu status=%s\n",
        base, removed, status);
    if (length > 0) {
        if (length >= (int)sizeof(line)) {
            length = (int)sizeof(line) - 1;
        }
        (void)write(STDERR_FILENO, line, (size_t)length);
    }
}

static char **filtered_environment(
    char *const environment[], size_t *removed, int *allocation_failed) {
    *removed = 0;
    *allocation_failed = 0;
    if (!environment) {
        return NULL;
    }

    size_t count = 0;
    for (char *const *entry = environment; *entry; entry++) {
        if (remove_environment_entry(*entry)) {
            *removed += 1;
        }
        count += 1;
    }
    if (*removed == 0) {
        return NULL;
    }

    char **filtered = calloc(count + 1, sizeof(*filtered));
    if (!filtered) {
        *allocation_failed = 1;
        return NULL;
    }
    size_t output = 0;
    for (char *const *entry = environment; *entry; entry++) {
        if (!remove_environment_entry(*entry)) {
            filtered[output++] = *entry;
        }
    }
    filtered[output] = NULL;
    return filtered;
}

static int execute_with_environment(
    execve_function function, const char *path, char *const argv[],
    char *const environment[]) {
    if (!is_steamwebhelper(path)) {
        return function(path, argv, environment);
    }

    size_t removed = 0;
    int allocation_failed = 0;
    char **filtered = filtered_environment(environment, &removed, &allocation_failed);
    if (allocation_failed) {
        trace_split(path, 0, "allocation_failed");
    } else if (removed == 0) {
        trace_split(path, 0, "no_matching_variables");
    } else {
        trace_split(path, removed, "pass");
    }
    int result = function(path, argv, filtered ? filtered : environment);
    int error_number = errno;
    free(filtered);
    errno = error_number;
    return result;
}

static execve_function real_execve(void) {
    static execve_function function;
    if (!function) {
        function = (execve_function)dlsym(RTLD_NEXT, "execve");
    }
    return function;
}

static execv_function real_execv(void) {
    static execv_function function;
    if (!function) {
        function = (execv_function)dlsym(RTLD_NEXT, "execv");
    }
    return function;
}

static execvp_function real_execvp(void) {
    static execvp_function function;
    if (!function) {
        function = (execvp_function)dlsym(RTLD_NEXT, "execvp");
    }
    return function;
}

static execvpe_function real_execvpe(void) {
    static execvpe_function function;
    if (!function) {
        function = (execvpe_function)dlsym(RTLD_NEXT, "execvpe");
    }
    return function;
}

static execveat_function real_execveat(void) {
    static execveat_function function;
    if (!function) {
        function = (execveat_function)dlsym(RTLD_NEXT, "execveat");
    }
    return function;
}

static posix_spawn_function real_posix_spawn(void) {
    static posix_spawn_function function;
    if (!function) {
        function = (posix_spawn_function)dlsym(RTLD_NEXT, "posix_spawn");
    }
    return function;
}

static posix_spawn_function real_posix_spawnp(void) {
    static posix_spawn_function function;
    if (!function) {
        function = (posix_spawn_function)dlsym(RTLD_NEXT, "posix_spawnp");
    }
    return function;
}

int execve(const char *path, char *const argv[], char *const environment[]) {
    execve_function function = real_execve();
    if (!function) {
        errno = ENOSYS;
        return -1;
    }
    return execute_with_environment(function, path, argv, environment);
}

int execv(const char *path, char *const argv[]) {
    execve_function function = real_execve();
    execv_function original = real_execv();
    if (!function || !original) {
        errno = ENOSYS;
        return -1;
    }
    if (!is_steamwebhelper(path)) {
        return original(path, argv);
    }
    return execute_with_environment(function, path, argv, environ);
}

int execvp(const char *path, char *const argv[]) {
    execve_function function = real_execve();
    execvp_function original = real_execvp();
    execvpe_function original_with_environment = real_execvpe();
    if (!function || !original || !original_with_environment) {
        errno = ENOSYS;
        return -1;
    }
    if (!is_steamwebhelper(path)) {
        return original(path, argv);
    }

    size_t removed = 0;
    int allocation_failed = 0;
    char **filtered = filtered_environment(environ, &removed, &allocation_failed);
    if (allocation_failed) {
        trace_split(path, 0, "allocation_failed");
    } else if (removed == 0) {
        trace_split(path, 0, "no_matching_variables");
    } else {
        trace_split(path, removed, "pass");
    }
    int result = original_with_environment(path, argv, filtered ? filtered : environ);
    int error_number = errno;
    free(filtered);
    errno = error_number;
    return result;
}

int execvpe(const char *path, char *const argv[], char *const environment[]) {
    execvpe_function original = real_execvpe();
    if (!original) {
        errno = ENOSYS;
        return -1;
    }
    if (!is_steamwebhelper(path)) {
        return original(path, argv, environment);
    }

    size_t removed = 0;
    int allocation_failed = 0;
    char **filtered = filtered_environment(environment, &removed, &allocation_failed);
    if (allocation_failed) {
        trace_split(path, 0, "allocation_failed");
    } else if (removed == 0) {
        trace_split(path, 0, "no_matching_variables");
    } else {
        trace_split(path, removed, "pass");
    }
    int result = original(path, argv, filtered ? filtered : environment);
    int error_number = errno;
    free(filtered);
    errno = error_number;
    return result;
}

int execveat(
    int directory_fd, const char *path, char *const argv[],
    char *const environment[], int flags) {
    execveat_function function = real_execveat();
    if (!function) {
        errno = ENOSYS;
        return -1;
    }
    if (!is_steamwebhelper(path)) {
        return function(directory_fd, path, argv, environment, flags);
    }

    size_t removed = 0;
    int allocation_failed = 0;
    char **filtered = filtered_environment(environment, &removed, &allocation_failed);
    if (allocation_failed) {
        trace_split(path, 0, "allocation_failed");
    } else if (removed == 0) {
        trace_split(path, 0, "no_matching_variables");
    } else {
        trace_split(path, removed, "pass");
    }
    int result = function(
        directory_fd, path, argv, filtered ? filtered : environment, flags);
    int error_number = errno;
    free(filtered);
    errno = error_number;
    return result;
}

static int spawn_with_environment(
    posix_spawn_function function, pid_t *pid, const char *path,
    const posix_spawn_file_actions_t *file_actions,
    const posix_spawnattr_t *attributes, char *const argv[],
    char *const environment[]) {
    if (!is_steamwebhelper(path)) {
        return function(pid, path, file_actions, attributes, argv, environment);
    }

    size_t removed = 0;
    int allocation_failed = 0;
    char **filtered = filtered_environment(environment, &removed, &allocation_failed);
    if (allocation_failed) {
        trace_split(path, 0, "allocation_failed");
    } else if (removed == 0) {
        trace_split(path, 0, "no_matching_variables");
    } else {
        trace_split(path, removed, "pass");
    }
    int result = function(
        pid, path, file_actions, attributes, argv,
        filtered ? filtered : environment);
    free(filtered);
    return result;
}

int posix_spawn(
    pid_t *pid, const char *path, const posix_spawn_file_actions_t *file_actions,
    const posix_spawnattr_t *attributes, char *const argv[],
    char *const environment[]) {
    posix_spawn_function function = real_posix_spawn();
    if (!function) {
        return ENOSYS;
    }
    return spawn_with_environment(
        function, pid, path, file_actions, attributes, argv, environment);
}

int posix_spawnp(
    pid_t *pid, const char *path, const posix_spawn_file_actions_t *file_actions,
    const posix_spawnattr_t *attributes, char *const argv[],
    char *const environment[]) {
    posix_spawn_function function = real_posix_spawnp();
    if (!function) {
        return ENOSYS;
    }
    return spawn_with_environment(
        function, pid, path, file_actions, attributes, argv, environment);
}
