#define _GNU_SOURCE

// Android's kernel configuration used by the Nova does not expose the
// System V semaphore syscalls. Steam's tier0 library uses semget/semctl/semop
// for its named events, so this narrowly scoped preload maps the subset Steam
// needs onto POSIX named semaphores in the Holo /dev/shm tmpfs.

#include <errno.h>
#include <fcntl.h>
#include <semaphore.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ipc.h>
#include <sys/sem.h>
#include <sys/stat.h>
#include <time.h>
#include <unistd.h>

static int shim_trace_enabled(void) {
    const char *value = getenv("NOVA_SYSV_SEM_SHIM_TRACE");
    return value && value[0] == '1';
}

static void shim_trace(const char *operation, int result, int error_number) {
    if (!shim_trace_enabled()) {
        return;
    }
    char line[192];
    int length = snprintf(
        line,
        sizeof(line),
        "nova_sysv_sem_shim uid=%d %s result=%d errno=%d error=%s\n",
        (int)getuid(),
        operation,
        result,
        error_number,
        strerror(error_number));
    if (length > 0) {
        if (length >= (int)sizeof(line)) {
            length = (int)sizeof(line) - 1;
        }
        (void)write(STDERR_FILENO, line, (size_t)length);
    }
}

static int make_id(key_t key) {
    // Keep the id positive and derive it deterministically in every process.
    // Steam uses stable non-private keys; masking the high two key bits is
    // sufficient for this lab and keeps the implementation stateless.
    int id = (int)(0x40000000u | ((uint32_t)key & 0x3fffffffu));
    return id == 0x40000000 ? 0x40000001 : id;
}

static int semaphore_name(int id, char *buffer, size_t length) {
    int written = snprintf(buffer, length, "/nova-sysv-%08x", (unsigned int)id);
    if (written < 0 || (size_t)written >= length) {
        errno = ENAMETOOLONG;
        return -1;
    }
    return 0;
}

static sem_t *open_id(int id, char *name, size_t name_length) {
    if (semaphore_name(id, name, name_length) < 0) {
        return SEM_FAILED;
    }
    return sem_open(name, 0);
}

static void relax_backing_permissions(const char *name) {
    char path[96];
    int written = snprintf(path, sizeof(path), "/dev/shm/sem.%s", name + 1);
    if (written >= 0 && (size_t)written < sizeof(path)) {
        // A Steam process can create the object as root and then hand the
        // same logical System V semaphore to a non-root child. The disposable
        // rootfs has no other users, so make the POSIX backing node usable by
        // every process participating in this single launch.
        (void)chmod(path, 0666);
    }
}

static int adjust_value(sem_t *semaphore, int target) {
    if (target < 0) {
        errno = EINVAL;
        return -1;
    }
    for (;;) {
        int current = 0;
        if (sem_getvalue(semaphore, &current) < 0) {
            return -1;
        }
        if (current == target) {
            return 0;
        }
        if (current < target) {
            if (sem_post(semaphore) < 0) {
                return -1;
            }
        } else if (sem_trywait(semaphore) < 0 && errno != EINTR) {
            return -1;
        }
    }
}

static int wait_zero(sem_t *semaphore, int nowait) {
    for (;;) {
        int current = 0;
        if (sem_getvalue(semaphore, &current) < 0) {
            return -1;
        }
        if (current == 0) {
            return 0;
        }
        if (nowait) {
            errno = EAGAIN;
            return -1;
        }
        struct timespec delay = {.tv_sec = 0, .tv_nsec = 1000000};
        if (nanosleep(&delay, NULL) < 0 && errno != EINTR) {
            return -1;
        }
    }
}

int semget(key_t key, int count, int flags) {
    char operation[96];
    (void)snprintf(operation, sizeof(operation), "semget key=%d flags=0x%x",
                   (int)key, flags);
    if (count != 1) {
        errno = EINVAL;
        shim_trace(operation, -1, errno);
        return -1;
    }

    char name[64];
    int id = make_id(key);
    if (semaphore_name(id, name, sizeof(name)) < 0) {
        shim_trace(operation, -1, errno);
        return -1;
    }

    int open_flags = 0;
    if (flags & IPC_CREAT) {
        open_flags |= O_CREAT;
    }
    if (flags & IPC_EXCL) {
        open_flags |= O_EXCL;
    }
    sem_t *semaphore = sem_open(name, open_flags, flags & 0777, 0);
    if (semaphore == SEM_FAILED) {
        int error_number = errno;
        shim_trace(operation, -1, error_number);
        errno = error_number;
        return -1;
    }
    relax_backing_permissions(name);
    sem_close(semaphore);
    errno = 0;
    shim_trace(operation, id, 0);
    return id;
}

int semctl(int id, int semnum, int command, ...) {
    if (semnum != 0) {
        errno = EINVAL;
        shim_trace("semctl", -1, errno);
        return -1;
    }

    char name[64];
    if (semaphore_name(id, name, sizeof(name)) < 0) {
        shim_trace("semctl", -1, errno);
        return -1;
    }

    if (command == IPC_RMID) {
        sem_t *semaphore = sem_open(name, 0);
        if (semaphore == SEM_FAILED) {
            int error_number = errno;
            shim_trace("semctl_rmid", -1, error_number);
            errno = error_number;
            return -1;
        }
        int result = sem_unlink(name);
        int error_number = errno;
        sem_close(semaphore);
        shim_trace("semctl_rmid", result, error_number);
        errno = error_number;
        return result;
    }

    sem_t *semaphore = sem_open(name, 0);
    if (semaphore == SEM_FAILED) {
        int error_number = errno;
        shim_trace("semctl", -1, error_number);
        errno = error_number;
        return -1;
    }

    int result = 0;
    errno = 0;
    if (command == SETVAL) {
        va_list arguments;
        va_start(arguments, command);
        unsigned long value = va_arg(arguments, unsigned long);
        va_end(arguments);
        result = adjust_value(semaphore, (int)value);
    } else if (command == GETVAL) {
        if (sem_getvalue(semaphore, &result) < 0) {
            result = -1;
        }
    } else if (command == GETPID) {
        result = (int)getpid();
    } else if (command == GETNCNT || command == GETZCNT) {
        result = 0;
    } else if (command == IPC_STAT || command == IPC_SET) {
        // Steam only uses IPC_STAT/IPC_SET for compatibility checks in some
        // builds. The event implementation does not consume the metadata.
        result = 0;
    } else {
        errno = EINVAL;
        result = -1;
    }
    int error_number = errno;
    sem_close(semaphore);
    shim_trace("semctl", result, error_number);
    errno = error_number;
    return result;
}

int semop(int id, struct sembuf *operations, size_t count) {
    if (!operations || count == 0) {
        errno = EINVAL;
        shim_trace("semop", -1, errno);
        return -1;
    }
    char name[64];
    sem_t *semaphore = open_id(id, name, sizeof(name));
    if (semaphore == SEM_FAILED) {
        int error_number = errno;
        shim_trace("semop", -1, error_number);
        errno = error_number;
        return -1;
    }

    int result = 0;
    errno = 0;
    for (size_t index = 0; index < count; index++) {
        struct sembuf operation = operations[index];
        int nowait = (operation.sem_flg & IPC_NOWAIT) != 0;
        if (operation.sem_op > 0) {
            for (int repeat = 0; repeat < operation.sem_op; repeat++) {
                if (sem_post(semaphore) < 0) {
                    result = -1;
                    break;
                }
            }
        } else if (operation.sem_op < 0) {
            for (int repeat = 0; repeat < -operation.sem_op; repeat++) {
                int wait_result = nowait ? sem_trywait(semaphore) : sem_wait(semaphore);
                if (wait_result < 0) {
                    result = -1;
                    break;
                }
            }
        } else {
            result = wait_zero(semaphore, nowait);
        }
        if (result < 0) {
            break;
        }
    }
    int error_number = errno;
    sem_close(semaphore);
    shim_trace("semop", result, error_number);
    errno = error_number;
    return result;
}
